--- Lags the camera smoothly behind the position maintaining other components
-- @classmod SmoothPositionCamera

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local CameraState = Resources:LoadLibrary("CameraState")
local Spring = Resources:LoadLibrary("Spring")
local SummedCamera = Resources:LoadLibrary("SummedCamera")

local SmoothPositionCamera = {ClassName = "SmoothPositionCamera"}

function SmoothPositionCamera.new(baseCamera)
	return setmetatable({
		Spring = Spring.new(Vector3.new());
		BaseCamera = baseCamera or error("Must have BaseCamera");
		Speed = 10;
	}, SmoothPositionCamera)
end

function SmoothPositionCamera:__add(other)
	return SummedCamera.new(self, other)
end

function SmoothPositionCamera:__newindex(index, value)
	if index == "BaseCamera" then
		rawset(self, "_" .. index, value)
		self.Spring.Target = self.BaseCamera.CameraState.Position
		self.Spring.Position = self.Spring.Target
		self.Spring.Velocity = Vector3.new()
	elseif index == "_lastUpdateTime" or index == "Spring" then
		rawset(self, index, value)
	elseif index == "Speed" or index == "Damper" or index == "Velocity" or index == "Position" then
		self:_internalUpdate()
		self.Spring[index] = value
	else
		error(index .. " is not a valid member of SmoothPositionCamera")
	end
end

function SmoothPositionCamera:__index(index)
	if index == "CameraState" then
		local baseCameraState = self.BaseCameraState

		local state = CameraState.new()
		state.FieldOfView = baseCameraState.FieldOfView
		state.CFrame = baseCameraState.CFrame
		state.Position = self.Position

		return state
	elseif index == "Position" then
		self:_internalUpdate()
		return self.Spring.Position
	elseif index == "Speed" or index == "Damper" or index == "Velocity" then
		return self.Spring[index]
	elseif index == "Target" then
		return self.BaseCameraState.Position
	elseif index == "BaseCameraState" then
		return self.BaseCamera.CameraState or self.BaseCamera
	elseif index == "BaseCamera" then
		return rawget(self, "_" .. index) or error("Internal error: index does not exist")
	else
		return SmoothPositionCamera[index]
	end
end

function SmoothPositionCamera:_internalUpdate()
	local delta
	if self._lastUpdateTime then
		delta = time() - self._lastUpdateTime
	end

	self._lastUpdateTime = time()
	self.Spring.Target = self.BaseCameraState.Position

	if delta then
		self.Spring:TimeSkip(delta)
	end
end

return SmoothPositionCamera