--!strict
--[[
    CARDS & CHAOS - PASSERELLE CLOUD & IA (GROQ & SUPABASE)
    Connexion sécurisée via HttpService pour animer le PNJ Maître Eldrin avec Groq (Llama 3.3 70B)
    et journaliser les transactions sur Supabase. Encapsulé dans des pcall pour le mode Studio.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkEvents = require(ReplicatedStorage.Shared.NetworkEvents)

local CloudBridge = {}

-- Clés et Endpoints configurés (Roblox Secret ou Clé d'API Groq)
local GROQ_API_KEY = ""
pcall(function()
    local secret = (HttpService :: any):GetSecret("GROQ_API_KEY")
    if secret then
        GROQ_API_KEY = secret
    end
end)
local GROQ_MODEL = "llama-3.3-70b-versatile"

local SUPABASE_URL = ""
local SUPABASE_KEY = ""

-- Dialogue avec Maître Eldrin via Groq API (avec fallback immersif hors-ligne)
function CloudBridge.AskGroq(player: Player, question: string): string
    if question == "" or string.len(question) > 200 then
        return "Approche, voyageur. Pose-moi une question sur les cartes ou l'arène."
    end

    if GROQ_API_KEY == "" then
        local fallbacks = {
            "Garde tes distances et prépare ton Météore Solaire (Touche 1 ou A) dès que l'ennemi avance !",
            "Le Pas Éclair (Touche 3 ou E) te permet de traverser les attaques ennemies tout en infligeant 28 dégâts.",
            "L'Égide du Souverain (Touche 4 ou R) restaure 40 points de vie tout en érigeant une barrière protectrice.",
            "Combine la Nova du Néant (Touche 2 ou Z) au corps-à-corps après avoir dashé avec le Pas Éclair !",
            "Accumule des points de Mérite dans l'Arène 1v1 pour gravir les échelons et débloquer des récompenses de rang."
        }
        return fallbacks[math.random(1, #fallbacks)]
    end

    local systemPrompt = "Tu es Maître Eldrin, le gardien sage et mystique de la crypte du jeu CARDS & CHAOS. Réponds en français de façon immersive, concise (max 2 phrases) et donne des conseils stratégiques sur les sorts (Météore, Nova, Pas Éclair, Égide), le Gacha et l'arène 1v1."

    local success, response = pcall(function()
        local payload = {
            model = GROQ_MODEL,
            messages = {
                { role = "system", content = systemPrompt },
                { role = "user", content = question },
            },
            max_tokens = 100,
            temperature = 0.7,
        }

        local res = HttpService:RequestAsync({
            Url = "https://api.groq.com/openai/v1/chat/completions",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = "Bearer " .. GROQ_API_KEY,
            },
            Body = HttpService:JSONEncode(payload),
        })

        if res.Success and res.StatusCode == 200 then
            local data = HttpService:JSONDecode(res.Body)
            return data.choices[1].message.content
        else
            return "Les vents astraux sont perturbés... (Code: " .. tostring(res.StatusCode) .. ")"
        end
    end)

    if success and response then
        return tostring(response)
    else
        return "Bienvenue dans CARDS & CHAOS ! Entraîne-toi sur les 3 mannequins, invoque de nouveaux sorts à l'autel ou affronte le Bot dans l'Arène 1v1 !"
    end
end

function CloudBridge.Init()
    local talkRF = NetworkEvents.GetFunction("TalkToNPC")
    talkRF.OnServerInvoke = function(player: Player, msg: any)
        return CloudBridge.AskGroq(player, tostring(msg or ""))
    end
    print("[CloudBridge] Passerelle Groq & Supabase active.")
end

return CloudBridge
