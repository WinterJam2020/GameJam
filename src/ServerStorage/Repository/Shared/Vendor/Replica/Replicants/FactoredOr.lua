local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local FastSignal = Resources:LoadLibrary("FastSignal")
local Replicant = require(script.Parent.Parent.Replicant)

local FactoredOr, Members, Super = Replicant.Extend()
local Metatable = {__index = Members}

function Members:Pairs()
	return next, self.Wrapped, nil
end

function Members:_SetLocal(Key, Value)
	if type(Key) ~= "string" then
		error("FactoredOr Replicant keys must be strings")
	end

	self.Wrapped[Key] = Value
end

function Members:Set(Key, Value)
	if type(Value) ~= "boolean" then
		error("FactoredOr Replicant values must be boolean")
	end

	if Value == true then
		Super.Set(self, Key, true)
	else
		Super.Set(self, Key, nil)
	end
end

function Members:Reset()
	self:Collate(function()
		for Key in next, self.Wrapped do
			self:Set(Key, false)
		end
	end)
end

function Members:Toggle(Key)
	if self.Wrapped[Key] then
		self:Set(Key, false)
	else
		self:Set(Key, true)
	end
end

function Members:ResolveState()
	if next(self.Wrapped) ~= nil then
		return true
	else
		return false
	end
end

function Members:Destroy()
	Super.Destroy(self)
	self.StateChanged:Destroy()
	self.StateChanged = nil
end

FactoredOr.SerialType = "FactoredOrReplicant"
function FactoredOr.Constructor(self, InitialValues, ...)
	Replicant.Constructor(self, ...)

	if InitialValues ~= nil then
		for Key, Value in next, InitialValues do
			if type(Value) ~= "boolean" then
				error("FactoredOr Replicant values must be boolean")
			end

			self:_SetLocal(Key, Value)
		end
	end

	self.StateChanged = FastSignal.new()
	self._StateConnections = {}

	self.LastState = self:ResolveState()
	self.OnUpdate:Connect(function()
		local NewState = self:ResolveState()
		if NewState ~= self.LastState then
			self.LastState = NewState
			self.StateChanged:Fire(NewState)
		end
	end)
end

function FactoredOr.new(...)
	local self = setmetatable({}, Metatable)
	FactoredOr.Constructor(self, ...)
	return self
end

function FactoredOr.Extend()
	local SubclassStatics, SubclassMembers = setmetatable({}, {__index = FactoredOr}), setmetatable({}, {__index = Members})
	SubclassMembers._Class = SubclassStatics
	return SubclassStatics, SubclassMembers, Members
end

return FactoredOr