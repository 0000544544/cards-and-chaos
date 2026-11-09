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


-- =============================================================================
-- 7. LE PORT MARITIME, LE BASSIN AQUATIQUE & LA GRUE INDUSTRIELLE (MODE PÊCHE)
-- =============================================================================
local docksFolder = Instance.new("Folder")
docksFolder.Name = "SanFranciscoDocks"
docksFolder.Parent = Workspace

-- A. Dalle principale du Quai (Béton industriel et pavés portuaires)
local dockFloor = createPart(
    "DockPlaza",
    Vector3.new(140, 4, 105),
    CFrame.new(0, -1, -90),
    Enum.Material.Concrete,
    Color3.fromRGB(90, 95, 102),
    true,
    docksFolder
)

-- Promenade en bois traité le long de la ligne d'eau
local woodBoardwalk = createPart(
    "WoodBoardwalk",
    Vector3.new(140, 0.4, 18),
    CFrame.new(0, 1.15, -133),
    Enum.Material.WoodPlanks,
    Color3.fromRGB(115, 85, 60),
    true,
    docksFolder
)

-- Bordure de quai en poutres massives d'amarrage
local dockEdgeBeam = createPart(
    "DockEdgeBeam",
    Vector3.new(140, 1.6, 2.5),
    CFrame.new(0, 1.6, -141),
    Enum.Material.WoodPlanks,
    Color3.fromRGB(65, 45, 30),
    true,
    docksFolder
)

-- Bollards d'amarrage maritimes en fonte noire le long du quai
for x = -60, 60, 15 do
    local bollard = Instance.new("Part")
    bollard.Name = "Bollard_" .. x
    bollard.Shape = Enum.PartType.Cylinder
    bollard.Size = Vector3.new(2.4, 1.2, 1.2)
    bollard.CFrame = CFrame.new(x, 2.2, -140) * CFrame.Angles(0, 0, math.rad(90))
    bollard.Material = Enum.Material.Metal
    bollard.Color = Color3.fromRGB(20, 22, 25)
    bollard.Anchored = true
    bollard.CanCollide = true
    bollard.Parent = docksFolder
end

-- Conteneurs maritimes décoratifs empilés sur les côtés du port
local containerColors = {
    Color3.fromRGB(210, 45, 35),  -- Rouge brique
    Color3.fromRGB(35, 110, 195), -- Bleu marine
    Color3.fromRGB(225, 160, 20), -- Jaune cargo
    Color3.fromRGB(35, 140, 65),  -- Vert industriel
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
    -- Portes de conteneur
    createPart(name .. "_Doors", Vector3.new(8.2, 8.2, 0.4), cont.CFrame * CFrame.new(0, 0, 11.1), Enum.Material.Metal, Color3.fromRGB(30, 32, 35), false, docksFolder)
end

buildCargoContainer("Container_L1", Vector3.new(-52, 5.5, -80), 12, 1)
buildCargoContainer("Container_L2", Vector3.new(-53, 14.5, -80), 8, 2)
buildCargoContainer("Container_L3", Vector3.new(-40, 5.5, -95), -5, 3)

buildCargoContainer("Container_R1", Vector3.new(52, 5.5, -80), -10, 4)
buildCargoContainer("Container_R2", Vector3.new(51, 14.5, -80), -12, 1)
buildCargoContainer("Container_R3", Vector3.new(42, 5.5, -95), 4, 3)

-- Point d'apparition principal (Spawn) au centre du Quai Maritime
local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Name = "DockSpawnPoint"
spawnLocation.Size = Vector3.new(12, 0.5, 12)
spawnLocation.CFrame = CFrame.new(0, 1.25, -75)
spawnLocation.Material = Enum.Material.Concrete
spawnLocation.Color = Color3.fromRGB(75, 80, 88)
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
waterBasin.Transparency = 0.42
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

-- Bulles d'eau qui montent de l'épave vers la surface
local bubbleEmitter = Instance.new("ParticleEmitter")
bubbleEmitter.Name = "UnderwaterBubbles"
bubbleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
bubbleEmitter.Color = ColorSequence.new(Color3.fromRGB(180, 240, 255))
bubbleEmitter.Size = NumberSequence.new(0.6, 1.4)
bubbleEmitter.Transparency = NumberSequence.new(0.3, 0.7)
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

-- C. La Grande Grue Industrielle Jaune Caterpillar (Mode Pêche)
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

-- D. Portique Lumineux d'Entrée vers la Pente 1v1 (Stop the Frame)
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

print("[WorldBuilder] Quai Maritime, Bassin Aquatique et Grue Industrielle initialisés avec succès.")
