---
-- @module CameraGamepadInputUtils
-- @author Quenty

local CameraGamepadInputUtils = {}

-- K is a tunable parameter that changes the shape of the S-curve
-- the larger K is the more straight/linear the curve gets
local k = 0.35
local lowerK = 0.8
local function SCurveTranform(t)
	t = math.clamp(t, -1, 1)
	if t >= 0 then
		return (k*t) / (k - t + 1)
	end
	return -((lowerK*-t) / (lowerK + t + 1))
end

local DEADZONE = 0.1
local function toSCurveSpace(t)
	return (1 + DEADZONE) * (2*math.abs(t) - 1) - DEADZONE
end

local function fromSCurveSpace(t)
	return t/2 + 0.5
end

function CameraGamepadInputUtils.OutOfDeadZone(InputObject)
	return InputObject.Position.Magnitude >= DEADZONE
end

local function OnAxis(AxisValue)
	local Sign = 1
	if AxisValue < 0 then
		Sign = -1
	end

	return math.clamp(fromSCurveSpace(SCurveTranform(toSCurveSpace(math.abs(AxisValue)))) * Sign, -1, 1)
end

function CameraGamepadInputUtils.GamepadLinearToCurve(ThumbstickPosition: Vector2)
	return Vector2.new(OnAxis(ThumbstickPosition.X), OnAxis(ThumbstickPosition.Y))
end


return CameraGamepadInputUtils