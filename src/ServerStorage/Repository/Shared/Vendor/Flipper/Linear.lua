local Linear = {ClassName = "Linear"}
Linear.__index = Linear

function Linear.new(TargetValue, TargetVelocity)
    assert(TargetValue, "Missing argument #1: TargetValue")
	return setmetatable({
        TargetValue = TargetValue;
        TargetVelocity = TargetVelocity or 1;
	}, Linear)
end

function Linear:Step(State, DeltaTime)
	local Position = State.Value
	local Velocity = self.TargetVelocity -- Linear motion ignores the state's velocity
	local Goal = self.TargetValue

	local DeltaPosition = DeltaTime * Velocity
	local Complete = DeltaPosition >= math.abs(Goal - Position)
	Position += DeltaPosition * (Goal > Position and 1 or -1)

	if Complete then
		Position = self.TargetValue
		Velocity = 0
	end

	return {
		complete = Complete;
		value = Position;
		velocity = Velocity;
	}
end

return Linear