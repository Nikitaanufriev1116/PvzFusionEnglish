local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local RE_Click = RemotesFolder:WaitForChild("Click")
local RE_RequestEvolution = RemotesFolder:WaitForChild("RequestEvolution")
local RE_BuyUpgrade = RemotesFolder:WaitForChild("BuyUpgrade")
local RE_ToggleAutoClick = RemotesFolder:WaitForChild("ToggleAutoClick")
local RE_PushState = RemotesFolder:WaitForChild("PushState")
local RE_Notify = RemotesFolder:WaitForChild("Notify")
local RF_GetState = RemotesFolder:WaitForChild("GetState")

-- State
local state = RF_GetState:InvokeServer()

-- UI helpers
local function create(className, props, children)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, c in ipairs(children or {}) do
		c.Parent = inst
	end
	return inst
end

local function round(n)
	return math.floor(n + 0.5)
end

-- Build UI
local screenGui = create("ScreenGui", { Name = "BrainRotUI", ResetOnSpawn = false })

local topBar = create("Frame", {
	Name = "TopBar",
	Size = UDim2.new(1, -20, 0, 60),
	Position = UDim2.new(0, 10, 0, 10),
	BackgroundTransparency = 0.2,
	BackgroundColor3 = Color3.fromRGB(25,25,35)
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 8) }),
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10) })
})

local brLabel = create("TextLabel", {
	Name = "BR",
	Size = UDim2.new(0, 280, 1, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	TextColor3 = Color3.fromRGB(255,255,255),
	TextXAlignment = Enum.TextXAlignment.Left
})

local evoLabel = create("TextLabel", {
	Name = "Evo",
	Size = UDim2.new(0, 280, 1, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextScaled = true,
	TextColor3 = Color3.fromRGB(200,220,255),
	TextXAlignment = Enum.TextXAlignment.Left
})

local perClickLabel = create("TextLabel", {
	Name = "PerClick",
	Size = UDim2.new(0, 260, 1, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextScaled = true,
	TextColor3 = Color3.fromRGB(200,255,220),
	TextXAlignment = Enum.TextXAlignment.Left
})

brLabel.Parent = topBar
evoLabel.Parent = topBar

local spacer = create("Frame", { Size = UDim2.new(1, -20-280-280-260, 1, 0), BackgroundTransparency = 1 })
spacer.Parent = topBar

perClickLabel.Parent = topBar

topBar.Parent = screenGui

local progressFrame = create("Frame", {
	Name = "Progress",
	Size = UDim2.new(1, -20, 0, 24),
	Position = UDim2.new(0, 10, 0, 80),
	BackgroundTransparency = 0.3,
	BackgroundColor3 = Color3.fromRGB(35,35,50)
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 8) })
})
local progressBar = create("Frame", {
	Name = "Fill",
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = Color3.fromRGB(80,120,255)
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 8) })
})
progressBar.Parent = progressFrame

local progressText = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, 0),
	Font = Enum.Font.Gotham,
	TextScaled = true,
	TextColor3 = Color3.fromRGB(255,255,255),
	Text = ""
})
progressText.Parent = progressFrame

local clickButton = create("TextButton", {
	Name = "ClickButton",
	Size = UDim2.new(0, 360, 0, 120),
	Position = UDim2.new(0.5, -180, 0.5, -60),
	BackgroundColor3 = Color3.fromRGB(70, 110, 255),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
	Text = "CLICK"
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 12) })
})

local evolveButton = create("TextButton", {
	Name = "Evolve",
	Size = UDim2.new(0, 220, 0, 60),
	Position = UDim2.new(0, 10, 1, -70),
	BackgroundColor3 = Color3.fromRGB(255, 120, 90),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextScaled = true,
	Font = Enum.Font.GothamBold,
	Text = "Эволюция"
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 10) })
})

local shopButton = create("TextButton", {
	Name = "ShopToggle",
	Size = UDim2.new(0, 220, 0, 60),
	Position = UDim2.new(1, -230, 1, -70),
	BackgroundColor3 = Color3.fromRGB(90, 200, 150),
	TextColor3 = Color3.fromRGB(25, 35, 35),
	TextScaled = true,
	Font = Enum.Font.GothamBold,
	Text = "Магазин"
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 10) })
})

local shopFrame = create("Frame", {
	Name = "Shop",
	Size = UDim2.new(0, 360, 0, 340),
	Position = UDim2.new(1, -380, 0, 110),
	BackgroundColor3 = Color3.fromRGB(25,25,35),
	BackgroundTransparency = 0.1,
	Visible = false
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 12) }),
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
})

local notifyFrame = create("TextLabel", {
	Name = "Notify",
	Size = UDim2.new(0, 420, 0, 50),
	Position = UDim2.new(0.5, -210, 0, 40),
	BackgroundTransparency = 0.3,
	BackgroundColor3 = Color3.fromRGB(25,25,25),
	TextColor3 = Color3.fromRGB(255,255,255),
	TextScaled = true,
	Font = Enum.Font.Gotham,
	Text = "",
	Visible = false
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 8) })
})

-- Shop items
local function makeShopItem(id, title)
	local btn = create("TextButton", {
		Name = id,
		Size = UDim2.new(1, -12, 0, 70),
		Position = UDim2.new(0, 6, 0, 0),
		BackgroundColor3 = Color3.fromRGB(45, 55, 75),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		Font = Enum.Font.Gotham,
		Text = title
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 8) })
	})
	btn.MouseButton1Click:Connect(function()
		RE_BuyUpgrade:FireServer(id)
	end)
	return btn
end

local shopItems = {
	makeShopItem("clickMultiplier", "Клик‑множитель"),
	makeShopItem("passiveIncome", "Пассивный доход"),
	makeShopItem("autoClicker", "Автокликер"),
}
for _, it in ipairs(shopItems) do it.Parent = shopFrame end

-- Mount UI
screenGui.Parent = PlayerGui
progressFrame.Parent = screenGui
clickButton.Parent = screenGui
evolveButton.Parent = screenGui
shopButton.Parent = screenGui
shopFrame.Parent = screenGui
notifyFrame.Parent = screenGui

-- Render
local function formatNumber(n)
	local left, num, right = string.match(tostring(n), '^([^%d]*%d)(%d*)(.-)$')
	return left .. (num:reverse():gsub("(%d%d%d)", "%1 "):reverse()) .. right
end

local function render()
	local perClick = state and state.upgrades and (2 ^ (state.upgrades.clickMultiplierLevel or 0)) or 1
	brLabel.Text = "BR: " .. formatNumber(round(state.brainRot or 0))
	evoLabel.Text = "Эволюция: " .. tostring(state.stageName or ("#"..tostring(state.evolution)))
	perClickLabel.Text = "+/клик: " .. tostring(perClick)

	local nextCost = state.nextEvolutionCost or math.huge
	local have = state.brainRot or 0
	local pct = 0
	if nextCost < math.huge and nextCost > 0 then
		pct = math.clamp(have / nextCost, 0, 1)
	end
	TweenService:Create(progressBar, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(pct, 0, 1, 0) }):Play()
	if nextCost == math.huge then
		progressText.Text = "Достигнута финальная стадия"
	else
		progressText.Text = string.format("До следующей: %s / %s", formatNumber(round(have)), formatNumber(round(nextCost)))
	end

	-- Shop button labels with dynamic cost/level
	for _, btn in ipairs(shopItems) do
		local id = btn.Name
		if id == "clickMultiplier" then
			local level = state.upgrades.clickMultiplierLevel or 0
			btn.Text = string.format("Клик‑множитель (ур. %d)", level)
		elseif id == "passiveIncome" then
			local level = state.upgrades.passiveIncomeLevel or 0
			btn.Text = string.format("Пассивный доход (ур. %d)", level)
		elseif id == "autoClicker" then
			btn.Text = state.upgrades.autoClickerOwned and "Автокликер (куплено)" or "Автокликер"
		end
	end
end

-- Notify
local notifyTweenIn = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local notifyTweenOut = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local function notify(text)
	notifyFrame.Text = tostring(text)
	notifyFrame.Visible = true
	TweenService:Create(notifyFrame, notifyTweenIn, { BackgroundTransparency = 0.1 }):Play()
	task.delay(1.2, function()
		TweenService:Create(notifyFrame, notifyTweenOut, { BackgroundTransparency = 0.8 }):Play()
		task.delay(0.35, function()
			notifyFrame.Visible = false
		end)
	end)
end

-- Interactions
clickButton.MouseButton1Click:Connect(function()
	RE_Click:FireServer()
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Space then
		RE_Click:FireServer()
	end
end)

evolveButton.MouseButton1Click:Connect(function()
	RE_RequestEvolution:FireServer()
end)

shopButton.MouseButton1Click:Connect(function()
	shopFrame.Visible = not shopFrame.Visible
end)

RE_PushState.OnClientEvent:Connect(function(newState)
	state = newState
	render()
end)

RE_Notify.OnClientEvent:Connect(function(msg)
	notify(msg)
end)

-- Initial render
render()