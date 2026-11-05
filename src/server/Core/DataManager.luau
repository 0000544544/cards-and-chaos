--!strict
--[[
    CARDS & CHAOS - GESTIONNAIRE DE DONNÉES & PROFILS JOUEURS
    Fichier : src/server/Core/DataManager.luau (Script Serveur)
    Gère la persistance DataStore, les leaderstats, et l'accès client via RemoteFunction.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

export type PlayerProfile = {
    Gold: number,
    Merit: number,
    Inventory: { string },
    EquippedDeck: { string },
}

local DATASTORE_NAME = "CardsAndChaos_PlayerData_v1"
local DataStoreInstance: DataStore? = nil

-- Initialisation sécurisée du DataStore (avec fallback mémoire immédiat en Studio local)
local function InitDataStore()
    if game.PlaceId == 0 or game.JobId == "" then
        DataStoreInstance = nil
        print("[DataManager] Mode Studio local détecté. Utilisation du cache mémoire instantané.")
        return
    end

    local success, store = pcall(function()
        return DataStoreService:GetDataStore(DATASTORE_NAME)
    end)

    if success and store then
        DataStoreInstance = store
        print("[DataManager] DataStore connecté : " .. DATASTORE_NAME)
    else
        warn("[DataManager] DataStore indisponible. Utilisation du cache mémoire.")
    end
end

InitDataStore()

local DataManager = {}
local Profiles: { [Player]: PlayerProfile } = {}

-- Création du profil par défaut (500 Or, 1000 Mérite, 2 sorts de départ)
local function CreateDefaultProfile(): PlayerProfile
    return {
        Gold = 500,
        Merit = 1000,
        Inventory = { "bouclier_egide", "orbe_chaos" },
        EquippedDeck = { "bouclier_egide", "orbe_chaos" },
    }
end

-- Création ou récupération du dossier Remotes et de la RemoteFunction GetPlayerData
local function SetupNetworking(): RemoteFunction
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes") :: Folder?
    if not remotesFolder then
        remotesFolder = Instance.new("Folder")
        remotesFolder.Name = "Remotes"
        remotesFolder.Parent = ReplicatedStorage
    end

    local getPlayerDataRF = remotesFolder:FindFirstChild("GetPlayerData") :: RemoteFunction?
    if not getPlayerDataRF then
        getPlayerDataRF = Instance.new("RemoteFunction")
        getPlayerDataRF.Name = "GetPlayerData"
        getPlayerDataRF.Parent = remotesFolder
    end

    return getPlayerDataRF
end

local GetPlayerDataRF = SetupNetworking()

-- Configuration des leaderstats pour l'affichage visuel en jeu
local function SetupLeaderstats(player: Player, profile: PlayerProfile)
    local leaderstats = player:FindFirstChild("leaderstats") :: Folder?
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end

    local goldVal = leaderstats:FindFirstChild("Gold") :: IntValue?
    if not goldVal then
        goldVal = Instance.new("IntValue")
        goldVal.Name = "Gold"
        goldVal.Parent = leaderstats
    end
    goldVal.Value = profile.Gold

    local meritVal = leaderstats:FindFirstChild("Merit") :: IntValue?
    if not meritVal then
        meritVal = Instance.new("IntValue")
        meritVal.Name = "Merit"
        meritVal.Parent = leaderstats
    end
    meritVal.Value = profile.Merit
end

-- Chargement du profil joueur (avec persistance DataStore)
function DataManager.LoadProfile(player: Player): PlayerProfile
    local key = "Player_" .. player.UserId
    local profile: PlayerProfile? = nil

    if DataStoreInstance then
        local success, data = pcall(function()
            return DataStoreInstance:GetAsync(key)
        end)
        if success and data and type(data) == "table" then
            profile = {
                Gold = tonumber(data.Gold) or 500,
                Merit = tonumber(data.Merit) or 1000,
                Inventory = (type(data.Inventory) == "table" and data.Inventory) or { "bouclier_egide", "orbe_chaos" },
                EquippedDeck = (type(data.EquippedDeck) == "table" and data.EquippedDeck) or { "bouclier_egide", "orbe_chaos" },
            }
        end
    end

    if not profile then
        profile = CreateDefaultProfile()
    end

    Profiles[player] = profile
    SetupLeaderstats(player, profile)

    print(string.format("[DataManager] Profil chargé pour %s | Gold: %d | Merit: %d", player.Name, profile.Gold, profile.Merit))
    return profile
end

-- Sauvegarde du profil joueur
function DataManager.SaveProfile(player: Player): boolean
    local profile = Profiles[player]
    if not profile then return false end
    if not DataStoreInstance then return true end

    local key = "Player_" .. player.UserId
    local success, err = pcall(function()
        DataStoreInstance:SetAsync(key, profile)
    end)

    if not success then
        warn(string.format("[DataManager] Erreur de sauvegarde pour %s : %s", player.Name, tostring(err)))
        return false
    end
    return true
end

-- Libération du profil à la déconnexion
function DataManager.ReleaseProfile(player: Player)
    DataManager.SaveProfile(player)
    Profiles[player] = nil
end

-- Accès au profil
function DataManager.GetProfile(player: Player): PlayerProfile
    if not Profiles[player] then
        return DataManager.LoadProfile(player)
    end
    return Profiles[player]
end

-- Ajout d'or avec mise à jour automatique des leaderstats
function DataManager.AddGold(player: Player, amount: number)
    local profile = Profiles[player]
    if profile and amount ~= 0 then
        profile.Gold = math.max(0, profile.Gold + math.floor(amount))
        local leaderstats = player:FindFirstChild("leaderstats")
        local goldVal = leaderstats and leaderstats:FindFirstChild("Gold") :: IntValue?
        if goldVal then
            goldVal.Value = profile.Gold
        end
    end
end

-- Ajout de mérite avec mise à jour automatique des leaderstats
function DataManager.AddMerit(player: Player, amount: number)
    local profile = Profiles[player]
    if profile and amount ~= 0 then
        profile.Merit = math.max(0, profile.Merit + math.floor(amount))
        local leaderstats = player:FindFirstChild("leaderstats")
        local meritVal = leaderstats and leaderstats:FindFirstChild("Merit") :: IntValue?
        if meritVal then
            meritVal.Value = profile.Merit
        end
    end
end

-- Connexion de la RemoteFunction pour renvoyer le profil au client
GetPlayerDataRF.OnServerInvoke = function(player: Player)
    return DataManager.GetProfile(player)
end

-- Écouteurs de cycle de vie des joueurs
Players.PlayerAdded:Connect(function(player: Player)
    DataManager.LoadProfile(player)
end)

Players.PlayerRemoving:Connect(function(player: Player)
    DataManager.ReleaseProfile(player)
end)

-- Prise en compte des joueurs déjà présents au lancement
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        DataManager.LoadProfile(player)
    end)
end

-- Sauvegarde d'urgence lors de l'arrêt du serveur
game:BindToClose(function()
    print("[DataManager] Arrêt du serveur : sauvegarde de sécurité de tous les profils...")
    for _, player in ipairs(Players:GetPlayers()) do
        DataManager.SaveProfile(player)
    end
end)

print("[DataManager] Initialisé avec succès (DataStore, leaderstats, Remotes/GetPlayerData).")

return DataManager
