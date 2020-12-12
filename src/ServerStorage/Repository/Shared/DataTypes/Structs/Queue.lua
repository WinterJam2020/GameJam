local Queue = {__type = "Queue"}
Queue.__index = Queue

function Queue.new()
	return setmetatable({
		First = 1;
		Length = 0;
	}, Queue)
end

function Queue:Push(Value)
	local Length = self.Length + 1
	self.Length = Length
	Length += self.First - 1
	self[Length] = Value
	return Length
end

function Queue:Pop()
	local Length = self.Length
	if Length > 0 then
		local First = self.First
		local Value = self[First]
		self[First] = nil

		self.First = First + 1
		self.Length = Length - 1

		return Value
	end
end

function Queue:Front()
	return self[self.First]
end

function Queue:IsEmpty()
	return self.Length == 0
end

function Queue:_Iterator(Position)
	Position = Position and Position + 1 or 1
	if Position > self.Length then
		return nil, nil
	else
		return Position, self[self.First + Position - 1]
	end
end

function Queue:Iterator()
	return Queue._Iterator, self
end

function Queue:__tostring()
	local QueueArray = table.create(self.Length)
	for Index, Value in self:Iterator() do
		QueueArray[Index] = tostring(Value)
	end

	return "[" .. table.concat(QueueArray, ", ") .. "]"
end

function Queue:__call(Value)
	if Value then
		return self:Push(Value)
	else
		return self:Pop()
	end
end

return Queue