--!strict
--[[
    STOP AT THE FRAME - GARAGE SERVICE (SERVICE MODULE)
    Gère le Showroom du Garage et la génération de cash passif :
    - Chaque véhicule exposé dans le hangar rapporte du Cash en continu ($ / sec).
    - Plus le véhicule est rare et prestigieux, plus le rendement passif est élevé.
    - Synchronise les gains avec DataManager et les leaderstats du joueur.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataManager = require(script.Parent.DataManager)
local CarBuilder = require(ReplicatedStorage:WaitForChild("CarBuilder") :: ModuleScript)

local GarageService = {}

-- Rendement passif ($ / seconde) selon la rareté du véhicule
local PASSIVE_RATES: { [string]: number } = {
    lotus_rally        = 2,   -- Tier 1
    cyber_truck        = 5,   -- Tier 2
    drift_supra        = 12,  -- Tier 3
    police_interceptor = 25,  -- Tier 4
    hyperion_jetcar    = 60,  -- Tier 5
    flash_mcqueen      = 150, -- Tier 6 (Légendaire / Piston Cup)
}

-- Événements réseau pour le Garage
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes") :: Folder?
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

local garageUpdateEvent = remotesFolder:FindFirstChild("GaragePassiveTick") :: RemoteEvent?
if not garageUpdateEvent then
    garageUpdateEvent = Instance.new("RemoteEvent")
    garageUpdateEvent.Name = "GaragePassiveTick"
    garageUpdateEvent.Parent = remotesFolder
end

function GarageService.GetPassiveRateForVehicle(vehicleId: string): number
    return PASSIVE_RATES[vehicleId] or 2
end

function GarageService.CalculateTotalIncomePerSecond(player: Player): number
    local data = DataManager.GetData(player)
    if not data then return 0 end

    local totalRate = 0
    for _, vId in pairs(data.Showroom) do
        totalRate += GarageService.GetPassiveRateForVehicle(vId)
    end
    return totalRate
end

-- Boucle de génération de revenu passif (Toutes les 2 secondes)
local TICK_INTERVAL = 2.0
task.spawn(function()
    while true do
        task.wait(TICK_INTERVAL)
        for _, player in ipairs(Players:GetPlayers()) do
            local incomeRate = GarageService.CalculateTotalIncomePerSecond(player)
            if incomeRate > 0 then
                local gained = math.floor(incomeRate * TICK_INTERVAL)
                DataManager.AddCash(player, gained)
                if garageUpdateEvent then
                    garageUpdateEvent:FireClient(player, gained, incomeRate)
                end
            end
        end
    end
end)

return GarageService
