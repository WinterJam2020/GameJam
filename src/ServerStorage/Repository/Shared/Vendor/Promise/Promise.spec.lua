--!nocheck
local function expect(_Message, _Function) end
local function it(_Message, _Function) end
local function describe(_Message, _Function) end

return function()
	local Promise = require(script.Parent)
	Promise.TEST = true

	local timeEvent = Instance.new("BindableEvent")
	Promise._timeEvent = timeEvent.Event

	local advanceTime do
		local injectedPromiseTime = 0
		local ONE_SIXTY = 1/60

		Promise._getTime = function()
			return injectedPromiseTime
		end

		function advanceTime(delta)
			delta = delta or ONE_SIXTY

			injectedPromiseTime += delta
			timeEvent:Fire(delta)
		end
	end

	local function pack(...)
		local len = select("#", ...)

		return len, { ... }
	end

	describe("Promise.Status", function()
		it("should error if indexing nil value", function()
			expect(function()
				local _ = Promise.Status.wrong
			end).to.throw()
		end)
	end)

	describe("Promise.new", function()
		it("should instantiate with a callback", function()
			local promise = Promise.new(function() end)

			expect(promise).to.be.ok()
		end)

		it("should invoke the given callback with resolve and reject", function()
			local callCount = 0
			local resolveArg
			local rejectArg

			local promise = Promise.new(function(resolve, reject)
				callCount += 1
				resolveArg = resolve
				rejectArg = reject
			end)

			expect(promise).to.be.ok()

			expect(callCount).to.equal(1)
			expect(resolveArg).to.be.a("function")
			expect(rejectArg).to.be.a("function")
			expect(promise:GetStatus()).to.equal(Promise.Status.Started)
		end)

		it("should resolve promises on resolve()", function()
			local callCount = 0

			local promise = Promise.new(function(resolve)
				callCount += 1
				resolve()
			end)

			expect(promise).to.be.ok()
			expect(callCount).to.equal(1)
			expect(promise:GetStatus()).to.equal(Promise.Status.Resolved)
		end)

		it("should reject promises on reject()", function()
			local callCount = 0

			local promise = Promise.new(function(_, reject)
				callCount += 1
				reject()
			end)

			expect(promise).to.be.ok()
			expect(callCount).to.equal(1)
			expect(promise:GetStatus()).to.equal(Promise.Status.Rejected)
		end)

		it("should reject on error in callback", function()
			local callCount = 0

			local promise = Promise.new(function()
				callCount += 1
				error("hahah")
			end)

			expect(promise).to.be.ok()
			expect(callCount).to.equal(1)
			expect(promise:GetStatus()).to.equal(Promise.Status.Rejected)
			expect(string.find(tostring(promise._values[1]), "hahah")).to.be.ok()

			-- Loosely check for the pieces of the stack trace we expect
			expect(string.find(tostring(promise._values[1]), "Promise2.spec")).to.be.ok()
			expect(string.find(tostring(promise._values[1]), "runExecutor")).to.be.ok()
		end)

		it("should work with C functions", function()
			expect(function()
				Promise.new(tick):Then(tick)
			end).to.never.throw()
		end)

		it("should have a nice tostring", function()
			expect(string.gmatch(tostring(Promise.Resolve()), "Promise(Resolved)")).to.be.ok()
		end)

		it("should allow yielding", function()
			local bindable = Instance.new("BindableEvent")
			local promise = Promise.new(function(resolve)
				bindable.Event:Wait()
				resolve(5)
			end)

			expect(promise:GetStatus()).to.equal(Promise.Status.Started)
			bindable:Fire()
			expect(promise:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(promise._values[1]).to.equal(5)
		end)

		it("should preserve stack traces of resolve-chained promises", function()
			local function nestedCall(text)
				error(text)
			end

			local promise = Promise.new(function(resolve)
				resolve(Promise.new(function()
					nestedCall("sample text")
				end))
			end)

			expect(promise:GetStatus()).to.equal(Promise.Status.Rejected)

			local trace = tostring(promise._values[1])
			expect(string.find(trace, "sample text")).to.be.ok()
			expect(string.find(trace, "nestedCall")).to.be.ok()
			expect(string.find(trace, "runExecutor")).to.be.ok()
			expect(string.find(trace, "runPlanNode")).to.be.ok()
			expect(string.find(trace, "...Rejected because it was chained to the following Promise, which encountered an error:")).to.be.ok()
		end)

		it("should report errors from Promises with _error (< v2)", function()
			local oldPromise = Promise.Reject()
			oldPromise._error = "Sample error"

			local newPromise = Promise.Resolve():ThenReturn(oldPromise)

			expect(newPromise:GetStatus()).to.equal(Promise.Status.Rejected)

			local trace = tostring(newPromise._values[1])
			expect(string.find(trace, "Sample error")).to.be.ok()
			expect(string.find(trace, "...Rejected because it was chained to the following Promise, which encountered an error:")).to.be.ok()
			expect(string.find(trace, "%[No stack trace available")).to.be.ok()
		end)
	end)

	describe("Promise.Defer", function()
		it("should execute after the time event", function()
			local callCount = 0
			local promise = Promise.Defer(function(resolve, reject, onCancel, nothing)
				expect(type(resolve)).to.equal("function")
				expect(type(reject)).to.equal("function")
				expect(type(onCancel)).to.equal("function")
				expect(type(nothing)).to.equal("nil")

				callCount += 1

				resolve("foo")
			end)

			expect(callCount).to.equal(0)
			expect(promise:GetStatus()).to.equal(Promise.Status.Started)

			advanceTime()
			expect(callCount).to.equal(1)
			expect(promise:GetStatus()).to.equal(Promise.Status.Resolved)

			advanceTime()
			expect(callCount).to.equal(1)
		end)
	end)

	describe("Promise.Delay", function()
		it("should schedule promise resolution", function()
			local promise = Promise.Delay(1)

			expect(promise:GetStatus()).to.equal(Promise.Status.Started)

			advanceTime()
			expect(promise:GetStatus()).to.equal(Promise.Status.Started)

			advanceTime(1)
			expect(promise:GetStatus()).to.equal(Promise.Status.Resolved)
		end)

		it("should allow for delays to be cancelled", function()
			local promise = Promise.Delay(2)

			Promise.Delay(1):Then(function()
			    promise:Cancel()
			end)

			expect(promise:GetStatus()).to.equal(Promise.Status.Started)
			advanceTime()
			expect(promise:GetStatus()).to.equal(Promise.Status.Started)
			advanceTime(1)
			expect(promise:GetStatus()).to.equal(Promise.Status.Cancelled)
			advanceTime(1)
		end)
	end)

	describe("Promise.Resolve", function()
		it("should immediately resolve with a value", function()
			local promise = Promise.Resolve(5, 6)

			expect(promise).to.be.ok()
			expect(promise:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(promise._values[1]).to.equal(5)
			expect(promise._values[2]).to.equal(6)
		end)

		it("should chain onto passed promises", function()
			local promise = Promise.Resolve(Promise.new(function(_, reject)
				reject(7)
			end))

			expect(promise).to.be.ok()
			expect(promise:GetStatus()).to.equal(Promise.Status.Rejected)
			expect(promise._values[1]).to.equal(7)
		end)
	end)

	describe("Promise.Reject", function()
		it("should immediately reject with a value", function()
			local promise = Promise.Reject(6, 7)

			expect(promise).to.be.ok()
			expect(promise:GetStatus()).to.equal(Promise.Status.Rejected)
			expect(promise._values[1]).to.equal(6)
			expect(promise._values[2]).to.equal(7)
		end)

		it("should pass a promise as-is as an error", function()
			local innerPromise = Promise.new(function(resolve)
				resolve(6)
			end)

			local promise = Promise.Reject(innerPromise)

			expect(promise).to.be.ok()
			expect(promise:GetStatus()).to.equal(Promise.Status.Rejected)
			expect(promise._values[1]).to.equal(innerPromise)
		end)
	end)

	describe("Promise:Then", function()
		it("should allow yielding", function()
			local bindable = Instance.new("BindableEvent")
			local promise = Promise.Resolve():Then(function()
				bindable.Event:Wait()
				return 5
			end)

			expect(promise:GetStatus()).to.equal(Promise.Status.Started)
			bindable:Fire()
			expect(promise:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(promise._values[1]).to.equal(5)
		end)

		it("should run Thens on a new thread", function()
			local bindable = Instance.new("BindableEvent")

			local resolve
			local parentPromise = Promise.new(function(_resolve)
				resolve = _resolve
			end)

			local deadlockedPromise = parentPromise:Then(function()
				bindable.Event:Wait()
				return 5
			end)

			local successfulPromise = parentPromise:Then(function()
				return "foo"
			end)

			expect(parentPromise:GetStatus()).to.equal(Promise.Status.Started)
			resolve()
			expect(successfulPromise:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(successfulPromise._values[1]).to.equal("foo")
			expect(deadlockedPromise:GetStatus()).to.equal(Promise.Status.Started)
		end)

		it("should chain onto resolved promises", function()
			local args
			local argsLength
			local callCount = 0
			local badCallCount = 0

			local promise = Promise.Resolve(5)

			local chained = promise:Then(
				function(...)
					argsLength, args = pack(...)
					callCount += 1
				end,
				function()
					badCallCount += 1
				end
			)

			expect(badCallCount).to.equal(0)

			expect(callCount).to.equal(1)
			expect(argsLength).to.equal(1)
			expect(args[1]).to.equal(5)

			expect(promise).to.be.ok()
			expect(promise:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(promise._values[1]).to.equal(5)

			expect(chained).to.be.ok()
			expect(chained).never.to.equal(promise)
			expect(chained:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(#chained._values).to.equal(0)
		end)

		it("should chain onto rejected promises", function()
			local args
			local argsLength
			local callCount = 0
			local badCallCount = 0

			local promise = Promise.Reject(5)

			local chained = promise:Then(
				function()
					badCallCount += 1
				end,
				function(...)
					argsLength, args = pack(...)
					callCount += 1
				end
			)

			expect(badCallCount).to.equal(0)

			expect(callCount).to.equal(1)
			expect(argsLength).to.equal(1)
			expect(args[1]).to.equal(5)

			expect(promise).to.be.ok()
			expect(promise:GetStatus()).to.equal(Promise.Status.Rejected)
			expect(promise._values[1]).to.equal(5)

			expect(chained).to.be.ok()
			expect(chained).never.to.equal(promise)
			expect(chained:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(#chained._values).to.equal(0)
		end)

		it("should reject on error in callback", function()
			local callCount = 0

			local promise = Promise.Resolve(1):Then(function()
				callCount += 1
				error("hahah")
			end)

			expect(promise).to.be.ok()
			expect(callCount).to.equal(1)
			expect(promise:GetStatus()).to.equal(Promise.Status.Rejected)
			expect(string.find(tostring(promise._values[1]), "hahah")).to.be.ok()

			-- Loosely check for the pieces of the stack trace we expect
			expect(string.find(tostring(promise._values[1]), "Promise2.spec")).to.be.ok()
			expect(string.find(tostring(promise._values[1]), "runExecutor")).to.be.ok()
		end)

		it("should chain onto asynchronously resolved promises", function()
			local args
			local argsLength
			local callCount = 0
			local badCallCount = 0

			local startResolution
			local promise = Promise.new(function(resolve)
				startResolution = resolve
			end)

			local chained = promise:Then(
				function(...)
					args = {...}
					argsLength = select("#", ...)
					callCount += 1
				end,
				function()
					badCallCount += 1
				end
			)

			expect(callCount).to.equal(0)
			expect(badCallCount).to.equal(0)

			startResolution(6)

			expect(badCallCount).to.equal(0)

			expect(callCount).to.equal(1)
			expect(argsLength).to.equal(1)
			expect(args[1]).to.equal(6)

			expect(promise).to.be.ok()
			expect(promise:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(promise._values[1]).to.equal(6)

			expect(chained).to.be.ok()
			expect(chained).never.to.equal(promise)
			expect(chained:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(#chained._values).to.equal(0)
		end)

		it("should chain onto asynchronously rejected promises", function()
			local args
			local argsLength
			local callCount = 0
			local badCallCount = 0

			local startResolution
			local promise = Promise.new(function(_, reject)
				startResolution = reject
			end)

			local chained = promise:Then(
				function()
					badCallCount += 1
				end,
				function(...)
					args = {...}
					argsLength = select("#", ...)
					callCount += 1
				end
			)

			expect(callCount).to.equal(0)
			expect(badCallCount).to.equal(0)

			startResolution(6)

			expect(badCallCount).to.equal(0)

			expect(callCount).to.equal(1)
			expect(argsLength).to.equal(1)
			expect(args[1]).to.equal(6)

			expect(promise).to.be.ok()
			expect(promise:GetStatus()).to.equal(Promise.Status.Rejected)
			expect(promise._values[1]).to.equal(6)

			expect(chained).to.be.ok()
			expect(chained).never.to.equal(promise)
			expect(chained:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(#chained._values).to.equal(0)
		end)

		it("should propagate errors through multiple levels", function()
			local x, y, z
			Promise.new(function(_, reject)
				reject(1, 2, 3)
			end):Then(function() end):Catch(function(a, b, c)
				x, y, z = a, b, c
			end)

			expect(x).to.equal(1)
			expect(y).to.equal(2)
			expect(z).to.equal(3)
		end)
	end)

	describe("Promise:Cancel", function()
		it("should mark promises as cancelled and not resolve or reject them", function()
			local callCount = 0
			local finallyCallCount = 0
			local promise = Promise.new(function() end):Then(function()
				callCount += 1
			end):Finally(function()
				finallyCallCount += 1
			end)

			promise:Cancel()
			promise:Cancel() -- Twice to check call counts

			expect(callCount).to.equal(0)
			expect(finallyCallCount).to.equal(1)
			expect(promise:GetStatus()).to.equal(Promise.Status.Cancelled)
		end)

		it("should call the cancellation hook once", function()
			local callCount = 0

			local promise = Promise.new(function(_, _, onCancel)
				onCancel(function()
					callCount += 1
				end)
			end)

			promise:Cancel()
			promise:Cancel() -- Twice to check call count

			expect(callCount).to.equal(1)
		end)

		it("should propagate cancellations", function()
			local promise = Promise.new(function() end)

			local consumer1 = promise:Then()
			local consumer2 = promise:Then()

			expect(promise:GetStatus()).to.equal(Promise.Status.Started)
			expect(consumer1:GetStatus()).to.equal(Promise.Status.Started)
			expect(consumer2:GetStatus()).to.equal(Promise.Status.Started)

			consumer1:Cancel()

			expect(promise:GetStatus()).to.equal(Promise.Status.Started)
			expect(consumer1:GetStatus()).to.equal(Promise.Status.Cancelled)
			expect(consumer2:GetStatus()).to.equal(Promise.Status.Started)

			consumer2:Cancel()

			expect(promise:GetStatus()).to.equal(Promise.Status.Cancelled)
			expect(consumer1:GetStatus()).to.equal(Promise.Status.Cancelled)
			expect(consumer2:GetStatus()).to.equal(Promise.Status.Cancelled)
		end)

		it("should affect downstream promises", function()
			local promise = Promise.new(function() end)
			local consumer = promise:Then()

			promise:Cancel()

			expect(consumer:GetStatus()).to.equal(Promise.Status.Cancelled)
		end)

		it("should track consumers", function()
			local pending = Promise.new(function() end)
			local p0 = Promise.Resolve()
			local p1 = p0:Finally(function()
				return pending
			end)

			local p2 = Promise.new(function(resolve)
				resolve(p1)
			end)

			local p3 = p2:Then(function() end)

			expect(p1._parent).to.never.equal(p0)
			expect(p2._parent).to.never.equal(p1)
			expect(p2._consumers[p3]).to.be.ok()
			expect(p3._parent).to.equal(p2)
		end)

		it("should cancel resolved pending promises", function()
			local p1 = Promise.new(function() end)

			local p2 = Promise.new(function(resolve)
				resolve(p1)
			end):Finally(function() end)

			p2:Cancel()

			expect(p1._status).to.equal(Promise.Status.Cancelled)
			expect(p2._status).to.equal(Promise.Status.Cancelled)
		end)
	end)

	describe("Promise:Finally", function()
		it("should be called upon resolve, reject, or cancel", function()
			local callCount = 0

			local function finally()
				callCount += 1
			end

			-- Resolved promise
			Promise.new(function(resolve)
				resolve()
			end):Finally(finally)

			-- Chained promise
			Promise.Resolve():Then(function()
			end):Finally(finally):Finally(finally)

			-- Rejected promise
			Promise.Reject():Finally(finally)

			local cancelledPromise = Promise.new(function() end):Finally(finally)
			cancelledPromise:Cancel()

			expect(callCount).to.equal(5)
		end)

		it("should be a child of the parent Promise", function()
			local p1 = Promise.new(function() end)
			local p2 = p1:Finally(function() end)

			expect(p2._parent).to.equal(p1)
			expect(p1._consumers[p2]).to.equal(true)
		end)

		it("should forward return values", function()
			local value

			Promise.Resolve():Finally(function()
				return 1
			end):Then(function(v)
				value = v
			end)

			expect(value).to.equal(1)
		end)
	end)

	describe("Promise.All", function()
		it("should error if given something other than a table", function()
			expect(function()
				Promise.All(1)
			end).to.throw()
		end)

		it("should resolve instantly with an empty table if given no promises", function()
			local promise = Promise.All {}
			local success, value = promise:_unwrap()

			expect(success).to.equal(true)
			expect(promise:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(value).to.be.a("table")
			expect(next(value)).to.equal(nil)
		end)

		it("should error if given non-promise values", function()
			expect(function()
				Promise.All(table.create(3, {}))
			end).to.throw()
		end)

		it("should wait for all promises to be resolved and return their values", function()
			local resolveFunctions = {}

			local testValuesLength, testValues = pack(1, "A string", nil, false)
			local promises = {}

			for i = 1, testValuesLength do
				promises[i] = Promise.new(function(resolve)
					local array = table.create(2, resolve)
					array[2] = testValues[i]
					resolveFunctions[i] = array
				end)
			end

			local combinedPromise = Promise.All(promises)

			for _, resolve in ipairs(resolveFunctions) do
				expect(combinedPromise:GetStatus()).to.equal(Promise.Status.Started)
				resolve[1](resolve[2])
			end

			local resultLength, result = pack(combinedPromise:_unwrap())
			local success, resolved = table.unpack(result, 1, resultLength)

			expect(resultLength).to.equal(2)
			expect(success).to.equal(true)
			expect(resolved).to.be.a("table")
			expect(#resolved).to.equal(#promises)

			for i = 1, testValuesLength do
				expect(resolved[i]).to.equal(testValues[i])
			end
		end)

		it("should reject if any individual promise rejected", function()
			local rejectA
			local resolveB

			local a = Promise.new(function(_, reject)
				rejectA = reject
			end)

			local b = Promise.new(function(resolve)
				resolveB = resolve
			end)

			local combinedPromise = Promise.All({a, b})

			expect(combinedPromise:GetStatus()).to.equal(Promise.Status.Started)

			rejectA("baz", "qux")
			resolveB("foo", "bar")

			local resultLength, result = pack(combinedPromise:_unwrap())
			local success, first, second = table.unpack(result, 1, resultLength)

			expect(resultLength).to.equal(3)
			expect(success).to.equal(false)
			expect(first).to.equal("baz")
			expect(second).to.equal("qux")
			expect(b:GetStatus()).to.equal(Promise.Status.Cancelled)
		end)

		it("should not resolve if resolved after rejecting", function()
			local rejectA
			local resolveB

			local a = Promise.new(function(_, reject)
				rejectA = reject
			end)

			local b = Promise.new(function(resolve)
				resolveB = resolve
			end)

			local combinedPromise = Promise.All({a, b})

			expect(combinedPromise:GetStatus()).to.equal(Promise.Status.Started)

			rejectA("baz", "qux")
			resolveB("foo", "bar")

			local resultLength, result = pack(combinedPromise:_unwrap())
			local success, first, second = table.unpack(result, 1, resultLength)

			expect(resultLength).to.equal(3)
			expect(success).to.equal(false)
			expect(first).to.equal("baz")
			expect(second).to.equal("qux")
		end)

		it("should only reject once", function()
			local rejectA
			local rejectB

			local a = Promise.new(function(_, reject)
				rejectA = reject
			end)

			local b = Promise.new(function(_, reject)
				rejectB = reject
			end)

			local combinedPromise = Promise.All({a, b})

			expect(combinedPromise:GetStatus()).to.equal(Promise.Status.Started)

			rejectA("foo", "bar")

			expect(combinedPromise:GetStatus()).to.equal(Promise.Status.Rejected)

			rejectB("baz", "qux")

			local resultLength, result = pack(combinedPromise:_unwrap())
			local success, first, second = table.unpack(result, 1, resultLength)

			expect(resultLength).to.equal(3)
			expect(success).to.equal(false)
			expect(first).to.equal("foo")
			expect(second).to.equal("bar")
		end)

		it("should error if a non-array table is passed in", function()
			local ok, err: string = pcall(function()
				Promise.All(Promise.new(function() end))
			end)

			expect(ok).to.be.ok()
			expect(string.find(err, "Non%-promise")).to.be.ok()
		end)

		it("should cancel pending promises if one rejects", function()
			local p = Promise.new(function() end)
			expect(Promise.All({
				Promise.Resolve(),
				Promise.Reject(),
				p
			}):GetStatus()).to.equal(Promise.Status.Rejected)
			expect(p:GetStatus()).to.equal(Promise.Status.Cancelled)
		end)

		it("should cancel promises if it is cancelled", function()
			local p = Promise.new(function() end)
			p:Then(function() end)

			local promises = {
				Promise.new(function() end),
				Promise.new(function() end),
				p
			}

			Promise.All(promises):Cancel()

			expect(promises[1]:GetStatus()).to.equal(Promise.Status.Cancelled)
			expect(promises[2]:GetStatus()).to.equal(Promise.Status.Cancelled)
			expect(promises[3]:GetStatus()).to.equal(Promise.Status.Started)
		end)
	end)

	describe("Promise.Race", function()
		it("should resolve with the first settled value", function()
			local promise = Promise.Race({
				Promise.Resolve(1),
				Promise.Resolve(2)
			}):Then(function(value)
				expect(value).to.equal(1)
			end)

			expect(promise:GetStatus()).to.equal(Promise.Status.Resolved)
		end)

		it("should cancel other promises", function()
			local promise = Promise.new(function() end)
			promise:Then(function() end)
			local promises = {
				promise,
				Promise.new(function() end),
				Promise.new(function(resolve)
					resolve(2)
				end)
			}

			local promiseRace = Promise.Race(promises)

			expect(promiseRace:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(promiseRace._values[1]).to.equal(2)
			expect(promises[1]:GetStatus()).to.equal(Promise.Status.Started)
			expect(promises[2]:GetStatus()).to.equal(Promise.Status.Cancelled)
			expect(promises[3]:GetStatus()).to.equal(Promise.Status.Resolved)

			local p = Promise.new(function() end)
			expect(Promise.Race({
				Promise.Reject(),
				Promise.Resolve(),
				p
			}):GetStatus()).to.equal(Promise.Status.Rejected)
			expect(p:GetStatus()).to.equal(Promise.Status.Cancelled)
		end)

		it("should error if a non-array table is passed in", function()
			local ok, err: string = pcall(function()
				Promise.Race(Promise.new(function() end))
			end)

			expect(ok).to.be.ok()
			expect(string.find(err, "Non%-promise")).to.be.ok()
		end)

		it("should cancel promises if it is cancelled", function()
			local p = Promise.new(function() end)
			p:Then(function() end)

			local promises = {
				Promise.new(function() end),
				Promise.new(function() end),
				p
			}

			Promise.Race(promises):Cancel()

			expect(promises[1]:GetStatus()).to.equal(Promise.Status.Cancelled)
			expect(promises[2]:GetStatus()).to.equal(Promise.Status.Cancelled)
			expect(promises[3]:GetStatus()).to.equal(Promise.Status.Started)
		end)
	end)

	describe("Promise.Promisify", function()
		it("should wrap functions", function()
			local function test(n)
				return n + 1
			end

			local promisified = Promise.Promisify(test)
			local promise = promisified(1)
			local success, result = promise:_unwrap()

			expect(success).to.equal(true)
			expect(promise:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(result).to.equal(2)
		end)

		it("should catch errors after a yield", function()
			local bindable = Instance.new("BindableEvent")
			local test = Promise.Promisify(function ()
				bindable.Event:Wait()
				error('errortext')
			end)

			local promise = test()

			expect(promise:GetStatus()).to.equal(Promise.Status.Started)
			bindable:Fire()
			expect(promise:GetStatus()).to.equal(Promise.Status.Rejected)
			expect(string.find(tostring(promise._values[1]), "errortext")).to.be.ok()
		end)
	end)

	describe("Promise.tap", function()
		it("should thread through values", function()
			local first, second

			Promise.Resolve(1)
				:Then(function(v)
					return v + 1
				end)
				:Tap(function(v)
					first = v
					return v + 1
				end)
				:Then(function(v)
					second = v
				end)

			expect(first).to.equal(2)
			expect(second).to.equal(2)
		end)

		it("should chain onto promises", function()
			local resolveInner, finalValue

			local promise = Promise.Resolve(1)
				:Tap(function()
					return Promise.new(function(resolve)
						resolveInner = resolve
					end)
				end)
				:Then(function(v)
					finalValue = v
				end)

			expect(promise:GetStatus()).to.equal(Promise.Status.Started)
			expect(finalValue).to.never.be.ok()

			resolveInner(1)

			expect(promise:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(finalValue).to.equal(1)
		end)
	end)

	describe("Promise.Try", function()
		it("should catch synchronous errors", function()
			local errorText
			Promise.Try(function()
				error("errortext")
			end):Catch(function(e)
				errorText = tostring(e)
			end)

			expect(string.find(errorText, "errortext")).to.be.ok()
		end)

		it("should reject with error objects", function()
			local object = {}
			local success, value = Promise.Try(function()
				error(object)
			end):_unwrap()

			expect(success).to.equal(false)
			expect(value).to.equal(object)
		end)

		it("should catch asynchronous errors", function()
			local bindable = Instance.new("BindableEvent")
			local promise = Promise.Try(function()
				bindable.Event:Wait()
				error("errortext")
			end)

			expect(promise:GetStatus()).to.equal(Promise.Status.Started)
			bindable:Fire()
			expect(promise:GetStatus()).to.equal(Promise.Status.Rejected)
			expect(string.find(tostring(promise._values[1]), "errortext")).to.be.ok()
		end)
	end)

	describe("Promise:ThenReturn", function()
		it("should return the given values", function()
			local value1, value2

			Promise.Resolve():ThenReturn(1, 2):Then(function(one, two)
				value1 = one
				value2 = two
			end)

			expect(value1).to.equal(1)
			expect(value2).to.equal(2)
		end)
	end)

	describe("Promise:DoneReturn", function()
		it("should return the given values", function()
			local value1, value2

			Promise.Resolve():DoneReturn(1, 2):Then(function(one, two)
				value1 = one
				value2 = two
			end)

			expect(value1).to.equal(1)
			expect(value2).to.equal(2)
		end)
	end)

	describe("Promise:ThenCall", function()
		it("should call the given function with arguments", function()
			local value1, value2
			Promise.Resolve():ThenCall(function(a, b)
				value1 = a
				value2 = b
			end, 3, 4)

			expect(value1).to.equal(3)
			expect(value2).to.equal(4)
		end)
	end)

	describe("Promise:DoneCall", function()
		it("should call the given function with arguments", function()
			local value1, value2
			Promise.Resolve():DoneCall(function(a, b)
				value1 = a
				value2 = b
			end, 3, 4)

			expect(value1).to.equal(3)
			expect(value2).to.equal(4)
		end)
	end)

	describe("Promise:Done", function()
		it("should trigger on resolve or cancel", function()
			local promise = Promise.new(function() end)
			local value

			local p = promise:Done(function()
				value = true
			end)

			expect(value).to.never.be.ok()
			promise:Cancel()
			expect(p:GetStatus()).to.equal(Promise.Status.Cancelled)
			expect(value).to.equal(true)

			local never, always
			Promise.Reject():Done(function()
				never = true
			end):Finally(function()
				always = true
			end)

			expect(never).to.never.be.ok()
			expect(always).to.be.ok()
		end)
	end)

	describe("Promise.Some", function()
		it("should resolve once the goal is reached", function()
			local p = Promise.Some({
				Promise.Resolve(1),
				Promise.Reject(),
				Promise.Resolve(2)
			}, 2)
			expect(p:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(p._values[1][1]).to.equal(1)
			expect(p._values[1][2]).to.equal(2)
		end)

		it("should error if the goal can't be reached", function()
			expect(Promise.Some({
				Promise.Resolve(),
				Promise.Reject()
			}, 2):GetStatus()).to.equal(Promise.Status.Rejected)

			local reject
			local p = Promise.Some({
				Promise.Resolve(),
				Promise.new(function(_, r) reject = r end)
			}, 2)

			expect(p:GetStatus()).to.equal(Promise.Status.Started)
			reject("foo")
			expect(p:GetStatus()).to.equal(Promise.Status.Rejected)
			expect(p._values[1]).to.equal("foo")
		end)

		it("should cancel pending Promises once the goal is reached", function()
			local resolve
			local pending1 = Promise.new(function() end)
			local pending2 = Promise.new(function(r)
				resolve = r
			end)

			local some = Promise.Some({
				pending1,
				pending2,
				Promise.Resolve()
			}, 2)

			expect(some:GetStatus()).to.equal(Promise.Status.Started)
			expect(pending1:GetStatus()).to.equal(Promise.Status.Started)
			expect(pending2:GetStatus()).to.equal(Promise.Status.Started)

			resolve()

			expect(some:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(pending1:GetStatus()).to.equal(Promise.Status.Cancelled)
			expect(pending2:GetStatus()).to.equal(Promise.Status.Resolved)
		end)

		it("should error if passed a non-number", function()
			expect(function()
				Promise.Some({}, "non-number")
			end).to.throw()
		end)

		it("should return an empty array if amount is 0", function()
			local p = Promise.Some(table.create(1, Promise.Resolve(2)), 0)

			expect(p:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(#p._values[1]).to.equal(0)
		end)

		it("should not return extra values", function()
			local p = Promise.Some({
				Promise.Resolve(1),
				Promise.Resolve(2),
				Promise.Resolve(3),
				Promise.Resolve(4),
			}, 2)

			expect(p:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(#p._values[1]).to.equal(2)
			expect(p._values[1][1]).to.equal(1)
			expect(p._values[1][2]).to.equal(2)
		end)

		it("should cancel promises if it is cancelled", function()
			local p = Promise.new(function() end)
			p:Then(function() end)

			local promises = {
				Promise.new(function() end),
				Promise.new(function() end),
				p
			}

			Promise.Some(promises, 3):Cancel()

			expect(promises[1]:GetStatus()).to.equal(Promise.Status.Cancelled)
			expect(promises[2]:GetStatus()).to.equal(Promise.Status.Cancelled)
			expect(promises[3]:GetStatus()).to.equal(Promise.Status.Started)
		end)

		describe("Promise.Any", function()
			it("should return the value directly", function()
				local p = Promise.Any({
					Promise.Reject(),
					Promise.Reject(),
					Promise.Resolve(1)
				})

				expect(p:GetStatus()).to.equal(Promise.Status.Resolved)
				expect(p._values[1]).to.equal(1)
			end)

			it("should error if all are rejected", function()
				expect(Promise.Any({
					Promise.Reject(),
					Promise.Reject(),
					Promise.Reject(),
				}):GetStatus()).to.equal(Promise.Status.Rejected)
			end)
		end)
	end)

	describe("Promise.AllSettled", function()
		it("should resolve with an array of PromiseStatuses", function()
			local reject
			local p = Promise.AllSettled({
				Promise.Resolve(),
				Promise.Reject(),
				Promise.Resolve(),
				Promise.new(function(_, r) reject = r end)
			})

			expect(p:GetStatus()).to.equal(Promise.Status.Started)
			reject()
			expect(p:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(p._values[1][1]).to.equal(Promise.Status.Resolved)
			expect(p._values[1][2]).to.equal(Promise.Status.Rejected)
			expect(p._values[1][3]).to.equal(Promise.Status.Resolved)
			expect(p._values[1][4]).to.equal(Promise.Status.Rejected)
		end)

		it("should cancel promises if it is cancelled", function()
			local p = Promise.new(function() end)
			p:Then(function() end)

			local promises = {
				Promise.new(function() end),
				Promise.new(function() end),
				p
			}

			Promise.AllSettled(promises):Cancel()

			expect(promises[1]:GetStatus()).to.equal(Promise.Status.Cancelled)
			expect(promises[2]:GetStatus()).to.equal(Promise.Status.Cancelled)
			expect(promises[3]:GetStatus()).to.equal(Promise.Status.Started)
		end)
	end)

	describe("Promise:Wait", function()
		it("should return the correct values", function()
			local promise = Promise.Resolve(5, 6, nil, 7)

			local a, b, c, d, e = promise:Wait()

			expect(a).to.equal(true)
			expect(b).to.equal(5)
			expect(c).to.equal(6)
			expect(d).to.equal(nil)
			expect(e).to.equal(7)
		end)
	end)

	describe("Promise:Expect", function()
		it("should throw the correct values", function()
			local rejectionValue = {}
			local promise = Promise.Reject(rejectionValue)

			local success, value = pcall(function()
				promise:Expect()
			end)

			expect(success).to.equal(false)
			expect(value).to.equal(rejectionValue)
		end)
	end)

	describe("Promise:Now", function()
		it("should resolve if the Promise is resolved", function()
			local success, value = Promise.Resolve("foo"):Now():_unwrap()

			expect(success).to.equal(true)
			expect(value).to.equal("foo")
		end)

		it("should reject if the Promise is not resolved", function()
			local success, value = Promise.new(function() end):Now():_unwrap()

			expect(success).to.equal(false)
			expect(Promise.Error.isKind(value, "NotResolvedInTime")).to.equal(true)
		end)

		it("should reject with a custom rejection value", function()
			local success, value = Promise.new(function() end):Now("foo"):_unwrap()

			expect(success).to.equal(false)
			expect(value).to.equal("foo")
		end)
	end)

	describe("Promise.Each", function()
		it("should iterate", function()
			local ok, result = Promise.Each({"foo", "bar", "baz", "qux"}, function(...)
				return {...}
			end):_unwrap()

			expect(ok).to.equal(true)
			expect(result[1][1]).to.equal("foo")
			expect(result[1][2]).to.equal(1)
			expect(result[2][1]).to.equal("bar")
			expect(result[2][2]).to.equal(2)
			expect(result[3][1]).to.equal("baz")
			expect(result[3][2]).to.equal(3)
			expect(result[4][1]).to.equal("qux")
			expect(result[4][2]).to.equal(4)
		end)

		it("should iterate serially", function()
			local resolves = {}
			local callCounts = {}

			local promise = Promise.Each({"foo", "bar", "baz"}, function(value, index)
				callCounts[index] = (callCounts[index] or 0) + 1

				return Promise.new(function(resolve)
					table.insert(resolves, function()
						resolve(string.upper(value))
					end)
				end)
			end)

			expect(promise:GetStatus()).to.equal(Promise.Status.Started)
			expect(#resolves).to.equal(1)
			expect(callCounts[1]).to.equal(1)
			expect(callCounts[2]).to.never.be.ok()

			table.remove(resolves, 1)()

			expect(promise:GetStatus()).to.equal(Promise.Status.Started)
			expect(#resolves).to.equal(1)
			expect(callCounts[1]).to.equal(1)
			expect(callCounts[2]).to.equal(1)
			expect(callCounts[3]).to.never.be.ok()

			table.remove(resolves, 1)()

			expect(promise:GetStatus()).to.equal(Promise.Status.Started)
			expect(callCounts[1]).to.equal(1)
			expect(callCounts[2]).to.equal(1)
			expect(callCounts[3]).to.equal(1)

			table.remove(resolves, 1)()

			expect(promise:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(type(promise._values[1])).to.equal("table")
			expect(type(promise._values[2])).to.equal("nil")

			local result = promise._values[1]

			expect(result[1]).to.equal("FOO")
			expect(result[2]).to.equal("BAR")
			expect(result[3]).to.equal("BAZ")
		end)

		it("should reject with the value if the predicate promise rejects", function()
			local promise = Promise.Each({1, 2, 3}, function()
				return Promise.Reject("foobar")
			end)

			expect(promise:GetStatus()).to.equal(Promise.Status.Rejected)
			expect(promise._values[1]).to.equal("foobar")
		end)

		it("should allow Promises to be in the list and wait when it gets to them", function()
			local innerResolve
			local innerPromise = Promise.new(function(resolve)
				innerResolve = resolve
			end)

			local promise = Promise.Each(table.create(1, innerPromise), function(value)
				return value * 2
			end)

			expect(promise:GetStatus()).to.equal(Promise.Status.Started)

			innerResolve(2)

			expect(promise:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(promise._values[1][1]).to.equal(4)
		end)

		it("should reject with the value if a Promise from the list rejects", function()
			local called = false
			local promise = Promise.Each({1, 2, Promise.Reject("foobar")}, function()
				called = true
				return "never"
			end)

			expect(promise:GetStatus()).to.equal(Promise.Status.Rejected)
			expect(promise._values[1]).to.equal("foobar")
			expect(called).to.equal(false)
		end)

		it("should reject immediately if there's a cancelled Promise in the list initially", function()
			local cancelled = Promise.new(function() end)
			cancelled:Cancel()

			local called = false
			local promise = Promise.Each({1, 2, cancelled}, function()
				called = true
			end)

			expect(promise:GetStatus()).to.equal(Promise.Status.Rejected)
			expect(called).to.equal(false)
			expect(promise._values[1].kind).to.equal(Promise.Error.Kind.AlreadyCancelled)
		end)

		it("should stop iteration if Promise.Each is cancelled", function()
			local callCounts = {}

			local promise = Promise.Each({"foo", "bar", "baz"}, function(_, index)
				callCounts[index] = (callCounts[index] or 0) + 1

				return Promise.new(function()
				end)
			end)

			expect(promise:GetStatus()).to.equal(Promise.Status.Started)
			expect(callCounts[1]).to.equal(1)
			expect(callCounts[2]).to.never.be.ok()

			promise:Cancel()

			expect(promise:GetStatus()).to.equal(Promise.Status.Cancelled)
			expect(callCounts[1]).to.equal(1)
			expect(callCounts[2]).to.never.be.ok()
		end)

		it("should cancel the Promise returned from the predicate if Promise.Each is cancelled", function()
			local innerPromise

			local promise = Promise.Each({"foo", "bar", "baz"}, function()
				innerPromise = Promise.new(function()
				end)

				return innerPromise
			end)

			promise:Cancel()

			expect(innerPromise:GetStatus()).to.equal(Promise.Status.Cancelled)
		end)

		it("should cancel Promises in the list if Promise.Each is cancelled", function()
			local innerPromise = Promise.new(function() end)
			local promise = Promise.Each(table.create(1, innerPromise), function() end)

			promise:Cancel()

			expect(innerPromise:GetStatus()).to.equal(Promise.Status.Cancelled)
		end)
	end)

	describe("Promise.Retry", function()
		it("should retry N times", function()
			local counter = 0

			local promise = Promise.Retry(function(parameter)
				expect(parameter).to.equal("foo")

				counter += 1

				if counter == 5 then
					return Promise.Resolve("ok")
				end

				return Promise.Reject("fail")
			end, 5, "foo")

			expect(promise:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(promise._values[1]).to.equal("ok")
		end)

		it("should reject if threshold is exceeded", function()
			local promise = Promise.Retry(function()
				return Promise.Reject("fail")
			end, 5)

			expect(promise:GetStatus()).to.equal(Promise.Status.Rejected)
			expect(promise._values[1]).to.equal("fail")
		end)
	end)

	describe("Promise.FromEvent", function()
		it("should convert a Promise into an event", function()
			local event = Instance.new("BindableEvent")

			local promise = Promise.FromEvent(event.Event)

			expect(promise:GetStatus()).to.equal(Promise.Status.Started)

			event:Fire("foo")

			expect(promise:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(promise._values[1]).to.equal("foo")
		end)

		it("should convert a Promise into an event with the predicate", function()
			local event = Instance.new("BindableEvent")

			local promise = Promise.FromEvent(event.Event, function(param)
				return param == "foo"
			end)

			expect(promise:GetStatus()).to.equal(Promise.Status.Started)

			event:Fire("bar")

			expect(promise:GetStatus()).to.equal(Promise.Status.Started)

			event:Fire("foo")

			expect(promise:GetStatus()).to.equal(Promise.Status.Resolved)
			expect(promise._values[1]).to.equal("foo")
		end)
	end)

	describe("Promise.Is", function()
		it("should work with current version", function()
			local promise = Promise.Resolve(1)
			expect(Promise.Is(promise)).to.equal(true)
		end)

		it("should work with any object with an Then", function()
			local obj = {
				Then = function()
					return 1
				end;
			}

			expect(Promise.Is(obj)).to.equal(true)
		end)

		it("should work with older promises", function()
			local OldPromise = {}
			OldPromise.prototype = {}
			OldPromise.__index = OldPromise.prototype

			function OldPromise.prototype.Then()
			end

			local oldPromise = setmetatable({}, OldPromise)

			expect(Promise.Is(oldPromise)).to.equal(true)
		end)
	end)
end