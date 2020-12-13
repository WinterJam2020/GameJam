local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")

local Resources = require(ReplicatedStorage.Resources)
local Color = Resources:LoadLibrary("Color")
local Enumeration = Resources:LoadLibrary("Enumerations")
local HmsPriorityUI = Resources:LoadLibrary("HmsPriorityUI")
local PseudoInstance = Resources:LoadLibrary("PseudoInstance")
local Tween = Resources:LoadLibrary("Tween")
local Typer = Resources:LoadLibrary("Typer")

Resources:LoadLibrary("ReplicatedPseudoInstance")
Resources:LoadLibrary("RippleButton")
Resources:LoadLibrary("Shadow")

local BUTTON_WIDTH_PADDING = 8
local WIDTH = UserInputService.TouchEnabled and 460 or 560
local FRAME_SIZE = Vector2.new(WIDTH - 48, math.huge)
local NEW_SIZE = UDim2.new(0, WIDTH, 0, 182)

local Left = Enum.TextXAlignment.Left
local SourceSansSemibold = Enum.Font.SourceSansSemibold
local SourceSans = Enum.Font.SourceSans

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

local VISIBLE_PROPERTIES = {
	ConfirmationDialog = {"BackgroundTransparency", 0.6};
	Background = {"ImageTransparency", 0};
	Header = {"TextTransparency", 0.129};
	PrimaryText = {"TextTransparency", 0.4};
	TextLabel = {"TextTransparency", 0.129};
	AmbientShadow = {"ImageTransparency", 0.8};
	PenumbraShadow = {"ImageTransparency", 0.88};
	UmbraShadow = {"ImageTransparency", 0.86};
}

local Frame do
	Frame = Instance.new("Frame")
	Frame.BackgroundTransparency = 1
	Frame.BackgroundColor3 = Color3.new()
	Frame.Position = UDim2.fromScale(0.5, 0.5)
	Frame.AnchorPoint = Vector2.new(0.5, 0.5)
	Frame.Size = UDim2.fromScale(1, 1)
	Frame.Name = "ConfirmationDialog"

	local Background = Instance.new("ImageLabel")
	Background.BackgroundTransparency = 1
	Background.ScaleType = Enum.ScaleType.Slice
	Background.SliceCenter = Rect.new(4, 4, 252, 252)
	Background.Image = "rbxassetid://1934624205"
	Background.Size = NEW_SIZE
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

	local DialogText = Instance.new("TextLabel")
	DialogText.BackgroundTransparency = 1
	DialogText.Name = "PrimaryText"
	DialogText.Position = UDim2.fromOffset(24, 40)
	DialogText.Size = UDim2.new(1, -48, 0, 64)
	DialogText.ZIndex = 3
	DialogText.TextSize = 20
	DialogText.Font = SourceSans
	DialogText.TextXAlignment = Left
	DialogText.TextTransparency = 0.4
	DialogText.TextColor3 = Color.Black
	DialogText.TextWrapped = true
	DialogText.Parent = Background

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
		self.OnConfirmed:Fire(LocalPlayer, true)
	end
end

local DialogsActive = 0
local ActivePrompt = nil

local function SubDialogsActive()
	DialogsActive -= 1
end

local function AdjustButtonSize(Button)
	Button.Size = UDim2.fromOffset(Button.TextBounds.X + BUTTON_WIDTH_PADDING * 2, 36)
end

local function RescaleUI(self, Text)
	local PrimaryText = self.PrimaryText
	if Text then
		local TextSize = TextService:GetTextSize(Text, 20, SourceSans, FRAME_SIZE).Y
		local SizeY = TextSize + 4 < 64 and 64 or TextSize + 4

		self.Background.Size = UDim2.fromOffset(WIDTH, TextSize + 40 + 52 + 24)
		PrimaryText.Size = UDim2.new(1, -48, 0, SizeY)
		PrimaryText.Position = UDim2.fromOffset(24, SizeY == 64 and 40 or 40 + (SizeY - 64))
	else
		local TextSize = TextService:GetTextSize(PrimaryText.Text, 20, SourceSans, FRAME_SIZE).Y
		local SizeY = TextSize + 4 < 64 and 64 or TextSize + 4

		self.Background.Size = UDim2.fromOffset(WIDTH, TextSize + 40 + 52 + 24)
		PrimaryText.Size = UDim2.new(1, -48, 0, SizeY)
		PrimaryText.Position = UDim2.fromOffset(24, SizeY == 64 and 40 or 40 + (SizeY - 64))
	end
end

local function GetDescendantsOfClass(Parent, ClassName)
	local Children = {}
	local Length = 0

	for _, Child in ipairs(Parent:GetDescendants()) do
		if Child:IsA(ClassName) then
			Length += 1
			Children[Length] = Child
		end
	end

	return Children
end

local function Concat(...)
	local Result = {}
	local Length = 0
	local Seen = {}

	for _, Value in ipairs {...} do
		for _, ArrayValue in ipairs(Value) do
			if not Seen[ArrayValue] then
				Length += 1
				Result[Length] = ArrayValue
				Seen[ArrayValue] = true
			end
		end
	end

	return Result
end

local TextObjects = {
	TextButton = true;
	TextBox = true;
	TextLabel = true;
}

local ImageObjects = {
	ImageButton = true;
	ImageLabel = true;
}

local function ShowGui(Parent, Length, EasingFunction, PropertyTable)
	for _, Child in ipairs(Concat(GetDescendantsOfClass(Parent, "GuiObject"), table.create(1, Parent))) do
		local Properties = PropertyTable[Child.Name]
		if Properties then
			Tween(Child, Properties[1], Properties[2], EasingFunction, Length, true)
		end
	end
end

local function HideGui(Parent, Length, EasingFunction)
	for _, Child in ipairs(Concat(GetDescendantsOfClass(Parent, "GuiObject"), table.create(1, Parent))) do
		Tween(Child, "BackgroundTransparency", 1, EasingFunction, Length, true)
		if TextObjects[Child.ClassName] then
			Tween(Child, "TextTransparency", 1, EasingFunction, Length, true)
		elseif ImageObjects[Child.ClassName] then
			Tween(Child, "ImageTransparency", 1, EasingFunction, Length, true)
		end
	end
end

return PseudoInstance:Register("ConfirmationDialog", {
	Storage = table.create(0);
	Internals = {
		"ConfirmButton", "DismissButton", "Header", "PrimaryText", "Background";
		SHOULD_BLUR = false;
	};

	Events = table.create(1, "OnConfirmed");
	Methods = {
		Enter = function(self)
			if ActivePrompt then
				SubDialogsActive()
				Debris:AddItem(ActivePrompt, 0)
				ActivePrompt = nil
			end

			RescaleUI(self)
			self.Object.Parent = self.SCREEN
			AdjustButtonSize(self.DismissButton)
			AdjustButtonSize(self.ConfirmButton)

			ShowGui(self.Object, self.ENTER_TIME, Enumeration.EasingFunction.Deceleration.Value, VISIBLE_PROPERTIES)
		end;

		Dismiss = function(self)
			-- Destroys Dialog when done
			if not self.Dismissed then
				self.Dismissed = true
				HideGui(self.Object, self.DISMISS_TIME, Enumeration.EasingFunction.Acceleration.Value)
				Debris:AddItem(self.Object, self.DISMISS_TIME)
				SubDialogsActive()
			end
		end;
	};

	Properties = {
		PrimaryColor3 = Typer.AssignSignature(2, Typer.Color3, function(self, PrimaryColor3)
			self.ConfirmButton.PrimaryColor3 = PrimaryColor3
			self.DismissButton.PrimaryColor3 = PrimaryColor3
			self:Rawset("PrimaryColor3", PrimaryColor3)
		end);

		HeaderText = Typer.AssignSignature(2, Typer.String, function(self, Text)
			self.Header.Text = Text
			self:Rawset("HeaderText", self.Header.Text)
		end);

		DialogText = Typer.AssignSignature(2, Typer.String, function(self, Text)
			RescaleUI(self, Text)
			self.PrimaryText.Text = Text
			self:Rawset("DialogText", self.PrimaryText.Text)
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
		if ActivePrompt then
			SubDialogsActive()
			Debris:AddItem(ActivePrompt, 0)
			ActivePrompt = self.Object
		end

		self.Background = self.Object.Background
		self.Header = self.Background.Header
		self.PrimaryText = self.Background.PrimaryText
		HideGui(self.Object, 0, Enumeration.EasingFunction.Acceleration.Value)

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

		self.ConfirmButton = ConfirmButton
		self.DismissButton = DismissButton
		self.Janitor:Add(ConfirmButton.OnPressed:Connect(OnConfirm, self), "Disconnect")
		self.Janitor:Add(DismissButton.OnPressed:Connect(OnDismiss, self), "Disconnect")

		self.Janitor:Add(self.Object, "Destroy")
		self.Janitor:Add(SubDialogsActive, true)

		self.PrimaryColor3 = Color3.fromRGB(98, 0, 238)
		self:SuperInit(...)
	end;
}, HmsPriorityUI)