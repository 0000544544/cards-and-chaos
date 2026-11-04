--!strict
--[[
    CARDS & SKILLS DATABASE (LE CODEX DU SOUVERAIN)
    30+ cartes d'aptitudes actives et passives réparties sur 6 raretés et 6 affinités élémentaires.
]]

export type CardDefinition = {
    Id: string,
    Name: string,
    Rarity: "Common" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Divine",
    Type: "Active" | "Passive",
    Affinity: "Blade" | "Void" | "Fire" | "Frost" | "Holy" | "Chrono" | "Lightning",
    Description: string,
    Lore: string,
    
    -- Pour les Actives :
    Cooldown: number?,      -- Temps de recharge en secondes
    Damage: number?,        -- Dégâts de base
    Range: number?,         -- Portée en studs
    Duration: number?,      -- Durée d'effet
    CastTime: number?,      -- Temps d'incantation
    VFXColor: Color3?,      -- Teinte des particules
    
    -- Pour les Passives / Buffs :
    PassiveStats: {
        BonusHealth: number?,
        BonusSpeed: number?,
        LifeStealPercent: number?,
        CooldownReductionPercent: number?,
        DamageBonusPercent: number?,
        MeritScalingPercent: number?,
        DodgeChancePercent: number?,
    }?,
}

local Cards: { [string]: CardDefinition } = {
    -- =========================================================================
    -- PALIER COMMUN (60% DROP)
    -- =========================================================================
    iron_slash = {
        Id = "iron_slash",
        Name = "Tranchant d'Acier",
        Rarity = "Common",
        Type = "Active",
        Affinity = "Blade",
        Description = "Coup d'épée rapide infligeant des dégâts immédiats aux ennemis proches.",
        Lore = "L'art martial de base des recrues de la Garde Souveraine.",
        Cooldown = 3.0,
        Damage = 25,
        Range = 12,
        CastTime = 0.1,
        VFXColor = Color3.fromRGB(220, 220, 230),
    },
    shadow_step = {
        Id = "shadow_step",
        Name = "Foulée Sombre",
        Rarity = "Common",
        Type = "Active",
        Affinity = "Void",
        Description = "Traverse les ténèbres en projetant une courte onde de choc ténébreuse.",
        Lore = "Un pas glissé dans l'interstice du néant.",
        Cooldown = 4.0,
        Damage = 18,
        Range = 16,
        CastTime = 0.1,
        VFXColor = Color3.fromRGB(80, 40, 110),
    },
    flame_bolt = {
        Id = "flame_bolt",
        Name = "Éclair de Braise",
        Rarity = "Common",
        Type = "Active",
        Affinity = "Fire",
        Description = "Tire un projectile incandescent qui explose à l'impact.",
        Lore = "Une flamme condensée par un simple mot de pouvoir.",
        Cooldown = 3.5,
        Damage = 28,
        Range = 40,
        CastTime = 0.2,
        VFXColor = Color3.fromRGB(249, 115, 22),
    },
    ice_shard = {
        Id = "ice_shard",
        Name = "Éclat Boréal",
        Rarity = "Common",
        Type = "Active",
        Affinity = "Frost",
        Description = "Projette un pic de givre tranchant qui ralentit la cible de 20% pendant 2s.",
        Lore = "Taillé dans les glaciers éternels du pic du Nord.",
        Cooldown = 3.2,
        Damage = 22,
        Range = 35,
        CastTime = 0.15,
        VFXColor = Color3.fromRGB(56, 189, 248),
    },
    holy_lance = {
        Id = "holy_lance",
        Name = "Pieu de Clarté",
        Rarity = "Common",
        Type = "Active",
        Affinity = "Holy",
        Description = "Fait jaillir un rayon de lumière pure perçant l'adversaire.",
        Lore = "Un faisceau béni par la lumière des premiers souverains.",
        Cooldown = 3.8,
        Damage = 27,
        Range = 30,
        CastTime = 0.2,
        VFXColor = Color3.fromRGB(253, 224, 71),
    },
    vitality_surge = {
        Id = "vitality_surge",
        Name = "Vigueur Martiale",
        Rarity = "Common",
        Type = "Passive",
        Affinity = "Blade",
        Description = "Augmente les points de vie max de 50.",
        Lore = "Le conditionnement physique rigoureux forge un corps d'acier.",
        PassiveStats = {
            BonusHealth = 50,
        },
    },

    -- =========================================================================
    -- PALIER RARE (25% DROP)
    -- =========================================================================
    blade_dance = {
        Id = "blade_dance",
        Name = "Danse des Lames",
        Rarity = "Rare",
        Type = "Active",
        Affinity = "Blade",
        Description = "Enchaîne 3 taillades ultra-rapides déstabilisant l'adversaire.",
        Lore = "Chaque rotation est calculée pour ne laisser aucune faille.",
        Cooldown = 6.0,
        Damage = 52,
        Range = 14,
        CastTime = 0.3,
        VFXColor = Color3.fromRGB(200, 210, 240),
    },
    abyssal_grasp = {
        Id = "abyssal_grasp",
        Name = "Étreinte du Gouffre",
        Rarity = "Rare",
        Type = "Active",
        Affinity = "Void",
        Description = "Invoque des mains spectrales qui enracinent l'ennemi pendant 1.5s.",
        Lore = "Les mains des anciens bannis réclament de nouveaux captifs.",
        Cooldown = 7.5,
        Damage = 40,
        Range = 25,
        CastTime = 0.25,
        VFXColor = Color3.fromRGB(120, 50, 160),
    },
    combustion_dash = {
        Id = "combustion_dash",
        Name = "Ruée Incendiaire",
        Rarity = "Rare",
        Type = "Active",
        Affinity = "Fire",
        Description = "Fonce en avant en laissant une traînée de feu qui brûle sur la durée.",
        Lore = "Le sillage laissé derrière ne s'éteint jamais avant le lever du jour.",
        Cooldown = 6.5,
        Damage = 48,
        Range = 28,
        CastTime = 0.1,
        VFXColor = Color3.fromRGB(234, 88, 12),
    },
    glacial_barrier = {
        Id = "glacial_barrier",
        Name = "Mur de Frimas",
        Rarity = "Rare",
        Type = "Active",
        Affinity = "Frost",
        Description = "Déploie un bouclier de glace absorbant 80 dégâts et gelant les assaillants.",
        Lore = "Un rempart impénétrable façonné par les vents polaires.",
        Cooldown = 10.0,
        Damage = 30,
        Range = 15,
        CastTime = 0.2,
        VFXColor = Color3.fromRGB(125, 211, 252),
    },
    swift_reflexes = {
        Id = "swift_reflexes",
        Name = "Réflexes Félins",
        Rarity = "Rare",
        Type = "Passive",
        Affinity = "Blade",
        Description = "+15% de vitesse de déplacement et esquive améliorée.",
        Lore = "Une seconde d'anticipation vaut mille armures.",
        PassiveStats = {
            BonusSpeed = 4,
            DodgeChancePercent = 8,
        },
    },

    -- =========================================================================
    -- PALIER ÉPIQUE (10% DROP)
    -- =========================================================================
    vortex_cleave = {
        Id = "vortex_cleave",
        Name = "Fendoir Tourbillonnant",
        Rarity = "Epic",
        Type = "Active",
        Affinity = "Blade",
        Description = "Tourbillonne avec férocité en aspirant les cibles avant de les projeter.",
        Lore = "L'ouragan né de la fureur du combattant ne connaît aucun répit.",
        Cooldown = 9.0,
        Damage = 85,
        Range = 18,
        CastTime = 0.2,
        VFXColor = Color3.fromRGB(168, 85, 247),
    },
    void_eruption = {
        Id = "void_eruption",
        Name = "Fissure du Vide",
        Rarity = "Epic",
        Type = "Active",
        Affinity = "Void",
        Description = "Ouvre une déchirure sombre au sol qui explose en geyser spectral.",
        Lore = "Le vide ne se contente pas d'absorber ; il dévore avec rage.",
        Cooldown = 9.5,
        Damage = 92,
        Range = 30,
        CastTime = 0.35,
        VFXColor = Color3.fromRGB(147, 51, 234),
    },
    inferno_pillar = {
        Id = "inferno_pillar",
        Name = "Colonne de Magma",
        Rarity = "Epic",
        Type = "Active",
        Affinity = "Fire",
        Description = "Fait jaillir 3 piliers de flammes ardentes sous les pieds de l'adversaire.",
        Lore = "La lave des profondeurs répond à la rage de l'invocateur.",
        Cooldown = 10.0,
        Damage = 105,
        Range = 35,
        CastTime = 0.3,
        VFXColor = Color3.fromRGB(220, 38, 38),
    },
    blizzard_storm = {
        Id = "blizzard_storm",
        Name = "Tempête d'Aurore",
        Rarity = "Epic",
        Type = "Active",
        Affinity = "Frost",
        Description = "Déclenche un blizzard gelant l'adversaire pendant 1.2s.",
        Lore = "Quand le ciel s'obscurcit de givre, tout mouvement cesse.",
        Cooldown = 11.0,
        Damage = 88,
        Range = 24,
        CastTime = 0.3,
        VFXColor = Color3.fromRGB(14, 165, 233),
    },
    blood_tribute = {
        Id = "blood_tribute",
        Name = "Pacte Sanguin",
        Rarity = "Epic",
        Type = "Passive",
        Affinity = "Void",
        Description = "Convertit 15% de tous les dégâts infligés en points de vie.",
        Lore = "La vie de l'adversaire nourrit la force du conquérant.",
        PassiveStats = {
            LifeStealPercent = 15,
        },
    },

    -- =========================================================================
    -- PALIER LÉGENDAIRE (4% DROP)
    -- =========================================================================
    sovereign_execution = {
        Id = "sovereign_execution",
        Name = "Exécution Souveraine",
        Rarity = "Legendary",
        Type = "Active",
        Affinity = "Blade",
        Description = "Estocade fulgurante. Inflige +40% de dégâts si la cible est sous 50% de PV.",
        Lore = "Le souverain ne discute pas ; il tranche et rétablit l'ordre.",
        Cooldown = 13.0,
        Damage = 145,
        Range = 22,
        CastTime = 0.25,
        VFXColor = Color3.fromRGB(245, 158, 11),
    },
    eclipse_cataclysm = {
        Id = "eclipse_cataclysm",
        Name = "Trou Noir de l'Éclipse",
        Rarity = "Legendary",
        Type = "Active",
        Affinity = "Void",
        Description = "Crée une singularité gravitationnelle qui attire violemment et compresse.",
        Lore = "Là où toute lumière abdique, seul subsiste le néant absolu.",
        Cooldown = 15.0,
        Damage = 160,
        Range = 32,
        CastTime = 0.4,
        VFXColor = Color3.fromRGB(124, 58, 237),
    },
    meteor_annihilation = {
        Id = "meteor_annihilation",
        Name = "Impact Météorique",
        Rarity = "Legendary",
        Type = "Active",
        Affinity = "Fire",
        Description = "Fait s'écraser un météore gigantesque embrasant l'arène entière.",
        Lore = "Les cieux eux-mêmes tremblent et s'effondrent sur les impies.",
        Cooldown = 16.0,
        Damage = 180,
        Range = 45,
        CastTime = 0.5,
        VFXColor = Color3.fromRGB(234, 88, 12),
    },
    archangels_wrath = {
        Id = "archangels_wrath",
        Name = "Courroux de l'Archange",
        Rarity = "Legendary",
        Type = "Active",
        Affinity = "Holy",
        Description = "Une pluie de 8 lames dorées célestes perfore la zone ciblée.",
        Lore = "La justice divine descend en épées de lumière étincelante.",
        Cooldown = 14.5,
        Damage = 165,
        Range = 35,
        CastTime = 0.35,
        VFXColor = Color3.fromRGB(250, 204, 21),
    },
    merit_catalyst = {
        Id = "merit_catalyst",
        Name = "Catalyseur de Gloire",
        Rarity = "Legendary",
        Type = "Passive",
        Affinity = "Holy",
        Description = "Augmente les dégâts de 1% pour chaque tranche de 100 Points de Mérite (Max +35%).",
        Lore = "Le véritable pouvoir ne s'achète pas ; il se gagne dans le sang de l'arène.",
        PassiveStats = {
            MeritScalingPercent = 35,
        },
    },

    -- =========================================================================
    -- PALIER MYTHIQUE (0.9% DROP)
    -- =========================================================================
    godslayer_judgment = {
        Id = "godslayer_judgment",
        Name = "Le Tranchant Déicide",
        Rarity = "Mythic",
        Type = "Active",
        Affinity = "Blade",
        Description = "Fend le continuum spatial en deux. Ignore 50% de l'armure et assomme.",
        Lore = "L'arme forgée pour terrasser les faux dieux de l'ancien monde.",
        Cooldown = 19.0,
        Damage = 250,
        Range = 28,
        CastTime = 0.3,
        VFXColor = Color3.fromRGB(239, 68, 68),
    },
    dominion_of_entropy = {
        Id = "dominion_of_entropy",
        Name = "Sphère d'Entropie Éternelle",
        Rarity = "Mythic",
        Type = "Active",
        Affinity = "Void",
        Description = "Embrase l'arène d'une tempête de néant drainant 220 PV et les transférant au lanceur.",
        Lore = "Tout ce qui a commencé doit finir. L'entropie est inéluctable.",
        Cooldown = 21.0,
        Damage = 220,
        Range = 30,
        CastTime = 0.45,
        VFXColor = Color3.fromRGB(162, 28, 175),
    },
    absolute_zero = {
        Id = "absolute_zero",
        Name = "Zéro Absolu",
        Rarity = "Mythic",
        Type = "Active",
        Affinity = "Frost",
        Description = "Arrête l'agitation thermique : inflige 230 dégâts et gèle net pendant 2.2s.",
        Lore = "Même les battements de cœur s'immobilisent sous le froid suprême.",
        Cooldown = 20.0,
        Damage = 230,
        Range = 26,
        CastTime = 0.3,
        VFXColor = Color3.fromRGB(6, 182, 212),
    },
    chrono_mastery = {
        Id = "chrono_mastery",
        Name = "Distorsion Temporelle",
        Rarity = "Mythic",
        Type = "Passive",
        Affinity = "Chrono",
        Description = "Réduit le temps de recharge de TOUTES les compétences de 25% et +12% esquive.",
        Lore = "Le temps n'est plus une contrainte mais une toile que vous peignez.",
        PassiveStats = {
            CooldownReductionPercent = 25,
            DodgeChancePercent = 12,
        },
    },

    -- =========================================================================
    -- PALIER DIVIN CÉLESTE (0.1% DROP - BROADCAST MONDIAL)
    -- =========================================================================
    primordial_severance = {
        Id = "primordial_severance",
        Name = "Fracture Primordiale de l'Infini",
        Rarity = "Divine",
        Type = "Active",
        Affinity = "Chrono",
        Description = "Déchire la réalité d'un rayon polychromatique. 380 dégâts, aveugle et ralentit 80%.",
        Lore = "L'attaque originelle qui sépara la lumière du néant à l'aube des temps.",
        Cooldown = 24.0,
        Damage = 380,
        Range = 50,
        CastTime = 0.4,
        VFXColor = Color3.fromRGB(250, 204, 21),
    },
    crown_of_the_sovereign = {
        Id = "crown_of_the_sovereign",
        Name = "Couronne du Vrai Souverain",
        Rarity = "Divine",
        Type = "Active",
        Affinity = "Holy",
        Description = "Confère une invulnérabilité totale pendant 2s, soigne 120 PV et explose à 320 dégâts.",
        Lore = "Celui qui porte cette couronne ne s'incline devant aucune loi mortelle.",
        Cooldown = 28.0,
        Damage = 320,
        Range = 30,
        CastTime = 0.2,
        VFXColor = Color3.fromRGB(253, 224, 71),
    },
    sovereign_ascendance = {
        Id = "sovereign_ascendance",
        Name = "Ascendance Infaillible",
        Rarity = "Divine",
        Type = "Passive",
        Affinity = "Holy",
        Description = "Empêche une mort fatale une fois par manche (laisse à 1 PV avec bouclier 2s) et +25% dégâts.",
        Lore = "Un empereur véritable ne meurt pas : il transcende la mortalité.",
        PassiveStats = {
            DamageBonusPercent = 25,
            BonusHealth = 100,
        },
    },
}

-- Liste des IDs pour un accès rapide
local AllCardIds = {}
for id in pairs(Cards) do
    table.insert(AllCardIds, id)
end
table.sort(AllCardIds)

return {
    Cards = Cards,
    AllIds = AllCardIds,
    GetCard = function(id: string): CardDefinition?
        return Cards[id]
    end,
}
