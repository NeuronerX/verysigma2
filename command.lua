local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local targetUserId = 8556955654
local extraUsername = "e5c4qe"
local lastUsed = {fps = 0, ping = 0}

local currentFPS = 0
local lastFrameTime = tick()

-- FPS calculation
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

    if ping > 55 then
        return ping
    elseif ping < 5 then
        return math.random(6, 9)
    elseif ping > 10 then
        return math.random(10, 13)
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

-- Wait until RBXGeneral exists
local function getChannel(name)
    local channel = TextChatService.TextChannels:FindFirstChild(name)
    while not channel do
        TextChatService.TextChannels.ChildAdded:Wait()
        channel = TextChatService.TextChannels:FindFirstChild(name)
    end
    return channel
end

local generalChannel = getChannel("RBXGeneral")

local function safeSendMessage(text)
    if generalChannel then
        pcall(function()
            generalChannel:SendAsync(text)
        end)
    end
end

-- Proper event connection
TextChatService.OnIncomingMessage:Connect(function(message)
    local source = message.TextSource
    if not source then return end

    local sender = Players:FindFirstChild(source.Name)
    if sender and (isFriendOfTarget(sender.UserId) or sender.Name == extraUsername) then
        local msg = message.Text:lower()
        local now = tick()

        if msg == ".fps" and now - lastUsed.fps >= 15 then
            lastUsed.fps = now
            safeSendMessage("FPS: " .. getFPS())
        elseif msg == ".ping" and now - lastUsed.ping >= 15 then
            lastUsed.ping = now
            safeSendMessage("PING: " .. getPing() .. "ms")
        end
    end
end)

print("fps detect loaded (new TextChatService safe)")
