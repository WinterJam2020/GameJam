local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local BaseMotor = require(script.Parent.BaseMotor)
local Debug = Resources:LoadLibrary("Debug")

local Debug_Assert = Debug.Assert

local SingleMotor = setmetatable({ClassName = "Motor(Single)"}, BaseMotor)
SingleMotor.__index = SingleMotor

function SingleMotor.new(InitialValue, UseImplicitConnections)
	Debug_Assert(type(InitialValue) == "number", "InitialValue must be a number!")

	local self = setmetatable(BaseMotor.new(), SingleMotor)

	if UseImplicitConnections ~= nil then
		self.UseImplicitConnections = UseImplicitConnections
	else
		self.UseImplicitConnections = true
	end

	self.Goal = nil
	self.State = {
		complete = true;
		value = InitialValue;
	}

	return self
end

function SingleMotor:Step(DeltaTime)
	if self.State.complete then
		return true
	end

	local NewState = self.Goal:Step(self.State, DeltaTime)

	self.State = NewState
	self.OnStepSignal:Fire(NewState.value)

	if NewState.complete then
		if self.UseImplicitConnections then
			self:Stop()
		end

		self.OnCompleteSignal:Fire()
	end

	return NewState.complete
end

function SingleMotor:GetValue()
	return self.State.value
end

function SingleMotor:SetGoal(Goal)
	self.State.complete = false
	self.Goal = Goal

	if self.UseImplicitConnections then
		self:Start()
	end
end

return SingleMotor