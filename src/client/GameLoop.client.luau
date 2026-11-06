--!strict
--[[
    STOP AT THE FRAME - GAME LOOP & FRAME GRADING (CLIENT SCRIPT)
    Gère la boucle de saut infinie de la Lotus Rally, les inputs d'arrêt (Espace / Clic / Touch),
    le calcul de précision par rapport au TargetFrame, et l'affichage des grades.
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
-- 1. CRÉATION DE L'INTERFACE UTILISATEUR (ScreenGui)
-- =============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Flash néon plein écran pour le "FRAME PERFECT!"
local flashFrame = Instance.new("Frame")
flashFrame.Name = "NeonFlash"
flashFrame.Size = UDim2.new(1, 0, 1, 0)
flashFrame.BackgroundColor3 = Color3.fromRGB(255, 235, 120)
flashFrame.BackgroundTransparency = 1
flashFrame.ZIndex = 20
flashFrame.Parent = screenGui

-- Label du véhicule en bas au centre : "#1 Lotus Rally"
local vehicleLabel = Instance.new("TextLabel")
vehicleLabel.Name = "VehicleLabel"
vehicleLabel.Size = UDim2.new(0, 360, 0, 40)
vehicleLabel.AnchorPoint = Vector2.new(0.5, 1)
vehicleLabel.Position = UDim2.new(0.5, 0, 1, -26)
vehicleLabel.BackgroundTransparency = 1
vehicleLabel.Font = Enum.Font.GothamBlack
vehicleLabel.TextSize = 22
vehicleLabel.TextColor3 = Color3.fromRGB(240, 242, 245)
vehicleLabel.TextStrokeColor3 = Color3.fromRGB(15, 18, 22)
vehicleLabel.TextStrokeTransparency = 0
vehicleLabel.Text = "#1 Lotus Rally"
vehicleLabel.Parent = screenGui

-- Conteneur central pour le résultat géant
local resultContainer = Instance.new("Frame")
resultContainer.Name = "ResultContainer"
resultContainer.Size = UDim2.new(0, 500, 0, 160)
resultContainer.AnchorPoint = Vector2.new(0.5, 0.5)
resultContainer.Position = UDim2.new(0.5, 0, 0.38, 0)
resultContainer.BackgroundTransparency = 1
resultContainer.Visible = false
resultContainer.Parent = screenGui

local gradeLabel = Instance.new("TextLabel")
gradeLabel.Name = "GradeLabel"
gradeLabel.Size = UDim2.new(1, 0, 0, 75)
gradeLabel.Position = UDim2.new(0, 0, 0, 0)
gradeLabel.BackgroundTransparency = 1
gradeLabel.Font = Enum.Font.FredokaOne
gradeLabel.TextSize = 58
gradeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
gradeLabel.TextStrokeColor3 = Color3.fromRGB(10, 12, 16)
gradeLabel.TextStrokeTransparency = 0
gradeLabel.Text = "FRAME PERFECT!"
gradeLabel.Parent = resultContainer

local accuracyLabel = Instance.new("TextLabel")
accuracyLabel.Name = "AccuracyLabel"
accuracyLabel.Size = UDim2.new(1, 0, 0, 40)
accuracyLabel.Position = UDim2.new(0, 0, 0, 80)
accuracyLabel.BackgroundTransparency = 1
accuracyLabel.Font = Enum.Font.GothamBlack
accuracyLabel.TextSize = 26
accuracyLabel.TextColor3 = Color3.fromRGB(245, 245, 250)
accuracyLabel.TextStrokeColor3 = Color3.fromRGB(12, 14, 18)
accuracyLabel.TextStrokeTransparency = 0.2
accuracyLabel.Text = "Précision : 100% (0.1 studs)"
accuracyLabel.Parent = resultContainer

-- Instruction d'aide discrète
local hintLabel = Instance.new("TextLabel")
hintLabel.Name = "HintLabel"
hintLabel.Size = UDim2.new(0, 400, 0, 30)
hintLabel.AnchorPoint = Vector2.new(0.5, 1)
hintLabel.Position = UDim2.new(0.5, 0, 1, -70)
hintLabel.BackgroundTransparency = 1
hintLabel.Font = Enum.Font.GothamMedium
hintLabel.TextSize = 15
hintLabel.TextColor3 = Color3.fromRGB(180, 255, 195)
hintLabel.TextStrokeColor3 = Color3.fromRGB(10, 15, 20)
hintLabel.TextStrokeTransparency = 0.4
hintLabel.Text = "[ESPACE] ou [CLIC GAUCHE] pour figer la voiture dans le cadre"
hintLabel.Parent = screenGui

-- =============================================================================
-- 2. CALIBRATION GÉOMÉTRIQUE DU SAUT PARABOLIQUE
-- =============================================================================
local targetFrame = Workspace:WaitForChild("TargetFrame", 15) :: Model?
local centerPoint = (targetFrame and targetFrame:WaitForChild("CenterPoint", 10)) :: BasePart?

-- Si centerPoint est introuvable, coordonnées de secours calculées à l'étape 1
local targetPos = (centerPoint and centerPoint.Position) or Vector3.new(0, 66.84, 158.22)

-- Trajectoire parabolique descendante :
-- Départ au sommet de la colline, passage EXACT à travers TargetFrame à t = 0.60
local JUMP_DURATION = 2.8 -- Durée totale du vol (secondes)
local T_TARGET = 0.60 -- Moment exact du passage dans le cadre

local zStart = 260.0
local zTarget = targetPos.Z
local zEnd = 90.0

local yStart = 96.0
local yTarget = targetPos.Y
local yEnd = 38.0

-- Résolution des coefficients quadratiques f(t) = a*t^2 + b*t + c
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

local function getJumpPosition(tNorm: number): Vector3
    local z = az * (tNorm ^ 2) + bz * tNorm + cz
    local y = ay * (tNorm ^ 2) + by * tNorm + cy
    return Vector3.new(0, y, z)
end

-- =============================================================================
-- 3. GESTION DU GRADE ET DES EFFETS
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
    flashFrame.BackgroundTransparency = 0.4
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
-- 4. ÉTAT DU JEU ET ÉCOUTE DES ENTRÉES DU JOUEUR
-- =============================================================================
local currentCar: Model? = nil
local isJumping = false
local hasStopped = false
local currentElapsed = 0

local function onPlayerInput()
    if not isJumping or hasStopped or not currentCar then return end
    hasStopped = true
    isJumping = false

    local root = currentCar.PrimaryPart
    if not root then return end

    -- 1. Fige immédiatement la voiture sur place
    root.Anchored = true
    for _, part in ipairs(currentCar:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
        end
    end

    -- 2. Calcul de la distance 3D précise entre RootPart et CenterPoint
    local actualTargetPos = (centerPoint and centerPoint.Position) or targetPos
    local distance = (root.Position - actualTargetPos).Magnitude
    local accuracyPct = computeAccuracyPercentage(distance)

    -- 3. Attribution du grade selon les seuils
    local gradeText = "RATÉ!"
    local gradeColor = Color3.fromRGB(255, 55, 55)

    if distance < 0.8 then
        gradeText = "FRAME PERFECT!"
        gradeColor = Color3.fromRGB(255, 215, 0) -- Doré
        triggerNeonFlash()
        triggerScreenShake(0.8, 0.35)
    elseif distance < 2.5 then
        gradeText = "PERFECT!"
        gradeColor = Color3.fromRGB(0, 255, 80) -- Vert fluo
    elseif distance < 5.0 then
        gradeText = "GOOD!"
        gradeColor = Color3.fromRGB(255, 215, 45) -- Jaune
    else
        gradeText = "RATÉ!"
        gradeColor = Color3.fromRGB(255, 50, 50) -- Rouge
        -- Active la physique/dé-ancrage pour que la voiture tombe et s'écrase
        task.defer(function()
            for _, part in ipairs(currentCar:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = false
                    part.CanCollide = true
                end
            end
            root.AssemblyLinearVelocity = Vector3.new(0, -15, -45)
            root.AssemblyAngularVelocity = Vector3.new(math.random(-5, 5), math.random(-3, 3), math.random(-8, 8))
        end)
    end

    -- 4. Affichage visuel du résultat avec animation pop-in
    gradeLabel.Text = gradeText
    gradeLabel.TextColor3 = gradeColor
    accuracyLabel.Text = string.format("Précision : %d%% (%.2f studs)", accuracyPct, distance)

    resultContainer.Visible = true
    resultContainer.Size = UDim2.new(0, 560, 0, 180)
    TweenService:Create(resultContainer, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 500, 0, 160),
    }):Play()
end

-- Écoute Clavier (Espace), Souris (Clic gauche) et Écran tactile (Touch)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Space
        or input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        onPlayerInput()
    end
end)

-- =============================================================================
-- 5. BOUCLE DE SAUT INFINIE
-- =============================================================================
local function startNextJump()
    -- Nettoyage de l'ancienne voiture
    if currentCar then
        currentCar:Destroy()
        currentCar = nil
    end

    resultContainer.Visible = false
    hasStopped = false
    currentElapsed = 0

    -- Instanciation de la Lotus Rally
    currentCar = CarBuilder.CreateLotusRally()
    currentCar.Parent = Workspace

    -- Position initiale au sommet de la colline
    local startPos = getJumpPosition(0)
    local nextPos = getJumpPosition(0.02)
    local startCF = CFrame.lookAt(startPos, nextPos)
    currentCar:PivotTo(startCF)

    isJumping = true
end

-- Mise à jour continue du déplacement parabolique à chaque frame
RunService.RenderStepped:Connect(function(dt)
    if not isJumping or hasStopped or not currentCar then return end

    currentElapsed += dt
    local tNorm = math.clamp(currentElapsed / JUMP_DURATION, 0, 1)

    local currentPos = getJumpPosition(tNorm)
    -- Calcul de la tangente pour orienter le véhicule le long de sa trajectoire
    local lookAheadT = math.clamp(tNorm + 0.015, 0, 1)
    local nextPos = getJumpPosition(lookAheadT)
    local moveDir = (nextPos - currentPos)

    local targetCF: CFrame
    if moveDir.Magnitude > 0.001 then
        targetCF = CFrame.lookAt(currentPos, nextPos)
    else
        targetCF = currentCar:GetPivot()
    end

    currentCar:PivotTo(targetCF)

    -- Si la voiture atteint la fin du saut sans appui du joueur
    if tNorm >= 1.0 then
        onPlayerInput() -- Déclenche automatiquement un "RATÉ"
    end
end)

-- Boucle infinie orchestrant les séquences de saut
task.spawn(function()
    task.wait(1.0) -- Léger temps de chargement initial
    while true do
        startNextJump()

        -- Attend la fin du saut ou l'appui du joueur
        while isJumping and not hasStopped do
            task.wait()
        end

        -- Affiche la note et le % de précision pendant 1.5 seconde
        task.wait(1.5)
    end
end)

print("[GameLoop] Boucle de saut Lotus Rally et système de Frame Grading activés.")
