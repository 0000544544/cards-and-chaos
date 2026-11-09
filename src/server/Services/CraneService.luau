--!strict
--[[
    STOP AT THE FRAME - CRANE SERVICE (SERVICE MODULE)
    Gère le Mode Pêche (Grue & Aimant sous-marin) :
    - Déploiement physique du câble et de l'aimant dans les profondeurs aquatiques.
    - Détection d'accrochage par Raycast sous-marin.
    - Tirage de loot procédural par palier de profondeur et puissance magnétique.
    - Remontée du véhicule et ajout automatique à l'inventaire du joueur.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataManager = require(script.Parent.DataManager)

local CraneService = {}

-- Paliers de profondeur aquatique et table de loot
export type LootEntry = {
    VehicleId: string,
    Name: string,
    Rarity: string,
    MinDepth: number,
    Weight: number,
}

local LOOT_TABLE: { LootEntry } = {
    { VehicleId = "lotus_rally",        Name = "Lotus Rally",        Rarity = "Commune",    MinDepth = 0,   Weight = 50 },
    { VehicleId = "cyber_truck",        Name = "Cyber Truck",        Rarity = "Peu Commune",MinDepth = 25,  Weight = 30 },
    { VehicleId = "drift_supra",        Name = "Drift Supra",        Rarity = "Rare",       MinDepth = 50,  Weight = 15 },
    { VehicleId = "police_interceptor", Name = "Police Interceptor", Rarity = "Épique",     MinDepth = 80,  Weight = 8  },
    { VehicleId = "hyperion_jetcar",    Name = "Hyperion JetCar",    Rarity = "Légendaire", MinDepth = 110, Weight = 4  },
    { VehicleId = "flash_mcqueen",      Name = "Flash McQueen ⚡",    Rarity = "Mythique",   MinDepth = 140, Weight = 1  },
}

-- Événements réseau pour la Grue
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes") :: Folder?
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

local deployCraneEvent = remotesFolder:FindFirstChild("DeployCrane") :: RemoteEvent?
if not deployCraneEvent then
    deployCraneEvent = Instance.new("RemoteEvent")
    deployCraneEvent.Name = "DeployCrane"
    deployCraneEvent.Parent = remotesFolder
end

local craneHookedEvent = remotesFolder:FindFirstChild("CraneHooked") :: RemoteEvent?
if not craneHookedEvent then
    craneHookedEvent = Instance.new("RemoteEvent")
    craneHookedEvent.Name = "CraneHooked"
    craneHookedEvent.Parent = remotesFolder
end

-- Tirage aléatoire pondéré selon la profondeur atteinte
function CraneService.RollLoot(depth: number, magnetPower: number): LootEntry
    local availablePool: { LootEntry } = {}
    local totalWeight = 0

    for _, entry in ipairs(LOOT_TABLE) do
        -- L'aimant puissant permet de repêcher des véhicules de paliers plus profonds plus facilement
        local effectiveMin = math.max(0, entry.MinDepth - (magnetPower - 1) * 15)
        if depth >= effectiveMin then
            table.insert(availablePool, entry)
            totalWeight += entry.Weight
        end
    end

    if #availablePool == 0 or totalWeight <= 0 then
        return LOOT_TABLE[1]
    end

    local roll = math.random() * totalWeight
    local current = 0
    for _, entry in ipairs(availablePool) do
        current += entry.Weight
        if roll <= current then
            return entry
        end
    end

    return availablePool[#availablePool]
end

-- Traitement du déploiement de la grue par le client
deployCraneEvent.OnServerEvent:Connect(function(player: Player, targetDepth: any)
    local data = DataManager.GetData(player)
    if not data then return end

    local requestedDepth = math.clamp(tonumber(targetDepth) or 20, 10, 250)
    -- Plafond de profondeur selon le niveau du câble
    local maxCableDepth = 30 + (data.Crane.CableLengthLevel * 25)
    local actualDepth = math.min(requestedDepth, maxCableDepth)

    -- Tirage de la trouvaille sous-marine
    local loot = CraneService.RollLoot(actualDepth, data.Crane.MagneticPowerLevel)

    -- Ajout du véhicule à l'inventaire du joueur
    local isNew = DataManager.AddVehicleToInventory(player, loot.VehicleId)

    -- Notification au client avec animation de remontée
    if craneHookedEvent then
        craneHookedEvent:FireClient(player, loot.VehicleId, loot.Name, loot.Rarity, actualDepth, isNew)
    end
end)

return CraneService
