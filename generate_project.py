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
            "$properties": {
                "FilteringEnabled": True
            },
            "Baseplate": {
                "$className": "Part",
                "$properties": {
                    "Anchored": True,
                    "Color": [0.10, 0.10, 0.12],
                    "Locked": True,
                    "Position": [0, -5, 0],
                    "Size": [512, 10, 512]
                }
            }
        },
        "Lighting": {
            "$className": "Lighting",
            "$properties": {
                "Ambient": [0.15, 0.12, 0.20],
                "OutdoorAmbient": [0.20, 0.16, 0.28],
                "Brightness": 1.8,
                "ClockTime": 21.0,
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

with open("roblox-card-dominion/default.project.json", "w", encoding="utf-8") as f:
    json.dump(project, f, indent=2)

print("default.project.json généré proprement (sans aucun bloc jaune fluo) !")
