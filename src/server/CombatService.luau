--!strict
--[[
    COMBAT SERVICE (VALIDATION SERVEUR, HITBOXES, PARRY & I-FRAMES)
    Exécution sécurisée côté serveur des cartes de compétences, calcul des hitboxes,
    système de parade (Parry timing 0.3s) récompensant le mérite, esquive (Dash I-frame) et statuts.
]]

local Players = game:GetService("Players")

local CardsData = require(game.ReplicatedStorage.Shared.CardsData)
local CardUtils = require(game.ReplicatedStorage.Shared.CardUtils)
local Network = require(game.ReplicatedStorage.Shared.NetworkEvents)
local DataManager = require(script.Parent.DataManager)

export type CombatState = {
    LastSkillCastTimes: { [string]: number },
    IsParrying: boolean,
    ParryWindowEnd: number,
    IsDashing: boolean,
    DashIFrameEnd: number,
    LastDashTime: number,
}

local CombatService = {}
local PlayerStates: { [Player]: CombatState } = {}

local function GetCombatState(player: Player): CombatState
    if not PlayerStates[player] then
        PlayerStates[player] = {
            LastSkillCastTimes = {},
            IsParrying = false,
            ParryWindowEnd = 0,
            IsDashing = false,
            DashIFrameEnd = 0,
            LastDashTime = 0,
        }
    end
    return PlayerStates[player]
end

-- Exécution d'une compétence
function CombatService.CastSkill(player: Player, slotIndex: number)
    local profile = DataManager.GetProfile(player)
    if not profile then return end

    local cardUniqueId = profile.EquippedDeck.Actives[slotIndex]
    if not cardUniqueId then return end

    -- Retrouver l'instance de la carte
    local cardInstance: CardUtils.CardInstance? = nil
    for _, c in ipairs(profile.Inventory) do
        if c.UniqueId == cardUniqueId then
            cardInstance = c
            break
        end
    end
    if not cardInstance then return end

    local def = CardsData.GetCard(cardInstance.CardId)
    if not def or def.Type ~= "Active" then return end

    local state = GetCombatState(player)
    local now = os.clock()
    local lastCast = state.LastSkillCastTimes[cardInstance.CardId] or 0

    -- Vérification anti-spam du temps de recharge
    local actualCooldown = def.Cooldown or 3
    if (now - lastCast) < (actualCooldown - 0.1) then
        return
    end
    state.LastSkillCastTimes[cardInstance.CardId] = now

    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return end

    -- Calcul des stats réelles (Prestige, Rareté, Mérite)
    local stats = CardUtils.ComputeCardStats(cardInstance, profile.Merit)!
    local baseDamage = stats.Damage
    local range = stats.Range or 20

    -- Broadcast visuel des particules / animations
    local combatVfx = Network.GetEvent("CombatVFX")
    combatVfx:FireAllClients({
        Caster = player,
        CardId = cardInstance.CardId,
        Position = hrp.Position,
        Direction = hrp.CFrame.LookVector,
        Color = def.VFXColor or Color3.fromRGB(255, 255, 255),
    })

    -- Détection de hitbox (Spatial Query)
    local center = hrp.Position + (hrp.CFrame.LookVector * (range * 0.4))
    local hitTargets = workspace:GetPartBoundsInRadius(center, range * 0.6)

    local alreadyHit: { [Model]: boolean } = {}
    for _, part in ipairs(hitTargets) do
        local targetModel = part:FindFirstAncestorOfClass("Model")
        if targetModel and targetModel ~= char and not alreadyHit[targetModel] then
            alreadyHit[targetModel] = true
            local targetHum = targetModel:FindFirstChildOfClass("Humanoid")
            local targetPlayer = Players:GetPlayerFromCharacter(targetModel)

            if targetHum and targetHum.Health > 0 then
                -- Vérification des I-frames (Dash)
                if targetPlayer then
                    local targetState = GetCombatState(targetPlayer)
                    if now < targetState.DashIFrameEnd then
                        -- L'adversaire a esquivé parfaitement !
                        continue
                    end

                    -- Vérification du PARRY (0.3s)
                    if now < targetState.ParryWindowEnd then
                        -- PARADE PARFAITE ! Le défenseur contre-attaque
                        combatVfx:FireAllClients({
                            Type = "ParrySuccess",
                            Position = part.Position,
                        })

                        -- L'attaquant subit un contrecoup / stun
                        local myHum = char:FindFirstChildOfClass("Humanoid")
                        if myHum then
                            myHum:TakeDamage(15)
                        end

                        -- Récompense de Mérite pour le timing chirurgical
                        DataManager.AddMerit(targetPlayer, 15)
                        local toast = Network.GetEvent("ToastNotify")
                        toast:FireClient(targetPlayer, "✨ PARADE PARFAITE ! (+15 Mérite)")
                        return
                    end
                end

                -- Application des dégâts
                targetHum:TakeDamage(baseDamage)

                -- Émission du chiffre de dégâts 3D
                local damageEv = Network.GetEvent("DamageIndicator")
                damageEv:FireAllClients({
                    Position = part.Position + Vector3.new(0, 2.5, 0),
                    Damage = baseDamage,
                    IsPrestige = stats.Prestige,
                    Color = stats.Prestige and Color3.fromRGB(250, 204, 21) or (def.VFXColor or Color3.fromRGB(255, 255, 255)),
                })

                -- Effet passif de Vol de Vie si équipé
                for _, passUid in ipairs(profile.EquippedDeck.Passives) do
                    for _, pc in ipairs(profile.Inventory) do
                        if pc.UniqueId == passUid and pc.CardId == "blood_tribute" then
                            local myHum = char:FindFirstChildOfClass("Humanoid")
                            if myHum then
                                myHum.Health = math.min(myHum.MaxHealth, myHum.Health + (baseDamage * 0.15))
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Action spéciale : Dash (Q) ou Parade (F)
function CombatService.PerformAction(player: Player, actionType: string)
    local state = GetCombatState(player)
    local now = os.clock()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return end

    if actionType == "Dash" then
        if (now - state.LastDashTime) < 3.0 then return end -- Cooldown dash 3s
        state.LastDashTime = now
        state.DashIFrameEnd = now + 0.35                    -- 0.35s d'invulnérabilité

        -- Propulsion physique
        local look = hrp.CFrame.LookVector
        hrp.AssemblyLinearVelocity = look * 75 + Vector3.new(0, 15, 0)

        local combatVfx = Network.GetEvent("CombatVFX")
        combatVfx:FireAllClients({
            Type = "Dash",
            Position = hrp.Position,
            Direction = look,
        })
    elseif actionType == "Parry" then
        -- Fenêtre de parade active pendant 0.35s
        state.ParryWindowEnd = now + 0.35

        local combatVfx = Network.GetEvent("CombatVFX")
        combatVfx:FireAllClients({
            Type = "ParryStance",
            Player = player,
        })
    end
end

function CombatService.Init()
    local castSkillRE = Network.GetEvent("CastSkill")
    castSkillRE.OnServerEvent:Connect(function(player: Player, slot: any)
        local s = tonumber(slot) or 1
        CombatService.CastSkill(player, s)
    end)

    local actionRE = Network.GetEvent("PerformAction")
    actionRE.OnServerEvent:Connect(function(player: Player, actionType: any)
        CombatService.PerformAction(player, tostring(actionType))
    end)
end

return CombatService
