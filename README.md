# ⚡ STOP AT THE FRAME (ROBLOX EDITION)

> **Jeu Roblox d'adresse, de réflexes et de précision millimétrée (style arcade viral TikTok / Shorts).**
> Une voiture est propulsée à grande vitesse dans les airs au-dessus d'une colline raide style San Francisco. Le joueur doit appuyer au moment exact où la silhouette du véhicule s'emboîte parfaitement dans le cadre vert néon (*TargetFrame*).

---

## 🎮 1. CONCEPT & GAMEPLAY

- **Le Saut Parabolique :** Le véhicule décolle avec un cabrage dynamique, culmine au-dessus de la cible, puis redescend en rasant le cadre vert néon avec une tangente parfaitement lisse ($sin^2$).
- **L'Arrêt d'Urgence :** Le joueur clique ou appuie sur `Espace` pour figer instantanément la voiture.
- **Le Frame Grading :**
  - 🏆 **FRAME PERFECT!** (< 0.8 stud) : 100% de la prime, snap visuel immédiat dans le cadre, flash néon doré plein écran, secousse de caméra et cloche cristalline.
  - 🟢 **PERFECT!** (< 2.5 studs) : 75% de la prime, alignement à plat face au cadre, son de succès et maintien de la série.
  - 🟡 **GOOD!** (< 5.0 studs) : 40% de la prime.
  - 💥 **RATÉ!** (≥ 5.0 studs) : 0$, remise à zéro de la série, dé-ancrage physique de la voiture qui s'écrase sur la route avec fracas de tôle.

---

## 🚗 2. LE GARAGE (5 VÉHICULES PROCÉDURAUX)

Tous les modèles 3D sont générés procéduralement sans aucun mesh ni asset externe :

| # | Véhicule | Vitesse | Prime | Description |
|---|---|---|---|---|
| **#1** | **Lotus Rally** | `x1.00` | **$50** | Voiture de rallye rouge vif compacte, idéale pour débuter |
| **#2** | **Cyber Truck** | `x1.35` | **$120** | Pick-up futuriste blindé en acier brossé avec lightbars cyan |
| **#3** | **Drift Supra** | `x1.70` | **$300** | Sportive japonaise orange vif, splitter carbone et aileron GT |
| **#4** | **Police Interceptor** | `x2.10` | **$750** | Berline de police noire et blanche, pare-buffle et gyrophares animés |
| **#5** | **Hyperion JetCar** | `x2.70` | **$2000** | Hypercar dorée avec verrière de chasseur et réacteurs à plasma |

---

## ⌨️ 3. COMMANDES DE JEU

| Action | Raccourcis PC | Mobile / Tactile |
|---|---|---|
| **Figer le véhicule** | `Barre d'Espace` ou `Clic Gauche` | `Appui sur l'écran` |
| **Changer de voiture** | `[Q] / [D]` ou `[←] / [→]` | Boutons `[◀]` et `[▶]` du HUD |

---

## 🛠️ 4. ARCHITECTURE DU CODE (ROJO & LUAU)

```text
roblox-card-dominion/
├── default.project.json                    # Configuration du mapping Rojo
├── StopAtTheFrame.rbxl                     # Fichier place Roblox binaire
├── StopAtTheFrame.rbxlx                    # Fichier place Roblox XML
├── launch_studio.bat                       # Raccourci pour lancer Roblox Studio
├── rebuild.bat                             # Script de compilation Rojo automatique
├── serve_rojo.bat                          # Serveur de synchronisation en direct
└── src/
    ├── client/
    │   ├── CameraController.client.luau    # Caméra fixe Scriptable en contre-plongée (20 studs)
    │   └── GameLoop.client.luau            # Trajectoire sin², inputs, audio SFX et HUD
    ├── server/
    │   ├── WorldBuilder.server.luau        # Génération procédurale de la rue San Francisco
    │   └── GameServer.server.luau          # Leaderstats (Cash, Streak, Titre), RemoteEvents
    └── shared/
        └── CarBuilder.luau                 # Modèles 3D des 5 voitures & scanner laser Raycast
```

---

## 🚀 5. SCRIPTS UTILITAIRES

- **`launch_studio.bat` :** Ouvre directement la place `StopAtTheFrame.rbxl` dans Roblox Studio.
- **`rebuild.bat` :** Compile le code Luau vers `StopAtTheFrame.rbxl` et `StopAtTheFrame.rbxlx` puis les copie automatiquement à la racine.
- **`serve_rojo.bat` :** Démarre le serveur local Rojo pour le live-sync pendant le développement dans Studio.
