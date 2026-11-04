--!strict
--[[
    MAP BUILDER (GÉNÉRATION DU HUB SOUVERAIN & DU COLISÉE CÉLESTE)
    Crée automatiquement le monde 3D procédural : Place Centrale, les 4 Autels interactifs
    (Gacha, Marché, Arène, Mérite) avec ProximityPrompts, et le Colisée 1v1 dans les cieux.
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
    part.Parent = Workspace
    return part
end

function MapBuilder.BuildEnvironment()
    if Workspace:FindFirstChild("SovereignHub") then return end

    local hubFolder = Instance.new("Folder")
    hubFolder.Name = "SovereignHub"
    hubFolder.Parent = Workspace

    -- =========================================================================
    -- 1. ÉCLAIRAGE DARK FANTASY & AMBIANCE CÉLESTE
    -- =========================================================================
    Lighting.Brightness = 2
    Lighting.ClockTime = 20.5 -- Nuit crépusculaire mystique
    Lighting.OutdoorAmbient = Color3.fromRGB(45, 35, 60)
    Lighting.Ambient = Color3.fromRGB(30, 25, 45)

    local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
    bloom.Intensity = 1.2
    bloom.Size = 24
    bloom.Threshold = 0.8

    local colorCorr = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
    colorCorr.Contrast = 0.15
    colorCorr.Saturation = 0.25

    -- =========================================================================
    -- 2. HUB CENTRAL (LE ROYAUME DU SOUVERAIN)
    -- =========================================================================
    -- Sol principal en marbre obsidienne
    local mainFloor = CreatePart({
        Name = "LobbyFloor",
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(4, 180, 180),
        CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Material = Enum.Material.Slate,
        Color = Color3.fromRGB(20, 22, 28),
        Parent = hubFolder,
    })

    -- Anneau d'énergie runique extérieure
    CreatePart({
        Name = "RuneRing",
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(4.2, 190, 190),
        CFrame = CFrame.new(0, -0.1, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(245, 158, 11),
        Transparency = 0.4,
        Parent = hubFolder,
    })

    -- Point d'apparition principal (Spawn)
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "MainSpawn"
    spawn.Size = Vector3.new(16, 1, 16)
    spawn.Position = Vector3.new(0, 1, 0)
    spawn.Anchored = true
    spawn.Material = Enum.Material.Neon
    spawn.Color = Color3.fromRGB(99, 102, 241)
    spawn.Duration = 0
    spawn.Parent = hubFolder

    -- =========================================================================
    -- 3. LES 4 AUTELS INTERACTIFS DU SOUVERAIN
    -- =========================================================================
    local altars = {
        {
            Name = "AutelDuDestin",
            Title = "Autel du Destin (Invocations / Gacha)",
            Action = "Tirer des Cartes",
            UIName = "Gacha",
            Position = Vector3.new(0, 3, -50),
            Color = Color3.fromRGB(168, 85, 247),
            LightColor = Color3.fromRGB(217, 70, 239),
        },
        {
            Name = "HotelDesVentes",
            Title = "Hôtel des Ventes (Marché & Trading)",
            Action = "Consulter la Bourse",
            UIName = "Market",
            Position = Vector3.new(50, 3, 0),
            Color = Color3.fromRGB(16, 185, 129),
            LightColor = Color3.fromRGB(52, 211, 153),
        },
        {
            Name = "AreneDuMerite",
            Title = "Porte de l'Arène Compétitive",
            Action = "Rejoindre la File 1v1",
            UIName = "Arena",
            Position = Vector3.new(0, 3, 50),
            Color = Color3.fromRGB(239, 68, 68),
            LightColor = Color3.fromRGB(248, 113, 113),
        },
        {
            Name = "SanctuaireDuMerite",
            Title = "Sanctuaire du Mérite (Forge Prestige)",
            Action = "Transcender une Carte",
            UIName = "Merit",
            Position = Vector3.new(-50, 3, 0),
            Color = Color3.fromRGB(245, 158, 11),
            LightColor = Color3.fromRGB(251, 191, 36),
        },
    }

    for _, altarInfo in ipairs(altars) do
        -- Base de l'autel
        local base = CreatePart({
            Name = altarInfo.Name,
            Size = Vector3.new(10, 4, 10),
            Position = altarInfo.Position,
            Material = Enum.Material.Cobblestone,
            Color = Color3.fromRGB(30, 32, 40),
            Parent = hubFolder,
        })

        -- Cristal flottant au-dessus
        local crystal = CreatePart({
            Name = "Crystal",
            Size = Vector3.new(3, 6, 3),
            Position = altarInfo.Position + Vector3.new(0, 5, 0),
            Material = Enum.Material.Neon,
            Color = altarInfo.Color,
            Parent = base,
        })

        -- Lumière dynamique
        local light = Instance.new("PointLight")
        light.Color = altarInfo.LightColor
        light.Range = 25
        light.Brightness = 3
        light.Parent = crystal

        -- ProximityPrompt pour l'ouverture UI
        local prompt = Instance.new("ProximityPrompt")
        prompt.ObjectText = altarInfo.Title
        prompt.ActionText = altarInfo.Action
        prompt.KeyboardKeyCode = Enum.KeyCode.E
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 14
        prompt.Parent = base

        -- Attribut permettant au client de savoir quel onglet ouvrir
        base:SetAttribute("TargetUI", altarInfo.UIName)
    end

    -- =========================================================================
    -- 4. MANNEQUINS D'ENTRAÎNEMENT & SPAR-BOTS
    -- =========================================================================
    local function SpawnDummy(name: string, position: Vector3, isParryTrainer: boolean)
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
            Size = Vector3.new(2, 2.5, 1),
            Position = position + Vector3.new(0, 3, 0),
            Material = Enum.Material.WoodPlanks,
            Color = isParryTrainer and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(160, 120, 80),
            Parent = dummy,
        })

        local head = CreatePart({
            Name = "Head",
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(1.6, 1.6, 1.6),
            Position = position + Vector3.new(0, 5, 0),
            Material = Enum.Material.Neon,
            Color = isParryTrainer and Color3.fromRGB(250, 204, 21) or Color3.fromRGB(220, 220, 230),
            Parent = dummy,
        })

        local hum = Instance.new("Humanoid")
        hum.MaxHealth = 1000
        hum.Health = 1000
        hum.Parent = dummy

        dummy.PrimaryPart = root

        -- Boucle d'auto-régénération
        task.spawn(function()
            while dummy.Parent do
                task.wait(2.5)
                if hum.Health < hum.MaxHealth then
                    hum.Health = hum.MaxHealth
                end
            end
        end)

        -- Si mannequin de parade : attaque cadencée pour s'entraîner au Parry
        if isParryTrainer then
            task.spawn(function()
                while dummy.Parent do
                    task.wait(4)
                    -- Flash d'avertissement
                    head.Color = Color3.fromRGB(239, 68, 68)
                    task.wait(0.7)
                    -- Attaque
                    head.Color = Color3.fromRGB(250, 204, 21)
                    local hitRadius = 10
                    local nearby = workspace:GetPartBoundsInRadius(root.Position, hitRadius)
                    for _, p in ipairs(nearby) do
                        local m = p:FindFirstAncestorOfClass("Model")
                        if m and m ~= dummy then
                            local targetHum = m:FindFirstChildOfClass("Humanoid")
                            if targetHum and targetHum.Health > 0 then
                                -- Vérifie si le joueur pare
                                local pl = game.Players:GetPlayerFromCharacter(m)
                                local didParry = false
                                if pl then
                                    local cs = require(script.Parent.CombatService)
                                    -- Si le joueur est en fenêtre de parade
                                    -- Il contre-attaquera via CombatService
                                end
                                targetHum:TakeDamage(10)
                            end
                        end
                    end
                end
            end)
        end
    end

    SpawnDummy("Mannequin_DPS", Vector3.new(25, 2, 25), false)
    SpawnDummy("Garde_Entrainement_Parry", Vector3.new(-25, 2, 25), true)

    -- =========================================================================
    -- 5. LE COLISÉE CÉLESTE (ARÈNE DE DUEL 1V1)
    -- =========================================================================
    local arenaHeight = 100
    local arenaFloor = CreatePart({
        Name = "ArenaFloor",
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(4, 140, 140),
        CFrame = CFrame.new(0, arenaHeight, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Material = Enum.Material.DiamondPlate,
        Color = Color3.fromRGB(15, 17, 23),
        Parent = hubFolder,
    })

    -- Dôme de protection / Barrière d'énergie
    local barrier = CreatePart({
        Name = "ArenaBarrier",
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(40, 142, 142),
        CFrame = CFrame.new(0, arenaHeight + 18, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Material = Enum.Material.ForceField,
        Color = Color3.fromRGB(239, 68, 68),
        Transparency = 0.85,
        CanCollide = true,
        Parent = hubFolder,
    })

    -- Piliers lumineux du Colisée
    for angle = 0, 315, 45 do
        local rad = math.rad(angle)
        local px = math.cos(rad) * 65
        local pz = math.sin(rad) * 65
        CreatePart({
            Name = "Pillar_" .. angle,
            Size = Vector3.new(4, 30, 4),
            Position = Vector3.new(px, arenaHeight + 15, pz),
            Material = Enum.Material.Neon,
            Color = Color3.fromRGB(245, 158, 11),
            Parent = hubFolder,
        })
    end

    print("[MapBuilder] Hub du Souverain et Colisée Céleste générés avec succès.")
end

return MapBuilder
