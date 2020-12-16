local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Janitor = Resources:LoadLibrary("Janitor")
local Signal = Resources:LoadLibrary("Signal")

local BasicPane = {ClassName = "BasicPane"}
BasicPane.__index = BasicPane

function BasicPane.new(Gui)
	local self = setmetatable({
		Janitor = Janitor.new();
		Visible = false;
		VisibleChanged = nil;
	}, BasicPane)

	self.VisibleChanged = self.Janitor:Add(Signal.new(), "Destroy") -- :Fire(isVisible, doNotAnimate, maid)

	if Gui then
		self.Gui = self.Janitor:Add(Gui, "Destroy")
	end

	return self
end

function BasicPane:SetVisible(IsVisible, DoNotAnimate)
	assert(type(IsVisible) == "boolean")

	if self.Visible ~= IsVisible then
		self.Visible = IsVisible
		self.VisibleChanged:Fire(self.Visible, DoNotAnimate, self.Janitor:Add(Janitor.new(), "Destroy", "PaneVisibleJanitor"))
	end
end

function BasicPane:Show(DoNotAnimate)
	self:SetVisible(true, DoNotAnimate)
end

function BasicPane:Hide(DoNotAnimate)
	self:SetVisible(false, DoNotAnimate)
end

function BasicPane:Toggle(DoNotAnimate)
	self:SetVisible(not self.Visible, DoNotAnimate)
end

function BasicPane:IsVisible()
	return self.Visible
end

function BasicPane:Destroy()
	self.Janitor:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

return BasicPane