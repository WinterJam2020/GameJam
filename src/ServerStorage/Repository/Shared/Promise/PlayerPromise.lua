local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local Promise = Resources:LoadLibrary("Promise")
local Services = Resources:LoadLibrary("Services")
local Typer = Resources:LoadLibrary("Typer")

local Players: Players = Services.Players

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

PlayerPromise.PromiseUserIdFromName = Typer.PromiseAssignSignature(Typer.String, function(Username: string)
	return Promise.Defer(function(Resolve, Reject)
		local Success, Value = pcall(Players.GetUserIdFromNameAsync, Players, Username);
		(Success and Resolve or Reject)(Value)
	end)
end)

local function PromiseUserThumbnail(UserId, ThumbnailType, ThumbnailSize)
	return Promise.new(function(Resolve, Reject)
		local Content, IsReady
		local Success, Error = pcall(function()
			Content, IsReady = Players:GetUserThumbnailAsync(UserId, ThumbnailType, ThumbnailSize)
		end)

		if not Success then
			Reject(Error)
		else
			if IsReady then
				Resolve(Content)
			else
				Promise.Delay(0.05):Wait()
			end
		end
	end)
end

PlayerPromise.PromiseUserThumbnail = Typer.PromiseAssignSignature(Typer.NonNegativeInteger, Typer.EnumOfTypeThumbnailType, Typer.EnumOfTypeThumbnailSize, function(UserId, ThumbnailType, ThumbnailSize)
	return Promise.Retry(PromiseUserThumbnail, 5, UserId, ThumbnailType, ThumbnailSize)
end)

return PlayerPromise