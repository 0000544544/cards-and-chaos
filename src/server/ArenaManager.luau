--!strict
--[[
    ARENA MANAGER (COMPÉTITION 1V1, MATCHMAKING & CLASSEMENT ELO)
    Gestion des files d'attente compétitives, téléportation dans le Colisée Céleste,
    déroulement du duel, calcul Elo (K=32), attribution du Mérite et anti-abandon.
]]

local Players = game:GetService("Players")

local RankConfig = require(game.ReplicatedStorage.Shared.RankConfig)
local Network = require(game.ReplicatedStorage.Shared.NetworkEvents)
local DataManager = require(script.Parent.DataManager)

export type ActiveMatch = {
    Player1: Player,
    Player2: Player,
    StartTime: number,
    RoundTimeLimit: number,
    MatchThread: thread?,
    IsActive: boolean,
}

local ArenaManager = {}
local Queue: { Player } = {}
local CurrentMatches: { [string]: ActiveMatch } = {}

-- Coordonnées par défaut de l'arène (construits par MapBuilder)
local ARENA_SPAWN_1 = Vector3.new(0, 105, 45)
local ARENA_SPAWN_2 = Vector3.new(0, 105, -45)
local LOBBY_SPAWN = Vector3.new(0, 5, 0)

-- Rejoindre la file d'attente
function ArenaManager.JoinQueue(player: Player): { Success: boolean, Message: string }
    for _, p in ipairs(Queue) do
        if p == player then
            return { Success = false, Message = "Déjà dans la file d'attente." }
        end
    end

    table.insert(Queue, player)
    
    -- Si le joueur est seul sur le serveur (ex: test solo en Studio), duel automatique contre l'IA du Colisée !
    if #Players:GetPlayers() == 1 then
        table.remove(Queue, 1)
        task.delay(0.5, function()
            ArenaManager.StartBotMatch(player)
        end)
        return { Success = true, Message = "Aucun joueur en ligne : Lancement du duel contre le Spectre du Champion (IA) !" }
    end

    ArenaManager.CheckQueue()
    return { Success = true, Message = "Recherche d'un adversaire..." }
end

-- Démarrage d'un duel contre un Bot IA d'entraînement
function ArenaManager.StartBotMatch(player: Player)
    local prof = DataManager.GetProfile(player)
    if not prof then return end

    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid") :: Humanoid
    local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart

    -- Création du Bot de Combat
    local botModel = Instance.new("Model")
    botModel.Name = "Spectre_du_Champion"
    botModel.Parent = workspace

    local botHrp = Instance.new("Part")
    botHrp.Name = "HumanoidRootPart"
    botHrp.Size = Vector3.new(2, 2, 1)
    botHrp.CFrame = CFrame.lookAt(ARENA_SPAWN_2, ARENA_SPAWN_1)
    botHrp.CanCollide = false
    botHrp.Parent = botModel

    local botTorso = Instance.new("Part")
    botTorso.Name = "Torso"
    botTorso.Size = Vector3.new(2, 2.5, 1)
    botTorso.Position = ARENA_SPAWN_2
    botTorso.Material = Enum.Material.Neon
    botTorso.Color = Color3.fromRGB(168, 85, 247)
    botTorso.Parent = botModel

    local botHead = Instance.new("Part")
    botHead.Name = "Head"
    botHead.Shape = Enum.PartType.Ball
    botHead.Size = Vector3.new(1.6, 1.6, 1.6)
    botHead.Position = ARENA_SPAWN_2 + Vector3.new(0, 2, 0)
    botHead.Material = Enum.Material.Neon
    botHead.Color = Color3.fromRGB(250, 204, 21)
    botHead.Parent = botModel

    local botHum = Instance.new("Humanoid")
    botHum.MaxHealth = 150
    botHum.Health = 150
    botHum.Parent = botModel
    botModel.PrimaryPart = botHrp

    -- Téléportation du joueur dans l'arène
    hrp.CFrame = CFrame.lookAt(ARENA_SPAWN_1, ARENA_SPAWN_2)
    hum.Health = hum.MaxHealth
    hum.WalkSpeed = 0

    local matchStateEv = Network.GetEvent("MatchStateChanged")
    matchStateEv:FireClient(player, { State = "VS", OpponentName = "Spectre du Champion (IA)", OpponentElo = 1250, OpponentRank = "Or" })

    task.spawn(function()
        for count = 3, 1, -1 do
            matchStateEv:FireClient(player, { State = "Countdown", Value = count })
            task.wait(1)
        end
        matchStateEv:FireClient(player, { State = "Fight" })
        hum.WalkSpeed = 16

        local isFightActive = true
        local timer = 90

        -- Boucle IA du bot
        local botLoop = task.spawn(function()
            while isFightActive and botHum.Health > 0 and hum.Health > 0 do
                task.wait(1.5)
                if hrp and botHrp then
                    botHum:MoveTo(hrp.Position)
                    local dist = (hrp.Position - botHrp.Position).Magnitude
                    if dist <= 14 then
                        hum:TakeDamage(16)
                        local combatVfx = Network.GetEvent("CombatVFX")
                        combatVfx:FireAllClients({
                            Position = hrp.Position,
                            Color = Color3.fromRGB(168, 85, 247),
                        })
                    end
                end
            end
        end)

        while timer > 0 and isFightActive do
            task.wait(1)
            timer -= 1
            matchStateEv:FireClient(player, { State = "Timer", TimeLeft = timer, MyHP = hum.Health, OpponentHP = botHum.Health })
            if hum.Health <= 0 or botHum.Health <= 0 then
                break
            end
        end

        isFightActive = false
        task.cancel(botLoop)

        local isWin = (botHum.Health <= 0) or (hum.Health > botHum.Health)
        if isWin then
            local meritGain = 35
            prof.Merit += meritGain
            prof.Coins += 200
            prof.Elo = math.max(0, prof.Elo + 25)
            prof.Rank = RankConfig.GetTierFromElo(prof.Elo).Name
            prof.Stats.Wins += 1
            prof.Stats.CurrentStreak += 1

            matchStateEv:FireClient(player, {
                State = "Victory",
                EloDelta = 25,
                NewElo = prof.Elo,
                MeritGained = meritGain,
                CoinsGained = 200,
                Streak = prof.Stats.CurrentStreak,
            })
        else
            prof.Merit += 5
            prof.Stats.CurrentStreak = 0
            matchStateEv:FireClient(player, {
                State = "Defeat",
                EloDelta = -15,
                NewElo = prof.Elo,
                MeritGained = 5,
                CoinsGained = 50,
            })
        end

        task.delay(4, function()
            botModel:Destroy()
            if char and char:FindFirstChild("HumanoidRootPart") then
                (char.HumanoidRootPart :: BasePart).CFrame = CFrame.new(LOBBY_SPAWN)
            end
        end)
    end)
end

-- Quitter la file d'attente
function ArenaManager.LeaveQueue(player: Player): { Success: boolean }
    for i, p in ipairs(Queue) do
        if p == player then
            table.remove(Queue, i)
            return { Success = true }
        end
    end
    return { Success = false }
end

-- Vérification de la file et appariement Elo
function ArenaManager.CheckQueue()
    if #Queue < 2 then return end

    -- Appariement des deux premiers joueurs disponibles
    local p1 = table.remove(Queue, 1)!
    local p2 = table.remove(Queue, 1)!

    if not p1 or not p2 or not p1.Parent or not p2.Parent then return end

    ArenaManager.StartMatch(p1, p2)
end

-- Démarrage d'un duel
function ArenaManager.StartMatch(p1: Player, p2: Player)
    local prof1 = DataManager.GetProfile(p1)
    local prof2 = DataManager.GetProfile(p2)
    if not prof1 or not prof2 then return end

    local char1 = p1.Character or p1.CharacterAdded:Wait()
    local char2 = p2.Character or p2.CharacterAdded:Wait()

    local hum1 = char1:WaitForChild("Humanoid") :: Humanoid
    local hum2 = char2:WaitForChild("Humanoid") :: Humanoid
    local hrp1 = char1:WaitForChild("HumanoidRootPart") :: BasePart
    local hrp2 = char2:WaitForChild("HumanoidRootPart") :: BasePart

    -- Téléportation dans le Colisée
    hrp1.CFrame = CFrame.lookAt(ARENA_SPAWN_1, ARENA_SPAWN_2)
    hrp2.CFrame = CFrame.lookAt(ARENA_SPAWN_2, ARENA_SPAWN_1)

    -- Soins complets
    hum1.Health = hum1.MaxHealth
    hum2.Health = hum2.MaxHealth

    -- Immobilisation pendant le compte à rebours
    hum1.WalkSpeed = 0
    hum2.WalkSpeed = 0

    local matchStateEv = Network.GetEvent("MatchStateChanged")
    matchStateEv:FireClient(p1, { State = "VS", OpponentName = p2.Name, OpponentElo = prof2.Elo, OpponentRank = prof2.Rank })
    matchStateEv:FireClient(p2, { State = "VS", OpponentName = p1.Name, OpponentElo = prof1.Elo, OpponentRank = prof1.Rank })

    local matchId = p1.UserId .. "_" .. p2.UserId
    local activeMatch: ActiveMatch = {
        Player1 = p1,
        Player2 = p2,
        StartTime = os.time(),
        RoundTimeLimit = 90,
        IsActive = true,
    }
    CurrentMatches[matchId] = activeMatch

    activeMatch.MatchThread = task.spawn(function()
        -- Compte à rebours 3, 2, 1
        for count = 3, 1, -1 do
            matchStateEv:FireClient(p1, { State = "Countdown", Value = count })
            matchStateEv:FireClient(p2, { State = "Countdown", Value = count })
            task.wait(1)
        end

        matchStateEv:FireClient(p1, { State = "Fight" })
        matchStateEv:FireClient(p2, { State = "Fight" })

        -- Déblocage de la mobilité
        hum1.WalkSpeed = 16
        hum2.WalkSpeed = 16

        -- Boucle de combat (max 90 secondes)
        local timer = 90
        while timer > 0 and activeMatch.IsActive do
            task.wait(1)
            timer -= 1
            matchStateEv:FireClient(p1, { State = "Timer", TimeLeft = timer, MyHP = hum1.Health, OpponentHP = hum2.Health })
            matchStateEv:FireClient(p2, { State = "Timer", TimeLeft = timer, MyHP = hum2.Health, OpponentHP = hum1.Health })

            if hum1.Health <= 0 or hum2.Health <= 0 then
                break
            end
        end

        if activeMatch.IsActive then
            -- Détermination du vainqueur
            local winner = (hum1.Health > hum2.Health) and p1 or p2
            local loser = (winner == p1) and p2 or p1
            ArenaManager.EndMatch(matchId, winner, loser)
        end
    end)
end

-- Clôture du match et redistribution des points
function ArenaManager.EndMatch(matchId: string, winner: Player, loser: Player)
    local match = CurrentMatches[matchId]
    if not match or not match.IsActive then return end
    match.IsActive = false
    CurrentMatches[matchId] = nil

    local profWin = DataManager.GetProfile(winner)
    local profLose = DataManager.GetProfile(loser)
    if not profWin or not profLose then return end

    -- Calcul du delta Elo
    local deltaWin, deltaLose = RankConfig.CalculateEloDelta(profWin.Elo, profLose.Elo, 1)

    profWin.Elo = math.max(0, profWin.Elo + deltaWin)
    profLose.Elo = math.max(0, profLose.Elo + deltaLose)

    profWin.Rank = RankConfig.GetTierFromElo(profWin.Elo).Name
    profLose.Rank = RankConfig.GetTierFromElo(profLose.Elo).Name

    -- Calcul des gains de Mérite (Bonus de série inclus)
    profWin.Stats.CurrentStreak += 1
    if profWin.Stats.CurrentStreak > profWin.Stats.BestStreak then
        profWin.Stats.BestStreak = profWin.Stats.CurrentStreak
    end
    profLose.Stats.CurrentStreak = 0

    local streakBonus = math.min(RankConfig.Rewards.MaxStreakBonus, (profWin.Stats.CurrentStreak - 1) * RankConfig.Rewards.StreakBonusPerWin)
    local totalWinMerit = RankConfig.Rewards.BaseWinMerit + streakBonus
    local totalLoseMerit = RankConfig.Rewards.BaseLossMerit

    profWin.Merit += totalWinMerit
    profLose.Merit += totalLoseMerit

    profWin.Coins += RankConfig.Rewards.BaseWinCoins
    profLose.Coins += RankConfig.Rewards.BaseLossCoins

    profWin.Stats.Wins += 1
    profLose.Stats.Losses += 1

    local matchStateEv = Network.GetEvent("MatchStateChanged")
    matchStateEv:FireClient(winner, {
        State = "Victory",
        EloDelta = deltaWin,
        NewElo = profWin.Elo,
        MeritGained = totalWinMerit,
        CoinsGained = RankConfig.Rewards.BaseWinCoins,
        Streak = profWin.Stats.CurrentStreak,
    })
    matchStateEv:FireClient(loser, {
        State = "Defeat",
        EloDelta = deltaLose,
        NewElo = profLose.Elo,
        MeritGained = totalLoseMerit,
        CoinsGained = RankConfig.Rewards.BaseLossCoins,
    })

    -- Téléportation retour au Hub après 5 secondes
    task.delay(5, function()
        if winner.Character and winner.Character:FindFirstChild("HumanoidRootPart") then
            (winner.Character.HumanoidRootPart :: BasePart).CFrame = CFrame.new(LOBBY_SPAWN)
        end
        if loser.Character and loser.Character:FindFirstChild("HumanoidRootPart") then
            (loser.Character.HumanoidRootPart :: BasePart).CFrame = CFrame.new(LOBBY_SPAWN)
        end
    end)
end

function ArenaManager.Init()
    local joinRF = Network.GetFunction("JoinArenaQueue")
    joinRF.OnServerInvoke = function(player: Player)
        return ArenaManager.JoinQueue(player)
    end

    local leaveRF = Network.GetFunction("LeaveArenaQueue")
    leaveRF.OnServerInvoke = function(player: Player)
        return ArenaManager.LeaveQueue(player)
    end

    Players.PlayerRemoving:Connect(function(player: Player)
        ArenaManager.LeaveQueue(player)
        for id, match in pairs(CurrentMatches) do
            if match.Player1 == player then
                ArenaManager.EndMatch(id, match.Player2, player)
            elseif match.Player2 == player then
                ArenaManager.EndMatch(id, match.Player1, player)
            end
        end
    end)
end

return ArenaManager
