-- Implementation of centripetal Catmull-Rom splines.
-- fractality

--[[
	Each spline takes 4 points.
	The first point and last point are just control points for the second and third points.
	The path and rot path extrapolate out to find 0th points and (n + 1)th points (if not looped).
	Then, splines are made using
	{0, 1, 2, 3}
	{1, 2, 3, 4}
	{2, 3, 4, 5}
	...
	{n-2, n-1, n, n+1}
	Notice how the 0th and (n+1)th points are only ever control points.
	The actual curves are from
	{1, 2}
	{2, 3}
	{3, 4}
	...
	{n-1, n}
	so the lengths are only the lengths between the second and third points of the spline.
--]]

--TODO: Combine VectorSpline and CFrameSpline
--TODO: Combine Path and RotPath

-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Squad = require(script.SQUAD)

-- local function AxisAngleToQuaternion(axis, angle)
-- 	local halfAngle = angle / 2
-- 	local qw = math.cos(halfAngle)
-- 	local qx = axis.X * math.sin(halfAngle)
-- 	local qy = axis.Y * math.sin(halfAngle)
-- 	local qz = axis.Z * math.sin(halfAngle)
-- 	return {qw, qx, qy, qz}
-- end

local function CFrameToQuaternion(cf)
	local _,_,_,m00,m01,m02,m10,m11,m12,m20,m21,m22=cf:GetComponents()
	local trace=m00+m11+m22
	if trace>0 then
		local s=math.sqrt(1+trace)
		local recip=0.5/s
		return {s*0.5,(m21-m12)*recip,(m02-m20)*recip,(m10-m01)*recip}
	else
		local big=math.max(m00,m11,m22)
		if big==m00 then
			local s=math.sqrt(1+m00-m11-m22)
			local recip=0.5/s
			return {(m21-m12)*recip,s/2,(m10+m01)*recip,(m02+m20)*recip}
		elseif big==m11 then
			local s=math.sqrt(1-m00+m11-m22)
			local recip=0.5/s
			return {(m02-m20)*recip,(m10+m01)*recip,s/2,(m21+m12)*recip}
		elseif big==m22 then
			local s=math.sqrt(1-m00-m11+m22)
			local recip=0.5/s
			return {(m10-m01)*recip,(m02+m20)*recip,(m21+m12)*recip,s/2}
		else
			return {nil,nil,nil,nil}
		end
	end
end

local VectorSpline = {ClassName = "VectorSpline"}
VectorSpline.__index = VectorSpline
do
	-- solve for the v3 position along the spline
	local function solve(a, b, c, d, t)
		local t2 = t*t
		local t3 = t2*t
		return Vector3.new(
			(a[1] + b[1]*t + c[1]*t2 + d[1]*t3)/2,
			(a[2] + b[2]*t + c[2]*t2 + d[2]*t3)/2,
			(a[3] + b[3]*t + c[3]*t2 + d[3]*t3)/2
		)
	end

	local RIEMANN_STEP = 0.05 -- Smaller steps produce more accurate results

	-- Creates a segment of a spline through p1 and p2 using control points p0 and p3
	function VectorSpline.new(p0, p1, p2, p3)
		local cA = table.create(3)
		cA[1], cA[2], cA[3] = 2*p1.X, 2*p1.Y, 2*p1.Z

		local cB = table.create(3)
		cB[1], cB[2], cB[3] = -p0.X + p2.X, -p0.Y + p2.Y, -p0.Z + p2.Z

		local cC = table.create(3)
		cC[1], cC[2], cC[3] = 2*p0.X - 5*p1.X + 4*p2.X - p3.X, 2*p0.Y - 5*p1.Y + 4*p2.Y - p3.Y, 2*p0.Z - 5*p1.Z + 4*p2.Z - p3.Z

		local cD = table.create(3)
		cD[1], cD[2], cD[3] = -p0.X + 3*p1.X - 3*p2.X + p3.X, -p0.Y + 3*p1.Y - 3*p2.Y + p3.Y, -p0.Z + 3*p1.Z - 3*p2.Z + p3.Z

		return setmetatable({
			cA = cA,
			cB = cB,
			cC = cC,
			cD = cD,
			Length = (function()
				local result = 0
				local start_here = solve(cA, cB, cC, cD, 0)
				for i = 0, 1 - RIEMANN_STEP, RIEMANN_STEP do
					local stop_here = solve(cA, cB, cC, cD, i + RIEMANN_STEP)
					result += (stop_here - start_here).Magnitude
					start_here = stop_here
				end

				result *= RIEMANN_STEP
				return result
			end)()
		}, VectorSpline)
	end

	-- Find a Vector3 position on the spline
	function VectorSpline:Solve(t)
		return solve(self.cA, self.cB, self.cC, self.cD, t)
	end

	-- Find a CFrame position & orientation on the spline rotated in the direction of the path.  No z rotation.
	-- A seperate step for rotation might be better
	function VectorSpline:SolveNorm(t, smoothing)
		return CFrame.lookAt(self:Solve(t), self:Solve(t + (smoothing or 0.01)))
	end
end

local CFrameSpline = {ClassName = "Spline"}
CFrameSpline.__index = CFrameSpline
do
	-- solve for the v3 position along the spline
	local function solve(a, b, c, d, t)
		local t2 = t*t
		local t3 = t2*t
		return Vector3.new(
			(a[1] + b[1]*t + c[1]*t2 + d[1]*t3)/2,
			(a[2] + b[2]*t + c[2]*t2 + d[2]*t3)/2,
			(a[3] + b[3]*t + c[3]*t2 + d[3]*t3)/2
		)
	end

	local RIEMANN_STEP = 0.05 -- Smaller steps produce more accurate results

	-- Creates a segment of a spline through p1 and p2 using control points p0 and p3
	function CFrameSpline.new(c0, c1, c2, c3)
		local p0, p1, p2, p3 = c0.Position, c1.Position, c2.Position, c3.Position
		local cA = table.create(3)
		cA[1], cA[2], cA[3] = 2*p1.X, 2*p1.Y, 2*p1.Z

		local cB = table.create(3)
		cB[1], cB[2], cB[3] = -p0.X + p2.X, -p0.Y + p2.Y, -p0.Z + p2.Z

		local cC = table.create(3)
		cC[1], cC[2], cC[3] = 2*p0.X - 5*p1.X + 4*p2.X - p3.X, 2*p0.Y - 5*p1.Y + 4*p2.Y - p3.Y, 2*p0.Z - 5*p1.Z + 4*p2.Z - p3.Z

		local cD = table.create(3)
		cD[1], cD[2], cD[3] = -p0.X + 3*p1.X - 3*p2.X + p3.X, -p0.Y + 3*p1.Y - 3*p2.Y + p3.Y, -p0.Z + 3*p1.Z - 3*p2.Z + p3.Z

		return setmetatable({
			CFrames = {c0, c1, c2, c3},
			cA = cA,
			cB = cB,
			cC = cC,
			cD = cD,
			Length = (function()
				local result = 0
				local start_here = solve(cA, cB, cC, cD, 0)
				for i = 0, 1 - RIEMANN_STEP, RIEMANN_STEP do
					local stop_here = solve(cA, cB, cC, cD, i + RIEMANN_STEP)
					result += (stop_here - start_here).Magnitude
					start_here = stop_here
				end

				result *= RIEMANN_STEP
				return result
			end)()
		}, CFrameSpline)
	end

	-- Find a Vector3 position on the spline
	function CFrameSpline:Solve(t)
		return solve(self.cA, self.cB, self.cC, self.cD, t)
	end

	-- Find a CFrame position & orientation on the spline rotated in the direction of the path.  No z rotation.
	-- A seperate step for rotation might be better
	function CFrameSpline:SolveNorm(t, smoothing)
		return CFrame.lookAt(self:Solve(t), self:Solve(t + (smoothing or 0.01)))
	end
end

-- Piecewise spline
-- Takes a table of Vector3/Vector2's representing points along the spline path.
local Path = {ClassName = "Path"}
Path.__index = Path
function Path.new(pts)
	assert(#pts >= 4, "At least four points are required to construct a spline path")
	local parts = {}
	local length = 0
	local prev_a, prev_b = nil, nil
	local num_points = #pts
	local loops = pts[1] == pts[num_points]

	-- extrapolate to get 0th cframe
	local sa
	if loops then
		sa = VectorSpline.new(pts[num_points], pts[1], pts[2], pts[3])
	else
		sa = VectorSpline.new(pts[2]:Lerp(pts[1], 2), pts[1], pts[2], pts[3])
	end

	length += sa.Length
	parts[1] = sa
	for i, v in ipairs(pts) do
		local nxt = pts[i + 1]
		if prev_a and prev_b and nxt then
			local n = VectorSpline.new(prev_a, prev_b, v, nxt)
			length += n.Length
			parts[#parts + 1] = n
		end

		prev_a = prev_b
		prev_b = v
	end

	-- extrapolate to get (n + 1)th point
	local sb
	if loops then
		sb = VectorSpline.new(pts[num_points - 2], pts[num_points - 1], pts[num_points], pts[1])
	else
		sb = VectorSpline.new(pts[num_points - 2], pts[num_points - 1], pts[num_points], pts[num_points - 1]:Lerp(pts[num_points], 2))
	end

	length += sb.Length
	parts[#parts + 1] = sb

	-- get the percent of the full length at each point
	local ranges = table.create(#parts)
	local csum = 0
	for i, part in ipairs(parts) do
		csum += part.Length
		ranges[i] = csum / length
	end
	local num_ranges = #ranges

	--Accepts a number in [0, 1] representing a point on the path.
	local function getLocationOnPath(val)
		-- t is percent of length to next spline
		-- spline is 
		local spline, t
		for i, v in ipairs(ranges) do
			if v > val or i == num_ranges then
				t = (val - (ranges[i - 1] or 0)) / parts[i].Length * length
				spline = parts[i]
				break
			end
		end

		return spline, t
	end

	local function GetPointOnPath(val)
		local spline, t = getLocationOnPath(val)
		return spline:Solve(t)
	end

	local function GetCFrameOnPath(val)
		local spline, t = getLocationOnPath(val)
		return spline:SolveNorm(t)
	end

	return setmetatable({
		parts = parts,
		Length = length,
		GetPointOnPath = GetPointOnPath,
		GetCFrameOnPath = GetCFrameOnPath
	}, Path)
end

-- Piecewise spline with rotation
-- Takes a table of CFrames representing points along the spline path.

local RotPath = {ClassName = "RotPath"}
RotPath.__index = RotPath
function RotPath.new(pts)
	assert(#pts >= 4, "At least four points are required to construct a spline path")
	local parts = {}
	local length = 0
	local prev_a, prev_b = nil, nil
	local num_points = #pts
	local loops = pts[1] == pts[num_points]

	-- extrapolate to get 0th cframe
	local sa
	if loops then
		sa = CFrameSpline.new(pts[num_points], pts[1], pts[2], pts[3])
	else
		sa = CFrameSpline.new(pts[2]:Lerp(pts[1], 2), pts[1], pts[2], pts[3])
	end

	length += sa.Length
	parts[1] = sa
	for i, v in ipairs(pts) do
		local nxt = pts[i + 1]
		if prev_a and prev_b and nxt then
			local n = CFrameSpline.new(prev_a, prev_b, v, nxt)
			length += n.Length
			parts[#parts + 1] = n
		end

		prev_a = prev_b
		prev_b = v
	end
	
	-- extrapolate to get (n + 1)th point
	local sb
	if loops then
		sb = CFrameSpline.new(pts[num_points - 2], pts[num_points - 1], pts[num_points], pts[1])
	else
		sb = CFrameSpline.new(pts[num_points - 2], pts[num_points - 1], pts[num_points], pts[num_points - 1]:Lerp(pts[num_points], 2))
	end

	length += sb.Length
	parts[#parts + 1] = sb

	-- get the percent of the full length at each point
	local ranges = table.create(#parts)
	local csum = 0
	for i, part in ipairs(parts) do
		csum += part.Length
		ranges[i] = csum / length
	end
	local num_ranges = #ranges
	
	--Accepts a number in [0, 1] representing a point on the path.
	local function getLocationOnPath(val)
		-- t is percent of length to next spline
		-- spline is 
		local spline, t
		for i, v in ipairs(ranges) do
			if v > val or i == num_ranges then
				t = (val - (ranges[i - 1] or 0)) / parts[i].Length * length
				spline = parts[i]
				break
			end
		end
		
		return spline, t
	end
	
	local function GetPointOnPath(val)
		local spline, t = getLocationOnPath(val)
		return spline:Solve(t)
	end

	local function GetCFrameOnPath(val)
		local spline, t = getLocationOnPath(val)
		return spline:SolveNorm(t)
	end
	
	local function GetRotCFrameOnPath(val)
		local spline, t = getLocationOnPath(val)
		local cfOnPath = spline:SolveNorm(t)
		---- SQUAD
		local cframes = spline.CFrames
		local qw, qx, qy, qz = Squad(
			CFrameToQuaternion(cframes[1]),
			CFrameToQuaternion(cframes[2]),
			CFrameToQuaternion(cframes[3]),
			CFrameToQuaternion(cframes[4])
		)(t)
		local quaternionToCF = CFrame.new(0, 0, 0, qx, qy, qz, qw)
		return CFrame.lookAt(
			cfOnPath.Position,
			cfOnPath.Position + cfOnPath.LookVector,
			quaternionToCF.UpVector
		)
	end

	return setmetatable({
		parts = parts,
		Length = length,
		GetPointOnPath = GetPointOnPath,
		GetCFrameOnPath = GetCFrameOnPath,
		GetRotCFrameOnPath = GetRotCFrameOnPath
	}, RotPath)
end

return {
	VectorSpline = VectorSpline,
	CFrameSpline = CFrameSpline,
	Path = Path,
	RotPath = RotPath
}