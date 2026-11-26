local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local DAY_LENGTH = 180
local NIGHT_START = 18
local DAY_START = 6

local STORM_CHANCE = 0.5
local STORM_DURATION = 45
local MAP_RANGE = 60
local MAX_STORM_COINS = 15
local COIN_SPAWN_EVERY = 2
local STORM_COIN_VALUE = 5
local BOOST_SPEED = 26
local BOOST_TIME = 10
local NORMAL_SPEED = 16

local notifyEvent = ReplicatedStorage:WaitForChild("Notify")

local function announce(message)
	for _, player in ipairs(Players:GetPlayers()) do
		notifyEvent:FireClient(player, message)
	end
end

local boostIds = {}

local function giveBoost(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	humanoid.WalkSpeed = BOOST_SPEED
	player:SetAttribute("SpeedBoostEndTime", workspace:GetServerTimeNow() + BOOST_TIME)

	boostIds[player] = (boostIds[player] or 0) + 1
	local myId = boostIds[player]

	task.delay(BOOST_TIME, function()
		if player.Parent and boostIds[player] == myId then
			player:SetAttribute("SpeedBoostEndTime", nil)
			local currentCharacter = player.Character
			local currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
			if currentHumanoid then
				currentHumanoid.WalkSpeed = NORMAL_SPEED
			end
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	boostIds[player] = nil
end)

local function flash()
	Lighting.ExposureCompensation = 2
	TweenService:Create(Lighting, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		ExposureCompensation = 0,
	}):Play()
end

local function strikeLightning()
	local x = math.random(-MAP_RANGE, MAP_RANGE)
	local z = math.random(-MAP_RANGE, MAP_RANGE)

	local bolt = Instance.new("Part")
	bolt.Size = Vector3.new(0.8, 140, 0.8)
	bolt.Position = Vector3.new(x, 70, z)
	bolt.Anchored = true
	bolt.CanCollide = false
	bolt.CanTouch = false
	bolt.Color = Color3.fromRGB(230, 240, 255)
	bolt.Material = Enum.Material.Neon
	bolt.Parent = workspace
	Debris:AddItem(bolt, 0.15)

	flash()
end

local stormCoins = {}

RunService.Heartbeat:Connect(function(dt)
	for coin in pairs(stormCoins) do
		coin.CFrame = coin.CFrame * CFrame.Angles(0, math.rad(180) * dt, 0)
	end
end)

local function countStormCoins()
	local count = 0
	for _ in pairs(stormCoins) do
		count += 1
	end
	return count
end

local function spawnStormCoin()
	local coin = Instance.new("Part")
	coin.Name = "StormCoin"
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(0.4, 3, 3)
	coin.Color = Color3.fromRGB(90, 190, 255)
	coin.Material = Enum.Material.Neon
	coin.Anchored = true
	coin.CanCollide = false
	coin.CFrame = CFrame.new(math.random(-MAP_RANGE, MAP_RANGE), 3, math.random(-MAP_RANGE, MAP_RANGE))
		* CFrame.Angles(0, 0, math.rad(90))

	local light = Instance.new("PointLight")
	light.Color = coin.Color
	light.Range = 10
	light.Parent = coin

	coin.Parent = workspace
	stormCoins[coin] = true

	local collected = false
	coin.Touched:Connect(function(hit)
		if collected then return end

		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then return end

		local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Coins")
		if not coins then return end

		collected = true
		local multiplier = player:GetAttribute("CoinMultiplier") or 1
		coins.Value += STORM_COIN_VALUE * multiplier
		giveBoost(player)

		stormCoins[coin] = nil
		coin:Destroy()
	end)
end

local function runStorm()
	announce("⛈️ A thunderstorm rolls in! Grab the blue coins!")

	local rainPart = Instance.new("Part")
	rainPart.Name = "RainCloud"
	rainPart.Size = Vector3.new(MAP_RANGE * 2 + 60, 1, MAP_RANGE * 2 + 60)
	rainPart.Position = Vector3.new(0, 90, 0)
	rainPart.Transparency = 1
	rainPart.Anchored = true
	rainPart.CanCollide = false
	rainPart.CanTouch = false
	rainPart.Parent = workspace

	local rain = Instance.new("ParticleEmitter")
	rain.Rate = 400
	rain.Lifetime = NumberRange.new(1.5, 1.8)
	rain.Speed = NumberRange.new(70, 80)
	rain.EmissionDirection = Enum.NormalId.Bottom
	rain.SpreadAngle = Vector2.new(3, 3)
	rain.Orientation = Enum.ParticleOrientation.VelocityParallel
	rain.Size = NumberSequence.new(0.4)
	rain.Color = ColorSequence.new(Color3.fromRGB(170, 200, 255))
	rain.Transparency = NumberSequence.new(0.4)
	rain.Parent = rainPart

	for i = 1, 8 do
		spawnStormCoin()
	end

	local endTime = os.clock() + STORM_DURATION
	local nextStrike = os.clock() + math.random(2, 4)
	local nextCoin = os.clock() + COIN_SPAWN_EVERY

	while os.clock() < endTime do
		task.wait(0.25)

		if os.clock() >= nextStrike then
			strikeLightning()
			nextStrike = os.clock() + math.random(3, 7)
		end

		if os.clock() >= nextCoin then
			if countStormCoins() < MAX_STORM_COINS then
				spawnStormCoin()
			end
			nextCoin = os.clock() + COIN_SPAWN_EVERY
		end
	end

	rain.Enabled = false
	Debris:AddItem(rainPart, 3)

	for coin in pairs(stormCoins) do
		coin:Destroy()
		stormCoins[coin] = nil
	end

	announce("The storm has passed.")
end

Lighting.ClockTime = 12
local wasNight = false

RunService.Heartbeat:Connect(function(dt)
	Lighting.ClockTime = (Lighting.ClockTime + dt * 24 / DAY_LENGTH) % 24

	local clock = Lighting.ClockTime
	local isNight = clock >= NIGHT_START or clock < DAY_START

	if isNight and not wasNight then
		if math.random() < STORM_CHANCE and #Players:GetPlayers() > 0 then
			task.spawn(runStorm)
		end
	end

	wasNight = isNight
end)
