local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PRICE = 25
local PAY_INTERVAL = 10 
local PAY_AMOUNT = 1

local notifyEvent = ReplicatedStorage:WaitForChild("Notify")


local shop = Instance.new("Part")
shop.Name = "PetShop"
shop.Size = Vector3.new(6, 8, 6)
shop.Position = Vector3.new(-24, 4, -20)
shop.Anchored = true
shop.Color = Color3.fromRGB(255, 120, 200)
shop.Material = Enum.Material.Neon
shop.Parent = workspace

local prompt = Instance.new("ProximityPrompt")
prompt.ObjectText = "Pet Shop"
prompt.ActionText = "Buy a Pet (" .. PRICE .. " coins)"
prompt.HoldDuration = 0.5
prompt.MaxActivationDistance = 10
prompt.Parent = shop

local pets = {} 

local function createPet(player)
	local part = Instance.new("Part")
	part.Name = player.Name .. "Pet"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(2, 2, 2)
	part.Color = Color3.fromHSV(math.random(), 0.7, 1) 
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false

	local light = Instance.new("PointLight")
	light.Color = part.Color
	light.Range = 12
	light.Parent = part

	
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		part.Position = root.Position
	end

	part.Parent = workspace
	pets[player] = { part = part, nextPay = os.clock() + PAY_INTERVAL }
end

prompt.Triggered:Connect(function(player)
	if pets[player] then
		notifyEvent:FireClient(player, "You already have a pet!")
		return
	end

	local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Coins")
	if not coins then return end

	if coins.Value < PRICE then
		notifyEvent:FireClient(player, "Not enough coins! Need " .. PRICE)
		return
	end

	coins.Value -= PRICE
	createPet(player)
	notifyEvent:FireClient(player, "🐾 New pet! It earns you coins over time.")
end)


RunService.Heartbeat:Connect(function(dt)
	for player, data in pairs(pets) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")

		if root then
			
			local bob = math.sin(os.clock() * 3) * 0.4
			local target = root.CFrame * Vector3.new(3, 1.5 + bob, 3)

			
			data.part.Position = data.part.Position:Lerp(target, math.min(1, dt * 6))
		end

		
		if os.clock() >= data.nextPay then
			data.nextPay = os.clock() + PAY_INTERVAL
			local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Coins")
			if coins then
				coins.Value += PAY_AMOUNT
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local data = pets[player]
	if data then
		data.part:Destroy()
		pets[player] = nil
	end
end)
