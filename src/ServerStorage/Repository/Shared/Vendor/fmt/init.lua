local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Table = Resources:LoadLibrary("Table")

local Formatter = require(script.Formatter)

local function Format(Template, ...)
	return Formatter.new():Write(Template, ...):AsString()
end

local function Output(Template, ...)
	return Formatter.new():Write(Template, ...):AsTuple()
end

-- Wrap the given object in a type that implements the given function as its
-- Debug implementation, and forwards __tostring to the type's underlying
-- tostring implementation.
local function Debugify(Object, FmtFunction)
	return setmetatable({}, {
		__FmtDebug = function(_, ...)
			return FmtFunction(Object, ...)
		end;

		__tostring = function()
			return tostring(Object)
		end;
	})
end

return Table.Lock({
	Formatter = Formatter;
	Format = Format;
	Output = Output;
	Debugify = Debugify;
}, function(_, ...)
	return Format(...)
end, script.Name)