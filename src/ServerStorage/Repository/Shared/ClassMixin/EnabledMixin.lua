local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Janitor = Resources:LoadLibrary("Janitor")
local Signal = Resources:LoadLibrary("Signal")

local EnabledMixin = {}

function EnabledMixin:Add(Class)
	assert(Class)
	assert(not Class.Enable)
	assert(not Class.Disable)
	assert(not Class.SetEnabled)
	assert(not Class.IsEnabled)
	assert(not Class.InitEnabledMixin)

	-- Inject methods
	Class.IsEnabled = self.IsEnabled
	Class.Enable = self.Enable
	Class.Disable = self.Disable
	Class.SetEnabled = self.SetEnabled
	Class.InitEnabledMixin = self.InitEnabledMixin
end

-- Initialize EnabledMixin
function EnabledMixin:InitEnabledMixin(EnabledJanitor)
	self.EnabledJanitorReference = assert(EnabledJanitor or self.Janitor, "Must have a Janitor.")
	self.Enabled = false
	self.EnabledChanged = self.EnabledJanitorReference:Add(Signal.new(), "Destroy") -- :Fire(isEnabled, doNotAnimate, enabledMaid)
end

function EnabledMixin:IsEnabled()
	return self.Enabled
end

function EnabledMixin:Enable(DoNotAnimate)
	self:SetEnabled(true, DoNotAnimate)
end

function EnabledMixin:Disable(DoNotAnimate)
	self:SetEnabled(false, DoNotAnimate)
end

function EnabledMixin:SetEnabled(IsEnabled: boolean, DoNotAnimate)
	assert(type(IsEnabled) == "boolean")

	if self.Enabled ~= IsEnabled then
		self.Enabled = IsEnabled
		self.EnabledChanged:Fire(IsEnabled, DoNotAnimate, self.EnabledJanitorReference:Add(Janitor.new(), "Destroy", "EnabledJanitor"))
	end
end

return EnabledMixin