local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Resources = require(ReplicatedStorage.Resources)

local Constants = Resources:LoadLibrary("Constants")
local Debug = Resources:LoadLibrary("Debug")
local MasterClock = Resources:LoadLibrary("MasterClock")
local Promise = Resources:LoadLibrary("Promise")
local SlaveClock = Resources:LoadLibrary("SlaveClock")
local TimeSyncUtils = Resources:LoadLibrary("TimeSyncUtils")

local Debug_Assert = Debug.Assert

local TimeSyncService = {}

local function PromiseGetRemoteEvent(Name)
	return Promise.Defer(function(Resolve)
		Resolve(Resources:GetRemoteEvent(Name))
	end)
end

local function PromiseGetRemoteFunction(Name)
	return Promise.Defer(function(Resolve)
		Resolve(Resources:GetRemoteFunction(Name))
	end)
end

function TimeSyncService:Initialize()
	Debug_Assert(not self.ClockPromise, "TimeSyncService is already initialized!")
	self.ClockPromise = Promise.new()

	if not RunService:IsRunning() then
		error("Cannot initialize in test mode")
	elseif RunService:IsServer() then
		self.ClockPromise:Resolve(self:_BuildMasterClock())
	elseif RunService:IsClient() then
		-- This also handles play solo edgecase where
		self.ClockPromise:Resolve(self:_PromiseSlaveClock())
	else
		error("Bad RunService state")
	end

	return self
end

function TimeSyncService:IsSynced()
	if not RunService:IsRunning() then
		return true
	end

	return Debug_Assert(self.ClockPromise, "TimeSyncService is not initialized."):GetStatus() == Promise.Status.Resolved
end

function TimeSyncService:WaitForSyncedClock()
	if not RunService:IsRunning() then
		return self:_BuildMockClock()
	end

	return Debug_Assert(self.ClockPromise, "TimeSyncService is not initialized."):Wait()
end

function TimeSyncService:GetSyncedClock()
	if not RunService:IsRunning() then
		return self:_BuildMockClock()
	end

	local ClockPromise = Debug_Assert(self.ClockPromise, "TimeSyncService is not initialized.")
	if ClockPromise:GetStatus() == Promise.Status.Resolved then
		return ClockPromise:Wait()
	end
end

function TimeSyncService:PromiseSyncedClock()
	if not RunService:IsRunning() then
		return Promise.Resolve(self:_BuildMockClock())
	end

	return Promise.Resolve(Debug_Assert(self.ClockPromise, "TimeSyncService is not initialized."))
end

function TimeSyncService._BuildMockClock()
	return {
		GetTime = tick;
		IsSynced = function()
			return true
		end;
	}
end

function TimeSyncService._BuildMasterClock()
	local RemoteEvent = Resources:GetRemoteEvent(Constants.REMOTE_NAMES.TIME_SYNC_REMOTE_EVENT_NAME)
	local RemoteFunction = Resources:GetRemoteFunction(Constants.REMOTE_NAMES.TIME_SYNC_REMOTE_FUNCTION_NAME)

	return MasterClock.new(RemoteEvent, RemoteFunction)
end

function TimeSyncService._PromiseSlaveClock()
	local Promises = table.create(2)
	Promises[1] = PromiseGetRemoteEvent(Constants.REMOTE_NAMES.TIME_SYNC_REMOTE_EVENT_NAME)
	Promises[2] = PromiseGetRemoteFunction(Constants.REMOTE_NAMES.TIME_SYNC_REMOTE_FUNCTION_NAME)

	return Promise.All(Promises):Spread(function(RemoteEvent, RemoteFunction)
		return TimeSyncUtils.PromiseClockSynced(SlaveClock.new(RemoteEvent, RemoteFunction))
	end)
end

return TimeSyncService
