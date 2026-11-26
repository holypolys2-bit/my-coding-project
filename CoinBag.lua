local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local MIN_WAIT = 10
local MAX_WAIT = 30
local DROP_HEIGHT = 200
local BAG_LIFETIME = 30
local MAP_RANGE = 60

local NORMAL_MIN = 10
local NORMAL_MAX = 30
local GOLDEN_CHANCE = 0.1
local GOLDEN_VALUE = 100

local notifyEvent = ReplicatedStorage:WaitForChild("Notify")

local function announce(message)
	for _, player in ipairs(Players:GetPlayers()) do
		notifyEvent:FireClient(player, message)
	end
end

local function findGround(x, z)
	local result = workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -1000, 0))
	return result and result.Position
end

local function dropBag()
	local x = math.random(-MAP_RANGE, MAP_RANGE)
	local z = math.random(-MAP_RANGE, MAP_RANGE)
	local ground = findGround(x, z)
	if not ground then return end

	local isGolden = math.random() < GOLDEN_CHANCE

	local marker = Instance.new("Part")
	marker.Name = "BagMarker"
	marker.Shape = Enum.PartType.Cylinder
	marker.Size = Vector3.new(0.2, 8, 8)
	marker.CFrame = CFrame.new(ground + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanTouch = false
	marker.Color = isGolden and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 70, 70)
	marker.Material = Enum.Material.Neon
	marker.Transparency = 0.3
	marker.Parent = workspace

	TweenService:Create(marker, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Transparency = 0.8,
	}):Play()

	local bag = Instance.new("Part")
	bag.Name = "CoinBag"
	bag.Shape = Enum.PartType.Ball
	bag.Size = isGolden and Vector3.new(5, 5, 5) or Vector3.new(3.5, 3.5, 3.5)
	bag.Position = Vector3.new(ground.X, DROP_HEIGHT, ground.Z)
	bag.Color = isGolden and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(139, 90, 43)
	bag.Material = isGolden and Enum.Material.Neon or Enum.Material.Fabric
	bag.Parent = workspace
	bag:SetNetworkOwner(nil)

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(60, 60)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = bag

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.fromScale(1, 1)
	icon.BackgroundTransparency = 1
	icon.Text = isGolden and "🌟" or "💰"
	icon.TextScaled = true
	icon.Parent = billboard

	if isGolden then
		announce("🌟 A GOLDEN coin bag is falling!")
	else
		announce("💰 A coin bag is falling from the sky!")
	end

	local collected = false

	bag.Touched:Connect(function(hit)
		if collected then return end

		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then return end

		local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Coins")
		if not coins then return end

		collected = true

		local value = isGolden and GOLDEN_VALUE or math.random(NORMAL_MIN, NORMAL_MAX)
		local multiplier = player:GetAttribute("CoinMultiplier") or 1
		local total = value * multiplier
		coins.Value += total

		notifyEvent:FireClient(player, (isGolden and "🌟 Golden bag! +" or "💰 Bag! +") .. total .. " coins")

		marker:Destroy()
		bag:Destroy()
	end)

	Debris:AddItem(bag, BAG_LIFETIME)
	Debris:AddItem(marker, BAG_LIFETIME)
end

while true do
	task.wait(math.random(MIN_WAIT, MAX_WAIT))
	if #Players:GetPlayers() > 0 then
		task.spawn(dropBag)
	end
end
