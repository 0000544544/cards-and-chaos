--!strict
--[[
    CARDS & CHAOS - BASE DE DONNÉES DES CARTES & SKILLS
    Définition des cartes/compétences avec types (Offensive, Defensive, Buff),
    raretés (Common à Legendary), puissances de base et AssetIds pour les illustrations (ComfyUI).
]]

export type CardRarity = "Common" | "Rare" | "Epic" | "Legendary"
export type CardType = "Offensive" | "Defensive" | "Buff"

export type CardBlueprint = {
    CardId: string,
    Name: string,
    Rarity: CardRarity,
    Type: CardType,
    BasePower: number,          -- Puissance de base (Dégâts, Bouclier ou Boost %)
    Cooldown: number,           -- Temps de recharge en secondes
    AssetId: string,            -- Image Decal / Texture (générée via ComfyUI)
    Description: string,
    Lore: string,
    VFXColor: Color3,
}

local Cards: { [string]: CardBlueprint } = {
    -- =========================================================================
    -- PALIER COMMUN (60% de base)
    -- =========================================================================
    strike_of_iron = {
        CardId = "strike_of_iron",
        Name = "Frappe d'Acier",
        Rarity = "Common",
        Type = "Offensive",
        BasePower = 30,
        Cooldown = 3.0,
        AssetId = "rbxassetid://13880479100", -- Placeholder ComfyUI Decal
        Description = "Coup tranchant rapide infligeant des dégâts physiques directs.",
        Lore = "L'escrime de base enseignée dans les casernes de la capitale.",
        VFXColor = Color3.fromRGB(200, 205, 215),
    },
    wooden_parry = {
        CardId = "wooden_parry",
        Name = "Parade du Garde",
        Rarity = "Common",
        Type = "Defensive",
        BasePower = 40,
        Cooldown = 5.0,
        AssetId = "rbxassetid://13880479100",
        Description = "Déploie une posture défensive absorbant 40 dégâts.",
        Lore = "Un bouclier solide forgé dans le chêne noir des marais.",
        VFXColor = Color3.fromRGB(140, 110, 80),
    },
    inner_focus = {
        CardId = "inner_focus",
        Name = "Concentration Martiale",
        Rarity = "Common",
        Type = "Buff",
        BasePower = 15, -- +15% Vitesse / Dégâts
        Cooldown = 8.0,
        AssetId = "rbxassetid://13880479100",
        Description = "Augmente votre vitesse de déplacement de 15% pendant 4s.",
        Lore = "Une respiration mesurée qui apaise l'esprit avant le choc.",
        VFXColor = Color3.fromRGB(96, 165, 250),
    },
    ember_spark = {
        CardId = "ember_spark",
        Name = "Étincelle de Braise",
        Rarity = "Common",
        Type = "Offensive",
        BasePower = 32,
        Cooldown = 3.5,
        AssetId = "rbxassetid://13880479100",
        Description = "Lance une boule de feu explosive à courte portée.",
        Lore = "Un résidu de magma canalisé au bout des doigts.",
        VFXColor = Color3.fromRGB(249, 115, 22),
    },

    -- =========================================================================
    -- PALIER RARE (25% de base)
    -- =========================================================================
    blade_flurry = {
        CardId = "blade_flurry",
        Name = "Rafale des Lames",
        Rarity = "Rare",
        Type = "Offensive",
        BasePower = 65,
        Cooldown = 6.0,
        AssetId = "rbxassetid://13880479100",
        Description = "Enchaîne 3 taillades ultra-rapides lacérant l'armure ennemie.",
        Lore = "Une technique d'assassin raffinée dans les arènes clandestines.",
        VFXColor = Color3.fromRGB(56, 189, 248),
    },
    crystalline_barrier = {
        CardId = "crystalline_barrier",
        Name = "Barrière de Cristal",
        Rarity = "Rare",
        Type = "Defensive",
        BasePower = 90,
        Cooldown = 9.0,
        AssetId = "rbxassetid://13880479100",
        Description = "Érige un rempart cristallin absorbant 90 dégâts et renvoyant 15% à l'impact.",
        Lore = "Les facettes du cristal réfractent même les sorts les plus violents.",
        VFXColor = Color3.fromRGB(125, 211, 252),
    },
    berserker_rage = {
        CardId = "berserker_rage",
        Name = "Rage Sanguinaire",
        Rarity = "Rare",
        Type = "Buff",
        BasePower = 25, -- +25% Dégâts
        Cooldown = 12.0,
        AssetId = "rbxassetid://13880479100",
        Description = "Augmente les dégâts de toutes vos cartes de 25% pendant 6s.",
        Lore = "La douleur se transmute en pure férocité au cœur du carnage.",
        VFXColor = Color3.fromRGB(220, 38, 38),
    },
    frost_nova = {
        CardId = "frost_nova",
        Name = "Onde Glaciale",
        Rarity = "Rare",
        Type = "Offensive",
        BasePower = 58,
        Cooldown = 7.0,
        AssetId = "rbxassetid://13880479100",
        Description = "Fige le sol et ralentit l'adversaire de 30% pendant 2.5s.",
        Lore = "Le froid polaire immobilise même les combattants les plus agiles.",
        VFXColor = Color3.fromRGB(6, 182, 212),
    },

    -- =========================================================================
    -- PALIER ÉPIQUE (11% de base)
    -- =========================================================================
    void_rift = {
        CardId = "void_rift",
        Name = "Déchirure du Néant",
        Rarity = "Epic",
        Type = "Offensive",
        BasePower = 115,
        Cooldown = 9.5,
        AssetId = "rbxassetid://13880479100",
        Description = "Ouvre une faille gravitationnelle aspirant et compressant l'adversaire.",
        Lore = "L'écho de l'antimatière réclame son tribut de matière vivante.",
        VFXColor = Color3.fromRGB(168, 85, 247),
    },
    celestial_aegis = {
        CardId = "celestial_aegis",
        Name = "Égide Céleste",
        Rarity = "Epic",
        Type = "Defensive",
        BasePower = 160,
        Cooldown = 13.0,
        AssetId = "rbxassetid://13880479100",
        Description = "Invoque la bénédiction des étoiles. Immunité aux étourdissements pendant 3s.",
        Lore = "Un fragment de comète scellé dans un médaillon de platine.",
        VFXColor = Color3.fromRGB(250, 204, 21),
    },
    chrono_warp = {
        CardId = "chrono_warp",
        Name = "Distorsion Temporelle",
        Rarity = "Epic",
        Type = "Buff",
        BasePower = 35, -- -35% Cooldowns
        Cooldown = 15.0,
        AssetId = "rbxassetid://13880479100",
        Description = "Réduit instantanément tous les temps de recharge actifs de 35%.",
        Lore = "Le temps n'est plus une ligne droite mais un méandre que l'on court-circuite.",
        VFXColor = Color3.fromRGB(147, 51, 234),
    },

    -- =========================================================================
    -- PALIER LÉGENDAIRE (4% de base - ALERTE MONDIALE)
    -- =========================================================================
    judgment_of_chaos = {
        CardId = "judgment_of_chaos",
        Name = "Le Jugement du Chaos",
        Rarity = "Legendary",
        Type = "Offensive",
        BasePower = 220,
        Cooldown = 16.0,
        AssetId = "rbxassetid://13880479100",
        Description = "Abat un pilier de feu sombre dévastateur ignorant 40% de l'armure de la cible.",
        Lore = "La première sentence prononcée lorsque le monde bascula dans le désordre primordial.",
        VFXColor = Color3.fromRGB(239, 68, 68),
    },
    primordial_avatar = {
        CardId = "primordial_avatar",
        Name = "Éveil de l'Avatar Souverain",
        Rarity = "Legendary",
        Type = "Buff",
        BasePower = 50, -- +50% Stats globales
        Cooldown = 22.0,
        AssetId = "rbxassetid://13880479100",
        Description = "Déchaîne l'aura de l'Avatar : +50% dégâts, vitesse accrue et régénération rapide pendant 6s.",
        Lore = "Quand l'élu s'éveille, les lois mortelles s'effacent devant sa souveraineté.",
        VFXColor = Color3.fromRGB(245, 158, 11),
    },
    absolute_sanctuary = {
        CardId = "absolute_sanctuary",
        Name = "Sanctuaire Absolu",
        Rarity = "Legendary",
        Type = "Defensive",
        BasePower = 280,
        Cooldown = 18.0,
        AssetId = "rbxassetid://13880479100",
        Description = "Crée un dôme inviolable absorbant 280 dégâts et repoussant tous les assaillants.",
        Lore = "Ni le fer, ni le feu, ni la haine ne franchissent ce seuil sacré.",
        VFXColor = Color3.fromRGB(253, 224, 71),
    },
}

-- Indexation par rareté pour un tirage Gacha instantané
local CardsByRarity: { [CardRarity]: { CardBlueprint } } = {
    Common = {},
    Rare = {},
    Epic = {},
    Legendary = {},
}

for _, card in pairs(Cards) do
    table.insert(CardsByRarity[card.Rarity], card)
end

return {
    Cards = Cards,
    CardsByRarity = CardsByRarity,
    GetCard = function(cardId: string): CardBlueprint?
        return Cards[cardId]
    end,
}
