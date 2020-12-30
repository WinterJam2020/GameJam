--- Clean up utils a bit
-- @module HapticFeedbackUtils

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local Promise = Resources:LoadLibrary("Promise")
local Services = Resources:LoadLibrary("Services")
local Typer = Resources:LoadLibrary("Typer")

local HapticService: HapticService = Services.HapticService

local HapticFeedbackUtils = {}

HapticFeedbackUtils.SmallVibrate = Typer.AssignSignature(Typer.EnumOfTypeUserInputType, Typer.OptionalNumber, Typer.OptionalNumber, function(UserInputType: EnumItem, Length: number?, Amplitude: number?)
	Length = Length or 0.1
	Amplitude = Amplitude or 1

	if HapticFeedbackUtils.SetSmallVibration(UserInputType, Amplitude) then
		return Promise.Delay(Length):ThenCall(HapticFeedbackUtils.SetSmallVibration, UserInputType, 0)
	else
		return Promise.Resolve()
	end
end)

HapticFeedbackUtils.SetSmallVibration = Typer.AssignSignature(Typer.EnumOfTypeUserInputType, Typer.Number, function(UserInputType: EnumItem, Amplitude: number): boolean
	return HapticFeedbackUtils.SetVibrationMotor(UserInputType, Enum.VibrationMotor.Small, Amplitude)
end)

function HapticFeedbackUtils.SetVibrationMotor(UserInputType: EnumItem, VibrationMotor: EnumItem, Amplitude: number, ...): boolean
	assert(type(Amplitude) == "number")
	if not HapticService:IsVibrationSupported(UserInputType) then
		return false
	end

	if not HapticService:IsMotorSupported(UserInputType, VibrationMotor) then
		return false
	end

	HapticService:SetMotor(UserInputType, VibrationMotor, Amplitude, ...)
	return true
end

return HapticFeedbackUtils