local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local Resources = require(ReplicatedStorage.Resources)
local Color = Resources:LoadLibrary("Color")
local Enumeration = Resources:LoadLibrary("Enumerations")
local PseudoInstance = Resources:LoadLibrary("PseudoInstance")
local SelectionController = Resources:LoadLibrary("SelectionController")
local Tween_new = Resources:LoadLibrary("Tween").new
local Typer = Resources:LoadLibrary("Typer")

Resources:LoadLibrary("EasingFunctions")

local CLICK_RIPPLE_TRANSPARENCY = 0.77 -- 0.88
local HOVER_RIPPLE_TRANSPARENCY = 0.93 -- 0.96

-- Images
local CHECKED_CHECKBOX_IMAGE = "rbxassetid://1990905054"
local UNCHECKED_CHECKBOX_IMAGE = "rbxassetid://1990916223"
local INDETERMINATE_CHECKBOX_IMAGE = "rbxassetid://1990919246"

-- Preload Images
spawn(function()
	ContentProvider:PreloadAsync {CHECKED_CHECKBOX_IMAGE, UNCHECKED_CHECKBOX_IMAGE}
end)

-- Configuration
local ANIMATION_TIME = 0.1

-- Constants
local SHRINK_DURATION = ANIMATION_TIME --* 0.95
local DRAW_DURATION = ANIMATION_TIME * (1 / 0.7501)
local FILL_DURATION = ANIMATION_TIME * (1 / 0.9286)
local CHECKBOX_SIZE = UDim2.fromOffset(24, 24)

local CHECKBOX_THEMES = {
	[Enumeration.MaterialTheme.Light.Value] = {
		ImageColor3 = Color.Black;
		ImageTransparency = 0.46;
		DisabledTransparency = 0.74;
	};

	[Enumeration.MaterialTheme.Dark.Value] = {
		ImageColor3 = Color.White;
		ImageTransparency = 0.3;
		DisabledTransparency = 0.7;
	};
}

local SETS = {
	Bars = 0;
	Corners = 0.69;
	Edges = 0.09;

	InnerBars = 0;
	InnerCorners = 0;
	InnerEdges = 0;
}

local SETS_GOALS = {
	Bars = 1;
	Corners = 1;
	Edges = 1;

	InnerBars = SETS.Bars;
	InnerCorners = SETS.Corners;
	InnerEdges = SETS.Edges;
}

local Checkbox do
	local MIDDLE_ANCHOR = Vector2.new(0.5, 0.5)
	local MIDDLE_POSITION = UDim2.fromScale(0.5, 0.5)

	Checkbox = Instance.new("ImageButton")
	Checkbox.BackgroundTransparency = 1
	Checkbox.Size = CHECKBOX_SIZE
	Checkbox.Image = UNCHECKED_CHECKBOX_IMAGE

	local Pixel = Instance.new("Frame")
	Pixel.BackgroundTransparency = 1
	Pixel.BackgroundColor3 = Color.Black
	Pixel.BorderSizePixel = 0
	Pixel.Size = UDim2.fromOffset(1, 1)

	local GridFrame = Instance.new("Frame")
	GridFrame.AnchorPoint = MIDDLE_ANCHOR
	GridFrame.BackgroundTransparency = 1
	GridFrame.Name = "GridFrame"
	GridFrame.Position = MIDDLE_POSITION
	GridFrame.Size = CHECKBOX_SIZE
	GridFrame.Visible = false
	GridFrame.Parent = Checkbox

	for a = 1, 14 do
		local Existant = 14 * (a - 1)
		for b = 1, 14 do
			local PixelClone = Pixel:Clone()
			PixelClone.Name = Existant + b
			PixelClone.Position = UDim2.fromOffset(b + 4, a + 4)
			PixelClone.Parent = GridFrame
		end
	end

	local BackgroundTransparency = CHECKBOX_THEMES[Enumeration.MaterialTheme.Light.Value].ImageTransparency

	local Bar = Instance.new("Frame")
	Bar.BackgroundColor3 = Color.Black
	Bar.BackgroundTransparency = BackgroundTransparency
	Bar.BorderSizePixel = 0
	Bar.Name = "Bars"

	local Count = 0
	for c = 0, 16, 16 do
		for b = 3, 4 do
			Count = Count + 1
			local d
			if Count > 1 and Count < 4 then
				d = 6
				Bar.Name = "InnerBars"
			else
				d = 5
				Bar.Name = "Bars"
			end

			local e = (12 - d) * 2

			local Horizontal = Bar:Clone()
			Horizontal.Position = UDim2.fromOffset(d, b + c)
			Horizontal.Size = UDim2.fromOffset(e, 1)

			local Vertical = Bar:Clone()
			Vertical.Position = UDim2.fromOffset(b + c, d)
			Vertical.Size = UDim2.fromOffset(1, e)

			Horizontal.Parent = GridFrame
			Vertical.Parent = GridFrame
		end
	end

	Pixel.Name = "Corners"
	local CornerTransparency = (1 - BackgroundTransparency) * SETS.Corners + BackgroundTransparency

	for a = 3, 20, 17 do
		local F1 = Pixel:Clone()
		F1.BackgroundTransparency = CornerTransparency
		F1.Position = UDim2.fromOffset(a, a)

		local F2 = Pixel:Clone()
		F2.BackgroundTransparency = CornerTransparency
		F2.Position = UDim2.fromOffset(a, 23 - a)

		F1.Parent = GridFrame
		F2.Parent = GridFrame
	end

	Pixel.Name = "InnerCorners"

	for a = 4, 19, 15 do
		local F1 = Pixel:Clone()
		F1.BackgroundTransparency = BackgroundTransparency
		F1.Position = UDim2.fromOffset(a, a)

		local F2 = Pixel:Clone()
		F2.BackgroundTransparency = BackgroundTransparency
		F2.Position = UDim2.fromOffset(a, 23 - a)

		F1.Parent = GridFrame
		F2.Parent = GridFrame
	end

	Pixel.Name = "Edges"
	local EdgeTransparency = (1 - BackgroundTransparency) * SETS.Edges + BackgroundTransparency

	for a = 3, 20, 17 do
		for b = 4, 19, 15 do
			local F1 = Pixel:Clone()
			F1.BackgroundTransparency = EdgeTransparency
			F1.Position = UDim2.fromOffset(a, b)

			local F2 = Pixel:Clone()
			F2.BackgroundTransparency = EdgeTransparency
			F2.Position = UDim2.fromOffset(b, a)

			F1.Parent = GridFrame
			F2.Parent = GridFrame
		end
	end

	Pixel.Name = "InnerEdges"

	for a = 4, 19, 15 do
		for b = 5, 18, 13 do
			local F1 = Pixel:Clone()
			F1.BackgroundTransparency = BackgroundTransparency
			F1.Position = UDim2.fromOffset(a, b)

			local F2 = Pixel:Clone()
			F2.BackgroundTransparency = BackgroundTransparency
			F2.Position = UDim2.fromOffset(b, a)

			F1.Parent = GridFrame
			F2.Parent = GridFrame
		end
	end

	-- Destroy Clonable Templates
	Pixel:Destroy()
	Bar:Destroy()
end

return PseudoInstance:Register("Checkbox", {
	Internals = {
		"OpenTween", "OpenTween2", "Grid", "", "", "GridFrame";

		ImageTransparency = 0;
		XOffset = 0;
		YOffset = 0;

		Template = Checkbox;

		SetColorAndTransparency = function(self, Color3, Transparency)
			local Grid = self.Grid
			local Opacity = 1 - Transparency

			self.HoverRippler.RippleColor3 = Color3
			self.ClickRippler.RippleColor3 = Color3

			self.HoverRippler.RippleTransparency = Opacity * HOVER_RIPPLE_TRANSPARENCY + Transparency
			self.ClickRippler.RippleTransparency = Opacity * CLICK_RIPPLE_TRANSPARENCY + Transparency

			self.Button.ImageTransparency = Transparency
			self.Button.ImageColor3 = Color3

			for Name, BackgroundTransparency in next, SETS do
				local PixelTransparency = Opacity * BackgroundTransparency + Transparency

				for _, Object in ipairs(Grid[Name]) do
					Object.BackgroundColor3 = Color3
					Object.BackgroundTransparency = PixelTransparency
				end
			end

			self.ImageTransparency = Transparency

			for a = 1, 196 do
				local Pixel = Grid[a]
				Pixel.BackgroundColor3 = Color3
				Pixel.BackgroundTransparency = Opacity * Pixel.BackgroundTransparency + Transparency -- CompoundTransparency
			end
		end;

		ExpandFrame = function(self, X)
			X = X or 1
			local Grid = self.Grid
			local ImageTransparency = self.ImageTransparency
			local ImageOpacity = 1 - ImageTransparency

			for Name, Start in next, SETS_GOALS do
				Start = ImageOpacity * Start + ImageTransparency
				local End = ImageOpacity * SETS[Name] + ImageTransparency - Start

				for _, Object in ipairs(Grid[Name]) do
					Object.BackgroundTransparency = Start + X * End
				end
			end
		end;

		ShrinkFrame = function(self, X)
			X = X or 1
			local Grid = self.Grid
			local ImageTransparency = self.ImageTransparency
			local ImageOpacity = 1 - ImageTransparency

			for Name, Start in next, SETS do
				Start = ImageOpacity * Start + ImageTransparency
				local End = ImageOpacity * SETS_GOALS[Name] + ImageTransparency - Start

				for _, Object in ipairs(Grid[Name]) do
					Object.BackgroundTransparency = Start + X * End
				end
			end

			if X == 1 then
				self.OpenTween2 = Tween_new(SHRINK_DURATION, Enumeration.EasingFunction.Deceleration.Value, self.ExpandFrame, self)
			end
		end;

		DrawCheckmark = function(self, X)
			X = X or 1
			local Grid = self.Grid

			for C = 1, -1, -2 do
				local A = math.floor(11 + X * (4 - 2 * C - 11)) -- Lerp(11, 4 - 2*c, x)
				local D = C == 1 and 15 or -4

				for A2 = A, 10 do
					local B = -C * A2 + D
					local E

					if A2 == 2 and B == 13 then
						E = 0.18
					elseif A2 == 3 and B == 12 or A2 == 4 and B == 11 or A2 == 5 and B == 10 or A2 == 9 and (B == 5 or B == 6) then
						E = 0.36
					elseif A2 == 6 then
						if B == 2 then
							E = 0.18
						elseif B == 9 then
							E = 0.36
						end
					elseif A2 == 7 then
						if B == 3 then
							E = 0.35
						elseif B == 8 then
							E = 0.36
						end
					elseif A2 == 8 then
						if B == 4 then
							E = 0.35
						elseif B == 7 then
							E = 0.36
						end
					elseif A2 == 10 then
						if B == 5 or B == 6 then
							E = 0.99
						end
					end

					Grid[14 * (A2 - 1) + B].BackgroundTransparency = E
					Grid[14 * A2 + B].BackgroundTransparency = 0.99
					Grid[14 * (A2 + 1) + B].BackgroundTransparency = 1
					Grid[14 * (A2 + 1) + B + C].BackgroundTransparency = 0.5
				end

				Grid[A * (14 - C) + C + D].BackgroundTransparency = C == 1 and 0.5 or 0.51 -- 14 * a + -c * a + d + c

				if A == 2 then
					self.Button.Image = CHECKED_CHECKBOX_IMAGE
					self.Button.ImageTransparency = 0
					self.GridFrame.Visible = false
				end
			end

			Grid[160].BackgroundTransparency = 0.5 -- 12, 6
		end;

		FillCenter = function(self, X)
			X = X or 1
			local Grid = self.Grid
			local CurrentSize = math.floor(14 * (2 - X)) / 2

			for I = 1, 14 - CurrentSize do
				for A = I, 15 - I do
					Grid[14 * (I - 1) + A].BackgroundTransparency = 0
					Grid[14 * (A - 1) + I].BackgroundTransparency = 0
					Grid[14 * ((15 - I) - 1) + A].BackgroundTransparency = 0
					Grid[14 * (A - 1) + 15 - I].BackgroundTransparency = 0
				end
			end

			if (CurrentSize + 0.5) % 1 == 0 then
				local I = 14.5 - CurrentSize
				for A = I, 15 - I do
					Grid[14 * (I - 1) + A].BackgroundTransparency = 0.5
					Grid[14 * (A - 1) + I].BackgroundTransparency = 0.5
					Grid[14 * ((15 - I) - 1) + A].BackgroundTransparency = 0.5
					Grid[14 * (A - 1) + 15 - I].BackgroundTransparency = 0.5
				end
			end

			local OpenTween = self.OpenTween
			if CurrentSize == 7 and OpenTween then
				self.OpenTween:Stop()
				self.OpenTween = Tween_new(DRAW_DURATION, Enumeration.EasingFunction.Deceleration.Value, self.DrawCheckmark, self)
			end
		end;

		EmptyCenter = function(self, X)
			X = X or 1
			local Grid = self.Grid
			local CurrentSize = math.ceil(14 * X) / 2

			for I = 1, CurrentSize do
				local Start = 8 - I
				local End = 7 + I

				for A = Start, End do
					Grid[14 * (Start - 1) + A].BackgroundTransparency = 1
					Grid[14 * (A - 1) + Start].BackgroundTransparency = 1
					Grid[14 * (End - 1) + A].BackgroundTransparency = 1
					Grid[14 * (A - 1) + End].BackgroundTransparency = 1
				end
			end

			if (CurrentSize + 0.5) % 1 == 0 then
				local I = 0.5 + CurrentSize
				local Start = 8 - I
				local End = 7 + I

				for A = Start, End do
					local BackgroundTransparency = (self.ImageTransparency + 1) / 2 -- CompoundTransparency
					Grid[14 * (Start - 1) + A].BackgroundTransparency = BackgroundTransparency
					Grid[14 * (A - 1) + Start].BackgroundTransparency = BackgroundTransparency
					Grid[14 * (End - 1) + A].BackgroundTransparency = BackgroundTransparency
					Grid[14 * (A - 1) + End].BackgroundTransparency = BackgroundTransparency
				end
			end

			if CurrentSize == 7 then
				self.Button.Image = UNCHECKED_CHECKBOX_IMAGE
				self.Button.ImageTransparency = CHECKBOX_THEMES[self.Theme.Value].ImageTransparency
				self.GridFrame.Visible = false
			end
		end;

		EraseCheckmark = function(self, X)
			X = X or 1
			local Grid = self.Grid
			local ImageTransparency = self.ImageTransparency
			local XOffset, YOffset = self.XOffset, self.YOffset
			local HalfImageTransparency = (ImageTransparency + 1) / 2 -- CompoundTransparency
			local A = math.ceil(8 * X + 1) -- ceil(Lerp(1, 9, x))

			for A2 = 2, A do
				local Object1 = 14 * (A2 + XOffset - 1) + 15 - A2 + YOffset
				local Object2 = Object1 + 14
				local Object3 = Object2 + 1

				if Object1 > 0 then
					Grid[Object1].BackgroundTransparency = ImageTransparency
				end

				if Object2 > 0 then
					Grid[Object2].BackgroundTransparency = ImageTransparency
				end

				if Object3 > 0 then
					Grid[Object3].BackgroundTransparency = ImageTransparency
				end

				Grid[Object2 + 14].BackgroundTransparency = HalfImageTransparency
				Grid[Object3 + 14].BackgroundTransparency = ImageTransparency
			end

			local C = math.ceil(4 * X + 5) -- Lerp(5, 9, x)

			for Index = 6, C do
				local E = 14 * (Index + XOffset - 1) + Index - 4 + YOffset
				Grid[E].BackgroundTransparency = ImageTransparency
				Grid[E + 13].BackgroundTransparency = ImageTransparency
				Grid[E + 14].BackgroundTransparency = ImageTransparency
				Grid[E + 28].BackgroundTransparency = HalfImageTransparency
				Grid[E + 27].BackgroundTransparency = ImageTransparency
			end

			local NewXOffset = math.floor(-5 * X + 1) -- Lerp(1, -3 - 1, x)
			local NewYOffset = math.ceil(3 * X - 1) -- Lerp(-1, 2, x)

			local XOffsetChange = XOffset - NewXOffset
			local YOffsetChange = NewYOffset - YOffset

			self.XOffset, self.YOffset = NewXOffset, NewYOffset

			-- Shift according to XOffsetChange and YOffsetChange
			for _ = 1, XOffsetChange do
				for B = 1, 14 do
					for F = 1, 13 do
						Grid[14 * (F - 1) + B].BackgroundTransparency = Grid[14 * F + B].BackgroundTransparency
					end
				end
			end

			for _ = 1, YOffsetChange do
				for B = 1, 14 do
					for F = 14, 2, -1 do
						Grid[14 * (B - 1) + F].BackgroundTransparency = Grid[14 * (B - 1) + F - 1].BackgroundTransparency
					end

					Grid[14 * (B - 1) + 1].BackgroundTransparency = ImageTransparency
				end
			end

			local OpenTween = self.OpenTween
			if A == 9 and OpenTween then
				self.OpenTween:Stop()
				for Index = 1, 196 do
					Grid[Index].BackgroundTransparency = ImageTransparency
				end

				self.OpenTween = Tween_new(FILL_DURATION, Enumeration.EasingFunction.Deceleration.Value, self.EmptyCenter, self)
			end
		end
	};

	WrappedProperties = {
		Button = {"AnchorPoint", "Name", "Parent", "Position", "LayoutOrder", "NextSelectionDown", "NextSelectionLeft", "NextSelectionRight", "NextSelectionUp"};
	};

	Properties = {
		Indeterminate = Typer.AssignSignature(2, Typer.Boolean, function(self, Indeterminate)
			if Indeterminate then
				if self.Checked then
					self:Rawset("Checked", false)
				end

				self:SetColorAndTransparency(self.PrimaryColor3, 0)
				self:FillCenter()
				self.Button.Image = INDETERMINATE_CHECKBOX_IMAGE
			end

			self:Rawset("Indeterminate", Indeterminate)
		end);

		Checked = Typer.AssignSignature(2, Typer.Boolean, function(self, Value)
			self:Rawset("Checked", Value)
			self.Indeterminate = false

			if self.OpenTween then
				self.OpenTween:Stop()
				self.OpenTween2:Stop()
				self.OpenTween = false
				self.OpenTween2 = false
			end

			if Value then
				self:SetColorAndTransparency(self.PrimaryColor3, 0)
				self:FillCenter()
				self:DrawCheckmark()
			else
				local Theme = CHECKBOX_THEMES[self.Theme.Value]
				self:SetColorAndTransparency(Theme.ImageColor3, Theme.ImageTransparency)
				self:EraseCheckmark()
				self:EmptyCenter()
			end

			self.OnChecked:Fire(Value)
		end);

		ZIndex = Typer.AssignSignature(2, Typer.Number, function(self, ZIndex)
			local Grid = self.Grid
			self.GridFrame.ZIndex = ZIndex

			for A = 1, 196 do
				Grid[A].ZIndex = ZIndex
			end

			for Name in next, SETS do
				for _, Set in ipairs(Grid[Name]) do
					Set.ZIndex = ZIndex
				end
			end

			self.Button.ZIndex = ZIndex + 1
			self:Rawset("ZIndex", ZIndex)
		end);
	};

	Events = table.create(0);

	Methods = {
		SetChecked = Typer.AssignSignature(2, Typer.OptionalBoolean, function(self, NewChecked)
			if NewChecked == nil then
				NewChecked = not self.Checked
			end

			local Button = self.Button

			if self.OpenTween then
				self.OpenTween:Stop()
				self.OpenTween2:Stop()
			end

			if NewChecked ~= self.Checked then
				self.GridFrame.Visible = true

				if Button.Size == CHECKBOX_SIZE then
					if NewChecked then
						self:SetColorAndTransparency(self.PrimaryColor3, 0)
						Button.ImageTransparency = 1
						self.OpenTween = self.Indeterminate and Tween_new(DRAW_DURATION, Enumeration.EasingFunction.Deceleration.Value, self.DrawCheckmark, self)
							or Tween_new(FILL_DURATION, Enumeration.EasingFunction.Deceleration.Value, self.FillCenter, self)
						self.OpenTween2 = Tween_new(SHRINK_DURATION, Enumeration.EasingFunction.Deceleration.Value, self.ShrinkFrame, self)
					else
						local Theme = CHECKBOX_THEMES[self.Theme.Value]

						self:SetColorAndTransparency(Theme.ImageColor3, Theme.ImageTransparency)
						Button.ImageTransparency = 1
						self.XOffset, self.YOffset = 0, 0
						self.OpenTween = Tween_new(DRAW_DURATION, Enumeration.EasingFunction.Deceleration.Value, self.EraseCheckmark, self)
						self.OpenTween2 = Tween_new(SHRINK_DURATION, Enumeration.EasingFunction.Deceleration.Value, self.ShrinkFrame, self)
					end

					self:Rawset("Checked", NewChecked)
					self.Indeterminate = false -- These two lines happen implicitly for the self.Checked = NewChecked statement
					self.OnChecked:Fire(NewChecked)
				else
					self.Checked = NewChecked
				end
			end
		end);
	};

	Init = function(self)
		self.Button = self.Template:Clone()
		self:Rawset("Object", self.Button)
		local GridFrame = self.Button.GridFrame
		local Grid = {}

		-- Private
		self.Grid = Grid
		self.GridFrame = GridFrame

		for Name in next, SETS do
			local Count = 0
			local Objects = {}
			local Pixel = GridFrame:FindFirstChild(Name)

			while Pixel do
				Count += 1
				Pixel.Name = ""
				Objects[Count] = Pixel
				Pixel = GridFrame:FindFirstChild(Name)
			end

			Grid[Name] = Objects
		end

		-- Track pixel grid
		for A = 1, 14 * 14 do
			Grid[A] = GridFrame[A]
		end

--		local Mouse = Players.LocalPlayer:GetMouse()
--
--		-- To-Do: Change to InputBegan and InputEnded!
--		self.Button.MouseEnter:Connect(function()
--			Mouse.Icon = "rbxassetid://1990755280"
--		end)
--
--		self.Button.MouseLeave:Connect(function()
--			Mouse.Icon = ""
--		end)

		self:SuperInit()

		-- Public
		self.ZIndex = 1
	end;
}, SelectionController)