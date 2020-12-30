local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadLibrary("Constants")
local Services = Resources:LoadLibrary("Services")

local PATH_WIDTH = Constants.SKI_PATH.PATH_WIDTH + 4
local NUM_GATES = Constants.SKI_PATH.NUM_GATES

local GatesContainer = Instance.new("Folder")
GatesContainer.Name = "Gates"
GatesContainer.Parent = Services.Workspace

local Part = Instance.new("Part")
Part.Anchored = true
Part.BrickColor = BrickColor.new("Persimmon")
Part.CanCollide = false
Part.Size = Vector3.new(3, 4, 1)
Part.TopSurface = Enum.SurfaceType.Smooth
Part.BottomSurface = Enum.SurfaceType.Smooth

local function generateGates(spline, rightOffset)
	for i = 0, NUM_GATES - 1 do
		local cf = spline:GetArcRotCFrame(i / (NUM_GATES - 1))
		local p = Part:Clone()
		p.CFrame = cf + cf.UpVector * 4 + cf.RightVector * rightOffset
		p.Parent = GatesContainer
	end
end

return function(spline)
	generateGates(spline, PATH_WIDTH / 2) -- right
	generateGates(spline, -PATH_WIDTH / 2) -- left
end