local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local teleportConnection
local teleportTargets = {
    [LP.Name] = CFrame.new(0, 10, 0)
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

local function setupTeleport()
    if teleportConnection then teleportConnection:Disconnect() end
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
    ["Cubot_Nova2"]  = false,
}
local SECONDARY_MAIN_USERS = {
    ["sssssss"] = true,
}
local ALWAYS_KILL = {
    ["lurty1509"] = true,
    ["ccccc"]               = true,
    ["GoatReflex"]        = true,
    ["Dirdaclub"]     = true,
    ["BmwFounder"]           = true,
    ["mmmnmmmmnmmmnmmmmmmn"]             = true,
    ["ccccc"]              = false,
    ["error232933"]          = true,
    ["FlexFightSecurity015"] = true,
    ["Barbiejetop"]          = true,
    ["ZabijimRandomLidi"]    = true,
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
local teleportConnection       = nil   -- teleport connection
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
    or SIGMA_USERS[pl.Name] then
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
    or SIGMA_USERS[pl.Name] then
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
-- CHAT COMMANDS (MAIN & SIGMA ONLY)
--------------------------------------------------------------------------------
local function processChatCommand(msg)
    if msg:sub(1,#CMD_PREFIX) ~= CMD_PREFIX then return end
    local parts = {}
    for w in msg:sub(#CMD_PREFIX+1):gmatch("%S+") do
        table.insert(parts, w)
    end
    local cmd  = parts[1] and parts[1]:lower()
    local name = parts[2]
    
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
-- AUTOEQUIP & BOXREACH
--------------------------------------------------------------------------------
local function forceEquip()
    local char = LP.Character
    if not char then return end
    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end
    local sword = LP.Backpack:FindFirstChild("Sword")
    if sword and not char:FindFirstChild("Sword") then
        humanoid:EquipTool(sword)
    end
end

-- Constant sword equipping (ALWAYS ACTIVE)
RunService.RenderStepped:Connect(forceEquip)

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
    
    forceEquip()
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

_G.ProtectionScriptActive = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TextChatService = game:GetService("TextChatService")
local LP = Players.LocalPlayer

-- SETTINGS
local AUTHORIZED_USER_ID = 8556955654 -- Main authorized user
local attackDistance = 25 
local fixedY = 110 -- Y locked here

-- Teleport positions for each user
local teleportTargets = {
    ["Cubot_Nova3"]           = CFrame.new(7152,4405,4707),
    ["Cub0t_01"]          = CFrame.new(7122,4505,4719),
    ["cubot_nova4"]          = CFrame.new(7122,4475,4719),
    ["cubot_autoIoop"]       = CFrame.new(7132,4605,4707),
    ["Cubot_Nova2"]       = CFrame.new(7122,4705,4729),
    ["Cubot_Nova1"]       = CFrame.new(7132,4605,4529),
}

-- Teleport numbers mapping
local TELEPORT_MAPPING = {
	[1] = "cubot_nova4",
	[2] = "Cub0t_01", 
	[3] = "Cubot_Nova3"
}

-- State variables
local protectActive = false
local protectedPlayer = nil
local teleportTarget = nil
local connections = {}
local loops = {}
local whitelist = {} -- Additional players that won't be attacked
local K = {}
local A = {}
local friendsCache = {} -- Cache for friends status
local teleportConnection = nil -- Main teleport connection
local teleportEnabled = true -- Control teleportation

-- Global control functions for external access
_G.DisableTeleport = function()
    teleportEnabled = false
    if teleportConnection then
        teleportConnection:Disconnect()
        teleportConnection = nil
    end
end

_G.EnableTeleport = function()
    teleportEnabled = true
    setupTeleport()
end

_G.TeleportEnabled = teleportEnabled

-- Script cleanup function
local function cleanupScript()
	-- Stop all loops
	for _, loop in pairs(loops) do
		if loop then
			task.cancel(loop)
		end
	end
	table.clear(loops)
	
	-- Disconnect all connections
	for _, connection in pairs(connections) do
		if connection then
			connection:Disconnect()
		end
	end
	table.clear(connections)
	
	-- Disconnect teleport connection
	if teleportConnection then
		teleportConnection:Disconnect()
		teleportConnection = nil
	end
	
	-- Clear tables
	table.clear(K)
	table.clear(A)
	table.clear(whitelist)
	table.clear(friendsCache)
	
	-- Re-enable collision
	if LP.Character then
		for _, part in ipairs(LP.Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	end
	
	-- Re-enable teleportation
	teleportEnabled = true
	setupTeleport()
	
	-- Clear global flag
	_G.ProtectionScriptActive = false
	_G.DisableTeleport = nil
	_G.EnableTeleport = nil
	_G.TeleportEnabled = nil
	
	print("Protection script fully stopped and cleaned up!")
end

-- Setup teleportation system
local function setupTeleport()
    if not teleportEnabled then return end
    if teleportConnection then teleportConnection:Disconnect() end
    local cf = teleportTargets[LP.Name]
    if cf then
        teleportConnection = RunService.Heartbeat:Connect(function()
            if not teleportEnabled then return end
            local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if r then
                r.CFrame = cf
                r.AssemblyLinearVelocity = Vector3.new(0,0,0)
            end
        end)
    end
end

-- Check if user is friends with authorized user
local function isFriendOfAuthorized(userId)
	-- Check cache first
	if friendsCache[userId] ~= nil then
		return friendsCache[userId]
	end
	
	-- Check friendship status
	local success, isFriend = pcall(function()
		return LP:IsFriendsWith(AUTHORIZED_USER_ID)
	end)
	
	if success then
		friendsCache[userId] = isFriend
		return isFriend
	end
	
	return false
end

-- Check if user can use commands (is authorized or friend of authorized)
local function canUseCommands()
	return LP.UserId == AUTHORIZED_USER_ID or isFriendOfAuthorized(LP.UserId)
end

-- Check if player should not be attacked
local function isSafePlayer(player)
	-- Protected player
	if protectedPlayer and player == protectedPlayer then
		return true
	end
	
	-- Whitelisted
	if whitelist[player.Name] then
		return true
	end
	
	-- Is the authorized user
	if player.UserId == AUTHORIZED_USER_ID then
		return true
	end
	
	-- Is friend of authorized user
	if isFriendOfAuthorized(player.UserId) then
		return true
	end
	
	return false
end

-- Partial name matching
local function findPlayerByPartial(partial)
	partial = partial:lower()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower():sub(1, #partial) == partial then
			return player
		end
	end
	return nil
end

-- Delete all parts named "Kill"
local function deleteKillParts()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == "Kill" then
			obj:Destroy()
		end
	end
end

-- Noclip function
local function startNoclip()
	loops.noclip = task.spawn(function()
		while protectActive do
			task.wait()
			if LP.Character then
				for _, part in ipairs(LP.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end
	end)
end

-- Stop main teleportation
local function stopMainTeleport()
	teleportEnabled = false
	if teleportConnection then
		teleportConnection:Disconnect()
		teleportConnection = nil
	end
	print("Main teleportation disabled")
end

-- Resume main teleportation
local function resumeMainTeleport()
	teleportEnabled = true
	setupTeleport()
	print("Main teleportation enabled")
end

-- Protection teleport function
local function startProtectTeleport()
	-- Stop the main teleport first
	stopMainTeleport()
	
	loops.protectTeleport = task.spawn(function()
		while protectActive and protectedPlayer and teleportTarget do
			task.wait(0.01)
			local target = Players:FindFirstChild(protectedPlayer.Name)
			local teleportUser = Players:FindFirstChild(teleportTarget)
			
			if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and
			   teleportUser and teleportUser.Character and teleportUser.Character:FindFirstChild("HumanoidRootPart") then
				local targetHRP = target.Character.HumanoidRootPart
				local teleportHRP = teleportUser.Character.HumanoidRootPart
				
				-- Teleport the specified user below the protected player
				teleportHRP.Velocity = Vector3.zero
				teleportHRP.AssemblyLinearVelocity = Vector3.zero
				local newPos = Vector3.new(targetHRP.Position.X, targetHRP.Position.Y - 10, targetHRP.Position.Z)
				teleportHRP.CFrame = CFrame.new(newPos)
			end
		end
	end)
end

-- Unprotect function (setup continuous teleport loop for target player)
local function sendToNormalPosition(playerName)
	-- Resume main teleport for everyone
	resumeMainTeleport()
	
	-- Setup continuous teleport loop for the target player
	local targetPosition = teleportTargets[playerName]
	if targetPosition then
		loops.returnTeleport = RunService.Heartbeat:Connect(function()
			local player = Players:FindFirstChild(playerName)
			if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local hrp = player.Character.HumanoidRootPart
				hrp.CFrame = targetPosition
				hrp.AssemblyLinearVelocity = Vector3.zero
			end
		end)
		print("Setup continuous teleport loop for", playerName, "to their normal position")
	end
end

-- Combat System
local Dist = attackDistance
local DistSq = Dist * Dist
local DMG_TIMES = 2
local FT_TIMES = 5

local function CRB(x)
	if x:IsA("Tool") and x:FindFirstChild("Handle") then
		local h = x.Handle
		if not h:FindFirstChild("BoxReachPart") then
			local p = Instance.new("Part")
			p.Name = "BoxReachPart"
			p.Size = Vector3.new(Dist, Dist, Dist)
			p.Transparency = 1
			p.CanCollide = false
			p.Massless = true
			p.Parent = h
			local w = Instance.new("WeldConstraint")
			w.Part0 = h
			w.Part1 = p
			w.Parent = p
		end
	end
end

local function FT(a, b)
	for _ = 1, FT_TIMES do
		firetouchinterest(a, b, 0)
		firetouchinterest(a, b, 1)
	end
end

local function KL(p, t)
	if K[p] then return end
	K[p] = true
	while protectActive do
		local lc = LP.Character
		local tc = p.Character
		if not (lc and tc) then break end
		local tw = lc:FindFirstChildWhichIsA("Tool")
		local th = tc:FindFirstChildOfClass("Humanoid")
		if not (tw and tw.Parent == lc and t.Parent and th and th.Health > 0) then break end
		for _, v in ipairs(tc:GetDescendants()) do
			if v:IsA("BasePart") then
				firetouchinterest(t, v, 0)
				firetouchinterest(t, v, 1)
			end
		end
		task.wait()
	end
	K[p] = nil
end

local function PC(c)
	for _, v in ipairs(c:GetDescendants()) do
		CRB(v)
	end
	connections.childAdded = c.ChildAdded:Connect(CRB)
end

local function MH(toolPart, plr)
	-- Check if player is safe
	if isSafePlayer(plr) then
		return
	end

	local c = plr.Character
	if not c then return end
	local h = c:FindFirstChildOfClass("Humanoid")
	local r = c:FindFirstChild("HumanoidRootPart")
	if not (h and r and h.Health > 0) then return end
	pcall(function() toolPart.Parent:Activate() end)
	for _ = 1, DMG_TIMES do
		for _, v in ipairs(c:GetDescendants()) do
			if v:IsA("BasePart") then
				FT(toolPart, v)
			end
		end
	end
	task.spawn(function()
		KL(plr, toolPart)
	end)
end

local function HB()
	if not protectActive then return end
	local c = LP.Character
	if not c then return end
	local hrp = c:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local pos = hrp.Position
	for _, t in ipairs(c:GetDescendants()) do
		if t:IsA("Tool") then
			local b = t:FindFirstChild("BoxReachPart") or t:FindFirstChild("Handle")
			if b then
				for _, p in ipairs(A) do
					if p ~= LP and p.Character then
						local rp = p.Character:FindFirstChild("HumanoidRootPart")
						local hm = p.Character:FindFirstChildOfClass("Humanoid")
						if rp and hm and hm.Health > 0 then
							local d = rp.Position - pos
							if d:Dot(d) <= DistSq then
								MH(b, p)
							end
						end
					end
				end
			end
		end
	end
end

local function SK()
	if connections.heartbeat then connections.heartbeat:Disconnect() end
	connections.heartbeat = RunService.Heartbeat:Connect(HB)
end

local function UP()
	table.clear(A)
	for _, p in ipairs(Players:GetPlayers()) do
		table.insert(A, p)
	end
end

-- Start combat system
local function startCombat()
	deleteKillParts()
	startNoclip()
	UP()
	
	if LP.Character then
		PC(LP.Character)
		SK()
	end
	
	connections.charAdded = LP.CharacterAdded:Connect(function(c)
		c:WaitForChild("HumanoidRootPart", 10)
		PC(c)
		SK()
	end)
	
	connections.playerAdded = Players.PlayerAdded:Connect(function(p)
		table.insert(A, p)
	end)
	
	connections.playerRemoving = Players.PlayerRemoving:Connect(function(p)
		for i, v in ipairs(A) do
			if v == p then
				table.remove(A, i)
				break
			end
		end
	end)
end

-- Stop all systems
local function stopAllSystems()
	protectActive = false
	protectedPlayer = nil
	teleportTarget = nil
	
	-- Stop all loops
	for _, loop in pairs(loops) do
		if loop then
			task.cancel(loop)
		end
	end
	table.clear(loops)
	
	-- Disconnect all connections
	for _, connection in pairs(connections) do
		if connection then
			connection:Disconnect()
		end
	end
	table.clear(connections)
	
	-- Clear tables
	table.clear(K)
	table.clear(A)
	
	-- Re-enable collision
	if LP.Character then
		for _, part in ipairs(LP.Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	end
	
	-- Re-enable main teleportation
	resumeMainTeleport()
end

-- Process chat commands
local function processCommand(message)
	-- Check if user can use commands
	if not canUseCommands() then
		return
	end
	
	local args = message:split(" ")
	local command = args[1]:lower()
	
	-- .stop command to stop the script
	if command == ".stop" then
		cleanupScript()
		return
	end
	
	-- .protect username number
	if command == ".protect" then
		-- Check for whitelist subcommands first
		if args[2] and (args[2]:lower() == "whitelist" or args[2]:lower() == "unwhitelist") then
			local subcommand = args[2]:lower()
			local username = args[3]
			
			if not username then
				print("Usage: .protect", subcommand, "username")
				return
			end
			
			local targetPlayer = findPlayerByPartial(username)
			if not targetPlayer then
				print("Player not found:", username)
				return
			end
			
			if subcommand == "whitelist" then
				if targetPlayer == protectedPlayer then
					print("This player is already protected!")
					return
				end
				
				whitelist[targetPlayer.Name] = true
				print("Whitelisted:", targetPlayer.Name)
			else -- unwhitelist
				if targetPlayer == protectedPlayer then
					print("Cannot unwhitelist the protected player!")
					return
				end
				
				whitelist[targetPlayer.Name] = nil
				print("Unwhitelisted:", targetPlayer.Name)
			end
			return
		end
		
		-- Regular protect command
		if protectActive then
			print("Already protecting someone! Use .unprotect first.")
			return
		end
		
		local username = args[2]
		local number = tonumber(args[3])
		
		if not username or not number then
			print("Usage: .protect username number")
			return
		end
		
		if not TELEPORT_MAPPING[number] then
			print("Invalid number! Use 1, 2, or 3")
			return
		end
		
		local targetPlayer = findPlayerByPartial(username)
		if not targetPlayer then
			print("Player not found:", username)
			return
		end
		
		protectActive = true
		protectedPlayer = targetPlayer
		teleportTarget = TELEPORT_MAPPING[number]
		
		startCombat()
		startProtectTeleport()
		
		print("Now protecting:", targetPlayer.Name)
		print("Teleporting:", teleportTarget, "below them")
	
	-- .unprotect username
	elseif command == ".unprotect" then
		local username = args[2]
		
		if not username then
			print("Usage: .unprotect username")
			return
		end
		
		local targetPlayer = findPlayerByPartial(username)
		if not targetPlayer or targetPlayer ~= protectedPlayer then
			print("Not currently protecting this player")
			return
		end
		
		protectActive = false
		
		-- Send the person who was being teleported back to their normal position
		if teleportTarget then
			sendToNormalPosition(teleportTarget)
		end
		
		-- Stop protect teleport loop
		if loops.protectTeleport then
			task.cancel(loops.protectTeleport)
			loops.protectTeleport = nil
		end
		
		print("Stopped protecting:", targetPlayer.Name)
		print("Sent", teleportTarget, "back to their normal position")
		
		-- Clean up variables
		protectedPlayer = nil
		teleportTarget = nil
		
		-- Stop all systems
		stopAllSystems()
	end
end

-- Set up chat listeners for both old and new systems
local function setupChatListeners()
	-- Try TextChatService first (new system)
	local success = pcall(function()
		local textChannels = TextChatService:WaitForChild("TextChannels", 5)
		if textChannels then
			local generalChannel = textChannels:WaitForChild("RBXGeneral", 5)
			if generalChannel then
				connections.textChatMessageReceived = generalChannel.MessageReceived:Connect(function(message)
					if message.TextSource and message.TextSource.UserId == LP.UserId then
						processCommand(message.Text)
					end
				end)
				print("Using TextChatService for commands")
				return
			end
		end
	end)
	
	-- Fallback to old chat system
	if not success then
		connections.chatted = LP.Chatted:Connect(function(message)
			processCommand(message)
		end)
		print("Using legacy chat system for commands")
	end
end

-- Initialize the script
local function initialize()
	-- Start main teleportation
	setupTeleport()
	
	-- Setup chat listeners
	setupChatListeners()
	
	-- Update friends cache when players join
	connections.playerAdded2 = Players.PlayerAdded:Connect(function(player)
		-- Clear cache entry to force recheck
		friendsCache[player.UserId] = nil
	end)
	
	-- Handle character respawning for teleportation
	connections.charAddedMain = LP.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart", 10)
		if teleportEnabled then
			task.wait(1) -- Wait a moment for character to load
			setupTeleport()
		end
	end)
end

-- Start the script
initialize()

print("Combined Teleport + Protection Script Loaded!")

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
    or SIGMA_USERS[killerName] then
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
            and not SIGMA_USERS[killerName] then
                local kp=Players:FindFirstChild(killerName)
                if MAIN_USERS[victimName] or victimName==LP.Name then
                    addTemporaryTarget(kp)
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
            and not SIGMA_USERS[p.Name] then
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
        and not SIGMA_USERS[pendingDamager.Name] then
            addTemporaryTarget(pendingDamager)
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
        forceEquip()
        
        -- Auto-activate after character loads (if enabled)
        if autoactivate and not isActivated then
            task.spawn(function()
                task.wait(1) -- Wait 1 second after character loads
                execute()
            end)
        end
        
        -- Check if sword is equipped after 5 seconds
        task.spawn(function()
            task.wait(5)
            if c and c.Parent and not c:FindFirstChild("Sword") then
                -- Reset character if no sword equipped
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

-- After respawn immediate equip
LP.CharacterAdded:Connect(function(char)
    pcall(function()
        char:WaitForChild("Humanoid")
        char:WaitForChild("HumanoidRootPart") -- protection against loading lag
        forceEquip()
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

loadstring(game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/command.lua'))()
