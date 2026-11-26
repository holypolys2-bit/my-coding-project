local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local MIN_WAIT = 60
local MAX_WAIT = 120
local DURATION = 25
local COIN_COUNT = 36
local MAP_RANGE = 50
local PICKUP_DISTANCE = 5
local BOTTOM_VALUE = 2
local TOP_VALUE = 10

local notifyEvent = ReplicatedStorage:WaitForChild("Notify")

local function announce(message)
	for _, player in ipairs(Players:GetPlayers()) do
		notifyEvent:FireClient(player, message)
	end
end

local function randomSpot()
	return Vector3.new(math.random(-MAP_RANGE, MAP_RANGE), 0, math.random(-MAP_RANGE, MAP_RANGE))
end

local function startTornado()
	local center = randomSpot()
	local target = randomSpot()
	local elapsed = 0

	local core = Instance.new("Part")
	core.Name = "TornadoCore"
	core.Size = Vector3.new(1, 1, 1)
	core.Transparency = 1
	core.Anchored = true
	core.CanCollide = false
	core.CanTouch = false
	core.Position = center
	core.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 60
	emitter.Lifetime = NumberRange.new(2, 3)
	emitter.Speed = NumberRange.new(15, 20)
	emitter.SpreadAngle = Vector2.new(8, 8)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 4),
		NumberSequenceKeypoint.new(1, 14),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Color = ColorSequence.new(Color3.fromRGB(200, 200, 200))
	emitter.RotSpeed = NumberRange.new(-120, 120)
	emitter.Parent = core

	local coinList = {}
	for i = 1, COIN_COUNT do
		local height = (i - 1) / (COIN_COUNT - 1)

		local part = Instance.new("Part")
		part.Name = "TornadoCoin"
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(0.4, 2.5, 2.5)
		part.Color = Color3.fromHSV(0.12 + height * 0.1, 1, 1)
		part.Material = Enum.Material.Neon
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.Parent = workspace

		table.insert(coinList, {
			part = part,
			height = height,
			offset = i * 2.4,
			value = height > 0.85 and TOP_VALUE or BOTTOM_VALUE,
		})
	end

	local totals = {}
	announce("🌪️ A Coin Tornado has formed! Run into the coins!")

	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt

		if elapsed >= DURATION then
			connection:Disconnect()
			core:Destroy()
			for _, coin in ipairs(coinList) do
				coin.part:Destroy()
			end
			for player, total in pairs(totals) do
				if player.Parent then
					notifyEvent:FireClient(player, "🌪️ You grabbed " .. total .. " coins from the tornado!")
				end
			end
			announce("The Coin Tornado has faded.")
			return
		end

		center = center:Lerp(target, math.min(1, dt * 0.3))
		if (center - target).Magnitude < 3 then
			target = randomSpot()
		end
		core.Position = center

		local roots = {}
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				table.insert(roots, { player = player, root = root })
			end
		end

		for i = #coinList, 1, -1 do
			local coin = coinList[i]
			local angle = coin.offset + elapsed * (3 - coin.height * 1.5)
			local radius = 3 + coin.height * 14
			local position = center + Vector3.new(math.cos(angle) * radius, 1.5 + coin.height * 35, math.sin(angle) * radius)

			coin.part.CFrame = CFrame.new(position) * CFrame.Angles(0, elapsed * 4 + coin.offset, 0)

			for _, entry in ipairs(roots) do
				if (entry.root.Position - position).Magnitude < PICKUP_DISTANCE then
					local coins = entry.player:FindFirstChild("leaderstats") and entry.player.leaderstats:FindFirstChild("Coins")
					if coins then
						local multiplier = entry.player:GetAttribute("CoinMultiplier") or 1
						local amount = coin.value * multiplier
						coins.Value += amount
						totals[entry.player] = (totals[entry.player] or 0) + amount
					end
					coin.part:Destroy()
					table.remove(coinList, i)
					break
				end
			end
		end
	end)

	Debris:AddItem(core, DURATION + 5)
end

while true do
	task.wait(math.random(MIN_WAIT, MAX_WAIT))
	if #Players:GetPlayers() > 0 then
		startTornado()
	end
end
