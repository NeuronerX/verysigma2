local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load external command script
pcall(function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/command.lua'))()
end)

local LP = Players.LocalPlayer
local PlaceId = game.PlaceId

-- CENTRALIZED TELEPORT TARGETS
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

-- CONFIGURATION
local autoactivate = false
local serverHopEnabled = true
local minPlayersRequired = 4
local hopAttemptInterval = 3 -- Reduced from 5 to 3 seconds
local isActivated = false
local oldScriptActive = true
local externalScriptLoaded = false

-- STATE VARIABLES
local spamConnection = nil
local spamAutoequipEnabled = false
local goonConnection = nil
local goonAnimTrack = nil
local isGooning = false
local goonAnimObject = nil
local autoequipEnabled = false
local autoequipConnections = {}
local activateAutoequipEnabled = false
local teleportConnection = nil

-- TOOL LIMITER (ALWAYS ENABLED - REMOVED COMMANDS)
local maxToolsPerPlayer = 1
local toolLimiterConnection = nil

-- TARGET MANAGEMENT
local targetList = {}
local targetNames = {}
local temporaryTargets = {}
local killTracker = {}
local DMG_TIMES = 3 -- Increased from 2 to 3
local FT_TIMES = 7 -- Increased from 5 to 7
local CN = nil
local TEMP_TARGET_DURATION = 99999999999
local SECONDARY_TARGET_DURATION = 120
local CMD_PREFIX = "."
local TOOL_COUNT_THRESHOLD = 200 -- Reduced from 250 to 200
local lastServerCheck = 0
local isHopping = false

-- USER TABLES
local MAIN_USERS = {
    ["cubot_autoIoop"] = true,
    ["Cubot_Nova2"] = true,
    ["Cubot_Nova3"] = true,
    ["cubot_nova4"] = true,
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
    ["lurty15109"] = true,
    ["honzikje85"] = true,
    ["GoatReflex"] = true,
    ["MISAKMALEJ"] = true,
    ["BmwFounder"] = true,
    ["mmmnmmmmnmmmnmmmmmmn"] = true,
    ["BuilderShadowStudio"] = true,
    ["GUMIDKOVA2010"] = true,
    ["FlexFightSecurity015"] = true,
    ["nechmelol2"] = true,
    ["Latticeon"] = true,
    ["playleeer014"] = true,
    ["cokoladova_zmrzlinkq"] = true,
    ["anticurak"] = true,
    ["SpicyDealldo"] = true,
}

local WHITELISTED_USERS = {
    ["e5c4qe"] = true,
    ["xL1fe_r"] = true,
    ["xL1v3_r"] = true,
    ["xLiv3_r"] = true,
}

-- SHARED REVENGE OBJECT
local sharedRevenge = workspace:FindFirstChild("SharedRevenge")
if not sharedRevenge then
    sharedRevenge = Instance.new("StringValue")
    sharedRevenge.Name = "SharedRevenge"
    sharedRevenge.Parent = workspace
end

-- QUEUE ON TELEPORT SETUP
local KeepInfYield = true
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

-- Initialize targetNames with ALWAYS_KILL users
for name, _ in pairs(ALWAYS_KILL) do
    targetNames[name] = true
end

-- OPTIMIZED TOOL LIMITER FUNCTIONS
local function countPlayerTools(player)
    if not player or player == LP then return 0 end
    
    local toolCount = 0
    local backpack = player:FindFirstChildOfClass("Backpack")
    local character = player.Character
    
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                toolCount = toolCount + 1
            end
        end
    end
    
    if character then
        for _, item in pairs(character:GetChildren()) do
            if item:IsA("Tool") then
                toolCount = toolCount + 1
            end
        end
    end
    
    return toolCount
end

local function destroyExcessTools(player)
    if not player or player == LP then return end
    
    local toolsDestroyed = 0
    local toolsFound = {}
    local backpack = player:FindFirstChildOfClass("Backpack")
    local character = player.Character
    
    -- Collect all tools more efficiently
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(toolsFound, item)
            end
        end
    end
    
    if character then
        for _, item in pairs(character:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(toolsFound, item)
            end
        end
    end
    
    -- Destroy excess tools
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
    if toolLimiterConnection then return end
    
    toolLimiterConnection = RunService.Heartbeat:Connect(function()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP then
                local toolCount = countPlayerTools(player)
                if toolCount > maxToolsPerPlayer then
                    destroyExcessTools(player)
                end
            end
        end
    end)
end

-- OPTIMIZED TELEPORT FUNCTIONS
local function setupTeleport()
    if teleportConnection then 
        teleportConnection:Disconnect() 
        teleportConnection = nil
    end
    
    local cf = teleportTargets[LP.Name]
    if cf then
        teleportConnection = RunService.Heartbeat:Connect(function()
            local character = LP.Character
            if character then
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    rootPart.CFrame = cf
                    rootPart.AssemblyLinearVelocity = Vector3.zero
                end
            end
        end)
    end
end

-- ENHANCED ANTI-AFK
local function setupAntiAFK()
    local GC = getconnections or get_signal_cons
    if GC then
        local success, connections = pcall(function()
            return GC(LP.Idled)
        end)
        if success and connections then
            for _, conn in pairs(connections) do
                pcall(function()
                    if conn.Disable then 
                        conn:Disable()
                    elseif conn.Disconnect then 
                        conn:Disconnect()
                    end
                end)
            end
        end
    else
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
end

-- UI HIDING
local function hideUI()
    task.spawn(function()
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
end

-- OPTIMIZED TARGET MANAGEMENT
local function hasValidTargets()
    for name, _ in pairs(targetNames) do
        if Players:FindFirstChild(name) then
            return true
        end
    end
    
    for name, _ in pairs(temporaryTargets) do
        if Players:FindFirstChild(name) then
            return true
        end
    end
    
    return false
end

local function shouldAutoequipBeEnabled()
    return hasValidTargets() or activateAutoequipEnabled or spamAutoequipEnabled
end

local function unequipAllTools()
    local character = LP.Character
    if not character then return end
    
    for _, tool in pairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Parent = LP.Backpack
        end
    end
end

-- ENHANCED AUTOEQUIP SYSTEM
local function fastForceEquip()
    if not autoequipEnabled then return end
    
    local character = LP.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end
    
    -- Check if we already have a sword equipped
    if character:FindFirstChild("Sword") then return end
    
    -- Try to find and equip sword from backpack
    local sword = LP.Backpack:FindFirstChild("Sword")
    if sword then
        pcall(function()
            humanoid:EquipTool(sword)
        end)
        return
    end
    
    -- Equip any available tool (except specific ones)
    for _, tool in pairs(LP.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name ~= "Punch" and tool.Name ~= "Ground Slam" and tool.Name ~= "Stomp" then
            pcall(function()
                humanoid:EquipTool(tool)
            end)
            break
        end
    end
end

local function startAutoequip()
    if autoequipEnabled then return end
    
    autoequipEnabled = true
    
    -- Clear existing connections
    for _, conn in pairs(autoequipConnections) do
        if conn then conn:Disconnect() end
    end
    autoequipConnections = {}
    
    -- Enhanced autoequip connections for faster response
    autoequipConnections[1] = RunService.Heartbeat:Connect(fastForceEquip)
    autoequipConnections[2] = RunService.Stepped:Connect(fastForceEquip)
    autoequipConnections[3] = RunService.RenderStepped:Connect(fastForceEquip)
    
    -- Monitor backpack changes
    autoequipConnections[4] = LP.ChildAdded:Connect(function(child)
        if child.Name == "Backpack" then
            autoequipConnections[5] = child.ChildAdded:Connect(function(tool)
                if tool:IsA("Tool") and tool.Name == "Sword" and autoequipEnabled then
                    fastForceEquip()
                end
            end)
        end
    end)
    
    -- Monitor character changes
    if LP.Character then
        autoequipConnections[6] = LP.Character.ChildRemoved:Connect(function(child)
            if child.Name == "Sword" and child:IsA("Tool") and autoequipEnabled then
                fastForceEquip()
            end
        end)
    end
end

local function stopAutoequip()
    if not autoequipEnabled then return end
    
    autoequipEnabled = false
    
    for _, conn in pairs(autoequipConnections) do
        if conn then conn:Disconnect() end
    end
    autoequipConnections = {}
    
    unequipAllTools()
end

local function updateAutoequipState()
    local shouldAutoequip = shouldAutoequipBeEnabled()
    
    if shouldAutoequip and not autoequipEnabled then
        startAutoequip()
    elseif not shouldAutoequip and autoequipEnabled then
        stopAutoequip()
    end
end

-- ENHANCED SPAM LOOP
local function startSpamLoop()
    if spamConnection then return end
    
    spamAutoequipEnabled = true
    updateAutoequipState()
    
    spamConnection = RunService.Stepped:Connect(function()
        -- Destroy unwanted tools and equip others
        for _, tool in pairs(LP.Backpack:GetChildren()) do
            if tool.Name == "Punch" or tool.Name == "Ground Slam" or tool.Name == "Stomp" then
                tool:Destroy()
            elseif tool:IsA("Tool") and autoequipEnabled then
                tool.Parent = LP.Character
            end
        end
        
        -- Activate equipped tool
        local character = LP.Character
        if character then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
            end
        end
    end)
end

local function stopSpamLoop()
    if spamConnection then
        spamConnection:Disconnect()
        spamConnection = nil
    end
    
    spamAutoequipEnabled = false
    updateAutoequipState()
end

-- ENHANCED GOON LOOP
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
    if isGooning then return end
    
    isGooning = true
    
    goonConnection = RunService.Heartbeat:Connect(function()
        if not isGooning then return end
        
        local character = LP.Character
        if not character then return end
        
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        if not humanoid then return end
        
        pcall(function()
            if goonAnimTrack then
                if goonAnimTrack.IsPlaying and goonAnimTrack.TimePosition >= (isR15(LP) and 0.7 or 0.65) then
                    goonAnimTrack:Stop()
                    goonAnimTrack = nil
                elseif not goonAnimTrack.IsPlaying then
                    goonAnimTrack = nil
                end
            end
            
            if not goonAnimTrack then
                local animObject = createGoonAnimation()
                if animObject then
                    goonAnimTrack = humanoid:LoadAnimation(animObject)
                    if goonAnimTrack then
                        goonAnimTrack.Priority = Enum.AnimationPriority.Action
                        goonAnimTrack:Play()
                        goonAnimTrack:AdjustSpeed(isR15(LP) and 0.7 or 0.65)
                        goonAnimTrack.TimePosition = 0.6
                    end
                end
            end
        end)
    end)
end

local function stopGoonLoop()
    if not isGooning then return end
    
    isGooning = false
    
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
    
    if goonAnimObject then
        goonAnimObject:Destroy()
        goonAnimObject = nil
    end
end

-- ENHANCED EXECUTE FUNCTION
local function execute()
    if isActivated then return end
    
    isActivated = true
    activateAutoequipEnabled = true
    updateAutoequipState()
    
    if not externalScriptLoaded then
        local success, err = pcall(function()
            local scriptContent = game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/aci.lua')
            loadstring(scriptContent)()
        end)
        
        if success then
            externalScriptLoaded = true
        else
            warn("Failed to load aci.lua:", err)
            isActivated = false
            activateAutoequipEnabled = false
            updateAutoequipState()
        end
    end
end

-- FPS BOOST FUNCTIONS
local function equipAllTools()
    for _, tool in pairs(LP:FindFirstChildOfClass("Backpack"):GetChildren()) do
        if tool:IsA("Tool") or tool:IsA("HopperBin") then
            tool.Parent = LP.Character
        end
    end
end

local function startFPSBoost()
    local unlockedSwords = ReplicatedStorage:FindFirstChild("UnlockedSwords")
    if unlockedSwords then
        for i = 1, 500 do -- Increased from 300 to 500
            pcall(function()
                unlockedSwords:FireServer({false, false, false}, "894An3ti44Ex321P3llo99i3t")
            end)
        end
    end
    
    task.wait(5) -- Reduced from 10 to 5 seconds
    equipAllTools()
end

-- ENHANCED FPS BOOSTER
local function optimizeGraphics()
    local Terrain = workspace:FindFirstChildOfClass("Terrain")
    if Terrain then
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0
    end
    
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    settings().Rendering.QualityLevel = 1
    
    -- Enhanced graphics optimization
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.Plastic
            obj.Reflectance = 0
        elseif obj:IsA("Decal") then
            obj.Transparency = 1
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            obj.Lifetime = NumberRange.new(0)
        elseif obj:IsA("Explosion") then
            obj.BlastPressure = 1
            obj.BlastRadius = 1
        end
    end
    
    for _, effect in pairs(Lighting:GetDescendants()) do
        if effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or 
           effect:IsA("ColorCorrectionEffect") or effect:IsA("BloomEffect") or 
           effect:IsA("DepthOfFieldEffect") then
            effect.Enabled = false
        end
    end
    
    workspace.DescendantAdded:Connect(function(child)
        task.spawn(function()
            if child:IsA("ForceField") or child:IsA("Sparkles") or 
               child:IsA("Smoke") or child:IsA("Fire") then
                RunService.Heartbeat:Wait()
                child:Destroy()
            end
        end)
    end)
end

-- ENHANCED ANTI-FLING
local function setupAntiFling()
    RunService.Stepped:Connect(function()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP and player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end

-- TARGET MANAGEMENT FUNCTIONS
local function addPermanentTarget(pl)
    if not oldScriptActive or not pl or 
       MAIN_USERS[pl.Name] or SECONDARY_MAIN_USERS[pl.Name] or 
       SIGMA_USERS[pl.Name] or WHITELISTED_USERS[pl.Name] then
        return
    end
    
    targetNames[pl.Name] = true
    if not table.find(targetList, pl) then
        table.insert(targetList, pl)
    end
    
    if MAIN_USERS[LP.Name] or SIGMA_USERS[LP.Name] then
        sharedRevenge.Value = pl.Name
    end
    
    updateAutoequipState()
end

local function removeTarget(pl)
    if not oldScriptActive or not pl or ALWAYS_KILL[pl.Name] then 
        return false 
    end
    
    targetNames[pl.Name] = nil
    temporaryTargets[pl.Name] = nil
    
    for i = #targetList, 1, -1 do
        if targetList[i] == pl then
            table.remove(targetList, i)
        end
    end
    
    updateAutoequipState()
    return true
end

-- NEW FUNCTION: Remove all targets except ALWAYS_KILL
local function removeAllTargetsExceptAlwaysKill()
    if not oldScriptActive then return 0 end
    
    local removedCount = 0
    
    -- Clear targetNames except ALWAYS_KILL
    for name, _ in pairs(targetNames) do
        if not ALWAYS_KILL[name] then
            targetNames[name] = nil
            removedCount = removedCount + 1
        end
    end
    
    -- Clear all temporary targets
    for name, _ in pairs(temporaryTargets) do
        temporaryTargets[name] = nil
        removedCount = removedCount + 1
    end
    
    -- Rebuild targetList with only ALWAYS_KILL players
    targetList = {}
    for name, _ in pairs(ALWAYS_KILL) do
        local player = Players:FindFirstChild(name)
        if player then
            table.insert(targetList, player)
        end
    end
    
    updateAutoequipState()
    return removedCount
end

local function addTemporaryTarget(pl, dur)
    if not oldScriptActive or not pl or 
       MAIN_USERS[pl.Name] or SECONDARY_MAIN_USERS[pl.Name] or 
       SIGMA_USERS[pl.Name] or WHITELISTED_USERS[pl.Name] then
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
    
    updateAutoequipState()
end

-- NAME MATCHING
local function findPlayerByPartialName(partial)
    if not partial or partial == "" then return nil end
    
    partial = partial:lower()
    
    -- Exact match first
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name:lower() == partial then
            return player
        end
    end
    
    -- Prefix match
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name:lower():sub(1, #partial) == partial then
            return player
        end
    end
    
    -- Contains match
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name:lower():find(partial, 1, true) then
            return player
        end
    end
    
    return nil
end

-- ENHANCED SERVER HOPPING
local function checkAndHopServers()
    if isHopping or not serverHopEnabled then return end
    
    local currentPlayers = #Players:GetPlayers()
    if currentPlayers >= minPlayersRequired then return end
    
    isHopping = true
    
    local success, result = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true")
    end)
    
    if not success then 
        isHopping = false
        return 
    end
    
    local body = pcall(function()
        return HttpService:JSONDecode(result)
    end) and HttpService:JSONDecode(result) or nil
    
    if body and body.data then
        local servers = {}
        
        for _, server in pairs(body.data) do
            if type(server) == "table" and server.id ~= game.JobId then
                local playing = tonumber(server.playing)
                local maxPlayers = tonumber(server.maxPlayers)
                
                if playing and maxPlayers and playing < maxPlayers then
                    table.insert(servers, {id = server.id, players = playing})
                end
            end
        end
        
        table.sort(servers, function(a, b) return a.players > b.players end)
        
        if #servers > 0 then
            if KeepInfYield and queueteleport then
                pcall(function()
                    queueteleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/file.lua'))()")
                end)
            end
            
            for idx, server in pairs(servers) do
                local teleportSuccess = pcall(function()
                    TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LP)
                end)
                
                if teleportSuccess then break end
                if idx >= 3 then break end
            end
        end
    end
    
    isHopping = false
end

-- ENHANCED CHAT COMMANDS
local function processChatCommand(msg)
    if msg:sub(1, #CMD_PREFIX) ~= CMD_PREFIX then return end
    
    local parts = {}
    for word in msg:sub(#CMD_PREFIX + 1):gmatch("%S+") do
        table.insert(parts, word)
    end
    
    local cmd = parts[1] and parts[1]:lower()
    local name = parts[2] and parts[2]:lower()
    
    if cmd == "activate" then
        execute()
        return
    end
    
    if cmd == "goon" then
        startGoonLoop()
        return
    elseif cmd == "ungoon" then
        stopGoonLoop()
        return
    end
    
    if cmd == "sp" then
        startSpamLoop()
        return
    elseif cmd == "unsp" then
        stopSpamLoop()
        return
    end
    
    if cmd == "hop" then
        if name == "on" then
            serverHopEnabled = true
        elseif name == "off" then
            serverHopEnabled = false
        elseif name == "now" then
            checkAndHopServers()
        end
        return
    end
    
    if cmd == "line" then
        for targetName, pos in pairs(lineTargets) do
            teleportTargets[targetName] = pos
        end
        setupTeleport()
        return
    end
    
    if cmd == "unline" then
        for targetName, pos in pairs(originalTargets) do
            teleportTargets[targetName] = pos
        end
        setupTeleport()
        return
    end
    
    if cmd == "fpsboost" then
        startFPSBoost()
        return
    end
    
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
    
    -- Handle .unloop all command (separate from player search)
    if cmd == "unloop" and name == "all" then
        local removedCount = removeAllTargetsExceptAlwaysKill()
        print("Removed " .. removedCount .. " targets (keeping ALWAYS_KILL players)")
        return
    end
    
    -- Regular player-specific commands
    if not cmd or not name then return end
    local player = findPlayerByPartialName(parts[2]) -- Use original case for player search
    if not player then return end

    if cmd == "loop" then
        addPermanentTarget(player)
    elseif cmd == "unloop" then
        removeTarget(player)
    end
end

-- SETUP CHAT COMMAND HANDLER
local function setupTextChatCommandHandler()
    pcall(function()
        if TextChatService and TextChatService.MessageReceived then
            TextChatService.MessageReceived:Connect(function(txtMsg)
                -- Fixed line 918 - Added proper nil checks
                if txtMsg and txtMsg.TextSource and txtMsg.TextSource.UserId then
                    local sender = Players:GetPlayerByUserId(txtMsg.TextSource.UserId)
                    if sender and (MAIN_USERS[sender.Name] or SIGMA_USERS[sender.Name]) then
                        local messageText = txtMsg.Text
                        processChatCommand(messageText)
                        
                        if messageText == ".update" then
                            sharedRevenge.Value = "UPDATE"
                        end
                    end
                end
            end)
        else
            local events = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 10)
            if events then
                local msgEvent = events:FindFirstChild("OnMessageDoneFiltering")
                if msgEvent then
                    msgEvent.OnClientEvent:Connect(function(data)
                        local speaker = Players:FindFirstChild(data.FromSpeaker)
                        if speaker and (MAIN_USERS[speaker.Name] or SIGMA_USERS[speaker.Name]) then
                            local messageText = data.Message
                            processChatCommand(messageText)
                            
                            if messageText == ".update" then
                                sharedRevenge.Value = "UPDATE"
                            end
                        end
                    end)
                end
            end
        end
    end)
end

-- SHARED REVENGE LISTENER
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

    if not oldScriptActive then return end

    if val:sub(1, 9) == "TEMP_EXT:" then
        local name = val:sub(10)
        local player = Players:FindFirstChild(name)
        if player then addTemporaryTarget(player, SECONDARY_TARGET_DURATION) end
    elseif val:sub(1, 5) == "TEMP:" then
        local name = val:sub(6)
        local player = Players:FindFirstChild(name)
        if player then addTemporaryTarget(player) end
    else
        local player = Players:FindFirstChild(val)
        if player then addPermanentTarget(player) end
    end
end)

-- CLEANUP TEMP TARGETS
task.spawn(function()
    while true do
        if oldScriptActive then
            local now = os.time()
            local targetsRemoved = false
            
            for name, expiration in pairs(temporaryTargets) do
                if expiration <= now then
                    temporaryTargets[name] = nil
                    
                    if not targetNames[name] then
                        local player = Players:FindFirstChild(name)
                        if player then 
                            for i = #targetList, 1, -1 do
                                if targetList[i] == player then
                                    table.remove(targetList, i)
                                    targetsRemoved = true
                                end
                            end
                        end
                    end
                end
            end
            
            if targetsRemoved then
                updateAutoequipState()
            end
        end
        task.wait(1)
    end
end)

-- ENHANCED TOOL COUNT DETECTION
local function checkPlayerToolCount(player)
    if not oldScriptActive or not player or
       MAIN_USERS[player.Name] or SECONDARY_MAIN_USERS[player.Name] or 
       SIGMA_USERS[player.Name] or WHITELISTED_USERS[player.Name] or 
       targetNames[player.Name] or ALWAYS_KILL[player.Name] then
        return
    end
    
    local count = 0
    local backpack = player:FindFirstChildOfClass("Backpack")
    local character = player.Character
    
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                count = count + 1
            end
        end
    end
    
    if character then
        for _, item in pairs(character:GetChildren()) do
            if item:IsA("Tool") then
                count = count + 1
            end
        end
    end
    
    if count >= TOOL_COUNT_THRESHOLD then
        addPermanentTarget(player)
    end
end

-- BOX REACH CREATION
local function CreateBoxReach(tool)
    if not tool or not tool:IsA("Tool") then return end
    
    local handle = tool:FindFirstChild("Handle")
    if not handle or handle:FindFirstChild("BoxReachPart") then return end
    
    local part = Instance.new("Part")
    part.Name = "BoxReachPart"
    part.Size = Vector3.new(20, 20, 20) -- Increased from 15 to 20
    part.Transparency = 1
    part.CanCollide = false
    part.Massless = true
    part.Anchored = false
    part.Parent = handle
    
    local weld = Instance.new("WeldConstraint", part)
    weld.Part0, weld.Part1 = handle, part
end

-- ENHANCED DAMAGE SYSTEM
local firetouchinterest = firetouchinterest or function(a, b, state)
    -- Fallback if not available
end

local function FT(part1, part2)
    for i = 1, FT_TIMES do
        pcall(function()
            firetouchinterest(part1, part2, 0)
            firetouchinterest(part1, part2, 1)
        end)
    end
end

local function MH(toolPart, player)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not (humanoid and rootPart and humanoid.Health > 0) then return end
    
    pcall(function() 
        toolPart.Parent:Activate() 
    end)
    
    for i = 1, DMG_TIMES do
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                FT(toolPart, part)
            end
        end
    end
end

-- ENHANCED HEARTBEAT FUNCTION
local function HB()
    if not oldScriptActive then return end
    
    if autoequipEnabled then
        fastForceEquip()
    end
    
    local character = LP.Character
    if not character then return end
    
    local tool = character:FindFirstChildWhichIsA("Tool")
    if not tool then return end
    
    CreateBoxReach(tool)
    local reach = tool:FindFirstChild("BoxReachPart") or tool:FindFirstChild("Handle")
    if not reach then return end

    for _, player in pairs(targetList) do
        if player and player.Parent and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            
            if humanoid and rootPart and humanoid.Health > 0 then
                MH(reach, player)
            end
        end
    end
end

-- KILL TRACKER INITIALIZATION
local function initializeKillCounter()
    for _, player in pairs(Players:GetPlayers()) do
        killTracker[player.Name] = {kills = {}, lastRespawn = 0}
    end
end

-- SECONDARY USER KILL HANDLING
local function handleSecondaryUserKilled(killerName, victimName)
    if not oldScriptActive or victimName ~= "a§sidaosidhsa" then return end
    
    if MAIN_USERS[killerName] or SECONDARY_MAIN_USERS[killerName] or 
       SIGMA_USERS[killerName] or WHITELISTED_USERS[killerName] then
        return
    end
    
    local now = os.time()
    local record = killTracker[killerName] or {kills = {}, lastRespawn = 0}
    table.insert(record.kills, now)
    
    while #record.kills > 3 do 
        table.remove(record.kills, 1) 
    end
    
    killTracker[killerName] = record
    
    if #record.kills == 3 and record.kills[3] - record.kills[1] <= 15 then
        local killer = Players:FindFirstChild(killerName)
        if killer then 
            addTemporaryTarget(killer, SECONDARY_TARGET_DURATION)
            record.kills = {}
        end
    end
end

-- KILL LOGGER SETUP
local function SetupKillLogger()
    pcall(function()
        local event = ReplicatedStorage:FindFirstChild("APlayerWasKilled")
        if not event then return end
        
        event.OnClientEvent:Connect(function(killerName, victimName, authCode)
            if authCode ~= "Anrt4tiEx354xpl5oitzs" then return end
            
            if SECONDARY_MAIN_USERS[victimName] then
                handleSecondaryUserKilled(killerName, victimName)
            end
            
            if killerName and not MAIN_USERS[killerName] and 
               not SECONDARY_MAIN_USERS[killerName] and not SIGMA_USERS[killerName] and 
               not WHITELISTED_USERS[killerName] then
                
                local killer = Players:FindFirstChild(killerName)
                if MAIN_USERS[victimName] or victimName == LP.Name then
                    addPermanentTarget(killer)
                end
            end
        end)
    end)
end

-- DAMAGE TRACKER (BACKUP)
local pendingDamager = nil

local function SetupDamageTracker(humanoid)
    if not oldScriptActive then return end
    
    humanoid.HealthChanged:Connect(function()
        if not oldScriptActive or not LP.Character then return end
        
        local counts = {}
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP and player.Character and
               not MAIN_USERS[player.Name] and not SECONDARY_MAIN_USERS[player.Name] and
               not SIGMA_USERS[player.Name] and not WHITELISTED_USERS[player.Name] then
                
                local tool = player.Character:FindFirstChildWhichIsA("Tool")
                if tool and tool.Name:lower():find("sword") then
                    local distance = (LP.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    if distance <= 30 then -- Increased from 25 to 30
                        counts[player] = (counts[player] or 0) + 1
                    end
                end
            end
        end
        
        local bestPlayer, topCount = nil, 0
        for player, count in pairs(counts) do
            if count > topCount then
                bestPlayer, topCount = player, count
            end
        end
        
        pendingDamager = bestPlayer
    end)
    
    humanoid.Died:Connect(function()
        if not oldScriptActive then return end
        
        if pendingDamager and not MAIN_USERS[pendingDamager.Name] and
           not SECONDARY_MAIN_USERS[pendingDamager.Name] and not SIGMA_USERS[pendingDamager.Name] and
           not WHITELISTED_USERS[pendingDamager.Name] then
            addPermanentTarget(pendingDamager)
        end
        
        pendingDamager = nil
    end)
end

-- ENHANCED CHARACTER SETUP
local function SetupChar(character)
    pcall(function()
        character:WaitForChild("HumanoidRootPart", 10)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        if SECONDARY_MAIN_USERS[LP.Name] and killTracker[LP.Name] then
            killTracker[LP.Name].lastRespawn = os.time()
        end
        
        setupTeleport()
        updateAutoequipState()
        
        if autoactivate and not isActivated then
            task.spawn(function()
                execute() -- Removed delay for faster activation
            end)
        end
        
        autoequipConnections[6] = character.ChildRemoved:Connect(function(child)
            if child.Name == "Sword" and child:IsA("Tool") and autoequipEnabled then
                fastForceEquip()
            end
        end)
        
        for _, tool in pairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                CreateBoxReach(tool)
            end
        end
        
        if oldScriptActive then
            if CN then CN:Disconnect() end
            CN = RunService.Heartbeat:Connect(HB)
            SetupDamageTracker(humanoid)
        end
    end)
end

-- CHARACTER EVENT HANDLING
LP.CharacterAdded:Connect(function(character)
    stopGoonLoop()
    
    pcall(function()
        character:WaitForChild("Humanoid")
        character:WaitForChild("HumanoidRootPart")
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                stopGoonLoop()
            end)
        end
        
        SetupChar(character)
    end)
end)

-- SERVER HOP MONITORING
task.spawn(function()
    task.wait(5) -- Reduced from 10 to 5 seconds
    
    while true do
        if serverHopEnabled then
            local currentPlayers = #Players:GetPlayers()
            
            if currentPlayers < minPlayersRequired then
                checkAndHopServers()
                task.wait(hopAttemptInterval)
            else
                task.wait(20) -- Reduced from 30 to 20 seconds
            end
        else
            task.wait(20)
        end
    end
end)

-- TOOL COUNT MONITORING
task.spawn(function()
    while true do
        if oldScriptActive then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LP then
                    checkPlayerToolCount(player)
                end
            end
        end
        task.wait(3) -- Reduced from 5 to 3 seconds
    end
end)

-- AUTOEQUIP STATE MONITORING
task.spawn(function()
    while true do
        if oldScriptActive then
            updateAutoequipState()
        end
        task.wait(0.1) -- Very frequent updates for responsiveness
    end
end)

-- PLAYER EVENT HANDLERS
Players.PlayerAdded:Connect(function(player)
    killTracker[player.Name] = {kills = {}, lastRespawn = 0}
    
    if oldScriptActive then
        if targetNames[player.Name] or temporaryTargets[player.Name] then
            if not table.find(targetList, player) then
                table.insert(targetList, player)
            end
            updateAutoequipState()
        elseif ALWAYS_KILL[player.Name] then
            addPermanentTarget(player)
        end
        
        task.spawn(function()
            task.wait(3) -- Reduced from 5 to 3 seconds
            if player and player.Parent then
                checkPlayerToolCount(player)
            end
        end)
    end
    
    -- Enhanced tool limiter for new players
    if player ~= LP then
        player.CharacterAdded:Connect(function(character)
            task.spawn(function()
                task.wait(1) -- Reduced delay
                destroyExcessTools(player)
            end)
        end)
        
        local backpack = player:WaitForChild("Backpack", 10)
        if backpack then
            backpack.ChildAdded:Connect(function(child)
                if child:IsA("Tool") then
                    task.spawn(function()
                        destroyExcessTools(player)
                    end)
                end
            end)
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    killTracker[player.Name] = nil
    
    for i = #targetList, 1, -1 do
        if targetList[i] == player then
            table.remove(targetList, i)
        end
    end
    
    updateAutoequipState()
end)

-- PLACE ID CHECK
if game.PlaceId ~= 6110766473 then return end

-- INITIALIZATION
setupAntiAFK()
hideUI()
optimizeGraphics()
setupAntiFling()
startToolLimiter()
initializeKillCounter()
setupTextChatCommandHandler()
SetupKillLogger()

-- Setup character if already exists
if LP.Character then 
    SetupChar(LP.Character) 
end

-- Add existing ALWAYS_KILL targets
if oldScriptActive then
    for _, player in pairs(Players:GetPlayers()) do
        if ALWAYS_KILL[player.Name] then
            addPermanentTarget(player)
        end
        checkPlayerToolCount(player)
    end
end

-- Initialize autoequip state
updateAutoequipState()

print("Enhanced script loaded - optimized and faster with .unloop all command")
