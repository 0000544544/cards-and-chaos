--!strict
--[[
    CARD UTILITIES
    Génération d'instances uniques, calculs de synergies de deck et application des bonus de Mérite.
]]

local HttpService = game:GetService("HttpService")

local CardsData = require(script.Parent.CardsData)
local RarityConfig = require(script.Parent.RarityConfig)
local RankConfig = require(script.Parent.RankConfig)

export type CardInstance = {
    UniqueId: string,
    CardId: string,
    Level: number,
    Prestige: boolean,       -- Carte élevée au Sanctuaire du Mérite
    AcquiredAt: number,      -- Timestamp
    Tradable: boolean,
}

export type PlayerDeck = {
    Actives: { string },     -- 4 emplacements (CardUniqueIds ou CardIds)
    Passives: { string },    -- 2 emplacements
}

local CardUtils = {}

-- Génération d'une nouvelle carte instanciée
function CardUtils.CreateCardInstance(cardId: string, isPrestige: boolean?): CardInstance?
    local def = CardsData.GetCard(cardId)
    if not def then
        return nil
    end

    return {
        UniqueId = HttpService:GenerateGUID(false),
        CardId = cardId,
        Level = 1,
        Prestige = isPrestige or false,
        AcquiredAt = os.time(),
        Tradable = true,
    }
end

-- Calcul des statistiques réelles d'une carte (en tenant compte de la Rareté, du Niveau et du Prestige)
function CardUtils.ComputeCardStats(cardInstance: CardInstance, playerMerit: number?)
    local def = CardsData.GetCard(cardInstance.CardId)
    if not def then
        return nil
    end

    local rarityInfo = RarityConfig.Rarities[def.Rarity]
    local rarityMult = rarityInfo and rarityInfo.StatMultiplier or 1.0
    local levelMult = 1 + (cardInstance.Level - 1) * 0.05
    local prestigeMult = cardInstance.Prestige and (1 + RankConfig.Prestige.StatBoostPercent / 100) or 1.0

    -- Bonus de Mérite passif si la carte possède la mise à l'échelle
    local meritBonus = 1.0
    if def.PassiveStats and def.PassiveStats.MeritScalingPercent and playerMerit then
        local rawScale = (playerMerit / 100) * 0.01
        meritBonus = 1.0 + math.clamp(rawScale, 0, def.PassiveStats.MeritScalingPercent / 100)
    end

    local totalMultiplier = rarityMult * levelMult * prestigeMult * meritBonus

    local stats = {
        Damage = def.Damage and math.round(def.Damage * totalMultiplier) or 0,
        Cooldown = def.Cooldown or 0,
        Range = def.Range or 0,
        RarityInfo = rarityInfo,
        Definition = def,
        Prestige = cardInstance.Prestige,
        Level = cardInstance.Level,
    }

    return stats
end

-- Calcul des synergies de deck
function CardUtils.ComputeDeckSynergies(cardIds: { string }): { [string]: any }
    local affinityCounts: { [string]: number } = {}
    for _, cardId in ipairs(cardIds) do
        local def = CardsData.GetCard(cardId)
        if def then
            affinityCounts[def.Affinity] = (affinityCounts[def.Affinity] or 0) + 1
        end
    end

    local synergies = {}
    if (affinityCounts["Blade"] or 0) >= 3 then
        table.insert(synergies, {
            Name = "Maîtrise des Lames",
            Description = "+10% de vitesse d'attaque sur toutes les compétences d'acier.",
            Bonus = "AttackSpeed",
            Value = 1.10,
        })
    end
    if (affinityCounts["Void"] or 0) >= 2 then
        table.insert(synergies, {
            Name = "Écho du Néant",
            Description = "+8% de vol de vie universel.",
            Bonus = "LifeSteal",
            Value = 0.08,
        })
    end
    if (affinityCounts["Holy"] or 0) >= 2 then
        table.insert(synergies, {
            Name = "Sanctuaire Céleste",
            Description = "+20% d'efficacité des boucliers et réduction de la durée des stuns de 25%.",
            Bonus = "Tenacity",
            Value = 0.25,
        })
    end

    return synergies
end

return CardUtils
