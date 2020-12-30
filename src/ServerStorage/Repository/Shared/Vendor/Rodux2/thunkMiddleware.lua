--[[
	A middleware that allows for functions to be dispatched.
	Functions will receive a single argument, the store itself.
	This middleware consumes the function; middleware further down the chain
	will not receive it.
]]
local function thunkMiddleware(nextDispatch, store)
	return function(action)
		if type(action) == "function" then
			return action(store)
		else
			return nextDispatch(action)
		end
	end
end

return thunkMiddleware
