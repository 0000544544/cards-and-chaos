--!strict
--[[
    SOVEREIGN: CARDS & DOMINION - SERVEUR PRINCIPAL
    Point d'entrée du serveur : initialise le réseau RPC, l'environnement 3D procédural,
    la persistance des données et l'ensemble des sous-systèmes de jeu.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Shared.NetworkEvents)
local DataManager = require(script.DataManager)
local PlayerInventoryManager = require(script.PlayerInventoryManager)
local GachaSystem = require(script.GachaSystem)
local MapBuilder = require(script.MapBuilder)
local GachaManager = require(script.GachaManager)
local MarketManager = require(script.MarketManager)
local TradeManager = require(script.TradeManager)
local ArenaManager = require(script.ArenaManager)
local CombatService = require(script.CombatService)
local MeritManager = require(script.MeritManager)

print("========================================================")
print("  CARDS & CHAOS - SERVEUR ROBLOX (LUAU)")
print("  Initialisation de l'infrastructure...")
print("========================================================")

-- 1. Initialisation de la couche réseau
Network.InitServer()

-- 2. Construction de la carte (Hub & Arène céleste)
MapBuilder.BuildEnvironment()

-- 3. Initialisation des gestionnaires centraux
PlayerInventoryManager.Init()
GachaSystem.Init()
DataManager.Init()
GachaManager.Init()
MarketManager.Init()
TradeManager.Init()
ArenaManager.Init()
CombatService.Init()
MeritManager.Init()

-- 3.5 Initialisation des Outils Développeur / Mode Test Studio
local CardUtils = require(ReplicatedStorage.Shared.CardUtils)
local devActionRF = Network.GetFunction("DevAction")
devActionRF.OnServerInvoke = function(player: Player, actionName: any)
    local profile = DataManager.GetProfile(player)
    if not profile then return { Success = false } end

    if actionName == "AddCoins" then
        profile.Coins += 5000
        return { Success = true, Message = "+5,000 Or ajoutés !" }
    elseif actionName == "AddMerit" then
        profile.Merit += 500
        return { Success = true, Message = "+500 Mérite ajoutés !" }
    elseif actionName == "GiveDivine" then
        local divineCard = CardUtils.CreateCardInstance("primordial_severance", true)!
        table.insert(profile.Inventory, divineCard)
        return { Success = true, Message = "✨ Carte Divine 'Fracture Primordiale' ajoutée à votre inventaire !" }
    elseif actionName == "StartBot" then
        ArenaManager.StartBotMatch(player)
        return { Success = true, Message = "Duel contre le Spectre du Champion lancé !" }
    end
    return { Success = false }
end

-- 4. Écouteurs de connexion des joueurs
Players.PlayerAdded:Connect(function(player: Player)
    print("[Server] Connexion de " .. player.Name .. " (ID: " .. player.UserId .. ")")
    local legacyProfile = DataManager.LoadData(player)
    local chaosProfile = PlayerInventoryManager.LoadProfile(player)

    player.CharacterAdded:Connect(function(character: Model)
        local hum = character:WaitForChild("Humanoid") :: Humanoid
        hum.MaxHealth = 100
        hum.Health = 100

        -- Application des bonus passifs équipés (PV max, vitesse)
        for _, passUid in ipairs(legacyProfile.EquippedDeck.Passives) do
            for _, card in ipairs(legacyProfile.Inventory) do
                if card.UniqueId == passUid then
                    if card.CardId == "vitality_surge" then
                        hum.MaxHealth += 50
                        hum.Health = hum.MaxHealth
                    elseif card.CardId == "swift_reflexes" then
                        hum.WalkSpeed = 20
                    end
                end
            end
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player: Player)
    print("[Server] Déconnexion de " .. player.Name)
    DataManager.ReleaseProfile(player)
    PlayerInventoryManager.ReleaseProfile(player)
end)

game:BindToClose(function()
    print("[Server] Arrêt du serveur : sauvegarde d'urgence de tous les profils...")
    for _, player in ipairs(Players:GetPlayers()) do
        DataManager.SaveData(player)
        PlayerInventoryManager.SaveProfile(player)
    end
end)

print("[Server] Serveur prêt ! Toutes les boucles de jeu sont actives.")
