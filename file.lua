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
local autoactivate = true -- Set to false to disable auto-activation

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
    ["IIIllIIlllllIIIllIIl"] = true,
    ["KERX31"]               = true,
    ["prd_statarkou"]        = true,
    ["xnikoti4nforlife"]     = true,
    ["sssdsadasd"]           = true,
    ["HVHlover"]             = true,
    ["ccccc"]              = false,
    ["error232933"]          = true,
    ["FlexFightSecurity015"] = true,
    ["MANGOCZXX12"]          = true,
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

--// AUTO ACTIVATE FUNCTION
local function executeActivate()
    -- Set activation state
    isActivated = true
    oldScriptActive = false
    
    -- Clear all targets when activating new script
    targetList = {}
    targetNames = {}
    temporaryTargets = {}
    oneShotTargets = {}
    
    -- Disconnect killloop
    if CN then 
        CN:Disconnect() 
        CN = nil
    end
    
    pcall(function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/aci.lua'))()
    end)
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
                        executeActivate()
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
                                executeActivate()
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

--------------------------------------------------------------------------------
-- TELEPORTATION + FALL PREVENTION
--------------------------------------------------------------------------------
local teleportTargets = {
    ["Cubot_Nova3"]           = CFrame.new(7152,4405,4707),
    ["Cub0t_01"]          = CFrame.new(7122,4505,4719),
    ["cubot_nova4"]          = CFrame.new(7122,4475,4719),
    ["cubot_autoIoop"]       = CFrame.new(7132,4605,4707),
    ["Cubot_Nova2"]       = CFrame.new(7122,4705,4729),
    ["Cubot_Nova1"]       = CFrame.new(7132,4605,4529),
}

local function setupTeleport()
    if teleportConnection then teleportConnection:Disconnect() end
    local cf = teleportTargets[LP.Name]
    if cf then
        teleportConnection = RunService.Heartbeat:Connect(function()
            local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if r then
                r.CFrame = cf
                r.AssemblyLinearVelocity = Vector3.new(0,0,0)
            end
        end)
    end
end

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
                executeActivate()
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
