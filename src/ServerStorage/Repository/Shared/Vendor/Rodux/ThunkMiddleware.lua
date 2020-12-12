--[[
	A middleware that allows for functions to be dispatched.
	Functions will receive a single argument, the store itself.
	This middleware consumes the function; middleware further down the chain
	will not receive it.
]]
local function ThunkMiddleware(NextDispatch, Store)
	return function(Action)
		if type(Action) == "function" then
			return Action(Store)
		else
			return NextDispatch(Action)
		end
	end
end

return ThunkMiddleware
