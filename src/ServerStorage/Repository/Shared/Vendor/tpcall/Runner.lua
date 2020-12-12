return setmetatable({}, {
	__call = function(_, Function, ...)
		return Function(...)
	end;
})