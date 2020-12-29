--- Slave clock on the client
-- @classmod SlaveClock

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Signal = Resources:LoadLibrary("Signal")

local SlaveClock = {
	ClassName = "SlaveClock";
	_Offset = -1;
}

SlaveClock.__index = SlaveClock

function SlaveClock.new(RemoteEvent, RemoteFunction)
	local self = setmetatable({
		RemoteEvent = RemoteEvent or error("No RemoteEvent");
		RemoteFunction = RemoteFunction or error("No RemoteFunction");
		SyncedEvent = Signal.new();
	}, SlaveClock)

	self.RemoteEvent.OnClientEvent:Connect(function(TimeOne)
		self:_HandleSyncEventAsync(TimeOne)
	end)

	self.RemoteEvent:FireServer() -- Request server to syncronize with us
	return self
end

function SlaveClock:TickToSyncedTime(SyncedTime)
	return SyncedTime - self._Offset
end

function SlaveClock:GetTime()
	if not self:IsSynced() then
		error("[SlaveClock.GetTime] - Slave clock is not yet synced")
	end

	return self:_GetLocalTime() - self._Offset
end

function SlaveClock:IsSynced()
	return self._Offset ~= -1
end

SlaveClock._GetLocalTime = tick

function SlaveClock:_HandleSyncEventAsync(TimeOne)
	local TimeTwo = self:_GetLocalTime() -- We can't actually get hardware stuff, so we'll send T1 immediately.
	local MasterSlaveDifference = TimeTwo - TimeOne -- We have Offst + MS Delay

	local TimeThree = self:_GetLocalTime()
	local SlaveMasterDifference = self:_SendDelayRequestAsync(TimeThree)

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

	local Offset = (MasterSlaveDifference - SlaveMasterDifference) / 2
	local OneWayDelay = (MasterSlaveDifference + SlaveMasterDifference) / 2

	self._Offset = Offset -- Estimated difference between server/client
	self._OneWayDelay = OneWayDelay -- Estimated time for network events to send. (MSDelay/SMDelay)

	self.SyncedEvent:Fire()
end

function SlaveClock:_SendDelayRequestAsync(TimeThree)
	return self.RemoteFunction:InvokeServer(TimeThree)
end

return SlaveClock