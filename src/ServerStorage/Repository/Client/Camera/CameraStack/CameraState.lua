--- Data container for the state of a camera.
-- @classmod CameraState

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Debug = Resources:LoadLibrary("Debug")
local QuaternionObject = Resources:LoadLibrary("QuaternionObject")

local CameraState = {
	ClassName = "CameraState";
	FieldOfView = 0;
	Quaterion = QuaternionObject.new();
	Position = Vector3.new();
}

function CameraState:__index(Index)
	if Index == "CFrame" then
		return QuaternionObject.ToCFrame(self.Quaterion, self.Position)
	else
		return CameraState[Index]
	end
end

function CameraState:__newindex(Index, Value)
	if Index == "CFrame" then
		rawset(self, "Position", Value.Position)
		rawset(self, "Quaterion", QuaternionObject.FromCFrame(Value))
	elseif Index == "FieldOfView" or Index == "Position" or Index == "Quaterion" then
		rawset(self, Index, Value)
	else
		Debug.Error("%q is not a valid index of CameraState", tostring(Index))
	end
end

--- Builds a new camera stack
-- @constructor
-- @param[opt=nil] camera
-- @treturn CameraState
function CameraState.new(Camera)
	local self = setmetatable({}, CameraState)

	if Camera then
		self.FieldOfView = Camera.FieldOfView
		self.CFrame = Camera.CFrame
	end

	return self
end

--- Current FieldOfView
-- @tfield number FieldOfView

--- Current CFrame
-- @tfield CFrame CFrame

--- Current Position
-- @tfield Vector3 Position

--- Quaternion representation of the rotation of the CameraState
-- @tfield Quaterion Quaternion


--- Adds two camera states together
-- @tparam CameraState other
function CameraState:__add(Other)
	local NewCameraState = CameraState.new(self)
	NewCameraState.FieldOfView = self.FieldOfView + Other.FieldOfView
	NewCameraState.Position = NewCameraState.Position + Other.Position
	NewCameraState.Quaterion = self.Quaterion * Other.Quaterion
	return NewCameraState
end

--- Subtract the camera state from another
-- @tparam CameraState other
function CameraState:__sub(Other)
	local NewCameraState = CameraState.new(self)
	NewCameraState.FieldOfView = self.FieldOfView - Other.FieldOfView
	NewCameraState.Position = NewCameraState.Position - Other.Position
	NewCameraState.Quaterion = self.Quaterion / Other.Quaterion
	return NewCameraState
end

--- Inverts camera state
function CameraState:__unm()
	local NewCameraState = CameraState.new(self)
	NewCameraState.FieldOfView = -self.FieldOfView
	NewCameraState.Position = -self.Position
	NewCameraState.Quaterion = -self.Quaterion
	return NewCameraState
end

--- Multiply camera state by percent effect
-- @tparam number other
function CameraState:__mul(Other)
	local NewCameraState = CameraState.new(self)

	if type(Other) == "number" then
		NewCameraState.FieldOfView = self.FieldOfView * Other
		NewCameraState.Quaterion = self.Quaterion ^ Other
		NewCameraState.Position = self.Position * Other
	else
		error("Invalid other")
	end

	return NewCameraState
end

--- Set another camera state. Typically used to set Workspace.CurrentCamera's state to match this camera's state
-- @tparam Camera camera A CameraState to set, also accepts a Roblox Camera
-- @treturn nil
function CameraState:Set(Camera)
	Camera.FieldOfView = self.FieldOfView
	Camera.CFrame = self.CFrame
end

return CameraState