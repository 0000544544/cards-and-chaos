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
-- 6. LE CADRE VERT CIBLE "TargetFrame" (Flottant à 4 studs au milieu de la pente)
-- =============================================================================
local targetFrameModel = Instance.new("Model")
targetFrameModel.Name = "TargetFrame"
targetFrameModel.Parent = Workspace

-- Position du milieu de la pente sur la surface de la route
local midT = 0.5
local midSurfaceY = ROAD_START_Y + midT * (ROAD_END_Y - ROAD_START_Y) + 1.0
local midSurfacePos = Vector3.new(0, midSurfaceY, midZ)

-- La base de la silhouette de voiture flotte à 4 studs au-dessus de la route
local FRAME_FLOAT_HEIGHT = 4.0
local frameBasePos = midSurfacePos + (normalVec * FRAME_FLOAT_HEIGHT)

-- Dimensions de la silhouette de voiture de face
local BAR_THICKNESS = 0.22
local NEON_GREEN = Color3.fromRGB(0, 255, 80)

-- Segments 2D formant la silhouette de face d'une voiture (en coordonnées locales x, y)
-- x : largeur (-4 à +4 studs), y : hauteur (0 à 4.2 studs au-dessus du point de flottaison)
local carSilhouetteSegments: { { number } } = {
    -- 1. Pare-chocs inférieur (Base)
    { -3.6, 0.2, 3.6, 0.2 },
    -- 2. Contour des pneus / bas de caisse
    { -3.6, 0.2, -3.9, 0.9 },
    { 3.6, 0.2, 3.9, 0.9 },
    -- 3. Pare-chocs principal horizontal
    { -4.0, 0.9, 4.0, 0.9 },
    -- 4. Ailes et calandre inférieure
    { -4.0, 0.9, -3.9, 2.0 },
    { 4.0, 0.9, 3.9, 2.0 },
    -- 5. Ligne de capot (Ceinture de caisse)
    { -3.9, 2.0, 3.9, 2.0 },
    -- 6. Montants de pare-brise (Piliers A inclinés)
    { -3.4, 2.0, -2.3, 4.0 },
    { 3.4, 2.0, 2.3, 4.0 },
    -- 7. Toit horizontal
    { -2.3, 4.0, 2.3, 4.0 },
    -- 8. Rétroviseurs extérieurs
    { -3.5, 2.3, -4.3, 2.4 },
    { 3.5, 2.3, 4.3, 2.4 },
    -- 9. Phares avant (Accents horizontaux)
    { -3.5, 1.5, -2.4, 1.5 },
    { 2.4, 1.5, 3.5, 1.5 },
    -- 10. Calandre centrale
    { -1.4, 1.4, 1.4, 1.4 },
}

-- Tracé de chaque barre en Neon vert fluo
for i, seg in ipairs(carSilhouetteSegments) do
    local x1, y1, x2, y2 = seg[1], seg[2], seg[3], seg[4]
    local p1 = frameBasePos + (rightVec * x1) + (normalVec * y1)
    local p2 = frameBasePos + (rightVec * x2) + (normalVec * y2)

    local segVec = p2 - p1
    local segLen = segVec.Magnitude
    local segMid = (p1 + p2) / 2

    if segLen > 0.01 then
        local bar = Instance.new("Part")
        bar.Name = "Bar_" .. i
        bar.Size = Vector3.new(BAR_THICKNESS, BAR_THICKNESS, segLen)
        bar.CFrame = CFrame.lookAt(segMid, segMid + segVec.Unit)
        bar.Material = Enum.Material.Neon
        bar.Color = NEON_GREEN
        bar.Anchored = true
        bar.CanCollide = false
        bar.Parent = targetFrameModel
    end
end

-- Calcul du centre exact du cadre vert
local centerLocalY = 2.1
local frameCenterPos = frameBasePos + (normalVec * centerLocalY)

-- Repère invisible "CenterPoint" avec PointLight au centre du cadre vert
local centerPoint = Instance.new("Part")
centerPoint.Name = "CenterPoint"
centerPoint.Size = Vector3.new(1, 1, 1)
centerPoint.CFrame = CFrame.new(frameCenterPos)
centerPoint.Transparency = 1
centerPoint.Anchored = true
centerPoint.CanCollide = false
centerPoint.Parent = targetFrameModel

local pointLight = Instance.new("PointLight")
pointLight.Name = "FrameLight"
pointLight.Color = NEON_GREEN
pointLight.Brightness = 3.5
pointLight.Range = 26
pointLight.Parent = centerPoint

targetFrameModel.PrimaryPart = centerPoint

print("[WorldBuilder] Rue San Francisco en pente et TargetFrame créés avec succès.")
