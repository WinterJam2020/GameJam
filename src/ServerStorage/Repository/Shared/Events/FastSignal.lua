local ENABLE_TRACEBACK = true

local FastSignal = {ClassName = "FastSignal"}
FastSignal.__index = FastSignal

--[[**
	Creates a new FastSignal object.
	@returns [FastSignal]
**--]]
function FastSignal.new()
	return setmetatable({
		BindableEvent = Instance.new("BindableEvent");
		Arguments = nil;
		Source = ENABLE_TRACEBACK and debug.traceback() or "";
	}, FastSignal)
end

--[[**
	Fire the event with the given arguments. All handlers will be invoked. Handlers follow Roblox signal conventions.
	@param [...Arguments] ... The arguments that will be passed to the connected functions.
	@returns [nil]
**--]]
function FastSignal:Fire(...): nil
	if not self.BindableEvent then
		return warn(string.format("Signal is already destroyed - traceback: %s", self.Source))
	end

	self.Arguments = table.pack(...)
	self.BindableEvent:Fire()
end

--[[**
	Connect a new handler to the event. Returns a connection object that can be disconnected.
	@param [Typer:Function] Function The function called with arguments passed when `:Fire(...)` is called.
	@returns [RBXScriptConnection] A RBXScriptConnection object that can be disconnected.
**--]]
function FastSignal:Connect(Function): RBXScriptConnection
	return self.BindableEvent.Event:Connect(function()
		local Arguments = self.Arguments
		Function(table.unpack(Arguments, 1, Arguments.n))
	end)
end

--[[**
	Wait for fire to be called, and return the arguments it was given.
	@returns [...Arguments] ... Variable arguments from connection.
**--]]
function FastSignal:Wait()
	self.BindableEvent.Event:Wait()
	local Arguments = self.Arguments
	if not Arguments then
		error("Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.", 2)
	end

	return table.unpack(Arguments, 1, Arguments.n)
end

--[[**
	Disconnects all connected events to the signal. Voids the signal as unusable.
	@returns [nil]
**--]]
function FastSignal:Destroy(): nil
	self.BindableEvent:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

return FastSignal