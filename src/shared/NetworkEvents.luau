--!strict
--[[
    NETWORK REMOTES & RPC CONTRACT
    Définition et initialisation des RemoteEvents et RemoteFunctions pour la réplication réseau client/serveur.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteFunctions = {
    "GetPlayerData",
    "RollGacha",
    "EquipDeck",
    "GetMarketListings",
    "ListMarketItem",
    "BuyMarketItem",
    "CancelMarketItem",
    "SendTradeRequest",
    "RespondTradeRequest",
    "ConfirmTrade",
    "JoinArenaQueue",
    "LeaveArenaQueue",
    "PrestigeCard",
    "RecycleCard",
    "DevAction",
    "RequestOpenPack",
}

local RemoteEvents = {
    "CastSkill",
    "PerformAction",        -- Dash (Q) / Parry (F)
    "UpdateTradeOffer",
    "CancelTrade",
    "ServerAnnouncement",   -- Broadcast mondial pour les cartes mythiques/divines
    "MatchStateChanged",    -- Info match (Countdown, VS, Round, Victory/Defeat)
    "CombatVFX",            -- Sync visuels d'impact, trails, explosions
    "ToastNotify",          -- Messages de succès/erreur au joueur
    "DamageIndicator",      -- Chiffres de dégâts 3D au-dessus de la cible
}

local Network = {}

local function GetFolder(): Folder
    local folder = ReplicatedStorage:FindFirstChild("NetworkRemotes") :: Folder?
    if not folder then
        if RunService:IsServer() then
            folder = Instance.new("Folder")
            folder.Name = "NetworkRemotes"
            folder.Parent = ReplicatedStorage
        else
            folder = ReplicatedStorage:WaitForChild("NetworkRemotes", 10) :: Folder
        end
    end
    return folder :: Folder
end

-- Initialisation côté Serveur
function Network.InitServer()
    local folder = GetFolder()
    for _, name in ipairs(RemoteFunctions) do
        if not folder:FindFirstChild(name) then
            local rf = Instance.new("RemoteFunction")
            rf.Name = name
            rf.Parent = folder
        end
    end
    for _, name in ipairs(RemoteEvents) do
        if not folder:FindFirstChild(name) then
            local re = Instance.new("RemoteEvent")
            re.Name = name
            re.Parent = folder
        end
    end
end

-- Récupération d'une RemoteFunction
function Network.GetFunction(name: string): RemoteFunction
    local folder = GetFolder()
    local rf = folder:WaitForChild(name, 10)
    assert(rf and rf:IsA("RemoteFunction"), "RemoteFunction absente: " .. name)
    return rf :: RemoteFunction
end

-- Récupération d'un RemoteEvent
function Network.GetEvent(name: string): RemoteEvent
    local folder = GetFolder()
    local re = folder:WaitForChild(name, 10)
    assert(re and re:IsA("RemoteEvent"), "RemoteEvent absent: " .. name)
    return re :: RemoteEvent
end

return Network
