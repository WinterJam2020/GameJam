local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local Enumeration = Resources:LoadLibrary("Enumerations")
local PseudoInstance = Resources:LoadLibrary("PseudoInstance")
local ReplicatedPseudoInstance = Resources:LoadLibrary("ReplicatedPseudoInstance")
local Tween = Resources:LoadLibrary("Tween")
local Typer = Resources:LoadLibrary("Typer")

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

local Screen = Instance.new("ScreenGui")
Screen.Name = "HmsPriorityUIs"
Screen.DisplayOrder = 2 ^ 31 - 2
Screen.ResetOnSpawn = false
Screen.Parent = PlayerGui

local DialogBlur = Instance.new("BlurEffect")
DialogBlur.Size = 0
DialogBlur.Name = "HmsBlur"

local function SetDialogBlurParentToNil()
	DialogBlur.Parent = nil
end

-- NOTE: Enter()s automatically when Parented
return PseudoInstance:Register("HmsPriorityUI", {
	Storage = table.create(0);
	Internals = {
		Blur = function(self)
			DialogBlur.Parent = Lighting
			Tween(DialogBlur, "Size", 56, Enumeration.EasingFunction.Deceleration.Value, self.ENTER_TIME, true)
		end;

		Unblur = function(self)
			Tween(DialogBlur, "Size", 0, Enumeration.EasingFunction.Acceleration.Value, self.ENTER_TIME, true, SetDialogBlurParentToNil)
		end;

		DISMISS_TIME = 75 / 1000 * 2;
		ENTER_TIME = 150 / 1000 * 2;
		SCREEN = Screen;
	};

	Events = table.create(0);
	Methods = {
		Enter = 0;
		Dismiss = 0;

		Destroy = function(self)
			self:Dismiss()
			self:Super("Destroy")
		end;
	};

	Properties = {
		Dismissed = Typer.Boolean;
		Parent = function(self, Parent)
			if Parent and PlayerGui then
				self:Enter()
				if self.SHOULD_BLUR then
					self:Blur()
				end
			end

			self:Rawset("Parent", Parent)
		end;
	};

	Init = function(self, ...)
		self:SuperInit(...)
	end;
}, ReplicatedPseudoInstance)