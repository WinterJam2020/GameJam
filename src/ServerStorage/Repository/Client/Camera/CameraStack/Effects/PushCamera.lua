--- Like a rotated camera, except we end up pushing back to a default rotation.
-- This same behavior is seen in Roblox vehicle seats
-- @classmod PushCamera

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)

local CameraState = Resources:LoadLibrary("CameraState")
local CFrameUtility = Resources:LoadLibrary("CFrameUtility")
local Math = Resources:LoadLibrary("Math")
local SummedCamera = Resources:LoadLibrary("SummedCamera")

local PushCamera = {
	ClassName = "PushCamera";

	-- Max/Min aim up and down
	_maxY = math.rad(80);
	_minY = math.rad(-80);
	_angleXZ0 = 0; -- Initial
	_angleY = 0;
	FadeBackTime = 0.5;
	DefaultAngleXZ0 = 0;
	_lastUpdateTime = -1;
	PushBackAfter = 0.5;
}

function PushCamera.new()
	return setmetatable({}, PushCamera)
end

function PushCamera:__add(other)
	return SummedCamera.new(self, other)
end
---
-- @param xzrotVector Vector2, the delta rotation to apply
function PushCamera:RotateXY(xzrotVector)
	self.AngleX += xzrotVector.X
	self.AngleY += xzrotVector.Y
end

function PushCamera:StopRotateBack()
	self.CFrame = self.CFrame
end

--- Resets to default position automatically
function PushCamera:Reset()
	self.LastUpdateTime = 0
end

function PushCamera:__newindex(index, value)
	if index == "CFrame" then
		local xzrot = CFrameUtility.GetRotationInXZPlane(value)
		self.AngleXZ = math.atan2(xzrot.LookVector.X, xzrot.LookVector.Z) + math.pi

		local yrot = xzrot:ToObjectSpace(value).LookVector.Y
		self.AngleY = math.asin(yrot)
	elseif index == "DefaultCFrame" then
		local xzrot = CFrameUtility.GetRotationInXZPlane(value)
		self.DefaultAngleXZ0 = math.atan2(xzrot.LookVector.X, xzrot.LookVector.Z) + math.pi

		local yrot = xzrot:ToObjectSpace(value).LookVector.Y
		self.AngleY = math.asin(yrot)
	elseif index == "AngleY" then
		self._angleY = math.clamp(value, self.MinY, self.MaxY)
	elseif index == "AngleX" or index == "AngleXZ" then
		self.LastUpdateTime = time()
		self._angleXZ0 = value
	elseif index == "MaxY" then
		assert(value > self.MinY, "MaxY must be greater than MinY")
		self._maxY = value
		self.AngleY = self.AngleY -- Reclamp value
	elseif index == "MinY" then
		assert(value < self.MinY, "MinY must be less than MeeeaxY")
		self._maxY = value
		self.AngleY = self.AngleY -- Reclamp value
	elseif index == "LastUpdateTime" then
		self._lastUpdateTime = value
	elseif PushCamera[index] ~= nil then
		rawset(self, index, value)
	else
		error(index .. " is not a valid member or PushCamera")
	end
end

function PushCamera:__index(index)
	if index == "CameraState" then
		local state = CameraState.new()
		state.CFrame = self.CFrame
		return state
	elseif index == "LastUpdateTime" then
		return self._lastUpdateTime
	elseif index == "LookVector" then
		return self.Rotation.LookVector
	elseif index == "CFrame" then
		return CFrame.Angles(0, self.AngleXZ, 0) * CFrame.Angles(self.AngleY, 0, 0)
	elseif index == "AngleY" then
		return self._angleY
	elseif index == "PushBackDelta" then
		return time() - self.LastUpdateTime - self.PushBackAfter
	elseif index == "PercentFaded" then
		-- How far in we are to the animation. Starts at 0 upon update and goes slowly to 1.
		return math.clamp(self.PushBackDelta / self.FadeBackTime, 0, 1)
	elseif index == "PercentFadedCurved" then
		-- A curved value of PercentFaded
		return self.PercentFaded ^ 2
	elseif index == "AngleX" or index == "AngleXZ" then
		return Math.Lerp(self._angleXZ0, self.DefaultAngleXZ0, self.PercentFadedCurved)
	elseif index == "MaxY" then
		return self._maxY
	elseif index == "MinY" then
		return self._minY
	else
		return PushCamera[index]
	end
end

return PushCamera
