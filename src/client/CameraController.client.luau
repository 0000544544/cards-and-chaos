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

-- Position fixe de la caméra : en bas de la pente, 55 studs en retrait du cadre,
-- élevée à 4.8 studs au-dessus du sol pour une perspective dynamique au ras de la route
local fixedCameraCFrame: CFrame? = nil

local function computeCameraCFrame(): CFrame
    if centerPoint then
        local targetPos = centerPoint.Position
        -- Recul de 52 studs vers le bas de la colline le long de la pente
        local roadBasePos = targetPos - (uDir * 52)
        -- Élévation au-dessus du sol
        local eyePos = roadBasePos + (normalVec * 0.8)
        -- Visée vers le centre du TargetFrame
        return CFrame.lookAt(eyePos, targetPos)
    else
        -- Coordonnées de secours si le point n'est pas encore instancié
        return CFrame.lookAt(Vector3.new(0, 48, 108), Vector3.new(0, 66, 160))
    end
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
