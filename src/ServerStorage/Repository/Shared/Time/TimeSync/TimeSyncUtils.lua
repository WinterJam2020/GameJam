local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Janitor = Resources:LoadLibrary("Janitor")
local Promise = Resources:LoadLibrary("Promise")

local TimeSyncUtils = {}

function TimeSyncUtils.PromiseClockSynced(Clock)
	if Clock:IsSynced() then
		return Promise.Resolve(Clock)
	end

	local SyncedEvent = assert(Clock.SyncedEvent, "Somehow master clock isn't synced")
	local ClockPromise = Promise.new()
	local ClockJanitor = Janitor.new()

	ClockJanitor:Add(SyncedEvent:Connect(function()
		if Clock:IsSynced() then
			ClockPromise:Resolve(Clock)
		end
	end), "Disconnect")

	ClockPromise:Finally(function()
		ClockJanitor = ClockJanitor:Destroy()
	end)

	return ClockPromise
end

return TimeSyncUtils