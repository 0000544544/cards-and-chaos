--!strict
--[[
    CARDS & CHAOS - CONFIGURATION DES PACKS DE GACHA
    Probabilités de tirage transparentes (Conformes aux règles Roblox de Gambling éthique).
]]

export type PackDefinition = {
    Id: string,
    Name: string,
    CostCoins: number,
    Description: string,
    Weights: { [string]: number },
    DisplayOdds: string,
    Color: Color3,
}

local Packs: { [string]: PackDefinition } = {
    ["pack_souverain"] = {
        Id = "pack_souverain",
        Name = "Pack Souverain",
        CostCoins = 250,
        Description = "Pack équilibré contenant des sorts de la Garde Souveraine.",
        Weights = {
            Common = 600,      -- 60%
            Rare = 250,        -- 25%
            Epic = 110,        -- 11%
            Legendary = 40,    -- 4%
        },
        DisplayOdds = "Commun: 60% | Rare: 25% | Épique: 11% | Légendaire: 4%",
        Color = Color3.fromRGB(79, 70, 229),
    },
    ["pack_chaos"] = {
        Id = "pack_chaos",
        Name = "Pack Chaos Mythique",
        CostCoins = 1000,
        Description = "Pack haut de gamme avec chances décuplées de sorts Épiques et Légendaires !",
        Weights = {
            Common = 200,      -- 20%
            Rare = 450,        -- 45%
            Epic = 250,        -- 25%
            Legendary = 100,   -- 10%
        },
        DisplayOdds = "Commun: 20% | Rare: 45% | Épique: 25% | Légendaire: 10%",
        Color = Color3.fromRGB(217, 70, 239),
    },
}

local PityRules = {
    MaxPacksWithoutLegendary = 50, -- 1 Légendaire garanti au 50ème tirage
}

return {
    Packs = Packs,
    Pity = PityRules,
    GetPack = function(packId: string): PackDefinition?
        return Packs[packId]
    end,
}
