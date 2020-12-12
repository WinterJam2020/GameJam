local Math = {}

function Math.Lerp(StartNumber: number, EndNumber: number, Alpha: number): number
	return StartNumber + (EndNumber - StartNumber)*Alpha
end

function Math.Map(Number: number, Minimum0: number, Maximum0: number, Minimum1: number, Maximum1: number): number
	return (((Number - Minimum0)*(Maximum1 - Minimum1))/(Maximum0 - Minimum0)) + Minimum1
end

function Math.WrapAround(Value: number, Minimum: number, Maximum: number): number
	local NewValue: number = Value + 1
	if NewValue > Maximum then
		NewValue = Minimum
	end

	return NewValue
end

function Math.InverseLerp(StartNumber: number, EndNumber: number, Alpha: number): number
	return (Alpha - StartNumber)/(EndNumber - StartNumber)
end

return Math