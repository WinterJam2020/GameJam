local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local None = Resources:LoadLibrary("None")
local typeof = Resources:LoadLibrary("TypeOf")

local LinkedList = {__type = "LinkedList"}
LinkedList.__index = LinkedList

local ListNode = {__type = "ListNode"}
ListNode.__index = ListNode

--[[**
	Creates an empty `LinkedList`.
	@param Types.Array<Types.Any>? Values An optional array that contains the values you want to add.
	@returns LinkedList
**--]]
function LinkedList.new(Values)
	if Values then
		local self = setmetatable({
			First = nil;
			Last = nil;
			Length = 0;
		}, LinkedList)

		for _, Value in ipairs(Values) do
			self:Push(Value)
		end

		return self
	else
		return setmetatable({
			First = nil;
			Last = nil;
			Length = 0;
		}, LinkedList)
	end
end

--[[**
	Adds the element `Value` to the end of the list. This operation should compute in O(1) time and O(1) memory.
	@param Types.Any Value The value you are appending.
	@returns ListNode The appended node.
**--]]
function LinkedList:Push(Value)
	if Value == nil then
		error("Value passed to LinkedList::Push was nil!", 2)
	end

	self.Length += 1
	local Previous = self.Last
	local Node = setmetatable({
		Previous = Previous;
		Next = nil;
		Value = Value;
		List = self;
	}, ListNode)

	if Previous then
		Previous.Next = Node
	else
		self.First = Node
	end

	self.Last = Node
	return Node
end

--[[**
	Adds the elements from `List` to the end of the list. This operation should compute in O(1) time and O(1) memory.
	@param LinkedList List The `LinkedList` you are appending from.
	@returns Types.Nil
**--]]
function LinkedList:Append(List)
	assert(typeof(List) == "LinkedList", string.format("Invalid type for LinkedList::Append (LinkedList expected, got %s)", typeof(List)))
	for _, NodeValue in List:Iterator() do
		self:Push(NodeValue)
	end
end

--[[**
	Adds the element `Value` to the start of the list. This operation should compute in O(1) time and O(1) memory.
	@param Types.Any Value The value you are prepending.
	@returns ListNode The prepended node.
**--]]
function LinkedList:PushFront(Value)
	if Value == nil then
		error("Value passed to LinkedList::PushFront was nil!", 2)
	end

	self.Length += 1
	local Next = self.First
	local Node = setmetatable({
		Previous = nil;
		Next = Next;
		Value = Value;
		List = self;
	}, ListNode)

	if Next then
		Next.Previous = Node
	else
		self.Last = Node
	end

	self.First = Node
	return Node
end

--[[**
	Adds the elements from `List` to the start of the list. This operation should compute in O(1) time and O(1) memory.
	@param LinkedList List The `LinkedList` you are prepending from.
	@returns Types.Nil
**--]]
function LinkedList:Prepend(List)
	assert(typeof(List) == "LinkedList", string.format("Invalid type for LinkedList::Prepend (LinkedList expected, got %s)", typeof(List)))
	for _, NodeValue in List:ReverseIterator() do
		self:PushFront(NodeValue)
	end
end

--[[**
	Removes the first element and returns it, or `None` if the list is empty. This operation should compute in O(1) time.
	@returns ListNode|None
**--]]
function LinkedList:Pop()
	if self.Length == 0 then
		return None
	else
		local Node = self.First
		if Node then
			Node:Destroy()
			return Node
		else
			return None
		end
	end
end

--[[**
	Removes the last element and returns it, or `None` if the list is empty. This operation should compute in O(1) time.
	@returns ListNode|None
**--]]
function LinkedList:PopBack()
	if self.Length == 0 then
		return None
	else
		local Node = self.Last
		if Node then
			Node:Destroy()
			return Node
		else
			return None
		end
	end
end

--[[**
	Returns `true` if the `LinkedList` is empty. This operation should compute in O(1) time.
	@returns Types.Boolean
**--]]
function LinkedList:IsEmpty()
	return self.Length <= 0
end

--[[**
	Removes all elements from the `LinkedList`. This operation should compute in O(n) time.
	@returns LinkedList
**--]]
function LinkedList:Clear()
	while self.Length > 0 do
		local Node = self.First
		if Node then
			Node:Destroy()
		end
	end

	return self
end

--[[**
	Returns `true` if the `LinkedList` contains an element equal to the given value.
	@param Types.Any|ListNode The value you are searching for.
	@returns Types.Boolean
**--]]
function LinkedList:Contains(Value)
	if typeof(Value) == "ListNode" then
		for Node in self:Iterator() do
			if Node == Value then
				return true
			end
		end
	else
		for _, NodeValue in self:Iterator() do
			if NodeValue == Value then
				return true
			end
		end
	end

	return false
end

function LinkedList:_Iterator(Node)
	Node = not Node and self.First or Node and Node.Next
	if not Node then
		return nil, nil
	else
		return Node, Node.Value
	end
end

function LinkedList:_ReverseIterator(Node)
	Node = not Node and self.Last or Node and Node.Previous
	if not Node then
		return nil, nil
	else
		return Node, Node.Value
	end
end

--[[**
	Provides a forward iterator.
	@returns LinkedListIterator
**--]]
function LinkedList:Iterator()
	return LinkedList._Iterator, self
end

--[[**
	Provides a reverse iterator.
	@returns LinkedListIterator
**--]]
function LinkedList:ReverseIterator()
	return LinkedList._ReverseIterator, self
end

--[[**
	Returns an array containing all of the elements in this list in proper sequence (from first to last element).
	@returns Array<Any>
**--]]
function LinkedList:ToArray()
	local Array = {}
	local Length = 0
	for _, Value in self:Iterator() do
		Length += 1
		Array[Length] = Value
	end

	return Array
end

--[[**
	Removes the element at the given index from the `LinkedList`. This operation should compute in O(n) time.
	@param Types.Number Index The index of the node you want to remove.
	@returns LinkedList
**--]]
function LinkedList:Remove(Index)
	if Index > self.Length or Index < 1 then
		error(string.format("Index %d is out of the range of [1, %d]", Index, self.Length), 2)
	end

	local CurrentNode = self.First
	local CurrentIndex = 0

	while CurrentNode do
		CurrentIndex += 1
		if CurrentIndex == Index then
			if CurrentNode == self.First then
				self.First = CurrentNode.Next
			elseif CurrentNode == self.Last then
				self.Last = CurrentNode.Previous
			else
				CurrentNode.Previous.Next = CurrentNode.Next
				CurrentNode.Next.Previous = CurrentNode.Previous
			end

			self.Length -= 1
			break
		end

		CurrentNode = CurrentNode.Next
	end

	return self
end

--[[**
	Removes any element with the given value from the `LinkedList`. This operation should compute in O(n) time.
	@param Types.Any Value The value you want to remove from the `LinkedList`.
	@returns LinkedList
**--]]
function LinkedList:RemoveValue(Value)
	local CurrentNode = self.First
	while CurrentNode do
		if CurrentNode.Value == Value then
			if CurrentNode == self.First then
				self.First = CurrentNode.Next
			elseif CurrentNode == self.Last then
				self.Last = CurrentNode.Previous
			else
				CurrentNode.Previous.Next = CurrentNode.Next
				CurrentNode.Next.Previous = CurrentNode.Previous
			end

			self.Length -= 1
		end

		CurrentNode = CurrentNode.Next
	end

	return self
end

--[[**
	Removes the given `ListNode` from the `LinkedList`. This operation should compute in O(n) time.
	@param ListNode Node The node you want to remove from the `LinkedList`.
	@returns LinkedList
**--]]
function LinkedList:RemoveNode(Node)
	local CurrentNode = self.First
	while CurrentNode do
		if CurrentNode == Node then
			if CurrentNode == self.First then
				self.First = CurrentNode.Next
			elseif CurrentNode == self.Last then
				self.Last = CurrentNode.Previous
			else
				CurrentNode.Previous.Next = CurrentNode.Next
				CurrentNode.Next.Previous = CurrentNode.Previous
			end

			self.Length -= 1
		end

		CurrentNode = CurrentNode.Next
	end

	return self
end

function ListNode:After(Value)
	local List = self.List
	if List then
		List.Length += 1
		local Node = setmetatable({
			Previous = self;
			Next = self.Next;
			Value = Value;
		}, ListNode)

		if List.Last == self then
			List.Last = Node
		else
			self.Next.Previous = Node
		end

		self.Next = Node
		return Node
	end
end

function ListNode:Before(Value)
	local List = self.List
	if List then
		List.Length += 1
		local Node = setmetatable({
			Previous = self.Previous;
			Next = self;
			Value = Value;
		}, ListNode)

		if List.First == self then
			List.First = Node
		else
			self.Previous.Next = Node
		end

		self.Previous = Node
		return Node
	end
end

function ListNode:Destroy()
	local List = self.List
	if List then
		self.List = nil
		List.Length -= 1

		local Previous = self.Previous
		local Next = self.Next

		if self == List.Last then
			List.Last = Previous
		end

		if self == List.First then
			List.First = Next
		end

		if Previous then
			Previous.Next = Next
		end

		if Next then
			Next.Previous = Previous
		end

		return true
	else
		return false
	end
end

function ListNode:Iterator()
	local List = self.List
	if List then
		return LinkedList._Iterator, List, self
	end
end

function ListNode:ReverseIterator()
	local List = self.List
	if List then
		return LinkedList._ReverseIterator, List, self
	end
end

function LinkedList:__tostring()
	local ListArray = table.create(self.Length)
	local Length = 0

	for _, Value in self:Iterator() do
		Length += 1
		ListArray[Length] = tostring(Value)
	end

	return "[" .. table.concat(ListArray, ", ") .. "]"
end

function ListNode:__tostring()
	return tostring(self.Value)
end

return LinkedList