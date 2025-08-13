local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local ShopService = {}

local Upgrades = {
	clickMultiplier = {
		id = "clickMultiplier",
		displayName = "Клик-множитель",
		baseCost = 50,
		costGrowth = 2.5,
		maxLevel = 10,
	},
	passiveIncome = {
		id = "passiveIncome",
		displayName = "Пассивный доход",
		baseCost = 100,
		costGrowth = 3.0,
		maxLevel = 10,
	},
	autoClicker = {
		id = "autoClicker",
		displayName = "Автокликер",
		cost = 2500,
	}
}

function ShopService.getUpgrades()
	return Upgrades
end

local function pow(a, b)
	return a ^ b
end

function ShopService.getClickMultiplier(level)
	-- level 0 => x1; each level doubles
	return 2 ^ level
end

function ShopService.getPassiveIncomePerSecond(level)
	-- level 0 => +0; growth roughly doubling minus 1
	return math.max(0, (2 ^ level) - 1)
end

function ShopService.getUpgradeCost(id, currentLevel)
	if id == Upgrades.clickMultiplier.id then
		return math.floor(Upgrades.clickMultiplier.baseCost * pow(Upgrades.clickMultiplier.costGrowth, currentLevel))
	elseif id == Upgrades.passiveIncome.id then
		return math.floor(Upgrades.passiveIncome.baseCost * pow(Upgrades.passiveIncome.costGrowth, currentLevel))
	elseif id == Upgrades.autoClicker.id then
		return Upgrades.autoClicker.cost
	end
	return math.huge
end

function ShopService.tryBuyUpgrade(state, id)
	if id == Upgrades.clickMultiplier.id then
		local level = state.upgrades.clickMultiplierLevel or 0
		local maxLevel = Upgrades.clickMultiplier.maxLevel
		if level >= maxLevel then return false, "Максимальный уровень" end
		local cost = ShopService.getUpgradeCost(id, level)
		if state.brainRot < cost then return false, "Недостаточно BR" end
		state.brainRot -= cost
		state.upgrades.clickMultiplierLevel = level + 1
		return true
	elseif id == Upgrades.passiveIncome.id then
		local level = state.upgrades.passiveIncomeLevel or 0
		local maxLevel = Upgrades.passiveIncome.maxLevel
		if level >= maxLevel then return false, "Максимальный уровень" end
		local cost = ShopService.getUpgradeCost(id, level)
		if state.brainRot < cost then return false, "Недостаточно BR" end
		state.brainRot -= cost
		state.upgrades.passiveIncomeLevel = level + 1
		return true
	elseif id == Upgrades.autoClicker.id then
		if state.upgrades.autoClickerOwned then return false, "Уже куплено" end
		local cost = ShopService.getUpgradeCost(id, 0)
		if state.brainRot < cost then return false, "Недостаточно BR" end
		state.brainRot -= cost
		state.upgrades.autoClickerOwned = true
		state.upgrades.autoClickerEnabled = true
		return true
	end
	return false, "Неизвестный апгрейд"
end

return ShopService