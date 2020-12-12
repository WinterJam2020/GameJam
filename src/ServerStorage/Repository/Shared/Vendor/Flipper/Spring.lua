local VELOCITY_THRESHOLD = 0.001
local POSITION_THRESHOLD = 0.001

local EPS = 0.0001

local Spring = {ClassName = "Spring"}
Spring.__index = Spring

function Spring.new(TargetValue, Options)
	assert(TargetValue, "Missing argument #1: TargetValue")
	Options = Options or {}

	return setmetatable({
		TargetValue = TargetValue;
		Frequency = Options.Frequency or 4;
		DampingRatio = Options.DampingRatio or 1;
	}, Spring)
end

function Spring:step(state, DeltaTime)
	-- Copyright 2018 Parker Stebbins (parker@fractality.io)
	-- github.com/Fraktality/Spring
	-- Distributed under the MIT license

	local DampingRatio = self.DampingRatio
	local Frequency = self.Frequency * 6.2831853071796
	local Goal = self.TargetValue
	local Position0 = state.value
	local Velocity0 = state.velocity or 0

	local Offset = Position0 - Goal
	local Decay = math.exp(-DampingRatio * Frequency * DeltaTime)

	local Position1, Velocity1

	if DampingRatio == 1 then -- Critically damped
		Position1 = (Offset * (1 + Frequency * DeltaTime) + Velocity0 * DeltaTime) * Decay + Goal
		Velocity1 = (Velocity0 * (1 - Frequency * DeltaTime) - Offset * (Frequency * Frequency * DeltaTime)) * Decay
	elseif DampingRatio < 1 then -- Underdamped
		local C = math.sqrt(1 - DampingRatio * DampingRatio)

		local I = math.cos(Frequency * C * DeltaTime)
		local J = math.sin(Frequency * C * DeltaTime)

		local Z
		if C > EPS then
			Z = J / C
		else
			local A = DeltaTime * Frequency
			Z = A + ((A * A) * (C * C) * (C * C) / 20 - C * C) * (A * A * A) / 6
		end

		local Y
		if Frequency * C > EPS then
			Y = J / Frequency * C
		else
			local B = Frequency * C
			Y = DeltaTime + ((DeltaTime * DeltaTime) * (B * B) * (B * B) / 20 - B * B) * (DeltaTime * DeltaTime * DeltaTime) / 6
		end

		Position1 = (Offset * (I + DampingRatio * Z) + Velocity0 * Y) * Decay + Goal
		Velocity1 = (Velocity0 * (I - Z * DampingRatio) - Offset* Z * Frequency) * Decay
	else -- Overdamped
		local C = math.sqrt(DampingRatio * DampingRatio - 1)

		local R1 = -Frequency * (DampingRatio - C)
		local R2 = -Frequency * (DampingRatio + C)

		local CO2 = (Velocity0 - Offset * R1) / (2 * Frequency * C)
		local CO1 = Offset - CO2

		local E1 = CO1 * math.exp(R1 * DeltaTime)
		local E2 = CO2 * math.exp(R2 * DeltaTime)

		Position1 = E1 + E2 + Goal
		Velocity1 = E1 * R1 + E2 * R2
	end

	local Complete = Velocity1 < VELOCITY_THRESHOLD and math.abs(Offset) < POSITION_THRESHOLD

	return {
		complete = Complete;
		value = Complete and Goal or Position1;
		velocity = Velocity1;
	}
end

return Spring