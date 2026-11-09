#!/usr/bin/env python3
"""
PIPELINE TRIPOSR 3D GENERATOR (STOP AT THE FRAME)
Convertit une image 2D en modèle 3D .glb en moins de 3 secondes sur RTX 5070 locale.
"""

import os
import sys
import time
import torch
from PIL import Image

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRIPOSR_DIR = r"C:\Users\AymaneELHOMAIDI\ComfyUI\custom_nodes\ComfyUI-Flowty-TripoSR"
WEIGHT_PATH = r"C:\Users\AymaneELHOMAIDI\ComfyUI\models\checkpoints\triposr.ckpt"
CONFIG_PATH = os.path.join(TRIPOSR_DIR, "config.yaml")

sys.path.insert(0, TRIPOSR_DIR)
from tsr.system import TSR

def generate_glb_from_image(input_image_path: str, output_glb_path: str, resolution: int = 256) -> str:
    if not os.path.exists(input_image_path):
        raise FileNotFoundError(f"Image introuvable : {input_image_path}")

    device = "cuda:0" if torch.cuda.is_available() else "cpu"
    print(f"[TripoSR] Chargement du modèle sur {device}...")
    model = TSR.from_pretrained_custom(weight_path=WEIGHT_PATH, config_path=CONFIG_PATH)
    model.to(device)
    model.renderer.set_chunk_size(8192)

    img = Image.open(input_image_path).convert("RGB")
    t0 = time.time()
    with torch.no_grad():
        scene_codes = model(img, device=device)
        meshes = model.extract_mesh(scene_codes, resolution=resolution)

    duration = time.time() - t0
    mesh = meshes[0]
    os.makedirs(os.path.dirname(os.path.abspath(output_glb_path)), exist_ok=True)
    mesh.export(output_glb_path)
    file_size_mb = os.path.getsize(output_glb_path) / (1024 * 1024)
    res_msg = f"[TripoSR] Maillage 3D extrait en {duration:.2f}s ! Sauvegardé sous {output_glb_path} ({file_size_mb:.2f} Mo, {len(mesh.vertices)} sommets, {len(mesh.faces)} polygones)"
    print(res_msg)
    return res_msg

if __name__ == "__main__":
    default_input = os.path.join(BASE_DIR, "pipeline", "generated_vehicle.png")
    default_output = os.path.join(BASE_DIR, "pipeline", "generated_vehicle.glb")
    in_img = sys.argv[1] if len(sys.argv) > 1 else default_input
    out_glb = sys.argv[2] if len(sys.argv) > 2 else default_output
    generate_glb_from_image(in_img, out_glb)
