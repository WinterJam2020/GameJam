--- Point a current element
-- @classmod PointCamera

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local CameraState = Resources:LoadLibrary("CameraState")
local SummedCamera = Resources:LoadLibrary("SummedCamera")

local PointCamera = {ClassName = "PointCamera"}

--- Initializes a new PointCamera
-- @constructor
-- @param originCamera A camera to use
-- @param focusCamera The Camera to look at.
function PointCamera.new(originCamera, focusCamera)
	return setmetatable({
		OriginCamera = originCamera or error("Must have originCamera");
		FocusCamera = focusCamera or error("Must have focusCamera");
	}, PointCamera)
end

function PointCamera:__add(other)
	return SummedCamera.new(self, other)
end

function PointCamera:__newindex(index, value)
	if index == "OriginCamera" or index == "FocusCamera" then
		rawset(self, index, value)
	else
		error(index .. " is not a valid member of PointCamera")
	end
end

function PointCamera:__index(index)
	if index == "CameraState" then
		local origin, focus = self.Origin, self.Focus

		local state = CameraState.new()
		state.FieldOfView = origin.FieldOfView + focus.FieldOfView
		state.CFrame = CFrame.new(origin.Position, focus.Position)

		return state
	elseif index == "Focus" then
		return self.FocusCamera.CameraState
	elseif index == "Origin" then
		return self.OriginCamera.CameraState
	else
		return PointCamera[index]
	end
end

return PointCamera