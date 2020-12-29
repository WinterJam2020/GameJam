local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local FastSignal = Resources:LoadLibrary("FastSignal")
local Janitor = Resources:LoadLibrary("Janitor")

local ValueObject = {ClassName = "ValueObject"}
ValueObject.__index = ValueObject

function ValueObject.new(InitialValue)
	local self = rawset(setmetatable({
		Changed = nil;
		Janitor = Janitor.new();
		_Value = nil;
	}, ValueObject), "_Value", InitialValue)

	return rawset(self, "Changed", self.Janitor:Add(FastSignal.new(), "Destroy"))
end

function ValueObject:__index(Index)
	if Index == "Value" then
		return self._Value
	elseif ValueObject[Index] then
		return ValueObject[Index]
	elseif Index == "_Value" then
		return nil
	else
		error(string.format("%q is not a member of ValueObject", tostring(Index)))
	end
end

function ValueObject:__newindex(Index, Value)
	if Index == "Value" then
		local Previous = rawget(self, "_Value")
		if Previous ~= Value then
			rawset(self, "_Value", Value)
			self.Changed:Fire(Value, Previous, self.Janitor:Add(Janitor.new(), "Destroy", "ValueJanitor"))
		end
	else
		error(string.format("%q is not a member of ValueObject", tostring(Index)))
	end
end

function ValueObject:Destroy()
	self.Value = nil
	self.Janitor:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

return ValueObject