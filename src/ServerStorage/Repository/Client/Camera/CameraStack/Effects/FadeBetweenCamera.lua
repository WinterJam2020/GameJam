--- Add another layer of effects that can be faded in/out
-- @classmod FadeBetweenCamera

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)

local Debug = Resources:LoadLibrary("Debug")
local Spring = Resources:LoadLibrary("Spring")
local SummedCamera = Resources:LoadLibrary("SummedCamera")
local FieldOfViewUtils = Resources:LoadLibrary("FieldOfViewUtils")

local EPSILON = 1E-4

local FadeBetweenCamera = {ClassName = "FadeBetweenCamera"}

function FadeBetweenCamera.new(CameraA, CameraB)
	return setmetatable({
		_spring = Spring.new(0);
		CameraA = CameraA or error("No cameraA");
		CameraB = CameraB or error("No cameraB");

		Damper = 1;
		Speed = 15;
	}, FadeBetweenCamera)
end

function FadeBetweenCamera:__add(Other)
	return SummedCamera.new(self, Other)
end

function FadeBetweenCamera:__newindex(Index, Value)
	if Index == "Damper" then
		self._spring.Damper = Value
	elseif Index == "Value" then
		self._spring.Value = Value
	elseif Index == "Speed" then
		self._spring.Speed = Value
	elseif Index == "Target" then
		self._spring.Target = Value
	elseif Index == "Velocity" then
		self._spring.Velocity = Value
	elseif Index == "CameraA" or Index == "CameraB" then
		rawset(self, Index, Value)
	else
		Debug.Error("%q is not a valid member of FadeBetweenCamera", tostring(Index))
	end
end

function FadeBetweenCamera:__index(Index)
	if Index == "CameraState" then
		local value = self._spring.Value

		if math.abs(value - 1) <= EPSILON then
			return self.CameraStateB
		elseif math.abs(value) <= EPSILON then
			return self.CameraStateA
		else
			local stateA = self.CameraStateA
			local stateB = self.CameraStateB
			local delta = stateB - stateA

			if delta.Quaterion.w < 0 then
				delta.Quaterion = -delta.Quaterion
			end

			local newState = stateA + delta*value
			newState.FieldOfView = FieldOfViewUtils.LerpInHeightSpace(stateA.FieldOfView, stateB.FieldOfView, value)

			return newState
		end
	elseif Index == "CameraStateA" then
		return self.CameraA.CameraState or self.CameraA
	elseif Index == "CameraStateB" then
		return self.CameraB.CameraState or self.CameraB
	elseif Index == "Damper" then
		return self._spring.Damper
	elseif Index == "Value" then
		return self._spring.Value
	elseif Index == "Speed" then
		return self._spring.Speed
	elseif Index == "Target" then
		return self._spring.Target
	elseif Index == "Velocity" then
		return self._spring.Velocity
	elseif Index == "HasReachedTarget" then
		return math.abs(self.Value - self.Target) < EPSILON and math.abs(self.Velocity) < EPSILON
	elseif Index == "Spring" then
		return self._spring
	else
		return FadeBetweenCamera[Index]
	end
end

return FadeBetweenCamera