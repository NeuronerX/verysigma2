local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

local function autoEquip()
    for _, tool in ipairs(localPlayer.Backpack:GetChildren()) do
        if tool.Name == "Sword" and tool:IsA("Tool") then
            tool.Parent = localPlayer.Character
        end
    end
end

local function swordSoundSpam(duration)
    local startTime = tick()
    while tick() - startTime < duration do
        -- Unequip all tools
        for _, tool in pairs(localPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Parent = localPlayer.Backpack
            end
        end

        -- Re-equip all tools
        for _, tool in pairs(localPlayer.Backpack:GetChildren()) do
            tool.Parent = localPlayer.Character
        end

        task.wait(0.01)
    end
end

local function removeAnimations(character)
    local humanoid = character:WaitForChild("Humanoid")

    -- remove Animator instantly (replicates, so others don’t see animations)
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        animator:Destroy()
    end

    -- stop any currently playing animations (local + replicated)
    for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
        track:Stop()
    end

    -- block new animators from being added
    humanoid.ChildAdded:Connect(function(child)
        if child:IsA("Animator") then
            task.wait()
            child:Destroy()
        end
    end)

    -- block animations locally (you won't see them either)
    humanoid.AnimationPlayed:Connect(function(track)
        track:Stop()
    end)
end

local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")

    -- Sword spam on death
    humanoid.Died:Connect(function()
        swordSoundSpam(0.1)
    end)

    -- Sword spam + remove animations instantly on respawn
    task.spawn(function()
        removeAnimations(character)
        swordSoundSpam(0.2)
    end)
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)

if localPlayer.Character then
    onCharacterAdded(localPlayer.Character)
end

RunService.Stepped:Connect(autoEquip)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local randomX, randomY, randomZ

local function pickRandomLocation()
    randomX = math.random(0, 1800)
    randomY = math.random(3000, 6000)
    randomZ = math.random(0, 2500)
end

local function teleportLoop(character)
    if not character then return end
    local hrp = character:WaitForChild("HumanoidRootPart")

    while character.Parent do
        hrp.CFrame = CFrame.new(randomX, randomY, randomZ)
        hrp.AssemblyLinearVelocity = Vector3.zero
        RunService.Heartbeat:Wait() -- fastest safe loop
    end
end

local function onCharacterAdded(character)
    pickRandomLocation()
    task.spawn(function()
        teleportLoop(character)
    end)

    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        pickRandomLocation() -- new location on death
    end)
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)

if localPlayer.Character then
    onCharacterAdded(localPlayer.Character)
end

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local function deleteGui()
    local playerGui = localPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui.Name == "MobileShiftLockSupport" or gui:IsA("ScreenGui") then
            gui:Destroy()
        end
    end
end

-- Run once immediately
deleteGui()

-- Watch for new GUIs being added
localPlayer.PlayerGui.ChildAdded:Connect(function(child)
    task.wait(0.1)
    deleteGui()
end)


local Workspace = game:GetService("Workspace")
Workspace.BaseBlock:Destroy()
for _, obj in ipairs(Workspace:GetChildren()) do
    if obj:IsA("BasePart") and (obj.Name == "Kill" or obj.Name == "Part") then
        obj:Destroy()
    end
end

local StarterGui = game:GetService("StarterGui")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local targetQuality = Enum.QualityLevel.Level01

for _, obj in ipairs(Lighting:GetChildren()) do
    if obj:IsA("Sky") then
        obj:Destroy()
    end
end

local function enforceGraphics()
    if settings().Rendering.QualityLevel ~= targetQuality then
        settings().Rendering.QualityLevel = targetQuality
    end
end

RunService.RenderStepped:Connect(enforceGraphics)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local GC = getconnections or get_signal_cons
if GC then
    for _, v in pairs(GC(LocalPlayer.Idled)) do
        if v.Disable then
            v:Disable()
        elseif v.Disconnect then
            v:Disconnect()
        end
    end
else
    local VirtualUser = cloneref(game:GetService("VirtualUser"))
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

-- Connect to the Idled event
Players.LocalPlayer.Idled:Connect(function()
    -- Simulate a harmless input to prevent AFK kick
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0,0))
end)

-- Send message to Discord webhook
local function sendToWebhook(url, content)
    local req = http_request or request or HttpPost or syn.request
    if not req then return end
    req({
        Url = url,
        Body = game:GetService("HttpService"):JSONEncode({
            ["content"] = content
        }),
        Method = "POST",
        Headers = {
            ["content-type"] = "application/json"
        }
    })
end

-- Auto-detect and add Czech diacritics based on patterns
local function fixCzechDiacritics(text)
    local result = text
    
    -- Pattern-based diacritic detection
    -- These patterns identify where diacritics should be added based on Czech language rules
    
    -- č patterns (c -> č)
    result = result:gsub("(%w*)c([aeiouáéíóú])", function(prefix, vowel)
        -- Common Czech patterns where 'c' should be 'č'
        if prefix:match("pro$") or prefix:match("re$") or prefix:match("pre$") or 
           prefix:match("^$") or prefix:match("spa$") or prefix:match("le$") then
            return prefix .. "č" .. vowel
        end
        return prefix .. "c" .. vowel
    end)
    
    -- More č patterns
    result = result:gsub("(%w*)ch([aeiouáéíóú])", function(prefix, vowel)
        if prefix:match("te$") or prefix:match("chte$") then
            return prefix .. "čh" .. vowel
        end
        return prefix .. "ch" .. vowel
    end)
    
    -- ř patterns (r -> ř)
    result = result:gsub("(%w*)r([aeiouáéíóú])", function(prefix, vowel)
        if prefix:match("p$") or prefix:match("t$") or prefix:match("k$") or
           prefix:match("^$") or prefix:match("říka$") then
            return prefix .. "ř" .. vowel
        end
        return prefix .. "r" .. vowel
    end)
    
    -- ž patterns (z -> ž)
    result = result:gsub("(%w*)z([aeiouáéíóú])", function(prefix, vowel)
        if prefix:match("u$") or prefix:match("ji$") or prefix:match("ta$") then
            return prefix .. "ž" .. vowel
        end
        return prefix .. "z" .. vowel
    end)
    
    -- š patterns (s -> š)
    result = result:gsub("(%w*)s([aeiouáéíóú])", function(prefix, vowel)
        if prefix:match("ma$") or prefix:match("na$") or prefix:match("vi$") or
           prefix:match("^$") and vowel:match("[eěí]") then
            return prefix .. "š" .. vowel
        end
        return prefix .. "s" .. vowel
    end)
    
    -- ň patterns (n -> ň)
    result = result:gsub("(%w*)n([aeiouáéíóú])", function(prefix, vowel)
        if prefix:match("spa$") or prefix:match("do$") or prefix:match("^$") then
            return prefix .. "ň" .. vowel
        end
        return prefix .. "n" .. vowel
    end)
    
    -- ť and ď patterns
    result = result:gsub("(%w*)t([eěií])", function(prefix, vowel)
        if prefix:match("^$") or prefix:match("bu$") or prefix:match("je$") then
            return prefix .. "ť" .. vowel
        end
        return prefix .. "t" .. vowel
    end)
    
    result = result:gsub("(%w*)d([eěií])", function(prefix, vowel)
        if prefix:match("^$") or prefix:match("bu$") or prefix:match("ve$") then
            return prefix .. "ď" .. vowel
        end
        return prefix .. "d" .. vowel
    end)
    
    -- Vowel diacritics based on context
    -- á patterns
    result = result:gsub("(%w*)a(%w*)", function(prefix, suffix)
        if prefix:match("m$") and suffix:match("^m") then -- mám
            return prefix .. "á" .. suffix
        elseif prefix:match("m$") and suffix:match("^[ts]") then -- más, mát
            return prefix .. "á" .. suffix
        elseif suffix:match("^t") and not suffix:match("^te") then -- spát, brát
            return prefix .. "á" .. suffix
        end
        return prefix .. "a" .. suffix
    end)
    
    -- í/ý patterns 
    result = result:gsub("(%w*)y(%w*)", function(prefix, suffix)
        if suffix:match("^m$") or suffix:match("^ch$") or suffix:match("^[ts]$") then
            return prefix .. "ý" .. suffix
        end
        return prefix .. "y" .. suffix
    end)
    
    result = result:gsub("(%w*)i(%w*)", function(prefix, suffix)
        if prefix:match("v$") and suffix:match("^m") then -- vím
            return prefix .. "í" .. suffix
        elseif prefix:match("[jř]$") and suffix:match("^[kct]") then
            return prefix .. "í" .. suffix
        end
        return prefix .. "i" .. suffix
    end)
    
    -- ú/ů patterns
    result = result:gsub("(%w*)u(%w*)", function(prefix, suffix)
        if prefix:match("^$") and suffix:match("^[žs]") then -- už, už
            return prefix .. "ů" .. suffix
        elseif suffix:match("^m$") and prefix:match("[td]$") then
            return prefix .. "ů" .. suffix
        elseif prefix:match("^$") and suffix:match("^t") then -- út (úterý)
            return prefix .. "ú" .. suffix
        end
        return prefix .. "u" .. suffix
    end)
    
    -- é patterns
    result = result:gsub("(%w*)e(%w*)", function(prefix, suffix)
        if prefix:match("dobr$") or prefix:match("špatn$") then
            return prefix .. "ě" .. suffix
        elseif suffix:match("^[ts]$") and prefix:match("[mn]$") then
            return prefix .. "é" .. suffix
        end
        return prefix .. "e" .. suffix
    end)
    
    return result
end

-- Translate text using Google Translate API
local function translateText(text, targetLang)
    local HttpService = game:GetService("HttpService")
    local req = http_request or request or HttpPost or syn.request
    if not req then 
        return text -- Return original if no request function
    end
    
    -- Try to fix Czech diacritics first
    local processedText = fixCzechDiacritics(text)
    
    -- Force Czech as source language for better translation
    local translateUrl = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=cs&tl=" .. targetLang .. "&dt=t&q=" .. HttpService:UrlEncode(processedText)
    
    local success, response = pcall(function()
        return req({
            Url = translateUrl,
            Method = "GET",
            Headers = {
                ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            }
        })
    end)
    
    if success and response and response.Body then
        -- Parse the JSON response
        local success2, decoded = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        
        if success2 and decoded and decoded[1] and decoded[1][1] and decoded[1][1][1] then
            return decoded[1][1][1] -- Return translated text
        end
    end
    
    -- If Czech translation fails, try auto-detect
    local autoUrl = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=" .. targetLang .. "&dt=t&q=" .. HttpService:UrlEncode(text)
    
    local success3, response2 = pcall(function()
        return req({
            Url = autoUrl,
            Method = "GET",
            Headers = {
                ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            }
        })
    end)
    
    if success3 and response2 and response2.Body then
        local success4, decoded2 = pcall(function()
            return HttpService:JSONDecode(response2.Body)
        end)
        
        if success4 and decoded2 and decoded2[1] and decoded2[1][1] and decoded2[1][1][1] then
            return decoded2[1][1][1]
        end
    end
    
    return text -- Return original text if all translation attempts fail
end

-- Replace with your actual webhook
local logsWebhook = "https://discord.com/api/webhooks/1409941487143092386/GaUQG8EhocNx1X7WpNb7TmcHSJqYu53fduwQDcSIuuIfVU0HTxSIwM0UDzsiQtccI8pY"

-- Formats current time as HH:MM (UTC+2)
local function formattedTime()
    -- get UTC time
    local utcHour = tonumber(os.date("!%H"))
    local utcMin  = os.date("!%M")
    -- convert to UTC+2 (CET/CEST)
    local localHour = (utcHour + 2) % 24
    return string.format("%02d:%s", localHour, utcMin)
end

-- Check if message is a command (shouldn't be translated)
local function isCommand(text)
    local trimmed = text:match("^%s*(.-)%s*$") -- trim whitespace
    if not trimmed or trimmed == "" then return false end
    
    -- Common command prefixes
    local commandPrefixes = {"/", "!", ".", "-", "+", "?", "#", "$", "%", "^", "&", "*", "~", "`", "\\"}
    
    -- Check if message starts with any command prefix
    for _, prefix in ipairs(commandPrefixes) do
        if trimmed:sub(1, 1) == prefix then
            return true
        end
    end
    
    -- Check for common admin/game commands without prefixes
    local commandWords = {
        "give", "tp", "teleport", "fly", "noclip", "speed", "jump", "god", "heal", 
        "kill", "kick", "ban", "unban", "mute", "unmute", "jail", "unjail",
        "spawn", "respawn", "reset", "clear", "help", "admin", "mod", "vip",
        "money", "cash", "coins", "points", "level", "rank", "group", "team",
        "loop", "unloop", "loopkill", "unloopkill"
    }
    
    local firstWord = trimmed:lower():match("^(%w+)")
    if firstWord then
        for _, cmd in ipairs(commandWords) do
            if firstWord == cmd then
                return true
            end
        end
    end
    
    return false
end

-- Hook chat from a player
local function hookPlayerChat(player)
    player.Chatted:Connect(function(msg)
        local timestamp = formattedTime()
        
        -- Check if message is a command
        if isCommand(msg) then
            -- Don't translate commands, just send original
            local content = string.format("`[%s]` **%s**: %s", 
                timestamp, player.Name, msg)
            sendToWebhook(logsWebhook, content)
        else
            -- Translate normal messages to German
            local translatedMsg = translateText(msg, "de")
            
            -- Format with both original and translated text
            local content = string.format("`[%s]` **%s**: %s\n**(German)**: %s", 
                timestamp, player.Name, msg, translatedMsg)
            
            sendToWebhook(logsWebhook, content)
        end
    end)
end

-- Security check - only allow specific user
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if LocalPlayer.Name ~= "Pyan_x0v" then
    -- Stop script execution for unauthorized users
    return
end

-- Track player state for chat filtering
local playerStates = {}

-- Initialize player state
local function initializePlayerState(player)
    playerStates[player] = {
        isDead = false,
        canChat = true,
        respawnConnection = nil
    }
end

-- Monitor player death/respawn
local function monitorPlayerHealth(player)
    if not player.Character then return end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Monitor health changes
    local healthConnection = humanoid.HealthChanged:Connect(function(health)
        if health <= 0 and not playerStates[player].isDead then
            -- Player died
            playerStates[player].isDead = true
            playerStates[player].canChat = false
        end
    end)
    
    -- Monitor respawn (character added)
    if playerStates[player].respawnConnection then
        playerStates[player].respawnConnection:Disconnect()
    end
    
    playerStates[player].respawnConnection = player.CharacterAdded:Connect(function()
        -- Player respawned, wait 1 second then allow chat
        playerStates[player].isDead = false
        wait(1)
        playerStates[player].canChat = true
    end)
    
    -- Clean up when character is removed
    player.CharacterRemoving:Connect(function()
        if healthConnection then
            healthConnection:Disconnect()
        end
    end)
end
for _, plr in ipairs(Players:GetPlayers()) do
    hookPlayerChat(plr)
end

-- Auto-hook new players
Players.PlayerAdded:Connect(hookPlayerChat)
