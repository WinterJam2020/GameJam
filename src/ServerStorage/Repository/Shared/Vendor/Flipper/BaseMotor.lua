local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local Janitor = Resources:LoadLibrary("Janitor")
local Signal = Resources:LoadLibrary("Signal")

local function Noop() end

local BaseMotor = {ClassName = "Motor"}
BaseMotor.__index = BaseMotor

function BaseMotor.new()
	local self = setmetatable({
		Janitor = Janitor.new();
		OnCompleteSignal = nil;
		OnStepSignal = nil;
	}, BaseMotor)

	self.OnCompleteSignal = self.Janitor:Add(Signal.new(), "Destroy")
	self.OnStepSignal = self.Janitor:Add(Signal.new(), "Destroy")
	self.Janitor:Add(function()
		for Index in next, self do
			self[Index] = nil
		end
	end, true)

	return self
end

function BaseMotor:OnStep(Function)
	return self.Janitor:Add(self.OnStepSignal:Connect(Function), "Disconnect")
end

function BaseMotor:OnComplete(Function)
	return self.Janitor:Add(self.OnCompleteSignal:Connect(Function), "Disconnect")
end

function BaseMotor:Start()
	if not self.Janitor:Get("Connection") then
		self.Janitor:Add(RunService.Heartbeat:Connect(function(DeltaTime)
			self:Step(DeltaTime)
		end), "Disconnect", "Connection")
	end
end

function BaseMotor:Stop()
	self.Janitor:Remove("Connection")
end

function BaseMotor:Destroy()
	self.Janitor = self.Janitor:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

BaseMotor.Step = Noop
BaseMotor.GetValue = Noop
BaseMotor.SetGoal = Noop

return BaseMotor