local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Resources = require(ReplicatedStorage.Resources)
local Color = Resources:LoadLibrary("Color")
local Enumeration = Resources:LoadLibrary("Enumerations")
local PseudoInstance = Resources:LoadLibrary("PseudoInstance")
local Scheduler = Resources:LoadLibrary("Scheduler")
local Tween = Resources:LoadLibrary("Tween")
local Typer = Resources:LoadLibrary("Typer")

Resources:LoadLibrary("Rippler")
Resources:LoadLibrary("Shadow")

-- Elevations
local RAISED_BASE_ELEVATION = 3
local RAISED_ELEVATION = 8

Enumeration.ButtonStyle = {"Flat", "Outlined", "Contained"}

local StateOpacity = { -- TODO: Derive these values based on the PrimaryColor3's luminosity
	-- Material Design specs have values which are more subtle, which I don't think look ideal
	[Enumeration.ButtonStyle.Flat.Value] = {
		Hover = 0.12;
		Pressed = 0.265;
	};

	[Enumeration.ButtonStyle.Outlined.Value] = {
		Hover = 0.12; -- 0.035;
		Pressed = 0.265; --0.125;
	};

	[Enumeration.ButtonStyle.Contained.Value] = {
		Hover = 0.12; --0.075;
		Pressed = 0.3; -- 0.265;
	};
}

local RaisedImages = {
	[0] = "rbxassetid://132155326";
	[2] = "rbxassetid://1934672242";
	[4] = "rbxassetid://1934624205";
	[8] = "rbxassetid://1935044829";
}

local OutlinedImages = {
	[0] = "rbxassetid://2091129360";
	[2] = "rbxassetid://1981015282";
	[4] = "rbxassetid://1981015668";
	[8] = "rbxassetid://1981285569";
}

local Rectangle = setmetatable({}, {
	__index = function(self, Index)
		local Value = Rect.new(Index, Index, 256 - Index, 256 - Index)
		self[Index] = Value
		return Value
	end;
})

for Size in next, RaisedImages do
	local _ = Rectangle[Size]
end

local ImageButton = Instance.new("ImageButton")
ImageButton.BackgroundTransparency = 1
ImageButton.ScaleType = Enum.ScaleType.Slice

local TextLabel = Instance.new("TextLabel")
TextLabel.BackgroundTransparency = 1
TextLabel.Font = Enum.Font.SourceSansSemibold
TextLabel.Size = UDim2.fromScale(0.85, 0.85)
TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
TextLabel.Position = UDim2.fromScale(0.5, 0.5)
TextLabel.TextSize = 16
TextLabel.Parent = ImageButton

--local TextLabel = Instance.new("TextLabel")
--TextLabel.BackgroundTransparency = 1
--TextLabel.Font = Enum.Font.SourceSansSemibold
--TextLabel.Size = UDim2.new(1, 0, 1, 0)
--TextLabel.TextSize = 16
--TextLabel.Parent = ImageButton

local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
UITextSizeConstraint.MaxTextSize = 100
UITextSizeConstraint.Parent = TextLabel

local OutlineImage = Instance.new("ImageLabel")
OutlineImage.BackgroundTransparency = 1
OutlineImage.Size = UDim2.fromScale(1, 1)
OutlineImage.ScaleType = Enum.ScaleType.Slice
OutlineImage.ImageTransparency = 0.88
OutlineImage.Name = "Outline"
OutlineImage.ImageColor3 = Color.Black

local TOOLTIP_BORDER_RADIUS = 4

local TooltipObject = Instance.new("ImageLabel")
TooltipObject.BackgroundTransparency = 1
TooltipObject.ScaleType = Enum.ScaleType.Slice
TooltipObject.ImageTransparency = 0.1
TooltipObject.ImageColor3 = Color3.fromRGB(97, 97, 97)
TooltipObject.Image = RaisedImages[TOOLTIP_BORDER_RADIUS]
TooltipObject.SliceCenter = Rectangle[TOOLTIP_BORDER_RADIUS]
TooltipObject.Name = "Tooltip"
TooltipObject.AnchorPoint = Vector2.new(0.5, 0)
TooltipObject.Position = UDim2.new(0.5, 0, 1, 8)

local ToolTipLabel = TextLabel:Clone()
ToolTipLabel.TextColor3 = Color.White
ToolTipLabel.TextSize = 12
ToolTipLabel.TextTransparency = 1
ToolTipLabel.Name = "TextLabel"
ToolTipLabel.Parent = TooltipObject

local MouseMovement = Enum.UserInputType.MouseMovement

local LARGE_FRAME_SIZE = Vector2.new(32767, 32767)

local Invisify = {UserInputType = MouseMovement}

return PseudoInstance:Register("RippleButton", {
	WrappedProperties = {
		Object = {"AnchorPoint", "Active", "Name", "Size", "Position", "LayoutOrder", "NextSelectionDown", "NextSelectionLeft", "NextSelectionRight", "NextSelectionUp", "Parent"};
		TextLabel = {"TextXAlignment", "TextYAlignment", "TextScaled", "TextWrapped"};
	};

	Internals = {
		"TextLabel", "Rippler", "OutlineImage", "OverlayOpacity", "Shadow", "TooltipObject", "InputBegan", "InputEnded", "InputChanged", "RegisteredRippleInputs";

		Render = function(self)
			local PrimaryColor3 = self.PrimaryColor3
			local Luminosity = PrimaryColor3.R * 0.299 + PrimaryColor3.G * 0.587 + PrimaryColor3.B * 0.114

			if self.Style == Enumeration.ButtonStyle.Contained then
				if self.Disabled then
					PrimaryColor3 = Color3.fromRGB(204, 204, 204)
				end

				local SecondaryColor3 = self.SecondaryColor3 or 0.5 < Luminosity and Color.Black or Color.White
				self.Rippler.RippleColor3 = SecondaryColor3
				self.TextLabel.TextColor3 = SecondaryColor3
				self.Object.ImageColor3 = PrimaryColor3
			else
				if self.Disabled then
					PrimaryColor3 = Color.Black
				end

				self.Rippler.RippleColor3 = PrimaryColor3
				self.TextLabel.TextColor3 = PrimaryColor3
				self.Object.ImageColor3 = PrimaryColor3
			end
		end;
	};

	Events = {
		OnPressed = function(self)
			local RegisteredRippleInputs = self.RegisteredRippleInputs

			return function(Signal)
				RegisteredRippleInputs[Enum.UserInputType.Touch.Value] = Signal
				RegisteredRippleInputs[Enum.UserInputType.MouseButton1.Value] = Signal
				RegisteredRippleInputs[Enum.UserInputType.Gamepad1.Value] = Signal
			end, function()
				RegisteredRippleInputs[Enum.UserInputType.Touch.Value] = nil
				RegisteredRippleInputs[Enum.UserInputType.MouseButton1.Value] = nil
				RegisteredRippleInputs[Enum.UserInputType.Gamepad1.Value] = nil
			end
		end;

		OnRightPressed = function(self)
			local RegisteredRippleInputs = self.RegisteredRippleInputs

			return function(Signal)
				RegisteredRippleInputs[Enum.UserInputType.MouseButton2.Value] = Signal
			end, function()
				RegisteredRippleInputs[Enum.UserInputType.MouseButton2.Value] = nil
			end
		end;

		OnMiddlePressed = function(self)
			local RegisteredRippleInputs = self.RegisteredRippleInputs

			return function(Signal)
				RegisteredRippleInputs[Enum.UserInputType.MouseButton3.Value] = Signal
			end, function()
				RegisteredRippleInputs[Enum.UserInputType.MouseButton3.Value] = nil
			end
		end;
	};

	Properties = {
		Elevation = Typer.AssignSignature(2, Typer.EnumerationOfTypeShadowElevation, function(self, Elevation)
			if Elevation.Value > 0 and self.Style ~= Enumeration.ButtonStyle.Contained then
				self.Style = Enumeration.ButtonStyle.Contained
				self.Shadow.Elevation = Elevation
			end

			self:Rawset("Elevation", Elevation)
		end);

		Text = Typer.AssignSignature(2, Typer.String, function(self, Text)
			self.TextLabel.Text = Text
			self:Rawset("Text", Text)
			self:Rawset("TextBounds", TextService:GetTextSize(Text, self.TextSize, self.Font, LARGE_FRAME_SIZE))
		end);

		TextSize = Typer.AssignSignature(2, Typer.Number, function(self, TextSize)
			self.TextLabel.TextSize = TextSize
			self:Rawset("TextSize", TextSize)
			self:Rawset("TextBounds", TextService:GetTextSize(self.Text, TextSize, self.Font, LARGE_FRAME_SIZE))
		end);

		MaxTextSize = Typer.AssignSignature(2, Typer.PositiveInteger, function(self, TextSize)
			self.TextLabel.UITextSizeConstraint.MaxTextSize = TextSize
			self:Rawset("TextSize", self.TextLabel.TextSize)
			self:Rawset("TextBounds", TextService:GetTextSize(self.Text, self.TextLabel.TextSize, self.Font, LARGE_FRAME_SIZE))
		end);

		Font = Typer.AssignSignature(2, Typer.EnumOfTypeFont, function(self, Font)
			self.TextLabel.Font = Font
			self:Rawset("Font", Font)
			self:Rawset("TextBounds", TextService:GetTextSize(self.Text, self.TextSize, Font, LARGE_FRAME_SIZE))
		end);

		TextTransparency = Typer.AssignSignature(2, Typer.Number, function(self, TextTransparency)
			if not self.Disabled then
				self.TextLabel.TextTransparency = TextTransparency
			end

			self:Rawset("TextTransparency", TextTransparency)
		end);

		Disabled = Typer.AssignSignature(2, Typer.Boolean, function(self, Disabled)
			if self.Disabled ~= Disabled  then
				if Disabled then
					if self.Style == Enumeration.ButtonStyle.Contained then
						self.Shadow.Visible = false
					end

					self.TextLabel.TextTransparency = 0.62
					self.Janitor:Remove("InputBegan")
					self.Janitor:Remove("InputEnded")
					self.Janitor:Remove("InputChanged")
				else
					if self.Style == Enumeration.ButtonStyle.Contained then
						self.Shadow.Visible = true
					end

					self.TextLabel.TextTransparency = self.TextTransparency
					self.Janitor:Add(self.Object.InputBegan:Connect(self.InputBegan), "Disconnect", "InputBegan")
					self.Janitor:Add(self.Object.InputEnded:Connect(self.InputEnded), "Disconnect", "InputEnded")
					self.Janitor:Add(self.Object.InputChanged:Connect(self.InputChanged), "Disconnect", "InputChanged")
				end

				self:Rawset("Disabled", Disabled)
				self:Render()
			end
		end);

		Tooltip = Typer.AssignSignature(2, Typer.String, function(self, Tip)
			if Tip == "" then
				self.TooltipObject = nil
				self.Janitor:Remove("TooltipObject")
			else
				self.TooltipObject = TooltipObject:Clone()
				self.TooltipObject.ZIndex = self.ZIndex + 1
				self.TooltipObject.TextLabel.Text = Tip
				self.TooltipObject.TextLabel.ZIndex = self.ZIndex + 2
				self.TooltipObject.Parent = self.Object

				self.Janitor:Add(self.TooltipObject, "Destroy", "TooltipObject")
			end

			self:Rawset("Tooltip", Tip)
		end);

		BorderRadius = Typer.AssignSignature(2, Typer.EnumerationOfTypeBorderRadius, function(self, BorderRadius)
			local Value = BorderRadius.Value
			local SliceCenter = Rectangle[Value]

			self.Object.Image = RaisedImages[Value]
			self.Object.SliceCenter = SliceCenter
			self.Rippler.BorderRadius = Value

			if self.Style == Enumeration.ButtonStyle.Outlined then
				self.OutlineImage.Image = OutlinedImages[Value]
				self.OutlineImage.SliceCenter = SliceCenter
			end

			self:Rawset("BorderRadius", BorderRadius)
		end);

		AspectRatio = Typer.AssignSignature(2, Typer.NonNegativeNumber, function(self, AspectRatio)
			if AspectRatio == 0 then
				local UIAspectRatioConstraint = self.Object:FindFirstChild("UIAspectRatioConstraint")
				if UIAspectRatioConstraint then
					UIAspectRatioConstraint:Destroy()
				end

				self:Rawset("AspectRatio", 0)
			else
				local UIAspectRatioConstraint = self.Object:FindFirstChild("UIAspectRatioConstraint")
				if not UIAspectRatioConstraint then
					UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
					UIAspectRatioConstraint.Parent = self.Object
				end

				UIAspectRatioConstraint.AspectRatio = AspectRatio
				self:Rawset("AspectRatio", AspectRatio)
			end
		end);

		Style = Typer.AssignSignature(2, Typer.EnumerationOfTypeButtonStyle, function(self, ButtonStyle)
			self:Rawset("Style", ButtonStyle)

			local StateData = StateOpacity[ButtonStyle.Value]
			self.OverlayOpacity = StateData.Hover
			self.Rippler.RippleTransparency = 1 - StateData.Pressed

			local IsOutlined = ButtonStyle == Enumeration.ButtonStyle.Outlined

			if ButtonStyle == Enumeration.ButtonStyle.Flat or IsOutlined then
				self.Object.ImageTransparency = 1
				self.Object.ImageColor3 = self.PrimaryColor3

				self.Janitor:Remove("Shadow")
				self.Shadow = nil

				self:Rawset("Elevation", Enumeration.ShadowElevation.Elevation0)
			elseif ButtonStyle == Enumeration.ButtonStyle.Contained then
				self.Object.ImageTransparency = 0
				-- self.Object.ImageColor3 = self.PrimaryColor3

				self.Shadow = PseudoInstance.new("Shadow")
				self.Shadow.Parent = self.Object
				self.Janitor:Add(self.Shadow, "Destroy", "Shadow")

				self.Elevation = RAISED_BASE_ELEVATION
				self.Shadow.Transparency = 0
			end

			self:Render()

			if IsOutlined then
				self.OutlineImage = OutlineImage:Clone()
				self.OutlineImage.ZIndex = self.ZIndex + 2
				self.OutlineImage.Parent = self.Object
				local Value = self.BorderRadius.Value

				self.OutlineImage.Image = OutlinedImages[Value]
				self.OutlineImage.SliceCenter = Rectangle[Value]
				self.Janitor:Add(self.OutlineImage, "Destroy", "OutlineImage")
			else
				self.OutlineImage = nil
				self.Janitor:Remove("OutlineImage")
			end
		end);

		PrimaryColor3 = Typer.AssignSignature(2, Typer.Color3, function(self, PrimaryColor3)
			self:Rawset("PrimaryColor3", PrimaryColor3)
			self:Render()
		end);

		SecondaryColor3 = Typer.AssignSignature(2, Typer.OptionalColor3, function(self, SecondaryColor3)
			self:Rawset("SecondaryColor3", SecondaryColor3)
			self:Render()
		end);

		Visible = Typer.AssignSignature(2, Typer.Boolean, function(self, Visible)
			self.Object.Visible = Visible
			if not Visible then
				self.InputEnded(Invisify)
			end

			self:Rawset("Visible", Visible)
		end);

		ZIndex = Typer.AssignSignature(2, Typer.Number, function(self, ZIndex)
			self.Object.ZIndex = ZIndex + 1
			self.TextLabel.ZIndex = ZIndex + 3

			if self.TooltipObject then
				self.TooltipObject.ZIndex = ZIndex + 1
				self.TooltipObject.TextLabel.ZIndex = ZIndex + 2
			end

			if self.OutlineImage then
				self.OutlineImage.ZIndex = ZIndex + 2
			end

			self:Rawset("ZIndex", ZIndex)
		end);
	};

	Methods = table.create(0);
	Init = function(self)
		self:Rawset("Object", ImageButton:Clone())
		self:Rawset("PrimaryColor3", Color.Black)
		self:Rawset("SecondaryColor3", nil)
		self:Rawset("Font", Enum.Font.SourceSansSemibold)
		self:Rawset("TextSize", 16)

		self.TextLabel = self.Object.TextLabel

		self.Rippler = PseudoInstance.new("Rippler")
		self.Rippler.RippleTransparency = 0.68

		self.Rippler.Parent = self.Object

		self.Style = Enumeration.ButtonStyle.Flat.Value
		self.BorderRadius = 4
		self.Tooltip = ""
		self.Text = ""
		self.ZIndex = 1
		self.TextTransparency = 0

		self.Janitor:Add(self.Object, "Destroy")
		self.Janitor:Add(self.TextLabel, "Destroy")
		self.Janitor:Add(self.Rippler, "Destroy")

		local Int = 0
		local IsHovered = false
		self.RegisteredRippleInputs = {}

		function self.InputBegan(InputObject)
			local Signal = self.RegisteredRippleInputs[InputObject.UserInputType.Value]

			if Signal then
				Signal.IsDown = true
				self.Rippler:Down(InputObject.Position.X, InputObject.Position.Y)
				if self.Style == Enumeration.ButtonStyle.Contained then
					self.Shadow:ChangeElevation(RAISED_ELEVATION)
				end
			elseif InputObject.UserInputType == MouseMovement then
				IsHovered = true
				if self.Style == Enumeration.ButtonStyle.Contained then
					Tween(self.Object, "ImageColor3", self.PrimaryColor3:Lerp(self.Rippler.RippleColor3, self.OverlayOpacity), Enumeration.EasingFunction.Deceleration.Value, 0.1, true)
				else
					Tween(self.Object, "ImageTransparency", 1 - self.OverlayOpacity, Enumeration.EasingFunction.Deceleration.Value, 0.1, true)
				end

				local TooltipObj = self.TooltipObject
				if TooltipObj then
					-- Over 150ms, tooltips fade in and scale up using the deceleration curve. They fade out over 75ms.

					local NewInt = Int + 1
					Int = NewInt

					Scheduler.Delay(0.5, function()
						if NewInt == Int then
							Tween(TooltipObj, "Size", UDim2.fromOffset(TooltipObj.TextLabel.TextBounds.X + 16, 24), Enumeration.EasingFunction.Deceleration.Value, 0.1, true)
							Tween(TooltipObj, "ImageTransparency", 0.1, Enumeration.EasingFunction.Deceleration.Value, 0.1, true)
							Tween(TooltipObj.TextLabel, "TextTransparency", 0, Enumeration.EasingFunction.Deceleration.Value, 0.1, true)
						end
					end)
				end
			end
		end

		function self.InputEnded(InputObject)
			local UserInputType = InputObject.UserInputType
			self.Rippler:Up()
			local Signal = self.RegisteredRippleInputs[UserInputType.Value]

			if Signal and Signal.IsDown then
				Signal.IsDown = false
				Signal:Fire()
			end

			if self.Style == Enumeration.ButtonStyle.Contained then
				self.Shadow:ChangeElevation(self.Elevation)
			end

			if UserInputType == MouseMovement then
				for _, EventSignal in next, self.RegisteredRippleInputs do
					EventSignal.IsDown = false
				end

				if self.Style == Enumeration.ButtonStyle.Contained then
					Tween(self.Object, "ImageColor3", self.PrimaryColor3, Enumeration.EasingFunction.Deceleration.Value, 0.1, true)
				else
					Tween(self.Object, "ImageTransparency", 1, Enumeration.EasingFunction.Deceleration.Value, 0.1, true)
				end

				IsHovered = false
			end

			Int += 1
			local TooltipObj = self.TooltipObject

			if TooltipObj then
				Tween(TooltipObj, "Size", UDim2.new(), Enumeration.EasingFunction.Deceleration.Value, 0.075, true)
				Tween(TooltipObj, "ImageTransparency", 1, Enumeration.EasingFunction.Deceleration.Value, 0.075, true)
				Tween(TooltipObj.TextLabel, "TextTransparency", 1, Enumeration.EasingFunction.Deceleration.Value, 0.075, true)
			end
		end

		function self.InputChanged(InputObject)
			if InputObject.UserInputType == MouseMovement and not IsHovered then
				IsHovered = true
				self.InputBegan(InputObject)
			end
		end

		self.Disabled = false
		self:SuperInit()
	end;
})