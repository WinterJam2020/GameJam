return setmetatable({}, {
	__index = function(self, Index)
		local Value = game:GetService(Index)
		self[Index] = Value
		return Value
	end;
})