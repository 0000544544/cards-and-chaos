--!strict
--[[
    MARKETPLACE & AUCTION HOUSE (HÔTEL DES VENTES & ACHAT-REVENTE)
    Système complet de Bourse des Cartes : mise en vente, achat instantané,
    taxe déflationniste de 5%, et historique des cours pour le trading/flipping.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local MarketConfig = require(game.ReplicatedStorage.Shared.MarketConfig)
local CardsData = require(game.ReplicatedStorage.Shared.CardsData)
local CardUtils = require(game.ReplicatedStorage.Shared.CardUtils)
local Network = require(game.ReplicatedStorage.Shared.NetworkEvents)
local DataManager = require(script.Parent.DataManager)

export type MarketListing = {
    ListingId: string,
    SellerUserId: number,
    SellerName: string,
    CardInstance: CardUtils.CardInstance,
    PriceCoins: number,
    ListedAt: number,
}

local MarketManager = {}
local ActiveListings: { [string]: MarketListing } = {}
local RecentSalesHistory: { [string]: { { Price: number, Timestamp: number } } } = {}

-- Récupérer la liste des ventes actives (avec filtres optionnels de rareté/prix)
function MarketManager.GetListings(rarityFilter: string?, maxPrice: number?): { MarketListing }
    local results = {}
    for _, listing in pairs(ActiveListings) do
        local def = CardsData.GetCard(listing.CardInstance.CardId)
        local matchRarity = (rarityFilter == nil or rarityFilter == "" or (def and def.Rarity == rarityFilter))
        local matchPrice = (maxPrice == nil or listing.PriceCoins <= maxPrice)

        if matchRarity and matchPrice then
            table.insert(results, listing)
        end
    end
    table.sort(results, function(a, b)
        return a.PriceCoins < b.PriceCoins
    end)
    return results
end

-- Mettre en vente une carte
function MarketManager.ListItem(player: Player, cardUniqueId: string, price: number): { Success: boolean, Error: string? }
    local profile = DataManager.GetProfile(player)
    if not profile then
        return { Success = false, Error = "Profil non chargé." }
    end

    price = math.floor(price)
    if price < MarketConfig.MinPriceCoins or price > MarketConfig.MaxPriceCoins then
        return { Success = false, Error = "Prix hors limites (" .. MarketConfig.MinPriceCoins .. " - " .. MarketConfig.MaxPriceCoins .. " Or)." }
    end

    -- Compter les ventes actives du joueur
    local count = 0
    for _, l in pairs(ActiveListings) do
        if l.SellerUserId == player.UserId then
            count += 1
        end
    end
    if count >= MarketConfig.MaxActiveListingsPerPlayer then
        return { Success = false, Error = "Limite d'annonces atteinte (" .. MarketConfig.MaxActiveListingsPerPlayer .. " max)." }
    end

    -- Trouver la carte dans l'inventaire
    local foundIndex: number? = nil
    local cardInstance: CardUtils.CardInstance? = nil

    for idx, card in ipairs(profile.Inventory) do
        if card.UniqueId == cardUniqueId then
            foundIndex = idx
            cardInstance = card
            break
        end
    end

    if not cardInstance or not foundIndex then
        return { Success = false, Error = "Carte introuvable dans votre inventaire." }
    end

    -- Empêcher la vente d'une carte équipée dans le deck
    for _, eqId in ipairs(profile.EquippedDeck.Actives) do
        if eqId == cardUniqueId then
            return { Success = false, Error = "Déséquipez d'abord cette carte de votre Deck." }
        end
    end
    for _, eqId in ipairs(profile.EquippedDeck.Passives) do
        if eqId == cardUniqueId then
            return { Success = false, Error = "Déséquipez d'abord cette carte de votre Deck." }
        end
    end

    -- Frais de mise en vente (1%)
    local listingFee = math.max(1, math.floor(price * (MarketConfig.ListingFeePercent / 100)))
    if profile.Coins < listingFee then
        return { Success = false, Error = "Or insuffisant pour régler les frais de mise en vente (" .. listingFee .. " Or)." }
    end
    profile.Coins -= listingFee

    -- Retrait de l'inventaire vers le séquestre du marché
    table.remove(profile.Inventory, foundIndex)

    local listingId = HttpService:GenerateGUID(false)
    local listing: MarketListing = {
        ListingId = listingId,
        SellerUserId = player.UserId,
        SellerName = player.Name,
        CardInstance = cardInstance,
        PriceCoins = price,
        ListedAt = os.time(),
    }

    ActiveListings[listingId] = listing
    return { Success = true }
end

-- Acheter une carte instantanément (Buyout)
function MarketManager.BuyItem(buyer: Player, listingId: string): { Success: boolean, Error: string? }
    local buyerProfile = DataManager.GetProfile(buyer)
    if not buyerProfile then
        return { Success = false, Error = "Profil non chargé." }
    end

    local listing = ActiveListings[listingId]
    if not listing then
        return { Success = false, Error = "Cette annonce a déjà été vendue ou annulée." }
    end

    if listing.SellerUserId == buyer.UserId then
        return { Success = false, Error = "Vous ne pouvez pas acheter votre propre carte." }
    end

    if buyerProfile.Coins < listing.PriceCoins then
        return { Success = false, Error = "Or insuffisant pour cet achat." }
    end

    -- Retrait de l'annonce du marché
    ActiveListings[listingId] = nil

    -- Débit de l'acheteur
    buyerProfile.Coins -= listing.PriceCoins

    -- Calcul de la taxe déflationniste (5% brûlés définitivement)
    local taxAmount = math.floor(listing.PriceCoins * (MarketConfig.TaxRatePercent / 100))
    local sellerNetGain = listing.PriceCoins - taxAmount

    -- Transfert des fonds au vendeur (en ligne ou hors ligne)
    local sellerPlayer = Players:GetPlayerByUserId(listing.SellerUserId)
    if sellerPlayer then
        local sellerProfile = DataManager.GetProfile(sellerPlayer)
        if sellerProfile then
            sellerProfile.Coins += sellerNetGain
            sellerProfile.Stats.MarketSales += 1
            local toast = Network.GetEvent("ToastNotify")
            toast:FireClient(sellerPlayer, "Votre carte a été vendue pour " .. sellerNetGain .. " Or (Taxe 5% déduite).")
        end
    end

    -- Ajout de la carte achetée à l'inventaire de l'acheteur
    table.insert(buyerProfile.Inventory, listing.CardInstance)

    -- Enregistrement dans l'historique des cours (permet aux traders de surveiller les prix moyens)
    local cardId = listing.CardInstance.CardId
    if not RecentSalesHistory[cardId] then
        RecentSalesHistory[cardId] = {}
    end
    table.insert(RecentSalesHistory[cardId], { Price = listing.PriceCoins, Timestamp = os.time() })

    return { Success = true }
end

-- Annuler sa propre vente
function MarketManager.CancelItem(player: Player, listingId: string): { Success: boolean, Error: string? }
    local profile = DataManager.GetProfile(player)
    if not profile then return { Success = false, Error = "Profil non chargé." } end

    local listing = ActiveListings[listingId]
    if not listing then return { Success = false, Error = "Annonce inexistante." } end

    if listing.SellerUserId ~= player.UserId then
        return { Success = false, Error = "Vous n'êtes pas le propriétaire de cette annonce." }
    end

    ActiveListings[listingId] = nil
    table.insert(profile.Inventory, listing.CardInstance)
    return { Success = true }
end

function MarketManager.Init()
    local getListingsRF = Network.GetFunction("GetMarketListings")
    getListingsRF.OnServerInvoke = function(player: Player, rarityFilter: any, maxPrice: any)
        return MarketManager.GetListings(rarityFilter, maxPrice)
    end

    local listRF = Network.GetFunction("ListMarketItem")
    listRF.OnServerInvoke = function(player: Player, cardUniqueId: any, price: any)
        return MarketManager.ListItem(player, tostring(cardUniqueId), tonumber(price) or 0)
    end

    local buyRF = Network.GetFunction("BuyMarketItem")
    buyRF.OnServerInvoke = function(player: Player, listingId: any)
        return MarketManager.BuyItem(player, tostring(listingId))
    end

    local cancelRF = Network.GetFunction("CancelMarketItem")
    cancelRF.OnServerInvoke = function(player: Player, listingId: any)
        return MarketManager.CancelItem(player, tostring(listingId))
    end
end

return MarketManager
