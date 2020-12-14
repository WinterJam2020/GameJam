local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Binder = Resources:LoadLibrary("Binder")
local BinderProvider = Resources:LoadLibrary("BinderProvider")

return BinderProvider.new(function(self)
	self:Add(Binder.new("Ragdoll", Resources:LoadLibrary("RagdollClient")))
	self:Add(Binder.new("Ragdollable", Resources:LoadLibrary("RagdollableClient")))

	self:Add(Binder.new("RagdollHumanoidOnDeath", Resources:LoadLibrary("RagdollHumanoidOnDeathClient")))
	self:Add(Binder.new("RagdollHumanoidOnFall", Resources:LoadLibrary("RagdollHumanoidOnFallClient")))
end)