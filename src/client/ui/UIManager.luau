--!strict
--[[
    CARDS & CHAOS - INTERFACE UTILISATEUR COMPLÈTE (CLIENT)
    Mappage strict des 5 onglets (CODEX, INVOCATION, MARCHÉ, ARÈNE, MÉRITE),
    Hotbar des sorts 1-5 cliquables à la souris et tous les menus interactifs remplis.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardsDatabase = require(ReplicatedStorage.Shared.CardsDatabase)
local NetworkEvents = require(ReplicatedStorage.Shared.NetworkEvents)
local PackOpeningController = require(script.Parent.Parent.PackOpeningController)
local CombatController = require(script.Parent.Parent.CombatController)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local UIManager = {}

local CachedProfile: any = nil
local CurrentTab: string? = nil

-- Éléments UI principaux
local ScreenGui: ScreenGui
local TopBar: Frame
local NavBar: Frame
local ModalContainer: Frame
local ModalTitle: TextLabel
local ModalBody: Frame
local HotbarFrame: Frame
local ToastContainer: Frame

local function CreateUI(className: string, props: { [string]: any }): any
    local inst = Instance.new(className)
    for k, v in pairs(props) do
        (inst :: any)[k] = v
    end
    return inst
end

local function ApplyCorner(instance: Instance, radius: number?)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = instance
end

local function ApplyStroke(instance: Instance, color: Color3, thickness: number?)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1.5
    s.Parent = instance
end

-- =============================================================================
-- TOAST NOTIFICATIONS & ALERTES
-- =============================================================================
function UIManager.ShowToast(message: string, isError: boolean?)
    local toast = CreateUI("TextLabel", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = isError and Color3.fromRGB(185, 28, 28) or Color3.fromRGB(30, 41, 59),
        TextColor3 = Color3.fromRGB(248, 250, 252),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        Text = message,
        TextTransparency = 1,
        Parent = ToastContainer,
    })
    ApplyCorner(toast, 6)
    ApplyStroke(toast, isError and Color3.fromRGB(239, 68, 68) or Color3.fromRGB(71, 85, 105), 1)

    TweenService:Create(toast, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
    task.delay(3.5, function()
        local out = TweenService:Create(toast, TweenInfo.new(0.3), { TextTransparency = 1 })
        out:Play()
        out.Completed:Connect(function() toast:Destroy() end)
    end)
end

-- =============================================================================
-- RAFRAÎCHISSEMENT DU HUD & DE LA BARRE DE SORTS (HOTBAR)
-- =============================================================================
function UIManager.RefreshHUD()
    if not CachedProfile then return end

    local coinsLabel = TopBar:FindFirstChild("CoinsLabel") :: TextLabel?
    if coinsLabel then
        coinsLabel.Text = "🪙 " .. tostring(CachedProfile.Coins) .. " Or"
    end

    local meritLabel = TopBar:FindFirstChild("MeritLabel") :: TextLabel?
    if meritLabel then
        meritLabel.Text = "⚡ " .. tostring(CachedProfile.Merit) .. " Mérite (" .. tostring(CachedProfile.Rank) .. ")"
    end

    -- Mise à jour de la Hotbar (Slots 1 à 4 + Slot 5 Dash)
    local slotHotkeys = { "1 [F]", "2 [G]", "3 [C]", "4 [V]", "5 [Shift]" }
    for i = 1, 4 do
        local cardId = CachedProfile.EquippedDeck[i] or CardsDatabase.StarterDeck[i]
        local cardDef = CardsDatabase.GetCard(cardId)
        local slotBtn = HotbarFrame:FindFirstChild("Slot_" .. i) :: TextButton?
        if slotBtn and cardDef then
            slotBtn.Text = slotHotkeys[i] .. "\n" .. cardDef.Name
            slotBtn.TextColor3 = cardDef.Color
            local stroke = slotBtn:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = cardDef.Color end
        end
    end
end

function UIManager.FetchData()
    local getProfRF = NetworkEvents.GetFunction("GetPlayerData")
    CachedProfile = getProfRF:InvokeServer()
    UIManager.RefreshHUD()
end

-- =============================================================================
-- LES 5 ONGLETS COMPLETS (PLUS AUCUN MENU VIDE !)
-- =============================================================================

-- 1. FENÊTRE CODEX & DECK (Affiche les cartes possédées et permet d'équiper)
local function RenderCodexTab()
    ModalBody:ClearAllChildren()

    local desc = CreateUI("TextLabel", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Text = "Cliquez sur 'Équiper' pour assigner une carte à l'un de vos 4 slots de combat :",
        TextColor3 = Color3.fromRGB(203, 213, 225),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = ModalBody,
    })

    local scroll = CreateUI("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -40),
        Position = UDim2.new(0, 0, 0, 35),
        BackgroundTransparency = 1,
        ScrollBarThickness = 6,
        CanvasSize = UDim2.new(0, 0, 0, math.ceil(#CachedProfile.Inventory / 3) * 110),
        Parent = ModalBody,
    })

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.31, 0, 0, 100)
    grid.CellPadding = UDim2.new(0.02, 0, 0, 10)
    grid.Parent = scroll

    for _, c in ipairs(CachedProfile.Inventory) do
        local def = CardsDatabase.GetCard(c.CardId)
        if def then
            local cardCard = CreateUI("Frame", {
                BackgroundColor3 = Color3.fromRGB(30, 41, 59),
                Parent = scroll,
            })
            ApplyCorner(cardCard, 8)
            ApplyStroke(cardCard, def.Color, 2)

            CreateUI("TextLabel", {
                Size = UDim2.new(1, -10, 0, 24),
                Position = UDim2.new(0, 5, 0, 5),
                BackgroundTransparency = 1,
                Text = def.Name,
                TextColor3 = def.Color,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                Parent = cardCard,
            })

            CreateUI("TextLabel", {
                Size = UDim2.new(1, -10, 0, 35),
                Position = UDim2.new(0, 5, 0, 28),
                BackgroundTransparency = 1,
                Text = def.SpellType .. " | Pwr: " .. def.BasePower .. " | CD: " .. def.Cooldown .. "s",
                TextColor3 = Color3.fromRGB(148, 163, 184),
                Font = Enum.Font.Gotham,
                TextSize = 10,
                TextWrapped = true,
                Parent = cardCard,
            })

            local equipBtn = CreateUI("TextButton", {
                Size = UDim2.new(1, -16, 0, 28),
                Position = UDim2.new(0, 8, 1, -34),
                BackgroundColor3 = Color3.fromRGB(79, 70, 229),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                Text = "Équiper (Slot 1)",
                Parent = cardCard,
            })
            ApplyCorner(equipBtn, 6)

            equipBtn.MouseButton1Click:Connect(function()
                local equipRF = NetworkEvents.GetFunction("EquipCard")
                local res = equipRF:InvokeServer(def.Id, 1)
                if res.Success then
                    CachedProfile = res.Profile
                    UIManager.RefreshHUD()
                    UIManager.ShowToast("✨ " .. def.Name .. " équipé en Slot 1 !")
                end
            end)
        end
    end
end

-- 2. FENÊTRE INVOCATION / GACHA (Packs Souverain et Chaos avec taux transparents)
local function RenderGachaTab()
    ModalBody:ClearAllChildren()

    local infoBanner = CreateUI("Frame", {
        Size = UDim2.new(1, 0, 0, 55),
        BackgroundColor3 = Color3.fromRGB(24, 24, 38),
        Parent = ModalBody,
    })
    ApplyCorner(infoBanner, 8)
    ApplyStroke(infoBanner, Color3.fromRGB(168, 85, 247), 1.5)

    CreateUI("TextLabel", {
        Size = UDim2.new(1, 0, 0, 26),
        Position = UDim2.new(0, 0, 0, 4),
        BackgroundTransparency = 1,
        Text = "⚡ AUTEL DU DESTIN : INVOCATIONS DE SORTS ⚡",
        TextColor3 = Color3.fromRGB(250, 204, 21),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = infoBanner,
    })

    CreateUI("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 28),
        BackgroundTransparency = 1,
        Text = "Taux garantis Roblox : Commun: 60% | Rare: 25% | Épique: 11% | Légendaire: 4%",
        TextColor3 = Color3.fromRGB(203, 213, 225),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        Parent = infoBanner,
    })

    local packs = {
        {
            Id = "pack_souverain",
            Name = "Pack Souverain",
            Cost = 250,
            Desc = "Pack standard de l'Ordre Souverain.\nProbabilités équilibrées pour agrandir votre grimoire.",
            Color = Color3.fromRGB(79, 70, 229),
        },
        {
            Id = "pack_chaos",
            Name = "Pack Chaos Mythique",
            Cost = 1000,
            Desc = "Pack d'élite imprégné de flammes primordiales.\nChances accrues d'Épique (25%) et de Légendaire (10%) !",
            Color = Color3.fromRGB(217, 70, 239),
        },
    }

    local function TriggerPackOpen(packId: string)
        local rf = NetworkEvents.GetFunction("RequestOpenPack")
        local res = rf:InvokeServer(packId)
        if res.Success and res.Card then
            UIManager.CloseModal()
            PackOpeningController.PlayRevealAnimation(res.Card, function()
                UIManager.FetchData()
                UIManager.ShowToast("🌟 Vous avez obtenu : " .. res.Card.Name .. " (" .. res.Card.Rarity .. ") !")
            end)
        else
            UIManager.ShowToast(res.Error or "Or insuffisant pour ouvrir ce pack.", true)
        end
    end

    for pIdx, p in ipairs(packs) do
        local pFrame = CreateUI("Frame", {
            Size = UDim2.new(0.48, 0, 0, 220),
            Position = UDim2.new((pIdx - 1) * 0.52, 0, 0, 75),
            BackgroundColor3 = Color3.fromRGB(30, 41, 59),
            Parent = ModalBody,
        })
        ApplyCorner(pFrame, 10)
        ApplyStroke(pFrame, p.Color, 2)

        CreateUI("TextLabel", {
            Size = UDim2.new(1, -20, 0, 32),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            Text = p.Name,
            TextColor3 = p.Color,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            Parent = pFrame,
        })

        CreateUI("TextLabel", {
            Size = UDim2.new(1, -20, 0, 75),
            Position = UDim2.new(0, 10, 0, 45),
            BackgroundTransparency = 1,
            Text = p.Desc,
            TextColor3 = Color3.fromRGB(203, 213, 225),
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextWrapped = true,
            Parent = pFrame,
        })

        local openBtn = CreateUI("TextButton", {
            Size = UDim2.new(1, -30, 0, 44),
            Position = UDim2.new(0, 15, 1, -55),
            BackgroundColor3 = p.Color,
            TextColor3 = Color3.fromRGB(15, 23, 42),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            Text = "INVOQUER x1 (" .. p.Cost .. " Or)",
            Parent = pFrame,
        })
        ApplyCorner(openBtn, 8)
        openBtn.MouseButton1Click:Connect(function()
            TriggerPackOpen(p.Id)
        end)
    end
end

-- 3. FENÊTRE MARCHÉ / HÔTEL DES VENTES (Offres du Marché Noir + Vente de cartes)
local function RenderMarketTab()
    ModalBody:ClearAllChildren()

    local header = CreateUI("Frame", {
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundColor3 = Color3.fromRGB(24, 24, 38),
        Parent = ModalBody,
    })
    ApplyCorner(header, 8)

    CreateUI("TextLabel", {
        Size = UDim2.new(0.65, 0, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = "HÔTEL DES VENTES & MARCHÉ NOIR (Taxe 5%)",
        TextColor3 = Color3.fromRGB(16, 185, 129),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })

    local sellBtn = CreateUI("TextButton", {
        Size = UDim2.new(0.3, 0, 0, 32),
        Position = UDim2.new(0.68, 0, 0, 6),
        BackgroundColor3 = Color3.fromRGB(16, 185, 129),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Text = "+ Vendre ma 1ère Carte (300 Or)",
        Parent = header,
    })
    ApplyCorner(sellBtn, 6)

    sellBtn.MouseButton1Click:Connect(function()
        if CachedProfile and #CachedProfile.Inventory > 0 then
            local card = CachedProfile.Inventory[#CachedProfile.Inventory]
            local listRF = NetworkEvents.GetFunction("ListMarketItem")
            local res = listRF:InvokeServer(card.CardId, 300)
            if res.Success then
                UIManager.ShowToast("Carte mise en vente pour 300 Or !")
                UIManager.FetchData()
                RenderMarketTab()
            else
                UIManager.ShowToast(res.Error or "Erreur de mise en vente", true)
            end
        else
            UIManager.ShowToast("Aucune carte disponible à vendre.", true)
        end
    end)

    local scroll = CreateUI("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -55),
        Position = UDim2.new(0, 0, 0, 52),
        BackgroundTransparency = 1,
        ScrollBarThickness = 6,
        CanvasSize = UDim2.new(0, 0, 0, 250),
        Parent = ModalBody,
    })

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.Parent = scroll

    local getListingsRF = NetworkEvents.GetFunction("GetMarketListings")
    local listings = getListingsRF:InvokeServer() or {}

    for _, l in ipairs(listings) do
        local def = CardsDatabase.GetCard(l.CardId)
        local row = CreateUI("Frame", {
            Size = UDim2.new(1, -10, 0, 48),
            BackgroundColor3 = Color3.fromRGB(30, 41, 59),
            Parent = scroll,
        })
        ApplyCorner(row, 6)
        ApplyStroke(row, def and def.Color or Color3.fromRGB(71, 85, 105), 1)

        CreateUI("TextLabel", {
            Size = UDim2.new(0.4, 0, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = l.CardName .. " (" .. l.Rarity .. ")",
            TextColor3 = def and def.Color or Color3.fromRGB(248, 250, 252),
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = row,
        })

        CreateUI("TextLabel", {
            Size = UDim2.new(0.3, 0, 1, 0),
            Position = UDim2.new(0.42, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "Vendeur : " .. l.SellerName,
            TextColor3 = Color3.fromRGB(148, 163, 184),
            Font = Enum.Font.Gotham,
            TextSize = 11,
            Parent = row,
        })

        local buyBtn = CreateUI("TextButton", {
            Size = UDim2.new(0.24, 0, 0, 32),
            Position = UDim2.new(0.74, 0, 0, 8),
            BackgroundColor3 = Color3.fromRGB(5, 150, 105),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            Text = "ACHETER (" .. l.Price .. " Or)",
            Parent = row,
        })
        ApplyCorner(buyBtn, 6)

        buyBtn.MouseButton1Click:Connect(function()
            local buyRF = NetworkEvents.GetFunction("BuyMarketItem")
            local res = buyRF:InvokeServer(l.ListingId)
            if res.Success then
                UIManager.ShowToast("Achat réussi de " .. l.CardName .. " !")
                UIManager.FetchData()
                RenderMarketTab()
            else
                UIManager.ShowToast(res.Error or "Échec de l'achat", true)
            end
        end)
    end
end

-- 4. FENÊTRE ARÈNE COMPÉTITIVE 1V1 (Duel contre Bot Duelliste ou Joueur)
local function RenderArenaTab()
    ModalBody:ClearAllChildren()

    local arenaCard = CreateUI("Frame", {
        Size = UDim2.new(1, 0, 0, 240),
        BackgroundColor3 = Color3.fromRGB(24, 24, 38),
        Parent = ModalBody,
    })
    ApplyCorner(arenaCard, 10)
    ApplyStroke(arenaCard, Color3.fromRGB(239, 68, 68), 2)

    CreateUI("TextLabel", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Text = "⚔️ ARÈNE 1V1 DU COLISÉE CÉLESTE ⚔️",
        TextColor3 = Color3.fromRGB(248, 113, 113),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        Parent = arenaCard,
    })

    local statsText = "Votre Rang : " .. (CachedProfile and CachedProfile.Rank or "Bronze") .. " | Elo : " .. (CachedProfile and CachedProfile.Merit or 1000) .. " Mérite"
    CreateUI("TextLabel", {
        Size = UDim2.new(1, 0, 0, 25),
        Position = UDim2.new(0, 0, 0, 45),
        BackgroundTransparency = 1,
        Text = statsText,
        TextColor3 = Color3.fromRGB(250, 204, 21),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = arenaCard,
    })

    CreateUI("TextLabel", {
        Size = UDim2.new(1, -40, 0, 35),
        Position = UDim2.new(0, 20, 0, 75),
        BackgroundTransparency = 1,
        Text = "Affrontez le Bot Duelliste IA ou un joueur adverse dans le Colisée Céleste.\nChaque victoire rapporte +25 Mérite et +150 Or !",
        TextColor3 = Color3.fromRGB(203, 213, 225),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        Parent = arenaCard,
    })

    local duelBtn = CreateUI("TextButton", {
        Size = UDim2.new(0.8, 0, 0, 56),
        Position = UDim2.new(0.1, 0, 0, 135),
        BackgroundColor3 = Color3.fromRGB(220, 38, 38),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        Text = "LANCER UN DUEL 1V1 (Bot Souverain / Joueur)\nGain : +25 Mérite & +150 Or",
        Parent = arenaCard,
    })
    ApplyCorner(duelBtn, 10)

    duelBtn.MouseButton1Click:Connect(function()
        local joinRF = NetworkEvents.GetFunction("JoinArenaQueue")
        local res = joinRF:InvokeServer()
        if res.Success then
            UIManager.CloseModal()
            UIManager.ShowToast("⚔️ Téléportation dans le Colisée Céleste !")
        end
    end)
end

-- 5. FENÊTRE MÉRITE & CLASSEMENT (Paliers de rang et récompense +500 Or)
local function RenderMeritTab()
    ModalBody:ClearAllChildren()

    local rankCard = CreateUI("Frame", {
        Size = UDim2.new(1, 0, 0, 120),
        BackgroundColor3 = Color3.fromRGB(24, 24, 38),
        Parent = ModalBody,
    })
    ApplyCorner(rankCard, 8)
    ApplyStroke(rankCard, Color3.fromRGB(245, 158, 11), 1.5)

    CreateUI("TextLabel", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundTransparency = 1,
        Text = "🏆 PROGRESSION DU MÉRITE & PALIERS ELO 🏆",
        TextColor3 = Color3.fromRGB(250, 204, 21),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = rankCard,
    })

    CreateUI("TextLabel", {
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 35),
        BackgroundTransparency = 1,
        Text = "Paliers : Bronze (1000) • Argent (1200) • Or (1500) • Souverain (2000)",
        TextColor3 = Color3.fromRGB(203, 213, 225),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        Parent = rankCard,
    })

    local claimBtn = CreateUI("TextButton", {
        Size = UDim2.new(0.6, 0, 0, 36),
        Position = UDim2.new(0.2, 0, 0, 72),
        BackgroundColor3 = Color3.fromRGB(217, 119, 6),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        Text = "Réclamer Récompense de Rang (+500 Or)",
        Parent = rankCard,
    })
    ApplyCorner(claimBtn, 6)

    claimBtn.MouseButton1Click:Connect(function()
        local claimRF = NetworkEvents.GetFunction("ClaimRankReward")
        local res = claimRF:InvokeServer()
        if res.Success then
            UIManager.FetchData()
            UIManager.ShowToast(res.Message or "+500 Or réclamés !")
        else
            UIManager.ShowToast(res.Error or "Récompense déjà réclamée pour ce rang.", true)
        end
    end)
end

-- 6. DIALOGUE PNJ MAÎTRE ELDRIN (GROQ IA)
local function RenderNPCTab()
    ModalBody:ClearAllChildren()

    CreateUI("TextLabel", {
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1,
        Text = "Maître Eldrin, Sage de la Crypte :",
        TextColor3 = Color3.fromRGB(250, 204, 21),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = ModalBody,
    })

    local answerBox = CreateUI("TextLabel", {
        Size = UDim2.new(1, 0, 0, 90),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(24, 24, 38),
        TextColor3 = Color3.fromRGB(226, 232, 240),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        Text = "Approche, combattant. Pose-moi une question sur les cartes, le Gacha ou la stratégie d'arène.",
        Parent = ModalBody,
    })
    ApplyCorner(answerBox, 8)

    local inputBox = CreateUI("TextBox", {
        Size = UDim2.new(0.72, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 130),
        BackgroundColor3 = Color3.fromRGB(30, 41, 59),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        PlaceholderText = "Écrivez votre question ici...",
        Parent = ModalBody,
    })
    ApplyCorner(inputBox, 6)

    local sendBtn = CreateUI("TextButton", {
        Size = UDim2.new(0.25, 0, 0, 40),
        Position = UDim2.new(0.75, 0, 0, 130),
        BackgroundColor3 = Color3.fromRGB(147, 51, 234),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        Text = "DEMANDER (IA)",
        Parent = ModalBody,
    })
    ApplyCorner(sendBtn, 6)

    sendBtn.MouseButton1Click:Connect(function()
        local q = inputBox.Text
        if q ~= "" then
            answerBox.Text = "Maître Eldrin consulte les arcanes de Groq..."
            local talkRF = NetworkEvents.GetFunction("TalkToNPC")
            local rep = talkRF:InvokeServer(q)
            answerBox.Text = tostring(rep)
        end
    end)
end

-- =============================================================================
-- GESTION STRICTE DU ROUTAGE DES ONGLETS
-- =============================================================================
function UIManager.OpenTab(tabName: string)
    CurrentTab = tabName
    ModalContainer.Visible = true

    if tabName == "Codex" then
        ModalTitle.Text = "MON CODEX & DECK DE COMBAT"
        RenderCodexTab()
    elseif tabName == "Gacha" then
        ModalTitle.Text = "AUTEL DU DESTIN (INVOCATIONS)"
        RenderGachaTab()
    elseif tabName == "Market" then
        ModalTitle.Text = "HÔTEL DES VENTES & MARCHÉ NOIR"
        RenderMarketTab()
    elseif tabName == "Arena" then
        ModalTitle.Text = "ARÈNE COMPÉTITIVE 1V1"
        RenderArenaTab()
    elseif tabName == "Merit" then
        ModalTitle.Text = "PROGRESSION DU MÉRITE & RANGS"
        RenderMeritTab()
    elseif tabName == "NPC_Eldrin" then
        ModalTitle.Text = "CONSEILS DE MAÎTRE ELDRIN (GROQ IA)"
        RenderNPCTab()
    end
end

function UIManager.CloseModal()
    ModalContainer.Visible = false
    CurrentTab = nil
end

-- =============================================================================
-- INITIALISATION DE L'INTERFACE
-- =============================================================================
function UIManager.Init()
    ScreenGui = CreateUI("ScreenGui", {
        Name = "CardsChaosGui",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = playerGui,
    })

    -- 1. Toasts Container
    ToastContainer = CreateUI("Frame", {
        Size = UDim2.new(0, 320, 0, 300),
        Position = UDim2.new(1, -340, 1, -340),
        BackgroundTransparency = 1,
        Parent = ScreenGui,
    })
    local toastLayout = Instance.new("UIListLayout")
    toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    toastLayout.Padding = UDim.new(0, 8)
    toastLayout.Parent = ToastContainer

    -- 2. TopBar (Or, Mérite, Elo)
    TopBar = CreateUI("Frame", {
        Size = UDim2.new(0, 500, 0, 42),
        Position = UDim2.new(0.5, -250, 0, 15),
        BackgroundColor3 = Color3.fromRGB(15, 23, 42),
        BackgroundTransparency = 0.2,
        Parent = ScreenGui,
    })
    ApplyCorner(TopBar, 10)
    ApplyStroke(TopBar, Color3.fromRGB(51, 65, 85), 1.5)

    CreateUI("TextLabel", {
        Name = "CoinsLabel",
        Size = UDim2.new(0.48, 0, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(245, 158, 11),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "🪙 2500 Or",
        Parent = TopBar,
    })

    CreateUI("TextLabel", {
        Name = "MeritLabel",
        Size = UDim2.new(0.48, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(56, 189, 248),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "⚡ 1000 Mérite (Bronze)",
        Parent = TopBar,
    })

    -- 3. Barre de Navigation Inférieure (MAPPING STRICT CORRIGÉ)
    NavBar = CreateUI("Frame", {
        Size = UDim2.new(0, 620, 0, 48),
        Position = UDim2.new(0.5, -310, 1, -65),
        BackgroundColor3 = Color3.fromRGB(15, 23, 42),
        BackgroundTransparency = 0.2,
        Parent = ScreenGui,
    })
    ApplyCorner(NavBar, 10)
    ApplyStroke(NavBar, Color3.fromRGB(71, 85, 105), 1.5)

    local tabs = {
        { Id = "Codex", Label = "⚔️ CODEX" },
        { Id = "Gacha", Label = "🎰 INVOCATION" },
        { Id = "Market", Label = "⚖️ MARCHÉ" },
        { Id = "Arena", Label = "🏆 ARÈNE" },
        { Id = "Merit", Label = "✨ MÉRITE" },
    }

    for i, t in ipairs(tabs) do
        local btn = CreateUI("TextButton", {
            Size = UDim2.new(0.18, 0, 0, 36),
            Position = UDim2.new((i - 1) * 0.20 + 0.01, 0, 0, 6),
            BackgroundColor3 = Color3.fromRGB(30, 41, 59),
            TextColor3 = Color3.fromRGB(248, 250, 252),
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            Text = t.Label,
            Parent = NavBar,
        })
        ApplyCorner(btn, 6)

        btn.MouseButton1Click:Connect(function()
            if CurrentTab == t.Id and ModalContainer.Visible then
                UIManager.CloseModal()
            else
                UIManager.OpenTab(t.Id)
            end
        end)
    end

    -- 4. Hotbar des 5 Sorts (Cliquables à la souris + Cooldowns)
    HotbarFrame = CreateUI("Frame", {
        Size = UDim2.new(0, 380, 0, 56),
        Position = UDim2.new(0.5, -190, 1, -130),
        BackgroundColor3 = Color3.fromRGB(15, 23, 42),
        BackgroundTransparency = 0.35,
        Parent = ScreenGui,
    })
    ApplyCorner(HotbarFrame, 8)
    ApplyStroke(HotbarFrame, Color3.fromRGB(71, 85, 105), 1)

    local hotbarLabels = { "1 [F]\nMétéore", "2 [G]\nNova", "3 [C]\nÉclair", "4 [V]\nÉgide", "5 [Shift]\nDash" }
    for slot = 1, 5 do
        local sBtn = CreateUI("TextButton", {
            Name = "Slot_" .. slot,
            Size = UDim2.new(0, 68, 0, 46),
            Position = UDim2.new((slot - 1) * 0.20 + 0.01, 0, 0, 5),
            BackgroundColor3 = Color3.fromRGB(30, 41, 59),
            TextColor3 = Color3.fromRGB(248, 250, 252),
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            Text = hotbarLabels[slot],
            Parent = HotbarFrame,
        })
        ApplyCorner(sBtn, 6)
        ApplyStroke(sBtn, Color3.fromRGB(99, 102, 241), 1.5)

        -- DÉCLENCHEMENT IMMÉDIAT AU CLIC SOURIS !
        sBtn.MouseButton1Click:Connect(function()
            CombatController.TriggerSpell(slot)
        end)
    end

    -- 5. Conteneur Central de Modale
    ModalContainer = CreateUI("Frame", {
        Size = UDim2.new(0, 680, 0, 440),
        Position = UDim2.new(0.5, -340, 0.5, -220),
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

    ModalBody = CreateUI("Frame", {
        Size = UDim2.new(1, -30, 1, -60),
        Position = UDim2.new(0, 15, 0, 50),
        BackgroundTransparency = 1,
        Parent = ModalContainer,
    })

    -- Écouteurs Réseau
    local toastRE = NetworkEvents.GetEvent("ToastNotify")
    toastRE.OnClientEvent:Connect(function(msg, isErr)
        UIManager.ShowToast(msg, isErr)
    end)

    local annRE = NetworkEvents.GetEvent("ServerAnnouncement")
    annRE.OnClientEvent:Connect(function(data)
        UIManager.ShowToast("🌟 [ALERTE MONDIALE] " .. tostring(data.PlayerName) .. " a tiré " .. tostring(data.CardName) .. " (" .. tostring(data.Rarity) .. ") !")
    end)

    local matchStateRE = NetworkEvents.GetEvent("MatchStateChanged")
    matchStateRE.OnClientEvent:Connect(function(data)
        if data.State == "VS" then
            UIManager.ShowToast("⚔️ DUEL 1V1 CONTRE " .. tostring(data.OpponentName) .. " !")
        elseif data.State == "Victory" then
            UIManager.ShowToast("🏆 VICTOIRE ! (+" .. tostring(data.MeritGained) .. " Mérite & +" .. tostring(data.CoinsGained) .. " Or)")
            UIManager.FetchData()
        elseif data.State == "Defeat" then
            UIManager.ShowToast("💀 DÉFAITE EN ARÈNE (+5 Mérite de consolation)")
            UIManager.FetchData()
        end
    end)

    -- Chargement initial
    UIManager.FetchData()
    print("[UIManager] Interface complète CARDS & CHAOS opérationnelle.")
end

return UIManager
