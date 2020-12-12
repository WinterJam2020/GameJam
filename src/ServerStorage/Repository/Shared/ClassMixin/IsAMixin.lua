--- Generic IsA interface for Lua classes.
-- @module IsAMixin

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Typer = Resources:LoadLibrary("Typer")

local IsAMixin = {}

--- Adds the IsA function to a class and all descendants
function IsAMixin:Add(class)
	assert(not class.IsA, "class already has an IsA method")
	assert(not class.CustomIsA, "class already has an CustomIsA method")
	assert(class.ClassName, "class needs a ClassName")

	class.IsA = self.IsA
	class.CustomIsA = self.IsA
end

--- Using the .ClassName property, returns whether or not a component is
--  a class
function IsAMixin:IsA(ClassName)

	assert(type(ClassName) == "string", "className must be a string")

	local currentMetatable = getmetatable(self)
	while currentMetatable do
		if currentMetatable.ClassName == ClassName then
			return true
		end

		currentMetatable = getmetatable(currentMetatable)
	end

	return false
end

return IsAMixin