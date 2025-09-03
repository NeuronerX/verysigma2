local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

-- WHITELIST CONFIGURATION
getgenv().WHITELIST = {
    "e5c4qe",
    "xL1fe_r",
    "xL1v3_r",
    "xLiv3_r"
}

local PROTECTED_USER_ID = 9260414163
local friendsList = {}
local friendsLoaded = false

-- Function to load friends of protected user
local function loadFriends()
    task.spawn(function()
        local success, result = pcall(function()
            local url = "https://friends.roblox.com/v1/users/" .. PROTECTED_USER_ID .. "/friends"
            local response = game:HttpGet(url)
            local data = HttpService:JSONDecode(response)
            
            friendsList = {}
            if data and data.data then
                for _, friend in ipairs(data.data) do
                    friendsList[friend.name] = true
                end
            end
            friendsLoaded = true
        end)
        
        if not success then
            friendsLoaded = true -- Still set to true to continue execution
        end
    end)
end

-- Pre-allocated tables for performance
local playerList = {}
local killTrackers = {}
local tempParts = {}
local cachedTools = {}

-- PERSISTENT HANDLE KILL SYSTEM
local handleKillActive = {}

-- Check if player is a valid target (now targets all except protected)
-- Check if player is a valid target (now targets all except protected & whitelist & protected user's friends)
local function isValidTarget(player)
    if player == LP then
        return false
    end
    
    -- Check whitelist
    for _, whitelistedName in ipairs(getgenv().WHITELIST) do
        if string.lower(player.Name) == string.lower(whitelistedName) then
            return false
        end
    end
    
    -- Check if player is PROTECTED_USER_ID themselves
    if player.UserId == PROTECTED_USER_ID then
        return false
    end
    
    -- If friends are loaded, check them
    if friendsLoaded then
        if friendsList[player.Name] then
            return false
        end
    else
        -- While friends are not loaded, just be safe: don't attack anyone yet
        return false
    end
    
    -- Target all other players
    return true
end

-- Fast batch fire touch with proper sequencing
local function batchFireTouch(toolPart, targetParts)
    if not firetouchinterest then
        return
    end
    
    pcall(function() toolPart.Parent:Activate() end)
    
    -- Direct sequential firing without nested loops
    for i = 1, #targetParts do
        local part = targetParts[i]
        if part and part.Parent then
            pcall(function()
                firetouchinterest(toolPart, part, 0)
                firetouchinterest(toolPart, part, 1)
                firetouchinterest(toolPart, part, 0)
                firetouchinterest(toolPart, part, 1)
            end)
        end
    end
    
    pcall(function() toolPart.Parent:Activate() end)
end

-- Modified tool handle setup
local function setupToolHandle(tool)
    if not tool:IsA("Tool") then return end
    
    local function modifyHandle(handle)
        handle.Massless = true
        handle.CanCollide = false
        cachedTools[tool] = handle
    end
    
    local handle = tool:FindFirstChild("Handle")
    if handle then
        modifyHandle(handle)
    else
        local connection
        connection = tool.ChildAdded:Connect(function(child)
            if child.Name == "Handle" then
                modifyHandle(child)
                connection:Disconnect()
            end
        end)
    end
end

-- Enhanced kill loop with consistent timing
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
            
            -- Reset failure counter on success
            consecutiveFailures = 0
            
            -- Multiple tool activations
            task.spawn(function()
                for _ = 1, 5 do
                    pcall(function() tool:Activate() end)
                end
            end)
            
            -- Batch collect all parts
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

-- Enhanced heartbeat function with better targeting
local function onHeartbeat()
    local char = LP.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Process all tools with enhanced targeting
    for tool, handle in pairs(cachedTools) do
        if tool.Parent == char and handle.Parent then
            for i = 1, #playerList do
                local player = playerList[i]
                if isValidTarget(player) and player.Character then
                    local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
                    local targetHumanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    
                    if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                        task.spawn(function()
                            handleCombat(handle, player)
                        end)
                    end
                end
            end
        end
    end
end

-- Connection management
local heartbeatConnection
local function setupHeartbeat()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end
    heartbeatConnection = RunService.Heartbeat:Connect(onHeartbeat)
end

-- Enhanced character setup
local function setupCharacter(character)
    -- Wait for character to fully load
    character:WaitForChild("HumanoidRootPart", 10)
    
    -- Setup existing tools
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            setupToolHandle(tool)
        end
    end
    
    -- Monitor new tools
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            setupToolHandle(child)
        end
    end)
    
    setupHeartbeat()
end

-- Player list management with batch updates
local function updatePlayerList()
    table.clear(playerList)
    local players = Players:GetPlayers()
    for i = 1, #players do
        playerList[i] = players[i]
    end
end

-- FAST AND EFFICIENT HANDLE KILL SYSTEM
local function startPersistentHandleKill(targetPlayer)
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
                                -- Ultra fast killing - direct hits to critical parts
                                pcall(function()
                                    -- Root part hits
                                    firetouchinterest(handle, root, 0)
                                    firetouchinterest(handle, root, 1)
                                    firetouchinterest(handle, root, 0)
                                    firetouchinterest(handle, root, 1)
                                    
                                    -- Head hits for instant kill
                                    local head = targetPlayer.Character:FindFirstChild("Head")
                                    if head then
                                        firetouchinterest(handle, head, 0)
                                        firetouchinterest(handle, head, 1)
                                        firetouchinterest(handle, head, 0)
                                        firetouchinterest(handle, head, 1)
                                    end
                                    
                                    -- Torso hits
                                    local torso = targetPlayer.Character:FindFirstChild("Torso") or targetPlayer.Character:FindFirstChild("UpperTorso")
                                    if torso then
                                        firetouchinterest(handle, torso, 0)
                                        firetouchinterest(handle, torso, 1)
                                    end
                                end)
                            else
                                -- Fast fallback
                                pcall(function() tool:Activate() end)
                                pcall(function() tool:Activate() end)
                            end
                        end
                    end
                end
            end
            task.wait() -- Keep it fast but not laggy
        end
    end)
end

-- Auto-start handle kill for all valid targets
local function initializeHandleKillForTargets()
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            startPersistentHandleKill(player)
        end
    end
end

-- Character added function
local function onCharacterAdded(character)
    setupCharacter(character)
    initializeHandleKillForTargets()
end

-- Enhanced character setup
LP.CharacterAdded:Connect(onCharacterAdded)
if LP.Character then
    onCharacterAdded(LP.Character)
end

-- Enhanced player management
Players.PlayerAdded:Connect(function(player)
    playerList[#playerList + 1] = player
    if isValidTarget(player) then
        startPersistentHandleKill(player)
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
    handleKillActive[player] = nil
end)

-- Load friends list and initialize
loadFriends()

-- Wait a moment for friends to load, then initialize
task.wait(1)
updatePlayerList()
initializeHandleKillForTargets()

warn("activated")
