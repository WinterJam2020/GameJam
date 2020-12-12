--- Lock camera to only XZPlane, preventing TrackerCameras from making players sick.
-- @classmod XZPlaneLockCamera

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local CameraState = Resources:LoadLibrary("CameraState")
local CFrameUtility = Resources:LoadLibrary("CFrameUtility")
local SummedCamera = Resources:LoadLibrary("SummedCamera")

local XZPlaneLockCamera = {ClassName = "XZPlaneLockCamera"}

function XZPlaneLockCamera.new(camera)
	return setmetatable({_camera = assert(camera, "No camera")}, XZPlaneLockCamera)
end

function XZPlaneLockCamera:__add(other)
	return SummedCamera.new(self, other)
end

function XZPlaneLockCamera:__index(index)
	if index == "CameraState" then
		local state = self._camera.CameraState or self._camera
		local xzrot = CFrameUtility.GetRotationInXZPlane(state.CFrame)

		local newState = CameraState.new()
		newState.CFrame = xzrot
		newState.FieldOfView = state.FieldOfView

		return newState
	else
		return XZPlaneLockCamera[index]
	end
end

return XZPlaneLockCamera