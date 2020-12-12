local SpritesheetHandler = require(script.Parent)

local SPRITESHEETS = {
	Economy = {"Premium", "RobuxDark", "RobuxShadow", "RobuxGold", "RobuxLight"};
	Gestures = {"DoubleRotate", "DoubleTap", "FingerFront", "FingerSide", "FullCircle", "HalfCircle", "Hold", "QuarterCircle", "ScrollDown", "ScrollLeft", "ScrollRight", "ScrollUp", "SwipeBottom", "SwipeBottomLeft", "SwipeBottomRight", "SwipeLeft", "SwipeRight", "SwipeTopLeft", "SwipeTopRight", "SwipeUp", "Tap", "ZoomIn", "ZoomOut"};
	Keyboard = {"BackspaceAlt", "Command", "Eleven", "Return", "EnterAlt", "EnterTall", "MarkLeft", "MarkRight", "MouseButton1", "MouseButton3", "MouseWheel", "MouseButton2", "MouseMovement", "PlusTall", "Shift", "ShiftAlt", "Ten", "Tilda", "Twelve", "Win", "A", "Asterisk", "B", "Backspace", "C", "CapsLock", "D", "Delete", "Down", "E", "Eight", "End", "Escape", "F", "F1", "F10", "F11", "F12", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "Five", "Four", "G", "H", "Home", "I", "Insert", "J", "K", "L", "Left", "LeftAlt", "LeftBracket", "LeftControl", "M", "Minus", "N", "Nine", "NumLock", "O", "One", "P", "PageDown", "PageUp", "Plus", "Print", "Q", "Question", "Quote", "R", "Right", "RightBracket", "S", "Semicolon", "Seven", "Six", "Slash", "Space", "T", "Tab", "Three", "Two", "U", "Up", "V", "W", "X", "Y", "Z", "Zero"};
	Xbox = {"ButtonX", "ButtonY", "ButtonA", "ButtonB", "ButtonR1", "ButtonL1", "ButtonR2", "ButtonL2", "ButtonR3", "ButtonL3", "ButtonSelect", "DPadLeft", "DPadRight", "DPadUp", "DPadDown", "Thumbstick1", "Thumbstick2", "DPad", "Controller", "RotateThumbstick1", "RotateThumbstick2"};
}

local function FromOffset(Offset, Parent): UICorner
	local UICorner: UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, Offset)
	UICorner.Parent = Parent
	return UICorner
end

local function FromUDim(Value)
	local UIPadding = Instance.new("UIPadding")
	UIPadding.PaddingBottom = Value
	UIPadding.PaddingTop = Value
	UIPadding.PaddingLeft = Value
	UIPadding.PaddingRight = Value
	return UIPadding
end

local function RemovePrefix(String, Prefix)
	return string.sub(String, 1, #Prefix) == Prefix and string.sub(String, #Prefix + 1) or String
end

local function Create(KeyCode, Theme, Parent)
	local Container = Instance.new("Frame")
	Container.BorderSizePixel = 0
	Container.Size = UDim2.fromScale(1, 1)

	FromOffset(8, Container)
	FromUDim(UDim.new(0, 5)).Parent = Container

	local PhaseTextLabel = Instance.new("TextLabel")
	PhaseTextLabel.Text = RemovePrefix(type(KeyCode) == "string" and KeyCode or KeyCode.Name, "Mouse")
	PhaseTextLabel.TextSize = 20
	PhaseTextLabel.TextTruncate = Enum.TextTruncate.AtEnd
	PhaseTextLabel.Font = Enum.Font.Highway
	PhaseTextLabel.TextColor3 = Color3.new(0.1, 0.1, 0.1)
	PhaseTextLabel.Size = UDim2.new(1, 0, 0, 30)
	PhaseTextLabel.AnchorPoint = Vector2.new(0.5, 0)
	PhaseTextLabel.Position = UDim2.fromScale(0.5, 0)
	PhaseTextLabel.TextWrapped = false
	PhaseTextLabel.BackgroundTransparency = 1
	PhaseTextLabel.LayoutOrder = 2
	PhaseTextLabel.Parent = Container

	Instance.new("UIListLayout").Parent = Container

	SpritesheetHandler.GetScaledImageLabel(KeyCode, Theme).Parent = Container

	Container.Parent = Parent
end

local function MakeTitle(Title, Parent)
	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Text = Title
	TitleLabel.TextSize = 24
	TitleLabel.TextColor3 = Color3.new()
	TitleLabel.TextColor3 = Color3.new(0.1, 0.1, 0.1)
	TitleLabel.Font = Enum.Font.Highway
	TitleLabel.Size = UDim2.new(1, -10, 0, 40)
	TitleLabel.AnchorPoint = Vector2.new(0.5, 0)
	TitleLabel.Position = UDim2.fromScale(0.5, 0)
	TitleLabel.TextWrapped = true
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.LayoutOrder = 2
	TitleLabel.Parent = Parent

	return TitleLabel
end

local function MakeSection(KeyCodes, Theme, Parent)
	local Container = Instance.new("Frame")
	Container.BorderSizePixel = 0
	Container.BackgroundTransparency = 1
	Container.Size = UDim2.fromScale(1, 1)

	local UIGridLayout = Instance.new("UIGridLayout")
	UIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIGridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	UIGridLayout.FillDirection = Enum.FillDirection.Horizontal
	UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIGridLayout.CellSize = UDim2.fromOffset(100, 130)
	UIGridLayout.Parent = Container

	for _, Item in ipairs(KeyCodes) do
		Create(Item, Theme, Container)
	end

	Container.Parent = Parent
	Container.Size = UDim2.new(1, 0, 0, UIGridLayout.AbsoluteContentSize.Y)

	return Container
end

return function(Target)
	local ScrollingFrame = Instance.new("ScrollingFrame")
	ScrollingFrame.Size = UDim2.fromScale(1, 1)
	ScrollingFrame.CanvasSize = UDim2.fromScale(1, 10)
	ScrollingFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	ScrollingFrame.BackgroundTransparency = 0
	ScrollingFrame.BorderSizePixel = 0

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Parent = ScrollingFrame

	ScrollingFrame.Parent = Target

	local LayoutOrder = -1
	local function Add(Item)
		LayoutOrder += 1
		Item.LayoutOrder = LayoutOrder
	end

	Add(MakeTitle("Economy", ScrollingFrame))
	Add(MakeSection(SPRITESHEETS.Economy, "Economy", ScrollingFrame))

	Add(MakeTitle("Gestures", ScrollingFrame))
	Add(MakeSection(SPRITESHEETS.Gestures, "Gestures", ScrollingFrame))

	Add(MakeTitle("Keyboard Dark", ScrollingFrame))
	Add(MakeSection(SPRITESHEETS.Keyboard, "KeyboardDark", ScrollingFrame))

	Add(MakeTitle("Keyboard Light", ScrollingFrame))
	Add(MakeSection(SPRITESHEETS.Keyboard, "KeyboardLight", ScrollingFrame))

	Add(MakeTitle("Xbox Dark", ScrollingFrame))
	Add(MakeSection(SPRITESHEETS.Xbox, "XboxDark", ScrollingFrame))

	Add(MakeTitle("Xbox Light", ScrollingFrame))
	Add(MakeSection(SPRITESHEETS.Xbox, "XboxLight", ScrollingFrame))

	return function()
		ScrollingFrame = ScrollingFrame:Destroy()
	end
end