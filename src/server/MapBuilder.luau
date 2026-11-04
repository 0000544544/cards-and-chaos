--!strict
--[[
    CARDS & CHAOS - ARCHITECTURE DE LA MAP, AUTELS & MANNEQUINS D'ENTRAÎNEMENT (SERVEUR)
    Génération propre de la map (ZÉRO bloc jaune fluo), 3 Mannequins d'entraînement réactifs
    avec Humanoid (1000 PV et respawn) à 30 studs du spawn, et autels interactifs.
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local MapBuilder = {}

local function CreatePart(props: { [string]: any }): Part
    local part = Instance.new("Part")
    part.Anchored = true
    for k, v in pairs(props) do
        (part :: any)[k] = v
    end
    return part
end

function MapBuilder.BuildEnvironment()
    -- Configuration de l'ambiance et de l'éclairage Dark Fantasy
    Lighting.Brightness = 1.8
    Lighting.ClockTime = 21.0
    Lighting.OutdoorAmbient = Color3.fromRGB(35, 30, 50)
    Lighting.Ambient = Color3.fromRGB(25, 20, 35)

    -- Nettoyage de tout ancien dossier de map pour garantir un monde propre
    local oldHub = Workspace:FindFirstChild("SovereignHub")
    if oldHub then
        oldHub:Destroy()
    end

    local hubFolder = Instance.new("Folder")
    hubFolder.Name = "SovereignHub"
    hubFolder.Parent = Workspace

    -- 1. SOL DU HUB (Dalles d'ardoise sombre élégante)
    CreatePart({
        Name = "LobbyFloor",
        Size = Vector3.new(160, 2, 160),
        Position = Vector3.new(0, 0, 0),
        Material = Enum.Material.Slate,
        Color = Color3.fromRGB(22, 24, 30),
        Parent = hubFolder,
    })

    -- Bordure fine discrète (Gris anthracite / Bleu nuit, AUCUN JAUNE FLUO)
    CreatePart({
        Name = "LobbyBorder",
        Size = Vector3.new(164, 2.2, 164),
        Position = Vector3.new(0, -0.1, 0),
        Material = Enum.Material.Cobblestone,
        Color = Color3.fromRGB(35, 40, 55),
        Parent = hubFolder,
    })

    -- 2. SPAWN LOCATION DU JOUEUR
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "MainSpawn"
    spawn.Size = Vector3.new(12, 1, 12)
    spawn.Position = Vector3.new(0, 1.2, 0)
    spawn.Anchored = true
    spawn.Material = Enum.Material.Neon
    spawn.Color = Color3.fromRGB(79, 70, 229)
    spawn.Duration = 0
    spawn.Parent = hubFolder

    -- =========================================================================
    -- 3. LES 3 MANNEQUINS D'ENTRAÎNEMENT (À 30 STUDS DU SPAWN)
    -- =========================================================================
    local function CreateDummy(name: string, position: Vector3)
        local dummy = Instance.new("Model")
        dummy.Name = name
        dummy.Parent = hubFolder

        local root = CreatePart({
            Name = "HumanoidRootPart",
            Size = Vector3.new(2, 2, 1),
            Position = position + Vector3.new(0, 3, 0),
            Transparency = 1,
            CanCollide = false,
            Parent = dummy,
        })

        local torso = CreatePart({
            Name = "Torso",
            Size = Vector3.new(2.5, 3, 1.5),
            Position = position + Vector3.new(0, 3.5, 0),
            Material = Enum.Material.WoodPlanks,
            Color = Color3.fromRGB(130, 95, 65),
            Parent = dummy,
        })

        local head = CreatePart({
            Name = "Head",
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(2, 2, 2),
            Position = position + Vector3.new(0, 5.8, 0),
            Material = Enum.Material.Slate,
            Color = Color3.fromRGB(200, 205, 215),
            Parent = dummy,
        })

        local hum = Instance.new("Humanoid")
        hum.MaxHealth = 1000
        hum.Health = 1000
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Always
        hum.NameDisplayDistance = 60
        hum.HealthDisplayDistance = 60
        hum.Parent = dummy

        dummy.PrimaryPart = root

        -- Boucle d'auto-régénération
        task.spawn(function()
            while dummy.Parent do
                task.wait(2.0)
                if hum.Health < hum.MaxHealth then
                    hum.Health = math.min(hum.MaxHealth, hum.Health + 100)
                end
            end
        end)
    end

    -- 3 Mannequins disposés en demi-cercle d'entraînement face au spawn
    CreateDummy("Mannequin_Alpha (DPS)", Vector3.new(-18, 0.5, -30))
    CreateDummy("Mannequin_Beta (AOE)", Vector3.new(0, 0.5, -35))
    CreateDummy("Mannequin_Gamma (Cible)", Vector3.new(18, 0.5, -30))

    -- =========================================================================
    -- 4. AUTEL D'INVOCATION & HÔTEL DES VENTES
    -- =========================================================================
    local function CreateAltar(name: string, title: string, action: string, uiTab: string, pos: Vector3, color: Color3)
        local base = CreatePart({
            Name = name,
            Size = Vector3.new(10, 3.5, 10),
            Position = pos,
            Material = Enum.Material.Cobblestone,
            Color = Color3.fromRGB(25, 28, 38),
            Parent = hubFolder,
        })
        base:SetAttribute("TargetUI", uiTab)

        local crystal = CreatePart({
            Name = "Crystal",
            Size = Vector3.new(3, 6, 3),
            Position = pos + Vector3.new(0, 5, 0),
            Material = Enum.Material.Neon,
            Color = color,
            Parent = base,
        })

        local light = Instance.new("PointLight")
        light.Color = color
        light.Range = 25
        light.Brightness = 3
        light.Parent = crystal

        local prompt = Instance.new("ProximityPrompt")
        prompt.ObjectText = title
        prompt.ActionText = action
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 15
        prompt.Parent = base
    end

    -- Autel d'Invocation (Violet néon)
    CreateAltar("AutelGacha", "Autel du Destin", "Invoquer des Sorts (E)", "Gacha", Vector3.new(-45, 1.8, 0), Color3.fromRGB(168, 85, 247))

    -- Comptoir du Marché (Émeraude)
    CreateAltar("ComptoirMarche", "Hôtel des Ventes", "Ouvrir le Marché (E)", "Market", Vector3.new(45, 1.8, 0), Color3.fromRGB(16, 185, 129))

    -- Porte de l'Arène (Rouge sang)
    CreateAltar("PorteArene", "Porte de l'Arène 1v1", "Rejoindre l'Arène (E)", "Arena", Vector3.new(0, 1.8, 45), Color3.fromRGB(239, 68, 68))

    -- =========================================================================
    -- 5. PNJ LORE : MAÎTRE DES CARTES ELDRIN (GROQ IA)
    -- =========================================================================
    local eldrin = Instance.new("Model")
    eldrin.Name = "Maitre_Eldrin"
    eldrin.Parent = hubFolder

    local eldrinRoot = CreatePart({
        Name = "HumanoidRootPart",
        Size = Vector3.new(2, 2, 1),
        Position = Vector3.new(-10, 2.5, 15),
        Transparency = 1,
        CanCollide = false,
        Parent = eldrin,
    })
    local eldrinTorso = CreatePart({
        Name = "Torso",
        Size = Vector3.new(2, 3, 1),
        Position = Vector3.new(-10, 3, 15),
        Material = Enum.Material.SmoothPlastic,
        Color = Color3.fromRGB(50, 40, 75),
        Parent = eldrin,
    })
    local eldrinHead = CreatePart({
        Name = "Head",
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(1.8, 1.8, 1.8),
        Position = Vector3.new(-10, 5, 15),
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(250, 204, 21),
        Parent = eldrin,
    })

    local eldrinHum = Instance.new("Humanoid")
    eldrinHum.MaxHealth = 500
    eldrinHum.Health = 500
    eldrinHum.Parent = eldrin
    eldrin.PrimaryPart = eldrinRoot

    local eldrinPrompt = Instance.new("ProximityPrompt")
    eldrinPrompt.ObjectText = "Maître Eldrin (Guide IA)"
    eldrinPrompt.ActionText = "Parler (E)"
    eldrinPrompt.HoldDuration = 0
    eldrinPrompt.MaxActivationDistance = 14
    eldrinPrompt.Parent = eldrinRoot
    eldrinRoot:SetAttribute("TargetUI", "NPC_Eldrin")

    -- =========================================================================
    -- 6. COLISÉE CÉLESTE 1V1 (À 100 STUDS D'ALTITUDE)
    -- =========================================================================
    CreatePart({
        Name = "ColosseumFloor",
        Size = Vector3.new(120, 3, 120),
        Position = Vector3.new(0, 100, 0),
        Material = Enum.Material.DiamondPlate,
        Color = Color3.fromRGB(15, 18, 24),
        Parent = hubFolder,
    })

    CreatePart({
        Name = "ColosseumBorder",
        Size = Vector3.new(124, 3.2, 124),
        Position = Vector3.new(0, 100.1, 0),
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(239, 68, 68),
        Transparency = 0.5,
        Parent = hubFolder,
    })

    print("[MapBuilder] Hub Dark Fantasy, 3 Mannequins d'entraînement et Colisée générés avec succès.")
end

return MapBuilder
