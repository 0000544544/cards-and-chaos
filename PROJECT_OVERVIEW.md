# 🚀 STOP AT THE FRAME — VISION & PIPELINE DU PROJET

> **Résumé exécutif :** Ce projet combine deux piliers complémentaires :
> 1. **Un pipeline de génération d'assets 3D autonome** exploitant nos ressources matérielles locales (GPU RTX 5070, ComfyUI, scripts d'automatisation Blender).
> 2. **Un jeu Roblox complet de qualité *Top Simulator*** associant farm actif (pêche d'épaves 3D), revenus passifs (showroom de véhicules) et compétition de précision (défi 1v1 sur pente abrupte).

---

## 🏗️ PILIER 1 : Le Pipeline de Génération d'Assets 3D

L'ambition est de s'affranchir de la création manuelle chronophage en automatisant la production de véhicules et d'accessoires 3D optimisés pour Roblox.

```
┌─────────────────────────────────┐
│     Concept / Modèle 3D         │ (Hunyuan3D-2.0, TripoSR, ou Mesh Low-Poly)
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│      ComfyUI Local (RTX 5070)   │ Génération ou conversion initiale en maillage 3D (.glb)
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│  Blender Automation (Python)    │ pipeline/blender_vehicle_cutter.py :
│                                 │ • Décimation polygonale (< 9 500 triangles)
│                                 │ • Découpe du châssis & des 4 roues
│                                 │ • Point d'attache 'CraneHookPoint' pour l'aimant
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│  Roblox Studio (Import 3D)      │ Import standard MeshPart -> ReplicatedStorage.Vehicles
└─────────────────────────────────┘
```

### Détail des étapes du pipeline :
1. **Génération / Acquisition 3D :**
   * Exploitation de la RTX 5070 en local pour générer des modèles (ex: `real_truck_chassis.glb`, `lightning_mcqueen_smooth.glb`, `mater_smooth.glb`).
   * Priorité aux formes "Low-Poly stylisées" et nettes qui s'intègrent parfaitement à la direction artistique Roblox.
2. **Post-traitement sous Blender (`pipeline/blender_vehicle_cutter.py`) :**
   * **Optimisation :** Réduction du maillage sous la barre des 10 000 triangles (limite recommandée pour la fluidité Roblox).
   * **Segmentation :** Séparation du châssis principal (`body`) et des roues (`wheel-front-left`, etc.) pour permettre l'animation de conduite physique.
   * **Rigging aimant :** Insertion d'une ancre invisible `CraneHookPoint` pour le grappin et l'électro-aimant de la grue.
3. **Importation dans Roblox :**
   * Via l'outil natif **Import 3D** de Roblox Studio.
   * Les scripts Luau instancient dynamiquement ces modèles à la place des pièces procédurales.

---

## 🎮 PILIER 2 : Le Jeu Roblox "Stop at the Frame"

Un gameplay hybride pensé selon les standards des plus grands succès Roblox (*Fishing Simulator*, *Fisch*, *Car Tycoon*).

```
┌───────────────────────────────────────────────────────────┐
│                    BOUCLE DE GAMEPLAY                     │
│                                                           │
│  [1. PÊCHE D'ÉPAVES]  ──>  [2. SHOWROOM GARAGE]  ──────┐  │
│    Farm actif en mer          Revenu passif ($/sec)     │  │
│                                                         │  │
│                           [3. STOP THE FRAME (1v1)] <───┘  │
│                              Pari & Compétition            │
└───────────────────────────────────────────────────────────┘
```

### 1. La Jetée Maritime Tropicale & le Mode Pêche (Farm Actif)
* **Ambiance Jetée "Runway" :**
  * Une longue jetée en bois maritime traversée par 5 lignes laser Cyan néon menant vers l'océan.
  * Éclairage immersif de station balnéaire (guirlandes lumineuses festives, atmosphère tropicale, reflets d'eau réalistes).
* **Station de Pêche Panoramique :**
  * Située au bout du quai, ouverte sur un horizon infini sans poteaux obstructifs.
  * Interaction immédiate via le bouton d'action au bas de l'écran **`[E] 🎣 PÊCHER DES VOITURES`**.
* **Mini-Jeu de Pêche au Timing :**
  * Dès l'activation, la caméra bascule en vue aérienne plongeante sur les fonds marins.
  * Déplacement libre de l'électro-aimant avec rayon laser au-dessus des 6 spots sous-marins de rareté (Commune, Rare, Épique, Légendaire, Mythique).
  * Jauge timing à zone cible verte : déclenchement avec `[ESPACE]` pour treuiller le véhicule jusqu'à la surface.

### 2. Le Garage Showroom (Progression & Revenus Passifs)
* **Double Rangée de Podiums :**
  * Les 6 véhicules de la collection sont exposés sur des podiums circulaires lumineux disposés de part et d'autre de la piste.
  * Rotation douce des modèles 3D avec éclairage sous-châssis.
* **Génération de Cash ($/s) :**
  * Chaque véhicule génère automatiquement des revenus en continu (de **$2/s** pour la *Lotus Rally* jusqu'à **$150/s** pour *Flash McQueen*).
  * Pads néon au sol permettant de visualiser et collecter ses gains.

### 3. Le Défi 1v1 "Stop the Frame" (Compétition & Précision)
* **La Pente Abrupte de San Francisco :**
  * Route inclinée spectaculaire bordée d'immeubles pastel victoriens.
  * Propulsion à haute vitesse avec saut cabré (+24° de pitch) au-dessus de la cible.
* **Le "Frame Perfect" :**
  * Le joueur doit immobiliser sa voiture exactement à l'intérieur du cadre vert néon (`TargetFrame`).
  * Système de notation au millième de seconde (*Frame Perfect 100%*, *Parfait*, *Bien*, *Raté*) accordant des multiplicateurs massifs de cash et une progression de streak (série de victoires).

### 4. Design System UI "Figma Simulator"
* **HUD minimaliste et moderne :**
  * Compteur de Cash et gain par seconde en bas à gauche (`💰 $29,948  +$254 / seconde`).
  * Bouton contextuel d'interaction au bas de l'écran centré.
  * Cartes de récompense avec bords arrondis, dégradés verticaux et boutons rebondissants au survol.

---

## 🛠️ Stack Technique & Outils

| Composant | Technologie | Rôle |
|---|---|---|
| **Orchestration & Code** | Google Antigravity + Gemini 3.1 | Pair programming, conception architecturale et implémentation Luau. |
| **Synchronisation Roblox** | Rojo + Luau | Compilation instantanée des scripts du dossier `src/` vers Roblox Studio. |
| **Moteur Physique & Rendu** | Roblox Studio | Moteur physique, rendu d'éclairage (Future/Atmosphere) et multijoueur. |
| **Génération 3D IA** | ComfyUI local (RTX 5070 12 Go) | Génération locale de maillages 3D (.glb). |
| **Pipeline Géométrie 3D** | Blender Python (Blender 4+) | Découpe du châssis, séparation des roues, décimation polygonale. |
