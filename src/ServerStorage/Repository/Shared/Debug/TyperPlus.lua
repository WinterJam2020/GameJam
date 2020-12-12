local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local LuaRegex = Resources:LoadLibrary("LuaRegex")
local Table = Resources:LoadLibrary("Table")
local Typer = Resources:LoadLibrary("Typer")

local LuaRegex_Match = LuaRegex.Match

local TyperPlus = {}

type Map<Index, Value> = {[Index]: Value}
type Array<Value> = Map<number, Value>

TyperPlus.RegexMatch = setmetatable({}, {
	__index = function(self, IndexName)
		local PatternValue = setmetatable({}, {
			__index = function(this, PatternToMatch)
				local MatchValue = {[IndexName] = function(Value, TypeOfString)
					return TypeOfString == "string" and LuaRegex_Match(Value, PatternToMatch) ~= nil
				end}

				this[PatternToMatch] = MatchValue
				return MatchValue
			end;
		})

		self[IndexName] = PatternValue
		return PatternValue
	end;

	__call = function(self, IndexName: string, PatternToMatch: string)
		return self[IndexName][PatternToMatch]
	end;
})

TyperPlus.StringMatch = setmetatable({}, {
	__index = function(self, IndexName)
		local PatternValue = setmetatable({}, {
			__index = function(this, PatternToMatch)
				local MatchValue = {[IndexName] = function(Value, TypeOfString)
					return TypeOfString == "string" and string.match(Value, PatternToMatch) ~= nil
				end}

				this[PatternToMatch] = MatchValue
				return MatchValue
			end;
		})

		self[IndexName] = PatternValue
		return PatternValue
	end;

	__call = function(self, IndexName: string, PatternToMatch: string)
		return self[IndexName][PatternToMatch]
	end;
})

TyperPlus.Literal = setmetatable({}, {
	_index = function(self, IndexName)
		local LiteralValue = setmetatable({}, {
			__index = function(this, ValuesMap: Map<any, boolean>)
				local FirstType = typeof(next(ValuesMap))
				local MatchValue = {[IndexName] = function(Value, TypeOfString)
					return TypeOfString == FirstType and ValuesMap[Value] == true
				end}

				this[ValuesMap] = MatchValue
				return MatchValue
			end;
		})

		self[IndexName] = LiteralValue
		return LiteralValue
	end;

	__call = function(self, IndexName: string, ValuesToMatch: Array<any>)
		local ValuesMap: Map<any, boolean> = {}
		for _, Value in ipairs(ValuesToMatch) do
			ValuesMap[Value] = true
		end

		return self[IndexName][ValuesMap]
	end;
})

if false then
	--[[**
		Creates a custom Typer checking function for a regular expression match.
		@param Name {Typer.String} The name of the function. This will be used as the index of the checking table.
		@param Pattern {Typer.String} The regex pattern to match with.
		@returns {TyperCheckFunction}
	**--]]
	TyperPlus.RegexMatch = Typer.AssignSignature(Typer.String, Typer.String, function(Name: string, Pattern: string)
		return Name, Pattern
	end)

	--[[**
		Creates a custom Typer checking function for a Lua string pattern.
		@param Name {Typer.String} The name of the function. This will be used as the index of the checking table.
		@param Pattern {Typer.String} The string pattern to match with.
		@returns {TyperCheckFunction}
	**--]]
	TyperPlus.StringMatch = Typer.AssignSignature(Typer.String, Typer.String, function(Name: string, Pattern: string)
		return Name, Pattern
	end)

	--[[**
		Creates a custom Typer checking function for a list of literal values.
		@param Name {Typer.String} The name of the function. This will be used as the index of the checking table.
		@param ValuesToMatch {Typer.Array} The allowed values.
		@returns {TyperCheckFunction}
	**--]]
	TyperPlus.Literal = Typer.AssignSignature(Typer.String, Typer.Array, function(Name: string, ValuesToMatch: Array<any>)
		return Name, ValuesToMatch
	end)
end

return Table.Lock(TyperPlus, nil, script.Name)