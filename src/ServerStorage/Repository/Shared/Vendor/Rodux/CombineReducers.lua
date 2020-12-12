--[[
	Create a composite reducer from a map of keys and sub-reducers.
]]
local function CombineReducers(Map)
	return function(State, Action)
		-- If state is nil, substitute it with a blank table.
		if State == nil then
			State = {}
		end

		local NewState = {}

		for Key, Reducer in next, Map do
			-- Each reducer gets its own state, not the entire state table
			NewState[Key] = Reducer(State[Key], Action)
		end

		return NewState
	end
end

return CombineReducers
