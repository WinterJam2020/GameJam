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

return {
	Formatter = Formatter;
	Format = Format;
	Output = Output;
	Debugify = Debugify;
}