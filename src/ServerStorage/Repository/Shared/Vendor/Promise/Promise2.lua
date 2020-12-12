--[[
	An implementation of Promises similar to Promise/A+.
]]

local ERROR_NON_PROMISE_IN_LIST = "Non-promise value passed into %s at index %s"
local ERROR_NON_LIST = "Please pass a list of promises to %s"
local ERROR_NON_FUNCTION = "Please pass a handler function to %s!"
local MODE_KEY_METATABLE = {__mode = "k"}

--[[
	Creates an enum dictionary with some metamethods to prevent common mistakes.
]]
local function makeEnum(enumName, members)
	local enum = {}

	for _, memberName in ipairs(members) do
		enum[memberName] = memberName
	end

	return setmetatable(enum, {
		__index = function(_, k)
			error(string.format("%s is not in %s!", k, enumName), 2)
		end,
		__newindex = function()
			error(string.format("Creating new members in %s is not allowed!", enumName), 2)
		end,
	})
end

--[[
	An object to represent runtime errors that occur during execution.
	Promises that experience an error like this will be rejected with
	an instance of this object.
]]
local Error do
	Error = {
		Kind = makeEnum("Promise.Error.Kind", {
			"ExecutionError",
			"AlreadyCancelled",
			"NotResolvedInTime",
			"TimedOut",
		}),
	}
	Error.__index = Error

	function Error.new(options, parent)
		options = options or {}
		return setmetatable({
			error = tostring(options.error) or "[This error has no error text.]",
			trace = options.trace,
			context = options.context,
			kind = options.kind,
			parent = parent,
			createdTick = os.clock(),
			createdTrace = debug.traceback(),
		}, Error)
	end

	function Error.is(anything)
		if type(anything) == "table" then
			local metatable = getmetatable(anything)

			if type(metatable) == "table" then
				return rawget(anything, "error") ~= nil and type(rawget(metatable, "extend")) == "function"
			end
		end

		return false
	end

	function Error.isKind(anything, kind)
		assert(kind ~= nil, "Argument #2 to Promise.Error.isKind must not be nil")

		return Error.is(anything) and anything.kind == kind
	end

	function Error:extend(options)
		options = options or {}

		options.kind = options.kind or self.kind

		return Error.new(options, self)
	end

	function Error:getErrorChain()
		local runtimeErrors = { self }

		while runtimeErrors[#runtimeErrors].parent do
			table.insert(runtimeErrors, runtimeErrors[#runtimeErrors].parent)
		end

		return runtimeErrors
	end

	function Error:__tostring()
		local errorStrings = {
			string.format("-- Promise.Error(%s) --", self.kind or "?"),
		}

		for _, runtimeError in ipairs(self:getErrorChain()) do
			table.insert(errorStrings, table.concat({
				runtimeError.trace or runtimeError.error,
				runtimeError.context,
			}, "\n"))
		end

		return table.concat(errorStrings, "\n")
	end
end

--[[
	Packs a number of arguments into a table and returns its length.

	Used to cajole varargs without dropping sparse values.
]]
local function pack(...)
	return select("#", ...), {...}
end

--[[
	Returns first value (success), and packs all following values.
]]
local function packResult(success, ...)
	return success, select("#", ...), {...}
end

local function makeErrorHandler(traceback)
	assert(traceback ~= nil)

	return function(err)
		-- If the error object is already a table, forward it directly.
		-- Should we extend the error here and add our own trace?

		if type(err) == "table" then
			return err
		end

		return Error.new({
			error = err,
			kind = Error.Kind.ExecutionError,
			trace = debug.traceback(tostring(err), 2),
			context = "Promise created at:\n\n" .. traceback,
		})
	end
end

--[[
	Calls a Promise executor with error handling.
]]
local function runExecutor(traceback, callback, ...)
	return packResult(xpcall(callback, makeErrorHandler(traceback), ...))
end

--[[
	Creates a function that invokes a callback with correct error handling and
	resolution mechanisms.
]]
local function createAdvancer(traceback, callback, resolve, reject)
	return function(...)
		local ok, resultLength, result = runExecutor(traceback, callback, ...)

		if ok then
			resolve(table.unpack(result, 1, resultLength))
		else
			reject(result[1])
		end
	end
end

local function isEmpty(t)
	return next(t) == nil
end

local Promise = {
	Error = Error,
	Status = makeEnum("Promise.Status", {"Started", "Resolved", "Rejected", "Cancelled"}),
	_getTime = os.clock,
	_timeEvent = game:GetService("RunService").Heartbeat,
	TEST = false,
}

Promise.prototype = {}
Promise.__index = Promise.prototype

--[[
	Constructs a new Promise with the given initializing callback.

	This is generally only called when directly wrapping a non-promise API into
	a promise-based version.

	The callback will receive 'resolve' and 'reject' methods, used to start
	invoking the promise chain.

	Second parameter, parent, is used internally for tracking the "parent" in a
	promise chain. External code shouldn't need to worry about this.
]]
function Promise._new(traceback, callback, parent)
	if parent ~= nil and not Promise.Is(parent) then
		error("Argument #2 to Promise.new must be a promise or nil", 2)
	end

	local self = {
		-- Used to locate where a promise was created
		_source = traceback,

		_status = Promise.Status.Started,

		-- A table containing a list of all results, whether success or failure.
		-- Only valid if _status is set to something besides Started
		_values = nil,

		-- Lua doesn't like sparse arrays very much, so we explicitly store the
		-- length of _values to handle middle nils.
		_valuesLength = -1,

		-- Tracks if this Promise has no error observers..
		_unhandledRejection = true,

		-- Queues representing functions we should invoke when we update!
		_queuedResolve = {},
		_queuedReject = {},
		_queuedFinally = {},

		-- The function to run when/if this promise is cancelled.
		_cancellationHook = nil,

		-- The "parent" of this promise in a promise chain. Required for
		-- cancellation propagation upstream.
		_parent = parent,

		-- Consumers are Promises that have chained onto this one.
		-- We track them for cancellation propagation downstream.
		_consumers = setmetatable({}, MODE_KEY_METATABLE),
	}

	if parent and parent._status == Promise.Status.Started then
		parent._consumers[self] = true
	end

	setmetatable(self, Promise)

	local function resolve(...)
		self:Resolve(...)
	end

	local function reject(...)
		self:Reject(...)
	end

	local function onCancel(cancellationHook)
		if cancellationHook then
			if self._status == Promise.Status.Cancelled then
				cancellationHook()
			else
				self._cancellationHook = cancellationHook
			end
		end

		return self._status == Promise.Status.Cancelled
	end

	local thread = coroutine.create(function()
		local ok, _, result = runExecutor(
			self._source,
			callback,
			resolve,
			reject,
			onCancel
		)

		if not ok then
			reject(result[1])
		end
	end)

	coroutine.resume(thread)
	return self
end

local NOOP = function() end

function Promise.new(executor)
	return Promise._new(debug.traceback(nil, 2), executor or NOOP)
end

function Promise:__tostring()
	return string.format("Promise(%s)", self._status)
end

--[[
	Promise.new, except pcall on a new thread is automatic.
]]
function Promise.Defer(callback)
	local traceback = debug.traceback(nil, 2)
	local promise
	promise = Promise._new(traceback, function(resolve, reject, onCancel)
		local connection
		connection = Promise._timeEvent:Connect(function()
			connection:Disconnect()
			local ok, _, result = runExecutor(traceback, callback, resolve, reject, onCancel)

			if not ok then
				reject(result[1])
			end
		end)
	end)

	return promise
end

-- Backwards compatibility
Promise.Async = Promise.Defer

--[[
	Create a promise that represents the immediately resolved value.
]]
function Promise.Resolve(...)
	local length, values = pack(...)
	return Promise._new(debug.traceback(nil, 2), function(resolve)
		resolve(table.unpack(values, 1, length))
	end)
end

--[[
	Create a promise that represents the immediately rejected value.
]]
function Promise.Reject(...)
	local length, values = pack(...)
	return Promise._new(debug.traceback(nil, 2), function(_, reject)
		reject(table.unpack(values, 1, length))
	end)
end

--[[
	Runs a non-promise-returning function as a Promise with the
  given arguments.
]]
function Promise._try(traceback, callback, ...)
	local valuesLength, values = pack(...)

	return Promise._new(traceback, function(resolve)
		resolve(callback(table.unpack(values, 1, valuesLength)))
	end)
end

--[[
	Begins a Promise chain, turning synchronous errors into rejections.
]]
function Promise.Try(...)
	return Promise._try(debug.traceback(nil, 2), ...)
end

--[[
	Returns a new promise that:
		* is resolved when all input promises resolve
		* is rejected if ANY input promises reject
]]
function Promise._all(traceback, promises, amount)
	if type(promises) ~= "table" then
		error(string.format(ERROR_NON_LIST, "Promise.All"), 3)
	end

	-- We need to check that each value is a promise here so that we can produce
	-- a proper error rather than a rejected promise with our error.
	for i, promise in ipairs(promises) do
		if not Promise.Is(promise) then
			error(string.format(ERROR_NON_PROMISE_IN_LIST, "Promise.All", tostring(i)), 3)
		end
	end

	-- If there are no values then return an already resolved promise.
	if #promises == 0 or amount == 0 then
		return Promise.Resolve {}
	end

	return Promise._new(traceback, function(resolve, reject, onCancel)
		-- An array to contain our resolved values from the given promises.
		local resolvedValues = {}
		local newPromises = {}

		-- Keep a count of resolved promises because just checking the resolved
		-- values length wouldn't account for promises that resolve with nil.
		local resolvedCount = 0
		local rejectedCount = 0
		local done = false

		local function cancel()
			for _, promise in ipairs(newPromises) do
				promise:Cancel()
			end
		end

		-- Called when a single value is resolved and resolves if all are done.
		local function resolveOne(i, ...)
			if done then
				return
			end

			resolvedCount += 1

			if amount == nil then
				resolvedValues[i] = ...
			else
				resolvedValues[resolvedCount] = ...
			end

			if resolvedCount >= (amount or #promises) then
				done = true
				resolve(resolvedValues)
				cancel()
			end
		end

		onCancel(cancel)

		-- We can assume the values inside `promises` are all promises since we
		-- checked above.
		for i, promise in ipairs(promises) do
			newPromises[i] = promise:Then(function(...)
				resolveOne(i, ...)
			end, function(...)
				rejectedCount += 1

				if amount == nil or #promises - rejectedCount < amount then
					cancel()
					done = true

					reject(...)
				end
			end)
		end

		if done then
			cancel()
		end
	end)
end

function Promise.All(promises)
	return Promise._all(debug.traceback(nil, 2), promises)
end

function Promise.Some(promises, amount)
	assert(type(amount) == "number", "Bad argument #2 to Promise.Some: must be a number")

	return Promise._all(debug.traceback(nil, 2), promises, amount)
end

function Promise.Any(promises)
	return Promise._all(debug.traceback(nil, 2), promises, 1):Then(function(values)
		return values[1]
	end)
end

function Promise.AllSettled(promises)
	if type(promises) ~= "table" then
		error(string.format(ERROR_NON_LIST, "Promise.AllSettled"), 2)
	end

	-- We need to check that each value is a promise here so that we can produce
	-- a proper error rather than a rejected promise with our error.
	for i, promise in ipairs(promises) do
		if not Promise.Is(promise) then
			error(string.format(ERROR_NON_PROMISE_IN_LIST, "Promise.AllSettled", tostring(i)), 2)
		end
	end

	-- If there are no values then return an already resolved promise.
	if #promises == 0 then
		return Promise.Resolve {}
	end

	return Promise._new(debug.traceback(nil, 2), function(resolve, _, onCancel)
		-- An array to contain our resolved values from the given promises.
		local fates = {}
		local newPromises = {}

		-- Keep a count of resolved promises because just checking the resolved
		-- values length wouldn't account for promises that resolve with nil.
		local finishedCount = 0

		-- Called when a single value is resolved and resolves if all are done.
		local function resolveOne(i, ...)
			finishedCount += 1

			fates[i] = ...

			if finishedCount >= #promises then
				resolve(fates)
			end
		end

		onCancel(function()
			for _, promise in ipairs(newPromises) do
				promise:Cancel()
			end
		end)

		-- We can assume the values inside `promises` are all promises since we
		-- checked above.
		for i, promise in ipairs(promises) do
			newPromises[i] = promise:Finally(function(...)
				resolveOne(i, ...)
			end)
		end
	end)
end

--[[
	Races a set of Promises and returns the first one that resolves,
	cancelling the others.
]]
function Promise.Race(promises)
	assert(type(promises) == "table", string.format(ERROR_NON_LIST, "Promise.Race"))

	for i, promise in ipairs(promises) do
		assert(Promise.Is(promise), string.format(ERROR_NON_PROMISE_IN_LIST, "Promise.Race", tostring(i)))
	end

	return Promise._new(debug.traceback(nil, 2), function(resolve, reject, onCancel)
		local newPromises = {}
		local finished = false

		local function cancel()
			for _, promise in ipairs(newPromises) do
				promise:Cancel()
			end
		end

		local function finalize(callback)
			return function(...)
				cancel()
				finished = true
				return callback(...)
			end
		end

		if onCancel(finalize(reject)) then
			return
		end

		for i, promise in ipairs(promises) do
			newPromises[i] = promise:Then(finalize(resolve), finalize(reject))
		end

		if finished then
			cancel()
		end
	end)
end

--[[
	Iterates serially over the given an array of values, calling the predicate callback on each before continuing.
	If the predicate returns a Promise, we wait for that Promise to resolve before continuing to the next item
	in the array. If the Promise the predicate returns rejects, the Promise from Promise.each is also rejected with
	the same value.

	Returns a Promise containing an array of the return values from the predicate for each item in the original list.
]]
function Promise.Each(list, predicate)
	assert(type(list) == "table", string.format(ERROR_NON_LIST, "Promise.Each"))
	assert(type(predicate) == "function", string.format(ERROR_NON_FUNCTION, "Promise.Each"))

	return Promise._new(debug.traceback(nil, 2), function(resolve, reject, onCancel)
		local results = {}
		local promisesToCancel = {}

		local cancelled = false

		local function cancel()
			for _, promiseToCancel in ipairs(promisesToCancel) do
				promiseToCancel:Cancel()
			end
		end

		onCancel(function()
			cancelled = true
			cancel()
		end)

		-- We need to preprocess the list of values and look for Promises.
		-- If we find some, we must register our andThen calls now, so that those Promises have a consumer
		-- from us registered. If we don't do this, those Promises might get cancelled by something else
		-- before we get to them in the series because it's not possible to tell that we plan to use it
		-- unless we indicate it here.

		local preprocessedList = {}

		for index, value in ipairs(list) do
			if Promise.Is(value) then
				if value:GetStatus() == Promise.Status.Cancelled then
					cancel()
					return reject(Error.new({
						error = "Promise is cancelled",
						kind = Error.Kind.AlreadyCancelled,
						context = string.format(
							"The Promise that was part of the array at index %d passed into Promise.Each was already cancelled when Promise.Each began.\n\nThat Promise was created at:\n\n%s",
							index,
							value._source
						),
					}))
				elseif value:GetStatus() == Promise.Status.Rejected then
					cancel()
					return reject(select(2, value:Wait()))
				end

				-- Chain a new Promise from this one so we only cancel ours
				local ourPromise = value:Then(function(...)
					return ...
				end)

				table.insert(promisesToCancel, ourPromise)
				preprocessedList[index] = ourPromise
			else
				preprocessedList[index] = value
			end
		end

		for index, value in ipairs(preprocessedList) do
			if Promise.Is(value) then
				local success
				success, value = value:Wait()

				if not success then
					cancel()
					return reject(value)
				end
			end

			if cancelled then
				return
			end

			local predicatePromise = Promise.Resolve(predicate(value, index))
			table.insert(promisesToCancel, predicatePromise)
			local success, result = predicatePromise:Wait()

			if not success then
				cancel()
				return reject(result)
			end

			results[index] = result
		end

		resolve(results)
	end)
end

--[[
	Is the given object a Promise instance?
]]
function Promise.Is(object)
	if type(object) ~= "table" then
		return false
	end

	local objectMetatable = getmetatable(object)

	if objectMetatable == Promise then
		-- The Promise came from this library.
		return true
	elseif objectMetatable == nil then
		-- No metatable, but we should still chain onto tables with andThen methods
		return type(object.Then) == "function"
	elseif
		type(objectMetatable) == "table"
		and type(rawget(objectMetatable, "__index")) == "table"
		and type(rawget(rawget(objectMetatable, "__index"), "Then")) == "function"
	then
		-- Maybe this came from a different or older Promise library.
		return true
	end

	return false
end

--[[
	Converts a yielding function into a Promise-returning one.
]]
function Promise.Promisify(callback)
	return function(...)
		return Promise._try(debug.traceback(nil, 2), callback, ...)
	end
end

--[[
	Creates a Promise that resolves after given number of seconds.
]]
do
	-- uses a sorted doubly linked list (queue) to achieve O(1) remove operations and O(n) for insert

	-- the initial node in the linked list
	local first
	local connection

	function Promise.Delay(seconds)
		assert(type(seconds) == "number", "Bad argument #1 to Promise.Delay, must be a number.")
		-- If seconds is -INF, INF, NaN, or less than 1 / 60, assume seconds is 1 / 60.
		-- This mirrors the behavior of wait()
		if not (seconds >= 1 / 60) or seconds == math.huge then
			seconds = 1 / 60
		end

		return Promise._new(debug.traceback(nil, 2), function(resolve, _, onCancel)
			local startTime = os.clock()
			local endTime = startTime + seconds

			local node = {
				resolve = resolve,
				startTime = startTime,
				endTime = endTime,
			}

			if connection == nil then -- first is nil when connection is nil
				first = node
				connection = Promise._timeEvent:Connect(function()
					local threadStart = os.clock()

					while first ~= nil and first.endTime < threadStart do
						local current = first
						first = current.next

						if first == nil then
							connection:Disconnect()
							connection = nil
						else
							first.previous = nil
						end

						current.resolve(os.clock() - current.startTime)
					end
				end)
			else -- first is non-nil
				if first.endTime < endTime then -- if `node` should be placed after `first`
					-- we will insert `node` between `current` and `next`
					-- (i.e. after `current` if `next` is nil)
					local current = first
					local next = current.next

					while next ~= nil and next.endTime < endTime do
						current = next
						next = current.next
					end

					-- `current` must be non-nil, but `next` could be `nil` (i.e. last item in list)
					current.next = node
					node.previous = current

					if next ~= nil then
						node.next = next
						next.previous = node
					end
				else
					-- set `node` to `first`
					node.next = first
					first.previous = node
					first = node
				end
			end

			onCancel(function()
				-- remove node from queue
				local next = node.next

				if first == node then
					if next == nil then -- if `node` is the first and last
						connection:Disconnect()
						connection = nil
					else -- if `node` is `first` and not the last
						next.previous = nil
					end

					first = next
				else
					local previous = node.previous
					-- since `node` is not `first`, then we know `previous` is non-nil
					previous.next = next

					if next ~= nil then
						next.previous = previous
					end
				end
			end)
		end)
	end
end

--[[
	Rejects the promise after `seconds` seconds.
]]
function Promise.prototype:Timeout(seconds, rejectionValue)
	local traceback = debug.traceback(nil, 2)
	
	local array = table.create(2)
	array[1], array[2] = Promise.Delay(seconds):Then(function()
		return Promise.Reject(rejectionValue == nil and Error.new({
			kind = Error.Kind.TimedOut,
			error = "Timed out",
			context = string.format(
				"Timeout of %d seconds exceeded.\n:timeout() called at:\n\n%s",
				seconds,
				traceback
			),
		}) or rejectionValue)
	end), self

	return Promise.Race(array)
end

function Promise.prototype:GetStatus()
	return self._status
end

--[[
	Creates a new promise that receives the result of this promise.

	The given callbacks are invoked depending on that result.
]]
function Promise.prototype:_andThen(traceback, successHandler, failureHandler)
	self._unhandledRejection = false

	-- Create a new promise to follow this part of the chain
	return Promise._new(traceback, function(resolve, reject)
		-- Our default callbacks just pass values onto the next promise.
		-- This lets success and failure cascade correctly!

		local successCallback = resolve
		if successHandler then
			successCallback = createAdvancer(
				traceback,
				successHandler,
				resolve,
				reject
			)
		end

		local failureCallback = reject
		if failureHandler then
			failureCallback = createAdvancer(
				traceback,
				failureHandler,
				resolve,
				reject
			)
		end

		if self._status == Promise.Status.Started then
			-- If we haven't resolved yet, put ourselves into the queue
			table.insert(self._queuedResolve, successCallback)
			table.insert(self._queuedReject, failureCallback)
		elseif self._status == Promise.Status.Resolved then
			-- This promise has already resolved! Trigger success immediately.
			successCallback(table.unpack(self._values, 1, self._valuesLength))
		elseif self._status == Promise.Status.Rejected then
			-- This promise died a terrible death! Trigger failure immediately.
			failureCallback(table.unpack(self._values, 1, self._valuesLength))
		elseif self._status == Promise.Status.Cancelled then
			-- We don't want to call the success handler or the failure handler,
			-- we just reject this promise outright.
			reject(Error.new({
				error = "Promise is cancelled",
				kind = Error.Kind.AlreadyCancelled,
				context = "Promise created at\n\n" .. traceback,
			}))
		end
	end, self)
end

function Promise.prototype:Then(successHandler, failureHandler)
	assert(
		successHandler == nil or type(successHandler) == "function",
		string.format(ERROR_NON_FUNCTION, "Promise:Then")
	)

	assert(
		failureHandler == nil or type(failureHandler) == "function",
		string.format(ERROR_NON_FUNCTION, "Promise:Then")
	)

	return self:_andThen(debug.traceback(nil, 2), successHandler, failureHandler)
end

--[[
	Used to catch any errors that may have occurred in the promise.
]]
function Promise.prototype:Catch(failureCallback)
	assert(
		failureCallback == nil or type(failureCallback) == "function",
		string.format(ERROR_NON_FUNCTION, "Promise:Catch")
	)

	return self:_andThen(debug.traceback(nil, 2), nil, failureCallback)
end

--[[
	Like andThen, but the value passed into the handler is also the
	value returned from the handler.
]]
function Promise.prototype:Tap(tapCallback)
	assert(type(tapCallback) == "function", string.format(ERROR_NON_FUNCTION, "Promise:Tap"))
	return self:_andThen(debug.traceback(nil, 2), function(...)
		local callbackReturn = tapCallback(...)

		if Promise.Is(callbackReturn) then
			local length, values = pack(...)
			return callbackReturn:Then(function()
				return table.unpack(values, 1, length)
			end)
		end

		return ...
	end)
end

--[[
	Calls a callback on `andThen` with specific arguments.
]]
function Promise.prototype:ThenCall(callback, ...)
	assert(type(callback) == "function", string.format(ERROR_NON_FUNCTION, "Promise:AndThenCall"))
	local length, values = pack(...)
	return self:_andThen(debug.traceback(nil, 2), function()
		return callback(table.unpack(values, 1, length))
	end)
end

--[[
	Shorthand for an andThen handler that returns the given value.
]]
function Promise.prototype:ThenReturn(...)
	local length, values = pack(...)
	return self:_andThen(debug.traceback(nil, 2), function()
		return table.unpack(values, 1, length)
	end)
end

--[[
	Cancels the promise, disallowing it from rejecting or resolving, and calls
	the cancellation hook if provided.
]]
function Promise.prototype:Cancel()
	if self._status ~= Promise.Status.Started then
		return
	end

	self._status = Promise.Status.Cancelled
	if self._cancellationHook then
		self._cancellationHook()
	end

	if self._parent then
		self._parent:_consumerCancelled(self)
	end

	for child in next, self._consumers do
		child:Cancel()
	end

	self:_finalize()
end

--[[
	Used to decrease the number of consumers by 1, and if there are no more,
	cancel this promise.
]]
function Promise.prototype:_consumerCancelled(consumer)
	if self._status ~= Promise.Status.Started then
		return
	end

	self._consumers[consumer] = nil
	if next(self._consumers) == nil then
		self:Cancel()
	end
end

--[[
	Used to set a handler for when the promise resolves, rejects, or is
	cancelled. Returns a new promise chained from this promise.
]]
function Promise.prototype:_finally(traceback, finallyHandler, onlyOk)
	if not onlyOk then
		self._unhandledRejection = false
	end

	-- Return a promise chained off of this promise
	return Promise._new(traceback, function(resolve, reject)
		local finallyCallback = resolve
		if finallyHandler then
			finallyCallback = createAdvancer(
				traceback,
				finallyHandler,
				resolve,
				reject
			)
		end

		if onlyOk then
			local callback = finallyCallback
			finallyCallback = function(...)
				if self._status == Promise.Status.Rejected then
					return resolve(self)
				end

				return callback(...)
			end
		end

		if self._status == Promise.Status.Started then
			-- The promise is not settled, so queue this.
			table.insert(self._queuedFinally, finallyCallback)
		else
			-- The promise already settled or was cancelled, run the callback now.
			finallyCallback(self._status)
		end
	end, self)
end

function Promise.prototype:Finally(finallyHandler)
	assert(
		finallyHandler == nil or type(finallyHandler) == "function",
		string.format(ERROR_NON_FUNCTION, "Promise:Finally")
	)

	return self:_finally(debug.traceback(nil, 2), finallyHandler)
end

--[[
	Calls a callback on `finally` with specific arguments.
]]
function Promise.prototype:FinallyCall(callback, ...)
	assert(type(callback) == "function", string.format(ERROR_NON_FUNCTION, "Promise:FinallyCall"))
	local length, values = pack(...)
	return self:_finally(debug.traceback(nil, 2), function()
		return callback(table.unpack(values, 1, length))
	end)
end

--[[
	Shorthand for a finally handler that returns the given value.
]]
function Promise.prototype:FinallyReturn(...)
	local length, values = pack(...)
	return self:_finally(debug.traceback(nil, 2), function()
		return table.unpack(values, 1, length)
	end)
end

--[[
	Similar to finally, except rejections are propagated through it.
]]
function Promise.prototype:Done(finallyHandler)
	assert(
		finallyHandler == nil or type(finallyHandler) == "function",
		string.format(ERROR_NON_FUNCTION, "Promise:Done")
	)

	return self:_finally(debug.traceback(nil, 2), finallyHandler, true)
end

--[[
	Calls a callback on `done` with specific arguments.
]]
function Promise.prototype:DoneCall(callback, ...)
	assert(type(callback) == "function", string.format(ERROR_NON_FUNCTION, "Promise:DoneCall"))
	local length, values = pack(...)
	return self:_finally(debug.traceback(nil, 2), function()
		return callback(table.unpack(values, 1, length))
	end, true)
end

--[[
	Shorthand for a done handler that returns the given value.
]]
function Promise.prototype:DoneReturn(...)
	local length, values = pack(...)
	return self:_finally(debug.traceback(nil, 2), function()
		return table.unpack(values, 1, length)
	end, true)
end

--[[
	Yield until the promise is completed.

	This matches the execution model of normal Roblox functions.
]]
function Promise.prototype:WaitStatus()
	self._unhandledRejection = false

	if self._status == Promise.Status.Started then
		local bindable = Instance.new("BindableEvent")

		self:Finally(function()
			bindable:Fire()
		end)

		bindable.Event:Wait()
		bindable:Destroy()
	end

	if self._status == Promise.Status.Resolved then
		return self._status, table.unpack(self._values, 1, self._valuesLength)
	elseif self._status == Promise.Status.Rejected then
		return self._status, table.unpack(self._values, 1, self._valuesLength)
	end

	return self._status
end

local function awaitHelper(status, ...)
	return status == Promise.Status.Resolved, ...
end

--[[
	Calls awaitStatus internally, returns (isResolved, values...)
]]
function Promise.prototype:Wait()
	return awaitHelper(self:WaitStatus())
end

local function expectHelper(status, ...)
	if status ~= Promise.Status.Resolved then
		error((...) == nil and "Expected Promise rejected with no value." or (...), 3)
	end

	return ...
end

--[[
	Calls await and only returns if the Promise resolves.
	Throws if the Promise rejects or gets cancelled.
]]
function Promise.prototype:Expect()
	return expectHelper(self:WaitStatus())
end

-- Backwards compatibility
Promise.prototype.WaitValue = Promise.prototype.Expect

--[[
	Intended for use in tests.

	Similar to await(), but instead of yielding if the promise is unresolved,
	_unwrap will throw. This indicates an assumption that a promise has
	resolved.
]]
function Promise.prototype:_unwrap()
	if self._status == Promise.Status.Started then
		error("Promise has not resolved or rejected.", 2)
	end

	local success = self._status == Promise.Status.Resolved
	return success, table.unpack(self._values, 1, self._valuesLength)
end

function Promise.prototype:Resolve(...)
	if self._status ~= Promise.Status.Started then
		if Promise.Is((...)) then
			(...):_consumerCancelled(self)
		end

		return
	end

	-- If the resolved value was a Promise, we chain onto it!
	if Promise.Is((...)) then
		-- Without this warning, arguments sometimes mysteriously disappear
		if select("#", ...) > 1 then
			warn(string.format(
				"When returning a Promise from Then, extra arguments are " ..
				"discarded! See:\n\n%s",
				self._source
			))
		end

		local chainedPromise = ...

		local promise = chainedPromise:Then(function(...)
			self:Resolve(...)
		end, function(...)
			local maybeRuntimeError = chainedPromise._values[1]

			-- Backwards compatibility < v2
			if chainedPromise._error then
				maybeRuntimeError = Error.new({
					error = chainedPromise._error,
					kind = Error.Kind.ExecutionError,
					context = "[No stack trace available as this Promise originated from an older version of the Promise library (< v2)]",
				})
			end

			if Error.isKind(maybeRuntimeError, Error.Kind.ExecutionError) then
				return self:Reject(maybeRuntimeError:extend({
					error = "This Promise was chained to a Promise that errored.",
					trace = "",
					context = string.format(
						"The Promise at:\n\n%s\n...Rejected because it was chained to the following Promise, which encountered an error:\n",
						self._source
					),
				}))
			end

			self:Reject(...)
		end)

		if promise._status == Promise.Status.Cancelled then
			self:Cancel()
		elseif promise._status == Promise.Status.Started then
			-- Adopt ourselves into promise for cancellation propagation.
			self._parent = promise
			promise._consumers[self] = true
		end

		return
	end

	self._status = Promise.Status.Resolved
	self._valuesLength, self._values = pack(...)

	-- We assume that these callbacks will not throw errors.
	for _, callback in ipairs(self._queuedResolve) do
		local thread = coroutine.create(callback)
		coroutine.resume(thread, ...)
	end

	self:_finalize()
end

local function RejectFunction(self, err)
	Promise._timeEvent:Wait()

	-- Someone observed the error, hooray!
	if not self._unhandledRejection then
		return
	end

	-- Build a reasonable message
	local message = string.format(
		"Unhandled Promise rejection:\n\n%s\n\n%s",
		err,
		self._source
	)

	if Promise.TEST then
		-- Don't spam output when we're running tests.
		return
	end

	warn(message)
end

function Promise.prototype:Reject(...)
	if self._status ~= Promise.Status.Started then
		return
	end

	self._status = Promise.Status.Rejected
	self._valuesLength, self._values = pack(...)

	-- If there are any rejection handlers, call those!
	if not isEmpty(self._queuedReject) then
		-- We assume that these callbacks will not throw errors.
		for _, callback in ipairs(self._queuedReject) do
			local thread = coroutine.create(callback)
			coroutine.resume(thread, ...)
		end
	else
		-- At this point, no one was able to observe the error.
		-- An error handler might still be attached if the error occurred
		-- synchronously. We'll wait one tick, and if there are still no
		-- observers, then we should put a message in the console.

		local thread = coroutine.create(RejectFunction)
		coroutine.resume(thread, self, tostring((...)))
	end

	self:_finalize()
end

--[[
	Calls any :finally handlers. We need this to be a separate method and
	queue because we must call all of the finally callbacks upon a success,
	failure, *and* cancellation.
]]
function Promise.prototype:_finalize()
	for _, callback in ipairs(self._queuedFinally) do
		-- Purposefully not passing values to callbacks here, as it could be the
		-- resolved values, or rejected errors. If the developer needs the values,
		-- they should use :andThen or :catch explicitly.
		local thread = coroutine.create(callback)
		coroutine.resume(thread, self._status)
	end

	self._queuedFinally = nil
	self._queuedReject = nil
	self._queuedResolve = nil

	-- Clear references to other Promises to allow gc
	if not Promise.TEST then
		self._parent = nil
		self._consumers = nil
	end
end

--[[
	Chains a Promise from this one that is resolved if this Promise is
	resolved, and rejected if it is not resolved.
]]
function Promise.prototype:Now(rejectionValue)
	local traceback = debug.traceback(nil, 2)
	if self._status == Promise.Status.Resolved then
		return self:_andThen(traceback, function(...)
			return ...
		end)
	else
		return Promise.Reject(rejectionValue == nil and Error.new({
			kind = Error.Kind.NotResolvedInTime,
			error = "This Promise was not resolved in time for :Now()",
			context = ":Now() was called at:\n\n" .. traceback,
		}) or rejectionValue)
	end
end

--[[
	Retries a Promise-returning callback N times until it succeeds.
]]
function Promise.Retry(callback, times, ...)
	assert(type(callback) == "function", "Parameter #1 to Promise.Retry must be a function")
	assert(type(times) == "number", "Parameter #2 to Promise.Retry must be a number")

	local args, length = {...}, select("#", ...)

	return Promise.Resolve(callback(...)):Catch(function(...)
		if times > 0 then
			return Promise.Retry(callback, times - 1, table.unpack(args, 1, length))
		else
			return Promise.Reject(...)
		end
	end)
end

--[[
	Converts an event into a Promise with an optional predicate
]]
function Promise.FromEvent(event, predicate)
	predicate = predicate or function()
		return true
	end

	return Promise._new(debug.traceback(nil, 2), function(resolve, _, onCancel)
		local connection
		local shouldDisconnect = false

		local function disconnect()
			connection:Disconnect()
			connection = nil
		end

		-- We use shouldDisconnect because if the callback given to Connect is called before
		-- Connect returns, connection will still be nil. This happens with events that queue up
		-- events when there's nothing connected, such as RemoteEvents

		connection = event:Connect(function(...)
			local callbackValue = predicate(...)

			if callbackValue == true then
				resolve(...)

				if connection then
					disconnect()
				else
					shouldDisconnect = true
				end
			elseif type(callbackValue) ~= "boolean" then
				error("Promise.FromEvent predicate should always return a boolean")
			end
		end)

		if shouldDisconnect and connection then
			return disconnect()
		end

		onCancel(disconnect)
	end)
end

return Promise