local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local EvolutionService = {}

function EvolutionService.getNextCost(currentIndex)
	local nextIndex = currentIndex + 1
	if nextIndex > #Config.EvolutionStages then return math.huge end
	return Config.EvolutionStages[nextIndex].cost or math.huge
end

local function ensureScaleValue(humanoid, name)
	local val = humanoid:FindFirstChild(name)
	if not val then
		val = Instance.new("NumberValue")
		val.Name = name
		val.Value = 1
		val.Parent = humanoid
	end
	return val
end

local function applyAppearance(character, stage)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local appearance = stage.appearance or {}
	local scale = appearance.scale or 1
	local color = appearance.color

	-- Scale (R15):
	local scaleNames = {
		"BodyDepthScale", "BodyHeightScale", "BodyWidthScale",
		"HeadScale"
	}
	for _, n in ipairs(scaleNames) do
		local v = ensureScaleValue(humanoid, n)
		v.Value = scale
	end

	-- Body color (for R6/R15 default rigs)
	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if bodyColors and color then
		bodyColors.HeadColor3 = color
		bodyColors.TorsoColor3 = color
		bodyColors.LeftArmColor3 = color
		bodyColors.RightArmColor3 = color
		bodyColors.LeftLegColor3 = color
		bodyColors.RightLegColor3 = color
	end

	-- Overhead label
	local existing = character:FindFirstChild("StageBillboard")
	if existing then existing:Destroy() end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "StageBillboard"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = character:FindFirstChild("Head") or character
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.5
	label.Text = stage.name or "Stage"
	label.Parent = billboard
end

function EvolutionService.applyStageAppearance(player, stageIndex)
	local character = player.Character or player.CharacterAdded:Wait()
	local stages = Config.EvolutionStages
	local idx = math.clamp(stageIndex, 1, #stages)
	applyAppearance(character, stages[idx])
end

return EvolutionService