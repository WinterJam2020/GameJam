--- Allow freedom of movement around a current place, much like the classic script works now.
-- Not intended to be use with the current character script
-- Intended to be used with a SummedCamera, relative.
-- @classmod SmoothZoomedCamera

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local CameraState = Resources:LoadLibrary("CameraState")
local Spring = Resources:LoadLibrary("Spring")
local SummedCamera = Resources:LoadLibrary("SummedCamera")

local SmoothZoomedCamera = {
	ClassName = "SmoothZoomedCamera";
	BounceAtEnd = true;

	_maxZoom = 100;
	_minZoom = 0.5;
}

function SmoothZoomedCamera.new()
	return setmetatable({
		Spring = Spring.new(0);
		Speed = 15;
	}, SmoothZoomedCamera)
end

function SmoothZoomedCamera:__add(other)
	return SummedCamera.new(self, other)
end

function SmoothZoomedCamera:ZoomIn(value, min, max)
	if min or max then
		self.Zoom -= math.clamp(value, min or -math.huge, max or math.huge)
	else
		self.Zoom -= value
	end
end

function SmoothZoomedCamera:Impulse(value)
	self.Spring:Impulse(value)
end

function SmoothZoomedCamera:__newindex(index, value)
	if index == "TargetZoom" or index == "Target" then
		local target = math.clamp(value, self.MinZoom, self.MaxZoom)
		self.Spring.Target = target

		if self.BounceAtEnd then
			if target < value then
				self:Impulse(self.MaxZoom)
			elseif target > value then
				self:Impulse(-self.MinZoom)
			end
		end
	elseif index == "TargetPercentZoom" then
		self.Target = self.MinZoom + self.Range*value
	elseif index == "PercentZoom" then
		self.Zoom = self.MinZoom + self.Range*value
	elseif index == "Damper" then
		self.Spring.Damper = value
	elseif index == "Value" or index == "Zoom" then
		self.Spring.Value = math.clamp(value, self.MinZoom, self.MaxZoom)
	elseif index == "Speed" then
		self.Spring.Speed = value
	elseif index == "MaxZoom" then
		--assert(value > self.MinZoom, "MaxZoom can't be less than MinZoom")

		self._maxZoom = value
	elseif index == "MinZoom" then
		--assert(value < self.MaxZoom, "MinZoom can't be greater than MinZoom")

		self._minZoom = value
	else
		rawset(self, index, value)
	end
end

function SmoothZoomedCamera:__index(index)
	if index == "CameraState" then
		local state = CameraState.new()
		state.Position = Vector3.new(0, 0, self.Zoom)
		return state
	elseif index == "Zoom" or index == "value" then
		return self.Spring.Value
	elseif index == "TargetPercentZoom" then
		return (self.Target - self.MinZoom) / self.Range
	elseif index == "PercentZoom" then
		return (self.Zoom - self.MinZoom) / self.Range
	elseif index == "MaxZoom" then
		return self._maxZoom
	elseif index == "MinZoom" then
		return self._minZoom
	elseif index == "Range" then
		return self.MaxZoom - self.MinZoom
	elseif index == "Damper" then
		return self.Spring.Damper
	elseif index == "Speed" then
		return self.Spring.Speed
	elseif index == "Target" or index == "TargetZoom" then
		return self.Spring.Target
	elseif index == "Velocity" then
		return self.Spring.Velocity
	elseif index == "HasReachedTarget" then
		return math.abs(self.Value - self.Target) < 1E-4 and math.abs(self.Velocity) < 1E-4
	else
		return SmoothZoomedCamera[index]
	end
end

return SmoothZoomedCamera