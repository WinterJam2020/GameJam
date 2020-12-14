local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local Resources = require(ReplicatedStorage.Resources)
local Debug = Resources:LoadLibrary("Debug")
local EnabledMixin = Resources:LoadLibrary("EnabledMixin")
local Janitor = Resources:LoadLibrary("Janitor")
local Signal = Resources:LoadLibrary("Signal")
local Typer = Resources:LoadLibrary("Typer")

local BaseAction = {ClassName = "BaseAction"}
BaseAction.__index = BaseAction

EnabledMixin:Add(BaseAction)

local Debug_Assert = Debug.Assert

type ReturnFunction<T> = () -> T
type Array<T> = {[number]: T}

type ActionData = {
	Name: string,
	Shortcuts: Array<EnumItem>,
	CanActivateShortcutCallback: ReturnFunction<boolean>?,
}

local ActionDataDefinition = Typer.MapDefinition {
	Name = Typer.String;
	Shortcuts = Typer.ArrayOfEnumItems; -- ArrayOfEnumOfTypeKeyCodeOrArrayOfEnumOfTypeUserInputType technically.
	CanActivateShortcutCallback = Typer.OptionalFunction;
}

BaseAction.new = Typer.AssignSignature({ActionData = ActionDataDefinition}, function(ActionData: ActionData)
	local self = setmetatable({
		Activated = nil;
		Deactivated = nil;
		IsActivatedValue = nil;

		ActivateData = nil;
		ContextActionKey = string.format("%s_ContextAction", tostring(ActionData.Name));
		Janitor = Janitor.new();
		Name = ActionData.Name;
	}, BaseAction)

	self.Activated = self.Janitor:Add(Signal.new(), "Destroy") -- :Fire(ActionJanitor, ... (activateData))
	self.Deactivated = self.Janitor:Add(Signal.new(), "Destroy") -- :Fire()
	self.IsActivatedValue = self.Janitor:Add(Instance.new("BoolValue"), "Destroy")

	self:InitEnabledMixin()

	self.Janitor:Add(self.IsActivatedValue.Changed:Connect(function()
		self:_HandleIsActiveValueChanged()
	end), "Disconnect")

	self.Janitor:Add(self.EnabledChanged:Connect(function(IsEnabled)
		self:_HandleEnabledChanged(IsEnabled)
	end), "Disconnect")

	return self:_WithActionData(ActionData)
end)

function BaseAction:GetName(): string
	return self.Name
end

function BaseAction:GetData(): ActionData
	return self.ActionData
end

function BaseAction:ToggleActivate(...)
	self.ActivateData = table.pack(...)
	if self.Enabled then
		self.IsActivatedValue.Value = not self.IsActivatedValue.Value
	else
		Debug.Warn("[BaseAction.ToggleActivate] - Not activating, not enabled")
		self.IsActivatedValue.Value = false
	end
end

function BaseAction:IsActive()
	return self.IsActivatedValue.Value
end

function BaseAction:Deactivate()
	self.IsActivatedValue.Value = false
end

function BaseAction:Activate(...)
	self.ActivateData = table.pack(...)
	if self.Enabled then
		self.IsActivatedValue.Value = true
	else
		Debug.Warn("[%s.Activate] - Not activating. Disabled!", self.Name)
	end
end

function BaseAction:Destroy()
	self.Janitor:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

BaseAction._WithActionData = Typer.AssignSignature(2, {ActionData = ActionDataDefinition}, function(self, ActionData: ActionData)
	self.ActionData = ActionData
	self:_UpdateShortcuts()
	return self
end)

function BaseAction:_HandleEnabledChanged(IsEnabled)
	if not IsEnabled then
		self:Deactivate()
	end

	self:_UpdateShortcuts()
end

function BaseAction:_HandleIsActiveValueChanged()
	if self.IsActivatedValue.Value then
		local ActivateData = self.ActivateData
		self.Activated:Fire(self.Janitor:Add(Janitor.new(), "Destroy", "ActionJanitor"), table.unpack(ActivateData, 1, ActivateData.n))
		self.ActivateData = nil
	else
		self.Janitor:Remove("ActionJanitor")
		self.Deactivated:Fire()
	end
end

function BaseAction:_UpdateShortcuts()
	local ActionData = Debug_Assert(self.ActionData, "ActionData doesn't exist?")
	local Shortcuts = ActionData.Shortcuts

	if #Shortcuts > 0 then
		if self.Enabled then
			ContextActionService:BindAction(self.ContextActionKey, function(_, UserInputState)
				if UserInputState == Enum.UserInputState.Begin then
					if self.ActionData.CanActivateShortcutCallback and not self.ActionData.CanActivateShortcutCallback() then
						return
					end

					self:ToggleActivate()
				end
			end, false, table.unpack(Shortcuts))
		else
			ContextActionService:UnbindAction(self.ContextActionKey)
		end
	end
end

return BaseAction