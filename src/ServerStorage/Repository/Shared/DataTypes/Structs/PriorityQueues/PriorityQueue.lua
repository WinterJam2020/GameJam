local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local t = Resources:LoadLibrary("t")

local PriorityQueue = {ClassName = "PriorityQueue"}
PriorityQueue.__index = PriorityQueue

type Array<Value> = {[number]: Value}
type IteratorFunction = typeof(ipairs{}) -- maybe?

export type HeapEntry = {
	Priority: number,
	Value: any,
}

export type PriorityQueue = typeof(setmetatable({
	Heap = {};
	Length = 0;
}, PriorityQueue))

local ipairs = ipairs
local null = nil

-- Queues are FIFO (first-in, first-out) order, which is basically like a line in a cafeteria. Or a "queue" if you're Bri*ish.

function PriorityQueue.new(): PriorityQueue
	return setmetatable({
		Heap = {};
		Length = 0;
	}, PriorityQueue)
end

--[[**
	Check whether the queue has no elements.
	@returns [Typer.Boolean] This will be true iff the queue is empty.
**--]]
function PriorityQueue:IsEmpty(): boolean
	return self.Length == 0
end

local function FindClosestIndex(self, Priority: number, Low: number, High: number): number
	local Middle: number do
		local Sum: number = Low + High
		Middle = (Sum - Sum % 2) / 2
	end

	if Middle == 0 then
		return -1
	end

	local Heap: Array<HeapEntry> = self.Heap
	local Element: HeapEntry = Heap[Middle]

	while Middle ~= High do
		local Priority2: number = Element.Priority
		if Priority == Priority2 then
			return Middle
		end

		if Priority < Priority2 then
			High = Middle - 1
		else
			Low = Middle + 1
		end

		local Sum: number = Low + High
		Middle = (Sum - Sum % 2) / 2
		Element = Heap[Middle]
	end

	return Middle
end

type SingleTypeChecker = (any) -> (boolean, string?)
type DoubleTypeChecker = (any, any) -> (boolean, string?)

local OptionalBoolean: SingleTypeChecker = t.optional(t.boolean)
local InsertWithPriorityTuple: DoubleTypeChecker = t.tuple(t.any, t.number)

--[[**
	Add an element to the queue with an associated priority.
	@param [Typer.Any] Value The value of the element.
	@param [Typer.Number] Priority The priority of the element.
	@returns [Typer.Integer] The inserted position.
**--]]
function PriorityQueue:InsertWithPriority(Value: any, Priority: number): number
	local TypeSuccess: boolean, TypeError: string? = InsertWithPriorityTuple(Value, Priority)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	local Heap: Array<HeapEntry> = self.Heap
	local Position: number = FindClosestIndex(self, Priority, 1, self.Length)
	local Element1: HeapEntry = {Value = Value, Priority = Priority}
	local Element2: HeapEntry? = Heap[Position]

	if Element2 then
		Position = Priority < Element2.Priority and Position or Position + 1
	else
		Position = 1
	end

	table.insert(Heap, Position, Element1)
	self.Length += 1
	return Position
end

PriorityQueue.Insert = PriorityQueue.InsertWithPriority

--[[**
	Changes the priority of the given value in the queue.
	@param [Typer.Any] Value The value you are updating the priority of.
	@param [Typer.Number] NewPriority The new priority of the value.
	@returns [Typer.OptionalNumber] The new position of the HeapEntry if it was found.
**--]]
function PriorityQueue:ChangePriority(Value: any, NewPriority: number): number?
	local TypeSuccess: boolean, TypeError: string? = InsertWithPriorityTuple(Value, NewPriority)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	local Heap: Array<HeapEntry> = self.Heap
	for Index, HeapEntry in ipairs(Heap) do
		if HeapEntry.Value == Value then
			table.remove(self.Heap, Index)
			self.Length -= 1
			return self:InsertWithPriority(Value, NewPriority)
		end
	end

	error("Couldn't find value in queue?", 2)
end

--[[**
	Gets the priority of the first value in the heap. This is the value that will be removed last.
	@returns [Typer.OptionalNumber] The priority of the first value.
**--]]
function PriorityQueue:GetFirstPriority(): number?
	if self.Length == 0 then
		return null
	end

	return self.Heap[1].Priority
end

--[[**
	Gets the priority of the last value in the heap. This is the value that will be removed first.
	@returns [Typer.OptionalNumber] The priority of the last value.
**--]]
function PriorityQueue:GetLastPriority(): number?
	local Length: number = self.Length
	if Length == 0 then
		return null
	end

	return self.Heap[Length].Priority
end

--[[**
	Remove the element from the queue that has the highest priority, and return it.
	@param [Typer.OptionalBoolean] OnlyValue Whether or not to return only the value or the entire entry.
	@returns [HeapEntry] The removed element.
**--]]
function PriorityQueue:PopElement(OnlyValue: boolean?): any | HeapEntry
	local TypeSuccess: boolean, TypeError: string? = OptionalBoolean(OnlyValue)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	local Heap: Array<HeapEntry> = self.Heap
	local Length: number = self.Length
	self.Length -= 1

	local Element: HeapEntry = Heap[Length]
	Heap[Length] = null
	return OnlyValue and Element.Value or Element
end

PriorityQueue.PullHighestPriorityElement = PriorityQueue.PopElement
PriorityQueue.GetMaximumElement = PriorityQueue.PopElement

--[[**
	Converts the entire PriorityQueue to an array.
	@param [Typer.OptionalBoolean] OnlyValues Whether or not the array is just the values or the priorities as well.
	@returns [Typer.Array] The PriorityQueue's array.
**--]]
function PriorityQueue:ToArray(OnlyValues: boolean?): Array<any> | Array<HeapEntry>
	local TypeSuccess: boolean, TypeError: string? = OptionalBoolean(OnlyValues)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	if OnlyValues then
		local Array: Array<any> = table.create(self.Length)
		for Index, HeapEntry in ipairs(self.Heap) do
			Array[Index] = HeapEntry.Value
		end

		return Array
	else
		-- This is slower, but it's so it's immutable.
		local Array: Array<HeapEntry> = table.create(self.Length)
		for Index, HeapEntry in ipairs(self.Heap) do
			Array[Index] = HeapEntry
		end

		return Array
	end
end

--[[**
	Returns an iterator function for iterating over the PriorityQueue.
	@param [Typer.OptionalBoolean] OnlyValues Whether or not the iterator returns just the values or the priorities as well.
	@returns [Typer.Function] The iterator function. Usage is `for Index, Value in PriorityQueue:Iterate(OnlyValues) do`.
**--]]
function PriorityQueue:Iterate(OnlyValues: boolean?): IteratorFunction
	local TypeSuccess: boolean, TypeError: string? = OptionalBoolean(OnlyValues)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	if OnlyValues then
		local Array: Array<any> = table.create(self.Length)
		for Index, HeapEntry in ipairs(self.Heap) do
			Array[Index] = HeapEntry.Value
		end

		return ipairs(Array)
	else
		return ipairs(self.Heap)
	end
end

--[[**
	Returns an iterator function for iterating over the PriorityQueue in reverse.
	@param [Typer.OptionalBoolean] OnlyValues Whether or not the iterator returns just the values or the priorities as well.
	@returns [Typer.Function] The iterator function. Usage is `for Index, Value in PriorityQueue:ReverseIterate(OnlyValues) do`.
**--]]
function PriorityQueue:ReverseIterate(OnlyValues: boolean?): IteratorFunction
	local TypeSuccess: boolean, TypeError: string? = OptionalBoolean(OnlyValues)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	local Length: number = self.Length
	local Top: number = Length + 1

	if OnlyValues then
		local Array: Array<any> = table.create(Length)
		for Index, HeapEntry in ipairs(self.Heap) do
			Array[Top - Index] = HeapEntry.Value
		end

		return ipairs(Array)
	else
		local Array: Array<HeapEntry> = table.create(Length)
		for Index, HeapEntry in ipairs(self.Heap) do
			Array[Top - Index] = HeapEntry
		end

		return ipairs(Array)
	end
end

--[[**
	Clears the entire PriorityQueue.
	@returns [PriorityQueue] The priority queue.
**--]]
function PriorityQueue:Clear(): PriorityQueue
	table.clear(self.Heap)
	self.Length = 0
	return self
end

--[[**
	Determines if the PriorityQueue contains the given value.
	@param [Typer.Any] Value The value you are searching for.
	@returns [Typer.Boolean] Whether or not the value was found.
**--]]
function PriorityQueue:Contains(Value: any): boolean
	for _, HeapEntry in ipairs(self.Heap) do
		if HeapEntry.Value == Value then
			return true
		end
	end

	return false
end

--[[**
	Removes the HeapEntry with the given priority, if it exists.
	@param [Typer.Number] Priority The priority you are removing from the queue.
	@returns [Typer.Nil]
**--]]
function PriorityQueue:RemovePriority(Priority: number)
	local TypeSuccess: boolean, TypeError: string? = t.number(Priority)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	for Index, HeapEntry in ipairs(self.Heap) do
		if HeapEntry.Priority == Priority then
			table.remove(self.Heap, Index)
			self.Length -= 1
			break
		end
	end
end

--[[**
	Removes the HeapEntry with the given value, if it exists.
	@param [Typer.Any] Value The value you are removing from the queue.
	@returns [Typer.Nil]
**--]]
function PriorityQueue:RemoveValue(Value: any)
	for Index, HeapEntry in ipairs(self.Heap) do
		if HeapEntry.Value == Value then
			table.remove(self.Heap, Index)
			self.Length -= 1
			break
		end
	end
end

function PriorityQueue:__tostring(): string
	local Array: Array<string> = table.create(self.Length)
	for Index, Value in self:Iterate(false) do
		Array[Index] = string.format("\t{Priority = %s, Value = %s};", tostring(Value.Priority), tostring(Value.Value))
	end

	return string.format("PriorityQueue {\n%s\n}", table.concat(Array, "\n"))
end

return PriorityQueue