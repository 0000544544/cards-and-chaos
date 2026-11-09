# Architecture & Normes Roblox de Développement - Stop at the Frame

- **Structure du projet** : Rojo avec code Luau strict localisé dans `src/`.
  * `src/server/` : Scripts serveur (Services, DataManager, Logique métier)
  * `src/client/` : Scripts client (Controllers, UI Luau, Inputs)
  * `src/shared/` : Modules partagés et configurations
- **Synchronisation & Build** : Toujours modifier les fichiers texte `.luau` dans `src/`. Ne jamais tenter d'éditer directement les fichiers binaires `.rbxl`. Compiler via `rebuild.bat` (ou `rojo build -o StopAtTheFrame.rbxl`).
- **Code Style** :
  * Utiliser du Luau typé (Typechecking `--!strict` en tête de chaque fichier).
  * Fichiers encodés en UTF-8 sans BOM (`HasBOM=False`).
  * Gérer le nettoyage mémoire et éviter les boucles `while true do` sans `task.wait()`.
- **Pipeline 3D** : Utiliser les scripts dans `pipeline/` (`comfy_client.py` et `blender_vehicle_cutter.py`) pour la génération et découpe 3D automatique (<10k poly, séparation roues/châssis, point d'ancrage `CraneHookPoint`).
- **Services Principaux** :
  * Mode Pêche : `CraneService.luau` (treuil, aimant sous-marin, tables de loot aquatique).
  * Showroom Garage : `GarageService.luau` (stands d'exposition, revenu passif $/sec).
  * Données Joueur : `DataManager.luau` (sauvegarde DataStore, inventaire, niveaux d'amélioration).
