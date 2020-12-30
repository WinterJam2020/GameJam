local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local Flipper = Resources:LoadLibrary("Flipper")
local Lerps = Resources:LoadLibrary("Lerps")
local Promise = Resources:LoadLibrary("Promise")
local Roact = Resources:LoadLibrary("Roact")

local SwShButton = Roact.Component:extend("SwShButton")
SwShButton.defaultProps = {
	BackgroundColor3 = Color3.new(1, 1, 1),
	HoveredColor3 = Color3.new(),
	GradientColor3 = Color3.fromRGB(201, 201, 201),
	Text = "Start Skiing",

	Activated = function()
	end,
}

local Roact_createElement = Roact.createElement

local HIDDEN_VECTOR2 = Vector2.new(-1, 0)
local VISIBLE_VECTOR2 = Vector2.new()

local SPRING_PROPERTIES = {
	DampingRatio = 0.9,
	Frequency = 4,
}

local Color3Lerp = Lerps.Color3

function SwShButton:init(props)
	self.offsetMotor = Flipper.SingleMotor.new(0)
	self.colorMotor = Flipper.SingleMotor.new(0)

	self.color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, props.GradientColor3),
		ColorSequenceKeypoint.new(0.99, props.GradientColor3),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
	})

	self:setState({
		hovered = false,
		offset = Vector2.new(-1, 0),
		backgroundColor = props.BackgroundColor3,
		textColor = props.TextColor3 or props.HoveredColor3,
	})

	self.offsetMotor:OnStep(function(alpha)
		if self.state.hovered then
			self:setState({
				offset = HIDDEN_VECTOR2:Lerp(VISIBLE_VECTOR2, alpha),
			})
		else
			self:setState({
				offset = VISIBLE_VECTOR2:Lerp(HIDDEN_VECTOR2, alpha),
			})
		end
	end)

	self.activated = function(inputObject: InputObject)
		props.Activated(inputObject)
	end

	self.colorMotor:OnStep(function(alpha)
		if self.state.hovered then
			self:setState({
				backgroundColor = Color3Lerp(self.state.backgroundColor, props.HoveredColor3, alpha),
				textColor = Color3Lerp(self.state.textColor, props.BackgroundColor3, alpha),
			})
		else
			if self.props.TextColor3 then
				self:setState({
					backgroundColor = Color3Lerp(self.state.backgroundColor, props.BackgroundColor3, alpha),
					textColor = Color3Lerp(self.state.textColor, props.TextColor3, alpha),
				})
			else
				self:setState({
					backgroundColor = Color3Lerp(self.state.backgroundColor, props.BackgroundColor3, alpha),
					textColor = Color3Lerp(self.state.textColor, props.HoveredColor3, alpha),
				})
			end
		end
	end)
end

function SwShButton:render()
	return Roact_createElement("TextButton", {
		AnchorPoint = self.props.AnchorPoint,
		BackgroundColor3 = self.state.backgroundColor,
		LayoutOrder = self.props.LayoutOrder,
		Position = self.props.Position,
		Size = self.props.Size,
		Text = "",

		[Roact.Event.InputBegan] = function(_, inputObject: InputObject)
			if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
				self.activated(inputObject)
			elseif inputObject.UserInputType == Enum.UserInputType.MouseMovement then
				self:setState({
					hovered = true,
				})

				if self.props.Hovered then
					self.props.Hovered(true)
				end

				self.colorMotor:SetGoal(Flipper.Spring.new(1))
				Promise.Delay(0.025):Then(function()
					self.offsetMotor:SetGoal(Flipper.Instant.new(1))
					Promise.Delay(0.025):Then(function()
						self.offsetMotor:SetGoal(Flipper.Spring.new(0, SPRING_PROPERTIES))
					end)
				end)
			end
		end,

		[Roact.Event.InputEnded] = function(_, inputObject: InputObject)
			if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
				self:setState({
					hovered = false,
				})

				if self.props.Hovered then
					self.props.Hovered(false)
				end

				self.colorMotor:SetGoal(Flipper.Spring.new(0))
				Promise.Delay(0.025):Then(function()
					self.offsetMotor:SetGoal(Flipper.Instant.new(0))
					Promise.Delay(0.025):Then(function()
						self.offsetMotor:SetGoal(Flipper.Spring.new(1, SPRING_PROPERTIES))
					end)
				end)

				-- Promise.Delay(0.05):Then(function()
				-- 	self.offsetMotor:SetGoal(Flipper.Spring.new(1))
				-- end)
			end
		end,
	}, {
		UICorner = Roact_createElement("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),

		UIGradient = Roact_createElement("UIGradient", {
			Color = self.color,
			Offset = self.state.offset,
			Rotation = 45,
		}),

		ButtonText = Roact_createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.7, 0.5),
			Text = self.props.Text,
			TextColor3 = self.state.textColor,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
end

return SwShButton