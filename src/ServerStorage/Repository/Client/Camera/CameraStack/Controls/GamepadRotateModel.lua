--- Rotation model for gamepad controls
-- @classmod GamepadRotateModel

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)

local AccelTween = Resources:LoadLibrary("AccelTween")
local BaseObject = Resources:LoadLibrary("BaseObject")
local CameraGamepadInputUtils = Resources:LoadLibrary("CameraGamepadInputUtils")

local GamepadRotateModel = setmetatable({ClassName = "GamepadRotateModel"}, BaseObject)
GamepadRotateModel.__index = GamepadRotateModel

function GamepadRotateModel.new()
	local self = setmetatable(BaseObject.new(), GamepadRotateModel)

	self.RampVelocityX = AccelTween.new(25)
	self.RampVelocityY = AccelTween.new(25)

	self.IsRotating = self.Janitor:Add(Instance.new("BoolValue"), "Destroy")
	self.IsRotating.Value = false

	return self
end

function GamepadRotateModel:GetThumbstickDeltaAngle()
	if not self.LastInputObject then
		return Vector2.new()
	end

	return Vector2.new(self.RampVelocityX.Position, self.RampVelocityY.Position)
end

function GamepadRotateModel:StopRotate()
	self.LastInputObject = nil
	self.RampVelocityX.Target = 0
	self.RampVelocityX.Position = self.RampVelocityX.Target

	self.RampVelocityY.Target = 0
	self.RampVelocityY.Position = self.RampVelocityY.Target

	self.IsRotating.Value = false
end

function GamepadRotateModel:HandleThumbstickInput(InputObject)
	if CameraGamepadInputUtils.OutOfDeadZone(InputObject) then
		self.LastInputObject = InputObject

		local StickOffset = self.LastInputObject.Position
		StickOffset = Vector2.new(-StickOffset.X, StickOffset.Y) -- Invert axis!

		local AdjustedStickOffset = CameraGamepadInputUtils.GamepadLinearToCurve(StickOffset)
		self.RampVelocityX.Target = AdjustedStickOffset.X
		self.RampVelocityY.Target = AdjustedStickOffset.Y

		self.IsRotating.Value = true
	else
		self:StopRotate()
	end
end

return GamepadRotateModel