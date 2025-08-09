local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local teleportConnection

-- CENTRALIZED TELEPORT TARGETS (FIXED DUPLICATE ISSUE)
local teleportTargets = {
    ["Cubot_Nova3"]     = CFrame.new(7152,4405,4707),
    ["Cub0t_01"]        = CFrame.new(7122,4505,4719),
    ["cubot_nova4"]     = CFrame.new(7122,4475,4719),
    ["cubot_autoIoop"]  = CFrame.new(7132,4605,4707),
    ["Cubot_Nova2"]     = CFrame.new(7122,4705,4729),
    ["Cubot_Nova1"]     = CFrame.new(7132,4605,4529),
}

-- Store original positions for unline command
local originalTargets = {
    ["Cubot_Nova3"]     = CFrame.new(7152,4405,4707),
    ["Cub0t_01"]        = CFrame.new(7122,4505,4719),
    ["cubot_nova4"]     = CFrame.new(7122,4475,4719),
    ["cubot_autoIoop"]  = CFrame.new(7132,4605,4707),
    ["Cubot_Nova2"]     = CFrame.new(7122,4705,4729),
    ["Cubot_Nova1"]     = CFrame.new(7132,4605,4529),
}

-- Line formation positions (facing backward - 180 degrees turned)
local lineTargets = {
    ["Cubot_Nova3"]     = CFrame.new(-31, 125, -70, -1, 0, 0, 0, 1, 0, 0, 0, -1),
    ["Cub0t_01"]        = CFrame.new(-23, 125, -70, -1, 0, 0, 0, 1, 0, 0, 0, -1),
    ["cubot_nova4"]     = CFrame.new(-15, 125, -70, -1, 0, 0, 0, 1, 0, 0, 0, -1),
    ["cubot_autoIoop"]  = CFrame.new(-7, 125, -70, -1, 0, 0, 0, 1, 0, 0, 0, -1),
    ["Cubot_Nova2"]     = CFrame.new(-3, 125, -70, -1, 0, 0, 0, 1, 0, 0, 0, -1),
    ["Cubot_Nova1"]     = CFrame.new(4, 125, -70, -1, 0, 0, 0, 1, 0, 0, 0, -1),
}

--// AUTO ACTIVATE SETTING (REMOVED DUPLICATE)
local autoactivate = false -- Set to false to disable auto-activation

--// SERVER HOP SETTINGS
local serverHopEnabled = true -- Set to false to disable server hopping
local minPlayersRequired = 4 -- Will hop if less than this many players
local hopAttemptInterval = 5 -- Try to hop every 5 seconds when below minimum players

--// ACTIVATION STATE
local isActivated = false -- Track if new script is activated
local oldScriptActive = true -- Track if old script features are active

--// SPAM LOOP VARIABLES
local spamConnection = nil -- Track the spam loop connection

--// IMPROVED GOON LOOP VARIABLES
local goonConnection = nil -- Track the goon loop connection
local goonAnimTrack = nil -- Track the animation
local isGooning = false -- Track goon state
local goonAnimObject = nil -- Store the animation object
local lastGoonTime = 0 -- Track timing for better loops

--// AUTOEQUIP STATE (ALWAYS ENABLED - DOESN'T DISABLE ON GOON)
local autoequipEnabled = true -- Track if autoequip should be enabled

--// TOOL LIMITER SYSTEM (ALWAYS ENABLED)
local toolLimiterEnabled = true -- Tool limiting system automatically enabled
local maxToolsPerPlayer = 1 -- Maximum tools allowed per player (excluding LocalPlayer)
local toolLimiterConnection = nil -- Track the tool limiter connection

-- TOOL LIMITER FUNCTIONS
local function countPlayerTools(player)
    if not player or player == LP then return 0 end
    
    local toolCount = 0
    
    -- Count tools in backpack
    local backpack = player:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                toolCount = toolCount + 1
            end
        end
    end
    
    -- Count equipped tools
    if player.Character then
        for _, item in ipairs(player.Character:GetChildren()) do
            if item:IsA("Tool") then
                toolCount = toolCount + 1
            end
        end
    end
    
    return toolCount
end

local function destroyExcessTools(player)
    if not player or player == LP or not toolLimiterEnabled then return end
    
    local toolsDestroyed = 0
    local toolsFound = {}
    
    -- Collect all tools
    local backpack = player:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(toolsFound, item)
            end
        end
    end
    
    if player.Character then
        for _, item in ipairs(player.Character:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(toolsFound, item)
            end
        end
    end
    
    -- Keep only the first tool, destroy the rest
    if #toolsFound > maxToolsPerPlayer then
        for i = maxToolsPerPlayer + 1, #toolsFound do
            local tool = toolsFound[i]
            if tool and tool.Parent then
                pcall(function()
                    tool:Destroy()
                    toolsDestroyed = toolsDestroyed + 1
                end)
            end
        end
    end
    
    return toolsDestroyed
end

local function startToolLimiter()
    if toolLimiterConnection then return end -- Already running
    
    toolLimiterConnection = RunService.Heartbeat:Connect(function()
        if not toolLimiterEnabled then return end
        
        pcall(function()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LP then
                    local toolCount = countPlayerTools(player)
                    if toolCount > maxToolsPerPlayer then
                        destroyExcessTools(player)
                    end
                end
            end
        end)
    end)
end

local function stopToolLimiter()
    if toolLimiterConnection then
        toolLimiterConnection:Disconnect()
        toolLimiterConnection = nil
    end
end

local function setupTeleport()
    if teleportConnection then 
        teleportConnection:Disconnect() 
        teleportConnection = nil
    end
    
    local cf = teleportTargets[LP.Name]
    if cf then
        teleportConnection = RunService.Heartbeat:Connect(function()
            local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if r then
                r.CFrame = cf
                r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
        end)
    end
end

-- Fix anti-AFK with proper error handling
local GC = getconnections or get_signal_cons
if GC then
    local success, connections = pcall(function()
        return GC(LP.Idled)
    end)
    if success and connections then
        for _, conn in pairs(connections) do
            if conn.Disable then 
                pcall(function() conn:Disable() end)
            elseif conn.Disconnect then 
                pcall(function() conn:Disconnect() end)
            end
        end
    end
else
    -- Fallback anti-AFK
    local success, vu = pcall(function()
        return game:GetService("VirtualUser")
    end)
    if success and vu then
        LP.Idled:Connect(function()
            pcall(function()
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end)
    end
end

task.defer(function()
    pcall(function()
        StarterGui:SetCore("PlayerListVisibility", false)
    end)

    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
            StarterGui:SetCore("ChatActive", false)
        else
            local chatUI = LP:WaitForChild("PlayerGui"):FindFirstChild("Chat")
            if chatUI then chatUI.Enabled = false end
        end
    end)

    pcall(function()
        local playerList = CoreGui:FindFirstChild("PlayerList")
        if playerList then playerList:Destroy() end
    end)
end)

if game.PlaceId ~= 6110766473 then return end

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Lighting          = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService   = game:GetService("TextChatService")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")
local LP                = Players.LocalPlayer
local PlaceId           = game.PlaceId

--// QUEUE ON TELEPORT SETUP
local KeepInfYield  = true
local TeleportCheck = false
local queueteleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)

LP.OnTeleport:Connect(function()
    if KeepInfYield and not TeleportCheck and queueteleport then
        TeleportCheck = true
        pcall(function()
            queueteleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/file.lua'))()")
        end)
    end
end)

--// CONFIGURATION
local MAIN_USERS = {
    ["cubot_autoIoop"] = true,
    ["Cubot_Nova2"] = true,
    ["Cubot_Nova3"] = true,
    ["cubot_nova4"] = true,
    ["Cub0t_01"] = true,
    ["FlexFightPro68"]   = true,
    ["Iamnotrealyblack"]  = true,
}
local SIGMA_USERS = {
    ["FlexFightPro68"]   = true,
    ["Iamnotrealyblack"]  = true,
    ["e5c4qe"]  = true,
}
local SECONDARY_MAIN_USERS = {
    ["sssssss"] = true,
}
local ALWAYS_KILL = {
    ["lurty15109"] = true,
    ["ccccc"]               = true,
    ["GoatReflex"]        = true,
    ["Dirdaclub"]     = true,
    ["BmwFounder"]           = true,
    ["mmmnmmmmnmmmnmmmmmmn"]             = true,
    ["Tvuj_ciko"]              = true,
    ["error232933"]          = true,
    ["FlexFightSecurity015"] = true,
    ["Barbiejetop"]          = true,
    ["Latticeon"]    = true,
}
-- NEW WHITELIST TABLE
local WHITELISTED_USERS = {
    ["e5c4qe"] = true,
    ["xL1fe_r"] = true,
    ["xL1v3_r"] = true,
    ["xLiv3_r"] = true,
}

--// VARIABLES
local targetList               = {}    -- Active player objects being targeted
local targetNames              = {}    -- Names of players to target (persists)
local temporaryTargets         = {}
local oneShotTargets           = {}   -- for .kill
local killTracker              = {}
local DMG_TIMES                = 2
local FT_TIMES                 = 5
local CN                       = nil   -- killloop connection
local TEMP_TARGET_DURATION     = 99999999999
local SECONDARY_TARGET_DURATION= 120
local CMD_PREFIX               = "."
local TOOL_COUNT_THRESHOLD     = 250
local lastServerCheck          = 0     -- For server hopping cooldown
local isHopping                = false -- Prevent multiple hop attempts

--// PERSISTENT TARGET TRACKING
-- Initialize targetNames with ALWAYS_KILL users
for name, _ in pairs(ALWAYS_KILL) do
    targetNames[name] = true
end

--// SHARED REVENGE OBJECT
local sharedRevenge = workspace:FindFirstChild("SharedRevenge")
if not sharedRevenge then
    sharedRevenge = Instance.new("StringValue")
    sharedRevenge.Name   = "SharedRevenge"
    sharedRevenge.Parent = workspace
end

--// SPAM LOOP FUNCTIONS
local function startSpamLoop()
    if spamConnection then return end -- Already running
    
    spamConnection = RunService.Stepped:Connect(function()
        pcall(function()
            -- Destroy specific tools from backpack
            for _, tool in ipairs(LP.Backpack:GetChildren()) do
                if tool.Name == "Punch" or tool.Name == "Ground Slam" or tool.Name == "Stomp" then
                    tool:Destroy()
                elseif tool:IsA("Tool") then
                    tool.Parent = LP.Character
                end
            end
            
            -- Activate equipped tool
            if LP.Character then
                local tool = LP.Character:FindFirstChildOfClass("Tool")
                if tool then
                    tool:Activate()
                end
            end
        end)
    end)
end

local function stopSpamLoop()
    if spamConnection then
        spamConnection:Disconnect()
        spamConnection = nil
    end
end

--// IMPROVED GOON LOOP FUNCTIONS
local function isR15(player)
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    return humanoid.RigType == Enum.HumanoidRigType.R15
end

local function createGoonAnimation()
    if goonAnimObject then return goonAnimObject end
    
    goonAnimObject = Instance.new("Animation")
    local isR15Player = isR15(LP)
    goonAnimObject.AnimationId = isR15Player and "rbxassetid://698251653" or "rbxassetid://72042024"
    return goonAnimObject
end

local function startGoonLoop()
    if isGooning then return end -- Already running
    
    isGooning = true
    -- DON'T disable autoequip - keep it enabled
    lastGoonTime = tick()
    
    goonConnection = RunService.Heartbeat:Connect(function()
        if not isGooning then return end
        
        local character = LP.Character
        if not character then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        pcall(function()
            -- Clean up old animation track if it exists and isn't playing properly
            if goonAnimTrack then
                if goonAnimTrack.IsPlaying and goonAnimTrack.TimePosition >= (isR15(LP) and 0.7 or 0.65) then
                    goonAnimTrack:Stop()
                    goonAnimTrack = nil
                elseif not goonAnimTrack.IsPlaying then
                    goonAnimTrack = nil
                end
            end
            
            -- Create new animation track if needed
            if not goonAnimTrack then
                local animObject = createGoonAnimation()
                if animObject then
                    goonAnimTrack = humanoid:LoadAnimation(animObject)
                    if goonAnimTrack then
                        goonAnimTrack.Priority = Enum.AnimationPriority.Action
                        goonAnimTrack:Play()
                        goonAnimTrack:AdjustSpeed(isR15(LP) and 0.7 or 0.65)
                        goonAnimTrack.TimePosition = 0.6
                        lastGoonTime = tick()
                    end
                end
            end
        end)
    end)
end

local function stopGoonLoop()
    if not isGooning then return end
    
    isGooning = false
    -- DON'T re-enable autoequip since we never disabled it
    
    if goonConnection then
        goonConnection:Disconnect()
        goonConnection = nil
    end
    
    if goonAnimTrack then
        pcall(function()
            goonAnimTrack:Stop()
        end)
        goonAnimTrack = nil
    end
    
    -- Clean up animation object
    if goonAnimObject then
        goonAnimObject:Destroy()
        goonAnimObject = nil
    end
end

--// FIXED EXECUTE FUNCTION
local function execute()
    -- Set activation state but DON'T disable old script
    isActivated = true
    -- Keep oldScriptActive = true so old features continue working
    
    -- DON'T clear targets - let them persist
    -- DON'T disconnect killloop - let it keep running
    
    -- Load the new script alongside the old one with better error handling
    local success, err = pcall(function()
        local scriptContent = game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/aci.lua')
        loadstring(scriptContent)()
    end)
    
    if not success then
        warn("Failed to load aci.lua:", err)
    end
end

-- Alias for chat handler compatibility
local executeActivate = execute

--// FPS BOOST FUNCTIONS
local function equipAllTools()
    for i,v in pairs(LP:FindFirstChildOfClass("Backpack"):GetChildren()) do
        if v:IsA("Tool") or v:IsA("HopperBin") then
            v.Parent = LP.Character
        end
    end
end

local function startFPSBoost()
    -- First, fire the remote 2000 times
    local unlockedSwords = ReplicatedStorage:FindFirstChild("UnlockedSwords")
    if unlockedSwords then
        for i = 1, 300 do
            pcall(function()
                unlockedSwords:FireServer({false, false, false}, "894An3ti44Ex321P3llo99i3t")
            end)
        end
    end
    
    -- Wait 55 seconds
    task.wait(10)
    
    -- Then equip all tools
    equipAllTools()
end

--------------------------------------------------------------------------------
-- FPS BOOSTER
--------------------------------------------------------------------------------
do
    local Terrain = workspace:FindFirstChildOfClass("Terrain")
    if Terrain then
        Terrain.WaterWaveSize     = 0
        Terrain.WaterWaveSpeed    = 0
        Terrain.WaterReflectance  = 0
        Terrain.WaterTransparency = 0
    end
    Lighting.GlobalShadows       = false
    Lighting.FogEnd              = 9e9
    settings().Rendering.QualityLevel = 1

    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material    = Enum.Material.Plastic
            v.Reflectance = 0
        elseif v:IsA("Decal") then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Lifetime = NumberRange.new(0)
        elseif v:IsA("Explosion") then
            v.BlastPressure = 1
            v.BlastRadius   = 1
        end
    end

    for _, eff in ipairs(Lighting:GetDescendants()) do
        if eff:IsA("BlurEffect")
        or eff:IsA("SunRaysEffect")
        or eff:IsA("ColorCorrectionEffect")
        or eff:IsA("BloomEffect")
        or eff:IsA("DepthOfFieldEffect") then
            eff.Enabled = false
        end
    end

    workspace.DescendantAdded:Connect(function(child)
        task.spawn(function()
            if child:IsA("ForceField")
            or child:IsA("Sparkles")
            or child:IsA("Smoke")
            or child:IsA("Fire") then
                RunService.Heartbeat:Wait()
                child:Destroy()
            end
        end)
    end)
end

--------------------------------------------------------------------------------
-- ANTI-FLING
--------------------------------------------------------------------------------
RunService.Stepped:Connect(function()
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP and pl.Character then
            for _, part in ipairs(pl.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- TARGET MANAGEMENT (SIMPLIFIED)
--------------------------------------------------------------------------------
local function addPermanentTarget(pl)
    if not oldScriptActive then return end -- Don't add targets if new script is active
    
    if not pl
    or MAIN_USERS[pl.Name]
    or SECONDARY_MAIN_USERS[pl.Name]
    or SIGMA_USERS[pl.Name]
    or WHITELISTED_USERS[pl.Name] then -- Check whitelist
        return
    end
    targetNames[pl.Name] = true
    if not table.find(targetList, pl) then
        table.insert(targetList, pl)
    end
    if MAIN_USERS[LP.Name] or SIGMA_USERS[LP.Name] then
        sharedRevenge.Value = pl.Name
    end
end

local function removeTarget(pl)
    if not oldScriptActive then return end -- Don't modify targets if new script is active
    
    if not pl or ALWAYS_KILL[pl.Name] then return false end
    targetNames[pl.Name] = nil
    temporaryTargets[pl.Name] = nil
    oneShotTargets[pl.Name] = nil
    -- Remove from targetList
    for i=#targetList,1,-1 do
        if targetList[i] == pl then
            table.remove(targetList, i)
        end
    end
    return true
end

local function addTemporaryTarget(pl, dur)
    if not oldScriptActive then return end -- Don't add targets if new script is active
    
    if not pl
    or MAIN_USERS[pl.Name]
    or SECONDARY_MAIN_USERS[pl.Name]
    or SIGMA_USERS[pl.Name]
    or WHITELISTED_USERS[pl.Name] then -- Check whitelist
        return
    end
    local duration = dur or TEMP_TARGET_DURATION
    temporaryTargets[pl.Name] = os.time() + duration
    if not table.find(targetList, pl) then
        table.insert(targetList, pl)
    end
    if MAIN_USERS[LP.Name] or SIGMA_USERS[LP.Name] then
        if dur == SECONDARY_TARGET_DURATION then
            sharedRevenge.Value = "TEMP_EXT:"..pl.Name
        else
            sharedRevenge.Value = "TEMP:"..pl.Name
        end
    end
end

--------------------------------------------------------------------------------
-- NAME MATCHING
--------------------------------------------------------------------------------
local function findPlayerByPartialName(partial)
    if not partial or partial == "" then return nil end
    partial = partial:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == partial then
            return p
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1,#partial) == partial then
            return p
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(partial,1,true) then
            return p
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- CHAT COMMANDS (MAIN & SIGMA ONLY) - UPDATED WITH SP COMMANDS
--------------------------------------------------------------------------------
local function processChatCommand(msg)
    if msg:sub(1,#CMD_PREFIX) ~= CMD_PREFIX then return end
    local parts = {}
    for w in msg:sub(#CMD_PREFIX+1):gmatch("%S+") do
        table.insert(parts, w)
    end
    local cmd  = parts[1] and parts[1]:lower()
    local name = parts[2]
    
    -- Handle tool limiter commands
    if cmd == "toollimit" then
        if name == "on" then
            toolLimiterEnabled = true
            startToolLimiter()
            return
        elseif name == "off" then
            toolLimiterEnabled = false
            stopToolLimiter()
            return
        end
    end
    
    -- Handle goon commands
    if cmd == "goon" then
        startGoonLoop()
        return
    elseif cmd == "ungoon" then
        stopGoonLoop()
        return
    end
    
    -- Handle spam commands
    if cmd == "sp" then
        startSpamLoop()
        return
    elseif cmd == "unsp" then
        stopSpamLoop()
        return
    end
    
    -- Handle server hop commands
    if cmd == "hop" then
        if name == "on" then
            serverHopEnabled = true
            return
        elseif name == "off" then
            serverHopEnabled = false
            return
        elseif name == "now" then
            checkAndHopServers()
            return
        end
    end
    
    -- Handle line commands - FIXED
    if cmd == "line" then
        -- Change teleport targets to line formation
        for name, pos in pairs(lineTargets) do
            teleportTargets[name] = pos
        end
        -- Reconnect teleport with new targets
        setupTeleport()
        return
    end
    
    if cmd == "unline" then
        -- Revert teleport targets back to original
        for name, pos in pairs(originalTargets) do
            teleportTargets[name] = pos
        end
        -- Reconnect teleport with original targets
        setupTeleport()
        return
    end
    
    -- Handle FPS boost command
    if cmd == "fpsboost" then
        startFPSBoost()
        return
    end
    
    -- Handle restart command
    if cmd == "restart" then
        local character = LP.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
            end
        end
        return
    end
    
    if not cmd or not name then return end
    local pl = findPlayerByPartialName(name)
    if not pl then return end

    if cmd == "loop" then
        addPermanentTarget(pl)
    elseif cmd == "unloop" then
        removeTarget(pl)
    elseif cmd == "kill" then
        oneShotTargets[pl.Name] = true
        if not targetNames[pl.Name] then
            table.insert(targetList, pl)
        end
    end
end

local function setupTextChatCommandHandler()
    pcall(function()
        if TextChatService and TextChatService.MessageReceived then
            TextChatService.MessageReceived:Connect(function(txtMsg)
                local sender = Players:GetPlayerByUserId(txtMsg.TextSource.UserId)
                if sender and (MAIN_USERS[sender.Name] or SIGMA_USERS[sender.Name]) then
                    local m = txtMsg.Text:lower()
                    if m == ".activate" then
                        execute()
                    elseif m == ".update" then
                        sharedRevenge.Value = "UPDATE"
                    else
                        processChatCommand(txtMsg.Text)
                    end
                end
            end)
        else
            local events = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents",10)
            if events then
                local msgEvent = events:FindFirstChild("OnMessageDoneFiltering")
                if msgEvent then
                    msgEvent.OnClientEvent:Connect(function(data)
                        local speaker = Players:FindFirstChild(data.FromSpeaker)
                        if speaker and (MAIN_USERS[speaker.Name] or SIGMA_USERS[speaker.Name]) then
                            local m = data.Message:lower()
                            if m == ".activate" then
                                execute()
                            elseif m == ".update" then
                                sharedRevenge.Value = "UPDATE"
                            else
                                processChatCommand(data.Message)
                            end
                        end
                    end)
                end
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- SHARED_REVENGE LISTENER (INCLUDES UPDATE)
--------------------------------------------------------------------------------
sharedRevenge:GetPropertyChangedSignal("Value"):Connect(function()
    local val = sharedRevenge.Value

    if val == "UPDATE" then
        if KeepInfYield and not TeleportCheck and queueteleport then
            TeleportCheck = true
            pcall(function()
                queueteleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/file.lua'))()")
            end)
        end
        TeleportService:TeleportToPlaceInstance(PlaceId, game.JobId)
        return
    end

    -- Only process revenge targets if old script is active
    if not oldScriptActive then return end

    if val:sub(1,9) == "TEMP_EXT:" then
        local name = val:sub(10)
        local p    = Players:FindFirstChild(name)
        if p then addTemporaryTarget(p, SECONDARY_TARGET_DURATION) end
    elseif val:sub(1,5) == "TEMP:" then
        local name = val:sub(6)
        local p    = Players:FindFirstChild(name)
        if p then addTemporaryTarget(p) end
    else
        local p = Players:FindFirstChild(val)
        if p then addPermanentTarget(p) end
    end
end)

--------------------------------------------------------------------------------
-- SERVER HOPPING LOGIC (FIXED)
--------------------------------------------------------------------------------
function checkAndHopServers()
    -- Prevent multiple simultaneous hop attempts
    if isHopping then return end
    
    -- Only hop if enabled
    if not serverHopEnabled then return end
    
    local currentPlayers = #Players:GetPlayers()
    
    -- Check if we should hop
    if currentPlayers >= minPlayersRequired then 
        return 
    end
    
    isHopping = true
    
    local servers = {}
    local success, result = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true")
    end)
    
    if not success then 
        warn("Failed to fetch servers:", result)
        isHopping = false
        return 
    end
    
    local body
    pcall(function()
        body = HttpService:JSONDecode(result)
    end)
    
    if body and body.data then
        for i, v in next, body.data do
            if type(v) == "table" and v.id ~= game.JobId then
                local playing = tonumber(v.playing)
                local maxPlayers = tonumber(v.maxPlayers)
                
                if playing and maxPlayers and playing < maxPlayers then
                    -- Add ALL available servers
                    table.insert(servers, {id = v.id, players = playing})
                end
            end
        end
    end
    
    -- Sort servers by player count (highest first)
    table.sort(servers, function(a, b) return a.players > b.players end)
    
    if #servers > 0 then
        -- Queue the script to run after teleport
        if KeepInfYield and queueteleport then
            pcall(function()
                queueteleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/file.lua'))()")
            end)
        end
        
        -- Try servers in order from most players to least
        for idx, server in ipairs(servers) do
            -- Try to teleport
            local teleportSuccess = pcall(function()
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LP)
            end)
            
            if teleportSuccess then
                break -- Exit if teleport initiated successfully
            end
            
            -- Try up to 3 servers before giving up this attempt
            if idx >= 3 then
                break
            end
            
            task.wait(0.5) -- Small delay between attempts
        end
    else
        warn("No available servers found")
    end
    
    isHopping = false
end

-- Server hop monitoring task (FIXED)
task.spawn(function()
    task.wait(10) -- Wait 10 seconds after joining before first check
    
    while true do
        if serverHopEnabled then
            local currentPlayers = #Players:GetPlayers()
            
            -- If below minimum players, check every 5 seconds
            if currentPlayers < minPlayersRequired then
                checkAndHopServers()
                task.wait(hopAttemptInterval) -- 5 seconds
            else
                -- If we have enough players, check less frequently
                task.wait(30)
            end
        else
            task.wait(30) -- Check every 30 seconds when disabled
        end
    end
end)

--------------------------------------------------------------------------------
-- CLEANUP TEMP TARGETS (SIMPLIFIED)
--------------------------------------------------------------------------------
task.spawn(function()
    while true do
        if oldScriptActive then -- Only clean up if old script is active
            local now = os.time()
            for name, exp in pairs(temporaryTargets) do
                if exp <= now then
                    temporaryTargets[name] = nil
                    -- Only remove from targetList if not a permanent target
                    if not targetNames[name] then
                        local p = Players:FindFirstChild(name)
                        if p then 
                            for i=#targetList,1,-1 do
                                if targetList[i] == p then
                                    table.remove(targetList, i)
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end)

--------------------------------------------------------------------------------
-- TOOL COUNT DETECTION
--------------------------------------------------------------------------------
local function checkPlayerToolCount(pl)
    if not oldScriptActive then return end -- Don't check if new script is active
    
    if   MAIN_USERS[pl.Name]
     or SECONDARY_MAIN_USERS[pl.Name]
     or SIGMA_USERS[pl.Name]
     or WHITELISTED_USERS[pl.Name] -- Check whitelist
     or targetNames[pl.Name]
     or ALWAYS_KILL[pl.Name] then
        return
    end
    local count = 0
    local bp = pl:FindFirstChildOfClass("Backpack")
    if bp then for _, itm in ipairs(bp:GetChildren()) do
        if itm:IsA("Tool") then count += 1 end
    end end
    if pl.Character then for _, itm in ipairs(pl.Character:GetChildren()) do
        if itm:IsA("Tool") then count += 1 end
    end end
    if count >= TOOL_COUNT_THRESHOLD then
        addPermanentTarget(pl)
    end
end

task.spawn(function()
    while true do
        if oldScriptActive then -- Only check if old script is active
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP then checkPlayerToolCount(p) end
            end
        end
        task.wait(5)
    end
end)

--------------------------------------------------------------------------------
-- ULTRA FAST AUTOEQUIP & BOXREACH (ALWAYS ENABLED) - NO DELAYS
--------------------------------------------------------------------------------

local function fastForceEquip()
    -- Always equip regardless of goon state
    local char = LP.Character
    if not char then return end
    
    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end
    
    -- Check if we already have a sword equipped
    local equippedSword = char:FindFirstChild("Sword")
    if equippedSword then return end
    
    -- Try to find and equip sword from backpack immediately
    local sword = LP.Backpack:FindFirstChild("Sword")
    if sword then
        -- Use pcall for safety
        pcall(function()
            humanoid:EquipTool(sword)
        end)
        return
    end
    
    -- If no sword in backpack, try to equip any available tool immediately
    for _, tool in ipairs(LP.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name ~= "Punch" and tool.Name ~= "Ground Slam" and tool.Name ~= "Stomp" then
            pcall(function()
                humanoid:EquipTool(tool)
            end)
            break
        end
    end
end

-- Maximum speed autoequip system with all available event loops
RunService.Heartbeat:Connect(fastForceEquip) -- Primary equip loop
RunService.Stepped:Connect(fastForceEquip)   -- Secondary equip loop
RunService.RenderStepped:Connect(fastForceEquip) -- Tertiary equip loop for maximum responsiveness

-- Immediate equip on backpack changes
LP.ChildAdded:Connect(function(child)
    if child.Name == "Backpack" then
        child.ChildAdded:Connect(function(tool)
            if tool:IsA("Tool") and tool.Name == "Sword" then
                fastForceEquip() -- Immediate equip attempt with no delay
            end
        end)
    end
end)

-- Instant equip on character spawn
LP.CharacterAdded:Connect(function(char)
    -- Immediate equip attempt
    fastForceEquip()
    
    -- Wait for humanoid and backpack with immediate equip attempts
    task.spawn(function()
        local humanoid = char:WaitForChild("Humanoid", 5)
        local backpack = LP:WaitForChild("Backpack", 5)
        
        if humanoid and backpack then
            -- Continuous immediate equip attempts with no delays
            for i = 1, 100 do -- Increased attempts
                fastForceEquip()
                if char:FindFirstChild("Sword") then break end
                task.wait() -- Minimal yield, no actual delay
            end
        end
    end)
end)

-- Monitor for sword being unequipped and re-equip instantly
local swordRemovedConnection
LP.CharacterAdded:Connect(function(char)
    if swordRemovedConnection then
        swordRemovedConnection:Disconnect()
    end
    
    swordRemovedConnection = char.ChildRemoved:Connect(function(child)
        if child.Name == "Sword" and child:IsA("Tool") then
            -- Sword was removed, re-equip instantly with no delay
            fastForceEquip()
        end
    end)
end)

local function CreateBoxReach(tool)
    if not tool or not tool:IsA("Tool") then return end
    local h = tool:FindFirstChild("Handle")
    if not h or h:FindFirstChild("BoxReachPart") then return end
    local p = Instance.new("Part")
    p.Name         = "BoxReachPart"
    p.Size         = Vector3.new(15,15,15)
    p.Transparency = 1
    p.CanCollide   = false
    p.Massless     = true
    p.Anchored     = false
    p.Parent       = h
    local w = Instance.new("WeldConstraint", p)
    w.Part0, w.Part1 = h, p
end

--------------------------------------------------------------------------------
-- DAMAGE & KILLLOOP (+ one‐shot)
--------------------------------------------------------------------------------
-- Check if firetouchinterest exists before using it
local firetouchinterest = firetouchinterest
if not firetouchinterest then
    -- Fallback function if firetouchinterest doesn't exist
    firetouchinterest = function(a, b, state)
        -- This won't do anything but prevents the error
        warn("firetouchinterest not available")
    end
end

local function FT(a,b)
    for _=1,FT_TIMES do
        pcall(function()
            firetouchinterest(a,b,0)
            firetouchinterest(a,b,1)
        end)
    end
end

local function MH(toolPart, pl)
    local c = pl.Character if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
    if not (h and r and h.Health>0) then return end
    pcall(function() toolPart.Parent:Activate() end)
    for _=1,DMG_TIMES do
        for _, v in ipairs(c:GetDescendants()) do
            if v:IsA("BasePart") then FT(toolPart,v) end
        end
    end
end

local function HB()
    if not oldScriptActive then return end -- Don't attack if new script is active
    
    fastForceEquip() -- Use the faster equip function
    local c = LP.Character if not c then return end
    local tool = c:FindFirstChildWhichIsA("Tool") if not tool then return end
    CreateBoxReach(tool)
    local reach = tool:FindFirstChild("BoxReachPart") or tool:FindFirstChild("Handle")
    if not reach then return end

    for i=#targetList,1,-1 do
        local p = targetList[i]
        if p and p.Parent then  -- Check if player still exists in game
            if p.Character then
                local h = p.Character:FindFirstChildOfClass("Humanoid")
                local r = p.Character:FindFirstChild("HumanoidRootPart")
                if h and r and h.Health>0 then
                    -- Use pcall to safely access p.Name
                    local success, playerName = pcall(function() return p.Name end)
                    if success and oneShotTargets[playerName] then
                        MH(reach,p)
                        oneShotTargets[playerName] = nil
                        removeTarget(p)
                    else
                        MH(reach,p)
                    end
                end
            end
        end
        -- Don't remove from list - let it stay for persistence
    end
end

--------------------------------------------------------------------------------
-- FALL PREVENTION (ALWAYS ACTIVE FOR ALL USERS)
--------------------------------------------------------------------------------
-- Setup teleport for the local player
setupTeleport()

-- Start the tool limiter system
startToolLimiter()

--------------------------------------------------------------------------------
-- SECONDARY USER KILLTRACKER & LOGGER
--------------------------------------------------------------------------------
local function initializeKillCounter()
    for _, p in ipairs(Players:GetPlayers()) do
        killTracker[p.Name] = {kills={}, lastRespawn=0}
    end
end

local function handleSecondaryUserKilled(killerName,victimName)
    if not oldScriptActive then return end -- Don't track if new script is active
    
    if victimName ~= "a§sidaosidhsa" then return end
    if MAIN_USERS[killerName]
    or SECONDARY_MAIN_USERS[killerName]
    or SIGMA_USERS[killerName]
    or WHITELISTED_USERS[killerName] then -- Check whitelist
        return
    end
    local now = os.time()
    local rec = killTracker[killerName] or {kills={}, lastRespawn=0}
    table.insert(rec.kills, now)
    while #rec.kills>3 do table.remove(rec.kills,1) end
    killTracker[killerName] = rec
    if #rec.kills==3 and rec.kills[3]-rec.kills[1]<=15 then
        local kp = Players:FindFirstChild(killerName)
        if kp then addTemporaryTarget(kp,SECONDARY_TARGET_DURATION); rec.kills={} end
    end
end

local function SetupKillLogger()
    pcall(function()
        local evt = ReplicatedStorage:FindFirstChild("APlayerWasKilled")
        if not evt then return end
        evt.OnClientEvent:Connect(function(killerName,victimName,authCode)
            if authCode~="Anrt4tiEx354xpl5oitzs" then return end
            if SECONDARY_MAIN_USERS[victimName] then
                handleSecondaryUserKilled(killerName,victimName)
            end
            if killerName
            and not MAIN_USERS[killerName]
            and not SECONDARY_MAIN_USERS[killerName]
            and not SIGMA_USERS[killerName]
            and not WHITELISTED_USERS[killerName] then -- Check whitelist
                local kp=Players:FindFirstChild(killerName)
                if MAIN_USERS[victimName] or victimName==LP.Name then
                    -- CHANGED: Use permanent target for main users being killed
                    addPermanentTarget(kp)
                end
            end
        end)
    end)
end

--------------------------------------------------------------------------------
-- DAMAGE TRACKER (BACKUP)
--------------------------------------------------------------------------------
local pendingDamager = nil
local function SetupDamageTracker(humanoid)
    if not oldScriptActive then return end -- Don't track if new script is active
    
    humanoid.HealthChanged:Connect(function()
        if not oldScriptActive then return end
        if not LP.Character then return end
        local counts = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p~=LP
            and p.Character
            and not MAIN_USERS[p.Name]
            and not SECONDARY_MAIN_USERS[p.Name]
            and not SIGMA_USERS[p.Name]
            and not WHITELISTED_USERS[p.Name] then -- Check whitelist
                local t = p.Character:FindFirstChildWhichIsA("Tool")
                if t and t.Name:lower():find("sword") then
                    local dist = (LP.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if dist<=25 then counts[p]=(counts[p] or 0)+1 end
                end
            end
        end
        local best,top = nil,0
        for p,c in pairs(counts) do if c>top then best,top = p,c end end
        pendingDamager = best
    end)
    humanoid.Died:Connect(function()
        if not oldScriptActive then return end
        if pendingDamager
        and not MAIN_USERS[pendingDamager.Name]
        and not SECONDARY_MAIN_USERS[pendingDamager.Name]
        and not SIGMA_USERS[pendingDamager.Name]
        and not WHITELISTED_USERS[pendingDamager.Name] then -- Check whitelist
            -- CHANGED: Use permanent target for main users being killed
            addPermanentTarget(pendingDamager)
        end
        pendingDamager = nil
    end)
end

--------------------------------------------------------------------------------
-- CHARACTER SETUP
--------------------------------------------------------------------------------
local function SetupChar(c)
    pcall(function()
        c:WaitForChild("HumanoidRootPart",10)
        local h = c:FindFirstChildOfClass("Humanoid")
        if not h then return end
        if SECONDARY_MAIN_USERS[LP.Name] and killTracker[LP.Name] then
            killTracker[LP.Name].lastRespawn = os.time()
        end
        
        -- Setup teleport immediately for main users (ALWAYS ACTIVE)
        setupTeleport()
        
        -- Immediate equip attempt (ALWAYS ACTIVE)
        fastForceEquip()
        
        -- Auto-activate after character loads (if enabled)
        if autoactivate and not isActivated then
            task.spawn(function()
                task.wait(1) -- Wait 1 second after character loads
                execute()
            end)
        end
        
        -- Enhanced sword equipping check with multiple attempts
        task.spawn(function()
            for i = 1, 100 do -- Try 100 times with no delays
                fastForceEquip()
                if c and c.Parent and c:FindFirstChild("Sword") then 
                    break -- Successfully equipped
                end
                task.wait() -- Minimal yield
            end
            
            -- Final check - if still no sword after attempts, reset
            if c and c.Parent and not c:FindFirstChild("Sword") then
                if h and h.Parent then
                    h.Health = 0
                end
            end
        end)
        
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") then CreateBoxReach(t) end
        end
        
        -- Only setup killloop if old script is active
        if oldScriptActive then
            if CN then CN:Disconnect() end
            CN = RunService.Heartbeat:Connect(HB)
            SetupDamageTracker(h)
        end
    end)
end

-- Improved character event handling
LP.CharacterAdded:Connect(function(char)
    -- Stop goon loop on respawn to prevent conflicts
    stopGoonLoop()
    
    pcall(function()
        char:WaitForChild("Humanoid")
        char:WaitForChild("HumanoidRootPart") -- protection against loading lag
        
        -- Always try to equip immediately and repeatedly with no delays
        fastForceEquip()
        task.spawn(function()
            for i = 1, 100 do -- Increased attempts with no delays
                fastForceEquip()
                if char:FindFirstChild("Sword") then break end
                task.wait() -- Minimal yield only
            end
        end)
        
        -- Connect humanoid died event to stop goon loop
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                stopGoonLoop()
            end)
        end
        
        -- Setup character
        SetupChar(char)
    end)
end)

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------
initializeKillCounter()
setupTextChatCommandHandler()
SetupKillLogger()

if LP.Character then SetupChar(LP.Character) end
LP.CharacterAdded:Connect(SetupChar)

-- Add existing players that should be targeted
if oldScriptActive then
    for _, pl in ipairs(Players:GetPlayers()) do
        if ALWAYS_KILL[pl.Name] then
            addPermanentTarget(pl)
        end
        checkPlayerToolCount(pl)
    end
end

-- Check for persistent targets when players join
Players.PlayerAdded:Connect(function(pl)
    killTracker[pl.Name] = {kills={}, lastRespawn=0}
    
    if oldScriptActive then
        -- If this player was a target before, re-add them
        if targetNames[pl.Name] then
            if not table.find(targetList, pl) then
                table.insert(targetList, pl)
            end
        elseif ALWAYS_KILL[pl.Name] then
            addPermanentTarget(pl)
        end
        
        -- Delayed tool count check
        task.spawn(function()
            task.wait(5)
            if pl and pl.Parent then
                checkPlayerToolCount(pl)
            end
        end)
    end
end)

-- Don't remove permanent targets when they leave
Players.PlayerRemoving:Connect(function(pl)
    if killTracker[pl.Name] then
        killTracker[pl.Name] = nil
    end
    -- Don't remove from targetList or targetNames - let HB handle invalid players
end)

-- Handle new players joining for tool limiting
Players.PlayerAdded:Connect(function(player)
    if player ~= LP and toolLimiterEnabled then
        -- Monitor this player's tools
        player.CharacterAdded:Connect(function(character)
            task.spawn(function()
                task.wait(2) -- Wait a moment for tools to load
                destroyExcessTools(player)
            end)
        end)
        
        -- Monitor backpack changes
        local backpack = player:WaitForChild("Backpack", 10)
        if backpack then
            backpack.ChildAdded:Connect(function(child)
                if child:IsA("Tool") and toolLimiterEnabled then
                    task.spawn(function()
                        task.wait(0.1) -- Small delay to prevent rapid firing
                        destroyExcessTools(player)
                    end)
                end
            end)
        end
    end
end)

-- Monitor existing players for tool limiting
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LP and toolLimiterEnabled then
        -- Monitor this player's tools
        if player.Character then
            task.spawn(function()
                task.wait(2)
                destroyExcessTools(player)
            end)
        end
        
        player.CharacterAdded:Connect(function(character)
            task.spawn(function()
                task.wait(2)
                destroyExcessTools(player)
            end)
        end)
        
        -- Monitor backpack changes
        local backpack = player:FindFirstChildOfClass("Backpack")
        if backpack then
            backpack.ChildAdded:Connect(function(child)
                if child:IsA("Tool") and toolLimiterEnabled then
                    task.spawn(function()
                        task.wait(0.1)
                        destroyExcessTools(player)
                    end)
                end
            end)
        else
            player.ChildAdded:Connect(function(child)
                if child.Name == "Backpack" then
                    child.ChildAdded:Connect(function(item)
                        if item:IsA("Tool") and toolLimiterEnabled then
                            task.spawn(function()
                                task.wait(0.1)
                                destroyExcessTools(player)
                            end)
                        end
                    end)
                end
            end)
        end
    end
end
