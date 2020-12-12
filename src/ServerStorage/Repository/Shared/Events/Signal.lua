local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Debug = Resources:LoadLibrary("Debug")
local Table = Resources:LoadLibrary("Table")

local Signals = setmetatable({}, {__mode = "k"})
local EventInterfaces = setmetatable({}, {__mode = "kv"})
local PseudoConnections = setmetatable({}, {__mode = "kv"})

local Debug_Error = Debug.Error
local Table_FastRemoveGivenLength = Table.FastRemoveGivenLength

local function BadIndex(_, Index, Value)
	Debug_Error("%q is not a valid member of " .. (Value or "RBXScriptSignal"), Index)
end

local Event = setmetatable({}, {__index = BadIndex})

function Event:Connect(Function, Argument)
	return EventInterfaces[self]:Connect(Function, Argument)
end

function Event:Wait()
	return EventInterfaces[self]:Wait()
end

local Signal = {
	__index = {
		NextId = 0;
		YieldingThreads = 0;
	};
}

local function GetArguments(self, Id)
	local Arguments = self.Arguments[Id]
	local ThreadsRemaining = Arguments.NumberOfConnectionsAndThreads - 1

	if ThreadsRemaining == 0 then
		self.Arguments[Id] = nil
	else
		Arguments.NumberOfConnectionsAndThreads = ThreadsRemaining
	end

	return table.unpack(Arguments, 1, Arguments.n)
end

local function Destruct(self)
	local ConstructorData = self.ConstructorData
	if self.Destructor and ConstructorData then
		self:Destructor(table.unpack(ConstructorData, 1, ConstructorData.n))
		self.ConstructorData = nil
	end
end

local function Disconnect(self)
	self = PseudoConnections[self]
	if self.Connection then
		self.Connection = self.Connection:Disconnect()
	end

	local CurrentSignal = self.Signal
	if CurrentSignal then
		self.Connected = false
		local Connections = CurrentSignal.Connections
		local NumberOfConnections = #Connections
		local Index = table.find(Connections, self)
		if Index then
			Table_FastRemoveGivenLength(Connections, Index, NumberOfConnections)
			if NumberOfConnections == 1 then
				Destruct(Signal)
			end
		end

		self.Signal = nil
	end
end

local function PseudoConnection__index(self, Index)
	if Index == "Disconnect" then
		return Disconnect
	elseif Index == "Connected" then
		return PseudoConnections[self].Connected
	else
		BadIndex(self, Index, "RBXScriptConnection")
	end
end

local function RBXScriptConnectionToString()
	return "RBXScriptConnection"
end

local function RBXScriptSignalToString()
	return "RBXScriptSignal"
end

function Signal.new(Constructor, Destructor)
	local self = setmetatable({
		BindableEvent = Instance.new("BindableEvent");
		Arguments = {};
		Connections = {};
		Constructor = Constructor;
		Destructor = Destructor;
		Event = newproxy(true);
	}, Signal)

	local EventMetatable = getmetatable(self.Event)
	EventMetatable.__index = Event
	EventMetatable.__metatable = "The metatable is locked"
	EventMetatable.__type = "RBXScriptSignal"
	EventMetatable.__tostring = RBXScriptSignalToString
	EventInterfaces[self.Event] = self
	Signals[self] = true

	return self
end

function Signal.IsA(Object)
	return Signals[Object] or false
end

function Signal.__index:Connect(Function, Argument)
	local NumberOfConnections = #self.Connections

	if NumberOfConnections == 0 and self.Constructor and not self.ConstructorData then
		self.ConstructorData = table.pack(self:Constructor())
	end

	local Connection = newproxy(true)
	local ConnectionMetatable = getmetatable(Connection)
	ConnectionMetatable.Connected = true
	ConnectionMetatable.__metatable = "The metatable is locked"
	ConnectionMetatable.__type = "RBXScriptConnection"
	ConnectionMetatable.__tostring = RBXScriptConnectionToString
	ConnectionMetatable.__index = PseudoConnection__index
	ConnectionMetatable.Signal = self
	ConnectionMetatable.Connection = self.BindableEvent.Event:Connect(function(Id)
		if Argument then
			Function(Argument, GetArguments(self, Id))
		else
			Function(GetArguments(self, Id))
		end
	end)

	PseudoConnections[Connection] = ConnectionMetatable
	self.Connections[NumberOfConnections + 1] = ConnectionMetatable
	return Connection
end

function Signal.__index:Fire(...)
	local Id = self.NextId
	local Stack = table.pack(...)
	local NumberOfConnectionsAndThreads = #self.Connections + self.YieldingThreads

	Stack.NumberOfConnectionsAndThreads = NumberOfConnectionsAndThreads

	self.NextId = Id + 1
	self.Arguments[Id] = Stack
	self.YieldingThreads = nil

	if NumberOfConnectionsAndThreads > 0 then
		self.BindableEvent:Fire(Id)
	end
end

function Signal.__index:Wait()
	self.YieldingThreads += 1
	return GetArguments(self, self.BindableEvent.Event:Wait())
end

function Signal.__index:Destroy()
	Destruct(self)

	self.BindableEvent = self.BindableEvent:Destroy()
	local Connections = self.Connections

	for Index = #Connections, 1, -1 do
		local Connection = Connections[Index]
		Connection.Connected = false
		Connection.Signal = nil
		Connection.Connection = nil
		Connections[Index] = nil
	end

	-- self.YieldingThreads = nil
	-- self.Arguments = nil
	-- self.Connections = nil
	table.clear(self)
	setmetatable(self, nil)
end

return Table.Lock(Signal, nil, script.Name)