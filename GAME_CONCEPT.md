# STOP AT THE FRAME — GAME DESIGN & CONCEPT DOCUMENT
================================================================================

## 1. Le Concept du Jeu
Expérience Roblox complète axée sur la collection, le farm actif et le pari de véhicules à haut risque :

* **Mode Pêche (Farm principal) :**
  Une grue industrielle équipée d'un câble physique et d'un aimant électromagnétique harponne des véhicules immergés au fond de l'eau.
  Plus le câble est long, résistant et puissant, plus vous pêchez des véhicules rares dans les abysses (de l'épave rouillée jusqu'à la Batmobile et Flash McQueen).

* **Garage Showroom (Revenu Passif) :**
  Les voitures repêchées sont restaurées, customisées et exposées dans un hangar personnel.
  Chaque véhicule exposé génère un revenu passif régulier en continu ($Cash / seconde$).

* **Mode 1v1 "Stop the Frame" (Pari High-Stakes) :**
  Deux joueurs misent une voiture de leur collection et s'affrontent sur une pente descendante abrupte style San Francisco.
  Le véhicule est propulsé à haute vitesse. Le joueur qui réalise l'arrêt le plus précis (Frame Perfect) remporte la voiture mise en jeu par son adversaire.

---

## 2. La Stack Technique & Matérielle

| Domaine | Outil | Rôle & Intégration |
|---|---|---|
| **IDE & IA principal** | **Google Antigravity** | Orchestration multi-agents avec Gemini 3.1 Pro / Flash (crédits Google Cloud). |
| **Code & Dynamic Sync** | **Rojo + Luau** | Architecture texte Luau sous `src/`, synchronisation instantanée avec Studio. |
| **Moteur de jeu** | **Roblox Studio** | Moteur physique, rendu 3D, leaderstats et éclairage. |
| **Génération 3D (Véhicules)** | **ComfyUI + Hunyuan3D-2.0** | Génération 3D locale sur GPU (RTX 5070 12 Go) ou fallback **Meshy AI**. |
| **Automation 3D** | **Blender + `mcp-for-blender`** | Découpe du châssis, roues, attache grappin `CraneHookPoint`, décimation < 10k tris via `pipeline/blender_vehicle_cutter.py`. |
| **Base de Connaissances** | **Obsidian** | Fiches techniques, tables de loot/raretés et équilibrage économique. |

---

## 3. Feuille de Route d'Exécution

```text
[Étape 1 : Switch Rojo] ──> [Étape 2 : Core Systems Luau] ──> [Étape 3 : Asset Pipeline 3D] ──> [Étape 4 : Mode 1v1]
```

### Étape 1 : Switch Rojo (Terminé)
- Architecture modulaire Luau (`src/client`, `src/server`, `src/shared`).
- Compilation automatique via `rebuild.bat` et `default.project.json`.

### Étape 2 : Core Systems Luau (Services Serveur)
Création des trois services piliers dans `src/server/Services/` :
1. `CraneService.luau` : Physique du câble, treuil, détection d'accrochage sous-marin, table de loot par palier de profondeur.
2. `GarageService.luau` : Emplacements d'exposition (Showroom Slots), boucle de calcul du cash passif par seconde.
3. `DataManager.luau` : Sauvegarde persistante avec `DataStoreService` (Cash, Streak, Inventaire de véhicules possédés, upgrades de grue).

### Étape 3 : Pipeline d'Importation 3D de Véhicules Rares
- Génération des meshes (Flash McQueen, Batmobile, CyberTruck, etc.).
- Traitement automatique Blender via `pipeline/blender_vehicle_cutter.py`.
- Injection dans `ReplicatedStorage.Vehicles`.

### Étape 4 : Connexion du Mode 1v1 "Stop the Frame"
- Mise en jeu des véhicules de l'inventaire.
- Arène 1v1 compétitive avec téléportation des duellistes et transfert de propriété du véhicule gagné.
