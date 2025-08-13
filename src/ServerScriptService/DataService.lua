local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local DataService = {}

local DATA_KEY_PREFIX = "u_"

local function getDefaults()
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

local store

function DataService.init(config)
	local name = config.DataStoreName or "BREVO_Data_v1"
	store = DataStoreService:GetDataStore(name)
end

local function try(times, fn)
	local lastErr
	for i = 1, times do
		local ok, res = pcall(fn)
		if ok then
			return res
		else
			lastErr = res
			if i < times then task.wait(0.5 * i) end
		end
	end
	warn("DataService error:", lastErr)
	return nil
end

function DataService.load(player)
	local key = DATA_KEY_PREFIX .. tostring(player.UserId)
	if RunService:IsStudio() then
		-- In Studio, to avoid throttling during dev, use mock load with no errors
		local data = getDefaults()
		return data
	end
	local data = try(3, function()
		return store:GetAsync(key)
	end)
	if typeof(data) ~= "table" then
		data = getDefaults()
	end
	-- Merge defaults to survive schema changes
	local defaults = getDefaults()
	for k, v in pairs(defaults) do
		if data[k] == nil then data[k] = v end
	end
	for k, v in pairs(defaults.upgrades) do
		if data.upgrades[k] == nil then data.upgrades[k] = v end
	end
	return data
end

function DataService.save(player, state)
	local key = DATA_KEY_PREFIX .. tostring(player.UserId)
	if RunService:IsStudio() then
		return true
	end
	return try(3, function()
		store:SetAsync(key, state)
		return true
	end) == true
end

return DataService