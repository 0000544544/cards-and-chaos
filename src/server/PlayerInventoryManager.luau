--!strict
--[[
    CARDS & CHAOS - GESTIONNAIRE CENTRAL DES PROFILS & INVENTAIRES (SERVEUR)
    Stockage sécurisé 100% côté serveur : Or, Mérite (Elo), Inventaire de cartes/skills,
    deck équipé (3 à 5 cartes), DataStore persistant, et connecteur optionnel Supabase.
]]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CardsDatabase = require(game.ReplicatedStorage.Shared.CardsDatabase)

local DATASTORE_NAME = "CardsAndChaos_V1"
local AUTOSAVE_INTERVAL_SEC = 60

-- =============================================================================
-- CONFIGURATION SUPABASE (JOURNALISATION DES TRANSACTIONS & GROS ÉCHANGES)
-- =============================================================================
local SupabaseConfig = {
    Enabled = false, -- Activez à true dès que vous renseignez vos clés Supabase
    Url = "",        -- Ex: "https://xyzcompany.supabase.co"
    ApiKey = "",     -- Clé anon / service_role
    TableLogs = "game_transactions_audit",
}

-- =============================================================================
-- STRUCTURE D'UNE CARTE DANS L'INVENTAIRE DU JOUEUR
-- =============================================================================
export type CardInstance = {
    UUID: string,                         -- Identifiant unique (HttpService:GenerateGUID)
    CardId: string,                       -- Référence vers CardsDatabase
    Name: string,
    Rarity: CardsDatabase.CardRarity,
    Type: CardsDatabase.CardType,
    Level: number,                        -- Niveau de la carte (démarrage au Niv 1)
    BasePower: number,                    -- Force réelle mise à l'échelle
    AssetId: string,                      -- Illustration Decal ComfyUI
    Cooldown: number,
    AcquiredAt: number,                   -- Timestamp de création
    IsLocked: boolean,                    -- Verrouillé pour éviter la vente/suppression accidentelle
}

-- =============================================================================
-- STRUCTURE COMPLÈTE DU PROFIL JOUEUR
-- =============================================================================
export type PlayerProfile = {
    UserId: number,
    Coins: number,                        -- Monnaie principale pour les packs et le marché
    MeritPoints: number,                  -- Points de classement compétitif (Elo)
    RankTitle: string,                    -- Bronze, Argent, Or, Légende
    Inventory: { CardInstance },          -- Liste de toutes les cartes possédées
    EquippedDeck: { string },             -- UUIDs des 3 à 5 cartes équipées en combat
    PityCounter: {
        SinceLastLegendary: number,
        SinceLastEpic: number,
    },
    Stats: {
        PacksOpened: number,
        DuelsWon: number,
        DuelsLost: number,
        WinStreak: number,
        MarketSales: number,
    },
    SessionLock: number,                  -- Prévention des courses d'écriture (Race Conditions)
}

local PlayerInventoryManager = {}
local ActiveProfiles: { [Player]: PlayerProfile } = {}
local DataStoreInstance: DataStore? = nil

-- Initialisation sécurisée du DataStore
local function InitDataStore()
    local success, store = pcall(function()
        return DataStoreService:GetDataStore(DATASTORE_NAME)
    end)
    if success and store then
        DataStoreInstance = store
        print("[PlayerInventoryManager] DataStore connecté : " .. DATASTORE_NAME)
    else
        warn("[PlayerInventoryManager] DataStore indisponible (Mode Studio/Hors-ligne). Utilisation du cache mémoire.")
    end
end

-- =============================================================================
-- USINE DE GÉNÉRATION D'UNE NOUVELLE CARTE (INSTANCE UNIQUE)
-- =============================================================================
function PlayerInventoryManager.CreateCardInstance(cardId: string, customLevel: number?): CardInstance?
    local blueprint = CardsDatabase.GetCard(cardId)
    if not blueprint then
        warn("[PlayerInventoryManager] Tentative de création d'une carte inexistante : " .. tostring(cardId))
        return nil
    end

    local lvl = customLevel or 1
    local levelMultiplier = 1 + (lvl - 1) * 0.1 -- +10% de puissance par niveau

    local instance: CardInstance = {
        UUID = HttpService:GenerateGUID(false),
        CardId = blueprint.CardId,
        Name = blueprint.Name,
        Rarity = blueprint.Rarity,
        Type = blueprint.Type,
        Level = lvl,
        BasePower = math.round(blueprint.BasePower * levelMultiplier),
        AssetId = blueprint.AssetId,
        Cooldown = blueprint.Cooldown,
        AcquiredAt = os.time(),
        IsLocked = false,
    }

    return instance
end

-- =============================================================================
-- PROFIL PAR DÉFAUT (NOUVEAU JOUEUR)
-- =============================================================================
local function CreateDefaultProfile(userId: number): PlayerProfile
    -- Offre 3 cartes de base équilibrées pour commencer immédiatement à jouer
    local starter1 = PlayerInventoryManager.CreateCardInstance("strike_of_iron")!
    local starter2 = PlayerInventoryManager.CreateCardInstance("wooden_parry")!
    local starter3 = PlayerInventoryManager.CreateCardInstance("inner_focus")!

    return {
        UserId = userId,
        Coins = 1000,              -- 10 tirages de bienvenue offerts !
        MeritPoints = 1000,        -- Classement initial Bronze / Argent
        RankTitle = "Bronze",
        Inventory = { starter1, starter2, starter3 },
        EquippedDeck = { starter1.UUID, starter2.UUID, starter3.UUID },
        PityCounter = {
            SinceLastLegendary = 0,
            SinceLastEpic = 0,
        },
        Stats = {
            PacksOpened = 0,
            DuelsWon = 0,
            DuelsLost = 0,
            WinStreak = 0,
            MarketSales = 0,
        },
        SessionLock = os.time(),
    }
end

-- =============================================================================
-- HOOK SUPABASE ASYNCHRONE (NON-BLOQUANT)
-- =============================================================================
local function PushAuditToSupabase(player: Player, eventType: string, payload: { [string]: any })
    if not SupabaseConfig.Enabled or SupabaseConfig.Url == "" then return end

    task.spawn(function()
        local url = SupabaseConfig.Url .. "/rest/v1/" .. SupabaseConfig.TableLogs
        local bodyData = {
            user_id = player.UserId,
            username = player.Name,
            event_type = eventType,
            details = payload,
            created_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }

        local jsonBody = HttpService:JSONEncode(bodyData)
        local success, response = pcall(function()
            return HttpService:RequestAsync({
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["apikey"] = SupabaseConfig.ApiKey,
                    ["Authorization"] = "Bearer " .. SupabaseConfig.ApiKey,
                    ["Prefer"] = "return=minimal",
                },
                Body = jsonBody,
            })
        end)

        if not success then
            warn("[Supabase Hook] Échec d'envoi du log d'audit : " .. tostring(response))
        end
    end)
end

-- =============================================================================
-- CHARGEMENT & SAUVEGARDE DU PROFIL
-- =============================================================================
function PlayerInventoryManager.LoadProfile(player: Player): PlayerProfile
    local key = "PlayerProfile_" .. player.UserId
    local profile: PlayerProfile? = nil

    if DataStoreInstance then
        local attempts = 0
        local maxAttempts = 3
        while attempts < maxAttempts and not profile do
            attempts += 1
            local success, data = pcall(function()
                return DataStoreInstance:GetAsync(key)
            end)
            if success and data and type(data) == "table" then
                profile = data :: PlayerProfile
            elseif not success then
                warn("[PlayerInventoryManager] Tentative de lecture " .. attempts .. " échouée pour " .. player.Name)
                task.wait(1)
            end
        end
    end

    if not profile then
        profile = CreateDefaultProfile(player.UserId)
    end

    profile.SessionLock = os.time()
    ActiveProfiles[player] = profile
    return profile
end

function PlayerInventoryManager.SaveProfile(player: Player): boolean
    local profile = ActiveProfiles[player]
    if not profile then return false end
    if not DataStoreInstance then return true end

    local key = "PlayerProfile_" .. player.UserId
    local success, err = pcall(function()
        DataStoreInstance:SetAsync(key, profile)
    end)

    if not success then
        warn("[PlayerInventoryManager] Erreur de sauvegarde critique pour " .. player.Name .. " : " .. tostring(err))
        return false
    end
    return true
end

function PlayerInventoryManager.ReleaseProfile(player: Player)
    PlayerInventoryManager.SaveProfile(player)
    ActiveProfiles[player] = nil
end

-- =============================================================================
-- GETTERS & MÉTHODES DE SÉCURITÉ SERVEUR
-- =============================================================================
function PlayerInventoryManager.GetProfile(player: Player): PlayerProfile?
    return ActiveProfiles[player]
end

function PlayerInventoryManager.GetCoins(player: Player): number
    local prof = ActiveProfiles[player]
    return prof and prof.Coins or 0
end

function PlayerInventoryManager.GetMerit(player: Player): number
    local prof = ActiveProfiles[player]
    return prof and prof.MeritPoints or 0
end

function PlayerInventoryManager.AddCoins(player: Player, amount: number)
    local prof = ActiveProfiles[player]
    if prof and amount > 0 then
        prof.Coins += math.floor(amount)
    end
end

function PlayerInventoryManager.DeductCoins(player: Player, amount: number): boolean
    local prof = ActiveProfiles[player]
    if not prof then return false end

    amount = math.floor(amount)
    if amount < 0 or prof.Coins < amount then
        return false
    end

    prof.Coins -= amount
    return true
end

function PlayerInventoryManager.AddCard(player: Player, cardInstance: CardInstance): boolean
    local prof = ActiveProfiles[player]
    if not prof then return false end

    table.insert(prof.Inventory, cardInstance)

    -- Si la carte tirée est Légendaire, trace d'audit Supabase
    if cardInstance.Rarity == "Legendary" then
        PushAuditToSupabase(player, "LEGENDARY_OBTAINED", {
            card_uuid = cardInstance.UUID,
            card_id = cardInstance.CardId,
            card_name = cardInstance.Name,
            power = cardInstance.BasePower,
        })
    end

    return true
end

function PlayerInventoryManager.RemoveCardByUUID(player: Player, cardUUID: string): CardInstance?
    local prof = ActiveProfiles[player]
    if not prof then return nil end

    for idx, card in ipairs(prof.Inventory) do
        if card.UUID == cardUUID then
            -- Vérifie que la carte n'est pas équipée
            for _, eqUid in ipairs(prof.EquippedDeck) do
                if eqUid == cardUUID then
                    return nil -- Interdit de retirer une carte équipée
                end
            end
            return table.remove(prof.Inventory, idx)
        end
    end
    return nil
end

function PlayerInventoryManager.EquipDeck(player: Player, cardUUIDs: { string }): { Success: boolean, Error: string? }
    local prof = ActiveProfiles[player]
    if not prof then return { Success = false, Error = "Profil non chargé." } end

    if #cardUUIDs < 3 or #cardUUIDs > 5 then
        return { Success = false, Error = "Le Deck de combat doit contenir entre 3 et 5 cartes." }
    end

    -- Vérification stricte que chaque UUID appartient bien au joueur
    local function HasCard(uid: string): boolean
        for _, c in ipairs(prof.Inventory) do
            if c.UUID == uid then return true end
        end
        return false
    end

    for _, uid in ipairs(cardUUIDs) do
        if not HasCard(uid) then
            return { Success = false, Error = "Tentative d'équiper une carte que vous ne possédez pas." }
        end
    end

    prof.EquippedDeck = cardUUIDs
    return { Success = true }
end

-- =============================================================================
-- INITIALISATION DU SERVICE
-- =============================================================================
function PlayerInventoryManager.Init()
    InitDataStore()

    -- Boucle d'autosauvegarde
    task.spawn(function()
        while true do
            task.wait(AUTOSAVE_INTERVAL_SEC)
            for _, p in ipairs(Players:GetPlayers()) do
                PlayerInventoryManager.SaveProfile(p)
            end
        end
    end)
end

return PlayerInventoryManager
