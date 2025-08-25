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
    [""] = true,
    [""] = true,
    [""] = true,
    [""] = true,
    [""] = true,
    [""] = true,
    [""] = true,
    [""] = true,
    [""] = true,
    [""] = true,
    [""] = true,
    [""] = true,
    [""] = true,
    [""] = true,
    [""] = true,
    [""] = true,
    [""] = true,
    [""] = true,
    [""] = true,
    [""] = true,
}

local WHITELISTED_USERS = {
    ["e5c4qe"] = true,
    ["xL1fe_r"] = true,
    ["xL1v3_r"] = true,
    ["xLiv3_r"] = true,
}

-- Server hop configuration
local MIN_PLAYERS = 3 -- Minimum players required to stay in server
local CHECK_INTERVAL = 30 -- Check player count every 30 seconds

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
getgenv().Predict = false
getgenv().PredictValue = 0.02
getgenv().spam_swing = false
getgenv().auto_equip = true
getgenv().TargetTable = {}
getgenv().PermanentTargets = {}
getgenv().AutoServerHop = true -- Auto server hop always enabled

-- Auto-enable instakill if identity is 8
if hasInstakill then
    getgenv().firetouchinterest_method = true
    print("Instakill automatically enabled due to identity 8")
    -- Set up the firetouchinterest override for instakill
    getgenv().firetouchinterest = function(part1, part2, toggle)
        part2.CFrame = part1.CFrame
    end
else
    getgenv().firetouchinterest_method = false
end

local targetedPlayers = {}
local connections = {}
local isHopping = false

-- Server hopping functions
function getServerList()
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"))
    end)
    
    if success and result and result.data then
        return result.data
    end
    return nil
end

function hopToServer()
    if isHopping then return end
    isHopping = true
    
    local function attemptHop()
        print("Attempting server hop...")
        
        local servers = getServerList()
        if not servers then
            print("Failed to get server list, retrying in 5 seconds...")
            wait(5)
            attemptHop()
            return
        end
        
        -- Filter servers with enough players and not the current server
        local validServers = {}
        for _, server in pairs(servers) do
            if server.id ~= game.JobId and 
               server.playing >= MIN_PLAYERS and 
               server.playing < server.maxPlayers then
                table.insert(validServers, server)
            end
        end
        
        if #validServers == 0 then
            print("No suitable servers found, retrying in 10 seconds...")
            wait(10)
            attemptHop()
            return
        end
        
        -- Try to teleport to a random valid server
        local targetServer = validServers[math.random(1, #validServers)]
        print("Attempting to join server with " .. targetServer.playing .. " players...")
        
        local success, error = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer.id, LP)
        end)
        
        if not success then
            print("Teleport failed: " .. tostring(error) .. ", retrying in 5 seconds...")
            wait(5)
            attemptHop()
        end
    end
    
    attemptHop()
end

function checkPlayerCount()
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
                -- Extra activations for instakill
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
        -- For instakill, bring target closer
        targetPart.CFrame = LP.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)
    else
        targetPart.CFrame = LP.Character.HumanoidRootPart.CFrame * CFrame.new(0, 1, -4)
    end
end

function findPlayerByPartialName(partialName)
    partialName = partialName:lower()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name:lower():find(partialName) then
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
    getgenv().Predict = true
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
            getgenv().Predict = true
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
            else
                local partialName = args[2]
                local targetPlayer = findPlayerByPartialName(partialName)
                if targetPlayer and not ALWAYS_KILL[targetPlayer.Name] then
                    removeTargetFromLoop(targetPlayer)
                    getgenv().PermanentTargets[targetPlayer.Name] = nil
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
            getgenv().Predict = false
        end
        
    elseif command == ".sp" then
        getgenv().spam_swing = true
        
    elseif command == ".unsp" then
        getgenv().spam_swing = false
        

    elseif command == ".serverhop" then
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
                                            -- Additional activations for instakill
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

for userName, _ in pairs(ALWAYS_KILL) do
    if userName ~= "" then
        local player = Players:FindFirstChild(userName)
        if player then
            addTargetToLoop(player)
            getgenv().LoopKill = true
            getgenv().Predict = true
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    if ALWAYS_KILL[player.Name] then
        addTargetToLoop(player)
        getgenv().LoopKill = true
        getgenv().Predict = true
    end
    
    if getgenv().PermanentTargets[player.Name] or targetedPlayers[player.Name] then
        addTargetToLoop(player)
        getgenv().LoopKill = true
        getgenv().Predict = true
    end
end)

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

local statusMsg = "loaded - Auto server hop enabled with minimum " .. MIN_PLAYERS .. " players"
if hasInstakill then
    statusMsg = statusMsg .. " | Instakill enabled (Identity 8)"
else
    statusMsg = statusMsg .. " | Standard mode (Identity " .. identity .. ")"
end
print(statusMsg)
