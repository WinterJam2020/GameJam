local Container = Instance.new("Model")
Container.Name = "Markers"
Container.Parent = workspace

local Part = Instance.new("Part")
Part.Anchored = true
Part.BrickColor = BrickColor.new("Electric blue")
Part.CanCollide = false
Part.TopSurface = Enum.SurfaceType.Smooth
Part.Transparency = 0.25
Part.BottomSurface = Enum.SurfaceType.Smooth

local SEGMENTS = 500
local PATH_WIDTH = 40
local HORIZONTAL_MARKER_DENSITY = 5
local VERTICAL_OFFSET = 1.8

local function generateMarkers(spline, rightOffset)
	local nextCFrame = spline:GetArcRotCFrame(0)
	for i = 0, SEGMENTS - 1 do
		local cf = nextCFrame
		local pos = cf.Position
			+ cf.UpVector * VERTICAL_OFFSET
			+ cf.RightVector * rightOffset
		local nextCF = spline:GetArcRotCFrame(i / (SEGMENTS - 1))
		local nextPos = nextCF.Position
			+ nextCF.UpVector * VERTICAL_OFFSET
			+ nextCF.RightVector * rightOffset
		nextCFrame = nextCF

		local p = Part:Clone()
		p.CFrame = CFrame.lookAt(pos, nextPos, cf.UpVector) + (nextPos - pos) / 2
		p.Size = Vector3.new(1, 1, (nextPos - pos).Magnitude)
		p.Parent = Container
	end
end

local function generateHorizontalMarkers(spline)
	for i = 0, SEGMENTS/HORIZONTAL_MARKER_DENSITY - 1 do
		local cf = spline:GetArcRotCFrame(i / (SEGMENTS/HORIZONTAL_MARKER_DENSITY - 1))
		local part = Part:Clone()
		part.CFrame = cf + cf.UpVector * VERTICAL_OFFSET
		part.Size = Vector3.new(PATH_WIDTH, 1, 1)
		part.Parent = Container
	end
end

return function(spline)
	generateMarkers(spline, PATH_WIDTH / 2) -- right
	generateMarkers(spline, -PATH_WIDTH / 2) -- left
	generateHorizontalMarkers(spline)
end