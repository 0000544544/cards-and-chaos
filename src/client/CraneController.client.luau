--!strict
--[[
    STOP AT THE FRAME - CRANE CONTROLLER (CLIENT SCRIPT)
    Design System UI "Figma Simulator" & Mode Pêche complet :
    - Déplacement libre de l'aimant au-dessus du bassin aquatique avec ZQSD / Flèches.
    - Rayon laser de visée vertical et réticule de verrouillage des 6 spots sous-marins.
    - Jauge de mini-jeu de pêche timing façon "Fisch" (presser [ESPACE] dans la zone verte).
    - Remontée du câble et attache physique du véhicule 3D à l'électro-aimant.
    - Carte pop-up "VÉHICULE REPÊCHÉ !" façon carte de collection Figma avec animations dynamiques.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera") :: Camera

local CarBuilder = require(ReplicatedStorage:WaitForChild("CarBuilder") :: ModuleScript)

-- Remotes
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10) :: Folder?
local deployCraneEvent: RemoteEvent? = nil
local craneHookedEvent: RemoteEvent? = nil
if remotesFolder then
    deployCraneEvent = remotesFolder:WaitForChild("DeployCrane", 10) :: RemoteEvent?
    craneHookedEvent = remotesFolder:WaitForChild("CraneHooked", 10) :: RemoteEvent?
end

-- Récupération de la Grue dans le Workspace
local docks = Workspace:WaitForChild("SanFranciscoDocks", 15) :: Folder?
local craneModel = (docks and docks:WaitForChild("IndustrialFishingCrane", 15)) :: Model?
local craneMagnet = (craneModel and craneModel:WaitForChild("CraneMagnet", 10)) :: BasePart?
local magnetRing = (craneModel and craneModel:FindFirstChild("MagnetNeonRing")) :: BasePart?
local winchCable = (craneModel and craneModel:WaitForChild("WinchCable", 10)) :: BasePart?

local MAGNET_REST_Y = 5.5
local MAGNET_WATER_Y = -0.5
local MAGNET_DEEP_Y = -33.0

-- Sons SFX pour la Grue
local sfxFolder = SoundService:FindFirstChild("GameSFX") or Instance.new("Folder")
sfxFolder.Name = "GameSFX"
sfxFolder.Parent = SoundService

local function createSound(name: string, id: string, vol: number): Sound
    local s = Instance.new("Sound")
    s.Name = name
    s.SoundId = id
    s.Volume = vol
    s.RollOffMaxDistance = 5000
    s.Parent = sfxFolder
    return s
end

local soundWinch = createSound("SFX_Winch", "rbxasset://sounds/action_swim.mp3", 0.8)
local soundZap   = createSound("SFX_Zap", "rbxasset://sounds/electronicpingshort.wav", 1.0)
local soundCheer = createSound("SFX_Cheer", "rbxasset://sounds/victory.wav", 0.9)
local soundHit   = createSound("SFX_Hit", "rbxasset://sounds/bell.wav", 0.85)

-- =============================================================================
-- FIGMA SIMULATOR UI DESIGN SYSTEM HELPERS
-- =============================================================================
local function styleFigmaCard(frame: Frame, topColor: Color3, bottomColor: Color3, strokeColor: Color3, cornerRadius: number)
    frame.BorderSizePixel = 0
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.ZIndex = math.max(2, frame.ZIndex)

    local shadowName = frame.Name .. "_Shadow"
    local shadow = frame.Parent and frame.Parent:FindFirstChild(shadowName) :: Frame?
    if not shadow and frame.Parent then
        shadow = Instance.new("Frame")
        shadow.Name = shadowName
        shadow.AnchorPoint = frame.AnchorPoint
        shadow.Size = frame.Size
        shadow.Position = frame.Position + UDim2.new(0, 0, 0, 5)
        shadow.BackgroundColor3 = Color3.fromRGB(6, 8, 12)
        shadow.BackgroundTransparency = 0.5
        shadow.BorderSizePixel = 0
        shadow.ZIndex = 1
        shadow.Visible = frame.Visible
        shadow.Parent = frame.Parent

        local shadowCorner = Instance.new("UICorner")
        shadowCorner.CornerRadius = UDim.new(0, cornerRadius)
        shadowCorner.Parent = shadow

        frame:GetPropertyChangedSignal("Position"):Connect(function()
            if shadow then shadow.Position = frame.Position + UDim2.new(0, 0, 0, 5) end
        end)
        frame:GetPropertyChangedSignal("Size"):Connect(function()
            if shadow then shadow.Size = frame.Size end
        end)
        frame:GetPropertyChangedSignal("Visible"):Connect(function()
            if shadow then shadow.Visible = frame.Visible end
        end)
    end

    local corner = frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, cornerRadius)
    corner.Parent = frame

    local stroke = frame:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = strokeColor
    stroke.Thickness = 3
    stroke.Transparency = 0
    stroke.Parent = frame

    local gradient = frame:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
    gradient.Rotation = 90
    gradient.Color = ColorSequence.new(topColor, bottomColor)
    gradient.Parent = frame
end

local function animateFigmaButton(button: TextButton | ImageButton)
    local scale = button:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
    scale.Parent = button

    local tweenInfoHover = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local tweenInfoLeave = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tweenInfoPress = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    button.MouseEnter:Connect(function()
        TweenService:Create(scale, tweenInfoHover, { Scale = 1.07 }):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(scale, tweenInfoLeave, { Scale = 1.0 }):Play()
    end)
    button.MouseButton1Down:Connect(function()
        TweenService:Create(scale, tweenInfoPress, { Scale = 0.92 }):Play()
    end)
    button.MouseButton1Up:Connect(function()
        TweenService:Create(scale, tweenInfoHover, { Scale = 1.07 }):Play()
    end)
end

-- =============================================================================
-- INTERFACE UTILISATEUR DE LA GRUE (ScreenGui)
-- =============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CraneHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = false
screenGui.Parent = playerGui

-- Panneau de commande bas de l'écran
local controlPanel = Instance.new("Frame")
controlPanel.Name = "ControlPanel"
controlPanel.Size = UDim2.new(0, 620, 0, 160)
controlPanel.AnchorPoint = Vector2.new(0.5, 1)
controlPanel.Position = UDim2.new(0.5, 0, 1, -25)
controlPanel.ZIndex = 5
controlPanel.Parent = screenGui

styleFigmaCard(
    controlPanel,
    Color3.fromRGB(24, 28, 38),
    Color3.fromRGB(12, 14, 18),
    Color3.fromRGB(0, 230, 255),
    18
)

-- Titre
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -30, 0, 28)
titleLabel.Position = UDim2.new(0, 15, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.TextSize = 22
titleLabel.TextColor3 = Color3.fromRGB(0, 240, 255)
titleLabel.TextStrokeColor3 = Color3.fromRGB(8, 12, 16)
titleLabel.TextStrokeTransparency = 0.2
titleLabel.Text = "🎣 POSTE DE COMMANDE : PÊCHE SOUS-MARINE"
titleLabel.Parent = controlPanel

-- Jauge de statut et d'aide
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -30, 0, 22)
statusLabel.Position = UDim2.new(0, 15, 0, 38)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 13
statusLabel.TextColor3 = Color3.fromRGB(180, 240, 255)
statusLabel.Text = "Déplace l'aimant avec [ZQSD] ou [FLÈCHES] au-dessus des spots de couleur !"
statusLabel.Parent = controlPanel

-- Label indicateur de verrouillage de spot
local lockLabel = Instance.new("TextLabel")
lockLabel.Name = "LockLabel"
lockLabel.Size = UDim2.new(1, -30, 0, 22)
lockLabel.Position = UDim2.new(0, 15, 0, 62)
lockLabel.BackgroundTransparency = 1
lockLabel.Font = Enum.Font.GothamBlack
lockLabel.TextSize = 14
lockLabel.TextColor3 = Color3.fromRGB(255, 220, 40)
lockLabel.Text = "🎯 SCAN DU BASSIN : Visez une colonne lumineuse pour cibler un véhicule !"
lockLabel.Parent = controlPanel

-- Bouton de largage de l'aimant
local btnDropMagnet = Instance.new("TextButton")
btnDropMagnet.Name = "BtnDropMagnet"
btnDropMagnet.Size = UDim2.new(0, 360, 0, 52)
btnDropMagnet.Position = UDim2.new(0, 15, 0, 92)
btnDropMagnet.BackgroundColor3 = Color3.fromRGB(0, 185, 235)
btnDropMagnet.Font = Enum.Font.GothamBlack
btnDropMagnet.TextSize = 16
btnDropMagnet.TextColor3 = Color3.fromRGB(255, 255, 255)
btnDropMagnet.Text = "⚓ LÂCHER L'ÉLECTRO-AIMANT [ESPACE]"
btnDropMagnet.Parent = controlPanel

local dropCorner = Instance.new("UICorner")
dropCorner.CornerRadius = UDim.new(0, 12)
dropCorner.Parent = btnDropMagnet
local dropStroke = Instance.new("UIStroke")
dropStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
dropStroke.Color = Color3.fromRGB(0, 240, 255)
dropStroke.Thickness = 2.5
dropStroke.Parent = btnDropMagnet
animateFigmaButton(btnDropMagnet)

-- Bouton Quitter (Retour au Quai)
local btnExit = Instance.new("TextButton")
btnExit.Name = "BtnExit"
btnExit.Size = UDim2.new(0, 210, 0, 52)
btnExit.Position = UDim2.new(1, -225, 0, 92)
btnExit.BackgroundColor3 = Color3.fromRGB(50, 55, 68)
btnExit.Font = Enum.Font.GothamBold
btnExit.TextSize = 14
btnExit.TextColor3 = Color3.fromRGB(235, 240, 250)
btnExit.Text = "✕ RETOUR AU QUAI"
btnExit.Parent = controlPanel

local exitCorner = Instance.new("UICorner")
exitCorner.CornerRadius = UDim.new(0, 12)
exitCorner.Parent = btnExit
animateFigmaButton(btnExit)

-- =============================================================================
-- JAUGE DE MINI-JEU DE PÊCHE FAÇON "FISCH"
-- =============================================================================
local fishingGaugeFrame = Instance.new("Frame")
fishingGaugeFrame.Name = "FishingGaugeFrame"
fishingGaugeFrame.Size = UDim2.new(0, 480, 0, 110)
fishingGaugeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fishingGaugeFrame.Position = UDim2.new(0.5, 0, 0.72, 0)
fishingGaugeFrame.Visible = false
fishingGaugeFrame.ZIndex = 15
fishingGaugeFrame.Parent = screenGui

styleFigmaCard(
    fishingGaugeFrame,
    Color3.fromRGB(25, 30, 42),
    Color3.fromRGB(12, 15, 20),
    Color3.fromRGB(0, 255, 160),
    16
)

local gaugeTitle = Instance.new("TextLabel")
gaugeTitle.Name = "GaugeTitle"
gaugeTitle.Size = UDim2.new(1, 0, 0, 28)
gaugeTitle.Position = UDim2.new(0, 0, 0, 10)
gaugeTitle.BackgroundTransparency = 1
gaugeTitle.Font = Enum.Font.FredokaOne
gaugeTitle.TextSize = 18
gaugeTitle.TextColor3 = Color3.fromRGB(0, 255, 160)
gaugeTitle.Text = "🎯 APPUYE SUR [ESPACE] DANS LA ZONE VERTE !"
gaugeTitle.Parent = fishingGaugeFrame

local trackBar = Instance.new("Frame")
trackBar.Name = "TrackBar"
trackBar.Size = UDim2.new(1, -40, 0, 32)
trackBar.Position = UDim2.new(0, 20, 0, 44)
trackBar.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
trackBar.BorderSizePixel = 0
trackBar.Parent = fishingGaugeFrame

local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(0, 8)
trackCorner.Parent = trackBar

local trackStroke = Instance.new("UIStroke")
trackStroke.Color = Color3.fromRGB(60, 75, 95)
trackStroke.Thickness = 2
trackStroke.Parent = trackBar

-- Zone Cible Verte Brillante
local targetZone = Instance.new("Frame")
targetZone.Name = "TargetZone"
targetZone.Size = UDim2.new(0.28, 0, 1, 0)
targetZone.Position = UDim2.new(0.36, 0, 0, 0)
targetZone.BackgroundColor3 = Color3.fromRGB(0, 230, 110)
targetZone.BorderSizePixel = 0
targetZone.Parent = trackBar

local targetCorner = Instance.new("UICorner")
targetCorner.CornerRadius = UDim.new(0, 6)
targetCorner.Parent = targetZone

local targetGradient = Instance.new("UIGradient")
targetGradient.Rotation = 90
targetGradient.Color = ColorSequence.new(Color3.fromRGB(80, 255, 150), Color3.fromRGB(0, 180, 80))
targetGradient.Parent = targetZone

-- Curseur Mobile
local needleCursor = Instance.new("Frame")
needleCursor.Name = "NeedleCursor"
needleCursor.Size = UDim2.new(0, 14, 1, 10)
needleCursor.AnchorPoint = Vector2.new(0.5, 0.5)
needleCursor.Position = UDim2.new(0.1, 0, 0.5, 0)
needleCursor.BackgroundColor3 = Color3.fromRGB(255, 235, 60)
needleCursor.BorderSizePixel = 0
needleCursor.ZIndex = 5
needleCursor.Parent = trackBar

local needleCorner = Instance.new("UICorner")
needleCorner.CornerRadius = UDim.new(0, 4)
needleCorner.Parent = needleCursor

local needleStroke = Instance.new("UIStroke")
needleStroke.Color = Color3.fromRGB(255, 255, 255)
needleStroke.Thickness = 2
needleStroke.Parent = needleCursor

-- Bouton alternatif tactile pour le harpon
local btnHitMinigame = Instance.new("TextButton")
btnHitMinigame.Name = "BtnHitMinigame"
btnHitMinigame.Size = UDim2.new(0, 160, 0, 24)
btnHitMinigame.AnchorPoint = Vector2.new(0.5, 1)
btnHitMinigame.Position = UDim2.new(0.5, 0, 1, -4)
btnHitMinigame.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
btnHitMinigame.Font = Enum.Font.GothamBlack
btnHitMinigame.TextSize = 12
btnHitMinigame.TextColor3 = Color3.fromRGB(255, 255, 255)
btnHitMinigame.Text = "⚡ HARPONNER !"
btnHitMinigame.Parent = fishingGaugeFrame
local hitCorner = Instance.new("UICorner")
hitCorner.CornerRadius = UDim.new(0, 6)
hitCorner.Parent = btnHitMinigame
animateFigmaButton(btnHitMinigame)

-- =============================================================================
-- CARTE POP-UP DE RÉCOMPENSE "VÉHICULE REPÊCHÉ !" (STYLE CARTE DE COLLECTION FIGMA)
-- =============================================================================
local rewardCard = Instance.new("Frame")
rewardCard.Name = "RewardCard"
rewardCard.Size = UDim2.new(0, 460, 0, 290)
rewardCard.AnchorPoint = Vector2.new(0.5, 0.5)
rewardCard.Position = UDim2.new(0.5, 0, 0.44, 0)
rewardCard.Visible = false
rewardCard.ZIndex = 20
rewardCard.Parent = screenGui

styleFigmaCard(
    rewardCard,
    Color3.fromRGB(28, 32, 45),
    Color3.fromRGB(12, 14, 20),
    Color3.fromRGB(255, 215, 0),
    20
)

local rewardHeader = Instance.new("TextLabel")
rewardHeader.Name = "Header"
rewardHeader.Size = UDim2.new(1, 0, 0, 36)
rewardHeader.Position = UDim2.new(0, 0, 0, 14)
rewardHeader.BackgroundTransparency = 1
rewardHeader.Font = Enum.Font.FredokaOne
rewardHeader.TextSize = 25
rewardHeader.TextColor3 = Color3.fromRGB(255, 215, 0)
rewardHeader.TextStrokeColor3 = Color3.fromRGB(12, 14, 18)
rewardHeader.TextStrokeTransparency = 0
rewardHeader.Text = "⭐ VÉHICULE DE COLLECTION DÉBLOQUÉ ⭐"
rewardHeader.Parent = rewardCard

local carNameLabel = Instance.new("TextLabel")
carNameLabel.Name = "CarName"
carNameLabel.Size = UDim2.new(1, -20, 0, 36)
carNameLabel.Position = UDim2.new(0, 10, 0, 56)
carNameLabel.BackgroundTransparency = 1
carNameLabel.Font = Enum.Font.FredokaOne
carNameLabel.TextSize = 27
carNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
carNameLabel.TextStrokeColor3 = Color3.fromRGB(10, 12, 16)
carNameLabel.TextStrokeTransparency = 0.2
carNameLabel.Text = "#6 Flash McQueen ⚡"
carNameLabel.Parent = rewardCard

local rarityBadge = Instance.new("TextLabel")
rarityBadge.Name = "RarityBadge"
rarityBadge.Size = UDim2.new(0, 200, 0, 30)
rarityBadge.AnchorPoint = Vector2.new(0.5, 0)
rarityBadge.Position = UDim2.new(0.5, 0, 0, 98)
rarityBadge.BackgroundColor3 = Color3.fromRGB(255, 60, 40)
rarityBadge.Font = Enum.Font.GothamBlack
rarityBadge.TextSize = 14
rarityBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
rarityBadge.Text = "MYTHIQUE"
rarityBadge.Parent = rewardCard
local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(0, 10)
badgeCorner.Parent = rarityBadge
local badgeStroke = Instance.new("UIStroke")
badgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
badgeStroke.Color = Color3.fromRGB(255, 255, 255)
badgeStroke.Thickness = 2
badgeStroke.Parent = rarityBadge

local descLabel = Instance.new("TextLabel")
descLabel.Name = "Desc"
descLabel.Size = UDim2.new(1, -36, 0, 44)
descLabel.Position = UDim2.new(0, 18, 0, 140)
descLabel.BackgroundTransparency = 1
descLabel.Font = Enum.Font.GothamMedium
descLabel.TextSize = 14
descLabel.TextColor3 = Color3.fromRGB(195, 240, 215)
descLabel.Text = "Ajouté à votre Showroom ! Il génère du Cash passif en continu pour votre garage."
descLabel.TextWrapped = true
descLabel.Parent = rewardCard

local btnClaim = Instance.new("TextButton")
btnClaim.Name = "BtnClaim"
btnClaim.Size = UDim2.new(0, 240, 0, 48)
btnClaim.AnchorPoint = Vector2.new(0.5, 1)
btnClaim.Position = UDim2.new(0.5, 0, 1, -18)
btnClaim.BackgroundColor3 = Color3.fromRGB(0, 210, 110)
btnClaim.Font = Enum.Font.GothamBlack
btnClaim.TextSize = 16
btnClaim.TextColor3 = Color3.fromRGB(255, 255, 255)
btnClaim.Text = "RÉCUPÉRER LE VÉHICULE"
btnClaim.Parent = rewardCard
local claimCorner = Instance.new("UICorner")
claimCorner.CornerRadius = UDim.new(0, 12)
claimCorner.Parent = btnClaim
local claimStroke = Instance.new("UIStroke")
claimStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
claimStroke.Color = Color3.fromRGB(255, 255, 255)
claimStroke.Thickness = 2
claimStroke.Parent = btnClaim
animateFigmaButton(btnClaim)

-- =============================================================================
-- GÉOMÉTRIE & LASER DE VISÉE DYNAMIQUE DANS LE BASSIN
-- =============================================================================
local magnetX = 0
local magnetZ = -125
local magnetY = MAGNET_REST_Y

local laserBeam = Instance.new("Part")
laserBeam.Name = "AimingLaserBeam"
laserBeam.Shape = Enum.PartType.Cylinder
laserBeam.Material = Enum.Material.Neon
laserBeam.Color = Color3.fromRGB(0, 240, 255)
laserBeam.Transparency = 0.45
laserBeam.Anchored = true
laserBeam.CanCollide = false
laserBeam.CanQuery = false
laserBeam.CastShadow = false
laserBeam.Size = Vector3.new(20, 0.25, 0.25)
laserBeam.Parent = Workspace

local laserReticle = Instance.new("Part")
laserReticle.Name = "AimingLaserReticle"
laserReticle.Shape = Enum.PartType.Cylinder
laserReticle.Material = Enum.Material.Neon
laserReticle.Color = Color3.fromRGB(0, 240, 255)
laserReticle.Transparency = 0.35
laserReticle.Anchored = true
laserReticle.CanCollide = false
laserReticle.CanQuery = false
laserReticle.CastShadow = false
laserReticle.Size = Vector3.new(0.2, 8.5, 8.5)
laserReticle.Parent = Workspace

local SPOT_TARGETS = {
    { Pos = Vector3.new(-24, -37, -118), Color = Color3.fromRGB(40, 230, 90),   Rarity = "Commune",    Depth = 20,  Label = "Lotus Rally" },
    { Pos = Vector3.new(24, -37, -120),  Color = Color3.fromRGB(0, 220, 255),   Rarity = "Peu Commune",Depth = 40,  Label = "Cyber Truck" },
    { Pos = Vector3.new(-14, -37, -132), Color = Color3.fromRGB(30, 120, 255),  Rarity = "Rare",       Depth = 65,  Label = "Drift Supra" },
    { Pos = Vector3.new(16, -37, -134),  Color = Color3.fromRGB(175, 45, 255),  Rarity = "Épique",     Depth = 90,  Label = "Police Interceptor" },
    { Pos = Vector3.new(-20, -37, -145), Color = Color3.fromRGB(255, 130, 20),  Rarity = "Légendaire", Depth = 120, Label = "Hyperion JetCar" },
    { Pos = Vector3.new(10, -37, -144),  Color = Color3.fromRGB(255, 215, 0),   Rarity = "Mythique",   Depth = 150, Label = "Flash McQueen ⚡" },
}

local currentLockedSpot: any = nil

local function setMagnetPos(x: number, y: number, z: number)
    magnetX = x
    magnetY = y
    magnetZ = z

    if craneMagnet then
        craneMagnet.CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.rad(90))
    end
    if magnetRing then
        magnetRing.CFrame = CFrame.new(x, y - 1.1, z)
    end
    if winchCable then
        local cableLength = math.max(1, 32 - y)
        winchCable.Size = Vector3.new(0.35, cableLength, 0.35)
        winchCable.CFrame = CFrame.new(x, 32 - (cableLength / 2), z)
    end
end

-- =============================================================================
-- LOGIQUE ET DÉPLACEMENTS ZQSD / FLÈCHES
-- =============================================================================
local isFishing = false
local MOVE_SPEED = 24

RunService.RenderStepped:Connect(function(dt)
    local inCrane = (player:GetAttribute("CurrentMode") == "Crane")
    if not inCrane then
        laserBeam.Transparency = 1
        laserReticle.Transparency = 1
        return
    end

    if not isFishing then
        laserBeam.Transparency = 0.45
        laserReticle.Transparency = 0.35

        -- Contrôles ZQSD / Flèches
        local dx = 0
        local dz = 0

        if UserInputService:IsKeyDown(Enum.KeyCode.Q) or UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
            dx -= 1
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
            dx += 1
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Z) or UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
            dz -= 1
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
            dz += 1
        end

        if dx ~= 0 or dz ~= 0 then
            local nextX = math.clamp(magnetX + dx * MOVE_SPEED * dt, -32, 32)
            local nextZ = math.clamp(magnetZ + dz * MOVE_SPEED * dt, -155, -112)
            setMagnetPos(nextX, MAGNET_REST_Y, nextZ)
        end
    else
        laserBeam.Transparency = 1
        laserReticle.Transparency = 1
    end

    -- Mise à jour du laser de visée vers la surface de l'eau
    local beamLen = math.max(0.5, magnetY - 0.2)
    laserBeam.Size = Vector3.new(beamLen, 0.25, 0.25)
    laserBeam.CFrame = CFrame.new(magnetX, (magnetY + 0.2) / 2, magnetZ) * CFrame.Angles(0, 0, math.rad(90))
    laserReticle.CFrame = CFrame.new(magnetX, 0.2, magnetZ) * CFrame.Angles(0, 0, math.rad(90))

    -- Détection de proximité des 6 spots sous-marins
    currentLockedSpot = nil
    local nearestDist = 999
    for _, spot in ipairs(SPOT_TARGETS) do
        local dist2D = Vector2.new(magnetX - spot.Pos.X, magnetZ - spot.Pos.Z).Magnitude
        if dist2D < 13 and dist2D < nearestDist then
            nearestDist = dist2D
            currentLockedSpot = spot
        end
    end

    if currentLockedSpot then
        laserReticle.Color = currentLockedSpot.Color
        laserBeam.Color = currentLockedSpot.Color
        lockLabel.Text = string.format("🎯 SPOT VERROUILLÉ : %s (%s) — Profondeur %dm !", currentLockedSpot.Label, currentLockedSpot.Rarity, currentLockedSpot.Depth)
        lockLabel.TextColor3 = currentLockedSpot.Color
    else
        laserReticle.Color = Color3.fromRGB(0, 240, 255)
        laserBeam.Color = Color3.fromRGB(0, 240, 255)
        lockLabel.Text = "🎯 SCAN DU BASSIN : Visez une colonne lumineuse pour cibler un véhicule !"
        lockLabel.TextColor3 = Color3.fromRGB(255, 220, 40)
    end
end)

-- =============================================================================
-- DÉROULEMENT DU MINI-JEU DE PÊCHE FAÇON "FISCH"
-- =============================================================================
local minigameResolved = false
local wasPerfectCatch = false

local function triggerMinigameAction()
    if not isFishing or minigameResolved then return end
    minigameResolved = true

    -- Vérification de la position du curseur dans la zone verte
    local cursorX = needleCursor.Position.X.Scale
    local targetStart = targetZone.Position.X.Scale
    local targetEnd = targetStart + targetZone.Size.X.Scale

    if cursorX >= (targetStart - 0.03) and cursorX <= (targetEnd + 0.03) then
        wasPerfectCatch = true
        soundHit:Play()
        gaugeTitle.Text = "⚡ PRISE PARFAITE ! ÉPAVE ACCROCHÉE ! ⚡"
        gaugeTitle.TextColor3 = Color3.fromRGB(255, 230, 40)
        targetZone.BackgroundColor3 = Color3.fromRGB(255, 220, 0)
    else
        wasPerfectCatch = false
        gaugeTitle.Text = "⚠️ TIMING APPROXIMATIF — Récupération partielle..."
        gaugeTitle.TextColor3 = Color3.fromRGB(255, 120, 80)
    end
end

btnHitMinigame.MouseButton1Click:Connect(triggerMinigameAction)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Space then
        if fishingGaugeFrame.Visible then
            triggerMinigameAction()
        elseif player:GetAttribute("CurrentMode") == "Crane" and not isFishing then
            task.spawn(function()
                btnDropMagnet.MouseButton1Click:Fire()
            end)
        end
    end
end)

local function runFishingSequence()
    if isFishing then return end
    isFishing = true
    btnDropMagnet.Active = false
    btnDropMagnet.BackgroundColor3 = Color3.fromRGB(80, 90, 100)
    btnDropMagnet.Text = "⏳ PLONGÉE EN COURS..."
    rewardCard.Visible = false

    -- 1. Descente de l'aimant vers la surface de l'eau
    statusLabel.Text = "Statut : Descente de l'aimant vers le bassin aquatique..."
    soundWinch:Play()

    local dropTime = 1.6
    local startT = os.clock()
    while os.clock() - startT < dropTime do
        local alpha = (os.clock() - startT) / dropTime
        local curY = MAGNET_REST_Y + alpha * (MAGNET_WATER_Y - MAGNET_REST_Y)
        setMagnetPos(magnetX, curY, magnetZ)
        task.wait(0.03)
    end
    setMagnetPos(magnetX, MAGNET_WATER_Y, magnetZ)

    -- 2. Lancement du Mini-Jeu Fisch
    fishingGaugeFrame.Visible = true
    minigameResolved = false
    wasPerfectCatch = false
    gaugeTitle.Text = "🎯 APPUYE SUR [ESPACE] DANS LA ZONE VERTE !"
    gaugeTitle.TextColor3 = Color3.fromRGB(0, 255, 160)
    targetZone.BackgroundColor3 = Color3.fromRGB(0, 230, 110)

    -- Aligner la zone cible selon le spot verrouillé
    if currentLockedSpot then
        targetZone.Size = UDim2.new(0.30, 0, 1, 0)
        targetZone.Position = UDim2.new(0.35, 0, 0, 0)
    else
        targetZone.Size = UDim2.new(0.24, 0, 1, 0)
        targetZone.Position = UDim2.new(0.38, 0, 0, 0)
    end

    local minigameStart = os.clock()
    local MAX_MINIGAME_TIME = 4.5
    local needleSpeed = 4.8

    while os.clock() - minigameStart < MAX_MINIGAME_TIME and not minigameResolved do
        local elapsed = os.clock() - minigameStart
        local posScale = (math.sin(elapsed * needleSpeed) + 1) / 2
        needleCursor.Position = UDim2.new(0.05 + posScale * 0.90, 0, 0.5, 0)
        task.wait(0.02)
    end

    if not minigameResolved then
        triggerMinigameAction()
    end

    task.wait(0.8)
    fishingGaugeFrame.Visible = false

    -- 3. Plongée profonde jusqu'au fond
    statusLabel.Text = "Statut : Accrochage électromagnétique dans les profondeurs..."
    soundWinch:Play()

    local deepTime = 1.8
    local startDeep = os.clock()
    while os.clock() - startDeep < deepTime do
        local alpha = (os.clock() - startDeep) / deepTime
        local curY = MAGNET_WATER_Y + alpha * (MAGNET_DEEP_Y - MAGNET_WATER_Y)
        setMagnetPos(magnetX, curY, magnetZ)
        task.wait(0.03)
    end
    setMagnetPos(magnetX, MAGNET_DEEP_Y, magnetZ)

    soundZap:Play()
    task.wait(0.5)

    -- Profondeur ciblée transmise au serveur
    local targetDepth = 50
    if currentLockedSpot then
        targetDepth = currentLockedSpot.Depth
    end
    if wasPerfectCatch then
        targetDepth += 35
    end

    if deployCraneEvent then
        deployCraneEvent:FireServer(targetDepth)
    end
end

-- =============================================================================
-- RÉCEPTION DU VÉHICULE REPÊCHÉ ET REMONTÉE 3D
-- =============================================================================
if craneHookedEvent then
    craneHookedEvent.OnClientEvent:Connect(function(vehicleId: string, name: string, rarity: string, depth: number, isNew: boolean)
        statusLabel.Text = string.format("Statut : %s repêché ! Remontée du câble...", name)

        local hookedModel: Model? = nil
        pcall(function()
            local cfg = CarBuilder.GetVehicleConfig(vehicleId)
            hookedModel = cfg.Builder()
            if hookedModel then
                hookedModel.Parent = Workspace
                for _, bp in ipairs(hookedModel:GetDescendants()) do
                    if bp:IsA("BasePart") then
                        bp.Anchored = true
                        bp.CanCollide = false
                    end
                end
            end
        end)

        local riseTime = 2.6
        local startRise = os.clock()
        while os.clock() - startRise < riseTime do
            local alpha = (os.clock() - startRise) / riseTime
            local curY = MAGNET_DEEP_Y + alpha * (MAGNET_REST_Y - MAGNET_DEEP_Y)
            setMagnetPos(magnetX, curY, magnetZ)

            if hookedModel then
                hookedModel:PivotTo(CFrame.new(magnetX, curY - 2.8, magnetZ) * CFrame.Angles(math.rad(10), 0, 0))
            end
            task.wait(0.03)
        end
        setMagnetPos(magnetX, MAGNET_REST_Y, magnetZ)

        soundCheer:Play()

        -- Mise à jour de la carte de collection pop-up
        carNameLabel.Text = name
        rarityBadge.Text = string.upper(rarity)

        if rarity == "Légendaire" or rarity == "Mythique" then
            rarityBadge.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
        elseif rarity == "Épique" then
            rarityBadge.BackgroundColor3 = Color3.fromRGB(165, 45, 235)
        elseif rarity == "Rare" then
            rarityBadge.BackgroundColor3 = Color3.fromRGB(35, 135, 245)
        else
            rarityBadge.BackgroundColor3 = Color3.fromRGB(45, 190, 85)
        end

        descLabel.Text = if isNew
            then "Nouveau véhicule débloqué ! Il a été transféré à votre Showroom pour générer du Cash passif."
            else "Véhicule déjà possédé ! Votre revenu passif du garage a été augmenté grâce à la prime."

        rewardCard.Visible = true

        task.delay(5, function()
            if hookedModel then
                hookedModel:Destroy()
                hookedModel = nil
            end
        end)

        isFishing = false
        btnDropMagnet.Active = true
        btnDropMagnet.BackgroundColor3 = Color3.fromRGB(0, 185, 235)
        btnDropMagnet.Text = "⚓ LÂCHER L'ÉLECTRO-AIMANT [ESPACE]"
        statusLabel.Text = "Statut : Prêt pour un nouveau lancer !"
    end)
end

btnDropMagnet.MouseButton1Click:Connect(runFishingSequence)

btnClaim.MouseButton1Click:Connect(function()
    rewardCard.Visible = false
end)

btnExit.MouseButton1Click:Connect(function()
    rewardCard.Visible = false
    fishingGaugeFrame.Visible = false
    player:SetAttribute("CurrentMode", "Hub")
end)

local function onModeChanged()
    local mode = tostring(player:GetAttribute("CurrentMode") or "Hub")
    local inCrane = (mode == "Crane")
    screenGui.Enabled = inCrane
    if not inCrane then
        rewardCard.Visible = false
        fishingGaugeFrame.Visible = false
        camera.CameraType = Enum.CameraType.Custom
    else
        -- Vue aérienne cinématographique plongeant sur l'océan et les 6 spots néon
        camera.CameraType = Enum.CameraType.Scriptable
        local targetCamCF = CFrame.lookAt(Vector3.new(0, 24, -108), Vector3.new(0, 0, -138))
        TweenService:Create(camera, TweenInfo.new(0.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
            CFrame = targetCamCF
        }):Play()
    end
end

player:GetAttributeChangedSignal("CurrentMode"):Connect(onModeChanged)
task.spawn(onModeChanged)

print("[CraneController] Module client de contrôle de la Grue initialisé avec succès (UI Figma Simulator).")
