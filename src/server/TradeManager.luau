--!strict
--[[
    PEER-TO-PEER TRADE MANAGER (ÉCHANGES SÉCURISÉS)
    Système d'échange direct entre joueurs avec vérification en deux étapes,
    compte à rebours de 3 secondes et transaction atomique sans risque de duplication.
]]

local Players = game:GetService("Players")

local CardUtils = require(game.ReplicatedStorage.Shared.CardUtils)
local Network = require(game.ReplicatedStorage.Shared.NetworkEvents)
local DataManager = require(script.Parent.DataManager)

export type TradeParticipant = {
    Player: Player,
    OfferedCardUniqueIds: { string },
    OfferedCoins: number,
    IsLocked: boolean,
    IsConfirmed: boolean,
}

export type TradeSession = {
    SessionId: string,
    Party1: TradeParticipant,
    Party2: TradeParticipant,
    CountdownTask: thread?,
    IsFinalized: boolean,
}

local TradeManager = {}
local ActiveSessions: { [string]: TradeSession } = {}
local PlayerToSession: { [Player]: TradeSession } = {}

-- Trouver la session d'un joueur
local function GetSession(player: Player): TradeSession?
    return PlayerToSession[player]
end

-- Création d'une nouvelle session d'échange
function TradeManager.StartSession(p1: Player, p2: Player): TradeSession
    local sessionId = p1.UserId .. "_" .. p2.UserId .. "_" .. os.time()
    local session: TradeSession = {
        SessionId = sessionId,
        Party1 = {
            Player = p1,
            OfferedCardUniqueIds = {},
            OfferedCoins = 0,
            IsLocked = false,
            IsConfirmed = false,
        },
        Party2 = {
            Player = p2,
            OfferedCardUniqueIds = {},
            OfferedCoins = 0,
            IsLocked = false,
            IsConfirmed = false,
        },
        IsFinalized = false,
    }

    ActiveSessions[sessionId] = session
    PlayerToSession[p1] = session
    PlayerToSession[p2] = session

    return session
end

-- Annuler un échange
function TradeManager.AbortSession(session: TradeSession, reason: string?)
    if session.IsFinalized then return end
    session.IsFinalized = true

    if session.CountdownTask then
        task.cancel(session.CountdownTask)
    end

    ActiveSessions[session.SessionId] = nil
    PlayerToSession[session.Party1.Player] = nil
    PlayerToSession[session.Party2.Player] = nil

    local cancelEv = Network.GetEvent("CancelTrade")
    cancelEv:FireClient(session.Party1.Player, reason or "Échange annulé.")
    cancelEv:FireClient(session.Party2.Player, reason or "Échange annulé.")
end

-- Mise à jour des offres (cartes ou or)
function TradeManager.UpdateOffer(player: Player, cardUniqueIds: { string }, coins: number)
    local session = GetSession(player)
    if not session or session.IsFinalized then return end

    local party = (session.Party1.Player == player) and session.Party1 or session.Party2
    local otherParty = (session.Party1.Player == player) and session.Party2 or session.Party1

    party.OfferedCardUniqueIds = cardUniqueIds
    party.OfferedCoins = math.max(0, math.floor(coins))

    -- Toute modification annule le verrouillage des deux côtés (sécurité anti-arnaque)
    party.IsLocked = false
    party.IsConfirmed = false
    otherParty.IsLocked = false
    otherParty.IsConfirmed = false

    if session.CountdownTask then
        task.cancel(session.CountdownTask)
        session.CountdownTask = nil
    end

    local updateEv = Network.GetEvent("UpdateTradeOffer")
    updateEv:FireClient(session.Party1.Player, {
        YourOffer = session.Party1,
        TheirOffer = session.Party2,
    })
    updateEv:FireClient(session.Party2.Player, {
        YourOffer = session.Party2,
        TheirOffer = session.Party1,
    })
end

-- Verrouiller et Confirmer l'échange
function TradeManager.ConfirmTrade(player: Player): boolean
    local session = GetSession(player)
    if not session or session.IsFinalized then return false end

    local party = (session.Party1.Player == player) and session.Party1 or session.Party2
    local otherParty = (session.Party1.Player == player) and session.Party2 or session.Party1

    if not party.IsLocked then
        party.IsLocked = true
    else
        party.IsConfirmed = true
    end

    -- Si les deux ont verrouillé, on lance le compte à rebours de sécurité de 3 secondes
    if session.Party1.IsLocked and session.Party2.IsLocked and not session.CountdownTask then
        session.CountdownTask = task.spawn(function()
            task.wait(3)
            -- Si les deux confirment après le compte à rebours, transaction atomique
            if session.Party1.IsConfirmed and session.Party2.IsConfirmed and not session.IsFinalized then
                TradeManager.ExecuteSwap(session)
            end
        end)
    end

    return true
end

-- Exécution atomique de l'échange
function TradeManager.ExecuteSwap(session: TradeSession)
    session.IsFinalized = true
    local p1 = session.Party1.Player
    local p2 = session.Party2.Player

    local prof1 = DataManager.GetProfile(p1)
    local prof2 = DataManager.GetProfile(p2)

    if not prof1 or not prof2 then
        TradeManager.AbortSession(session, "Profil manquant lors de la transaction.")
        return
    end

    -- Vérification des fonds
    if prof1.Coins < session.Party1.OfferedCoins or prof2.Coins < session.Party2.OfferedCoins then
        TradeManager.AbortSession(session, "Fonds insuffisants lors de la transaction.")
        return
    end

    -- Échange d'or
    prof1.Coins = prof1.Coins - session.Party1.OfferedCoins + session.Party2.OfferedCoins
    prof2.Coins = prof2.Coins - session.Party2.OfferedCoins + session.Party1.OfferedCoins

    -- Déplacement des cartes de P1 vers P2
    local function ExtractCards(profile: DataManager.PlayerProfile, uids: { string }): { CardUtils.CardInstance }
        local extracted = {}
        for _, uid in ipairs(uids) do
            for i = #profile.Inventory, 1, -1 do
                if profile.Inventory[i].UniqueId == uid then
                    table.insert(extracted, table.remove(profile.Inventory, i))
                    break
                end
            end
        end
        return extracted
    end

    local cardsFrom1 = ExtractCards(prof1, session.Party1.OfferedCardUniqueIds)
    local cardsFrom2 = ExtractCards(prof2, session.Party2.OfferedCardUniqueIds)

    for _, c in ipairs(cardsFrom1) do
        table.insert(prof2.Inventory, c)
    end
    for _, c in ipairs(cardsFrom2) do
        table.insert(prof1.Inventory, c)
    end

    prof1.Stats.CardsTraded += #cardsFrom1
    prof2.Stats.CardsTraded += #cardsFrom2

    TradeManager.AbortSession(session, "Échange finalisé avec succès !")
end

function TradeManager.Init()
    local confirmRF = Network.GetFunction("ConfirmTrade")
    confirmRF.OnServerInvoke = function(player: Player)
        return TradeManager.ConfirmTrade(player)
    end

    local updateOfferRE = Network.GetEvent("UpdateTradeOffer")
    updateOfferRE.OnServerEvent:Connect(function(player: Player, data: any)
        if type(data) == "table" then
            TradeManager.UpdateOffer(player, data.CardUniqueIds or {}, data.Coins or 0)
        end
    end)

    Players.PlayerRemoving:Connect(function(player: Player)
        local session = GetSession(player)
        if session then
            TradeManager.AbortSession(session, player.Name .. " a quitté la partie.")
        end
    end)
end

return TradeManager
