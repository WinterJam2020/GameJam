local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local Color = Resources:LoadLibrary("Color")
local Enumeration = Resources:LoadLibrary("Enumerations")
local HmsPriorityUI = Resources:LoadLibrary("HmsPriorityUI")
local PseudoInstance = Resources:LoadLibrary("PseudoInstance")
local Tween = Resources:LoadLibrary("Tween")
local Typer = Resources:LoadLibrary("Typer")

Resources:LoadLibrary("Radio")
Resources:LoadLibrary("RadioGroup")
Resources:LoadLibrary("ReplicatedPseudoInstance")
Resources:LoadLibrary("RippleButton")
Resources:LoadLibrary("Shadow")

local BUTTON_WIDTH_PADDING = 8

local Left = Enum.TextXAlignment.Left
local SourceSansSemibold = Enum.Font.SourceSansSemibold

local LocalPlayer, PlayerGui do
	if RunService:IsClient() then
		if RunService:IsServer() then
			PlayerGui = game:GetService("CoreGui")
		else
			repeat
				LocalPlayer = Players.LocalPlayer
			until LocalPlayer or not wait()

			repeat
				PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
			until PlayerGui or not wait()
		end
	end
end

local Frame do
	Frame = Instance.new("Frame")
	Frame.BackgroundTransparency = 1
	Frame.Position = UDim2.fromScale(0.5, 0.5)
	Frame.AnchorPoint = Vector2.new(0.5, 0.5)
	Frame.Size = UDim2.fromScale(1, 1)
	Frame.Name = "ChoiceDialog"

	local UIScale = Instance.new("UIScale")
	UIScale.Scale = 0
	UIScale.Name = "UIScale"
	UIScale.Parent = Frame

	local Background = Instance.new("ImageLabel")
	Background.BackgroundTransparency = 1
	Background.ScaleType = Enum.ScaleType.Slice
	Background.SliceCenter = Rect.new(4, 4, 256 - 4, 256 - 4)
	Background.Image = "rbxassetid://1934624205"
	Background.Size = UDim2.fromOffset(280, 117)
	Background.Position = UDim2.fromScale(0.5, 0.5)
	Background.AnchorPoint = Vector2.new(0.5, 0.5)
	Background.Name = "Background"
	Background.ZIndex = 2
	Background.Parent = Frame

	local Header = Instance.new("TextLabel")
	Header.Font = SourceSansSemibold
	Header.TextSize = 26
	Header.Size = UDim2.new(1, -24, 0, 64)
	Header.Position = UDim2.fromOffset(24, 1)
	Header.BackgroundTransparency = 1
	Header.TextXAlignment = Left
	Header.TextTransparency = 0.129
	Header.TextColor3 = Color.Black
	Header.Name = "Header"
	Header.ZIndex = 3
	Header.Parent = Background

	local Border = Instance.new("Frame")
	Border.BackgroundColor3 = Color.Black
	Border.BackgroundTransparency = 238 / 255
	Border.BorderSizePixel = 0
	Border.Position = UDim2.fromOffset(0, 64 - 2 + 1)
	Border.Size = UDim2.new(1, 0, 0, 1)
	Border.ZIndex = 3
	Border.Parent = Background

	local BottomBorder = Border:Clone()
	BottomBorder.Position = UDim2.new(0, 0, 1, -52 + 2 - 4 + 1)
	BottomBorder.Parent = Background

	local Shadow = PseudoInstance.new("Shadow")
	Shadow.Elevation = 8
	Shadow.Parent = Background
end

local function OnDismiss(self)
	if not self.Dismissed then
		self:Dismiss()
		self.OnConfirmed:Fire(LocalPlayer, false)
	end
end

local function OnConfirm(self)
	if not self.Dismissed then
		self:Dismiss()
		self.OnConfirmed:Fire(LocalPlayer, self.RadioGroup:GetSelection())
	end
end

local function ConfirmEnable(ConfirmButton)
	ConfirmButton.Disabled = false
end

local function HideUIScale(self)
	self.UIScale.Parent = nil
end

local DialogsActive = 0

local function SubDialogsActive()
	DialogsActive -= 1
end

local function AdjustButtonSize(Button)
	Button.Size = UDim2.fromOffset(Button.TextBounds.X + BUTTON_WIDTH_PADDING * 2, 36)
end

return PseudoInstance:Register("ChoiceDialog", {
	Storage = table.create(0);
	Internals = {
		"ConfirmButton", "DismissButton", "RadioGroup", "AssociatedRadioContainers", "Header", "UIScale", "Background";
		SHOULD_BLUR = true;
	};

	Events = table.create(1, "OnConfirmed");
	Methods = {
		Enter = function(self)
			self.UIScale.Parent = self.Object
			self.Object.Parent = self.SCREEN
			AdjustButtonSize(self.DismissButton)
			AdjustButtonSize(self.ConfirmButton)

			Tween(self.UIScale, "Scale", 1, Enumeration.EasingFunction.Deceleration.Value, self.ENTER_TIME, true, HideUIScale, self)
		end;

		Dismiss = function(self)
			-- Destroys Dialog when done
			if not self.Dismissed then
				self.Dismissed = true
				Tween(self.UIScale, "Scale", 0, Enumeration.EasingFunction.Acceleration.Value, self.DISMISS_TIME, true, self.Janitor)
				self.UIScale.Parent = self.Object
				self:Unblur()
			end
		end;
	};

	Properties = {
		PrimaryColor3 = Typer.AssignSignature(2, Typer.Color3, function(self, PrimaryColor3)
			self.ConfirmButton.PrimaryColor3 = PrimaryColor3
			self.DismissButton.PrimaryColor3 = PrimaryColor3

			for Item, ItemContainer in next, self.AssociatedRadioContainers do
				Item.PrimaryColor3 = PrimaryColor3
				ItemContainer.PrimaryColor3 = PrimaryColor3
			end

			self:Rawset("PrimaryColor3", PrimaryColor3)
		end);

		Options = Typer.AssignSignature(2, Typer.ArrayOfStrings, function(self, Options)
			self.Background.Size = UDim2.fromOffset(280, 117 + 48 * #Options)

			for Item, ItemContainer in next, self.AssociatedRadioContainers do
				Item:Destroy()
				ItemContainer:Destroy() -- ItemDescriptions are destroyed here
				self.AssociatedRadioContainers[Item] = nil
			end

			if self.RadioGroup then
				self.Janitor[self.RadioGroup] = self.RadioGroup:Destroy()
			end

			self.RadioGroup = PseudoInstance.new("RadioGroup")
			self.Janitor:Add(self.RadioGroup.SelectionChanged:Connect(ConfirmEnable, self.ConfirmButton), "Disconnect")
			self.Janitor:Add(self.RadioGroup, "Destroy")

			for Index, ChoiceName in ipairs(Options) do
				local ItemContainer = PseudoInstance.new("RippleButton")
				ItemContainer.Position = UDim2.fromOffset(0, 64 + 48 * (Index - 1))
				ItemContainer.Size = UDim2.new(1, 0, 0, 48)
				ItemContainer.BorderRadius = 0
				ItemContainer.ZIndex = 5
				ItemContainer.Style = Enumeration.ButtonStyle.Flat.Value
				ItemContainer.Parent = self.Background

				local Item = PseudoInstance.new("Radio")
				Item.AnchorPoint = Vector2.new(0.5, 0.5)
				Item.Position = UDim2.new(0, 36, 0.5, 0)
				Item.ZIndex = 8
				Item.Parent = ItemContainer.Object

				ItemContainer.PrimaryColor3 = self.PrimaryColor3
				Item.PrimaryColor3 = self.PrimaryColor3

				self.AssociatedRadioContainers[Item] = ItemContainer

				self.RadioGroup:Add(Item, ChoiceName)
				ItemContainer.OnPressed:Connect(Item.SetChecked, Item)

				local ItemDescription = Instance.new("TextLabel")
				ItemDescription.BackgroundTransparency = 1
				ItemDescription.Position = UDim2.new(0, 48 + 32, 0.5, 0)
				ItemDescription.TextXAlignment = Left
				ItemDescription.Font = SourceSansSemibold
				ItemDescription.TextSize = 20
				ItemDescription.Text = ChoiceName
				ItemDescription.TextTransparency = 0.13
				ItemDescription.ZIndex = 8
				ItemDescription.Parent = ItemContainer.Object
			end

			self:Rawset("Options", Options)
		end);

		HeaderText = Typer.AssignSignature(2, Typer.String, function(self, Text)
			self.Header.Text = Text
			self:Rawset("HeaderText", self.Header.Text)
		end);

		DismissText = Typer.AssignSignature(2, Typer.String, function(self, Text)
			local DismissButton = self.DismissButton
			DismissButton.Text = Text
			self:Rawset("DismissText", DismissButton.Text)
		end);

		ConfirmText = Typer.AssignSignature(2, Typer.String, function(self, Text)
			local ConfirmButton = self.ConfirmButton
			ConfirmButton.Text = Text
			self:Rawset("ConfirmText", ConfirmButton.Text)
		end);
	};

	Init = function(self, ...)
		self:Rawset("Object", Frame:Clone())
		self.UIScale = self.Object.UIScale
		self.Background = self.Object.Background
		self.Header = self.Background.Header
		self.AssociatedRadioContainers = {}

		local ConfirmButton = PseudoInstance.new("RippleButton")
		ConfirmButton.AnchorPoint = Vector2.new(1, 1)
		ConfirmButton.Position = UDim2.new(1, -8, 1, -8)
		ConfirmButton.BorderRadius = 4
		ConfirmButton.ZIndex = 10
		ConfirmButton.TextSize = 16
		ConfirmButton.TextTransparency = 0.129
		ConfirmButton.Style = Enumeration.ButtonStyle.Flat.Value
		ConfirmButton.Parent = self.Background

		local DismissButton = ConfirmButton:Clone()
		DismissButton.Position = UDim2.new(0, -8, 1, 0)
		DismissButton.Parent = ConfirmButton.Object

		self.Janitor:Add(DismissButton:GetPropertyChangedSignal("TextBounds"):Connect(AdjustButtonSize, DismissButton), "Disconnect")
		self.Janitor:Add(ConfirmButton:GetPropertyChangedSignal("TextBounds"):Connect(AdjustButtonSize, ConfirmButton), "Disconnect")

		ConfirmButton.Disabled = true

		self.ConfirmButton = ConfirmButton
		self.DismissButton = DismissButton
		self.Janitor:Add(ConfirmButton.OnPressed:Connect(OnConfirm, self), "Disconnect")
		self.Janitor:Add(DismissButton.OnPressed:Connect(OnDismiss, self), "Disconnect")

		self.Janitor:Add(self.Object, "Destroy")
		self.Janitor:Add(self.UIScale, "Destroy")
		self.Janitor:Add(SubDialogsActive, true)

		self.PrimaryColor3 = Color3.fromRGB(98, 0, 238)
		self:SuperInit(...)
	end;
}, HmsPriorityUI)