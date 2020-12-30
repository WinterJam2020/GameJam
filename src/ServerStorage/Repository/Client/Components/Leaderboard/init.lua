local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)

local LeaderboardEntry = Resources:LoadLibrary("LeaderboardEntry")
local Llama = Resources:LoadLibrary("Llama")
local Roact = Resources:LoadLibrary("Roact")

local Leaderboard = Roact.Component:extend("Leaderboard")
Leaderboard.defaultProps = {
	Entries = {
		{
			Time = 0,
			Username = "Bob",
		},
	},
}

function Leaderboard:init()
	self.sortFunction = function(a, b)
		return a.Time < b.Time
	end
end

function Leaderboard:render()
	local children = {
		UIListLayout = Roact.createElement("UIListLayout", {
			Padding = UDim.new(0, 5),
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		}),
	}

	local entries = Llama.List.sort(self.props.Entries, self.sortFunction)
	for index, elementData in ipairs(entries) do
		children[elementData.Username] = Roact.createElement(LeaderboardEntry, {
			LayoutOrder = index - 1,
			Time = elementData.Time,
			Username = elementData.Username,
		})
	end

	return Roact.createElement("Frame", {})
end

return Leaderboard