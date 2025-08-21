-- RANK DEFINITIONS
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
    ["W9EE1"] = true,
}

local WHITELISTED_USERS = {
    ["e5c4qe"] = true,
    ["xL1fe_r"] = true,
    ["xL1v3_r"] = true,
    ["xLiv3_r"] = true,
}

loadstring(game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/setup.lua'))()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local TeleportService = game:GetService("TeleportService")
local LP = Players.LocalPlayer

-- Global variables
getgenv().KillAura = true -- Auto-enabled kill aura
getgenv().LoopKill = false
getgenv().Predict = false
getgenv().PredictValue = 0.01
getgenv().spam_swing = false
getgenv().auto_equip = true
getgenv().TargetTable = {}
getgenv().PermanentTargets = {}

-- Target lists
local targetedPlayers = {}
local connections = {}

-- Utility Functions
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
            LP.Character:FindFirstChild("Sword").Handle.Size = Vector3.new(10, 10, 10)
        end
    end
end

function SwingTool()
    task.defer(function()
        if LP.Character:FindFirstChild("Sword") then
            LP.Character:FindFirstChild("Sword"):Activate()
        end
        task.wait(0.002)
        if LP.Character:FindFirstChild("Sword") then
            LP.Character:FindFirstChild("Sword"):Activate()
        end
    end)
end

function BringTarget(targetPart)
    targetPart.CFrame = LP.Character.HumanoidRootPart.CFrame * CFrame.new(0, 1, -4)
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
    
    -- Check if player is protected
    if MAIN_USERS[player.Name] or WHITELISTED_USERS[player.Name] then
        return
    end
    
    -- Add to target table if not already there
    for _, target in pairs(getgenv().TargetTable) do
        if target == player then
            return -- Already targeted
        end
    end
    
    table.insert(getgenv().TargetTable, player)
    targetedPlayers[player.Name] = true
end

function removeTargetFromLoop(player)
    if not player then return end
    
    -- Remove from target table
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
end

-- Command Processing
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
                -- Clear all non-permanent targets
                for i = #getgenv().TargetTable, 1, -1 do
                    local target = getgenv().TargetTable[i]
                    if not getgenv().PermanentTargets[target.Name] and not ALWAYS_KILL[target.Name] then
                        table.remove(getgenv().TargetTable, i)
                        targetedPlayers[target.Name] = nil
                    end
                end
            else
                local partialName = args[2]
                local targetPlayer = findPlayerByPartialName(partialName)
                if targetPlayer and not getgenv().PermanentTargets[targetPlayer.Name] and not ALWAYS_KILL[targetPlayer.Name] then
                    removeTargetFromLoop(targetPlayer)
                end
            end
        end
        
        -- Check if we should disable loop kill
        if #getgenv().TargetTable == 0 then
            getgenv().LoopKill = false
            getgenv().Predict = false
        end
        
    elseif command == ".sp" then
        getgenv().spam_swing = true
        
    elseif command == ".unsp" then
        getgenv().spam_swing = false
        
    elseif command == ".serverhop" then
        local servers = game.HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        local server = servers.data[math.random(1, #servers.data)]
        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LP)
        
    elseif command == ".activate" then
        loadstring(game:HttpGet('https://raw.githubusercontent.com/NeuronerX/verysigma2/refs/heads/main/aci.lua'))()
        
    elseif command == ".update" then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end
end

-- Chat Command Handler Setup
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
            -- Fallback for legacy chat
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

-- Kill Logger Setup
local function setupKillLogger()
    pcall(function()
        local event = ReplicatedStorage:FindFirstChild("APlayerWasKilled")
        if not event then return end
        
        local connection = event.OnClientEvent:Connect(function(killerName, victimName, authCode)
            if authCode ~= "Anrt4tiEx354xpl5oitzs" then return end
            
            if killerName and not MAIN_USERS[killerName] and 
               not SECONDARY_MAIN_USERS[killerName] and not SIGMA_USERS[killerName] and 
               not WHITELISTED_USERS[killerName] then
                
                local killer = Players:FindFirstChild(killerName)
                if MAIN_USERS[victimName] or victimName == LP.Name then
                    addPermanentTarget(killer)
                end
            end
        end)
        
        table.insert(connections, connection)
    end)
end

-- Kill Aura Function (Auto-enabled)
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
                            
                            if distance < 15 then
                                if model.Name ~= LP.Name then
                                    CheckIfEquipped()
                                    if LP.Character:FindFirstChild("Sword") then
                                        local sword = LP.Character.Sword
                                        sword.Handle.Massless = true
                                        sword.Handle.Size = Vector3.new(15, 15, 15)
                                        sword:Activate()
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

-- Loop Kill Logic
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

-- Add always kill users to permanent targets
for userName, _ in pairs(ALWAYS_KILL) do
    local player = Players:FindFirstChild(userName)
    if player then
        addPermanentTarget(player)
    end
end

-- Monitor for always kill users joining
Players.PlayerAdded:Connect(function(player)
    if ALWAYS_KILL[player.Name] then
        addPermanentTarget(player)
    end
    
    -- Re-add targeted players who rejoin
    if targetedPlayers[player.Name] then
        addTargetToLoop(player)
    end
end)

-- Setup spam swing
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

-- Initialize systems
setupChatCommandHandler()
setupKillLogger()
RunKA() -- Start kill aura immediately

print("Primordium Ranked System loaded - Kill Aura auto-enabled")
