--- Point a current element but lag behind for a smoother experience
-- @classmod LagPointCamera

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local CameraState = Resources:LoadLibrary("CameraState")
local Spring = Resources:LoadLibrary("Spring")
local SummedCamera = Resources:LoadLibrary("SummedCamera")

local LagPointCamera = {
	ClassName = "LagPointCamera";
	_FocusCamera = nil;
	_OriginCamera = nil;
}

---
-- @constructor
-- @param originCamera A camera to use
-- @param focusCamera The Camera to look at.
function LagPointCamera.new(originCamera, focusCamera)
	return setmetatable({
		FocusSpring = Spring.new(Vector3.new());
		OriginCamera = originCamera or error("Must have originCamera");
		FocusCamera = focusCamera or error("Must have focusCamera");
		Speed = 10;
	}, LagPointCamera)
end

function LagPointCamera:__add(other)
	return SummedCamera.new(self, other)
end

function LagPointCamera:__newindex(index, value)
	if index == "FocusCamera" then
		rawset(self, "_" .. index, value)
		self.FocusSpring.Target = self.FocusCamera.CameraState.Position
		self.FocusSpring.Position = self.FocusSpring.Target
		self.FocusSpring.Velocity = Vector3.new()
	elseif index == "OriginCamera" then
		rawset(self, "_" .. index, value)
	elseif index == "LastFocusUpdate" or index == "FocusSpring" then
		rawset(self, index, value)
	elseif index == "Speed" or index == "Damper" or index == "Velocity" then
		self.FocusSpring[index] = value
	else
		error(index .. " is not a valid member of LagPointCamera")
	end
end

function LagPointCamera:__index(index)
	if index == "CameraState" then
		local origin, focusPosition = self.Origin, self.FocusPosition

		local state = CameraState.new()
		state.FieldOfView = origin.FieldOfView + self.FocusCamera.CameraState.FieldOfView
		state.CFrame = CFrame.new(origin.Position, focusPosition)

		return state
	elseif index == "FocusPosition" then
		local delta
		if self.LastFocusUpdate then
			delta = time() - self.LastFocusUpdate
		end

		self.LastFocusUpdate = time()
		self.FocusSpring.Target = self.FocusCamera.CameraState.Position

		if delta then
			self.FocusSpring:TimeSkip(delta)
		end

		return self.FocusSpring.Position
	elseif index == "Speed" or index == "Damper" or index == "Velocity" then
		return self.FocusSpring[index]
	elseif index == "Origin" then
		return self.OriginCamera.CameraState
	elseif index == "FocusCamera" or index == "OriginCamera" then
		return rawget(self, "_" .. index) or error("Internal error: index does not exist")
	else
		return LagPointCamera[index]
	end
end

return LagPointCamera