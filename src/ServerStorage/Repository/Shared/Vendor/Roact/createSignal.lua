--[[
	This is a simple signal implementation that has a dead-simple API.

		local signal = createSignal()

		local disconnect = signal.subscribe(function(foo)
			print("Cool foo:", foo)
		end)

		signal.fire("something")

		disconnect()
]]

local function addToMap(map, addKey, addValue)
	local new = {}
	for key, value in next, map do
		new[key] = value
	end

	new[addKey] = addValue
	return new
end

local function removeFromMap(map, removeKey)
	local new = {}
	for key, value in next, map do
		if key ~= removeKey then
			new[key] = value
		end
	end

	return new
end

local function createSignal()
	local connections = {}

	local function subscribe(callback)
		if type(callback) ~= "function" then
			error("Can only subscribe to signals with a function.", 2)
		end

		local connection = {
			callback = callback,
			disconnected = false,
		}

		connections = addToMap(connections, callback, connection)

		local function disconnect()
			if connection.disconnected then
				error("Listeners can only be disconnected once.", 2)
			end

			connection.disconnected = true
			connections = removeFromMap(connections, callback)
		end

		return disconnect
	end

	local function fire(...)
		for callback, connection in next, connections do
			if not connection.disconnected then
				callback(...)
			end
		end
	end

	return {
		subscribe = subscribe,
		fire = fire,
	}
end

return createSignal