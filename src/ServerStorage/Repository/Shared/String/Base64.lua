local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Table = Resources:LoadLibrary("Table")

local Alphabet = {}
local Indexes = {}

-- A-Z
for Index = 65, 90 do
	table.insert(Alphabet, Index)
end

-- a-z
for Index = 97, 122 do
	table.insert(Alphabet, Index)
end

-- 0-9
for Index = 48, 57 do
	table.insert(Alphabet, Index)
end

table.insert(Alphabet, 43) -- +
table.insert(Alphabet, 47) -- /

for Index, Character in ipairs(Alphabet) do
	Indexes[Character] = Index
end

local Base64 = {}

local bit32_rshift = bit32.rshift
local bit32_lshift = bit32.lshift
local bit32_band = bit32.band

--[[**
	Encodes a string in Base64.
	@param [string] Input The input string to encode.
	@returns [string] The string encoded in Base64.
**--]]
function Base64.Encode(Input: string): string
	local Output = {}
	local Length = 0

	for Index = 1, #Input, 3 do
		local C1, C2, C3 = string.byte(Input, Index, Index + 2)

		local A = bit32_rshift(C1, 2)
		local B = bit32_lshift(bit32_band(C1, 3), 4) + bit32_rshift(C2 or 0, 4)
		local C = bit32_lshift(bit32_band(C2 or 0, 15), 2) + bit32_rshift(C3 or 0, 6)
		local D = bit32_band(C3 or 0, 63)

		Output[Length + 1] = Alphabet[A + 1]
		Output[Length + 2] = Alphabet[B + 1]
		Output[Length + 3] = C2 and Alphabet[C + 1] or 61
		Output[Length + 4] = C3 and Alphabet[D + 1] or 61
		Length += 4
	end

	local NewOutput = {}
	local NewLength = 0

	for Index = 1, Length, 4096 do
		NewLength += 1
		NewOutput[NewLength] = string.char(table.unpack(Output, Index, math.min(Index + 4096 - 1, Length)))
	end

	return table.concat(NewOutput)
end

--[[**
	Decodes a string from Base64.
	@param [string] Input The input string to decode.
	@returns [string] The newly decoded string.
**--]]
function Base64.Decode(Input: string): string
	local Output = {}
	local Length = 0

	for Index = 1, #Input, 4 do
		local C1, C2, C3, C4 = string.byte(Input, Index, Index + 3)

		local I1 = Indexes[C1] - 1
		local I2 = Indexes[C2] - 1
		local I3 = (Indexes[C3] or 1) - 1
		local I4 = (Indexes[C4] or 1) - 1

		local A = bit32_lshift(I1, 2) + bit32_rshift(I2, 4)
		local B = bit32_lshift(bit32_band(I2, 15), 4) + bit32_rshift(I3, 2)
		local C = bit32_lshift(bit32_band(I3, 3), 6) + I4

		Length += 1
		Output[Length] = A
		if C3 ~= 61 then
			Length += 1
			Output[Length] = B
		end

		if C4 ~= 61 then
			Length += 1
			Output[Length] = C
		end
	end

	local NewOutput = {}
	local NewLength = 0

	for Index = 1, Length, 4096 do
		NewLength += 1
		NewOutput[NewLength] = string.char(table.unpack(Output, Index, math.min(Index + 4096 - 1, Length)))
	end

	return table.concat(NewOutput)
end

return Table.Lock(Base64, nil, script.Name)