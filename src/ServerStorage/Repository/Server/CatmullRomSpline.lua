-- Implementation of centripetal Catmull-Rom splines.
-- fractality
--------------- --- -------

--[[
Potential uses:
	* Rollercoasters
	* Complex camera movements during cutscenes
	* Smooth character animations
	* Rollercoasters
	* Building cars
	* Rollercoasters

Example code:

	local crModule = require(game.ServerScriptService.crSpline)
	local function TweenCam(pts, speed)
		local path = crModule.Path.create(pts)
		workspace.CurrentCamera.CameraType = "Scriptable"
		for i = 0, 1, speed/path.length do
			workspace.CurrentCamera.CFrame = CFrame.new(path.GetPointOnPath(i))
			wait()
		end
		workspace.CurrentCamera.CameraType = "Custom"
	end

--]]

local Spline = {ClassName = "Spline"}
Spline.__index = Spline

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
	function Spline.new(p0, p1, p2, p3)
		local cA = table.create(3)
		cA[1], cA[2], cA[3] = 2*p1.X, 2*p1.Y, 2*p1.Z

		local cB = table.create(3)
		cB[1], cB[2], cB[3] = -p0.X + p2.X, -p0.Y + p2.Y, -p0.Z + p2.Z

		local cC = table.create(3)
		cC[1], cC[2], cC[3] = 2*p0.X - 5*p1.X + 4*p2.X - p3.X, 2*p0.Y - 5*p1.Y + 4*p2.Y - p3.Y, 2*p0.Z - 5*p1.Z + 4*p2.Z - p3.Z

		local cD = table.create(3)
		cD[1], cD[2], cD[3] = -p0.X + 3*p1.X - 3*p2.X + p3.X, -p0.Y + 3*p1.Y - 3*p2.Y + p3.Y, -p0.Z + 3*p1.Z - 3*p2.Z + p3.Z

		return setmetatable({
			cA = cA;
			cB = cB;
			cC = cC;
			cD = cD;
			length = (function()
				local result = 0
				local start_here = solve(cA, cB, cC, cD, 0)
				for i = 0, 1 - RIEMANN_STEP, RIEMANN_STEP do
					local stop_here = solve(cA, cB, cC, cD, i + RIEMANN_STEP)
					result += (stop_here - start_here).Magnitude
					start_here = stop_here
				end

				result *= RIEMANN_STEP
				return result
			end)();
		}, Spline)
	end

	-- Find a Vector3 position on the spline
	function Spline:Solve(t)
		return solve(self.cA, self.cB, self.cC, self.cD, t)
	end

	-- Find a CFrame position & orientation on the spline rotated in the direction of the path.  No z rotation.
	-- A seperate step for rotation might be better
	function Spline:SolveNorm(t, smoothing)
		return CFrame.new(self:Solve(t), self:Solve(t + (smoothing or 0.01)))
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

	-- catmull rom splines don't pass through all four points, so extrapolate some extras as control points
	local sa
	if loops then
		sa = Spline.new(pts[2]:Lerp(pts[1], 2), pts[1], pts[2], pts[3])
	else
		sa = Spline.new(pts[num_points], pts[1], pts[2], pts[3])
	end

	length += sa.length
	parts[1] = sa
	for i, v in ipairs(pts) do
		local nxt = pts[i + 1]
		if prev_a and prev_b and nxt then
			local n = Spline.new(prev_a, prev_b, v, nxt)
			length += n.length
			parts[#parts + 1] = n
		end

		prev_a = prev_b
		prev_b = v
	end

	do
		local sb
		if loops then
			sb = Spline.new(pts[num_points - 2], pts[num_points - 1], pts[num_points], pts[num_points - 1]:Lerp(pts[num_points], 2))
		else
			sb = Spline.new(pts[num_points - 2], pts[num_points - 1], pts[num_points], pts[1])
		end

		length += sb.length
		parts[#parts + 1] = sb
	end

	local ranges = table.create(#parts)
	do
		local csum = 0
		for i, part in ipairs(parts) do
			csum += part.length
			ranges[i] = csum / length
		end
	end

	local nr = #ranges
	--Accepts a number in [0, 1] representing a point on the path.
	local function GetPointOnPath(val)
		local res, af
		for i = 1, nr do
			if ranges[i] > val or i == nr then
				af = (val - (ranges[i - 1] or 0))/parts[i].length*length
				res = parts[i]
				break
			end
		end

		return res:Solve(af)
	end

	return setmetatable({
		parts = parts;
		length = length;
		GetPointOnPath = GetPointOnPath;
	}, Path)
end

return {
	Spline = Spline;
	Path = Path;
}