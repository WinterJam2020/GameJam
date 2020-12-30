local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Roact = Resources:LoadLibrary("Roact")

local storeKey = require(script.Parent.storeKey)

local StoreProvider = Roact.Component:extend("StoreProvider")

function StoreProvider:init(props)
	local store = props.store

	if store == nil then
		error("Error initializing StoreProvider. Expected a `store` prop to be a Rodux store.")
	end

	self._context[storeKey] = store
end

function StoreProvider:render()
	return Roact.createFragment(self.props[Roact.Children])
end

return StoreProvider