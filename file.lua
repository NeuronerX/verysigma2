if game.PlaceId ~= 6110766473 then
    return
end

wait(2)

-- Check execution identity at start
local identity = getidentity()
local hasInstakill = false

if identity == 8 then
    hasInstakill = true
    print("Identity 8 detected - Instakill features will be enabled")
elseif identity == 3 then
    print("Identity 3 detected - Standard features enabled")
else
    print("Identity " .. identity .. " detected - Continuing with standard features")
end

local MAIN_USERS = {
    ["Pyan_x3v"] = true,
    ["Pyan_x2v"] = true,
    ["Pyan_x0v"] = true,
    ["Pyan_x1v"] = true,
    ["Oliv3rTig3r2008"] = true,
    ["SebastianBuilder83"] = true,
    ["nagiconfi209"] = true,
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
    ["kurwuwA"] = true,
    ["GoatReflex"] = true,
    ["vreckotygecko"] = true,
    ["fdngdfngjdfgndf"] = true,
}

local WHITELISTED_USERS = {
    ["e5c4qe"] = true,
    ["xL1fe_r"] = true,
    ["xL1v3_r"] = true,
    ["xLiv3_r"] = true,
}

-- Server hop configuration
local MIN_PLAYERS = 3
local CHECK_INTERVAL = 30
local HOP_COOLDOWN = 5 -- Seconds between hop attempts

-- Discord webhook function
sendmsg = function(url, message)
    local request = http_request or request or HttpPost or syn.request
    if request then
        pcall(function()
            request({
                Url = url,
                Body = game:GetService("HttpService"):JSONEncode({
                    ["content"] = message
                }),
                Method = "POST",
                Headers = {
                    ["content-type"] = "application/json"
                }
            })
        end)
    end
end

loadstring(game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/setup.lua'))()
loadstring(game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/command.lua'))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

getgenv().KillAura = true
getgenv().LoopKill = false
getgenv().spam_swing = false
getgenv().auto_equip = true
getgenv().TargetTable = {}
getgenv().PermanentTargets = {}
getgenv().AutoServerHop = true

-- Auto-enable instakill if identity is 8
if hasInstakill then
    getgenv().firetouchinterest_method = true
    print("Instakill automatically enabled due to identity 8")
    getgenv().firetouchinterest = function(part1, part2, toggle)
        part2.CFrame = part1.CFrame
    end
else
    getgenv().firetouchinterest_method = false
end

local targetedPlayers = {}
local connections = {}
local isHopping = false
local lastHopAttempt = 0

-- Enhanced server hopping functions
local function getServerList()
    local success, result = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100")
    end)
    
    if not success then
        print("Failed to fetch server list - HTTP request failed")
        return nil
    end
    
    local decoded
    success, decoded = pcall(function()
        return HttpService:JSONDecode(result)
    end)
    
    if not success or not decoded or not decoded.data then
        print("Failed to decode server list JSON")
        return nil
    end
    
    return decoded.data
end

local function findValidServers(serverList, minPlayers)
    local validServers = {}
    
    for _, server in pairs(serverList) do
        if server.id and server.id ~= game.JobId then
            local playing = tonumber(server.playing) or 0
            local maxPlayers = tonumber(server.maxPlayers) or 0
            
            -- More flexible server selection
            if playing >= minPlayers and playing < maxPlayers then
                table.insert(validServers, {
                    id = server.id,
                    playing = playing,
                    maxPlayers = maxPlayers
                })
            end
        end
    end
    
    -- Sort by player count (highest first)
    table.sort(validServers, function(a, b)
        return a.playing > b.playing
    end)
    
    return validServers
end

local function hopToServer()
    local currentTime = tick()
    if isHopping or (currentTime - lastHopAttempt) < HOP_COOLDOWN then
        return
    end
    
    isHopping = true
    lastHopAttempt = currentTime
    
    print("Initiating server hop...")
    
    local function attemptHop()
        local serverList = getServerList()
        if not serverList then
            print("Could not retrieve server list, retrying...")
            wait(3)
            if #Players:GetPlayers() < MIN_PLAYERS then
                attemptHop()
            else
                isHopping = false
            end
            return
        end
        
        print("Found " .. #serverList .. " total servers")
        
        -- Try different minimum player requirements
        local attempts = {MIN_PLAYERS, math.max(1, MIN_PLAYERS - 1), 1}
        
        for _, minReq in ipairs(attempts) do
            local validServers = findValidServers(serverList, minReq)
            
            if #validServers > 0 then
                print("Found " .. #validServers .. " valid servers with min " .. minReq .. " players")
                
                -- Try multiple servers in case one fails
                for i = 1, math.min(3, #validServers) do
                    local targetServer = validServers[i]
                    print("Attempting to join server " .. i .. " with " .. targetServer.playing .. "/" .. targetServer.maxPlayers .. " players")
                    
                    local success = pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer.id, LP)
                    end)
                    
                    if success then
                        print("Teleport request sent successfully")
                        return
                    else
                        print("Teleport failed for server " .. i .. ", trying next...")
                        wait(1)
                    end
                end
                
                break -- Exit the attempts loop if we found servers but all failed
            else
                print("No valid servers found with min " .. minReq .. " players")
            end
        end
        
        print("No suitable servers available, will retry later")
        isHopping = false
    end
    
    attemptHop()
end

local function checkPlayerCount()
    if not getgenv().AutoServerHop then return end
    
    local currentPlayers = #Players:GetPlayers()
    print("Current players: " .. currentPlayers .. " | Minimum required: " .. MIN_PLAYERS)
    
    if currentPlayers < MIN_PLAYERS then
        print("Player count too low, initiating server hop...")
        hopToServer()
    end
end

-- Start player count monitoring
task.spawn(function()
    while true do
        if not isHopping then
            checkPlayerCount()
        end
        wait(CHECK_INTERVAL)
    end
end)

function CheckIfEquipped()
    if not LP.Character:FindFirstChild("Sword") then
        if LP.Backpack:FindFirstChild("Sword") then
            LP.Backpack:FindFirstChild("Sword").Parent = LP.Character
        end
    end
    
    if LP.Character:FindFirstChild("Sword") then
        if LP.Character:FindFirstChild("Sword").Handle then
            LP.Character:FindFirstChild("Sword").Handle.Massless = true
            LP.Character:FindFirstChild("Sword").Handle.CanCollide = false
            if getgenv().firetouchinterest_method then
                LP.Character:FindFirstChild("Sword").Handle.Size = Vector3.new(1000000000, 1000000000, 1000000000)
            else
                LP.Character:FindFirstChild("Sword").Handle.Size = Vector3.new(10, 10, 10)
            end
        end
    end
end

function SwingTool()
    task.defer(function()
        if LP.Character:FindFirstChild("Sword") then
            LP.Character:FindFirstChild("Sword"):Activate()
            if getgenv().firetouchinterest_method then
                task.wait(0.001)
                LP.Character:FindFirstChild("Sword"):Activate()
                task.wait(0.001)
                LP.Character:FindFirstChild("Sword"):Activate()
            end
        end
        task.wait(0.002)
        if LP.Character:FindFirstChild("Sword") then
            LP.Character:FindFirstChild("Sword"):Activate()
        end
    end)
end

function BringTarget(targetPart)
    if getgenv().firetouchinterest_method then
        targetPart.CFrame = LP.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)
    else
        targetPart.CFrame = LP.Character.HumanoidRootPart.CFrame * CFrame.new(0, 1, -4)
    end
end

function findPlayerByPartialName(partialName)
    partialName = partialName:lower()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name:lower():find(partialName, 1, true) then
            return player
        end
    end
    return nil
end

function addTargetToLoop(player)
    if not player then return end
    
    if MAIN_USERS[player.Name] or WHITELISTED_USERS[player.Name] then
        return
    end
    
    for _, target in pairs(getgenv().TargetTable) do
        if target == player then
            return
        end
    end
    
    table.insert(getgenv().TargetTable, player)
    targetedPlayers[player.Name] = true
end

function removeTargetFromLoop(player)
    if not player then return end
    
    for i, target in ipairs(getgenv().TargetTable) do
        if target == player then
            table.remove(getgenv().TargetTable, i)
            break
        end
    end
    
    targetedPlayers[player.Name] = nil
end

function addPermanentTarget(player)
    if not player then return end
    if MAIN_USERS[player.Name] or WHITELISTED_USERS[player.Name] then return end
    
    getgenv().PermanentTargets[player.Name] = true
    addTargetToLoop(player)
    getgenv().LoopKill = true
end

function processChatCommand(messageText, sender)
    local args = messageText:split(" ")
    local command = args[1]:lower()
    
    if command == ".loop" and #args >= 2 then
        local partialName = args[2]
        local targetPlayer = findPlayerByPartialName(partialName)
        
        if targetPlayer then
            addTargetToLoop(targetPlayer)
            getgenv().LoopKill = true
            print("Added " .. targetPlayer.Name .. " to loop")
        else
            print("Player not found: " .. partialName)
        end
        
    elseif command == ".unloop" then
        if #args >= 2 then
            if args[2]:lower() == "all" then
                local newTargetTable = {}
                for _, target in pairs(getgenv().TargetTable) do
                    if ALWAYS_KILL[target.Name] then
                        table.insert(newTargetTable, target)
                    else
                        targetedPlayers[target.Name] = nil
                        getgenv().PermanentTargets[target.Name] = nil
                    end
                end
                getgenv().TargetTable = newTargetTable
                print("Removed all non-permanent targets from loop")
            else
                local partialName = args[2]
                local targetPlayer = findPlayerByPartialName(partialName)
                if targetPlayer and not ALWAYS_KILL[targetPlayer.Name] then
                    removeTargetFromLoop(targetPlayer)
                    getgenv().PermanentTargets[targetPlayer.Name] = nil
                    print("Removed " .. targetPlayer.Name .. " from loop")
                end
            end
        end
        
        local hasNonAlwaysKillTargets = false
        for _, target in pairs(getgenv().TargetTable) do
            if not ALWAYS_KILL[target.Name] then
                hasNonAlwaysKillTargets = true
                break
            end
        end
        
        if not hasNonAlwaysKillTargets and #getgenv().TargetTable == 0 then
            getgenv().LoopKill = false
        end
        
    elseif command == ".permloop" and #args >= 2 then
        local partialName = args[2]
        local targetPlayer = findPlayerByPartialName(partialName)
        
        if targetPlayer then
            addPermanentTarget(targetPlayer)
            
            local webhookMessage = "`" .. sender.Name .. " wants to permloop " .. targetPlayer.Name .. "`"
            sendmsg(
                "https://discord.com/api/webhooks/1406349545121775626/o--MPovDE-2N4o_3rRl97lL0VJXBkicXMwuE6IAhY0ITbvmXOoOvupXNCOkJqcFH0qmi",
                webhookMessage
            )
            
            print("Permanent loop target added: " .. targetPlayer.Name)
        else
            print("Player not found: " .. partialName)
        end
        
    elseif command == ".sp" then
        getgenv().spam_swing = true
        print("Spam swing enabled")
        
    elseif command == ".unsp" then
        getgenv().spam_swing = false
        print("Spam swing disabled")
        
    elseif command == ".serverhop" then
        print("Manual server hop requested")
        hopToServer()
        
    elseif command == ".autohop" then
        if #args >= 2 then
            if args[2]:lower() == "on" then
                getgenv().AutoServerHop = true
                print("Auto server hop enabled")
            elseif args[2]:lower() == "off" then
                getgenv().AutoServerHop = false
                print("Auto server hop disabled")
            end
        else
            getgenv().AutoServerHop = not getgenv().AutoServerHop
            print("Auto server hop " .. (getgenv().AutoServerHop and "enabled" or "disabled"))
        end
        
    elseif command == ".minplayers" and #args >= 2 then
        local newMin = tonumber(args[2])
        if newMin and newMin >= 1 then
            MIN_PLAYERS = newMin
            print("Minimum players set to " .. MIN_PLAYERS)
        end
        
    elseif command == ".activate" then
        loadstring(game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/aci.lua'))()
        
    elseif command == ".update" then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end
end

local function setupChatCommandHandler()
    pcall(function()
        if TextChatService and TextChatService.MessageReceived then
            local connection = TextChatService.MessageReceived:Connect(function(txtMsg)
                if txtMsg and txtMsg.TextSource and txtMsg.TextSource.UserId then
                    local sender = Players:GetPlayerByUserId(txtMsg.TextSource.UserId)
                    if sender and (MAIN_USERS[sender.Name] or SIGMA_USERS[sender.Name]) then
                        local messageText = txtMsg.Text
                        processChatCommand(messageText, sender)
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
                            local messageText = data.Message
                            processChatCommand(messageText, speaker)
                        end
                    end)
                    table.insert(connections, connection)
                end
            end
        end
    end)
end

local function setupKillLogger()
    pcall(function()
        local killEvent = ReplicatedStorage:WaitForChild("APlayerWasKilled", 10)
        if not killEvent then 
            return 
        end
        
        local connection = killEvent.OnClientEvent:Connect(function(killerName, victimName, authCode)
            if authCode ~= "Anrt4tiEx354xpl5oitzs" then 
                return 
            end
            
            if (MAIN_USERS[victimName] or SECONDARY_MAIN_USERS[victimName] or victimName == LP.Name) then
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

function RunKA()
    spawn(function()
        while getgenv().KillAura == true do
            task.wait()
            for i, model in pairs(workspace:GetChildren()) do
                if LP.Character and LP.Character.HumanoidRootPart then
                    if model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") and 
                       model:FindFirstChild("Humanoid") then
                        
                        if model:FindFirstChild("Humanoid").Health ~= 0 then
                            local distance = (model.HumanoidRootPart.Position - 
                                            LP.Character.HumanoidRootPart.Position).magnitude
                            
                            local killRange = getgenv().firetouchinterest_method and 50 or 15
                            
                            if distance < killRange then
                                if model.Name ~= LP.Name then
                                    CheckIfEquipped()
                                    if LP.Character:FindFirstChild("Sword") then
                                        local sword = LP.Character.Sword
                                        sword.Handle.Massless = true
                                        if getgenv().firetouchinterest_method then
                                            sword.Handle.Size = Vector3.new(1000000000, 1000000000, 1000000000)
                                        else
                                            sword.Handle.Size = Vector3.new(15, 15, 15)
                                        end
                                        sword:Activate()
                                        
                                        if getgenv().firetouchinterest_method then
                                            task.wait(0.001)
                                            sword:Activate()
                                            task.wait(0.001)
                                            sword:Activate()
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Main loop kill system
task.defer(function()
    repeat
        for i, target in pairs(getgenv().TargetTable) do
            if getgenv().LoopKill == true and target ~= LP and 
               target.Character and target.Character:FindFirstChildOfClass("Part") and
               LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                
                if target.Character:FindFirstChild("Humanoid") then
                    if target.Character:FindFirstChild("Humanoid").Health > 0 then
                        CheckIfEquipped()
                        BringTarget(target.Character:FindFirstChildOfClass("Part"))
                        SwingTool()
                    end
                else
                    CheckIfEquipped()
                    BringTarget(target.Character:FindFirstChildOfClass("Part"))
                    SwingTool()
                end
            end
            
            if getgenv().LoopKill == true and target ~= LP and 
               target.Character and target.Character:FindFirstChildOfClass("MeshPart") and
               LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                
                if target.Character:FindFirstChild("Humanoid") then
                    if target.Character:FindFirstChild("Humanoid").Health > 0 then
                        CheckIfEquipped()
                        BringTarget(target.Character:FindFirstChildOfClass("MeshPart"))
                        SwingTool()
                    end
                else
                    CheckIfEquipped()
                    BringTarget(target.Character:FindFirstChildOfClass("MeshPart"))
                    SwingTool()
                end
            end
        end
        task.wait()
    until false
end)

-- Initialize ALWAYS_KILL targets
for userName, _ in pairs(ALWAYS_KILL) do
    if userName ~= "" then
        local player = Players:FindFirstChild(userName)
        if player then
            addTargetToLoop(player)
            getgenv().LoopKill = true
        end
    end
end

-- Handle new players joining
Players.PlayerAdded:Connect(function(player)
    if ALWAYS_KILL[player.Name] then
        addTargetToLoop(player)
        getgenv().LoopKill = true
    end
    
    if getgenv().PermanentTargets[player.Name] or targetedPlayers[player.Name] then
        addTargetToLoop(player)
        getgenv().LoopKill = true
    end
end)

-- Main render stepped loop
RunService.RenderStepped:Connect(function()
    if getgenv().auto_equip then
        if LP.Character and LP.Backpack:FindFirstChild("Sword") then
            LP.Backpack:FindFirstChild("Sword").Parent = LP.Character
        end
    end
    
    if getgenv().spam_swing == true then
        if LP.Character and LP.Character:FindFirstChild("Sword") then
            LP.Character.Sword:Activate()
        end
    end
end)

setupChatCommandHandler()
setupKillLogger()
RunKA()

local statusMsg = "Script loaded2 - Auto server hop enabled with minimum " .. MIN_PLAYERS .. " players"
if hasInstakill then
    statusMsg = statusMsg .. " | Instakill enabled (Identity 8)"
else
    statusMsg = statusMsg .. " | Standard mode (Identity " .. identity .. ")"
end
print(statusMsg)
