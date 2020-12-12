--- Be the inverse of a fading camera (makes scaling in cameras easy).
-- @classmod InverseFader

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local SummedCamera = Resources:LoadLibrary("SummedCamera")

local InverseFader = {ClassName = "InverseFader"}

function InverseFader.new(camera, fader)
	return setmetatable({
		_camera = camera or error("No camera");
		_fader = fader or error("No fader");
	}, InverseFader)
end

function InverseFader:__add(other)
	return SummedCamera.new(self, other)
end

function InverseFader:__index(index)
	if index == "CameraState" then
		return (self._camera.CameraState or self._camera)*(1-self._fader.Value)
	else
		return InverseFader[index]
	end
end

return InverseFader