local Workspace = game:GetService("Workspace")

local function ensureSpawn()
	for _, inst in ipairs(Workspace:GetChildren()) do
		if inst:IsA("SpawnLocation") then return end
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Locked = true
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.BrickColor = BrickColor.new("Bright blue")
	spawn.CanCollide = true
	spawn.Name = "Spawn"
	spawn.Position = Vector3.new(0, 5, 0)
	spawn.Parent = Workspace

	local base = Instance.new("Part")
	base.Anchored = true
	base.Size = Vector3.new(256, 1, 256)
	base.Position = Vector3.new(0, 0, 0)
	base.BrickColor = BrickColor.new("Medium stone grey")
	base.Name = "BaseplateAuto"
	base.Parent = Workspace
end

pcall(ensureSpawn)