--!strict
--[[
    CARDS & CHAOS - RÉSEAU RPC & REMOTES (CLIENT / SERVEUR)
    Contrat unique des RemoteFunctions et RemoteEvents.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteFunctions = {
    "GetPlayerData",
    "RequestOpenPack",
    "EquipCard",
    "GetMarketListings",
    "ListMarketItem",
    "BuyMarketItem",
    "ClaimRankReward",
    "JoinArenaQueue",
    "LeaveArenaQueue",
    "TalkToNPC",
}

local RemoteEvents = {
    "CastSpell",            -- Déclenchement d'un sort ou du dash (Slot 1-5 + TargetPos)
    "ToastNotify",          -- Notifications de feedback joueur (Succès/Erreur)
    "ServerAnnouncement",   -- Alerte mondiale (Tirage Légendaire, etc.)
    "MatchStateChanged",    -- États du duel d'arène (VS, Countdown, Fight, Victory, Defeat)
}

local NetworkEvents = {}

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

function NetworkEvents.InitServer()
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

function NetworkEvents.GetFunction(name: string): RemoteFunction
    local folder = GetFolder()
    local rf = folder:WaitForChild(name, 10)
    assert(rf and rf:IsA("RemoteFunction"), "RemoteFunction absente : " .. name)
    return rf :: RemoteFunction
end

function NetworkEvents.GetEvent(name: string): RemoteEvent
    local folder = GetFolder()
    local re = folder:WaitForChild(name, 10)
    assert(re and re:IsA("RemoteEvent"), "RemoteEvent absent : " .. name)
    return re :: RemoteEvent
end

return NetworkEvents
