--[[
	A utility used to create a function spy that can be used to robustly test
	that functions are invoked the correct number of times and with the correct
	number of arguments.

	This should only be used in tests.
]]

local assertDeepEqual = require(script.Parent.assertDeepEqual)

local function createSpy(inner)
	local self = {
		callCount = 0,
		values = {},
		valuesLength = 0,

		value = nil,
		assertCalledWith = nil,
		assertCalledWithDeepEqual = nil,
		captureValues = nil,
	}

	self.value = function(...)
		self.callCount += 1
		self.values = {...}
		self.valuesLength = select("#", ...)

		if inner ~= nil then
			return inner(...)
		end
	end

	self.assertCalledWith = function(_, ...)
		local len = select("#", ...)

		if self.valuesLength ~= len then
			error(string.format(
				"Expected %d arguments, but was called with %d arguments",
				self.valuesLength,
				len
			), 2)
		end

		for i = 1, len do
			local expected = select(i, ...)

			assert(self.values[i] == expected, "value differs")
		end
	end

	self.assertCalledWithDeepEqual = function(_, ...)
		local len = select("#", ...)

		if self.valuesLength ~= len then
			error(string.format(
				"Expected %d arguments, but was called with %d arguments",
				self.valuesLength,
				len
			), 2)
		end

		for i = 1, len do
			local expected = select(i, ...)

			assertDeepEqual(self.values[i], expected)
		end
	end

	self.captureValues = function(_, ...)
		local len = select("#", ...)
		local result = {}

		assert(self.valuesLength == len, "length of expected values differs from stored values")

		for i = 1, len do
			local key = select(i, ...)
			result[key] = self.values[i]
		end

		return result
	end

	return setmetatable(self, {
		__index = function(_, key)
			error(("%q is not a valid member of spy"):format(key))
		end,
	})
end

return createSpy