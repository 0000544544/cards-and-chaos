--!strict
--[[
    INTERACTION CONTROLLER
    Détection des interactions avec les autels du Hub et ouverture automatique des interfaces correspondantes.
]]

local ProximityPromptService = game:GetService("ProximityPromptService")

local InteractionController = {}

function InteractionController.Init(openUITabCallback: (tabName: string) -> ())
    ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
        local parentPart = prompt.Parent :: Instance?
        if parentPart then
            local uiName = parentPart:GetAttribute("TargetUI")
            if uiName and type(uiName) == "string" then
                openUITabCallback(uiName)
            end
        end
    end)
end

return InteractionController
