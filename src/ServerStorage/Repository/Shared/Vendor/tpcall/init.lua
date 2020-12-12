--[[
	Use:
	On success:
		local success, return1, return2, ... = tpcall(func, arg1, arg2, ...)
	On error:
		local success, error, traceback = tpcall(func, arg1, arg2, ...)
--]]

local ScriptContext = game:GetService("ScriptContext")
local PREGENERATE_RUNNERS_COUNT = 10

local RunnerBase = script.Runner

local RunnersFree = {}
local RunnersById = {}
local RunnersByCoroutine = {}

local Count = 0
local function GetFreeRunner(Running)
	if RunnersByCoroutine[Running] then
		return RunnersByCoroutine[Running]
	else
		local FreeRunner = next(RunnersFree)
		if FreeRunner then
			return FreeRunner
		else
			Count += 1
			local UniqueId = "tpcall:" .. Count
			RunnerBase.Name = UniqueId
			local NewRunner = require(RunnerBase:Clone())
			NewRunner.Id = UniqueId
			RunnersById[UniqueId] = NewRunner
			return NewRunner
		end
	end
end

for _ = 1, PREGENERATE_RUNNERS_COUNT do
	Count += 1
	local UniqueId = "tpcall:" .. Count
	RunnerBase.Name = UniqueId
	local NewRunner = require(RunnerBase:Clone())
	NewRunner.Id = UniqueId
	RunnersById[UniqueId] = NewRunner
	RunnersFree[NewRunner] = true
end

local LastErrorId, LastError, LastTrace
ScriptContext.Error:Connect(function(Error, Traceback)
	local TpcallId = string.match(Traceback, "(tpcall:%d+)")
	if TpcallId then
		local ScriptName, ErrorLine = string.match(Traceback, "^(.-), line (%d+) %- [^\n]*\n")
		if ScriptName then
			if string.sub(Error, 1, #ScriptName) == ScriptName then
				LastError = string.sub(Error, #ScriptName + #ErrorLine + 4)
			else
				LastError = Error
			end
		else
			LastError = string.match(Error, "^" .. TpcallId .. ":%d+: (.*)$") or Error
		end

		LastErrorId = TpcallId
		LastTrace = string.match(Traceback, "^(.*)\n[^\n]+\n[^\n]+\n$") or ""
		RunnersById[TpcallId].BindableEvent:Fire()
	end
end)

return function(Function, ...)
	local Runner = GetFreeRunner(coroutine.running())
	local InitialCoroutine, InitialEvent = Runner.Thread, Runner.BindableEvent

	local Results

	local Arguments = table.pack(...)
	local BindableEvent = Instance.new("BindableEvent")
	Runner.BindableEvent = BindableEvent
	local Running
	local Connection

	Connection = BindableEvent.Event:Connect(function()
		Connection = Connection:Disconnect()
		Running = coroutine.running()
		Runner.Thread = Running
		RunnersByCoroutine[Running] = Runner
		Results = table.pack(Runner(Function, table.unpack(Arguments, 1, Arguments.n)))
		BindableEvent:Fire()
	end)

	RunnersFree[Runner] = nil
	BindableEvent:Fire()
	local RunnerId = Runner.Id
	if not Results and LastErrorId ~= RunnerId then
		BindableEvent.Event:Wait()
	end

	RunnersByCoroutine[Running] = nil
	Runner.Thread, Runner.BindableEvent = InitialCoroutine, InitialEvent
	if not InitialCoroutine then
		RunnersFree[Runner] = true
	end

	if LastErrorId == RunnerId then
		LastErrorId = nil
		return false, LastError, LastTrace
	else
		return true, table.unpack(Results, 1, Results.n)
	end
end