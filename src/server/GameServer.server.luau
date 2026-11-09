--!strict
--[[
    STOP AT THE FRAME - GAME SERVER (SERVER SCRIPT)
    Gère l'économie, les leaderstats (Cash $, Streak 🔥, Titre),
    les récompenses de saut et l'initialisation des Services (DataManager, Garage, Grue).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarBuilder = require(ReplicatedStorage:WaitForChild("CarBuilder") :: ModuleScript)

-- Services Serveur
local DataManager = require(script.Parent.Services.DataManager)
local GarageService = require(script.Parent.Services.GarageService)
local CraneService = require(script.Parent.Services.CraneService)

-- 1. Configuration des dossiers réseau
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes") :: Folder?
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

local submitEvent = remotesFolder:FindFirstChild("SubmitStopResult") :: RemoteEvent?
if not submitEvent then
    submitEvent = Instance.new("RemoteEvent")
    submitEvent.Name = "SubmitStopResult"
    submitEvent.Parent = remotesFolder
end

-- 2. Configuration des leaderstats et données du joueur
local function calculateTitle(streak: number, framePerfects: number): string
    if framePerfects >= 10 then
        return "240Hz Stopper God"
    elseif framePerfects >= 3 then
        return "Frame 1 Demon"
    elseif streak >= 10 or framePerfects >= 1 then
        return "Œil Bionique"
    elseif streak >= 3 then
        return "Chasseur de Frames"
    else
        return "Réflexes de Tortue"
    end
end

local function setupPlayer(player: Player)
    local data = DataManager.LoadData(player)

    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local cashVal = Instance.new("IntValue")
    cashVal.Name = "Cash"
    cashVal.Value = data.Cash
    cashVal.Parent = leaderstats

    local streakVal = Instance.new("IntValue")
    streakVal.Name = "Streak"
    streakVal.Value = data.Streak
    streakVal.Parent = leaderstats

    local titleVal = Instance.new("StringValue")
    titleVal.Name = "Title"
    titleVal.Value = data.Title
    titleVal.Parent = leaderstats

    local fpVal = Instance.new("IntValue")
    fpVal.Name = "TotalFramePerfects"
    fpVal.Value = data.TotalFramePerfects
    fpVal.Parent = player
end

Players.PlayerAdded:Connect(setupPlayer)
for _, p in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        setupPlayer(p)
    end)
end

-- 3. Traitement des résultats de saut soumis par le client
submitEvent.OnServerEvent:Connect(function(player: Player, vehicleId: any, grade: any, distance: any, accuracy: any)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end

    local cashVal = leaderstats:FindFirstChild("Cash") :: IntValue?
    local streakVal = leaderstats:FindFirstChild("Streak") :: IntValue?
    local titleVal = leaderstats:FindFirstChild("Title") :: StringValue?
    local fpVal = player:FindFirstChild("TotalFramePerfects") :: IntValue?

    if not cashVal or not streakVal or not titleVal or not fpVal then return end

    local vId = tostring(vehicleId or "lotus_rally")
    local vConfig = CarBuilder.GetVehicleConfig(vId)
    local gradeStr = tostring(grade or "RATÉ!")
    local baseReward = vConfig.RewardCash

    if gradeStr == "FRAME PERFECT!" then
        streakVal.Value += 1
        fpVal.Value += 1
        local reward = math.floor(baseReward + (streakVal.Value * 15))
        DataManager.AddCash(player, reward)

    elseif gradeStr == "PERFECT!" then
        streakVal.Value += 1
        local reward = math.floor(baseReward * 0.75 + (streakVal.Value * 8))
        DataManager.AddCash(player, reward)

    elseif gradeStr == "GOOD!" then
        streakVal.Value += 1
        local reward = math.floor(baseReward * 0.40)
        DataManager.AddCash(player, reward)

    else
        -- RATÉ : Réinitialisation du streak
        streakVal.Value = 0
    end

    -- Mise à jour automatique du titre honorifique
    local newTitle = calculateTitle(streakVal.Value, fpVal.Value)
    titleVal.Value = newTitle
end)

print("[GameServer] Services initialisés : DataManager, GarageService (Revenu passif), CraneService (Pêche).")
