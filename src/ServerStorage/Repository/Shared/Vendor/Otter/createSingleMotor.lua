local RunService = game:GetService("RunService")

local createSignal = require(script.Parent.createSignal)

local SingleMotor = {}
SingleMotor.prototype = {}
SingleMotor.__index = SingleMotor.prototype

local function createSingleMotor(initialValue)
	assert(typeof(initialValue) == "number")

	local self = {
		__goal = nil,
		__state = {
			value = initialValue,
			complete = true,
		},
		__onComplete = createSignal(),
		__onStep = createSignal(),
		__running = false,
	}

	setmetatable(self, SingleMotor)

	return self
end

function SingleMotor.prototype:GetValue()
	return self.__state.value
end

function SingleMotor.prototype:Start()
	if self.__running then
		return
	end

	self.__connection = RunService.Heartbeat:Connect(function(dt)
		self:Step(dt)
	end)

	self.__running = true
end

function SingleMotor.prototype:Stop()
	if self.__connection ~= nil then
		self.__connection:Disconnect()
	end

	self.__running = false
end

function SingleMotor.prototype:Step(dt)
	assert(typeof(dt) == "number")

	if self.__state.complete then
		return
	end

	if self.__goal == nil then
		return
	end

	local newState = self.__goal:Step(self.__state, dt)

	if newState ~= nil then
		self.__state = newState
	end

	self.__onStep:Fire(self.__state.value)

	if self.__state.complete and self.__running then
		self:Stop()
		self.__onComplete:Fire(self.__state.value)
	end
end

function SingleMotor.prototype:SetGoal(goal)
	self.__goal = goal
	self.__state.complete = false
	self:Start()
end

function SingleMotor.prototype:OnStep(callback)
	assert(typeof(callback) == "function")

	return self.__onStep:Connect(callback)
end

function SingleMotor.prototype:OnComplete(callback)
	assert(typeof(callback) == "function")

	return self.__onComplete:Connect(callback)
end

function SingleMotor.prototype:Destroy()
	self:Stop()
	table.clear(self)
	setmetatable(self, nil)
end

return createSingleMotor