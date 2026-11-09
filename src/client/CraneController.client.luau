--!strict
--[[
    STOP AT THE FRAME - CRANE CONTROLLER (CLIENT SCRIPT)
    Gère l'interface et les animations du Mode Pêche (Grue & Aimant sous-marin) :
    - Descente physique de l'électro-aimant dans le bassin aquatique.
    - Déclenchement de l'événement DeployCrane vers CraneService.
    - Remontée du câble avec le véhicule repêché accroché à l'aimant.
    - Affichage de la carte de récompense de véhicule.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

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

-- =============================================================================
-- INTERFACE UTILISATEUR DE LA GRUE (ScreenGui)
-- =============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CraneHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Enabled = false
screenGui.Parent = playerGui

-- Panneau de commande bas de l'écran
local controlPanel = Instance.new("Frame")
controlPanel.Name = "ControlPanel"
controlPanel.Size = UDim2.new(0, 560, 0, 150)
controlPanel.AnchorPoint = Vector2.new(0.5, 1)
controlPanel.Position = UDim2.new(0.5, 0, 1, -25)
controlPanel.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
controlPanel.BorderSizePixel = 0
controlPanel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 16)
panelCorner.Parent = controlPanel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(0, 220, 255)
panelStroke.Thickness = 2
panelStroke.Parent = controlPanel

-- Titre
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -30, 0, 28)
titleLabel.Position = UDim2.new(0, 15, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.TextSize = 22
titleLabel.TextColor3 = Color3.fromRGB(0, 240, 255)
titleLabel.Text = "🎣 POSTE DE COMMANDE : PÊCHE SOUS-MARINE"
titleLabel.Parent = controlPanel

-- Jauge de statut
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -30, 0, 22)
statusLabel.Position = UDim2.new(0, 15, 0, 38)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 14
statusLabel.TextColor3 = Color3.fromRGB(175, 195, 215)
statusLabel.Text = "Statut : Prêt à lancer l'électro-aimant dans les profondeurs."
statusLabel.Parent = controlPanel

-- Bouton de largage de l'aimant
local btnDropMagnet = Instance.new("TextButton")
btnDropMagnet.Name = "BtnDropMagnet"
btnDropMagnet.Size = UDim2.new(0, 320, 0, 48)
btnDropMagnet.Position = UDim2.new(0, 15, 0, 75)
btnDropMagnet.BackgroundColor3 = Color3.fromRGB(0, 175, 220)
btnDropMagnet.Font = Enum.Font.GothamBlack
btnDropMagnet.TextSize = 17
btnDropMagnet.TextColor3 = Color3.fromRGB(255, 255, 255)
btnDropMagnet.Text = "⚓ LÂCHER L'ÉLECTRO-AIMANT"
btnDropMagnet.Parent = controlPanel

local dropCorner = Instance.new("UICorner")
dropCorner.CornerRadius = UDim.new(0, 10)
dropCorner.Parent = btnDropMagnet

-- Bouton Quitter (Retour au Quai)
local btnExit = Instance.new("TextButton")
btnExit.Name = "BtnExit"
btnExit.Size = UDim2.new(0, 185, 0, 48)
btnExit.Position = UDim2.new(0, 350, 0, 75)
btnExit.BackgroundColor3 = Color3.fromRGB(45, 50, 60)
btnExit.Font = Enum.Font.GothamBold
btnExit.TextSize = 14
btnExit.TextColor3 = Color3.fromRGB(220, 225, 235)
btnExit.Text = "✕ QUITTER LA GRUE"
btnExit.Parent = controlPanel

local exitCorner = Instance.new("UICorner")
exitCorner.CornerRadius = UDim.new(0, 10)
exitCorner.Parent = btnExit

-- Carte Pop-up de Récompense (Centre écran)
local rewardCard = Instance.new("Frame")
rewardCard.Name = "RewardCard"
rewardCard.Size = UDim2.new(0, 440, 0, 260)
rewardCard.AnchorPoint = Vector2.new(0.5, 0.5)
rewardCard.Position = UDim2.new(0.5, 0, 0.45, 0)
rewardCard.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
rewardCard.BorderSizePixel = 0
rewardCard.Visible = false
rewardCard.Parent = screenGui

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 18)
cardCorner.Parent = rewardCard

local cardStroke = Instance.new("UIStroke")
cardStroke.Color = Color3.fromRGB(255, 215, 0)
cardStroke.Thickness = 3
cardStroke.Parent = rewardCard

local rewardHeader = Instance.new("TextLabel")
rewardHeader.Name = "Header"
rewardHeader.Size = UDim2.new(1, 0, 0, 38)
rewardHeader.Position = UDim2.new(0, 0, 0, 12)
rewardHeader.BackgroundTransparency = 1
rewardHeader.Font = Enum.Font.FredokaOne
rewardHeader.TextSize = 24
rewardHeader.TextColor3 = Color3.fromRGB(255, 215, 0)
rewardHeader.Text = "🎉 VÉHICULE REPÊCHÉ !"
rewardHeader.Parent = rewardCard

local carNameLabel = Instance.new("TextLabel")
carNameLabel.Name = "CarName"
carNameLabel.Size = UDim2.new(1, -20, 0, 36)
carNameLabel.Position = UDim2.new(0, 10, 0, 55)
carNameLabel.BackgroundTransparency = 1
carNameLabel.Font = Enum.Font.GothamBlack
carNameLabel.TextSize = 26
carNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
carNameLabel.Text = "#6 Flash McQueen ⚡"
carNameLabel.Parent = rewardCard

local rarityBadge = Instance.new("TextLabel")
rarityBadge.Name = "RarityBadge"
rarityBadge.Size = UDim2.new(0, 180, 0, 28)
rarityBadge.AnchorPoint = Vector2.new(0.5, 0)
rarityBadge.Position = UDim2.new(0.5, 0, 0, 96)
rarityBadge.BackgroundColor3 = Color3.fromRGB(255, 60, 40)
rarityBadge.Font = Enum.Font.GothamBold
rarityBadge.TextSize = 14
rarityBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
rarityBadge.Text = "MYTHIQUE"
rarityBadge.Parent = rewardCard
local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(0, 8)
badgeCorner.Parent = rarityBadge

local descLabel = Instance.new("TextLabel")
descLabel.Name = "Desc"
descLabel.Size = UDim2.new(1, -30, 0, 44)
descLabel.Position = UDim2.new(0, 15, 0, 136)
descLabel.BackgroundTransparency = 1
descLabel.Font = Enum.Font.GothamMedium
descLabel.TextSize = 13
descLabel.TextColor3 = Color3.fromRGB(180, 240, 200)
descLabel.Text = "Ajouté à votre inventaire ! Vous pouvez désormais l'exposer dans votre Showroom pour générer du Cash passif."
descLabel.TextWrapped = true
descLabel.Parent = rewardCard

local btnClaim = Instance.new("TextButton")
btnClaim.Name = "BtnClaim"
btnClaim.Size = UDim2.new(0, 220, 0, 42)
btnClaim.AnchorPoint = Vector2.new(0.5, 1)
btnClaim.Position = UDim2.new(0.5, 0, 1, -16)
btnClaim.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
btnClaim.Font = Enum.Font.GothamBlack
btnClaim.TextSize = 15
btnClaim.TextColor3 = Color3.fromRGB(255, 255, 255)
btnClaim.Text = "RÉCUPÉRER"
btnClaim.Parent = rewardCard
local claimCorner = Instance.new("UICorner")
claimCorner.CornerRadius = UDim.new(0, 10)
claimCorner.Parent = btnClaim

-- =============================================================================
-- LOGIQUE ET ANIMATIONS DE PÊCHE
-- =============================================================================
local isFishing = false

local function setMagnetY(y: number)
    if craneMagnet then
        craneMagnet.CFrame = CFrame.new(0, y, -165) * CFrame.Angles(0, 0, math.rad(90))
    end
    if winchCable then
        local cableLength = 32 - y
        winchCable.Size = Vector3.new(0.35, cableLength, 0.35)
        winchCable.CFrame = CFrame.new(0, 32 - (cableLength / 2), -165)
    end
end

local function runFishingSequence()
    if isFishing then return end
    isFishing = true
    btnDropMagnet.Active = false
    btnDropMagnet.BackgroundColor3 = Color3.fromRGB(80, 90, 100)
    btnDropMagnet.Text = "⏳ PLONGÉE EN COURS..."
    rewardCard.Visible = false

    -- 1. Descente de l'aimant vers l'eau
    statusLabel.Text = "Statut : Descente de l'aimant vers le bassin aquatique..."
    soundWinch:Play()

    local dropTime = 2.4
    local startTime = os.clock()
    while os.clock() - startTime < dropTime do
        local alpha = (os.clock() - startTime) / dropTime
        local currentY = MAGNET_REST_Y + alpha * (MAGNET_DEEP_Y - MAGNET_REST_Y)
        setMagnetY(currentY)
        local depthMeters = math.floor(math.max(0, -currentY) * 3)
        statusLabel.Text = string.format("Statut : Profondeur atteinte : %d mètres...", depthMeters)
        task.wait(0.03)
    end
    setMagnetY(MAGNET_DEEP_Y)

    -- 2. Déclenchement de la détection magnétique
    statusLabel.Text = "Statut : Détection électromagnétique... ACCROCHAGE !"
    soundZap:Play()
    task.wait(0.6)

    -- Appel serveur pour roll le loot
    if deployCraneEvent then
        deployCraneEvent:FireServer(80) -- Profondeur cible
    end
end

-- Réception du véhicule repêché par le serveur
if craneHookedEvent then
    craneHookedEvent.OnClientEvent:Connect(function(vehicleId: string, name: string, rarity: string, depth: number, isNew: boolean)
        statusLabel.Text = string.format("Statut : Épave accrochée ! Remontée du câble (%s)...", name)

        -- 3. Remontée du câble
        local hookedModel: Model? = nil
        pcall(function()
            local cfg = CarBuilder.GetVehicleConfig(vehicleId)
            hookedModel = cfg.Builder()
            if hookedModel then
                hookedModel.Parent = Workspace
            end
        end)

        local riseTime = 2.8
        local startRise = os.clock()
        while os.clock() - startRise < riseTime do
            local alpha = (os.clock() - startRise) / riseTime
            local currentY = MAGNET_DEEP_Y + alpha * (MAGNET_REST_Y - MAGNET_DEEP_Y)
            setMagnetY(currentY)

            if hookedModel then
                hookedModel:PivotTo(CFrame.new(0, currentY - 2.8, -165) * CFrame.Angles(math.rad(10), 0, 0))
            end
            task.wait(0.03)
        end
        setMagnetY(MAGNET_REST_Y)

        soundCheer:Play()

        -- 4. Affichage de la carte de récompense
        carNameLabel.Text = name
        rarityBadge.Text = string.upper(rarity)
        if rarity == "Légendaire" or rarity == "Mythique" then
            rarityBadge.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
        elseif rarity == "Épique" then
            rarityBadge.BackgroundColor3 = Color3.fromRGB(160, 40, 220)
        elseif rarity == "Rare" then
            rarityBadge.BackgroundColor3 = Color3.fromRGB(40, 140, 240)
        else
            rarityBadge.BackgroundColor3 = Color3.fromRGB(80, 160, 80)
        end

        descLabel.Text = if isNew
            then "Nouveau véhicule débloqué ! Il a été transféré à votre garage."
            else "Véhicule déjà possédé ! Votre revenu passif du garage a été boosté."

        rewardCard.Visible = true

        -- Nettoyage du modèle temporaire accroché
        task.delay(4, function()
            if hookedModel then
                hookedModel:Destroy()
                hookedModel = nil
            end
        end)

        isFishing = false
        btnDropMagnet.Active = true
        btnDropMagnet.BackgroundColor3 = Color3.fromRGB(0, 175, 220)
        btnDropMagnet.Text = "⚓ LÂCHER L'ÉLECTRO-AIMANT"
        statusLabel.Text = "Statut : Prêt pour un nouveau lancer !"
    end)
end

btnDropMagnet.MouseButton1Click:Connect(runFishingSequence)

btnClaim.MouseButton1Click:Connect(function()
    rewardCard.Visible = false
end)

btnExit.MouseButton1Click:Connect(function()
    rewardCard.Visible = false
    player:SetAttribute("CurrentMode", "Hub")
end)

-- Activation / Désactivation du HUD selon le mode
local function onModeChanged()
    local mode = tostring(player:GetAttribute("CurrentMode") or "Hub")
    screenGui.Enabled = (mode == "Crane")
    if mode ~= "Crane" then
        rewardCard.Visible = false
    end
end

player:GetAttributeChangedSignal("CurrentMode"):Connect(onModeChanged)
task.spawn(onModeChanged)

print("[CraneController] Module client de contrôle de la Grue initialisé avec succès.")
