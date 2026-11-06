--!strict
--[[
    STOP AT THE FRAME - GAME LOOP & FRAME GRADING (CLIENT SCRIPT)
    Gère la trajectoire parabolique avec saut cabré (+24° pitch) et alignement
    mathématique 100% parfait à t = T_TARGET avec TargetCFrame,
    le TargetFrame en boucle fermée extérieure unique sans clone fantôme ni lignes internes,
    et le système de notation de précision (Frame Grading).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarBuilder = require(ReplicatedStorage:WaitForChild("CarBuilder") :: ModuleScript)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera") :: Camera

-- =============================================================================
-- 1. CONNEXION RÉSEAU (REMOTES)
-- =============================================================================
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10) :: Folder?
local submitEvent: RemoteEvent? = nil
if remotesFolder then
    submitEvent = remotesFolder:WaitForChild("SubmitStopResult", 10) :: RemoteEvent?
end

-- =============================================================================
-- 2. GÉOMÉTRIE ET CIBLE UNIQUE "TargetCFrame"
-- =============================================================================
local slopeVector = Vector3.new(0, 120, 400)
local uDir = slopeVector.Unit
local rightVec = Vector3.new(1, 0, 0)
local normalVec = uDir:Cross(rightVec)
local downhillDir = -uDir -- Direction descendante vers la caméra

local midSurfacePos = Vector3.new(0, 61.0, 160.0)
local frameCenterPos = midSurfacePos + (normalVec * 5.8)

-- CFrame de référence unique pour le passage dans le cadre (de face face à la caméra)
local TargetCFrame = CFrame.lookAt(frameCenterPos, frameCenterPos + downhillDir, normalVec)

-- =============================================================================
-- 3. INTERFACE UTILISATEUR COMPLETE (ScreenGui)
-- =============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Flash néon plein écran (FRAME PERFECT)
local flashFrame = Instance.new("Frame")
flashFrame.Name = "NeonFlash"
flashFrame.Size = UDim2.new(1, 0, 1, 0)
flashFrame.BackgroundColor3 = Color3.fromRGB(255, 235, 120)
flashFrame.BackgroundTransparency = 1
flashFrame.ZIndex = 30
flashFrame.Parent = screenGui

-- Bannière supérieure "STOP AT THE FRAME"
local titleBanner = Instance.new("TextLabel")
titleBanner.Name = "TitleBanner"
titleBanner.Size = UDim2.new(0, 520, 0, 46)
titleBanner.AnchorPoint = Vector2.new(0.5, 0)
titleBanner.Position = UDim2.new(0.5, 0, 0, 22)
titleBanner.BackgroundTransparency = 1
titleBanner.Font = Enum.Font.FredokaOne
titleBanner.TextSize = 34
titleBanner.TextColor3 = Color3.fromRGB(255, 225, 60)
titleBanner.TextStrokeColor3 = Color3.fromRGB(12, 14, 18)
titleBanner.TextStrokeTransparency = 0
titleBanner.Text = "⚡ STOP AT THE FRAME ⚡"
titleBanner.Parent = screenGui

-- Card d'état joueur (Haut Gauche) : Cash, Streak, Titre
local statsCard = Instance.new("Frame")
statsCard.Name = "StatsCard"
statsCard.Size = UDim2.new(0, 230, 0, 115)
statsCard.Position = UDim2.new(0, 24, 0, 24)
statsCard.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
statsCard.BackgroundTransparency = 0.25
statsCard.BorderSizePixel = 0
statsCard.Parent = screenGui

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 12)
statsCorner.Parent = statsCard

local statsStroke = Instance.new("UIStroke")
statsStroke.Color = Color3.fromRGB(50, 60, 75)
statsStroke.Thickness = 1.5
statsStroke.Transparency = 0.3
statsStroke.Parent = statsCard

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "CashLabel"
cashLabel.Size = UDim2.new(1, -24, 0, 28)
cashLabel.Position = UDim2.new(0, 12, 0, 10)
cashLabel.BackgroundTransparency = 1
cashLabel.Font = Enum.Font.GothamBlack
cashLabel.TextSize = 18
cashLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.Text = "💰 Cash : $100"
cashLabel.Parent = statsCard

local streakLabel = Instance.new("TextLabel")
streakLabel.Name = "StreakLabel"
streakLabel.Size = UDim2.new(1, -24, 0, 26)
streakLabel.Position = UDim2.new(0, 12, 0, 42)
streakLabel.BackgroundTransparency = 1
streakLabel.Font = Enum.Font.GothamBold
streakLabel.TextSize = 16
streakLabel.TextColor3 = Color3.fromRGB(255, 160, 50)
streakLabel.TextXAlignment = Enum.TextXAlignment.Left
streakLabel.Text = "🔥 Série : 0"
streakLabel.Parent = statsCard

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -24, 0, 26)
titleLabel.Position = UDim2.new(0, 12, 0, 74)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamMedium
titleLabel.TextSize = 14
titleLabel.TextColor3 = Color3.fromRGB(190, 220, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "🎖️ Titre : Réflexes de Tortue"
titleLabel.Parent = statsCard

-- Conteneur central pour le résultat géant
local resultContainer = Instance.new("Frame")
resultContainer.Name = "ResultContainer"
resultContainer.Size = UDim2.new(0, 540, 0, 160)
resultContainer.AnchorPoint = Vector2.new(0.5, 0.5)
resultContainer.Position = UDim2.new(0.5, 0, 0.36, 0)
resultContainer.BackgroundTransparency = 1
resultContainer.Visible = false
resultContainer.ZIndex = 25
resultContainer.Parent = screenGui

local gradeLabel = Instance.new("TextLabel")
gradeLabel.Name = "GradeLabel"
gradeLabel.Size = UDim2.new(1, 0, 0, 75)
gradeLabel.Position = UDim2.new(0, 0, 0, 0)
gradeLabel.BackgroundTransparency = 1
gradeLabel.Font = Enum.Font.FredokaOne
gradeLabel.TextSize = 62
gradeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
gradeLabel.TextStrokeColor3 = Color3.fromRGB(10, 12, 16)
gradeLabel.TextStrokeTransparency = 0
gradeLabel.Text = "FRAME PERFECT!"
gradeLabel.Parent = resultContainer

local accuracyLabel = Instance.new("TextLabel")
accuracyLabel.Name = "AccuracyLabel"
accuracyLabel.Size = UDim2.new(1, 0, 0, 38)
accuracyLabel.Position = UDim2.new(0, 0, 0, 80)
accuracyLabel.BackgroundTransparency = 1
accuracyLabel.Font = Enum.Font.GothamBlack
accuracyLabel.TextSize = 25
accuracyLabel.TextColor3 = Color3.fromRGB(245, 245, 250)
accuracyLabel.TextStrokeColor3 = Color3.fromRGB(12, 14, 18)
accuracyLabel.TextStrokeTransparency = 0.2
accuracyLabel.Text = "Précision : 100% (0.0 studs)"
accuracyLabel.Parent = resultContainer

local rewardPopupLabel = Instance.new("TextLabel")
rewardPopupLabel.Name = "RewardPopupLabel"
rewardPopupLabel.Size = UDim2.new(1, 0, 0, 30)
rewardPopupLabel.Position = UDim2.new(0, 0, 0, 120)
rewardPopupLabel.BackgroundTransparency = 1
rewardPopupLabel.Font = Enum.Font.GothamBold
rewardPopupLabel.TextSize = 20
rewardPopupLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
rewardPopupLabel.TextStrokeColor3 = Color3.fromRGB(10, 15, 20)
rewardPopupLabel.TextStrokeTransparency = 0.2
rewardPopupLabel.Text = "+$50"
rewardPopupLabel.Parent = resultContainer

-- Barre de sélection de véhicule en bas
local selectorBar = Instance.new("Frame")
selectorBar.Name = "VehicleSelectorBar"
selectorBar.Size = UDim2.new(0, 480, 0, 60)
selectorBar.AnchorPoint = Vector2.new(0.5, 1)
selectorBar.Position = UDim2.new(0.5, 0, 1, -44)
selectorBar.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
selectorBar.BackgroundTransparency = 0.25
selectorBar.BorderSizePixel = 0
selectorBar.Parent = screenGui

local selectorCorner = Instance.new("UICorner")
selectorCorner.CornerRadius = UDim.new(0, 14)
selectorCorner.Parent = selectorBar

local selectorStroke = Instance.new("UIStroke")
selectorStroke.Color = Color3.fromRGB(50, 60, 75)
selectorStroke.Thickness = 1.5
selectorStroke.Transparency = 0.3
selectorStroke.Parent = selectorBar

local btnPrev = Instance.new("TextButton")
btnPrev.Name = "BtnPrev"
btnPrev.Size = UDim2.new(0, 46, 0, 46)
btnPrev.Position = UDim2.new(0, 8, 0.5, -23)
btnPrev.BackgroundColor3 = Color3.fromRGB(34, 38, 48)
btnPrev.Font = Enum.Font.GothamBlack
btnPrev.TextSize = 22
btnPrev.TextColor3 = Color3.fromRGB(255, 255, 255)
btnPrev.Text = "◀"
btnPrev.BorderSizePixel = 0
btnPrev.Parent = selectorBar
local prevCorner = Instance.new("UICorner")
prevCorner.CornerRadius = UDim.new(0, 10)
prevCorner.Parent = btnPrev

local btnNext = Instance.new("TextButton")
btnNext.Name = "BtnNext"
btnNext.Size = UDim2.new(0, 46, 0, 46)
btnNext.Position = UDim2.new(1, -54, 0.5, -23)
btnNext.BackgroundColor3 = Color3.fromRGB(34, 38, 48)
btnNext.Font = Enum.Font.GothamBlack
btnNext.TextSize = 22
btnNext.TextColor3 = Color3.fromRGB(255, 255, 255)
btnNext.Text = "▶"
btnNext.BorderSizePixel = 0
btnNext.Parent = selectorBar
local nextCorner = Instance.new("UICorner")
nextCorner.CornerRadius = UDim.new(0, 10)
nextCorner.Parent = btnNext

local vehicleTitleLabel = Instance.new("TextLabel")
vehicleTitleLabel.Name = "VehicleTitleLabel"
vehicleTitleLabel.Size = UDim2.new(1, -120, 0, 26)
vehicleTitleLabel.Position = UDim2.new(0, 60, 0, 7)
vehicleTitleLabel.BackgroundTransparency = 1
vehicleTitleLabel.Font = Enum.Font.GothamBlack
vehicleTitleLabel.TextSize = 20
vehicleTitleLabel.TextColor3 = Color3.fromRGB(250, 250, 255)
vehicleTitleLabel.Text = "#1 Lotus Rally"
vehicleTitleLabel.Parent = selectorBar

local vehicleSubLabel = Instance.new("TextLabel")
vehicleSubLabel.Name = "VehicleSubLabel"
vehicleSubLabel.Size = UDim2.new(1, -120, 0, 20)
vehicleSubLabel.Position = UDim2.new(0, 60, 0, 33)
vehicleSubLabel.BackgroundTransparency = 1
vehicleSubLabel.Font = Enum.Font.GothamBold
vehicleSubLabel.TextSize = 13
vehicleSubLabel.TextColor3 = Color3.fromRGB(160, 175, 195)
vehicleSubLabel.Text = "Vitesse: x1.0 • Prime: $50"
vehicleSubLabel.Parent = selectorBar

-- Instruction d'aide
local hintLabel = Instance.new("TextLabel")
hintLabel.Name = "HintLabel"
hintLabel.Size = UDim2.new(0, 560, 0, 24)
hintLabel.AnchorPoint = Vector2.new(0.5, 1)
hintLabel.Position = UDim2.new(0.5, 0, 1, -14)
hintLabel.BackgroundTransparency = 1
hintLabel.Font = Enum.Font.GothamMedium
hintLabel.TextSize = 13
hintLabel.TextColor3 = Color3.fromRGB(180, 255, 195)
hintLabel.TextStrokeColor3 = Color3.fromRGB(10, 15, 20)
hintLabel.TextStrokeTransparency = 0.4
hintLabel.Text = "[ESPACE] ou [CLIC GAUCHE] pour figer • [Q / D] ou [← / →] Changer de véhicule"
hintLabel.Parent = screenGui

-- =============================================================================
-- 4. BINDING EN TEMPS RÉEL DES LEADERSTATS
-- =============================================================================
local function bindLeaderstats()
    local leaderstats = player:WaitForChild("leaderstats", 10)
    if not leaderstats then return end

    local cash = leaderstats:WaitForChild("Cash", 10) :: IntValue?
    local streak = leaderstats:WaitForChild("Streak", 10) :: IntValue?
    local title = leaderstats:WaitForChild("Title", 10) :: StringValue?

    local function updateStats()
        if cash then cashLabel.Text = string.format("💰 Cash : $%d", cash.Value) end
        if streak then streakLabel.Text = string.format("🔥 Série : %d", streak.Value) end
        if title then titleLabel.Text = string.format("🎖️ Titre : %s", title.Value) end
    end

    if cash then cash.Changed:Connect(updateStats) end
    if streak then streak.Changed:Connect(updateStats) end
    if title then title.Changed:Connect(updateStats) end
    updateStats()
end
task.spawn(bindLeaderstats)

-- =============================================================================
-- 5. ÉTAT DES VÉHICULES ET SÉLECTION DYNAMIQUE
-- =============================================================================
local totalVehicles = #CarBuilder.Vehicles
local currentVehicleIndex = 1
local currentConfig = CarBuilder.GetVehicleConfig(currentVehicleIndex)

local currentCar: Model? = nil
local isJumping = false
local hasStopped = false
local currentElapsed = 0

local function updateVehicleUI()
    currentConfig = CarBuilder.GetVehicleConfig(currentVehicleIndex)
    vehicleTitleLabel.Text = currentConfig.Name
    vehicleSubLabel.Text = string.format("Vitesse: x%.2f • Prime: $%d", currentConfig.SpeedMultiplier, currentConfig.RewardCash)
end

local function applyVehicleChange(newIndex: number)
    currentVehicleIndex = math.clamp(newIndex, 1, totalVehicles)
    updateVehicleUI()

    -- Reconstruit le TargetFrame avec la boucle fermée extérieure unique correspondant au véhicule
    CarBuilder.CreateTargetFrame(currentVehicleIndex, frameCenterPos)

    -- Relance immédiatement le saut avec le nouveau véhicule
    hasStopped = true
    isJumping = false
end

btnPrev.MouseButton1Click:Connect(function()
    local nextIdx = currentVehicleIndex - 1
    if nextIdx < 1 then nextIdx = totalVehicles end
    applyVehicleChange(nextIdx)
end)

btnNext.MouseButton1Click:Connect(function()
    local nextIdx = currentVehicleIndex + 1
    if nextIdx > totalVehicles then nextIdx = 1 end
    applyVehicleChange(nextIdx)
end)

-- =============================================================================
-- 6. EFFETS VISUELS ET CALCULS DE PRÉCISION
-- =============================================================================
local function triggerScreenShake(intensity: number, duration: number)
    task.spawn(function()
        local startTime = os.clock()
        while (os.clock() - startTime) < duration do
            local elapsed = os.clock() - startTime
            local decay = 1 - (elapsed / duration)
            local offset = Vector3.new(
                (math.random() - 0.5) * 2 * intensity * decay,
                (math.random() - 0.5) * 2 * intensity * decay,
                0
            )
            camera:SetAttribute("ShakeOffset", offset)
            RunService.RenderStepped:Wait()
        end
        camera:SetAttribute("ShakeOffset", Vector3.zero)
    end)
end

local function triggerNeonFlash()
    flashFrame.BackgroundTransparency = 0.35
    local tween = TweenService:Create(flashFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1,
    })
    tween:Play()
end

local function computeAccuracyPercentage(dist: number): number
    if dist <= 0.8 then
        return math.clamp(math.floor(98 + (1 - dist / 0.8) * 2), 98, 100)
    elseif dist <= 2.5 then
        return math.clamp(math.floor(90 + (1 - (dist - 0.8) / 1.7) * 7.9), 90, 97)
    elseif dist <= 5.0 then
        return math.clamp(math.floor(75 + (1 - (dist - 2.5) / 2.5) * 14.9), 75, 89)
    else
        return math.max(0, math.floor(70 - (dist - 5.0) * 3.5))
    end
end

-- =============================================================================
-- 7. PHYSIQUE DU SAUT ET CONVERGENCE STRICTE VERS TargetCFrame À t = T_TARGET
-- =============================================================================
local JUMP_BASE_DURATION = 2.6 -- Durée de base à vitesse x1.0
local T_TARGET = 0.60 -- Moment exact du passage dans le TargetFrame

-- Points directeurs de la parabole de trajectoire
local zStart = 265.0
local zTarget = frameCenterPos.Z
local zEnd = 85.0

local yStart = 98.0
local yTarget = frameCenterPos.Y
local yEnd = 34.0

-- Résolution de la parabole f(t) = a*t^2 + b*t + c
local dz1 = zTarget - zStart
local dz2 = zEnd - zStart
local az = (dz2 * T_TARGET - dz1) / (T_TARGET * (1 - T_TARGET))
local bz = dz2 - az
local cz = zStart

local dy1 = yTarget - yStart
local dy2 = yEnd - yStart
local ay = (dy2 * T_TARGET - dy1) / (T_TARGET * (1 - T_TARGET))
local by = dy2 - ay
local cy = yStart

local function getJumpCFrame(tNorm: number): CFrame
    -- 1. Position de base le long de la pente
    local z = az * (tNorm ^ 2) + bz * tNorm + cz
    local yBase = ay * (tNorm ^ 2) + by * tNorm + cy

    -- 2. Surélévation parabolique puissante (Saut HAUT au-dessus du cadre)
    -- Culmine à +14 studs à mi-parcours (t = 0.30) et s'annule exactement à t = T_TARGET (0.60)
    local yArc = 0
    local pitchDeg = 0

    if tNorm <= T_TARGET then
        local arcProgress = tNorm / T_TARGET
        -- sin² annule la dérivée verticale à t = T_TARGET : la voiture atterrit tangentiellement
        -- sans décalage vertical résiduel même à 1 stud d'écart (zone PERFECT)
        local sinEnv = math.sin(math.pi * arcProgress) ^ 2
        yArc = 14.0 * sinEnv
        -- Le cabrage s'annule également en douceur avec la même enveloppe
        pitchDeg = 24.0 * sinEnv
    else
        -- Redescente après la cible
        local postProgress = (tNorm - T_TARGET) / (1.0 - T_TARGET)
        pitchDeg = -10.0 * math.sin(math.pi * 0.5 * postProgress)
    end

    local currentPos = Vector3.new(0, yBase + yArc, z)

    -- Si tNorm est exactement à T_TARGET, renvoie strictement TargetCFrame
    if math.abs(tNorm - T_TARGET) < 0.0005 then
        return TargetCFrame
    end

    -- 3. Calcul de la tangente de vol
    local nextT = math.clamp(tNorm + 0.012, 0, 1)
    local nextZ = az * (nextT ^ 2) + bz * nextT + cz
    local nextYBase = ay * (nextT ^ 2) + by * nextT + cy
    local nextYArc = 0
    if nextT <= T_TARGET then
        nextYArc = 14.0 * math.sin(math.pi * (nextT / T_TARGET)) ^ 2
    end
    local nextPos = Vector3.new(0, nextYBase + nextYArc, nextZ)

    local moveDir = (nextPos - currentPos)
    local baseLookCF: CFrame
    if moveDir.Magnitude > 0.001 then
        baseLookCF = CFrame.lookAt(currentPos, nextPos, normalVec)
    else
        baseLookCF = TargetCFrame - TargetCFrame.Position + currentPos
    end

    local pitchCF = CFrame.Angles(math.rad(pitchDeg), 0, 0)
    -- Orientation de vol : basée sur TargetCFrame pour garantir que la rotation finale est toujours correcte
    -- pitchDeg vaut 0 à T_TARGET grâce au sin², donc flightCF === TargetCFrame en position
    local orientBase = TargetCFrame - TargetCFrame.Position + currentPos
    local flightCF = orientBase * pitchCF

    -- 4. Convergence SmoothStep vers TargetCFrame dans les 35% finaux de l'approche
    if tNorm < T_TARGET then
        local approachProgress = tNorm / T_TARGET
        if approachProgress >= 0.65 then
            local alpha = (approachProgress - 0.65) / 0.35
            local smoothAlpha = alpha * alpha * (3 - 2 * alpha)
            local targetAtPos = TargetCFrame - TargetCFrame.Position + currentPos
            return flightCF:Lerp(targetAtPos, smoothAlpha)
        end
        return flightCF
    else
        return flightCF
    end
end

-- =============================================================================
-- 8. GESTION DES INPUTS ET ARRÊT D'URGENCE (STOP)
-- =============================================================================
local function onPlayerInput()
    if not isJumping or hasStopped or not currentCar then return end
    hasStopped = true
    isJumping = false

    local root = currentCar.PrimaryPart
    if not root then return end

    -- 1. Fige immédiatement le véhicule
    root.Anchored = true
    for _, part in ipairs(currentCar:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
        end
    end

    -- 2. Recherche du repère CenterPoint dans TargetFrame
    local targetFrame = Workspace:FindFirstChild("TargetFrame")
    local centerPoint = targetFrame and targetFrame:FindFirstChild("CenterPoint") :: BasePart?
    local actualTargetPos = (centerPoint and centerPoint.Position) or frameCenterPos

    -- 3. Calcul de la distance 3D précise et pourcentage
    local distance = (root.Position - actualTargetPos).Magnitude
    local accuracyPct = computeAccuracyPercentage(distance)

    -- 4. Détermination du grade et récompenses
    local gradeText = "RATÉ!"
    local gradeColor = Color3.fromRGB(255, 55, 55)
    local rewardAmount = 0

    if distance < 0.8 then
        gradeText = "FRAME PERFECT!"
        gradeColor = Color3.fromRGB(255, 215, 0)
        rewardAmount = currentConfig.RewardCash
        -- Snap visuel ultra-satisfaisant : emboîtement parfait dans le cadre
        currentCar:PivotTo(TargetCFrame)
        triggerNeonFlash()
        triggerScreenShake(0.9, 0.4)
    elseif distance < 2.5 then
        gradeText = "PERFECT!"
        gradeColor = Color3.fromRGB(0, 255, 80)
        rewardAmount = math.floor(currentConfig.RewardCash * 0.75)
        triggerScreenShake(0.4, 0.2)
    elseif distance < 5.0 then
        gradeText = "GOOD!"
        gradeColor = Color3.fromRGB(255, 215, 45)
        rewardAmount = math.floor(currentConfig.RewardCash * 0.40)
    else
        gradeText = "RATÉ!"
        gradeColor = Color3.fromRGB(255, 50, 50)
        rewardAmount = 0
        -- Crash physique spectaculaire en cas de raté
        task.defer(function()
            for _, part in ipairs(currentCar:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = false
                    part.CanCollide = true
                end
            end
            root.AssemblyLinearVelocity = Vector3.new(0, -18, -50)
            root.AssemblyAngularVelocity = Vector3.new(math.random(-6, 6), math.random(-4, 4), math.random(-9, 9))
        end)
    end

    -- 5. Transmission sécurisée au serveur pour mise à jour du Cash, Streak et Titre
    if submitEvent then
        submitEvent:FireServer(currentConfig.Id, gradeText, distance, accuracyPct)
    end

    -- 6. Affichage du résultat avec pop-in
    gradeLabel.Text = gradeText
    gradeLabel.TextColor3 = gradeColor
    accuracyLabel.Text = string.format("Précision : %d%% (%.2f studs)", accuracyPct, distance)

    if rewardAmount > 0 then
        rewardPopupLabel.Text = string.format("+$%d (Prime %s)", rewardAmount, currentConfig.Name)
        rewardPopupLabel.Visible = true
    else
        rewardPopupLabel.Text = "Série brisée !"
        rewardPopupLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        rewardPopupLabel.Visible = true
    end

    resultContainer.Visible = true
    resultContainer.Size = UDim2.new(0, 600, 0, 180)
    TweenService:Create(resultContainer, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 540, 0, 160),
    }):Play()
end

-- Écoute Clavier, Souris et Tactile
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Space
        or input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        onPlayerInput()
    elseif input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.A then
        local nextIdx = currentVehicleIndex - 1
        if nextIdx < 1 then nextIdx = totalVehicles end
        applyVehicleChange(nextIdx)
    elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.D then
        local nextIdx = currentVehicleIndex + 1
        if nextIdx > totalVehicles then nextIdx = 1 end
        applyVehicleChange(nextIdx)
    end
end)

-- =============================================================================
-- 9. BOUCLE DE SAUT INFINIE ET RENDU FRAME PAR FRAME
-- =============================================================================
local sirenTimer = 0

local function startNextJump()
    if currentCar then
        currentCar:Destroy()
        currentCar = nil
    end

    resultContainer.Visible = false
    hasStopped = false
    currentElapsed = 0

    currentConfig = CarBuilder.GetVehicleConfig(currentVehicleIndex)
    currentCar = currentConfig.Builder()
    currentCar.Parent = Workspace

    local startCF = getJumpCFrame(0)
    currentCar:PivotTo(startCF)

    isJumping = true
end

RunService.RenderStepped:Connect(function(dt)
    if not isJumping or hasStopped or not currentCar then return end

    local jumpDuration = JUMP_BASE_DURATION / currentConfig.SpeedMultiplier
    currentElapsed += dt
    local tNorm = math.clamp(currentElapsed / jumpDuration, 0, 1)

    local targetCF = getJumpCFrame(tNorm)
    currentCar:PivotTo(targetCF)

    -- Animation des gyrophares pour l'Interceptor
    if currentConfig.Id == "police_interceptor" then
        sirenTimer += dt
        local sirenFlash = math.floor(sirenTimer * 12) % 2 == 0
        local redLight = currentCar:FindFirstChild("Siren_Red") :: BasePart?
        local blueLight = currentCar:FindFirstChild("Siren_Blue") :: BasePart?
        if redLight and blueLight then
            redLight.Color = sirenFlash and Color3.fromRGB(255, 30, 30) or Color3.fromRGB(60, 10, 10)
            blueLight.Color = (not sirenFlash) and Color3.fromRGB(30, 100, 255) or Color3.fromRGB(10, 20, 60)
        end
    end

    -- Temps écoulé sans arrêt du joueur
    if tNorm >= 1.0 then
        onPlayerInput()
    end
end)

task.spawn(function()
    task.wait(0.8)
    -- Initialisation du TargetFrame pour le véhicule sélectionné par défaut
    CarBuilder.CreateTargetFrame(currentVehicleIndex, frameCenterPos)
    updateVehicleUI()

    while true do
        startNextJump()

        while isJumping and not hasStopped do
            task.wait()
        end

        task.wait(1.5)
    end
end)

print("[GameLoop] Trajectoire, boucle fermée TargetFrame et système de grading opérationnels.")
