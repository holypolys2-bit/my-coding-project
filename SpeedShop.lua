local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PRICE = 10
local BOOST_SPEED = 28
local NORMAL_SPEED = 16
local BOOST_TIME = 30


local notifyEvent = Instance.new("RemoteEvent")
notifyEvent.Name = "Notify"
notifyEvent.Parent = ReplicatedStorage


local shop = Instance.new("Part")
shop.Name = "SpeedShop"
shop.Size = Vector3.new(6, 8, 6)
shop.Position = Vector3.new(0, 4, -20)
shop.Anchored = true
shop.BrickColor = BrickColor.new("Bright blue")
shop.Material = Enum.Material.SmoothPlastic
shop.Parent = workspace

local prompt = Instance.new("ProximityPrompt")
prompt.ObjectText = "Speed Shop"
prompt.ActionText = "Buy Speed Boost (" .. PRICE .. " coins)"
prompt.HoldDuration = 0.5
prompt.MaxActivationDistance = 10
prompt.Parent = shop

local activeBoosts = {} 

prompt.Triggered:Connect(function(player)
	if activeBoosts[player] then
		notifyEvent:FireClient(player, "You already have a boost running!")
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if not coins then return end

	
	if coins.Value < PRICE then
		notifyEvent:FireClient(player, "Not enough coins! Need " .. PRICE)
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	coins.Value -= PRICE
	humanoid.WalkSpeed = BOOST_SPEED
	activeBoosts[player] = true
	notifyEvent:FireClient(player, "Speed boost active for " .. BOOST_TIME .. "s!")

	task.delay(BOOST_TIME, function()
		activeBoosts[player] = nil
		
		if player.Parent and humanoid.Parent then
			humanoid.WalkSpeed = NORMAL_SPEED
			notifyEvent:FireClient(player, "Speed boost ended.")
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	activeBoosts[player] = nil
end)

