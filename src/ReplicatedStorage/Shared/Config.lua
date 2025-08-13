local Config = {}

-- DataStore
Config.DataStoreName = "BREVO_Data_v1"
Config.SaveIntervalSeconds = 60

-- Economy
Config.BaseClickGain = 1
Config.BasePassiveGainPerSecond = 0
Config.AutoClickClicksPerSecond = 5

-- Anti-exploit
Config.AntiExploit = {
	MaxClicksPerSecond = 20,
	MinClickIntervalSeconds = 0.03
}

-- Evolution stages
-- cost = требуемый BrainRot для перехода на следующую стадию (стоимость списывается)
Config.EvolutionStages = {
	{ name = "Норми",            cost = 0,         appearance = { scale = 1.00, color = Color3.fromRGB(255,255,255) } },
	{ name = "Мем-энджойер",     cost = 100,       appearance = { scale = 1.02, color = Color3.fromRGB(240,240,255) } },
	{ name = "Сигма",            cost = 500,       appearance = { scale = 1.05, color = Color3.fromRGB(220,240,255) } },
	{ name = "Скибиди",          cost = 2000,      appearance = { scale = 1.08, color = Color3.fromRGB(210,255,240) } },
	{ name = "Риззлер",          cost = 8000,      appearance = { scale = 1.10, color = Color3.fromRGB(255,240,220) } },
	{ name = "Огайо",            cost = 25000,     appearance = { scale = 1.12, color = Color3.fromRGB(255,225,210) } },
	{ name = "Фэнум Такс",       cost = 80000,     appearance = { scale = 1.15, color = Color3.fromRGB(255,210,210) } },
	{ name = "Гиятт",            cost = 250000,    appearance = { scale = 1.20, color = Color3.fromRGB(255,210,240) } },
	{ name = "NPC-Оверлорд",     cost = 800000,    appearance = { scale = 1.25, color = Color3.fromRGB(240,210,255) } },
	{ name = "BrainRot Incarnate", cost = 2500000, appearance = { scale = 1.35, color = Color3.fromRGB(210,210,255) } },
	{ name = "Ultra BrainRot",   cost = 8000000,   appearance = { scale = 1.45, color = Color3.fromRGB(210,255,255) } },
	{ name = "Ascended",         cost = 25000000,  appearance = { scale = 1.60, color = Color3.fromRGB(200,255,220) } },
}

function Config.getStageCount()
	return #Config.EvolutionStages
end

return Config