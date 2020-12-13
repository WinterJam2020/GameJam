local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local Resources = require(ReplicatedStorage.Resources)
local Enumeration = Resources:LoadLibrary("Enumerations")
local HmsPriorityUI = Resources:LoadLibrary("HmsPriorityUI")
local PseudoInstance = Resources:LoadLibrary("PseudoInstance")
local Scheduler = Resources:LoadLibrary("Scheduler")
local Tween = Resources:LoadLibrary("Tween")
local Typer = Resources:LoadLibrary("Typer")

Resources:LoadLibrary("ReplicatedPseudoInstance")

local PillBackingBuilder = Resources:LoadLibrary("PillBackingBuilder").new {
	ZIndex = 3;
	ShadowZIndex = 2;
	BackgroundColor3 = Color3.new();
}

local TEXT_SIZE = 20
local FONT = Enum.Font.SourceSans

local HEIGHT = 48
local SMALLEST_WIDTH = 294

local TweenCompleted = Enum.TweenStatus.Completed

local ToastFrame = Instance.new("Frame")
ToastFrame.AnchorPoint = Vector2.new(0.5, 0.9)
ToastFrame.Size = UDim2.new(1, 0, 0, 48)
ToastFrame.Position = UDim2.fromScale(0.5, 0.9)
ToastFrame.Name = "ToastFrame"
ToastFrame.BackgroundTransparency = 1

local LocalPlayer, PlayerGui do
	if RunService:IsClient() then
		repeat
			LocalPlayer = Players.LocalPlayer
		until LocalPlayer or not wait()

		repeat
			PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		until PlayerGui or not wait()
	end
end

local LARGE_FRAME_SIZE = Vector2.new(32767, 32767)

local Storage = {}

local function IsInputting(CurrentlyInputting)
	for _, Bool in next, CurrentlyInputting do
		if Bool == true then
			return true
		end
	end

	return false
end

return PseudoInstance:Register("Toast", {
	Storage = Storage;
	WrappedProperties = {
		Object = {"Active", "LayoutOrder", "NextSelectionDown", "NextSelectionLeft", "NextSelectionRight", "NextSelectionUp"};
	};

	Methods = {
		Enter = function(self)
			self.Dismissed = false
			local ParentFrame = self.ParentFrame
			ParentFrame.Parent = self.SCREEN

			if Storage.OpenToast then
				Storage.OpenToast:Dismiss()
				Storage.OpenToast.Janitor:Cleanup()
			end

			Storage.OpenToast = self
			local CurrentlyInputting = {}

			ParentFrame.InputBegan:Connect(function(InputObject)
				CurrentlyInputting[InputObject.UserInputType.Value] = true
			end)

			ParentFrame.InputEnded:Connect(function(InputObject)
				CurrentlyInputting[InputObject.UserInputType.Value] = false
			end)

			Tween(self.ToastText, "TextTransparency", 0, Enumeration.EasingFunction.Deceleration.Value, 0.3, false)

			Tween(self.Object.LeftHalfCircle, "ImageTransparency", 0.4, Enumeration.EasingFunction.Deceleration.Value, 0.3, false)
			Tween(self.Object.RightHalfCircle, "ImageTransparency", 0.4, Enumeration.EasingFunction.Deceleration.Value, 0.3, false)
			Tween(self.Object, "BackgroundTransparency", 0.4, Enumeration.EasingFunction.Deceleration.Value, 0.3, false, function(Completed)
				if Completed == TweenCompleted and Scheduler.Wait2(self.DisplayTime) then
					while IsInputting(CurrentlyInputting) do
						repeat until not IsInputting(CurrentlyInputting) or not Scheduler.Wait2(0.03)
						Scheduler.Wait2(self.DisplayTime)
					end

					pcall(function()
						self:Dismiss()
					end)
				end
			end)
		end;

		Dismiss = function(self)
			if not self.Dismissed then
				self.Dismissed = true
				local ParentFrame = self.ParentFrame
				ParentFrame.ZIndex -= 1
				Debris:AddItem(ParentFrame, 0.375)

				Tween(self.ToastText, "TextTransparency", 1, Enumeration.EasingFunction.Acceleration.Value, 0.375, false)
				Tween(self.Object.LeftHalfCircle, "ImageTransparency", 1, Enumeration.EasingFunction.Acceleration.Value, 0.375, false)
				Tween(self.Object.RightHalfCircle, "ImageTransparency", 1, Enumeration.EasingFunction.Acceleration.Value, 0.375, false)
				Tween(self.Object, "BackgroundTransparency", 1, Enumeration.EasingFunction.Acceleration.Value, 0.375, false, function(Completed)
					if Completed == TweenCompleted then
						if Storage.OpenToast == self then
							Storage.OpenToast = nil
						end
					end
				end)
			end
		end;
	};

	Events = table.create(0);
	Internals = {
		"ToastText", "ParentFrame";
		SHOULD_BLUR = false;

		TextWidth = 0;
		ENTER_TIME = 0.275;

		AdjustToastSize = function(self)
			local Width = self.TextWidth + 48
			self.Object.Size = UDim2.fromOffset(Width > SMALLEST_WIDTH and Width or SMALLEST_WIDTH, HEIGHT)
		end;
	};

	Properties = {
		DisplayTime = Typer.Number;
		Text = Typer.AssignSignature(2, Typer.String, function(self, Text)
			self.TextWidth = TextService:GetTextSize(Text, TEXT_SIZE, FONT, LARGE_FRAME_SIZE).X
			self.ToastText.Text = Text
			self:AdjustToastSize()
			self:Rawset("Text", Text)
		end);
	};

	Init = function(self, ...)
		self.ParentFrame = ToastFrame:Clone()
		self:Rawset("Object", PillBackingBuilder:Create(self.ParentFrame, {
			ZIndex = 3;
			ShadowZIndex = 2;
			BackgroundColor3 = Color3.new();
		}))

		local TextHolder = Instance.new("Frame")
		TextHolder.BackgroundTransparency = 1
		TextHolder.Name = "TextHolder"
		TextHolder.Size = UDim2.fromScale(1, 1)
		TextHolder.Parent = self.Object

		local UIPadding = Instance.new("UIPadding")
		UIPadding.PaddingBottom = UDim.new(0, 12)
		UIPadding.PaddingTop = UDim.new(0, 16)
		UIPadding.Parent = TextHolder

		local ToastText = Instance.new("TextLabel")
		ToastText.BackgroundTransparency = 1
		ToastText.Name = "ToastText"
		ToastText.Size = UDim2.fromScale(1, 1)
		ToastText.Font = Enum.Font.SourceSans
		ToastText.TextScaled = true
		ToastText.TextXAlignment = Enum.TextXAlignment.Left
		ToastText.TextColor3 = Color3.new(1, 1, 1)
		ToastText.ZIndex = 500
		ToastText.TextTransparency = 1
		ToastText.Parent = TextHolder

		self.Object.LeftHalfCircle.ImageTransparency = 1
		self.Object.RightHalfCircle.ImageTransparency = 1
		self.Object.BackgroundTransparency = 1
		self.ToastText = ToastText

		self:Rawset("DisplayTime", 4)

		self.Janitor:Add(self.ParentFrame, "Destroy")
		self.Janitor:Add(self.Object, "Destroy")
		self.Janitor:Add(self.ToastText, "Destroy")

		self:SuperInit(...)
	end;
}, HmsPriorityUI)