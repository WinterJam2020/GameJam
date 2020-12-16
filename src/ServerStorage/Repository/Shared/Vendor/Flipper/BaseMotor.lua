local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local FastSignal = Resources:LoadLibrary("FastSignal")

local noop = function() end

local BaseMotor = {ClassName = "BaseMotor"}
BaseMotor.__index = BaseMotor

function BaseMotor.new()
	return setmetatable({
		_onStep = FastSignal.new(),
		_onComplete = FastSignal.new(),
	}, BaseMotor)
end

function BaseMotor:OnStep(handler)
	return self._onStep:Connect(handler)
end

function BaseMotor:OnComplete(handler)
	return self._onComplete:Connect(handler)
end

function BaseMotor:Start()
	if not self._connection then
		self._connection = RunService.Heartbeat:Connect(function(deltaTime)
			self:Step(deltaTime)
		end)
	end
end

function BaseMotor:Stop()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
end

BaseMotor.Destroy = BaseMotor.Stop

BaseMotor.Step = noop
BaseMotor.GetValue = noop
BaseMotor.SetGoal = noop

function BaseMotor:__tostring()
	return "Motor"
end

return BaseMotor