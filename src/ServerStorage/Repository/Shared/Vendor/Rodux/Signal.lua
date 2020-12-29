--[[
	A limited, simple implementation of a Signal.

	Handlers are fired in order, and (dis)connections are properly handled when
	executing an event.
]]

local function immutableAppend(list, ...)
	local len = #list
	local varLen = select("#", ...)
	local new = table.create(varLen + len)

	for index = 1, len do
		new[index] = list[index]
	end

	for index = 1, varLen do
		new[len + index] = select(index, ...)
	end

	return new
end

local function immutableRemoveValue(list, removeValue)
	local new = {}
	local length = 0

	for _, value in ipairs(list) do
		if value ~= removeValue then
			length += 1
			new[length] = value
		end
	end

	return new
end

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({
		_listeners = {},
	}, Signal)
end

function Signal:connect(callback)
	local listener = {
		callback = callback,
		disconnected = false,
	}

	self._listeners = immutableAppend(self._listeners, listener)

	local function disconnect()
		listener.disconnected = true
		self._listeners = immutableRemoveValue(self._listeners, listener)
	end

	return {
		disconnect = disconnect,
	}
end

function Signal:fire(...)
	for _, listener in ipairs(self._listeners) do
		if not listener.disconnected then
			listener.callback(...)
		end
	end
end

return Signal