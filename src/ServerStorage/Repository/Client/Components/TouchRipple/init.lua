local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Flipper = Resources:LoadLibrary("Flipper")
local FlipperBinding = Resources:LoadLibrary("FlipperBinding")
local Roact = Resources:LoadLibrary("Roact")

local EXPAND_SPRING = {
	DampingRatio = 2,
	Frequency = 7,
}

local TouchRipple = Roact.Component:extend("TouchRipple")
TouchRipple.defaultProps = {
	Color = Color3.new(1, 1, 1),
	Transparency = 0.9,
	ZIndex = 1,
}

function TouchRipple:init()
	self.ref = Roact.createRef()
	self.motor = Flipper.GroupMotor.new({
		scale = 0,
		opacity = 0,
	})

	self.binding = FlipperBinding.FromMotor(self.motor)
	self.position, self.setPosition = Roact.createBinding(Vector2.new())
end

function TouchRipple:Reset()
	self.motor:SetGoal({
		scale = Flipper.Instant.new(0),
		opacity = Flipper.Instant.new(0),
	})

	-- Forces motor to update
	self.motor:Step(0)
end

function TouchRipple:CalculateRadius(position)
	local container = self.ref.current

	if container then
		local corner = Vector2.new(
			math.floor(1 - position.X + 0.5),
			math.floor(1 - position.Y + 0.5)
		)

		local size = container.AbsoluteSize
		local ratio = size / math.min(size.X, size.Y)

		return (corner * ratio - position * ratio).Magnitude
	else
		return 0
	end
end

function TouchRipple:render()
	local scale = FlipperBinding.DeriveProperty(self.binding, "scale")
	local transparency = FlipperBinding.DeriveProperty(self.binding, "opacity"):map(function(value)
		return 1 - value
	end)

	transparency = Roact.joinBindings({
		transparency,
		self.props.Transparency,
	}):map(FlipperBinding.BlendAlpha)

	return Roact.createElement("Frame", {
		ClipsDescendants = true,
		Size = UDim2.fromScale(1, 1),
		ZIndex = self.props.ZIndex,
		BackgroundTransparency = 1,

		[Roact.Ref] = self.ref,

		[Roact.Event.InputBegan] = function(object, input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				self:Reset()

				local position = Vector2.new(input.Position.X, input.Position.Y)
				local relativePosition = (position - object.AbsolutePosition) / object.AbsoluteSize

				self.setPosition(relativePosition)

				self.motor:SetGoal({
					scale = Flipper.Spring.new(1, EXPAND_SPRING),
					opacity = Flipper.Spring.new(1, EXPAND_SPRING),
				})

				input:GetPropertyChangedSignal("UserInputState"):Connect(function()
					local userInputState = input.UserInputState

					if
						userInputState == Enum.UserInputState.Cancel
						or userInputState == Enum.UserInputState.End
					then
						self.motor:SetGoal({
							opacity = Flipper.Spring.new(0, {
								DampingRatio = 1,
								Frequency = 5,
							}),
						})
					end
				end)
			end
		end,
	}, {
		Circle = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = "rbxassetid://2609138523",
			ImageColor3 = self.props.Color,
			ImageTransparency = transparency,

			Size = Roact.joinBindings({
				scale = scale,
				position = self.position,
			}):map(function(values)
				local targetSize = self:CalculateRadius(values.position) * 2
				local currentSize = targetSize * values.scale

				local container = self.ref.current

				if container then
					local containerSize = container.AbsoluteSize
					local containerAspect = containerSize.X / containerSize.Y

					return UDim2.fromScale(
						currentSize / math.max(containerAspect, 1),
						currentSize * math.min(containerAspect, 1)
					)
				end
			end),

			Position = self.position:map(function(value)
				return UDim2.fromScale(value.X, value.Y)
			end),
		}),
	})
end

return TouchRipple