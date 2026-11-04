--!strict
--[[
    CARDS & CHAOS - GESTIONNAIRE UNIQUE DU GACHA (SERVEUR)
    Tirage aléatoire pondéré (60% Common, 25% Rare, 11% Epic, 4% Legendary),
    protection de Pity et alerte mondiale serveur pour les Légendaires.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardsDatabase = require(ReplicatedStorage.Shared.CardsDatabase)
local PackConfig = require(ReplicatedStorage.Shared.PackConfig)
local NetworkEvents = require(ReplicatedStorage.Shared.NetworkEvents)
local DataManager = require(script.Parent.DataManager)

local GachaManager = {}
local pityCounters: { [number]: number } = {} -- [userId] = packsWithoutLegendary

function GachaManager.OpenPack(player: Player, packId: string)
    local prof = DataManager.GetProfile(player)
    if not prof then
        return { Success = false, Error = "Profil non chargé." }
    end

    local pack = PackConfig.GetPack(packId) or PackConfig.GetPack("pack_souverain")
    if not pack then
        return { Success = false, Error = "Pack introuvable." }
    end

    -- Vérification et déduction atomique de l'or
    if prof.Coins < pack.CostCoins then
        return {
            Success = false,
            Error = "Or insuffisant (" .. pack.CostCoins .. " requis, vous avez " .. prof.Coins .. " Or).",
        }
    end

    local deducted = DataManager.DeductCoins(player, pack.CostCoins)
    if not deducted then
        return { Success = false, Error = "Échec de la transaction financière." }
    end

    -- Pity tracking
    local userId = player.UserId
    pityCounters[userId] = (pityCounters[userId] or 0) + 1

    local wonRarity: CardsDatabase.CardRarity = "Common"

    if pityCounters[userId] >= PackConfig.Pity.MaxPacksWithoutLegendary then
        wonRarity = "Legendary"
        pityCounters[userId] = 0
    else
        -- Tirage pondéré conforme aux taux
        local totalWeight = 0
        for _, w in pairs(pack.Weights) do
            totalWeight += w
        end
        local roll = math.random(1, totalWeight)
        local current = 0

        for _, r in ipairs({ "Legendary", "Epic", "Rare", "Common" }) do
            local w = pack.Weights[r] or 0
            current += w
            if roll <= current and w > 0 then
                wonRarity = r :: CardsDatabase.CardRarity
                break
            end
        end
    end

    if wonRarity == "Legendary" then
        pityCounters[userId] = 0
    end

    -- Sélection d'une carte de la rareté obtenue
    local pool = CardsDatabase.CardsByRarity[wonRarity]
    local chosenCard = pool[math.random(1, #pool)]
    local cardItem = DataManager.AddCard(player, chosenCard.Id)
    prof.Stats.PacksOpened += 1

    -- Alerte mondiale si carte Légendaire
    if wonRarity == "Legendary" then
        local annEv = NetworkEvents.GetEvent("ServerAnnouncement")
        annEv:FireAllClients({
            PlayerName = player.Name,
            CardName = chosenCard.Name,
            Rarity = "LÉGENDAIRE",
            RarityColor = Color3.fromRGB(245, 158, 11),
        })
    end

    return {
        Success = true,
        Card = cardItem,
        Definition = chosenCard,
        RemainingCoins = prof.Coins,
    }
end

function GachaManager.Init()
    local rf = NetworkEvents.GetFunction("RequestOpenPack")
    rf.OnServerInvoke = function(player: Player, packId: any)
        return GachaManager.OpenPack(player, tostring(packId or "pack_souverain"))
    end
    print("[GachaManager] Prêt pour les tirages.")
end

return GachaManager
