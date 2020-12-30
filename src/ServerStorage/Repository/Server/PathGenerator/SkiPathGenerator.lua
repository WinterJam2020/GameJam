--[[
	This method creates a height map from a local max to a local min.
	Then it offsets the height map vertically with a smaller noise octave
	and  offsets it horizontally with more noise. Lastly, the height map is adjusted
	to be along a spline made of 4 points.
--]]

--TODO: formalize the remaining magic numbers

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadShared("Constants").SKI_PATH
local Janitor = Resources:LoadShared("Janitor")
-- local Arrow = Resources:LoadLibrary("Arrow")
local SplineModule = Resources:LoadShared("AstroSpline")
local DrawSkiPath = Resources:LoadServer("DrawSkiPath")
local Services = Resources:LoadLibrary("Services")

local Workspace: Workspace = Services.Workspace

---- Settings
local DELTA = 0.2
local SMALL_DELTA = 0.01
local MIN_DIST = 6
local MAX_DIST = 9
local HEIGHT_MAP_THRESHOLD = 0.4
local NOISE_OFFSET = math.floor(os.clock() % 86400 * 100) / 100

local SCALE_FACTOR = Constants.SCALE_FACTOR
local MAX_VERTICAL_OFFSET = 20
local MAX_HORIZONTAL_OFFSET = 2

local POINT_DENSITY = 5
local MAX_BANK_ANGLE = Constants.MAX_BANK_ANGLE

local DEBUG = Constants.DEBUG
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
-- local function ZFunction(x)
-- 	return math.sin(4 * math.pi * x)
-- end

local PathGenerator = {
	Janitor = nil,
	Props = nil,
	SkiChain = nil,
	SkiChainCFrames = nil
}

function PathGenerator:Initialize()
	print("initializing path generator")
	self.Janitor = Janitor.new()	
end

function PathGenerator:Generate()
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

	local ArcSpline = SplineModule.Chain.new(ArcPoints, 1)

	---- Height map cframes
	local SkiChainCFrames = {}
	for i = 0, Length * POINT_DENSITY - 1 do
		i /= Length * POINT_DENSITY - 1
		local input = Start[1] + i * Length
		local y = Noise(input) -- initial height map
		y = Scale * (y + VShift) -- shift y between 0 and 1
		y += math.noise(input + NOISE_OFFSET + 20) / 5 -- add smaller octave later in the noise
		y -= ErrorBarFunction(y, i) -- bring y closer to -x + 1
		--local z = math.random() * ZFunction(i) * 5
		local z = math.noise((input + NOISE_OFFSET)* 2) * MAX_HORIZONTAL_OFFSET * 2 -- add horizontal offset later later in the noise
		local cf = ArcSpline:GetArcCFrame(i) + Vector3.new(0, y * MAX_VERTICAL_OFFSET, 0)
		cf += cf.RightVector * z -- horizontal offset but along arc
		table.insert(SkiChainCFrames, cf)
	end

	---- Bank height map cframes
	local numHeightMapCFrames = #SkiChainCFrames
	for i, cf in ipairs(SkiChainCFrames) do
		if i == 1 or i == numHeightMapCFrames then
			continue
		end

		local nextPoint = SkiChainCFrames[i + 1].Position
		local lastPoint = SkiChainCFrames[i - 1].Position
		local toLast = ((lastPoint - cf.Position) * PROJ_VEC).Unit
		local toNext = ((nextPoint - cf.Position) * PROJ_VEC).Unit
		local cross = toNext:Cross(toLast)
		local dot = toNext:Dot(toLast)
		local angle = math.acos(math.clamp(dot, -1, 1))
		local rot = math.sign(cross.Y) * (3.1415926535898 - angle) * (MAX_BANK_ANGLE / 3.1415926535898)
		SkiChainCFrames[i] = cf * CFrame.Angles(0, 0, rot)
	end

	---- Scale up height map cframes
	local skiPathOrigin = SkiChainCFrames[1].Position * SCALE_FACTOR
	for i, cf in ipairs(SkiChainCFrames) do
		SkiChainCFrames[i] = (cf - cf.Position) + cf.Position * SCALE_FACTOR - skiPathOrigin
	end

	local SkiChain = SplineModule.Chain.new(SkiChainCFrames, 1)
	local Props = DrawSkiPath(SkiChain)

	if DEBUG then
		for _, v in ipairs(ArcPoints) do
			local part = Instance.new("Part")
			part.BrickColor = BrickColor.new("Bright yellow")
			part.CFrame = CFrame.new(v)
			part.Size = Vector3.new(1, 1, 1)
			part.Anchored = true
			part.Parent = Workspace
		end

		for _, cf in ipairs(SkiChainCFrames) do
			local part = Instance.new("Part")
			part.BrickColor = BrickColor.new("Bright green")
			part.CFrame = cf
			part.Size = Vector3.new(4, 4, 4)
			part.Anchored = true
			part.Parent = Workspace
		end

		local points = {}
		for i = 0, 200 - 1 do
			i /= (200 / 1)
			local point = ArcSpline:GetArcPosition(i)
			local part = Instance.new("Part")
			part.BrickColor = BrickColor.new("Persimmon")
			part.CFrame = CFrame.new(point)
			part.Size = Vector3.new(1, 1, 1) / 2
			part.Anchored = true
			part.Parent = Workspace

			--local point1 = SkiPath.GetRotCFrameOnPath(i)
			--local part1 = Instance.new("Part")
			--part1.BrickColor = BrickColor.new("Persimmon")
			--part1.CFrame = point1
			--part1.Size = Vector3.new(1, 1, 1) / 2
			--part1.Anchored = true
			--part1.Parent = workspace

			local point2 = SkiChain:GetArcPosition(i)
			table.insert(points, point2)
			local part2 = Instance.new("Part")
			part2.BrickColor = BrickColor.Green()
			part2.CFrame = CFrame.new(point2)
			part2.Size = Vector3.new(1, 1, 1) / 2
			part2.Anchored = true
			part2.Parent = Workspace
		end
	end

	self.Props = Props
	self.SkiChain = SkiChain
	self.SkiChainCFrames = SkiChainCFrames
	self.Janitor:Add(Props)
	self.Janitor:Add(function()
		self.SkiChain = nil
		self.SkiChainCFrames = nil
	end)
	return SkiChain, SkiChainCFrames
end

function PathGenerator:Clear()
	self.Janitor:Cleanup()
	workspace.Terrain:Clear()
end

return PathGenerator