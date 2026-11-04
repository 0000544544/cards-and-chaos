--!strict
--[[
    MARKET & ECONOMY CONFIGURATION
    Règles de l'Hôtel des Ventes (Marché), achat-revente, taxes déflationnistes et échanges P2P.
]]

export type MarketConfigType = {
    TaxRatePercent: number,          -- 5% prélevés sur chaque vente pour brûler la monnaie
    ListingFeePercent: number,      -- 1% payé à la mise en vente
    ListingDurationHours: number,   -- 24 heures de validité
    MaxActiveListingsPerPlayer: number,
    MinPriceCoins: number,
    MaxPriceCoins: number,
    TradeCountdownSeconds: number,  -- Sécurité anti-arnaque 3 secondes
}

local MarketConfig: MarketConfigType = {
    TaxRatePercent = 5,
    ListingFeePercent = 1,
    ListingDurationHours = 24,
    MaxActiveListingsPerPlayer = 10,
    MinPriceCoins = 20,
    MaxPriceCoins = 10000000,
    TradeCountdownSeconds = 3,
}

return MarketConfig
