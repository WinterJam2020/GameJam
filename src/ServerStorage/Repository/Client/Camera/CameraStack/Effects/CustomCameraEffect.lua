--- For effects that can be easily bound in scope
-- @classmod CustomCameraEffect

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local SummedCamera = Resources:LoadLibrary("SummedCamera")

local CustomCameraEffect = {ClassName = "CustomCameraEffect"}

--- Constructs a new custom camera effect
-- @tparam function getCurrentStateFunc to return a function state
function CustomCameraEffect.new(GetCurrentStateFunction)
	return setmetatable({
		GetCurrentStateFunction = GetCurrentStateFunction or error("GetCurrentStateFunction is required.", 2);
	}, CustomCameraEffect)
end

function CustomCameraEffect:__add(Other)
	return SummedCamera.new(self, Other)
end

function CustomCameraEffect:__index(Index)
	if Index == "CameraState" then
		return self.GetCurrentStateFunction()
	else
		return CustomCameraEffect[Index]
	end
end

return CustomCameraEffect