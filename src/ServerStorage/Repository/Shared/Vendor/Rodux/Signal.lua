--[[
	A limited, simple implementation of a Signal.

	Handlers are fired in order, and (dis)connections are properly handled when
	executing an event.
]]

local function immutableAppend(list, ...)
	local new = {}
	local len = #list

	for key = 1, len do
		new[key] = list[key]
	end

	for i = 1, select("#", ...) do
		new[len + i] = select(i, ...)
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

local Signal = {
	ClassName = "RoduxSignal";
	__tostring = function(self): string
		return self.ClassName
	end;
}

Signal.__index = Signal

function Signal.new()
	return setmetatable({
		Listeners = {};
	}, Signal)
end

function Signal:Connect(Function)
	local Listener = {
		Function = Function;
		Disconnected = false;
	}

	self.Listeners = immutableAppend(self.Listeners, Listener)

	local function Disconnect()
		Listener.Disconnected = true
		self.Listeners = immutableRemoveValue(self.Listeners, Listener)
	end

	return {
		Disconnect = Disconnect;
	}
end

function Signal:Fire(...)
	for _, Listener in ipairs(self.Listeners) do
		if not Listener.Disconnected then
			Listener.Function(...)
		end
	end
end

return Signal