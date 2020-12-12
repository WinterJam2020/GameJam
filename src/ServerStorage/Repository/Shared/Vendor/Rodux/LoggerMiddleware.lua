local indent = "    "

local function PrettyPrint(Value, IndentLevel)
	IndentLevel = IndentLevel or 0
	local Output = {}
	local Length = 0

	if type(Value) == "table" then
		Length += 1
		Output[Length] = "{\n"

		for Key, Value2 in next, Value do
			Length += 1
			Output[Length] = string.rep(indent, IndentLevel + 1)

			Length += 1
			Output[Length] = tostring(Key)

			Length += 1
			Output[Length] = " = "

			Length += 1
			Output[Length] = PrettyPrint(Value2, IndentLevel + 1)

			Length += 1
			Output[Length] = "\n"
		end

		Length += 1
		Output[Length] = string.rep(indent, IndentLevel)

		Length += 1
		Output[Length] = "}"
	elseif type(Value) == "string" then
		Length += 1
		Output[Length] = string.format("%q", Value)

		Length += 1
		Output[Length] = " (string)"
	else
		Length += 1
		Output[Length] = tostring(Value)

		Length += 1
		Output[Length] = " ("

		Length += 1
		Output[Length] = typeof(Value)

		Length += 1
		Output[Length] = ")"
	end

	return table.concat(Output)
end

-- We want to be able to override OutputFunction in tests, so the shape of this
-- module is kind of unconventional.
--
-- We fix it this weird shape in init.lua.
local LoggerMiddleware = {
	OutputFunction = print,
}

function LoggerMiddleware.Middleware(NextDispatch, Store)
	return function(Action)
		local Result = NextDispatch(Action)
		LoggerMiddleware.OutputFunction(string.format(
			"Action dispatched: %s\nState changed to: %s",
			PrettyPrint(Action),
			PrettyPrint(Store:GetState())
		))

		return Result
	end
end

return LoggerMiddleware
