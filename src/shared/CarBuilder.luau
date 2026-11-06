--!strict
--[[
    STOP AT THE FRAME - CAR BUILDER (MODULE SCRIPT)
    Génère procéduralement la voiture de rallye compacte "Lotus Rally" :
    carrosserie rouge vif, vitres noir brillant, 4 roues avec jantes,
    phares Neon, RootPart invisible et soudures WeldConstraint.
]]

local CarBuilder = {}

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

function CarBuilder.CreateLotusRally(): Model
    local car = Instance.new("Model")
    car.Name = "LotusRally"

    -- 1. RootPart invisible centrée
    local root = Instance.new("Part")
    root.Name = "RootPart"
    root.Size = Vector3.new(1, 1, 1)
    root.Transparency = 1
    root.CanCollide = false
    root.Anchored = true
    root.CFrame = CFrame.new(0, 0, 0)
    root.Parent = car
    car.PrimaryPart = root

    local RED = Color3.fromRGB(225, 24, 32) -- Rouge rallye éclatant
    local DARK_RED = Color3.fromRGB(180, 16, 22)
    local BLACK_GLOSS = Color3.fromRGB(18, 20, 24) -- Vitres noir brillant
    local CHARCOAL = Color3.fromRGB(32, 34, 38)
    local RIM_GRAY = Color3.fromRGB(195, 200, 208)
    local TIRE_BLACK = Color3.fromRGB(20, 20, 22)
    local HEADLIGHT_COLOR = Color3.fromRGB(255, 252, 225)
    local FOGLIGHT_YELLOW = Color3.fromRGB(255, 225, 90)
    local TAILLIGHT_RED = Color3.fromRGB(255, 25, 25)

    -- 2. Châssis inférieur et carrosserie principale
    local baseBody = createPart("BaseBody", Vector3.new(6.8, 1.3, 11.6), root.CFrame * CFrame.new(0, -0.2, 0), Enum.Material.SmoothPlastic, RED, car)
    weldParts(root, baseBody)

    -- Lame avant / Splitter aéro
    local splitter = createPart("FrontSplitter", Vector3.new(6.6, 0.35, 1.4), root.CFrame * CFrame.new(0, -0.7, -5.9), Enum.Material.SmoothPlastic, CHARCOAL, car)
    weldParts(root, splitter)

    -- Diffuseur arrière
    local diffuser = createPart("RearDiffuser", Vector3.new(6.6, 0.45, 1.2), root.CFrame * CFrame.new(0, -0.6, 5.9), Enum.Material.SmoothPlastic, CHARCOAL, car)
    weldParts(root, diffuser)

    -- Capot avant biseauté
    local hood = createPart("Hood", Vector3.new(6.4, 0.7, 4.0), root.CFrame * CFrame.new(0, 0.45, -3.7) * CFrame.Angles(math.rad(-6), 0, 0), Enum.Material.SmoothPlastic, RED, car)
    weldParts(root, hood)

    -- Coffre / Plage arrière
    local rearDeck = createPart("RearDeck", Vector3.new(6.4, 0.9, 3.2), root.CFrame * CFrame.new(0, 0.55, 3.8), Enum.Material.SmoothPlastic, RED, car)
    weldParts(root, rearDeck)

    -- 3. Habitacle & Vitres noir brillant
    -- Toit
    local roof = createPart("Roof", Vector3.new(4.8, 0.35, 4.8), root.CFrame * CFrame.new(0, 1.85, 0.4), Enum.Material.SmoothPlastic, DARK_RED, car)
    weldParts(root, roof)

    -- Pare-brise avant
    local windshield = createPart("Windshield", Vector3.new(4.7, 1.6, 0.25), root.CFrame * CFrame.new(0, 1.2, -1.8) * CFrame.Angles(math.rad(-32), 0, 0), Enum.Material.Glass, BLACK_GLOSS, car)
    windshield.Reflectance = 0.35
    weldParts(root, windshield)

    -- Lunette arrière
    local rearWindow = createPart("RearWindow", Vector3.new(4.7, 1.5, 0.25), root.CFrame * CFrame.new(0, 1.25, 2.7) * CFrame.Angles(math.rad(28), 0, 0), Enum.Material.Glass, BLACK_GLOSS, car)
    rearWindow.Reflectance = 0.35
    weldParts(root, rearWindow)

    -- Vitres latérales
    local leftWin = createPart("SideWindow_L", Vector3.new(0.2, 1.25, 4.3), root.CFrame * CFrame.new(-2.35, 1.15, 0.45), Enum.Material.Glass, BLACK_GLOSS, car)
    leftWin.Reflectance = 0.35
    weldParts(root, leftWin)

    local rightWin = createPart("SideWindow_R", Vector3.new(0.2, 1.25, 4.3), root.CFrame * CFrame.new(2.35, 1.15, 0.45), Enum.Material.Glass, BLACK_GLOSS, car)
    rightWin.Reflectance = 0.35
    weldParts(root, rightWin)

    -- Prise d'air de toit (Rally Roof Scoop)
    local scoop = createPart("RoofScoop", Vector3.new(1.6, 0.5, 1.8), root.CFrame * CFrame.new(0, 2.15, -0.6) * CFrame.Angles(math.rad(-10), 0, 0), Enum.Material.SmoothPlastic, CHARCOAL, car)
    weldParts(root, scoop)

    -- Aileron de rallye arrière (Rear Wing)
    local wing = createPart("RearWing", Vector3.new(6.4, 0.3, 1.8), root.CFrame * CFrame.new(0, 2.1, 5.7), Enum.Material.SmoothPlastic, CHARCOAL, car)
    weldParts(root, wing)

    local strutL = createPart("WingStrut_L", Vector3.new(0.25, 1.2, 0.8), root.CFrame * CFrame.new(-2.2, 1.4, 5.6), Enum.Material.SmoothPlastic, CHARCOAL, car)
    weldParts(root, strutL)
    local strutR = createPart("WingStrut_R", Vector3.new(0.25, 1.2, 0.8), root.CFrame * CFrame.new(2.2, 1.4, 5.6), Enum.Material.SmoothPlastic, CHARCOAL, car)
    weldParts(root, strutR)

    -- Rétroviseurs extérieurs
    local mirrorL = createPart("Mirror_L", Vector3.new(0.7, 0.4, 0.8), root.CFrame * CFrame.new(-2.7, 0.95, -1.6), Enum.Material.SmoothPlastic, CHARCOAL, car)
    weldParts(root, mirrorL)
    local mirrorR = createPart("Mirror_R", Vector3.new(0.7, 0.4, 0.8), root.CFrame * CFrame.new(2.7, 0.95, -1.6), Enum.Material.SmoothPlastic, CHARCOAL, car)
    weldParts(root, mirrorR)

    -- 4. 4 Roues noires avec jantes grises
    local wheelPositions = {
        { name = "Wheel_FL", cf = CFrame.new(-3.45, -0.7, -3.7) },
        { name = "Wheel_FR", cf = CFrame.new(3.45, -0.7, -3.7) },
        { name = "Wheel_RL", cf = CFrame.new(-3.45, -0.7, 3.7) },
        { name = "Wheel_RR", cf = CFrame.new(3.45, -0.7, 3.7) },
    }

    for _, wInfo in ipairs(wheelPositions) do
        -- Pneu (Cylindre noir)
        local tire = Instance.new("Part")
        tire.Name = wInfo.name
        tire.Shape = Enum.PartType.Cylinder
        tire.Size = Vector3.new(0.9, 2.2, 2.2)
        -- En Roblox, le cylindre a son axe le long de X : rotation pour orienter les flancs vers les côtés
        tire.CFrame = root.CFrame * wInfo.cf * CFrame.Angles(0, 0, math.rad(90))
        tire.Material = Enum.Material.Rubber
        tire.Color = TIRE_BLACK
        tire.Anchored = false
        tire.CanCollide = false
        tire.Parent = car
        weldParts(root, tire)

        -- Jante grise (Cylindre intérieur légèrement débordant)
        local rim = Instance.new("Part")
        rim.Name = wInfo.name .. "_Rim"
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

    -- 5. Phares avant (Neon blanc/jaune)
    local headL = createPart("Headlight_L", Vector3.new(1.3, 0.55, 0.2), root.CFrame * CFrame.new(-2.3, 0.05, -5.85), Enum.Material.Neon, HEADLIGHT_COLOR, car)
    weldParts(root, headL)

    local headR = createPart("Headlight_R", Vector3.new(1.3, 0.55, 0.2), root.CFrame * CFrame.new(2.3, 0.05, -5.85), Enum.Material.Neon, HEADLIGHT_COLOR, car)
    weldParts(root, headR)

    -- Phares antibrouillard ronds centraux (Style rallye jaune)
    local fogL = Instance.new("Part")
    fogL.Name = "RallyFog_L"
    fogL.Shape = Enum.PartType.Cylinder
    fogL.Size = Vector3.new(0.3, 0.85, 0.85)
    fogL.CFrame = root.CFrame * CFrame.new(-0.8, -0.15, -5.9) * CFrame.Angles(0, math.rad(90), 0)
    fogL.Material = Enum.Material.Neon
    fogL.Color = FOGLIGHT_YELLOW
    fogL.Anchored = false
    fogL.CanCollide = false
    fogL.Parent = car
    weldParts(root, fogL)

    local fogR = Instance.new("Part")
    fogR.Name = "RallyFog_R"
    fogR.Shape = Enum.PartType.Cylinder
    fogR.Size = Vector3.new(0.3, 0.85, 0.85)
    fogR.CFrame = root.CFrame * CFrame.new(0.8, -0.15, -5.9) * CFrame.Angles(0, math.rad(90), 0)
    fogR.Material = Enum.Material.Neon
    fogR.Color = FOGLIGHT_YELLOW
    fogR.Anchored = false
    fogR.CanCollide = false
    fogR.Parent = car
    weldParts(root, fogR)

    -- Feux arrière rouges
    local tailL = createPart("Taillight_L", Vector3.new(1.4, 0.5, 0.2), root.CFrame * CFrame.new(-2.2, 0.3, 5.85), Enum.Material.Neon, TAILLIGHT_RED, car)
    weldParts(root, tailL)
    local tailR = createPart("Taillight_R", Vector3.new(1.4, 0.5, 0.2), root.CFrame * CFrame.new(2.2, 0.3, 5.85), Enum.Material.Neon, TAILLIGHT_RED, car)
    weldParts(root, tailR)

    return car
end

return CarBuilder
