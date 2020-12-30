local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)

local CatchFactory = Resources:LoadLibrary("CatchFactory")
local FriendUtils = Resources:LoadLibrary("FriendUtils")
local Leaderboard = require(script.Parent)
local Roact = Resources:LoadLibrary("Roact")

local LeaderboardStory = Roact.Component:extend("LeaderboardStory")

function LeaderboardStory:render()
	local amount = self.props.Amount
	local elements = table.create(amount)
	local random = Random.new(tick() % 1 * 1E7)

	FriendUtils.PromiseStudioServiceUserId():Then(function(userId)
		FriendUtils.PromiseAllFriends(userId, amount):Then(function(friendsArray)
			for index, friendData in ipairs(friendsArray) do
				elements[index] = {
					Username = friendData.Username,
					Time = random:NextNumber(120, 240),
				}
			end
		end):Catch(CatchFactory("FriendUtils.PromiseAllFriends")):Wait()
	end):Catch(CatchFactory("FriendUtils.PromiseStudioServiceUserId")):Wait()

	return Roact.createElement(Leaderboard, {
		Entries = elements,
	})
end

return function(Target)
	return coroutine.wrap(function()
		local Tree = Roact.mount(Roact.createElement(LeaderboardStory, {
			Amount = 10,
		}), Target, "LeaderboardStory")

		return function()
			Roact.unmount(Tree)
		end
	end)()
end