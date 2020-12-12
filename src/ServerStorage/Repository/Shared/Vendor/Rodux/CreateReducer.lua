return function(InitialState, Handlers)
	return function(State, Action)
		if State == nil then
			State = InitialState
		end

		local Handler = Handlers[Action.Type]

		if Handler then
			return Handler(State, Action)
		end

		return State
	end
end
