local RunService = game:GetService("RunService")
local Signal = require(script.Parent.Signal)
local NoYield = require(script.Parent.NoYield)

local Store = {
	ClassName = "RoduxStore";
	FlushEvent = RunService.Heartbeat;
	__tostring = function(self): string
		return self.ClassName
	end;
}

-- This value is exposed as a private value so that the test code can stay in
-- sync with what event we listen to for dispatching the Changed event.
-- It may not be Heartbeat in the future.

Store.__index = Store

--[[
	Create a new Store whose state is transformed by the given reducer function.

	Each time an action is dispatched to the store, the new state of the store
	is given by:

		state = reducer(state, action)

	Reducers do not mutate the state object, so the original state is still
	valid.
]]
function Store.new(Reducer, InitialState, Middlewares)
	assert(type(Reducer) == "function", "Bad argument #1 to Store.new, expected function.")
	assert(Middlewares == nil or type(Middlewares) == "table", "Bad argument #3 to Store.new, expected nil or table.")

	local self = setmetatable({
		Changed = Signal.new();

		Reducer = Reducer;
		State = Reducer(InitialState, {Type = "@@INIT"});
		LastState = nil;

		MutatedSinceFlush = false;
		Connections = {};
	}, Store)

	self.LastState = self.State
	table.insert(self.Connections, self.FlushEvent:Connect(function()
		self:Flush()
	end))

	if Middlewares then
		local UnboundDispatch = self.Dispatch
		local function Dispatch(...)
			return UnboundDispatch(self, ...)
		end

		for Index = #Middlewares, 1, -1 do
			local Middleware = Middlewares[Index]
			Dispatch = Middleware(Dispatch, self)
		end

		function self.Dispatch(_, ...)
			return Dispatch(...)
		end
	end

	return self
end

--[[
	Get the current state of the Store. Do not mutate this!
]]
function Store:GetState()
	warn("Store::GetState is deprecated, just reference Store.State directly!")
	return self.State
end

--[[
	Dispatch an action to the store. This allows the store's reducer to mutate
	the state of the application by creating a new copy of the state.

	Listeners on the changed event of the store are notified when the state
	changes, but not necessarily on every Dispatch.
]]
function Store:Dispatch(Action)
	if type(Action) == "table" then
		if Action.Type == nil then
			error("Action does not have a Type field", 2)
		end

		self.State = self.Reducer(self.State, Action)
		self.MutatedSinceFlush = true
	else
		error(string.format("actions of type %q are not permitted", typeof(Action)), 2)
	end
end

--[[
	Marks the store as deleted, disconnecting any outstanding connections.
]]
function Store:Destroy()
	for _, Connection in ipairs(self.Connections) do
		Connection:Disconnect()
	end

	self.Connections = nil
end

--[[
	Flush all pending actions since the last change event was dispatched.
]]
function Store:Flush()
	if not self.MutatedSinceFlush then
		return
	end

	self.MutatedSinceFlush = false

	-- On self.changed:fire(), further actions may be immediately dispatched, in
	-- which case self._lastState will be set to the most recent self._state,
	-- unless we cache this value first
	local State = self.State

	-- If a changed listener yields, *very* surprising bugs can ensue.
	-- Because of that, changed listeners cannot yield.
	NoYield(function()
		self.Changed:Fire(State, self.LastState)
	end)

	self.LastState = State
end

return Store
