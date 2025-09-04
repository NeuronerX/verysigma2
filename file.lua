local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

task.wait(2)

loadstring(game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/command.lua'))()

-- Discord webhook function
local sendmsg = function(url, message)
    local request = http_request or request or HttpPost or syn.request
    pcall(function()
        request({
            Url = url,
            Body = HttpService:JSONEncode({
                ["content"] = message
            }),
            Method = "POST",
            Headers = {
                ["content-type"] = "application/json"
            }
        })
    end)
end

local webhookUrl = "https://discord.com/api/webhooks/1412803981297844244/4lgHSrrd5ZJa0meQ_uTNca2yXuLRaDYd9p0m18K5WMdtqO6zTPoAamRpIgcG5iYNJlc_"

-- Cleanup function
local function cleanupOnStart()
    -- Remove ScreenGui from LocalPlayer's PlayerGui
    pcall(function()
        local playerGui = LP:FindFirstChild("PlayerGui")
        if playerGui then
            local screenGui = playerGui:FindFirstChild("ScreenGui")
            if screenGui then
                screenGui:Destroy()
            end
        end
    end)
    
    -- Remove all BaseBlock and Kill parts from workspace
    pcall(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name == "BaseBlock" or obj.Name == "Kill") then
                obj:Destroy()
            end
        end
    end)
end

-- Run cleanup
cleanupOnStart()

-- Performance constants
local DIST = 67690
local DIST_SQ = DIST * DIST
local DMG_TIMES = 20
local FT_TIMES = 30
local SWORD_NAME = "Sword"
local version = "8.0"

-- USER TABLES
local MAIN_USERS = {
    ["Pyan_x2v"] = true,
    ["Pyan_x0v"] = true,
    ["XxAmeliaBeastStormyx"] = true,
    ["Pyan503"] = true,
    ["Cub0t_01"] = true,
    ["FlexFightPro68"] = true,
    ["Iamnotrealyblack"] = true,
}

local SIGMA_USERS = {
    ["FlexFightPro68"] = true,
    ["Iamnotrealyblack"] = true,
    ["e5c4qe"] = true,
}

local SECONDARY_MAIN_USERS = {
    ["sssssss"] = true,
}

local ALWAYS_KILL = {
    ["sigmaboy123"] = true,
    ["josko730"] = true,
}

local WHITELISTED_USERS = {
    ["e5c4qe"] = true,
    ["xL1fe_r"] = true,
    ["xL1v3_r"] = true,
    ["xLiv3_r"] = true,
}

-- Original targets with teleport locations
local originalTargets = {
    ["Pyan_x2v"] = CFrame.new(7152, 4405, 4707),
    ["XxAmeliaBeastStormyx"] = CFrame.new(7122, 4505, 4719),
    ["Pyan503"] = CFrame.new(7122, 4475, 4719),
    ["cubot_autoIoop"] = CFrame.new(7132, 4605, 4707),
    ["Cubot_Nova2"] = CFrame.new(7122, 4705, 4729),
    ["Cubot_Nova1"] = CFrame.new(7132, 4605, 4529),
}

-- Global variables
getgenv().TargetTable = {}
getgenv().PermanentTargets = {}
getgenv().spam_swing = false

-- Track target sources
local targetSources = {} -- Track how each player was added to target list
local TARGET_SOURCE_MANUAL = "manual"
local TARGET_SOURCE_KILL_REVENGE = "kill_revenge"
local TARGET_SOURCE_TOOL_COUNT = "tool_count"
local TARGET_SOURCE_ALWAYS_KILL = "always_kill"

-- Performance tracking variables
local connections = {}
local targetedPlayers = {}
local playerList = {}
local killTrackers = {}
local tempParts = {}
local cachedTools = {}
local handleKillActive = {}
local toolTargetedPlayers = {} -- Players targeted for having too many tools
local lastPlayerCountCheck = 0
local chatCommandQueue = {}

-- Enhanced server hop function
local function serverHop()
    print("Starting server hop...")
    task.spawn(function()
        local success, servers = pcall(function()
            local req = game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true")
            local body = HttpService:JSONDecode(req)
            
            if not body or not body.data then 
                error("No server data received")
            end
            
            local validServers = {}
            for _, server in pairs(body.data) do
                if type(server) == "table" and 
                   server.id and 
                   server.playing and 
                   server.maxPlayers and 
                   tonumber(server.playing) < tonumber(server.maxPlayers) and 
                   server.id ~= JobId then
                    table.insert(validServers, server.id)
                end
            end
            
            return validServers
        end)
        
        if success and servers and #servers > 0 then
            local randomServer = servers[math.random(1, #servers)]
            print("Teleporting to server: " .. randomServer)
            
            local teleportSuccess = pcall(function()
                TeleportService:TeleportToPlaceInstance(PlaceId, randomServer, LP)
            end)
            
            if not teleportSuccess then
                print("Teleport failed, trying alternative method...")
                pcall(function()
                    TeleportService:Teleport(PlaceId, LP)
                end)
            end
        else
            print("No servers found or error occurred, trying regular teleport...")
            pcall(function()
                TeleportService:Teleport(PlaceId, LP)
            end)
        end
    end)
end

-- Auto server hop check function (improved)
local function checkPlayerCountForServerHop()
    local currentTime = tick()
    if currentTime - lastPlayerCountCheck < 25 then return end
    lastPlayerCountCheck = currentTime
    
    local playerCount = #Players:GetPlayers()
    if playerCount < 2 then
        print("Low player count detected (" .. playerCount .. "), server hopping...")
        serverHop()
    end
end

-- Tool count check function
local function checkToolCount(player)
    if not player then return end
    if MAIN_USERS[player.Name] or WHITELISTED_USERS[player.Name] then return end
    
    local toolCount = 0
    if player.Backpack then
        for _, item in pairs(player.Backpack:GetChildren()) do
            if item:IsA("Tool") then
                toolCount = toolCount + 1
            end
        end
    end
    if player.Character then
        for _, item in pairs(player.Character:GetChildren()) do
            if item:IsA("Tool") then
                toolCount = toolCount + 1
            end
        end
    end
    
    if toolCount >= 88 and not toolTargetedPlayers[player.Name] then
        addTargetToLoop(player, TARGET_SOURCE_TOOL_COUNT)
    end
end

-- Utility functions
local function findPlayerByPartialName(partialName)
    partialName = partialName:lower()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name:lower():find(partialName) or player.Name:lower():sub(1, #partialName) == partialName then
            return player
        end
    end
end

local function addTargetToLoop(player, source)
    if not player or MAIN_USERS[player.Name] or WHITELISTED_USERS[player.Name] then return end
    
    for _, target in pairs(getgenv().TargetTable) do
        if target == player then return end
    end
    
    table.insert(getgenv().TargetTable, player)
    targetedPlayers[player.Name] = true
    targetSources[player.Name] = source or TARGET_SOURCE_MANUAL
    
    -- Mark if this is a tool-based target
    if source == TARGET_SOURCE_TOOL_COUNT then
        toolTargetedPlayers[player.Name] = true
    end
    
    -- Start persistent handle kill for this target
    startPersistentHandleKill(player)
end

local function removeTargetFromLoop(player)
    if not player then return end
    
    for i, target in ipairs(getgenv().TargetTable) do
        if target == player then
            table.remove(getgenv().TargetTable, i)
            break
        end
    end
    
    targetedPlayers[player.Name] = nil
    targetSources[player.Name] = nil
    toolTargetedPlayers[player.Name] = nil -- Remove tool target flag
    handleKillActive[player] = nil
end

local function addPermanentTarget(player, source)
    if not player or MAIN_USERS[player.Name] or WHITELISTED_USERS[player.Name] then return end
    
    getgenv().PermanentTargets[player.Name] = true
    addTargetToLoop(player, source or TARGET_SOURCE_KILL_REVENGE)
end

-- Enhanced auto-equip system
local function autoEquip()
    for _, tool in ipairs(LP.Backpack:GetChildren()) do
        if tool.Name == "Sword" and tool:IsA("Tool") then
            tool.Parent = LP.Character
        end
    end
end

local function swordSoundSpam(duration)
    local startTime = tick()
    while tick() - startTime < duration do
        -- Unequip all tools
        for _, tool in pairs(LP.Character:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Parent = LP.Backpack
            end
        end
        -- Re-equip all tools
        for _, tool in pairs(LP.Backpack:GetChildren()) do
            tool.Parent = LP.Character
        end
        RunService.Heartbeat:Wait()
    end
end

local function removeAnimations(character)
    local humanoid = character:WaitForChild("Humanoid")
    -- remove Animator instantly (replicates, so others don't see animations)
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
            child:Destroy()
        end
    end)
    -- block animations locally (you won't see them either)
    humanoid.AnimationPlayed:Connect(function(track)
        track:Stop()
    end)
end

-- Tool setup
local function setupTool(tool)
    if not tool or not tool:IsA("Tool") or not tool:FindFirstChild("Handle") then return end
    
    local handle = tool.Handle
    handle.Massless = true
    handle.CanCollide = false
    
    cachedTools[tool] = handle
end

-- Enhanced batch fire touch system (optimized)
local function batchFireTouch(toolPart, targetParts)
    if not firetouchinterest then return end
    
    local tool = toolPart.Parent
    if tool and tool:IsA("Tool") then
        tool:Activate()
    end
    
    -- Fire touch for all parts simultaneously
    for i = 1, #targetParts do
        local part = targetParts[i]
        if part and part.Parent then
            for _ = 1, DMG_TIMES do
                firetouchinterest(toolPart, part, 0)
                firetouchinterest(toolPart, part, 1)
            end
        end
    end
    
    if tool and tool:IsA("Tool") then
        tool:Activate()
    end
end

-- Enhanced kill loop with better performance and no delays
local function killLoop(player, toolPart)
    if killTrackers[player] then return end
    killTrackers[player] = true
    
    local consecutiveFailures = 0
    
    while killTrackers[player] and consecutiveFailures < 10 do
        local localChar = LP.Character
        local targetChar = player.Character
        
        if not (localChar and targetChar) then 
            consecutiveFailures = consecutiveFailures + 1
            RunService.Heartbeat:Wait()
            continue 
        end
        
        local tool = localChar:FindFirstChildWhichIsA("Tool")
        local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
        local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
        
        if not (tool and tool.Parent == localChar and toolPart.Parent and humanoid and humanoid.Health > 0 and rootPart) then
            consecutiveFailures = consecutiveFailures + 1
            RunService.Heartbeat:Wait()
            continue
        end
        
        consecutiveFailures = 0
        
        -- Multiple tool activations
        for _ = 1, 10 do
            tool:Activate()
        end
        
        -- Collect all target parts
        table.clear(tempParts)
        for _, part in ipairs(targetChar:GetDescendants()) do
            if part:IsA("BasePart") and part.Parent then
                tempParts[#tempParts + 1] = part
            end
        end
        
        -- Enhanced batch fire touch
        if #tempParts > 0 then
            batchFireTouch(toolPart, tempParts)
        end
        
        RunService.Heartbeat:Wait()
    end
    killTrackers[player] = nil
end

-- Enhanced combat handler (no delays)
local function handleCombat(toolPart, player)
    local localChar = LP.Character
    local targetChar = player.Character
    
    if not (localChar and targetChar) then return end
    
    local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
    local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
    
    if not (humanoid and rootPart and humanoid.Health > 0) then return end
    
    -- Enhanced tool activations
    for _ = 1, 15 do
        toolPart.Parent:Activate()
    end
    
    -- Collect all target parts
    table.clear(tempParts)
    for _, part in ipairs(targetChar:GetDescendants()) do
        if part:IsA("BasePart") and part.Parent then
            tempParts[#tempParts + 1] = part
        end
    end
    
    -- Enhanced damage application
    if #tempParts > 0 then
        batchFireTouch(toolPart, tempParts)
    end
    
    -- Start enhanced kill loop
    if not killTrackers[player] then
        task.spawn(function()
            killLoop(player, toolPart)
        end)
    end
end

-- Persistent handle kill system (no delays)
function startPersistentHandleKill(targetPlayer)
    if handleKillActive[targetPlayer] then return end
    handleKillActive[targetPlayer] = true
    
    task.spawn(function()
        while handleKillActive[targetPlayer] do
            local char = LP.Character
            if char then
                local tool = char:FindFirstChildWhichIsA("Tool")
                
                if tool then
                    local handle = tool:FindFirstChild("Handle")
                    if handle and targetPlayer.Character then
                        local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                        local root = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                        
                        if root and humanoid and humanoid.Health > 0 then
                            if firetouchinterest then
                                -- Root part hits
                                for _ = 1, DMG_TIMES do
                                    firetouchinterest(handle, root, 0)
                                    firetouchinterest(handle, root, 1)
                                end
                                
                                -- Head hits for instant kill
                                local head = targetPlayer.Character:FindFirstChild("Head")
                                if head then
                                    for _ = 1, DMG_TIMES do
                                        firetouchinterest(handle, head, 0)
                                        firetouchinterest(handle, head, 1)
                                    end
                                end
                                
                                -- Torso hits
                                local torso = targetPlayer.Character:FindFirstChild("Torso") or targetPlayer.Character:FindFirstChild("UpperTorso")
                                if torso then
                                    for _ = 1, DMG_TIMES do
                                        firetouchinterest(handle, torso, 0)
                                        firetouchinterest(handle, torso, 1)
                                    end
                                end
                            end
                            
                            -- Additional tool activations
                            for _ = 1, 5 do
                                tool:Activate()
                            end
                        end
                    end
                end
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

-- Enhanced heartbeat combat function
local localPosition
local function onHeartbeat()
    local char = LP.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    localPosition = hrp.Position
    
    -- Process targets in TargetTable with enhanced logic
    for _, target in pairs(getgenv().TargetTable) do
        if target ~= LP and target.Character then
            local targetChar = target.Character
            local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
            
            if targetHRP and targetHumanoid and targetHumanoid.Health > 0 then
                -- Enhanced distance check
                local distance = (targetHRP.Position - localPosition)
                local distanceSq = distance:Dot(distance)
                
                if distanceSq <= DIST_SQ then
                    -- Use cached tool handles for better performance
                    for tool, handle in pairs(cachedTools) do
                        if tool.Parent == char and handle.Parent then
                            handleCombat(handle, target)
                        end
                    end
                end
            end
        end
    end
    
    -- Process ALWAYS_KILL targets
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and ALWAYS_KILL[player.Name] and player.Character then
            local targetChar = player.Character
            local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
            
            if targetHRP and targetHumanoid and targetHumanoid.Health > 0 then
                local distance = (targetHRP.Position - localPosition)
                local distanceSq = distance:Dot(distance)
                
                if distanceSq <= DIST_SQ then
                    for tool, handle in pairs(cachedTools) do
                        if tool.Parent == char and handle.Parent then
                            handleCombat(handle, player)
                        end
                    end
                end
            end
        end
    end
end

-- Teleport loop for original targets
local function teleportLoop()
    local character = LP.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local targetCFrame = originalTargets[LP.Name]
        if targetCFrame then
            character.HumanoidRootPart.CFrame = targetCFrame
            character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.PlatformStand = true
                humanoid:ChangeState(Enum.HumanoidStateType.Physics)
            end
            
            -- Additional anti-fall measures
            local bodyPosition = character.HumanoidRootPart:FindFirstChild("BodyPosition")
            if not bodyPosition then
                bodyPosition = Instance.new("BodyPosition")
                bodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bodyPosition.Parent = character.HumanoidRootPart
            end
            bodyPosition.Position = targetCFrame.Position
        end
    end
end

-- ENHANCED CHAT COMMAND PROCESSING (FIXED)
local function processChatCommand(messageText, sender)
    -- Only process if sender is authorized
    if not (MAIN_USERS[sender.Name] or SIGMA_USERS[sender.Name]) then return end
    
    local commandPart = ""
    
    -- Handle different chat formats
    if messageText:sub(1, 3) == "/e " then
        commandPart = messageText:sub(4)
    elseif messageText:sub(1, 1) == "/" then
        commandPart = messageText:sub(2)
    else
        commandPart = messageText
    end
    
    if commandPart == "" then return end
    
    local args = {}
    for word in commandPart:gmatch("%S+") do
        table.insert(args, word)
    end
    
    if #args == 0 then return end
    
    local command = args[1]:lower()
    
    -- Valid commands list
    local validCommands = {
        ["loop"] = true,
        ["unloop"] = true,
        ["sp"] = true,
        ["unsp"] = true,
        ["activate"] = true,
        ["update"] = true,
        ["serverhop"] = true,
        ["shop"] = true
    }
    
    -- Only process if it's a valid command
    if not validCommands[command] then return end
    
    -- Prepare webhook message
    local webhookMessage = "```" .. sender.Name .. " used command: " .. command
    if #args > 1 then
        webhookMessage = webhookMessage .. " " .. table.concat(args, " ", 2)
    end
    webhookMessage = webhookMessage .. "```"
    
    -- Process commands immediately
    if command == "loop" and #args >= 2 then
        local targetName = args[2]:lower()
        local targetPlayer = findPlayerByPartialName(targetName)
        if targetPlayer then
            addTargetToLoop(targetPlayer, TARGET_SOURCE_MANUAL)
            webhookMessage = webhookMessage .. "\nSuccessfully looped: " .. targetPlayer.Name
        else
            webhookMessage = webhookMessage .. "\nPlayer not found: " .. args[2]
        end
        
    elseif command == "unloop" then
        if #args >= 2 then
            if args[2]:lower() == "all" then
                local removedCount = #getgenv().TargetTable
                
                -- Clear all targets
                for _, target in pairs(getgenv().TargetTable) do
                    if target and target.Name then
                        targetedPlayers[target.Name] = nil
                        targetSources[target.Name] = nil
                        toolTargetedPlayers[target.Name] = nil
                        handleKillActive[target] = nil
                        killTrackers[target] = nil
                    end
                end
                
                getgenv().PermanentTargets = {}
                getgenv().TargetTable = {}
                
                webhookMessage = webhookMessage .. "\nRemoved all " .. removedCount .. " targets"
            else
                local targetName = args[2]:lower()
                local targetPlayer = findPlayerByPartialName(targetName)
                if targetPlayer then
                    getgenv().PermanentTargets[targetPlayer.Name] = nil
                    removeTargetFromLoop(targetPlayer)
                    webhookMessage = webhookMessage .. "\nSuccessfully unlooped: " .. targetPlayer.Name
                else
                    webhookMessage = webhookMessage .. "\nPlayer not found: " .. args[2]
                end
            end
        else
            webhookMessage = webhookMessage .. "\nUsage: /e unloop <player> or /e unloop all"
        end
        
    elseif command == "sp" then
        getgenv().spam_swing = true
        webhookMessage = webhookMessage .. "\nSpam swing enabled"
        
    elseif command == "unsp" then
        getgenv().spam_swing = false
        webhookMessage = webhookMessage .. "\nSpam swing disabled"
        
    elseif command == "activate" then
        task.spawn(function()
            loadstring(game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/aci.lua'))()
        end)
        webhookMessage = webhookMessage .. "\nActivating external script"
        
    elseif command == "update" then
        task.spawn(function()
            TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LP)
        end)
        webhookMessage = webhookMessage .. "\nRestarting script"
        
    elseif command == "serverhop" or command == "shop" then
        task.spawn(function()
            serverHop()
        end)
        webhookMessage = webhookMessage .. "\nServer hopping..."
    end
    
    -- Send webhook (keep this functionality)
    if LP.Name == "Pyan503" then
        task.spawn(function()
            sendmsg(webhookUrl, webhookMessage)
        end)
    end
end

-- IMPROVED MULTIPLE CHAT DETECTION SYSTEMS
local function setupChatCommandHandler()
    print("Setting up enhanced chat command handler...")
    
    -- Method 1: Direct player Chatted event (most reliable)
    local function connectPlayerChat(player)
        if player == LP then return end
        
        local success, connection = pcall(function()
            return player.Chatted:Connect(function(message)
                task.spawn(function()
                    processChatCommand(message, player)
                end)
            end)
        end)
        
        if success and connection then
            table.insert(connections, connection)
        end
    end
    
    -- Connect to all existing players
    for _, player in pairs(Players:GetPlayers()) do
        connectPlayerChat(player)
    end
    
    -- Connect to new players
    local playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        connectPlayerChat(player)
    end)
    table.insert(connections, playerAddedConnection)
    
    -- Method 2: TextChatService (for newer chat system)
    task.spawn(function()
        local success = pcall(function()
            if TextChatService then
                local textChannels = TextChatService:FindFirstChild("TextChannels")
                if textChannels then
                    local rbxGeneral = textChannels:FindFirstChild("RBXGeneral")
                    if rbxGeneral then
                        local connection = rbxGeneral.MessageReceived:Connect(function(message)
                            task.spawn(function()
                                if message.TextSource then
                                    local userId = message.TextSource.UserId
                                    local sender = Players:GetPlayerByUserId(userId)
                                    if sender and sender ~= LP then
                                        processChatCommand(message.Text, sender)
                                    end
                                end
                            end)
                        end)
                        table.insert(connections, connection)
                    end
                end
            end
        end)
    end)
    
    -- Method 3: Legacy chat system backup
    task.spawn(function()
        local success = pcall(function()
            local chatEvents = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 5)
            if chatEvents then
                local onMessageDoneFiltering = chatEvents:FindFirstChild("OnMessageDoneFiltering")
                if onMessageDoneFiltering then
                    local connection = onMessageDoneFiltering.OnClientEvent:Connect(function(messageData)
                        task.spawn(function()
                            if messageData and messageData.FromSpeaker and messageData.Message then
                                local sender = Players:FindFirstChild(messageData.FromSpeaker)
                                if sender and sender ~= LP then
                                    processChatCommand(messageData.Message, sender)
                                end
                            end
                        end)
                    end)
                    table.insert(connections, connection)
                end
            end
        end)
    end)
    
    -- Method 4: StarterGui chat backup
    task.spawn(function()
        pcall(function()
            local StarterGui = game:GetService("StarterGui")
            StarterGui:SetCore("ChatMakeSystemMessage", {
                Text = "Enhanced chat system v8.0 loaded";
                Color = Color3.fromRGB(0, 255, 0);
            })
        end)
    end)
end

-- Kill logger setup
local function setupKillLogger()
    task.spawn(function()
        local success = pcall(function()
            local event = ReplicatedStorage:WaitForChild("APlayerWasKilled", 10)
            if event then
                local connection = event.OnClientEvent:Connect(function(killerName, victimName, authCode)
                    if authCode ~= "Anrt4tiEx354xpl5oitzs" then return end
                    
                    if (MAIN_USERS[victimName] or victimName == LP.Name) then
                        if killerName and killerName ~= "" and 
                           not MAIN_USERS[killerName] and 
                           not SECONDARY_MAIN_USERS[killerName] and 
                           not SIGMA_USERS[killerName] and 
                           not WHITELISTED_USERS[killerName] then
                            
                            local killer = Players:FindFirstChild(killerName)
                            if killer then
                                addPermanentTarget(killer, TARGET_SOURCE_KILL_REVENGE)
                            else
                                getgenv().PermanentTargets[killerName] = true
                                targetedPlayers[killerName] = true
                                targetSources[killerName] = TARGET_SOURCE_KILL_REVENGE
                            end
                        end
                    end
                end)
                
                table.insert(connections, connection)
            end
        end)
    end)
end

-- Enhanced character setup
local function setupCharacter(character)
    character:WaitForChild("HumanoidRootPart", 10)
    
    -- Setup existing tools
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            setupTool(tool)
        end
    end
    
    -- Monitor new tools
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            setupTool(child)
        end
    end)
end

-- Player list management
local function updatePlayerList()
    table.clear(playerList)
    local players = Players:GetPlayers()
    for i = 1, #players do
        playerList[i] = players[i]
    end
end

-- Initialize always kill targets
for userName in pairs(ALWAYS_KILL) do
    if userName ~= "" then
        local player = Players:FindFirstChild(userName)
        if player then
            addTargetToLoop(player, TARGET_SOURCE_ALWAYS_KILL)
        end
    end
end

-- Player management
Players.PlayerAdded:Connect(function(player)
    playerList[#playerList + 1] = player
    if ALWAYS_KILL[player.Name] then
        addTargetToLoop(player, TARGET_SOURCE_ALWAYS_KILL)
    elseif getgenv().PermanentTargets[player.Name] then
        addTargetToLoop(player, targetSources[player.Name] or TARGET_SOURCE_KILL_REVENGE)
    elseif targetedPlayers[player.Name] and not toolTargetedPlayers[player.Name] then
        addTargetToLoop(player, targetSources[player.Name] or TARGET_SOURCE_MANUAL)
    end
    
    -- Check tool count for new players
    if player.Character then
        checkToolCount(player)
    end
    player.CharacterAdded:Connect(function()
        task.wait(2) -- Wait for tools to load
        checkToolCount(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    for i = #playerList, 1, -1 do
        if playerList[i] == player then
            table.remove(playerList, i)
            killTrackers[player] = nil
            break
        end
    end
    handleKillActive[player] = nil
    
    -- Only remove from targeting if they were tool-targeted (not permanently or manually targeted)
    if toolTargetedPlayers[player.Name] and not getgenv().PermanentTargets[player.Name] then
        toolTargetedPlayers[player.Name] = nil
        targetedPlayers[player.Name] = nil
        targetSources[player.Name] = nil
        removeTargetFromLoop(player)
    end
end)

-- Character setup
LP.CharacterAdded:Connect(function(character)
    task.spawn(function()
        local humanoid = character:WaitForChild("Humanoid")
        -- Sword spam on death
        humanoid.Died:Connect(function()
            task.spawn(function()
                swordSoundSpam(0.1)
            end)
        end)
        -- Sword spam + remove animations instantly on respawn
        removeAnimations(character)
        swordSoundSpam(0.2)
        setupCharacter(character)
    end)
end)

if LP.Character then
    task.spawn(function()
        local humanoid = LP.Character:WaitForChild("Humanoid")
        -- Sword spam on death
        humanoid.Died:Connect(function()
            task.spawn(function()
                swordSoundSpam(0.1)
            end)
        end)
        -- Sword spam + remove animations instantly on respawn
        removeAnimations(LP.Character)
        swordSoundSpam(0.2)
        setupCharacter(LP.Character)
    end)
end

-- Main enhanced loops (optimized)
RunService.Heartbeat:Connect(onHeartbeat)
RunService.Stepped:Connect(autoEquip)
RunService.RenderStepped:Connect(teleportLoop)

-- Auto server hop check loop
RunService.Heartbeat:Connect(checkPlayerCountForServerHop)

-- Tool count monitoring loop (optimized)
local toolCheckCounter = 0
RunService.Heartbeat:Connect(function()
    toolCheckCounter = toolCheckCounter + 1
    if toolCheckCounter >= 60 then -- Check every 60 frames (~1 second)
        toolCheckCounter = 0
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP then
                checkToolCount(player)
            end
        end
    end
end)

-- Spam swing loop (optimized)
RunService.Heartbeat:Connect(function()
    if getgenv().spam_swing and LP.Character then
        local sword = LP.Character:FindFirstChild("Sword")
        if sword and sword:IsA("Tool") then
            sword:Activate()
        end
    end
end)

-- Initialize systems
updatePlayerList()
setupChatCommandHandler()
setupKillLogger()

print("Enhanced Script v" .. version .. " - Optimized Performance & Fixed Commands")
