local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadShared("Constants").SKI_PATH
local DrawTriangle = Resources:LoadServer("DrawTriangle")
local Terrain = workspace.Terrain
local WIDTH = Constants.TERRAIN_WIDTH
local WEDGE_DEPTH = Constants.WEDGE_DEPTH
local DEBUG = Constants.DEBUG

local DebugContainer
if DEBUG then
	DebugContainer = Instance.new("Folder")
	DebugContainer.Name = "SkiPathContainer"
	DebugContainer.Parent = workspace
end

local function DrawTerrainWedge(cf0, cf1, size0, size1, debugColor)
	if DEBUG then
		local w0 = Instance.new("WedgePart")
		w0.Anchored = true
		w0.BrickColor = debugColor or BrickColor.new("Medium stone grey")
		w0.CFrame = cf0
		w0.Size = size0
		w0.Parent = DebugContainer
		local w1 = Instance.new("WedgePart")
		w1.Anchored = true
		w1.BrickColor = debugColor or BrickColor.new("Medium stone grey")
		w1.CFrame = cf1
		w1.Size = size1
		w1.Parent = DebugContainer
	else
		Terrain:FillWedge(cf0, size0, Enum.Material.Snow)
		Terrain:FillWedge(cf1, size1, Enum.Material.Snow)
	end
end

local function DrawSkiPath(spline)
	local pathPoints = {}

	for i = 0, 1000 - 1 do
		i /= (1000 - 1)
		local cf = spline:GetArcRotCFrame(i)
		local debugColor
		if DEBUG then
			local _, curvature = spline:GetArcCurvature(i)
			local p = Instance.new("Part")
			p.Anchored = true
			p.CFrame = cf
			p.Size = Vector3.new(WIDTH, 1, 1)
			if curvature * 1000 > 5 then
				p.BrickColor = BrickColor.Black()
				debugColor = BrickColor.Black()
			end
			p.Parent = DebugContainer
		end
		pathPoints[#pathPoints + 1] = {
			CFrame = cf,
			P0 = cf.Position + cf.RightVector * WIDTH/2,
			P1 = cf.Position - cf.RightVector * WIDTH/2,
			DebugColor = debugColor
		}
	end
	local numPathPoints = #pathPoints
	for i, pt in ipairs(pathPoints) do
		if i == numPathPoints then
			break
		end

		local nxt = pathPoints[i + 1]
		-- local midpoint = (pt.CFrame.Position + nxt.CFrame.Position) / 2

		-- 4: midpoint
		--DrawTerrainWedge(DrawTriangle(pt.P0, pt.P1, midpoint, WEDGE_DEPTH))
		--DrawTerrainWedge(DrawTriangle(nxt.P0, nxt.P1, midpoint, WEDGE_DEPTH))
		--DrawTerrainWedge(DrawTriangle(pt.P0, nxt.P0, midpoint, WEDGE_DEPTH))
		--DrawTerrainWedge(DrawTriangle(pt.P1, nxt.P1, midpoint, WEDGE_DEPTH))

		-- 2:
		local cf0, cf1, size0, size1 = DrawTriangle(pt.P0, nxt.P0, pt.P1, WEDGE_DEPTH, pt.CFrame.UpVector)
		local cfa, cfb, sizea, sizeb = DrawTriangle(pt.P1, nxt.P0, nxt.P1, WEDGE_DEPTH, pt.CFrame.UpVector)
		DrawTerrainWedge(cf0, cf1, size0, size1, pt.DebugColor)
		DrawTerrainWedge(cfa, cfb, sizea, sizeb, pt.DebugColor)
	end
end

return DrawSkiPath