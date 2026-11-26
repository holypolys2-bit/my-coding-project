local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local MIN_WAIT = 30 
local MAX_WAIT = 60

local notifyEvent = ReplicatedStorage:WaitForChild("Notify")


local function announce(message)
	for _, player in ipairs(Players:GetPlayers()) do
		notifyEvent:FireClient(player, message)
	end
end


local function coinRain()
	announce("💰 Coin Rain! Grab them fast!")

	for i = 1, 15 do
		local coin = Instance.new("Part")
		coin.Name = "Coin"
		coin.Shape = Enum.PartType.Cylinder
		coin.Size = Vector3.new(0.4, 3, 3)
		coin.Color = Color3.fromRGB(255, 200, 0)
		coin.Material = Enum.Material.Neon
		coin.CFrame = CFrame.new(math.random(-60, 60), 3, math.random(-60, 60))
			* CFrame.Angles(0, 0, math.rad(90))
		coin.Parent = workspace
		CollectionService:AddTag(coin, "Coin") 

		Debris:AddItem(coin, 20) 
	end

	task.wait(20)
end


local function speedFrenzy()
	announce("⚡ Speed Frenzy! Everyone is faster for 15 seconds!")

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 30
		end
	end

	task.wait(15)

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16
		end
	end
	announce("Speed Frenzy is over.")
end


local function lowGravity()
	announce("🌙 Low Gravity! Try jumping!")
	workspace.Gravity = 50
	task.wait(15)
	workspace.Gravity = 196.2 -- Roblox default
	announce("Gravity is back to normal.")
end


local events = { coinRain, speedFrenzy, lowGravity }


while true do
	task.wait(math.random(MIN_WAIT, MAX_WAIT))

	if #Players:GetPlayers() > 0 then
		local pickedEvent = events[math.random(1, #events)]
		pickedEvent()
	end
end
