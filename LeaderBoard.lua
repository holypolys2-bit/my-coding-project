local Players = game:GetService("Players")

local UPDATE_EVERY = 2
local SHOW_TOP = 5


local board = Instance.new("Part")
board.Name = "TopCoinsBoard"
board.Size = Vector3.new(16, 9, 1)
board.Position = Vector3.new(0, 6, -40)
board.Anchored = true
board.Color = Color3.fromRGB(25, 25, 25)
board.Material = Enum.Material.SmoothPlastic
board.Parent = workspace


local surface = Instance.new("SurfaceGui")
surface.Face = Enum.NormalId.Back
surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
surface.PixelsPerStud = 50
surface.Parent = board

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1, 0.2)
title.BackgroundTransparency = 1
title.Text = "🏆 TOP COINS"
title.TextColor3 = Color3.fromRGB(255, 200, 0)
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.Parent = surface

local list = Instance.new("TextLabel")
list.Position = UDim2.fromScale(0, 0.22)
list.Size = UDim2.fromScale(1, 0.75)
list.BackgroundTransparency = 1
list.TextColor3 = Color3.new(1, 1, 1)
list.Font = Enum.Font.GothamBold
list.TextSize = 38
list.TextYAlignment = Enum.TextYAlignment.Top
list.Text = ""
list.Parent = surface

local function refresh()
	local entries = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Coins")
		if coins then
			table.insert(entries, { name = player.Name, coins = coins.Value })
		end
	end

	
	table.sort(entries, function(a, b)
		return a.coins > b.coins
	end)

	local lines = {}
	for i = 1, math.min(SHOW_TOP, #entries) do
		table.insert(lines, i .. ". " .. entries[i].name .. "  -  " .. entries[i].coins)
	end

	list.Text = table.concat(lines, "\n")
end

while true do
	refresh()
	task.wait(UPDATE_EVERY)
end
