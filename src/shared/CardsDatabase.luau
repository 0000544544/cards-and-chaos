--!strict
--[[
    CARDS & CHAOS - BASE DE DONNÉES UNIQUE DES CARTES & SPELLS
    12 Cartes / Compétences d'arène avec types de sorts 3D (Projectile, AoE, DashStrike, ShieldBuff).
]]

export type SpellType = "Projectile" | "AoE" | "DashStrike" | "ShieldBuff"
export type CardRarity = "Common" | "Rare" | "Epic" | "Legendary"

export type CardDefinition = {
    Id: string,
    Name: string,
    Rarity: CardRarity,
    SpellType: SpellType,
    BasePower: number,
    Cooldown: number,
    Speed: number?,
    Radius: number?,
    Range: number?,
    Color: Color3,
    Description: string,
    Image: string,
    ManaCost: number?,
}

local CardsDatabase = {}

CardsDatabase.Cards = {
    -- 4 SORTS DU STARTER DECK
    ["pyro_meteor"] = {
        Id = "pyro_meteor",
        Name = "Météore Solaire",
        Rarity = "Legendary",
        SpellType = "Projectile",
        BasePower = 45,
        Cooldown = 3.0,
        Speed = 95,
        Radius = 12,
        Color = Color3.fromRGB(255, 85, 0),
        Description = "Lance une sphère de magma qui explose à l'impact.",
        Image = "rbxassetid://13880479100",
        ManaCost = 20,
    },
    ["void_chain"] = {
        Id = "void_chain",
        Name = "Nova du Néant",
        Rarity = "Epic",
        SpellType = "AoE",
        BasePower = 35,
        Cooldown = 4.5,
        Radius = 18,
        Color = Color3.fromRGB(145, 40, 255),
        Description = "Déchaîne une onde de choc gravitationnelle autour du lanceur.",
        Image = "rbxassetid://13880479100",
        ManaCost = 25,
    },
    ["thunder_step"] = {
        Id = "thunder_step",
        Name = "Pas Éclair",
        Rarity = "Rare",
        SpellType = "DashStrike",
        BasePower = 28,
        Cooldown = 2.5,
        Range = 35,
        Color = Color3.fromRGB(0, 215, 255),
        Description = "Téléportation éclair vers l'avant qui électrocute les cibles sur le passage.",
        Image = "rbxassetid://13880479100",
        ManaCost = 15,
    },
    ["sovereign_aegis"] = {
        Id = "sovereign_aegis",
        Name = "Égide du Souverain",
        Rarity = "Epic",
        SpellType = "ShieldBuff",
        BasePower = 30,
        Cooldown = 6.0,
        Radius = 10,
        Color = Color3.fromRGB(255, 215, 50),
        Description = "Restaure 30 PV et entoure le joueur d'une aura dorée protectrice.",
        Image = "rbxassetid://13880479100",
        ManaCost = 30,
    },

    -- 8 CARTES ADDITIONNELLES POUR LE GACHA & LE MARCHÉ
    ["frost_nova"] = {
        Id = "frost_nova",
        Name = "Onde de Givre",
        Rarity = "Rare",
        SpellType = "AoE",
        BasePower = 25,
        Cooldown = 3.5,
        Radius = 15,
        Color = Color3.fromRGB(120, 220, 255),
        Description = "Congèle le sol et inflige des dégâts de froid aux ennemis proches.",
        Image = "rbxassetid://13880479100",
        ManaCost = 15,
    },
    ["blade_flurry"] = {
        Id = "blade_flurry",
        Name = "Rafale d'Acier",
        Rarity = "Common",
        SpellType = "DashStrike",
        BasePower = 22,
        Cooldown = 2.0,
        Range = 25,
        Color = Color3.fromRGB(200, 210, 225),
        Description = "Entaille rapide en avant touchant tous les ennemis sur la trajectoire.",
        Image = "rbxassetid://13880479100",
        ManaCost = 10,
    },
    ["crimson_slash"] = {
        Id = "crimson_slash",
        Name = "Lame Sanglante",
        Rarity = "Common",
        SpellType = "Projectile",
        BasePower = 24,
        Cooldown = 2.2,
        Speed = 90,
        Radius = 8,
        Color = Color3.fromRGB(220, 38, 38),
        Description = "Projette un arc d'énergie tranchante couleur sang.",
        Image = "rbxassetid://13880479100",
        ManaCost = 10,
    },
    ["chaos_strike"] = {
        Id = "chaos_strike",
        Name = "Impact du Chaos",
        Rarity = "Rare",
        SpellType = "Projectile",
        BasePower = 34,
        Cooldown = 3.0,
        Speed = 85,
        Radius = 10,
        Color = Color3.fromRGB(217, 70, 239),
        Description = "Boule d'énergie chaotique provoquant une violente déflagration.",
        Image = "rbxassetid://13880479100",
        ManaCost = 18,
    },
    ["celestial_beam"] = {
        Id = "celestial_beam",
        Name = "Rayon Primordial",
        Rarity = "Legendary",
        SpellType = "DashStrike",
        BasePower = 52,
        Cooldown = 5.0,
        Range = 50,
        Color = Color3.fromRGB(250, 204, 21),
        Description = "Traverse l'arène dans un faisceau de lumière divine dévastateur.",
        Image = "rbxassetid://13880479100",
        ManaCost = 35,
    },
    ["shadow_warp"] = {
        Id = "shadow_warp",
        Name = "Éclipse Ténébreuse",
        Rarity = "Common",
        SpellType = "AoE",
        BasePower = 20,
        Cooldown = 3.0,
        Radius = 14,
        Color = Color3.fromRGB(75, 45, 110),
        Description = "Pousse un cri d'ombre repoussant et endommageant les ennemis.",
        Image = "rbxassetid://13880479100",
        ManaCost = 12,
    },
    ["abyssal_shield"] = {
        Id = "abyssal_shield",
        Name = "Rempart Abyssal",
        Rarity = "Rare",
        SpellType = "ShieldBuff",
        BasePower = 25,
        Cooldown = 5.0,
        Radius = 8,
        Color = Color3.fromRGB(99, 102, 241),
        Description = "Restaure 25 PV et octroie une protection du néant.",
        Image = "rbxassetid://13880479100",
        ManaCost = 20,
    },
    ["berserk_fury"] = {
        Id = "berserk_fury",
        Name = "Fureur Déchaînée",
        Rarity = "Epic",
        SpellType = "Projectile",
        BasePower = 40,
        Cooldown = 4.0,
        Speed = 100,
        Radius = 14,
        Color = Color3.fromRGB(239, 68, 68),
        Description = "Orbe de pure rage explosive projetant les cibles au loin.",
        Image = "rbxassetid://13880479100",
        ManaCost = 25,
    },
}

CardsDatabase.StarterDeck = { "pyro_meteor", "void_chain", "thunder_step", "sovereign_aegis" }

-- Regroupement par rareté pour le Gacha
CardsDatabase.CardsByRarity = {
    Common = {},
    Rare = {},
    Epic = {},
    Legendary = {},
}

for _, card in pairs(CardsDatabase.Cards) do
    if CardsDatabase.CardsByRarity[card.Rarity] then
        table.insert(CardsDatabase.CardsByRarity[card.Rarity], card)
    end
end

function CardsDatabase.GetCard(cardId: string): CardDefinition?
    return CardsDatabase.Cards[cardId]
end

return CardsDatabase
