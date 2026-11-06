--!strict
--[[
    STOP AT THE FRAME - CAMERA CONTROLLER (CLIENT SCRIPT)
    Verrouille la caméra en mode Scriptable en bas de la colline,
    orientée vers le haut pour cadrer le "TargetFrame" vert au premier plan
    avec la pente raide et les immeubles pastel en arrière-plan.
    Désactive également les contrôles du joueur.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera") :: Camera

-- 1. Verrouillage initial de la caméra
camera.CameraType = Enum.CameraType.Scriptable

-- 2. Désactivation des contrôles du joueur
local function disablePlayerControls()
    local playerScripts = player:WaitForChild("PlayerScripts")
    local playerModule = playerScripts:WaitForChild("PlayerModule", 5)
    if playerModule then
        local success, controls = pcall(function()
            local module = require(playerModule) :: any
            return module:GetControls()
        end)
        if success and controls and controls.Disable then
            controls:Disable()
            print("[CameraController] Contrôles joueur désactivés.")
        end
    end
end
task.spawn(disablePlayerControls)

-- 3. Masquer le personnage du joueur pour ne pas gêner la vue
local function setupCharacter(char: Model)
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = 1
        elseif part:IsA("Decal") then
            part.Transparency = 1
        end
    end

    local hrp = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?
    if hrp then
        hrp.Anchored = true
        hrp.CFrame = CFrame.new(0, -50, 0) -- Placé sous la scène
    end
end

if player.Character then
    setupCharacter(player.Character)
end
player.CharacterAdded:Connect(setupCharacter)

-- 4. Recherche du TargetFrame et calcul de la position idéale de caméra
local targetFrame = Workspace:WaitForChild("TargetFrame", 15) :: Model?
local centerPoint = (targetFrame and targetFrame:WaitForChild("CenterPoint", 10)) :: BasePart?

-- Paramètres géométriques de la pente
local slopeVector = Vector3.new(0, 120, 400)
local uDir = slopeVector.Unit -- Monte vers le sommet
local rightVec = Vector3.new(1, 0, 0)
local normalVec = uDir:Cross(rightVec) -- Perpendiculaire au sol vers le haut

-- Position fixe de la caméra : rapprochée à ~20 studs du cadre vert (en contre-plongée légère)
-- Le TargetFrame occupe ainsi une place imposante et majestueuse au premier plan de l'écran.
local fixedCameraCFrame: CFrame? = nil

local function computeCameraCFrame(): CFrame
    local currentTarget = Workspace:FindFirstChild("TargetFrame")
    local cp = currentTarget and currentTarget:FindFirstChild("CenterPoint") :: BasePart?
    local targetPos = (cp and cp.Position) or (centerPoint and centerPoint.Position) or Vector3.new(0, 66.84, 158.22)

    -- Rapprochement à 20 studs devant le TargetFrame le long de la pente
    local roadBasePos = targetPos - (uDir * 20)
    -- Contre-plongée légère : caméra placée sous le centre pour une visée ascendante dynamique
    local eyePos = roadBasePos - (normalVec * 0.4)
    local lookTarget = targetPos + (normalVec * 0.3)

    return CFrame.lookAt(eyePos, lookTarget)
end

fixedCameraCFrame = computeCameraCFrame()

-- 5. Maintien strict de la caméra à chaque frame de rendu
local function onRenderStep()
    camera.CameraType = Enum.CameraType.Scriptable
    if not fixedCameraCFrame or (centerPoint and not fixedCameraCFrame) then
        fixedCameraCFrame = computeCameraCFrame()
    end
    if fixedCameraCFrame then
        local shake = camera:GetAttribute("ShakeOffset")
        if shake and typeof(shake) == "Vector3" then
            camera.CFrame = fixedCameraCFrame * CFrame.new(shake)
        else
            camera.CFrame = fixedCameraCFrame
        end
    end
end

RunService.RenderStepped:Connect(onRenderStep)
print("[CameraController] Caméra fixe Scriptable initialisée avec succès.")
