--!strict
--[[
    STOP AT THE FRAME - WORLD BUILDER (SERVER SCRIPT)
    Génère procéduralement la rue en pente raide style San Francisco,
    les immeubles pastel, et le cadre cible vert néon "TargetFrame" flottant au milieu de la pente.
]]

local Workspace = game:GetService("Workspace")

-- 1. Suppression de la Baseplate par défaut
for _, child in ipairs(Workspace:GetChildren()) do
    if child.Name == "Baseplate" and child:IsA("BasePart") then
        child:Destroy()
    end
end

local streetFolder = Instance.new("Folder")
streetFolder.Name = "SanFranciscoStreet"
streetFolder.Parent = Workspace

-- Paramètres géométriques de la pente raide (San Francisco)
-- Pente le long de l'axe Z (montée de Z = -40 à Z = 360, dénivelé Y = 0 à Y = 120)
local ROAD_START_Z = -40
local ROAD_END_Z = 360
local ROAD_START_Y = 0
local ROAD_END_Y = 120
local ROAD_WIDTH = 34
local SIDEWALK_WIDTH = 8

local slopeVector = Vector3.new(0, ROAD_END_Y - ROAD_START_Y, ROAD_END_Z - ROAD_START_Z)
local slopeLength = slopeVector.Magnitude
local uDir = slopeVector.Unit -- Vecteur unitaire qui monte la pente
local rightVec = Vector3.new(1, 0, 0) -- Vecteur transversal horizontal
local normalVec = uDir:Cross(rightVec) -- Vecteur normal perpendiculaire à la route vers le ciel

local midX = 0
local midY = (ROAD_START_Y + ROAD_END_Y) / 2
local midZ = (ROAD_START_Z + ROAD_END_Z) / 2
local roadCenterPos = Vector3.new(midX, midY, midZ)
local roadCFrame = CFrame.fromMatrix(roadCenterPos, rightVec, normalVec)

local function createPart(name: string, size: Vector3, cf: CFrame, material: Enum.Material, color: Color3, canCollide: boolean, parent: Instance): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cf
    part.Material = material
    part.Color = color
    part.Anchored = true
    part.CanCollide = canCollide
    part.Parent = parent
    return part
end

-- 2. Chaussée en asphalte gris foncé
local roadPart = createPart(
    "AsphaltRoad",
    Vector3.new(ROAD_WIDTH, 2, slopeLength + 20),
    roadCFrame,
    Enum.Material.Asphalt,
    Color3.fromRGB(36, 38, 42),
    true,
    streetFolder
)

-- 3. Double ligne jaune centrale
local lineLength = slopeLength + 20
local line1Pos = roadCenterPos + (rightVec * -0.6) + (normalVec * 1.05)
local line2Pos = roadCenterPos + (rightVec * 0.6) + (normalVec * 1.05)

createPart("YellowLine_Left", Vector3.new(0.4, 0.05, lineLength), CFrame.fromMatrix(line1Pos, rightVec, normalVec), Enum.Material.SmoothPlastic, Color3.fromRGB(255, 204, 0), false, streetFolder)
createPart("YellowLine_Right", Vector3.new(0.4, 0.05, lineLength), CFrame.fromMatrix(line2Pos, rightVec, normalVec), Enum.Material.SmoothPlastic, Color3.fromRGB(255, 204, 0), false, streetFolder)

-- 4. Trottoirs gauche et droite avec bordure surélevée
local leftSidewalkX = -(ROAD_WIDTH / 2 + SIDEWALK_WIDTH / 2)
local rightSidewalkX = (ROAD_WIDTH / 2 + SIDEWALK_WIDTH / 2)

local leftSidewalkPos = roadCenterPos + (rightVec * leftSidewalkX) + (normalVec * 0.5)
local rightSidewalkPos = roadCenterPos + (rightVec * rightSidewalkX) + (normalVec * 0.5)

createPart("Sidewalk_Left", Vector3.new(SIDEWALK_WIDTH, 2.5, lineLength), CFrame.fromMatrix(leftSidewalkPos, rightVec, normalVec), Enum.Material.Concrete, Color3.fromRGB(185, 188, 192), true, streetFolder)
createPart("Sidewalk_Right", Vector3.new(SIDEWALK_WIDTH, 2.5, lineLength), CFrame.fromMatrix(rightSidewalkPos, rightVec, normalVec), Enum.Material.Concrete, Color3.fromRGB(185, 188, 192), true, streetFolder)

-- Bordures de trottoir (Curbs)
local leftCurbPos = roadCenterPos + (rightVec * -(ROAD_WIDTH / 2 + 0.3)) + (normalVec * 0.6)
local rightCurbPos = roadCenterPos + (rightVec * (ROAD_WIDTH / 2 + 0.3)) + (normalVec * 0.6)
createPart("Curb_Left", Vector3.new(0.6, 2.7, lineLength), CFrame.fromMatrix(leftCurbPos, rightVec, normalVec), Enum.Material.Concrete, Color3.fromRGB(135, 138, 142), true, streetFolder)
createPart("Curb_Right", Vector3.new(0.6, 2.7, lineLength), CFrame.fromMatrix(rightCurbPos, rightVec, normalVec), Enum.Material.Concrete, Color3.fromRGB(135, 138, 142), true, streetFolder)

-- 5. Immeubles pastel style San Francisco avec fenêtres des deux côtés
local pastelColors = {
    Color3.fromRGB(168, 218, 185), -- Vert clair pastel
    Color3.fromRGB(245, 230, 205), -- Beige / Crème pastel
    Color3.fromRGB(165, 200, 235), -- Bleu ciel pastel
    Color3.fromRGB(245, 202, 188), -- Pêche pastel
    Color3.fromRGB(215, 202, 235), -- Lilas doux
}

local buildingFolder = Instance.new("Folder")
buildingFolder.Name = "PastelBuildings"
buildingFolder.Parent = streetFolder

local function buildTownhouse(xOffset: number, zPos: number, colorIndex: number, isLeftSide: boolean)
    local t = (zPos - ROAD_START_Z) / (ROAD_END_Z - ROAD_START_Z)
    local groundY = ROAD_START_Y + t * (ROAD_END_Y - ROAD_START_Y)

    local bWidth = 20
    local bDepth = 22
    local bHeight = 36 + ((zPos * 7) % 8)
    local buildingColor = pastelColors[((colorIndex - 1) % #pastelColors) + 1]

    local bCenterPos = Vector3.new(xOffset, groundY + (bHeight / 2) - 4, zPos)
    local bModel = Instance.new("Model")
    bModel.Name = "Townhouse_" .. math.floor(zPos)
    bModel.Parent = buildingFolder

    -- Corps principal de l'immeuble
    createPart("MainBody", Vector3.new(bWidth, bHeight, bDepth), CFrame.new(bCenterPos), Enum.Material.SmoothPlastic, buildingColor, true, bModel)

    -- Corniche de toit (Style victorien)
    createPart("Cornice", Vector3.new(bWidth + 1.2, 1.8, bDepth + 1.2), CFrame.new(bCenterPos + Vector3.new(0, bHeight / 2 + 0.9, 0)), Enum.Material.SmoothPlastic, Color3.fromRGB(250, 250, 252), true, bModel)

    -- Façade orientée vers la rue
    local facadeX = if isLeftSide then (bCenterPos.X + bWidth / 2 + 0.1) else (bCenterPos.X - bWidth / 2 - 0.1)

    -- Porte d'entrée
    local doorY = groundY + 3.5
    local doorZ = zPos - 5
    createPart("Door", Vector3.new(0.3, 7, 3.5), CFrame.new(facadeX, doorY, doorZ), Enum.Material.WoodPlanks, Color3.fromRGB(75, 50, 40), false, bModel)

    -- Fenêtres sur 3 étages (2 fenêtres par étage)
    for floor = 1, 3 do
        local windowY = groundY + 5 + (floor * 8)
        for _, zOffset in ipairs({ -3, 4 }) do
            local winZ = zPos + zOffset
            -- Cadre de fenêtre
            createPart("WindowFrame", Vector3.new(0.35, 4.6, 3.2), CFrame.new(facadeX, windowY, winZ), Enum.Material.SmoothPlastic, Color3.fromRGB(255, 255, 255), false, bModel)
            -- Vitre avec reflet lumineux
            createPart("WindowGlass", Vector3.new(0.4, 4.0, 2.6), CFrame.new(facadeX, windowY, winZ), Enum.Material.Neon, Color3.fromRGB(225, 242, 255), false, bModel)
        end
    end
end

-- Génération des rangées d'immeubles des deux côtés de la colline
local stepZ = 24
local colorIdx = 1
for z = ROAD_START_Z + 10, ROAD_END_Z - 10, stepZ do
    buildTownhouse(-35, z, colorIdx, true) -- Côté gauche
    buildTownhouse(35, z, colorIdx + 2, false) -- Côté droit
    colorIdx += 1
end

-- =============================================================================
-- 6. LE CADRE VERT CIBLE "TargetFrame" INITIALISÉ VIA CARBUILDER
-- =============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CarBuilder = require(ReplicatedStorage:WaitForChild("CarBuilder") :: ModuleScript)

-- Position du milieu de la pente sur la surface de la route
local midT = 0.5
local midSurfaceY = ROAD_START_Y + midT * (ROAD_END_Y - ROAD_START_Y) + 1.0
local midSurfacePos = Vector3.new(0, midSurfaceY, midZ)

-- La base de la silhouette de voiture flotte à 4 studs au-dessus de la route
local FRAME_FLOAT_HEIGHT = 4.0
local frameCenterPos = midSurfacePos + (normalVec * (FRAME_FLOAT_HEIGHT + 1.8))
local frameBaseCF = CFrame.fromMatrix(frameCenterPos, rightVec, normalVec)

CarBuilder.CreateTargetFrame("lotus_rally", frameCenterPos, frameBaseCF)

print("[WorldBuilder] Rue San Francisco en pente et TargetFrame initialisés avec succès.")
