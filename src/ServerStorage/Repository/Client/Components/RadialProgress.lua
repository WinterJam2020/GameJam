local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Roact = Resources:LoadLibrary("Roact")

local TRANSPARENCY_SEQUENCE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5 - 0.001, 1),
	NumberSequenceKeypoint.new(0.5 + 0.001, 0),
	NumberSequenceKeypoint.new(1, 0),
})

local RadialProgress = Roact.Component:extend("RadialProgress")
RadialProgress.defaultProps = {
	Clockwise = true,
}

local Roact_createElement = Roact.createElement

function RadialProgress:render()
	local imageSize = self.props.ImageSize

	local gradientRotation = self.props.Clockwise and self.props.Value:map(function(value)
		return (value - 0.5) * 360
	end)

	local isUnderHalf = self.props.Value:map(function(value)
		return value < 0.5
	end)

	local isOverHalf = self.props.Value:map(function(value)
		return value > 0.5
	end)

	return Roact_createElement("Frame", {
		AnchorPoint = self.props.AnchorPoint,
		BackgroundTransparency = 1,
		Position = self.props.Position,
		Rotation = self.props.Rotation,
		LayoutOrder = self.props.LayoutOrder,
		SizeConstraint = self.props.SizeConstraint,
		Size = self.props.Size,
	}, {
		Left = Roact_createElement("ImageLabel", {
			BackgroundTransparency = 1,
			Image = self.props.Image,
			ImageColor3 = self.props.ImageColor3,
			ImageRectSize = Vector2.new(imageSize.X / 2, imageSize.Y),
			ImageTransparency = self.props.ImageTransparency,
			Size = UDim2.fromScale(0.5, 1),
			Visible = not self.props.Clockwise or isOverHalf,
		}, {
			Gradient = Roact_createElement("UIGradient", {
				Enabled = self.props.Clockwise and true or isUnderHalf,
				Offset = Vector2.new(0.5, 0),
				Rotation = gradientRotation,
				Transparency = TRANSPARENCY_SEQUENCE,
			}),
		}),

		Right = Roact_createElement("ImageLabel", {
			BackgroundTransparency = 1,
			Image = self.props.Image,
			ImageColor3 = self.props.ImageColor3,
			ImageRectOffset = Vector2.new(imageSize.X / 2, 0),
			ImageRectSize = Vector2.new(imageSize.X / 2, imageSize.Y),
			ImageTransparency = self.props.ImageTransparency,
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.fromScale(0.5, 1),
			Visible = self.props.Clockwise or isOverHalf,
		}, {
			Gradient = Roact_createElement("UIGradient", {
				Enabled = self.props.Clockwise and isUnderHalf or true,
				Offset = Vector2.new(-0.5, 0),
				Rotation = gradientRotation,
				Transparency = TRANSPARENCY_SEQUENCE,
			}),
		}),
	})
end

return RadialProgress