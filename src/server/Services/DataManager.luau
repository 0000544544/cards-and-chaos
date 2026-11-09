--!strict
--[[
    STOP AT THE FRAME - DATA MANAGER (SERVICE MODULE)
    Gère la persistance DataStore des joueurs :
    - Économie (Cash $, Streak 🔥, Titre)
    - Inventaire de véhicules pêchés et débloqués
    - Showroom (Véhicules exposés générant du cash passif)
    - Améliorations de la Grue (Longueur de câble, Puissance aimant, Vitesse treuil)
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DataManager = {}

export type PlayerData = {
    Cash: number,
    Streak: number,
    TotalFramePerfects: number,
    Title: string,
    Inventory: { string }, -- Liste des IDs de véhicules possédés
    Showroom: { [number]: string }, -- SlotIndex -> VehicleId
    Crane: {
        CableLengthLevel: number,
        MagneticPowerLevel: number,
        WinchSpeedLevel: number,
    },
}

local DATA_VERSION = "SATF_V1_PlayerData"
local playerDataStore: DataStore? = nil

local success, ds = pcall(function()
    return DataStoreService:GetDataStore(DATA_VERSION)
end)
if success and ds then
    playerDataStore = ds
else
    warn("[DataManager] DataStore non disponible en mode hors-ligne Studio. Utilisation de la mémoire cache.")
end

local sessionCache: { [Player]: PlayerData } = {}

local DEFAULT_DATA: PlayerData = {
    Cash = 100,
    Streak = 0,
    TotalFramePerfects = 0,
    Title = "Réflexes de Tortue",
    Inventory = { "lotus_rally" },
    Showroom = { [1] = "lotus_rally" },
    Crane = {
        CableLengthLevel = 1,
        MagneticPowerLevel = 1,
        WinchSpeedLevel = 1,
    },
}

local function cloneDefaultData(): PlayerData
    local copy: PlayerData = {
        Cash = DEFAULT_DATA.Cash,
        Streak = DEFAULT_DATA.Streak,
        TotalFramePerfects = DEFAULT_DATA.TotalFramePerfects,
        Title = DEFAULT_DATA.Title,
        Inventory = {},
        Showroom = {},
        Crane = {
            CableLengthLevel = DEFAULT_DATA.Crane.CableLengthLevel,
            MagneticPowerLevel = DEFAULT_DATA.Crane.MagneticPowerLevel,
            WinchSpeedLevel = DEFAULT_DATA.Crane.WinchSpeedLevel,
        },
    }
    for _, id in ipairs(DEFAULT_DATA.Inventory) do
        table.insert(copy.Inventory, id)
    end
    for slot, id in pairs(DEFAULT_DATA.Showroom) do
        copy.Showroom[slot] = id
    end
    return copy
end

function DataManager.LoadData(player: Player): PlayerData
    if sessionCache[player] then
        return sessionCache[player]
    end

    local loadedData: PlayerData = cloneDefaultData()
    if playerDataStore then
        local key = "Player_" .. tostring(player.UserId)
        local ok, result = pcall(function()
            return playerDataStore:GetAsync(key)
        end)
        if ok and type(result) == "table" then
            if type(result.Cash) == "number" then loadedData.Cash = result.Cash end
            if type(result.Streak) == "number" then loadedData.Streak = result.Streak end
            if type(result.TotalFramePerfects) == "number" then loadedData.TotalFramePerfects = result.TotalFramePerfects end
            if type(result.Title) == "string" then loadedData.Title = result.Title end
            if type(result.Inventory) == "table" then loadedData.Inventory = result.Inventory end
            if type(result.Showroom) == "table" then loadedData.Showroom = result.Showroom end
            if type(result.Crane) == "table" then
                loadedData.Crane.CableLengthLevel = result.Crane.CableLengthLevel or 1
                loadedData.Crane.MagneticPowerLevel = result.Crane.MagneticPowerLevel or 1
                loadedData.Crane.WinchSpeedLevel = result.Crane.WinchSpeedLevel or 1
            end
        end
    end

    sessionCache[player] = loadedData
    return loadedData
end

function DataManager.SaveData(player: Player)
    local data = sessionCache[player]
    if not data or not playerDataStore then return end

    local key = "Player_" .. tostring(player.UserId)
    pcall(function()
        playerDataStore:SetAsync(key, data)
    end)
end

function DataManager.GetData(player: Player): PlayerData?
    return sessionCache[player]
end

function DataManager.AddCash(player: Player, amount: number)
    local data = sessionCache[player]
    if not data then return end
    data.Cash = math.max(0, data.Cash + amount)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local cashVal = leaderstats:FindFirstChild("Cash") :: IntValue?
        if cashVal then cashVal.Value = data.Cash end
    end
end

function DataManager.AddVehicleToInventory(player: Player, vehicleId: string): boolean
    local data = sessionCache[player]
    if not data then return false end
    for _, id in ipairs(data.Inventory) do
        if id == vehicleId then
            -- Doublon : compensation en cash
            DataManager.AddCash(player, 500)
            return false
        end
    end
    table.insert(data.Inventory, vehicleId)
    return true
end

function DataManager.UnloadPlayer(player: Player)
    DataManager.SaveData(player)
    sessionCache[player] = nil
end

Players.PlayerRemoving:Connect(function(player)
    DataManager.UnloadPlayer(player)
end)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        DataManager.SaveData(player)
    end
end)

return DataManager
