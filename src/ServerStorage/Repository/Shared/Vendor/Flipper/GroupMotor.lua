local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Debug = Resources:LoadLibrary("Debug")

local BaseMotor = require(script.Parent.BaseMotor)
local SingleMotor = require(script.Parent.SingleMotor)
local IsMotor = require(script.Parent.IsMotor)

local Debug_Assert = Debug.Assert

local GroupMotor = setmetatable({ClassName = "Motor(Group)"}, BaseMotor)
GroupMotor.__index = GroupMotor

local function ToMotor(Value)
	if IsMotor(Value) then
		return Value
	end

	local ValueType = typeof(Value)

	if ValueType == "number" then
		return SingleMotor.new(Value, false)
	elseif ValueType == "table" then
		return GroupMotor.new(Value, false)
	end

	error(string.format("Unable to convert %q to motor; type %s is unsupported", Value, ValueType))
end

function GroupMotor.new(InitialValues, UseImplicitConnections)
	Debug_Assert(type(InitialValues) == "table", "InitialValues must be a table!")
	local self = setmetatable(BaseMotor.new(), GroupMotor)

	if UseImplicitConnections ~= nil then
		self.UseImplicitConnections = UseImplicitConnections
	else
		self.UseImplicitConnections = true
	end

	self.Complete = true
	self.Motors = {}

	for Index, Value in next, InitialValues do
		self.Motors[Index] = ToMotor(Value)
	end

	return self
end

function GroupMotor:Step(DeltaTime)
	if self.Complete then
		return true
	end

	local AllMotorsComplete = true
	for _, Motor in next, self.Motors do
		if not Motor:Step(DeltaTime) then
			AllMotorsComplete = false
		end
	end

	self.OnStepSignal:Fire(self:GetValue())

	if AllMotorsComplete then
		if self.UseImplicitConnections then
			self:Stop()
		end

		self.Complete = true
		self.OnCompleteSignal:Fire()
	end

	return AllMotorsComplete
end

function GroupMotor:SetGoal(Goals)
	self.Complete = false
	for Index, Goal in next, Goals do
		Debug_Assert(self.Motors[Index], "Unknown motor for index %s", Index):SetGoal(Goal)
	end

	if self.UseImplicitConnections then
		self:Start()
	end
end

function GroupMotor:GetValue()
	local Values = {}
	for Index, Motor in next, self.Motors do
		Values[Index] = Motor:GetValue()
	end

	return Values
end

return GroupMotor