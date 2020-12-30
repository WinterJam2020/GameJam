local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local Flipper = Resources:LoadLibrary("Flipper")
local RadialProgress = Resources:LoadLibrary("RadialProgress")
local Roact = Resources:LoadLibrary("Roact")
local RoactFlipper = Resources:LoadLibrary("RoactFlipper")
local RoundedRectangle = Resources:LoadLibrary("RoundedRectangle")

local Countdown = Roact.Component:extend("Countdown")
Countdown.defaultProps = {
	Active = false,
	Duration = 60,
	GradientColor3 = Color3.fromRGB(201, 201, 201),
	Size = UDim2.fromScale(0.25, 0.075),

	UseGradientProgress = true,
	ReverseProgress = true, -- true = right to left, false = left to right
	Destroy = function()
		print("destroy")
	end,
}

local VISIBLE_VECTOR2 = Vector2.new(0.4, 0)
local HIDDEN_VECTOR2 = Vector2.new(-0.7, 0)

function Countdown:init(props)
	self.motor = Flipper.SingleMotor.new(0)
	self.timeRemaining, self.setTimeRemaining = Roact.createBinding(0)
	self.activeTime = props.Duration

	-- local duration = props.Duration
	self.offset = props.ReverseProgress and self.timeRemaining:map(function(value)
		-- print(value / self.activeTime)
		-- return HIDDEN_VECTOR2:Lerp(VISIBLE_VECTOR2, Math.Map(value, 0, duration, 0, 1))
		return HIDDEN_VECTOR2:Lerp(VISIBLE_VECTOR2, value / self.activeTime)
	end) or self.timeRemaining:map(function(value)
		-- return VISIBLE_VECTOR2:Lerp(HIDDEN_VECTOR2, Math.Map(value, 0, duration, 0, 1))
		return VISIBLE_VECTOR2:Lerp(HIDDEN_VECTOR2, value / self.activeTime)
	end)
end

function Countdown:didMount()
	if self.props.Active and not self.connection then
		self.motor:SetGoal(Flipper.Spring.new(1, {
			DampingRatio = 1.2,
			Frequency = 6,
		}))

		local startTime = os.clock()
		self.connection = RunService.Heartbeat:Connect(function()
			local timeRemaining = self.activeTime - math.clamp(os.clock() - startTime, 0, self.activeTime)
			if timeRemaining == 0 and self.props.Active then
				self:Close()
				self.connection = self.connection:Disconnect()
			end

			self.setTimeRemaining(timeRemaining)
		end)
	end
end

function Countdown:Close()
	if not self.isClosing then
		self.isClosing = true
		self.motor:SetGoal(Flipper.Spring.new(0, {
			DampingRatio = 0.75,
			Frequency = 4,
		}))

		self.motor:OnComplete(self.props.Destroy)
	end
end

function Countdown:didUpdate(lastProps)
	if self.props.Active and not self.connection then
		self.motor:SetGoal(Flipper.Spring.new(1, {
			DampingRatio = 1.2,
			Frequency = 6,
		}))

		local startTime = os.clock()
		self.connection = RunService.Heartbeat:Connect(function()
			local timeRemaining = self.activeTime - math.clamp(os.clock() - startTime, 0, self.activeTime)
			if timeRemaining == 0 and self.props.Active then
				self:Close()
				self.connection = self.connection:Disconnect()
			end

			self.setTimeRemaining(timeRemaining)
		end)
	end

	if self.props.Active ~= lastProps.Active and not self.props.Active then
		self:Close()
	end
end

function Countdown:willUnmount()
	if self.connection then
		self.connection:Disconnect()
	end
end

local Roact_createElement = Roact.createElement

function Countdown:render()
	local transparency = RoactFlipper.GetBinding(self.motor):map(function(value)
		return 1 - value
	end)

	return self.props.UseGradientProgress and Roact_createElement("Frame", {
		AnchorPoint = self.props.AnchorPoint,
		BackgroundTransparency = 1,
		Position = self.props.Position,
		Size = self.props.Size,
		Visible = self.props.Visible,
	}, {
		TimerFrame = Roact_createElement(RoundedRectangle, {
			Radius = 18,
			Size = UDim2.fromScale(1, 1),
			Transparency = transparency,
		}, {
			UIGradient = Roact_createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, self.props.GradientColor3),
					ColorSequenceKeypoint.new(0.99, self.props.GradientColor3),
					ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
				}),

				Rotation = 45,
				Offset = self.offset,
			}),

			Contents = Roact_createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.85, 0.85),
			}, {
				UIListLayout = Roact_createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				CountdownTime = Roact_createElement("TextLabel", {
					BackgroundTransparency = 1,
					Text = self.timeRemaining:map(math.ceil),
					Font = Enum.Font.GothamBold,
					TextColor3 = Color3.new(),
					TextTransparency = transparency,
					Size = UDim2.fromScale(1, 1),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					TextScaled = true,
				}),
			}),
		}),
	}) or Roact_createElement("Frame", {
		AnchorPoint = self.props.AnchorPoint,
		BackgroundTransparency = 1,
		Position = self.props.Position,
		Size = self.props.Size,
		Visible = self.props.Visible,
	}, {
		TimerFrame = Roact_createElement(RoundedRectangle, {
			Radius = 18,
			Size = UDim2.fromScale(1, 1),
			Transparency = transparency,
		}, {
			UIGradient = Roact_createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, self.props.GradientColor3),
					ColorSequenceKeypoint.new(0.99, self.props.GradientColor3),
					ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
				}),

				Rotation = 45,
			}),

			Contents = Roact_createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.85, 0.85),
			}, {
				UIListLayout = Roact_createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				CountdownTime = Roact_createElement("TextLabel", {
					BackgroundTransparency = 1,
					Text = self.timeRemaining:map(math.ceil),
					Font = Enum.Font.GothamBold,
					TextColor3 = Color3.new(),
					TextTransparency = transparency,
					LayoutOrder = 1,
					Size = UDim2.fromScale(1, 1),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					TextScaled = true,
				}),

				RadialProgress = Roact_createElement(RadialProgress, {
					Image = "rbxassetid://5409990484",
					ImageTransparency = transparency,
					ImageSize = Vector2.new(36, 36),
					Size = UDim2.fromScale(1, 1),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					Value = self.timeRemaining:map(function(value)
						return value / self.activeTime
					end),
				}),
			}),
		}),
	})
end

return Countdown