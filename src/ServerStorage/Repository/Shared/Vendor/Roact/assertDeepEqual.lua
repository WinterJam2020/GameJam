--[[
	A utility used to assert that two objects are value-equal recursively. It
	outputs fairly nicely formatted messages to help diagnose why two objects
	would be different.

	This should only be used in tests.
]]

local function deepEqual(a, b)
	if typeof(a) ~= typeof(b) then
		return false, string.format("{1} is of type %s, but {2} is of type %s", typeof(a), typeof(b))
	end

	if typeof(a) == "table" then
		local visitedKeys = {}

		for key, value in next, a do
			visitedKeys[key] = true

			local success, innerMessage = deepEqual(value, b[key])
			if not success then
				return false, string.gsub(string.gsub(innerMessage, "{1}", string.format("{1}[%s]", tostring(key))), "{2}", string.format("{2}[%s]", tostring(key)))
			end
		end

		for key, value in next, b do
			if not visitedKeys[key] then
				local success, innerMessage = deepEqual(value, a[key])

				if not success then
					return false, string.gsub(string.gsub(innerMessage, "{1}", string.format("{1}[%s]", tostring(key))), "{2}", string.format("{2}[%s]", tostring(key)))
				end
			end
		end

		return true
	end

	if a == b then
		return true
	end

	return false, "{1} ~= {2}"
end

local function assertDeepEqual(a, b)
	local success, innerMessageTemplate = deepEqual(a, b)

	if not success then
		error(string.format("Values were not deep-equal.\n%s", string.gsub(string.gsub(innerMessageTemplate, "{1}", "first"), "{2}", "second")), 2)
	end
end

return assertDeepEqual