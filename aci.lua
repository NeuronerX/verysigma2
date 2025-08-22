-- Loop Kill Everyone Script with Friend Protection (FIXED)
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
    "xLiv3_r",
    "Oliv3rTig3r2008"
}
getgenv().ProtectedPlayers = {} -- Store friends of protected user

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Function to get friends of the protected user (FIXED)
local function getFriendsOfUser(userId)
    local success, result = pcall(function()
        local friendPages = Players:GetFriendsAsync(userId)
        local friends = {}
        
        while true do
            local currentPage = friendPages:GetCurrentPage()
            for _, friend in pairs(currentPage) do
                table.insert(friends, friend.Username)
            end
            
            if friendPages.IsFinished then
                break
            end
            friendPages:AdvanceToNextPageAsync()
        end
        
        return friends
    end)
    
    if success then
        return result
    else
        warn("Failed to get friends list for user ID: " .. userId)
        return {}
    end
end

-- Function to check if player should be protected
local function isPlayerProtected(player)
    -- Check if player is the local player (ALWAYS PROTECT SELF)
    if player == Players.LocalPlayer then
        return true
    end
    
    -- Check if player is in whitelist (ALWAYS PROTECT WHITELIST)
    for _, whitelistedName in pairs(getgenv().WHITELIST) do
        if player.Name == whitelistedName then
            return true
        end
    end
    
    -- Check if player is in protected friends list (ALWAYS PROTECT FRIENDS)
    for _, friendName in pairs(getgenv().ProtectedPlayers) do
        if player.Name == friendName then
            return true
        end
    end
    
    return false
end

-- Function to update protected players list (FIXED)
local function updateProtectedPlayers()
    spawn(function()
        local success, friends = pcall(function()
            return getFriendsOfUser(PROTECTED_USER_ID)
        end)
        
        if success then
            getgenv().ProtectedPlayers = friends
        end
    end)
end

-- Utility Functions
function CheckIfEquipped()
    local character = Players.LocalPlayer.Character
    if not character then return end
    
    if not character:FindFirstChild("Sword") then
        local backpack = Players.LocalPlayer.Backpack
        local sword = backpack:FindFirstChild("Sword")
        if sword then
            sword.Parent = character
        end
    end
    
    local sword = character:FindFirstChild("Sword")
    if sword and sword:FindFirstChild("Handle") then
        sword.Handle.Massless = true
        sword.Handle.CanCollide = false
        sword.Handle.Size = Vector3.new(10, 10, 10)
    end
end

function BringTarget(targetPart)
    if Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        targetPart.CFrame = Players.LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 1, -4)
    end
end

function SwingTool()
    spawn(function()
        local character = Players.LocalPlayer.Character
        if character then
            local sword = character:FindFirstChild("Sword")
            if sword then
                sword:Activate()
                wait(0.002)
                sword:Activate()
            end
        end
    end)
end

-- Chat command processing removed - script runs continuously

-- Main Loop Kill Everyone Function (FIXED)
local function startLoopKillEveryone()
    -- Update protected players list initially
    updateProtectedPlayers()
    
    -- Update protected list every 15 seconds - runs indefinitely
    spawn(function()
        while true do
            wait(15)
            updateProtectedPlayers()
        end
    end)
    
    -- Main loop kill logic - runs indefinitely
    spawn(function()
        while true do
            if getgenv().LoopKillAll then
                for _, player in pairs(Players:GetPlayers()) do
                    -- DOUBLE CHECK - Skip if player is protected
                    if isPlayerProtected(player) then
                        continue -- Skip this player entirely
                    end
                    
                    -- Only target non-protected players
                    if player.Character and 
                       Players.LocalPlayer.Character and 
                       Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        
                        -- Try to target Part objects first
                        local targetPart = player.Character:FindFirstChildOfClass("Part")
                        if targetPart then
                            local humanoid = player.Character:FindFirstChild("Humanoid")
                            if not humanoid or humanoid.Health > 0 then
                                CheckIfEquipped()
                                BringTarget(targetPart)
                                SwingTool()
                            end
                        else
                            -- Try to target MeshPart objects if Part not found
                            local meshPart = player.Character:FindFirstChildOfClass("MeshPart")
                            if meshPart then
                                local humanoid = player.Character:FindFirstChild("Humanoid")
                                if not humanoid or humanoid.Health > 0 then
                                    CheckIfEquipped()
                                    BringTarget(meshPart)
                                    SwingTool()
                                end
                            end
                        end
                    end
                end
            end
            wait(0.1) -- Small delay to prevent lag
        end
    end)
end

-- One-click kill everyone function (PROTECTS WHITELIST AND FRIENDS)
function killEveryoneOnce()
    spawn(function()
        local character = Players.LocalPlayer.Character
        local backpack = Players.LocalPlayer.Backpack
        
        if backpack:FindFirstChild("Sword") then
            backpack:FindFirstChild("Sword").Parent = character
        end
        
        if character then
            local sword = character:WaitForChild("Sword", 5)
            if sword and sword:FindFirstChild("Handle") then
                -- Store original size
                local originalSize = sword.Handle.Size
                
                -- Make sword massive
                sword.Handle.Size = Vector3.new(1000000000, 1000000000, 1000000000)
                sword.Handle.Massless = true
                
                sword:Activate()
                wait(0.05)
                sword:Activate()
                wait(0.05)
                sword:Activate()
                wait(0.05)
                
                -- Restore original size
                sword.Handle.Size = originalSize
            end
        end
    end)
end

-- Control functions removed - script runs continuously once started

-- Auto-execute when script runs
startLoopKillEveryone()

-- Expose essential functions globally
getgenv().killEveryoneOnce = killEveryoneOnce
getgenv().updateProtectedPlayers = updateProtectedPlayers
