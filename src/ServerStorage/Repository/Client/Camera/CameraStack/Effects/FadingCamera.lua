--- Add another layer of effects that can be faded in/out
-- @classmod FadingCamera

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Spring = Resources:LoadLibrary("Spring")
local SummedCamera = Resources:LoadLibrary("SummedCamera")

local FadingCamera = {ClassName = "FadingCamera"}

function FadingCamera.new(camera)
	return setmetatable({
		Spring = Spring.new(0);
		Camera = assert(camera, "No camera");
		Damper = 1;
		Speed = 15;
	}, FadingCamera)
end

function FadingCamera:__add(other)
	return SummedCamera.new(self, other)
end

function FadingCamera:__newindex(index, value)
	if index == "Damper" then
		self.Spring.Damper = value
	elseif index == "value" then
		self.Spring.Value = value
	elseif index == "Speed" then
		self.Spring.Speed = value
	elseif index == "Target" then
		self.Spring.Target = value
	elseif index == "Spring" or index == "Camera" then
		rawset(self, index, value)
	else
		error(index .. " is not a valid member of fading camera")
	end
end

function FadingCamera:__index(index)
	if index == "CameraState" then
		return (self.Camera.CameraState or self.Camera) * self.Spring.Value
	elseif index == "Damper" then
		return self.Spring.Damper
	elseif index == "value" then
		return self.Spring.Value
	elseif index == "Speed" then
		return self.Spring.Speed
	elseif index == "Target" then
		return self.Spring.Target
	elseif index == "Velocity" then
		return self.Spring.Velocity
	elseif index == "HasReachedTarget" then
		return math.abs(self.Value - self.Target) < 1e-4 and math.abs(self.Velocity) < 1e-4
	else
		return FadingCamera[index]
	end
end

return FadingCamera