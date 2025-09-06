local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId
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

task.wait(1)

loadstring(game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/command.lua'))()

-- Unique instance identifier to prevent chat conflicts
local INSTANCE_ID = HttpService:GenerateGUID(false):sub(1, 8)
local COMMAND_COOLDOWN = {}

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
local version = "8.1"

-- DAMAGE TRACKING SETTINGS
local damage_taking = false -- Enable/disable damage tracking for main users
local local_damage = 1 -- Damage threshold before auto-loop

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
    ["GoatReflex"] = true,
    ["skkssjsndndn"] = true,
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

-- Damage tracking variables
local damageTrackers = {} -- Track damage dealt to main users by other players
local lastHealthValues = {} -- Track last known health values for main users

-- Track target sources
local targetSources = {} -- Track how each player was added to target list
local TARGET_SOURCE_MANUAL = "manual"
local TARGET_SOURCE_KILL_REVENGE = "kill_revenge"
local TARGET_SOURCE_TOOL_COUNT = "tool_count"
local TARGET_SOURCE_ALWAYS_KILL = "always_kill"
local TARGET_SOURCE_DAMAGE = "damage_threshold"

-- Performance tracking variables
local connections = {}
local targetedPlayers = {}
local playerList = {}
local killTrackers = {}
local tempParts = {}
local cachedTools = {}
local toolTargetedPlayers = {} -- Players targeted for having too many tools
local lastPlayerCountCheck = 0

-- FIXED Server hop function
local function serverHop()
    task.spawn(function()
        local success, result = pcall(function()
            local httpRequest = (syn and syn.request) or http_request or request
            if not httpRequest then
                warn("No HTTP request function available")
                return false
            end
            
            local response = httpRequest({
                Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
                Method = "GET"
            })
            
            if response.StatusCode ~= 200 then
                warn("HTTP request failed with status: " .. tostring(response.StatusCode))
                return false
            end
            
            local serverData = HttpService:JSONDecode(response.Body)
            if not serverData or not serverData.data then
                warn("Invalid server data received")
                return false
            end
            
            local validServers = {}
            for _, server in pairs(serverData.data) do
                if server.playing and server.maxPlayers and server.id and 
                   server.playing < server.maxPlayers and 
                   server.id ~= JobId then
                    table.insert(validServers, server.id)
                end
            end
            
            if #validServers > 0 then
                local targetServerId = validServers[math.random(1, #validServers)]
                print("Attempting to teleport to server: " .. targetServerId)
                TeleportService:TeleportToPlaceInstance(PlaceId, targetServerId, LP)
                return true
            else
                warn("No valid servers found")
                return false
            end
        end)
        
        if not success then
            warn("Server hop failed: " .. tostring(result))
        end
    end)
end

-- Auto server hop check function
local function checkPlayerCountForServerHop()
    local currentTime = tick()
    if currentTime - lastPlayerCountCheck < 23.002 then return end
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
        print("Player " .. player.Name .. " has " .. toolCount .. " tools, targeting...")
        addTargetToLoop(player, TARGET_SOURCE_TOOL_COUNT)
    end
end

-- Damage tracking function for main users
local function trackMainUserDamage(mainUserName, newHealth)
    if not damage_taking then return end
    if not MAIN_USERS[mainUserName] then return end
    
    local lastHealth = lastHealthValues[mainUserName] or 100
    local damageTaken = lastHealth - newHealth
    
    -- Only track if damage was actually taken (not healing)
    if damageTaken > 0 then
        -- Find who might have caused this damage (closest non-main user)
        local mainUser = Players:FindFirstChild(mainUserName)
        if mainUser and mainUser.Character and mainUser.Character:FindFirstChild("HumanoidRootPart") then
            local mainUserPos = mainUser.Character.HumanoidRootPart.Position
            local closestPlayer = nil
            local closestDistance = math.huge
            
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= mainUser and 
                   not MAIN_USERS[player.Name] and 
                   not WHITELISTED_USERS[player.Name] and
                   player.Character and 
                   player.Character:FindFirstChild("HumanoidRootPart") then
                    
                    local distance = (player.Character.HumanoidRootPart.Position - mainUserPos).Magnitude
                    if distance < closestDistance and distance <= 100 then -- Within reasonable range
                        closestDistance = distance
                        closestPlayer = player
                    end
                end
            end
            
            -- Track damage from the closest player
            if closestPlayer then
                if not damageTrackers[closestPlayer.Name] then
                    damageTrackers[closestPlayer.Name] = {}
                end
                
                if not damageTrackers[closestPlayer.Name][mainUserName] then
                    damageTrackers[closestPlayer.Name][mainUserName] = 0
                end
                
                damageTrackers[closestPlayer.Name][mainUserName] = damageTrackers[closestPlayer.Name][mainUserName] + damageTaken
                
                print("Player " .. closestPlayer.Name .. " dealt " .. damageTaken .. " damage to " .. mainUserName .. " (Total: " .. damageTrackers[closestPlayer.Name][mainUserName] .. ")")
                
                -- Check if damage threshold exceeded
                if damageTrackers[closestPlayer.Name][mainUserName] >= local_damage then
                    print("Damage threshold exceeded! Looping " .. closestPlayer.Name .. " for dealing " .. damageTrackers[closestPlayer.Name][mainUserName] .. " damage to " .. mainUserName)
                    addTargetToLoop(closestPlayer, TARGET_SOURCE_DAMAGE)
                    
                    -- Reset damage counter for this player-victim pair
                    damageTrackers[closestPlayer.Name][mainUserName] = 0
                end
            end
        end
    end
    
    lastHealthValues[mainUserName] = newHealth
end

-- Setup damage tracking for main users
local function setupMainUserDamageTracking()
    for _, player in pairs(Players:GetPlayers()) do
        if MAIN_USERS[player.Name] then
            local function setupPlayerDamageTracking(character)
                local humanoid = character:WaitForChild("Humanoid", 10)
                if humanoid then
                    lastHealthValues[player.Name] = humanoid.Health
                    
                    local connection = humanoid.HealthChanged:Connect(function(newHealth)
                        trackMainUserDamage(player.Name, newHealth)
                    end)
                    
                    table.insert(connections, connection)
                end
            end
            
            if player.Character then
                setupPlayerDamageTracking(player.Character)
            end
            
            local connection = player.CharacterAdded:Connect(setupPlayerDamageTracking)
            table.insert(connections, connection)
        end
    end
end

-- Utility functions
local function findPlayerByPartialName(partialName)
    partialName = partialName:lower()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name:lower():find(partialName) then
            return player
        end
    end
end

addTargetToLoop = function(player, source)
    if not player or not player.Name or MAIN_USERS[player.Name] or WHITELISTED_USERS[player.Name] then return end
    
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
end

local function removeTargetFromLoop(player)
    if not player or not player.Name then return end
    
    for i, target in ipairs(getgenv().TargetTable) do
        if target == player then
            table.remove(getgenv().TargetTable, i)
            break
        end
    end
    
    targetedPlayers[player.Name] = nil
    targetSources[player.Name] = nil
    toolTargetedPlayers[player.Name] = nil -- Remove tool target flag
end

local function addPermanentTarget(player, source)
    if not player or not player.Name or MAIN_USERS[player.Name] or WHITELISTED_USERS[player.Name] then return end
    
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
        task.wait(0.01)
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
            task.wait()
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

-- Enhanced batch fire touch system
local function batchFireTouch(toolPart, targetParts)
    if not firetouchinterest then
        warn("firetouchinterest function not available in this executor")
        return
    end
    
    pcall(function() toolPart.Parent:Activate() end)
    
    -- Direct sequential firing with DMG_TIMES repetitions
    for i = 1, #targetParts do
        local part = targetParts[i]
        if part and part.Parent then
            pcall(function()
                for _ = 1, DMG_TIMES do
                    firetouchinterest(toolPart, part, 0)
                    firetouchinterest(toolPart, part, 1)
                end
            end)
        end
    end
    
    pcall(function() toolPart.Parent:Activate() end)
end

-- Enhanced kill loop with better performance
local function killLoop(player, toolPart)
    if killTrackers[player] then return end
    killTrackers[player] = true
    
    task.spawn(function()
        local consecutiveFailures = 0
        
        while killTrackers[player] and consecutiveFailures < 10 do
            local localChar = LP.Character
            local targetChar = player.Character
            
            if not (localChar and targetChar) then 
                consecutiveFailures = consecutiveFailures + 1
                task.wait(0.1)
                continue 
            end
            
            local tool = localChar:FindFirstChildWhichIsA("Tool")
            local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
            local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
            
            if not (tool and tool.Parent == localChar and toolPart.Parent and humanoid and humanoid.Health > 0 and rootPart) then
                consecutiveFailures = consecutiveFailures + 1
                task.wait(0.1)
                continue
            end
            
            consecutiveFailures = 0
            
            -- Multiple tool activations (reduced from 8 to 5)
            task.spawn(function()
                for _ = 1, 5 do
                    pcall(function() tool:Activate() end)
                end
            end)
            
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
            
            -- Consistent timing
            RunService.Heartbeat:Wait()
        end
        killTrackers[player] = nil
    end)
end

-- Enhanced combat handler
local function handleCombat(toolPart, player)
    local localChar = LP.Character
    local targetChar = player.Character
    
    if not (localChar and targetChar) then return end
    
    local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
    local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
    
    if not (humanoid and rootPart and humanoid.Health > 0) then return end
    
    -- Enhanced tool activations
    task.spawn(function()
        for _ = 1, 8 do
            pcall(function() 
                toolPart.Parent:Activate()
            end)
        end
    end)
    
    -- Collect all target parts
    table.clear(tempParts)
    for _, part in ipairs(targetChar:GetDescendants()) do
        if part:IsA("BasePart") and part.Parent then
            tempParts[#tempParts + 1] = part
        end
    end
    
    -- Enhanced damage application
    if #tempParts > 0 then
        task.spawn(function()
            batchFireTouch(toolPart, tempParts)
        end)
    end
    
    -- Start enhanced kill loop
    if not killTrackers[player] then
        killLoop(player, toolPart)
    end
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
                            task.spawn(function()
                                handleCombat(handle, target)
                            end)
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
                            task.spawn(function()
                                handleCombat(handle, player)
                            end)
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

-- FIXED CHAT COMMAND PROCESSING WITH ANTI-CONFLICT
local function processChatCommand(messageText, sender)
    -- Only process if sender is authorized and has a valid name
    if not sender or not sender.Name or not (MAIN_USERS[sender.Name] or SIGMA_USERS[sender.Name]) then return end
    
    -- Check if message starts with "/e "
    if messageText:sub(1, 3) ~= "/e " or #messageText <= 3 then return end
    
    local commandPart = messageText:sub(4) -- Remove "/e "
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
        ["shop"] = true,
        ["damagetaking"] = true -- New command for damage tracking
    }
    
    -- Only process if it's a valid command
    if not validCommands[command] then return end
    
    -- ANTI-CONFLICT SYSTEM: Check if this instance should handle the command
    local currentTime = tick()
    local commandKey = sender.Name .. "_" .. command .. "_" .. (args[2] or "")
    
    -- Cooldown check to prevent spam
    if COMMAND_COOLDOWN[commandKey] and currentTime - COMMAND_COOLDOWN[commandKey] < 1.5 then
        return
    end
    
    -- Instance selection based on player name hash for consistent assignment
    local hash = 0
    for i = 1, #LP.Name do
        hash = hash + LP.Name:byte(i)
    end
    local shouldHandle = (hash % 2) == (tick() % 2 < 1 and 0 or 1)
    
    -- For main users, always handle
    if MAIN_USERS[LP.Name] then
        shouldHandle = true
    end
    
    if not shouldHandle then return end
    
    COMMAND_COOLDOWN[commandKey] = currentTime
    
    -- Add small random delay to prevent exact simultaneous execution
    task.wait(math.random(1, 30) / 1000)
    
    -- Prepare webhook message
    local webhookMessage = "```[" .. INSTANCE_ID .. "] " .. sender.Name .. " used command: " .. command
    if #args > 1 then
        webhookMessage = webhookMessage .. " " .. table.concat(args, " ", 2)
    end
    webhookMessage = webhookMessage .. "```"
    
    if command == "loop" and #args >= 2 then
        local targetName = args[2]:lower()
        local targetPlayer = findPlayerByPartialName(targetName)
        if targetPlayer then
            addTargetToLoop(targetPlayer, TARGET_SOURCE_MANUAL)
            webhookMessage = webhookMessage .. "\nSuccessfully looped: " .. targetPlayer.Name
            print("Looped: " .. targetPlayer.Name)
        else
            webhookMessage = webhookMessage .. "\nPlayer not found: " .. args[2]
            print("Player not found: " .. args[2])
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
                        killTrackers[target] = nil
                    end
                end
                
                getgenv().PermanentTargets = {}
                getgenv().TargetTable = {}
                
                webhookMessage = webhookMessage .. "\nRemoved all " .. removedCount .. " targets"
                print("Removed all " .. removedCount .. " targets")
            else
                local targetName = args[2]:lower()
                local targetPlayer = findPlayerByPartialName(targetName)
                if targetPlayer then
                    getgenv().PermanentTargets[targetPlayer.Name] = nil
                    removeTargetFromLoop(targetPlayer)
                    webhookMessage = webhookMessage .. "\nSuccessfully unlooped: " .. targetPlayer.Name
                    print("Unlooped: " .. targetPlayer.Name)
                else
                    webhookMessage = webhookMessage .. "\nPlayer not found: " .. args[2]
                    print("Player not found: " .. args[2])
                end
            end
        else
            webhookMessage = webhookMessage .. "\nUsage: /e unloop <player> or /e unloop all"
        end
        
    elseif command == "sp" then
        getgenv().spam_swing = true
        webhookMessage = webhookMessage .. "\nSpam swing enabled"
        print("Spam swing enabled")
        
    elseif command == "unsp" then
        getgenv().spam_swing = false
        webhookMessage = webhookMessage .. "\nSpam swing disabled"
        print("Spam swing disabled")
        
    elseif command == "damagetaking" then
        if #args >= 2 then
            local setting = args[2]:lower()
            if setting == "true" or setting == "on" or setting == "enable" then
                damage_taking = true
                webhookMessage = webhookMessage .. "\nDamage tracking enabled (threshold: " .. local_damage .. ")"
                print("Damage tracking enabled")
            elseif setting == "false" or setting == "off" or setting == "disable" then
                damage_taking = false
                webhookMessage = webhookMessage .. "\nDamage tracking disabled"
                print("Damage tracking disabled")
                -- Clear damage trackers when disabled
                damageTrackers = {}
            else
                webhookMessage = webhookMessage .. "\nUsage: /e damagetaking true/false"
            end
        else
            local status = damage_taking and "enabled" or "disabled"
            webhookMessage = webhookMessage .. "\nDamage tracking is currently " .. status .. " (threshold: " .. local_damage .. ")"
        end
        
    elseif command == "activate" then
        loadstring(game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/aci.lua'))()
        webhookMessage = webhookMessage .. "\nActivating external script"
        print("Activating external script")
        
    elseif command == "update" then
        TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LP)
        webhookMessage = webhookMessage .. "\nRestarting script"
        print("Restarting script")
        
    elseif command == "serverhop" or command == "shop" then
        serverHop()
        webhookMessage = webhookMessage .. "\nServer hopping..."
        print("Server hopping...")
    end
    
    -- Only send webhook if the LOCAL PLAYER is "Pyan503" (not the sender)
    if LP.Name == "Pyan503" then
        sendmsg(webhookUrl, webhookMessage)
    end
end

-- IMPROVED CHAT DETECTION SYSTEM WITH CONFLICT RESOLUTION
local chatConnections = {}

local function setupChatCommandHandler()
    -- Clear existing chat connections
    for _, connection in pairs(chatConnections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(chatConnections)
    
    -- Method 1: Direct player Chatted event (most reliable)
    local function connectPlayerChat(player)
        if player == LP then return end
        
        local connection = player.Chatted:Connect(function(message)
            processChatCommand(message, player)
        end)
        chatConnections[#chatConnections + 1] = connection
    end
    
    -- Connect to existing players
    for _, player in pairs(Players:GetPlayers()) do
        connectPlayerChat(player)
    end
    
    -- Connect to new players
    local playerAddedConnection = Players.PlayerAdded:Connect(connectPlayerChat)
    chatConnections[#chatConnections + 1] = playerAddedConnection
    
    -- Method 2: TextChatService (backup for newer chat system)
    pcall(function()
        if TextChatService then
            local textChannels = TextChatService:FindFirstChild("TextChannels")
            if textChannels then
                local rbxGeneral = textChannels:FindFirstChild("RBXGeneral")
                if rbxGeneral then
                    local connection = rbxGeneral.MessageReceived:Connect(function(message)
                        if message.TextSource then
                            local userId = message.TextSource.UserId
                            local sender = Players:GetPlayerByUserId(userId)
                            if sender and sender ~= LP then
                                processChatCommand(message.Text, sender)
                            end
                        end
                    end)
                    chatConnections[#chatConnections + 1] = connection
                end
            end
        end
    end)
    
    -- Method 3: Legacy chat system (additional backup)
    pcall(function()
        local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvents then
            local onMessageDoneFiltering = chatEvents:FindFirstChild("OnMessageDoneFiltering")
            if onMessageDoneFiltering then
                local connection = onMessageDoneFiltering.OnClientEvent:Connect(function(messageData)
                    if messageData and messageData.FromSpeaker and messageData.Message then
                        local sender = Players:FindFirstChild(messageData.FromSpeaker)
                        if sender then
                            processChatCommand(messageData.Message, sender)
                        end
                    end
                end)
                chatConnections[#chatConnections + 1] = connection
            end
        end
    end)
    
    print("Chat command handler setup complete for instance: " .. INSTANCE_ID)
end

-- Kill logger setup
local function setupKillLogger()
    pcall(function()
        local event = ReplicatedStorage:WaitForChild("APlayerWasKilled", 10)
        if not event then return end
        
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
                        -- Only add as permanent target if damage_taking is disabled
                        if not damage_taking then
                            addPermanentTarget(killer, TARGET_SOURCE_KILL_REVENGE)
                        end
                    else
                        if not damage_taking then
                            getgenv().PermanentTargets[killerName] = true
                            targetedPlayers[killerName] = true
                            targetSources[killerName] = TARGET_SOURCE_KILL_REVENGE
                        end
                    end
                end
            end
        end)
        
        table.insert(connections, connection)
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
    
    -- Setup damage tracking for main users
    if MAIN_USERS[player.Name] then
        local function setupPlayerDamageTracking(character)
            local humanoid = character:WaitForChild("Humanoid", 10)
            if humanoid then
                lastHealthValues[player.Name] = humanoid.Health
                
                -- Clear any existing damage trackers for this main user when they respawn
                for attackerName in pairs(damageTrackers) do
                    if damageTrackers[attackerName][player.Name] then
                        damageTrackers[attackerName][player.Name] = 0
                    end
                end
                
                local connection = humanoid.HealthChanged:Connect(function(newHealth)
                    trackMainUserDamage(player.Name, newHealth)
                end)
                
                table.insert(connections, connection)
            end
        end
        
        if player.Character then
            setupPlayerDamageTracking(player.Character)
        end
        
        local connection = player.CharacterAdded:Connect(setupPlayerDamageTracking)
        table.insert(connections, connection)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    for i = #playerList, 1, -1 do
        if playerList[i] == player then
            table.remove(playerList, i)
            killTrackers[player] = nil
            break
        end
    end
    
    -- Clean up damage tracking data
    if player.Name then
        damageTrackers[player.Name] = nil
        lastHealthValues[player.Name] = nil
        
        -- Only remove from targeting if they were tool-targeted (not permanently or manually targeted)
        if toolTargetedPlayers[player.Name] and not getgenv().PermanentTargets[player.Name] then
            toolTargetedPlayers[player.Name] = nil
            targetedPlayers[player.Name] = nil
            targetSources[player.Name] = nil
            removeTargetFromLoop(player)
        end
    end
end)

-- Character setup
LP.CharacterAdded:Connect(function(character)
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
    setupCharacter(character)
end)

if LP.Character then
    local humanoid = LP.Character:WaitForChild("Humanoid")
    -- Sword spam on death
    humanoid.Died:Connect(function()
        swordSoundSpam(0.1)
    end)
    -- Sword spam + remove animations instantly on respawn
    task.spawn(function()
        removeAnimations(LP.Character)
        swordSoundSpam(0.2)
    end)
    setupCharacter(LP.Character)
end

-- Main enhanced loops
RunService.Heartbeat:Connect(onHeartbeat)
RunService.Stepped:Connect(autoEquip)
RunService.RenderStepped:Connect(teleportLoop)

-- Auto server hop check loop
RunService.Heartbeat:Connect(checkPlayerCountForServerHop)

-- Tool count monitoring loop
RunService.Heartbeat:Connect(function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then
            checkToolCount(player)
        end
    end
end)

-- Spam swing loop
RunService.Heartbeat:Connect(function()
    if getgenv().spam_swing and LP.Character and LP.Character:FindFirstChild("Sword") then
        LP.Character.Sword:Activate()
    end
end)

-- Initialize systems
updatePlayerList()
setupChatCommandHandler()
setupKillLogger()
setupMainUserDamageTracking()

local statusMsg = "ver" .. version .. " [" .. INSTANCE_ID .. "] - Fixed Server Hop & Nil Username Error"
print(statusMsg)

-- Send initialization webhook if this is Pyan503
if LP.Name == "Pyan503" then
    sendmsg(webhookUrl, "```Script initialized: " .. statusMsg .. "```")
end
