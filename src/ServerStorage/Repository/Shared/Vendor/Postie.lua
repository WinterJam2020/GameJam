local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local Promise = Resources:LoadLibrary("Promise")
local Scheduler = Resources:LoadLibrary("Scheduler")
local Table = Resources:LoadLibrary("Table")
local t = Resources:LoadLibrary("t")

local Received = Resources:GetRemoteEvent("Received")
local Sent = Resources:GetRemoteEvent("Sent")

local IS_SERVER = RunService:IsServer()
local FunctionById = {}
local Listeners = {}

local Postie = {}

local Scheduler_Delay = Scheduler.Delay
local Table_FastRemove = Table.FastRemove

local InvokeClientTuple = t.tuple(t.instanceIsA("Player"), t.string, t.number)
local InvokeServerTuple = t.tuple(t.string, t.number)
local SetFunctionTuple = t.tuple(t.string, t.optional(t.callback))

--[[**
	Invoke `Player` with sent data. Invocation identified by `Id`. Yield until `Timeout` (given in seconds) is reached and return `false`, or a signal is received back from the client and return `true` plus the data returned from the client.
	@param Player Player The Player you are invoking.
	@param string Id The Id of the function you are calling.
	@param number Timeout How long until the function automatically times-out.
	@param ...Arguments ... The varargs to call the function with.
	@returns (boolean, ...Arguments) The success status of the call as well as whatever the function called returns with.
**--]]
function Postie.InvokeClient(Player: Player, Id: string, Timeout: number, ...)
	local TypeSuccess, TypeError = InvokeClientTuple(Player, Id, Timeout)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	if not IS_SERVER then
		error("Postie.InvokeClient can only be called from the server", 2)
	end

	local BindableEvent = Instance.new("BindableEvent")
	local IsResumed = false
	local Position = #Listeners + 1
	local Uuid = HttpService:GenerateGUID(false)

	Listeners[Position] = function(PlayerWhoFired, SignalUuid, ...)
		if PlayerWhoFired ~= Player or SignalUuid ~= Uuid then
			return false
		else
			IsResumed = true
			Table_FastRemove(Listeners, Position)
			BindableEvent:Fire(true, ...)
			return true
		end
	end

	Scheduler_Delay(Timeout, function()
		if not IsResumed then
			Table_FastRemove(Listeners, Position)
			BindableEvent:Fire(false)
		end
	end)

	Sent:FireClient(Player, Id, Uuid, ...)
	return BindableEvent.Event:Wait()
end

function Postie.PromiseInvokeClient(Player: Player, Id: string, Timeout: number, ...)
	local TypeSuccess, TypeError = InvokeClientTuple(Player, Id, Timeout)
	if not TypeSuccess then
		return Promise.Reject(TypeError, 2)
	end

	if not IS_SERVER then
		return Promise.Reject("Postie.InvokeClient can only be called from the server", 2)
	end

	local Arguments = table.pack(...)
	return Promise.Defer(function(Resolve, _, OnCancel)
		local BindableEvent = Instance.new("BindableEvent")
		local IsResumed = false
		local Position = #Listeners + 1
		local Uuid = HttpService:GenerateGUID(false)

		Listeners[Position] = function(PlayerWhoFired, SignalUuid, ...)
			if PlayerWhoFired ~= Player or SignalUuid ~= Uuid then
				return false
			else
				IsResumed = true
				Table_FastRemove(Listeners, Position)
				BindableEvent:Fire(...)
				return true
			end
		end

		OnCancel(function()
			if not IsResumed then
				Table_FastRemove(Listeners, Position)
				BindableEvent:Fire(false)
			end
		end)

		Sent:FireClient(Player, Id, Uuid, table.unpack(Arguments, 1, Arguments.n))
		return Resolve(BindableEvent.Event:Wait())
	end):Timeout(Timeout)
end

--[[**
	Invoke the server with sent data. Invocation identified by `Id`. Yield until `Timeout` (given in seconds) is reached and return `false`, or a signal is received back from the server and return `true` plus the data returned from the server.
	@param string Id The Id of the function you are calling.
	@param number Timeout How long until the function automatically times-out.
	@param ...Arguments ... The varargs to call the function with.
	@returns (boolean, ...Arguments) The success status of the call as well as whatever the function called returns with.
**--]]
function Postie.InvokeServer(Id: string, Timeout: number, ...)
	local TypeSuccess, TypeError = InvokeServerTuple(Id, Timeout)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	if IS_SERVER then
		error("Postie.InvokeServer can only be called from the client", 2)
	end

	local BindableEvent = Instance.new("BindableEvent")
	local IsResumed = false
	local Position = #Listeners + 1
	local Uuid = HttpService:GenerateGUID(false)

	Listeners[Position] = function(SignalUuid, ...)
		if SignalUuid ~= Uuid then
			return false
		else
			IsResumed = true
			Table_FastRemove(Listeners, Position)
			BindableEvent:Fire(true, ...)
			return true
		end
	end

	Scheduler_Delay(Timeout, function()
		if not IsResumed then
			Table_FastRemove(Listeners, Position)
			BindableEvent:Fire(false)
		end
	end)

	Sent:FireServer(Id, Uuid, ...)
	return BindableEvent.Event:Wait()
end

--[[**
	Set the function that is invoked when an invocation identified by `Id` is received. Data sent with the invocation are passed to the function. If server-side, the player who invoked is implicitly received as the first argument.
	@param string Id The name / id of the function.
	@param function? Function The function to set. Can be `nil` to remove it.
	@returns nil
**--]]
function Postie.SetFunction(Id: string, Function): nil
	local TypeSuccess, TypeError = SetFunctionTuple(Id, Function)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	FunctionById[Id] = Function
end

--[[**
	Return the function corresponding with `Id`.
	@param string Id The name / id of the function.
	@returns function?
**--]]
function Postie.GetFunction(Id: string)
	local TypeSuccess, TypeError = t.string(Id)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	return FunctionById[Id]
end

if IS_SERVER then
	Received.OnServerEvent:Connect(function(...)
		for _, Function in ipairs(Listeners) do
			if Function(...) then
				break
			end
		end
	end)

	Sent.OnServerEvent:Connect(function(Player, Id, Uuid, ...)
		local Function = FunctionById[Id]
		if Function == nil then
			Received:FireClient(Player, Uuid)
		else
			Received:FireClient(Player, Uuid, Function(Player, ...))
		end
	end)
else
	Received.OnClientEvent:Connect(function(...)
		for _, Function in ipairs(Listeners) do
			if Function(...) then
				break
			end
		end
	end)

	Sent.OnClientEvent:Connect(function(Id, Uuid, ...)
		local Function = FunctionById[Id]
		if Function == nil then
			Received:FireServer(Uuid)
		else
			Received:FireServer(Uuid, Function(...))
		end
	end)
end

return Postie

--[[
function Postie.InvokeClient(Player, Id, Timeout, ...)
	local TypeSuccess, TypeError = InvokeClientTuple(Player, Id, Timeout)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	if not IS_SERVER then
		error("Postie.InvokeClient can only be called from the server", 2)
	end

	local BindableEvent = Instance.new("BindableEvent")
	local IsResumed = false
	local Position = #Listeners + 1
	local Uuid = HttpService:GenerateGUID(false)

	Listeners[Position] = function(PlayerWhoFired, SignalUuid, ...)
		if PlayerWhoFired ~= Player or SignalUuid ~= Uuid then
			return false
		else
			IsResumed = true
			Table.FastRemove(Listeners, Position)
			BindableEvent:Fire(true, Ser.DeserializeArgsAndUnpack(...))
			return true
		end
	end

	Scheduler.Delay(Timeout, function()
		if not IsResumed then
			Table.FastRemove(Listeners, Position)
			BindableEvent:Fire(false)
		end
	end)

	Sent:FireClient(Player, Id, Uuid, Ser.SerializeArgsAndUnpack(...))
	return BindableEvent.Event:Wait()
end
]]