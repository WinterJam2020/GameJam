local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)

local Table = {}

function Table.FastRemove(Array, Index: number)
	local Length: number = #Array
	Array[Index] = Array[Length]
	Array[Length] = nil
end

function Table.FastRemoveGivenLength(Array, Index: number, Length: number): number
	Array[Index] = Array[Length]
	Array[Length] = nil
	return Length - 1
end

local function DeepCopy(Target, Context)
	Context = Context or {}
	if Context[Target] then
		return Context[Target]
	end

	if type(Target) == "table" then
		local NewTable = {}
		Context[Target] = NewTable
		for Index, Value in next, Target do
			NewTable[DeepCopy(Index, Context)] = DeepCopy(Value, Context)
		end

		return setmetatable(NewTable, DeepCopy(getmetatable(Target), Context))
	else
		return Target
	end
end

Table.DeepCopy = DeepCopy

local function FastDeepCopy(From)
	local CopiedTable = table.create(#From)
	for Index, Value in next, From do
		if type(Value) == "table" then
			CopiedTable[Index] = FastDeepCopy(Value)
		else
			CopiedTable[Index] = Value
		end
	end

	return CopiedTable
end

Table.FastDeepCopy = FastDeepCopy

local function UpdateTable(Target, Template)
	for Index, Value in next, Template do
		if type(Index) == "string" then
			if Target[Index] == nil then
				if type(Value) == "table" then
					Target[Index] = FastDeepCopy(Value)
				else
					Target[Index] = Value
				end
			elseif type(Target[Index]) == "table" and type(Value) == "table" then
				UpdateTable(Target[Index], Value)
			end
		end
	end
end

Table.UpdateTable = UpdateTable

function Table.RemoveObject(Array, Object)
	local Index: number? = table.find(Array, Object)
	if Index then
		local Length: number = #Array
		Array[Index] = Array[Length]
		Array[Length] = nil
	end
end

function Table.Lock(Target, __call, ModuleName: string)
	ModuleName = ModuleName or tostring(Target)
	local Userdata = newproxy(true)
	local Metatable = getmetatable(Userdata)

	function Metatable.__index(_, Index)
		local Value = Target[Index]
		return Value == nil and Resources:LoadLibrary("Debug").Error("!%q does not exist in read-only table.", ModuleName, Index) or Value
	end

	function Metatable.__newindex(_, Index, Value)
		Resources:LoadLibrary("Debug").Error("!Cannot write %s to index [%q] of read-only table", ModuleName, Value, Index)
	end

	function Metatable.__tostring(): string
		return ModuleName
	end

	Metatable.__call = __call
	Metatable.__metatable = "[" .. ModuleName .. "] Requested metatable of read-only table is locked"
	return Userdata
end

function Table.FastLock(Target, __call, ModuleName: string?)
	ModuleName = ModuleName or tostring(Target)
	local function BadIndex(_, Index)
		error(string.format("%q (%s) is not a valid member of %s", tostring(Index), typeof(Index), ModuleName), 2)
	end

	return setmetatable(Target, {
		__metatable = "[" .. ModuleName .. "] Requested metatable of read-only table is locked";
		__call = __call;
		__index = BadIndex;
		__newindex = BadIndex;
		__tostring = function()
			return ModuleName
		end;
	})
end

return Table.Lock(Table, nil, script.Name)