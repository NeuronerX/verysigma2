local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
loadstring(game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/command.lua'))()

-- Performance constants
local DIST = 67690
local DIST_SQ = DIST * DIST
local SWORD_NAME = "Sword"

-- USER TABLES
local MAIN_USERS = {
    ["Pyan_x2v"] = true,
    ["Pyan_x0v"] = true,
    ["XxAmeliaBeastStormyx"] = true,
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
    ["sigmaboy123"] = true,
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
    ["cubot_nova4"] = CFrame.new(7122, 4475, 4719),
    ["cubot_autoIoop"] = CFrame.new(7132, 4605, 4707),
    ["Cubot_Nova2"] = CFrame.new(7122, 4705, 4729),
    ["Cubot_Nova1"] = CFrame.new(7132, 4605, 4529),
}

-- Global variables
getgenv().TargetTable = {}
getgenv().PermanentTargets = {}
getgenv().spam_swing = false

-- Performance tracking variables
local connections = {}
local targetedPlayers = {}
local playerList = {}
local killTrackers = {}
local tempParts = {}
local cachedTools = {}
local handleKillActive = {}

-- Utility functions
local function findPlayerByPartialName(partialName)
    partialName = partialName:lower()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name:lower():find(partialName) then
            return player
        end
    end
end

local function addTargetToLoop(player)
    if not player or MAIN_USERS[player.Name] or WHITELISTED_USERS[player.Name] then return end
    
    for _, target in pairs(getgenv().TargetTable) do
        if target == player then return end
    end
    
    table.insert(getgenv().TargetTable, player)
    targetedPlayers[player.Name] = true
    
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
    handleKillActive[player] = nil
end

local function addPermanentTarget(player)
    if not player or MAIN_USERS[player.Name] or WHITELISTED_USERS[player.Name] then return end
    
    getgenv().PermanentTargets[player.Name] = true
    addTargetToLoop(player)
end

-- Enhanced auto-equip system
local function autoEquip()
    local character = LP.Character
    if not character then return end
    
    -- Auto-equip sword from backpack
    for _, tool in ipairs(LP.Backpack:GetChildren()) do
        if tool.Name == SWORD_NAME and tool:IsA("Tool") then
            tool.Parent = character
        end
    end
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
    
    -- Direct sequential firing for maximum damage
    for i = 1, #targetParts do
        local part = targetParts[i]
        if part and part.Parent then
            pcall(function()
                firetouchinterest(toolPart, part, 0)
                firetouchinterest(toolPart, part, 1)
                firetouchinterest(toolPart, part, 0)
                firetouchinterest(toolPart, part, 1)
                firetouchinterest(toolPart, part, 0)
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
            
            -- Multiple tool activations
            task.spawn(function()
                for _ = 1, 8 do
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

-- Persistent handle kill system
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
                                pcall(function()
                                    -- Root part hits
                                    firetouchinterest(handle, root, 0)
                                    firetouchinterest(handle, root, 1)
                                    firetouchinterest(handle, root, 0)
                                    firetouchinterest(handle, root, 1)
                                    firetouchinterest(handle, root, 0)
                                    
                                    -- Head hits for instant kill
                                    local head = targetPlayer.Character:FindFirstChild("Head")
                                    if head then
                                        firetouchinterest(handle, head, 0)
                                        firetouchinterest(handle, head, 1)
                                        firetouchinterest(handle, head, 0)
                                        firetouchinterest(handle, head, 1)
                                        firetouchinterest(handle, head, 0)
                                    end
                                    
                                    -- Torso hits
                                    local torso = targetPlayer.Character:FindFirstChild("Torso") or targetPlayer.Character:FindFirstChild("UpperTorso")
                                    if torso then
                                        firetouchinterest(handle, torso, 0)
                                        firetouchinterest(handle, torso, 1)
                                        firetouchinterest(handle, torso, 0)
                                        firetouchinterest(handle, torso, 1)
                                    end
                                end)
                            end
                            
                            -- Additional tool activations
                            pcall(function() tool:Activate() end)
                            pcall(function() tool:Activate() end)
                        end
                    end
                end
            end
            task.wait()
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
            character.HumanoidRootPart.AngularVelocity = Vector3.new(0, 0, 0)
            
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

-- Chat command processing
local function processChatCommand(messageText, sender)
    local args = messageText:split(" ")
    local command = args[1]:lower()
    
    if command == ".loop" and #args >= 2 then
        local targetPlayer = findPlayerByPartialName(args[2])
        if targetPlayer then
            addTargetToLoop(targetPlayer)
        end
        
    elseif command == ".unloop" then
        if #args >= 2 then
            if args[2]:lower() == "all" then
                local newTargetTable = {}
                for _, target in pairs(getgenv().TargetTable) do
                    if not getgenv().PermanentTargets[target.Name] then
                        targetedPlayers[target.Name] = nil
                        handleKillActive[target] = nil
                    else
                        table.insert(newTargetTable, target)
                    end
                end
                getgenv().TargetTable = newTargetTable
            else
                local targetPlayer = findPlayerByPartialName(args[2])
                if targetPlayer and not getgenv().PermanentTargets[targetPlayer.Name] then
                    removeTargetFromLoop(targetPlayer)
                end
            end
        end
        
    elseif command == ".sp" then
        getgenv().spam_swing = true
        
    elseif command == ".unsp" then
        getgenv().spam_swing = false
        
    elseif command == ".activate" then
        loadstring(game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/aci.lua'))()
    end
end

-- Chat monitoring setup
local function setupChatCommandHandler()
    pcall(function()
        if TextChatService and TextChatService.MessageReceived then
            local connection = TextChatService.MessageReceived:Connect(function(txtMsg)
                if txtMsg and txtMsg.TextSource and txtMsg.TextSource.UserId then
                    local sender = Players:GetPlayerByUserId(txtMsg.TextSource.UserId)
                    if sender and (MAIN_USERS[sender.Name] or SIGMA_USERS[sender.Name]) then
                        processChatCommand(txtMsg.Text, sender)
                    end
                end
            end)
            table.insert(connections, connection)
        else
            local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if events then
                local msgEvent = events:FindFirstChild("OnMessageDoneFiltering")
                if msgEvent then
                    local connection = msgEvent.OnClientEvent:Connect(function(data)
                        local speaker = Players:FindFirstChild(data.FromSpeaker)
                        if speaker and (MAIN_USERS[speaker.Name] or SIGMA_USERS[speaker.Name]) then
                            processChatCommand(data.Message, speaker)
                        end
                    end)
                    table.insert(connections, connection)
                end
            end
        end
    end)
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
                        addPermanentTarget(killer)
                    else
                        getgenv().PermanentTargets[killerName] = true
                        targetedPlayers[killerName] = true
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
            addTargetToLoop(player)
        end
    end
end

-- Player management
Players.PlayerAdded:Connect(function(player)
    playerList[#playerList + 1] = player
    if ALWAYS_KILL[player.Name] or getgenv().PermanentTargets[player.Name] or targetedPlayers[player.Name] then
        addTargetToLoop(player)
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

-- Character setup
LP.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    setupCharacter(character)
end)

if LP.Character then
    setupCharacter(LP.Character)
end

-- Main enhanced loops
RunService.Heartbeat:Connect(onHeartbeat)
RunService.Stepped:Connect(autoEquip)
RunService.RenderStepped:Connect(teleportLoop)

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
