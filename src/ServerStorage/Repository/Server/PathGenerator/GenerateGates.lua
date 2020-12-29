local Container = Instance.new("Model")
Container.Name = "Gates"
Container.Parent = workspace

local Part = Instance.new("Part")
Part.Anchored = true
Part.BrickColor = BrickColor.new("Persimmon")
Part.CanCollide = false
Part.Size = Vector3.new(3, 4, 1)
Part.TopSurface = Enum.SurfaceType.Smooth
Part.BottomSurface = Enum.SurfaceType.Smooth

local SEGMENTS = 50
local PATH_WIDTH = 44

local function generateGates(spline, rightOffset)
	for i = 0, SEGMENTS - 1 do
		local cf = spline:GetArcRotCFrame(i / (SEGMENTS - 1))
		local p = Part:Clone()
		p.CFrame = cf + cf.UpVector * 4 + cf.RightVector * rightOffset
		p.Parent = Container
	end
end

return function(spline)
	generateGates(spline,  PATH_WIDTH / 2) -- right
	generateGates(spline, -PATH_WIDTH / 2) -- left
end