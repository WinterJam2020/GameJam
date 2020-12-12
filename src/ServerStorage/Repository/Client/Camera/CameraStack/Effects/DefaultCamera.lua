-- Hack to maintain default camera control by binding before and after the camera update cycle
-- This allows other cameras to build off of the "default" camera while maintaining the same Roblox control scheme
-- @classmod DefaultCamera

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local CameraState = Resources:LoadLibrary("CameraState")
local SummedCamera = Resources:LoadLibrary("SummedCamera")

local DefaultCamera = {ClassName = "DefaultCamera"}

function DefaultCamera.new()
	return setmetatable({
		_CameraState = CameraState.new(Workspace.CurrentCamera);
	}, DefaultCamera)
end

function DefaultCamera:__add(Other)
	return SummedCamera.new(self, Other)
end

function DefaultCamera:OverrideGlobalFieldOfView(FieldOfView)
	self._CameraState.FieldOfView = FieldOfView
end

function DefaultCamera:OverrideCameraState(NewCameraState)
	self._CameraState = NewCameraState or error("No CameraState")
end

function DefaultCamera:BindToRenderStep()
	RunService:BindToRenderStep("DefaultCamera_Preupdate", Enum.RenderPriority.Camera.Value - 1, function()
		self._CameraState:Set(Workspace.CurrentCamera)
	end)

	RunService:BindToRenderStep("DefaultCamera_PostUpdate", Enum.RenderPriority.Camera.Value + 1, function()
		self._CameraState = CameraState.new(Workspace.CurrentCamera)
	end)

	self._CameraState = CameraState.new(Workspace.CurrentCamera)
end

function DefaultCamera.UnbindFromRenderStep(_)
	RunService:UnbindFromRenderStep("DefaultCamera_Preupdate")
	RunService:UnbindFromRenderStep("DefaultCamera_PostUpdate")
end

function DefaultCamera:__index(Index)
	if Index == "CameraState" then
		return rawget(self, "_CameraState")
	else
		return DefaultCamera[Index]
	end
end

return DefaultCamera