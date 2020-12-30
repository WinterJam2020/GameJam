-- @author evaera

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Services = Resources:LoadLibrary("Services")

local Workspace: Workspace = Services.Workspace

local function arrow(name, from, to, color, scale)
	color = color or BrickColor.random().Color
	scale = scale or 1

	if typeof(from) == "Instance" then
		local _: Instance = from
		if from:IsA("BasePart") then
			from = from.CFrame
		elseif from:IsA("Attachment") then
			from = from.WorldCFrame
		end

		if to ~= nil then
			from = from.Position
		end
	end

	if typeof(to) == "Instance" then
		local _: Instance = to
		if to:IsA("BasePart") then
			to = to.Position
		elseif to:IsA("Attachment") then
			to = to.WorldPosition
		end
	end

	if typeof(from) == "CFrame" and to == nil then
		local look = from.LookVector
		to = from.Position
		from = to + (look * -10)
	end

	if to == nil then
		to = from
		from = to + Vector3.new(0, 10, 0)
	end

	assert(typeof(from) == "Vector3" and typeof(to) == "Vector3", "Passed parameters are of invalid types")

	local container = Workspace:FindFirstChild("Arrows") or Instance.new("Folder")
	container.Name = "Arrows"
	container.Parent = Workspace

	local shaft = container:FindFirstChild(name .. "_shaft") or Instance.new("CylinderHandleAdornment")

	shaft.Height = (from - to).Magnitude - 2

	shaft.CFrame = CFrame.lookAt(
		((from + to)/2) - ((to - from).Unit * 1),
		to
	)

	if shaft.Parent == nil then
		shaft.Name = name .. "_shaft"
		shaft.Color3 = color
		shaft.Radius = 0.15
		shaft.Adornee = Workspace.Terrain
		shaft.Transparency = 0
		shaft.Radius = 0.15 * scale
		shaft.Transparency = 0
		shaft.AlwaysOnTop = true
		shaft.ZIndex = 5 - math.ceil(scale)
	end

	shaft.Parent = container

	local pointy = container:FindFirstChild(name .. "_head") or Instance.new("ConeHandleAdornment")

	scale = scale == 1 and 1 or 1.4

	if pointy.Parent == nil then
		pointy.Name = name .. "_head"
		pointy.Color3 = color
		pointy.Radius = scale / 2
		pointy.Transparency = 0
		pointy.Adornee = workspace.Terrain
		pointy.Height = 2 * scale
		pointy.AlwaysOnTop = true
		pointy.ZIndex = 5 - math.ceil(scale)
	end

	pointy.CFrame = CFrame.lookAt((CFrame.lookAt(to, from) * CFrame.new(0, 0, -2 - ((scale-1)/2))).Position, to)

	pointy.Parent = container

	if scale == 1 then
		arrow(name .. "_backdrop", from, to, Color3.new(), 2)
	end
end

return arrow