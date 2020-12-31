local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)

local Constants = Resources:LoadLibrary("Constants")
local Flipper = Resources:LoadLibrary("Flipper")
local Janitor = Resources:LoadLibrary("Janitor")
local Padding = Resources:LoadLibrary("Padding")
local Promise = Resources:LoadLibrary("Promise")
local Roact = Resources:LoadLibrary("Roact")
local Scale = Resources:LoadLibrary("Scale")
local Services = Resources:LoadLibrary("Services")
local SwShButton = Resources:LoadLibrary("SwShButton")
local ValueObject = Resources:LoadLibrary("ValueObject")

local RunService: RunService = Services.RunService

local GameEvent = Resources:GetRemoteEvent("GameEvent")

local Menu = Roact.Component:extend("Menu")
Menu.defaultProps = {
	MenuLayoutOrder = 0,
	Visible = true,
}

local Roact_createElement = Roact.createElement
local Promise_FromEvent = Promise.FromEvent

function Menu:init()
	self.janitor = Janitor.new()
	self.pageRef = Roact.createRef()
	self.motor = self.janitor:Add(Flipper.SingleMotor.new(0), "Destroy")
	self.displayValue = self.janitor:Add(ValueObject.new(0), "Destroy")

	self.janitor:Add(self.displayValue.Changed:Connect(function(newValue)
		print("self.displayValue.Changed:", newValue)
		if newValue and self.pageRef then
			local uiPageLayout: UIPageLayout = self.pageRef:getValue()
			if uiPageLayout then
				uiPageLayout:JumpToIndex(newValue)
			end
		end
	end), "Disconnect")

	-- self:setState({
	-- 	visible = props.Visible,
	-- })

	-- print(Debug.TableToString(self.props, true, "self.props"))
	-- print(Debug.TableToString(self.state, true, "self.state"))
end

function Menu:willUpdate(nextProps)
	if nextProps.Visible ~= self.props.Visible and not nextProps.Visible then
		local uiPageLayout: UIPageLayout = self.pageRef:getValue()
		if uiPageLayout then
			uiPageLayout:JumpToIndex(0)
		end
	end
end

function Menu:willUnmount()
	self.janitor:Destroy()
end

local PADDING_SIZE = UDim2.fromScale(1, 0.025)

function Menu:render()
	return Roact_createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = self.props.Visible,
	}, {
		UIPageLayout = Roact_createElement("UIPageLayout", {
			Animated = true,
			EasingDirection = Enum.EasingDirection.Out,
			EasingStyle = Enum.EasingStyle.Cubic,
			TweenTime = 0.25,

			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,

			GamepadInputEnabled = false,
			ScrollWheelInputEnabled = false,
			TouchInputEnabled = false,

			[Roact.Ref] = self.pageRef,
		}),

		MainFrame = Roact_createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			LayoutOrder = 0,
		}, {
			ContainerFrame = Roact_createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, {
				UIScale = Roact_createElement(Scale, {
					Scale = 0.85,
					Size = Vector2.new(850, 850),
				}),

				UIListLayout = Roact_createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				TitleLabel = Roact_createElement("TextLabel", {
					BackgroundTransparency = 1,
					LayoutOrder = 0,
					Size = UDim2.fromScale(1, 0.15),
					Font = Enum.Font.GothamBlack,
					Text = "Untitled Ski Game",
					TextScaled = true,
					TextColor3 = Color3.new(1, 1, 1),
					TextStrokeTransparency = 0.85,
				}),

				Padding1 = Roact_createElement(Padding, {
					LayoutOrder = 1,
					Size = UDim2.fromScale(1, 0.05),
				}),

				PlayButton = Roact_createElement(SwShButton, {
					Text = "Start Skiing",
					LayoutOrder = 2,
					-- HoveredColor3 = Color.Blue[500],
					-- GradientColor3 = Color.Blue[100],
					-- TextColor3 = Color.Black,
					Size = UDim2.fromScale(0.5, 0.15),
					Activated = function()
						Promise_FromEvent(self.pageRef:getValue().Stopped, function()
							return true
						end):Then(function()
							if self.props.StartButtonFunction then
								self.props.StartButtonFunction()
							end

							if RunService:IsRunning() then
								GameEvent:FireServer(Constants.READY_PLAYER)
							end
						end)

						self.displayValue.Value = 1
					end,
				}),

				Padding3 = Roact_createElement(Padding, {
					LayoutOrder = 3,
					Size = PADDING_SIZE,
				}),

				StatsButton = Roact_createElement(SwShButton, {
					Text = "Player Stats",
					LayoutOrder = 4,
					Size = UDim2.fromScale(0.5, 0.15),
					Activated = function()
						self.displayValue.Value = 2
					end,
				}),

				Padding5 = Roact_createElement(Padding, {
					LayoutOrder = 5,
					Size = PADDING_SIZE,
				}),

				SettingsButton = Roact_createElement(SwShButton, {
					Text = "Settings",
					LayoutOrder = 6,
					Size = UDim2.fromScale(0.5, 0.15),
					Activated = function()
						self.displayValue.Value = 3
					end,
				}),

				Padding7 = Roact_createElement(Padding, {
					LayoutOrder = 7,
					Size = PADDING_SIZE,
				}),

				CreditsButton = Roact_createElement(SwShButton, {
					Text = "Credits",
					LayoutOrder = 8,
					Size = UDim2.fromScale(0.5, 0.15),
					Activated = function()
						self.displayValue.Value = 4
					end,
				}),
			}),
		}),

		PlayFrame = Roact_createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			LayoutOrder = 1,
		}),

		StatsFrame = Roact_createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			LayoutOrder = 2,
		}, {
			ContainerFrame = Roact_createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, {
				UIScale = Roact_createElement(Scale, {
					Scale = 0.85,
					Size = Vector2.new(850, 850),
				}),

				UIListLayout = Roact_createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				TitleLabel = Roact_createElement("TextLabel", {
					BackgroundTransparency = 1,
					LayoutOrder = 0,
					Size = UDim2.fromScale(1, 0.15),
					Font = Enum.Font.GothamBlack,
					Text = "Player Stats",
					TextScaled = true,
					TextColor3 = Color3.new(1, 1, 1),
					TextStrokeTransparency = 0.85,
				}),

				Padding1 = Roact_createElement(Padding, {
					LayoutOrder = 1,
					Size = UDim2.fromScale(1, 0.05),
				}),

				BackButton = Roact_createElement(SwShButton, {
					Text = "Go Back",
					LayoutOrder = 3,
					Size = UDim2.fromScale(0.5, 0.15),
					Activated = function()
						self.displayValue.Value = 0
					end,
				}),
			}),
		}),

		SettingsFrame = Roact_createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			LayoutOrder = 3,
		}, {
			ContainerFrame = Roact_createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, {
				UIScale = Roact_createElement(Scale, {
					Scale = 0.85,
					Size = Vector2.new(850, 850),
				}),

				UIListLayout = Roact_createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				TitleLabel = Roact_createElement("TextLabel", {
					BackgroundTransparency = 1,
					LayoutOrder = 0,
					Size = UDim2.fromScale(1, 0.15),
					Font = Enum.Font.GothamBlack,
					Text = "Settings",
					TextScaled = true,
					TextColor3 = Color3.new(1, 1, 1),
					TextStrokeTransparency = 0.85,
				}),

				Padding1 = Roact_createElement(Padding, {
					LayoutOrder = 1,
					Size = UDim2.fromScale(1, 0.05),
				}),

				BackButton = Roact_createElement(SwShButton, {
					Text = "Go Back",
					LayoutOrder = 3,
					Size = UDim2.fromScale(0.5, 0.15),
					Activated = function()
						self.displayValue.Value = 0
					end,
				}),
			}),
		}),

		CreditsFrame = Roact_createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			LayoutOrder = 4,
		}, {
			ContainerFrame = Roact_createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, {
				UIScale = Roact_createElement(Scale, {
					Scale = 0.85,
					Size = Vector2.new(850, 850),
				}),

				UIListLayout = Roact_createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				TitleLabel = Roact_createElement("TextLabel", {
					BackgroundTransparency = 1,
					LayoutOrder = 0,
					Size = UDim2.fromScale(1, 0.15),
					Font = Enum.Font.GothamBlack,
					Text = "Credits",
					TextScaled = true,
					TextColor3 = Color3.new(1, 1, 1),
					TextStrokeTransparency = 0.85,
				}),

				Padding1 = Roact_createElement(Padding, {
					LayoutOrder = 1,
					Size = UDim2.fromScale(1, 0.05),
				}),

				BackButton = Roact_createElement(SwShButton, {
					Text = "Go Back",
					LayoutOrder = 3,
					Size = UDim2.fromScale(0.5, 0.15),
					Activated = function()
						self.displayValue.Value = 0
					end,
				}),
			}),
		}),
	})
end

return Menu

-- return RoactRodux.connect(function(state)
-- 	return {
-- 		Visible = state.MenuVisible,
-- 	}
-- end, function(dispatch)
-- 	return {
-- 		SetLoaded = function(isLoaded)
-- 			dispatch({
-- 				type = "Loaded",
-- 				IsLoaded = isLoaded,
-- 			})
-- 		end,
-- 	}
-- end)(Menu)