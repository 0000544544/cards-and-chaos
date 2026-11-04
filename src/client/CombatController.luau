--!strict
--[[
    CARDS & CHAOS - CONTRÔLEUR DE COMBAT & ENTRÉES SORTS (CLIENT)
    Visée à la souris, support clavier universel (QWERTY + AZERTY A/Z/E/R/F + Pavé Numérique),
    et support clic direct sur les boutons de la barre de sorts (Hotbar).
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkEvents = require(ReplicatedStorage.Shared.NetworkEvents)

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local CombatController = {}

function CombatController.TriggerSpell(slotIndex: number)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not root then return end

    local targetPos = mouse.Hit and mouse.Hit.Position or (root.Position + root.CFrame.LookVector * 30)
    local castRE = NetworkEvents.GetEvent("CastSpell")
    castRE:FireServer(slotIndex, targetPos)
end

function CombatController.Init()
    -- Écouteur des entrées clavier
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        local kc = input.KeyCode

        -- SLOT 1 : Météore Solaire
        if kc == Enum.KeyCode.One or kc == Enum.KeyCode.KeypadOne or kc == Enum.KeyCode.A then
            CombatController.TriggerSpell(1)

        -- SLOT 2 : Nova du Néant
        elseif kc == Enum.KeyCode.Two or kc == Enum.KeyCode.KeypadTwo or kc == Enum.KeyCode.Z or kc == Enum.KeyCode.W then
            CombatController.TriggerSpell(2)

        -- SLOT 3 : Pas Éclair
        elseif kc == Enum.KeyCode.Three or kc == Enum.KeyCode.KeypadThree or kc == Enum.KeyCode.E then
            CombatController.TriggerSpell(3)

        -- SLOT 4 : Égide du Souverain
        elseif kc == Enum.KeyCode.Four or kc == Enum.KeyCode.KeypadFour or kc == Enum.KeyCode.R then
            CombatController.TriggerSpell(4)

        -- SLOT 5 : Dash Éclair (I-Frame)
        elseif kc == Enum.KeyCode.Five or kc == Enum.KeyCode.KeypadFive or kc == Enum.KeyCode.Q or kc == Enum.KeyCode.F or kc == Enum.KeyCode.Space then
            CombatController.TriggerSpell(5)
        end
    end)

    print("[CombatController] Contrôles QWERTY / AZERTY / Clic Souris activés.")
end

return CombatController
