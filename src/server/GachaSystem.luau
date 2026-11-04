--!strict
--[[
    CARDS & CHAOS - SYSTÈME DE GACHA & PACK OPENING (SERVEUR)
    Tirage aléatoire pondéré conforme aux règles Roblox (transparence des taux),
    protection de Pity anti-malchance, déduction atomique de l'or et sécurité serveur.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardsDatabase = require(ReplicatedStorage.Shared.CardsDatabase)
local PackConfig = require(ReplicatedStorage.Shared.PackConfig)
local Network = require(ReplicatedStorage.Shared.NetworkEvents)
local PlayerInventoryManager = require(script.Parent.PlayerInventoryManager)

export type PackOpenResult = {
    Success: boolean,
    Card: PlayerInventoryManager.CardInstance?,
    RemainingCoins: number?,
    DisplayOdds: string?,
    Error: string?,
}

local GachaSystem = {}

-- =============================================================================
-- LOGIQUE MATHÉMATIQUE DE SÉLECTION DE RARETÉ PONDÉRÉE
-- =============================================================================
local function RollRarity(pack: PackConfig.PackDefinition, pity: { SinceLastLegendary: number, SinceLastEpic: number }): CardsDatabase.CardRarity
    -- 1. Vérification de la Pity Légendaire
    if pity.SinceLastLegendary >= PackConfig.Pity.MaxPacksWithoutLegendary then
        return "Legendary"
    end

    -- 2. Vérification de la Pity Épique
    if pity.SinceLastEpic >= PackConfig.Pity.MaxPacksWithoutEpic and pack.Weights["Epic"] and pack.Weights["Epic"] > 0 then
        return "Epic"
    end

    -- 3. Tirage aléatoire pondéré (Weighted Random)
    local totalWeight = 0
    for _, weight in pairs(pack.Weights) do
        totalWeight += weight
    end

    local roll = math.random(1, totalWeight)
    local cumulative = 0

    local tiersPriority: { CardsDatabase.CardRarity } = { "Legendary", "Epic", "Rare", "Common" }
    for _, tier in ipairs(tiersPriority) do
        local w = pack.Weights[tier] or 0
        cumulative += w
        if roll <= cumulative and w > 0 then
            return tier
        end
    end

    return "Common"
end

-- =============================================================================
-- TRAITEMENT DU TIRAGE D'UN PACK (APPEL DEPUIS LE CLIENT)
-- =============================================================================
function GachaSystem.OpenPack(player: Player, packId: string): PackOpenResult
    local profile = PlayerInventoryManager.GetProfile(player)
    if not profile then
        return { Success = false, Error = "Profil joueur introuvable." }
    end

    local pack = PackConfig.GetPack(packId)
    if not pack then
        return { Success = false, Error = "Ce type de paquet n'existe pas." }
    end

    -- 1. Vérification atomique des fonds côté serveur
    if profile.Coins < pack.CostCoins then
        return {
            Success = false,
            Error = "Or insuffisant. Requis : " .. pack.CostCoins .. " Or (Vous avez : " .. profile.Coins .. " Or).",
        }
    end

    -- 2. Déduction de la monnaie
    local deductOk = PlayerInventoryManager.DeductCoins(player, pack.CostCoins)
    if not deductOk then
        return { Success = false, Error = "Erreur lors de la transaction financière." }
    end

    -- 3. Résolution de la rareté avec Pity
    local pity = profile.PityCounter
    local wonRarity = RollRarity(pack, pity)

    -- 4. Mise à jour des compteurs de malchance
    if wonRarity == "Legendary" then
        pity.SinceLastLegendary = 0
        pity.SinceLastEpic = 0
    elseif wonRarity == "Epic" then
        pity.SinceLastEpic = 0
        pity.SinceLastLegendary += 1
    else
        pity.SinceLastEpic += 1
        pity.SinceLastLegendary += 1
    end

    profile.Stats.PacksOpened += 1

    -- 5. Sélection d'une carte dans cette rareté
    local availableCards = CardsDatabase.CardsByRarity[wonRarity]
    assert(#availableCards > 0, "Aucune carte enregistrée pour la rareté : " .. wonRarity)
    local chosenBlueprint = availableCards[math.random(1, #availableCards)]

    -- 6. Création de l'instance unique et ajout à l'inventaire
    local newCardInstance = PlayerInventoryManager.CreateCardInstance(chosenBlueprint.CardId)!
    PlayerInventoryManager.AddCard(player, newCardInstance)

    -- 7. Alerte serveur globale si la carte est Légendaire (Aura & ElevenLabs Sound Cue)
    if wonRarity == "Legendary" then
        local announcementEvent = Network.GetEvent("ServerAnnouncement")
        announcementEvent:FireAllClients({
            PlayerName = player.Name,
            CardName = newCardInstance.Name,
            Rarity = "Legendary",
            RarityColor = Color3.fromRGB(245, 158, 11),
            IsDivine = false,
        })
    end

    return {
        Success = true,
        Card = newCardInstance,
        RemainingCoins = profile.Coins,
        DisplayOdds = pack.DisplayOdds,
    }
end

-- =============================================================================
-- INITIALISATION DES RÉSEAUX RPC
-- =============================================================================
function GachaSystem.Init()
    -- Enregistrement de la RemoteFunction officielle RequestOpenPack
    local folder = game.ReplicatedStorage:WaitForChild("NetworkRemotes", 10) :: Folder
    local openPackRF = folder:FindFirstChild("RequestOpenPack") :: RemoteFunction?
    if not openPackRF then
        openPackRF = Instance.new("RemoteFunction")
        openPackRF.Name = "RequestOpenPack"
        openPackRF.Parent = folder
    end

    openPackRF.OnServerInvoke = function(player: Player, packId: any)
        if type(packId) ~= "string" then
            return { Success = false, Error = "Paramètre de pack invalide." }
        end
        return GachaSystem.OpenPack(player, packId)
    end

    print("[GachaSystem] Système d'ouverture de paquets initialisé et prêt.")
end

return GachaSystem
