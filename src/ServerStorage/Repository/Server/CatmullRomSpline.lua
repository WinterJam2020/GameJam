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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Typer = Resources:LoadLibrary("Typer")

local Spline = {ClassName = "Spline"}
Spline.__index = Spline

local ConstrainedAlpha = {Alpha = function(Value, TypeOfString)
	return TypeOfString == "number" and Value >= 0 and Value <= 1
end}

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
	Spline.new = Typer.AssignSignature(Typer.Vector3, Typer.Vector3, Typer.Vector3, Typer.Vector3, function(P0, P1, P2, P3)
		local cA = table.create(3)
		cA[1], cA[2], cA[3] = 2*P1.X, 2*P1.Y, 2*P1.Z

		local cB = table.create(3)
		cB[1], cB[2], cB[3] = -P0.X + P2.X, -P0.Y + P2.Y, -P0.Z + P2.Z

		local cC = table.create(3)
		cC[1], cC[2], cC[3] = 2*P0.X - 5*P1.X + 4*P2.X - P3.X, 2*P0.Y - 5*P1.Y + 4*P2.Y - P3.Y, 2*P0.Z - 5*P1.Z + 4*P2.Z - P3.Z

		local cD = table.create(3)
		cD[1], cD[2], cD[3] = -P0.X + 3*P1.X - 3*P2.X + P3.X, -P0.Y + 3*P1.Y - 3*P2.Y + P3.Y, -P0.Z + 3*P1.Z - 3*P2.Z + P3.Z

		return setmetatable({
			cA = cA;
			cB = cB;
			cC = cC;
			cD = cD;
			Length = (function()
				local Result = 0
				local StartHere = solve(cA, cB, cC, cD, 0)
				for Index = 0, 1 - RIEMANN_STEP, RIEMANN_STEP do
					local StopHere = solve(cA, cB, cC, cD, Index + RIEMANN_STEP)
					Result += (StopHere - StartHere).Magnitude
					StartHere = StopHere
				end

				Result *= RIEMANN_STEP
				return Result
			end)();
		}, Spline)
	end)

	-- Find a Vector3 position on the spline
	Spline.Solve = Typer.AssignSignature(2, ConstrainedAlpha, function(self, Alpha: number): Vector3
		return solve(self.cA, self.cB, self.cC, self.cD, Alpha)
	end)

	-- Find a CFrame position & orientation on the spline rotated in the direction of the path.  No z rotation.
	-- A seperate step for rotation might be better
	Spline.SolveNorm = Typer.AssignSignature(2, ConstrainedAlpha, Typer.OptionalNumber, function(self, Alpha: number, Smoothing: number?): CFrame
		return CFrame.new(self:Solve(Alpha), self:Solve(Alpha + (Smoothing or 0.01)))
	end)
end

-- Piecewise spline
-- Takes a table of Vector3/Vector2's representing points along the spline path.

local Path = {ClassName = "Path"}
Path.__index = Path

type Array<Value> = {[number]: Value}

Path.new = Typer.AssignSignature(Typer.ArrayOfVector3s, function(Points: Array<Vector3>)
	local NumberOfPoints = #Points
	assert(NumberOfPoints >= 4, "At least four points are required to construct a spline path")
	local Parts = {}
	local Length = 0
	local PreviousA, PreviousB = nil, nil
	local Loops = Points[1] == Points[NumberOfPoints]

	-- catmull rom splines don't pass through all four points, so extrapolate some extras as control points
	local SplineValue =
		Loops and Spline.new(Points[2]:Lerp(Points[1], 2), Points[1], Points[2], Points[3]) or
		Spline.new(Points[NumberOfPoints], Points[1], Points[2], Points[3])

	Length += SplineValue.Length
	Parts[1] = SplineValue

	for Index, Value in ipairs(Points) do
		local Next = Points[Index + 1]
		if PreviousA and PreviousB and Next then
			local NewSpline = Spline.new(PreviousA, PreviousB, Value, Next)
			Length += NewSpline.Length
			Parts[#Parts + 1] = NewSpline
		end

		PreviousA = PreviousB
		PreviousB = Value
	end

	local SplineB =
		Loops and Spline.new(Points[NumberOfPoints - 2], Points[NumberOfPoints - 1], Points[NumberOfPoints], Points[NumberOfPoints - 1]:Lerp(Points[NumberOfPoints], 2)) or
		Spline.new(Points[NumberOfPoints - 2], Points[NumberOfPoints - 1], Points[NumberOfPoints], Points[1])

	Length += SplineB.Length
	Parts[#Parts + 1] = SplineB

	local Ranges = table.create(#Parts)
	local CSum = 0
	for Index, Part in ipairs(Parts) do
		CSum += Part.Length
		Ranges[Index] = CSum / Length
	end

	local RangeLength = #Ranges
	--Accepts a number in [0, 1] representing a point on the path.
	local function GetPointOnPath(Value)
		local SplinePoint, Alpha
		for Index = 1, RangeLength do
			if Ranges[Index] > Value or Index == RangeLength then
				Alpha = (Value - (Ranges[Index - 1] or 0)) / Parts[Index].Length * Length
				SplinePoint = Parts[Index]
				break
			end
		end

		return SplinePoint:Solve(Alpha)
	end

	return setmetatable({
		Parts = Parts;
		Length = Length;
		GetPointOnPath = GetPointOnPath;
	}, Path)
end)

return {
	Spline = Spline;
	Path = Path;
}