if game.PlaceId ~= 6110766473 then return end

local identity = getidentity()
local hasInstakill = identity == 8

local MAIN_USERS = {
    ["Pyan_x3v"] = true, ["Pyan_x2v"] = true, ["Pyan_x0v"] = true, ["Pyan_x1v"] = true,
    ["Oliv3rTig3r2008"] = true, ["SebastianBuilder83"] = true, ["nagiconfi209"] = true,
    ["FlexFightPro68"] = true, ["Iamnotrealyblack"] = true,
}

local SIGMA_USERS = {
    ["FlexFightPro68"] = true, ["Iamnotrealyblack"] = true, ["e5c4qe"] = true,
}

local SECONDARY_MAIN_USERS = {["sssssss"] = true}

local ALWAYS_KILL = {
    ["kurwuwA"] = true, ["GoatReflex"] = true, ["vreckotygecko"] = true, ["fdngdfngjdfgndf"] = true,
}

local WHITELISTED_USERS = {
    ["e5c4qe"] = true, ["xL1fe_r"] = true, ["xL1v3_r"] = true, ["xLiv3_r"] = true,
}

local MIN_PLAYERS = 3
local CHECK_INTERVAL = 30

sendmsg = function(url, message)
    (http_request or request or HttpPost or syn.request)({
        Url = url,
        Body = game:GetService("HttpService"):JSONEncode({["content"] = message}),
        Method = "POST",
        Headers = {["content-type"] = "application/json"}
    })
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
getgenv().Predict = false
getgenv().PredictValue = 0.02
getgenv().spam_swing = false
getgenv().auto_equip = true
getgenv().TargetTable = {}
getgenv().PermanentTargets = {}
getgenv().AutoServerHop = true

if hasInstakill then
    getgenv().firetouchinterest_method = true
    getgenv().firetouchinterest = function(part1, part2, toggle)
        part2.CFrame = part1.CFrame
    end
else
    getgenv().firetouchinterest_method = false
end

local targetedPlayers = {}
local connections = {}
local isHopping = false

function getServerList()
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"))
    end)
    return success and result and result.data
end

function hopToServer()
    if isHopping then return end
    isHopping = true
    
    local function attemptHop()
        local servers = getServerList()
        if not servers then
            task.wait(5)
            attemptHop()
            return
        end
        
        local validServers = {}
        for _, server in pairs(servers) do
            if server.id ~= game.JobId and server.playing >= MIN_PLAYERS and server.playing < server.maxPlayers then
                table.insert(validServers, server)
            end
        end
        
        if #validServers == 0 then
            task.wait(10)
            attemptHop()
            return
        end
        
        local targetServer = validServers[math.random(1, #validServers)]
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer.id, LP)
        end)
        
        task.wait(5)
        attemptHop()
    end
    
    attemptHop()
end

function checkPlayerCount()
    if getgenv().AutoServerHop and #Players:GetPlayers() < MIN_PLAYERS then
        hopToServer()
    end
end

task.spawn(function()
    while true do
        if not isHopping then checkPlayerCount() end
        task.wait(CHECK_INTERVAL)
    end
end)

local sword_cache
function CheckIfEquipped()
    if not LP.Character then return end
    
    sword_cache = LP.Character:FindFirstChild("Sword")
    if not sword_cache then
        sword_cache = LP.Backpack:FindFirstChild("Sword")
        if sword_cache then
            sword_cache.Parent = LP.Character
        else
            return
        end
    end
    
    local handle = sword_cache.Handle
    if handle then
        handle.Massless = true
        handle.CanCollide = false
        handle.Size = getgenv().firetouchinterest_method and 
            Vector3.new(1000000000, 1000000000, 1000000000) or 
            Vector3.new(15, 15, 15)
    end
end

function SwingTool()
    if sword_cache then
        sword_cache:Activate()
        if getgenv().firetouchinterest_method then
            sword_cache:Activate()
            sword_cache:Activate()
        end
    end
end

function BringTarget(targetPart)
    if LP.Character and LP.Character.HumanoidRootPart then
        targetPart.CFrame = LP.Character.HumanoidRootPart.CFrame * 
            (getgenv().firetouchinterest_method and CFrame.new(0, 0, -2) or CFrame.new(0, 1, -4))
    end
end

function findPlayerByPartialName(partialName)
    partialName = partialName:lower()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name:lower():find(partialName) then
            return player
        end
    end
end

function addTargetToLoop(player)
    if not player or MAIN_USERS[player.Name] or WHITELISTED_USERS[player.Name] then return end
    
    for _, target in pairs(getgenv().TargetTable) do
        if target == player then return end
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
    if not player or MAIN_USERS[player.Name] or WHITELISTED_USERS[player.Name] then return end
    
    getgenv().PermanentTargets[player.Name] = true
    addTargetToLoop(player)
    getgenv().LoopKill = true
    getgenv().Predict = true
end

function processChatCommand(messageText, sender)
    local args = messageText:split(" ")
    local command = args[1]:lower()
    
    if command == ".loop" and #args >= 2 then
        local targetPlayer = findPlayerByPartialName(args[2])
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
                local targetPlayer = findPlayerByPartialName(args[2])
                if targetPlayer and not ALWAYS_KILL[targetPlayer.Name] then
                    removeTargetFromLoop(targetPlayer)
                    getgenv().PermanentTargets[targetPlayer.Name] = nil
                end
            end
        end
        
        local hasTargets = false
        for _, target in pairs(getgenv().TargetTable) do
            if not ALWAYS_KILL[target.Name] then
                hasTargets = true
                break
            end
        end
        
        if not hasTargets and #getgenv().TargetTable == 0 then
            getgenv().LoopKill = false
            getgenv().Predict = false
        end
        
    elseif command == ".permloop" and #args >= 2 then
        local targetPlayer = findPlayerByPartialName(args[2])
        if targetPlayer then
            addPermanentTarget(targetPlayer)
            sendmsg(
                "https://discord.com/api/webhooks/1406349545121775626/o--MPovDE-2N4o_3rRl97lL0VJXBkicXMwuE6IAhY0ITbvmXOoOvupXNCOkJqcFH0qmi",
                "`" .. sender.Name .. " wants to permloop " .. targetPlayer.Name .. "`"
            )
        end
        
    elseif command == ".sp" then
        getgenv().spam_swing = true
    elseif command == ".unsp" then
        getgenv().spam_swing = false
    elseif command == ".serverhop" then
        hopToServer()
    elseif command == ".autohop" then
        if #args >= 2 then
            getgenv().AutoServerHop = args[2]:lower() == "on"
        else
            getgenv().AutoServerHop = not getgenv().AutoServerHop
        end
    elseif command == ".minplayers" and #args >= 2 then
        local newMin = tonumber(args[2])
        if newMin and newMin >= 1 then MIN_PLAYERS = newMin end
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

local function setupKillLogger()
    pcall(function()
        local killEvent = ReplicatedStorage:WaitForChild("APlayerWasKilled", 10)
        if killEvent then
            local connection = killEvent.OnClientEvent:Connect(function(killerName, victimName, authCode)
                if authCode == "Anrt4tiEx354xpl5oitzs" and (MAIN_USERS[victimName] or SECONDARY_MAIN_USERS[victimName] or victimName == LP.Name) then
                    if killerName and killerName ~= "" and not MAIN_USERS[killerName] and not SECONDARY_MAIN_USERS[killerName] and not SIGMA_USERS[killerName] and not WHITELISTED_USERS[killerName] then
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
        end
    end)
end

function RunKA()
    task.spawn(function()
        while getgenv().KillAura do
            if LP.Character and LP.Character.HumanoidRootPart then
                local myPos = LP.Character.HumanoidRootPart.Position
                local killRange = getgenv().firetouchinterest_method and 50 or 20
                
                for _, model in pairs(workspace:GetChildren()) do
                    if model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") and model:FindFirstChild("Humanoid") and model.Name ~= LP.Name then
                        local humanoid = model:FindFirstChild("Humanoid")
                        if humanoid.Health > 0 then
                            local distance = (model.HumanoidRootPart.Position - myPos).Magnitude
                            if distance < killRange then
                                CheckIfEquipped()
                                if sword_cache then
                                    sword_cache:Activate()
                                    if getgenv().firetouchinterest_method then
                                        sword_cache:Activate()
                                        sword_cache:Activate()
                                    end
                                end
                            end
                        end
                    end
                end
            end
            task.wait()
        end
    end)
end

task.defer(function()
    while true do
        if getgenv().LoopKill and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            for _, target in pairs(getgenv().TargetTable) do
                if target ~= LP and target.Character then
                    local targetPart = target.Character:FindFirstChildOfClass("Part") or target.Character:FindFirstChildOfClass("MeshPart")
                    if targetPart then
                        local humanoid = target.Character:FindFirstChild("Humanoid")
                        if not humanoid or humanoid.Health > 0 then
                            CheckIfEquipped()
                            BringTarget(targetPart)
                            SwingTool()
                        end
                    end
                end
            end
        end
        task.wait()
    end
end)

for userName in pairs(ALWAYS_KILL) do
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
    if ALWAYS_KILL[player.Name] or getgenv().PermanentTargets[player.Name] or targetedPlayers[player.Name] then
        addTargetToLoop(player)
        getgenv().LoopKill = true
        getgenv().Predict = true
    end
end)

RunService.Heartbeat:Connect(function()
    if getgenv().auto_equip and LP.Character and LP.Backpack:FindFirstChild("Sword") and not LP.Character:FindFirstChild("Sword") then
        LP.Backpack:FindFirstChild("Sword").Parent = LP.Character
    end
    
    if getgenv().spam_swing and LP.Character and LP.Character:FindFirstChild("Sword") then
        LP.Character.Sword:Activate()
    end
end)

setupChatCommandHandler()
setupKillLogger()
RunKA()
