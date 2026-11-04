--!strict
--[[
    DATA MANAGER (PROFILES & DATASTORE)
    Sauvegarde persistante des profils joueurs : Cartes, Decks, Monnaie, Mérite, Élo, et Compteurs de Pity.
    Fallback mémoire automatique en local (Studio) si les API DataStore ne sont pas activées.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local CardUtils = require(game.ReplicatedStorage.Shared.CardUtils)
local RankConfig = require(game.ReplicatedStorage.Shared.RankConfig)

local DATA_VERSION = "Sovereign_V1"
local AUTOSAVE_INTERVAL = 60

export type PlayerProfile = {
    Coins: number,
    SoulGems: number,
    Merit: number,
    Elo: number,
    Rank: string,
    Inventory: { CardUtils.CardInstance },
    EquippedDeck: {
        Actives: { string },   -- UniqueIds
        Passives: { string },
    },
    PityCounters: {
        SinceLastEpic: number,
        SinceLastLegendary: number,
        SinceLastMythic: number,
    },
    Stats: {
        TotalRolls: number,
        Wins: number,
        Losses: number,
        CurrentStreak: number,
        BestStreak: number,
        CardsTraded: number,
        MarketSales: number,
    },
}

local DataManager = {}
local Profiles: { [Player]: PlayerProfile } = {}
local SessionStore: DataStore? = nil

-- Initialisation sécurisée du DataStore
local function InitDataStore()
    local success, store = pcall(function()
        return DataStoreService:GetDataStore(DATA_VERSION)
    end)
    if success and store then
        SessionStore = store
    else
        warn("[DataManager] DataStore indisponible (Mode Studio/Offline). Utilisation de la mémoire vive.")
    end
end

-- Création d'un profil par défaut pour les nouveaux joueurs (Deck de départ équilibré)
local function CreateDefaultProfile(): PlayerProfile
    local starterCards = {
        CardUtils.CreateCardInstance("iron_slash")!,
        CardUtils.CreateCardInstance("shadow_step")!,
        CardUtils.CreateCardInstance("flame_bolt")!,
        CardUtils.CreateCardInstance("ice_shard")!,
        CardUtils.CreateCardInstance("vitality_surge")!,
        CardUtils.CreateCardInstance("swift_reflexes")!,
    }

    local defaultDeck = {
        Actives = {
            starterCards[1].UniqueId,
            starterCards[2].UniqueId,
            starterCards[3].UniqueId,
            starterCards[4].UniqueId,
        },
        Passives = {
            starterCards[5].UniqueId,
            starterCards[6].UniqueId,
        },
    }

    return {
        Coins = 1000,         -- 10 rolls gratuits offerts au départ !
        SoulGems = 50,
        Merit = 100,          -- Prime de bienvenue martiale
        Elo = 1000,           -- Cote de base Argent
        Rank = "Silver",
        Inventory = starterCards,
        EquippedDeck = defaultDeck,
        PityCounters = {
            SinceLastEpic = 0,
            SinceLastLegendary = 0,
            SinceLastMythic = 0,
        },
        Stats = {
            TotalRolls = 0,
            Wins = 0,
            Losses = 0,
            CurrentStreak = 0,
            BestStreak = 0,
            CardsTraded = 0,
            MarketSales = 0,
        },
    }
end

function DataManager.GetProfile(player: Player): PlayerProfile?
    return Profiles[player]
end

function DataManager.LoadData(player: Player): PlayerProfile
    local key = "Player_" .. player.UserId
    local profile: PlayerProfile? = nil

    if SessionStore then
        local success, result = pcall(function()
            return SessionStore:GetAsync(key)
        end)
        if success and result and type(result) == "table" then
            profile = result :: PlayerProfile
        end
    end

    if not profile then
        profile = CreateDefaultProfile()
    end

    -- Mise à jour du rang en fonction de l'Elo
    profile.Rank = RankConfig.GetTierFromElo(profile.Elo).Name
    Profiles[player] = profile
    return profile
end

function DataManager.SaveData(player: Player): boolean
    local profile = Profiles[player]
    if not profile then return false end
    if not SessionStore then return true end

    local key = "Player_" .. player.UserId
    local success, err = pcall(function()
        SessionStore:SetAsync(key, profile)
    end)
    if not success then
        warn("[DataManager] Erreur de sauvegarde pour " .. player.Name .. ": " .. tostring(err))
        return false
    end
    return true
end

function DataManager.ReleaseProfile(player: Player)
    DataManager.SaveData(player)
    Profiles[player] = nil
end

function DataManager.AddCoins(player: Player, amount: number)
    local profile = Profiles[player]
    if profile then
        profile.Coins = math.max(0, profile.Coins + amount)
    end
end

function DataManager.AddMerit(player: Player, amount: number)
    local profile = Profiles[player]
    if profile then
        profile.Merit = math.max(0, profile.Merit + amount)
    end
end

-- Démarrage de la boucle d'autosauvegarde
function DataManager.Init()
    InitDataStore()

    task.spawn(function()
        while true do
            task.wait(AUTOSAVE_INTERVAL)
            for _, player in ipairs(Players:GetPlayers()) do
                DataManager.SaveData(player)
            end
        end
    end)
end

return DataManager
