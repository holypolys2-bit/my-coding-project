local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local COIN_TAG = "Coin"
local COIN_VALUE = 1
local RESPAWN_TIME = 5
local SPIN_SPEED = math.rad(120)
local AUTO_SPAWN_COUNT = 20
local MAP_RANGE = 60

local RAINBOW_CHANCE = 0.1
local RAINBOW_VALUE = 10
local NORMAL_COLOR = Color3.fromRGB(255, 200, 0)

Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = leaderstats
end)

local spinningCoins = {}
local rainbowCoins = {}

RunService.Heartbeat:Connect(function(dt)
	local hue = (os.clock() / 3) % 1

	for coin in pairs(spinningCoins) do
		coin.CFrame = coin.CFrame * CFrame.Angles(0, SPIN_SPEED * dt, 0)
	end

	for coin in pairs(rainbowCoins) do
		coin.Color = Color3.fromHSV(hue, 1, 1)
	end
end)

local function rollCoinType(coin)
	if math.random() < RAINBOW_CHANCE then
		coin:SetAttribute("Value", RAINBOW_VALUE)
		rainbowCoins[coin] = true
	else
		coin:SetAttribute("Value", COIN_VALUE)
		rainbowCoins[coin] = nil
		coin.Color = NORMAL_COLOR
	end
end

local function setupCoin(coin)
	if not coin:IsA("BasePart") then return end

	local available = true
	coin.Anchored = true
	coin.CanCollide = false
	spinningCoins[coin] = true
	rollCoinType(coin)

	coin.Touched:Connect(function(hit)
		if not available then return end

		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then return end

		local leaderstats = player:FindFirstChild("leaderstats")
		local coins = leaderstats and leaderstats:FindFirstChild("Coins")
		if not coins then return end

		available = false

		local value = coin:GetAttribute("Value") or COIN_VALUE
		local multiplier = player:GetAttribute("CoinMultiplier") or 1
		coins.Value += value * multiplier

		coin.Transparency = 1
		coin.CanTouch = false
		spinningCoins[coin] = nil
		rainbowCoins[coin] = nil

		task.delay(RESPAWN_TIME, function()
			rollCoinType(coin)
			coin.Transparency = 0
			coin.CanTouch = true
			spinningCoins[coin] = true
			available = true
		end)
	end)
end

for _, coin in ipairs(CollectionService:GetTagged(COIN_TAG)) do
	setupCoin(coin)
end
CollectionService:GetInstanceAddedSignal(COIN_TAG):Connect(setupCoin)

for i = 1, AUTO_SPAWN_COUNT do
	local coin = Instance.new("Part")
	coin.Name = "Coin"
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(0.4, 3, 3)
	coin.Color = NORMAL_COLOR
	coin.Material = Enum.Material.Neon
	coin.CFrame = CFrame.new(math.random(-MAP_RANGE, MAP_RANGE), 3, math.random(-MAP_RANGE, MAP_RANGE))
		* CFrame.Angles(0, 0, math.rad(90))
	coin.Parent = workspace
	CollectionService:AddTag(coin, COIN_TAG)
end

print("CoinCollector finished, coins tagged:", #CollectionService:GetTagged(COIN_TAG))
