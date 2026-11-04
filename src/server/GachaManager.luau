--!strict
--[[
    GACHA MANAGER (AUTEL DU DESTIN / INVOCATION)
    Système complet de tirage aléatoire pondéré (Gambling), gestion de la Pity,
    boosts de chance et annonces mondiales pour les paliers Légendaire, Mythique et Divin.
]]

local Players = game:GetService("Players")

local CardsData = require(game.ReplicatedStorage.Shared.CardsData)
local RarityConfig = require(game.ReplicatedStorage.Shared.RarityConfig)
local CardUtils = require(game.ReplicatedStorage.Shared.CardUtils)
local Network = require(game.ReplicatedStorage.Shared.NetworkEvents)
local DataManager = require(script.Parent.DataManager)

local GachaManager = {}

-- Regroupement des cartes par rareté pour un tirage immédiat
local CardsByRarity: { [string]: { string } } = {
    Common = {},
    Rare = {},
    Epic = {},
    Legendary = {},
    Mythic = {},
    Divine = {},
}

for id, def in pairs(CardsData.Cards) do
    if CardsByRarity[def.Rarity] then
        table.insert(CardsByRarity[def.Rarity], id)
    end
end

-- Tirage d'une rareté en tenant compte de la Pity
local function DetermineRarity(pity: { SinceLastEpic: number, SinceLastLegendary: number, SinceLastMythic: number }): string
    -- 1. Pity Mythique prioritaire
    if pity.SinceLastMythic >= RarityConfig.Pity.MythicGuaranteed then
        return "Mythic"
    end
    -- 2. Pity Légendaire
    if pity.SinceLastLegendary >= RarityConfig.Pity.LegendaryGuaranteed then
        return "Legendary"
    end
    -- 3. Pity Épique
    if pity.SinceLastEpic >= RarityConfig.Pity.EpicGuaranteed then
        return "Epic"
    end

    -- 4. Tirage aléatoire pondéré classique
    local totalWeight = 0
    for _, info in pairs(RarityConfig.Rarities) do
        totalWeight += info.Weight
    end

    local roll = math.random(1, totalWeight)
    local current = 0

    -- On parcourt dans l'ordre de rareté
    local orderedTiers = { "Divine", "Mythic", "Legendary", "Epic", "Rare", "Common" }
    for _, tier in ipairs(orderedTiers) do
        local weight = RarityConfig.Rarities[tier].Weight
        current += weight
        if roll <= current then
            return tier
        end
    end

    return "Common"
end

-- Tirage d'une seule carte
local function RollSingleCard(player: Player, profile: DataManager.PlayerProfile): CardUtils.CardInstance
    local pity = profile.PityCounters
    local rarity = DetermineRarity(pity)

    -- Mise à jour des compteurs de pity
    if rarity == "Divine" or rarity == "Mythic" then
        pity.SinceLastMythic = 0
        pity.SinceLastLegendary = 0
        pity.SinceLastEpic = 0
    elseif rarity == "Legendary" then
        pity.SinceLastLegendary = 0
        pity.SinceLastEpic = 0
        pity.SinceLastMythic += 1
    elseif rarity == "Epic" then
        pity.SinceLastEpic = 0
        pity.SinceLastLegendary += 1
        pity.SinceLastMythic += 1
    else
        pity.SinceLastEpic += 1
        pity.SinceLastLegendary += 1
        pity.SinceLastMythic += 1
    end

    -- Sélection d'une carte au sein de cette rareté
    local candidateList = CardsByRarity[rarity]
    local chosenCardId = candidateList[math.random(1, #candidateList)]
    local newCard = CardUtils.CreateCardInstance(chosenCardId)!

    table.insert(profile.Inventory, newCard)
    profile.Stats.TotalRolls += 1

    -- Annonce mondiale si la carte est Légendaire, Mythique ou Divine !
    local rarityInfo = RarityConfig.Rarities[rarity]
    if rarityInfo and rarityInfo.BroadcastRoll then
        local cardDef = CardsData.GetCard(chosenCardId)!
        local announcementEvent = Network.GetEvent("ServerAnnouncement")
        announcementEvent:FireAllClients({
            PlayerName = player.Name,
            CardName = cardDef.Name,
            Rarity = rarity,
            RarityColor = rarityInfo.Color,
            IsDivine = (rarity == "Divine"),
        })
    end

    return newCard
end

-- Fonction RPC appelée par le client
function GachaManager.HandleRoll(player: Player, count: number): { Success: boolean, Cards: { CardUtils.CardInstance }?, Error: string? }
    local profile = DataManager.GetProfile(player)
    if not profile then
        return { Success = false, Error = "Profil non chargé." }
    end

    local cost = 0
    if count == 1 then
        cost = RarityConfig.Cost.SingleRollCoins
    elseif count == 10 then
        cost = RarityConfig.Cost.MultiRollCoins
    else
        return { Success = false, Error = "Quantité de tirage invalide." }
    end

    if profile.Coins < cost then
        return { Success = false, Error = "Or insuffisant (" .. cost .. " requis)." }
    end

    profile.Coins -= cost

    local results = {}
    for i = 1, count do
        local card = RollSingleCard(player, profile)
        table.insert(results, card)
    end

    return {
        Success = true,
        Cards = results,
    }
end

function GachaManager.Init()
    local rollFunction = Network.GetFunction("RollGacha")
    rollFunction.OnServerInvoke = function(player: Player, count: any)
        local c = tonumber(count) or 1
        return GachaManager.HandleRoll(player, c)
    end
end

return GachaManager
