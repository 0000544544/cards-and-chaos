--!strict
--[[
    CARDS & CHAOS - CONFIGURATION DES PACKS DE GACHA
    Probabilités de tirage transparentes (Conformes aux règles Roblox de Gambling éthique),
    coûts en Or et protection contre la malchance (Pity System).
]]

local CardsDatabase = require(script.Parent.CardsDatabase)

export type PackDefinition = {
    Id: string,
    Name: string,
    CostCoins: number,
    Description: string,
    Weights: { [CardsDatabase.CardRarity]: number },
    DisplayOdds: string, -- Texte affiché au joueur pour la conformité Roblox
    GuaranteedRarity: CardsDatabase.CardRarity?,
}

local Packs: { [string]: PackDefinition } = {
    starter_pack = {
        Id = "starter_pack",
        Name = "Pack Débutant",
        CostCoins = 100,
        Description = "Pack idéal pour débuter votre collection d'aptitudes martiales.",
        Weights = {
            Common = 600,      -- 60.0%
            Rare = 250,        -- 25.0%
            Epic = 110,        -- 11.0%
            Legendary = 40,    -- 4.0%
        },
        DisplayOdds = "Commun: 60% | Rare: 25% | Épique: 11% | Légendaire: 4%",
    },
    chaos_pack = {
        Id = "chaos_pack",
        Name = "Pack Chaos",
        CostCoins = 500,
        Description = "Contient des compétences imprégnées de pure énergie de discorde.",
        Weights = {
            Common = 300,      -- 30.0%
            Rare = 420,        -- 42.0%
            Epic = 200,        -- 20.0%
            Legendary = 80,    -- 8.0%
        },
        DisplayOdds = "Commun: 30% | Rare: 42% | Épique: 20% | Légendaire: 8%",
    },
    sovereign_pack = {
        Id = "sovereign_pack",
        Name = "Pack du Souverain",
        CostCoins = 1500,
        Description = "Pack d'élite sans aucune carte commune. 1 Légendaire toutes les 5 ouvertures !",
        Weights = {
            Common = 0,        -- 0.0%
            Rare = 350,        -- 35.0%
            Epic = 450,        -- 45.0%
            Legendary = 200,   -- 20.0%
        },
        DisplayOdds = "Rare: 35% | Épique: 45% | Légendaire: 20% (0% Commun)",
    },
}

local PityRules = {
    MaxPacksWithoutLegendary = 50, -- 1 Légendaire garanti au 50ème tirage
    MaxPacksWithoutEpic = 10,      -- 1 Épique garanti tous les 10 tirages
}

return {
    Packs = Packs,
    Pity = PityRules,
    GetPack = function(packId: string): PackDefinition?
        return Packs[packId]
    end,
}
