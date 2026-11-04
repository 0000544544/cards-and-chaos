--!strict
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

	-- Visée horizontale propre devant le personnage ou vers le pointeur souris
	local lookPos = root.Position + root.CFrame.LookVector * 35
	if mouse.Hit then
		local hitPos = mouse.Hit.Position
		if (hitPos - root.Position).Magnitude <= 180 then
			lookPos = Vector3.new(hitPos.X, root.Position.Y, hitPos.Z)
		end
	end

	local castRE = NetworkEvents.GetEvent("CastSpell")
	castRE:FireServer(slotIndex, lookPos)
end

function CombatController.Init()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		local kc = input.KeyCode

		-- Touches 1-5 (Haut du clavier + Pavé numérique) + Raccourcis de combat F, G, C, V, LeftShift (ZÉRO conflit avec ZQSD/WASD/Espace/E)
		if kc == Enum.KeyCode.One or kc == Enum.KeyCode.KeypadOne or kc == Enum.KeyCode.F then
			CombatController.TriggerSpell(1)
		elseif kc == Enum.KeyCode.Two or kc == Enum.KeyCode.KeypadTwo or kc == Enum.KeyCode.G then
			CombatController.TriggerSpell(2)
		elseif kc == Enum.KeyCode.Three or kc == Enum.KeyCode.KeypadThree or kc == Enum.KeyCode.C then
			CombatController.TriggerSpell(3)
		elseif kc == Enum.KeyCode.Four or kc == Enum.KeyCode.KeypadFour or kc == Enum.KeyCode.V then
			CombatController.TriggerSpell(4)
		elseif kc == Enum.KeyCode.Five or kc == Enum.KeyCode.KeypadFive or kc == Enum.KeyCode.LeftShift then
			CombatController.TriggerSpell(5)
		end
	end)
end

return CombatController
