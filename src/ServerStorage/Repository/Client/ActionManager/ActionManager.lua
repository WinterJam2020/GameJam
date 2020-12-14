--- Holds single toggleable actions (like a tool system)
-- @classmod ActionManager

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local Resources = require(ReplicatedStorage.Resources)
local Debug = Resources:LoadLibrary("Debug")
local Janitor = Resources:LoadLibrary("Janitor")
local Signal = Resources:LoadLibrary("Signal")
local ValueObject = Resources:LoadLibrary("ValueObject")

local ActionManager = setmetatable({ClassName = "ActionManager"}, {})
ActionManager.__index = ActionManager

function ActionManager.new()
	local self = setmetatable({
		ActionAdded = Signal.new(); -- :Fire(action)
		ActiveAction = nil;

		Actions = {};
		Janitor = Janitor.new();
	}, ActionManager)

	self.ActiveAction = self.Janitor:Add(ValueObject.new(), "Destroy")

	self.Janitor:Add(ContextActionService.LocalToolEquipped:Connect(function()
		self:StopCurrentAction()
	end), "Disconnect", "ToolEquipped")

	self.Janitor:Add(self.ActiveAction.Changed:Connect(function(Value)
		local ActiveActionJanitor = self.Janitor:Add(Janitor.new(), "Destroy", "ActiveActionJanitor")
		if Value then
			ActiveActionJanitor:Add(function()
				Value:Deactivate()
			end, true)

			ActiveActionJanitor:Add(Value.Deactivated:Connect(function()
				if self.ActiveAction == Value then
					self.ActiveAction.Value = nil
				end
			end), "Disconnect")
		end

		if Value and not Value.IsActivatedValue.Value then
			Debug.Warn("[ActionManager.ActiveAction.Changed] - Immediate deactivation of %q", tostring(Value:GetName()))
			self.ActiveAction.Value = nil
		end
	end), "Disconnect")

	return self
end

function ActionManager:StopCurrentAction()
	self.ActiveAction.Value = nil
end

function ActionManager:ActivateAction(Name, ...)
	local Action = self.Actions[Name]
	if Action then
		Action:Activate(...)
	else
		Debug.Error("[ActionManager] - No action with name %q.", Name)
	end
end

function ActionManager:GetAction(Name)
	return self.Actions[Name]
end

function ActionManager:GetActions()
	local Actions = {}
	local Length = 0
	for _, Action in next, self.Actions do
		Length += 1
		Actions[Length] = Action
	end

	return Actions
end

function ActionManager:AddAction(Action)
	local Name = Action:GetName()
	if self.Actions[Name] then
		Debug.Error("[ActionManager] - action with name %q already exists", Name)
	end

	self.Actions[Name] = Action
	self.Janitor:Add(Action.Activated:Connect(function()
		self.ActiveAction.Value = Action
	end), "Disconnect")

	self.Janitor:Add(Action.Deactivated:Connect(function()
		if self.ActiveAction.Value == Action then
			self.ActiveAction.Value = nil
		end
	end), "Disconnect")

	self.ActionAdded:Fire(Action)
	return self
end

return ActionManager