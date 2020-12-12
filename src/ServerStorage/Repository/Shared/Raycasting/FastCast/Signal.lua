-- A new implementation of RBXScriptSignal that uses proper Lua OOP.
-- This was explicitly made to transport other OOP objects.
-- I would be using BindableEvents, but they don't like cyclic tables (part of OOP objects with __index)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")

local Resources = require(ReplicatedStorage.Resources)
local Table = Resources:LoadLibrary("Table")

local SignalStatic = {ClassName = "Signal"}
SignalStatic.__index = SignalStatic

local ConnectionStatic = {ClassName = "SignalConnection"}
ConnectionStatic.__index = ConnectionStatic

-- Format params: methodName, ctorName
local ERR_NOT_INSTANCE = "Cannot statically invoke method '%s' - It is an instance method. Call it on an instance of this class created via %s"

function SignalStatic.new(signalName)
	return setmetatable({
		Connections = {};
		Name = signalName;
		YieldingThreads = {};
	}, SignalStatic)
end

local function NewConnection(sig, func)
	return setmetatable({
		Delegate = func;
		Index = -1;
		Signal = sig;
	}, ConnectionStatic)
end

local function ThreadAndReportError(delegate, args, handlerName)
	local thread = coroutine.create(function()
		delegate(table.unpack(args, 1, args.n))
	end)

	local success, msg = coroutine.resume(thread)
	if not success then
		-- For the love of god roblox PLEASE add the ability to customize message type in output statements.
		-- This "testservice" garbage at the start of my message is annoying as all hell.
		TestService:Error(string.format("Exception thrown in your %s event handler: %s", handlerName, msg))
		TestService:Checkpoint(debug.traceback(thread))
	end
end

function SignalStatic:Connect(func)
	assert(getmetatable(self) == SignalStatic, string.format(ERR_NOT_INSTANCE, "Connect", "Signal.new()"))
	local connection = NewConnection(self, func)
	connection.Index = #self.Connections + 1
	table.insert(self.Connections, connection.Index, connection)
	return connection
end

function SignalStatic:Fire(...)
	assert(getmetatable(self) == SignalStatic, string.format(ERR_NOT_INSTANCE, "Fire", "Signal.new()"))
	local args = table.pack(...)
	for _, connection in ipairs(self.Connections) do
		if connection.Delegate ~= nil then
			-- Catch case for disposed signals.
			ThreadAndReportError(connection.Delegate, args, connection.Signal.Name)
		end
	end

	for _, thread in ipairs(self.YieldingThreads) do
		if thread ~= nil then
			coroutine.resume(thread, ...)
		end
	end
end

function SignalStatic:FireSync(...)
	assert(getmetatable(self) == SignalStatic, string.format(ERR_NOT_INSTANCE, "FireSync", "Signal.new()"))
	local args = table.pack(...)
	for _, connection in ipairs(self.Connections) do
		if connection.Delegate ~= nil then
			-- Catch case for disposed signals.
			connection.Delegate(table.unpack(args, 1, args.n))
		end
	end

	for _, thread in ipairs(self.YieldingThreads) do
		if thread ~= nil then
			coroutine.resume(thread, ...)
		end
	end
end

function SignalStatic:Wait()
	assert(getmetatable(self) == SignalStatic, string.format(ERR_NOT_INSTANCE, "Wait", "Signal.new()"))
	local thread = coroutine.running()
	table.insert(self.YieldingThreads, thread)
	local args = table.pack(coroutine.yield())
	Table.RemoveObject(self.YieldingThreads, thread)
	return table.unpack(args, 1, args.n)
end

function SignalStatic:Destroy()
	assert(getmetatable(self) == SignalStatic, string.format(ERR_NOT_INSTANCE, "Dispose", "Signal.new()"))
	local allCons = self.Connections
	for index = 1, #allCons do
		allCons[index]:Disconnect()
	end

	table.clear(self.Connections)
	setmetatable(self, nil)
end

function ConnectionStatic:Disconnect()
	assert(getmetatable(self) == ConnectionStatic, string.format(ERR_NOT_INSTANCE, "Disconnect", "private function NewConnection()"))
	table.remove(self.Signal.Connections, self.Index)
	self.SignalStatic = nil
	self.Delegate = nil
	table.clear(self.YieldingThreads)
	self.Index = -1
	setmetatable(self, nil)
end

return SignalStatic