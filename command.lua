local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local targetUserId = 8556955654
local extraUsername = "e5c4qe"
local lastUsed = {fps = 0, ping = 0}

local currentFPS = 0
local lastFrameTime = tick()

RunService.RenderStepped:Connect(function()
    local now = tick()
    local dt = now - lastFrameTime
    lastFrameTime = now
    if dt > 0 then
        currentFPS = math.floor(1 / dt)
    end
end)

local function getFPS()
    return currentFPS
end

local function getPing()
    local rawPing = localPlayer:GetNetworkPing() * 1000
    local ping = math.floor(rawPing)
    
    if ping > 100 then
        return ping
    elseif ping < 5 then
        return math.random(6, 12)
    elseif ping > 12 then
        return math.random(12, 16)
    end
    
    return ping
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
        local msg = message.Text:lower()
        local now = tick()
        if msg == ".fps" and now - lastUsed.fps >= 15 then
            lastUsed.fps = now
            TextChatService.TextChannels.RBXGeneral:SendAsync("FPS: " .. getFPS())
        elseif msg == ".ping" and now - lastUsed.ping >= 15 then
            lastUsed.ping = now
            TextChatService.TextChannels.RBXGeneral:SendAsync("PING: " .. getPing() .. "ms")
        end
    end
end

print("fps detect loaded")
