--!nocheck
-- Scheduler
-- pobammer
-- September 11, 2020

local RunService = game:GetService("RunService")
local Heartbeat = RunService.Heartbeat
local Scheduler = {}

local First, Connection

function Scheduler.Delay(DelayTime, Function, ...)
	if DelayTime == nil or not (DelayTime >= 0.029) or DelayTime == math.huge then
		DelayTime = 0.029
	end

	local StartTime = os.clock()
	local EndTime = StartTime + DelayTime

	local Node = {
		Arguments = nil;
		Function = Function;
		StartTime = StartTime;
		EndTime = EndTime;
		Next = nil;
	}

	local Length = select("#", ...)
	if Length > 0 then
		Node.Arguments = {Length + 1, ...}
	end

	if Connection == nil then
		First = Node
		Connection = Heartbeat:Connect(function()
			while First.EndTime <= os.clock() do
				local Current = First
				First = Current.Next

				if not First then
					Connection = Connection:Disconnect()
				end

				local Arguments = Current.Arguments
				local FunctionToCall = Current.Function

				if typeof(FunctionToCall) == "Instance" then
					if Arguments then
						FunctionToCall:Fire(table.unpack(Arguments, 2, Arguments[1]))
					else
						FunctionToCall:Fire(os.clock() - Current.StartTime)
					end
				else
					local BindableEvent = Instance.new("BindableEvent")
					if Arguments then
						BindableEvent.Event:Connect(function()
							FunctionToCall(table.unpack(Arguments, 2, Arguments[1]))
						end)

						BindableEvent:Fire()
						BindableEvent:Destroy()
					else
						BindableEvent.Event:Connect(FunctionToCall)
						BindableEvent:Fire(os.clock() - Current.StartTime)
						BindableEvent:Destroy()
					end

				end

				if not Current.Next then
					return
				end
			end
		end)
	else
		if First.EndTime < EndTime then
			local Current = First
			local Next = Current.Next

			while Next and Next.EndTime < EndTime do
				Current = Next
				Next = Current.Next
			end

			Current.Next = Node
			if Next then
				Node.Next = Next
			end
		else
			Node.Next = First
			First = Node
		end
	end
end

function Scheduler.Wait(Seconds)
	local BindableEvent = Instance.new("BindableEvent")
	Scheduler.Delay(math.max(Seconds or 0.03, 0.029), BindableEvent)
	return BindableEvent.Event:Wait()
end

function Scheduler.Wait2(Seconds)
	Seconds = math.max(Seconds or 0.03, 0.029)
	local TimeRemaining = Seconds

	while TimeRemaining > 0 do
		TimeRemaining -= Heartbeat:Wait()
	end

	return Seconds - TimeRemaining
end

-- @source https://devforum.roblox.com/t/psa-you-can-get-errors-and-stack-traces-from-coroutines/455510/2
local function Finish(Thread, Success, ...)
	if not Success then
		warn(debug.traceback(Thread, tostring((...))))
	end

	return Success, ...
end

function Scheduler.Spawn(Function, ...)
	local Thread = coroutine.create(Function)
	return Finish(Thread, coroutine.resume(Thread, ...))
end

function Scheduler.FastSpawn(Function, ...)
	local Arguments = table.pack(...)
	local BindableEvent = Instance.new("BindableEvent")
	BindableEvent.Event:Connect(function()
		Function(table.unpack(Arguments, 1, Arguments.n))
	end)

	BindableEvent:Fire()
	BindableEvent:Destroy()
end

function Scheduler.SpawnDelayed(Function, ...)
	local Length = select("#", ...)
	if Length > 0 then
		local Arguments = {...}
		local HeartbeatConnection

		HeartbeatConnection = Heartbeat:Connect(function()
			HeartbeatConnection:Disconnect()
			Function(table.unpack(Arguments, 1, Length))
		end)
	else
		local HeartbeatConnection
		HeartbeatConnection = Heartbeat:Connect(function()
			HeartbeatConnection:Disconnect()
			Function()
		end)
	end
end

return Scheduler