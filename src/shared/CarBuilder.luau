--!strict
--[[
    STOP AT THE FRAME - CAR BUILDER & TARGET FRAME GENERATOR (MODULE SCRIPT)
    Génère procéduralement les 5 véhicules avec soubassement noir détaillé,
    et génère le TargetFrame : un seul polygone fermé continu en fines barres Neon vertes (0.14)
    délimitant exclusivement le contour extérieur (vide à l'intérieur, aucun clone fantôme, aucune ligne interne).
]]

local CarBuilder = {}

export type ContourPoint = { number } -- { X, Y }

export type VehicleConfig = {
    Id: string,
    Index: number,
    Name: string,
    SpeedMultiplier: number,
    RewardCash: number,
    FrontZ: number,
    OuterContour: { ContourPoint },
    Builder: () -> Model,
}

local function createPart(name: string, size: Vector3, cf: CFrame, mat: Enum.Material, col: Color3, parent: Instance): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Material = mat
    p.Color = col
    p.Anchored = false
    p.CanCollide = false
    p.Parent = parent
    return p
end

local function weldParts(part0: BasePart, part1: BasePart)
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = part0
    weld.Part1 = part1
    weld.Parent = part1
end

-- Ajoute un soubassement mécanique noir détaillé (visible quand le nez est cabré)
local function addDetailedUndercarriage(root: BasePart, car: Model, width: number, length: number)
    local UNDER_BLACK = Color3.fromRGB(15, 16, 18)
    local METAL_GRAY = Color3.fromRGB(175, 180, 188)
    local EXHAUST_HEAT = Color3.fromRGB(120, 150, 190)

    -- Plaque de protection inférieure (Skid Plate)
    local skidPlate = createPart("SkidPlate", Vector3.new(width - 0.8, 0.25, length - 1.5), root.CFrame * CFrame.new(0, -0.9, 0), Enum.Material.DiamondPlate, UNDER_BLACK, car)
    weldParts(root, skidPlate)

    -- Carter de transmission & boîte centrale
    local transmission = createPart("GearboxPan", Vector3.new(2.0, 0.4, 3.0), root.CFrame * CFrame.new(0, -0.95, -0.4), Enum.Material.Metal, METAL_GRAY, car)
    weldParts(root, transmission)

    -- Double ligne d'échappement inox
    local exhaustL = createPart("ExhaustPipe_L", Vector3.new(0.35, 0.35, length - 3.2), root.CFrame * CFrame.new(-1.2, -0.92, 0.8), Enum.Material.Metal, EXHAUST_HEAT, car)
    weldParts(root, exhaustL)
    local exhaustR = createPart("ExhaustPipe_R", Vector3.new(0.35, 0.35, length - 3.2), root.CFrame * CFrame.new(1.2, -0.92, 0.8), Enum.Material.Metal, EXHAUST_HEAT, car)
    weldParts(root, exhaustR)

    -- Embouts d'échappement chromés à l'arrière
    local tipL = Instance.new("Part")
    tipL.Name = "ExhaustTip_L"
    tipL.Shape = Enum.PartType.Cylinder
    tipL.Size = Vector3.new(0.8, 0.5, 0.5)
    tipL.CFrame = root.CFrame * CFrame.new(-1.3, -0.7, length / 2 + 0.3) * CFrame.Angles(0, math.rad(90), 0)
    tipL.Material = Enum.Material.Metal
    tipL.Color = METAL_GRAY
    tipL.Anchored = false
    tipL.CanCollide = false
    tipL.Parent = car
    weldParts(root, tipL)

    local tipR = Instance.new("Part")
    tipR.Name = "ExhaustTip_R"
    tipR.Shape = Enum.PartType.Cylinder
    tipR.Size = Vector3.new(0.8, 0.5, 0.5)
    tipR.CFrame = root.CFrame * CFrame.new(1.3, -0.7, length / 2 + 0.3) * CFrame.Angles(0, math.rad(90), 0)
    tipR.Material = Enum.Material.Metal
    tipR.Color = METAL_GRAY
    tipR.Anchored = false
    tipR.CanCollide = false
    tipR.Parent = car
    weldParts(root, tipR)

    -- Essieux de suspension avant et arrière
    local axleFront = createPart("Suspension_F", Vector3.new(width - 0.4, 0.3, 0.8), root.CFrame * CFrame.new(0, -0.8, -length * 0.3), Enum.Material.Metal, UNDER_BLACK, car)
    weldParts(root, axleFront)
    local axleRear = createPart("Suspension_R", Vector3.new(width - 0.4, 0.3, 0.8), root.CFrame * CFrame.new(0, -0.8, length * 0.3), Enum.Material.Metal, UNDER_BLACK, car)
    weldParts(root, axleRear)
end

-- =============================================================================
-- #1 LOTUS RALLY (Rouge vif, vitesse x1.0, 50$)
-- =============================================================================
function CarBuilder.CreateLotusRally(): Model
    local car = Instance.new("Model")
    car.Name = "LotusRally"

    local root = Instance.new("Part")
    root.Name = "RootPart"
    root.Size = Vector3.new(1, 1, 1)
    root.Transparency = 1
    root.CanCollide = false
    root.Anchored = true
    root.Parent = car
    car.PrimaryPart = root

    local RED = Color3.fromRGB(230, 25, 35)
    local DARK_RED = Color3.fromRGB(180, 16, 22)
    local CHARCOAL = Color3.fromRGB(30, 32, 36)
    local BLACK_GLOSS = Color3.fromRGB(15, 18, 22)
    local RIM_GRAY = Color3.fromRGB(195, 200, 208)

    -- Carrosserie
    local base = createPart("Base", Vector3.new(6.4, 1.2, 11.6), root.CFrame * CFrame.new(0, -0.2, 0), Enum.Material.SmoothPlastic, RED, car)
    weldParts(root, base)
    local splitter = createPart("Splitter", Vector3.new(6.4, 0.35, 1.4), root.CFrame * CFrame.new(0, -0.7, -5.9), Enum.Material.SmoothPlastic, CHARCOAL, car)
    weldParts(root, splitter)
    local hood = createPart("Hood", Vector3.new(6.2, 0.65, 3.8), root.CFrame * CFrame.new(0, 0.45, -3.7) * CFrame.Angles(math.rad(-6), 0, 0), Enum.Material.SmoothPlastic, RED, car)
    weldParts(root, hood)
    local rearDeck = createPart("RearDeck", Vector3.new(6.2, 0.85, 3.2), root.CFrame * CFrame.new(0, 0.55, 3.8), Enum.Material.SmoothPlastic, RED, car)
    weldParts(root, rearDeck)

    -- Toit et vitres
    local roof = createPart("Roof", Vector3.new(4.8, 0.35, 4.6), root.CFrame * CFrame.new(0, 1.85, 0.4), Enum.Material.SmoothPlastic, DARK_RED, car)
    weldParts(root, roof)
    local windshield = createPart("Windshield", Vector3.new(4.7, 1.6, 0.25), root.CFrame * CFrame.new(0, 1.2, -1.8) * CFrame.Angles(math.rad(-32), 0, 0), Enum.Material.Glass, BLACK_GLOSS, car)
    windshield.Reflectance = 0.35
    weldParts(root, windshield)
    local rearWin = createPart("RearWin", Vector3.new(4.7, 1.5, 0.25), root.CFrame * CFrame.new(0, 1.25, 2.7) * CFrame.Angles(math.rad(28), 0, 0), Enum.Material.Glass, BLACK_GLOSS, car)
    weldParts(root, rearWin)

    -- Aileron et scoop
    local wing = createPart("RearWing", Vector3.new(6.4, 0.3, 1.8), root.CFrame * CFrame.new(0, 2.1, 5.7), Enum.Material.SmoothPlastic, CHARCOAL, car)
    weldParts(root, wing)
    local scoop = createPart("RoofScoop", Vector3.new(1.6, 0.5, 1.8), root.CFrame * CFrame.new(0, 2.15, -0.6) * CFrame.Angles(math.rad(-10), 0, 0), Enum.Material.SmoothPlastic, CHARCOAL, car)
    weldParts(root, scoop)

    -- 4 Roues (Rayon 1.1, Largeur 0.9, Bas à Y = -1.80)
    for _, offset in ipairs({ Vector3.new(-3.45, -0.7, -3.7), Vector3.new(3.45, -0.7, -3.7), Vector3.new(-3.45, -0.7, 3.7), Vector3.new(3.45, -0.7, 3.7) }) do
        local tire = Instance.new("Part")
        tire.Shape = Enum.PartType.Cylinder
        tire.Size = Vector3.new(0.9, 2.2, 2.2)
        tire.CFrame = root.CFrame * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(90))
        tire.Material = Enum.Material.Rubber
        tire.Color = Color3.fromRGB(20, 20, 22)
        tire.Anchored = false
        tire.CanCollide = false
        tire.Parent = car
        weldParts(root, tire)

        local rim = Instance.new("Part")
        rim.Shape = Enum.PartType.Cylinder
        rim.Size = Vector3.new(0.96, 1.4, 1.4)
        rim.CFrame = tire.CFrame
        rim.Material = Enum.Material.Metal
        rim.Color = RIM_GRAY
        rim.Anchored = false
        rim.CanCollide = false
        rim.Parent = car
        weldParts(root, rim)
    end

    -- Phares Neon
    local headL = createPart("HeadL", Vector3.new(1.3, 0.5, 0.2), root.CFrame * CFrame.new(-2.3, 0.05, -5.85), Enum.Material.Neon, Color3.fromRGB(255, 252, 225), car)
    weldParts(root, headL)
    local headR = createPart("HeadR", Vector3.new(1.3, 0.5, 0.2), root.CFrame * CFrame.new(2.3, 0.05, -5.85), Enum.Material.Neon, Color3.fromRGB(255, 252, 225), car)
    weldParts(root, headR)

    -- Rétroviseurs
    local mirL = createPart("MirrorL", Vector3.new(0.7, 0.35, 0.8), root.CFrame * CFrame.new(-2.7, 0.95, -1.6), Enum.Material.SmoothPlastic, CHARCOAL, car)
    weldParts(root, mirL)
    local mirR = createPart("MirrorR", Vector3.new(0.7, 0.35, 0.8), root.CFrame * CFrame.new(2.7, 0.95, -1.6), Enum.Material.SmoothPlastic, CHARCOAL, car)
    weldParts(root, mirR)

    addDetailedUndercarriage(root, car, 6.4, 11.6)
    return car
end

-- =============================================================================
-- #2 CYBER TRUCK (Pick-up futuriste acier brossé, vitesse x1.35, 120$)
-- =============================================================================
function CarBuilder.CreateCyberTruck(): Model
    local car = Instance.new("Model")
    car.Name = "CyberTruck"

    local root = Instance.new("Part")
    root.Name = "RootPart"
    root.Size = Vector3.new(1, 1, 1)
    root.Transparency = 1
    root.CanCollide = false
    root.Anchored = true
    root.Parent = car
    car.PrimaryPart = root

    local STEEL = Color3.fromRGB(220, 225, 232)
    local DARK_STEEL = Color3.fromRGB(135, 140, 150)
    local CYBER_CYAN = Color3.fromRGB(0, 240, 255)
    local BLACK_ARMOR = Color3.fromRGB(22, 24, 28)

    -- Châssis principal profilé (Largeur 6.4, Hauteur 1.2, Longueur 11.6)
    local lower = createPart("LowerArmor", Vector3.new(6.4, 1.2, 11.6), root.CFrame * CFrame.new(0, -0.2, 0), Enum.Material.Metal, STEEL, car)
    weldParts(root, lower)

    -- Toit triangulaire pyramidale emblématique
    local roofFront = createPart("RoofFrontSlope", Vector3.new(5.8, 0.45, 5.8), root.CFrame * CFrame.new(0, 1.25, -2.4) * CFrame.Angles(math.rad(-21), 0, 0), Enum.Material.Metal, STEEL, car)
    weldParts(root, roofFront)

    local roofBack = createPart("RoofBackSlope", Vector3.new(5.8, 0.45, 6.0), root.CFrame * CFrame.new(0, 1.25, 2.9) * CFrame.Angles(math.rad(19), 0, 0), Enum.Material.Metal, STEEL, car)
    weldParts(root, roofBack)

    -- Crête supérieure du toit
    local roofPeak = createPart("RoofPeakBar", Vector3.new(2.8, 0.35, 1.2), root.CFrame * CFrame.new(0, 2.05, 0.2), Enum.Material.Metal, STEEL, car)
    weldParts(root, roofPeak)

    -- Pare-brise angulaire blindé teinté
    local glass = createPart("ArmorWindshield", Vector3.new(5.4, 1.6, 0.25), root.CFrame * CFrame.new(0, 1.2, -2.3) * CFrame.Angles(math.rad(-25), 0, 0), Enum.Material.Glass, BLACK_ARMOR, car)
    glass.Reflectance = 0.4
    weldParts(root, glass)

    -- Lightbar avant continue néon cyan (Pleine largeur 6.2 studs)
    local lightbar = createPart("FrontLightbar", Vector3.new(6.2, 0.28, 0.2), root.CFrame * CFrame.new(0, 0.45, -5.85), Enum.Material.Neon, CYBER_CYAN, car)
    weldParts(root, lightbar)

    -- Lightbar arrière rouge
    local rearLight = createPart("RearLightbar", Vector3.new(6.2, 0.28, 0.2), root.CFrame * CFrame.new(0, 0.55, 5.85), Enum.Material.Neon, Color3.fromRGB(255, 30, 30), car)
    weldParts(root, rearLight)

    -- Rétroviseurs angulaires compacts
    local mirL = createPart("CyberMirrorL", Vector3.new(0.65, 0.35, 0.7), root.CFrame * CFrame.new(-3.3, 0.95, -1.8), Enum.Material.Metal, DARK_STEEL, car)
    weldParts(root, mirL)
    local mirR = createPart("CyberMirrorR", Vector3.new(0.65, 0.35, 0.7), root.CFrame * CFrame.new(3.3, 0.95, -1.8), Enum.Material.Metal, DARK_STEEL, car)
    weldParts(root, mirR)

    -- 4 Roues polygonales cyberpunk (Diamètre 2.2, Rayon 1.1, Bas à Y = -1.80)
    for _, offset in ipairs({ Vector3.new(-3.40, -0.7, -3.8), Vector3.new(3.40, -0.7, -3.8), Vector3.new(-3.40, -0.7, 3.8), Vector3.new(3.40, -0.7, 3.8) }) do
        local tire = Instance.new("Part")
        tire.Shape = Enum.PartType.Cylinder
        tire.Size = Vector3.new(0.9, 2.2, 2.2)
        tire.CFrame = root.CFrame * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(90))
        tire.Material = Enum.Material.Rubber
        tire.Color = BLACK_ARMOR
        tire.Anchored = false
        tire.CanCollide = false
        tire.Parent = car
        weldParts(root, tire)

        local cap = Instance.new("Part")
        cap.Shape = Enum.PartType.Cylinder
        cap.Size = Vector3.new(0.96, 1.4, 1.4)
        cap.CFrame = tire.CFrame
        cap.Material = Enum.Material.Metal
        cap.Color = DARK_STEEL
        cap.Anchored = false
        cap.CanCollide = false
        cap.Parent = car
        weldParts(root, cap)
    end

    addDetailedUndercarriage(root, car, 6.4, 11.6)
    return car
end

-- =============================================================================
-- #3 DRIFT SUPRA (Orange néon, kit carrosserie large, vitesse x1.7, 300$)
-- =============================================================================
function CarBuilder.CreateDriftSupra(): Model
    local car = Instance.new("Model")
    car.Name = "DriftSupra"

    local root = Instance.new("Part")
    root.Name = "RootPart"
    root.Size = Vector3.new(1, 1, 1)
    root.Transparency = 1
    root.CanCollide = false
    root.Anchored = true
    root.Parent = car
    car.PrimaryPart = root

    local ORANGE = Color3.fromRGB(255, 95, 0)
    local DARK_ORANGE = Color3.fromRGB(200, 70, 0)
    local CARBON = Color3.fromRGB(25, 27, 30)
    local BRONZE_WHEEL = Color3.fromRGB(175, 130, 75)

    -- Châssis large surbaissé
    local base = createPart("WideBase", Vector3.new(6.4, 1.1, 11.6), root.CFrame * CFrame.new(0, -0.25, 0), Enum.Material.SmoothPlastic, ORANGE, car)
    weldParts(root, base)
    local splitter = createPart("CarbonSplitter", Vector3.new(6.6, 0.25, 1.6), root.CFrame * CFrame.new(0, -0.75, -5.9), Enum.Material.DiamondPlate, CARBON, car)
    weldParts(root, splitter)

    -- Canards aérodynamiques latéraux avant
    local canardL = createPart("CanardL", Vector3.new(0.6, 0.25, 1.2), root.CFrame * CFrame.new(-3.7, -0.55, -5.7) * CFrame.Angles(0, math.rad(-15), math.rad(10)), Enum.Material.SmoothPlastic, CARBON, car)
    weldParts(root, canardL)
    local canardR = createPart("CanardR", Vector3.new(0.6, 0.25, 1.2), root.CFrame * CFrame.new(3.7, -0.55, -5.7) * CFrame.Angles(0, math.rad(15), math.rad(-10)), Enum.Material.SmoothPlastic, CARBON, car)
    weldParts(root, canardR)

    -- Capot galbé carbone avec sorties d'air
    local hood = createPart("CarbonHood", Vector3.new(6.2, 0.6, 4.0), root.CFrame * CFrame.new(0, 0.4, -3.7) * CFrame.Angles(math.rad(-7), 0, 0), Enum.Material.DiamondPlate, CARBON, car)
    weldParts(root, hood)

    -- Toit galbé profilé
    local roof = createPart("RoofDoubleBubble", Vector3.new(4.6, 0.35, 4.4), root.CFrame * CFrame.new(0, 1.65, 0.3), Enum.Material.SmoothPlastic, DARK_ORANGE, car)
    weldParts(root, roof)
    local windshield = createPart("Windshield", Vector3.new(4.5, 1.5, 0.25), root.CFrame * CFrame.new(0, 1.15, -1.8) * CFrame.Angles(math.rad(-34), 0, 0), Enum.Material.Glass, Color3.fromRGB(15, 18, 22), car)
    windshield.Reflectance = 0.4
    weldParts(root, windshield)

    -- Aileron GT démesuré
    local wingBlade = createPart("GTWingBlade", Vector3.new(7.2, 0.25, 1.8), root.CFrame * CFrame.new(0, 2.45, 5.5), Enum.Material.SmoothPlastic, CARBON, car)
    weldParts(root, wingBlade)
    local uprightL = createPart("UprightL", Vector3.new(0.25, 1.2, 0.8), root.CFrame * CFrame.new(-2.2, 1.85, 5.5), Enum.Material.Metal, CARBON, car)
    weldParts(root, uprightL)
    local uprightR = createPart("UprightR", Vector3.new(0.25, 1.2, 0.8), root.CFrame * CFrame.new(2.2, 1.85, 5.5), Enum.Material.Metal, CARBON, car)
    weldParts(root, uprightR)

    -- Roues larges bronze (Bas à Y = -1.75)
    for _, offset in ipairs({ Vector3.new(-3.50, -0.65, -3.7), Vector3.new(3.50, -0.65, -3.7), Vector3.new(-3.50, -0.65, 3.7), Vector3.new(3.50, -0.65, 3.7) }) do
        local tire = Instance.new("Part")
        tire.Shape = Enum.PartType.Cylinder
        tire.Size = Vector3.new(0.9, 2.2, 2.2)
        tire.CFrame = root.CFrame * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(90))
        tire.Material = Enum.Material.Rubber
        tire.Color = Color3.fromRGB(20, 20, 22)
        tire.Anchored = false
        tire.CanCollide = false
        tire.Parent = car
        weldParts(root, tire)

        local rim = Instance.new("Part")
        rim.Shape = Enum.PartType.Cylinder
        rim.Size = Vector3.new(0.96, 1.4, 1.4)
        rim.CFrame = tire.CFrame
        rim.Material = Enum.Material.Metal
        rim.Color = BRONZE_WHEEL
        rim.Anchored = false
        rim.CanCollide = false
        rim.Parent = car
        weldParts(root, rim)
    end

    -- Rétroviseurs aéro carbone
    local mirL = createPart("MirL", Vector3.new(0.65, 0.35, 0.7), root.CFrame * CFrame.new(-2.9, 0.95, -1.6), Enum.Material.SmoothPlastic, CARBON, car)
    weldParts(root, mirL)
    local mirR = createPart("MirR", Vector3.new(0.65, 0.35, 0.7), root.CFrame * CFrame.new(2.9, 0.95, -1.6), Enum.Material.SmoothPlastic, CARBON, car)
    weldParts(root, mirR)

    addDetailedUndercarriage(root, car, 6.4, 11.6)
    return car
end

-- =============================================================================
-- #4 POLICE INTERCEPTOR (Noir/blanc, bullbar, gyrophares, vitesse x2.1, 750$)
-- =============================================================================
function CarBuilder.CreatePoliceInterceptor(): Model
    local car = Instance.new("Model")
    car.Name = "PoliceInterceptor"

    local root = Instance.new("Part")
    root.Name = "RootPart"
    root.Size = Vector3.new(1, 1, 1)
    root.Transparency = 1
    root.CanCollide = false
    root.Anchored = true
    root.Parent = car
    car.PrimaryPart = root

    local BLACK = Color3.fromRGB(18, 20, 24)
    local WHITE = Color3.fromRGB(245, 248, 252)
    local STEEL = Color3.fromRGB(160, 165, 175)

    -- Carrosserie bicolore
    local base = createPart("Chassis", Vector3.new(6.4, 1.3, 11.8), root.CFrame * CFrame.new(0, -0.2, 0), Enum.Material.SmoothPlastic, BLACK, car)
    weldParts(root, base)
    local doors = createPart("WhiteDoors", Vector3.new(6.45, 1.1, 5.0), root.CFrame * CFrame.new(0, 0.05, 0.2), Enum.Material.SmoothPlastic, WHITE, car)
    weldParts(root, doors)

    -- Pare-buffle avant (PushBar)
    local bullbar = createPart("BullbarMain", Vector3.new(4.8, 1.4, 0.6), root.CFrame * CFrame.new(0, -0.1, -6.1), Enum.Material.Metal, STEEL, car)
    weldParts(root, bullbar)

    -- Toit et vitres
    local roof = createPart("Roof", Vector3.new(4.6, 0.35, 4.6), root.CFrame * CFrame.new(0, 1.85, 0.4), Enum.Material.SmoothPlastic, WHITE, car)
    weldParts(root, roof)
    local windshield = createPart("Windshield", Vector3.new(4.5, 1.6, 0.25), root.CFrame * CFrame.new(0, 1.2, -1.8) * CFrame.Angles(math.rad(-30), 0, 0), Enum.Material.Glass, Color3.fromRGB(15, 18, 22), car)
    weldParts(root, windshield)

    -- Gyrophares sur le toit (Rouge / Bleu)
    local sirenRed = createPart("Siren_Red", Vector3.new(1.8, 0.35, 0.8), root.CFrame * CFrame.new(-1.0, 2.2, 0.4), Enum.Material.Neon, Color3.fromRGB(255, 30, 30), car)
    weldParts(root, sirenRed)
    local sirenBlue = createPart("Siren_Blue", Vector3.new(1.8, 0.35, 0.8), root.CFrame * CFrame.new(1.0, 2.2, 0.4), Enum.Material.Neon, Color3.fromRGB(30, 100, 255), car)
    weldParts(root, sirenBlue)

    -- Rétroviseurs
    local mirL = createPart("MirL", Vector3.new(0.65, 0.35, 0.7), root.CFrame * CFrame.new(-2.8, 0.95, -1.6), Enum.Material.SmoothPlastic, BLACK, car)
    weldParts(root, mirL)
    local mirR = createPart("MirR", Vector3.new(0.65, 0.35, 0.7), root.CFrame * CFrame.new(2.8, 0.95, -1.6), Enum.Material.SmoothPlastic, BLACK, car)
    weldParts(root, mirR)

    -- 4 Roues police (Bas à Y = -1.80)
    for _, offset in ipairs({ Vector3.new(-3.45, -0.7, -3.8), Vector3.new(3.45, -0.7, -3.8), Vector3.new(-3.45, -0.7, 3.8), Vector3.new(3.45, -0.7, 3.8) }) do
        local tire = Instance.new("Part")
        tire.Shape = Enum.PartType.Cylinder
        tire.Size = Vector3.new(0.9, 2.2, 2.2)
        tire.CFrame = root.CFrame * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(90))
        tire.Material = Enum.Material.Rubber
        tire.Color = Color3.fromRGB(20, 20, 22)
        tire.Anchored = false
        tire.CanCollide = false
        tire.Parent = car
        weldParts(root, tire)

        local cap = Instance.new("Part")
        cap.Shape = Enum.PartType.Cylinder
        cap.Size = Vector3.new(0.96, 1.4, 1.4)
        cap.CFrame = tire.CFrame
        cap.Material = Enum.Material.Metal
        cap.Color = STEEL
        cap.Anchored = false
        cap.CanCollide = false
        cap.Parent = car
        weldParts(root, cap)
    end

    addDetailedUndercarriage(root, car, 6.4, 11.8)
    return car
end

-- =============================================================================
-- #5 HYPERION JETCAR (Hypercar dorée/carbone, réacteurs cyan, vitesse x2.7, 2000$)
-- =============================================================================
function CarBuilder.CreateHyperionJetCar(): Model
    local car = Instance.new("Model")
    car.Name = "HyperionJetCar"

    local root = Instance.new("Part")
    root.Name = "RootPart"
    root.Size = Vector3.new(1, 1, 1)
    root.Transparency = 1
    root.CanCollide = false
    root.Anchored = true
    root.Parent = car
    car.PrimaryPart = root

    local GOLD = Color3.fromRGB(245, 195, 45)
    local DARK_CARBON = Color3.fromRGB(18, 20, 24)
    local JET_CYAN = Color3.fromRGB(0, 245, 255)

    -- Fuselage en flèche
    local body = createPart("Fuselage", Vector3.new(6.4, 1.0, 12.4), root.CFrame * CFrame.new(0, -0.25, 0), Enum.Material.Metal, GOLD, car)
    weldParts(root, body)
    local nose = createPart("AeroNose", Vector3.new(4.2, 0.45, 2.4), root.CFrame * CFrame.new(0, -0.45, -6.4), Enum.Material.DiamondPlate, DARK_CARBON, car)
    weldParts(root, nose)

    -- Verrière cockpit type avion de chasse
    local canopy = createPart("Canopy", Vector3.new(3.2, 1.4, 4.4), root.CFrame * CFrame.new(0, 0.85, -0.4) * CFrame.Angles(math.rad(-15), 0, 0), Enum.Material.Glass, Color3.fromRGB(10, 15, 20), car)
    canopy.Reflectance = 0.5
    weldParts(root, canopy)

    -- Dérive dorsale centrale
    local fin = createPart("DorsalFin", Vector3.new(0.3, 1.3, 3.4), root.CFrame * CFrame.new(0, 1.95, 2.2), Enum.Material.SmoothPlastic, DARK_CARBON, car)
    weldParts(root, fin)

    -- Tuyères de réacteur arrière avec plasma cyan
    for _, xOff in ipairs({ -1.8, 1.8 }) do
        local jetHousing = Instance.new("Part")
        jetHousing.Name = "JetHousing"
        jetHousing.Shape = Enum.PartType.Cylinder
        jetHousing.Size = Vector3.new(1.8, 1.5, 1.5)
        jetHousing.CFrame = root.CFrame * CFrame.new(xOff, 0.35, 6.0) * CFrame.Angles(0, math.rad(90), 0)
        jetHousing.Material = Enum.Material.Metal
        jetHousing.Color = DARK_CARBON
        jetHousing.Anchored = false
        jetHousing.CanCollide = false
        jetHousing.Parent = car
        weldParts(root, jetHousing)

        local plasma = Instance.new("Part")
        plasma.Name = "JetFlame"
        plasma.Shape = Enum.PartType.Cylinder
        plasma.Size = Vector3.new(0.4, 1.1, 1.1)
        plasma.CFrame = root.CFrame * CFrame.new(xOff, 0.35, 6.9) * CFrame.Angles(0, math.rad(90), 0)
        plasma.Material = Enum.Material.Neon
        plasma.Color = JET_CYAN
        plasma.Anchored = false
        plasma.CanCollide = false
        plasma.Parent = car
        weldParts(root, plasma)
    end

    -- 4 Roues aéro (Bas à Y = -1.65)
    for _, offset in ipairs({ Vector3.new(-3.40, -0.65, -3.8), Vector3.new(3.40, -0.65, -3.8), Vector3.new(-3.40, -0.65, 3.8), Vector3.new(3.40, -0.65, 3.8) }) do
        local tire = Instance.new("Part")
        tire.Shape = Enum.PartType.Cylinder
        tire.Size = Vector3.new(0.9, 2.0, 2.0)
        tire.CFrame = root.CFrame * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(90))
        tire.Material = Enum.Material.Rubber
        tire.Color = DARK_CARBON
        tire.Anchored = false
        tire.CanCollide = false
        tire.Parent = car
        weldParts(root, tire)
    end

    addDetailedUndercarriage(root, car, 6.4, 12.4)
    return car
end

-- =============================================================================
-- REGISTRE DES 5 VÉHICULES AVEC LEUR CONTOUR EXTÉRIEUR UNIQUE (BOUCLE FERMÉE)
-- =============================================================================
CarBuilder.Vehicles = {
    {
        Id = "lotus_rally",
        Index = 1,
        Name = "#1 Lotus Rally",
        SpeedMultiplier = 1.0,
        RewardCash = 50,
        FrontZ = -6.6,
        OuterContour = {
            {  0.00, -0.88 }, -- Bas du splitter central
            { -3.00, -0.88 }, -- Intérieur pneu avant G
            { -3.45, -1.80 }, -- Bas du pneu G
            { -3.90, -1.80 }, -- Coin bas extérieur pneu G
            { -3.90, -0.20 }, -- Flanc extérieur pneu G
            { -3.45,  0.45 }, -- Jonction aile G
            { -3.20,  0.80 }, -- Bord supérieur aile / capot G
            { -3.05,  0.90 }, -- Base rétroviseur G
            { -3.15,  1.15 }, -- Pointe rétroviseur G
            { -2.50,  1.20 }, -- Montant pare-brise G
            { -3.25,  1.95 }, -- Bas dérive aileron arrière G
            { -3.25,  2.35 }, -- Haut dérive aileron arrière G
            { -2.40,  2.05 }, -- Bord gauche toit
            { -0.80,  2.40 }, -- Prise d'air toit G
            {  0.00,  2.42 }, -- Sommet prise d'air toit
            {  0.80,  2.40 }, -- Prise d'air toit D
            {  2.40,  2.05 }, -- Bord droit toit
            {  3.25,  2.35 }, -- Haut dérive aileron arrière D
            {  3.25,  1.95 }, -- Bas dérive aileron arrière D
            {  2.50,  1.20 }, -- Montant pare-brise D
            {  3.15,  1.15 }, -- Pointe rétroviseur D
            {  3.05,  0.90 }, -- Base rétroviseur D
            {  3.20,  0.80 }, -- Bord supérieur aile / capot D
            {  3.45,  0.45 }, -- Jonction aile D
            {  3.90, -0.20 }, -- Flanc extérieur pneu D
            {  3.90, -1.80 }, -- Coin bas extérieur pneu D
            {  3.45, -1.80 }, -- Bas du pneu D
            {  3.00, -0.88 }, -- Intérieur pneu avant D
        },
        Builder = CarBuilder.CreateLotusRally,
    },
    {
        Id = "cyber_truck",
        Index = 2,
        Name = "#2 Cyber Truck",
        SpeedMultiplier = 1.35,
        RewardCash = 120,
        FrontZ = -6.2,
        OuterContour = {
            {  0.00, -0.75 }, -- Garde au sol centrale
            { -2.95, -0.75 }, -- Intérieur pneu G
            { -3.40, -1.80 }, -- Bas pneu G
            { -3.85, -1.80 }, -- Coin bas extérieur pneu G
            { -3.85, -0.30 }, -- Flanc extérieur pneu G
            { -3.45,  0.40 }, -- Arche de roue angulaire G
            { -3.25,  0.55 }, -- Coin lightbar G
            { -3.65,  0.95 }, -- Pointe rétroviseur angulaire G
            { -3.10,  1.05 }, -- Base rétroviseur G
            { -1.40,  2.05 }, -- Sommet pyramide toit G
            {  0.00,  2.08 }, -- Crête centrale toit
            {  1.40,  2.05 }, -- Sommet pyramide toit D
            {  3.10,  1.05 }, -- Base rétroviseur D
            {  3.65,  0.95 }, -- Pointe rétroviseur angulaire D
            {  3.25,  0.55 }, -- Coin lightbar D
            {  3.45,  0.40 }, -- Arche de roue angulaire D
            {  3.85, -0.30 }, -- Flanc extérieur pneu D
            {  3.85, -1.80 }, -- Coin bas extérieur pneu D
            {  3.40, -1.80 }, -- Bas pneu D
            {  2.95, -0.75 }, -- Intérieur pneu D
        },
        Builder = CarBuilder.CreateCyberTruck,
    },
    {
        Id = "drift_supra",
        Index = 3,
        Name = "#3 Drift Supra",
        SpeedMultiplier = 1.7,
        RewardCash = 300,
        FrontZ = -6.6,
        OuterContour = {
            {  0.00, -0.85 }, -- Centre splitter
            { -3.05, -0.85 }, -- Intérieur pneu G
            { -3.50, -1.75 }, -- Bas pneu G
            { -3.95, -1.75 }, -- Coin bas pneu G
            { -4.05, -0.55 }, -- Canard aéro avant G
            { -3.80,  0.40 }, -- Élargisseur aile large G
            { -3.25,  0.95 }, -- Rétroviseur carbone G
            { -2.25,  1.20 }, -- Montant pare-brise G
            { -3.60,  1.90 }, -- Embase aileron GT G
            { -3.65,  2.45 }, -- Dérive haute aileron GT G
            { -2.00,  2.45 }, -- Lame aileron GT G
            { -1.80,  1.80 }, -- Double bossage toit G
            {  0.00,  1.75 }, -- Creux central toit
            {  1.80,  1.80 }, -- Double bossage toit D
            {  2.00,  2.45 }, -- Lame aileron GT D
            {  3.65,  2.45 }, -- Dérive haute aileron GT D
            {  3.60,  1.90 }, -- Embase aileron GT D
            {  2.25,  1.20 }, -- Montant pare-brise D
            {  3.25,  0.95 }, -- Rétroviseur carbone D
            {  3.80,  0.40 }, -- Élargisseur aile large D
            {  4.05, -0.55 }, -- Canard aéro avant D
            {  3.95, -1.75 }, -- Coin bas pneu D
            {  3.50, -1.75 }, -- Bas pneu D
            {  3.05, -0.85 }, -- Intérieur pneu D
        },
        Builder = CarBuilder.CreateDriftSupra,
    },
    {
        Id = "police_interceptor",
        Index = 4,
        Name = "#4 Police Interceptor",
        SpeedMultiplier = 2.1,
        RewardCash = 750,
        FrontZ = -6.8,
        OuterContour = {
            {  0.00, -0.80 }, -- Bas bullbar central
            { -2.40, -0.80 }, -- Coin bas bullbar G
            { -3.00, -0.80 }, -- Intérieur pneu G
            { -3.45, -1.80 }, -- Bas pneu G
            { -3.90, -1.80 }, -- Coin extérieur pneu G
            { -3.90, -0.20 }, -- Flanc extérieur pneu G
            { -3.50,  0.50 }, -- Aile avant G
            { -2.40,  0.60 }, -- Sommet bullbar G
            { -3.30,  1.05 }, -- Rétroviseur & spot recherche G
            { -2.35,  1.25 }, -- Montant pare-brise G
            { -2.30,  1.95 }, -- Bord toit G
            { -1.90,  2.35 }, -- Sommet gyrophare G
            {  0.00,  2.35 }, -- Centre rampe gyrophare
            {  1.90,  2.35 }, -- Sommet gyrophare D
            {  2.30,  1.95 }, -- Bord toit D
            {  2.35,  1.25 }, -- Montant pare-brise D
            {  3.30,  1.05 }, -- Rétroviseur & spot recherche D
            {  2.40,  0.60 }, -- Sommet bullbar D
            {  3.50,  0.50 }, -- Aile avant D
            {  3.90, -0.20 }, -- Flanc extérieur pneu D
            {  3.90, -1.80 }, -- Coin extérieur pneu D
            {  3.45, -1.80 }, -- Bas pneu D
            {  3.00, -0.80 }, -- Intérieur pneu D
            {  2.40, -0.80 }, -- Coin bas bullbar D
        },
        Builder = CarBuilder.CreatePoliceInterceptor,
    },
    {
        Id = "hyperion_jetcar",
        Index = 5,
        Name = "#5 Hyperion JetCar",
        SpeedMultiplier = 2.7,
        RewardCash = 2000,
        FrontZ = -7.2,
        OuterContour = {
            {  0.00, -0.85 }, -- Pointe avant basse
            { -2.90, -0.85 }, -- Intérieur roue G
            { -3.40, -1.65 }, -- Bas roue G
            { -3.85, -1.65 }, -- Coin bas roue G
            { -4.10, -0.40 }, -- Aileron canard supersonique G
            { -3.50,  0.30 }, -- Écope latérale G
            { -2.80,  1.10 }, -- Nacelle réacteur jet G
            { -1.80,  1.20 }, -- Base verrière bulle G
            { -1.40,  1.75 }, -- Épaulement verrière G
            { -0.20,  2.10 }, -- Base aileron dorsal G
            {  0.00,  2.65 }, -- Crête dérive dorsale fusée
            {  0.20,  2.10 }, -- Base aileron dorsal D
            {  1.40,  1.75 }, -- Épaulement verrière D
            {  1.80,  1.20 }, -- Base verrière bulle D
            {  2.80,  1.10 }, -- Nacelle réacteur jet D
            {  3.50,  0.30 }, -- Écope latérale D
            {  4.10, -0.40 }, -- Aileron canard supersonique D
            {  3.85, -1.65 }, -- Coin bas roue D
            {  3.40, -1.65 }, -- Bas roue D
            {  2.90, -0.85 }, -- Intérieur roue D
        },
        Builder = CarBuilder.CreateHyperionJetCar,
    },
}

-- Récupère la config d'un véhicule par ID ou Index
function CarBuilder.GetVehicleConfig(idOrIndex: any): VehicleConfig
    if type(idOrIndex) == "number" then
        return CarBuilder.Vehicles[math.clamp(idOrIndex, 1, #CarBuilder.Vehicles)]
    end
    for _, cfg in ipairs(CarBuilder.Vehicles) do
        if cfg.Id == idOrIndex then
            return cfg
        end
    end
    return CarBuilder.Vehicles[1]
end

-- =============================================================================
-- CRÉATION DU TARGETFRAME : BOUCLE FERMÉE UNIQUE SANS LIGNES INTERNES
-- Calée directement sur la silhouette extérieure réelle du véhicule
-- =============================================================================
function CarBuilder.CreateTargetFrame(idOrIndex: any, centerPos: Vector3, param3: any?, param4: any?): Model
    local cfg = CarBuilder.GetVehicleConfig(idOrIndex)

    -- Nettoyage de tout ancien TargetFrame existant
    local oldFrame = workspace:FindFirstChild("TargetFrame")
    if oldFrame then
        oldFrame:Destroy()
    end

    local frameModel = Instance.new("Model")
    frameModel.Name = "TargetFrame"
    frameModel.Parent = workspace

    -- Orientation standard alignée avec la descente de la colline
    local slopeVector = Vector3.new(0, 120, 400)
    local uDir = slopeVector.Unit
    local rightVec = Vector3.new(1, 0, 0)
    local normalVec = uDir:Cross(rightVec)
    local downhillDir = -uDir

    local targetCF = CFrame.lookAt(centerPos, centerPos + downhillDir, normalVec)

    local NEON_GREEN = Color3.fromRGB(0, 255, 60)
    local BAR_THICKNESS = 0.14

    -- 1. Repère invisible CenterPoint exactement au centre cible
    local centerPoint = Instance.new("Part")
    centerPoint.Name = "CenterPoint"
    centerPoint.Size = Vector3.new(1, 1, 1)
    centerPoint.CFrame = targetCF
    centerPoint.Transparency = 1
    centerPoint.Anchored = true
    centerPoint.CanCollide = false
    centerPoint.Parent = frameModel
    frameModel.PrimaryPart = centerPoint

    local pointLight = Instance.new("PointLight")
    pointLight.Name = "FrameLight"
    pointLight.Color = NEON_GREEN
    pointLight.Brightness = 3.0
    pointLight.Range = 26
    pointLight.Parent = centerPoint

    -- 2. Plan du contour placé 0.15 stud devant le nez de la voiture
    -- Cela empêche toute barre de traverser la carrosserie lorsque la voiture est figée à l'arrêt
    local contourCF = targetCF * CFrame.new(0, 0, cfg.FrontZ - 0.15)

    -- 3. Construction de la boucle fermée extérieure UNIQUE (aucun clone fantôme, aucune ligne interne)
    local pts = cfg.OuterContour
    local count = #pts

    for i = 1, count do
        local pA = pts[i]
        local nextIdx = (i % count) + 1
        local pB = pts[nextIdx]

        -- Conversion des coordonnées 2D (X, Y) du contour dans l'espace 3D du plan frontal
        local wA = contourCF:PointToWorldSpace(Vector3.new(pA[1], pA[2], 0))
        local wB = contourCF:PointToWorldSpace(Vector3.new(pB[1], pB[2], 0))

        local segVec = wB - wA
        local segLen = segVec.Magnitude
        local segMid = (wA + wB) / 2

        if segLen > 0.02 then
            local bar = Instance.new("Part")
            bar.Name = string.format("Outline_%02d", i)
            bar.Size = Vector3.new(BAR_THICKNESS, BAR_THICKNESS, segLen)
            bar.CFrame = CFrame.lookAt(segMid, segMid + segVec.Unit)
            bar.Material = Enum.Material.Neon
            bar.Color = NEON_GREEN
            bar.Anchored = true
            bar.CanCollide = false
            bar.CastShadow = false
            bar.Parent = frameModel
        end
    end

    print(string.format("[CarBuilder] TargetFrame boucle fermée extérieure créée pour %s (%d segments)", cfg.Name, count))
    return frameModel
end

return CarBuilder
