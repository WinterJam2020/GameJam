local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local CatchFactory = Resources:LoadLibrary("CatchFactory")
local GetTimeString = Resources:LoadLibrary("GetTimeString")
local PlayerPromise = Resources:LoadLibrary("PlayerPromise")
local Roact = Resources:LoadLibrary("Roact")
local t = Resources:LoadLibrary("t")

local LeaderboardEntry = Roact.Component:extend("LeaderboardEntry")
LeaderboardEntry.defaultProps = {
	BackgroundColor3 = Color3.new(1, 1, 1),
	GradientColor3 = Color3.fromRGB(201, 201, 201),
	Height = 50,
}

LeaderboardEntry.validateProps = t.interface({
	BackgroundColor3 = t.Color3,
	GradientColor3 = t.Color3,
	Height = t.integer,
	LayoutOrder = t.integer,
	Time = t.union(t.number, t.string),
	Username = t.string,
})

function LeaderboardEntry:init(props)
	PlayerPromise.PromiseUserIdFromName(props.Username):Then(function(userId)
		PlayerPromise.PromiseUserThumbnail(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100):Then(function(thumbnail)
			self:setState({
				currentTime = type(props.Time) == "number" and GetTimeString(props.Time) or props.Time,
				thumbnail = thumbnail,
			})
		end):Catch(CatchFactory("PlayerPromise.PromiseUserThumbnail"))
	end):Catch(CatchFactory("PlayerPromise.PromiseUserIdFromName"))
end

function LeaderboardEntry:render()
	return Roact.createElement("Frame", {
		BackgroundColor3 = self.props.BackgroundColor3,
		LayoutOrder = self.props.LayoutOrder,
		Size = UDim2.new(0.95, 0, 0, self.props.Height),
	}, {
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),

		UIGradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, self.props.GradientColor3),
				ColorSequenceKeypoint.new(0.99, self.props.GradientColor3),
				ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
			}),

			Rotation = 45,
		}),

		Contents = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.95, 0.85),
		}, {
			UIListLayout = Roact.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			PlayerInfo = Roact.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.65, 1),
			}, {
				UIListLayout = Roact.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				PlayerRank = Roact.createElement("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					Font = Enum.Font.Oswald,
					Text = string.format("%d", self.props.LayoutOrder + 1),
					TextColor3 = Color3.new(),
					TextScaled = true,
				}),

				PlayerIcon = Roact.createElement("ImageLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					LayoutOrder = 1,
					Image = self.state.thumbnail,
				}),

				Gap = Roact.createElement("Frame", {
					BackgroundTransparency = 1,
					LayoutOrder = 3,
					Size = UDim2.fromScale(0.025, 1),
				}),

				PlayerName = Roact.createElement("TextLabel", {
					BackgroundTransparency = 1,
					Font = Enum.Font.Oswald,
					LayoutOrder = 4,
					Size = UDim2.fromScale(0.6, 1),
					Text = self.props.Username,
					TextColor3 = Color3.new(),
					TextSize = 36,
					TextWrapped = true,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
			}),

			PlayerTime = Roact.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.RobotoMono, -- Oswald would be preferred, but it isn't monospace. ):
				LayoutOrder = 1,
				Size = UDim2.fromScale(0.35, 0.75),
				Text = self.state.currentTime,
				TextColor3 = Color3.new(),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
		}),
	})
end

return LeaderboardEntry