local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local targetUserId = 8556955654
local extraUsername = "e5c4qe"
local lastUsed = {fps = 0, ping = 0}

local function getFPS()
    local t = tick()
    RunService.RenderStepped:Wait()
    return math.floor(1 / (tick() - t))
end

local function getPing()
    return math.floor(localPlayer:GetNetworkPing() * 1000)
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
    if sender and (isFriendOfTarget(sender.UserId) or sender.Name == extraUsername) then
        if message.Text:lower() == ".fps" and tick() - lastUsed.fps >= 15 then
            lastUsed.fps = tick()
            TextChatService.TextChannels.RBXGeneral:SendAsync("FPS: " .. getFPS())
        elseif message.Text:lower() == ".ping" and tick() - lastUsed.ping >= 15 then
            lastUsed.ping = tick()
            TextChatService.TextChannels.RBXGeneral:SendAsync("PING: " .. getPing() .. "ms")
        end
    end
end

print("fps detect loaded")
