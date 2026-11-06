--!strict
--[[
    STOP AT THE FRAME - CAR BUILDER & TARGET FRAME GENERATOR (MODULE SCRIPT)
    Génère procéduralement les 5 véhicules uniques (#1 Lotus Rally, #2 Cyber Truck,
    #3 Drift Supra, #4 Police Interceptor, #5 Hyperion JetCar) avec châssis inférieur détaillé,
    et génère le TargetFrame 100% fidèle avec clone fantôme (Highlight AlwaysOnTop)
    et contour polygonal en fines barres vert fluo.
]]

local CarBuilder = {}

export type VehicleConfig = {
    Id: string,
    Index: number,
    Name: string,
    SpeedMultiplier: number,
    RewardCash: number,
    TargetTilt: CFrame,
    SilhouettePoints: { { number } },
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

-- Ajoute un soubassement noir détaillé sous n'importe quel châssis (visible quand le nez est cabré)
local function addDetailedUndercarriage(root: BasePart, car: Model, width: number, length: number)
    local UNDER_BLACK = Color3.fromRGB(15, 16, 18)
    local METAL_GRAY = Color3.fromRGB(175, 180, 188)
    local EXHAUST_HEAT = Color3.fromRGB(120, 150, 190)

    -- 1. Plaque de protection inférieure (Skid Plate)
    local skidPlate = createPart("SkidPlate", Vector3.new(width - 0.8, 0.25, length - 1.5), root.CFrame * CFrame.new(0, -0.9, 0), Enum.Material.DiamondPlate, UNDER_BLACK, car)
    weldParts(root, skidPlate)

    -- 2. Carter de transmission & boîte centrale
    local transmission = createPart("GearboxPan", Vector3.new(2.2, 0.4, 3.2), root.CFrame * CFrame.new(0, -0.95, -0.4), Enum.Material.Metal, METAL_GRAY, car)
    weldParts(root, transmission)

    -- 3. Double ligne d'échappement inox
    local exhaustL = createPart("ExhaustPipe_L", Vector3.new(0.4, 0.4, length - 3.0), root.CFrame * CFrame.new(-1.2, -0.92, 0.8), Enum.Material.Metal, EXHAUST_HEAT, car)
    weldParts(root, exhaustL)
    local exhaustR = createPart("ExhaustPipe_R", Vector3.new(0.4, 0.4, length - 3.0), root.CFrame * CFrame.new(1.2, -0.92, 0.8), Enum.Material.Metal, EXHAUST_HEAT, car)
    weldParts(root, exhaustR)

    -- 4. Embouts d'échappement chromés à l'arrière
    local tipL = Instance.new("Part")
    tipL.Name = "ExhaustTip_L"
    tipL.Shape = Enum.PartType.Cylinder
    tipL.Size = Vector3.new(0.8, 0.55, 0.55)
    tipL.CFrame = root.CFrame * CFrame.new(-1.4, -0.7, length / 2 + 0.3) * CFrame.Angles(0, math.rad(90), 0)
    tipL.Material = Enum.Material.Metal
    tipL.Color = METAL_GRAY
    tipL.Anchored = false
    tipL.CanCollide = false
    tipL.Parent = car
    weldParts(root, tipL)

    local tipR = Instance.new("Part")
    tipR.Name = "ExhaustTip_R"
    tipR.Shape = Enum.PartType.Cylinder
    tipR.Size = Vector3.new(0.8, 0.55, 0.55)
    tipR.CFrame = root.CFrame * CFrame.new(1.4, -0.7, length / 2 + 0.3) * CFrame.Angles(0, math.rad(90), 0)
    tipR.Material = Enum.Material.Metal
    tipR.Color = METAL_GRAY
    tipR.Anchored = false
    tipR.CanCollide = false
    tipR.Parent = car
    weldParts(root, tipR)

    -- 5. Bras de suspension / Essieux avant et arrière
    local axleFront = createPart("Suspension_F", Vector3.new(width - 0.4, 0.3, 0.8), root.CFrame * CFrame.new(0, -0.8, -length * 0.3), Enum.Material.Metal, UNDER_BLACK, car)
    weldParts(root, axleFront)
    local axleRear = createPart("Suspension_R", Vector3.new(width - 0.4, 0.3, 0.8), root.CFrame * CFrame.new(0, -0.8, length * 0.3), Enum.Material.Metal, UNDER_BLACK, car)
    weldParts(root, axleRear)
end

-- =============================================================================
-- #1 LOTUS RALLY (Rouge vif, saut classique cabré, vitesse x1.0, 50$)
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

    -- Châssis & carrosserie
    local base = createPart("Base", Vector3.new(6.8, 1.3, 11.6), root.CFrame * CFrame.new(0, -0.2, 0), Enum.Material.SmoothPlastic, RED, car)
    weldParts(root, base)
    local splitter = createPart("Splitter", Vector3.new(6.6, 0.35, 1.4), root.CFrame * CFrame.new(0, -0.7, -5.9), Enum.Material.SmoothPlastic, CHARCOAL, car)
    weldParts(root, splitter)
    local hood = createPart("Hood", Vector3.new(6.4, 0.7, 4.0), root.CFrame * CFrame.new(0, 0.45, -3.7) * CFrame.Angles(math.rad(-6), 0, 0), Enum.Material.SmoothPlastic, RED, car)
    weldParts(root, hood)
    local rearDeck = createPart("RearDeck", Vector3.new(6.4, 0.9, 3.2), root.CFrame * CFrame.new(0, 0.55, 3.8), Enum.Material.SmoothPlastic, RED, car)
    weldParts(root, rearDeck)

    -- Toit et vitres
    local roof = createPart("Roof", Vector3.new(4.8, 0.35, 4.8), root.CFrame * CFrame.new(0, 1.85, 0.4), Enum.Material.SmoothPlastic, DARK_RED, car)
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

    -- 4 Roues
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
    local headL = createPart("HeadL", Vector3.new(1.3, 0.55, 0.2), root.CFrame * CFrame.new(-2.3, 0.05, -5.85), Enum.Material.Neon, Color3.fromRGB(255, 252, 225), car)
    weldParts(root, headL)
    local headR = createPart("HeadR", Vector3.new(1.3, 0.55, 0.2), root.CFrame * CFrame.new(2.3, 0.05, -5.85), Enum.Material.Neon, Color3.fromRGB(255, 252, 225), car)
    weldParts(root, headR)

    -- Rétroviseurs
    local mirL = createPart("MirrorL", Vector3.new(0.7, 0.4, 0.8), root.CFrame * CFrame.new(-2.7, 0.95, -1.6), Enum.Material.SmoothPlastic, CHARCOAL, car)
    weldParts(root, mirL)
    local mirR = createPart("MirrorR", Vector3.new(0.7, 0.4, 0.8), root.CFrame * CFrame.new(2.7, 0.95, -1.6), Enum.Material.SmoothPlastic, CHARCOAL, car)
    weldParts(root, mirR)

    addDetailedUndercarriage(root, car, 6.8, 11.6)
    return car
end

-- =============================================================================
-- #2 CYBER TRUCK (Argenté anguleux, saut rapide incliné côté, vitesse x1.35, 120$)
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

    local STEEL = Color3.fromRGB(215, 220, 228)
    local DARK_STEEL = Color3.fromRGB(150, 155, 165)
    local CYBER_CYAN = Color3.fromRGB(0, 240, 255)
    local BLACK_ARMOR = Color3.fromRGB(25, 26, 30)

    -- Corps anguleux massif
    local lower = createPart("LowerArmor", Vector3.new(7.6, 1.8, 13.0), root.CFrame * CFrame.new(0, -0.1, 0), Enum.Material.Metal, STEEL, car)
    weldParts(root, lower)

    -- Ligne de toit triangulaire pyramidale emblématique
    local roofFront = createPart("RoofFrontSlope", Vector3.new(6.8, 0.5, 6.5), root.CFrame * CFrame.new(0, 1.5, -2.6) * CFrame.Angles(math.rad(-22), 0, 0), Enum.Material.Metal, STEEL, car)
    weldParts(root, roofFront)

    local roofBack = createPart("RoofBackSlope", Vector3.new(6.8, 0.5, 6.8), root.CFrame * CFrame.new(0, 1.5, 3.2) * CFrame.Angles(math.rad(20), 0, 0), Enum.Material.Metal, STEEL, car)
    weldParts(root, roofBack)

    -- Vitre pare-brise angulaire blindée
    local glass = createPart("ArmorWindshield", Vector3.new(6.2, 1.8, 0.3), root.CFrame * CFrame.new(0, 1.35, -2.5) * CFrame.Angles(math.rad(-26), 0, 0), Enum.Material.Glass, Color3.fromRGB(18, 22, 28), car)
    glass.Reflectance = 0.4
    weldParts(root, glass)

    -- Lightbar avant pleine largeur (Barre LED continue néon cyan/blanc)
    local lightbar = createPart("FrontLightbar", Vector3.new(7.4, 0.35, 0.25), root.CFrame * CFrame.new(0, 0.7, -6.55), Enum.Material.Neon, CYBER_CYAN, car)
    weldParts(root, lightbar)

    -- Lightbar arrière rouge continu
    local rearLight = createPart("RearLightbar", Vector3.new(7.4, 0.35, 0.25), root.CFrame * CFrame.new(0, 0.8, 6.55), Enum.Material.Neon, Color3.fromRGB(255, 35, 35), car)
    weldParts(root, rearLight)

    -- 4 Grandes roues cyberpunk géométriques
    for _, offset in ipairs({ Vector3.new(-3.85, -0.6, -4.2), Vector3.new(3.85, -0.6, -4.2), Vector3.new(-3.85, -0.6, 4.2), Vector3.new(3.85, -0.6, 4.2) }) do
        local tire = Instance.new("Part")
        tire.Shape = Enum.PartType.Cylinder
        tire.Size = Vector3.new(1.1, 2.6, 2.6)
        tire.CFrame = root.CFrame * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(90))
        tire.Material = Enum.Material.Rubber
        tire.Color = BLACK_ARMOR
        tire.Anchored = false
        tire.CanCollide = false
        tire.Parent = car
        weldParts(root, tire)

        local cap = Instance.new("Part")
        cap.Shape = Enum.PartType.Cylinder
        cap.Size = Vector3.new(1.15, 1.6, 1.6)
        cap.CFrame = tire.CFrame
        cap.Material = Enum.Material.Metal
        cap.Color = DARK_STEEL
        cap.Anchored = false
        cap.CanCollide = false
        cap.Parent = car
        weldParts(root, cap)
    end

    addDetailedUndercarriage(root, car, 7.6, 13.0)
    return car
end

-- =============================================================================
-- #3 DRIFT SUPRA (Orange néon, saut en drift, vitesse x1.7, 300$)
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

    local ORANGE = Color3.fromRGB(255, 105, 15)
    local CARBON = Color3.fromRGB(22, 22, 25)
    local BRONZE_RIM = Color3.fromRGB(205, 140, 60)
    local GLOSS_BLACK = Color3.fromRGB(15, 18, 22)

    -- Carrosserie Widebody aérodynamique
    local body = createPart("Widebody", Vector3.new(7.2, 1.2, 11.8), root.CFrame * CFrame.new(0, -0.2, 0), Enum.Material.SmoothPlastic, ORANGE, car)
    weldParts(root, body)

    -- Lame avant carbone et ailettes canards
    local frontCanards = createPart("FrontCanards", Vector3.new(7.4, 0.25, 1.6), root.CFrame * CFrame.new(0, -0.65, -5.9), Enum.Material.DiamondPlate, CARBON, car)
    weldParts(root, frontCanards)

    -- Capot avec double ouïes d'aération
    local hood = createPart("VentedHood", Vector3.new(6.6, 0.65, 4.4), root.CFrame * CFrame.new(0, 0.45, -3.6) * CFrame.Angles(math.rad(-7), 0, 0), Enum.Material.SmoothPlastic, ORANGE, car)
    weldParts(root, hood)

    local ventL = createPart("HoodVent_L", Vector3.new(0.8, 0.1, 2.0), root.CFrame * CFrame.new(-1.6, 0.78, -3.6) * CFrame.Angles(math.rad(-7), 0, 0), Enum.Material.Metal, CARBON, car)
    weldParts(root, ventL)
    local ventR = createPart("HoodVent_R", Vector3.new(0.8, 0.1, 2.0), root.CFrame * CFrame.new(1.6, 0.78, -3.6) * CFrame.Angles(math.rad(-7), 0, 0), Enum.Material.Metal, CARBON, car)
    weldParts(root, ventR)

    -- Habitacle profilé bulle
    local cabin = createPart("CabinRoof", Vector3.new(5.0, 1.5, 4.6), root.CFrame * CFrame.new(0, 1.3, 0.4), Enum.Material.SmoothPlastic, ORANGE, car)
    weldParts(root, cabin)
    local windshield = createPart("Windshield", Vector3.new(4.8, 1.5, 0.25), root.CFrame * CFrame.new(0, 1.15, -1.9) * CFrame.Angles(math.rad(-34), 0, 0), Enum.Material.Glass, GLOSS_BLACK, car)
    windshield.Reflectance = 0.4
    weldParts(root, windshield)

    -- Énorme Aileron GT incurvé carbone
    local gtWing = createPart("GTWing", Vector3.new(7.6, 0.35, 1.9), root.CFrame * CFrame.new(0, 2.4, 5.8), Enum.Material.Metal, CARBON, car)
    weldParts(root, gtWing)
    local strutL = createPart("StrutL", Vector3.new(0.2, 1.5, 0.9), root.CFrame * CFrame.new(-2.6, 1.6, 5.7), Enum.Material.Metal, CARBON, car)
    weldParts(root, strutL)
    local strutR = createPart("StrutR", Vector3.new(0.2, 1.5, 0.9), root.CFrame * CFrame.new(2.6, 1.6, 5.7), Enum.Material.Metal, CARBON, car)
    weldParts(root, strutR)

    -- Roues larges avec jantes bronze de drift
    for _, offset in ipairs({ Vector3.new(-3.65, -0.65, -3.8), Vector3.new(3.65, -0.65, -3.8), Vector3.new(-3.65, -0.65, 3.8), Vector3.new(3.65, -0.65, 3.8) }) do
        local tire = Instance.new("Part")
        tire.Shape = Enum.PartType.Cylinder
        tire.Size = Vector3.new(1.1, 2.3, 2.3)
        tire.CFrame = root.CFrame * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(90))
        tire.Material = Enum.Material.Rubber
        tire.Color = Color3.fromRGB(18, 18, 20)
        tire.Anchored = false
        tire.CanCollide = false
        tire.Parent = car
        weldParts(root, tire)

        local rim = Instance.new("Part")
        rim.Shape = Enum.PartType.Cylinder
        rim.Size = Vector3.new(1.16, 1.5, 1.5)
        rim.CFrame = tire.CFrame
        rim.Material = Enum.Material.Metal
        rim.Color = BRONZE_RIM
        rim.Anchored = false
        rim.CanCollide = false
        rim.Parent = car
        weldParts(root, rim)
    end

    -- Phares avant LED angulaires néon blanc pur
    local hL = createPart("HeadL", Vector3.new(1.4, 0.45, 0.3), root.CFrame * CFrame.new(-2.5, 0.1, -5.9), Enum.Material.Neon, Color3.fromRGB(255, 255, 255), car)
    weldParts(root, hL)
    local hR = createPart("HeadR", Vector3.new(1.4, 0.45, 0.3), root.CFrame * CFrame.new(2.5, 0.1, -5.9), Enum.Material.Neon, Color3.fromRGB(255, 255, 255), car)
    weldParts(root, hR)

    addDetailedUndercarriage(root, car, 7.2, 11.8)
    return car
end

-- =============================================================================
-- #4 POLICE INTERCEPTOR (Noir & Blanc, gyrophare bleu/rouge, saut plongeant, 750$)
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

    local POLICE_BLACK = Color3.fromRGB(18, 20, 24)
    local POLICE_WHITE = Color3.fromRGB(245, 248, 252)
    local CHROME = Color3.fromRGB(210, 215, 220)
    local BLUE_SIREN = Color3.fromRGB(0, 130, 255)
    local RED_SIREN = Color3.fromRGB(255, 20, 30)

    -- Carrosserie bicolore (portes blanches, avant et arrière noirs)
    local bodyFront = createPart("BodyFront", Vector3.new(7.0, 1.4, 4.0), root.CFrame * CFrame.new(0, -0.2, -3.8), Enum.Material.SmoothPlastic, POLICE_BLACK, car)
    weldParts(root, bodyFront)
    local bodyCenter = createPart("BodyCenter", Vector3.new(7.0, 1.4, 4.2), root.CFrame * CFrame.new(0, -0.2, 0.2), Enum.Material.SmoothPlastic, POLICE_WHITE, car)
    weldParts(root, bodyCenter)
    local bodyRear = createPart("BodyRear", Vector3.new(7.0, 1.4, 3.8), root.CFrame * CFrame.new(0, -0.2, 4.1), Enum.Material.SmoothPlastic, POLICE_BLACK, car)
    weldParts(root, bodyRear)

    -- Pare-buffle imposant en acier noir (Push Bumper / Bullbar)
    local bullbar = createPart("Bullbar", Vector3.new(5.6, 1.6, 0.4), root.CFrame * CFrame.new(0, 0.1, -6.1), Enum.Material.DiamondPlate, POLICE_BLACK, car)
    weldParts(root, bullbar)
    local bullbarBarT = createPart("BullbarTop", Vector3.new(5.0, 0.3, 0.3), root.CFrame * CFrame.new(0, 0.8, -6.1), Enum.Material.Metal, CHROME, car)
    weldParts(root, bullbarBarT)

    -- Toit blanc et vitres teintées
    local roof = createPart("Roof", Vector3.new(5.0, 0.35, 4.8), root.CFrame * CFrame.new(0, 1.85, 0.4), Enum.Material.SmoothPlastic, POLICE_WHITE, car)
    weldParts(root, roof)
    local windshield = createPart("Windshield", Vector3.new(4.8, 1.6, 0.25), root.CFrame * CFrame.new(0, 1.2, -1.8) * CFrame.Angles(math.rad(-30), 0, 0), Enum.Material.Glass, Color3.fromRGB(10, 12, 16), car)
    windshield.Reflectance = 0.3
    weldParts(root, windshield)

    -- Gyrophare de toit Police (Bleu et Rouge clignotants)
    local sirenBase = createPart("SirenBase", Vector3.new(3.8, 0.2, 0.8), root.CFrame * CFrame.new(0, 2.1, 0.3), Enum.Material.Metal, POLICE_BLACK, car)
    weldParts(root, sirenBase)
    local sirenBlue = createPart("SirenBlue", Vector3.new(1.6, 0.45, 0.7), root.CFrame * CFrame.new(-0.9, 2.35, 0.3), Enum.Material.Neon, BLUE_SIREN, car)
    weldParts(root, sirenBlue)
    local sirenRed = createPart("SirenRed", Vector3.new(1.6, 0.45, 0.7), root.CFrame * CFrame.new(0.9, 2.35, 0.3), Enum.Material.Neon, RED_SIREN, car)
    weldParts(root, sirenRed)

    -- Spots de recherche sur les montants A
    local spotL = createPart("SpotL", Vector3.new(0.5, 0.5, 0.5), root.CFrame * CFrame.new(-2.6, 1.3, -1.5), Enum.Material.Neon, Color3.fromRGB(255, 255, 255), car)
    weldParts(root, spotL)
    local spotR = createPart("SpotR", Vector3.new(0.5, 0.5, 0.5), root.CFrame * CFrame.new(2.6, 1.3, -1.5), Enum.Material.Neon, Color3.fromRGB(255, 255, 255), car)
    weldParts(root, spotR)

    -- 4 Roues de police avec jantes acier noires à cabochon chromé
    for _, offset in ipairs({ Vector3.new(-3.5, -0.7, -3.7), Vector3.new(3.5, -0.7, -3.7), Vector3.new(-3.5, -0.7, 3.7), Vector3.new(3.5, -0.7, 3.7) }) do
        local tire = Instance.new("Part")
        tire.Shape = Enum.PartType.Cylinder
        tire.Size = Vector3.new(0.95, 2.2, 2.2)
        tire.CFrame = root.CFrame * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(90))
        tire.Material = Enum.Material.Rubber
        tire.Color = POLICE_BLACK
        tire.Anchored = false
        tire.CanCollide = false
        tire.Parent = car
        weldParts(root, tire)

        local cap = Instance.new("Part")
        cap.Shape = Enum.PartType.Cylinder
        cap.Size = Vector3.new(1.0, 0.9, 0.9)
        cap.CFrame = tire.CFrame
        cap.Material = Enum.Material.Metal
        cap.Color = CHROME
        cap.Anchored = false
        cap.CanCollide = false
        cap.Parent = car
        weldParts(root, cap)
    end

    addDetailedUndercarriage(root, car, 7.0, 12.0)
    return car
end

-- =============================================================================
-- #5 HYPERION JETCAR (Or & Noir, vitesse extrême x2.7, 2000$)
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

    local GOLD = Color3.fromRGB(255, 205, 30)
    local CARBON = Color3.fromRGB(16, 16, 20)
    local CYAN_THRUSTER = Color3.fromRGB(0, 245, 255)
    local ORANGE_AFTERBURN = Color3.fromRGB(255, 110, 0)

    -- Châssis hypercar effilé fuselé
    local mainCockpit = createPart("Cockpit", Vector3.new(6.6, 1.1, 12.6), root.CFrame * CFrame.new(0, -0.25, 0), Enum.Material.Metal, GOLD, car)
    weldParts(root, mainCockpit)

    -- Ailerons canards avant en flèche
    local nose = createPart("NoseCone", Vector3.new(5.0, 0.6, 3.2), root.CFrame * CFrame.new(0, 0.1, -5.8) * CFrame.Angles(math.rad(-12), 0, 0), Enum.Material.SmoothPlastic, CARBON, car)
    weldParts(root, nose)

    -- Verrière bulle cockpit d'avion de chasse (Canopy)
    local canopy = createPart("JetCanopy", Vector3.new(4.2, 1.4, 5.0), root.CFrame * CFrame.new(0, 0.95, -0.2), Enum.Material.Glass, Color3.fromRGB(10, 14, 20), car)
    canopy.Reflectance = 0.5
    weldParts(root, canopy)

    -- Dérive dorsale verticale (Stabilisateur jet)
    local fin = createPart("DorsalFin", Vector3.new(0.3, 1.8, 3.8), root.CFrame * CFrame.new(0, 1.8, 2.8), Enum.Material.Metal, GOLD, car)
    weldParts(root, fin)

    -- Double réacteur à propulsion jet à l'arrière
    local jetL = Instance.new("Part")
    jetL.Name = "JetEngine_L"
    jetL.Shape = Enum.PartType.Cylinder
    jetL.Size = Vector3.new(4.2, 1.6, 1.6)
    jetL.CFrame = root.CFrame * CFrame.new(-1.8, 0.2, 5.2) * CFrame.Angles(0, math.rad(90), 0)
    jetL.Material = Enum.Material.Metal
    jetL.Color = CARBON
    jetL.Anchored = false
    jetL.CanCollide = false
    jetL.Parent = car
    weldParts(root, jetL)

    local flameL = Instance.new("Part")
    flameL.Name = "JetFlame_L"
    flameL.Shape = Enum.PartType.Cylinder
    flameL.Size = Vector3.new(0.6, 1.2, 1.2)
    flameL.CFrame = root.CFrame * CFrame.new(-1.8, 0.2, 7.3) * CFrame.Angles(0, math.rad(90), 0)
    flameL.Material = Enum.Material.Neon
    flameL.Color = CYAN_THRUSTER
    flameL.Anchored = false
    flameL.CanCollide = false
    flameL.Parent = car
    weldParts(root, flameL)

    local jetR = Instance.new("Part")
    jetR.Name = "JetEngine_R"
    jetR.Shape = Enum.PartType.Cylinder
    jetR.Size = Vector3.new(4.2, 1.6, 1.6)
    jetR.CFrame = root.CFrame * CFrame.new(1.8, 0.2, 5.2) * CFrame.Angles(0, math.rad(90), 0)
    jetR.Material = Enum.Material.Metal
    jetR.Color = CARBON
    jetR.Anchored = false
    jetR.CanCollide = false
    jetR.Parent = car
    weldParts(root, jetR)

    local flameR = Instance.new("Part")
    flameR.Name = "JetFlame_R"
    flameR.Shape = Enum.PartType.Cylinder
    flameR.Size = Vector3.new(0.6, 1.2, 1.2)
    flameR.CFrame = root.CFrame * CFrame.new(1.8, 0.2, 7.3) * CFrame.Angles(0, math.rad(90), 0)
    flameR.Material = Enum.Material.Neon
    flameR.Color = CYAN_THRUSTER
    flameR.Anchored = false
    flameR.CanCollide = false
    flameR.Parent = car
    weldParts(root, flameR)

    -- 4 Roues carénées aéro
    for _, offset in ipairs({ Vector3.new(-3.6, -0.65, -3.9), Vector3.new(3.6, -0.65, -3.9), Vector3.new(-3.6, -0.65, 3.9), Vector3.new(3.6, -0.65, 3.9) }) do
        local tire = Instance.new("Part")
        tire.Shape = Enum.PartType.Cylinder
        tire.Size = Vector3.new(1.0, 2.2, 2.2)
        tire.CFrame = root.CFrame * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(90))
        tire.Material = Enum.Material.Rubber
        tire.Color = CARBON
        tire.Anchored = false
        tire.CanCollide = false
        tire.Parent = car
        weldParts(root, tire)

        local goldRim = Instance.new("Part")
        goldRim.Shape = Enum.PartType.Cylinder
        goldRim.Size = Vector3.new(1.08, 1.4, 1.4)
        goldRim.CFrame = tire.CFrame
        goldRim.Material = Enum.Material.Metal
        goldRim.Color = GOLD
        goldRim.Anchored = false
        goldRim.CanCollide = false
        goldRim.Parent = car
        weldParts(root, goldRim)
    end

    addDetailedUndercarriage(root, car, 6.6, 12.6)
    return car
end

-- =============================================================================
-- REGISTRE DES 5 VÉHICULES / MOMENTS
-- =============================================================================
CarBuilder.Vehicles = {
    {
        Id = "lotus_rally",
        Index = 1,
        Name = "#1 Lotus Rally",
        SpeedMultiplier = 1.0,
        RewardCash = 50,
        TargetTilt = CFrame.Angles(0, 0, 0),
        Builder = CarBuilder.CreateLotusRally,
        SilhouettePoints = {
            { -3.6, -1.6, 3.6, -1.6 },   -- Bas pneus
            { -3.6, -1.6, -3.8, -0.2 },  -- Flanc pneu G
            { 3.6, -1.6, 3.8, -0.2 },    -- Flanc pneu D
            { -4.0, -0.2, 4.0, -0.2 },   -- Pare-chocs
            { -4.0, -0.2, -3.9, 0.8 },   -- Aile G
            { 4.0, -0.2, 3.9, 0.8 },     -- Aile D
            { -3.9, 0.8, 3.9, 0.8 },     -- Capot
            { -3.4, 0.8, -2.4, 2.1 },    -- Montant pare-brise G
            { 3.4, 0.8, 2.4, 2.1 },      -- Montant pare-brise D
            { -2.4, 2.1, 2.4, 2.1 },     -- Ligne de toit
            { -3.5, 1.1, -4.3, 1.2 },    -- Rétroviseur G
            { 3.5, 1.1, 4.3, 1.2 },      -- Rétroviseur D
            { -3.5, 0.3, -2.2, 0.3 },    -- Phare G
            { 2.2, 0.3, 3.5, 0.3 },      -- Phare D
        },
    },
    {
        Id = "cyber_truck",
        Index = 2,
        Name = "#2 Cyber Truck",
        SpeedMultiplier = 1.35,
        RewardCash = 120,
        TargetTilt = CFrame.Angles(0, 0, math.rad(7)), -- Saut incliné côté
        Builder = CarBuilder.CreateCyberTruck,
        SilhouettePoints = {
            { -3.9, -1.8, 3.9, -1.8 },   -- Bas pneus
            { -4.0, -1.8, -4.1, 0.0 },   -- Flanc G
            { 4.0, -1.8, 4.1, 0.0 },     -- Flanc D
            { -4.3, 0.0, 4.3, 0.0 },     -- Pare-chocs anguleux
            { -4.3, 0.0, -4.0, 1.1 },    -- Ligne ceinture G
            { 4.3, 0.0, 4.0, 1.1 },      -- Ligne ceinture D
            { -4.0, 1.1, -0.2, 2.4 },    -- Toit pointe triangulaire G
            { 4.0, 1.1, 0.2, 2.4 },      -- Toit pointe triangulaire D
            { -0.2, 2.4, 0.2, 2.4 },     -- Arête sommitale
            { -3.8, 0.7, 3.8, 0.7 },     -- Lightbar horizontale continue
        },
    },
    {
        Id = "drift_supra",
        Index = 3,
        Name = "#3 Drift Supra",
        SpeedMultiplier = 1.7,
        RewardCash = 300,
        TargetTilt = CFrame.Angles(0, math.rad(12), 0), -- Saut en travers drift
        Builder = CarBuilder.CreateDriftSupra,
        SilhouettePoints = {
            { -3.8, -1.7, 3.8, -1.7 },   -- Bas pneus
            { -4.2, -0.3, 4.2, -0.3 },   -- Canards splitter large
            { -4.2, -0.3, -3.9, 0.7 },   -- Aile élargie G
            { 4.2, -0.3, 3.9, 0.7 },     -- Aile élargie D
            { -3.9, 0.7, 3.9, 0.7 },     -- Ligne capot
            { -3.5, 0.7, -2.4, 1.9 },    -- Pare-brise profilé G
            { 3.5, 0.7, 2.4, 1.9 },      -- Pare-brise profilé D
            { -2.4, 1.9, 2.4, 1.9 },     -- Toit
            { -4.1, 2.5, 4.1, 2.5 },     -- Aileron GT démesuré
            { -2.7, 1.8, -2.7, 2.5 },    -- Support aileron G
            { 2.7, 1.8, 2.7, 2.5 },      -- Support aileron D
            { -3.6, 0.2, -2.2, 0.2 },    -- Phares acérés
            { 2.2, 0.2, 3.6, 0.2 },
        },
    },
    {
        Id = "police_interceptor",
        Index = 4,
        Name = "#4 Police Interceptor",
        SpeedMultiplier = 2.1,
        RewardCash = 750,
        TargetTilt = CFrame.Angles(math.rad(-10), 0, 0), -- Saut plongeant
        Builder = CarBuilder.CreatePoliceInterceptor,
        SilhouettePoints = {
            { -3.7, -1.7, 3.7, -1.7 },   -- Bas pneus
            { -4.1, -0.1, 4.1, -0.1 },   -- Pare-chocs
            { -3.0, -0.7, 3.0, -0.7 },   -- Pare-buffle avant bas
            { -3.0, 0.8, 3.0, 0.8 },     -- Pare-buffle haut
            { -3.0, -0.7, -3.0, 0.8 },   -- Barres bullbar
            { 3.0, -0.7, 3.0, 0.8 },
            { -4.0, 0.1, -3.8, 1.0 },    -- Ailes
            { 4.0, 0.1, 3.8, 1.0 },
            { -3.4, 1.0, -2.4, 2.0 },    -- Pare-brise
            { 3.4, 1.0, 2.4, 2.0 },
            { -2.4, 2.0, 2.4, 2.0 },     -- Toit
            { -2.0, 2.3, 2.0, 2.3 },     -- Gyrophare de police
            { -2.0, 2.0, -2.0, 2.3 },
            { 2.0, 2.0, 2.0, 2.3 },
        },
    },
    {
        Id = "hyperion_jetcar",
        Index = 5,
        Name = "#5 Hyperion JetCar",
        SpeedMultiplier = 2.7,
        RewardCash = 2000,
        TargetTilt = CFrame.Angles(0, 0, 0),
        Builder = CarBuilder.CreateHyperionJetCar,
        SilhouettePoints = {
            { -3.8, -1.6, 3.8, -1.6 },   -- Bas roues
            { -4.3, -0.3, 4.3, -0.3 },   -- Flèche basse
            { -4.3, -0.3, -3.5, 0.5 },   -- Canards
            { 4.3, -0.3, 3.5, 0.5 },
            { -3.2, 0.5, 3.2, 0.5 },     -- Cockpit
            { -2.6, 0.5, -1.8, 1.8 },    -- Verrière bulle avion
            { 2.6, 0.5, 1.8, 1.8 },
            { -1.8, 1.8, 1.8, 1.8 },     -- Haut verrière
            { 0.0, 1.8, 0.0, 2.8 },      -- Dérive dorsale fusée
            { -2.6, -0.1, -2.6, 1.2 },   -- Tuyère réacteur G
            { 2.6, -0.1, 2.6, 1.2 },     -- Tuyère réacteur D
        },
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
-- CRÉATION D'UN TARGETFRAME 100% FIDÈLE AU VÉHICULE
-- Clone fantôme (Highlight AlwaysOnTop) + barres Neon vert fluo + CenterPoint
-- =============================================================================
function CarBuilder.CreateTargetFrame(idOrIndex: any, centerPos: Vector3, baseCFrame: CFrame): Model
    local cfg = CarBuilder.GetVehicleConfig(idOrIndex)

    -- Nettoyage de tout ancien TargetFrame existant
    local oldFrame = workspace:FindFirstChild("TargetFrame")
    if oldFrame then
        oldFrame:Destroy()
    end

    local frameModel = Instance.new("Model")
    frameModel.Name = "TargetFrame"
    frameModel.Parent = workspace

    local targetCF = baseCFrame * cfg.TargetTilt
    local NEON_GREEN = Color3.fromRGB(0, 255, 60)
    local BAR_THICKNESS = 0.15

    -- 1. Repère invisible CenterPoint exactement au centre
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
    pointLight.Brightness = 3.5
    pointLight.Range = 28
    pointLight.Parent = centerPoint

    -- 2. Clone fantôme du véhicule avec Highlight AlwaysOnTop (silhouette volumétrique 3D parfaite)
    local ghostCar = cfg.Builder()
    ghostCar.Name = "GhostVehicleSilhouette"
    for _, part in ipairs(ghostCar:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false
            part.Transparency = 0.92
            part.CastShadow = false
        end
    end
    ghostCar:PivotTo(targetCF)
    ghostCar.Parent = frameModel

    local highlight = Instance.new("Highlight")
    highlight.Name = "GreenOutlineHighlight"
    highlight.FillTransparency = 1
    highlight.OutlineColor = NEON_GREEN
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = ghostCar
    highlight.Parent = ghostCar

    -- 3. Barres Neon vert fluo reliant les points de contour exacts du gabarit frontal
    local rightVec = targetCF.RightVector
    local upVec = targetCF.UpVector

    for i, seg in ipairs(cfg.SilhouettePoints) do
        local x1, y1, x2, y2 = seg[1], seg[2], seg[3], seg[4]
        local p1 = targetCF.Position + (rightVec * x1) + (upVec * y1)
        local p2 = targetCF.Position + (rightVec * x2) + (upVec * y2)

        local segVec = p2 - p1
        local segLen = segVec.Magnitude
        local segMid = (p1 + p2) / 2

        if segLen > 0.02 then
            local bar = Instance.new("Part")
            bar.Name = "Bar_" .. i
            bar.Size = Vector3.new(BAR_THICKNESS, BAR_THICKNESS, segLen)
            bar.CFrame = CFrame.lookAt(segMid, segMid + segVec.Unit)
            bar.Material = Enum.Material.Neon
            bar.Color = NEON_GREEN
            bar.Anchored = true
            bar.CanCollide = false
            bar.Parent = frameModel
        end
    end

    print(string.format("[CarBuilder] TargetFrame 100%% synchronisé créé pour %s", cfg.Name))
    return frameModel
end

return CarBuilder
