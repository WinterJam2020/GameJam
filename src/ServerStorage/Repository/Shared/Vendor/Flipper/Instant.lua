local Instant = {ClassName = "Instant"}
Instant.__index = Instant

function Instant.new(targetValue)
	return setmetatable({
		_targetValue = targetValue,
	}, Instant)
end

function Instant:Step()
	return {
		complete = true,
		value = self._targetValue,
	}
end

return Instant