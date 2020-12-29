--[[
	This method creates a height map from a local max to a local min.
	Then it offsets the height map vertically with a smaller noise octave
	and randomly offsets it horizontally. Lastly, the height map is adjusted
	to be along a spline made of 4 points.
--]]

--TODO: formalize the remaining magic numbers

-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Arrow = require(ReplicatedStorage:WaitForChild("Arrow"))
local SplineModule = require(script.CatmullRomSpline)
local DrawSkiPath = require(script.DrawSkiPath)

---- Settings
local DELTA = 0.2
local SMALL_DELTA = 0.01
local MIN_DIST = 6
local MAX_DIST = 9
local HEIGHT_MAP_THRESHOLD = 0.4
local NOISE_OFFSET = math.floor(os.clock() % 86400 * 100) / 100

local POINT_DENSITY = 5
local MAX_BANK = math.rad(60)

---- Constants
local PROJ_VEC = Vector3.new(1, 0, 1)

---- Functions
local function Noise(input)
	return math.noise(0.5 * input + NOISE_OFFSET)
end

-- Aligns the function closer to -x + 1
local function ErrorBarFunction(y, alpha)
	return (y - (-alpha + 1)) * 5/6
end

-- Envelope for z offset
local function ZFunction(x)
	return math.sin(4 * math.pi * x)
end

return function()
	-- Find a local maximum and local minimum
	local Start, End, Scale, VShift, Length do
		-- find a local maximum > 0.4
		local input, output = 0, 0
		while output < HEIGHT_MAP_THRESHOLD do
			input += DELTA
			output = Noise(input)
		end
		local lastInput, lastOutput = 0, 0
		while output > lastOutput do
			lastInput, lastOutput = input, output
			input += SMALL_DELTA
			output = Noise(input)
		end
		Start = {lastInput, lastOutput}

		-- find a local minimum within a predefined range
		End = {0, 2}
		for i = Start[1] + MIN_DIST, Start[1] + MAX_DIST, DELTA do
			local val = Noise(i)
			if val < End[2] then
				End = {i, val}
			end
		end

		-- calculate parameters
		Scale = 1 / (Start[2] - End[2])
		VShift = -End[2]
		Length = End[1] - Start[1]
	end

	---- Large arc spline
	local ArcPoints = {}
	for i = 0, 3 do
		table.insert(ArcPoints, Vector3.new(
			(i / 3) * 5 * Length,
			0,
			math.random() * 40 - 20
			))
	end
	local ArcSpline = SplineModule.Path.new(ArcPoints)

	---- Height map cframes
	local HeightMapCFrames = {}
	for i = 0, 1, 1 / (POINT_DENSITY * Length) do
		local input = Start[1] + i * Length
		local y = Noise(input) -- initial height map
		y = Scale * (y + VShift) -- shift y between 0 and 1
		y += math.noise(input + NOISE_OFFSET + 20) / 5 -- add smaller noise octave
		y -= ErrorBarFunction(y, i) -- bring y closer to -x + 1
		local z = math.random() * ZFunction(i) * 5
		local cf = ArcSpline.GetCFrameOnPath(i)
		cf += Vector3.new(0, y * 20, 0) + cf.RightVector * z -- position but along arc
		table.insert(HeightMapCFrames, cf)
	end

	---- Bank height map cframes
	local numHeightMapCFrames = #HeightMapCFrames
	for i, v in ipairs(HeightMapCFrames) do
		if i == 1 or i == numHeightMapCFrames then continue end
		local nextPoint = HeightMapCFrames[i + 1].Position
		local lastPoint = HeightMapCFrames[i - 1].Position
		local toLast = ((lastPoint - v.Position) * PROJ_VEC).Unit
		local toNext = ((nextPoint - v.Position) * PROJ_VEC).Unit
		local cross = toNext:Cross(toLast)
		local dot = toNext:Dot(toLast)
		local angle = math.acos(math.clamp(dot, -1, 1))
		local rot = math.sign(cross.Y) * (math.pi - angle) * (MAX_BANK / math.pi)
		HeightMapCFrames[i] = v * CFrame.Angles(0, 0, rot)
	end

	---- Scale up height map cframes
	for i, v in ipairs(HeightMapCFrames) do
		HeightMapCFrames[i] = (v - v.Position) + v.Position * 100
	end

	local HeightMapSpline = SplineModule.RotPath.new(HeightMapCFrames)
	DrawSkiPath(HeightMapSpline)

	-- visualize
	for _, v in ipairs(ArcSpline) do
		local part = Instance.new("Part")
		part.BrickColor = BrickColor.new("Brick yellow")
		part.CFrame = CFrame.new(v)
		part.Size = Vector3.new(1, 1, 1)
		part.Anchored = true
		part.Parent = workspace
	end

	for i = 0, 1, 0.004 do
		local point = ArcSpline.GetPointOnPath(i)
		local part = Instance.new("Part")
		part.BrickColor = BrickColor.new("Persimmon")
		part.CFrame = CFrame.new(point)
		part.Size = Vector3.new(1, 1, 1) / 2
		part.Anchored = true
		part.Parent = workspace

		local point1 = HeightMapSpline.GetRotCFrameOnPath(i)
		local part1 = Instance.new("Part")
		part1.BrickColor = BrickColor.new("Persimmon")
		part1.CFrame = point1
		part1.Size = Vector3.new(1, 1, 1) / 2
		part1.Anchored = true
		part1.Parent = workspace
	end
	
	return HeightMapSpline
end