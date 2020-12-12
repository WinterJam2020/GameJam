local function Symbol(Name: string)
	local SymbolName = string.format("Symbol(%s)", Name)
	local self = newproxy(true)
	getmetatable(self).__tostring = function(): string
		return SymbolName
	end

	return self
end

return Symbol