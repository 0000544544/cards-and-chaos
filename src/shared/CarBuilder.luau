--!strict
--[[
    STOP AT THE FRAME - CAR BUILDER & TARGET FRAME GENERATOR (MODULE SCRIPT)
    GÃ©nÃ¨re procÃ©duralement les 5 vÃ©hicules avec soubassement noir dÃ©taillÃ©,
    et gÃ©nÃ¨re le TargetFrame : un seul polygone fermÃ© continu en fines barres Neon vertes (0.14)
    dÃ©limitant exclusivement le contour extÃ©rieur (vide Ã  l'intÃ©rieur, aucun clone fantÃ´me, aucune ligne interne).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarBuilder = {}

export type ContourPoint = { number } -- { X, Y, Z } en coords locales du vÃ©hicule

export type VehicleConfig = {
    Id: string,
    Index: number,
    Name: string,
    SpeedMultiplier: number,
    RewardCash: number,
    FrontZ: number,
    OuterContour: { ContourPoint }?,
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

-- Ajoute un soubassement mÃ©canique noir dÃ©taillÃ© (visible quand le nez est cabrÃ©)
local function addDetailedUndercarriage(root: BasePart, car: Model, width: number, length: number)
    local UNDER_BLACK = Color3.fromRGB(15, 16, 18)
    local METAL_GRAY = Color3.fromRGB(175, 180, 188)
    local EXHAUST_HEAT = Color3.fromRGB(120, 150, 190)

    -- Plaque de protection infÃ©rieure (Skid Plate)
    local skidPlate = createPart("SkidPlate", Vector3.new(width - 0.8, 0.25, length - 1.5), root.CFrame * CFrame.new(0, -0.9, 0), Enum.Material.DiamondPlate, UNDER_BLACK, car)
    weldParts(root, skidPlate)

    -- Carter de transmission & boÃ®te centrale
    local transmission = createPart("GearboxPan", Vector3.new(2.0, 0.4, 3.0), root.CFrame * CFrame.new(0, -0.95, -0.4), Enum.Material.Metal, METAL_GRAY, car)
    weldParts(root, transmission)

    -- Double ligne d'Ã©chappement inox
    local exhaustL = createPart("ExhaustPipe_L", Vector3.new(0.35, 0.35, length - 3.2), root.CFrame * CFrame.new(-1.2, -0.92, 0.8), Enum.Material.Metal, EXHAUST_HEAT, car)
    weldParts(root, exhaustL)
    local exhaustR = createPart("ExhaustPipe_R", Vector3.new(0.35, 0.35, length - 3.2), root.CFrame * CFrame.new(1.2, -0.92, 0.8), Enum.Material.Metal, EXHAUST_HEAT, car)
    weldParts(root, exhaustR)

    -- Embouts d'Ã©chappement chromÃ©s Ã  l'arriÃ¨re
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

    -- Essieux de suspension avant et arriÃ¨re
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

    -- 4 Roues droites debout (axe X, sans rotation Z) â€” flanc externe Ã  X=Â±3.05, sous carrosserie Â±3.20
    local wheelOffsets = {
        Vector3.new(-2.55, -0.95, -3.8), Vector3.new(2.55, -0.95, -3.8), -- Avant
        Vector3.new(-2.55, -0.95,  3.8), Vector3.new(2.55, -0.95,  3.8), -- ArriÃ¨re
    }
    for _, offset in ipairs(wheelOffsets) do
        local tire = Instance.new("Part")
        tire.Shape = Enum.PartType.Cylinder
        tire.Size = Vector3.new(1.0, 2.1, 2.1)
        tire.CFrame = root.CFrame * CFrame.new(offset)
        tire.Material = Enum.Material.Rubber
        tire.Color = Color3.fromRGB(20, 20, 22)
        tire.Anchored = false
        tire.CanCollide = false
        tire.Parent = car
        weldParts(root, tire)

        local rim = Instance.new("Part")
        rim.Shape = Enum.PartType.Cylinder
        rim.Size = Vector3.new(1.05, 1.3, 1.3)
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

    -- RÃ©troviseurs
    local mirL = createPart("MirrorL", Vector3.new(0.7, 0.35, 0.8), root.CFrame * CFrame.new(-2.7, 0.95, -1.6), Enum.Material.SmoothPlastic, CHARCOAL, car)
    weldParts(root, mirL)
    local mirR = createPart("MirrorR", Vector3.new(0.7, 0.35, 0.8), root.CFrame * CFrame.new(2.7, 0.95, -1.6), Enum.Material.SmoothPlastic, CHARCOAL, car)
    weldParts(root, mirR)

    addDetailedUndercarriage(root, car, 6.4, 11.6)
    return car
end

-- =============================================================================
-- #2 CYBER TRUCK (Pick-up futuriste acier brossÃ©, vitesse x1.35, 120$)
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

    -- ChÃ¢ssis principal profilÃ© (Largeur 6.4, Hauteur 1.2, Longueur 11.6)
    local lower = createPart("LowerArmor", Vector3.new(6.4, 1.2, 11.6), root.CFrame * CFrame.new(0, -0.2, 0), Enum.Material.Metal, STEEL, car)
    weldParts(root, lower)

    -- Toit triangulaire pyramidale emblÃ©matique
    local roofFront = createPart("RoofFrontSlope", Vector3.new(5.8, 0.45, 5.8), root.CFrame * CFrame.new(0, 1.25, -2.4) * CFrame.Angles(math.rad(-21), 0, 0), Enum.Material.Metal, STEEL, car)
    weldParts(root, roofFront)

    local roofBack = createPart("RoofBackSlope", Vector3.new(5.8, 0.45, 6.0), root.CFrame * CFrame.new(0, 1.25, 2.9) * CFrame.Angles(math.rad(19), 0, 0), Enum.Material.Metal, STEEL, car)
    weldParts(root, roofBack)

    -- CrÃªte supÃ©rieure du toit
    local roofPeak = createPart("RoofPeakBar", Vector3.new(2.8, 0.35, 1.2), root.CFrame * CFrame.new(0, 2.05, 0.2), Enum.Material.Metal, STEEL, car)
    weldParts(root, roofPeak)

    -- Pare-brise angulaire blindÃ© teintÃ©
    local glass = createPart("ArmorWindshield", Vector3.new(5.4, 1.6, 0.25), root.CFrame * CFrame.new(0, 1.2, -2.3) * CFrame.Angles(math.rad(-25), 0, 0), Enum.Material.Glass, BLACK_ARMOR, car)
    glass.Reflectance = 0.4
    weldParts(root, glass)

    -- Lightbar avant continue nÃ©on cyan (Pleine largeur 6.2 studs)
    local lightbar = createPart("FrontLightbar", Vector3.new(6.2, 0.28, 0.2), root.CFrame * CFrame.new(0, 0.45, -5.85), Enum.Material.Neon, CYBER_CYAN, car)
    weldParts(root, lightbar)

    -- Lightbar arriÃ¨re rouge
    local rearLight = createPart("RearLightbar", Vector3.new(6.2, 0.28, 0.2), root.CFrame * CFrame.new(0, 0.55, 5.85), Enum.Material.Neon, Color3.fromRGB(255, 30, 30), car)
    weldParts(root, rearLight)

    -- RÃ©troviseurs angulaires compacts
    local mirL = createPart("CyberMirrorL", Vector3.new(0.65, 0.35, 0.7), root.CFrame * CFrame.new(-3.3, 0.95, -1.8), Enum.Material.Metal, DARK_STEEL, car)
    weldParts(root, mirL)
    local mirR = createPart("CyberMirrorR", Vector3.new(0.65, 0.35, 0.7), root.CFrame * CFrame.new(3.3, 0.95, -1.8), Enum.Material.Metal, DARK_STEEL, car)
    weldParts(root, mirR)

    -- 4 Roues droites debout (axe X, sans rotation Z) â€” flanc externe Ã  X=Â±3.05, sous carrosserie Â±3.20
    local wheelOffsets = {
        Vector3.new(-2.55, -0.95, -3.8), Vector3.new(2.55, -0.95, -3.8),
        Vector3.new(-2.55, -0.95,  3.8), Vector3.new(2.55, -0.95,  3.8),
    }
    for _, offset in ipairs(wheelOffsets) do
        local tire = Instance.new("Part")
        tire.Shape = Enum.PartType.Cylinder
        tire.Size = Vector3.new(1.0, 2.1, 2.1)
        tire.CFrame = root.CFrame * CFrame.new(offset)
        tire.Material = Enum.Material.Rubber
        tire.Color = BLACK_ARMOR
        tire.Anchored = false
        tire.CanCollide = false
        tire.Parent = car
        weldParts(root, tire)

        local cap = Instance.new("Part")
        cap.Shape = Enum.PartType.Cylinder
        cap.Size = Vector3.new(1.05, 1.3, 1.3)
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
-- #3 DRIFT SUPRA (Orange nÃ©on, kit carrosserie large, vitesse x1.7, 300$)
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

    -- ChÃ¢ssis large surbaissÃ©
    local base = createPart("WideBase", Vector3.new(6.4, 1.1, 11.6), root.CFrame * CFrame.new(0, -0.25, 0), Enum.Material.SmoothPlastic, ORANGE, car)
    weldParts(root, base)
    local splitter = createPart("CarbonSplitter", Vector3.new(6.6, 0.25, 1.6), root.CFrame * CFrame.new(0, -0.75, -5.9), Enum.Material.DiamondPlate, CARBON, car)
    weldParts(root, splitter)

    -- Canards aÃ©rodynamiques latÃ©raux avant
    local canardL = createPart("CanardL", Vector3.new(0.6, 0.25, 1.2), root.CFrame * CFrame.new(-3.7, -0.55, -5.7) * CFrame.Angles(0, math.rad(-15), math.rad(10)), Enum.Material.SmoothPlastic, CARBON, car)
    weldParts(root, canardL)
    local canardR = createPart("CanardR", Vector3.new(0.6, 0.25, 1.2), root.CFrame * CFrame.new(3.7, -0.55, -5.7) * CFrame.Angles(0, math.rad(15), math.rad(-10)), Enum.Material.SmoothPlastic, CARBON, car)
    weldParts(root, canardR)

    -- Capot galbÃ© carbone avec sorties d'air
    local hood = createPart("CarbonHood", Vector3.new(6.2, 0.6, 4.0), root.CFrame * CFrame.new(0, 0.4, -3.7) * CFrame.Angles(math.rad(-7), 0, 0), Enum.Material.DiamondPlate, CARBON, car)
    weldParts(root, hood)

    -- Toit galbÃ© profilÃ©
    local roof = createPart("RoofDoubleBubble", Vector3.new(4.6, 0.35, 4.4), root.CFrame * CFrame.new(0, 1.65, 0.3), Enum.Material.SmoothPlastic, DARK_ORANGE, car)
    weldParts(root, roof)
    local windshield = createPart("Windshield", Vector3.new(4.5, 1.5, 0.25), root.CFrame * CFrame.new(0, 1.15, -1.8) * CFrame.Angles(math.rad(-34), 0, 0), Enum.Material.Glass, Color3.fromRGB(15, 18, 22), car)
    windshield.Reflectance = 0.4
    weldParts(root, windshield)

    -- Aileron GT dÃ©mesurÃ©
    local wingBlade = createPart("GTWingBlade", Vector3.new(7.2, 0.25, 1.8), root.CFrame * CFrame.new(0, 2.45, 5.5), Enum.Material.SmoothPlastic, CARBON, car)
    weldParts(root, wingBlade)
    local uprightL = createPart("UprightL", Vector3.new(0.25, 1.2, 0.8), root.CFrame * CFrame.new(-2.2, 1.85, 5.5), Enum.Material.Metal, CARBON, car)
    weldParts(root, uprightL)
    local uprightR = createPart("UprightR", Vector3.new(0.25, 1.2, 0.8), root.CFrame * CFrame.new(2.2, 1.85, 5.5), Enum.Material.Metal, CARBON, car)
    weldParts(root, uprightR)

    -- Roues larges bronze droites debout (sans rotation Z)
    local wheelOffsets = {
        Vector3.new(-2.55, -0.95, -3.8), Vector3.new(2.55, -0.95, -3.8),
        Vector3.new(-2.55, -0.95,  3.8), Vector3.new(2.55, -0.95,  3.8),
    }
    for _, offset in ipairs(wheelOffsets) do
        local tire = Instance.new("Part")
        tire.Shape = Enum.PartType.Cylinder
        tire.Size = Vector3.new(1.0, 2.1, 2.1)
        tire.CFrame = root.CFrame * CFrame.new(offset)
        tire.Material = Enum.Material.Rubber
        tire.Color = Color3.fromRGB(20, 20, 22)
        tire.Anchored = false
        tire.CanCollide = false
        tire.Parent = car
        weldParts(root, tire)

        local rim = Instance.new("Part")
        rim.Shape = Enum.PartType.Cylinder
        rim.Size = Vector3.new(1.05, 1.3, 1.3)
        rim.CFrame = tire.CFrame
        rim.Material = Enum.Material.Metal
        rim.Color = BRONZE_WHEEL
        rim.Anchored = false
        rim.CanCollide = false
        rim.Parent = car
        weldParts(root, rim)
    end

    -- RÃ©troviseurs aÃ©ro carbone
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

    -- RÃ©troviseurs
    local mirL = createPart("MirL", Vector3.new(0.65, 0.35, 0.7), root.CFrame * CFrame.new(-2.8, 0.95, -1.6), Enum.Material.SmoothPlastic, BLACK, car)
    weldParts(root, mirL)
    local mirR = createPart("MirR", Vector3.new(0.65, 0.35, 0.7), root.CFrame * CFrame.new(2.8, 0.95, -1.6), Enum.Material.SmoothPlastic, BLACK, car)
    weldParts(root, mirR)

    -- 4 Roues police droites debout (sans rotation Z)
    local wheelOffsets = {
        Vector3.new(-2.55, -0.95, -3.8), Vector3.new(2.55, -0.95, -3.8),
        Vector3.new(-2.55, -0.95,  3.8), Vector3.new(2.55, -0.95,  3.8),
    }
    for _, offset in ipairs(wheelOffsets) do
        local tire = Instance.new("Part")
        tire.Shape = Enum.PartType.Cylinder
        tire.Size = Vector3.new(1.0, 2.1, 2.1)
        tire.CFrame = root.CFrame * CFrame.new(offset)
        tire.Material = Enum.Material.Rubber
        tire.Color = Color3.fromRGB(20, 20, 22)
        tire.Anchored = false
        tire.CanCollide = false
        tire.Parent = car
        weldParts(root, tire)

        local cap = Instance.new("Part")
        cap.Shape = Enum.PartType.Cylinder
        cap.Size = Vector3.new(1.05, 1.3, 1.3)
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
-- #5 HYPERION JETCAR (Hypercar dorÃ©e/carbone, rÃ©acteurs cyan, vitesse x2.7, 2000$)
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

    -- Fuselage en flÃ¨che
    local body = createPart("Fuselage", Vector3.new(6.4, 1.0, 12.4), root.CFrame * CFrame.new(0, -0.25, 0), Enum.Material.Metal, GOLD, car)
    weldParts(root, body)
    local nose = createPart("AeroNose", Vector3.new(4.2, 0.45, 2.4), root.CFrame * CFrame.new(0, -0.45, -6.4), Enum.Material.DiamondPlate, DARK_CARBON, car)
    weldParts(root, nose)

    -- VerriÃ¨re cockpit type avion de chasse
    local canopy = createPart("Canopy", Vector3.new(3.2, 1.4, 4.4), root.CFrame * CFrame.new(0, 0.85, -0.4) * CFrame.Angles(math.rad(-15), 0, 0), Enum.Material.Glass, Color3.fromRGB(10, 15, 20), car)
    canopy.Reflectance = 0.5
    weldParts(root, canopy)

    -- DÃ©rive dorsale centrale
    local fin = createPart("DorsalFin", Vector3.new(0.3, 1.3, 3.4), root.CFrame * CFrame.new(0, 1.95, 2.2), Enum.Material.SmoothPlastic, DARK_CARBON, car)
    weldParts(root, fin)

    -- TuyÃ¨res de rÃ©acteur arriÃ¨re avec plasma cyan
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

    -- 4 Roues aÃ©ro droites debout (sans rotation Z)
    local wheelOffsets = {
        Vector3.new(-2.55, -0.95, -3.8), Vector3.new(2.55, -0.95, -3.8),
        Vector3.new(-2.55, -0.95,  3.8), Vector3.new(2.55, -0.95,  3.8),
    }
    for _, offset in ipairs(wheelOffsets) do
        local tire = Instance.new("Part")
        tire.Shape = Enum.PartType.Cylinder
        tire.Size = Vector3.new(1.0, 2.1, 2.1)
        tire.CFrame = root.CFrame * CFrame.new(offset)
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
-- #6 FLASH MCQUEEN ⚡ (MODÈLE IMPORTÉ AUTO-CALIBRÉ OU NASCAR CURVÉ DÉTAILLÉ)
-- =============================================================================
function CarBuilder.CreateFlashMcQueen(): Model
    -- 1. Recherche d'un modèle template importé (via src/shared/FlashMcQueen.rbxm ou ReplicatedStorage)
    local template: Instance? = nil
    local importedFolder = ReplicatedStorage:FindFirstChild("ImportedVehicles")
    if importedFolder then
        template = importedFolder:FindFirstChild("FlashMcQueen")
    end
    if not template then
        template = ReplicatedStorage:FindFirstChild("FlashMcQueen")
    end

    if template and template:IsA("Model") then
        local car = template:Clone()
        car.Name = "FlashMcQueen"

        -- Nettoyage de tout script, siège ou son parasite provenant de la Toolbox
        for _, desc in ipairs(car:GetDescendants()) do
            if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("VehicleSeat") or desc:IsA("Seat") or desc:IsA("Sound") then
                desc:Destroy()
            end
        end

        -- Calcule sa boîte englobante actuelle
        local bbCF, bbSize = car:GetBoundingBox()

        -- Si le modèle est orienté sur l'axe X au lieu de Z (longueur sur X), rotation automatique de 90°
        if bbSize.X > bbSize.Z then
            car:PivotTo(bbCF * CFrame.Angles(0, math.rad(90), 0))
            bbCF, bbSize = car:GetBoundingBox()
        end

        -- Redimensionnement automatique pour que sa largeur (X) fasse exactement 6.2 studs
        if bbSize.X > 0.01 then
            local scaleRatio = 6.2 / bbSize.X
            car:ScaleTo(scaleRatio)
            bbCF, bbSize = car:GetBoundingBox()
        end

        -- Création d'une Part invisible "RootPart" centrée géométriquement avec le bas des roues à Y = -2.0
        local rootY = bbCF.Position.Y - (bbSize.Y / 2) + 2.0
        local rootCF = CFrame.new(bbCF.Position.X, rootY, bbCF.Position.Z)

        local root = Instance.new("Part")
        root.Name = "RootPart"
        root.Size = Vector3.new(1, 1, 1)
        root.CFrame = rootCF
        root.Transparency = 1
        root.CanCollide = false
        root.Anchored = true
        root.Parent = car

        -- Soude toutes les BaseParts au RootPart, CanCollide = false, CanQuery = true, Anchored = false
        for _, desc in ipairs(car:GetDescendants()) do
            if desc:IsA("BasePart") and desc ~= root then
                desc.Anchored = false
                desc.CanCollide = false
                desc.CanQuery = true
                weldParts(root, desc)
            end
        end

        car.PrimaryPart = root
        addDetailedUndercarriage(root, car, 6.2, math.max(bbSize.Z, 11.5))
        return car
    end

    -- 2. NASCAR stock-car procédural courbé & aérodynamique (si aucun .rbxm présent)
    local car = Instance.new("Model")
    car.Name = "FlashMcQueen"

    local root = Instance.new("Part")
    root.Name = "RootPart"
    root.Size = Vector3.new(1, 1, 1)
    root.Transparency = 1
    root.CanCollide = false
    root.Anchored = true
    root.Parent = car
    car.PrimaryPart = root

    local MCQUEEN_RED  = Color3.fromRGB(230, 20, 25)
    local DARK_RED     = Color3.fromRGB(165, 12, 18)
    local CARBON_BLACK = Color3.fromRGB(20, 22, 25)
    local GOLD         = Color3.fromRGB(255, 215, 0)
    local ORANGE       = Color3.fromRGB(255, 115, 0)
    local WHITE_GLASS  = Color3.fromRGB(230, 240, 250)
    local EYE_BLUE     = Color3.fromRGB(55, 130, 220)
    local PUPIL_BLACK  = Color3.fromRGB(8, 8, 12)
    local RIM_GOLD     = Color3.fromRGB(210, 175, 55)
    local HEADLIGHT    = Color3.fromRGB(255, 252, 225)

    -- Fonction d'aide pour ajouter une forme courbée avec SpecialMesh
    local function createCurvedPart(name: string, size: Vector3, cf: CFrame, meshType: Enum.MeshType, col: Color3): Part
        local p = createPart(name, size, cf, Enum.Material.SmoothPlastic, col, car)
        local sm = Instance.new("SpecialMesh")
        sm.MeshType = meshType
        sm.Parent = p
        weldParts(root, p)
        return p
    end

    -- ===== CARROSSERIE NASCAR ARRONDIE & BOMBÉE =====
    -- Châssis principal bas de caisse
    local base = createPart("Base", Vector3.new(6.4, 1.2, 12.0),
        root.CFrame * CFrame.new(0, -0.2, 0), Enum.Material.SmoothPlastic, MCQUEEN_RED, car)
    weldParts(root, base)

    -- Splitter avant carbone profilé
    local splitter = createPart("Splitter", Vector3.new(6.6, 0.3, 1.6),
        root.CFrame * CFrame.new(0, -0.72, -6.2), Enum.Material.SmoothPlastic, CARBON_BLACK, car)
    weldParts(root, splitter)

    -- Nez avant arrondi plongeant (SpecialMesh Sphere)
    createCurvedPart("FrontNoseRound", Vector3.new(6.2, 0.95, 2.6),
        root.CFrame * CFrame.new(0, -0.05, -5.5), Enum.MeshType.Sphere, MCQUEEN_RED)

    -- Capot avant plongeant incliné
    local hood = createPart("Hood", Vector3.new(6.0, 0.55, 4.2),
        root.CFrame * CFrame.new(0, 0.42, -3.5) * CFrame.Angles(math.rad(-8), 0, 0),
        Enum.Material.SmoothPlastic, MCQUEEN_RED, car)
    weldParts(root, hood)

    -- Bombe aérodynamique centrale du capot (SpecialMesh Sphere)
    createCurvedPart("HoodBulgeRound", Vector3.new(5.6, 0.70, 4.0),
        root.CFrame * CFrame.new(0, 0.48, -3.5) * CFrame.Angles(math.rad(-8), 0, 0),
        Enum.MeshType.Sphere, MCQUEEN_RED)

    -- 4 Ailes galbées bombées au-dessus des roues (SpecialMesh Sphere)
    createCurvedPart("FenderFL_Round", Vector3.new(1.35, 0.95, 3.4),
        root.CFrame * CFrame.new(-2.85, 0.22, -3.8), Enum.MeshType.Sphere, MCQUEEN_RED)
    createCurvedPart("FenderFR_Round", Vector3.new(1.35, 0.95, 3.4),
        root.CFrame * CFrame.new(2.85, 0.22, -3.8), Enum.MeshType.Sphere, MCQUEEN_RED)
    createCurvedPart("FenderRL_Round", Vector3.new(1.35, 1.05, 3.6),
        root.CFrame * CFrame.new(-2.85, 0.28, 3.8), Enum.MeshType.Sphere, MCQUEEN_RED)
    createCurvedPart("FenderRR_Round", Vector3.new(1.35, 1.05, 3.6),
        root.CFrame * CFrame.new(2.85, 0.28, 3.8), Enum.MeshType.Sphere, MCQUEEN_RED)

    -- Flancs cintrés arrondis (SpecialMesh Sphere pour courber les portières)
    createCurvedPart("SideWaistL", Vector3.new(0.65, 1.15, 7.8),
        root.CFrame * CFrame.new(-3.12, -0.15, 0.1), Enum.MeshType.Sphere, MCQUEEN_RED)
    createCurvedPart("SideWaistR", Vector3.new(0.65, 1.15, 7.8),
        root.CFrame * CFrame.new(3.12, -0.15, 0.1), Enum.MeshType.Sphere, MCQUEEN_RED)

    -- Pont arrière / coffre arrondi
    local rearDeck = createPart("RearDeck", Vector3.new(6.2, 0.85, 3.4),
        root.CFrame * CFrame.new(0, 0.50, 4.0), Enum.Material.SmoothPlastic, MCQUEEN_RED, car)
    weldParts(root, rearDeck)

    createCurvedPart("RearBumperRound", Vector3.new(6.2, 0.95, 2.0),
        root.CFrame * CFrame.new(0, 0.18, 5.7), Enum.MeshType.Sphere, MCQUEEN_RED)

    -- ===== TOIT EN DÔME BOMBÉ & VITRES NASCAR =====
    -- Dôme de toit profilé fluide (SpecialMesh Sphere)
    createCurvedPart("RoofDome", Vector3.new(4.8, 1.35, 4.6),
        root.CFrame * CFrame.new(0, 1.68, 0.35), Enum.MeshType.Sphere, MCQUEEN_RED)

    -- Toit plat de renfort
    local roof = createPart("Roof", Vector3.new(4.4, 0.35, 4.0),
        root.CFrame * CFrame.new(0, 1.88, 0.3), Enum.Material.SmoothPlastic, MCQUEEN_RED, car)
    weldParts(root, roof)

    -- Pare-brise incliné (fond blanc/clair pour les yeux)
    local windshield = createPart("Windshield", Vector3.new(4.5, 1.65, 0.2),
        root.CFrame * CFrame.new(0, 1.20, -1.9) * CFrame.Angles(math.rad(-33), 0, 0),
        Enum.Material.Glass, WHITE_GLASS, car)
    windshield.Reflectance = 0.15
    windshield.Transparency = 0.15
    weldParts(root, windshield)

    -- ===== YEUX EMBLÉMATIQUES SUR LE PARE-BRISE =====
    -- Iris gauche (bleu)
    local eyeL = createPart("EyeIrisL", Vector3.new(1.0, 0.85, 0.08),
        root.CFrame * CFrame.new(-0.85, 1.30, -2.08) * CFrame.Angles(math.rad(-33), 0, 0),
        Enum.Material.SmoothPlastic, EYE_BLUE, car)
    weldParts(root, eyeL)
    -- Pupille gauche (noire)
    local pupilL = createPart("EyePupilL", Vector3.new(0.45, 0.45, 0.09),
        root.CFrame * CFrame.new(-0.85, 1.30, -2.12) * CFrame.Angles(math.rad(-33), 0, 0),
        Enum.Material.SmoothPlastic, PUPIL_BLACK, car)
    weldParts(root, pupilL)
    -- Iris droit (bleu)
    local eyeR = createPart("EyeIrisR", Vector3.new(1.0, 0.85, 0.08),
        root.CFrame * CFrame.new(0.85, 1.30, -2.08) * CFrame.Angles(math.rad(-33), 0, 0),
        Enum.Material.SmoothPlastic, EYE_BLUE, car)
    weldParts(root, eyeR)
    -- Pupille droite (noire)
    local pupilR = createPart("EyePupilR", Vector3.new(0.45, 0.45, 0.09),
        root.CFrame * CFrame.new(0.85, 1.30, -2.12) * CFrame.Angles(math.rad(-33), 0, 0),
        Enum.Material.SmoothPlastic, PUPIL_BLACK, car)
    weldParts(root, pupilR)

    -- Lunette arrière
    local rearWin = createPart("RearWindow", Vector3.new(4.5, 1.4, 0.2),
        root.CFrame * CFrame.new(0, 1.25, 2.6) * CFrame.Angles(math.rad(30), 0, 0),
        Enum.Material.Glass, CARBON_BLACK, car)
    rearWin.Reflectance = 0.30
    weldParts(root, rearWin)

    -- ===== ÉCLAIRS LATÉRAUX "KA-CHOW" (NÉON OR + ORANGE) =====
    -- Flanc GAUCHE
    local boltL1 = createPart("BoltL1", Vector3.new(0.12, 0.55, 2.8),
        root.CFrame * CFrame.new(-3.25, 0.15, -2.0) * CFrame.Angles(0, 0, math.rad(12)),
        Enum.Material.Neon, GOLD, car)
    weldParts(root, boltL1)
    local boltL2 = createPart("BoltL2", Vector3.new(0.12, 0.50, 1.8),
        root.CFrame * CFrame.new(-3.25, 0.40, 0.4) * CFrame.Angles(0, 0, math.rad(-15)),
        Enum.Material.Neon, ORANGE, car)
    weldParts(root, boltL2)
    local boltL3 = createPart("BoltL3", Vector3.new(0.12, 0.55, 2.6),
        root.CFrame * CFrame.new(-3.25, 0.10, 2.6) * CFrame.Angles(0, 0, math.rad(10)),
        Enum.Material.Neon, GOLD, car)
    weldParts(root, boltL3)

    -- Flanc DROIT (symétrique)
    local boltR1 = createPart("BoltR1", Vector3.new(0.12, 0.55, 2.8),
        root.CFrame * CFrame.new(3.25, 0.15, -2.0) * CFrame.Angles(0, 0, math.rad(-12)),
        Enum.Material.Neon, GOLD, car)
    weldParts(root, boltR1)
    local boltR2 = createPart("BoltR2", Vector3.new(0.12, 0.50, 1.8),
        root.CFrame * CFrame.new(3.25, 0.40, 0.4) * CFrame.Angles(0, 0, math.rad(15)),
        Enum.Material.Neon, ORANGE, car)
    weldParts(root, boltR2)
    local boltR3 = createPart("BoltR3", Vector3.new(0.12, 0.55, 2.6),
        root.CFrame * CFrame.new(3.25, 0.10, 2.6) * CFrame.Angles(0, 0, math.rad(-10)),
        Enum.Material.Neon, GOLD, car)
    weldParts(root, boltR3)

    -- ===== GRAND AILERON ARRIÈRE PISTON CUP =====
    local wingStrutL = createPart("WingStrutL", Vector3.new(0.3, 1.5, 0.6),
        root.CFrame * CFrame.new(-1.8, 1.75, 5.5) * CFrame.Angles(math.rad(8), 0, 0),
        Enum.Material.SmoothPlastic, CARBON_BLACK, car)
    weldParts(root, wingStrutL)
    local wingStrutR = createPart("WingStrutR", Vector3.new(0.3, 1.5, 0.6),
        root.CFrame * CFrame.new(1.8, 1.75, 5.5) * CFrame.Angles(math.rad(8), 0, 0),
        Enum.Material.SmoothPlastic, CARBON_BLACK, car)
    weldParts(root, wingStrutR)

    local wing = createPart("RearWingSpoiler", Vector3.new(6.6, 0.25, 1.9),
        root.CFrame * CFrame.new(0, 2.55, 5.7) * CFrame.Angles(math.rad(-5), 0, 0),
        Enum.Material.SmoothPlastic, MCQUEEN_RED, car)
    weldParts(root, wing)

    local endplateL = createPart("EndplateL", Vector3.new(0.15, 0.8, 1.6),
        root.CFrame * CFrame.new(-3.35, 2.35, 5.7), Enum.Material.SmoothPlastic, DARK_RED, car)
    weldParts(root, endplateL)
    local endplateR = createPart("EndplateR", Vector3.new(0.15, 0.8, 1.6),
        root.CFrame * CFrame.new(3.35, 2.35, 5.7), Enum.Material.SmoothPlastic, DARK_RED, car)
    weldParts(root, endplateR)

    -- ===== PHARES AVANT NÉON =====
    local headL = createPart("HeadlightL", Vector3.new(1.4, 0.45, 0.2),
        root.CFrame * CFrame.new(-2.2, 0.05, -6.05), Enum.Material.Neon, HEADLIGHT, car)
    weldParts(root, headL)
    local headR = createPart("HeadlightR", Vector3.new(1.4, 0.45, 0.2),
        root.CFrame * CFrame.new(2.2, 0.05, -6.05), Enum.Material.Neon, HEADLIGHT, car)
    weldParts(root, headR)

    -- Feux arrière rouges
    local tailL = createPart("TaillightL", Vector3.new(1.2, 0.4, 0.15),
        root.CFrame * CFrame.new(-2.3, 0.35, 6.05), Enum.Material.Neon, Color3.fromRGB(255, 20, 20), car)
    weldParts(root, tailL)
    local tailR = createPart("TaillightR", Vector3.new(1.2, 0.4, 0.15),
        root.CFrame * CFrame.new(2.3, 0.35, 6.05), Enum.Material.Neon, Color3.fromRGB(255, 20, 20), car)
    weldParts(root, tailR)

    -- ===== NUMÉRO "95" =====
    local numL = createPart("Number95_L", Vector3.new(0.1, 1.1, 1.6),
        root.CFrame * CFrame.new(-3.25, 0.65, 0.0), Enum.Material.Neon, GOLD, car)
    weldParts(root, numL)
    local numR = createPart("Number95_R", Vector3.new(0.1, 1.1, 1.6),
        root.CFrame * CFrame.new(3.25, 0.65, 0.0), Enum.Material.Neon, GOLD, car)
    weldParts(root, numR)

    -- ===== 4 ROUES AVEC JANTES DORÉES =====
    local wheelOffsets = {
        Vector3.new(-2.55, -0.95, -3.8), Vector3.new(2.55, -0.95, -3.8),
        Vector3.new(-2.55, -0.95,  3.8), Vector3.new(2.55, -0.95,  3.8),
    }
    for _, offset in ipairs(wheelOffsets) do
        local tire = Instance.new("Part")
        tire.Shape = Enum.PartType.Cylinder
        tire.Size = Vector3.new(1.0, 2.1, 2.1)
        tire.CFrame = root.CFrame * CFrame.new(offset)
        tire.Material = Enum.Material.Rubber
        tire.Color = Color3.fromRGB(20, 20, 22)
        tire.Anchored = false
        tire.CanCollide = false
        tire.Parent = car
        weldParts(root, tire)

        local rim = Instance.new("Part")
        rim.Shape = Enum.PartType.Cylinder
        rim.Size = Vector3.new(1.05, 1.3, 1.3)
        rim.CFrame = tire.CFrame
        rim.Material = Enum.Material.Metal
        rim.Color = RIM_GOLD
        rim.Anchored = false
        rim.CanCollide = false
        rim.Parent = car
        weldParts(root, rim)
    end

    -- Rétroviseurs
    local mirL = createPart("MirrorL", Vector3.new(0.7, 0.35, 0.8),
        root.CFrame * CFrame.new(-2.7, 0.95, -1.5), Enum.Material.SmoothPlastic, DARK_RED, car)
    weldParts(root, mirL)
    local mirR = createPart("MirrorR", Vector3.new(0.7, 0.35, 0.8),
        root.CFrame * CFrame.new(2.7, 0.95, -1.5), Enum.Material.SmoothPlastic, DARK_RED, car)
    weldParts(root, mirR)

    addDetailedUndercarriage(root, car, 6.4, 12.0)
    return car
end


-- =============================================================================
-- REGISTRE DES 5 VÃ‰HICULES (OuterContour supprimÃ© â€” scan Raycast automatique)
-- =============================================================================
CarBuilder.Vehicles = {
    {
        Id = "lotus_rally",
        Index = 1,
        Name = "#1 Lotus Rally",
        SpeedMultiplier = 1.0,
        RewardCash = 50,
        FrontZ = -6.0,
        Builder = CarBuilder.CreateLotusRally,
    },
    {
        Id = "cyber_truck",
        Index = 2,
        Name = "#2 Cyber Truck",
        SpeedMultiplier = 1.35,
        RewardCash = 120,
        FrontZ = -6.0,
        Builder = CarBuilder.CreateCyberTruck,
    },
    {
        Id = "drift_supra",
        Index = 3,
        Name = "#3 Drift Supra",
        SpeedMultiplier = 1.7,
        RewardCash = 300,
        FrontZ = -6.0,
        Builder = CarBuilder.CreateDriftSupra,
    },
    {
        Id = "police_interceptor",
        Index = 4,
        Name = "#4 Police Interceptor",
        SpeedMultiplier = 2.1,
        RewardCash = 750,
        FrontZ = -6.4,
        Builder = CarBuilder.CreatePoliceInterceptor,
    },
    {
        Id = "hyperion_jetcar",
        Index = 5,
        Name = "#5 Hyperion JetCar",
        SpeedMultiplier = 2.7,
        RewardCash = 2000,
        FrontZ = -6.8,
        Builder = CarBuilder.CreateHyperionJetCar,
    },
    {
        Id = "flash_mcqueen",
        Index = 6,
        Name = "#6 Flash McQueen ⚡",
        SpeedMultiplier = 3.2,
        RewardCash = 5000,
        FrontZ = -6.0,
        Builder = CarBuilder.CreateFlashMcQueen,
    },
}

-- RÃ©cupÃ¨re la config d'un vÃ©hicule par ID ou Index
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
-- CRÃ‰ATION DU TARGETFRAME PAR SCANNER RAYCAST AUTOMATIQUE
-- â–º Instancie temporairement la vraie voiture 3D sur targetCF
-- â–º Tire une grille de rayons depuis eyePos Ã  travers le plan contourCF
-- â–º Collecte le profil haut + bas, simplifie (Douglas-Peucker), trace la boucle Neon verte
-- â–º RÃ©sultat : contour mathÃ©matiquement impossible Ã  dÃ©Phaser â€” calquÃ© au laser sur la carrosserie rÃ©elle
-- =============================================================================
function CarBuilder.CreateTargetFrame(idOrIndex: any, centerPos: Vector3): Model
    local cfg = CarBuilder.GetVehicleConfig(idOrIndex)

    -- Nettoyage de tout ancien TargetFrame existant
    local oldFrame = workspace:FindFirstChild("TargetFrame")
    if oldFrame then oldFrame:Destroy() end

    local frameModel = Instance.new("Model")
    frameModel.Name = "TargetFrame"
    frameModel.Parent = workspace

    -- RepÃ¨re gÃ©omÃ©trique identique Ã  CameraController et GameLoop
    local slopeVector = Vector3.new(0, 120, 400)
    local uDir = slopeVector.Unit
    local rightVec = Vector3.new(1, 0, 0)
    local normalVec = uDir:Cross(rightVec)
    local downhillDir = -uDir

    -- CFrame cible du vÃ©hicule (de face face Ã  la camÃ©ra)
    local targetCF = CFrame.lookAt(centerPos, centerPos + downhillDir, normalVec)

    -- Position de l'Å“il de la camÃ©ra (identique Ã  CameraController.client.luau)
    local roadBasePos = centerPos - (uDir * 20)
    local eyePos = roadBasePos - (normalVec * 0.4)

    -- Plan du contour : devant le nez de la voiture
    local contourCF = targetCF * CFrame.new(0, 0, cfg.FrontZ - 0.15)

    local NEON_GREEN = Color3.fromRGB(0, 255, 60)
    local BAR_THICKNESS = 0.12

    -- RepÃ¨re invisible CenterPoint
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

    -- =========================================================
    -- Ã‰TAPE 1 : Instanciation temporaire du vrai modÃ¨le 3D
    -- =========================================================
    local tempCar = cfg.Builder()
    for _, part in ipairs(tempCar:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = true
            part.CanQuery = true
        end
    end
    tempCar.Parent = workspace
    tempCar:PivotTo(targetCF)

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = { tempCar }

    -- =========================================================
    -- Ã‰TAPE 2 : Scan Raycast colonne par colonne
    -- =========================================================
    local topProfile: { Vector2 } = {}
    local botProfile: { Vector2 } = {}

    local xMin, xMax, xStep = -3.60, 3.60, 0.08
    local yMin, yMax, yStep = -2.30, 2.80, 0.06

    local x = xMin
    while x <= xMax + 0.001 do
        local firstHitY: number? = nil
        local lastHitY: number? = nil

        local y = yMin
        while y <= yMax + 0.001 do
            local planePt = contourCF:PointToWorldSpace(Vector3.new(x, y, 0))
            local dir = (planePt - eyePos).Unit * 60
            local hit = workspace:Raycast(eyePos, dir, rayParams)
            if hit then
                if not firstHitY then firstHitY = y end
                lastHitY = y
            end
            y += yStep
        end

        if firstHitY and lastHitY then
            table.insert(topProfile, Vector2.new(x, lastHitY :: number))
            table.insert(botProfile, Vector2.new(x, firstHitY :: number))
        end
        x += xStep
    end

    -- DÃ©truit immÃ©diatement le modÃ¨le temporaire
    tempCar:Destroy()

    -- =========================================================
    -- Ã‰TAPE 3 : Simplification Ramer-Douglas-Peucker
    -- =========================================================
    local function simplifyPolyline(pts: { Vector2 }, epsilon: number): { Vector2 }
        if #pts <= 2 then return pts end
        local maxDist = 0
        local index = 1
        local p1, p2 = pts[1], pts[#pts]
        local lineVec = p2 - p1
        local lineLen = lineVec.Magnitude
        for i = 2, #pts - 1 do
            local d = 0
            if lineLen < 1e-5 then
                d = (pts[i] - p1).Magnitude
            else
                local t = math.clamp((pts[i] - p1):Dot(lineVec) / (lineLen * lineLen), 0, 1)
                local proj = p1 + lineVec * t
                d = (pts[i] - proj).Magnitude
            end
            if d > maxDist then index = i; maxDist = d end
        end
        if maxDist > epsilon then
            local leftPts: { Vector2 } = {}
            for i = 1, index do table.insert(leftPts, pts[i]) end
            local rightPts: { Vector2 } = {}
            for i = index, #pts do table.insert(rightPts, pts[i]) end
            local res1 = simplifyPolyline(leftPts, epsilon)
            local res2 = simplifyPolyline(rightPts, epsilon)
            local merged: { Vector2 } = {}
            for i = 1, #res1 - 1 do table.insert(merged, res1[i]) end
            for i = 1, #res2 do table.insert(merged, res2[i]) end
            return merged
        else
            return { p1, p2 }
        end
    end

    local cleanTop = simplifyPolyline(topProfile, 0.05)
    local reversedBot: { Vector2 } = {}
    for i = #botProfile, 1, -1 do table.insert(reversedBot, botProfile[i]) end
    local cleanBot = simplifyPolyline(reversedBot, 0.05)

    -- Polygone fermÃ© complet (haut gaucheâ†’droite, bas droiteâ†’gauche)
    local fullPolygon: { Vector2 } = {}
    for _, pt in ipairs(cleanTop) do table.insert(fullPolygon, pt) end
    for _, pt in ipairs(cleanBot) do table.insert(fullPolygon, pt) end

    -- =========================================================
    -- Ã‰TAPE 4 : TracÃ© de la boucle Neon verte
    -- =========================================================
    local count = #fullPolygon
    if count < 3 then
        -- Fallback : carrÃ© de sÃ©curitÃ© si le scan ne touche rien
        warn("[CarBuilder] Raycast scan vide pour " .. cfg.Name .. " â€” cadre fallback")
        local fallback = { Vector2.new(-3, -1.5), Vector2.new(3, -1.5), Vector2.new(3, 2.5), Vector2.new(-3, 2.5) }
        for i, pt in ipairs(fallback) do
            local nextPt = fallback[(i % #fallback) + 1]
            local wA = contourCF:PointToWorldSpace(Vector3.new(pt.X, pt.Y, 0))
            local wB = contourCF:PointToWorldSpace(Vector3.new(nextPt.X, nextPt.Y, 0))
            local seg = Instance.new("Part")
            seg.Name = "Fallback_" .. i
            seg.Size = Vector3.new(BAR_THICKNESS, BAR_THICKNESS, (wB - wA).Magnitude)
            seg.CFrame = CFrame.lookAt((wA + wB) / 2, wB)
            seg.Material = Enum.Material.Neon
            seg.Color = NEON_GREEN
            seg.Anchored = true
            seg.CanCollide = false
            seg.CastShadow = false
            seg.Parent = frameModel
        end
    else
        for i = 1, count do
            local ptA = fullPolygon[i]
            local ptB = fullPolygon[(i % count) + 1]
            local wA = contourCF:PointToWorldSpace(Vector3.new(ptA.X, ptA.Y, 0))
            local wB = contourCF:PointToWorldSpace(Vector3.new(ptB.X, ptB.Y, 0))
            local segVec = wB - wA
            local segLen = segVec.Magnitude
            if segLen > 0.02 then
                local bar = Instance.new("Part")
                bar.Name = string.format("Outline_%02d", i)
                bar.Size = Vector3.new(BAR_THICKNESS, BAR_THICKNESS, segLen)
                bar.CFrame = CFrame.lookAt((wA + wB) / 2, (wA + wB) / 2 + segVec.Unit)
                bar.Material = Enum.Material.Neon
                bar.Color = NEON_GREEN
                bar.Anchored = true
                bar.CanCollide = false
                bar.CastShadow = false
                bar.Parent = frameModel
            end
        end
    end

    print(string.format("[CarBuilder] TargetFrame RAYCAST scannÃ© pour %s (%d segments)", cfg.Name, count))
    return frameModel
end

return CarBuilder
