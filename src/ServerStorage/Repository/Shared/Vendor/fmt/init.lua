local Formatter = require(script.Formatter)

local function Format(template, ...)
    local formatter = Formatter.new()

    formatter:write(template, ...)

    return formatter:asString()
end

local function Output(template, ...)
    local Formatter = Formatter.new()
    Formatter:write(template, ...)
    return Formatter:asTuple()
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