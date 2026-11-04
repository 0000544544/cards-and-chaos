--!strict
--[[
    SOVEREIGN: CARDS & DOMINION - CLIENT PRINCIPAL
    Point d'entrée côté joueur : initialise l'interface utilisateur (HUD, Codex, Gacha, Marché, Arène),
    le contrôleur de combat réactif (clavier/mobile) et la détection des autels interactifs.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIManager = require(script.ui.UIManager)
local CombatController = require(script.CombatController)
local InteractionController = require(script.InteractionController)

print("========================================================")
print("  SOVEREIGN: CARDS & DOMINION (ROBLOX CLIENT)")
print("  Initialisation du client...")
print("========================================================")

-- Initialisation de l'interface graphique procédurale
UIManager.Init()

-- Initialisation des contrôles de combat (1-4 compétences, Q Dash, F Parry)
CombatController.Init()

-- Initialisation des interactions physiques avec les autels du Hub
InteractionController.Init(function(tabName: string)
    UIManager.OpenTab(tabName)
end)

print("[Client] Prêt au combat ! Utilisez les touches 1 à 4 pour vos cartes, Q pour esquiver et F pour parer.")
