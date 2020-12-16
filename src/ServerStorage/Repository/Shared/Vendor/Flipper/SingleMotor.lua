local BaseMotor = require(script.Parent.BaseMotor)

local SingleMotor = setmetatable({ClassName = "SingleMotor"}, BaseMotor)
SingleMotor.__index = SingleMotor

function SingleMotor.new(initialValue, useImplicitConnections)
	assert(typeof(initialValue) == "number", "initialValue must be a number!")

	local self = setmetatable(BaseMotor.new(), SingleMotor)

	if useImplicitConnections ~= nil then
		self._useImplicitConnections = useImplicitConnections
	else
		self._useImplicitConnections = true
	end

	self._goal = nil
	self._state = {
		complete = true,
		value = initialValue,
	}

	return self
end

function SingleMotor:Step(deltaTime)
	if self._state.complete then
		return true
	end

	local newState = self._goal:Step(self._state, deltaTime)

	self._state = newState
	self._onStep:Fire(newState.value)

	if newState.complete then
		if self._useImplicitConnections then
			self:Stop()
		end

		self._onComplete:Fire()
	end

	return newState.complete
end

function SingleMotor:GetValue()
	return self._state.value
end

function SingleMotor:SetGoal(goal)
	self._state.complete = false
	self._goal = goal

	if self._useImplicitConnections then
		self:Start()
	end
end

function SingleMotor:__tostring()
	return "Motor(Single)"
end

return SingleMotor