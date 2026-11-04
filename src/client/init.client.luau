--!strict
--[[
    CARDS & CHAOS - INITIALISATION CLIENT
    Point d'entrée côté joueur : initialise le contrôleur de sorts (touches QWERTY/AZERTY & clic souris),
    l'interface graphique complète et les autels interactifs (touche E).
]]

local Players = game:GetService("Players")

local UIManager = require(script.ui.UIManager)
local CombatController = require(script.CombatController)
local InteractionController = require(script.InteractionController)

print("========================================================")
print("  CARDS & CHAOS - LANCEMENT DU CLIENT")
print("========================================================")

-- 1. Initialisation des contrôles de combat (Sorts 1-5, visée souris, AZERTY A/Z/E/R/F)
CombatController.Init()

-- 2. Initialisation de l'interface graphique (Hotbar, TopBar, et 5 fenêtres interactives)
UIManager.Init()

-- 3. Initialisation des interactions physiques avec les autels (touche E)
InteractionController.Init(function(tabName: string)
    UIManager.OpenTab(tabName)
end)

print("[Client] Prêt ! Lancez vos sorts avec 1-4 ou A/Z/E/R (ou clic souris sur la Hotbar).")
