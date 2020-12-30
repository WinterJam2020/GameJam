local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)

local AutomatedScrollingFrameComponent = Resources:LoadLibrary("AutomatedScrollingFrameComponent")
local LeaderboardEntry = Resources:LoadLibrary("LeaderboardEntry")
local Llama = Resources:LoadLibrary("Llama")
local Roact = Resources:LoadLibrary("Roact")
local Scale = Resources:LoadLibrary("Scale")
local t = Resources:LoadLibrary("t")

local Leaderboard = Roact.Component:extend("Leaderboard")
Leaderboard.defaultProps = {
	Entries = {
		{
			Time = 0,
			Username = "Bob",
		},
	},

	Visible = true,
}

Leaderboard.validateProps = t.interface({
	Entries = t.array(t.interface({
		Time = t.number,
		Username = t.string,
	})),

	Visible = t.boolean,
})

function Leaderboard:init()
	self.sortFunction = function(a, b)
		return a.Time < b.Time
	end
end

-- function Leaderboard:didUpdate(oldProps)
-- 	if self.props.Event ~= oldProps.Event or self.props.Function ~= oldProps.Function then
-- 		self.connection:Disconnect()
-- 		self.connection = self.props.Event:Connect(self.props.Function)
-- 	end
-- end

function Leaderboard:render()
	local children = {
		UIListLayout = Roact.createElement("UIListLayout", {
			Padding = UDim.new(0, 5),
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		}),

		UIScale = Roact.createElement(Scale, {
			Scale = 0.85,
			Size = Vector2.new(850, 850),
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

	return Roact.createElement(AutomatedScrollingFrameComponent, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Visible = self.props.Visible,
	}, children)
end

return Leaderboard