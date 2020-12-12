-- Update on heartbeat, must GC this camera state, unlike others. This
-- allows for camera effects to run on heartbeat and cache information once instead
-- of potentially going deeep into a tree and getting invoked multiple times
-- @classmod HeartbeatCamera

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local Janitor = Resources:LoadLibrary("Janitor")
local SummedCamera = Resources:LoadLibrary("SummedCamera")

local HeartbeatCamera = {
	ClassName = "HeartbeatCamera";
	ProfileName = "HeartbeatCamera";
}

function HeartbeatCamera.new(camera)
	local self = setmetatable({
		_camera = assert(camera, "No camera");
		_janitor = Janitor.new();
		_currentStateCache = camera.CameraState or error("Camera state returned null");
	}, HeartbeatCamera)

	self._janitor:Add(RunService.Heartbeat:Connect(function()
		debug.profilebegin(self.ProfileName)
		self._currentStateCache = self._camera.CameraState or error("Camera state returned null")
		debug.profileend()
	end), "Disconnect")

	return self
end

function HeartbeatCamera:__add(other)
	return SummedCamera.new(self, other)
end

function HeartbeatCamera:ForceUpdateCache()
	self._currentStateCache = self._camera.CameraState
end

function HeartbeatCamera:__index(index)
	if index == "CameraState" then
		return self._currentStateCache
	else
		return HeartbeatCamera[index]
	end
end

function HeartbeatCamera:Destroy()
	self._janitor:Destroy()
	setmetatable(self, nil)
end

return HeartbeatCamera