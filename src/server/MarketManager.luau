--!strict
--[[
    CARDS & CHAOS - HÔTEL DES VENTES & MARCHÉ NOIR (SERVEUR)
    4 Offres de base du Marché Noir + Ventes entre joueurs avec taxe de 5%.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardsDatabase = require(ReplicatedStorage.Shared.CardsDatabase)
local NetworkEvents = require(ReplicatedStorage.Shared.NetworkEvents)
local DataManager = require(script.Parent.DataManager)

export type MarketListing = {
    ListingId: string,
    SellerUserId: number,
    SellerName: string,
    CardId: string,
    CardName: string,
    Rarity: string,
    Price: number,
    IsNPC: boolean,
}

local MarketManager = {}
local Listings: { [string]: MarketListing } = {}

-- Initialisation des 4 offres par défaut du Marché Noir
local function InitDefaultListings()
    local defaultOffers = {
        { Id = "pyro_meteor", Seller = "Maître Eldrin", Price = 650 },
        { Id = "void_chain", Seller = "L'Ombre de la Crypte", Price = 400 },
        { Id = "thunder_step", Seller = "Recrue Stellaire", Price = 250 },
        { Id = "sovereign_aegis", Seller = "Gardien d'Obsidienne", Price = 450 },
    }

    for _, offer in ipairs(defaultOffers) do
        local def = CardsDatabase.GetCard(offer.Id)
        if def then
            local lId = "NPC_" .. offer.Id
            Listings[lId] = {
                ListingId = lId,
                SellerUserId = 0,
                SellerName = offer.Seller,
                CardId = def.Id,
                CardName = def.Name,
                Rarity = def.Rarity,
                Price = offer.Price,
                IsNPC = true,
            }
        end
    end
end

function MarketManager.GetListings()
    local list = {}
    for _, l in pairs(Listings) do
        table.insert(list, l)
    end
    table.sort(list, function(a, b)
        return a.Price < b.Price
    end)
    return list
end

function MarketManager.ListItem(player: Player, cardId: string, price: number)
    local prof = DataManager.GetProfile(player)
    if not prof then return { Success = false, Error = "Profil non chargé." } end

    price = math.floor(price)
    if price < 50 or price > 100000 then
        return { Success = false, Error = "Prix invalide (entre 50 et 100,000 Or)." }
    end

    -- Trouve et retire la carte de l'inventaire
    local foundIdx: number? = nil
    local cardName = ""
    local rarity = ""
    for idx, c in ipairs(prof.Inventory) do
        if c.CardId == cardId then
            foundIdx = idx
            cardName = c.Name
            rarity = c.Rarity
            break
        end
    end

    if not foundIdx then
        return { Success = false, Error = "Vous ne possédez pas cette carte." }
    end

    -- Empêche de vendre une carte équipée
    for _, eqId in ipairs(prof.EquippedDeck) do
        if eqId == cardId then
            return { Success = false, Error = "Déséquipez d'abord cette carte de vos 4 slots." }
        end
    end

    table.remove(prof.Inventory, foundIdx)

    local lId = HttpService:GenerateGUID(false)
    Listings[lId] = {
        ListingId = lId,
        SellerUserId = player.UserId,
        SellerName = player.Name,
        CardId = cardId,
        CardName = cardName,
        Rarity = rarity,
        Price = price,
        IsNPC = false,
    }

    return { Success = true }
end

function MarketManager.BuyItem(buyer: Player, listingId: string)
    local buyerProf = DataManager.GetProfile(buyer)
    if not buyerProf then return { Success = false, Error = "Profil non chargé." } end

    local listing = Listings[listingId]
    if not listing then return { Success = false, Error = "Offre expirée ou déjà vendue." } end

    if listing.SellerUserId == buyer.UserId then
        return { Success = false, Error = "Vous ne pouvez pas acheter votre propre offre." }
    end

    if buyerProf.Coins < listing.Price then
        return { Success = false, Error = "Or insuffisant." }
    end

    -- Déduction de l'acheteur
    DataManager.DeductCoins(buyer, listing.Price)

    -- Si offre joueur : versement au vendeur moins 5% de taxe
    if not listing.IsNPC and listing.SellerUserId > 0 then
        local tax = math.floor(listing.Price * 0.05)
        local netGain = listing.Price - tax
        local sellerPlayer = Players:GetPlayerByUserId(listing.SellerUserId)
        if sellerPlayer then
            DataManager.AddCoins(sellerPlayer, netGain)
            local toast = NetworkEvents.GetEvent("ToastNotify")
            toast:FireClient(sellerPlayer, "Votre carte '" .. listing.CardName .. "' a été vendue pour " .. netGain .. " Or !")
        end
    end

    -- Attribution de la carte à l'acheteur
    DataManager.AddCard(buyer, listing.CardId)

    -- Si offre joueur, retrait du marché. Si offre PNJ, elle reste disponible
    if not listing.IsNPC then
        Listings[listingId] = nil
    end

    return { Success = true, RemainingCoins = buyerProf.Coins }
end

function MarketManager.Init()
    InitDefaultListings()

    local getRF = NetworkEvents.GetFunction("GetMarketListings")
    getRF.OnServerInvoke = function()
        return MarketManager.GetListings()
    end

    local listRF = NetworkEvents.GetFunction("ListMarketItem")
    listRF.OnServerInvoke = function(player: Player, cardId: any, price: any)
        return MarketManager.ListItem(player, tostring(cardId), tonumber(price) or 0)
    end

    local buyRF = NetworkEvents.GetFunction("BuyMarketItem")
    buyRF.OnServerInvoke = function(player: Player, listingId: any)
        return MarketManager.BuyItem(player, tostring(listingId))
    end

    print("[MarketManager] Marché Noir et Hôtel des Ventes initialisés.")
end

return MarketManager
