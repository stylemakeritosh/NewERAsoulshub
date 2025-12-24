--== Initialization ==--
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Stats = game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/x2zu/OPEN-SOURCE-UI-ROBLOX/refs/heads/main/X2ZU%20UI%20ROBLOX%20OPEN%20SOURCE/DummyUi-leak-by-x2zu/fetching-main/Tools/Framework.luau"))()

local currentwalkspeed = 16
local xrayenabled = false
local xraytransparency = 0.6
local originaltransparencies = {}
local noVelocityEnabled = false
local noVelocityConnection = nil
local bunnyHopEnabled = false
local bunnyHopDelay = 1
local bunnyHopConnection = nil

local originallighting = {
	Brightness = game.Lighting.Brightness,
	Ambient = game.Lighting.Ambient,
	OutdoorAmbient = game.Lighting.OutdoorAmbient,
	FogEnd = game.Lighting.FogEnd,
	FogStart = game.Lighting.FogStart
}

local espenabled = false
local outlineenabled = false
local tracersenabled = false
local skeletonenabled = false

local espconfig = {
	espcolor = Color3.fromRGB(255, 255, 255),
	outlinecolor = Color3.fromRGB(255, 255, 255),
	outlinefillcolor = Color3.fromRGB(255, 255, 255),
	tracercolor = Color3.fromRGB(255, 255, 255),
	skeletoncolor = Color3.fromRGB(255, 255, 255),
	espsize = 16,
	tracersize = 2,
	outlinetransparency = 0,
	outlinefilltransparency = 1,
	rainbowesp = false,
	rainbowoutline = false,
	rainbowtracers = false,
	rainbowskeleton = false,
	rainbowspeed = 5,
	tracerposition = "Bottom"
}

local rainbowhue = 0
local lastupdate = 0
local espobjects = {}
local activehighlights = {}
local playerconnections = {}
local tracerlines = {}
local skeletonlines = {}
local shieldedPlayers = {}

local aimlockenabled = false
local smoothaimlock = false
local aimlocktype = "Nearest Player"
local aimpart = "Head"
local fovenabled = false
local showfov = false
local fovsize = 100
local fovcolor = Color3.fromRGB(255, 255, 255)
local fovgui = nil
local fovframe = nil
local fovstroke = nil
local fovstrokethickness = 2
local nearestplayerdistance = 1000
local nearestmousedistance = 500
local fovlockdistance = 1000
local rainbowfov = false
local aimlockcertainplayer = false
local selectedplayer = nil
local ignoredplayers = {}
local prioritizedplayers = {}
local wallcheckenabled = true
local lerpalpha = 0.4
local aimlockOffsetX = 0
local aimlockOffsetY = 0
local ignoreShielded = true
local ignoreLobby = true

local autoFireEnabled = false
local autoFireDelay = 1.5
local autoFireShootDelay = 0.1
local nextFireTime = 0
local currentTarget = nil
local autoFireConnection = nil
local isFiring = false

local knifeCloseEnabled = false
local knifeRange = 10
local showKnifeRange = false
local knifeRangeColor = Color3.fromRGB(255, 255, 255)
local knifeRangeTransparency = 0.5
local rangeSphere = nil
local knifeConnection = nil
local lastKnifeState = nil
local SwapWeapon = nil
local knifeCrateCount = 0
local gunCrateCount = 0
local isOpeningCrates = false

local autoRespawnEnabled = false
local autoRespawnDelay = 0
local autoRespawnLastFire = 0
local CommandRemote = nil

local rgbGunKnifeEnabled = false
local rgbSpeed = 10
local rgbReapplySpeed = 1
local rgbHue = 0
local rgbConnection = nil
local rgbReapplyConnection = nil
local lastGunTool = nil
local rgbType = "Material"

local hitSfxId = ""
local critSfxId = ""
local autoApplySfx = false
local autoApplyDelay = 1
local autoApplyConnection = nil

local rgbAsyncEnabled = false
local rgbSyncHue = 0
local rgbSyncLastUpdate = 0
local rgbAsyncSpeed = 10
local rgbAsyncMode = "Backwards"

getgenv().RGB_ForceNeon = true

local inLobby = false

local function GetLocalHRP()
	if not LocalPlayer.Character then return nil end
	return LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function getrainbowcolor()
	local currenttime = tick()
	local speedmultiplier = 11 - espconfig.rainbowspeed
	local increment = 0.001 * speedmultiplier
	if currenttime - lastupdate >= 0.1 then
		rainbowhue = (rainbowhue + increment) % 1
		lastupdate = currenttime
	end
	return Color3.fromHSV(rainbowhue, 1, 1)
end

local function getSyncRainbowColor()
	local currenttime = tick()
	local speedmultiplier = 11 - rgbAsyncSpeed
	local increment = 0.001 * speedmultiplier
	if rgbAsyncMode == "Backwards" then increment = -increment end
	if currenttime - rgbSyncLastUpdate >= 0.1 then
		rgbSyncHue = (rgbSyncHue + increment) % 1
		rgbSyncLastUpdate = currenttime
	end
	return Color3.fromHSV(rgbSyncHue, 1, 1)
end

local function getPlayerWeapon(player)
	if not player.Character then return "None" end
	local tool = player.Character:FindFirstChildWhichIsA("Tool")
	if tool then return tool.Name end
	return "None"
end

local function createesp(player)
	if player == LocalPlayer or espobjects[player] then return end
	local nametext = Drawing.new("Text")
	nametext.Size = espconfig.espsize
	nametext.Center = true
	nametext.Outline = true
	nametext.Color = espconfig.espcolor
	nametext.Font = 2
	nametext.Visible = false
	espobjects[player] = { Name = nametext }
end

local function removeesp(player)
	if espobjects[player] then
		espobjects[player].Name:Remove()
		espobjects[player] = nil
	end
end

local function updateesp()
	for player, esp in pairs(espobjects) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = player.Character.HumanoidRootPart
			local pos, onscreen = Camera:WorldToViewportPoint(hrp.Position)
			local isShielded = shieldedPlayers[player]
			local color = isShielded and Color3.fromRGB(255, 0, 0) or (espconfig.rainbowesp and (rgbAsyncEnabled and getSyncRainbowColor() or getrainbowcolor()) or espconfig.espcolor)
			esp.Name.Color = color
			esp.Name.Size = espconfig.espsize
			if onscreen then
				local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
				local weapon = getPlayerWeapon(player)
				local prefix = isShielded and "[SHIELDED] " or ""
				esp.Name.Position = Vector2.new(pos.X, pos.Y - 20)
				esp.Name.Text = prefix .. player.Name .. " | " .. math.floor(distance) .. " studs | " .. weapon
				esp.Name.Visible = true
			else
				esp.Name.Visible = false
			end
		else
			esp.Name.Visible = false
		end
	end
end

local function applyhighlighttocharacter(player, character)
	if not character then return end
	local userid = player.UserId
	if activehighlights[userid] then activehighlights[userid]:Destroy() end
	local highlighter = Instance.new("Highlight")
	highlighter.FillTransparency = espconfig.outlinefilltransparency
	highlighter.OutlineTransparency = espconfig.outlinetransparency
	highlighter.OutlineColor = espconfig.rainbowoutline and (rgbAsyncEnabled and getSyncRainbowColor() or getrainbowcolor()) or espconfig.outlinecolor
	highlighter.FillColor = espconfig.rainbowoutline and (rgbAsyncEnabled and getSyncRainbowColor() or getrainbowcolor()) or espconfig.outlinefillcolor
	highlighter.Adornee = character
	highlighter.Parent = character
	activehighlights[userid] = highlighter
end

local function setupplayerhighlight(player)
	local userid = player.UserId
	playerconnections[userid] = playerconnections[userid] or {}
	local function oncharacteradded(character)
		if not character then return end
		task.spawn(function()
			local humanoid = character:WaitForChild("Humanoid", 5)
			if not humanoid then return end
			if outlineenabled then applyhighlighttocharacter(player, character) end
			table.insert(playerconnections[userid], player:GetPropertyChangedSignal("TeamColor"):Connect(function()
				local highlight = activehighlights[userid]
				if highlight then
					highlight.OutlineColor = espconfig.rainbowoutline and (rgbAsyncEnabled and getSyncRainbowColor() or getrainbowcolor()) or (player.TeamColor and player.TeamColor.Color) or espconfig.outlinecolor
				end
			end))
			table.insert(playerconnections[userid], humanoid.Died:Connect(function() removehighlight(player) end))
		end)
	end
	local charaddedconn = player.CharacterAdded:Connect(oncharacteradded)
	table.insert(playerconnections[userid], charaddedconn)
	if player.Character then oncharacteradded(player.Character) end
end

function removehighlight(player)
	local userid = player.UserId
	if activehighlights[userid] then activehighlights[userid]:Destroy() activehighlights[userid] = nil end
	if playerconnections[userid] then
		for _, conn in pairs(playerconnections[userid]) do if conn then conn:Disconnect() end end
		playerconnections[userid] = nil
	end
end

local function createtracers()
	tracerlines = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local line = Drawing.new("Line")
			line.Thickness = espconfig.tracersize
			line.Transparency = 1
			line.Visible = false
			tracerlines[player] = line
		end
	end
end

local function updatetracers()
	local screenHeight = Camera.ViewportSize.Y
	local fromY
	if espconfig.tracerposition == "Bottom" then
		fromY = screenHeight
	elseif espconfig.tracerposition == "Middle" then
		fromY = screenHeight / 2
	elseif espconfig.tracerposition == "Up" then
		fromY = 0
	end
	for player, line in pairs(tracerlines) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local root = player.Character.HumanoidRootPart
			local screenpos, onscreen = Camera:WorldToViewportPoint(root.Position)
			local isShielded = shieldedPlayers[player]
			local color = isShielded and Color3.fromRGB(255, 0, 0) or (espconfig.rainbowtracers and (rgbAsyncEnabled and getSyncRainbowColor() or getrainbowcolor()) or espconfig.tracercolor)
			if onscreen then
				line.From = Vector2.new(Camera.ViewportSize.X / 2, fromY)
				line.To = Vector2.new(screenpos.X, screenpos.Y)
				line.Color = color
				line.Visible = true
			else
				line.Visible = false
			end
		else
			line.Visible = false
		end
	end
end

local function toggletracers()
	if tracersenabled then
		createtracers()
		RunService:BindToRenderStep("Tracers", Enum.RenderPriority.Camera.Value + 1, updatetracers)
	else
		RunService:UnbindFromRenderStep("Tracers")
		for _, line in pairs(tracerlines) do line:Remove() end
		tracerlines = {}
	end
end

local function createskeletonlines()
	skeletonlines = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local lines = {}
			for i = 1, 6 do
				local line = Drawing.new("Line")
				line.Thickness = 2
				line.Transparency = 1
				line.Visible = false
				lines[i] = line
			end
			skeletonlines[player] = lines
		end
	end
end

local function updateskeleton()
	for player, lines in pairs(skeletonlines) do
		if player.Character then
			local char = player.Character
			local parts = {
				Head = char:FindFirstChild("Head"),
				Torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"),
				Hip = char:FindFirstChild("LowerTorso") or char:FindFirstChild("Torso"),
				LeftArm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm"),
				RightArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm"),
				LeftLeg = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg"),
				RightLeg = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")
			}
			local isShielded = shieldedPlayers[player]
			local color = isShielded and Color3.fromRGB(255, 0, 0) or (espconfig.rainbowskeleton and (rgbAsyncEnabled and getSyncRainbowColor() or getrainbowcolor()) or espconfig.skeletoncolor)
			local function getscreen(part) if part then local pos, visible = Camera:WorldToViewportPoint(part.Position) if visible then return Vector2.new(pos.X, pos.Y) end end end
			local head = getscreen(parts.Head)
			local torso = getscreen(parts.Torso)
			local hip = getscreen(parts.Hip)
			local la = getscreen(parts.LeftArm)
			local ra = getscreen(parts.RightArm)
			local ll = getscreen(parts.LeftLeg)
			local rl = getscreen(parts.RightLeg)
			
			local connections = {
				{head, torso, lines[1]},
				{torso, hip, lines[2]},
				{torso, la, lines[3]},
				{torso, ra, lines[4]},
				{hip, ll, lines[5]},
				{hip, rl, lines[6]}
			}
			
			for _, conn in ipairs(connections) do
				local p1, p2, line = conn[1], conn[2], conn[3]
				if p1 and p2 then
					line.From = p1
					line.To = p2
					line.Color = color
					line.Visible = true
				else
					line.Visible = false
				end
			end
		else
			for _, line in ipairs(lines) do line.Visible = false end
		end
	end
end

local function toggleskeleton()
	if skeletonenabled then
		createskeletonlines()
		RunService:BindToRenderStep("SkeletonESP", Enum.RenderPriority.Camera.Value + 1, updateskeleton)
	else
		RunService:UnbindFromRenderStep("SkeletonESP")
		for _, lines in pairs(skeletonlines) do
			for _, line in ipairs(lines) do line:Remove() end
		end
		skeletonlines = {}
	end
end

local function applyShieldEffect(player)
	if player == LocalPlayer then return end
	shieldedPlayers[player] = true
	if activehighlights[player.UserId] then
		activehighlights[player.UserId].OutlineColor = Color3.fromRGB(255, 0, 0)
		activehighlights[player.UserId].FillColor = Color3.fromRGB(255, 0, 0)
	end
	task.delay(1.5, function()
		if shieldedPlayers[player] then
			shieldedPlayers[player] = nil
			if activehighlights[player.UserId] then
				activehighlights[player.UserId].OutlineColor = espconfig.rainbowoutline and (rgbAsyncEnabled and getSyncRainbowColor() or getrainbowcolor()) or espconfig.outlinecolor
				activehighlights[player.UserId].FillColor = espconfig.rainbowoutline and (rgbAsyncEnabled and getSyncRainbowColor() or getrainbowcolor()) or espconfig.outlinefillcolor
			end
		end
	end)
end

local function isShielded(player)
	return shieldedPlayers[player] == true
end

local function checkLobbyStatus()
	local team = LocalPlayer.Team
	if team then
		inLobby = (team.Name == "Lobby")
	else
		inLobby = false
	end
end

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(checkLobbyStatus)
LocalPlayer:GetPropertyChangedSignal("TeamColor"):Connect(checkLobbyStatus)
checkLobbyStatus()

local function getclosestplayer()
	local localHRP = GetLocalHRP()
	if not localHRP then return nil end
	local mousePos = UserInputService:GetMouseLocation()

	local function getPriorityScore(player)
		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return math.huge end
		if player == LocalPlayer or ignoredplayers[player.Name] or (ignoreShielded and isShielded(player)) or (ignoreLobby and player.Team and player.Team.Name == "Lobby") then return math.huge end

		local hrp = player.Character.HumanoidRootPart
		local screen, onscreen = Camera:WorldToViewportPoint(hrp.Position)
		if not onscreen then return math.huge end

		if fovenabled then
			local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
			local distFromCenter = (Vector2.new(screen.X, screen.Y) - center).Magnitude
			if distFromCenter > fovsize/2 then return math.huge end
			if (localHRP.Position - hrp.Position).Magnitude > fovlockdistance then return math.huge end
		end

		if wallcheckenabled then
			local head = player.Character:FindFirstChild("Head")
			if head then
				local origin = localHRP.Parent:FindFirstChild("Head") and localHRP.Parent.Head.Position or localHRP.Position
				local direction = head.Position - origin
				local rayParams = RaycastParams.new()
				rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				local result = workspace:Raycast(origin, direction, rayParams)
				if result then
					if not result.Instance:IsDescendantOf(player.Character) then
						return math.huge
					end
				end
			end
		end

		if aimlocktype == "Nearest Player" then
			return (localHRP.Position - hrp.Position).Magnitude
		else
			return (Vector2.new(screen.X, screen.Y) - mousePos).Magnitude
		end
	end

	local bestPlayer, bestScore = nil, math.huge
	for _, player in ipairs(prioritizedplayers) do
		local score = getPriorityScore(player)
		if score and score < bestScore then
			bestScore = score
			bestPlayer = player
		end
	end

	if bestPlayer then return bestPlayer end

	for _, player in ipairs(Players:GetPlayers()) do
		if table.find(prioritizedplayers, player) then continue end
		local score = getPriorityScore(player)
		if score and score < bestScore then
			bestScore = score
			bestPlayer = player
		end
	end

	return bestPlayer
end

local function getaimpartposition(targetplayer)
	if not targetplayer or not targetplayer.Character then return nil end
	if aimpart == "Head" and targetplayer.Character:FindFirstChild("Head") then
		return targetplayer.Character.Head.Position
	elseif aimpart == "Torso" then
		local torso = targetplayer.Character:FindFirstChild("UpperTorso") or targetplayer.Character:FindFirstChild("Torso")
		if torso then return torso.Position end
	elseif aimpart == "Feet" and targetplayer.Character:FindFirstChild("HumanoidRootPart") then
		return targetplayer.Character.HumanoidRootPart.Position + Vector3.new(0, -3, 0)
	end
	return nil
end

local aimlockConnection = nil

local function updateaimlock()
	local localHRP = GetLocalHRP()
	if not localHRP then return end
	
	checkLobbyStatus()
	if inLobby then return end

	local targetplayer = aimlockcertainplayer and selectedplayer or getclosestplayer()
	if targetplayer then
		local targetposition = getaimpartposition(targetplayer)
		if targetposition then
			targetposition = targetposition + Vector3.new(aimlockOffsetX, aimlockOffsetY, 0)
			local lookdirection = (targetposition - Camera.CFrame.Position).Unit
			if smoothaimlock then
				local targetcframe = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + lookdirection)
				Camera.CFrame = Camera.CFrame:Lerp(targetcframe, lerpalpha)
			else
				Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + lookdirection)
			end
		end
	end
end

local function startAimlockLoop()
	if aimlockConnection then return end
	aimlockConnection = RunService.RenderStepped:Connect(updateaimlock)
end

local function stopAimlockLoop()
	if aimlockConnection then
		aimlockConnection:Disconnect()
		aimlockConnection = nil
	end
end

local function updatefovcircle()
	if fovframe and fovstroke then
		if showfov then
			fovstroke.Color = rainbowfov and (rgbAsyncEnabled and getSyncRainbowColor() or getrainbowcolor()) or fovcolor
			fovframe.Visible = true
		else
			fovframe.Visible = false
		end
	end
end

local function toggleNoVelocity()
	if noVelocityEnabled then
		noVelocityConnection = RunService.Heartbeat:Connect(function()
			for _, player in pairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local hrp = player.Character.HumanoidRootPart
					hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
				end
			end
		end)
	else
		if noVelocityConnection then noVelocityConnection:Disconnect() noVelocityConnection = nil end
	end
end

local function toggleBunnyHop()
	if bunnyHopEnabled then
		bunnyHopConnection = RunService.Heartbeat:Connect(function()
			local char = LocalPlayer.Character
			if not char or not char:FindFirstChild("Humanoid") then return end
			local humanoid = char.Humanoid

			if humanoid:GetState() == Enum.HumanoidStateType.Running and humanoid.FloorMaterial ~= Enum.Material.Air then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				task.wait(bunnyHopDelay)
			end
		end)
	else
		if bunnyHopConnection then bunnyHopConnection:Disconnect() bunnyHopConnection = nil end
	end
end

local function updateKnifeRangeSphere()
	if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
		if rangeSphere then rangeSphere.Transparency = 1 end
		return
	end
	local root = LocalPlayer.Character.HumanoidRootPart
	if showKnifeRange then
		if not rangeSphere then
			rangeSphere = Instance.new("Part")
			rangeSphere.Name = "KnifeRangeSphere"
			rangeSphere.Shape = Enum.PartType.Ball
			rangeSphere.Material = Enum.Material.ForceField
			rangeSphere.CanCollide = false
			rangeSphere.Anchored = true
			rangeSphere.CastShadow = false
			rangeSphere.Parent = workspace
		end
		rangeSphere.Size = Vector3.new(knifeRange * 2, knifeRange * 2, knifeRange * 2)
		rangeSphere.CFrame = root.CFrame
		rangeSphere.Color = knifeRangeColor
		rangeSphere.Transparency = knifeRangeTransparency
	else
		if rangeSphere then rangeSphere:Destroy() rangeSphere = nil end
	end
end

local function applyRGBToGun(toolModel, hue)
	if not toolModel then return end
	local faces = Enum.NormalId:GetEnumItems()
	local forceNeon = getgenv().RGB_ForceNeon == true
	for _, part in ipairs(toolModel:GetDescendants()) do
		if part:IsA("UnionOperation") or part:IsA("BasePart") then
			if rgbGunKnifeEnabled and forceNeon then
				part.Material = Enum.Material.Neon
			end
			if rgbGunKnifeEnabled then
				part.Color = Color3.fromHSV(hue, 1, 1)
				part.UsePartColor = true
				local light = part:FindFirstChildOfClass("SpotLight") or Instance.new("SpotLight")
				light.Color = Color3.fromHSV(hue, 1, 1)
				light.Range = 18
				light.Brightness = 5
				light.Face = faces[math.random(1, #faces)]
				light.Angle = 45
				light.Parent = part
			end
		end
	end
end

local function toggleRGBGunKnife()
	if rgbGunKnifeEnabled then
		rgbConnection = RunService.Heartbeat:Connect(function()
			rgbHue = (rgbHue + 0.001 * rgbSpeed) % 1
			local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
			if tool then
				if rgbType == "Material" then
					applyRGBToGun(tool, rgbHue)
				elseif rgbType == "Highlight" then
					local highlight = tool:FindFirstChildOfClass("Highlight") or Instance.new("Highlight")
					highlight.FillColor = Color3.fromHSV(rgbHue, 1, 1)
					highlight.OutlineColor = Color3.fromHSV(rgbHue, 1, 1)
					highlight.FillTransparency = 0.5
					highlight.OutlineTransparency = 0
					highlight.Parent = tool
				end
				lastGunTool = tool
			end
		end)
		rgbReapplyConnection = RunService.Heartbeat:Connect(function()
			task.wait(rgbReapplySpeed)
			if lastGunTool then
				if rgbType == "Material" then
					applyRGBToGun(lastGunTool, rgbHue)
				end
			end
		end)
	else
		if rgbConnection then rgbConnection:Disconnect() rgbConnection = nil end
		if rgbReapplyConnection then rgbReapplyConnection:Disconnect() rgbReapplyConnection = nil end
	end
end

local function applyCustomSFX()
	local char = LocalPlayer.Character
	if char then
		local tool = char:FindFirstChildOfClass("Tool")
		if tool then
			local hitSfx = tool:FindFirstChild("HitSfx") or Instance.new("Sound")
			hitSfx.Name = "HitSfx"
			hitSfx.SoundId = "rbxassetid://" .. hitSfxId
			hitSfx.Parent = tool
			local critSfx = tool:FindFirstChild("CritSfx") or Instance.new("Sound")
			critSfx.Name = "CritSfx"
			critSfx.SoundId = "rbxassetid://" .. critSfxId
			critSfx.Parent = tool
		end
	end
end

local function toggleAutoApplySFX()
	if autoApplySfx then
		autoApplyConnection = RunService.Heartbeat:Connect(function()
			task.wait(autoApplyDelay)
			applyCustomSFX()
		end)
	else
		if autoApplyConnection then autoApplyConnection:Disconnect() autoApplyConnection = nil end
	end
end

local function openKnifeCrates()
	if isOpeningCrates then return end
	isOpeningCrates = true
	for i = 1, knifeCrateCount do
		ReplicatedStorage:WaitForChild("Events"):WaitForChild("OpenCrate"):FireServer("Knife")
		task.wait(0.5)
	end
	isOpeningCrates = false
end

local function openGunCrates()
	if isOpeningCrates then return end
	isOpeningCrates = true
	for i = 1, gunCrateCount do
		ReplicatedStorage:WaitForChild("Events"):WaitForChild("OpenCrate"):FireServer("Gun")
		task.wait(0.5)
	end
	isOpeningCrates = false
end

local function toggleKnifeSwitch()
	if knifeCloseEnabled then
		knifeConnection = RunService.Heartbeat:Connect(function()
			local closestPlayer, closestDistance = nil, knifeRange
			local localHRP = GetLocalHRP()
			if not localHRP then return end
			for _, player in pairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local hrp = player.Character.HumanoidRootPart
					local distance = (localHRP.Position - hrp.Position).Magnitude
					if distance < closestDistance then
						closestDistance = distance
						closestPlayer = player
					end
				end
			end
			if closestPlayer then
				local knife = LocalPlayer.Backpack:FindFirstChild("Knife") or LocalPlayer.Character:FindFirstChild("Knife")
				if knife and lastKnifeState ~= true then
					SwapWeapon = LocalPlayer.Character:FindFirstChildOfClass("Tool").Name
					LocalPlayer.Character.Humanoid:EquipTool(knife)
					lastKnifeState = true
				end
			else
				if lastKnifeState == true then
					local gun = LocalPlayer.Backpack:FindFirstChild(SwapWeapon) or LocalPlayer.Character:FindFirstChild(SwapWeapon)
					if gun then
						LocalPlayer.Character.Humanoid:EquipTool(gun)
					end
					lastKnifeState = false
				end
			end
		end)
	else
		if knifeConnection then knifeConnection:Disconnect() knifeConnection = nil end
		lastKnifeState = nil
	end
end

local function autoFireLoop()
	local currentTime = tick()
	if currentTime >= nextFireTime then
		currentTarget = getclosestplayer()
		if currentTarget then
			isFiring = true
			CommandRemote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Fire")
			CommandRemote:FireServer(currentTarget.Character[aimpart].Position)
			task.wait(autoFireShootDelay)
			isFiring = false
			nextFireTime = currentTime + autoFireDelay
		end
	end
end

local function toggleAutoFire()
	if autoFireEnabled then
		autoFireConnection = RunService.Heartbeat:Connect(autoFireLoop)
	else
		if autoFireConnection then autoFireConnection:Disconnect() autoFireConnection = nil end
	end
end

local function toggleesp()
	if espenabled then
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then createesp(player) end
		end
		RunService:BindToRenderStep("ESP", Enum.RenderPriority.Camera.Value + 1, updateesp)
	else
		RunService:UnbindFromRenderStep("ESP")
		for player in pairs(espobjects) do removeesp(player) end
	end
end

local function toggleoutline()
	if outlineenabled then
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then setupplayerhighlight(player) end
		end
	else
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then removehighlight(player) end
		end
	end
end

local function togglenoclip()
	if noclipenabled then
		noclipConnection = RunService.Stepped:Connect(function()
			if LocalPlayer.Character then
				for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end)
	else
		if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
	end
end

local function togglefly()
	if flyenabled then
		local char = LocalPlayer.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local bodyVelocity = Instance.new("BodyVelocity")
				bodyVelocity.Velocity = Vector3.new(0, 0, 0)
				bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				bodyVelocity.Parent = hrp
				flyBV = bodyVelocity
				flyConnection = UserInputService.InputBegan:Connect(function(input)
					if input.KeyCode == Enum.KeyCode.Space then
						flyBV.Velocity = Vector3.new(0, flyspeed, 0)
					elseif input.KeyCode == Enum.KeyCode.LeftShift then
						flyBV.Velocity = Vector3.new(0, -flyspeed, 0)
					end
				end)
				flyEndConnection = UserInputService.InputEnded:Connect(function(input)
					if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.LeftShift then
						flyBV.Velocity = Vector3.new(0, 0, 0)
					end
				end)
			end
		end
	else
		if flyBV then flyBV:Destroy() flyBV = nil end
		if flyConnection then flyConnection:Disconnect() flyConnection = nil end
		if flyEndConnection then flyEndConnection:Disconnect() flyEndConnection = nil end
	end
end

local function togglexray()
	if xrayenabled then
		for _, part in pairs(workspace:GetDescendants()) do
			if part:IsA("BasePart") and part.Transparency < xraytransparency then
				originaltransparencies[part] = part.Transparency
				part.Transparency = xraytransparency
			end
		end
	else
		for part, trans in pairs(originaltransparencies) do
			if part and part.Parent then
				part.Transparency = trans
			end
		end
		originaltransparencies = {}
	end
end

local function toggleAimlock()
	if aimlockenabled then
		startAimlockLoop()
	else
		stopAimlockLoop()
	end
end

-- Create Main Window
local Window = Library:Window({
    Title = "Souls Hub | Flick",
    Desc = "by rintoshiiii",
    Icon = "user",
    Theme = "Dark",
    Config = {
        Keybind = Enum.KeyCode.LeftControl,
        Size = UDim2.new(0, 530, 0, 400)
    },
    CloseUIButton = {
        Enabled = true,
        Text = "Close UI"
    }
})

-- Info Tab
local InfoTab = Window:Tab({Title = "Info", Icon = "info-circle"}) do
    InfoTab:Section({Title = "Info"})
    InfoTab:Label({Title = "Souls Hub | Flick", Desc = "Thanks for using Souls Hub :D"})

    InfoTab:Section({Title = "Creator"})
    InfoTab:Label({Title = "Made by rintoshiiii"})
    InfoTab:Label({Title = "My Discord: rintoshiii"})
    InfoTab:Label({Title = "Souls Hub", Desc = "Made by Rin and Souls"})
    InfoTab:Label({Title = "https://discord.gg/nHS3RxTM5M", Desc = "Join for more"})

    InfoTab:Section({Title = "Links (Socials)"})
    InfoTab:Button({
        Title = "Discord (Co-Owner) (Rintoshiii)",
        Callback = function()
            setclipboard("@rintoshiii")
        end
    })
    InfoTab:Button({
        Title = "Souls (Owner) (soulshub_)",
        Callback = function()
            setclipboard("@soulshub_")
        end
    })

    InfoTab:Section({Title = "Discord Link"})
    InfoTab:Button({
        Title = "Click to Join Discord",
        Callback = function()
            setclipboard("https://discord.gg/nHS3RxTM5M")
        end
    })
    InfoTab:Button({
        Title = "More Scripts Soon, So Join :)",
        Callback = function()
            setclipboard("oke")
        end
    })
end

-- Main Tab
local MainTab = Window:Tab({Title = "Main", Icon = "home"}) do
    MainTab:Section({Title = "Player"})
    MainTab:Slider({
        Title = "Speed",
        Min = 16,
        Max = 100,
        Rounding = 0,
        Value = 16,
        Callback = function(v)
            currentwalkspeed = v
        end
    })
    MainTab:Slider({
        Title = "Jump",
        Min = 50,
        Max = 300,
        Rounding = 0,
        Value = 50,
        Callback = function(v)
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.JumpPower = v
            end
        end
    })
    MainTab:Slider({
        Title = "Gravity",
        Min = 0,
        Max = 196,
        Rounding = 0,
        Value = 196,
        Callback = function(v)
            workspace.Gravity = v
        end
    })
    MainTab:Toggle({
        Title = "Fly",
        Value = false,
        Callback = function(v)
            flyenabled = v
            togglefly()
        end
    })
    MainTab:Slider({
        Title = "Fly Speed",
        Min = 16,
        Max = 300,
        Rounding = 0,
        Value = 16,
        Callback = function(v)
            flyspeed = v
        end
    })
    MainTab:Toggle({
        Title = "Noclip",
        Value = false,
        Callback = function(v)
            noclipenabled = v
            togglenoclip()
        end
    })
    MainTab:Toggle({
        Title = "No Velocity (Others)",
        Value = false,
        Callback = function(v)
            noVelocityEnabled = v
            toggleNoVelocity()
        end
    })
    MainTab:Toggle({
        Title = "Bunny Hop",
        Value = false,
        Callback = function(v)
            bunnyHopEnabled = v
            toggleBunnyHop()
        end
    })
    MainTab:Slider({
        Title = "Bunny Hop Delay",
        Min = 0,
        Max = 1,
        Rounding = 2,
        Value = 0.1,
        Callback = function(v)
            bunnyHopDelay = v
        end
    })
    MainTab:Toggle({
        Title = "Auto Respawn",
        Value = false,
        Callback = function(v)
            autoRespawnEnabled = v
        end
    })
    MainTab:Slider({
        Title = "Auto Respawn Delay",
        Min = 0,
        Max = 5,
        Rounding = 2,
        Value = 0,
        Callback = function(v)
            autoRespawnDelay = v
        end
    })

    MainTab:Section({Title = "Game"})
    MainTab:Slider({
        Title = "Field of View",
        Min = 60,
        Max = 120,
        Rounding = 1,
        Value = 70,
        Callback = function(v)
            Camera.FieldOfView = v
        end
    })
    MainTab:Toggle({
        Title = "Full Bright",
        Value = false,
        Callback = function(v)
            if v then 
                game.Lighting.Brightness = 2 
                game.Lighting.Ambient = Color3.fromRGB(255,255,255) 
                game.Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255) 
            else 
                game.Lighting.Brightness = originallighting.Brightness 
                game.Lighting.Ambient = originallighting.Ambient 
                game.Lighting.OutdoorAmbient = originallighting.OutdoorAmbient 
            end 
        end
    })
    MainTab:Toggle({
        Title = "No Fog",
        Value = false,
        Callback = function(v)
            if v then 
                game.Lighting.FogEnd = 100000 
                game.Lighting.FogStart = 0 
            else 
                game.Lighting.FogEnd = originallighting.FogEnd 
                game.Lighting.FogStart = originallighting.FogStart 
            end 
        end
    })
end

-- Visuals Tab
local VisualsTab = Window:Tab({Title = "Visuals", Icon = "eye"}) do
    VisualsTab:Section({Title = "ESP"})
    VisualsTab:Toggle({
        Title = "ESP",
        Value = false,
        Callback = function(v)
            espenabled = v
            toggleesp()
        end
    })
    VisualsTab:Slider({
        Title = "ESP Size",
        Min = 10,
        Max = 30,
        Rounding = 0,
        Value = 16,
        Callback = function(v)
            espconfig.espsize = v
        end
    })
    VisualsTab:Toggle({
        Title = "Rainbow ESP",
        Value = false,
        Callback = function(v)
            espconfig.rainbowesp = v
        end
    })

    VisualsTab:Section({Title = "Outline"})
    VisualsTab:Toggle({
        Title = "Outline",
        Value = false,
        Callback = function(v)
            outlineenabled = v
            toggleoutline()
        end
    })
    VisualsTab:Toggle({
        Title = "Rainbow Outline",
        Value = false,
        Callback = function(v)
            espconfig.rainbowoutline = v
        end
    })
    VisualsTab:Slider({
        Title = "Outline Transparency",
        Min = 0,
        Max = 1,
        Rounding = 2,
        Value = 0,
        Callback = function(v)
            espconfig.outlinetransparency = v
        end
    })
    VisualsTab:Slider({
        Title = "Outline Fill Transparency",
        Min = 0,
        Max = 1,
        Rounding = 2,
        Value = 1,
        Callback = function(v)
            espconfig.outlinefilltransparency = v
        end
    })

    VisualsTab:Section({Title = "Tracers"})
    VisualsTab:Toggle({
        Title = "Tracers",
        Value = false,
        Callback = function(v)
            tracersenabled = v
            toggletracers()
        end
    })
    VisualsTab:Dropdown({
        Title = "Tracer Position",
        List = {"Bottom", "Middle", "Up"},
        Value = "Bottom",
        Callback = function(v)
            espconfig.tracerposition = v
        end
    })
    VisualsTab:Slider({
        Title = "Tracer Thickness",
        Min = 1,
        Max = 5,
        Rounding = 0,
        Value = 2,
        Callback = function(v)
            espconfig.tracersize = v
        end
    })
    VisualsTab:Toggle({
        Title = "Rainbow Tracers",
        Value = false,
        Callback = function(v)
            espconfig.rainbowtracers = v
        end
    })

    VisualsTab:Section({Title = "Skeleton"})
    VisualsTab:Toggle({
        Title = "Skeleton",
        Value = false,
        Callback = function(v)
            skeletonenabled = v
            toggleskeleton()
        end
    })
    VisualsTab:Toggle({
        Title = "Rainbow Skeleton",
        Value = false,
        Callback = function(v)
            espconfig.rainbowskeleton = v
        end
    })

    VisualsTab:Section({Title = "Rainbow Speed"})
    VisualsTab:Slider({
        Title = "Rainbow Speed",
        Min = 1,
        Max = 10,
        Rounding = 0,
        Value = 5,
        Callback = function(v)
            espconfig.rainbowspeed = v
        end
    })
end

-- Features Tab
local FeaturesTab = Window:Tab({Title = "Features", Icon = "bug"}) do
    FeaturesTab:Section({Title = "AimLock"})
    FeaturesTab:Toggle({
        Title = "Activate Aimlock",
        Value = false,
        Callback = function(v) 
            aimlockenabled = v 
            if v then startAimlockLoop() else stopAimlockLoop() end 
        end
    })
    FeaturesTab:Dropdown({
        Title = "Aimlock Type",
        List = {"Nearest Player", "Nearest Mouse"},
        Value = "Nearest Player",
        Callback = function(v) aimlocktype = v end
    })
    FeaturesTab:Toggle({
        Title = "Auto-Fire (W.I.P)",
        Value = false,
        Callback = function(v) 
            autoFireEnabled = v 
            if v then
                autoFireConnection = RunService.Heartbeat:Connect(autoFireLoop)
            else
                if autoFireConnection then autoFireConnection:Disconnect() autoFireConnection = nil end
            end
        end
    })
    FeaturesTab:Label({Title = "CAUTION: love yourself, because i will if you dont.:]"})
    FeaturesTab:Toggle({
        Title = "Aimlock Certain Player",
        Value = false,
        Callback = function(v) aimlockcertainplayer = v end
    })
    local playerList = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(playerList, p.Name) end
    end
    FeaturesTab:Dropdown({
        Title = "Select Player",
        List = playerList,
        Value = playerList[1] or "None",
        Callback = function(v) selectedplayer = Players:FindFirstChild(v) end
    })
    FeaturesTab:Toggle({
        Title = "Enable FOV",
        Value = false,
        Callback = function(v) 
            fovenabled = v 
        end
    })
    FeaturesTab:Toggle({
        Title = "Show FOV",
        Value = false,
        Callback = function(v) 
            showfov = v 
            if v then 
                if not fovgui then 
                    fovgui = Instance.new("ScreenGui") 
                    fovgui.Name = "FOVCircle" 
                    fovgui.IgnoreGuiInset = true 
                    fovgui.Parent = game:GetService("CoreGui") 
                    fovframe = Instance.new("Frame") 
                    fovframe.Name = "Circle" 
                    fovframe.AnchorPoint = Vector2.new(0.5, 0.5) 
                    fovframe.Position = UDim2.new(0.5, 0, 0.5, 0) 
                    fovframe.BackgroundTransparency = 1
                    fovframe.BorderSizePixel = 0 
                    fovframe.Parent = fovgui 
                    local corner = Instance.new("UICorner") 
                    corner.CornerRadius = UDim.new(1, 0) 
                    corner.Parent = fovframe 
                    fovstroke = Instance.new("UIStroke") 
                    fovstroke.Color = fovcolor 
                    fovstroke.Thickness = fovstrokethickness 
                    fovstroke.Parent = fovframe 
                    fovframe.Size = UDim2.new(0, fovsize, 0, fovsize) 
                end 
                fovframe.Visible = true 
            else 
                if fovframe then fovframe.Visible = false end 
            end 
        end
    })

    FeaturesTab:Section({Title = "Aimlock Configurations"})
    FeaturesTab:Slider({
        Title = "Nearest Player Lock Distance (Studs)",
        Min = 10,
        Max = 5000,
        Rounding = 1,
        Value = 1000,
        Callback = function(v) nearestplayerdistance = v end
    })
    FeaturesTab:Slider({
        Title = "Nearest Mouse Lock Distance (Studs)",
        Min = 10,
        Max = 5000,
        Rounding = 1,
        Value = 500,
        Callback = function(v) nearestmousedistance = v end
    })
    FeaturesTab:Slider({
        Title = "FOV Lock Distance (Studs)",
        Min = 50,
        Max = 5000,
        Rounding = 1,
        Value = 1000,
        Callback = function(v) fovlockdistance = v end
    })
    FeaturesTab:Toggle({
        Title = "Smooth Aimlock",
        Value = false,
        Callback = function(v) smoothaimlock = v end
    })
    FeaturesTab:Slider({
        Title = "Smooth Aimlock Speed (lerp alpha)",
        Min = 100,
        Max = 1000,
        Rounding = 0,
        Value = 400,
        Callback = function(v) lerpalpha = v / 1000 end
    })
    FeaturesTab:Toggle({
        Title = "Ignore Shielded",
        Value = true,
        Callback = function(v) ignoreShielded = v end
    })
    FeaturesTab:Toggle({
        Title = "Ignore Lobby",
        Value = true,
        Callback = function(v) ignoreLobby = v end
    })
    FeaturesTab:Dropdown({
        Title = "Aim Part",
        List = {"Head", "Torso", "Feet"},
        Value = "Head",
        Callback = function(v) aimpart = v end
    })
    FeaturesTab:Toggle({
        Title = "Rainbow FOV",
        Value = false,
        Callback = function(v) rainbowfov = v end
    })
    FeaturesTab:Slider({
        Title = "FOV Size",
        Min = 1,
        Max = 750,
        Rounding = 1,
        Value = 100,
        Callback = function(v) fovsize = v if fovframe then fovframe.Size = UDim2.new(0, v, 0, v) end end
    })
    FeaturesTab:Slider({
        Title = "FOV Stroke Thickness",
        Min = 1,
        Max = 10,
        Rounding = 1,
        Value = 2,
        Callback = function(v) fovstrokethickness = v if fovstroke then fovstroke.Thickness = v end end
    })
    FeaturesTab:Slider({
        Title = "Auto-Fire Delay (W.I.P)",
        Min = 1.5,
        Max = 3,
        Rounding = 2,
        Value = 1.5,
        Callback = function(v) autoFireDelay = v end
    })
    FeaturesTab:Slider({
        Title = "Auto-Fire Shoot Delay (W.I.P)",
        Min = 0.1,
        Max = 1,
        Rounding = 2,
        Value = 0.1,
        Callback = function(v) autoFireShootDelay = v end
    })
    FeaturesTab:Toggle({
        Title = "Wall Check",
        Value = true,
        Callback = function(v) wallcheckenabled = v end
    })
    FeaturesTab:Slider({
        Title = "Aimlock Offset (Y)",
        Min = -1,
        Max = 1,
        Rounding = 2,
        Value = 0,
        Callback = function(v) aimlockOffsetY = v end
    })
    FeaturesTab:Slider({
        Title = "Aimlock Offset (X)",
        Min = -1,
        Max = 1,
        Rounding = 2,
        Value = 0,
        Callback = function(v) aimlockOffsetX = v end
    })

    FeaturesTab:Section({Title = "Features"})
    FeaturesTab:Toggle({
        Title = "Switch To Knife When Close To Player",
        Value = false,
        Callback = function(v) knifeCloseEnabled = v toggleKnifeSwitch() end
    })
    FeaturesTab:Slider({
        Title = "S.T.K.W.C.T.P. Range",
        Min = 1,
        Max = 50,
        Rounding = 1,
        Value = 10,
        Callback = function(v) knifeRange = v updateKnifeRangeSphere() end
    })
    FeaturesTab:Toggle({
        Title = "Show S.T.K.W.C.T.P. Range",
        Value = false,
        Callback = function(v) showKnifeRange = v updateKnifeRangeSphere() end
    })
    FeaturesTab:Button({
        Title = "Mass Open Knife Crate",
        Callback = openKnifeCrates
    })
    FeaturesTab:Slider({
        Title = "Knife Crate Count To Open",
        Min = 0,
        Max = 25,
        Rounding = 1,
        Value = 0,
        Callback = function(v) knifeCrateCount = math.floor(v) end
    })
    FeaturesTab:Button({
        Title = "Mass Open Gun Crate",
        Callback = openGunCrates
    })
    FeaturesTab:Slider({
        Title = "Gun Crate Count To Open",
        Min = 0,
        Max = 15,
        Rounding = 1,
        Value = 0,
        Callback = function(v) gunCrateCount = math.floor(v) end
    })

    FeaturesTab:Section({Title = "Fun"})
    FeaturesTab:Toggle({
        Title = "RGB ASync",
        Value = false,
        Callback = function(v) rgbAsyncEnabled = v end
    })
    FeaturesTab:Slider({
        Title = "RGB ASync Speed",
        Min = 1,
        Max = 50,
        Rounding = 1,
        Value = 10,
        Callback = function(v) rgbAsyncSpeed = v end
    })
    FeaturesTab:Dropdown({
        Title = "RGB ASync Spectrum Mode",
        List = {"Forward", "Backwards"},
        Value = "Backwards",
        Callback = function(v) rgbAsyncMode = v end
    })
    FeaturesTab:Toggle({
        Title = "RGB Gun/Knife",
        Value = false,
        Callback = function(v) rgbGunKnifeEnabled = v toggleRGBGunKnife() end
    })
    FeaturesTab:Slider({
        Title = "RGB Speed",
        Min = 1,
        Max = 50,
        Rounding = 0,
        Value = 10,
        Callback = function(v) rgbSpeed = v end
    })
    FeaturesTab:Slider({
        Title = "RGB Re-Apply Speed",
        Min = 0,
        Max = 5,
        Rounding = 1,
        Value = 1,
        Callback = function(v) rgbReapplySpeed = v end
    })
    FeaturesTab:Dropdown({
        Title = "RGB Type",
        List = {"Material", "Highlight"},
        Value = "Material",
        Callback = function(v) rgbType = v end
    })
    FeaturesTab:Toggle({
        Title = "Change Material To Neon",
        Value = true,
        Callback = function(v) getgenv().RGB_ForceNeon = v end
    })
end

Players.PlayerAdded:Connect(function(p)
	if p ~= LocalPlayer then
		if espenabled then createesp(p) end
		if outlineenabled then playerconnections[p.UserId] = {} setupplayerhighlight(p) end
		if tracersenabled then
			local line = Drawing.new("Line")
			line.Thickness = espconfig.tracersize
			line.Transparency = 1
			line.Visible = false
			tracerlines[p] = line
		end
		if skeletonenabled then
			local lines = {}
			for i = 1, 6 do
				local line = Drawing.new("Line")
				line.Thickness = 2
				line.Transparency = 1
				line.Visible = false
				lines[i] = line
			end
			skeletonlines[p] = lines
		end
		p.CharacterAdded:Connect(function(c)
			applyShieldEffect(p)
			if espenabled then task.wait(0.1) if not espobjects[p] then createesp(p) end end
			if outlineenabled then task.wait(0.1) applyhighlighttocharacter(p, c) end
		end)
	end
end)

Players.PlayerRemoving:Connect(function(p)
	removeesp(p)
	removehighlight(p)
	shieldedPlayers[p] = nil
	if tracerlines[p] then tracerlines[p]:Remove() tracerlines[p] = nil end
	if skeletonlines[p] then
		for _, line in ipairs(skeletonlines[p]) do line:Remove() end
		skeletonlines[p] = nil
	end
end)

for _, p in pairs(Players:GetPlayers()) do
	if p ~= LocalPlayer then
		p.CharacterAdded:Connect(function(c)
			applyShieldEffect(p)
			if espenabled then task.wait(0.1) if not espobjects[p] then createesp(p) end end
			if outlineenabled then task.wait(0.1) applyhighlighttocharacter(p, c) end
		end)
	end
end

RunService.RenderStepped:Connect(function(dt)
	fpsLabel:SetText("FPS: " .. math.floor(1 / dt))
	pingLabel:SetText("Ping: " .. math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) .. "ms")
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("Humanoid") then
		healthLabel:SetText("Health: " .. math.floor(char.Humanoid.Health))
	else
		healthLabel:SetText("Health: 0")
	end
	updateKnifeRangeSphere()
	if outlineenabled then
		for _, h in pairs(activehighlights) do
			if h then
				h.OutlineColor = espconfig.rainbowoutline and (rgbAsyncEnabled and getSyncRainbowColor() or getrainbowcolor()) or espconfig.outlinecolor
				h.FillColor = espconfig.rainbowoutline and (rgbAsyncEnabled and getSyncRainbowColor() or getrainbowcolor()) or espconfig.outlinefillcolor
			end
		end
	end
	updatefovcircle()
end)

task.spawn(function()
	while true do
		task.wait()
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
			LocalPlayer.Character.Humanoid.WalkSpeed = currentwalkspeed
		end
	end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomButtonGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999999999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = gethui and gethui() or game:GetService("CoreGui")

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HapticService = game:GetService("HapticService")

local button = Instance.new("ImageButton")
button.Name = "CustomButton"
button.Image = "rbxassetid://130346803512317"
button.BackgroundTransparency = 1
button.Position = UDim2.new(0.5, 0, 0, 50)
button.AnchorPoint = Vector2.new(0.5, 0)
button.Size = UDim2.new(0, 60, 0, 60)
button.ClipsDescendants = true
button.ZIndex = 999999999
button.Visible = showToggle
button.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 6)
uiCorner.Parent = button

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(255, 255, 255)
uiStroke.Thickness = 2
uiStroke.Parent = button

local uiGradient = Instance.new("UIGradient")
uiGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 140, 100)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 90, 65))
}
uiGradient.Rotation = 0
uiGradient.Parent = uiStroke

local function triggerSmallHaptic()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		local success, supported = pcall(function()
			return HapticService:IsMotorSupported(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small)
		end)
		if success and supported then
			HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0.3)
			task.delay(0.06, function()
				HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0)
			end)
		end
	end
end

local currentInput = nil
local dragStartPos = nil
local isDragging = false
local dragThreshold = 8
local clickStartTime = 0

button.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if currentInput then return end
		currentInput = input
		dragStartPos = input.Position
		isDragging = false
		clickStartTime = tick()
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == currentInput and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStartPos
		if delta.Magnitude > dragThreshold and not isDragging then
			isDragging = true
		end
		if isDragging then
			local newPos = UDim2.new(0, dragStartPos.X + delta.X, 0, dragStartPos.Y + delta.Y)
			TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {Position = newPos}):Play()
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input == currentInput then
		local clickDuration = tick() - clickStartTime
		if not isDragging and clickDuration < 0.3 then
			Library:Toggle()
			triggerSmallHaptic()
			local pos = input.Position
			local absPos = button.AbsolutePosition
			local absSize = button.AbsoluteSize
			local relX = (pos.X - absPos.X) / absSize.X
			local relY = (pos.Y - absPos.Y) / absSize.Y
			local wave = Instance.new("ImageLabel")
			wave.Size = UDim2.new(0, 0, 0, 0)
			wave.Position = UDim2.new(relX, 0, relY, 0)
			wave.AnchorPoint = Vector2.new(0.5, 0.5)
			wave.BackgroundTransparency = 1
			wave.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
			wave.ImageColor3 = Color3.fromRGB(255, 255, 255)
			wave.ImageTransparency = 0.3
			wave.ZIndex = 999999999
			wave.Parent = button
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(1, 0)
			corner.Parent = wave
			local tween = TweenService:Create(wave, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {
				Size = UDim2.new(2.5, 0, 2.5, 0),
				ImageTransparency = 1
			})
			tween:Play()
			task.delay(0.5, function() wave:Destroy() end)
		end
		currentInput = nil
		isDragging = false
	end
end)

button.MouseEnter:Connect(function()
	TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, button.Size.X.Offset * 1.08, 0, button.Size.Y.Offset * 1.08)
	}):Play()
end)

button.MouseLeave:Connect(function()
	local size = math.clamp(math.min(workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y) * 0.08, 50, 80)
	local scale = toggleSize / 100
	TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, size * scale, 0, size * scale)
	}):Play()
end)

local function updateButtonSize()
	local base = math.clamp(math.min(workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y) * 0.08, 50, 80)
	local scale = toggleSize / 100
	button.Size = UDim2.new(0, base * scale, 0, base * scale)
end

updateButtonSize()

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateButtonSize)

if showToggle then
	button.Visible = true
end

local function isPCPlatform()
    return not (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
end

if isPCPlatform() then
    button.Visible = showToggle
else
    print("NOT ON A PC!!!!, PASS!")
end

-- Final Notification
Window:Notify({
    Title = "Souls Hub Loaded",
    Desc = "Script loaded successfully!",
    Time = 4
})