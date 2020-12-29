--- Slave clock on the server
-- @classmod MasterClock on the server

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Scheduler = Resources:LoadLibrary("Scheduler")

local MasterClock = {ClassName = "MasterClock"}
MasterClock.__index = MasterClock

function MasterClock.new(RemoteEvent, RemoteFunction)
	local self = setmetatable({
		RemoteEvent = RemoteEvent or error("No RemoteEvent");
		RemoteFunction = RemoteFunction or error("No RemoteFunction");
	}, MasterClock)

	function self.RemoteFunction.OnServerInvoke(_, TimeThree)
		return self:_HandleDelayRequest(TimeThree)
	end

	self.RemoteEvent.OnServerEvent:Connect(function(Player)
		self.RemoteEvent:FireClient(Player, tick())
	end)

	Scheduler.Spawn(function()
		while true do
			wait(5)
			self:_ForceSync()
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
function MasterClock:_ForceSync()
	local TimeOne = tick()
	self.RemoteEvent:FireAllClients(TimeOne)
end

--- Client sends back message to get the SM_Difference.
-- @return slaveMasterDifference
function MasterClock._HandleDelayRequest(_, TimeThree)
	local TimeFour = tick()
	return TimeFour - TimeThree -- -offset + SM Delay
end

return MasterClock