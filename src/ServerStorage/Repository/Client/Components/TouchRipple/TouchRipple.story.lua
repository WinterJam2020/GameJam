local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)

local Flipper = Resources:LoadLibrary("Flipper")
local FlipperBinding = Resources:LoadLibrary("FlipperBinding")
local Roact = Resources:LoadLibrary("Roact")
local SlicedImage = Resources:LoadLibrary("SlicedImage")
local TouchRipple = require(script.Parent)
local Services = Resources:LoadLibrary("Services")

local TextService: TextService = Services.TextService

local TextButton = Roact.Component:extend("TextButton")
TextButton.defaultProps = {
	Enabled = true,
	Text = "Text",
	Style = "Solid",
	AnchorPoint = Vector2.new(),
	Position = UDim2.new(),
	LayoutOrder = 0,
	Transparency = 0.85,

	OnClick = function()
	end,
}

local SPRING_PROPS = {
	DampingRatio = 1,
	Frequency = 5,
}

local ROUNDED_BACKGROUND = {
	Center = Rect.new(10, 10, 10, 10),
	Image = "rbxassetid://5981360418",
	Scale = 0.5,
}

local function HexColor(Decimal)
	local Red = bit32.band(bit32.rshift(Decimal, 16), 2 ^ 8 - 1)
	local Green = bit32.band(bit32.rshift(Decimal, 8), 2 ^ 8 - 1)
	local Blue = bit32.band(Decimal, 2 ^ 8 - 1)

	return Color3.fromRGB(Red, Green, Blue)
end

function TextButton:init()
	self.motor = Flipper.GroupMotor.new({
		hover = 0,
		enabled = self.props.Enabled and 1 or 0,
	})

	self.binding = FlipperBinding.FromMotor(self.motor)
end

function TextButton:didUpdate(lastProps)
	if lastProps.Enabled ~= self.props.Enabled then
		self.motor:SetGoal({
			enabled = Flipper.Spring.new(self.props.Enabled and 1 or 0),
		})
	end
end

function TextButton:render()
	local textSize = TextService:GetTextSize(
		self.props.Text, 18, Enum.Font.GothamSemibold,
		Vector2.new(math.huge, math.huge)
	)

	local style = self.props.Style
	local theme = {
		ActionFillColor = HexColor(0xFFFFFF),
		ActionFillTransparency = 0.8,
		Enabled = {
			TextColor = HexColor(0xFFFFFF),
			BackgroundColor = HexColor(0xE13835),
		},

		Disabled = {
			TextColor = HexColor(0xFFFFFF),
			BackgroundColor = HexColor(0xE13835),
		},
	}

	local bindingHover = FlipperBinding.DeriveProperty(self.binding, "hover")
	local bindingEnabled = FlipperBinding.DeriveProperty(self.binding, "enabled")

	return Roact.createElement("ImageButton", {
		Size = UDim2.fromOffset(15 + textSize.X + 15, 34),
		Position = self.props.Position,
		AnchorPoint = self.props.AnchorPoint,

		LayoutOrder = self.props.LayoutOrder,
		BackgroundTransparency = 1,

		[Roact.Event.Activated] = self.props.OnClick,

		[Roact.Event.MouseEnter] = function()
			self.motor:SetGoal({
				hover = Flipper.Spring.new(1, SPRING_PROPS),
			})
		end,

		[Roact.Event.MouseLeave] = function()
			self.motor:SetGoal({
				hover = Flipper.Spring.new(0, SPRING_PROPS),
			})
		end,
	}, {
		TouchRipple = Roact.createElement(TouchRipple, {
			Color = theme.ActionFillColor,
			Transparency = self.props.Transparency:map(function(value)
				local array = table.create(2, theme.ActionFillTransparency)
				array[2] = value
				return FlipperBinding.BlendAlpha(array)
			end),
			ZIndex = 2,
		}),

		Text = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamSemibold,
			Size = UDim2.fromScale(1, 1),
			Text = self.props.Text,
			TextColor3 = FlipperBinding.MapLerp(bindingEnabled, theme.Enabled.TextColor, theme.Disabled.TextColor),
			TextSize = 18,
			TextTransparency = self.props.Transparency,
		}),

		Border = style == "Bordered" and Roact.createElement(SlicedImage, {
			Color = FlipperBinding.MapLerp(bindingEnabled, theme.Enabled.BorderColor, theme.Disabled.BorderColor),
			Size = UDim2.fromScale(1, 1),
			Slice = {
				Image = "rbxassetid://5981360137",
				Center = Rect.new(10, 10, 10, 10),
				Scale = 0.5,
			},

			Transparency = self.props.Transparency,
			ZIndex = 0,
		}),

		HoverOverlay = Roact.createElement(SlicedImage, {
			Slice = ROUNDED_BACKGROUND,
			Color = theme.ActionFillColor,
			Transparency = Roact.joinBindings({
				hover = bindingHover:map(function(value)
					return 1 - value
				end),
				transparency = self.props.Transparency,
			}):map(function(values)
				local array = table.create(3, theme.ActionFillTransparency)
				array[2], array[3] = values.hover, values.transparency
				return FlipperBinding.BlendAlpha(array)
			end),

			Size = UDim2.fromScale(1, 1),
			ZIndex = -1,
		}),

		Background = style == "Solid" and Roact.createElement(SlicedImage, {
			Slice = ROUNDED_BACKGROUND,
			Color = FlipperBinding.MapLerp(bindingEnabled, theme.Enabled.BackgroundColor, theme.Disabled.BackgroundColor),
			Transparency = self.props.Transparency,
			Size = UDim2.fromScale(1, 1),
			ZIndex = -2,
		}),
	})
end

local function CreateButtons()
	return Roact.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Button1 = Roact.createElement(TextButton, {
			Enabled = true,
			Text = "Button1",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			LayoutOrder = 0,
			Transparency = 0.85,

			OnClick = function()
			end,
		}),
	})
end

return function(Target)
	local Tree = Roact.mount(Roact.createElement(CreateButtons), Target, "TouchRipple")
	return function()
		Roact.unmount(Tree)
	end
end