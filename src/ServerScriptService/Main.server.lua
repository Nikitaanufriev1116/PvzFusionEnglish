local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local ShopService = require(script.Parent.ShopService)
local EvolutionService = require(script.Parent.EvolutionService)
local AntiExploit = require(script.Parent.AntiExploit)

-- Remotes setup
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
end

local function getOrCreateRemoteEvent(name)
	local r = Remotes:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = Remotes
	end
	return r
end

local function getOrCreateRemoteFunction(name)
	local r = Remotes:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteFunction")
		r.Name = name
		r.Parent = Remotes
	end
	return r
end

local RE_Click = getOrCreateRemoteEvent("Click")
local RE_RequestEvolution = getOrCreateRemoteEvent("RequestEvolution")
local RE_BuyUpgrade = getOrCreateRemoteEvent("BuyUpgrade")
local RE_ToggleAutoClick = getOrCreateRemoteEvent("ToggleAutoClick")
local RE_PushState = getOrCreateRemoteEvent("PushState")
local RE_Notify = getOrCreateRemoteEvent("Notify")
local RF_GetState = getOrCreateRemoteFunction("GetState")

-- State
local playerStates = {}
local clickWindows = {}

local function defaultState()
	return {
		brainRot = 0,
		evolution = 1,
		upgrades = {
			clickMultiplierLevel = 0,
			passiveIncomeLevel = 0,
			autoClickerOwned = false,
			autoClickerEnabled = false,
		},
		totalClicks = 0,
		rebirths = 0,
		lastLoginUnix = os.time(),
	}
end

local function sanitizeForClient(state)
	local copy = table.clone(state)
	copy.nextEvolutionCost = EvolutionService.getNextCost(state.evolution)
	copy.stageCount = #Config.EvolutionStages
	copy.stageName = Config.EvolutionStages[math.clamp(state.evolution, 1, #Config.EvolutionStages)].name
	return copy
end

local function sendState(player)
	local state = playerStates[player]
	if state then
		RE_PushState:FireClient(player, sanitizeForClient(state))
	end
end

local function updateLeaderstats(player)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end
	local evo = stats:FindFirstChild("Evo")
	local br = stats:FindFirstChild("BR")
	if evo then evo.Value = playerStates[player].evolution end
	if br then br.Value = math.floor(playerStates[player].brainRot) end
end

local function applyStage(player)
	local state = playerStates[player]
	if not state then return end
	EvolutionService.applyStageAppearance(player, state.evolution)
end

local function addBrainRot(player, amount)
	local state = playerStates[player]
	if not state then return end
	state.brainRot = math.max(0, state.brainRot + amount)
	updateLeaderstats(player)
	sendState(player)
end

-- Autosave
local function periodicSave()
	while task.wait(Config.SaveIntervalSeconds) do
		for player, state in pairs(playerStates) do
			pcall(function()
				DataService.save(player, state)
			end)
		end
	end
end

task.spawn(periodicSave)

-- Passive + autoclick tick
local function periodicIncome()
	while task.wait(1) do
		for player, state in pairs(playerStates) do
			local passive = ShopService.getPassiveIncomePerSecond(state.upgrades.passiveIncomeLevel)
			if passive > 0 then addBrainRot(player, passive) end
			if state.upgrades.autoClickerOwned and state.upgrades.autoClickerEnabled then
				local clicks = Config.AutoClickClicksPerSecond
				local gainPerClick = Config.BaseClickGain * ShopService.getClickMultiplier(state.upgrades.clickMultiplierLevel)
				addBrainRot(player, gainPerClick * clicks)
			end
		end
	end
end

task.spawn(periodicIncome)

-- Player lifecycle
DataService.init(Config)

Players.PlayerAdded:Connect(function(player)
	-- Leaderstats
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player
	local br = Instance.new("IntValue")
	br.Name = "BR"
	br.Parent = stats
	local evo = Instance.new("IntValue")
	evo.Name = "Evo"
	evo.Parent = stats

	-- Load state
	local loaded = DataService.load(player) or defaultState()
	playerStates[player] = loaded
	clickWindows[player] = AntiExploit.createClickWindow()

	updateLeaderstats(player)
	sendState(player)

	player.CharacterAdded:Connect(function()
		applyStage(player)
	end)
	applyStage(player)
end)

Players.PlayerRemoving:Connect(function(player)
	local state = playerStates[player]
	if state then
		pcall(function()
			DataService.save(player, state)
		end)
		playerStates[player] = nil
		clickWindows[player] = nil
	end
end)

game:BindToClose(function()
	for player, state in pairs(playerStates) do
		pcall(function()
			DataService.save(player, state)
		end)
	end
end)

-- Remotes
RE_Click.OnServerEvent:Connect(function(player)
	local state = playerStates[player]
	if not state then return end
	local clickWindow = clickWindows[player]
	if not clickWindow then
		clickWindow = AntiExploit.createClickWindow()
		clickWindows[player] = clickWindow
	end
	if not AntiExploit.allowClick(clickWindow, Config) then return end
	local gain = Config.BaseClickGain * ShopService.getClickMultiplier(state.upgrades.clickMultiplierLevel)
	state.totalClicks += 1
	addBrainRot(player, gain)
end)

RE_RequestEvolution.OnServerEvent:Connect(function(player)
	local state = playerStates[player]
	if not state then return end
	local nextCost = EvolutionService.getNextCost(state.evolution)
	if state.evolution >= #Config.EvolutionStages then
		RE_Notify:FireClient(player, "Максимальная стадия")
		return
	end
	if state.brainRot >= nextCost then
		state.brainRot -= nextCost
		state.evolution += 1
		applyStage(player)
		updateLeaderstats(player)
		sendState(player)
		RE_Notify:FireClient(player, "Эволюция: " .. Config.EvolutionStages[state.evolution].name)
	else
		RE_Notify:FireClient(player, "Нужно BR: " .. tostring(nextCost))
	end
end)

RE_BuyUpgrade.OnServerEvent:Connect(function(player, id)
	local state = playerStates[player]
	if not state then return end
	if typeof(id) ~= "string" then return end
	local ok, msg = ShopService.tryBuyUpgrade(state, id)
	if ok then
		updateLeaderstats(player)
		sendState(player)
		RE_Notify:FireClient(player, "Куплено: " .. id)
	else
		if msg then RE_Notify:FireClient(player, msg) end
	end
end)

RE_ToggleAutoClick.OnServerEvent:Connect(function(player)
	local state = playerStates[player]
	if not state then return end
	if not state.upgrades.autoClickerOwned then return end
	state.upgrades.autoClickerEnabled = not state.upgrades.autoClickerEnabled
	sendState(player)
end)

RF_GetState.OnServerInvoke = function(player)
	local state = playerStates[player]
	if not state then return defaultState() end
	return sanitizeForClient(state)
end