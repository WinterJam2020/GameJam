type GenericTable = {[any]: any}

local function TypeOf(Value: any): string
	local ValueType: string = typeof(Value)
	if ValueType == "table" then
		local Metatable: GenericTable? = getmetatable(Value)
		if type(Metatable) == "table" then
			local CustomType: string? = Metatable.__type or Metatable.ClassName
			if CustomType then
				return CustomType
			else
				return ValueType
			end
		else
			return ValueType
		end
	else
		return ValueType
	end
end

return TypeOf