local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local targetUserId = 8556955654
local lastUsed = 0

local function getFPS()
    local t = tick()
    RunService.RenderStepped:Wait()
    return math.floor(1 / (tick() - t))
end

local function isFriendOfTarget(userId)
    local success, friendsPages = pcall(function()
        return Players:GetFriendsAsync(targetUserId)
    end)
    if success then
        for _, friendData in ipairs(friendsPages:GetCurrentPage()) do
            if friendData.Id == userId then
                return true
            end
        end
    end
    return false
end

TextChatService.OnIncomingMessage = function(message)
    local sender = Players:FindFirstChild(message.TextSource and message.TextSource.Name)
    if sender and message.Text == ".fps" then
        if isFriendOfTarget(sender.UserId) and tick() - lastUsed >= 15 then
            lastUsed = tick()
            TextChatService.TextChannels.RBXGeneral:SendAsync("Current FPS: " .. getFPS())
        end
    end
end
