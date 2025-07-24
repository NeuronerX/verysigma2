-- SINGLE EXECUTION PROTECTION
-- Check if script is already running
if _G.SCRIPT_PROTECTION_8556955654 then
    warn("⚠️ Script is already running! Execution blocked.")
    return
end

-- Set global protection flag immediately
_G.SCRIPT_PROTECTION_8556955654 = true

-- Create multiple protection layers
local scriptId = "PROTECTED_INSTANCE_" .. tostring(game.PlaceId) .. "_" .. tostring(game.JobId)
if shared[scriptId] then
    warn("⚠️ Script instance already exists! Execution blocked.")
    _G.SCRIPT_PROTECTION_8556955654 = nil
    return
end
shared[scriptId] = true

-- Add protection to workspace
local protectionObject = workspace:FindFirstChild("ScriptProtection_8556955654")
if protectionObject then
    warn("⚠️ Protection object detected! Script already running.")
    _G.SCRIPT_PROTECTION_8556955654 = nil
    shared[scriptId] = nil
    return
end

-- Create invisible protection object
protectionObject = Instance.new("Folder")
protectionObject.Name = "ScriptProtection_8556955654"
protectionObject.Parent = workspace
protectionObject.Archivable = false

-- Lock the protection object
local protectionConnection
protectionConnection = protectionObject.AncestryChanged:Connect(function()
    if not protectionObject.Parent then
        -- Someone tried to delete our protection, restore it
        protectionObject.Parent = workspace
    end
end)

-- Monitor for script re-execution attempts
local executionMonitor = game:GetService("RunService").Heartbeat:Connect(function()
    if not _G.SCRIPT_PROTECTION_8556955654 then
        -- Protection was removed, restore it
        _G.SCRIPT_PROTECTION_8556955654 = true
    end
end)

-- MAIN SCRIPT STARTS HERE
loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LP = Players.LocalPlayer
local Dist, DistSq = math.huge, math.huge * math.huge
local DMG_TIMES, FT_TIMES = 2, 5
local TARGET_USER_ID = 8556955654
local PlaceId = game.PlaceId
local JobId = game.JobId

-- Store whitelisted players by UserId - this will persist across rejoins
local WHITELISTED_IDS = {}
local A, K = {}, {}
local isScriptActive = true

-- SERVER HOPPING VARIABLES
local serverHopEnabled = true
local minPlayersBeforeHop = 5 -- Will hop if player count drops to 2 or below
local hopCheckDelay = 30 -- Check every 30 seconds
local lastHopCheck = 0

-- AUTHORIZED USERS - Can control all instances
local AUTHORIZED_USERS = {
    [8548956606] = true,
    [8145592635] = true,
    [TARGET_USER_ID] = true,
    [8556955654] = true -- Add more authorized user IDs here
}

-- Enhanced logging system
local function logMessage(type, message)
    local timestamp = os.date("%H:%M:%S")
    local prefix = "🔥"
    
    if type == "command" then prefix = "⚡"
    elseif type == "chat" then prefix = "💬"
    elseif type == "system" then prefix = "🔧"
    elseif type == "sync" then prefix = "🔄"
    elseif type == "hop" then prefix = "🚀"
    end
    
    print(prefix .. " [" .. timestamp .. "] [" .. LP.Name .. "]: " .. message)
end

-- SERVER HOPPING FUNCTION
local function serverHop()
    if not serverHopEnabled then return end
    
    logMessage("hop", "🔍 Searching for new server...")
    
    local servers = {}
    local success, req = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true")
    end)
    
    if not success then
        logMessage("hop", "❌ Failed to fetch server list")
        return
    end
    
    local bodySuccess, body = pcall(function()
        return HttpService:JSONDecode(req)
    end)
    
    if not bodySuccess or not body or not body.data then
        logMessage("hop", "❌ Failed to parse server data")
        return
    end
    
    -- Filter servers
    for i, v in next, body.data do
        if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and 
           v.playing < v.maxPlayers and v.id ~= JobId and v.playing >= minPlayersBeforeHop then
            table.insert(servers, 1, v.id)
        end
    end
    
    if #servers > 0 then
        local targetServer = servers[math.random(1, #servers)]
        logMessage("hop", "🚀 Hopping to new server with " .. #servers .. " options available")
        
        -- Clean up before teleporting
        if protectionConnection then
            protectionConnection:Disconnect()
        end
        if executionMonitor then
            executionMonitor:Disconnect()
        end
        
        TeleportService:TeleportToPlaceInstance(PlaceId, targetServer, LP)
    else
        logMessage("hop", "❌ No suitable servers found")
    end
end

-- CHECK SERVER POPULATION
local function checkServerPopulation()
    if not serverHopEnabled then return end
    
    local currentTime = tick()
    if currentTime - lastHopCheck < hopCheckDelay then return end
    lastHopCheck = currentTime
    
    local playerCount = #Players:GetPlayers()
    logMessage("hop", "📊 Current server population: " .. playerCount .. " players")
    
    if playerCount <= 2 then
        logMessage("hop", "⚠️ Server population too low (" .. playerCount .. " players), initiating server hop...")
        task.wait(2) -- Small delay before hopping
        serverHop()
    end
end

-- Improved whitelist check function with xL1 protection and specific name
local function isWhitelisted(player)
    if not player or not player.UserId then return false end

    -- Check if player name starts with "xL1"
    if player.Name:sub(1, 3) == "xL1" then
        return true
    end

    -- Check if player has a protected username
    if player.Name == "e5c4qe" then
        return true
    end

    -- Check manual whitelist first
    if WHITELISTED_IDS[player.UserId] then 
        return true 
    end

    -- Check friendship (with error handling)
    local success, isFriend = pcall(function()
        return player:IsFriendsWith(TARGET_USER_ID)
    end)

    if success and isFriend then
        -- Auto-add friends to whitelist to avoid repeated API calls
        WHITELISTED_IDS[player.UserId] = true
        return true
    end

    return false
end

-- Enhanced player finder with better matching
local function findPlayer(partial)
    if not partial or partial == "" then return nil end
    partial = partial:lower()
    
    local players = Players:GetPlayers()
    local exactMatches = {}
    local prefixMatches = {}
    local substringMatches = {}
    
    -- Categorize matches
    for _, plr in ipairs(players) do
        local name = plr.Name:lower()
        local displayName = plr.DisplayName:lower()
        
        -- Exact matches (highest priority)
        if name == partial or displayName == partial then
            table.insert(exactMatches, plr)
        -- Prefix matches (medium priority)
        elseif name:sub(1, #partial) == partial or displayName:sub(1, #partial) == partial then
            table.insert(prefixMatches, plr)
        -- Substring matches (lowest priority)
        elseif name:find(partial, 1, true) or displayName:find(partial, 1, true) then
            table.insert(substringMatches, plr)
        end
    end
    
    -- Return best match
    if #exactMatches > 0 then
        return exactMatches[1]
    elseif #prefixMatches > 0 then
        return prefixMatches[1]
    elseif #substringMatches > 0 then
        return substringMatches[1]
    end
    
    return nil
end

local function fire(a, b)
    firetouchinterest(a, b, 0)
    firetouchinterest(a, b, 1)
end

local function reachBox(tool)
    if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
        local h = tool.Handle
        if not h:FindFirstChild("BoxReachPart") then
            local p = Instance.new("Part")
            p.Name, p.Size, p.Transparency = "BoxReachPart", Vector3.new(Dist, Dist, Dist), 1
            p.CanCollide, p.Massless, p.Parent = false, true, h
            local w = Instance.new("WeldConstraint", p)
            w.Part0, w.Part1 = h, p
        end
    end
end

local function fullTouch(part, char)
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then 
            pcall(function() fire(part, v) end)
        end
    end
end

local function loopTouch(plr, part)
    if K[plr] then return end
    K[plr] = true
    
    task.spawn(function()
        while K[plr] and isScriptActive do
            -- Check whitelist status every loop iteration
            if isWhitelisted(plr) then 
                K[plr] = nil
                break 
            end
            
            local lc, tc = LP.Character, plr.Character
            if not (lc and tc) then break end
            
            local tw = lc:FindFirstChildWhichIsA("Tool")
            local hum = tc:FindFirstChildOfClass("Humanoid")
            
            if not (tw and tw.Parent == lc and part.Parent and hum and hum.Health > 0) then 
                break 
            end
            
            fullTouch(part, tc)
            task.wait()
        end
        K[plr] = nil
    end)
end

local function hit(part, plr)
    if not isScriptActive then return end
    
    -- Check whitelist before attacking
    if isWhitelisted(plr) then 
        return 
    end
    
    local c, hum = plr.Character, plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    if not c or not hum or hum.Health <= 0 then return end
    
    pcall(function() part.Parent:Activate() end)
    for _ = 1, DMG_TIMES do 
        fullTouch(part, c) 
    end
    loopTouch(plr, part)
end

local function heartbeat()
    if not isScriptActive then return end
    
    -- Check server population periodically
    checkServerPopulation()
    
    local char, root = LP.Character, LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not char or not root then return end
    
    local myPos = root.Position
    for _, tool in ipairs(char:GetDescendants()) do
        if tool:IsA("Tool") then
            local part = tool:FindFirstChild("BoxReachPart") or tool:FindFirstChild("Handle")
            if part then
                for _, plr in ipairs(A) do
                    if plr ~= LP and plr.Character and not isWhitelisted(plr) then
                        local pr, ph = plr.Character:FindFirstChild("HumanoidRootPart"), plr.Character:FindFirstChildOfClass("Humanoid")
                        if pr and ph and ph.Health > 0 then
                            local d = pr.Position - myPos
                            if d:Dot(d) <= DistSq then 
                                hit(part, plr) 
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ENHANCED SYNCHRONIZED COMMAND HANDLER
local function executeCommand(command, args, executor)
    logMessage("command", "Executing: " .. command .. " by " .. executor)
    
    if command == "whitelist" or command == "wl" then
        if #args >= 1 and args[1]:lower() == "current" then
            logMessage("sync", "Whitelisting all current players...")
            local count = 0
            local playerNames = {}
            local allPlayers = Players:GetPlayers()
            
            for _, player in ipairs(allPlayers) do
                if player ~= LP then
                    WHITELISTED_IDS[player.UserId] = true
                    if K[player] then
                        K[player] = nil
                    end
                    count = count + 1
                    table.insert(playerNames, player.Name)
                end
            end
            logMessage("sync", "✅ Whitelisted " .. count .. " players: " .. table.concat(playerNames, ", "))
            
        elseif #args >= 1 then
            local username = args[1]
            local targetPlayer = findPlayer(username)
            if targetPlayer then
                WHITELISTED_IDS[targetPlayer.UserId] = true
                if K[targetPlayer] then
                    K[targetPlayer] = nil
                end
                logMessage("sync", "✅ Whitelisted " .. targetPlayer.Name)
            else
                logMessage("sync", "❌ Player not found: " .. username)
            end
        end
        
    elseif command == "unwhitelist" or command == "unwl" then
        if #args >= 1 and args[1]:lower() == "current" then
            local count = 0
            local playerNames = {}
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LP and WHITELISTED_IDS[player.UserId] then
                    WHITELISTED_IDS[player.UserId] = nil
                    count = count + 1
                    table.insert(playerNames, player.Name)
                end
            end
            logMessage("sync", "✅ Unwhitelisted " .. count .. " players: " .. table.concat(playerNames, ", "))
        elseif #args >= 1 then
            local username = args[1]
            local targetPlayer = findPlayer(username)
            if targetPlayer then
                WHITELISTED_IDS[targetPlayer.UserId] = nil
                logMessage("sync", "✅ Unwhitelisted " .. targetPlayer.Name)
            else
                logMessage("sync", "❌ Player not found: " .. username)
            end
        end
        
    elseif command == "listwhitelist" or command == "lwl" then
        local count = 0
        local currentPlayers = {}
        local xl1Players = {}
        
        -- Check for xL1 players
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Name:sub(1, 3) == "xL1" then
                table.insert(xl1Players, player.Name)
            end
        end
        
        for userId, _ in pairs(WHITELISTED_IDS) do
            local player = Players:GetPlayerByUserId(userId)
            if player then
                table.insert(currentPlayers, player.Name)
                count = count + 1
            end
        end
        
        local message = "📋 Whitelist (" .. count .. " manual): " .. table.concat(currentPlayers, ", ")
        if #xl1Players > 0 then
            message = message .. " | xL1 Protected: " .. table.concat(xl1Players, ", ")
        end
        logMessage("sync", message)
        
    elseif command == "clearwhitelist" or command == "cwl" then
        local count = 0
        for _ in pairs(WHITELISTED_IDS) do
            count = count + 1
        end
        WHITELISTED_IDS = {}
        logMessage("sync", "🧹 Cleared " .. count .. " whitelisted players (xL1 protection remains active)")
        
    elseif command == "stop" then
        isScriptActive = false
        logMessage("sync", "🛑 Script stopped by " .. executor)
        
    elseif command == "start" then
        isScriptActive = true
        logMessage("sync", "▶️ Script started by " .. executor)
        
    elseif command == "serverhop" or command == "hop" then
        logMessage("hop", "🚀 Manual server hop requested by " .. executor)
        serverHop()
        
    elseif command == "hopstatus" or command == "hs" then
        local status = serverHopEnabled and "ENABLED" or "DISABLED"
        local playerCount = #Players:GetPlayers()
        logMessage("hop", "📊 Server Hop: " .. status .. " | Current players: " .. playerCount .. " | Min threshold: " .. minPlayersBeforeHop)
        
    elseif command == "hoptoggle" or command == "ht" then
        serverHopEnabled = not serverHopEnabled
        local status = serverHopEnabled and "ENABLED" or "DISABLED"
        logMessage("hop", "🔄 Server hop " .. status .. " by " .. executor)
        
    elseif command == "status" then
        local status = isScriptActive and "ACTIVE" or "STOPPED"
        local hopStatus = serverHopEnabled and "ENABLED" or "DISABLED"
        local whitelistCount = 0
        local xl1Count = 0
        local playerCount = #Players:GetPlayers()
        
        for _ in pairs(WHITELISTED_IDS) do
            whitelistCount = whitelistCount + 1
        end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Name:sub(1, 3) == "xL1" then
                xl1Count = xl1Count + 1
            end
        end
        
        logMessage("sync", "📊 Status: " .. status .. " | Players: " .. playerCount .. " | Whitelisted: " .. whitelistCount .. " | xL1 Protected: " .. xl1Count .. " | Server Hop: " .. hopStatus)
    end
end

-- UNIVERSAL CHAT MESSAGE HANDLER
local function handleChatMessage(speaker, message)
    logMessage("chat", speaker.Name .. ": " .. message)
    
    -- Check if speaker is authorized
    local isAuthorized = false
    
    -- Check authorized users list
    if AUTHORIZED_USERS[speaker.UserId] then
        isAuthorized = true
        logMessage("system", speaker.Name .. " is authorized (admin list)")
    else
        -- Check friendship with target user
        local success, isFriend = pcall(function()
            return speaker:IsFriendsWith(TARGET_USER_ID)
        end)
        if success and isFriend then
            isAuthorized = true
            logMessage("system", speaker.Name .. " is authorized (friend)")
        end
    end
    
    if not isAuthorized then
        return -- Don't process commands from unauthorized users
    end
    
    -- Parse command
    local clean = message:gsub("^%s+", ""):gsub("%s+$", "")
    if not clean:match("^%.") then return end -- Must start with .
    
    local parts = {}
    for word in clean:gmatch("%S+") do
        table.insert(parts, word)
    end
    
    if #parts < 1 then return end
    
    local command = parts[1]:sub(2):lower() -- Remove the . prefix
    local args = {}
    for i = 2, #parts do
        table.insert(args, parts[i])
    end
    
    -- Execute command synchronously across all instances
    executeCommand(command, args, speaker.Name)
end

-- MULTI-METHOD CHAT HOOKING SYSTEM
logMessage("system", "🚀 Initializing synchronized chat system...")

-- Method 1: Hook all player chat (including LocalPlayer)
local chatConnections = {}

local function hookPlayerChat(player)
    if chatConnections[player] then
        chatConnections[player]:Disconnect()
    end
    
    if player.Chatted then
        chatConnections[player] = player.Chatted:Connect(function(message)
            handleChatMessage(player, message)
        end)
        logMessage("system", "🔗 Hooked chat for " .. player.Name)
    end
end

-- Hook existing players
for _, player in ipairs(Players:GetPlayers()) do
    hookPlayerChat(player)
end

-- Hook new players
Players.PlayerAdded:Connect(function(player)
    hookPlayerChat(player)
end)

-- Clean up connections when players leave
Players.PlayerRemoving:Connect(function(player)
    if chatConnections[player] then
        chatConnections[player]:Disconnect()
        chatConnections[player] = nil
    end
    
    -- Check if server hop is needed after player leaves
    task.wait(1) -- Small delay to let the player count update
    checkServerPopulation()
end)

-- Method 2: TextChatService Hook (New chat system)
task.spawn(function()
    pcall(function()
        if TextChatService and TextChatService.OnIncomingMessage then
            TextChatService.OnIncomingMessage:Connect(function(message)
                local player = Players:GetPlayerByUserId(message.TextSource.UserId)
                if player then
                    handleChatMessage(player, message.Text)
                end
            end)
            logMessage("system", "🔗 Hooked TextChatService")
        end
    end)
end)

-- Method 3: RemoteEvent monitoring for chat
task.spawn(function()
    pcall(function()
        local function monitorRemoteEvent(remoteEvent)
            if remoteEvent.Name:lower():find("chat") or remoteEvent.Name:lower():find("message") then
                remoteEvent.OnClientEvent:Connect(function(...)
                    local args = {...}
                    logMessage("system", "📡 Chat RemoteEvent detected: " .. remoteEvent.Name)
                    -- Additional processing can be added here
                end)
            end
        end
        
        -- Monitor existing RemoteEvents
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                monitorRemoteEvent(obj)
            end
        end
        
        -- Monitor new RemoteEvents
        ReplicatedStorage.DescendantAdded:Connect(function(obj)
            if obj:IsA("RemoteEvent") then
                monitorRemoteEvent(obj)
            end
        end)
    end)
end)

-- Core character and heartbeat setup
local hbConn
local function onChar(c)
    c:WaitForChild("HumanoidRootPart", 10)
    for _, v in ipairs(c:GetDescendants()) do 
        reachBox(v) 
    end
    c.ChildAdded:Connect(reachBox)
    if hbConn then 
        hbConn:Disconnect() 
    end
    hbConn = RunService.Heartbeat:Connect(heartbeat)
end

LP.CharacterAdded:Connect(onChar)
if LP.Character then 
    onChar(LP.Character) 
end

-- Player management
local function refreshPlayers()
    table.clear(A)
    for _, pl in ipairs(Players:GetPlayers()) do 
        table.insert(A, pl) 
    end
end

Players.PlayerAdded:Connect(function(p) 
    table.insert(A, p) 
end)

Players.PlayerRemoving:Connect(function(p)
    for i, v in ipairs(A) do 
        if v == p then 
            table.remove(A, i) 
            break 
        end 
    end
    K[p] = nil
end)

refreshPlayers()

-- Discord webhook system - only for Cubot_Nova3
local WEBHOOK_URL = "https://discord.com/api/webhooks/1389727852232183848/UBkChkLNmXKhadYg3ZdxT6W5WXR-LFsKe5mOxt01qegPpQqYnT8ZDqzGCpJ2Qs7-hurS"

local function getPragueTimeString()
    local utc = os.time(os.date("!*t"))
    local offset = 2 * 3600
    local t = os.date("!*t", utc + offset)
    return string.format("%04d-%02d-%02d %02d:%02d:%02d", t.year, t.month, t.day, t.hour, t.min, t.sec)
end

local function sendWebhook(joinedUsername)
    local message = "Attacking " .. joinedUsername .. " | čas: " .. getPragueTimeString()
    
    local success, json = pcall(function()
        return HttpService:JSONEncode({content = message})
    end)
    
    if not success then return end
    
    local request = syn and syn.request or http_request or request or (http and http.request)
    if request then
        pcall(function()
            request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = json
            })
        end)
    end
end

-- Only send webhooks if LocalPlayer is Cubot_Nova3
Players.PlayerAdded:Connect(function(player)
    if LP.Name == "Cubot_Nova3" then
        -- Skip players whose names start with "cubot" or "xL1" (case insensitive)
        if not player.Name:lower():match("^cubot") and not player.Name:sub(1, 3) == "xL1" then
            sendWebhook(player.Name)
        end
    end
end)

-- Initialization complete
logMessage("system", "🎯 Enhanced Synchronized Multi-Instance System with Server Hopping Activated!")
logMessage("system", "🛡️ xL1 Protection Active - Players starting with 'xL1' are automatically protected")
logMessage("system", "🚀 Server Hop: Will automatically hop if player count drops to 2 or below")
logMessage("system", "📋 Available Commands:")
logMessage("system", "  .whitelist current - Whitelist all current players")
logMessage("system", "  .unwhitelist current - Unwhitelist all current players")
logMessage("system", "  .whitelist <player> - Whitelist specific player")
logMessage("system", "  .unwhitelist <player> - Unwhitelist specific player")
logMessage("system", "  .listwhitelist - Show all whitelisted players")
logMessage("system", "  .clearwhitelist - Clear entire whitelist")
logMessage("system", "  .stop - Stop script execution")
logMessage("system", "  .start - Start script execution")
logMessage("system", "  .serverhop - Manual server hop")
logMessage("system", "  .hopstatus - Show server hop status")
logMessage("system", "  .hoptoggle - Toggle server hop on/off")
logMessage("system", "  .status - Show current status")
logMessage("system", "✅ System ready VER : V2")

-- Test message and initial population check
task.wait(2)
logMessage("system", "🔥 Instance ready! Try: .status")
checkServerPopulation()

-- CLEANUP PROTECTION ON SCRIPT STOP
game.Players.LocalPlayer.AncestryChanged:Connect(function()
    -- Player is leaving, clean up
    if protectionConnection then
        protectionConnection:Disconnect()
    end
    if executionMonitor then
        executionMonitor:Disconnect()
    end
    if protectionObject and protectionObject.Parent then
        protectionObject:Destroy()
    end
end)
