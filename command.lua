local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local targetUserId = 9260414163
local extraUsername = "e5c4qe"
local lastUsed = {fps = 0, ping = 0}

-- Smoothed FPS calculation
local frameTimes = {}
local maxSamples = 60

RunService.RenderStepped:Connect(function(dt)
    table.insert(frameTimes, dt)
    if #frameTimes > maxSamples then
        table.remove(frameTimes, 1)
    end
end)

local function getFPS()
    if #frameTimes == 0 then return 0 end
    local total = 0
    for _, dt in ipairs(frameTimes) do
        total = total + dt
    end
    local avgDt = total / #frameTimes
    return math.floor(1 / avgDt)
end

local function getPing()
    local rawPing = localPlayer:GetNetworkPing() * 1000
    local ping = math.floor(rawPing)

    if ping > 55 then
        return ping
    elseif ping < 5 then
        return math.random(3, 6)
    elseif ping > 10 then
        return math.random(10,12)
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

-- Using new callback style
TextChatService.OnIncomingMessage = function(message)
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
end

print("FPS detect loaded (smoothed)")
