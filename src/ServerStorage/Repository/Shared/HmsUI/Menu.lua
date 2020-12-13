local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")

local Resources = require(ReplicatedStorage.Resources)
local Color = Resources:LoadLibrary("Color")
local Enumeration = Resources:LoadLibrary("Enumerations")
local PseudoInstance = Resources:LoadLibrary("PseudoInstance")
local Tween = Resources:LoadLibrary("Tween")
local Typer = Resources:LoadLibrary("Typer")

Resources:LoadLibrary("IconLabel")
Resources:LoadLibrary("RippleButton")
Resources:LoadLibrary("Rippler")
Resources:LoadLibrary("Shadow")

local DISMISS_TIME = 0.05
local ENTER_TIME = 0.1

local LARGE_FRAME_SIZE = Vector2.new(32767, 48)
local GRAY_500 = Color.Black

local TOUCH_TYPES = {
	[Enum.UserInputType.MouseButton1] = true;
	[Enum.UserInputType.Touch] = true;
	[Enum.UserInputType.Gamepad1] = true;
}

local SourceSans = Enum.Font.SourceSans

Enumeration.ExpandDirection = {"Top", "Bottom", "Center"}

local MenuStatePosition = {
	[Enumeration.ExpandDirection.Top.Value] = {
		AnchorPoint = Vector2.new(0, 1);
		Position = UDim2.fromScale(0, 1);
	};

	[Enumeration.ExpandDirection.Bottom.Value] = {
		AnchorPoint = Vector2.new();
		Position = UDim2.fromScale(0, 1);
	};

	[Enumeration.ExpandDirection.Center.Value] = {
		AnchorPoint = Vector2.new(0, 0.5);
		Position = UDim2.fromScale(0, 0.5);
	};
}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local MenuFrame = Instance.new("Frame") do
	MenuFrame.BackgroundTransparency = 1
	MenuFrame.Size = UDim2.fromOffset(112, 160) -- Size = UDim2.new(0, 112, 0, #Elements * 48 + 16)
	MenuFrame.Name = "MenuFrame"

	local Menu = Instance.new("ImageLabel")
	Menu.ZIndex = 2147483634
	Menu.BorderSizePixel = 0
	Menu.SliceCenter = Rect.new(4, 4, 252, 252)
	Menu.ScaleType = Enum.ScaleType.Slice
	Menu.BackgroundTransparency = 1
	Menu.AnchorPoint = Vector2.new(0.5, 0.5)
	Menu.Image = "rbxassetid://1934624205"
	Menu.Position = UDim2.fromScale(0.5, 0.5)
	Menu.Size = UDim2.fromScale(1, 1)
	Menu.Name = "Menu"
	Menu.Parent = MenuFrame

	local UIPadding = Instance.new("UIPadding")
	UIPadding.PaddingTop = UDim.new(0, 8)
	UIPadding.PaddingRight = UDim.new(0, 16)
	UIPadding.PaddingLeft = UDim.new(0, 16)
	UIPadding.PaddingBottom = UDim.new(0, 8)
	UIPadding.Parent = Menu

	local Shadows = Instance.new("Frame")
	Shadows.ZIndex = 2147483633
	Shadows.BorderSizePixel = 0
	Shadows.BackgroundColor3 = Color3.new(1, 1, 1)
	Shadows.BackgroundTransparency = 1
	Shadows.Size = UDim2.fromScale(1, 1)
	Shadows.Name = "Shadows"
	Shadows.Parent = MenuFrame

	local Shadow = PseudoInstance.new("Shadow")
	Shadow.Elevation = 8
	Shadow.Parent = Shadows

	local UIScale = Instance.new("UIScale")
	UIScale.Scale = 0
	UIScale.Parent = MenuFrame
end

local function InputBegan(self)
	return function(InputObject)
		if TOUCH_TYPES[InputObject.UserInputType] and not self.Dismissed then
			local GuiObjects = PlayerGui:GetGuiObjectsAtPosition(InputObject.Position.X, InputObject.Position.Y)
			if #GuiObjects > 0 then
				local ShouldFireFalse = true

				for _, Object in ipairs(GuiObjects) do
					if Object:IsDescendantOf(self.Object) then
						ShouldFireFalse = false
						break
					end
				end

				if ShouldFireFalse then
					self.OnConfirmed:Fire(false)
					self:Dismiss()
				end
			else
				self.OnConfirmed:Fire(false)
				self:Dismiss()
			end
		end
	end
end

local function OnConfirm(self)
	if not self.Dismissed then
		self.OnConfirmed:Fire(self.CurrentSelection)
		self:Dismiss()
	end
end

local function EnableInputService(self)
	self.Janitor:Add(UserInputService.InputBegan:Connect(InputBegan(self)), "Disconnect")
end

local MenusActive = 0

local function SubMenusActive()
	MenusActive -= 1
end

return PseudoInstance:Register("Menu", {
	Storage = table.create(0);
	WrappedProperties = {
		Object = {"AnchorPoint", "Active", "Name", "Size", "Position", "LayoutOrder", "NextSelectionDown", "NextSelectionLeft", "NextSelectionRight", "NextSelectionUp", "Parent"};
	};

	Internals = {"Dismissed", "CurrentSelection", "RippleButtons", "UIScale", "Menu"};
	Events = table.create(1, "OnConfirmed");

	Methods = {
		Enter = function(self)
			Tween(self.UIScale, "Scale", 1, Enumeration.EasingFunction.Deceleration.Value, ENTER_TIME, true, EnableInputService, self)
		end;

		Dismiss = function(self)
			if not self.Dismissed then
				self.Dismissed = true
				Tween(self.UIScale, "Scale", 0, Enumeration.EasingFunction.Acceleration.Value, DISMISS_TIME, true, self.Janitor)
			end
		end;
	};

	Properties = {
		Options = Typer.AssignSignature(2, Typer.ArrayOfStrings, function(self, Options)
			local LongestTextSize = 80

			for Index, RippleButton in ipairs(self.RippleButtons) do
				RippleButton:Destroy()
				self.RippleButtons[Index] = nil
			end

			for Index, ChoiceName in ipairs(Options) do
				LongestTextSize = math.max(LongestTextSize, TextService:GetTextSize(ChoiceName, 16, SourceSans, LARGE_FRAME_SIZE).X)

				local RippleButton = PseudoInstance.new("RippleButton")
				RippleButton.Position = UDim2.fromOffset(0, (Index - 1) * 48)
				RippleButton.Size = UDim2.new(1, 0, 0, 48)
				RippleButton.BorderRadius = 0
				RippleButton.ZIndex = 2147483635
				RippleButton.Name = ChoiceName
				RippleButton.Text = ChoiceName
				RippleButton.Font = SourceSans
				RippleButton.Style = Enumeration.ButtonStyle.Flat.Value
				RippleButton.PrimaryColor3 = GRAY_500
				RippleButton.TextXAlignment = Enum.TextXAlignment.Left
				RippleButton.TextTransparency = 0.4
				RippleButton.Parent = self.Menu
				self.RippleButtons[Index] = RippleButton

				self.Janitor:Add(RippleButton.OnPressed:Connect(function()
					self.CurrentSelection = ChoiceName
					OnConfirm(self)
				end), "Disconnect")
			end

			self.Object.Size = UDim2.fromOffset(LongestTextSize + 32 + 56, 16 + 48 * #Options)
			self:Rawset("Options", Options)
		end);

		ExpandDirection = Typer.AssignSignature(2, Typer.EnumerationOfTypeExpandDirection, function(self, ExpandDirection)
			local State = MenuStatePosition[ExpandDirection.Value]
			self.Object.AnchorPoint = State.AnchorPoint
			self.Object.Position = State.Position
			self:Rawset("ExpandDirection", ExpandDirection)
		end);
	};

	Init = function(self, ...)
		self:Rawset("Object", MenuFrame:Clone())
		self.UIScale = self.Object.UIScale
		self.Menu = self.Object.Menu
		self.RippleButtons = {}
		self.CurrentSelection = ""

		self.ExpandDirection = Enumeration.ExpandDirection.Bottom

		self.Janitor:Add(self.Object, "Destroy")
		self.Janitor:Add(self.UIScale, "Destroy")
		self.Janitor:Add(SubMenusActive, true)

		self:SuperInit(...)
	end;
})