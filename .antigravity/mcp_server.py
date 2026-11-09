import subprocess
import os
import sys

# Support for both MCP v1 (FastMCP) and MCP v2 (MCPServer)
try:
    from mcp.server.fastmcp import FastMCP as MCPServer
except (ImportError, ModuleNotFoundError):
    from mcp.server import MCPServer

# 1. Initialisation du serveur MCP 
# L'IA verra ce nom quand elle cherchera ses outils
mcp = MCPServer("Roblox VibeStarter")

# Chemin absolu de base du projet roblox-card-dominion
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COMFY_PYTHON = r"C:\Users\AymaneELHOMAIDI\ComfyUI\venv\Scripts\python.exe"

# --- OUTIL 1 : GÉNÉRATION 3D ---
@mcp.tool()
def generate_3d_car(prompt: str) -> str:
    """
    Génère un véhicule en 3D via ComfyUI et TripoSR sur la RTX 5070 locale.
    Produit une image conceptuelle et extrait un véritable modèle 3D .glb en moins de 3s.
    """
    try:
        # Étape 1 : Image conceptuelle via ComfyUI
        comfy_script = os.path.join(BASE_DIR, "pipeline", "comfy_client.py")
        res_comfy = subprocess.run(
            [sys.executable, comfy_script, "--prompt", prompt],
            capture_output=True, text=True, check=True, cwd=BASE_DIR
        )
        logs = res_comfy.stdout

        # Étape 2 : Extraction du maillage 3D .glb via TripoSR sur RTX 5070
        tripo_script = os.path.join(BASE_DIR, "pipeline", "triposr_generator.py")
        res_tripo = subprocess.run(
            [COMFY_PYTHON, tripo_script],
            capture_output=True, text=True, check=True, cwd=BASE_DIR
        )
        logs += "\n" + res_tripo.stdout

        return f"Succès : Véhicule 3D (.glb) généré avec succès sur RTX 5070 !\nLogs:\n{logs}"
    except subprocess.CalledProcessError as e:
        return f"Erreur lors de la génération 3D : {e.stderr or e.stdout}"
    except Exception as e:
        return f"Erreur inattendue : {e}"

# --- OUTIL 2 : PIPELINE BLENDER ---
@mcp.tool()
def cut_vehicle_in_blender() -> str:
    """
    Passe le dernier modèle 3D généré dans Blender pour découper les roues, 
    ajouter le point d'ancrage de la grue et optimiser le mesh (<10k tris).
    À utiliser systématiquement APRÈS generate_3d_car.
    """
    try:
        script_path = os.path.join(BASE_DIR, "pipeline", "blender_vehicle_cutter.py")
        result = subprocess.run(
            [sys.executable, script_path],
            capture_output=True, text=True, check=True, cwd=BASE_DIR
        )
        return f"Succès : Véhicule découpé et optimisé pour Roblox.\nLogs: {result.stdout}"
    except subprocess.CalledProcessError as e:
        return f"Erreur Blender : {e.stderr or e.stdout}"
    except Exception as e:
        return f"Erreur inattendue : {e}"

# --- OUTIL 3 : COMPILATION ROBLOX ---
@mcp.tool()
def rebuild_roblox_place() -> str:
    """
    Compile le projet Luau en StopAtTheFrame.rbxl via rebuild.bat et met à jour Git.
    À utiliser après toute modification de code importante.
    """
    try:
        rebuild_bat = os.path.join(BASE_DIR, "rebuild.bat")
        result = subprocess.run(
            [rebuild_bat, "cli"], 
            capture_output=True, text=True, check=True, shell=True, cwd=BASE_DIR
        )
        return f"Succès : Place Roblox recompilée.\nLogs: {result.stdout}"
    except subprocess.CalledProcessError as e:
        return f"Erreur de compilation : {e.stderr or e.stdout}"
    except Exception as e:
        return f"Erreur inattendue : {e}"

if __name__ == "__main__":
    # Lance le serveur sur les canaux standards (stdio) pour qu'Antigravity puisse y parler
    mcp.run(transport='stdio')
