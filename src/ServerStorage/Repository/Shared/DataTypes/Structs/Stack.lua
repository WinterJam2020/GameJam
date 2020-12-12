local Stack = {__type = "Stack"}
Stack.__index = Stack

function Stack.new()
	return setmetatable({Length = 0}, Stack)
end

function Stack:Push(Value)
	local Length = self.Length + 1
	self[Length] = Value
	self.Length = Length
	return Length
end

function Stack:Pop()
	local Length = self.Length
	if Length > 0 then
		local Value = self[Length]
		self[Length] = nil
		self.Length = Length - 1
		return Value
	end
end

function Stack:Top()
	return self[self.Length]
end

function Stack:IsEmpty()
	return self.Length == 0
end

function Stack:__call(Value)
	if Value ~= nil then
		return self:Push(Value)
	else
		return self:Pop()
	end
end

function Stack:__tostring()
	return "[" .. table.concat(self, ", ") .. "]"
end

return Stack