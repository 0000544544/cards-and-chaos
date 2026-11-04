--!strict
--[[
    RANK & MERIT CONFIGURATION
    Paliers de classement compétitif (Elo/MMR), gains de Mérite et bonus de série de victoires.
]]

export type TierInfo = {
    Id: string,
    Name: string,
    MinElo: number,
    Color: Color3,
    MeritMultiplier: number,
    SeasonEndRewardCoins: number,
    BadgeIcon: string,
}

local Ranks: { TierInfo } = {
    {
        Id = "Bronze",
        Name = "Bronze",
        MinElo = 0,
        Color = Color3.fromRGB(180, 115, 60),
        MeritMultiplier = 1.0,
        SeasonEndRewardCoins = 500,
        BadgeIcon = "rbxassetid://6031075938",
    },
    {
        Id = "Silver",
        Name = "Argent",
        MinElo = 1000,
        Color = Color3.fromRGB(192, 192, 205),
        MeritMultiplier = 1.2,
        SeasonEndRewardCoins = 1500,
        BadgeIcon = "rbxassetid://6031075938",
    },
    {
        Id = "Gold",
        Name = "Or",
        MinElo = 1500,
        Color = Color3.fromRGB(245, 200, 66),
        MeritMultiplier = 1.5,
        SeasonEndRewardCoins = 3500,
        BadgeIcon = "rbxassetid://6031075938",
    },
    {
        Id = "Platinum",
        Name = "Platine",
        MinElo = 2000,
        Color = Color3.fromRGB(45, 212, 191),
        MeritMultiplier = 1.85,
        SeasonEndRewardCoins = 7000,
        BadgeIcon = "rbxassetid://6031075938",
    },
    {
        Id = "Diamond",
        Name = "Diamant",
        MinElo = 2500,
        Color = Color3.fromRGB(96, 165, 250),
        MeritMultiplier = 2.25,
        SeasonEndRewardCoins = 15000,
        BadgeIcon = "rbxassetid://6031075938",
    },
    {
        Id = "Master",
        Name = "Maître Suprême",
        MinElo = 3000,
        Color = Color3.fromRGB(217, 70, 239),
        MeritMultiplier = 2.8,
        SeasonEndRewardCoins = 30000,
        BadgeIcon = "rbxassetid://6031075938",
    },
    {
        Id = "Sovereign",
        Name = "LE SOUVERAIN",
        MinElo = 3500,
        Color = Color3.fromRGB(251, 191, 36),
        MeritMultiplier = 3.5,
        SeasonEndRewardCoins = 100000,
        BadgeIcon = "rbxassetid://6031075938",
    },
}

-- Formule Elo standard (Chess/FIDE K=32)
local function CalculateEloDelta(ratingA: number, ratingB: number, actualScoreA: number, kFactor: number?): (number, number)
    local K = kFactor or 32
    local expectedScoreA = 1 / (1 + 10 ^ ((ratingB - ratingA) / 400))
    local expectedScoreB = 1 - expectedScoreA
    local actualScoreB = 1 - actualScoreA

    local deltaA = math.round(K * (actualScoreA - expectedScoreA))
    local deltaB = math.round(K * (actualScoreB - expectedScoreB))
    return deltaA, deltaB
end

-- Calculateur de rang selon l'Elo
local function GetTierFromElo(elo: number): TierInfo
    local currentTier = Ranks[1]
    for _, tier in ipairs(Ranks) do
        if elo >= tier.MinElo then
            currentTier = tier
        end
    end
    return currentTier
end

-- Récompenses compétitives par match
local MatchRewards = {
    BaseWinMerit = 25,
    BaseLossMerit = 5,       -- Même en perdant, l'effort et l'apprentissage sont récompensés
    BaseWinCoins = 150,
    BaseLossCoins = 40,
    StreakBonusPerWin = 5,   -- +5 Mérite par victoire consécutive
    MaxStreakBonus = 50,     -- Plafond du bonus de série
    PerfectRoundMeritBonus = 20, -- Victoire sans subir de dégâts
}

-- Coûts de Transcendance du Mérite (Prestige)
local MeritPrestige = {
    CostPerCard = 500,      -- Points de Mérite nécessaires pour rendre une carte "Prestige"
    StatBoostPercent = 20,  -- +20% d'efficacité
    UnlocksExclusiveBorder = true,
}

return {
    Tiers = Ranks,
    GetTierFromElo = GetTierFromElo,
    CalculateEloDelta = CalculateEloDelta,
    Rewards = MatchRewards,
    Prestige = MeritPrestige,
}
