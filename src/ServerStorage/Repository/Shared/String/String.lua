local StringPlus = {}

function StringPlus.RemovePrefix(String, Prefix)
	return string.sub(String, 1, #Prefix) == Prefix and string.sub(String, #Prefix + 1) or String
end

function StringPlus.RemovePostfix(String, Postfix)
	return string.sub(String, -#Postfix) == Postfix and string.sub(String, 1, -#Postfix - 1) or String
end

return StringPlus