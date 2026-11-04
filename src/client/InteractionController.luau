--!strict
--[[
    CARDS & CHAOS - DÉTECTION DES INTERACTIONS PHYSIQUES (PROXIMITY PROMPT)
    Ouvre automatiquement le bon onglet (Gacha, Market, Arena, Merit, NPC_Eldrin)
    quand le joueur s'approche d'un autel ou du PNJ et appuie sur E.
]]

local ProximityPromptService = game:GetService("ProximityPromptService")

local InteractionController = {}

function InteractionController.Init(openTabCallback: (tabName: string) -> ())
    ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
        local parent = prompt.Parent
        if parent then
            local targetUI = parent:GetAttribute("TargetUI")
            if not targetUI and parent.Parent then
                targetUI = parent.Parent:GetAttribute("TargetUI")
            end
            if targetUI and type(targetUI) == "string" then
                openTabCallback(targetUI)
            end
        end
    end)
    print("[InteractionController] Autels et PNJ interactifs (E) branchés.")
end

return InteractionController
