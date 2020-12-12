--- Slave clock on the server
-- @classmod MasterClock on the server

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Scheduler = Resources:LoadLibrary("Scheduler")

local MasterClock = {ClassName = "MasterClock"}
MasterClock.__index = MasterClock

function MasterClock.new(remoteEvent, remoteFunction)
	local self = setmetatable({
		_remoteEvent = remoteEvent or error("No remoteEvent");
		_remoteFunction = remoteFunction or error("No remoteFunction");
	}, MasterClock)

	self._remoteFunction.OnServerInvoke = function(_, timeThree)
		return self:_handleDelayRequest(timeThree)
	end

	self._remoteEvent.OnServerEvent:Connect(function(player)
		self._remoteEvent:FireClient(player, tick())
	end)

	Scheduler.Spawn(function()
		while true do
			Scheduler.Wait(5)
			self:_forceSync()
		end
	end)

	return self
end

--- Returns true if the manager has synced with the server
-- @treturn boolean
function MasterClock.IsSynced()
	return true
end

--- Returns the sycncronized time
-- @treturn number current time
MasterClock.GetTime = tick

--- Starts the sync process with all slave clocks.
function MasterClock:_forceSync()
	local timeOne = tick()
	self._remoteEvent:FireAllClients(timeOne)
end

--- Client sends back message to get the SM_Difference.
-- @return slaveMasterDifference
function MasterClock._handleDelayRequest(_, timeThree)
	local timeFour = tick()
	return timeFour - timeThree -- -offset + SM Delay
end

return MasterClock