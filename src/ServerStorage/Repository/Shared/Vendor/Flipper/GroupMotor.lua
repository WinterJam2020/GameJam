local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Debug = Resources:LoadLibrary("Debug")

local BaseMotor = require(script.Parent.BaseMotor)
local SingleMotor = require(script.Parent.SingleMotor)

local IsMotor = require(script.Parent.IsMotor)

local GroupMotor = setmetatable({ClassName = "GroupMotor"}, BaseMotor)
GroupMotor.__index = GroupMotor

local Debug_Assert = Debug.Assert

local function toMotor(value)
	if IsMotor(value) then
		return value
	end

	local valueType = typeof(value)

	if valueType == "number" then
		return SingleMotor.new(value, false)
	elseif valueType == "table" then
		return GroupMotor.new(value, false)
	end

	Debug.Error("Unable to convert %q to motor; type %s is unsupported", value, valueType)
end

function GroupMotor.new(initialValues, useImplicitConnections)
	assert(type(initialValues) == "table", "initialValues must be a table!")

	local self = setmetatable(BaseMotor.new(), GroupMotor)

	if useImplicitConnections ~= nil then
		self._useImplicitConnections = useImplicitConnections
	else
		self._useImplicitConnections = true
	end

	self._complete = true
	self._motors = {}

	for key, value in next, initialValues do
		self._motors[key] = toMotor(value)
	end

	return self
end

function GroupMotor:Step(deltaTime)
	if self._complete then
		return true
	end

	local allMotorsComplete = true

	for _, motor in next, self._motors do
		local complete = motor:Step(deltaTime)
		if not complete then
			-- If any of the sub-motors are incomplete, the group motor will not be complete either
			allMotorsComplete = false
		end
	end

	self._onStep:Fire(self:GetValue())

	if allMotorsComplete then
		if self._useImplicitConnections then
			self:Stop()
		end

		self._complete = true
		self._onComplete:Fire()
	end

	return allMotorsComplete
end

function GroupMotor:SetGoal(goals)
	self._complete = false

	for key, goal in next, goals do
		Debug_Assert(self._motors[key], "Unknown motor for key %s", key):SetGoal(goal)
	end

	if self._useImplicitConnections then
		self:Start()
	end
end

function GroupMotor:GetValue()
	local values = {}

	for key, motor in next, self._motors do
		values[key] = motor:GetValue()
	end

	return values
end

function GroupMotor:__tostring()
	return "Motor(Group)"
end

return GroupMotor