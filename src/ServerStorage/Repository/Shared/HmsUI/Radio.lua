local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local Resources = require(ReplicatedStorage.Resources)
local Color = Resources:LoadLibrary("Color")
local Enumeration = Resources:LoadLibrary("Enumerations")
local PseudoInstance = Resources:LoadLibrary("PseudoInstance")
local SelectionController = Resources:LoadLibrary("SelectionController")
local Tween = Resources:LoadLibrary("Tween")
local Typer = Resources:LoadLibrary("Typer")

local CHECKED_IMAGE = "rbxassetid://2012883990"
local UNCHECKED_IMAGE = "rbxassetid://2012883770"
local DEFAULT_SIZE = UDim2.fromOffset(24, 24)

local RadioButton = Instance.new("ImageButton")
RadioButton.BackgroundTransparency = 1
RadioButton.Size = DEFAULT_SIZE
RadioButton.Image = UNCHECKED_IMAGE
RadioButton.ImageColor3 = Color.Black
RadioButton.ImageTransparency = 0.46

local CLICK_RIPPLE_TRANSPARENCY = 0.77
local HOVER_RIPPLE_TRANSPARENCY = 0.93
local ANIMATION_TIME = 0.1 -- 0.125

local Circle = Instance.new("ImageLabel")
Circle.AnchorPoint = Vector2.new(0.5, 0.5)
Circle.BackgroundTransparency = 1
Circle.ImageTransparency = 1
Circle.Position = UDim2.fromScale(0.5, 0.5)
Circle.Size = UDim2.fromScale(1, 1)
Circle.Image = "rbxassetid://517259585"
Circle.Name = "InnerCircle"
Circle.Parent = RadioButton

local RippleCheckedSize = UDim2.fromScale(10 / 24, 10 / 24)
local RippleUncheckedSize = UDim2.fromScale(20 / 24, 20 / 24)

spawn(function()
	ContentProvider:PreloadAsync {CHECKED_IMAGE, UNCHECKED_IMAGE}
end)

return PseudoInstance:Register("Radio", {
	WrappedProperties = {
		Button = {"AnchorPoint", "Name", "Parent", "Size", "Position", "LayoutOrder", "NextSelectionDown", "NextSelectionLeft", "NextSelectionRight", "NextSelectionUp"};
	};

	Internals = {
		"InnerCircle";
		RippleCheckedFinished = function(self, TweenStatus)
			if TweenStatus == Enum.TweenStatus.Completed then
				self.Button.Image = CHECKED_IMAGE
				self.InnerCircle.Visible = false
			end
		end;

		SetColorAndTransparency = function(self, Color3, Transparency)
			local Opacity = 1 - Transparency

			self.HoverRippler.RippleColor3 = Color3
			self.ClickRippler.RippleColor3 = Color3

			self.HoverRippler.RippleTransparency = Opacity * HOVER_RIPPLE_TRANSPARENCY + Transparency
			self.ClickRippler.RippleTransparency = Opacity * CLICK_RIPPLE_TRANSPARENCY + Transparency

			self.Button.ImageTransparency = Transparency
			self.Button.ImageColor3 = Color3
		end;
	};

	Properties = {
		Checked = Typer.AssignSignature(2, Typer.Boolean, function(self, Checked)
			if Checked then
				self:SetColorAndTransparency(self.PrimaryColor3, 0)
				self.Button.Image = CHECKED_IMAGE
			else
				local MyTheme = self.Themes[self.Theme.Value]

				self:SetColorAndTransparency(MyTheme.ImageColor3, MyTheme.ImageTransparency)
				self.Button.Image = UNCHECKED_IMAGE
			end

			self:Rawset("Checked", Checked)
			self.OnChecked:Fire(Checked)
		end);

		ZIndex = Typer.AssignSignature(2, Typer.Number, function(self, ZIndex)
			self.Button.ZIndex = ZIndex
			self.InnerCircle.ZIndex = ZIndex

			self:Rawset("ZIndex", ZIndex)
		end);
	};

	Methods = {
		SetChecked = Typer.AssignSignature(2, Typer.OptionalBoolean, function(self, Checked)
			if self.Disabled then
				return true
			end

			if Checked == nil then
				Checked = true
			end

			local Changed = self.Checked == Checked == false
			if Changed then
				local Button = self.Button
				local InnerCircle = self.InnerCircle
				InnerCircle.ImageColor3 = self.PrimaryColor3
				InnerCircle.Visible = true

				if Checked then
					self:SetColorAndTransparency(self.PrimaryColor3, 0)

					Tween(InnerCircle, "Size", RippleCheckedSize, Enumeration.EasingFunction.Deceleration.Value, ANIMATION_TIME, true)
					Tween(InnerCircle, "ImageTransparency", 0, Enumeration.EasingFunction.Deceleration.Value, ANIMATION_TIME * 0.8, true, self.RippleCheckedFinished, self)
				else
					local MyTheme = self.Themes[self.Theme.Value]
					self:SetColorAndTransparency(MyTheme.ImageColor3, MyTheme.ImageTransparency)

					Button.Image = UNCHECKED_IMAGE
					Tween(InnerCircle, "Size", RippleUncheckedSize, Enumeration.EasingFunction.Deceleration.Value, ANIMATION_TIME, true)
					Tween(InnerCircle, "ImageTransparency", 1, Enumeration.EasingFunction.Deceleration.Value, ANIMATION_TIME * 2, true)
				end
			end

			self:Rawset("Checked", Checked)
			self.OnChecked:Fire(Checked)
		end);
	};

	Init = function(self)
		self.Button = self.Janitor:Add(RadioButton:Clone(), "Destroy")
		self:Rawset("Object", self.Button)
		self.InnerCircle = self.Janitor:Add(self.Button.InnerCircle, "Destroy")
		self:SuperInit()
	end;
}, SelectionController)