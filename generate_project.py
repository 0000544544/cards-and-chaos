import json

project = {
    "name": "roblox-card-dominion",
    "tree": {
        "$className": "DataModel",
        "ReplicatedStorage": {
            "$className": "ReplicatedStorage",
            "Shared": {
                "$path": "src/shared"
            }
        },
        "ServerScriptService": {
            "$className": "ServerScriptService",
            "Server": {
                "$path": "src/server"
            }
        },
        "StarterPlayer": {
            "$className": "StarterPlayer",
            "StarterPlayerScripts": {
                "$className": "StarterPlayerScripts",
                "Client": {
                    "$path": "src/client"
                }
            }
        },
        "Workspace": {
            "$className": "Workspace",
            "Baseplate": {
                "$className": "Part",
                "$properties": {
                    "Anchored": True,
                    "Color": [0.25, 0.28, 0.35],
                    "Locked": True,
                    "Position": [0, -5, 0],
                    "Size": [512, 10, 512]
                }
            }
        },
        "Lighting": {
            "$className": "Lighting",
            "$properties": {
                "Ambient": [0.47, 0.49, 0.59],
                "OutdoorAmbient": [0.55, 0.57, 0.69],
                "Brightness": 2.5,
                "ClockTime": 14.5,
                "GlobalShadows": True,
                "Technology": "Voxel"
            }
        },
        "SoundService": {
            "$className": "SoundService",
            "$properties": {
                "RespectFilteringEnabled": True
            }
        }
    }
}

from pathlib import Path
output_file = Path(__file__).parent / "default.project.json"
with open(output_file, "w", encoding="utf-8") as f:
    json.dump(project, f, indent=2)

print("default.project.json généré proprement (sans aucun bloc jaune fluo) !")
