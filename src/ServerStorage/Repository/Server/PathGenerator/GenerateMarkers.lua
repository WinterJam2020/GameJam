local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadShared("Constants").SKI_PATH

local Part = Instance.new("Part")
Part.Anchored = true
Part.BrickColor = BrickColor.new("Electric blue")
Part.CanCollide = false
Part.TopSurface = Enum.SurfaceType.Smooth
Part.Transparency = 0.25
Part.BottomSurface = Enum.SurfaceType.Smooth

local SEGMENTS = 500
local PATH_WIDTH = Constants.PATH_WIDTH
local HORIZONTAL_MARKER_DENSITY = 5
local VERTICAL_OFFSET = 1.8

local function generateMarkers(spline, container, rightOffset)
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
		p.Name = "SideMarker"
		p.CFrame = CFrame.lookAt(pos, nextPos, cf.UpVector) + (nextPos - pos) / 2
		p.Size = Vector3.new(1, 1, (nextPos - pos).Magnitude)
		p.Parent = container
	end
end

local function generateHorizontalMarkers(spline, container)
	for i = 0, SEGMENTS/HORIZONTAL_MARKER_DENSITY - 1 do
		local cf = spline:GetArcRotCFrame(i / (SEGMENTS/HORIZONTAL_MARKER_DENSITY - 1))
		local part = Part:Clone()
		part.Name = "HorizontalMarker"
		part.CFrame = cf + cf.UpVector * VERTICAL_OFFSET
		part.Size = Vector3.new(PATH_WIDTH, 1, 1)
		part.Parent = container
	end
end

return function(spline, parent)
	local container = Instance.new("Model")
	container.Name = "Markers"
	container.Parent = parent
	generateMarkers(spline, container, PATH_WIDTH / 2) -- right
	generateMarkers(spline, container, -PATH_WIDTH / 2) -- left
	generateHorizontalMarkers(spline, container)
end