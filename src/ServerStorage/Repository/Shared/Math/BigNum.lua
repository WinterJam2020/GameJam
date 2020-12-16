-- BigNum Library
-- @author Validark

-- This library implements two's complement signed integers in base 16777216 (2^24)

-- In binary, numbers have place values like so:
-- | -2^4 | 2^3 | 2^2 | 2^1 | 2^0 |
-- | -16's| 8's | 4's | 2's | 1's |

-- In base 16777216, the place values look like this (the leftmost radix is a bit more complicated)
-- | 16777216^4        | 16777216^3      | 16777216^2   | 16777216^1 | 16777216^0 |

-- Hence, each base 16777216 value holds what would be 24 base 2 values, or 3 bytes
-- This means we could hypothetically implement a 64 bit signed integer using 2 2/3 radix

-- These BigNums are initialized with a pre-allocated amount of radix
-- This is because signed integers work in a particular way
-- In order to achieve efficient, signed integers, we basically flip the number line below the negative so
-- we can intentionally overflow one way or the other when adding and subtracting across the 0 boundary

-- Caveats:
-- The most negative number possible can not be used in a division expression
-- 		This is an extreme edge case but it could be encountered if someone turns the DEFAULT_RADIX to 1

local DEFAULT_RADIX = 32 -- Number of places/digits/radix
local PLATFORM = "Roblox"

-- We use 2^24 for two reasons:
--	1) It can be represented by 4 radix in base 2^6
--	2) It is large enough to take advantage of the underlying double construct but small
-- 		enough that the internal operands will not be larger than the largest (consecutive) integer a double can represent: 2^53
-- 		This is the largest internal operand value (before modulo): (DEFAULT_BASE - 1)^2 + DEFAULT_BASE - 1
local DEFAULT_BASE = 2^24 -- Don't change this

local BigNum = {
	ClassName = "BigNum";
	__index = {};
}

local WRITE_FILE_FOR_PLATFORM = {
	Roblox = function(Source)
		Instance.new("Script", game:GetService("Lighting")).Source = Source
	end;
}

local CONSTANTS_VALUE = {
	__index = function(self, Index)
		local Value = {}
		local Jndex = self.n

		for A = 1, Jndex - 1 do
			Value[A] = 0
		end

		Value[Jndex] = Index

		while Value[Jndex] >= self.Base do
			local ValueJndex = Value[Jndex]
			local X = ValueJndex % self.Base
			Value[Jndex] = X
			Jndex -= 1
			Value[Jndex] = (ValueJndex - X) / self.Base
		end

		self[Index] = Value
		return setmetatable(Value, BigNum)
	end;
}

local CONSTANTS_LENGTH = {
	__index = function(self, Index)
		local Value = setmetatable({n = Index, Base = self.Base}, CONSTANTS_VALUE)
		self[Index] = Value
		return Value
	end;
}

local CONSTANTS = setmetatable({}, { -- Usage: CONSTANTS[BASE][LENGTH][VALUE]
	__index = function(self, Index)
		local Value = setmetatable({Base = Index}, CONSTANTS_LENGTH)
		self[Index] = Value
		return Value
	end;
})

local function __unm(self, Base)
	-- Find the 2's complement
	local Characters = {}
	local Length = #self
	for Index = 1, Length - 1 do
		Characters[Index] = Base - self[Index] - 1
	end

	local LastValue = Base - self[Length]
	while LastValue == Base do
		Characters[Length] = 0
		Length -= 1
		if Length == 0 then
			break
		end

		LastValue = Characters[Length] + 1
	end

	if Length > 0 then
		Characters[Length] = LastValue
	end

	return setmetatable(Characters, BigNum)
end

local function IsNegative(self, Base)
	return self[1] >= Base / 2
end

local function abs(self, Base)
	local B = IsNegative(self, Base)
	return B and __unm(self, Base) or self, B
end

local function __add(A, B, Base)
	local Carry = 0
	local Characters = {}

	for Index = #A, 1, -1 do
		local V = A[Index] + B[Index] + Carry

		if V >= Base then
			local K = V % Base
			Carry = (V - K) / Base
			V = K
		else
			Carry = 0
		end

		Characters[Index] = V
	end

	return setmetatable(Characters, BigNum)
end

local function __sub(a, b, Base)
	return __add(a, __unm(b, Base), Base)
end

local function __eq(A, B)
	for Index = 1, #A do
		if A[Index] ~= B[Index] then
			return false
		end
	end

	return true
end

local function __lt(A, B, Base)
	local FirstA = A[1]
	local FirstB = B[1]

	if FirstA ~= FirstB then
		if FirstA >= Base / 2 then
			if FirstB >= Base / 2 then
				return FirstA < FirstB
			else
				return true
			end
		elseif FirstB >= Base / 2 then
			return false
		end

		return FirstA < FirstB
	end

	for Index = 2, #A do
		local ValueA = A[Index]
		local ValueB = B[Index]

		if ValueA ~= ValueB then
			return ValueA < ValueB
		end
	end

	return false -- equal
end

local function __mul(A, B, Base)
	local Length = #A
	local Characters = {}

	for Index = Length, 1, -1 do
		local ValueB = B[Index]

		if ValueB == 0 then
			if not Characters[Index] then
				Characters[Index] = 0
			end
		else
			for Jndex = Length, 1, -1 do
				local ValueA = A[Jndex]
				local K = Index + Jndex - Length

				if K > 0 then -- TODO: Change for loops to accomodate automatically
					local X = ValueB * ValueA + (Characters[K] or 0)
					local Y = X % Base
					local Z = (X - Y) / Base

					Characters[K] = Y

					while Z > 0 and K > 1 do
						K -= 1
						X = (Characters[K] or 0) + Z
						Y = X % Base
						Z = (X - Y) / Base

						Characters[K] = Y
					end
				end
			end
		end
	end

	return setmetatable(Characters, BigNum)
end

local function __div(N, D, Base)
	-- https://youtu.be/6bpLYxk9TUQ
	local Length = #N -- n-digit numbers
	local N_IsNegative, D_IsNegative

	N, N_IsNegative = abs(N, Base)
	D, D_IsNegative = abs(D, Base)

	local Q_IsNegative
	if N_IsNegative then
		Q_IsNegative = not D_IsNegative
	elseif D_IsNegative then
		Q_IsNegative = true
	else
		Q_IsNegative = false
	end

	if __lt(N, D, Base) then
		return CONSTANTS[Base][Length][0], N
	end

	local NumDigits
	local SingleDigit

	for Index = 1, Length do
		if D[Index] ~= 0 then
			NumDigits = Index
			SingleDigit = D[Index]
			break
		end
	end

	if not NumDigits then
		error("Cannot divide by 0")
	end

	local Q
	local R = N
	repeat
		local R_Is_Negative = IsNegative(R, Base)
		if R_Is_Negative then
			R = __unm(R, Base)
		end

		local Sub_Q = setmetatable({}, BigNum)
		local Remainder = 0

		for Index = 1, NumDigits do
			local X = Base * Remainder + R[Index]
			Remainder = X % SingleDigit
			Sub_Q[Length - NumDigits + Index] = (X - Remainder) / SingleDigit
		end

		for Index = 1, Length - NumDigits do
			Sub_Q[Index] = 0
		end

		if R_Is_Negative then
			Sub_Q = __unm(Sub_Q, Base)
		end

		Q = Q and __add(Q, Sub_Q, Base) or Sub_Q
		R = __sub(N, __mul(D, Q, Base), Base)
	until __lt((abs(R, Base)), D, Base)

	if IsNegative(R, Base) then
		Q = __sub(Q, CONSTANTS[Base][Length][1], Base)
		R = __sub(N, __mul(D, Q, Base), Base)
	end

	if Q_IsNegative then
		Q = __unm(Q, Base)
	end

	return Q, R
end

local function __pow(A, B, Base)
	local N = #A
    if __eq(B, CONSTANTS[Base][N][0]) then
		return CONSTANTS[Base][N][1]
	end

    local X = __pow(A, __div(B, CONSTANTS[Base][N][2], Base), Base)
    if B[N] % 2 == 0 then
        return __mul(X, X, Base)
    else
        return __mul(A, __mul(X, X, Base), Base)
	end
end

local function __mod(A, B, Base)
	local _, X = __div(A, B, Base)
	return X
end

local function __tostring(self, Base)
	local Length = #self
	local Negative = IsNegative(self, Base)

	-- Not all bases with a given number of places can represent the number 10
	-- Therefore, for small numbers we can simply convert to a Lua number
	-- However, for larger numbers we need to use the math functions in this library

	-- The following conditional is derived from: 10 < Base^(n - 1) - 1

	if math.log(11, Base) + 1 < Length then
		local Characters = {}
		local Ten = CONSTANTS[Base][Length][10]
		local Zero = CONSTANTS[Base][Length][0]

		local Index = 0

		repeat
			local X
			self, X = __div(self, Ten, Base)
			Index += 1
			Characters[Index] = X[Length]
		until __eq(self, Zero)

		if Negative and not __eq(Characters, CONSTANTS[Base][Index][0]) then
			Characters[Index + 1] = "-"
		end

		return string.reverse(table.concat(Characters))
	else
		local PlaceValue = 1
		local Sum = 0

		for Index = Length, 2, -1 do
			Sum += self[Index] * PlaceValue
			PlaceValue *= Base
		end

		return tostring(Sum + (self[1] - (Negative and Base or 0)) * PlaceValue)
	end
end

local function EnsureCompatibility(Func, Unary)
	local typeof = typeof or type

	if Unary then
		return function(A, ...)
			local TypeA = type(A)

			if TypeA == "number" then
				A = BigNum.new(tostring(A))
			elseif TypeA == "string" then
				A = BigNum.new(A)
			elseif TypeA ~= "table" or getmetatable(A) ~= BigNum then
				error("bad argument to #1: expected BigNum, got " .. typeof(A))
			end

			return Func(A, DEFAULT_BASE, ...)
		end
	else
		return function(A, B)
			local TypeA = type(A)

			if TypeA == "number" then
				A = BigNum.new(tostring(A))
			elseif TypeA == "string" then
				A = BigNum.new(A)
			elseif TypeA ~= "table" or getmetatable(A) ~= BigNum then
				error("bad argument to #1: expected BigNum, got " .. typeof(A))
			end

			local TypeB = type(B)

			if TypeB == "number" then
				B = BigNum.new(tostring(B))
			elseif TypeB == "string" then
				B = BigNum.new(B)
			elseif TypeB ~= "table" or getmetatable(B) ~= BigNum then
				error("bad argument to #2: expected BigNum, got " .. typeof(B))
			end

			if #A ~= #B then
				error("You cannot operate on BigNums with different radix: " .. #A .. " and " .. #B)
			end

			return Func(A, B, DEFAULT_BASE)
		end
	end
end

local function GCD(M, N, Base)
	local Zero = CONSTANTS[Base][#M][0]
	while not __eq(N, Zero) do
		M, N = N, __mod(M, N, Base)
	end

    return M
end

local function LCM(M, N, Base)
	local Zero = CONSTANTS[Base][#M][0]
    return M ~= Zero and N ~= Zero and __mul(M, N, Base) / GCD(M, N, Base) or Zero
end

local Char_0 = string.byte("0")

local function ToScientificNotation(self, Base, DigitsAfterDecimal)
	DigitsAfterDecimal = DigitsAfterDecimal or 2
	local MaxString = __tostring(self, Base)

	if #MaxString - 2 < DigitsAfterDecimal then
		return MaxString
	else
		local Arguments = table.create(DigitsAfterDecimal + 2)
		for Index = 1, DigitsAfterDecimal do
			Arguments[Index] = string.byte(MaxString, Index) - Char_0
		end

		Arguments[DigitsAfterDecimal + 1] = string.byte(MaxString, DigitsAfterDecimal + 1) - Char_0 + ((string.byte(MaxString, DigitsAfterDecimal + 2) - Char_0) > 4 and 1 or 0)
		Arguments[DigitsAfterDecimal + 2] = #MaxString - 1

		return string.format("%d." .. string.rep("%d", DigitsAfterDecimal) .. "e%d", table.unpack(Arguments))
	end
end

-- Unary operators
BigNum.__tostring = EnsureCompatibility(__tostring, true)
BigNum.__unm = EnsureCompatibility(__unm, true)
BigNum.__index.ToScientificNotation = EnsureCompatibility(ToScientificNotation, true)

-- Binary operators
BigNum.__add = EnsureCompatibility(__add)
BigNum.__sub = EnsureCompatibility(__sub)
BigNum.__mul = EnsureCompatibility(__mul)
BigNum.__div = EnsureCompatibility(__div)
BigNum.__pow = EnsureCompatibility(__pow)
BigNum.__mod = EnsureCompatibility(__mod)

BigNum.__lt = EnsureCompatibility(__lt)
BigNum.__eq = EnsureCompatibility(__eq)

-- Other operations
BigNum.__index.GCD = EnsureCompatibility(GCD)
BigNum.__index.LCM = EnsureCompatibility(LCM)

type Map<Index, Value> = {[Index]: Value}

local function ProcessAsDecimal(Bytes, Negative, Value, Power, FromBase, ToBase)
	-- @param boolean Negative Whether the number is negative
	-- @param string Value a number in the form "%d*%.?%d*"
	-- @param number Power The power of 10 by which Value should be multiplied

	if Power then -- Truncates anything that falls after a decimal point, moved by X in AeX
		Power = tonumber(Power)
		local PointLocation = string.find(Value, ".", 1, true) - 1
		local K = PointLocation + Power

		Value = string.sub(string.sub(Value, 1, PointLocation) .. string.sub(Value, PointLocation + 2), 1, K > 0 and K or 0)

		if Value == "" then
			Value = "0"
		end

		return __mul(ProcessAsDecimal(Bytes, Negative, Value, nil, FromBase, ToBase), __pow(CONSTANTS[ToBase][Bytes][10], CONSTANTS[ToBase][Bytes][K - #Value], ToBase), ToBase)
	end

	local self = {string.byte(string.rep("0", Bytes - #Value) .. Value, 1, -1)}
	local Length = #self

	local Zero = CONSTANTS[FromBase][Length][0]
	local Divisor = CONSTANTS[FromBase][Length][ToBase]

	for Index = 1, Length do
		self[Index] = self[Index] - Char_0
	end

	local Characters = {}
	local Index = Bytes

	repeat
		local X
		self, X = __div(self, Divisor, FromBase)
		Characters[Index] = tonumber(table.concat(X))
		Index -= 1
	until __eq(self, Zero)

	for Jndex = 1, Index do
		Characters[Jndex] = 0
	end

	return setmetatable(Negative and __unm(Characters, ToBase) or Characters, BigNum)
end

function BigNum.new(Number, Bytes)
	-- Parses a number, and determines whether it is a valid number
	-- If valid, it will call ProcessAsHexidecimal or ProcessAsDecimal depending
	-- on the number's format

	-- @param string Number The number to convert into base_256
	-- @return what the called Process function returns (array representing base256)

	local Type = type(Number)

	if Type == "number" then
		Number = tostring(Number)
		Type = "string"
	end

	if Type == "string" then
		local Number2 = tostring(Number)
		local Length = #Number

		if Length > 0 then
			local _, Hexadecimal = string.match(Number2, "^(%-?)0[Xx](%x*%.?%x*)$")

			if Hexadecimal and Hexadecimal ~= "" and Hexadecimal ~= "." then
				return error("Hexadecimal is currently unsupported") -- ProcessAsDecimal(Bytes or DEFAULT_RADIX, Negative == "-", Hexidecimal, false, 16, 256)
			else
				local _, DecimalEndPlace, Minus, Decimal, Point = string.find(Number2, "^(%-?)(%d*(%.?)%d*)")

				if Decimal ~= "" and Decimal ~= "." then
					local Power = string.match(Number2, "^[Ee]([%+%-]?%d+)$", DecimalEndPlace + 1)

					if Power or DecimalEndPlace == Length then
						return ProcessAsDecimal(Bytes or DEFAULT_RADIX, Minus == "-", Power and Point == "" and Decimal .. "." or Decimal, Power, 10, DEFAULT_BASE)
					end
				end
			end
		end

		error(Number2 .. " is not a valid Decimal value")
	elseif Type == "table" then
		-- The LSP is dumb.
		local Number2: Map<any, any> = Number
		return setmetatable(Number2, BigNum)
	else
		error(tostring(Number) .. " is not a valid input to BigNum.new, please supply a string or table")
	end
end

function BigNum:GetRange(Radix, Base)
	-- Returns the range for a given integer number of Radix
	-- @returns string

	Base = Base or DEFAULT_BASE
	Radix = Radix or DEFAULT_RADIX

	local Max = table.create(Radix)
	for Index = 2, Radix do
		Max[Index] = Base - 1
	end

	Max[1] = (Base - Base % 2) / 2 - 1
	return "+/- " .. ToScientificNotation(Max, Base)
end

function BigNum:SetDefaultRadix(NumRadix)
	DEFAULT_RADIX = NumRadix
end

-- The range of usable characters should be [CHAR_OFFSET, CHAR_OFFSET + 64]
local CHAR_OFFSET = 58
local _64_2 = 64 * 64
local _64_3 = _64_2 * 64

function BigNum.FromString64(String)
	-- Creates a BigNum from characters which were outputted by toString64()
	local Length = #String / 4
	local Array = table.create(Length)

	for Index = 1, Length do
		local Value = 4 * Index
		local A, B, C, D = string.byte(String, Value - 3, Value)
		Array[Index] = (A - CHAR_OFFSET) * _64_3 + (B - CHAR_OFFSET) * _64_2 + (C - CHAR_OFFSET) * 64 + (D - CHAR_OFFSET)
	end

	return setmetatable(Array, BigNum)
end

function BigNum.__index:ToString64()
	-- returns a string of characters which hold the values in the array for storage purposes
	local Array = table.create(#self)
	for Index, Value in ipairs(self) do
		local D = Value % 64
		Value = (Value - D) / 64
		local C = Value % 64
		Value = (Value - C) / 64
		local B = Value % 64
		Value = (Value - B) / 64
		local A = Value % 64

		Array[Index] = string.char(A + CHAR_OFFSET, B + CHAR_OFFSET, C + CHAR_OFFSET, D + CHAR_OFFSET)
	end

	return table.concat(Array)
end

function BigNum.__index:ToConstantForm(NumbersPerRow)
	-- l is number of numbers per row

	NumbersPerRow = NumbersPerRow or 16
	local Array = {"local CONSTANT_NUMBER = BigNum.new{\n\t"}

	for Index, Value in ipairs(self) do
		Value = tostring(Value)
		table.insert(Array, string.rep(" ", 0) .. Value)
		table.insert(Array, ",")
		if Index % NumbersPerRow == 0 then
			table.insert(Array, "\n\t")
		else
			table.insert(Array, " ")
		end
	end

	table.remove(Array)
	Array[#Array] = "\n}"
	WRITE_FILE_FOR_PLATFORM[PLATFORM](table.concat(Array))
end

function BigNum.__index:Stringify(Base)
	return (IsNegative(self, Base or DEFAULT_BASE) and "-" or " ") .. "{" .. table.concat(self, ", ") .. "}"
end

local Fraction = {
	ClassName = "Fraction";
	__index = {};
}

local function NewFraction(Numerator, Denominator, Base)
	if IsNegative(Denominator, Base) then
		Numerator = __unm(Numerator, Base)
		Denominator = __unm(Denominator, Base)
	end

	return setmetatable({
		Numerator = Numerator;
		Denominator = Denominator;
	}, Fraction)
end

local function Fraction__Reduce(self, Base)
	local CommonFactor = GCD(self.Numerator, self.Denominator, Base)

	self.Numerator = __div(self.Numerator, CommonFactor, Base)
	self.Denominator = __div(self.Denominator, CommonFactor, Base)

	return self
end

local function Fraction__add(A, B, Base)
	return NewFraction(__add(__mul(A.Numerator, B.Denominator, Base), __mul(B.Numerator, A.Denominator, Base), Base), __mul(A.Denominator, B.Denominator, Base), Base)
end

local function Fraction__sub(A, B, Base)
	return NewFraction(__sub(__mul(A.Numerator, B.Denominator, Base), __mul(B.Numerator, A.Denominator, Base), Base), __mul(A.Denominator, B.Denominator, Base), Base)
end

local function Fraction__mul(A, B, Base)
	return NewFraction(__mul(A.Numerator, B.Numerator, Base), __mul(A.Denominator, B.Denominator, Base), Base)
end

local function Fraction__div(A, B, Base)
	return NewFraction(__mul(A.Numerator, B.Denominator, Base), __mul(A.Denominator, B.Numerator, Base), Base)
end

local function Fraction__mod()
	error("The modulo operation is undefined for Fractions")
end

local function Fraction__pow(self, Power, Base)
	Power = __div(Power.Numerator, Power.Denominator, Base)

	if type(Power) == "number" then
		return NewFraction(__pow(self.Numerator, Power, Base), __pow(self.Denominator, Power, Base), Base)
	else
		error("Cannot raise " .. __tostring(self, Base) .. " to the Power of " .. __tostring(Power, Base))
	end
end

local function Fraction__tostring(self, Base)
	return __tostring(self.Numerator, Base) .. " / " .. __tostring(self.Denominator, Base)
end

local function Fraction__ToScientificNotation(self, Base, DigitsAfterDecimal)
	return ToScientificNotation(self.Numerator, Base, DigitsAfterDecimal) .. " / " .. ToScientificNotation(self.Denominator, Base, DigitsAfterDecimal)
end

local function Fraction__lt(A, B, Base)
	return __lt(__mul(A.Numerator, B.Denominator, Base), __mul(B.Numerator, A.Denominator, Base), Base)
end

local function Fraction__unm(A, Base)
	return NewFraction(__unm(A.Numerator, Base), A.Denominator, Base)
end

local function Fraction__eq(A, B, Base)
	return __eq(__mul(A.Numerator, B.Denominator, Base), __mul(B.Numerator, A.Denominator, Base))
end

local function EnsureFractionalCompatibility(Func, Unary)
	local typeof = typeof or type

	if Unary then
		return function(A, ...)
			if getmetatable(A) ~= Fraction then
				error("bad argument to #1: expected Fraction, got " .. typeof(A))
			end

			return Func(A, DEFAULT_BASE, ...)
		end
	else
		return function(A, B)
			if getmetatable(A) ~= Fraction then
				error("bad argument to #1: expected Fraction, got " .. typeof(A))
			end

			if getmetatable(B) ~= Fraction then
				error("bad argument to #2: expected Fraction, got " .. typeof(B))
			end

			if #A ~= #B then
				error("You cannot operate on Fractions with BigNums of different sizes: " .. #A .. " and " .. #B)
			end

			return Func(A, B, DEFAULT_BASE)
		end
	end
end

-- Unary operators
Fraction.__tostring = EnsureFractionalCompatibility(Fraction__tostring, true)
Fraction.__unm = EnsureFractionalCompatibility(Fraction__unm, true)
Fraction.__index.Reduce = EnsureFractionalCompatibility(Fraction__Reduce, true)
Fraction.__index.ToScientificNotation = EnsureFractionalCompatibility(Fraction__ToScientificNotation, true)

-- Binary operators
Fraction.__add = EnsureFractionalCompatibility(Fraction__add)
Fraction.__sub = EnsureFractionalCompatibility(Fraction__sub)
Fraction.__mul = EnsureFractionalCompatibility(Fraction__mul)
Fraction.__div = EnsureFractionalCompatibility(Fraction__div)
Fraction.__pow = EnsureFractionalCompatibility(Fraction__pow)
Fraction.__mod = EnsureFractionalCompatibility(Fraction__mod)

Fraction.__lt = EnsureFractionalCompatibility(Fraction__lt)
Fraction.__eq = EnsureFractionalCompatibility(Fraction__eq)

BigNum.NewFraction = EnsureCompatibility(NewFraction)

return BigNum