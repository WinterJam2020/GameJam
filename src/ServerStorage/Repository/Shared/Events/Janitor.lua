-- Janitor
-- pobammer
-- September 10, 2020

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Promise = Resources:LoadLibrary("Promise")
local Scheduler = Resources:LoadLibrary("Scheduler")

local LinkToInstanceIndex = newproxy(false)

local Janitors = setmetatable({}, {__mode = "k"})
local Janitor = {
	ClassName = "Janitor";
	__index = {CurrentlyCleaning = true};
}

local USE_INSTANCELESS_WAIT = true
local Wait = USE_INSTANCELESS_WAIT and Scheduler.Wait2 or Scheduler.Wait

local TypeDefaults = {
	["function"] = true;
	["RBXScriptConnection"] = "Disconnect";
}

function Janitor.new()
	return setmetatable({CurrentlyCleaning = false}, Janitor)
end

function Janitor.Is(Object)
	return type(Object) == "table" and getmetatable(Object) == Janitor
end

function Janitor.__index:Add(Object, MethodName, Index)
	if Index then
		self:Remove(Index)

		local This = Janitors[self]

		if not This then
			This = {}
			Janitors[self] = This
		end

		This[Index] = Object
	end

	self[Object] = MethodName or TypeDefaults[typeof(Object)] or "Destroy"
	return Object
end

function Janitor.__index:AddPromise(PromiseObject)
	if PromiseObject:GetStatus() == Promise.Status.Started then
		local Id = newproxy(false)
		return self:Add(Promise.Resolve(PromiseObject):FinallyCall(self.Remove, self, Id), "Cancel", Id)
	else
		return PromiseObject
	end
end

function Janitor.__index:Remove(Index)
	local This = Janitors[self]

	if This then
		local Object = This[Index]

		if Object then
			local MethodName = self[Object]

			if MethodName then
				if MethodName == true then
					Object()
				else
					Object[MethodName](Object)
				end

				self[Object] = nil
			end

			This[Index] = nil
		end
	end

	return self
end

function Janitor.__index:Get(Index)
	local This = Janitors[self]
	if This then
		return This[Index]
	end
end

function Janitor.__index:Cleanup()
	if not self.CurrentlyCleaning then
		self.CurrentlyCleaning = nil
		for Object, MethodName in next, self do
			if MethodName == true then
				Object()
			else
				Object[MethodName](Object)
			end

			self[Object] = nil
		end

		local This = Janitors[self]
		if This then
			for Index in next, This do
				This[Index] = nil
			end

			Janitors[self] = nil
		end

		self.CurrentlyCleaning = false
	end
end

function Janitor.__index:Destroy()
	self:Cleanup()
	table.clear(self)
	setmetatable(self, nil)
end

Janitor.__call = Janitor.__index.Cleanup

--- Makes the Janitor clean up when the instance is destroyed
-- @param Instance Instance The Instance the Janitor will wait for to be Destroyed
-- @returns Disconnectable table to stop Janitor from being cleaned up upon Instance Destroy (automatically cleaned up by Janitor, btw)
-- @author Corecii
local Disconnect = {Connected = true}
Disconnect.__index = Disconnect
function Disconnect:Disconnect()
	self.Connected = false
	self.Connection = self.Connection:Disconnect()
end

function Janitor.__index:LinkToInstance(Object, AllowMultiple)
	local Reference = Instance.new("ObjectValue")
	Reference.Value = Object

	local ManualDisconnect = setmetatable({}, Disconnect)
	local Connection
	local function ChangedFunction(Obj, Par)
		if not Reference.Value then
			ManualDisconnect.Connected = false
			return self:Cleanup()
		elseif Obj == Reference.Value and not Par then
			Obj = nil
			Wait(0.03)

			if (not Reference.Value or not Reference.Value.Parent) and ManualDisconnect.Connected then
				if not Connection.Connected then
					ManualDisconnect.Connected = false
					return self:Cleanup()
				else
					while 1 do
						Wait(0.2)
						if not ManualDisconnect.Connected then
							return
						elseif not Connection.Connected then
							ManualDisconnect.Connected = false
							return self:Cleanup()
						elseif Reference.Value.Parent then
							return
						end
					end
				end
			end
		end
	end

	Connection = Object.AncestryChanged:Connect(ChangedFunction)
	ManualDisconnect.Connection = Connection
	Object = nil
	Scheduler.FastSpawn(ChangedFunction, Reference.Value, Reference.Value.Parent)

	if AllowMultiple then
		self:Add(ManualDisconnect, "Disconnect")
	else
		self:Add(ManualDisconnect, "Disconnect", LinkToInstanceIndex)
	end

	return ManualDisconnect
end

function Janitor.__index:LinkToInstances(...)
	local ManualCleanup = Janitor.new()
	for Index = 1, select("#", ...) do
		ManualCleanup:Add(self:LinkToInstance(select(Index, ...), true), "Disconnect")
	end

	return ManualCleanup
end

return Janitor