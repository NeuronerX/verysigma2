-- Loop Kill Everyone Script with Friend Protection
-- Automatically activates on execution and protects friends of user ID 9260414163

-- Configuration
local PROTECTED_USER_ID = 9260414163
local shouldStop = false

-- Initialize global variables
getgenv().LoopKillAll = true -- Automatically enable on execution
getgenv().WHITELIST = {
    "e5c4qe",
    "xL1fe_r",
    "xL1v3_r",
    "xLiv3_r"
}
getgenv().ProtectedPlayers = {} -- Store friends of protected user

-- Function to get friends of the protected user
local function getFriendsOfUser(userId)
    local success, friendsInfo = pcall(function()
        return game:GetService("Players"):GetFriendsAsync(userId)
    end)
    
    if success then
        local friends = {}
        for friend in friendsInfo:GetCurrentPage() do
            table.insert(friends, friend.Username)
        end
        return friends
    else
        warn("Failed to get friends list for user ID: " .. userId)
        return {}
    end
end

-- Function to check if player should be protected
local function isPlayerProtected(player)
    -- Check if player is in whitelist
    if table.find(getgenv().WHITELIST, player.Name) then
        return true
    end
    
    -- Check if player is in protected friends list
    if table.find(getgenv().ProtectedPlayers, player.Name) then
        return true
    end
    
    -- Check if player is the local player
    if player == game.Players.LocalPlayer then
        return true
    end
    
    return false
end

-- Function to update protected players list
local function updateProtectedPlayers()
    local friends = getFriendsOfUser(PROTECTED_USER_ID)
    getgenv().ProtectedPlayers = friends
    print("Updated protected players list. Protected friends:", #friends)
    for i, friendName in pairs(friends) do
        print("Protected friend:", friendName)
    end
end

-- Utility Functions
function CheckIfEquipped()
    if not game.Players.LocalPlayer.Character:FindFirstChild("Sword") then
        if game.Players.LocalPlayer.Backpack:FindFirstChild("Sword") then
            game.Players.LocalPlayer.Backpack:FindFirstChild("Sword").Parent = game.Players.LocalPlayer.Character
        end
    end
    
    if game.Players.LocalPlayer.Character:FindFirstChild("Sword") then
        if game.Players.LocalPlayer.Character:FindFirstChild("Sword").Handle then
            game.Players.LocalPlayer.Character:FindFirstChild("Sword").Handle.Massless = true
            game.Players.LocalPlayer.Character:FindFirstChild("Sword").Handle.CanCollide = false
            game.Players.LocalPlayer.Character:FindFirstChild("Sword").Handle.Size = Vector3.new(10, 10, 10)
        end
    end
end

function BringTarget(targetPart)
    targetPart.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 1, -4)
end

function SwingTool()
    task.defer(function()
        if game.Players.LocalPlayer.Character:FindFirstChild("Sword") then
            game.Players.LocalPlayer.Character:FindFirstChild("Sword"):Activate()
        end
        task.wait(0.002)
        if game.Players.LocalPlayer.Character:FindFirstChild("Sword") then
            game.Players.LocalPlayer.Character:FindFirstChild("Sword"):Activate()
        end
    end)
end

-- Main Loop Kill Everyone Function
local function startLoopKillEveryone()
    print("Starting Loop Kill Everyone - Friends of user " .. PROTECTED_USER_ID .. " are protected!")
    
    -- Update protected players list initially
    updateProtectedPlayers()
    
    -- Update protected list every 60 seconds
    spawn(function()
        while not shouldStop do
            wait(15)
            updateProtectedPlayers()
        end
    end)
    
    -- Main loop kill logic
    task.defer(function()
        repeat
            for i, player in pairs(game.Players:GetPlayers()) do
                if getgenv().LoopKillAll == true and not isPlayerProtected(player) and 
                   player.Character and game.Players.LocalPlayer.Character and 
                   game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    
                    -- Try to target Part objects first
                    if player.Character:FindFirstChildOfClass("Part") then
                        if player.Character:FindFirstChild("Humanoid") then
                            if player.Character:FindFirstChild("Humanoid").Health > 0 then
                                CheckIfEquipped()
                                BringTarget(player.Character:FindFirstChildOfClass("Part"))
                                SwingTool()
                            end
                        else
                            CheckIfEquipped()
                            BringTarget(player.Character:FindFirstChildOfClass("Part"))
                            SwingTool()
                        end
                    end
                    
                    -- Try to target MeshPart objects if Part not found
                    if player.Character:FindFirstChildOfClass("MeshPart") then
                        if player.Character:FindFirstChild("Humanoid") then
                            if player.Character:FindFirstChild("Humanoid").Health > 0 then
                                CheckIfEquipped()
                                BringTarget(player.Character:FindFirstChildOfClass("MeshPart"))
                                SwingTool()
                            end
                        else
                            CheckIfEquipped()
                            BringTarget(player.Character:FindFirstChildOfClass("MeshPart"))
                            SwingTool()
                        end
                    end
                end
            end
            task.wait()
        until shouldStop == true
    end)
end

-- One-click kill everyone function (from original script)
local function killEveryoneOnce()
    spawn(function()
        if game.Players.LocalPlayer.Backpack:FindFirstChild("Sword") then
            game.Players.LocalPlayer.Backpack:FindFirstChild("Sword").Parent = game.Players.LocalPlayer.Character
        end
        
        local sword = game.Players.LocalPlayer.Character:WaitForChild("Sword")
        sword.Handle.Size = Vector3.new(1000000000, 1000000000, 1000000000)
        sword.Handle.Massless = true
        
        sword:Activate()
        wait(0.05)
        sword:Activate()
        wait(0.05)
        sword:Activate()
        wait(0.05)
        
        sword.Handle.Size = Vector3.new(4, 4, 4)
    end)
end

-- Control functions
local function stopLoopKill()
    getgenv().LoopKillAll = false
    shouldStop = true
    print("Loop Kill Everyone stopped")
end

local function startLoopKill()
    getgenv().LoopKillAll = true
    shouldStop = false
    startLoopKillEveryone()
end

-- Auto-execute when script runs
print("Auto-executing Loop Kill Everyone with friend protection...")
startLoopKillEveryone()

-- Expose control functions globally for manual control if needed
getgenv().stopLoopKill = stopLoopKill
getgenv().startLoopKill = startLoopKill
getgenv().killEveryoneOnce = killEveryoneOnce
getgenv().updateProtectedPlayers = updateProtectedPlayers

print("Script loaded! Loop Kill Everyone is now active.")
print("Protected user ID:", PROTECTED_USER_ID)
print("Use getgenv().stopLoopKill() to stop or getgenv().startLoopKill() to restart")
print("Use getgenv().killEveryoneOnce() for one-time mass kill")
print("Use getgenv().updateProtectedPlayers() to refresh friends list")
