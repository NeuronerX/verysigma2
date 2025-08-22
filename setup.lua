local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

local function autoEquip()
    for _, tool in ipairs(localPlayer.Backpack:GetChildren()) do
        if tool.Name == "Sword" and tool:IsA("Tool") then
            tool.Parent = localPlayer.Character
        end
    end
end

local function swordSoundSpam(duration)
    local startTime = tick()
    while tick() - startTime < duration do
        -- Unequip all tools
        for _, tool in pairs(localPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Parent = localPlayer.Backpack
            end
        end

        -- Re-equip all tools
        for _, tool in pairs(localPlayer.Backpack:GetChildren()) do
            tool.Parent = localPlayer.Character
        end

        task.wait(0.01)
    end
end

local function removeAnimations(character)
    local humanoid = character:WaitForChild("Humanoid")

    -- remove Animator instantly (replicates, so others don’t see animations)
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        animator:Destroy()
    end

    -- stop any currently playing animations (local + replicated)
    for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
        track:Stop()
    end

    -- block new animators from being added
    humanoid.ChildAdded:Connect(function(child)
        if child:IsA("Animator") then
            task.wait()
            child:Destroy()
        end
    end)

    -- block animations locally (you won't see them either)
    humanoid.AnimationPlayed:Connect(function(track)
        track:Stop()
    end)
end

local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")

    -- Sword spam on death
    humanoid.Died:Connect(function()
        swordSoundSpam(0.1)
    end)

    -- Sword spam + remove animations instantly on respawn
    task.spawn(function()
        removeAnimations(character)
        swordSoundSpam(0.2)
    end)
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)

if localPlayer.Character then
    onCharacterAdded(localPlayer.Character)
end

RunService.Stepped:Connect(autoEquip)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local randomX, randomY, randomZ

local function pickRandomLocation()
    randomX = math.random(0, 1800)
    randomY = math.random(3000, 6000)
    randomZ = math.random(0, 2500)
end

local function teleportLoop(character)
    if not character then return end
    local hrp = character:WaitForChild("HumanoidRootPart")

    while character.Parent do
        hrp.CFrame = CFrame.new(randomX, randomY, randomZ)
        hrp.AssemblyLinearVelocity = Vector3.zero
        RunService.Heartbeat:Wait() -- fastest safe loop
    end
end

local function onCharacterAdded(character)
    pickRandomLocation()
    task.spawn(function()
        teleportLoop(character)
    end)

    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        pickRandomLocation() -- new location on death
    end)
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)

if localPlayer.Character then
    onCharacterAdded(localPlayer.Character)
end

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local function deleteGui()
    local playerGui = localPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui.Name == "MobileShiftLockSupport" or gui:IsA("ScreenGui") then
            gui:Destroy()
        end
    end
end

-- Run once immediately
deleteGui()

-- Watch for new GUIs being added
localPlayer.PlayerGui.ChildAdded:Connect(function(child)
    task.wait(0.1)
    deleteGui()
end)


local Workspace = game:GetService("Workspace")
Workspace.BaseBlock:Destroy()
for _, obj in ipairs(Workspace:GetChildren()) do
    if obj:IsA("BasePart") and (obj.Name == "Kill" or obj.Name == "Part") then
        obj:Destroy()
    end
end

local StarterGui = game:GetService("StarterGui")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local targetQuality = Enum.QualityLevel.Level01

for _, obj in ipairs(Lighting:GetChildren()) do
    if obj:IsA("Sky") then
        obj:Destroy()
    end
end

local function enforceGraphics()
    if settings().Rendering.QualityLevel ~= targetQuality then
        settings().Rendering.QualityLevel = targetQuality
    end
end

RunService.RenderStepped:Connect(enforceGraphics)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local GC = getconnections or get_signal_cons
if GC then
    for _, v in pairs(GC(LocalPlayer.Idled)) do
        if v.Disable then
            v:Disable()
        elseif v.Disconnect then
            v:Disconnect()
        end
    end
else
    local VirtualUser = cloneref(game:GetService("VirtualUser"))
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

-- Connect to the Idled event
Players.LocalPlayer.Idled:Connect(function()
    -- Simulate a harmless input to prevent AFK kick
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0,0))
end)
