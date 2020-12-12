local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Debug = Resources:LoadLibrary("Debug")
local SortedArray = Resources:LoadLibrary("SortedArray")
local Typer = Resources:LoadLibrary("Typer")

local Debug_Error = Debug.Error
local Debug_Inspect = Debug.Inspect
local ipairs = ipairs
local next = next

local Error__index = {
	__index = function(_, Index)
		Debug_Error(tostring(Index) .. " is not a valid EnumerationItem")
	end;
}

local Error__index2 = {
	__index = function(_, Index)
		Debug_Error(tostring(Index) .. " is not a valid member")
	end;
}

local EnumerationsArray = SortedArray.new(nil, function(Left, Right)
	return tostring(Left) < tostring(Right)
end)

local Enumerations = setmetatable({}, Error__index)

function Enumerations.GetEnumerations()
	return EnumerationsArray:Copy()
end

local function ReadOnlyNewIndex(_, Index)
	Debug_Error("Cannot write to index [%q]", tostring(Index))
end

local function CompareEnumTypes(EnumItem1, EnumItem2)
	return EnumItem1.Value < EnumItem2.Value
end

local Casts = {}
local EnumContainerTemplate = {__index = setmetatable({}, Error__index)}

function EnumContainerTemplate.__index:GetEnumerationItems()
	local Array = {}
	local Count = 0

	for _, Item in next, EnumContainerTemplate[self] do
		Count += 1
		Array[Count] = Item
	end

	table.sort(Array, CompareEnumTypes)
	return Array
end

function EnumContainerTemplate.__index:Cast(Value)
	local Castables = Casts[self]
	local Cast = Castables[Value]

	if Cast then
		return Cast
	else
		return false, "[" .. Debug_Inspect(Value) .. "] is not a valid " .. tostring(self)
	end
end

local function ConstructUserdata(__index, __newindex, __tostring: string)
	local Enumeration = newproxy(true)

	local EnumerationMetatable = getmetatable(Enumeration)
	EnumerationMetatable.__index = __index
	EnumerationMetatable.__metatable = "[Enumeration] Requested metatable is locked"
	EnumerationMetatable.__newindex = __newindex
	function EnumerationMetatable.__tostring(): string
		return __tostring
	end

	return Enumeration
end

local function ConstructEnumerationItem(Name, Value, EnumContainer, LockedEnumContainer, EnumerationStringStub, Castables)
	local Item = ConstructUserdata(setmetatable({
		Name = Name;
		Value = Value;
		EnumerationType = LockedEnumContainer;
	}, Error__index2), ReadOnlyNewIndex, EnumerationStringStub .. Name)

	Castables[Name] = Item
	Castables[Value] = Item
	Castables[Item] = Item

	EnumContainer[Name] = Item
end

-- local MakeEnumerationTuple = t.tuple(t.string, t.union(t.array(t.string), t.map(t.string, t.number)))

local MakeEnumeration = Typer.AssignSignature(2, Typer.String, Typer.ArrayOfStringsOrDictionaryOfNumbers, function(_, EnumType, EnumTypes)
	if rawget(Enumerations, EnumType) then
		Debug_Error("Enumeration of EnumType " .. EnumType .. " already exists", 2)
	end

	local Castables = {}
	local EnumContainer = setmetatable({}, EnumContainerTemplate)
	local LockedEnumContainer = ConstructUserdata(EnumContainer, ReadOnlyNewIndex, EnumType)
	local EnumerationStringStub = "Enumeration." .. EnumType .. "."

	if #EnumTypes > 0 then
		for Index, Type in ipairs(EnumTypes) do
			ConstructEnumerationItem(Type, Index - 1, EnumContainer, LockedEnumContainer, EnumerationStringStub, Castables)
		end
	else
		for Name, Value in next, EnumTypes do
			ConstructEnumerationItem(Name, Value, EnumContainer, LockedEnumContainer, EnumerationStringStub, Castables)
		end
	end

	Casts[LockedEnumContainer] = Castables
	EnumContainerTemplate[LockedEnumContainer] = EnumContainer
	EnumerationsArray:Insert(LockedEnumContainer)
	Enumerations[EnumType] = LockedEnumContainer
end)

return ConstructUserdata(Enumerations, MakeEnumeration, "Enumerations")