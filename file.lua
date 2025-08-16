local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ENHANCED SCRIPT DUPLICATION PREVENTION
local LP = Players.LocalPlayer
local scriptIdentifier = "EnhancedScriptV3_" .. LP.Name .. "_" .. game.JobId

-- Kill ALL existing instances more aggressively
for key, value in pairs(_G) do
    if type(key) == "string" and (key:find("EnhancedScript") or key:find("ScriptController") or key:find("DiscordLogger")) then
        if type(value) == "table" and value.Destroy then
            pcall(function()
                value:Destroy()
            end)
        end
        _G[key] = nil
    end
end

-- More aggressive cleanup
if _G.EnhancedScriptConnections then
    for _, conn in pairs(_G.EnhancedScriptConnections) do
        pcall(function()
            if conn.Disconnect then conn:Disconnect() end
            if conn.Connected == false then return end
            task.cancel(conn)
        end)
    end
    _G.EnhancedScriptConnections = nil
end

-- Wait for cleanup
task.wait(1)

-- Check if already running with more strict checking
if _G[scriptIdentifier] or _G["SCRIPT_RUNNING_" .. LP.Name] then
    warn("Script already running for this user in this server! Terminating.")
    return
end

-- Set running flag
_G["SCRIPT_RUNNING_" .. LP.Name] = true

-- Load external command script ONCE
local externalScriptLoaded = false
pcall(function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/command.lua'))()
    externalScriptLoaded = true
end)

local PlaceId = game.PlaceId

-- ENHANCED SCRIPT CONTROLLER
local ScriptController = {}
ScriptController.__index = ScriptController

function ScriptController:Destroy()
    self.active = false
    print("Destroying script instance for " .. LP.Name)
    
    -- Cleanup all connections
    for i, connection in ipairs(self.connections) do
        if connection then
            pcall(function()
                -- Handle RBXScriptConnection objects
                if type(connection) == "userdata" and connection.Connected then
                    connection:Disconnect()
                -- Handle task.spawn coroutines
                elseif type(connection) == "thread" then
                    task.cancel(connection)
                -- Handle any other cleanup function
                elseif type(connection) == "function" then
                    connection()
                end
            end)
        end
    end
    
    self.connections = {}
    _G[scriptIdentifier] = nil
    _G["SCRIPT_RUNNING_" .. LP.Name] = nil
    print("Script cleanup completed for " .. LP.Name)
end

function ScriptController.new()
    local self = setmetatable({}, ScriptController)
    self.active = true
    self.connections = {}
    return self
end

-- Create singleton instance
_G[scriptIdentifier] = ScriptController.new()
print("Script initialized for " .. LP.Name .. " in JobId: " .. game.JobId)

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

-- Line formation positions (standing normally on ground, facing backward - 180 degrees turned)
local lineTargets = {
    ["Cubot_Nova3"]     = CFrame.new(-15, 124, -70, -1, 0, 0, 0, 1, 0, 0, 0, -1),
    ["Cub0t_01"]        = CFrame.new(3, 124, -70, -1, 0, 0, 0, 1, 0, 0, 0, -1),
    ["cubot_nova4"]     = CFrame.new(21, 124, -70, -1, 0, 0, 0, 1, 0, 0, 0, -1),
    ["cubot_autoIoop"]  = CFrame.new(-7, 124, -70, -1, 0, 0, 0, 1, 0, 0, 0, -1),
    ["Cubot_Nova2"]     = CFrame.new(-3, 124, -70, -1, 0, 0, 0, 1, 0, 0, 0, -1),
    ["Cubot_Nova1"]     = CFrame.new(4, 124, -70, -1, 0, 0, 0, 1, 0, 0, 0, -1),
}

-- USER NUMBER MAPPING FOR SERVERHOP
local userNumbers = {
    ["Cubot_Nova3"] = 1,
    ["Cub0t_01"] = 2,
    ["cubot_nova4"] = 3,
    ["cubot_autoIoop"] = 4,
    ["Cubot_Nova2"] = 5,
    ["Cubot_Nova1"] = 6,
}

-- CONFIGURATION
local autoactivate = false
local serverHopEnabled = true
local minPlayersRequired = 4
local hopAttemptInterval = 3
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
local activateAutoequipEnabled = false
local teleportConnection = nil

-- TOOL LIMITER (ALWAYS ENABLED - REMOVED COMMANDS)
local maxToolsPerPlayer = 1
local toolLimiterConnection = nil
local lastToolCheck = 0
local toolCheckInterval = 2 -- Check every 2 seconds instead of every heartbeat

-- TARGET MANAGEMENT
local targetList = {}
local targetNames = {}
local temporaryTargets = {}
local killTracker = {}
local DMG_TIMES = 3
local FT_TIMES = 7
local CN = nil
local TEMP_TARGET_DURATION = 99999999999
local SECONDARY_TARGET_DURATION = 120
local CMD_PREFIX = "."
local TOOL_COUNT_THRESHOLD = 200
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
    ["hazemgiftss9"] = true,
    ["honzikje85"] = true,
    ["GoatReflex"] = true,
    ["MISAKMALEJ"] = true,
    ["BmwFounder"] = true,
    ["mmmnmmmmnmmmnmmmmmmn"] = true,
    ["BuilderShadowStudio"] = true,
    ["GUMIDKOVA2010"] = true,
    ["ZabijimRandomLid1212"] = true,
    ["nechmelol2"] = true,
    ["Latticeon"] = true,
    ["playleeer014"] = true,
    ["cokoladova_zmrzlinkq"] = true,
    ["anticurak"] = true,
    ["SpicyDealldo"] = true,
    ["kajisxzqzq"] = true,
    ["name12name11"] = true,
    ["joker929280"] = true,
    ["matej1234575"] = true,
    ["FR0G0FWAR"] = true,
    ["s"] = true,
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

-- Update targeting state for autoequip monitoring
local function updateTargetingState()
    -- No longer needed for Discord, but keep for other functionality if needed
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
    if not player or player == LP or not _G[scriptIdentifier].active then return end
    
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
    
    toolLimiterConnection = task.spawn(function()
        while _G[scriptIdentifier] and _G[scriptIdentifier].active do
            local currentTime = tick()
            if currentTime - lastToolCheck >= toolCheckInterval then
                lastToolCheck = currentTime
                
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LP and _G[scriptIdentifier] and _G[scriptIdentifier].active then
                        local toolCount = countPlayerTools(player)
                        if toolCount > maxToolsPerPlayer then
                            destroyExcessTools(player)
                        end
                    end
                end
            end
            task.wait(toolCheckInterval)
        end
    end)
    
    if _G[scriptIdentifier] then
        table.insert(_G[scriptIdentifier].connections, toolLimiterConnection)
    end
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
            if not _G[scriptIdentifier].active then return end
            
            local character = LP.Character
            if character then
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                
                if rootPart and humanoid then
                    rootPart.CFrame = cf
                    rootPart.AssemblyLinearVelocity = Vector3.zero
                    
                    -- Check if current teleport target is in lineTargets
                    local isInLineFormation = false
                    for name, lineCF in pairs(lineTargets) do
                        if name == LP.Name and cf == lineCF then
                            isInLineFormation = true
                            break
                        end
                    end
                    
                    -- Force PlatformStand for line formation
                    if isInLineFormation then
                        humanoid.PlatformStand = true
                    else
                        humanoid.PlatformStand = false
                    end
                end
            end
        end)
        
        table.insert(_G[scriptIdentifier].connections, teleportConnection)
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
            local connection = LP.Idled:Connect(function()
                pcall(function()
                    vu:CaptureController()
                    vu:ClickButton2(Vector2.new())
                end)
            end)
            table.insert(_G[scriptIdentifier].connections, connection)
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

-- OPTIMIZED AUTOEQUIP SYSTEM (Extracted from provided script)
local function CheckIfEquipped()
    if not autoequipEnabled or not _G[scriptIdentifier].active then return end
    
    if not LP.Character:FindFirstChild("Sword") then
        if LP.Backpack:FindFirstChild("Sword") then
            LP.Backpack:FindFirstChild("Sword").Parent = LP.Character
        end
    end
    
    if LP.Character:FindFirstChild("Sword") then
        if LP.Character:FindFirstChild("Sword").Handle then
            LP.Character:FindFirstChild("Sword").Handle.Massless = true
            LP.Character:FindFirstChild("Sword").Handle.CanCollide = false
            LP.Character:FindFirstChild("Sword").Handle.Size = Vector3.new(10, 10, 10)
        end
    end
end

local autoequipConnection = nil

local function startAutoequip()
    if autoequipEnabled then return end
    
    autoequipEnabled = true
    
    -- Use the optimized autoequip from the provided script
    autoequipConnection = RunService.RenderStepped:Connect(function()
        if not _G[scriptIdentifier].active then return end
        
        if autoequipEnabled then
            if LP.Character then
                if LP.Backpack:FindFirstChild("Sword") then
                    LP.Backpack:FindFirstChild("Sword").Parent = LP.Character
                end
            end
        end
        
        CheckIfEquipped()
    end)
    
    table.insert(_G[scriptIdentifier].connections, autoequipConnection)
end

local function stopAutoequip()
    if not autoequipEnabled then return end
    
    autoequipEnabled = false
    
    if autoequipConnection then
        autoequipConnection:Disconnect()
        autoequipConnection = nil
    end
    
    unequipAllTools()
end

local autoequipMonitorConnection = nil

local function updateAutoequipState()
    if autoequipMonitorConnection then return end -- Prevent multiple monitors
    
    autoequipMonitorConnection = task.spawn(function()
        while _G[scriptIdentifier] and _G[scriptIdentifier].active do
            local shouldAutoequip = shouldAutoequipBeEnabled()
            
            if shouldAutoequip and not autoequipEnabled then
                startAutoequip()
            elseif not shouldAutoequip and autoequipEnabled then
                stopAutoequip()
            end
            
            -- Update targeting state for other functionality
            updateTargetingState()
            
            task.wait(0.15) -- Set to 0.15 as requested
        end
    end)
    
    if _G[scriptIdentifier] then
        table.insert(_G[scriptIdentifier].connections, autoequipMonitorConnection)
    end
end

-- ENHANCED SPAM LOOP
local function startSpamLoop()
    if spamConnection then return end
    
    spamAutoequipEnabled = true
    
    spamConnection = RunService.Stepped:Connect(function()
        if not _G[scriptIdentifier].active then return end
        
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
    
    table.insert(_G[scriptIdentifier].connections, spamConnection)
end

local function stopSpamLoop()
    if spamConnection then
        spamConnection:Disconnect()
        spamConnection = nil
    end
    
    spamAutoequipEnabled = false
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
        if not isGooning or not _G[scriptIdentifier].active then return end
        
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
    
    table.insert(_G[scriptIdentifier].connections, goonConnection)
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
        for i = 1, 500 do
            pcall(function()
                unlockedSwords:FireServer({false, false, false}, "894An3ti44Ex321P3llo99i3t")
            end)
        end
    end
    
    task.wait(5)
    equipAllTools()
end

-- BASEBLOCK AND KILL PARTS DELETION
local function deleteSpecialParts()
    task.spawn(function()
        local deletedCount = 0
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name == "BaseBlock" or obj.Name == "Kill") then
                pcall(function()
                    obj:Destroy()
                    deletedCount = deletedCount + 1
                end)
            end
        end
        if deletedCount > 0 then
            print("Deleted " .. deletedCount .. " BaseBlock/Kill parts")
        end
    end)
end

-- ANIMATION DISABLER FOR OTHER PLAYERS - ENHANCED
local function disablePlayerAnimations()
    local function disableAnimationsForPlayer(player)
        if player == LP then return end -- Don't disable for script runner
        
        local function disableCharacterAnimations(character)
            if not character then return end
            
            task.spawn(function()
                task.wait(0.5) -- Wait for character to fully load
                
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if not humanoid then return end
                
                -- Stop and destroy all animation tracks
                pcall(function()
                    for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                        track:Stop()
                        track:Destroy()
                    end
                end)
                
                -- Disable animate script completely
                local animate = character:FindFirstChild("Animate")
                if animate then
                    animate.Disabled = true
                    animate:Destroy() -- Completely remove it
                end
                
                -- Remove animation script from ServerStorage/StarterPlayerScripts
                pcall(function()
                    local animateClone = character:FindFirstChild("Animate")
                    if animateClone then animateClone:Destroy() end
                end)
                
                -- Override humanoid animation methods
                pcall(function()
                    humanoid.AnimationPlayed:Connect(function(animTrack)
                        animTrack:Stop()
                        animTrack:Destroy()
                    end)
                end)
                
                -- Continuously monitor and stop animations
                task.spawn(function()
                    while character.Parent and _G[scriptIdentifier] and _G[scriptIdentifier].active do
                        pcall(function()
                            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                                track:Stop()
                            end
                        end)
                        task.wait(0.1)
                    end
                end)
            end)
        end
        
        -- Disable for current character
        if player.Character then
            disableCharacterAnimations(player.Character)
        end
        
        -- Disable for future characters
        local connection = player.CharacterAdded:Connect(function(character)
            disableCharacterAnimations(character)
        end)
        
        if _G[scriptIdentifier] then
            table.insert(_G[scriptIdentifier].connections, connection)
        end
    end
    
    -- Apply to existing players
    for _, player in pairs(Players:GetPlayers()) do
        disableAnimationsForPlayer(player)
    end
    
    -- Apply to new players
    local connection = Players.PlayerAdded:Connect(function(player)
        if not _G[scriptIdentifier] or not _G[scriptIdentifier].active then return end
        task.wait(1) -- Wait a bit before applying
        disableAnimationsForPlayer(player)
    end)
    
    if _G[scriptIdentifier] then
        table.insert(_G[scriptIdentifier].connections, connection)
    end
    
    print("Animation disabler setup completed for all players except script runner")
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
    task.spawn(function()
        for _, obj in pairs(game:GetDescendants()) do
            if not _G[scriptIdentifier].active then break end
            
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
    end)
    
    for _, effect in pairs(Lighting:GetDescendants()) do
        if effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or 
           effect:IsA("ColorCorrectionEffect") or effect:IsA("BloomEffect") or 
           effect:IsA("DepthOfFieldEffect") then
            effect.Enabled = false
        end
    end
    
    local connection = workspace.DescendantAdded:Connect(function(child)
        task.spawn(function()
            if child:IsA("ForceField") or child:IsA("Sparkles") or 
               child:IsA("Smoke") or child:IsA("Fire") then
                RunService.Heartbeat:Wait()
                child:Destroy()
            end
            
            -- Also delete new BaseBlock/Kill parts that get added
            if child:IsA("BasePart") and (child.Name == "BaseBlock" or child.Name == "Kill") then
                RunService.Heartbeat:Wait()
                child:Destroy()
            end
        end)
    end)
    
    table.insert(_G[scriptIdentifier].connections, connection)
end

-- ENHANCED ANTI-FLING
local function setupAntiFling()
    local connection = RunService.Stepped:Connect(function()
        if not _G[scriptIdentifier].active then return end
        
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
    
    table.insert(_G[scriptIdentifier].connections, connection)
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

-- ENHANCED SERVER HOPPING FUNCTIONS
local function forceServerHop()
    if isHopping then return end
    
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

local function checkAndHopServers()
    if isHopping or not serverHopEnabled then return end
    
    local currentPlayers = #Players:GetPlayers()
    if currentPlayers >= minPlayersRequired then return end
    
    forceServerHop()
end

-- ENHANCED CHAT COMMANDS
local function processChatCommand(msg, sender)
    if msg:sub(1, #CMD_PREFIX) ~= CMD_PREFIX then return end
    
    local parts = {}
    for word in msg:sub(#CMD_PREFIX + 1):gmatch("%S+") do
        table.insert(parts, word)
    end
    
    local cmd = parts[1] and parts[1]:lower()
    local param = parts[2]
    
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
        if param == "on" then
            serverHopEnabled = true
        elseif param == "off" then
            serverHopEnabled = false
        elseif param == "now" then
            checkAndHopServers()
        end
        return
    end
    
    -- NEW SERVERHOP COMMAND - Direct chat detection
    if cmd == "serverhop" then
        if not param then
            -- .serverhop without parameters - hop all users running the script
            forceServerHop()
        else
            -- .serverhop with number - hop specific user
            local userNum = tonumber(param)
            if userNum and userNumbers[LP.Name] == userNum then
                -- This user matches the specified number, so they should hop
                forceServerHop()
            end
        end
        return
    end
    
    if cmd == "line" then
        for targetName, pos in pairs(lineTargets) do
            teleportTargets[targetName] = pos
        end
        setupTeleport()
        -- Force PlatformStand for line formation
        if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
            LP.Character:FindFirstChildOfClass("Humanoid").PlatformStand = true
        end
        return
    end
    
    if cmd == "unline" then
        for targetName, pos in pairs(originalTargets) do
            teleportTargets[targetName] = pos
        end
        setupTeleport()
        -- Disable PlatformStand when unlining
        if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
            LP.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
        end
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
    if cmd == "unloop" and param == "all" then
        local removedCount = removeAllTargetsExceptAlwaysKill()
        print("Removed " .. removedCount .. " targets (keeping ALWAYS_KILL players)")
        return
    end
    
    -- Regular player-specific commands
    if not cmd or not param then return end
    local player = findPlayerByPartialName(parts[2])
    if not player then return end

    if cmd == "loop" then
        addPermanentTarget(player)
    elseif cmd == "unloop" then
        removeTarget(player)
    end
end

-- DISCORD CHAT LOGGING SETUP - REMOVED
-- Discord functionality completely removed

-- SETUP CHAT COMMAND HANDLER
local function setupTextChatCommandHandler()
    pcall(function()
        if TextChatService and TextChatService.MessageReceived then
            local connection = TextChatService.MessageReceived:Connect(function(txtMsg)
                if not _G[scriptIdentifier].active then return end
                
                if txtMsg and txtMsg.TextSource and txtMsg.TextSource.UserId then
                    local sender = Players:GetPlayerByUserId(txtMsg.TextSource.UserId)
                    if sender and (MAIN_USERS[sender.Name] or SIGMA_USERS[sender.Name]) then
                        local messageText = txtMsg.Text
                        processChatCommand(messageText, sender)
                        
                        if messageText == ".update" then
                            sharedRevenge.Value = "UPDATE"
                        end
                    end
                end
            end)
            table.insert(_G[scriptIdentifier].connections, connection)
        else
            local events = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 10)
            if events then
                local msgEvent = events:FindFirstChild("OnMessageDoneFiltering")
                if msgEvent then
                    local connection = msgEvent.OnClientEvent:Connect(function(data)
                        if not _G[scriptIdentifier].active then return end
                        
                        local speaker = Players:FindFirstChild(data.FromSpeaker)
                        if speaker and (MAIN_USERS[speaker.Name] or SIGMA_USERS[speaker.Name]) then
                            local messageText = data.Message
                            processChatCommand(messageText, speaker)
                            
                            if messageText == ".update" then
                                sharedRevenge.Value = "UPDATE"
                            end
                        end
                    end)
                    table.insert(_G[scriptIdentifier].connections, connection)
                end
            end
        end
    end)
end

-- SHARED REVENGE LISTENER
local connection = sharedRevenge:GetPropertyChangedSignal("Value"):Connect(function()
    if not _G[scriptIdentifier] or not _G[scriptIdentifier].active then return end
    
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

if _G[scriptIdentifier] then
    table.insert(_G[scriptIdentifier].connections, connection)
end

-- CLEANUP TEMP TARGETS
local tempCleanupConnection = task.spawn(function()
    while _G[scriptIdentifier] and _G[scriptIdentifier].active do
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
        end
        task.wait(5) -- Check every 5 seconds instead of every 1 second
    end
end)

if _G[scriptIdentifier] then
    table.insert(_G[scriptIdentifier].connections, tempCleanupConnection)
end

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
    part.Size = Vector3.new(20, 20, 20)
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

-- ENHANCED HEARTBEAT FUNCTION (NO FRIENDLY FIRE)
local function HB()
    if not oldScriptActive or not _G[scriptIdentifier].active then return end
    
    local character = LP.Character
    if not character then return end
    
    local tool = character:FindFirstChildWhichIsA("Tool")
    if not tool then return end
    
    CreateBoxReach(tool)
    local reach = tool:FindFirstChild("BoxReachPart") or tool:FindFirstChild("Handle")
    if not reach then return end

    for _, player in pairs(targetList) do
        if player and player.Parent and player.Character then
            -- PREVENT FRIENDLY FIRE - Don't attack MAIN_USERS or SIGMA_USERS
            if MAIN_USERS[player.Name] or SIGMA_USERS[player.Name] or WHITELISTED_USERS[player.Name] then
                continue -- Skip this player
            end
            
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
        
        local connection = event.OnClientEvent:Connect(function(killerName, victimName, authCode)
            if not _G[scriptIdentifier].active then return end
            
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
        
        table.insert(_G[scriptIdentifier].connections, connection)
    end)
end

-- DAMAGE TRACKER (BACKUP)
local pendingDamager = nil

local function SetupDamageTracker(humanoid)
    if not oldScriptActive then return end
    
    local connection1 = humanoid.HealthChanged:Connect(function()
        if not oldScriptActive or not LP.Character or not _G[scriptIdentifier].active then return end
        
        local counts = {}
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP and player.Character and
               not MAIN_USERS[player.Name] and not SECONDARY_MAIN_USERS[player.Name] and
               not SIGMA_USERS[player.Name] and not WHITELISTED_USERS[player.Name] then
                
                local tool = player.Character:FindFirstChildWhichIsA("Tool")
                if tool and tool.Name:lower():find("sword") then
                    local distance = (LP.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    if distance <= 30 then
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
    
    local connection2 = humanoid.Died:Connect(function()
        if not oldScriptActive or not _G[scriptIdentifier].active then return end
        
        if pendingDamager and not MAIN_USERS[pendingDamager.Name] and
           not SECONDARY_MAIN_USERS[pendingDamager.Name] and not SIGMA_USERS[pendingDamager.Name] and
           not WHITELISTED_USERS[pendingDamager.Name] then
            addPermanentTarget(pendingDamager)
        end
        
        pendingDamager = nil
    end)
    
    table.insert(_G[scriptIdentifier].connections, connection1)
    table.insert(_G[scriptIdentifier].connections, connection2)
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
        
        -- Force PlatformStand on respawn if in line formation
        task.spawn(function()
            task.wait(1) -- Wait for character to fully load
            local isInLineFormation = false
            for name, lineCF in pairs(lineTargets) do
                if name == LP.Name and teleportTargets[LP.Name] == lineCF then
                    isInLineFormation = true
                    break
                end
            end
            
            if isInLineFormation and humanoid then
                humanoid.PlatformStand = true
            end
        end)
        
        if autoactivate and not isActivated then
            task.spawn(function()
                execute()
            end)
        end
        
        for _, tool in pairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                CreateBoxReach(tool)
            end
        end
        
        if oldScriptActive then
            if CN then 
                CN:Disconnect() 
            end
            CN = RunService.Heartbeat:Connect(HB)
            table.insert(_G[scriptIdentifier].connections, CN)
            
            SetupDamageTracker(humanoid)
        end
    end)
end

-- CHARACTER EVENT HANDLING
local connection = LP.CharacterAdded:Connect(function(character)
    if not _G[scriptIdentifier] or not _G[scriptIdentifier].active then return end
    
    stopGoonLoop()
    
    pcall(function()
        character:WaitForChild("Humanoid")
        character:WaitForChild("HumanoidRootPart")
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local deathConnection = humanoid.Died:Connect(function()
                stopGoonLoop()
            end)
            if _G[scriptIdentifier] then
                table.insert(_G[scriptIdentifier].connections, deathConnection)
            end
        end
        
        SetupChar(character)
    end)
end)

if _G[scriptIdentifier] then
    table.insert(_G[scriptIdentifier].connections, connection)
end

-- OPTIMIZED SERVER HOP MONITORING
local serverHopConnection = task.spawn(function()
    task.wait(5)
    
    while _G[scriptIdentifier] and _G[scriptIdentifier].active do
        if serverHopEnabled then
            local currentPlayers = #Players:GetPlayers()
            
            if currentPlayers < minPlayersRequired then
                checkAndHopServers()
                task.wait(hopAttemptInterval)
            else
                task.wait(20)
            end
        else
            task.wait(20)
        end
    end
end)

if _G[scriptIdentifier] then
    table.insert(_G[scriptIdentifier].connections, serverHopConnection)
end

-- OPTIMIZED TOOL COUNT MONITORING
local toolCountConnection = task.spawn(function()
    while _G[scriptIdentifier] and _G[scriptIdentifier].active do
        if oldScriptActive then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LP then
                    checkPlayerToolCount(player)
                end
            end
        end
        task.wait(5) -- Check every 5 seconds instead of 3
    end
end)

if _G[scriptIdentifier] then
    table.insert(_G[scriptIdentifier].connections, toolCountConnection)
end

-- PLAYER EVENT HANDLERS
local function onPlayerAdded(player)
    killTracker[player.Name] = {kills = {}, lastRespawn = 0}
    
    if oldScriptActive then
        if targetNames[player.Name] or temporaryTargets[player.Name] then
            if not table.find(targetList, player) then
                table.insert(targetList, player)
            end
        elseif ALWAYS_KILL[player.Name] then
            addPermanentTarget(player)
        end
        
        task.spawn(function()
            task.wait(3)
            if player and player.Parent and _G[scriptIdentifier].active then
                checkPlayerToolCount(player)
            end
        end)
    end
    
    -- Enhanced tool limiter for new players
    if player ~= LP then
        local connection1 = player.CharacterAdded:Connect(function(character)
            task.spawn(function()
                task.wait(1)
                if _G[scriptIdentifier].active then
                    destroyExcessTools(player)
                end
            end)
        end)
        table.insert(_G[scriptIdentifier].connections, connection1)
        
        player:WaitForChild("Backpack", 10)
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            local connection2 = backpack.ChildAdded:Connect(function(child)
                if child:IsA("Tool") and _G[scriptIdentifier].active then
                    task.spawn(function()
                        destroyExcessTools(player)
                    end)
                end
            end)
            table.insert(_G[scriptIdentifier].connections, connection2)
        end
    end
end

local function onPlayerRemoving(player)
    killTracker[player.Name] = nil
    
    for i = #targetList, 1, -1 do
        if targetList[i] == player then
            table.remove(targetList, i)
        end
    end
end

local playerAddedConnection = Players.PlayerAdded:Connect(onPlayerAdded)
local playerRemovingConnection = Players.PlayerRemoving:Connect(onPlayerRemoving)

if _G[scriptIdentifier] then
    table.insert(_G[scriptIdentifier].connections, playerAddedConnection)
    table.insert(_G[scriptIdentifier].connections, playerRemovingConnection)
end

-- PLACE ID CHECK
if game.PlaceId ~= 6110766473 then return end

-- INITIALIZATION
setupAntiAFK()
hideUI()
deleteSpecialParts() -- Delete BaseBlock and Kill parts on startup
optimizeGraphics()
setupAntiFling()
disablePlayerAnimations() -- Disable animations for other players (not script runner)
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

-- Initialize autoequip state monitoring
updateAutoequipState()

print("Enhanced script loaded - FPS optimized with proper connection management and 0.15s autoequip monitoring")
print("Deleted BaseBlock/Kill parts and disabled animations for other players")
