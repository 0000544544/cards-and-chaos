--!strict
--[[
    STOP AT THE FRAME - WORLD BUILDER (SERVER SCRIPT)
    Génère procéduralement la rue en pente raide style San Francisco,
    les immeubles pastel, le cadre cible vert néon "TargetFrame",
    et le Hub Portuaire Simulator compact et chaleureux (Quai 80x70, Grue 3D, 6 Podiums Showroom, Spots sous-marins).
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
    Color3.fromRGB(168, 218, 185),
    Color3.fromRGB(245, 230, 205),
    Color3.fromRGB(165, 200, 235),
    Color3.fromRGB(245, 202, 188),
    Color3.fromRGB(215, 202, 235),
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

    createPart("MainBody", Vector3.new(bWidth, bHeight, bDepth), CFrame.new(bCenterPos), Enum.Material.SmoothPlastic, buildingColor, true, bModel)
    createPart("Cornice", Vector3.new(bWidth + 1.2, 1.8, bDepth + 1.2), CFrame.new(bCenterPos + Vector3.new(0, bHeight / 2 + 0.9, 0)), Enum.Material.SmoothPlastic, Color3.fromRGB(250, 250, 252), true, bModel)

    local facadeX = if isLeftSide then (bCenterPos.X + bWidth / 2 + 0.1) else (bCenterPos.X - bWidth / 2 - 0.1)

    local doorY = groundY + 3.5
    local doorZ = zPos - 5
    createPart("Door", Vector3.new(0.3, 7, 3.5), CFrame.new(facadeX, doorY, doorZ), Enum.Material.WoodPlanks, Color3.fromRGB(75, 50, 40), false, bModel)

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
    buildTownhouse(-35, z, colorIdx, true)
    buildTownhouse(35, z, colorIdx + 2, false)
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
-- 7. LE HUB SIMULATOR TROPICAL & JETÉE MARITIME (STYLE TOP SIMULATOR ROBLOX)
-- =============================================================================
local Lighting = game:GetService("Lighting")

-- Configuration de l'Éclairage & Ambiance Tropicale
Lighting.Brightness = 2.8
Lighting.ClockTime = 14.5
Lighting.GeographicLatitude = 25
Lighting.GlobalShadows = true
Lighting.Ambient = Color3.fromRGB(115, 135, 160)
Lighting.OutdoorAmbient = Color3.fromRGB(145, 170, 195)
Lighting.ColorShift_Top = Color3.fromRGB(255, 248, 235)

local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Density = 0.28
atmosphere.Offset = 0.25
atmosphere.Color = Color3.fromRGB(195, 225, 255)
atmosphere.Decay = Color3.fromRGB(245, 195, 140)
atmosphere.Glare = 0.35
atmosphere.Haze = 0.4
atmosphere.Parent = Lighting

local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
bloom.Intensity = 0.65
bloom.Size = 22
bloom.Threshold = 1.6
bloom.Parent = Lighting

local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
colorCorrection.Brightness = 0.03
colorCorrection.Contrast = 0.12
colorCorrection.Saturation = 0.28
colorCorrection.TintColor = Color3.fromRGB(255, 252, 245)
colorCorrection.Parent = Lighting

local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect")
sunRays.Intensity = 0.16
sunRays.Spread = 0.8
sunRays.Parent = Lighting

local docksFolder = Instance.new("Folder")
docksFolder.Name = "SanFranciscoDocks"
docksFolder.Parent = Workspace

-- =============================================================================
-- A. VASTE OCÉAN TROPICAL & HORIZON CÔTIER
-- =============================================================================
local vastOcean = createPart(
    "VastOceanSurface",
    Vector3.new(2048, 2, 2048),
    CFrame.new(0, -0.6, -180),
    Enum.Material.Glass,
    Color3.fromRGB(18, 155, 215),
    false,
    docksFolder
)
vastOcean.Transparency = 0.38
vastOcean.Reflectance = 0.45

local vastSeaBed = createPart(
    "VastSeaBed",
    Vector3.new(2048, 8, 2048),
    CFrame.new(0, -42, -180),
    Enum.Material.Sand,
    Color3.fromRGB(30, 44, 54),
    true,
    docksFolder
)

-- Rivages tropicaux sur les côtés
createPart("Coastline_Left", Vector3.new(200, 18, 400), CFrame.new(-135, -6, -80), Enum.Material.Sand, Color3.fromRGB(240, 222, 172), true, docksFolder)
createPart("Coastline_Right", Vector3.new(200, 18, 400), CFrame.new(135, -6, -80), Enum.Material.Sand, Color3.fromRGB(240, 222, 172), true, docksFolder)

-- Épave sous-marine au fond de l'eau avec bulles
local wreckRally = CarBuilder.CreateLotusRally()
wreckRally.Name = "SunkenWreck_Lotus"
wreckRally.Parent = docksFolder
wreckRally:PivotTo(CFrame.new(0, -36, -135) * CFrame.Angles(math.rad(15), math.rad(45), math.rad(-10)))
for _, p in ipairs(wreckRally:GetDescendants()) do
    if p:IsA("BasePart") then
        p.Material = Enum.Material.CorrodedMetal
        p.Color = Color3.fromRGB(90, 60, 45)
        p.Anchored = true
        p.CanCollide = false
    end
end

local bubbleEmitter = Instance.new("ParticleEmitter")
bubbleEmitter.Name = "UnderwaterBubbles"
bubbleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
bubbleEmitter.Color = ColorSequence.new(Color3.fromRGB(180, 240, 255))
bubbleEmitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1.4) })
bubbleEmitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.7) })
bubbleEmitter.Rate = 14
bubbleEmitter.Speed = NumberRange.new(4, 9)
bubbleEmitter.SpreadAngle = Vector2.new(15, 15)
local bubbleAnchor = Instance.new("Part")
bubbleAnchor.Name = "BubbleAnchor"
bubbleAnchor.Size = Vector3.new(1, 1, 1)
bubbleAnchor.CFrame = CFrame.new(0, -34, -135)
bubbleAnchor.Transparency = 1
bubbleAnchor.Anchored = true
bubbleAnchor.CanCollide = false
bubbleAnchor.Parent = docksFolder
bubbleEmitter.Parent = bubbleAnchor

-- =============================================================================
-- B. LA GRANDE JETÉE CENTRALE (PIER RUNWAY AVEC LIGNES CYAN NÉON)
-- =============================================================================
local mainPier = createPart(
    "MainPierPlaza",
    Vector3.new(34, 3, 98),
    CFrame.new(0, -0.5, -83),
    Enum.Material.WoodPlanks,
    Color3.fromRGB(28, 40, 52),
    true,
    docksFolder
)

-- Bordures de finition en bois chaud
createPart("PierBorder_L", Vector3.new(1.2, 1.4, 98), CFrame.new(-17, 1.2, -83), Enum.Material.WoodPlanks, Color3.fromRGB(115, 80, 48), true, docksFolder)
createPart("PierBorder_R", Vector3.new(1.2, 1.4, 98), CFrame.new(17, 1.2, -83), Enum.Material.WoodPlanks, Color3.fromRGB(115, 80, 48), true, docksFolder)
createPart("PierBorder_End", Vector3.new(35.2, 1.4, 1.4), CFrame.new(0, 1.2, -132), Enum.Material.WoodPlanks, Color3.fromRGB(115, 80, 48), true, docksFolder)

-- 5 Lignes Cyan Néon "Runway" au centre du quai (Exactement comme dans l'image 5)
local stripeOffsets = { -8, -4, 0, 4, 8 }
for i, xOff in ipairs(stripeOffsets) do
    local stripe = createPart(
        "RunwayStripe_" .. i,
        Vector3.new(0.4, 0.05, 94),
        CFrame.new(xOff, 1.03, -83),
        Enum.Material.Neon,
        Color3.fromRGB(0, 245, 255),
        false,
        docksFolder
    )
    stripe.Transparency = 0.15
end

-- Barrières et Guirlandes lumineuses festives le long de la jetée
local festoonColors = {
    Color3.fromRGB(255, 215, 80),
    Color3.fromRGB(0, 240, 255),
    Color3.fromRGB(255, 75, 120),
    Color3.fromRGB(60, 255, 140),
}

for _, sideX in ipairs({ -17.2, 17.2 }) do
    for z = -38, -128, 12 do
        local post = createPart("PierPost", Vector3.new(0.8, 6.5, 0.8), CFrame.new(sideX, 3.5, z), Enum.Material.WoodPlanks, Color3.fromRGB(110, 75, 45), true, docksFolder)
        local orb = createPart("FestoonOrb", Vector3.new(1.1, 1.1, 1.1), CFrame.new(sideX, 6.8, z), Enum.Material.Neon, festoonColors[((math.abs(math.floor(z)) // 12) % #festoonColors) + 1], false, docksFolder)
        local pLight = Instance.new("PointLight")
        pLight.Color = orb.Color
        pLight.Brightness = 1.8
        pLight.Range = 16
        pLight.Parent = orb
    end
end

-- Spawn du joueur au début de la jetée, orienté vers la mer et le Showroom
local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Name = "DockSpawnPoint"
spawnLocation.Size = Vector3.new(8, 0.5, 8)
spawnLocation.CFrame = CFrame.new(0, 1.25, -45)
spawnLocation.Material = Enum.Material.WoodPlanks
spawnLocation.Color = Color3.fromRGB(35, 50, 65)
spawnLocation.Anchored = true
spawnLocation.CanCollide = true
spawnLocation.Neutral = true
spawnLocation.Parent = docksFolder

-- =============================================================================
-- C. LES 6 PODIUMS DU SHOWROOM (2 RANGÉES ÉLÉGANTES ET SYMÉTRIQUES)
-- =============================================================================
local showroomFolder = Instance.new("Folder")
showroomFolder.Name = "ShowroomPodiums"
showroomFolder.Parent = docksFolder

local SHOWROOM_CONFIGS = {
    -- Rangée Gauche (X = -10.5)
    { Slot = 1, Pos = Vector3.new(-10.5, 1.0, -58),  VehId = "lotus_rally",        Rate = "$2/s",   Color = Color3.fromRGB(40, 230, 90),   Rarity = "COMMUNE",    Name = "Lotus Rally" },
    { Slot = 2, Pos = Vector3.new(-10.5, 1.0, -80),  VehId = "drift_supra",        Rate = "$12/s",  Color = Color3.fromRGB(30, 120, 255),  Rarity = "RARE",       Name = "Drift Supra" },
    { Slot = 3, Pos = Vector3.new(-10.5, 1.0, -102), VehId = "hyperion_jetcar",    Rate = "$60/s",  Color = Color3.fromRGB(255, 130, 20),  Rarity = "LÉGENDAIRE", Name = "Hyperion JetCar" },
    
    -- Rangée Droite (X = 10.5)
    { Slot = 4, Pos = Vector3.new(10.5, 1.0, -58),   VehId = "cyber_truck",        Rate = "$5/s",   Color = Color3.fromRGB(0, 220, 255),   Rarity = "PEU COMMUNE",Name = "Cyber Truck" },
    { Slot = 5, Pos = Vector3.new(10.5, 1.0, -80),   VehId = "police_interceptor", Rate = "$25/s",  Color = Color3.fromRGB(175, 45, 255),  Rarity = "ÉPIQUE",     Name = "Police Interceptor" },
    { Slot = 6, Pos = Vector3.new(10.5, 1.0, -102),  VehId = "flash_mcqueen",      Rate = "$150/s", Color = Color3.fromRGB(255, 215, 0),   Rarity = "MYTHIQUE",   Name = "⭐ Flash McQueen ⚡" },
}

for _, pcfg in ipairs(SHOWROOM_CONFIGS) do
    local pModel = Instance.new("Model")
    pModel.Name = "Podium_" .. pcfg.VehId
    pModel.Parent = showroomFolder

    -- Base circulaire du podium (Blanc lisse)
    local stand = Instance.new("Part")
    stand.Name = "PodiumStand"
    stand.Shape = Enum.PartType.Cylinder
    stand.Size = Vector3.new(0.7, 7.5, 7.5)
    stand.CFrame = CFrame.new(pcfg.Pos) * CFrame.Angles(0, 0, math.rad(90))
    stand.Material = Enum.Material.SmoothPlastic
    stand.Color = Color3.fromRGB(245, 248, 255)
    stand.Anchored = true
    stand.CanCollide = true
    stand.Parent = pModel

    -- Anneau Néon coloré selon la rareté
    local glowRing = Instance.new("Part")
    glowRing.Name = "GlowRing"
    glowRing.Shape = Enum.PartType.Cylinder
    glowRing.Size = Vector3.new(0.35, 7.9, 7.9)
    glowRing.CFrame = CFrame.new(pcfg.Pos + Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, 0, math.rad(90))
    glowRing.Material = Enum.Material.Neon
    glowRing.Color = pcfg.Color
    glowRing.Anchored = true
    glowRing.CanCollide = false
    glowRing.Parent = pModel

    local pLight = Instance.new("PointLight")
    pLight.Color = pcfg.Color
    pLight.Brightness = 2.0
    pLight.Range = 14
    pLight.Parent = glowRing

    -- Véhicule 3D exposé sur le podium
    local carModel: Model? = nil
    pcall(function()
        local vcfg = CarBuilder.GetVehicleConfig(pcfg.VehId)
        carModel = vcfg.Builder()
        if carModel then
            carModel.Name = "ExhibitionCar_" .. pcfg.VehId
            carModel.Parent = pModel
            local angleY = (pcfg.Pos.X < 0) and 15 or -15
            carModel:PivotTo(CFrame.new(pcfg.Pos + Vector3.new(0, 1.4, 0)) * CFrame.Angles(0, math.rad(180 + angleY), 0))
            for _, bp in ipairs(carModel:GetDescendants()) do
                if bp:IsA("BasePart") then
                    bp.Anchored = true
                    bp.CanCollide = false
                end
            end
        end
    end)

    -- Tag compact flottant (AlwaysOnTop = false pour éviter l'encombrement)
    local statBb = Instance.new("BillboardGui")
    statBb.Name = "VehicleTag"
    statBb.Size = UDim2.new(0, 170, 0, 38)
    statBb.StudsOffset = Vector3.new(0, 4.4, 0)
    statBb.AlwaysOnTop = false
    statBb.MaxDistance = 35
    statBb.Parent = stand

    local tagFrame = Instance.new("Frame")
    tagFrame.Size = UDim2.new(1, 0, 1, 0)
    tagFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
    tagFrame.BorderSizePixel = 0
    tagFrame.Parent = statBb

    local tagCorner = Instance.new("UICorner")
    tagCorner.CornerRadius = UDim.new(0, 8)
    tagCorner.Parent = tagFrame

    local tagStroke = Instance.new("UIStroke")
    tagStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    tagStroke.Color = pcfg.Color
    tagStroke.Thickness = 2
    tagStroke.Parent = tagFrame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -8, 0, 18)
    nameLabel.Position = UDim2.new(0, 4, 0, 2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.FredokaOne
    nameLabel.TextSize = 13
    nameLabel.TextColor3 = pcfg.Color
    nameLabel.Text = pcfg.Name
    nameLabel.Parent = tagFrame

    local rateLabel = Instance.new("TextLabel")
    rateLabel.Size = UDim2.new(1, -8, 0, 16)
    rateLabel.Position = UDim2.new(0, 4, 0, 18)
    rateLabel.BackgroundTransparency = 1
    rateLabel.Font = Enum.Font.GothamBold
    rateLabel.TextSize = 11
    rateLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
    rateLabel.Text = pcfg.Rarity .. " • +" .. pcfg.Rate
    rateLabel.Parent = tagFrame

    -- Bouton / Pad circulaire au sol devant le podium (Collect Pad)
    local collectX = (pcfg.Pos.X < 0) and (pcfg.Pos.X + 4.8) or (pcfg.Pos.X - 4.8)
    local collectPad = Instance.new("Part")
    collectPad.Name = "CollectPad_" .. pcfg.VehId
    collectPad.Shape = Enum.PartType.Cylinder
    collectPad.Size = Vector3.new(0.25, 4.2, 4.2)
    collectPad.CFrame = CFrame.new(collectX, 1.05, pcfg.Pos.Z) * CFrame.Angles(0, 0, math.rad(90))
    collectPad.Material = Enum.Material.Neon
    collectPad.Color = pcfg.Color
    collectPad.Transparency = 0.2
    collectPad.Anchored = true
    collectPad.CanCollide = false
    collectPad.Parent = pModel

    local padBb = Instance.new("BillboardGui")
    padBb.Name = "PadTag"
    padBb.Size = UDim2.new(0, 120, 0, 24)
    padBb.StudsOffset = Vector3.new(0, 1.6, 0)
    padBb.AlwaysOnTop = false
    padBb.MaxDistance = 22
    padBb.Parent = collectPad

    local padLbl = Instance.new("TextLabel")
    padLbl.Size = UDim2.new(1, 0, 1, 0)
    padLbl.BackgroundTransparency = 1
    padLbl.Font = Enum.Font.GothamBlack
    padLbl.TextSize = 11
    padLbl.TextColor3 = pcfg.Color
    padLbl.TextStrokeColor3 = Color3.fromRGB(10, 12, 16)
    padLbl.TextStrokeTransparency = 0.2
    padLbl.Text = "💰 +" .. pcfg.Rate
    padLbl.Parent = padBb
end

-- =============================================================================
-- D. LA STATION DE PÊCHE MARITIME AU BOUT DU QUAI (VUE PANORAMIQUE SUR L'OCÉAN)
-- =============================================================================
local craneModel = Instance.new("Model")
craneModel.Name = "IndustrialFishingCrane"
craneModel.Parent = docksFolder

-- Portique maritime moderne cadrant l'océan sur les côtés (laisse le centre 100% ouvert)
local GANTRY_NAVY = Color3.fromRGB(24, 32, 44)
local GANTRY_WHITE = Color3.fromRGB(240, 245, 252)
local GANTRY_CYAN = Color3.fromRGB(0, 245, 255)

-- Piliers stylisés gauche et droite
createPart("GantryPillar_L", Vector3.new(2.4, 16, 2.4), CFrame.new(-14, 8, -130), Enum.Material.Metal, GANTRY_NAVY, true, craneModel)
createPart("GantryPillar_R", Vector3.new(2.4, 16, 2.4), CFrame.new(14, 8, -130), Enum.Material.Metal, GANTRY_NAVY, true, craneModel)
createPart("GantryBeam_L", Vector3.new(2.8, 2.4, 14), CFrame.new(-14, 15, -135), Enum.Material.Metal, GANTRY_WHITE, true, craneModel)
createPart("GantryBeam_R", Vector3.new(2.8, 2.4, 14), CFrame.new(14, 15, -135), Enum.Material.Metal, GANTRY_WHITE, true, craneModel)

-- Bandes lumineuses néon cyan sur les portiques
createPart("GantryNeon_L", Vector3.new(0.3, 14, 0.3), CFrame.new(-12.7, 8, -130), Enum.Material.Neon, GANTRY_CYAN, false, craneModel)
createPart("GantryNeon_R", Vector3.new(0.3, 14, 0.3), CFrame.new(12.7, 8, -130), Enum.Material.Neon, GANTRY_CYAN, false, craneModel)

-- Pupitre de commande / Timonerie maritime au centre
local craneConsole = createPart("CraneControlConsole", Vector3.new(3.6, 3.2, 2.2), CFrame.new(0, 2.6, -128), Enum.Material.Metal, GANTRY_NAVY, true, craneModel)
local consoleScreen = createPart("ConsoleScreen", Vector3.new(2.8, 1.4, 0.2), craneConsole.CFrame * CFrame.new(0, 0.6, 1.1), Enum.Material.Neon, GANTRY_CYAN, false, craneModel)

local cranePrompt = Instance.new("ProximityPrompt")
cranePrompt.Name = "CraneControlPrompt"
cranePrompt.ActionText = "Pêcher des Voitures 3D"
cranePrompt.ObjectText = "Mode Pêche Maritime 🎣"
cranePrompt.KeyboardKeyCode = Enum.KeyCode.E
cranePrompt.MaxActivationDistance = 14
cranePrompt.HoldDuration = 0
cranePrompt.Parent = craneConsole

-- Câble et Électro-Aimant suspendus au-dessus de l'eau
local winchCable = createPart("WinchCable", Vector3.new(0.35, 18, 0.35), CFrame.new(0, 14, -135), Enum.Material.Metal, Color3.fromRGB(40, 44, 52), false, craneModel)

local craneMagnet = Instance.new("Part")
craneMagnet.Name = "CraneMagnet"
craneMagnet.Shape = Enum.PartType.Cylinder
craneMagnet.Size = Vector3.new(2.5, 7.5, 7.5)
craneMagnet.CFrame = CFrame.new(0, 5.5, -135) * CFrame.Angles(0, 0, math.rad(90))
craneMagnet.Material = Enum.Material.Metal
craneMagnet.Color = GANTRY_NAVY
craneMagnet.Anchored = true
craneMagnet.CanCollide = true
craneMagnet.Parent = craneModel

local magnetRing = createPart("MagnetNeonRing", Vector3.new(6.8, 0.4, 6.8), craneMagnet.CFrame * CFrame.new(-1.1, 0, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Neon, GANTRY_CYAN, false, craneModel)

local magnetLight = Instance.new("PointLight")
magnetLight.Name = "MagnetLight"
magnetLight.Color = GANTRY_CYAN
magnetLight.Brightness = 3.5
magnetLight.Range = 25
magnetLight.Parent = craneMagnet

-- =============================================================================
-- E. LES 6 SPOTS SOUS-MARINS VISIBLES AVEC COLONNES DE LUMIÈRE DANS L'OCÉAN
-- =============================================================================
local underwaterSpotsFolder = Instance.new("Folder")
underwaterSpotsFolder.Name = "UnderwaterSpots"
underwaterSpotsFolder.Parent = docksFolder

local SPOT_DEFS = {
    { Pos = Vector3.new(-22, -37, -125), Color = Color3.fromRGB(40, 230, 90),   Rarity = "Commune",    Label = "🟢 Lotus Rally" },
    { Pos = Vector3.new(22, -37, -125),  Color = Color3.fromRGB(0, 220, 255),   Rarity = "Peu Commune",Label = "🔷 Cyber Truck" },
    { Pos = Vector3.new(-14, -37, -138), Color = Color3.fromRGB(30, 120, 255),  Rarity = "Rare",       Label = "🔵 Drift Supra" },
    { Pos = Vector3.new(14, -37, -138),  Color = Color3.fromRGB(175, 45, 255),  Rarity = "Épique",     Label = "🟣 Police Interceptor" },
    { Pos = Vector3.new(-18, -37, -150), Color = Color3.fromRGB(255, 130, 20),  Rarity = "Légendaire", Label = "🟠 Hyperion JetCar" },
    { Pos = Vector3.new(12, -37, -148),  Color = Color3.fromRGB(255, 215, 0),   Rarity = "Mythique",   Label = "⭐ Flash McQueen ⚡" },
}

for i, spot in ipairs(SPOT_DEFS) do
    local spotModel = Instance.new("Model")
    spotModel.Name = "UnderwaterSpot_" .. i
    spotModel.Parent = underwaterSpotsFolder

    local baseDisc = Instance.new("Part")
    baseDisc.Name = "BaseGlow"
    baseDisc.Shape = Enum.PartType.Cylinder
    baseDisc.Size = Vector3.new(0.8, 10, 10)
    baseDisc.CFrame = CFrame.new(spot.Pos) * CFrame.Angles(0, 0, math.rad(90))
    baseDisc.Material = Enum.Material.Neon
    baseDisc.Color = spot.Color
    baseDisc.Anchored = true
    baseDisc.CanCollide = false
    baseDisc.Parent = spotModel

    local beamHeight = 36
    local lightBeam = Instance.new("Part")
    lightBeam.Name = "LightColumn"
    lightBeam.Shape = Enum.PartType.Cylinder
    lightBeam.Size = Vector3.new(beamHeight, 7, 7)
    lightBeam.CFrame = CFrame.new(spot.Pos.X, spot.Pos.Y + (beamHeight / 2), spot.Pos.Z) * CFrame.Angles(0, 0, math.rad(90))
    lightBeam.Material = Enum.Material.Neon
    lightBeam.Color = spot.Color
    lightBeam.Transparency = 0.76
    lightBeam.Anchored = true
    lightBeam.CanCollide = false
    lightBeam.Parent = spotModel

    local surfaceRing = Instance.new("Part")
    surfaceRing.Name = "SurfaceRing"
    surfaceRing.Shape = Enum.PartType.Cylinder
    surfaceRing.Size = Vector3.new(0.3, 8.5, 8.5)
    surfaceRing.CFrame = CFrame.new(spot.Pos.X, 0.2, spot.Pos.Z) * CFrame.Angles(0, 0, math.rad(90))
    surfaceRing.Material = Enum.Material.Neon
    surfaceRing.Color = spot.Color
    surfaceRing.Transparency = 0.45
    surfaceRing.Anchored = true
    surfaceRing.CanCollide = false
    surfaceRing.Parent = spotModel

    local sLight = Instance.new("PointLight")
    sLight.Color = spot.Color
    sLight.Brightness = 3.0
    sLight.Range = 26
    sLight.Parent = surfaceRing
end

-- =============================================================================
-- F. PORTIQUE D'ENTRÉE DU DÉFI "STOP THE FRAME" (AU DÉBUT DU QUAI À Z = -34)
-- =============================================================================
local gateModel = Instance.new("Model")
gateModel.Name = "StopTheFrameEntryGate"
gateModel.Parent = docksFolder

local GATE_POS_Z = -34
local pillarL = createPart("GatePillar_L", Vector3.new(2.5, 18, 2.5), CFrame.new(-16, 9, GATE_POS_Z), Enum.Material.Metal, Color3.fromRGB(35, 38, 42), true, gateModel)
local pillarR = createPart("GatePillar_R", Vector3.new(2.5, 18, 2.5), CFrame.new(16, 9, GATE_POS_Z), Enum.Material.Metal, Color3.fromRGB(35, 38, 42), true, gateModel)
local crossbeam = createPart("GateCrossbeam", Vector3.new(34, 3, 2.5), CFrame.new(0, 17, GATE_POS_Z), Enum.Material.Metal, Color3.fromRGB(35, 38, 42), true, gateModel)

local neonSign = createPart("NeonSign_StopTheFrame", Vector3.new(30, 2.2, 0.5), CFrame.new(0, 17, GATE_POS_Z + 1.4), Enum.Material.Neon, Color3.fromRGB(255, 225, 0), false, gateModel)

local lightGreen  = createPart("LightGreen", Vector3.new(1.2, 1.2, 0.6), CFrame.new(-5, 14, GATE_POS_Z + 1.3), Enum.Material.Neon, Color3.fromRGB(0, 255, 60), false, gateModel)
local lightYellow = createPart("LightYellow", Vector3.new(1.2, 1.2, 0.6), CFrame.new(0, 14, GATE_POS_Z + 1.3), Enum.Material.Neon, Color3.fromRGB(255, 190, 0), false, gateModel)
local lightRed    = createPart("LightRed", Vector3.new(1.2, 1.2, 0.6), CFrame.new(5, 14, GATE_POS_Z + 1.3), Enum.Material.Neon, Color3.fromRGB(255, 30, 30), false, gateModel)

local raceTerminal = createPart("RaceTerminal", Vector3.new(3, 3.5, 2), CFrame.new(-10, 2.75, GATE_POS_Z - 3), Enum.Material.Metal, Color3.fromRGB(25, 28, 32), true, gateModel)
createPart("TerminalScreen", Vector3.new(2.2, 1.4, 0.2), raceTerminal.CFrame * CFrame.new(0, 0.6, -1.0), Enum.Material.Neon, Color3.fromRGB(255, 230, 60), false, gateModel)

local racePrompt = Instance.new("ProximityPrompt")
racePrompt.Name = "StartRacePrompt"
racePrompt.ActionText = "Lancer le Défi"
racePrompt.ObjectText = "Pente 1v1 Stop the Frame ⚡"
racePrompt.KeyboardKeyCode = Enum.KeyCode.E
racePrompt.MaxActivationDistance = 14
racePrompt.HoldDuration = 0
racePrompt.Parent = raceTerminal

print("[WorldBuilder] Jetée Maritime Tropicale, Lignes Runway Cyan, 6 Podiums Showroom et Station de Pêche initialisés avec succès !")
