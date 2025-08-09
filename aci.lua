if _G.SCRIPT_PROTECTION_8556955654 then return end
_G.SCRIPT_PROTECTION_8556955654 = true

local allowedIds = {
    [8556955654] = true,
}
local allowedUsernames = {
    ["e5c4qe"] = true,
}

local lastUse = {fps = 0, ping = 0}
local cooldown = 15

local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Stats = game:GetService("Stats")

local function sendChatMessage(msg)
    TextChatService.TextChannels.RBXGeneral:SendAsync(msg)
end

TextChatService.OnIncomingMessage = function(message)
    local speaker = Players:FindFirstChild(message.TextSource and message.TextSource.Name)
    if not speaker then return end
    if not (allowedIds[speaker.UserId] or allowedUsernames[speaker.Name]) then return end

    local now = tick()
    local msg = string.lower(message.Text)

    if msg == ".fps" and now - lastUse.fps >= cooldown then
        lastUse.fps = now
        local fps = math.floor(1 / game:GetService("RunService").RenderStepped:Wait())
        sendChatMessage("FPS : " .. fps)
    elseif msg == ".ping" and now - lastUse.ping >= cooldown then
        lastUse.ping = now
        local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        sendChatMessage("PING : " .. ping)
    end
end
