local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local Promise = Resources:LoadLibrary("Promise")

local PlayerPromise = {}

function PlayerPromise.PromiseRequestStreamAround(Player: Player, Position: Vector3, Timeout: number?)
	return Promise.Defer(function(Resolve, Reject)
		local Success, Error = pcall(Player.RequestStreamAroundAsync, Player, Position, Timeout)
		if Success then
			Resolve(true)
		else
			Reject(Error)
		end
	end)
end

function PlayerPromise.PromiseUserIdFromName(Username: string)
	return Promise.Defer(function(Resolve, Reject)
		local Success, Value = pcall(Players.GetUserIdFromNameAsync, Players, Username);
		(Success and Resolve or Reject)(Value)
	end)
end

return PlayerPromise