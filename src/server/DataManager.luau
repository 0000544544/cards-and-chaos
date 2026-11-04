--!strict
--[[
    CARDS & CHAOS - GESTIONNAIRE UNIQUE DU PROFIL & DE L'INVENTAIRE (SERVEUR)
    Persistance des données, profil starter obligatoire (2500 Or + 4 Sorts équipés),
    mérite/classement et sécurité serveur.
]]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local CardsDatabase = require(game.ReplicatedStorage.Shared.CardsDatabase)

local DATASTORE_NAME = "CardsAndChaos_Core_V2"
local AUTOSAVE_INTERVAL_SEC = 60

export type CardItem = {
    UUID: string,
    CardId: string,
    Name: string,
    Rarity: string,
    SpellType: string,
    BasePower: number,
    Cooldown: number,
    Level: number,
    AcquiredAt: number,
}

export type PlayerProfile = {
    UserId: number,
    Coins: number,
    Merit: number,           -- Elo / Mérite (démarrage à 1000)
    Rank: string,            -- Bronze, Argent, Or, Souverain
    Inventory: { CardItem },
    EquippedDeck: { string },-- [1] = pyro_meteor, [2] = void_chain, [3] = thunder_step, [4] = sovereign_aegis
    ClaimedRewards: { [string]: boolean },
    Stats: {
        PacksOpened: number,
        DuelsWon: number,
        DuelsLost: number,
        WinStreak: number,
    },
}

local DataManager = {}
local Profiles: { [Player]: PlayerProfile } = {}
local DataStoreInstance: DataStore? = nil

-- Initialisation du DataStore avec fallback mémoire pour Studio
local function InitDataStore()
    local success, store = pcall(function()
        return DataStoreService:GetDataStore(DATASTORE_NAME)
    end)
    if success and store then
        DataStoreInstance = store
        print("[DataManager] DataStore connecté : " .. DATASTORE_NAME)
    else
        warn("[DataManager] DataStore indisponible (Mode Studio/Offline). Utilisation du cache mémoire.")
    end
end

-- Création d'une instance de carte
function DataManager.CreateCardItem(cardId: string): CardItem?
    local def = CardsDatabase.GetCard(cardId)
    if not def then return nil end

    return {
        UUID = HttpService:GenerateGUID(false),
        CardId = def.Id,
        Name = def.Name,
        Rarity = def.Rarity,
        SpellType = def.SpellType,
        BasePower = def.BasePower,
        Cooldown = def.Cooldown,
        Level = 1,
        AcquiredAt = os.time(),
    }
end

-- Calcul du rang selon le Mérite
function DataManager.GetRankFromMerit(merit: number): string
    if merit >= 2000 then
        return "Souverain"
    elseif merit >= 1500 then
        return "Or"
    elseif merit >= 1200 then
        return "Argent"
    else
        return "Bronze"
    end
end

-- Création du Starter Pack garanti (2500 Or + 4 Sorts équipés)
local function CreateStarterProfile(userId: number): PlayerProfile
    local starterCards = {
        DataManager.CreateCardItem("pyro_meteor")!,
        DataManager.CreateCardItem("void_chain")!,
        DataManager.CreateCardItem("thunder_step")!,
        DataManager.CreateCardItem("sovereign_aegis")!,
        DataManager.CreateCardItem("blade_flurry")!,
        DataManager.CreateCardItem("crimson_slash")!,
    }

    return {
        UserId = userId,
        Coins = 2500,       -- 2500 Or offerts pour tester immédiatement les tirages et le marché !
        Merit = 1000,       -- 1000 Elo de base
        Rank = "Bronze",
        Inventory = starterCards,
        EquippedDeck = { "pyro_meteor", "void_chain", "thunder_step", "sovereign_aegis" },
        ClaimedRewards = {},
        Stats = {
            PacksOpened = 0,
            DuelsWon = 0,
            DuelsLost = 0,
            WinStreak = 0,
        },
    }
end

function DataManager.LoadProfile(player: Player): PlayerProfile
    local key = "Player_" .. player.UserId
    local profile: PlayerProfile? = nil

    if DataStoreInstance then
        local success, data = pcall(function()
            return DataStoreInstance:GetAsync(key)
        end)
        if success and data and type(data) == "table" then
            profile = data :: PlayerProfile
        end
    end

    -- Si nouveau joueur OU joueur ayant un profil vide/cassé (0 Or et 0 carte), on injecte le Starter Pack !
    if not profile or (profile.Coins == 0 and #profile.Inventory == 0) or not profile.EquippedDeck or #profile.EquippedDeck == 0 then
        profile = CreateStarterProfile(player.UserId)
    end

    -- Vérification de sécurité : s'assurer que les 4 slots sont toujours équipés
    if #profile.EquippedDeck < 4 then
        profile.EquippedDeck = { "pyro_meteor", "void_chain", "thunder_step", "sovereign_aegis" }
    end
    if profile.Coins < 1000 then
        profile.Coins = 2500
    end

    profile.Rank = DataManager.GetRankFromMerit(profile.Merit)
    Profiles[player] = profile

    print("[DataManager] Profil chargé pour " .. player.Name .. " | Or: " .. profile.Coins .. " | Mérite: " .. profile.Merit)
    return profile
end

function DataManager.SaveProfile(player: Player): boolean
    local profile = Profiles[player]
    if not profile then return false end
    if not DataStoreInstance then return true end

    local key = "Player_" .. player.UserId
    local success, err = pcall(function()
        DataStoreInstance:SetAsync(key, profile)
    end)
    if not success then
        warn("[DataManager] Erreur de sauvegarde pour " .. player.Name .. " : " .. tostring(err))
        return false
    end
    return true
end

function DataManager.ReleaseProfile(player: Player)
    DataManager.SaveProfile(player)
    Profiles[player] = nil
end

function DataManager.GetProfile(player: Player): PlayerProfile?
    return Profiles[player]
end

function DataManager.AddCoins(player: Player, amount: number)
    local prof = Profiles[player]
    if prof and amount > 0 then
        prof.Coins += math.floor(amount)
    end
end

function DataManager.DeductCoins(player: Player, amount: number): boolean
    local prof = Profiles[player]
    if not prof then return false end
    amount = math.floor(amount)
    if amount < 0 or prof.Coins < amount then
        return false
    end
    prof.Coins -= amount
    return true
end

function DataManager.AddCard(player: Player, cardId: string): CardItem?
    local prof = Profiles[player]
    if not prof then return nil end

    local item = DataManager.CreateCardItem(cardId)
    if item then
        table.insert(prof.Inventory, item)
    end
    return item
end

function DataManager.EquipCard(player: Player, cardId: string, slotIndex: number): boolean
    local prof = Profiles[player]
    if not prof or slotIndex < 1 or slotIndex > 4 then return false end

    -- Vérifie la possession
    local owns = false
    for _, c in ipairs(prof.Inventory) do
        if c.CardId == cardId then
            owns = true
            break
        end
    end
    if not owns then return false end

    prof.EquippedDeck[slotIndex] = cardId
    return true
end

function DataManager.AddMerit(player: Player, amount: number)
    local prof = Profiles[player]
    if prof then
        prof.Merit = math.max(0, prof.Merit + math.floor(amount))
        prof.Rank = DataManager.GetRankFromMerit(prof.Merit)
    end
end

function DataManager.Init()
    InitDataStore()

    task.spawn(function()
        while true do
            task.wait(AUTOSAVE_INTERVAL_SEC)
            for _, p in ipairs(Players:GetPlayers()) do
                DataManager.SaveProfile(p)
            end
        end
    end)
end

return DataManager
