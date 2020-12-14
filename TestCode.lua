local function SetReadonly(Class, ReadonlyProperties)
	local __index = assert(Class.__index, "Class must have __index metamethod before calling setreadonly.")
	for Index, Value in next, ReadonlyProperties do
		__index[Index] = Value
	end

	function Class:__newindex(Index, Value)
		if ReadonlyProperties[Index] == nil then
			rawset(self, Index, Value)
		else
			assert(false, string.format("Property %q is read-only", tostring(Index)))
		end
	end
end

local Class = {}
Class.__index = Class

function Class.new(BufferSize)
	return setmetatable({
		BufferSize = BufferSize;
		Data = {};
	}, Class)
end
SetReadonly(Class, {BufferSize = 6})

local Object = Class.new(5)
SetReadonly(Object, {BufferSize = 6})
print(Object.BufferSize)
Object.BufferSize = 10
print(Object.BufferSize)