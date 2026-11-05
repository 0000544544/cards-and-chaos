--!strict
--[[
    CARDS & CHAOS - CONFIGURATION DES SORTS & COMPÉTENCES
    Fichier : src/shared/Config/SpellsData.luau (ModuleScript)
    Dictionnaire des compétences magiques avec statistiques, types et raretés.
]]

export type SpellRarity = "Common" | "Rare" | "Epic" | "Legendary"
export type SpellType = "Projectile" | "Nova" | "Teleport" | "Shield"

export type SpellDefinition = {
    Id: string,
    Name: string,
    Rarity: SpellRarity,
    Type: SpellType,
    BaseDamage: number,
    Cooldown: number,
    ManaCost: number,
    Description: string,
}

local SpellsData: { [string]: SpellDefinition } = {
    ["meteore_solaire"] = {
        Id = "meteore_solaire",
        Name = "Météore Solaire",
        Rarity = "Legendary",
        Type = "Projectile",
        BaseDamage = 65,
        Cooldown = 4.5,
        ManaCost = 40,
        Description = "Invoque un météore incandescent qui s'écrase sur la zone ciblée en infligeant de lourds dégâts d'impact.",
    },

    ["faisceau_celeste"] = {
        Id = "faisceau_celeste",
        Name = "Faisceau Céleste",
        Rarity = "Legendary",
        Type = "Projectile",
        BaseDamage = 55,
        Cooldown = 4.0,
        ManaCost = 35,
        Description = "Projette un rayon d'énergie pure traversant les défenses ennemies sur une longue portée linéaire.",
    },

    ["pas_eclair"] = {
        Id = "pas_eclair",
        Name = "Pas Éclair",
        Rarity = "Rare",
        Type = "Teleport",
        BaseDamage = 25,
        Cooldown = 2.5,
        ManaCost = 15,
        Description = "Téléportation fulgurante vers l'avant infligeant des décharges électriques aux ennemis traversés.",
    },

    ["nova_neant"] = {
        Id = "nova_neant",
        Name = "Nova du Néant",
        Rarity = "Epic",
        Type = "Nova",
        BaseDamage = 40,
        Cooldown = 3.5,
        ManaCost = 30,
        Description = "Libère une onde de choc gravitationnelle tout autour du lanceur repoussant les cibles proches.",
    },

    ["bouclier_egide"] = {
        Id = "bouclier_egide",
        Name = "Bouclier d'Égide",
        Rarity = "Common",
        Type = "Shield",
        BaseDamage = 0,
        Cooldown = 5.0,
        ManaCost = 20,
        Description = "Déploie une barrière arcanique protectrice qui absorbe les attaques ennemies et protège le lanceur.",
    },

    ["orbe_chaos"] = {
        Id = "orbe_chaos",
        Name = "Orbe du Chaos",
        Rarity = "Common",
        Type = "Projectile",
        BaseDamage = 20,
        Cooldown = 2.0,
        ManaCost = 10,
        Description = "Lance un projectile d'énergie chaotique instable à cadence rapide vers le curseur.",
    },
}

return SpellsData
