local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)

local CatchFactory = Resources:LoadLibrary("CatchFactory")
local FriendUtils = Resources:LoadLibrary("FriendUtils")
local LeaderboardEntry = require(script.Parent)
local Roact = Resources:LoadLibrary("Roact")

local Data = Roact.Component:extend("Data")

function Data:render()
	local children = {
		UIListLayout = Roact.createElement("UIListLayout", {
			Padding = UDim.new(0, 5),
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		}),
	}

	local elements = table.create(20)
	local random = Random.new(tick() % 1 * 1E7)

	FriendUtils.PromiseStudioServiceUserId():Then(function(userId)
		FriendUtils.PromiseAllFriends(userId, 20):Then(function(friendsArray)
			for index, friendData in ipairs(friendsArray) do
				elements[index] = {
					key = friendData.Username,
					time = random:NextNumber(120, 240),
				}
			end
		end):Catch(CatchFactory("FriendUtils.PromiseAllFriends")):Wait()
	end):Catch(CatchFactory("FriendUtils.PromiseStudioServiceUserId")):Wait()

	table.sort(elements, function(a, b)
		return a.time < b.time
	end)

	for index, elementData in ipairs(elements) do
		children[elementData.key] = Roact.createElement(LeaderboardEntry, {
			LayoutOrder = index - 1,
			Time = elementData.time,
			Username = elementData.key,
		})
	end

	return Roact.createElement("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, children)
end

return function(Target)
	return coroutine.wrap(function()
		local Tree = Roact.mount(Roact.createElement(Data), Target, "LeaderboardEntryStory")
		return function()
			Roact.unmount(Tree)
		end
	end)()
end