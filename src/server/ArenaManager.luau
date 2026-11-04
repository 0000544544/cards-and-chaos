--!strict
--[[
    CARDS & CHAOS - ARÈNE COMPÉTITIVE 1V1 & DUEL CONTRE BOT IA (SERVEUR)
    Téléportation dans le Colisée Céleste, duel contre un Bot Duelliste IA intelligent,
    calcul des gains compétitifs (+25 Mérite & +150 Or) et gestion des récompenses de rang.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local NetworkEvents = require(ReplicatedStorage.Shared.NetworkEvents)
local DataManager = require(script.Parent.DataManager)

local ArenaManager = {}

local ARENA_SPAWN_PLAYER = Vector3.new(400, 54, 35)
local ARENA_SPAWN_BOT = Vector3.new(400, 54, -35)
local LOBBY_SPAWN = Vector3.new(0, 3, 0)

-- Lance un duel compétitif contre le Bot Duelliste IA
function ArenaManager.StartBotDuel(player: Player)
    local prof = DataManager.GetProfile(player)
    if not prof then return { Success = false, Error = "Profil non chargé." } end

    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid") :: Humanoid
    local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart

    -- Téléportation du joueur dans le Colisée
    hrp.CFrame = CFrame.lookAt(ARENA_SPAWN_PLAYER, ARENA_SPAWN_BOT)
    hum.Health = hum.MaxHealth
    hum.WalkSpeed = 0

    -- Création du Bot Duelliste IA
    local botModel = Instance.new("Model")
    botModel.Name = "Bot_Duelliste_Souverain"
    botModel.Parent = workspace

    local botHrp = Instance.new("Part")
    botHrp.Name = "HumanoidRootPart"
    botHrp.Size = Vector3.new(2, 2, 1)
    botHrp.CFrame = CFrame.lookAt(ARENA_SPAWN_BOT, ARENA_SPAWN_PLAYER)
    botHrp.CanCollide = false
    botHrp.Anchored = true
    botHrp.Transparency = 1
    botHrp.Parent = botModel

    local botTorso = Instance.new("Part")
    botTorso.Name = "Torso"
    botTorso.Size = Vector3.new(2.5, 3, 1.5)
    botTorso.CFrame = botHrp.CFrame
    botTorso.Material = Enum.Material.Slate
    botTorso.Color = Color3.fromRGB(145, 40, 255)
    botTorso.CanCollide = true
    botTorso.Anchored = true
    botTorso.Parent = botModel

    local botHead = Instance.new("Part")
    botHead.Name = "Head"
    botHead.Shape = Enum.PartType.Ball
    botHead.Size = Vector3.new(2, 2, 2)
    botHead.CFrame = botHrp.CFrame * CFrame.new(0, 2.5, 0)
    botHead.Material = Enum.Material.Neon
    botHead.Color = Color3.fromRGB(239, 68, 68)
    botHead.CanCollide = true
    botHead.Anchored = true
    botHead.Parent = botModel

    local botHum = Instance.new("Humanoid")
    botHum.MaxHealth = 200
    botHum.Health = 200
    botHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Always
    botHum.Parent = botModel
    botModel.PrimaryPart = botHrp

    local matchStateEv = NetworkEvents.GetEvent("MatchStateChanged")
    matchStateEv:FireClient(player, { State = "VS", OpponentName = "Bot Duelliste Souverain (IA)" })

    task.spawn(function()
        -- Compte à rebours 3, 2, 1
        for count = 3, 1, -1 do
            matchStateEv:FireClient(player, { State = "Countdown", Value = count })
            task.wait(1)
        end
        matchStateEv:FireClient(player, { State = "Fight" })
        hum.WalkSpeed = 16

        local isMatchActive = true
        local timer = 75

        -- Comportement du Bot IA : Déplacement CFrame régulier pour ne jamais traverser le sol
        local aiThread = task.spawn(function()
            while isMatchActive and botHum.Health > 0 and hum.Health > 0 do
                task.wait(0.15)
                if hrp and botHrp and botTorso and botHead then
                    local targetPos = Vector3.new(hrp.Position.X, 54, hrp.Position.Z)
                    local currentPos = botHrp.Position
                    local dir = (targetPos - currentPos)
                    local dist = dir.Magnitude

                    if dist > 14 then
                        local step = math.min(1.4, dist)
                        local newPos = currentPos + (dir.Unit * step)
                        local newCFrame = CFrame.lookAt(newPos, Vector3.new(hrp.Position.X, newPos.Y, hrp.Position.Z))
                        botHrp.CFrame = newCFrame
                        botTorso.CFrame = newCFrame
                        botHead.CFrame = newCFrame * CFrame.new(0, 2.5, 0)
                    else
                        local newCFrame = CFrame.lookAt(currentPos, Vector3.new(hrp.Position.X, currentPos.Y, hrp.Position.Z))
                        botHrp.CFrame = newCFrame
                        botTorso.CFrame = newCFrame
                        botHead.CFrame = newCFrame * CFrame.new(0, 2.5, 0)
                    end
                end
            end
        end)

        -- Boucle d'attaque du Bot : lance des projectiles toutes les 2.5s
        local shootThread = task.spawn(function()
            while isMatchActive and botHum.Health > 0 and hum.Health > 0 do
                task.wait(2.5)
                if hrp and botHrp and (hrp.Position - botHrp.Position).Magnitude <= 55 then
                    local orb = Instance.new("Part")
                    orb.Shape = Enum.PartType.Ball
                    orb.Material = Enum.Material.Neon
                    orb.Color = Color3.fromRGB(255, 85, 0)
                    orb.Size = Vector3.new(2.5, 2.5, 2.5)
                    orb.Anchored = true
                    orb.CanCollide = false
                    orb.CFrame = botHrp.CFrame * CFrame.new(0, 1, -2)
                    orb.Parent = workspace

                    local endPos = hrp.Position
                    local tween = TweenService:Create(orb, TweenInfo.new(0.6), { Position = endPos })
                    tween:Play()
                    tween.Completed:Connect(function()
                        if hum and hum.Health > 0 and (hrp.Position - orb.Position).Magnitude <= 10 then
                            hum:TakeDamage(20)
                        end
                        orb:Destroy()
                    end)
                end
            end
        end)

        while timer > 0 and isMatchActive do
            task.wait(1)
            timer -= 1
            if hum.Health <= 0 or botHum.Health <= 0 then
                break
            end
        end

        isMatchActive = false
        task.cancel(aiThread)
        task.cancel(shootThread)

        local isVictory = (botHum.Health <= 0) or (hum.Health > botHum.Health)
        if isVictory then
            DataManager.AddMerit(player, 25)
            DataManager.AddCoins(player, 150)
            prof.Stats.DuelsWon += 1
            prof.Stats.WinStreak += 1

            matchStateEv:FireClient(player, {
                State = "Victory",
                MeritGained = 25,
                CoinsGained = 150,
                NewMerit = prof.Merit,
                NewCoins = prof.Coins,
            })
        else
            prof.Stats.DuelsLost += 1
            prof.Stats.WinStreak = 0
            matchStateEv:FireClient(player, {
                State = "Defeat",
                MeritGained = 5,
                CoinsGained = 40,
                NewMerit = prof.Merit,
                NewCoins = prof.Coins,
            })
        end

        task.delay(4, function()
            botModel:Destroy()
            if char and char:FindFirstChild("HumanoidRootPart") then
                (char.HumanoidRootPart :: BasePart).CFrame = CFrame.new(LOBBY_SPAWN)
            end
        end)
    end)

    return { Success = true }
end

-- Réclamation de la récompense de palier Mérite (+500 Or)
function ArenaManager.ClaimReward(player: Player)
    local prof = DataManager.GetProfile(player)
    if not prof then return { Success = false, Error = "Profil non chargé." } end

    local rank = prof.Rank
    if prof.ClaimedRewards[rank] then
        return { Success = false, Error = "Récompense de rang '" .. rank .. "' déjà réclamée." }
    end

    prof.ClaimedRewards[rank] = true
    DataManager.AddCoins(player, 500)
    return { Success = true, Message = "Récompense de rang '" .. rank .. "' réclamée : +500 Or !", RemainingCoins = prof.Coins }
end

function ArenaManager.Init()
    local joinRF = NetworkEvents.GetFunction("JoinArenaQueue")
    joinRF.OnServerInvoke = function(player: Player)
        return ArenaManager.StartBotDuel(player)
    end

    local claimRF = NetworkEvents.GetFunction("ClaimRankReward")
    claimRF.OnServerInvoke = function(player: Player)
        return ArenaManager.ClaimReward(player)
    end

    print("[ArenaManager] Colisée 1v1 et Bot Duelliste prêts.")
end

return ArenaManager
