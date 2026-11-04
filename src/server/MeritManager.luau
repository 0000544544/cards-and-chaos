--!strict
--[[
    MERIT & ASCENSION MANAGER (SANCTUAIRE DU MÉRITE & FORGE DE PRESTIGE)
    Gestion de la transcendance des cartes par le mérite (Anti-Pay-To-Win),
    recyclage des doublons en poussière astrale et gestion de l'équipement du Deck.
]]

local Players = game:GetService("Players")

local RankConfig = require(game.ReplicatedStorage.Shared.RankConfig)
local RarityConfig = require(game.ReplicatedStorage.Shared.RarityConfig)
local CardsData = require(game.ReplicatedStorage.Shared.CardsData)
local Network = require(game.ReplicatedStorage.Shared.NetworkEvents)
local DataManager = require(script.Parent.DataManager)

local MeritManager = {}

-- Transcendance d'une carte grâce au Mérite
function MeritManager.PrestigeCard(player: Player, cardUniqueId: string): { Success: boolean, Error: string? }
    local profile = DataManager.GetProfile(player)
    if not profile then
        return { Success = false, Error = "Profil non chargé." }
    end

    if profile.Merit < RankConfig.Prestige.CostPerCard then
        return { Success = false, Error = "Points de Mérite insuffisants (" .. RankConfig.Prestige.CostPerCard .. " requis). Jouez en Arène !" }
    end

    local targetCard: any = nil
    for _, card in ipairs(profile.Inventory) do
        if card.UniqueId == cardUniqueId then
            targetCard = card
            break
        end
    end

    if not targetCard then
        return { Success = false, Error = "Carte introuvable." }
    end

    if targetCard.Prestige then
        return { Success = false, Error = "Cette carte a déjà atteint le rang Souverain Prestige." }
    end

    -- Déduction du Mérite et application de la transcendance
    profile.Merit -= RankConfig.Prestige.CostPerCard
    targetCard.Prestige = true

    local toast = Network.GetEvent("ToastNotify")
    toast:FireClient(player, "🌟 CARTE TRANSCENDÉE AU RANG PRESTIGE SOUVERAIN (+20% Efficacité) !")

    return { Success = true }
end

-- Recyclage d'une carte doublon contre de l'Or et de la Poussière
function MeritManager.RecycleCard(player: Player, cardUniqueId: string): { Success: boolean, CoinsEarned: number?, Error: string? }
    local profile = DataManager.GetProfile(player)
    if not profile then
        return { Success = false, Error = "Profil non chargé." }
    end

    local foundIndex: number? = nil
    local cardInstance: any = nil
    for idx, card in ipairs(profile.Inventory) do
        if card.UniqueId == cardUniqueId then
            foundIndex = idx
            cardInstance = card
            break
        end
    end

    if not cardInstance or not foundIndex then
        return { Success = false, Error = "Carte introuvable." }
    end

    -- Vérification si équipée
    for _, id in ipairs(profile.EquippedDeck.Actives) do
        if id == cardUniqueId then
            return { Success = false, Error = "Impossible de recycler une carte équipée dans votre Deck." }
        end
    end
    for _, id in ipairs(profile.EquippedDeck.Passives) do
        if id == cardUniqueId then
            return { Success = false, Error = "Impossible de recycler une carte équipée dans votre Deck." }
        end
    end

    local def = CardsData.GetCard(cardInstance.CardId)
    local rarityInfo = def and RarityConfig.Rarities[def.Rarity]
    local payout = rarityInfo and rarityInfo.BaseSellPrice or 20

    table.remove(profile.Inventory, foundIndex)
    profile.Coins += payout

    return { Success = true, CoinsEarned = payout }
end

-- Équipement du Deck (4 Actives, 2 Passives)
function MeritManager.EquipDeck(player: Player, newDeck: { Actives: { string }, Passives: { string } }): { Success: boolean, Error: string? }
    local profile = DataManager.GetProfile(player)
    if not profile then return { Success = false, Error = "Profil non chargé." } end

    if not newDeck or not newDeck.Actives or not newDeck.Passives then
        return { Success = false, Error = "Structure de Deck invalide." }
    end

    if #newDeck.Actives > 4 or #newDeck.Passives > 2 then
        return { Success = false, Error = "Le Deck ne peut contenir que 4 Actives et 2 Passives." }
    end

    -- Vérification de possession de chaque carte
    local function OwnsCard(uid: string): boolean
        for _, c in ipairs(profile.Inventory) do
            if c.UniqueId == uid then return true end
        end
        return false
    end

    for _, uid in ipairs(newDeck.Actives) do
        if not OwnsCard(uid) then return { Success = false, Error = "Vous ne possédez pas l'une des cartes actives." } end
    end
    for _, uid in ipairs(newDeck.Passives) do
        if not OwnsCard(uid) then return { Success = false, Error = "Vous ne possédez pas l'une des cartes passives." } end
    end

    profile.EquippedDeck = newDeck
    return { Success = true }
end

function MeritManager.Init()
    local prestigeRF = Network.GetFunction("PrestigeCard")
    prestigeRF.OnServerInvoke = function(player: Player, cardUid: any)
        return MeritManager.PrestigeCard(player, tostring(cardUid))
    end

    local recycleRF = Network.GetFunction("RecycleCard")
    recycleRF.OnServerInvoke = function(player: Player, cardUid: any)
        return MeritManager.RecycleCard(player, tostring(cardUid))
    end

    local equipRF = Network.GetFunction("EquipDeck")
    equipRF.OnServerInvoke = function(player: Player, newDeck: any)
        return MeritManager.EquipDeck(player, newDeck)
    end

    local getProfileRF = Network.GetFunction("GetPlayerData")
    getProfileRF.OnServerInvoke = function(player: Player)
        return DataManager.GetProfile(player)
    end
end

return MeritManager
