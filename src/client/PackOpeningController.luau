--!strict
--[[
    CARDS & CHAOS - ANIMATION D'OUVERTURE DE PACK (CLIENT)
    Animation cinématographique de révélation de carte : carte qui flotte, tourne,
    irradie de particules d'aura, se retourne (Card Flip) et explose aux couleurs de sa rareté.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local CardsDatabase = require(game.ReplicatedStorage.Shared.CardsDatabase)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local PackOpeningController = {}

local RarityColors: { [CardsDatabase.CardRarity]: Color3 } = {
    Common = Color3.fromRGB(180, 190, 205),
    Rare = Color3.fromRGB(56, 189, 248),
    Epic = Color3.fromRGB(168, 85, 247),
    Legendary = Color3.fromRGB(245, 158, 11),
}

-- Création de l'interface d'animation de tirage
function PackOpeningController.PlayRevealAnimation(cardInstance: any, onComplete: (() -> ())?)
    local screenGui = playerGui:FindFirstChild("PackRevealGui") :: ScreenGui?
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "PackRevealGui"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.Parent = playerGui
    end
    screenGui:ClearAllChildren()

    local rarity = (cardInstance.Rarity or "Common") :: CardsDatabase.CardRarity
    local glowColor = RarityColors[rarity] or Color3.fromRGB(255, 255, 255)

    -- Fond assombri avec flou cinématique
    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(5, 7, 12)
    backdrop.BackgroundTransparency = 1
    backdrop.Parent = screenGui

    local fadeBackdrop = TweenService:Create(backdrop, TweenInfo.new(0.35), { BackgroundTransparency = 0.25 })
    fadeBackdrop:Play()

    -- Conteneur central de la carte
    local cardHolder = Instance.new("Frame")
    cardHolder.Size = UDim2.new(0, 240, 0, 360)
    cardHolder.Position = UDim2.new(0.5, -120, 0.5, -180)
    cardHolder.BackgroundTransparency = 1
    cardHolder.Parent = backdrop

    -- Dos de la carte (Initialement visible)
    local cardBack = Instance.new("Frame")
    cardBack.Size = UDim2.new(1, 0, 1, 0)
    cardBack.BackgroundColor3 = Color3.fromRGB(24, 24, 38)
    cardBack.Parent = cardHolder

    local corner1 = Instance.new("UICorner")
    corner1.CornerRadius = UDim.new(0, 12)
    corner1.Parent = cardBack

    local stroke1 = Instance.new("UIStroke")
    stroke1.Color = Color3.fromRGB(99, 102, 241)
    stroke1.Thickness = 3
    stroke1.Parent = cardBack

    local backLogo = Instance.new("TextLabel")
    backLogo.Size = UDim2.new(1, 0, 1, 0)
    backLogo.BackgroundTransparency = 1
    backLogo.Font = Enum.Font.GothamBold
    backLogo.TextSize = 24
    backLogo.TextColor3 = Color3.fromRGB(168, 85, 247)
    backLogo.Text = "CARDS\n&\nCHAOS"
    backLogo.Parent = cardBack

    -- Face avant de la carte (Révélée après le retournement)
    local cardFront = Instance.new("Frame")
    cardFront.Size = UDim2.new(1, 0, 1, 0)
    cardFront.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
    cardFront.Visible = false
    cardFront.Parent = cardHolder

    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0, 12)
    corner2.Parent = cardFront

    local stroke2 = Instance.new("UIStroke")
    stroke2.Color = glowColor
    stroke2.Thickness = (rarity == "Legendary") and 4 or 2.5
    stroke2.Parent = cardFront

    -- Rendu de l'illustration (Decal ComfyUI)
    local cardImage = Instance.new("ImageLabel")
    cardImage.Size = UDim2.new(1, -20, 0, 170)
    cardImage.Position = UDim2.new(0, 10, 0, 10)
    cardImage.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    cardImage.Image = cardInstance.AssetId or "rbxassetid://13880479100"
    cardImage.ScaleType = Enum.ScaleType.Fit
    cardImage.Parent = cardFront

    local imgCorner = Instance.new("UICorner")
    imgCorner.CornerRadius = UDim.new(0, 8)
    imgCorner.Parent = cardImage

    -- Nom & Rareté
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -20, 0, 30)
    nameLabel.Position = UDim2.new(0, 10, 0, 190)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 16
    nameLabel.TextColor3 = glowColor
    nameLabel.Text = cardInstance.Name
    nameLabel.Parent = cardFront

    local typeLabel = Instance.new("TextLabel")
    typeLabel.Size = UDim2.new(1, -20, 0, 20)
    typeLabel.Position = UDim2.new(0, 10, 0, 220)
    typeLabel.BackgroundTransparency = 1
    typeLabel.Font = Enum.Font.Gotham
    typeLabel.TextSize = 12
    typeLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
    typeLabel.Text = string.upper(tostring(cardInstance.Type or "Aptitude")) .. " • " .. string.upper(tostring(rarity))
    typeLabel.Parent = cardFront

    -- Statistique de Puissance (BasePower)
    local powerLabel = Instance.new("TextLabel")
    powerLabel.Size = UDim2.new(1, -20, 0, 40)
    powerLabel.Position = UDim2.new(0, 10, 0, 250)
    powerLabel.BackgroundTransparency = 1
    powerLabel.Font = Enum.Font.GothamBold
    powerLabel.TextSize = 22
    powerLabel.TextColor3 = Color3.fromRGB(248, 250, 252)
    powerLabel.Text = "⚡ PUISSANCE : " .. tostring(cardInstance.BasePower or 50)
    powerLabel.Parent = cardFront

    -- Bouton de confirmation
    local collectBtn = Instance.new("TextButton")
    collectBtn.Size = UDim2.new(1, -40, 0, 40)
    collectBtn.Position = UDim2.new(0, 20, 1, -55)
    collectBtn.BackgroundColor3 = glowColor
    collectBtn.TextColor3 = Color3.fromRGB(15, 23, 42)
    collectBtn.Font = Enum.Font.GothamBold
    collectBtn.TextSize = 14
    collectBtn.Text = "RÉCUPÉRER LA CARTE"
    collectBtn.Parent = cardFront

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = collectBtn

    -- =========================================================================
    -- SÉQUENCE CINÉMATIQUE (TWEENING)
    -- =========================================================================
    cardHolder.Position = UDim2.new(0.5, -120, 0.7, -180)
    cardHolder.Size = UDim2.new(0, 80, 0, 120)

    -- Phase 1 : Montée et flottement
    local riseTween = TweenService:Create(cardHolder, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -120, 0.5, -180),
        Size = UDim2.new(0, 240, 0, 360),
    })
    riseTween:Play()
    riseTween.Completed:Wait()

    -- Phase 2 : Retournement 3D (Simulation Flip horizontal)
    local flipHalf1 = TweenService:Create(cardHolder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 360),
    })
    flipHalf1:Play()
    flipHalf1.Completed:Wait()

    cardBack.Visible = false
    cardFront.Visible = true

    local flipHalf2 = TweenService:Create(cardHolder, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 240, 0, 360),
    })
    flipHalf2:Play()

    -- Phase 3 : Fermeture
    collectBtn.MouseButton1Click:Connect(function()
        local closeTween = TweenService:Create(backdrop, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
        closeTween:Play()
        closeTween.Completed:Connect(function()
            screenGui:Destroy()
            if onComplete then onComplete() end
        end)
    end)
end

return PackOpeningController
