import json
import os
import random
import time
import urllib.parse
import urllib.request
import uuid
import websocket
from PIL import Image
import io

DEFAULT_COMFYUI_URL = "http://127.0.0.1:8188"

def get_server_info(server_url: str = DEFAULT_COMFYUI_URL):
    """Récupère les checkpoints et LoRAs disponibles sur l'instance ComfyUI."""
    try:
        req = urllib.request.Request(f"{server_url}/object_info/CheckpointLoaderSimple")
        with urllib.request.urlopen(req, timeout=5) as response:
            ckpt_info = json.loads(response.read().decode())
            checkpoints = ckpt_info.get("CheckpointLoaderSimple", {}).get("input", {}).get("required", {}).get("ckpt_name", [[]])[0]
    except Exception:
        checkpoints = []

    try:
        req = urllib.request.Request(f"{server_url}/object_info/LoraLoader")
        with urllib.request.urlopen(req, timeout=5) as response:
            lora_info = json.loads(response.read().decode())
            loras = lora_info.get("LoraLoader", {}).get("input", {}).get("required", {}).get("lora_name", [[]])[0]
    except Exception:
        loras = []

    try:
        req = urllib.request.Request(f"{server_url}/object_info/ControlNetLoader")
        with urllib.request.urlopen(req, timeout=5) as response:
            cnet_info = json.loads(response.read().decode())
            controlnets = cnet_info.get("ControlNetLoader", {}).get("input", {}).get("required", {}).get("control_net_name", [[]])[0]
    except Exception:
        controlnets = []

    return {"checkpoints": checkpoints, "loras": loras, "controlnets": controlnets}


def create_animagine_workflow(
    ckpt_name: str,
    prompt: str,
    negative_prompt: str,
    seed: int = -1,
    width: int = 832,
    height: int = 1216,
    steps: int = 28,
    cfg: float = 7.0,
    lora_name: str = None,
    lora_strength: float = 0.8
) -> dict:
    if seed < 0:
        seed = random.randint(1, 1125899906842624)

    positive_full = f"masterpiece, best quality, very aesthetic, character sprite, {prompt}"
    negative_full = f"lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, blurry, artist name, {negative_prompt}"

    workflow = {
        "3": {
            "inputs": {
                "seed": seed,
                "steps": steps,
                "cfg": cfg,
                "sampler_name": "euler_ancestral",
                "scheduler": "karras",
                "denoise": 1.0,
                "model": ["10", 0] if lora_name else ["4", 0],
                "positive": ["6", 0],
                "negative": ["7", 0],
                "latent_image": ["5", 0]
            },
            "class_type": "KSampler"
        },
        "4": {
            "inputs": {
                "ckpt_name": ckpt_name
            },
            "class_type": "CheckpointLoaderSimple"
        },
        "5": {
            "inputs": {
                "width": width,
                "height": height,
                "batch_size": 1
            },
            "class_type": "EmptyLatentImage"
        },
        "6": {
            "inputs": {
                "text": positive_full,
                "clip": ["10", 1] if lora_name else ["4", 1]
            },
            "class_type": "CLIPTextEncode"
        },
        "7": {
            "inputs": {
                "text": negative_full,
                "clip": ["10", 1] if lora_name else ["4", 1]
            },
            "class_type": "CLIPTextEncode"
        },
        "8": {
            "inputs": {
                "samples": ["3", 0],
                "vae": ["4", 2]
            },
            "class_type": "VAEDecode"
        },
        "9": {
            "inputs": {
                "filename_prefix": "HD2D_Sprite",
                "images": ["8", 0]
            },
            "class_type": "SaveImage"
        }
    }

    if lora_name:
        workflow["10"] = {
            "inputs": {
                "lora_name": lora_name,
                "strength_model": lora_strength,
                "strength_clip": lora_strength,
                "model": ["4", 0],
                "clip": ["4", 1]
            },
            "class_type": "LoraLoader"
        }

    return workflow


class ComfyUIClient:
    def __init__(self, server_url: str = DEFAULT_COMFYUI_URL):
        self.server_url = server_url.rstrip("/")
        self.client_id = str(uuid.uuid4())

    def check_connection(self) -> bool:
        try:
            req = urllib.request.Request(f"{self.server_url}/system_stats")
            with urllib.request.urlopen(req, timeout=3) as resp:
                return resp.status == 200
        except Exception:
            return False

    def find_animagine_checkpoint(self) -> str:
        info = get_server_info(self.server_url)
        ckpts = info.get("checkpoints", [])
        for c in ckpts:
            if "animagine" in c.lower():
                return c
        return ckpts[0] if ckpts else "animagine-xl-3.1.safetensors"

    def queue_prompt(self, prompt_workflow: dict) -> dict:
        p = {"prompt": prompt_workflow, "client_id": self.client_id}
        data = json.dumps(p).encode("utf-8")
        req = urllib.request.Request(f"{self.server_url}/prompt", data=data, headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req) as response:
            return json.loads(response.read().decode())

    def get_image(self, filename: str, subfolder: str, folder_type: str) -> bytes:
        params = urllib.parse.urlencode({"filename": filename, "subfolder": subfolder, "type": folder_type})
        req = urllib.request.Request(f"{self.server_url}/view?{params}")
        with urllib.request.urlopen(req) as response:
            return response.read()

    def generate(
        self,
        prompt: str,
        negative_prompt: str = "",
        seed: int = -1,
        width: int = 832,
        height: int = 1216,
        lora_name: str = None,
        lora_strength: float = 0.8,
        ckpt_name: str = None,
        timeout: int = 180
    ) -> Image.Image:
        if not self.check_connection():
            raise ConnectionError(f"Impossible de joindre ComfyUI sur {self.server_url}. Vérifiez que ComfyUI est bien lancé.")

        if not ckpt_name:
            ckpt_name = self.find_animagine_checkpoint()

        workflow = create_animagine_workflow(
            ckpt_name=ckpt_name,
            prompt=prompt,
            negative_prompt=negative_prompt,
            seed=seed,
            width=width,
            height=height,
            lora_name=lora_name,
            lora_strength=lora_strength
        )

        ws_url = self.server_url.replace("http://", "ws://").replace("https://", "wss://")
        try:
            ws = websocket.create_connection(f"{ws_url}/ws?clientId={self.client_id}", timeout=timeout)
        except Exception:
            ws = None

        try:
            queued = self.queue_prompt(workflow)
            prompt_id = queued["prompt_id"]

            start_time = time.time()
            output_images = []

            # Attente de la fin d'exécution via WebSocket ou polling HTTP
            while time.time() - start_time < timeout:
                if ws:
                    try:
                        msg = ws.recv()
                        if isinstance(msg, str):
                            message = json.loads(msg)
                            msg_type = message.get("type")
                            data = message.get("data", {})

                            if msg_type == "executing" and data.get("node") is None and data.get("prompt_id") == prompt_id:
                                break
                            elif msg_type == "execution_error":
                                raise RuntimeError(f"Erreur d'exécution ComfyUI: {data}")
                    except websocket.WebSocketTimeoutException:
                        pass
                    except Exception:
                        ws = None

                # Fallback : vérification de l'historique par polling HTTP
                try:
                    req = urllib.request.Request(f"{self.server_url}/history/{prompt_id}")
                    with urllib.request.urlopen(req, timeout=3) as resp:
                        history = json.loads(resp.read().decode())
                        if prompt_id in history:
                            break
                except Exception:
                    pass

                time.sleep(1.0)

            req = urllib.request.Request(f"{self.server_url}/history/{prompt_id}")
            with urllib.request.urlopen(req) as resp:
                history = json.loads(resp.read().decode())
                outputs = history.get(prompt_id, {}).get("outputs", {})
                for node_id, node_output in outputs.items():
                    if "images" in node_output:
                        for img_meta in node_output["images"]:
                            img_bytes = self.get_image(img_meta["filename"], img_meta.get("subfolder", ""), img_meta.get("type", "output"))
                            output_images.append(Image.open(io.BytesIO(img_bytes)))

            if not output_images:
                raise RuntimeError("ComfyUI n'a retourné aucune image.")

            return output_images[0]
        finally:
            if ws:
                try:
                    ws.close()
                except Exception:
                    pass

    def generate_animation_frames(
        self,
        character_prompt: str,
        negative_prompt: str = "",
        base_seed: int = -1,
        lora_name: str = None
    ) -> list[Image.Image]:
        """
        Génère une séquence complète de 12 poses cohérentes pour un personnage :
        - 4 frames 'idle' (ligne 0)
        - 4 frames 'walk' (ligne 1)
        - 4 frames 'attack' (ligne 2)
        """
        if base_seed < 0:
            base_seed = random.randint(1000, 99999999)

        # Génération d'une planche de sprite sheet par prompt structuré
        # Animagine XL gère les planches de sprites en résolution paysage (1216x832)
        sheet_prompt = (
            f"sprite sheet, character animation sheet, 12 poses, {character_prompt}, "
            f"top row: 4 frames idle breathing stance, "
            f"middle row: 4 frames walk cycle running movement, "
            f"bottom row: 4 frames sword attack forward strike slash, "
            f"isolated character, solid plain white background, full body, pixel art aesthetic"
        )

        # Essai de génération de la planche globale
        try:
            print(f"[ComfyUI] Génération de la planche complète pour '{character_prompt}'...")
            raw_sheet = self.generate(
                prompt=sheet_prompt,
                negative_prompt=negative_prompt + ", messy background, overlapping characters, cropped limbs",
                seed=base_seed,
                width=1216,
                height=832,
                lora_name=lora_name
            )
            return [raw_sheet]
        except Exception as e:
            print(f"[ComfyUI] Génération globale échouée ({e}), fallback vers génération par animations...")

        # Fallback : génération de 3 planches horizontales (idle, walk, attack)
        anims = [
            ("idle", "sprite sheet, 4 frames, idle stance breathing cycle"),
            ("walk", "sprite sheet, 4 frames, walk cycle running forward"),
            ("attack", "sprite sheet, 4 frames, sword attack combat slash action")
        ]
        results = []
        for anim_name, anim_prompt in anims:
            full_prompt = f"{anim_prompt}, {character_prompt}, solid white background, clean full body"
            img = self.generate(
                prompt=full_prompt,
                negative_prompt=negative_prompt,
                seed=base_seed,
                width=1216,
                height=416,
                lora_name=lora_name
            )
            results.append(img)

        return results
