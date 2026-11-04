--!strict
--[[
    CARDS & CHAOS - INITIALISATION SERVEUR UNIQUE
    Bootstrap propre : Réseau RPC, Map 3D, Profils DataStore, Combat 3D, Gacha, Marché et Cloud Groq.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkEvents = require(ReplicatedStorage.Shared.NetworkEvents)
local DataManager = require(script.DataManager)
local CombatService = require(script.CombatService)
local GachaManager = require(script.GachaManager)
local MarketManager = require(script.MarketManager)
local ArenaManager = require(script.ArenaManager)
local MapBuilder = require(script.MapBuilder)
local CloudBridge = require(script.CloudBridge)

print("========================================================")
print("  CARDS & CHAOS - LANCEMENT DU SERVEUR ROBLOX (LUAU)")
print("========================================================")

-- 1. Initialisation du Réseau
NetworkEvents.InitServer()

-- 2. Construction de la carte 3D (ZÉRO cube jaune fluo, 3 mannequins d'entraînement réactifs)
MapBuilder.BuildEnvironment()

-- 3. Initialisation des Services Serveur
DataManager.Init()
CombatService.Init()
GachaManager.Init()
MarketManager.Init()
ArenaManager.Init()
CloudBridge.Init()

-- 4. Connexions des Joueurs
Players.PlayerAdded:Connect(function(player: Player)
    local prof = DataManager.LoadProfile(player)

    player.CharacterAdded:Connect(function(char: Model)
        local hum = char:WaitForChild("Humanoid") :: Humanoid
        hum.MaxHealth = 100
        hum.Health = 100
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        DataManager.LoadProfile(player)
    end)
end

Players.PlayerRemoving:Connect(function(player: Player)
    DataManager.ReleaseProfile(player)
end)

game:BindToClose(function()
    print("[Server] Arrêt du serveur : sauvegarde d'urgence de tous les profils...")
    for _, p in ipairs(Players:GetPlayers()) do
        DataManager.SaveProfile(p)
    end
end)

-- RemoteFunction pour synchroniser les données du joueur avec l'UI
local getProfRF = NetworkEvents.GetFunction("GetPlayerData")
getProfRF.OnServerInvoke = function(player: Player)
    return DataManager.GetProfile(player)
end

-- RemoteFunction pour équiper une carte dans un slot (1-4)
local equipRF = NetworkEvents.GetFunction("EquipCard")
equipRF.OnServerInvoke = function(player: Player, cardId: any, slotIdx: any)
    local slot = tonumber(slotIdx) or 1
    local success = DataManager.EquipCard(player, tostring(cardId), slot)
    return { Success = success, Profile = DataManager.GetProfile(player) }
end

print("[Server] Serveur CARDS & CHAOS prêt à 100% !")
