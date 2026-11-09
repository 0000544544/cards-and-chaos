--!strict
--[[
    STOP AT THE FRAME - WORLD BUILDER (SERVER SCRIPT)
    Génère procéduralement la rue en pente raide style San Francisco,
    les immeubles pastel, le cadre cible vert néon "TargetFrame",
    et le Hub Portuaire Simulator chaleureux (Quai en bois, Grue 3D, Podiums Showroom, Spots sous-marins).
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
            createPart("WindowFrame", Vector3.new(0.35, 4.6, 3.2), CFrame.new(facadeX, windowY, winZ), Enum.Material.SmoothPlastic, Color3.fromRGB(255, 255, 255), false, bModel)
            createPart("WindowGlass", Vector3.new(0.4, 4.0, 2.6), CFrame.new(facadeX, windowY, winZ), Enum.Material.Neon, Color3.fromRGB(225, 242, 255), false, bModel)
        end
    end
end

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
local CarBuilder = require(ReplicatedStorage:WaitForChild("CarBuilder") :: ModuleScript)

local midT = 0.5
local midSurfaceY = ROAD_START_Y + midT * (ROAD_END_Y - ROAD_START_Y) + 1.0
local midSurfacePos = Vector3.new(0, midSurfaceY, midZ)

local FRAME_FLOAT_HEIGHT = 4.0
local frameCenterPos = midSurfacePos + (normalVec * (FRAME_FLOAT_HEIGHT + 1.8))
local frameBaseCF = CFrame.fromMatrix(frameCenterPos, rightVec, normalVec)

CarBuilder.CreateTargetFrame("lotus_rally", frameCenterPos)

print("[WorldBuilder] Rue San Francisco en pente et TargetFrame initialisés avec succès.")

-- =============================================================================
-- 7. LE HUB SIMULATOR CHALEUREUX : QUAI EN BOIS, ZONES NÉON & SPOTS SOUS-MARINS
-- =============================================================================
local docksFolder = Instance.new("Folder")
docksFolder.Name = "SanFranciscoDocks"
docksFolder.Parent = Workspace

-- A. Grand Ponton en Bois Clair Chaleureux
local dockFloor = createPart(
    "DockPlaza",
    Vector3.new(140, 4, 105),
    CFrame.new(0, -1, -90),
    Enum.Material.WoodPlanks,
    Color3.fromRGB(195, 150, 105), -- Bois clair chaleureux
    true,
    docksFolder
)

-- Promenade en bois traité le long de la ligne d'eau
local woodBoardwalk = createPart(
    "WoodBoardwalk",
    Vector3.new(140, 0.5, 18),
    CFrame.new(0, 1.25, -133),
    Enum.Material.WoodPlanks,
    Color3.fromRGB(165, 120, 80),
    true,
    docksFolder
)

-- Bordure de quai en poutres massives d'amarrage
local dockEdgeBeam = createPart(
    "DockEdgeBeam",
    Vector3.new(140, 1.6, 2.5),
    CFrame.new(0, 1.8, -141),
    Enum.Material.WoodPlanks,
    Color3.fromRGB(110, 75, 45),
    true,
    docksFolder
)

-- Barrières portuaires de sécurité en bois le long des côtés
local function buildRailing(startPos: Vector3, endPos: Vector3)
    local length = (endPos - startPos).Magnitude
    local cf = CFrame.lookAt((startPos + endPos) / 2, endPos)
    -- Lisse supérieure
    createPart("Rail_Top", Vector3.new(0.6, 0.4, length), cf * CFrame.new(0, 3.2, 0), Enum.Material.WoodPlanks, Color3.fromRGB(120, 80, 50), true, docksFolder)
    -- Lisse médiane
    createPart("Rail_Mid", Vector3.new(0.4, 0.3, length), cf * CFrame.new(0, 1.8, 0), Enum.Material.WoodPlanks, Color3.fromRGB(120, 80, 50), true, docksFolder)
    -- Poteaux verticaux réguliers
    for dist = 0, length, 8 do
        local postPos = startPos:Lerp(endPos, dist / length) + Vector3.new(0, 1.7, 0)
        createPart("Rail_Post", Vector3.new(0.8, 3.4, 0.8), CFrame.new(postPos), Enum.Material.WoodPlanks, Color3.fromRGB(90, 60, 38), true, docksFolder)
    end
end

buildRailing(Vector3.new(-68, 1, -40), Vector3.new(-68, 1, -140))
buildRailing(Vector3.new(68, 1, -40), Vector3.new(68, 1, -140))

-- Lampadaires portuaires chaleureux avec globes lumineux
local function buildStreetlamp(pos: Vector3)
    local post = createPart("LampPost", Vector3.new(1.2, 12, 1.2), CFrame.new(pos + Vector3.new(0, 6, 0)), Enum.Material.Metal, Color3.fromRGB(45, 50, 55), true, docksFolder)
    local lantern = createPart("LampLantern", Vector3.new(2.4, 2.8, 2.4), CFrame.new(pos + Vector3.new(0, 13, 0)), Enum.Material.Neon, Color3.fromRGB(255, 235, 160), false, docksFolder)
    local light = Instance.new("PointLight")
    light.Name = "LampLight"
    light.Color = Color3.fromRGB(255, 225, 140)
    light.Brightness = 2.5
    light.Range = 28
    light.Parent = lantern
end

buildStreetlamp(Vector3.new(-60, 1, -55))
buildStreetlamp(Vector3.new(-60, 1, -115))
buildStreetlamp(Vector3.new(60, 1, -55))
buildStreetlamp(Vector3.new(60, 1, -115))
buildStreetlamp(Vector3.new(-25, 1, -136))
buildStreetlamp(Vector3.new(25, 1, -136))

-- Palmiers décoratifs style Simulator
local function buildPalmTree(pos: Vector3)
    local trunk = Instance.new("Part")
    trunk.Name = "PalmTrunk"
    trunk.Shape = Enum.PartType.Cylinder
    trunk.Size = Vector3.new(14, 2.2, 2.2)
    trunk.CFrame = CFrame.new(pos + Vector3.new(0, 7, 0)) * CFrame.Angles(0, 0, math.rad(84))
    trunk.Material = Enum.Material.Wood
    trunk.Color = Color3.fromRGB(120, 85, 55)
    trunk.Anchored = true
    trunk.CanCollide = false
    trunk.Parent = docksFolder

    local leafCenter = pos + Vector3.new(1.5, 14.5, 0)
    for angle = 0, 300, 60 do
        local leaf = Instance.new("Part")
        leaf.Name = "PalmLeaf"
        leaf.Size = Vector3.new(3, 0.4, 9)
        leaf.CFrame = CFrame.new(leafCenter) * CFrame.Angles(math.rad(-20), math.rad(angle), 0) * CFrame.new(0, 0, 4.2)
        leaf.Material = Enum.Material.Grass
        leaf.Color = Color3.fromRGB(45, 180, 65)
        leaf.Anchored = true
        leaf.CanCollide = false
        leaf.Parent = docksFolder
    end
end

buildPalmTree(Vector3.new(-62, 1, -45))
buildPalmTree(Vector3.new(62, 1, -45))
buildPalmTree(Vector3.new(-62, 1, -130))
buildPalmTree(Vector3.new(62, 1, -130))

-- Caisses de bois décoratives
local function buildCrate(pos: Vector3, size: Vector3, rotY: number)
    createPart("DockCrate", size, CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0), Enum.Material.WoodPlanks, Color3.fromRGB(170, 125, 80), true, docksFolder)
end

buildCrate(Vector3.new(-54, 2.5, -60), Vector3.new(3.5, 3.5, 3.5), 15)
buildCrate(Vector3.new(-51, 2.5, -62), Vector3.new(3, 3, 3), -10)
buildCrate(Vector3.new(-53, 5.8, -61), Vector3.new(2.8, 2.8, 2.8), 5)
buildCrate(Vector3.new(53, 2.5, -60), Vector3.new(3.5, 3.5, 3.5), -20)
buildCrate(Vector3.new(55, 2.5, -64), Vector3.new(3, 3, 3), 12)

-- Conteneurs maritimes stylisés sur les côtés du port
local containerColors = {
    Color3.fromRGB(225, 50, 40),  -- Rouge écarlate
    Color3.fromRGB(35, 125, 215), -- Bleu cyan vif
    Color3.fromRGB(245, 175, 25), -- Jaune doré
    Color3.fromRGB(40, 165, 75),  -- Vert émeraude
}

local function buildCargoContainer(name: string, pos: Vector3, rotY: number, colorIdx: number)
    local cont = createPart(
        name,
        Vector3.new(9, 9, 22),
        CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0),
        Enum.Material.CorrugatedMetal,
        containerColors[colorIdx],
        true,
        docksFolder
    )
    createPart(name .. "_Doors", Vector3.new(8.2, 8.2, 0.4), cont.CFrame * CFrame.new(0, 0, 11.1), Enum.Material.Metal, Color3.fromRGB(30, 32, 35), false, docksFolder)
end

buildCargoContainer("Container_L1", Vector3.new(-52, 5.5, -80), 12, 1)
buildCargoContainer("Container_L2", Vector3.new(-53, 14.5, -80), 8, 2)
buildCargoContainer("Container_R1", Vector3.new(52, 5.5, -80), -10, 4)
buildCargoContainer("Container_R2", Vector3.new(51, 14.5, -80), -12, 1)

-- Point d'apparition principal (Spawn) au centre du Quai Maritime
local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Name = "DockSpawnPoint"
spawnLocation.Size = Vector3.new(12, 0.5, 12)
spawnLocation.CFrame = CFrame.new(0, 1.25, -75)
spawnLocation.Material = Enum.Material.WoodPlanks
spawnLocation.Color = Color3.fromRGB(210, 165, 115)
spawnLocation.Anchored = true
spawnLocation.CanCollide = true
spawnLocation.Neutral = true
spawnLocation.Parent = docksFolder

-- B. Le Grand Bassin Aquatique & Fonds Marins
local waterBasin = createPart(
    "WaterSurface",
    Vector3.new(180, 1, 150),
    CFrame.new(0, -0.2, -215),
    Enum.Material.Glass,
    Color3.fromRGB(25, 150, 215),
    false,
    docksFolder
)
waterBasin.Transparency = 0.40
waterBasin.Reflectance = 0.35

-- Fond marin sableux sous-marin
local seaBed = createPart(
    "SeaBed",
    Vector3.new(180, 6, 150),
    CFrame.new(0, -38, -215),
    Enum.Material.Sand,
    Color3.fromRGB(35, 45, 52),
    true,
    docksFolder
)

-- Épave sous-marine visible sous l'eau transparente
local wreckRally = CarBuilder.CreateLotusRally()
wreckRally.Name = "SunkenWreck_Lotus"
wreckRally.Parent = docksFolder
wreckRally:PivotTo(CFrame.new(0, -34, -165) * CFrame.Angles(math.rad(15), math.rad(45), math.rad(-10)))
for _, p in ipairs(wreckRally:GetDescendants()) do
    if p:IsA("BasePart") then
        p.Material = Enum.Material.CorrodedMetal
        p.Color = Color3.fromRGB(90, 60, 45)
        p.Anchored = true
        p.CanCollide = false
    end
end

-- Bulles d'eau (CORRECTION DU BUG NumberSequence.new)
local bubbleEmitter = Instance.new("ParticleEmitter")
bubbleEmitter.Name = "UnderwaterBubbles"
bubbleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
bubbleEmitter.Color = ColorSequence.new(Color3.fromRGB(180, 240, 255))
bubbleEmitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1.4) })
bubbleEmitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.7) })
bubbleEmitter.Rate = 12
bubbleEmitter.Speed = NumberRange.new(4, 9)
bubbleEmitter.SpreadAngle = Vector2.new(15, 15)
local bubbleAnchor = Instance.new("Part")
bubbleAnchor.Name = "BubbleAnchor"
bubbleAnchor.Size = Vector3.new(1, 1, 1)
bubbleAnchor.CFrame = CFrame.new(0, -32, -165)
bubbleAnchor.Transparency = 1
bubbleAnchor.Anchored = true
bubbleAnchor.CanCollide = false
bubbleAnchor.Parent = docksFolder
bubbleEmitter.Parent = bubbleAnchor

-- =============================================================================
-- C. LES 6 SPOTS SOUS-MARINS VISIBLES AVEC COLONNES DE LUMIÈRE NÉON
-- =============================================================================
local underwaterSpotsFolder = Instance.new("Folder")
underwaterSpotsFolder.Name = "UnderwaterSpots"
underwaterSpotsFolder.Parent = docksFolder

local SPOT_DEFS = {
    { Pos = Vector3.new(-42, -37, -158), Color = Color3.fromRGB(40, 230, 90),   Rarity = "Commune",    Label = "🟢 Lotus Rally" },
    { Pos = Vector3.new(38, -37, -162),  Color = Color3.fromRGB(0, 220, 255),   Rarity = "Peu Commune",Label = "🔷 Cyber Truck" },
    { Pos = Vector3.new(-22, -37, -182), Color = Color3.fromRGB(30, 120, 255),  Rarity = "Rare",       Label = "🔵 Drift Supra" },
    { Pos = Vector3.new(26, -37, -192),  Color = Color3.fromRGB(175, 45, 255),  Rarity = "Épique",     Label = "🟣 Police Interceptor" },
    { Pos = Vector3.new(-34, -37, -215), Color = Color3.fromRGB(255, 130, 20),  Rarity = "Légendaire", Label = "🟠 Hyperion JetCar" },
    { Pos = Vector3.new(12, -37, -208),  Color = Color3.fromRGB(255, 215, 0),   Rarity = "Mythique",   Label = "⭐ Flash McQueen ⚡" },
}

for i, spot in ipairs(SPOT_DEFS) do
    local spotModel = Instance.new("Model")
    spotModel.Name = "UnderwaterSpot_" .. i
    spotModel.Parent = underwaterSpotsFolder

    -- Socle néon circulaire au fond marin
    local baseDisc = Instance.new("Part")
    baseDisc.Name = "BaseGlow"
    baseDisc.Shape = Enum.PartType.Cylinder
    baseDisc.Size = Vector3.new(0.8, 12, 12)
    baseDisc.CFrame = CFrame.new(spot.Pos) * CFrame.Angles(0, 0, math.rad(90))
    baseDisc.Material = Enum.Material.Neon
    baseDisc.Color = spot.Color
    baseDisc.Anchored = true
    baseDisc.CanCollide = false
    baseDisc.Parent = spotModel

    -- Colonne de faisceau lumineux vertical montant du fond marin à la surface
    local beamHeight = 36
    local lightBeam = Instance.new("Part")
    lightBeam.Name = "LightColumn"
    lightBeam.Shape = Enum.PartType.Cylinder
    lightBeam.Size = Vector3.new(beamHeight, 8, 8)
    lightBeam.CFrame = CFrame.new(spot.Pos.X, spot.Pos.Y + (beamHeight / 2), spot.Pos.Z) * CFrame.Angles(0, 0, math.rad(90))
    lightBeam.Material = Enum.Material.Neon
    lightBeam.Color = spot.Color
    lightBeam.Transparency = 0.76
    lightBeam.Anchored = true
    lightBeam.CanCollide = false
    lightBeam.Parent = spotModel

    -- Anneau de surface flottant visible depuis le quai
    local surfaceRing = Instance.new("Part")
    surfaceRing.Name = "SurfaceRing"
    surfaceRing.Shape = Enum.PartType.Cylinder
    surfaceRing.Size = Vector3.new(0.3, 10, 10)
    surfaceRing.CFrame = CFrame.new(spot.Pos.X, 0.2, spot.Pos.Z) * CFrame.Angles(0, 0, math.rad(90))
    surfaceRing.Material = Enum.Material.Neon
    surfaceRing.Color = spot.Color
    surfaceRing.Transparency = 0.45
    surfaceRing.Anchored = true
    surfaceRing.CanCollide = false
    surfaceRing.Parent = spotModel

    -- Lumière sous-marine
    local pLight = Instance.new("PointLight")
    pLight.Color = spot.Color
    pLight.Brightness = 3.0
    pLight.Range = 28
    pLight.Parent = surfaceRing
end

-- =============================================================================
-- D. FONCTION UTILITAIRE : CRÉATION DES ZONES NÉON SIMULATOR AVEC BILLBOARDGUI
-- =============================================================================
local zonesFolder = Instance.new("Folder")
zonesFolder.Name = "SimulatorInteractiveZones"
zonesFolder.Parent = docksFolder

local function createNeonZonePad(name: string, pos: Vector3, radius: number, padColor: Color3, titleText: string, subtitleText: string): Part
    local pad = Instance.new("Part")
    pad.Name = name .. "_Pad"
    pad.Shape = Enum.PartType.Cylinder
    pad.Size = Vector3.new(0.4, radius * 2, radius * 2)
    pad.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
    pad.Material = Enum.Material.Neon
    pad.Color = padColor
    pad.Transparency = 0.25
    pad.Anchored = true
    pad.CanCollide = false
    pad.Parent = zonesFolder

    -- Anneau extérieur d'accent
    local outerRing = Instance.new("Part")
    outerRing.Name = name .. "_Ring"
    outerRing.Shape = Enum.PartType.Cylinder
    outerRing.Size = Vector3.new(0.3, (radius + 1.6) * 2, (radius + 1.6) * 2)
    outerRing.CFrame = CFrame.new(pos - Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
    outerRing.Material = Enum.Material.SmoothPlastic
    outerRing.Color = Color3.fromRGB(25, 28, 35)
    outerRing.Anchored = true
    outerRing.CanCollide = false
    outerRing.Parent = zonesFolder

    -- Grand BillboardGui flottant dans l'air
    local bb = Instance.new("BillboardGui")
    bb.Name = name .. "_Billboard"
    bb.Size = UDim2.new(0, 320, 0, 85)
    bb.StudsOffset = Vector3.new(0, 8.5, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 160
    bb.Parent = pad

    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.new(1, 0, 1, 0)
    card.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
    card.BorderSizePixel = 0
    card.Parent = bb

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = padColor
    stroke.Thickness = 3.5
    stroke.Parent = card

    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 90
    gradient.Color = ColorSequence.new(Color3.fromRGB(35, 40, 52), Color3.fromRGB(12, 14, 18))
    gradient.Parent = card

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Name = "Title"
    titleLbl.Size = UDim2.new(1, -20, 0, 42)
    titleLbl.Position = UDim2.new(0, 10, 0, 8)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.FredokaOne
    titleLbl.TextSize = 21
    titleLbl.TextColor3 = padColor
    titleLbl.TextStrokeColor3 = Color3.fromRGB(10, 12, 16)
    titleLbl.TextStrokeTransparency = 0
    titleLbl.Text = titleText
    titleLbl.Parent = card

    local subLbl = Instance.new("TextLabel")
    subLbl.Name = "Subtitle"
    subLbl.Size = UDim2.new(1, -20, 0, 24)
    subLbl.Position = UDim2.new(0, 10, 0, 50)
    subLbl.BackgroundTransparency = 1
    subLbl.Font = Enum.Font.GothamBold
    subLbl.TextSize = 13
    subLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
    subLbl.TextStrokeColor3 = Color3.fromRGB(10, 12, 16)
    subLbl.TextStrokeTransparency = 0.3
    subLbl.Text = subtitleText
    subLbl.Parent = card

    return pad
end

-- 1. Zone Cyan : "🎣 PILOTER LA GRUE [E]"
createNeonZonePad("CraneZone", Vector3.new(0, 1.25, -125), 6.5, Color3.fromRGB(0, 240, 255), "🎣 PILOTER LA GRUE [E]", "PÊCHE D'ÉPAVES 3D & LOOT MYTHIQUE")

-- 2. Zone Verte : "🏎️ GARAGE SHOWROOM ($/sec)"
createNeonZonePad("GarageZone", Vector3.new(-38, 1.25, -85), 18, Color3.fromRGB(40, 230, 90), "🏎️ GARAGE SHOWROOM ($/sec)", "REVENU PASSIF AUTOMATIQUE")

-- 3. Zone Or/Rouge : "⚡ STOP THE FRAME [E]"
createNeonZonePad("RaceZone", Vector3.new(0, 1.25, -42), 8.5, Color3.fromRGB(255, 205, 30), "⚡ STOP THE FRAME [E]", "DÉFI DE PRÉCISION 1v1 EN PENTE")

-- Damier de départ de course au sol devant l'arche
local checkerZStart = -48
local checkerZEnd = -38
local tileIdx = 0
for z = checkerZStart, checkerZEnd, 2.5 do
    for x = -14, 14, 2.5 do
        local isWhite = (tileIdx % 2 == 0)
        local tile = createPart(
            "CheckeredTile",
            Vector3.new(2.4, 0.1, 2.4),
            CFrame.new(x, 1.25, z),
            Enum.Material.SmoothPlastic,
            isWhite and Color3.fromRGB(245, 245, 250) or Color3.fromRGB(25, 28, 32),
            true,
            zonesFolder
        )
        tileIdx += 1
    end
    tileIdx += 1
end

-- =============================================================================
-- E. SHOWROOM GARAGE : LES 6 PODIUMS AVEC VOITURES 3D EXPOSÉES PHYSIQUEMENT
-- =============================================================================
local showroomFolder = Instance.new("Folder")
showroomFolder.Name = "ShowroomPodiums"
showroomFolder.Parent = docksFolder

local PODIUM_CONFIGS = {
    { Pos = Vector3.new(-52, 2.0, -74),  VehId = "lotus_rally",        Rate = "$2/s",   Color = Color3.fromRGB(40, 230, 90),   Rarity = "COMMUNE" },
    { Pos = Vector3.new(-38, 2.0, -74),  VehId = "cyber_truck",        Rate = "$5/s",   Color = Color3.fromRGB(0, 220, 255),   Rarity = "PEU COMMUNE" },
    { Pos = Vector3.new(-24, 2.0, -74),  VehId = "drift_supra",        Rate = "$12/s",  Color = Color3.fromRGB(30, 120, 255),  Rarity = "RARE" },
    { Pos = Vector3.new(-52, 2.0, -96),  VehId = "police_interceptor", Rate = "$25/s",  Color = Color3.fromRGB(175, 45, 255),  Rarity = "ÉPIQUE" },
    { Pos = Vector3.new(-38, 2.0, -96),  VehId = "hyperion_jetcar",    Rate = "$60/s",  Color = Color3.fromRGB(255, 130, 20),  Rarity = "LÉGENDAIRE" },
    { Pos = Vector3.new(-24, 2.0, -96),  VehId = "flash_mcqueen",      Rate = "$150/s", Color = Color3.fromRGB(255, 215, 0),   Rarity = "MYTHIQUE" },
}

for i, pcfg in ipairs(PODIUM_CONFIGS) do
    local pModel = Instance.new("Model")
    pModel.Name = "Podium_" .. pcfg.VehId
    pModel.Parent = showroomFolder

    -- Socle cylindrique surélevé
    local stand = Instance.new("Part")
    stand.Name = "PodiumStand"
    stand.Shape = Enum.PartType.Cylinder
    stand.Size = Vector3.new(1.8, 12, 12)
    stand.CFrame = CFrame.new(pcfg.Pos) * CFrame.Angles(0, 0, math.rad(90))
    stand.Material = Enum.Material.Metal
    stand.Color = Color3.fromRGB(32, 35, 42)
    stand.Anchored = true
    stand.CanCollide = true
    stand.Parent = pModel

    -- Anneau néon brillant de rareté
    local glowRing = Instance.new("Part")
    glowRing.Name = "GlowRing"
    glowRing.Shape = Enum.PartType.Cylinder
    glowRing.Size = Vector3.new(0.3, 12.6, 12.6)
    glowRing.CFrame = CFrame.new(pcfg.Pos + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, 0, math.rad(90))
    glowRing.Material = Enum.Material.Neon
    glowRing.Color = pcfg.Color
    glowRing.Anchored = true
    glowRing.CanCollide = false
    glowRing.Parent = pModel

    -- Instanciation de la vraie voiture 3D posée fièrement sur le podium
    local carModel: Model? = nil
    pcall(function()
        local vcfg = CarBuilder.GetVehicleConfig(pcfg.VehId)
        carModel = vcfg.Builder()
        if carModel then
            carModel.Name = "ExhibitionCar_" .. pcfg.VehId
            carModel.Parent = pModel
            carModel:PivotTo(CFrame.new(pcfg.Pos + Vector3.new(0, 1.9, 0)) * CFrame.Angles(0, math.rad(180), 0))
            for _, bp in ipairs(carModel:GetDescendants()) do
                if bp:IsA("BasePart") then
                    bp.Anchored = true
                    bp.CanCollide = false
                end
            end
        end
    end)

    -- Étiquette flottante de stats du véhicule
    local statBb = Instance.new("BillboardGui")
    statBb.Name = "VehicleTag"
    statBb.Size = UDim2.new(0, 200, 0, 52)
    statBb.StudsOffset = Vector3.new(0, 5.2, 0)
    statBb.AlwaysOnTop = true
    statBb.MaxDistance = 90
    statBb.Parent = stand

    local tagFrame = Instance.new("Frame")
    tagFrame.Size = UDim2.new(1, 0, 1, 0)
    tagFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
    tagFrame.BorderSizePixel = 0
    tagFrame.Parent = statBb

    local tagCorner = Instance.new("UICorner")
    tagCorner.CornerRadius = UDim.new(0, 10)
    tagCorner.Parent = tagFrame

    local tagStroke = Instance.new("UIStroke")
    tagStroke.Color = pcfg.Color
    tagStroke.Thickness = 2
    tagStroke.Parent = tagFrame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 24)
    nameLabel.Position = UDim2.new(0, 5, 0, 3)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.FredokaOne
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = pcfg.Color
    nameLabel.Text = pcfg.Rarity .. " • " .. pcfg.Rate
    nameLabel.Parent = tagFrame

    local idLabel = Instance.new("TextLabel")
    idLabel.Size = UDim2.new(1, -10, 0, 20)
    idLabel.Position = UDim2.new(0, 5, 0, 26)
    idLabel.BackgroundTransparency = 1
    idLabel.Font = Enum.Font.GothamBlack
    idLabel.TextSize = 12
    idLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
    idLabel.Text = CarBuilder.GetVehicleConfig(pcfg.VehId).Name
    idLabel.Parent = tagFrame
end

-- =============================================================================
-- F. LA GRANDE GRUE INDUSTRIELLE JAUNE (MODE PÊCHE)
-- =============================================================================
local craneModel = Instance.new("Model")
craneModel.Name = "IndustrialFishingCrane"
craneModel.Parent = docksFolder

local CRANE_YELLOW = Color3.fromRGB(240, 185, 20)
local CRANE_DARK   = Color3.fromRGB(28, 30, 35)
local CRANE_NEON   = Color3.fromRGB(0, 255, 200)

-- Socle lourd cylindrique
local craneBase = Instance.new("Part")
craneBase.Name = "CraneBase"
craneBase.Shape = Enum.PartType.Cylinder
craneBase.Size = Vector3.new(3, 14, 14)
craneBase.CFrame = CFrame.new(0, 2.5, -135) * CFrame.Angles(0, 0, math.rad(90))
craneBase.Material = Enum.Material.Metal
craneBase.Color = CRANE_DARK
craneBase.Anchored = true
craneBase.CanCollide = true
craneBase.Parent = craneModel

-- Mât vertical en treillis jaune
local craneMast = createPart("CraneMast", Vector3.new(5, 30, 5), CFrame.new(0, 17, -135), Enum.Material.DiamondPlate, CRANE_YELLOW, true, craneModel)

-- Cabine d'opérateur vitrée avec gyrophare orange
local craneCabin = createPart("CraneCabin", Vector3.new(7, 6, 8), CFrame.new(4.5, 25, -135), Enum.Material.SmoothPlastic, CRANE_DARK, true, craneModel)
local cabinGlass = createPart("CabinGlass", Vector3.new(0.3, 4.5, 6.5), craneCabin.CFrame * CFrame.new(3.5, 0.2, 0), Enum.Material.Glass, Color3.fromRGB(180, 225, 255), false, craneModel)
cabinGlass.Transparency = 0.3

local beaconLight = createPart("CraneBeacon", Vector3.new(1.2, 1.2, 1.2), craneCabin.CFrame * CFrame.new(0, 3.6, 0), Enum.Material.Neon, Color3.fromRGB(255, 140, 0), false, craneModel)

-- Flèche horizontale (Boom) surplombant le bassin aquatique
local craneBoom = createPart("CraneBoom", Vector3.new(4.5, 4.5, 50), CFrame.new(0, 32, -160), Enum.Material.DiamondPlate, CRANE_YELLOW, true, craneModel)

-- Câble métallique et Tête d'électro-aimant suspendue
local winchCable = createPart("WinchCable", Vector3.new(0.35, 24, 0.35), CFrame.new(0, 18, -165), Enum.Material.Metal, CRANE_DARK, false, craneModel)

local craneMagnet = Instance.new("Part")
craneMagnet.Name = "CraneMagnet"
craneMagnet.Shape = Enum.PartType.Cylinder
craneMagnet.Size = Vector3.new(2.5, 8, 8)
craneMagnet.CFrame = CFrame.new(0, 5.5, -165) * CFrame.Angles(0, 0, math.rad(90))
craneMagnet.Material = Enum.Material.Metal
craneMagnet.Color = CRANE_DARK
craneMagnet.Anchored = true
craneMagnet.CanCollide = true
craneMagnet.Parent = craneModel

-- Anneau néon électromagnétique lumineux sous l'aimant
local magnetRing = createPart("MagnetNeonRing", Vector3.new(7.2, 0.4, 7.2), craneMagnet.CFrame * CFrame.new(-1.1, 0, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Neon, CRANE_NEON, false, craneModel)

local magnetLight = Instance.new("PointLight")
magnetLight.Name = "MagnetLight"
magnetLight.Color = CRANE_NEON
magnetLight.Brightness = 3.5
magnetLight.Range = 25
magnetLight.Parent = craneMagnet

-- Pupitre de commande au sol avec ProximityPrompt pour piloter la Grue
local craneConsole = createPart("CraneControlConsole", Vector3.new(3, 3.5, 2), CFrame.new(0, 2.75, -126), Enum.Material.Metal, CRANE_DARK, true, craneModel)
local consoleScreen = createPart("ConsoleScreen", Vector3.new(2.2, 1.4, 0.2), craneConsole.CFrame * CFrame.new(0, 0.6, 1.0), Enum.Material.Neon, Color3.fromRGB(0, 230, 255), false, craneModel)

local cranePrompt = Instance.new("ProximityPrompt")
cranePrompt.Name = "CraneControlPrompt"
cranePrompt.ActionText = "Contrôler la Grue"
cranePrompt.ObjectText = "Mode Pêche Sous-Marine 🎣"
cranePrompt.KeyboardKeyCode = Enum.KeyCode.E
cranePrompt.MaxActivationDistance = 14
cranePrompt.HoldDuration = 0
cranePrompt.Parent = craneConsole

-- =============================================================================
-- G. PORTIQUE D'ENTRÉE VERS LA PENTE 1v1 (STOP THE FRAME)
-- =============================================================================
local gateModel = Instance.new("Model")
gateModel.Name = "StopTheFrameEntryGate"
gateModel.Parent = docksFolder

local GATE_POS_Z = -38
local pillarL = createPart("GatePillar_L", Vector3.new(2.5, 18, 2.5), CFrame.new(-18, 9, GATE_POS_Z), Enum.Material.Metal, Color3.fromRGB(35, 38, 42), true, gateModel)
local pillarR = createPart("GatePillar_R", Vector3.new(2.5, 18, 2.5), CFrame.new(18, 9, GATE_POS_Z), Enum.Material.Metal, Color3.fromRGB(35, 38, 42), true, gateModel)
local crossbeam = createPart("GateCrossbeam", Vector3.new(38, 3, 2.5), CFrame.new(0, 17, GATE_POS_Z), Enum.Material.Metal, Color3.fromRGB(35, 38, 42), true, gateModel)

-- Enseigne Néon de Course
local neonSign = createPart("NeonSign_StopTheFrame", Vector3.new(32, 2.2, 0.5), CFrame.new(0, 17, GATE_POS_Z + 1.4), Enum.Material.Neon, Color3.fromRGB(255, 225, 0), false, gateModel)

-- Feux de départ de course (Vert, Orange, Rouge)
local lightGreen  = createPart("LightGreen", Vector3.new(1.2, 1.2, 0.6), CFrame.new(-6, 14, GATE_POS_Z + 1.3), Enum.Material.Neon, Color3.fromRGB(0, 255, 60), false, gateModel)
local lightYellow = createPart("LightYellow", Vector3.new(1.2, 1.2, 0.6), CFrame.new(0, 14, GATE_POS_Z + 1.3), Enum.Material.Neon, Color3.fromRGB(255, 190, 0), false, gateModel)
local lightRed    = createPart("LightRed", Vector3.new(1.2, 1.2, 0.6), CFrame.new(6, 14, GATE_POS_Z + 1.3), Enum.Material.Neon, Color3.fromRGB(255, 30, 30), false, gateModel)

-- Borne d'enregistrement Stop The Frame avec ProximityPrompt
local raceTerminal = createPart("RaceTerminal", Vector3.new(3, 3.5, 2), CFrame.new(-12, 2.75, GATE_POS_Z - 5), Enum.Material.Metal, Color3.fromRGB(25, 28, 32), true, gateModel)
createPart("TerminalScreen", Vector3.new(2.2, 1.4, 0.2), raceTerminal.CFrame * CFrame.new(0, 0.6, -1.0), Enum.Material.Neon, Color3.fromRGB(255, 230, 60), false, gateModel)

local racePrompt = Instance.new("ProximityPrompt")
racePrompt.Name = "StartRacePrompt"
racePrompt.ActionText = "Lancer le Défi"
racePrompt.ObjectText = "Pente 1v1 Stop the Frame ⚡"
racePrompt.KeyboardKeyCode = Enum.KeyCode.E
racePrompt.MaxActivationDistance = 14
racePrompt.HoldDuration = 0
racePrompt.Parent = raceTerminal

print("[WorldBuilder] Quai Maritime, Bassin Aquatique, 6 Podiums Showroom et Grue Industrielle initialisés avec succès.")
