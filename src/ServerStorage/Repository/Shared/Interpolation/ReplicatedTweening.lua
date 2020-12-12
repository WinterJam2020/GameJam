local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadLibrary("Constants")
local Scheduler = Resources:LoadLibrary("Scheduler")
local TweenService = Resources:LoadLibrary("TweenService")
local Typer = Resources:LoadLibrary("Typer")

local TweenEvent = Resources:GetRemoteEvent("TweenEvent")

local ReplicatedTweening = {}
local LatestFinish = {}

local function ServerAssignProperties(Object, Properties)
	for Property, Value in next, Properties do
		Object[Property] = Value
	end
end

local function SpawnFunction(Object, WaitTime, TweenMaster, PropertyTable)
	local Index = 0
	local ExistingFinish = LatestFinish[Object]
	repeat
		Scheduler.Wait2(0.1)
		Index += 1
	until Index >= WaitTime or TweenMaster.Stopped

	if LatestFinish[Object] == ExistingFinish then
		LatestFinish[Object] = nil
	end

	if not TweenMaster.Paused then
		ServerAssignProperties(Object, PropertyTable)
	end
end

local InformationDefinition = Typer.MapDefinition {
	[1] = Typer.Number;
	[2] = Typer.String;
	[3] = Typer.String;
}

-- local GetTweenObjectTuple = t.tuple(t.Instance, t.strictArray(t.number, t.string, t.string), t.keys(t.string))

ReplicatedTweening.GetTweenObject = Typer.AssignSignature(Typer.Instance, {Information = InformationDefinition}, Typer.Dictionary, function(Object: Instance, Information, Properties)
	local TweenMaster = {
		DoNotUpdate = {};
		Paused = false;
		Stopped = false;
	}

	local Length = 0

	local function Play(Yield, SpecificClient, Queue)
		local WaitTime = Information[1]
		local FinishTime = os.time() + WaitTime
		LatestFinish[Object] = LatestFinish[Object] or os.time()

		Queue = Queue == nil and false or Queue
		TweenMaster.Paused = false

		if SpecificClient == nil and not Queue then
			LatestFinish[Object] = FinishTime
			TweenEvent:FireAllClients(Constants.RUN_TWEEN, Object, Information, Properties)
		elseif Queue and SpecificClient == nil then
			local Latest = LatestFinish[Object] - os.time()
			WaitTime += Latest
			LatestFinish[Object] = FinishTime + Latest
			TweenEvent:FireAllClients(Constants.QUEUE_TWEEN, Object, Information, Properties)
		elseif Queue then
			TweenEvent:FireClient(SpecificClient, Constants.QUEUE_TWEEN, Object, Information, Properties)
		else
			TweenEvent:FireClient(SpecificClient, Constants.RUN_TWEEN, Object, Information, Properties)
		end

		if Yield and SpecificClient == nil then
			local Index = 0
			local ExistingFinish = LatestFinish[Object]
			repeat
				Scheduler.Wait2(0.1)
				Index += 1
			until Index >= WaitTime or TweenMaster.Stopped

			if LatestFinish[Object] == ExistingFinish then
				LatestFinish[Object] = nil
			end

			if not TweenMaster.Paused then
				ServerAssignProperties(Object, Properties)
			end

			return
		elseif SpecificClient == nil then
			Scheduler.Spawn(SpawnFunction, Object, WaitTime, TweenMaster, Properties)
		end
	end

	TweenMaster.Play = Play
	function TweenMaster.QueuePlay(Yield, SpecificClient)
		Play(Yield, SpecificClient, true)
	end

	function TweenMaster.Pause(SpecificClient)
		if SpecificClient == nil then
			TweenMaster.Paused = true
			TweenEvent:FireAllClients(Constants.PAUSE_TWEEN, Object)
		else
			Length += 1
			TweenMaster.DoNotUpdate[Length] = SpecificClient
			TweenEvent:FireClient(SpecificClient, Constants.PAUSE_TWEEN, Object)
		end
	end

	function TweenMaster.Stop(SpecificClient)
		if SpecificClient == nil then
			TweenMaster.Stopped = true
			TweenEvent:FireAllClients(Constants.STOP_TWEEN, Object)
		else
			TweenEvent:FireClient(SpecificClient, Constants.STOP_TWEEN, Object)
		end
	end

	return TweenMaster
end)

if RunService:IsClient() then
	local RunningTweens = {}
	TweenEvent.OnClientEvent:Connect(function(FunctionCall, Object, Information, PropertyTable)
		local Time, EasingFunction, EasingDirection = Information[1], Information[2], Information[3]
		local TweenInformation = {
			Time = Time or 0.5;
			Function = EasingFunction or "Smoother";
			Direction = EasingDirection or "Out";
		}

		local function RunTween(Queued)
			local FinishTime = os.time() + TweenInformation.Time
			LatestFinish[Object] = LatestFinish[Object] or os.time()

			local ExistingFinish = LatestFinish[Object]
			if Queued and LatestFinish[Object] >= os.time() then
				local WaitTime = LatestFinish[Object] - os.time()
				LatestFinish[Object] = FinishTime + WaitTime
				ExistingFinish = LatestFinish[Object]
				Scheduler.Wait(WaitTime)
			else
				LatestFinish[Object] = FinishTime
			end

			local Thread, NewInformation = TweenService.TweenCreate(Object, Time, EasingFunction, EasingDirection, PropertyTable)
			RunningTweens[Object] = Thread

			local Success, Error = coroutine.resume(Thread, table.unpack(NewInformation))
			if not Success then
				warn(debug.traceback(Thread, tostring(Error)))
			end

			Scheduler.Wait(TweenInformation.Time or 1)
			if LatestFinish[Object] == ExistingFinish then
				LatestFinish[Object] = nil
			end

			if RunningTweens[Object] == Thread then
				RunningTweens[Object] = nil
			end
		end

		if FunctionCall == Constants.RUN_TWEEN then
			RunTween()
		elseif FunctionCall == Constants.QUEUE_TWEEN then
			RunTween(true)
		elseif FunctionCall == Constants.STOP_TWEEN then
			if RunningTweens[Object] ~= nil then
				TweenService.Interrupt(Object)
				RunningTweens[Object] = nil
			else
				warn("Tween being stopped does not exist.")
			end
		end
	end)
end

return ReplicatedTweening