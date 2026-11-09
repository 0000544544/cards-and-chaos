--!strict
--[[
    STOP AT THE FRAME - MULTI-MODE CAMERA CONTROLLER (CLIENT SCRIPT)
    Gère la caméra selon le mode de jeu actuel :
    - "Hub" (Quai / Port) : Caméra libre à la 3e personne (Custom) sur l'avatar du joueur.
    - "StopTheFrame" (Pari 1v1) : Caméra fixe Scriptable en contre-plongée vers le cadre vert.
    - "Crane" (Mode Pêche) : Caméra aérienne Scriptable surplombant la grue et le bassin aquatique.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera") :: Camera

-- Mode par défaut : Hub (Marche libre sur le quai)
if not player:GetAttribute("CurrentMode") then
    player:SetAttribute("CurrentMode", "Hub")
end

-- Paramètres géométriques de la pente San Francisco
local slopeVector = Vector3.new(0, 120, 400)
local uDir = slopeVector.Unit
local rightVec = Vector3.new(1, 0, 0)
local normalVec = uDir:Cross(rightVec)

-- Calcul de la CFrame de caméra fixe pour le mode "StopTheFrame"
local fixedSlopeCameraCFrame: CFrame? = nil

local function computeSlopeCameraCFrame(): CFrame
    local currentTarget = Workspace:FindFirstChild("TargetFrame")
    local cp = currentTarget and currentTarget:FindFirstChild("CenterPoint") :: BasePart?
    local targetPos = (cp and cp.Position) or Vector3.new(0, 66.84, 158.22)

    local roadBasePos = targetPos - (uDir * 20)
    local eyePos = roadBasePos - (normalVec * 0.4)
    local lookTarget = targetPos + (normalVec * 0.3)

    return CFrame.lookAt(eyePos, lookTarget)
end

-- CFrame de la caméra pour le Mode Pêche (vue haute derrière la grue)
local craneCameraCFrame = CFrame.lookAt(Vector3.new(0, 38, -78), Vector3.new(0, 6, -125))

-- Gestion des contrôles du joueur
local playerControls: any = nil
local function setupPlayerControls()
    local playerScripts = player:WaitForChild("PlayerScripts")
    local playerModule = playerScripts:WaitForChild("PlayerModule", 5)
    if playerModule then
        local success, controls = pcall(function()
            local module = require(playerModule) :: any
            return module:GetControls()
        end)
        if success and controls then
            playerControls = controls
        end
    end
end
task.spawn(setupPlayerControls)

local function setPlayerControlsEnabled(enabled: boolean)
    if playerControls then
        if enabled and playerControls.Enable then
            playerControls:Enable()
        elseif not enabled and playerControls.Disable then
            playerControls:Disable()
        end
    end
end

-- Mise à jour du mode de caméra
local function onModeChanged()
    local mode = tostring(player:GetAttribute("CurrentMode") or "Hub")

    if mode == "Hub" then
        camera.CameraType = Enum.CameraType.Custom
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                camera.CameraSubject = hum
            end
        end
        setPlayerControlsEnabled(true)
        print("[CameraController] Mode Hub actif (Caméra libre 3e personne).")

    elseif mode == "StopTheFrame" then
        camera.CameraType = Enum.CameraType.Scriptable
        fixedSlopeCameraCFrame = computeSlopeCameraCFrame()
        setPlayerControlsEnabled(false)
        print("[CameraController] Mode StopTheFrame actif (Caméra fixe sur la pente).")

    elseif mode == "Crane" then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = craneCameraCFrame
        setPlayerControlsEnabled(false)
        print("[CameraController] Mode Pêche / Grue actif (Caméra aérienne bassin).")
    end
end

player:GetAttributeChangedSignal("CurrentMode"):Connect(onModeChanged)
task.spawn(onModeChanged)

-- Maintien de la caméra Scriptable pendant les modes actifs
local function onRenderStep()
    local mode = tostring(player:GetAttribute("CurrentMode") or "Hub")

    if mode == "StopTheFrame" then
        camera.CameraType = Enum.CameraType.Scriptable
        if not fixedSlopeCameraCFrame then
            fixedSlopeCameraCFrame = computeSlopeCameraCFrame()
        end
        if fixedSlopeCameraCFrame then
            local shake = camera:GetAttribute("ShakeOffset")
            if shake and typeof(shake) == "Vector3" then
                camera.CFrame = fixedSlopeCameraCFrame * CFrame.new(shake)
            else
                camera.CFrame = fixedSlopeCameraCFrame
            end
        end

    elseif mode == "Crane" then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = craneCameraCFrame
    end
end

RunService.RenderStepped:Connect(onRenderStep)
print("[CameraController] Multi-mode Camera Controller initialisé avec succès.")
