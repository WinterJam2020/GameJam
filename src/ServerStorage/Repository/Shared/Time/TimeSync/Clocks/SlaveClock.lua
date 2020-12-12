--- Slave clock on the client
-- @classmod SlaveClock

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Signal = Resources:LoadLibrary("Signal")

local SlaveClock = {
	ClassName = "SlaveClock";
	_offset = -1;
}

SlaveClock.__index = SlaveClock

function SlaveClock.new(remoteEvent, remoteFunction)
	local self = setmetatable({
		_remoteEvent = remoteEvent or error("No remoteEvent");
		_remoteFunction = remoteFunction or error("No remoteFunction");
		SyncedEvent = Signal.new();
	}, SlaveClock)

	self._remoteEvent.OnClientEvent:Connect(function(timeOne)
		self:_handleSyncEventAsync(timeOne)
	end)

	self._remoteEvent:FireServer() -- Request server to syncronize with us
	return self
end

function SlaveClock:TickToSyncedTime(syncedTime)
	return syncedTime - self._offset
end

function SlaveClock:GetTime()
	if not self:IsSynced() then
		error("[SlaveClock.GetTime] - Slave clock is not yet synced")
	end

	return self:_getLocalTime() - self._offset
end

function SlaveClock:IsSynced()
	return self._offset ~= -1
end

SlaveClock._getLocalTime = tick

function SlaveClock:_handleSyncEventAsync(timeOne)
	local timeTwo = self:_getLocalTime() -- We can't actually get hardware stuff, so we'll send T1 immediately.
	local masterSlaveDifference = timeTwo - timeOne -- We have Offst + MS Delay

	local timeThree = self:_getLocalTime()
	local slaveMasterDifference = self:_sendDelayRequestAsync(timeThree)

	--[[ From explination link.
		The result is that we have the following two equations:
		MS_difference = offset + MS delay
		SM_difference = ?offset + SM delay

		With two measured quantities:
		MS_difference = 90 minutes
		SM_difference = ?20 minutes

		And three unknowns:
		offset , MS delay, and SM delay

		Rearrange the equations according to the tutorial.
		-- Assuming this: MS delay = SM delay = one_way_delay

		one_way_delay = (MSDelay + SMDelay) / 2
	]]

	local offset = (masterSlaveDifference - slaveMasterDifference)/2
	local oneWayDelay = (masterSlaveDifference + slaveMasterDifference)/2

	self._offset = offset -- Estimated difference between server/client
	self._oneWayDelay = oneWayDelay -- Estimated time for network events to send. (MSDelay/SMDelay)

	self.SyncedEvent:Fire()
end

function SlaveClock:_sendDelayRequestAsync(timeThree)
	return self._remoteFunction:InvokeServer(timeThree)
end

return SlaveClock