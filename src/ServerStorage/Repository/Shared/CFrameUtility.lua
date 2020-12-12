local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Table = Resources:LoadLibrary("Table")
local t = Resources:LoadLibrary("t")

local CFrameUtility = {}

local EMPTY_CFRAME: CFrame = CFrame.new()
local UP_VECTOR3: Vector3 = Vector3.fromNormalId(Enum.NormalId.Top)
local BACK_VECTOR3: Vector3 = Vector3.fromNormalId(Enum.NormalId.Back)
local HALF_PI_X_ANGLES: CFrame = CFrame.Angles(1.5707963267949, 0, 0)

local function GetTransitionBetween(VectorOne: Vector3, VectorTwo: Vector3, PitchAxis: Vector3): CFrame
	local DotProduct: number = VectorOne:Dot(VectorTwo)
	if DotProduct > 0.99999 then
		return EMPTY_CFRAME
	elseif DotProduct < -0.99999 then
		return CFrame.fromAxisAngle(PitchAxis, 3.1415926535898)
	else
		return CFrame.fromAxisAngle(VectorOne:Cross(VectorTwo), math.acos(DotProduct))
	end
end

function CFrameUtility.GetRotationInXZPlane(CoordinateFrame: CFrame): CFrame
	local TypeSuccess, TypeError = t.CFrame(CoordinateFrame)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	local BackVector: Vector3 = -CoordinateFrame.LookVector
	BackVector = Vector3.new(BackVector.X, 0, BackVector.Z).Unit
	local RightVector: Vector3 = CoordinateFrame.RightVector

	return CFrame.new(
		CoordinateFrame.X, CoordinateFrame.Y, CoordinateFrame.Z,
		RightVector.X, 0, BackVector.X,
		RightVector.Y, 1, BackVector.Y,
		RightVector.Z, 0, BackVector.Z
	)
end

local GetSurfaceCFrameTuple = t.tuple(t.instanceIsA("BasePart"), t.Vector3)

function CFrameUtility.GetSurfaceCFrame(BasePart: BasePart, LNormal: Vector3): CFrame
	local TypeSuccess, TypeError = GetSurfaceCFrameTuple(BasePart, LNormal)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	local Transition: CFrame = GetTransitionBetween(UP_VECTOR3, LNormal, BACK_VECTOR3)
	return BasePart.CFrame * Transition * HALF_PI_X_ANGLES
end

return Table.Lock(CFrameUtility, nil, script.Name)