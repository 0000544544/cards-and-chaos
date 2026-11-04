--!strict
--[[
    RARITY CONFIGURATION
    Paliers de rareté, probabilités de tirage (Gacha), multiplicateurs et esthétique.
]]

export type RarityInfo = {
    Id: string,
    Name: string,
    Weight: number,          -- Poids pour la roulette Gacha
    DropRatePercent: number, -- % théorique affiché aux joueurs
    Color: Color3,
    SecondaryColor: Color3,
    StatMultiplier: number,  -- Multiplicateur de dégâts/effets
    BaseSellPrice: number,   -- Prix de rachat NPC / démantèlement
    RecycleDust: number,     -- Poussière astrale gagnée au recyclage
    BroadcastRoll: boolean,  -- Alerte sur tout le serveur
    GlowIntensity: number,
}

local RarityConfig: { [string]: RarityInfo } = {
    Common = {
        Id = "Common",
        Name = "Commun",
        Weight = 6000,
        DropRatePercent = 60.0,
        Color = Color3.fromRGB(180, 190, 205),
        SecondaryColor = Color3.fromRGB(100, 110, 125),
        StatMultiplier = 1.0,
        BaseSellPrice = 25,
        RecycleDust = 5,
        BroadcastRoll = false,
        GlowIntensity = 0,
    },
    Rare = {
        Id = "Rare",
        Name = "Rare",
        Weight = 2500,
        DropRatePercent = 25.0,
        Color = Color3.fromRGB(56, 189, 248),
        SecondaryColor = Color3.fromRGB(2, 132, 199),
        StatMultiplier = 1.35,
        BaseSellPrice = 75,
        RecycleDust = 20,
        BroadcastRoll = false,
        GlowIntensity = 0.3,
    },
    Epic = {
        Id = "Epic",
        Name = "Épique",
        Weight = 1000,
        DropRatePercent = 10.0,
        Color = Color3.fromRGB(168, 85, 247),
        SecondaryColor = Color3.fromRGB(126, 34, 206),
        StatMultiplier = 1.85,
        BaseSellPrice = 200,
        RecycleDust = 60,
        BroadcastRoll = false,
        GlowIntensity = 0.6,
    },
    Legendary = {
        Id = "Legendary",
        Name = "LÉGENDAIRE",
        Weight = 400,
        DropRatePercent = 4.0,
        Color = Color3.fromRGB(245, 158, 11),
        SecondaryColor = Color3.fromRGB(180, 83, 9),
        StatMultiplier = 2.6,
        BaseSellPrice = 600,
        RecycleDust = 200,
        BroadcastRoll = true,
        GlowIntensity = 0.9,
    },
    Mythic = {
        Id = "Mythic",
        Name = "MYTHIQUE",
        Weight = 90,
        DropRatePercent = 0.9,
        Color = Color3.fromRGB(239, 68, 68),
        SecondaryColor = Color3.fromRGB(153, 27, 27),
        StatMultiplier = 3.8,
        BaseSellPrice = 2000,
        RecycleDust = 800,
        BroadcastRoll = true,
        GlowIntensity = 1.2,
    },
    Divine = {
        Id = "Divine",
        Name = "DIVIN CÉLESTE",
        Weight = 10,
        DropRatePercent = 0.1,
        Color = Color3.fromRGB(250, 204, 21),
        SecondaryColor = Color3.fromRGB(255, 255, 255),
        StatMultiplier = 5.5,
        BaseSellPrice = 10000,
        RecycleDust = 5000,
        BroadcastRoll = true,
        GlowIntensity = 2.0,
    },
}

-- Ordre hiérarchique pour le tri
local RarityOrder: { [string]: number } = {
    Common = 1,
    Rare = 2,
    Epic = 3,
    Legendary = 4,
    Mythic = 5,
    Divine = 6,
}

-- Pity Rules (Protection contre la malchance)
local PityRules = {
    EpicGuaranteed = 10,       -- Au moins 1 Épique tous les 10 tirages
    LegendaryGuaranteed = 50,  -- 1 Légendaire garanti après 50 tirages
    MythicGuaranteed = 200,    -- 1 Mythique garanti après 200 tirages
}

-- Coût des invocations (en Or et en Gemmes d'Âme)
local GachaCost = {
    SingleRollCoins = 100,
    MultiRollCoins = 900, -- Réduction 10% pour 10 tirages
    SingleRollGems = 10,
    MultiRollGems = 90,
}

return {
    Rarities = RarityConfig,
    Order = RarityOrder,
    Pity = PityRules,
    Cost = GachaCost,
}
