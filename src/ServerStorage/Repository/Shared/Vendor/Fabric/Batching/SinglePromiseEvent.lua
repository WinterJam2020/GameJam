local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Promise = Resources:LoadLibrary("Promise")

local SinglePromiseEvent = {ClassName = "SinglePromiseEvent"}
SinglePromiseEvent.__index = SinglePromiseEvent

function SinglePromiseEvent.new(executor)
	local self = setmetatable({
		_listener = nil;
	}, SinglePromiseEvent)

	local function fire()
		if self._listener then
			local thread = coroutine.create(self._listener)
			coroutine.resume(thread)
		end
	end

	self._promise = Promise.Defer(function(resolve)
		resolve(Promise.new(executor(fire)):Then(function()
			self._listener = nil
		end))
	end)

	return self
end

function SinglePromiseEvent:Connect(callback)
	assert(self._listener == nil, "SinglePromiseEvent is already used up")
	assert(self._promise:GetStatus() == Promise.Status.Started, "SinglePromiseEvent is already used up")

	self._listener = callback
	return {
		Disconnect = function()
			self._promise:Cancel()
			self._listener = nil
		end;
	}
end

return SinglePromiseEvent