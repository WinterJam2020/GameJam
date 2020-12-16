local Math = {}
local RandomLib: Random = Random.new(tick() % 1 * 1E7)

function Math.Lerp(StartNumber: number, EndNumber: number, Alpha: number): number
	return StartNumber + (EndNumber - StartNumber) * Alpha
end

function Math.Map(Number: number, Minimum0: number, Maximum0: number, Minimum1: number, Maximum1: number): number
	return (((Number - Minimum0) * (Maximum1 - Minimum1)) / (Maximum0 - Minimum0)) + Minimum1
end

function Math.WrapAround(Value: number, Minimum: number, Maximum: number): number
	local NewValue: number = Value + 1
	if NewValue > Maximum then
		NewValue = Minimum
	end

	return NewValue
end

function Math.InverseLerp(StartNumber: number, EndNumber: number, Alpha: number): number
	return (Alpha - StartNumber) / (EndNumber - StartNumber)
end

function Math.Normal(Average: number?, StandardDeviation: number?): number
	return (Average or 0) * math.sqrt(-2 * math.log(RandomLib:NextNumber())) * math.cos(6.2831853071796 * RandomLib:NextNumber()) * 0.5 * (StandardDeviation or 1)
end

return Math