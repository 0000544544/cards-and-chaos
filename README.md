# 👑 SOVEREIGN: CARDS & DOMINION (ROBLOX EDITION)

> **Jeu Roblox Compétitif de Collection de Cartes, Gacha / Roulette (Gambling), Système Anti-P2W de Mérite & Hôtel des Ventes (Achat / Revente)**

---

## 🌟 1. VUE D'ENSEMBLE & PILIERS DE JEU

*SOVEREIGN: CARDS & DOMINION* est conçu en s'appuyant sur les architectures de dark-fantasy, de combat en arène et de théorie des jeux développées dans le workspace (*Crypt of the Sovereign*, *Neon Space Survivor*, *f409 - Evolutionary Game Theory*).

### 🃏 Les 5 Piliers Clés :
1. **🎰 Gambling & Invocations (L'Autel du Destin) :**
   - Roulette de tirage de cartes avec 6 paliers de rareté (*Commun*, *Rare*, *Épique*, *Légendaire*, *Mythique*, *Divin Céleste*).
   - Système de **Pity** (garantie Épique tous les 10 tirages, Légendaire à 50, Mythique à 200).
   - Annonce serveur mondiale spectaculaire à chaque tirage de rareté Légendaire+.
2. **⚡ Le Système de Mérite (Anti-Pay-To-Win) :**
   - Les **Points de Mérite** NE PEUVENT PAS être achetés avec de l'argent réel ou gagnés au hasard !
   - Ils s'obtiennent **strictement au combat** : victoires en arène 1v1, séries de victoires (*Win Streaks*), parades parfaites (*Parry timing à 0.3s*).
   - Utilisés au **Sanctuaire du Mérite** pour **Transcender** une carte en version **Prestige Souverain** (+20% d'efficacité, bordure holographique).
3. **⚖️ Hôtel des Ventes & Achat-Revente (Trading & Marketplace) :**
   - Bourse mondiale des cartes avec recherche, filtres et achat instantané (*Buyout*).
   - Mécanique d'**Achat / Revente (Flipping)** : acheter des cartes sous-évaluées pour les revendre au prix fort.
   - **Taxe déflationniste de 5%** sur chaque transaction pour assainir l'économie et prévenir l'hyperinflation.
   - Système d'échange direct entre joueurs (**P2P Trade**) avec vérification en 2 étapes et compte à rebours anti-arnaque de 3 secondes.
4. **⚔️ Arène Compétitive 1v1 & Classement Elo :**
   - File d'attente compétitive avec appariement automatique basé sur l'Elo (*Formule d'échecs standard K=32*).
   - 7 Paliers compétitifs : *Bronze*, *Argent*, *Or*, *Platine*, *Diamant*, *Maître Suprême*, *LE SOUVERAIN*.
   - Combat en temps réel dans le Colisée Céleste (90 secondes, barres de PV, compte à rebours, annonces de victoire).
5. **🎴 Deck-Building & Synergies :**
   - Composition d'un deck de 4 Compétences Actives (touches 1, 2, 3, 4) + 2 Aptitudes Passives.
   - Synergies d'affinités élémentaires (ex: 3 cartes d'Acier = bonus de vitesse d'attaque, 2 cartes du Vide = vol de vie).

---

## 🎮 2. COMMANDES DE JEU (PC & MOBILE)

| Touche / Action | Rôle |
|---|---|
| **1, 2, 3, 4** | Lancer les 4 compétences actives équipées dans le Deck |
| **A / Q** | **Foulée / Dash d'esquive** (0.35s d'invulnérabilité *I-frame*) |
| **F** | **Posture de Parade (Parry)** (Fenêtre de 0.3s : contre-attaque, étourdit l'adversaire et octroie +15 Mérite) |
| **E** | Interagir avec les 4 Autels du Hub central |
| **Boutons HUD** | Ouvrir le Deck, l'Invocation, le Marché, les Échanges ou l'Arène |

---

## 🏛️ 3. LES 4 AUTELS DU HUB CENTRAL

Le jeu génère automatiquement un Hub 3D en obsidienne avec 4 Autels interactifs équipés de `ProximityPrompt` :
1. **Autel du Destin (Violet / Néon) :** Tirage 1x (100 Or) ou 10x (900 Or) avec compteur de Pity et révélation de cartes.
2. **Hôtel des Ventes (Émeraude) :** Consultation des offres, achat immédiat, et mise en vente de vos cartes.
3. **Porte de l'Arène (Rubis) :** Entrée dans la file 1v1 classée et téléportation vers le Colisée Céleste.
4. **Sanctuaire du Mérite (Or Céleste) :** Transcendance des cartes au rang Souverain Prestige (500 Mérite requis).

---

## 🚀 4. LANCEMENT DU PROJET

Vous pouvez lancer le jeu de 3 façons différentes :

### Option A — Double-clic direct (Le plus rapide)
Double-cliquez sur `launch_studio.bat` (ou à la racine sur `launch_roblox_game.bat`).  
Le fichier de place Roblox `SovereignDominion.rbxl` s'ouvrira immédiatement dans **Roblox Studio**.

### Option B — Live Sync avec Rojo
Si vous préférez coder dans votre éditeur favori et synchroniser en direct dans Roblox Studio :
```bash
# Dans roblox-card-dominion :
serve_rojo.bat
```
Puis dans Roblox Studio, ouvrez le plugin Rojo et cliquez sur **Connect**.

### Option C — Recompiler le projet
Pour reconstruire les fichiers de place après modification des scripts :
```bash
rebuild.bat
```

---

## 📂 5. STRUCTURE DU CODE SOURCE

```
roblox-card-dominion/
├── default.project.json           # Configuration du DataModel Rojo
├── SovereignDominion.rbxl         # Fichier binaire Roblox Place
├── SovereignDominion.rbxlx        # Fichier XML Roblox Place
├── launch_studio.bat              # Script de lancement direct dans Studio
├── serve_rojo.bat                 # Serveur de synchronisation Rojo
├── rebuild.bat                    # Script de recompilation
└── src/
    ├── shared/                    # Modules partagés (ReplicatedStorage.Shared)
    │   ├── CardsData.luau         # Codex de 30+ compétences et cartes
    │   ├── CardUtils.luau         # Calculs de stats, synergies et instances
    │   ├── RarityConfig.luau      # Probabilités Gacha, Pity et multiplicateurs
    │   ├── RankConfig.luau        # Tiers Elo, formules et gains de Mérite
    │   ├── MarketConfig.luau      # Paramètres du Marché et taxes déflationnistes
    │   └── NetworkEvents.luau     # RPC RemoteEvents & RemoteFunctions
    ├── server/                    # Scripts serveur (ServerScriptService.Server)
    │   ├── init.server.luau       # Bootstrap du serveur
    │   ├── DataManager.luau       # DataStore persistant avec fallback mémoire
    │   ├── GachaManager.luau      # Moteur d'invocation et alertes mondiales
    │   ├── MarketManager.luau     # Hôtel des Ventes & Achat-Revente
    │   ├── TradeManager.luau      # Échanges P2P sécurisés
    │   ├── ArenaManager.luau      # File 1v1, gestion de round et calcul Elo
    │   ├── CombatService.luau     # Hitboxes, parade et esquive serveur
    │   ├── MeritManager.luau      # Transcendance et recyclage des cartes
    │   └── MapBuilder.luau        # Génération procédurale du Hub et du Colisée
    └── client/                    # Scripts client (StarterPlayerScripts.Client)
        ├── init.client.luau       # Bootstrap du client
        ├── CombatController.luau  # Gestion des inputs de combat (1-4, Q, F)
        ├── InteractionController.luau # Détection des autels (Touche E)
        └── ui/
            └── UIManager.luau     # Interface complète Dark Fantasy / Glassmorphism
```
