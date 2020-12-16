local DrawTriangle = require(script.DrawTriangle)
local Terrain = workspace.Terrain
local WIDTH = 100
local WEDGE_DEPTH = 12
local DEBUG = false

local function DrawTerrainWedge(cf0, cf1, size0, size1)
	if DEBUG then
		local w0 = Instance.new("WedgePart")
		w0.Anchored = true
		w0.CFrame = cf0
		w0.Size = size0
		w0.Parent = workspace
		local w1 = Instance.new("WedgePart")
		w1.Anchored = true
		w1.CFrame = cf1
		w1.Size = size1
		w1.Parent = workspace
	else
		Terrain:FillWedge(cf0, size0, Enum.Material.Snow)
		Terrain:FillWedge(cf1, size1, Enum.Material.Snow)
	end
end

local function DrawTerrainBlock(cf, size)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CFrame = cf
	p.Size = size
	p.Parent = workspace
	Terrain:FillBlock(cf, size, Enum.Material.Snow)
end

local function DrawSkiPath(spline)
	local pathPoints = {}
	
	for i = 0, 1, 0.001 do
		local cf = spline.GetRotCFrameOnPath(i)
		if DEBUG then
			local p = Instance.new("Part")
			p.Anchored = true
			p.CFrame = cf
			p.Size = Vector3.new(WIDTH, 1, 1)
			p.Parent = workspace
		end
		pathPoints[#pathPoints + 1] = {
			CFrame = cf,
			P0 = cf.Position + cf.RightVector * WIDTH/2,
			P1 = cf.Position - cf.RightVector * WIDTH/2
		}
	end
	local numPathPoints = #pathPoints
	local f = Instance.new("Folder")
	for i, pt in ipairs(pathPoints) do
		if i == numPathPoints then break end
		local nxt = pathPoints[i + 1]
		local midpoint = (pt.CFrame.Position + nxt.CFrame.Position) / 2

		-- 4: midpoint
		--DrawTerrainWedge(DrawTriangle(pt.P0, pt.P1, midpoint, WEDGE_DEPTH))
		--DrawTerrainWedge(DrawTriangle(nxt.P0, nxt.P1, midpoint, WEDGE_DEPTH))
		--DrawTerrainWedge(DrawTriangle(pt.P0, nxt.P0, midpoint, WEDGE_DEPTH))
		--DrawTerrainWedge(DrawTriangle(pt.P1, nxt.P1, midpoint, WEDGE_DEPTH))

		-- 2:
		DrawTerrainWedge(DrawTriangle(pt.P0, nxt.P0, pt.P1, WEDGE_DEPTH, pt.CFrame.UpVector))
		DrawTerrainWedge(DrawTriangle(pt.P1, nxt.P0, nxt.P1, WEDGE_DEPTH, pt.CFrame.UpVector))
	end
end

return DrawSkiPath