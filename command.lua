local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

-- SETTINGS
local AUTHORIZED_USER_ID = 8556955654 -- Main authorized user
local attackDistance = 25 

-- Original teleport positions from other script
local teleportTargets = {
    ["Cubot_Nova3"] = CFrame.new(7152,4405,4707),
    ["Cub0t_01"] = CFrame.new(7122,4505,4719),
    ["cubot_nova4"] = CFrame.new(7122,4475,4719),
    ["cubot_autoIoop"] = CFrame.new(7132,4605,4707),
    ["Cubot_Nova2"] = CFrame.new(7122,4705,4729),
    ["Cubot_Nova1"] = CFrame.new(7132,4605,4529),
}

-- Teleport numbers mapping
local TELEPORT_MAPPING = {
	[1] = "cubot_nova4",
	[2] = "Cub0t_01", 
	[3] = "Cubot_Nova3"
}

-- State variables
local protectActive = false
local protectedPlayer = nil
local teleportTarget = nil
local connections = {}
local loops = {}
local whitelist = {} -- Additional players that won't be attacked
local K = {}
local A = {}
local friendsCache = {} -- Cache for friends status
local originalTeleportPaused = false -- Track if we paused original teleport

-- Reference to the other script's teleport connection (if accessible)
local externalTeleportConnection = nil

-- Check if user is friends with authorized user
local function isFriendOfAuthorized(userId)
	-- Check cache first
	if friendsCache[userId] ~= nil then
		return friendsCache[userId]
	end
	
	-- Check friendship status
	local success, isFriend = pcall(function()
		return LP:IsFriendsWith(AUTHORIZED_USER_ID)
	end)
	
	if success then
		friendsCache[userId] = isFriend
		return isFriend
	end
	
	return false
end

-- Check if user can use commands (is authorized or friend of authorized)
local function canUseCommands()
	return LP.UserId == AUTHORIZED_USER_ID or isFriendOfAuthorized(LP.UserId)
end

-- Check if player should not be attacked
local function isSafePlayer(player)
	-- Protected player
	if protectedPlayer and player == protectedPlayer then
		return true
	end
	
	-- Whitelisted
	if whitelist[player.Name] then
		return true
	end
	
	-- Is the authorized user
	if player.UserId == AUTHORIZED_USER_ID then
		return true
	end
	
	-- Is friend of authorized user
	if isFriendOfAuthorized(player.UserId) then
		return true
	end
	
	return false
end

-- Partial name matching
local function findPlayerByPartial(partial)
	partial = partial:lower()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower():sub(1, #partial) == partial then
			return player
		end
	end
	return nil
end

-- Delete all parts named "Kill"
local function deleteKillParts()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == "Kill" then
			obj:Destroy()
		end
	end
end

-- Noclip function
local function startNoclip()
	loops.noclip = task.spawn(function()
		while protectActive do
			task.wait()
			if LP.Character then
				for _, part in ipairs(LP.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end
	end)
end

-- Stop external teleport (from other script)
local function stopExternalTeleport()
	-- Try to find and disconnect the external teleport connection
	-- This is a common pattern - look for connections in the environment
	for _, connection in pairs(getconnections(RunService.Heartbeat)) do
		local func = debug.getinfo(connection.Function)
		if func and func.source:find("teleportConnection") then
			connection:Disable()
			externalTeleportConnection = connection
			originalTeleportPaused = true
			break
		end
	end
end

-- Resume external teleport
local function resumeExternalTeleport()
	if externalTeleportConnection and originalTeleportPaused then
		externalTeleportConnection:Enable()
		originalTeleportPaused = false
	end
end

-- Protection teleport function
local function startProtectTeleport()
	-- Stop the external teleport first
	stopExternalTeleport()
	
	loops.protectTeleport = task.spawn(function()
		while protectActive and protectedPlayer and teleportTarget do
			task.wait(0.01)
			local target = Players:FindFirstChild(protectedPlayer.Name)
			local teleportUser = Players:FindFirstChild(teleportTarget)
			
			if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and
			   teleportUser and teleportUser.Character and teleportUser.Character:FindFirstChild("HumanoidRootPart") then
				local targetHRP = target.Character.HumanoidRootPart
				local teleportHRP = teleportUser.Character.HumanoidRootPart
				
				-- Teleport the specified user below the protected player
				teleportHRP.Velocity = Vector3.zero
				teleportHRP.AssemblyLinearVelocity = Vector3.zero
				local newPos = Vector3.new(targetHRP.Position.X, targetHRP.Position.Y - 10, targetHRP.Position.Z)
				teleportHRP.CFrame = CFrame.new(newPos)
			end
		end
	end)
end

-- Return player to their original teleport position
local function returnToOriginalPosition(playerName)
	local originalCFrame = teleportTargets[playerName]
	if originalCFrame then
		loops.returnTeleport = task.spawn(function()
			for i = 1, 10 do -- Run for a short time to ensure they return
				task.wait(0.1)
				local player = Players:FindFirstChild(playerName)
				if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local hrp = player.Character.HumanoidRootPart
					hrp.CFrame = originalCFrame
					hrp.AssemblyLinearVelocity = Vector3.zero
				end
			end
			
			-- Resume external teleport after returning
			resumeExternalTeleport()
		end)
	else
		-- If no original position, just resume external teleport
		resumeExternalTeleport()
	end
end

-- Combat System
local Dist = attackDistance
local DistSq = Dist * Dist
local DMG_TIMES = 2
local FT_TIMES = 5

local function CRB(x)
	if x:IsA("Tool") and x:FindFirstChild("Handle") then
		local h = x.Handle
		if not h:FindFirstChild("BoxReachPart") then
			local p = Instance.new("Part")
			p.Name = "BoxReachPart"
			p.Size = Vector3.new(Dist, Dist, Dist)
			p.Transparency = 1
			p.CanCollide = false
			p.Massless = true
			p.Parent = h
			local w = Instance.new("WeldConstraint")
			w.Part0 = h
			w.Part1 = p
			w.Parent = p
		end
	end
end

local function FT(a, b)
	for _ = 1, FT_TIMES do
		firetouchinterest(a, b, 0)
		firetouchinterest(a, b, 1)
	end
end

local function KL(p, t)
	if K[p] then return end
	K[p] = true
	while protectActive do
		local lc = LP.Character
		local tc = p.Character
		if not (lc and tc) then break end
		local tw = lc:FindFirstChildWhichIsA("Tool")
		local th = tc:FindFirstChildOfClass("Humanoid")
		if not (tw and tw.Parent == lc and t.Parent and th and th.Health > 0) then break end
		for _, v in ipairs(tc:GetDescendants()) do
			if v:IsA("BasePart") then
				firetouchinterest(t, v, 0)
				firetouchinterest(t, v, 1)
			end
		end
		task.wait()
	end
	K[p] = nil
end

local function PC(c)
	for _, v in ipairs(c:GetDescendants()) do
		CRB(v)
	end
	connections.childAdded = c.ChildAdded:Connect(CRB)
end

local function MH(toolPart, plr)
	-- Check if player is safe
	if isSafePlayer(plr) then
		return
	end

	local c = plr.Character
	if not c then return end
	local h = c:FindFirstChildOfClass("Humanoid")
	local r = c:FindFirstChild("HumanoidRootPart")
	if not (h and r and h.Health > 0) then return end
	pcall(function() toolPart.Parent:Activate() end)
	for _ = 1, DMG_TIMES do
		for _, v in ipairs(c:GetDescendants()) do
			if v:IsA("BasePart") then
				FT(toolPart, v)
			end
		end
	end
	task.spawn(function()
		KL(plr, toolPart)
	end)
end

local function HB()
	if not protectActive then return end
	local c = LP.Character
	if not c then return end
	local hrp = c:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local pos = hrp.Position
	for _, t in ipairs(c:GetDescendants()) do
		if t:IsA("Tool") then
			local b = t:FindFirstChild("BoxReachPart") or t:FindFirstChild("Handle")
			if b then
				for _, p in ipairs(A) do
					if p ~= LP and p.Character then
						local rp = p.Character:FindFirstChild("HumanoidRootPart")
						local hm = p.Character:FindFirstChildOfClass("Humanoid")
						if rp and hm and hm.Health > 0 then
							local d = rp.Position - pos
							if d:Dot(d) <= DistSq then
								MH(b, p)
							end
						end
					end
				end
			end
		end
	end
end

local function SK()
	if connections.heartbeat then connections.heartbeat:Disconnect() end
	connections.heartbeat = RunService.Heartbeat:Connect(HB)
end

local function UP()
	table.clear(A)
	for _, p in ipairs(Players:GetPlayers()) do
		table.insert(A, p)
	end
end

-- Start combat system
local function startCombat()
	deleteKillParts()
	startNoclip()
	UP()
	
	if LP.Character then
		PC(LP.Character)
		SK()
	end
	
	connections.charAdded = LP.CharacterAdded:Connect(function(c)
		c:WaitForChild("HumanoidRootPart", 10)
		PC(c)
		SK()
	end)
	
	connections.playerAdded = Players.PlayerAdded:Connect(function(p)
		table.insert(A, p)
	end)
	
	connections.playerRemoving = Players.PlayerRemoving:Connect(function(p)
		for i, v in ipairs(A) do
			if v == p then
				table.remove(A, i)
				break
			end
		end
	end)
end

-- Stop all systems
local function stopAllSystems()
	protectActive = false
	protectedPlayer = nil
	teleportTarget = nil
	
	-- Stop all loops
	for _, loop in pairs(loops) do
		if loop then
			task.cancel(loop)
		end
	end
	table.clear(loops)
	
	-- Disconnect all connections
	for _, connection in pairs(connections) do
		if connection then
			connection:Disconnect()
		end
	end
	table.clear(connections)
	
	-- Clear tables
	table.clear(K)
	table.clear(A)
	
	-- Re-enable collision
	if LP.Character then
		for _, part in ipairs(LP.Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	end
end

-- Chat command handler
LP.Chatted:Connect(function(message)
	-- Check if user can use commands
	if not canUseCommands() then
		return
	end
	
	local args = message:split(" ")
	local command = args[1]:lower()
	
	-- .protect username number
	if command == ".protect" then
		-- Check for whitelist subcommands first
		if args[2] and (args[2]:lower() == "whitelist" or args[2]:lower() == "unwhitelist") then
			local subcommand = args[2]:lower()
			local username = args[3]
			
			if not username then
				print("Usage: .protect", subcommand, "username")
				return
			end
			
			local targetPlayer = findPlayerByPartial(username)
			if not targetPlayer then
				print("Player not found:", username)
				return
			end
			
			if subcommand == "whitelist" then
				if targetPlayer == protectedPlayer then
					print("This player is already protected!")
					return
				end
				
				whitelist[targetPlayer.Name] = true
				print("Whitelisted:", targetPlayer.Name)
			else -- unwhitelist
				if targetPlayer == protectedPlayer then
					print("Cannot unwhitelist the protected player!")
					return
				end
				
				whitelist[targetPlayer.Name] = nil
				print("Unwhitelisted:", targetPlayer.Name)
			end
			return
		end
		
		-- Regular protect command
		if protectActive then
			print("Already protecting someone! Use .unprotect first.")
			return
		end
		
		local username = args[2]
		local number = tonumber(args[3])
		
		if not username or not number then
			print("Usage: .protect username number")
			return
		end
		
		if not TELEPORT_MAPPING[number] then
			print("Invalid number! Use 1, 2, or 3")
			return
		end
		
		local targetPlayer = findPlayerByPartial(username)
		if not targetPlayer then
			print("Player not found:", username)
			return
		end
		
		protectActive = true
		protectedPlayer = targetPlayer
		teleportTarget = TELEPORT_MAPPING[number]
		
		startCombat()
		startProtectTeleport()
		
		print("Now protecting:", targetPlayer.Name)
		print("Teleporting:", teleportTarget, "below them")
	
	-- .unprotect username
	elseif command == ".unprotect" then
		local username = args[2]
		
		if not username then
			print("Usage: .unprotect username")
			return
		end
		
		local targetPlayer = findPlayerByPartial(username)
		if not targetPlayer or targetPlayer ~= protectedPlayer then
			print("Not currently protecting this player")
			return
		end
		
		protectActive = false
		
		-- Return the teleport target to their original position
		if teleportTarget then
			returnToOriginalPosition(teleportTarget)
		end
		
		-- Stop protect teleport loop
		if loops.protectTeleport then
			task.cancel(loops.protectTeleport)
			loops.protectTeleport = nil
		end
		
		print("Stopped protecting:", targetPlayer.Name)
		
		-- Clean up variables
		protectedPlayer = nil
		teleportTarget = nil
		
		-- Stop all systems
		stopAllSystems()
	end
end)

-- Update friends cache when players join
Players.PlayerAdded:Connect(function(player)
	-- Clear cache entry to force recheck
	friendsCache[player.UserId] = nil
end)

print("Advanced Protection Script Loaded!")
print("Authorized user and their friends can use commands")
print("Friends of authorized user are automatically safe from attacks")
print("Commands:")
print("  .protect username number - Protect a player (1-3 for teleport target)")
print("  .unprotect username - Stop protecting")
print("  .protect whitelist username - Add to whitelist")
print("  .protect unwhitelist username - Remove from whitelist")
