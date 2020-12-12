--[[
	Calls a function and throws an error if it attempts to yield.

	Pass any number of arguments to the function after the callback.

	This function supports multiple return; all results returned from the
	given function will be returned.
]]

local function ResultHandler(Thread, Success, ...)
	if not Success then
		local Message = (...)
		error(debug.traceback(Thread, Message), 2)
	end

	if coroutine.status(Thread) ~= "dead" then
		error(debug.traceback(Thread, "Attempted to yield inside changed event!"), 2)
	end

	return ...
end

local function NoYield(Function, ...)
	local Thread = coroutine.create(Function)
	return ResultHandler(Thread, coroutine.resume(Thread, ...))
end

return NoYield