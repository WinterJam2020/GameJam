local Instant = {ClassName = "Instant"}
Instant.__index = Instant

function Instant.new(TargetValue)
	return setmetatable({TargetValue = TargetValue}, Instant)
end

function Instant:Step()
	return {
		complete = true;
		value = self.TargetValue;
	}
end

return Instant