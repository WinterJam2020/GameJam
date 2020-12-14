--- Holds binders
-- @classmod RagdollBindersServer
-- @author Quenty

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Binder = Resources:LoadLibrary("Binder")
local BinderProvider = Resources:LoadLibrary("BinderProvider")

return BinderProvider.new(function(self)
	self:Add(Binder.new("Ragdoll", Resources:LoadLibrary("Ragdoll")))
	self:Add(Binder.new("Ragdollable", Resources:LoadLibrary("Ragdollable")))

	self:Add(Binder.new("RagdollHumanoidOnDeath", Resources:LoadLibrary("RagdollHumanoidOnDeath")))
	self:Add(Binder.new("RagdollHumanoidOnFall", Resources:LoadLibrary("RagdollHumanoidOnFall")))
end)