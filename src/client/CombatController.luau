--!strict
--[[
    COMBAT CONTROLLER (COMMANDES JOUEUR, COMBOS, DASH & PARADE)
    Gestion des entrées clavier (1-4 pour les compétences, A/Q pour le Dash, F pour le Parry),
    retour visuel et sonore immédiat, et synchronisation des effets de combat.
]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Network = require(game.ReplicatedStorage.Shared.NetworkEvents)

local player = Players.LocalPlayer
local CombatController = {}

local Cooldowns: { [number]: number } = {
    [1] = 0,
    [2] = 0,
    [3] = 0,
    [4] = 0,
    Dash = 0,
    Parry = 0,
}

-- Effet visuel local d'onde de choc / flash
local function CreateShockwave(pos: Vector3, color: Color3)
    local p = Instance.new("Part")
    p.Shape = Enum.PartType.Cylinder
    p.Size = Vector3.new(0.5, 2, 2)
    p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
    p.Material = Enum.Material.Neon
    p.Color = color
    p.Anchored = true
    p.CanCollide = false
    p.Parent = workspace

    local tween = TweenService:Create(p, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.2, 35, 35),
        Transparency = 1,
    })
    tween:Play()
    Debris:AddItem(p, 0.45)
end

function CombatController.Init()
    local castSkillRE = Network.GetEvent("CastSkill")
    local performActionRE = Network.GetEvent("PerformAction")
    local combatVfxRE = Network.GetEvent("CombatVFX")

    -- Écouteur des touches clavier
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        local now = os.clock()

        -- Touches 1, 2, 3, 4 : Compétences actives
        if input.KeyCode == Enum.KeyCode.One then
            castSkillRE:FireServer(1)
        elseif input.KeyCode == Enum.KeyCode.Two then
            castSkillRE:FireServer(2)
        elseif input.KeyCode == Enum.KeyCode.Three then
            castSkillRE:FireServer(3)
        elseif input.KeyCode == Enum.KeyCode.Four then
            castSkillRE:FireServer(4)
        -- Touche Q ou A : Dash (I-frame)
        elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.A then
            if (now - Cooldowns.Dash) >= 3.0 then
                Cooldowns.Dash = now
                performActionRE:FireServer("Dash")
            end
        -- Touche F : Parade / Parry
        elseif input.KeyCode == Enum.KeyCode.F then
            if (now - Cooldowns.Parry) >= 2.0 then
                Cooldowns.Parry = now
                performActionRE:FireServer("Parry")
            end
        end
    end)

    -- Réception des effets visuels envoyés par le serveur
    combatVfxRE.OnClientEvent:Connect(function(data)
        if data.Type == "ParrySuccess" and data.Position then
            CreateShockwave(data.Position, Color3.fromRGB(250, 204, 21))
        elseif data.Type == "Dash" and data.Position then
            CreateShockwave(data.Position, Color3.fromRGB(56, 189, 248))
        elseif data.Position and data.Color then
            CreateShockwave(data.Position, data.Color)
        end
    end)
end

return CombatController
