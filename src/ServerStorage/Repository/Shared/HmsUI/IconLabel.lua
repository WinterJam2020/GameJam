local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local Color = Resources:LoadLibrary("Color")
local PseudoInstance = Resources:LoadLibrary("PseudoInstance")
local Spritesheet = Resources:LoadLibrary("MaterialSpritesheet")
local Typer = Resources:LoadLibrary("Typer")

local SHEET_ASSETS = {
	"rbxassetid://3926305904";
	"rbxassetid://3926307971";
	"rbxassetid://3926309567";
	"rbxassetid://3926311105";
	"rbxassetid://3926312257";
	"rbxassetid://3926313458";
	"rbxassetid://3926314806";
	"rbxassetid://3926316119";
	"rbxassetid://3926317787";
	"rbxassetid://3926319099";
	"rbxassetid://3926319860";
	"rbxassetid://3926321212";
	"rbxassetid://3926326846";
	"rbxassetid://3926327588";
	"rbxassetid://3926328650";
	"rbxassetid://3926329330";
	"rbxassetid://3926330123";
	"rbxassetid://3926333840";
	"rbxassetid://3926334787";
	"rbxassetid://3926335698";
}

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

local ClosestResolution = Typer.AssignSignature(Typer.Table, Typer.Number, function(Icon, GoalResolution)
	local Closest = 0
	local ClosestDelta = nil

	for Resolution in next, Icon do
		if GoalResolution % Resolution == 0 or Resolution % GoalResolution == 0 then
			return Resolution
		elseif not ClosestDelta or math.abs(Resolution - GoalResolution) < ClosestDelta then
			Closest = Resolution
			ClosestDelta = math.abs(Resolution - GoalResolution)
		end
	end

	return Closest
end)

local Frame = Instance.new("ImageLabel")
Frame.BackgroundTransparency = 1
Frame.BorderSizePixel = 0
Frame.Image = ""
Instance.new("UIAspectRatioConstraint").Parent = Frame

return PseudoInstance:Register("IconLabel", {
	WrappedProperties = {
		Object = {"AnchorPoint", "Active", "Name", "Size", "Position", "LayoutOrder", "NextSelectionDown", "NextSelectionLeft", "NextSelectionRight", "NextSelectionUp", "Parent", "ZIndex"};
	};

	Events = table.create(0);
	Methods = table.create(0);

	Properties = {
		Resolution = Typer.NonNegativeNumber;
		IconColor3 = Typer.AssignSignature(2, Typer.Color3, function(self, IconColor3)
			self.Object.ImageColor3 = IconColor3
			self:Rawset("IconColor3", IconColor3)
		end);

		IconTransparency = Typer.AssignSignature(2, Typer.NonNegativeNumber, function(self, Transparency)
			self.Object.ImageTransparency = Transparency
			self:Rawset("IconTransparency", Transparency)
		end);

		Icon = Typer.AssignSignature(2, Typer.String, function(self, IconName)
			local Icon = Spritesheet[IconName]
			local ChosenResolution = self.Resolution
			local Object = self.Object

			if not ChosenResolution then
				if Object.Size.X.Scale ~= 0 or Object.Size.Y.Scale ~= 0 then
					ChosenResolution = ClosestResolution(Icon, math.huge)
				else
					assert(Object.Size.X.Offset == Object.Size.Y.Offset, "If using offset Icon size must result in a square")
					ChosenResolution = ClosestResolution(Icon, Object.Size.X.Offset)
				end
			end

			local Variant = Icon[ChosenResolution]
			Object.Image = SHEET_ASSETS[Variant.Sheet]
			Object.BackgroundTransparency = 1
			Object.ImageRectSize = Vector2.new(Variant.Size, Variant.Size)
			Object.ImageRectOffset = Vector2.new(Variant.X, Variant.Y)
			self:Rawset("Icon", IconName)
		end);
	};

	Init = function(self, ...)
		self:Rawset("Object", Frame:Clone())
		self.Janitor:Add(self.Object, "Destroy")

		self.Icon = "more_vert"
		self.IconColor3 = Color.White
		self.IconTransparency = 0

		self:SuperInit(...)
	end;
})