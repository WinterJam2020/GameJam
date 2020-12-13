--- Generic IsA interface for Lua classes.
-- @module IsAMixin

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Typer = Resources:LoadLibrary("Typer")

local IsAMixin = {}

--- Adds the IsA function to a class and all descendants
function IsAMixin:Add(Class)
	assert(not Class.IsA, "class already has an IsA method")
	assert(not Class.CustomIsA, "class already has an CustomIsA method")
	assert(Class.ClassName, "class needs a ClassName")

	Class.IsA = self.IsA
	Class.CustomIsA = self.IsA
end

--- Using the .ClassName property, returns whether or not a component is
--  a class
IsAMixin.IsA = Typer.AssignSignature(2, Typer.String, function(self, ClassName: string)
	local CurrentMetatable = getmetatable(self)
	while CurrentMetatable do
		if CurrentMetatable.ClassName == ClassName then
			return true
		end

		CurrentMetatable = getmetatable(CurrentMetatable)
	end

	return false
end)

return IsAMixin