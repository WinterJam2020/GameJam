-- luaregex.lua ver.130911
-- A true, python-like regular expression for Lua

-- Usage:
--	local LuaRegex = require(LuaRegex)
--	local Regex = LuaRegex.Compile("\\w+")
--	for Match in Regex:Gmatch("Hello, World!") do
--		print(Match:Group(0))
--	end

--
-- If you find bugs, report them to omawarisan.bokudesu _AT_ live.jp.
--
-- The author releases this script in the public domain,
-- but he would appreciate your mercy if you remove or change the e-mail address above
-- when you publish some modified version of this script.

-- This version has PascalCase methods instead of lowerCamelCase.

--[[
or-exp:
	pair-exp
	or-exp "|" pair-exp

pair-exp:
	repeat-exp_opt
	pair-exp repeat-exp

repeat-exp:
	primary-exp
	repeat-exp repeater
	repeat-exp repeater "?"

primary-exp:
	"(?:" or-exp ")"
	"(?P<" identifier ">" or-exp ")"
	"(?P=" name ")"
	"(?=" or-exp ")"
	"(?!" or-exp ")"
	"(?<=" or-exp ")"
	"(?<!" or-exp ")"
	"(?(" name ")" pair-exp "|" pair-exp ")"
	"(?(" name ")" pair-exp ")"
	"(" or-exp ")"
	char-class
	non-terminal
	terminal-str

repeater:
	"*"
	"+"
	"?"
	"{" number_opt "," number_opt "}"
	"{" number "}"

char-class:
	"[^" user-char-class "]"
	"[" user-char-class "]"

user-char-class:
	user-char-range
	user-char-class user-char-range

user-char-range:
	user-char "-" user-char_opt
	user-char

user-char:
	class-escape-sequence
	CHARACTER OTHER THAN
		\, ]

class-escape-sequence:
	term-escape-sequence
	"\b"

terminal-str:
	terminal
	terminal-str terminal

terminal:
	term-escape-sequence
	CHARACTER OTHER THAN
		^, $, \, |, [, ], {, }, (, ), *, +, ?

term-escape-sequence:
	"\a"
	"\f"
	"\n"
	"\r"
	"\t"
	"\v"
	"\\"
	"\" ascii-puncuation-char
	"\x" hex-number

non-terminal:
	"^"
	"$"
	"."
	"\d"
	"\D"
	"\s"
	"\S"
	"\w"
	"\W"
	"\A"
	"\b"
	"\B"
	"\Z"
	"\" number

name:
	identifier
	number

number:
	STRING THAT MATCHES REGEX /[0-9]+/

identifier:
	STRING THAT MATCHES REGEX /[A-Za-z_][A-Za-z_0-9]*/

ascii-puncuation-char:
	CHAR THAT MATCHES REGEX /[!-~]/ and also /[^A-Za-z0-9]/

hex-number:
	STRING THAT MATCHES REGEX /[0-9A-Fa-f]{1,2}/
]]

local ZERO_BYTE = string.byte("0")
local NINE_BYTE = string.byte("9")

local LOWER_A_BYTE = string.byte("a")
local UPPER_A_BYTE = string.byte("A")

local LOWER_F_BYTE = string.byte("f")
local UPPER_F_BYTE = string.byte("F")

local LOWER_X_BYTE = string.byte("x")

local LOWER_Z_BYTE = string.byte("z")
local UPPER_Z_BYTE = string.byte("Z")

local UNDERSCORE_BYTE = string.byte("_")

local ff, nl, cr, ht, vt, ws = string.byte("\f\n\r\t\v ", 1, 6)

local DASH_BYTE = string.byte("-")

-- the base class of all
local __base_class__ = {}
function __base_class__.__init__(_)
end

-- Creates a new class, deriving from a base (optional)
local function class(base)
	base = base or __base_class__
	return setmetatable({}, {__index = base})
end

--- Creates a new object of a class
local function new(cls, ...)
	--- cls: the class
	--- ...: arguments for the constructor
	local self = setmetatable({}, {__index = cls})
	self:__init__(...)
	return self
end

-- Get object"s class
local function classof(object)
	return rawget(getmetatable(object), "__index")
end

-- Nodes of expression tree

-- expression"s base
local Expression = class()

function Expression:SetMatchee(matchee, pos)
	-- Resets the state of the self and set matchee.
	-- setting pos = nil just resets the expression
	-- (or, lets NextMatch(submatches, flags) return false)
	self.matchee = matchee
	self.pos = pos
	self:OnSetMatchee()
end

function Expression:NextMatch(submatches, flags): (boolean, number?)
	-- Before first calling this function,
	-- the user should have called self:SetMatchee(matchee, pos).
	-- (otherwise, this function just returns false)
	--
	-- This function enumerates possible matches for the self.
	-- Each time this is called, this returns (isOK, nextPos).
	-- - if isOK == true,
	-- nextPos denotes the position for the next expression.
	-- - if isOK == false,
	-- there was no match left.
	--
	-- Look also at the comment of Expression:OnNextMatch
	local pos = self.pos
	local isOK, nextPos
	if pos then
		isOK, nextPos = self:OnNextMatch(submatches, flags)
		if not isOK then
			self.pos = nil
		end
	end

	if self.name then
		if isOK then
			local array = table.create(2)
			array[1], array[2] = pos, nextPos
			submatches[self.name] = array
		else
			submatches[self.name] = nil
		end
	end

	return isOK, nextPos
end

function Expression:SetName(name)
	-- name: number or string
	self.name = name
end

function Expression:CloneCoreStateTo(clone)
	-- This should be called by Clone() of derived classes.
	-- Clones the core states into "clone"
	clone.matchee = self.matchee
	clone.pos = self.pos
	clone.name = self.name
end

-- Override this if necessary
function Expression.OnSetMatchee(_)
end

-- Define following functions in derived classes
-- function Expression:Clone()
-- Return a clone object of the self.
-- The state of the clone shall be the same as the self.
-- If the self has sub-objects, the sub-objects shall also be cloned.
--
-- function Expression:IsFixedLength()
-- Checks if the expression"s length is fixed.
-- This functions returns (isFixed, length)
--
-- function Expression:OnNextMatch(submatches, flags)
-- When this function is called,
-- self.matchee and self.pos refer to the string to be matched.
--
-- - If there are one or more matches for the self, then
-- this function shall return (true, NEXT_POSITION),
-- in the favored order, one by one, each time it is called.
-- - If there are no matches, or if there are no matches left,
-- then this function shall return false.
--
-- It is guaranteed that this function is never called
-- after
-- - this function returns false, or
-- - this function sets self.pos = nil,
-- until the user calls self:SetMatchee again.
--
-- A matched group named "name" (string or number)
-- can be obtained by
-- pos, nextPos = unpack(submatches[name])
-- str = string.sub(self.matchee, pos, nextPos-1)

-- expression AB
local ExpPair = class(Expression)

function ExpPair:__init__(sub1, sub2)
	self.sub1 = sub1
	self.sub2 = sub2
end

function ExpPair:OnSetMatchee()
	self.sub1:SetMatchee(self.matchee, self.pos)
	self.sub2:SetMatchee(nil, nil)
end

function ExpPair:Clone()
	local clone = new(classof(self), self.sub1:Clone(), self.sub2:Clone())
	self:CloneCoreStateTo(clone)
	return clone
end

function ExpPair:IsFixedLength(): (boolean, number?)
	local b, len1 = self.sub1:IsFixedLength()
	local len2
	if b then
		b, len2 = self.sub2:IsFixedLength()
		if b then
			return true, len1 + len2
		end
	end

	return false
end

function ExpPair:OnNextMatch(submatches, flags): (boolean, number?)
	local isOK, nextPos = self.sub2:NextMatch(submatches, flags)
	if isOK then
		return isOK, nextPos
	end

	repeat
		isOK, nextPos = self.sub1:NextMatch(submatches, flags)
		if not isOK then
			return false
		end

		self.sub2:SetMatchee(self.matchee, nextPos)
		isOK, nextPos = self.sub2:NextMatch(submatches, flags)
	until isOK

	return isOK, nextPos
end

-- expression A|B
local ExpOr = class(Expression)

function ExpOr:__init__(sub1, sub2)
	self.sub1 = sub1
	self.sub2 = sub2
end

function ExpOr:OnSetMatchee()
	local matchee = self.matchee
	local pos = self.pos
	self.sub1:SetMatchee(matchee, pos)
	self.sub2:SetMatchee(matchee, pos)
end

function ExpOr:Clone()
	local clone = new(classof(self), self.sub1:Clone(), self.sub2:Clone())
	self:CloneCoreStateTo(clone)
	return clone
end

function ExpOr:IsFixedLength(): (boolean, number?)
	local b, len1 = self.sub1:IsFixedLength()
	local len2
	if b then
		b, len2 = self.sub2:IsFixedLength()
		if b and len1 == len2 then
			return true, len1
		end
	end

	return false
end

function ExpOr:OnNextMatch(submatches, flags)
	local isOK, nextPos = self.sub1:NextMatch(submatches, flags)
	if isOK then
		return isOK, nextPos
	end

	return self.sub2:NextMatch(submatches, flags)
end

-- expression A{a,b}, which includes:
-- A* = A{,}
-- A+ = A{1,}
-- A? = A{,1}
-- A{n} = A{n,n}
-- a,b when omitted are assumed to be 0 and infinity, respectively
local ExpRepeat = class(Expression)

function ExpRepeat:__init__(sub, min, max)
	self.sub = sub
	self.min = min or 0
	self.max = max
end

function ExpRepeat:OnSetMatchee()
	local clone = self.sub:Clone()
	clone:SetMatchee(self.matchee, self.pos)

	local array = table.create(2)
	array[1], array[2] = clone, self.pos

	self.stack = {array}
end

function ExpRepeat:Clone()
	local clone = new(classof(self), self.sub:Clone(), self.min, self.max)
	self:CloneCoreStateTo(clone)

	if self.stack then
		local cloneStack = {}
		for i, v in ipairs(self.stack) do
			local array = table.create(2)
			array[1], array[2] = v[1]:Clone(), v[2]
			cloneStack[i] = array
		end

		clone.stack = cloneStack
	end

	return clone
end

function ExpRepeat:IsFixedLength(): boolean | number
	local min = self.min
	if min == self.max then
		local b, len = self.sub:IsFixedLength()
		if b then
			return len * min
		end
	end

	return false
end

function ExpRepeat:OnNextMatch(submatches, flags): (boolean, number?)
	local stack = self.stack
	local length = #stack
	local max = self.max
	local isOK, nextPos, entry

	while self.pos do
		local sub, pos

		while true do
			entry = stack[length]
			sub, pos = entry[1], entry[2]
			isOK, nextPos = sub:NextMatch(submatches, flags)
			if isOK then
				if not max or length < max then
					local clone = self.sub:Clone()
					clone:SetMatchee(self.matchee, nextPos)

					local array = table.create(2)
					array[1], array[2] = clone, nextPos
					length += 1

					stack[length] = array
				else
					break
				end
			else
				stack[length] = nil
				length -= 1
				nextPos = pos
				break
			end
		end

		if length == 0 then
			self.pos = nil
		end

		if self.min <= length and (not self.max or length <= self.max) then
			return true, nextPos
		end
	end

	return false
end

-- expression A{a,b}?, which includes:
-- A*? = A{,}?
-- A+? = A{1,}?
-- A?? = A{,1}?
-- a,b when omitted are assumed to be 0 and infinity, respectively
local ExpVigorless = class(Expression)

function ExpVigorless:__init__(sub, min, max)
	self.sub = sub
	self.min = min or 0
	self.max = max
end

function ExpVigorless:OnSetMatchee()
	self.sub:SetMatchee(self.matchee, self.pos)
	self.queue = nil
	self.curExp = nil
	self.curDepth = 0
end

function ExpVigorless:Clone()
	local clone = new(classof(self), self.sub:Clone(), self.min, self.max)
	self:CloneCoreStateTo(clone)

	local queue = self.queue
	if queue then
		local cloneQ = table.create(#queue)
		for i, v in ipairs(queue) do
			cloneQ[i] = v
		end

		clone.queue = cloneQ
	end

	clone.curExp = self.curExp
	clone.curDepth = self.curDepth

	return clone
end

function ExpVigorless:IsFixedLength(): boolean | number
	local min = self.min
	if min == self.max then
		local b, len = self.sub:IsFixedLength()
		if b then
			return len * min
		end
	end

	return false
end

function ExpVigorless:OnNextMatch(submatches, flags): (boolean, number?)
	local min = self.min
	local max = self.max
	local queue = self.queue

	if not queue then
		local array = table.create(2)
		array[1], array[2] = self.pos, 1
		self.queue = {array}

		if min <= 0 and (not max or 0 <= max) then
			return true, self.pos
		end
	end

	local length = #queue
	while true do
		local isOK, nextPos
		if self.curExp then
			isOK, nextPos = self.curExp:NextMatch(submatches, flags)
			if isOK then
				if not max or self.curDepth < max then
					local array = table.create(2)
					array[1], array[2] = nextPos, self.curDepth + 1
					length += 1
					queue[length] = array
				end

				if min <= self.curDepth and (not max or self.curDepth <= max) then
					return isOK, nextPos
				end
			else
				self.curExp = nil
			end
		elseif length > 0 then
			length -= 1
			nextPos, self.curDepth = table.unpack(table.remove(queue, 1))
			local clone = self.sub:Clone()
			clone:SetMatchee(self.matchee, nextPos)
			self.curExp = clone
		else
			return false
		end
	end
end

-- expression (?=A), (?!A)
local ExpLookAhead = class(Expression)

function ExpLookAhead:__init__(sub, affirmative)
	self.sub = sub
	self.aff = affirmative
end

function ExpLookAhead:OnSetMatchee()
	self.sub:SetMatchee(self.matchee, self.pos)
end

function ExpLookAhead:Clone()
	local clone = new(classof(self), self.sub:Clone())
	self:CloneCoreStateTo(clone)
	return clone
end

function ExpLookAhead.IsFixedLength(_): (boolean, number)
	return true, 0
end

function ExpLookAhead:OnNextMatch(submatches, flags): (boolean, number?)
	local isOK, nextPos = self.sub:NextMatch(submatches, flags)
	if (not self.aff) == (not isOK) then
		nextPos = self.pos
		self.pos = nil
		return true, nextPos
	end

	return false
end

-- expression (?<=A), (?<!A)
local ExpLookBack = class(Expression)

function ExpLookBack:__init__(sub, affirmative)
	local isFixed, len = sub:IsFixedLength()
	if not isFixed then
		error("isFixed failed to pass check!", 2)
	end

	self.sub = sub
	self.len = len
	self.aff = affirmative
end

function ExpLookBack:OnSetMatchee()
	local len = self.len
	local pos = self.pos

	if len < pos then
		self.sub:SetMatchee(self.matchee, pos - len)
	else
		self.sub:SetMatchee(nil, nil)
	end
end

function ExpLookBack:Clone()
	local clone = new(classof(self), self.sub:Clone())
	self:CloneCoreStateTo(clone)
	return clone
end

function ExpLookBack.IsFixedLength(_): (boolean, number)
	return true, 0
end

function ExpLookBack:OnNextMatch(submatches, flags): (boolean, number?)
	local isOK, nextPos = self.sub:NextMatch(submatches, flags)
	if (not self.aff) == (not isOK) then
		nextPos = self.pos
		self.pos = nil
		return true, nextPos
	end

	return false
end

-- expression (?(NAME)A|B)
-- "|B" can be omitted
local ExpConditional = class(Expression)

function ExpConditional:__init__(refname, sub1, sub2)
	self.refname = refname
	self.sub1 = sub1
	self.sub2 = sub2
end

function ExpConditional:OnSetMatchee()
	self.sub1:SetMatchee(self.matchee, self.pos)
	if self.sub2 then
		self.sub2:SetMatchee(self.matchee, self.pos)
	end
end

function ExpConditional:Clone()
	local cloneSub1 = self.sub1:Clone()
	local cloneSub2
	if self.sub2 then
		cloneSub2 = self.sub2:Clone()
	end

	local clone = new(classof(self), self.refname, cloneSub1, cloneSub2)
	self:CloneCoreStateTo(clone)
	return clone
end

function ExpConditional:IsFixedLength(): (boolean, number?)
	local b, len1 = self.sub1:IsFixedLength()
	if b then
		if self.sub2 then
			local len2
			b, len2 = self.sub2:IsFixedLength()
			if b and len1 == len2 then
				return true, len1
			end
		elseif len1 == 0 then
			return true, 0
		end
	end

	return false
end

function ExpConditional:OnNextMatch(submatches, flags): (boolean, number?)
	if submatches[self.refname] then
		return self.sub1:NextMatch(submatches, flags)
	elseif self.sub2 then
		return self.sub2:NextMatch(submatches, flags)
	else
		local pos = self.pos
		self.pos = nil
		return true, pos
	end
end

-- expression (?P=NAME)
local ExpReference = class(Expression)

function ExpReference:__init__(refname)
	self.refname = refname
end

function ExpReference:Clone()
	local clone = new(classof(self), self.refname)
	self:CloneCoreStateTo(clone)
	return clone
end

function ExpReference.IsFixedLength(_): boolean
	return false
end

function ExpReference:OnNextMatch(submatches): (boolean, number?)
	local pos = self.pos
	self.pos = nil

	local refRange = submatches[self.refname]
	if refRange then
		local refBeg, refEnd = refRange[1], refRange[2]
		local len = refEnd - refBeg
		local matchee = self.matchee
		if string.sub(matchee, pos, pos + len - 1) == string.sub(matchee, refBeg, refEnd - 1) then
			return true, pos + len
		else
			return false
		end
	else
		return true, pos
	end
end

-- expression that matches just one char
local ExpOneChar = class(Expression)

function ExpOneChar:__init__(fnIsMatch)
	-- fnIsMatch(char:byte()) -> bool
	self.fnIsMatch = fnIsMatch
end

function ExpOneChar:Clone()
	local clone = new(classof(self), self.fnIsMatch)
	self:CloneCoreStateTo(clone)
	return clone
end

function ExpOneChar.IsFixedLength()
	return true, 1
end

function ExpOneChar:OnNextMatch()
	local pos = self.pos
	local matchee = self.matchee
	self.pos = nil

	if pos > #matchee then
		return false
	end

	if self.fnIsMatch(string.byte(matchee, pos)) then
		return true, pos + 1
	else
		return false
	end
end

-- expression ^
local ExpLineBegin = class(Expression)

function ExpLineBegin:Clone()
	local clone = new(classof(self))
	self:CloneCoreStateTo(clone)
	return clone
end

function ExpLineBegin.IsFixedLength()
	return true, 0
end

function ExpLineBegin:OnNextMatch()
	local pos = self.pos
	self.pos = nil

	-- ^ matches even a null string
	if pos == 1 then
		return true, pos
	end

	if string.byte(self.matchee, pos - 1, pos - 1) == 10 then
		return true, pos
	end

	return false
end

-- expression $
local ExpLineEnd = class(Expression)

function ExpLineEnd:Clone()
	local clone = new(classof(self))
	self:CloneCoreStateTo(clone)
	return clone
end

function ExpLineEnd.IsFixedLength()
	return true, 0
end

function ExpLineEnd:OnNextMatch()
	local pos = self.pos
	self.pos = nil

	-- $ matches even a null string
	if pos == #self.matchee + 1 then
		return true, pos
	end

	if string.byte(self.matchee, pos, pos) == 10 then
		return true, pos
	end

	return false
end

-- expression \A
local ExpBegin = class(Expression)

function ExpBegin:Clone()
	local clone = new(classof(self))
	self:CloneCoreStateTo(clone)
	return clone
end

function ExpBegin.IsFixedLength()
	return true, 0
end

function ExpBegin:OnNextMatch()
	local pos = self.pos
	self.pos = nil

	-- ^ matches even a null string
	if pos == 1 then
		return true, pos
	end

	return false
end

-- expression \Z
local ExpEnd = class(Expression)

function ExpEnd:Clone()
	local clone = new(classof(self))
	self:CloneCoreStateTo(clone)
	return clone
end

function ExpEnd.IsFixedLength()
	return true, 0
end

function ExpEnd:OnNextMatch()
	local pos = self.pos
	self.pos = nil

	-- $ matches even a null string
	if pos == #self.matchee + 1 then
		return true, pos
	end

	return false
end

-- expression \b
local ExpBorder = class(Expression)

function ExpBorder:Clone()
	local clone = new(classof(self))
	self:CloneCoreStateTo(clone)
	return clone
end

function ExpBorder.IsFixedLength()
	return true, 0
end

function ExpBorder:OnNextMatch()
	local pos = self.pos
	self.pos = nil

	if self:IsWordAt(pos - 1) ~= self:IsWordAt(pos) then
		return true, pos
	end

	return false
end

function ExpBorder:IsWordAt(pos)
	if pos <= 0 then
		return false
	end

	local value = string.byte(self.matchee, pos)
	if not value then
		return false
	end

	return ZERO_BYTE <= value and value <= NINE_BYTE
		or UPPER_A_BYTE <= value and value <= UPPER_Z_BYTE
		or LOWER_A_BYTE <= value and value <= LOWER_Z_BYTE
		or value == UNDERSCORE_BYTE
end

-- expression \B
local ExpNegBorder = class(ExpBorder)

function ExpNegBorder:OnNextMatch()
	local pos = self.pos
	self.pos = nil

	if self:IsWordAt(pos - 1) == self:IsWordAt(pos) then
		return true, pos
	end

	return false
end

-- expression that matches a terminal string
local ExpTerminals = class(Expression)

function ExpTerminals:__init__(str)
	self.str = str
end

function ExpTerminals:Clone()
	local clone = new(classof(self), self.str)
	self:CloneCoreStateTo(clone)
	return clone
end

function ExpTerminals:IsFixedLength()
	return true, #self.str
end

function ExpTerminals:OnNextMatch()
	local pos = self.pos
	self.pos = nil

	local str = self.str
	local len = #str

	if string.sub(self.matchee, pos, pos + len - 1) == str then
		return true, pos + len
	else
		return false
	end
end

-- Parser to compile regex-string to expression-tree
local Parser = class()

function Parser:__init__(regexp, flags)
	self.regexp = regexp
	self.flags = flags
	self.nextCapture = 1

	local expOr, nextPos = self:GetExpOr(1)

	if not expOr then
		return
	end

	if nextPos ~= #regexp + 1 then
		if not self.errMsg then
			self.errMsg = "cannot compile"
			self.errPos = nextPos
		end

		return
	end

	self.errMsg = nil
	self.errPos = nil
	self.exp = expOr
end

function Parser:Error()
	return self.errMsg, self.errPos
end

function Parser:Expression()
	return self.exp
end

function Parser:GetExpOr(pos)
	local expOr, nextPos = self:GetExpPair(pos)
	if not expOr then
		return nil
	end

	local expPair
	while string.byte(self.regexp, nextPos, nextPos) == 124 do
		expPair, nextPos = self:GetExpPair(nextPos + 1)
		if not expPair then
			return nil
		end

		expOr = new(ExpOr, expOr, expPair)
	end

	return expOr, nextPos
end

function Parser:GetExpPair(pos)
	local expPair, nextPos = self:GetExpRepeat(pos)
	if not expPair then
		return new(ExpTerminals, ""), pos
	end

	pos = nextPos
	local expRepeat
	while true do
		expRepeat, nextPos = self:GetExpRepeat(pos)
		if not expRepeat then
			return expPair, pos
		end

		expPair = new(ExpPair, expPair, expRepeat)
		pos = nextPos
	end
end

function Parser:GetExpRepeat(pos)
	local expRepeat, nextPos = self:GetExpPrimary(pos)
	if not expRepeat then
		return nil
	end

	pos = nextPos
	local repeater
	while true do
		repeater, nextPos = self:GetRepeater(pos)
		if not repeater then
			return expRepeat, pos
		end

		local clsExp
		if string.byte(self.regexp, nextPos, nextPos) == 63 then
			clsExp = ExpVigorless
			nextPos += 1
		else
			clsExp = ExpRepeat
		end

		local min = repeater.min
		local max = repeater.max

		expRepeat = new(clsExp, expRepeat, min, max)
		pos = nextPos
	end
end

function Parser:GetExpPrimary(pos)
	local regexp = self.regexp

	if string.byte(regexp, pos, pos) == 40 then
		pos += 1
		local subExp, nextPos
		if string.byte(regexp, pos, pos) == 63 then
			pos += 1
			if string.byte(regexp, pos, pos) == 58 then
				subExp, nextPos = self:GetUnnamedGroup(pos + 1)
			elseif string.sub(regexp, pos, pos + 1) == "P<" then
				subExp, nextPos = self:GetUserNamedGroup(pos + 2)
			elseif string.sub(regexp, pos, pos + 1) == "P=" then
				subExp, nextPos = self:GetUserNamedRef(pos + 2)
			elseif string.byte(regexp, pos, pos) == 61 then
				subExp, nextPos = self:GetLookAhead(pos + 1)
			elseif string.byte(regexp, pos, pos) == 33 then
				subExp, nextPos = self:GetNegLookAhead(pos + 1)
			elseif string.sub(regexp, pos, pos + 1) == "<=" then
				subExp, nextPos = self:GetLookBack(pos + 2)
			elseif string.sub(regexp, pos, pos + 1) == "<!" then
				subExp, nextPos = self:GetNegLookBack(pos + 2)
			elseif string.byte(regexp, pos, pos) == 40 then
				subExp, nextPos = self:GetConditional(pos + 1)
			else
				self.errMsg = "invalid char"
				self.errPos = pos
				return nil
			end
		else
			subExp, nextPos = self:GetNamedGroup(pos)
		end

		if not subExp then
			return nil
		end

		if string.byte(self.regexp, nextPos, nextPos) == 41 then
			return subExp, nextPos + 1
		else
			self.errMsg = ") expected"
			self.errPos = nextPos
			return nil
		end
	end

	local subExp, nextPos = self:GetCharClass(pos)
	if subExp then
		return subExp, nextPos
	end

	subExp, nextPos = self:GetNonTerminal(pos)
	if subExp then
		return subExp, nextPos
	end

	subExp, nextPos = self:GetTerminalStr(pos)
	if subExp then
		return subExp, nextPos
	end

	return nil
end

function Parser:GetUnnamedGroup(pos)
	return self:GetExpOr(pos)
end

function Parser:GetUserNamedGroup(pos)
	local name, nextPos = self:GetIdentifier(pos)
	if not name then
		return nil
	end

	if string.byte(self.regexp, nextPos, nextPos) ~= 62 then
		self.errMsg = "> expected"
		self.errPos = nextPos
		return nil
	end

	local expOr
	expOr, nextPos = self:GetExpOr(nextPos + 1)
	if expOr then
		expOr:SetName(name)
	end

	return expOr, nextPos
end

function Parser:GetUserNamedRef(pos)
	local name, nextPos = self:GetName(pos)
	if not name then
		return nil
	end

	return new(ExpReference, name), nextPos
end

function Parser:GetLookAhead(pos)
	local expOr, nextPos = self:GetExpOr(pos)
	if expOr then
		expOr = new(ExpLookAhead, expOr, true)
	end

	return expOr, nextPos
end

function Parser:GetNegLookAhead(pos)
	local expOr, nextPos = self:GetExpOr(pos)
	if expOr then
		expOr = new(ExpLookAhead, expOr, false)
	end

	return expOr, nextPos
end

function Parser:GetLookBack(pos)
	local expOr, nextPos = self:GetExpOr(pos)
	if not expOr then
		return nil
	end

	if not expOr:IsFixedLength() then
		self.errMsg = "length must be fixed"
		self.errPos = pos + 1
		return nil
	end

	return new(ExpLookBack, expOr, true), nextPos
end

function Parser:GetNegLookBack(pos)
	local expOr, nextPos = self:GetExpOr(pos)
	if not expOr then
		return nil
	end

	if not expOr:IsFixedLength() then
		self.errMsg = "length must be fixed"
		self.errPos = pos + 1
		return nil
	end

	return new(ExpLookBack, expOr, false), nextPos
end

function Parser:GetConditional(pos)
	local name, nextPos = self:GetName(pos)
	if not name then
		return nil
	end

	if string.byte(self.regexp, nextPos, nextPos) ~= 41 then
		self.errMsg = ") expected"
		self.errPos = nextPos
		return nil
	end

	local exp1
	exp1, nextPos = self:GetExpPair(nextPos + 1)
	if not exp1 then
		return nil
	end

	local exp2
	if string.byte(self.regexp, nextPos,nextPos) == 124 then
		exp2, nextPos = self:GetExpPair(nextPos + 1)
		if not exp2 then
			return nil
		end
	end

	return new(ExpConditional, name, exp1, exp2), nextPos
end

function Parser:GetNamedGroup(pos)
	local id = self.nextCapture
	self.nextCapture += 1

	local expOr, nextPos = self:GetExpOr(pos)
	if expOr then
		expOr:SetName(id)
	else
		-- restore "nextCapture"
		self.nextCapture = id
	end

	return expOr, nextPos
end

function Parser:GetRepeater(pos)
	local regexp = self.regexp
	if pos > #regexp then
		return nil
	end

	local c = string.byte(regexp, pos, pos)
	if c == 42 then
		return {}, pos + 1
	end

	if c == 43 then
		return {min = 1}, pos + 1
	end

	if c == 63 then
		return {max = 1}, pos + 1
	end

	if c ~= 123 then
		return nil
	end

	pos += 1
	local min, max, nextPos

	min, nextPos = self:GetNumber(pos)
	if min then
		pos = nextPos
	end

	c = string.byte(regexp, pos, pos)
	if string.sub(regexp, pos, pos) == "" or (c ~= 44 and c ~= 125) then
		self.errMsg = ", or } expected"
		self.errPos = pos
		return nil
	end

	if not min and c == 125 then
		self.errMsg = "iteration number expected"
		self.errPos = pos
		return nil
	end

	pos += 1

	if c == 44 then
		max, nextPos = self:GetNumber(pos)
		if max then
			pos = nextPos
		end

		c = string.byte(regexp, pos, pos)
		if string.sub(regexp, pos, pos) == "" or c ~= 125 then
			self.errMsg = "} expected"
			self.errPos = pos
			return nil
		end

		pos += 1
	else
		max = min
	end

	return {min = min, max = max}, pos
end

function Parser:GetCharClass(pos)
	local regexp = self.regexp
	if string.byte(regexp, pos, pos) ~= 91 then
		return nil
	end

	pos += 1
	local affirmative
	if string.byte(regexp, pos, pos) == 94 then
		affirmative = false
		pos += 1
	else
		affirmative = true
	end

	local fnIsMatch, nextPos = self:GetUserCharClass(pos)
	if not fnIsMatch then
		return nil
	end

	if string.byte(regexp, nextPos,nextPos) ~= 93 then
		self.errMsg = "] expected"
		self.errPos = nextPos
		return nil
	end

	local fn
	if affirmative then
		fn = fnIsMatch
	else
		fn = function(c)
			return not fnIsMatch(c)
		end
	end

	return new(ExpOneChar, fn), nextPos + 1
end

function Parser:GetUserCharClass(pos)
	local fnIsMatch, nextPos = self:GetUserCharRange(pos)
	if not fnIsMatch then
		self.errMsg = "empty class not allowed"
		self.errPos = pos
		return nil
	end

	local aFn = {fnIsMatch}
	local length = 1
	pos = nextPos
	while true do
		-- the following "local" is mandatory
		fnIsMatch, nextPos = self:GetUserCharRange(pos)
		if not fnIsMatch then
			local fn = function(c)
				for _, v in ipairs(aFn) do
					if v(c) then
						return true
					end
				end

				return false
			end

			return fn, pos
		end

		length += 1
		aFn[length] = fnIsMatch
		pos = nextPos
	end
end

function Parser:GetUserCharRange(pos)
	local char1, nextPos = self:GetUserChar(pos)
	if not char1 then
		return nil
	end

	if string.byte(self.regexp, nextPos, nextPos) ~= 45 then
		return function(c)
			return c == char1
		end, nextPos
	end

	pos = nextPos + 1

	local char2
	char2, nextPos = self:GetUserChar(pos)
	if char2 then
		return function(c)
			return char1 <= c and c <= char2
		end, nextPos
	else
		char2 = DASH_BYTE
		return function(c)
			return DASH_BYTE == c or c == DASH_BYTE
		end, pos
	end
end

function Parser:GetUserChar(pos)
	local value, nextPos = self:GetClassEscSeq(pos)
	if value then
		return value, nextPos
	end

	local regexp = self.regexp
	local c = string.byte(regexp, pos, pos)
	if string.sub(regexp, pos, pos) ~= "" and c ~= 92 and c ~= 93 then
		return c, pos + 1
	else
		return nil
	end
end

function Parser:GetClassEscSeq(pos)
	local value, nextPos = self:GetTermEscSeq(pos)
	if value then
		return value, nextPos
	end

	if string.sub(self.regexp, pos, pos + 1) == "\\b" then
		return 0x08, pos + 2
	else
		return nil
	end
end

--local values = {
--	"^", "$", ".", "\\";
--	"d", "D", "s", "S", "w", "W", "A", "b", "B", "Z";
--}

--for _, Value in ipairs(values) do
--	print(string.format("%s = %d", Value, string.byte(Value)))
--end

function Parser:GetNonTerminal(pos)
	local regexp = self.regexp
	local char = string.byte(regexp, pos, pos)
	if char == 94 then
		return new(ExpLineBegin), pos + 1
	end

	if char == 36 then
		return new(ExpLineEnd), pos + 1
	end

	if char == 46 then
		return new(ExpOneChar, function(c)
			return c ~= nl
		end), pos + 1
	end

	if char ~= 92 then
		return nil
	end

	char = string.byte(regexp, pos + 1, pos + 1)
	if char == 100 then
		local fn = function(c)
			return ZERO_BYTE <= c and c <= NINE_BYTE
		end

		return new(ExpOneChar, fn), pos + 2
	end

	if char == 68 then
		local fn = function(c)
			return not (ZERO_BYTE <= c and c <= NINE_BYTE)
		end

		return new(ExpOneChar, fn), pos + 2
	end

	if char == 115 then
		local fn = function(c)
			-- check it in the order of likeliness
			return c == ws or c == nl or c == ht
				or c == cr or c == vt or c == ff
		end

		return new(ExpOneChar, fn), pos + 2
	end

	if char == 83 then
		local fn = function(c)
			-- check it in the order of likeliness
			return not (c == ws or c == nl or c == ht or c == cr or c == vt or c == ff)
		end

		return new(ExpOneChar, fn), pos + 2
	end

	if char == 119 then
		local fn = function(c)
			return
				LOWER_A_BYTE <= c and c <= LOWER_Z_BYTE
				or UPPER_A_BYTE <= c and c <= UPPER_Z_BYTE
				or ZERO_BYTE <= c and c <= NINE_BYTE
				or c == UNDERSCORE_BYTE
		end

		return new(ExpOneChar, fn), pos + 2
	end

	if char == 87 then
		local fn = function(c)
			return not (
				LOWER_A_BYTE <= c and c <= LOWER_Z_BYTE
				or UPPER_A_BYTE <= c and c <= UPPER_Z_BYTE
				or ZERO_BYTE <= c and c <= NINE_BYTE
				or c == UNDERSCORE_BYTE
				--(a <= c and c <= z)
				--or (A <= c and c <= UPPER_Z_BYTE)
				--or (zero <= c and c <= NINE_BYTE)
				--or c == UNDERSCORE_BYTE
			)
		end

		return new(ExpOneChar, fn), pos + 2
	end

	if char == 65 then
		return new(ExpBegin), pos + 2
	end

	if char == 98 then
		return new(ExpBorder), pos + 2
	end

	if char == 66 then
		return new(ExpNegBorder), pos + 2
	end

	if char == 90 then
		return new(ExpEnd), pos + 2
	end

	local value, nextPos = self:GetNumber(pos + 1)
	if value then
		return new(ExpReference, value), nextPos
	end

	self.errMsg = "invalid escape sequence"
	self.errPos = pos
	return nil
end

--function Parser:GetNonTerminal(pos)
--	local regexp = self.regexp
--	local char = string.sub(regexp, pos, pos)
--	if char == "^" then
--		return new(ExpLineBegin), pos + 1
--	end

--	if char == "$" then
--		return new(ExpLineEnd), pos + 1
--	end

--	if char == "." then
--		return new(ExpOneChar, function(c)
--			return c ~= nl
--		end), pos + 1
--	end

--	if char ~= "\\" then
--		return nil
--	end

--	char = string.sub(regexp, pos + 1, pos + 1)
--	if char == "d" then
--		local fn = function(c)
--			return ZERO_BYTE <= c and c <= NINE_BYTE
--		end

--		return new(ExpOneChar, fn), pos + 2
--	end

--	if char == "D" then
--		local fn = function(c)
--			return not (ZERO_BYTE <= c and c <= NINE_BYTE)
--		end

--		return new(ExpOneChar, fn), pos + 2
--	end

--	if char == "s" then
--		local fn = function(c)
--			-- check it in the order of likeliness
--			return c == ws or c == nl or c == ht
--				or c == cr or c == vt or c == ff
--		end

--		return new(ExpOneChar, fn), pos + 2
--	end

--	if char == "S" then
--		local fn = function(c)
--			-- check it in the order of likeliness
--			return not (c == ws or c == nl or c == ht or c == cr or c == vt or c == ff)
--		end

--		return new(ExpOneChar, fn), pos + 2
--	end

--	if char == "w" then
--		local fn = function(c)
--			return
--				LOWER_A_BYTE <= c and c <= LOWER_Z_BYTE
--				or UPPER_A_BYTE <= c and c <= UPPER_Z_BYTE
--				or ZERO_BYTE <= c and c <= NINE_BYTE
--				or c == UNDERSCORE_BYTE
--		end

--		return new(ExpOneChar, fn), pos + 2
--	end

--	if char == "W" then
--		local fn = function(c)
--			return not (
--				LOWER_A_BYTE <= c and c <= LOWER_Z_BYTE
--				or UPPER_A_BYTE <= c and c <= UPPER_Z_BYTE
--				or ZERO_BYTE <= c and c <= NINE_BYTE
--				or c == UNDERSCORE_BYTE
--				--(a <= c and c <= z)
--				--or (A <= c and c <= UPPER_Z_BYTE)
--				--or (zero <= c and c <= NINE_BYTE)
--				--or c == UNDERSCORE_BYTE
--			)
--		end

--		return new(ExpOneChar, fn), pos + 2
--	end

--	if char == "A" then
--		return new(ExpBegin), pos + 2
--	end

--	if char == "b" then
--		return new(ExpBorder), pos + 2
--	end

--	if char == "B" then
--		return new(ExpNegBorder), pos + 2
--	end

--	if char == "Z" then
--		return new(ExpEnd), pos + 2
--	end

--	local value, nextPos = self:GetNumber(pos + 1)
--	if value then
--		return new(ExpReference, value), nextPos
--	end

--	self.errMsg = "invalid escape sequence"
--	self.errPos = pos
--	return nil
--end

function Parser:GetTerminalStr(pos)
	local value, nextPos = self:GetTerminal(pos)
	if not value then
		return nil
	end

	local list = {value}
	local length = 1
	pos = nextPos

	while true do
		value, nextPos = self:GetTerminal(pos)
		if not value then
			return new(ExpTerminals, self.regexp.char(table.unpack(list))), pos
		end

		length += 1
		list[length] = value
		pos = nextPos
	end
end

local g_nonTerminal_Parser_GetTerminal = {
	[string.byte("^")] = true;
	[string.byte("$")] = true;
	[string.byte("\\")] = true;
	[string.byte("|")] = true;
	[string.byte("[")] = true;
	[string.byte("]")] = true;
	[string.byte("{")] = true;
	[string.byte("}")] = true;
	[string.byte("(")] = true;
	[string.byte(")")] = true;
	[string.byte("*")] = true;
	[string.byte("+")] = true;
	[string.byte("?")] = true;
}

function Parser:GetTerminal(pos)
	local value, nextPos = self:GetTermEscSeq(pos)
	if value then
		return value, nextPos
	end

	value = string.byte(self.regexp, pos, pos)
	if not value then
		return nil
	end

	local nonTerminal = g_nonTerminal_Parser_GetTerminal
	if nonTerminal[value] then
		return nil
	end

	return value, pos + 1
end

local g_entity_Parser_GetTermEscSeq = {
	[string.byte("a")] = 0x07;
	[string.byte("f")] = 0x0c;
	[string.byte("n")] = 0x0a;
	[string.byte("r")] = 0x0d;
	[string.byte("t")] = 0x09;
	[string.byte("v")] = 0x0b;
	[string.byte("!")] = string.byte("!");
	[string.byte("\"")] = string.byte("\"");
	[string.byte("#")] = string.byte("#");
	[string.byte("$")] = string.byte("$");
	[string.byte("%")] = string.byte("%");
	[string.byte("&")] = string.byte("&");
	[string.byte("'")] = string.byte("'");
	[string.byte("(")] = string.byte("(");
	[string.byte(")")] = string.byte(")");
	[string.byte("*")] = string.byte("*");
	[string.byte("+")] = string.byte("+");
	[string.byte(",")] = string.byte(",");
	[string.byte("-")] = string.byte("-");
	[string.byte(".")] = string.byte(".");
	[string.byte("/")] = string.byte("/");
	[string.byte(":")] = string.byte(":");
	[string.byte(";")] = string.byte(";");
	[string.byte("<")] = string.byte("<");
	[string.byte("=")] = string.byte("=");
	[string.byte(">")] = string.byte(">");
	[string.byte("?")] = string.byte("?");
	[string.byte("@")] = string.byte("@");
	[string.byte("[")] = string.byte("[");
	[string.byte("\\")] = string.byte("\\");
	[string.byte("]")] = string.byte("]");
	[string.byte("^")] = string.byte("^");
	[string.byte("_")] = string.byte("_");
	[string.byte("`")] = string.byte("`");
	[string.byte("{")] = string.byte("{");
	[string.byte("|")] = string.byte("|");
	[string.byte("}")] = string.byte("}");
	[string.byte("~")] = string.byte("~");
}

function Parser:GetTermEscSeq(pos)
	local regexp = self.regexp
	if string.byte(regexp, pos, pos) ~= 92 then
		return nil
	end

	local entity = g_entity_Parser_GetTermEscSeq
	local c = string.byte(regexp, pos + 1)
	local value = entity[c]
	if value then
		return value, pos + 2
	end

	if c == LOWER_X_BYTE then
		local nextPos
		value, nextPos = self:GetHexNumber(pos + 2, 2)
		if not value then
			self.errMsg = "hexadecimal number expected"
			self.errPos = pos + 2
			return nil
		end

		return value, nextPos
	end

	self.errMsg = "invalid escape sequence"
	self.errPos = pos

	return nil
end

function Parser:GetName(pos)
	local name, nextPos = self:GetIdentifier(pos)
	if name then
		return name, nextPos
	end

	name, nextPos = self:GetNumber(pos)
	if name then
		return name, nextPos
	end

	return nil
end

function Parser:GetIdentifier(pos)
	local regexp = self.regexp

	local value
	local c = string.byte(regexp, pos)
	if not c then
		return nil
	end

	local length = 0
	if UPPER_A_BYTE <= c and c <= UPPER_Z_BYTE or LOWER_A_BYTE <= c and c <= LOWER_Z_BYTE or c == UNDERSCORE_BYTE then
		value = {c}
		length = 1
	else
		return nil
	end

	local nextPos = pos + 1
	while true do
		c = string.byte(regexp, nextPos)
		if not c then
			break
		end

		if UPPER_A_BYTE <= c and c <= UPPER_Z_BYTE or LOWER_A_BYTE <= c and c <= LOWER_Z_BYTE or ZERO_BYTE <= c and c <= NINE_BYTE or c == UNDERSCORE_BYTE then
			length += 1
			value[length] = c
			nextPos += 1
		else
			break
		end
	end

	return regexp.char(table.unpack(value)), nextPos
end

function Parser:GetNumber(pos)
	local regexp = self.regexp

	local nextPos = pos
	local value = 0
	while 1 do
		local digit = string.byte(regexp, nextPos)
		if not digit then
			break
		end

		if not (ZERO_BYTE <= digit and digit <= NINE_BYTE) then
			break
		end

		value = 10 * value + (digit - ZERO_BYTE)
		nextPos += 1
	end

	if pos == nextPos then
		return nil
	end

	return value, nextPos
end

function Parser:GetHexNumber(pos, maxDigits)
	local regexp = self.regexp

	local nextPos = pos
	local value = 0
	local i = 0
	while not maxDigits or i < maxDigits do
		local digit = string.byte(regexp, nextPos)
		if not digit then
			break
		end

		if ZERO_BYTE <= digit and digit <= NINE_BYTE then
			value = 16 * value + (digit - ZERO_BYTE)
		elseif UPPER_A_BYTE <= digit and digit <= UPPER_F_BYTE then
			value = 16 * value + (digit - UPPER_A_BYTE + 10)
		elseif LOWER_A_BYTE <= digit and digit <= LOWER_F_BYTE then
			value = 16 * value + (digit - LOWER_A_BYTE + 10)
		else
			break
		end

		nextPos += 1
		i += 1
	end

	if pos == nextPos then
		return nil
	end

	return value, nextPos
end

-- Match class (represents submatches)
local Match = class()

function Match:__init__(matchee, submatches)
	self.matchee = matchee
	self.submatches = submatches
end

-- function Match:expand(format) end
-- This is defined later (to use Regex)

function Match:Group(...)
	-- /(a)(b)(c)/ matching "abc", then
	-- group(0,1,2,3) returns "abc", "a", "b", "c"
	-- group() is equivalent to group(0)

	local args = {...}
	if #args == 0 then
		args = table.create(1, 0)
	end

	local matchee = self.matchee
	local submatches = self.submatches
	local groups = {}

	for i, name in ipairs(args) do
		local span = submatches[name]
		if span then
			groups[i] = string.sub(matchee, span[1], span[2] - 1)
		end
	end

	return table.unpack(groups)
end

function Match:Span(groupId)
	-- Returns index pair (begin, end) of group "groupId".
	-- Note "end" is one past the end.

	groupId = groupId or 0

	local span = self.submatches[groupId]
	if span then
		return table.unpack(span)
	else
		return nil
	end
end

-- Regex class
local Regex = class()

Regex.__regex__ = true -- type marker

function Regex:__init__(regexp, flags)
	local parser = new(Parser, regexp, flags)
	local exp = parser:Expression()
	if exp == nil then
		local msg, pos = parser:Error()
		error(string.format("regex at %d: %s", pos, msg), 2)
	end

	self.exp = exp
	self.flags = flags
end

function Regex:Match(str, pos)
	if not pos then
		pos = 1
	elseif pos < 0 then
		pos = #str - pos + 1
	end

	if pos < 0 then
		pos = 1
	end

	local submatches = {}
	local exp = self.exp
	exp:SetMatchee(str, pos)
	local isOK, nextPos = exp:NextMatch(submatches, self.flags)

	if not isOK then
		return nil
	end

	local array = table.create(2, pos)
	array[2] = nextPos
	submatches[0] = array
	return new(Match, str, submatches)
end

function Regex:Search(str, pos)
	if not pos then
		pos = 1
	elseif pos < 0 then
		pos = #str - pos + 1
	end

	if pos < 0 then
		pos = 1
	end

	for p = pos, #str do
		local match = self:Match(str, p)
		if match then
			return match
		end
	end

	return nil
end

--function Regex:Sub(repl, str, count)
--	if count and count <= 0 then
--		return str, 0
--	end

--	local isFunc
--	if type(repl) == "function" then
--		isFunc = true
--	else
--		local meta = getmetatable(repl)
--		if meta and meta.__call then
--			isFunc = true
--		end
--	end

--	local list = {}
--	local length = 0
--	local nRepl = 0
--	local prevPos = 1
--	for match in self:GFind(str) do
--		local curBeg, curEnd = match:Span()
--		length += 1
--		list[length] = string.sub(str, prevPos, curBeg - 1)

--		local r
--		if isFunc then
--			r = repl(match)
--			if r then
--				r = tostring(r)
--			else
--				r = ""
--			end
--		else
--			r = match:Expand(repl)
--		end

--		length += 1
--		list[length] = r
--		prevPos = curEnd

--		nRepl += 1
--		if count and count <= nRepl then
--			break
--		end
--	end

--	length += 1
--	list[length] = string.sub(str, prevPos, -1)
--	return table.concat(list), nRepl
--end

type ReplaceWith = string | {} | (string) -> string

function Regex:Sub(ReplaceWith: ReplaceWith, String: string, MaxReplacements: number?): (string, number)
	if MaxReplacements and MaxReplacements <= 0 then
		return String, 0
	end

	local IsFunction: boolean = false
	if type(ReplaceWith) == "function" then
		IsFunction = true
	else
		local Metatable = getmetatable(ReplaceWith)
		if Metatable and Metatable.__call then
			IsFunction = true
		end
	end

	local StringArray = {}
	local Length = 0
	local TotalReplacements = 0
	local PreviousPosition = 1
	for StringMatch in self:GFind(String) do
		local CurrentBeginning, CurrendEnd = StringMatch:Span()
		Length += 1
		StringArray[Length] = string.sub(String, PreviousPosition, CurrentBeginning - 1)

		local Replacement
		if IsFunction then
			Replacement = ReplaceWith(StringMatch)
			if Replacement then
				Replacement = tostring(Replacement)
			else
				Replacement = ""
			end
		else
			Replacement = StringMatch:Expand(ReplaceWith)
		end

		Length += 1
		StringArray[Length] = Replacement
		PreviousPosition = CurrendEnd

		TotalReplacements += 1
		if MaxReplacements and MaxReplacements <= TotalReplacements then
			break
		end
	end

	Length += 1
	StringArray[Length] = string.sub(String, PreviousPosition, -1)
	return table.concat(StringArray), TotalReplacements
end

Regex.Gsub = Regex.Sub

function Regex:FindAll(str, pos)
	local list = {}
	local length = 0
	for match in self:GFind(str, pos) do
		length += 1
		list[length] = match
	end

	return list
end

function Regex:GFind(str, pos)
	pos = pos or 1

	local match = {
		matchee = str;
		Span = function()
			return nil, pos
		end;
	}

	return self.__finditer, self, match
end

Regex.Gmatch = Regex.GFind
Regex.Gfind = Regex.GFind

function Regex:__finditer(match)
	local prevBeg, prevEnd = match:Span(0)
	if prevBeg == prevEnd then
		prevEnd += 1
	end

	return self:Search(match.matchee, prevEnd)
end

-- additional method of Match
local g_regex_Match_expand = new(Regex, [[\\(?:(\d+)|g<(?:(\d+)|([A-Za-z_][A-Za-z0-9_]*))>|[xX]([0-9a-fA-F]{1,2})|([abfnrtv\\]))]])
function Match:Expand(format)
	-- Replaces \number, \g<number>, \g<name>
	-- to the corresponding groups
	-- Also \a, \b, \f, \n, \r, \t, \v, \x## are recognized

	local regex = g_regex_Match_expand

	local function replace(match)
		local group = match:Group(1) or match:Group(2)
		if group then
			return self:Group(tonumber(group, 10))
		end

		group = match:Group(3)
		if group then
			return self:Group(group)
		end

		group = match:Group(4)
		if group then
			return match.matchee.char(tonumber("0x" .. group))
		end

		group = match:Group(5)
		if group == "a" then
			return "\a"
		elseif group == "b" then
			return "\b"
		elseif group == "f" then
			return "\f"
		elseif group == "n" then
			return "\n"
		elseif group == "r" then
			return "\r"
		elseif group == "t" then
			return "\t"
		elseif group == "v" then
			return "\v"
		elseif group == "\\" then
			return "\\"
		end
	end

	return (regex:Sub(replace, format))
end

-- export type Regex = typeof(new(Regex, "\\w+"))

local re = {}

function re.Compile(regexp: string, flags)
	return new(Regex, regexp, flags)
end

function re.Match(regexp: string, str: string, pos, flags)
	return re.__getRegex(regexp, flags):Match(str, pos)
end

function re.Search(regexp: string, str: string, pos, flags)
	return re.__getRegex(regexp, flags):Search(str, pos)
end

--function re.Sub(regexp: string, repl, str: string, count, flags)
--	return re.__getRegex(regexp, flags):Sub(repl, str, count)
--end

--[[**
	Essentially a Regex version of string.gsub.
	@param [string] String The string you are gsubbing.
	@param [string] Pattern The regex pattern to replace with.
	@param [ReplaceWith] ReplaceWith What you are using to replace with. This can be a string, a table with __call, or a function.
	@param [number?] MaxReplacements The max amount of replacements to make.
	@returns [string] The gsubbed string.
**--]]
function re.Gsub(String: string, Pattern: string, ReplaceWith: ReplaceWith, MaxReplacements: number?, Flags): (string, number)
	return re.__getRegex(Pattern, Flags):Sub(ReplaceWith, String, MaxReplacements)
end

re.Sub = re.Gsub

function re.FindAll(regexp: string, str: string, pos, flags)
	return re.__getRegex(regexp, flags):FindAll(str, pos)
end

function re.Gmatch(regexp: string, str: string, pos, flags)
	return re.__getRegex(regexp, flags):GFind(str, pos)
end

re.GFind = re.Gmatch
re.Gfind = re.Gmatch

function re.__getRegex(regexp, flags)
	if regexp.__regex__ then
		return regexp
	else
		return re.__compile(regexp, flags)
	end
end

re.cacheSize = 100 -- this is the size of regex cache

local g_sourceCache_re = {}
local g_objectCache_re = {}

function re.__compile(regexp, flags)
	local sourceCache = g_sourceCache_re
	local objectCache = g_objectCache_re

	local obj = objectCache[regexp]
	if obj then
		-- flags must be considered:
		-- anyway, flags does not work for now

		local theI = table.find(sourceCache, regexp)
		if theI and theI > 1 then
			for i = theI, 2, -1 do
				sourceCache[i] = sourceCache[i - 1]
			end

			sourceCache[1] = regexp
		end

		return obj
	end

	obj = re.Compile(regexp, flags)
	local cacheSize = re.cacheSize

	local size = #sourceCache
	while cacheSize <= size do
		local name = sourceCache[size]
		sourceCache[size] = nil
		objectCache[name] = nil
		size -= 1
	end

	table.insert(sourceCache, 1, regexp)
	objectCache[regexp] = obj

	return obj
end

return re