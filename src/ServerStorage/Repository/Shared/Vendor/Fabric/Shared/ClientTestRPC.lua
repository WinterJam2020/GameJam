local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local Scheduler = Resources:LoadLibrary("Scheduler")

local __TestRPC = Resources:GetRemoteFunction("__TestRPC")

return function(name, ...)
	local plr = Players:GetPlayers()[1]
	while not plr do
		Scheduler.Wait2(0.03)
		plr = Players:GetPlayers()[1]
	end

	return __TestRPC:InvokeClient(plr, name, ...)
end