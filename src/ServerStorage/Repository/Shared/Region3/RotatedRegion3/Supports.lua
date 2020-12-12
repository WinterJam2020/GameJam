-- support functions for GJK
-- Ego

local ZERO = Vector3.new()
local RIGHT = Vector3.new(1, 0, 0)

local function rayPlane(p, v, s, n)
	local r = p - s
	local t = -r:Dot(n) / v:Dot(n)
	return p + t * v, t
end

local Supports = {}

function Supports.PointCloud(set, direction)
	local max, maxDot = set[1], set[1]:Dot(direction)
	for i = 2, #set do
		local dot = set[i]:Dot(direction)
		if dot > maxDot then
			max = set[i]
			maxDot = dot
		end
	end

	return max
end

function Supports.Cylinder(set, direction)
	local cf, size2 = set[1], set[2]
	direction = cf:VectorToObjectSpace(direction)
	local radius = math.min(size2.Y, size2.Z)
	local dotT, cPoint = direction:Dot(RIGHT), Vector3.new(size2.X, 0, 0)
	local h, final

	if dotT == 0 then
		final = direction.Unit * radius
	else
		cPoint = dotT > 0 and cPoint or -cPoint
		h = rayPlane(ZERO, direction, cPoint, RIGHT)
		final = cPoint + (h - cPoint).Unit * radius
	end

	return cf:PointToWorldSpace(final)
end

function Supports.Ellipsoid(set, direction)
	local cf, size2 = set[1], set[2]
	return cf:PointToWorldSpace(size2 * (size2 * cf:VectorToObjectSpace(direction)).Unit)
end

return Supports