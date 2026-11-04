--!strict
--[[
    CARDS & CHAOS - SERVICE DE COMBAT 3D & HITBOXES (SERVEUR)
    Exécution serveur-autoritaire des 4 sorts (Projectile, AoE, DashStrike, ShieldBuff)
    et du Dash (Slot 5), avec pop-up 3D BillboardGui de dégâts sur tous les Humanoids.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CardsDatabase = require(Shared:WaitForChild("CardsDatabase"))
local NetworkEvents = require(Shared:WaitForChild("NetworkEvents"))
local DataManager = require(script.Parent.DataManager)

local CombatService = {}
local cooldowns: { [number]: { [number]: number } } = {} -- [userId][slot] = os.clock()

local function showDamageBillboard(targetPart: BasePart, amount: number, color: Color3, prefix: string?)
	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.fromOffset(120, 50)
	bg.StudsOffset = Vector3.new(math.random(-2, 2), 3, math.random(-2, 2))
	bg.AlwaysOnTop = true
	bg.Parent = targetPart

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = (prefix or "-") .. tostring(math.floor(amount))
	lbl.TextColor3 = color
	lbl.TextStrokeTransparency = 0
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextScaled = true
	lbl.Parent = bg

	TweenService:Create(bg, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		StudsOffset = bg.StudsOffset + Vector3.new(0, 4, 0)
	}):Play()
	TweenService:Create(lbl, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(bg, 0.85)
end

local function dealAreaDamage(casterChar: Model, centerPos: Vector3, radius: number, damage: number, color: Color3)
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Humanoid") and obj.Health > 0 then
			local model = obj.Parent
			if model and model ~= casterChar then
				local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
				if root and root:IsA("BasePart") and (root.Position - centerPos).Magnitude <= radius then
					obj:TakeDamage(damage)
					showDamageBillboard(root, damage, color, "-")
				end
			end
		end
	end
end

function CombatService.CastSpell(player: Player, slotIndex: number, targetPosition: Vector3)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid") :: Humanoid?
	if not root or not hum or hum.Health <= 0 then return end

	-- Gestion du Dash (Slot 5)
	if slotIndex == 5 then
		cooldowns[player.UserId] = cooldowns[player.UserId] or {}
		local now = os.clock()
		if (now - (cooldowns[player.UserId][5] or 0)) < 2.0 then return end
		cooldowns[player.UserId][5] = now

		local dir = (Vector3.new(targetPosition.X, root.Position.Y, targetPosition.Z) - root.Position)
		local moveDir = dir.Magnitude > 1 and dir.Unit or root.CFrame.LookVector

		local trailPart = Instance.new("Part")
		trailPart.Shape = Enum.PartType.Ball
		trailPart.Material = Enum.Material.Neon
		trailPart.Color = Color3.fromRGB(0, 200, 255)
		trailPart.Size = Vector3.new(3, 3, 3)
		trailPart.Anchored = true
		trailPart.CanCollide = false
		trailPart.CFrame = root.CFrame
		trailPart.Parent = workspace
		TweenService:Create(trailPart, TweenInfo.new(0.35), { Size = Vector3.new(8, 8, 8), Transparency = 1 }):Play()
		Debris:AddItem(trailPart, 0.4)

		root.CFrame = root.CFrame + (moveDir * 28)
		return
	end

	-- Récupération du sort équipé dans le slot
	local prof = DataManager.GetProfile(player)
	local spellId = (prof and prof.EquippedDeck[slotIndex]) or CardsDatabase.StarterDeck[slotIndex]
	local spell = spellId and CardsDatabase.Cards[spellId]
	if not spell then return end

	cooldowns[player.UserId] = cooldowns[player.UserId] or {}
	local now = os.clock()
	if (now - (cooldowns[player.UserId][slotIndex] or 0)) < spell.Cooldown then return end
	cooldowns[player.UserId][slotIndex] = now

	local aimDir = (targetPosition - root.Position)
	aimDir = Vector3.new(aimDir.X, 0, aimDir.Z)
	local unitDir = aimDir.Magnitude > 0.5 and aimDir.Unit or root.CFrame.LookVector

	if spell.SpellType == "Projectile" then
		local orb = Instance.new("Part")
		orb.Shape = Enum.PartType.Ball
		orb.Material = Enum.Material.Neon
		orb.Color = spell.Color
		orb.Size = Vector3.new(3.5, 3.5, 3.5)
		orb.Anchored = true
		orb.CanCollide = false
		orb.CFrame = root.CFrame * CFrame.new(0, 1, -3)
		orb.Parent = workspace

		local endPos = root.Position + (unitDir * 65)
		local tween = TweenService:Create(orb, TweenInfo.new(0.55, Enum.EasingStyle.Linear), { Position = endPos })
		tween:Play()
		tween.Completed:Connect(function()
			local blast = Instance.new("Part")
			blast.Shape = Enum.PartType.Ball
			blast.Material = Enum.Material.Neon
			blast.Color = spell.Color
			blast.Size = Vector3.new(2, 2, 2)
			blast.Anchored = true
			blast.CanCollide = false
			blast.Position = orb.Position
			blast.Parent = workspace
			TweenService:Create(blast, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new((spell.Radius or 10) * 2, (spell.Radius or 10) * 2, (spell.Radius or 10) * 2),
				Transparency = 1
			}):Play()
			Debris:AddItem(blast, 0.4)
			dealAreaDamage(char, orb.Position, spell.Radius or 10, spell.BasePower, spell.Color)
			orb:Destroy()
		end)

	elseif spell.SpellType == "AoE" then
		local radius = spell.Radius or 16
		local ring = Instance.new("Part")
		ring.Shape = Enum.PartType.Cylinder
		ring.Material = Enum.Material.Neon
		ring.Color = spell.Color
		ring.Size = Vector3.new(1, 2, 2)
		ring.Anchored = true
		ring.CanCollide = false
		ring.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = workspace

		TweenService:Create(ring, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(1.5, radius * 2, radius * 2),
			Transparency = 1
		}):Play()
		Debris:AddItem(ring, 0.5)
		dealAreaDamage(char, root.Position, radius, spell.BasePower, spell.Color)

	elseif spell.SpellType == "DashStrike" then
		local range = spell.Range or 35
		local startPos = root.Position
		local endPos = startPos + (unitDir * range)
		local beam = Instance.new("Part")
		beam.Material = Enum.Material.Neon
		beam.Color = spell.Color
		beam.Anchored = true
		beam.CanCollide = false
		beam.Size = Vector3.new(2.5, 2.5, range)
		beam.CFrame = CFrame.lookAt((startPos + endPos) / 2, endPos)
		beam.Parent = workspace

		root.CFrame = CFrame.lookAt(endPos, endPos + unitDir)
		dealAreaDamage(char, (startPos + endPos) / 2, range * 0.6, spell.BasePower, spell.Color)
		TweenService:Create(beam, TweenInfo.new(0.35), { Size = Vector3.new(0.2, 0.2, range), Transparency = 1 }):Play()
		Debris:AddItem(beam, 0.4)

	elseif spell.SpellType == "ShieldBuff" then
		hum.Health = math.min(hum.MaxHealth, hum.Health + spell.BasePower)
		showDamageBillboard(root, spell.BasePower, Color3.fromRGB(80, 255, 120), "+")
		local shield = Instance.new("Part")
		shield.Shape = Enum.PartType.Ball
		shield.Material = Enum.Material.ForceField
		shield.Color = spell.Color
		shield.Size = Vector3.new(9, 9, 9)
		shield.Anchored = true
		shield.CanCollide = false
		shield.Position = root.Position
		shield.Parent = workspace
		TweenService:Create(shield, TweenInfo.new(1.2), { Transparency = 1, Size = Vector3.new(12, 12, 12) }):Play()
		Debris:AddItem(shield, 1.25)
	end
end

function CombatService.Init()
    local castRE = NetworkEvents.GetEvent("CastSpell")
    castRE.OnServerEvent:Connect(function(player: Player, slotIndex: any, targetPos: any)
        local slot = tonumber(slotIndex) or 1
        local pos = (typeof(targetPos) == "Vector3") and targetPos or (player.Character and player.Character:GetPivot().Position + Vector3.new(0, 0, -20)) or Vector3.zero
        CombatService.CastSpell(player, slot, pos)
    end)
    print("[CombatService] Sorts 3D prêts et branchés sur le réseau.")
end

return CombatService
