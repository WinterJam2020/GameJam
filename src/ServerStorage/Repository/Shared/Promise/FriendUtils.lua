local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local Debug = Resources:LoadLibrary("Debug")
local Promise = Resources:LoadLibrary("Promise")
local Services = Resources:LoadLibrary("Services")
local Typer = Resources:LoadLibrary("Typer")

local Debug_Assert = Debug.Assert

local FriendUtils = {}

function FriendUtils.PromiseAllStudioFriends()
	return FriendUtils.PromiseCurrentStudioUserId():Then(FriendUtils.PromiseAllFriends)
end

-- @param[opt=nil] limitMaxFriends
FriendUtils.PromiseAllFriends = Typer.AssignSignature(Typer.Integer, Typer.OptionalInteger, function(UserId, LimitMaxFriends)
	return FriendUtils.PromiseFriendPages(UserId):Then(function(Pages)
		return Promise.Defer(function(Resolve)
			local Users = {}
			local Length = 0
			for UserData in FriendUtils.IterateFriendsYielding(Pages) do
				Length += 1
				Users[Length] = UserData

				if LimitMaxFriends and Length >= LimitMaxFriends then
					return Resolve(Users)
				end
			end

			Resolve(Users)
		end)
	end)
end)

FriendUtils.PromiseFriendPages = Typer.AssignSignature(Typer.Integer, function(UserId)
	return Promise.Defer(function(Resolve, Reject)
		local Success, Pages = pcall(Services.Players.GetFriendsAsync, Services.Players, UserId);
		if not Success then
			Reject(Pages)
		elseif not Pages then
			Reject("No Pages.")
		else
			Resolve(Pages)
		end
		-- (Success and Resolve and Reject)(Pages)
	end)
end)

local UserDataDefinition = Typer.MapDefinition {
	AvatarFinal = Typer.Boolean;
	AvatarUri = Typer.String;
	Id = Typer.Integer;
	IsOnline = Typer.Boolean;
	Username = Typer.String;
}

function FriendUtils.IterateFriendsYielding(Pages)
	Debug_Assert(Pages, "Pages doesn't exist!")

	return coroutine.wrap(function()
		while true do
			for _, UserData in ipairs(Pages:GetCurrentPage()) do
				-- print(UserData)
				-- Debug_Assert(Typer_Boolean(UserData.IsOnline))
				-- Debug_Assert(Typer_String(UserData.Username))
				-- Debug_Assert(Typer_Integer(UserData.Id))

				Debug_Assert(UserDataDefinition(UserData))
				coroutine.yield(UserData)
			end

			if Pages.IsFinished then
				break
			end

			Pages:AdvanceToNextPageAsync()
		end
	end)
end

function FriendUtils.PromiseStudioServiceUserId()
	return Promise.new(function(Resolve, Reject)
		local UserId
		local Success, Error = pcall(function()
			UserId = Services.StudioService:GetUserId()
		end)

		if not Success then
			Reject(Error)
		elseif type(UserId) ~= "number" then
			Reject("no UserId returned")
		else
			Resolve(UserId)
		end
	end)
end

function FriendUtils.PromiseCurrentStudioUserId()
	return FriendUtils.PromiseStudioServiceUserId():Catch(function()
		local Player = Services.Players:FindFirstChildOfClass("Player")
		if Player then
			return Player.UserId
		end

		return 4397833
	end)
end

return FriendUtils