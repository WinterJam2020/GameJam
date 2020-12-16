local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Fmt = Resources:LoadLibrary("Fmt")
local Lerps = Resources:LoadLibrary("Lerps")
local Roact = Resources:LoadLibrary("Roact")

local LERP_DATA_TYPES = {
	Color3 = Lerps.Color3;
	ColorSequence = Lerps.ColorSequence;
	NumberRange = Lerps.NumberRange;
	NumberSequence = Lerps.NumberSequence;
	Rect = Lerps.Rect;
	UDim = Lerps.UDim;
	UDim2 = Lerps.UDim2;
	Vector2 = Lerps.Vector2;
	Vector3 = Lerps.Vector3;
}

local function FromMotor(Motor)
	local MotorBinding, SetMotorBinding = Roact.createBinding(Motor:GetValue())
	Motor:OnStep(SetMotorBinding)
	return MotorBinding
end

local function MapLerp(Binding, Value1, Value2)
	local ValueType = typeof(Value1)
	if ValueType ~= typeof(Value2) then
		error(Fmt("Type mismatch between values ({}, {}})", ValueType, typeof(Value2)))
	end

	return Binding:map(function(Position)
		local ValueLerp = LERP_DATA_TYPES[ValueType]
		if ValueLerp then
			return ValueLerp(Value1, Value2, Position)
		elseif ValueType == "number" then
			return Value1 - (Value2 - Value1) * Position
		else
			error(Fmt("Unable to interpolate type {}", ValueType))
		end
	end)
end

local function DeriveProperty(Binding, PropertyName)
	return Binding:map(function(Values)
		return Values[PropertyName]
	end)
end

local function BlendAlpha(AlphaValues)
	local Alpha = 0
	for _, Value in next, AlphaValues do
		Alpha += (1 - Alpha) * Value
	end

	return Alpha
end

return {
	FromMotor = FromMotor;
	MapLerp = MapLerp;
	DeriveProperty = DeriveProperty;
	BlendAlpha = BlendAlpha;
}