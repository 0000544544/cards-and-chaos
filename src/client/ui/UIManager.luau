--!strict
--[[
    UI MANAGER (INTERFACE DARK FANTASY & NEON GLASSMORPHISM)
    Génération procédurale complète du HUD, barre de navigation, modales (Deck, Gacha, Marché, Échange, Arène, Mérite),
    HUD de combat 1v1 avec barres de recharge, toasts et bannières d'annonces mondiales.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Shared.NetworkEvents)
local RarityConfig = require(ReplicatedStorage.Shared.RarityConfig)
local CardsData = require(ReplicatedStorage.Shared.CardsData)
local RankConfig = require(ReplicatedStorage.Shared.RankConfig)
local PackOpeningController = require(script.Parent.Parent.PackOpeningController)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

local UIManager = {}

-- Variables d'état local
local CachedData: any = nil
local CurrentTab: string? = nil

-- Références UI
local ScreenGui: ScreenGui
local TopBar: Frame
local ModalContainer: Frame
local ModalTitle: TextLabel
local ModalContent: Frame
local ArenaHUD: Frame
local BannerFrame: Frame
local ToastContainer: Frame

-- Fonction utilitaire de création d'éléments UI avec style uniforme
local function CreateUI(className: string, properties: { [string]: any }): any
    local inst = Instance.new(className)
    for k, v in pairs(properties) do
        (inst :: any)[k] = v
    end
    return inst
end

local function ApplyCorner(instance: Instance, radius: number?)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = instance
end

local function ApplyStroke(instance: Instance, color: Color3, thickness: number?)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness or 1.5
    stroke.Parent = instance
end

-- =============================================================================
-- SYSTÈME DE TOAST & BANNIÈRE MONDIALE
-- =============================================================================
function UIManager.ShowToast(message: string, isError: boolean?)
    local toast = CreateUI("TextLabel", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = isError and Color3.fromRGB(185, 28, 28) or Color3.fromRGB(30, 41, 59),
        TextColor3 = Color3.fromRGB(248, 250, 252),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        Text = message,
        TextTransparency = 1,
        Parent = ToastContainer,
    })
    ApplyCorner(toast, 6)
    ApplyStroke(toast, isError and Color3.fromRGB(239, 68, 68) or Color3.fromRGB(71, 85, 105), 1)

    local tweenIn = TweenService:Create(toast, TweenInfo.new(0.25), { TextTransparency = 0 })
    tweenIn:Play()

    task.delay(3.5, function()
        local tweenOut = TweenService:Create(toast, TweenInfo.new(0.3), { TextTransparency = 1 })
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            toast:Destroy()
        end)
    end)
end

function UIManager.ShowServerAnnouncement(data: any)
    local text = "✨ [ANNONCE MONDIALE] " .. data.PlayerName .. " a tiré " .. data.CardName .. " (" .. data.Rarity .. ") !"
    local banner = CreateUI("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(15, 23, 42),
        BackgroundTransparency = 0.1,
        TextColor3 = data.IsDivine and Color3.fromRGB(250, 204, 21) or Color3.fromRGB(248, 113, 113),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        Text = text,
        Parent = BannerFrame,
    })
    ApplyCorner(banner, 8)
    ApplyStroke(banner, data.RarityColor or Color3.fromRGB(250, 204, 21), 2)

    BannerFrame.Position = UDim2.new(0.5, -300, 0, -60)
    BannerFrame.Visible = true

    local tweenDown = TweenService:Create(BannerFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -300, 0, 70),
    })
    tweenDown:Play()

    task.delay(5, function()
        local tweenUp = TweenService:Create(BannerFrame, TweenInfo.new(0.4), {
            Position = UDim2.new(0.5, -300, 0, -60),
        })
        tweenUp:Play()
        tweenUp.Completed:Connect(function()
            banner:Destroy()
            BannerFrame.Visible = false
        end)
    end)
end

-- Chiffres de dégâts 3D flottants au-dessus de la cible
function UIManager.ShowDamageNumber(pos: Vector3, damage: number, isPrestige: boolean, color: Color3)
    local part = Instance.new("Part")
    part.Size = Vector3.new(1, 1, 1)
    part.Position = pos + Vector3.new(math.random(-10, 10) * 0.08, 0, math.random(-10, 10) * 0.08)
    part.Transparency = 1
    part.Anchored = true
    part.CanCollide = false
    part.Parent = workspace

    local bg = Instance.new("BillboardGui")
    bg.Size = UDim2.new(0, 150, 0, 40)
    bg.AlwaysOnTop = true
    bg.Adornee = part
    bg.Parent = part

    local label = CreateUI("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = (isPrestige and "💥 -" or "-") .. tostring(damage) .. (isPrestige and " [PRESTIGE]" or ""),
        TextColor3 = color,
        Font = Enum.Font.GothamBold,
        TextSize = isPrestige and 24 or 18,
        Parent = bg,
    })
    ApplyStroke(label, Color3.fromRGB(0, 0, 0), 2)

    local tween = TweenService:Create(part, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = part.Position + Vector3.new(0, 4.5, 0),
    })
    local fade = TweenService:Create(label, TweenInfo.new(0.85), {
        TextTransparency = 1,
    })
    tween:Play()
    fade:Play()

    task.delay(0.9, function()
        part:Destroy()
    end)
end

-- =============================================================================
-- RAFRAÎCHISSEMENT DU HUD SUPÉRIEUR (MONNAIE, ÉLO, MÉRITE)
-- =============================================================================
function UIManager.RefreshTopBar()
    if not CachedData then return end

    local coinsLabel = TopBar:FindFirstChild("CoinsLabel") :: TextLabel?
    if coinsLabel then
        coinsLabel.Text = "🪙 " .. string.format("%d", CachedData.Coins) .. " Or"
    end

    local meritLabel = TopBar:FindFirstChild("MeritLabel") :: TextLabel?
    if meritLabel then
        meritLabel.Text = "⚡ " .. string.format("%d", CachedData.Merit) .. " Mérite"
    end

    local eloLabel = TopBar:FindFirstChild("EloLabel") :: TextLabel?
    if eloLabel then
        local tier = RankConfig.GetTierFromElo(CachedData.Elo)
        eloLabel.Text = "🏆 " .. tier.Name .. " (" .. CachedData.Elo .. " Elo)"
        eloLabel.TextColor3 = tier.Color
    end

    local streakLabel = TopBar:FindFirstChild("StreakLabel") :: TextLabel?
    if streakLabel then
        local streak = (CachedData.Stats and CachedData.Stats.CurrentStreak) or 0
        streakLabel.Text = "🔥 Série : " .. streak
    end
end

-- =============================================================================
-- CONTENUS DES ONGLETS
-- =============================================================================

-- 1. ONGLET DECK (INVENTAIRE, ÉQUIPEMENT & SYNERGIES)
local function RenderDeckTab()
    ModalContent:ClearAllChildren()

    local activeDeckFrame = CreateUI("Frame", {
        Size = UDim2.new(1, 0, 0, 110),
        BackgroundColor3 = Color3.fromRGB(15, 23, 42),
        BackgroundTransparency = 0.5,
        Parent = ModalContent,
    })
    ApplyCorner(activeDeckFrame, 8)
    ApplyStroke(activeDeckFrame, Color3.fromRGB(51, 65, 85))

    local title = CreateUI("TextLabel", {
        Size = UDim2.new(1, -20, 0, 24),
        Position = UDim2.new(0, 10, 0, 5),
        BackgroundTransparency = 1,
        Text = "DECK ACTIF (4 Compétences + 2 Passives) :",
        TextColor3 = Color3.fromRGB(203, 213, 225),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = activeDeckFrame,
    })

    -- Affichage des 4 slots actifs
    for slot = 1, 4 do
        local uid = CachedData.EquippedDeck.Actives[slot]
        local cardName = "[Vide]"
        local cardColor = Color3.fromRGB(100, 116, 139)
        if uid then
            for _, c in ipairs(CachedData.Inventory) do
                if c.UniqueId == uid then
                    local def = CardsData.GetCard(c.CardId)
                    if def then
                        cardName = def.Name
                        local rInfo = RarityConfig.Rarities[def.Rarity]
                        if rInfo then cardColor = rInfo.Color end
                    end
                    break
                end
            end
        end

        local slotBtn = CreateUI("TextButton", {
            Size = UDim2.new(0.15, -6, 0, 60),
            Position = UDim2.new((slot - 1) * 0.16 + 0.01, 0, 0, 35),
            BackgroundColor3 = Color3.fromRGB(30, 41, 59),
            TextColor3 = cardColor,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextWrapped = true,
            Text = tostring(slot) .. "\n" .. cardName,
            Parent = activeDeckFrame,
        })
        ApplyCorner(slotBtn, 6)
        ApplyStroke(slotBtn, cardColor, 1.5)
    end

    -- Grille de toutes les cartes possédées
    local scroll = CreateUI("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -125),
        Position = UDim2.new(0, 0, 0, 120),
        BackgroundTransparency = 1,
        ScrollBarThickness = 6,
        CanvasSize = UDim2.new(0, 0, 0, math.ceil(#CachedData.Inventory / 4) * 90),
        Parent = ModalContent,
    })

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.23, 0, 0, 80)
    grid.CellPadding = UDim2.new(0.02, 0, 0, 8)
    grid.Parent = scroll

    for _, c in ipairs(CachedData.Inventory) do
        local def = CardsData.GetCard(c.CardId)
        if def then
            local rInfo = RarityConfig.Rarities[def.Rarity]
            local cardFrame = CreateUI("TextButton", {
                BackgroundColor3 = Color3.fromRGB(30, 41, 59),
                TextColor3 = rInfo.Color,
                Font = Enum.Font.GothamMedium,
                TextSize = 11,
                TextWrapped = true,
                Text = def.Name .. "\n(" .. rInfo.Name .. ")" .. (c.Prestige and " [PRESTIGE]" or ""),
                Parent = scroll,
            })
            ApplyCorner(cardFrame, 6)
            ApplyStroke(cardFrame, rInfo.Color, c.Prestige and 2.5 or 1)

            -- Clic pour équiper
            cardFrame.MouseButton1Click:Connect(function()
                if def.Type == "Active" then
                    -- Équipe dans le premier slot disponible
                    table.remove(CachedData.EquippedDeck.Actives, 1)
                    table.insert(CachedData.EquippedDeck.Actives, c.UniqueId)
                else
                    table.remove(CachedData.EquippedDeck.Passives, 1)
                    table.insert(CachedData.EquippedDeck.Passives, c.UniqueId)
                end
                local equipRF = Network.GetFunction("EquipDeck")
                equipRF:InvokeServer(CachedData.EquippedDeck)
                UIManager.ShowToast("Deck mis à jour : " .. def.Name .. " équipé !")
                RenderDeckTab()
            end)
        end
    end
end

-- 2. ONGLET GACHA (BOUTIQUE DE PACKS & TRANSPARENCE ROBLOX)
local function RenderGachaTab()
    ModalContent:ClearAllChildren()

    local altarCard = CreateUI("Frame", {
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = Color3.fromRGB(24, 24, 38),
        Parent = ModalContent,
    })
    ApplyCorner(altarCard, 10)
    ApplyStroke(altarCard, Color3.fromRGB(168, 85, 247), 1.5)

    CreateUI("TextLabel", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundTransparency = 1,
        Text = "⚡ OUVERTURE DE PACKS - PROBABILITÉS TRANSPARENTES ⚡",
        TextColor3 = Color3.fromRGB(245, 158, 11),
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        Parent = altarCard,
    })

    CreateUI("TextLabel", {
        Size = UDim2.new(1, 0, 0, 25),
        Position = UDim2.new(0, 0, 0, 38),
        BackgroundTransparency = 1,
        Text = "Protection Pity active : 1 Légendaire garantie au 50ème paquet | Taux certifiés conformes",
        TextColor3 = Color3.fromRGB(148, 163, 184),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        Parent = altarCard,
    })

    -- Liste des 3 Packs
    local packContainer = CreateUI("Frame", {
        Size = UDim2.new(1, 0, 1, -85),
        Position = UDim2.new(0, 0, 0, 80),
        BackgroundTransparency = 1,
        Parent = ModalContent,
    })

    local packList = {
        {
            Id = "starter_pack",
            Name = "Pack Débutant",
            Cost = 100,
            Odds = "Commun: 60% | Rare: 25% | Épique: 11% | Légendaire: 4%",
            Color = Color3.fromRGB(79, 70, 229),
        },
        {
            Id = "chaos_pack",
            Name = "Pack Chaos",
            Cost = 500,
            Odds = "Commun: 30% | Rare: 42% | Épique: 20% | Légendaire: 8%",
            Color = Color3.fromRGB(217, 70, 239),
        },
        {
            Id = "sovereign_pack",
            Name = "Pack du Souverain",
            Cost = 1500,
            Odds = "0% Commun | Rare: 35% | Épique: 45% | Légendaire: 20%",
            Color = Color3.fromRGB(245, 158, 11),
        },
    }

    local function TriggerOpenPack(packId: string)
        local openPackRF = Network.GetFunction("RequestOpenPack")
        local res = openPackRF:InvokeServer(packId)
        if res.Success and res.Card then
            UIManager.CloseModal()
            PackOpeningController.PlayRevealAnimation(res.Card, function()
                UIManager.FetchData()
                UIManager.ShowToast("✨ " .. res.Card.Name .. " (" .. res.Card.Rarity .. ") ajouté à votre inventaire !")
            end)
        else
            UIManager.ShowToast(res.Error or "Échec de l'ouverture du pack", true)
        end
    end

    for pIdx, pInfo in ipairs(packList) do
        local packCard = CreateUI("Frame", {
            Size = UDim2.new(0.31, 0, 0, 220),
            Position = UDim2.new((pIdx - 1) * 0.34 + 0.01, 0, 0, 10),
            BackgroundColor3 = Color3.fromRGB(30, 41, 59),
            Parent = packContainer,
        })
        ApplyCorner(packCard, 10)
        ApplyStroke(packCard, pInfo.Color, 2)

        CreateUI("TextLabel", {
            Size = UDim2.new(1, -10, 0, 36),
            Position = UDim2.new(0, 5, 0, 10),
            BackgroundTransparency = 1,
            Text = pInfo.Name,
            TextColor3 = pInfo.Color,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            Parent = packCard,
        })

        CreateUI("TextLabel", {
            Size = UDim2.new(1, -16, 0, 70),
            Position = UDim2.new(0, 8, 0, 50),
            BackgroundTransparency = 1,
            Text = "Taux garantis :\n" .. pInfo.Odds,
            TextColor3 = Color3.fromRGB(203, 213, 225),
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextWrapped = true,
            Parent = packCard,
        })

        local openBtn = CreateUI("TextButton", {
            Size = UDim2.new(1, -20, 0, 44),
            Position = UDim2.new(0, 10, 1, -55),
            BackgroundColor3 = pInfo.Color,
            TextColor3 = Color3.fromRGB(15, 23, 42),
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            Text = "OUVRIR (" .. pInfo.Cost .. " Or)",
            Parent = packCard,
        })
        ApplyCorner(openBtn, 8)

        openBtn.MouseButton1Click:Connect(function()
            TriggerOpenPack(pInfo.Id)
        end)
    end
end

-- 3. ONGLET MARCHÉ (HÔTEL DES VENTES & ACHAT-REVENTE)
local function RenderMarketTab()
    ModalContent:ClearAllChildren()

    local header = CreateUI("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = Color3.fromRGB(15, 23, 42),
        Parent = ModalContent,
    })
    ApplyCorner(header, 6)

    CreateUI("TextLabel", {
        Size = UDim2.new(0.6, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "BOURSE DES CARTES (Taxe 5% - Anti-Inflation)",
        TextColor3 = Color3.fromRGB(52, 211, 153),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })

    -- Bouton de mise en vente
    local sellBtn = CreateUI("TextButton", {
        Size = UDim2.new(0.35, -10, 0, 36),
        Position = UDim2.new(0.65, 0, 0, 7),
        BackgroundColor3 = Color3.fromRGB(16, 185, 129),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Text = "+ Mettre en Vente",
        Parent = header,
    })
    ApplyCorner(sellBtn, 6)

    local listingsScroll = CreateUI("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -65),
        Position = UDim2.new(0, 0, 0, 60),
        BackgroundTransparency = 1,
        ScrollBarThickness = 6,
        CanvasSize = UDim2.new(0, 0, 0, 400),
        Parent = ModalContent,
    })

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.Parent = listingsScroll

    local getListingsRF = Network.GetFunction("GetMarketListings")
    local listings = getListingsRF:InvokeServer() or {}

    if #listings == 0 then
        CreateUI("TextLabel", {
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundTransparency = 1,
            Text = "Aucune carte en vente pour le moment. Soyez le premier à commercer !",
            TextColor3 = Color3.fromRGB(148, 163, 184),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            Parent = listingsScroll,
        })
    end

    for _, l in ipairs(listings) do
        local def = CardsData.GetCard(l.CardInstance.CardId)
        if def then
            local rInfo = RarityConfig.Rarities[def.Rarity]
            local row = CreateUI("Frame", {
                Size = UDim2.new(1, -10, 0, 48),
                BackgroundColor3 = Color3.fromRGB(30, 41, 59),
                Parent = listingsScroll,
            })
            ApplyCorner(row, 6)
            ApplyStroke(row, rInfo.Color, 1)

            CreateUI("TextLabel", {
                Size = UDim2.new(0.4, 0, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = rInfo.Color,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = def.Name .. " (" .. rInfo.Name .. ")",
                Parent = row,
            })

            CreateUI("TextLabel", {
                Size = UDim2.new(0.25, 0, 1, 0),
                Position = UDim2.new(0.4, 0, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(148, 163, 184),
                Font = Enum.Font.Gotham,
                TextSize = 11,
                Text = "Par : " .. l.SellerName,
                Parent = row,
            })

            local buyBtn = CreateUI("TextButton", {
                Size = UDim2.new(0.25, 0, 0, 32),
                Position = UDim2.new(0.72, 0, 0, 8),
                BackgroundColor3 = Color3.fromRGB(5, 150, 105),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                Text = "Acheter (" .. l.PriceCoins .. " Or)",
                Parent = row,
            })
            ApplyCorner(buyBtn, 6)

            buyBtn.MouseButton1Click:Connect(function()
                local buyRF = Network.GetFunction("BuyMarketItem")
                local res = buyRF:InvokeServer(l.ListingId)
                if res.Success then
                    UIManager.ShowToast("Achat réussi !")
                    UIManager.FetchData()
                    RenderMarketTab()
                else
                    UIManager.ShowToast(res.Error or "Échec de l'achat", true)
                end
            end)
        end
    end

    sellBtn.MouseButton1Click:Connect(function()
        -- Mise en vente de la première carte disponible non équipée
        if #CachedData.Inventory > 0 then
            local cardToSell = CachedData.Inventory[1]
            local listRF = Network.GetFunction("ListMarketItem")
            local res = listRF:InvokeServer(cardToSell.UniqueId, 250)
            if res.Success then
                UIManager.ShowToast("Carte mise en vente pour 250 Or !")
                UIManager.FetchData()
                RenderMarketTab()
            else
                UIManager.ShowToast(res.Error or "Erreur de mise en vente", true)
            end
        else
            UIManager.ShowToast("Aucune carte à vendre.", true)
        end
    end)
end

-- 4. ONGLET ARÈNE (1V1 COMPÉTITIF)
local function RenderArenaTab()
    ModalContent:ClearAllChildren()

    local arenaCard = CreateUI("Frame", {
        Size = UDim2.new(1, 0, 0, 220),
        BackgroundColor3 = Color3.fromRGB(24, 24, 38),
        Parent = ModalContent,
    })
    ApplyCorner(arenaCard, 10)
    ApplyStroke(arenaCard, Color3.fromRGB(239, 68, 68), 2)

    CreateUI("TextLabel", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Text = "⚔️ ARÈNE COMPÉTITIVE 1V1 DU SOUVERAIN ⚔️",
        TextColor3 = Color3.fromRGB(248, 113, 113),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        Parent = arenaCard,
    })

    local tier = RankConfig.GetTierFromElo(CachedData.Elo)
    CreateUI("TextLabel", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 45),
        BackgroundTransparency = 1,
        Text = "Votre Rang : " .. tier.Name .. " | Elo : " .. CachedData.Elo,
        TextColor3 = tier.Color,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = arenaCard,
    })

    local joinBtn = CreateUI("TextButton", {
        Size = UDim2.new(0.7, 0, 0, 56),
        Position = UDim2.new(0.15, 0, 0, 95),
        BackgroundColor3 = Color3.fromRGB(220, 38, 38),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        Text = "REJOINDRE LA FILE 1V1",
        Parent = arenaCard,
    })
    ApplyCorner(joinBtn, 10)

    joinBtn.MouseButton1Click:Connect(function()
        local joinRF = Network.GetFunction("JoinArenaQueue")
        local res = joinRF:InvokeServer()
        UIManager.ShowToast(res.Message or "Recherche d'un adversaire...")
        UIManager.CloseModal()
    end)
end

-- 5. ONGLET MÉRITE & PRESTIGE
local function RenderMeritTab()
    ModalContent:ClearAllChildren()

    local meritCard = CreateUI("Frame", {
        Size = UDim2.new(1, 0, 0, 160),
        BackgroundColor3 = Color3.fromRGB(24, 24, 38),
        Parent = ModalContent,
    })
    ApplyCorner(meritCard, 10)
    ApplyStroke(meritCard, Color3.fromRGB(245, 158, 11), 2)

    CreateUI("TextLabel", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Text = "⚡ SANCTUAIRE DU MÉRITE & FORGE DE PRESTIGE ⚡",
        TextColor3 = Color3.fromRGB(251, 191, 36),
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        Parent = meritCard,
    })

    CreateUI("TextLabel", {
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 45),
        BackgroundTransparency = 1,
        Text = "Points de Mérite disponibles : " .. CachedData.Merit .. "\n(Coût de transcendance : 500 Mérite)",
        TextColor3 = Color3.fromRGB(203, 213, 225),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        Parent = meritCard,
    })

    local prestigeBtn = CreateUI("TextButton", {
        Size = UDim2.new(0.6, 0, 0, 44),
        Position = UDim2.new(0.2, 0, 0, 100),
        BackgroundColor3 = Color3.fromRGB(217, 119, 6),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        Text = "TRANSCENDER UNE CARTE (+20%)",
        Parent = meritCard,
    })
    ApplyCorner(prestigeBtn, 8)

    prestigeBtn.MouseButton1Click:Connect(function()
        -- Transcende la première carte non prestige
        local targetUid: string? = nil
        for _, c in ipairs(CachedData.Inventory) do
            if not c.Prestige then
                targetUid = c.UniqueId
                break
            end
        end

        if targetUid then
            local prestigeRF = Network.GetFunction("PrestigeCard")
            local res = prestigeRF:InvokeServer(targetUid)
            if res.Success then
                UIManager.FetchData()
                RenderMeritTab()
            else
                UIManager.ShowToast(res.Error or "Échec de transcendance", true)
            end
        else
            UIManager.ShowToast("Aucune carte éligible.", true)
        end
    end)
end

-- =============================================================================
-- GESTION DE L'OUVERTURE / FERMETURE DES MODALES
-- =============================================================================
function UIManager.OpenTab(tabName: string)
    CurrentTab = tabName
    ModalContainer.Visible = true

    if tabName == "Deck" then
        ModalTitle.Text = "MON CODEX & DECK DE COMBAT"
        RenderDeckTab()
    elseif tabName == "Gacha" then
        ModalTitle.Text = "AUTEL DU DESTIN (INVOCATIONS)"
        RenderGachaTab()
    elseif tabName == "Market" then
        ModalTitle.Text = "HÔTEL DES VENTES & TRADING"
        RenderMarketTab()
    elseif tabName == "Arena" then
        ModalTitle.Text = "ARÈNE COMPÉTITIVE 1V1"
        RenderArenaTab()
    elseif tabName == "Merit" then
        ModalTitle.Text = "SANCTUAIRE DU MÉRITE"
        RenderMeritTab()
    end
end

function UIManager.CloseModal()
    ModalContainer.Visible = false
    CurrentTab = nil
end

-- Récupération du profil auprès du serveur
function UIManager.FetchData()
    local getProfRF = Network.GetFunction("GetPlayerData")
    CachedData = getProfRF:InvokeServer()
    UIManager.RefreshTopBar()
end

-- =============================================================================
-- INITIALISATION COMPLÈTE DE L'INTERFACE
-- =============================================================================
function UIManager.Init()
    ScreenGui = CreateUI("ScreenGui", {
        Name = "SovereignUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = playerGui,
    })

    -- 1. Toast Container
    ToastContainer = CreateUI("Frame", {
        Size = UDim2.new(0, 320, 0, 300),
        Position = UDim2.new(1, -340, 1, -320),
        BackgroundTransparency = 1,
        Parent = ScreenGui,
    })
    local toastLayout = Instance.new("UIListLayout")
    toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    toastLayout.Padding = UDim.new(0, 8)
    toastLayout.Parent = ToastContainer

    -- 2. Banner Frame
    BannerFrame = CreateUI("Frame", {
        Size = UDim2.new(0, 600, 0, 50),
        Position = UDim2.new(0.5, -300, 0, -60),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = ScreenGui,
    })

    -- 3. TopBar (Coins, Merit, Elo, Streak)
    TopBar = CreateUI("Frame", {
        Size = UDim2.new(1, -40, 0, 48),
        Position = UDim2.new(0, 20, 0, 14),
        BackgroundColor3 = Color3.fromRGB(15, 23, 42),
        BackgroundTransparency = 0.25,
        Parent = ScreenGui,
    })
    ApplyCorner(TopBar, 10)
    ApplyStroke(TopBar, Color3.fromRGB(51, 65, 85), 1.5)

    CreateUI("TextLabel", {
        Name = "CoinsLabel",
        Size = UDim2.new(0.25, 0, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(245, 158, 11),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "🪙 0 Or",
        Parent = TopBar,
    })

    CreateUI("TextLabel", {
        Name = "MeritLabel",
        Size = UDim2.new(0.25, 0, 1, 0),
        Position = UDim2.new(0.26, 0, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(56, 189, 248),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "⚡ 0 Mérite",
        Parent = TopBar,
    })

    CreateUI("TextLabel", {
        Name = "EloLabel",
        Size = UDim2.new(0.25, 0, 1, 0),
        Position = UDim2.new(0.52, 0, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(250, 204, 21),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "🏆 Bronze (1000 Elo)",
        Parent = TopBar,
    })

    CreateUI("TextLabel", {
        Name = "StreakLabel",
        Size = UDim2.new(0.2, 0, 1, 0),
        Position = UDim2.new(0.78, 0, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(248, 113, 113),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "🔥 Série : 0",
        Parent = TopBar,
    })

    -- 4. Barre de Navigation Inférieure
    local navBar = CreateUI("Frame", {
        Size = UDim2.new(0, 680, 0, 52),
        Position = UDim2.new(0.5, -340, 1, -70),
        BackgroundColor3 = Color3.fromRGB(15, 23, 42),
        BackgroundTransparency = 0.25,
        Parent = ScreenGui,
    })
    ApplyCorner(navBar, 12)
    ApplyStroke(navBar, Color3.fromRGB(71, 85, 105), 1.5)

    local navTabs = {
        { Id = "Deck", Text = "⚔️ DECK" },
        { Id = "Gacha", Text = "🎰 INVOCATION" },
        { Id = "Market", Text = "⚖️ MARCHÉ" },
        { Id = "Arena", Text = "🏆 ARÈNE" },
        { Id = "Merit", Text = "✨ MÉRITE" },
    }

    for i, tab in ipairs(navTabs) do
        local btn = CreateUI("TextButton", {
            Size = UDim2.new(0.18, 0, 0, 38),
            Position = UDim2.new((i - 1) * 0.20 + 0.01, 0, 0, 7),
            BackgroundColor3 = Color3.fromRGB(30, 41, 59),
            TextColor3 = Color3.fromRGB(241, 245, 249),
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            Text = tab.Text,
            Parent = navBar,
        })
        ApplyCorner(btn, 8)

        btn.MouseButton1Click:Connect(function()
            if CurrentTab == tab.Id and ModalContainer.Visible then
                UIManager.CloseModal()
            else
                UIManager.OpenTab(tab.Id)
            end
        end)
    end

    -- 5. Conteneur de Modale Centré
    ModalContainer = CreateUI("Frame", {
        Size = UDim2.new(0, 720, 0, 480),
        Position = UDim2.new(0.5, -360, 0.5, -240),
        BackgroundColor3 = Color3.fromRGB(15, 23, 42),
        BackgroundTransparency = 0.08,
        Visible = false,
        Parent = ScreenGui,
    })
    ApplyCorner(ModalContainer, 12)
    ApplyStroke(ModalContainer, Color3.fromRGB(99, 102, 241), 2)

    ModalTitle = CreateUI("TextLabel", {
        Size = UDim2.new(1, -60, 0, 44),
        Position = UDim2.new(0, 20, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(248, 250, 252),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = ModalContainer,
    })

    local closeBtn = CreateUI("TextButton", {
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -44, 0, 6),
        BackgroundColor3 = Color3.fromRGB(239, 68, 68),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Text = "X",
        Parent = ModalContainer,
    })
    ApplyCorner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(UIManager.CloseModal)

    ModalContent = CreateUI("Frame", {
        Size = UDim2.new(1, -30, 1, -65),
        Position = UDim2.new(0, 15, 0, 50),
        BackgroundTransparency = 1,
        Parent = ModalContainer,
    })

    -- 6. HUD de Combat en Arène (Cooldowns 1-4, Dash, Parry)
    ArenaHUD = CreateUI("Frame", {
        Size = UDim2.new(0, 380, 0, 60),
        Position = UDim2.new(0.5, -190, 1, -140),
        BackgroundColor3 = Color3.fromRGB(15, 23, 42),
        BackgroundTransparency = 0.3,
        Parent = ScreenGui,
    })
    ApplyCorner(ArenaHUD, 10)
    ApplyStroke(ArenaHUD, Color3.fromRGB(71, 85, 105))

    local slots = { "1", "2", "3", "4", "Q\nDash", "F\nParry" }
    for sIdx, slotText in ipairs(slots) do
        local slotFrame = CreateUI("TextLabel", {
            Size = UDim2.new(0, 48, 0, 48),
            Position = UDim2.new((sIdx - 1) * 0.16 + 0.02, 0, 0, 6),
            BackgroundColor3 = Color3.fromRGB(30, 41, 59),
            TextColor3 = Color3.fromRGB(226, 232, 240),
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            Text = slotText,
            Parent = ArenaHUD,
        })
        ApplyCorner(slotFrame, 8)
        ApplyStroke(slotFrame, Color3.fromRGB(99, 102, 241), 1)
    end

    -- Écouteurs Réseau
    local toastRE = Network.GetEvent("ToastNotify")
    toastRE.OnClientEvent:Connect(function(msg, isErr)
        UIManager.ShowToast(msg, isErr)
    end)

    local dmgRE = Network.GetEvent("DamageIndicator")
    dmgRE.OnClientEvent:Connect(function(data)
        if data and data.Position and data.Damage then
            UIManager.ShowDamageNumber(data.Position, data.Damage, data.IsPrestige or false, data.Color or Color3.fromRGB(255, 255, 255))
        end
    end)

    local annRE = Network.GetEvent("ServerAnnouncement")
    annRE.OnClientEvent:Connect(function(data)
        UIManager.ShowServerAnnouncement(data)
    end)

    -- Panneau Développeur / Enroules de Test (Bouton Rapide)
    local devBtn = CreateUI("TextButton", {
        Size = UDim2.new(0, 110, 0, 32),
        Position = UDim2.new(1, -130, 0, 22),
        BackgroundColor3 = Color3.fromRGB(147, 51, 234),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        Text = "⚡ ENROULES DEV",
        Parent = ScreenGui,
    })
    ApplyCorner(devBtn, 6)

    local devPanel = CreateUI("Frame", {
        Size = UDim2.new(0, 220, 0, 200),
        Position = UDim2.new(1, -240, 0, 60),
        BackgroundColor3 = Color3.fromRGB(15, 23, 42),
        BackgroundTransparency = 0.1,
        Visible = false,
        Parent = ScreenGui,
    })
    ApplyCorner(devPanel, 8)
    ApplyStroke(devPanel, Color3.fromRGB(168, 85, 247), 1.5)

    local devActions = {
        { Label = "🪙 +5,000 Or", Action = "AddCoins" },
        { Label = "⚡ +500 Mérite", Action = "AddMerit" },
        { Label = "🌟 Carte Divine Gratuite", Action = "GiveDivine" },
        { Label = "⚔️ Duel vs Bot IA", Action = "StartBot" },
    }

    local devRF = Network.GetFunction("DevAction")
    for dIdx, dInfo in ipairs(devActions) do
        local btn = CreateUI("TextButton", {
            Size = UDim2.new(1, -20, 0, 36),
            Position = UDim2.new(0, 10, 0, (dIdx - 1) * 44 + 10),
            BackgroundColor3 = Color3.fromRGB(30, 41, 59),
            TextColor3 = Color3.fromRGB(241, 245, 249),
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            Text = dInfo.Label,
            Parent = devPanel,
        })
        ApplyCorner(btn, 6)
        btn.MouseButton1Click:Connect(function()
            local res = devRF:InvokeServer(dInfo.Action)
            if res.Success then
                UIManager.ShowToast(res.Message or "Action exécutée !")
                UIManager.FetchData()
            end
        end)
    end

    devBtn.MouseButton1Click:Connect(function()
        devPanel.Visible = not devPanel.Visible
    end)

    local matchStateRE = Network.GetEvent("MatchStateChanged")
    matchStateRE.OnClientEvent:Connect(function(data)
        if data.State == "VS" then
            UIManager.ShowToast("⚔️ DUEL LANCÉ CONTRE " .. data.OpponentName .. " (" .. data.OpponentRank .. ") !")
        elseif data.State == "Victory" then
            UIManager.ShowToast("🏆 VICTOIRE ÉCLATANTE ! (+" .. data.EloDelta .. " Elo, +" .. data.MeritGained .. " Mérite)")
            UIManager.FetchData()
        elseif data.State == "Defeat" then
            UIManager.ShowToast("💀 DÉFAITE EN ARÈNE (" .. data.EloDelta .. " Elo, +" .. data.MeritGained .. " Mérite de bravoure)")
            UIManager.FetchData()
        end
    end)

    -- Chargement initial des données
    UIManager.FetchData()
end

return UIManager
