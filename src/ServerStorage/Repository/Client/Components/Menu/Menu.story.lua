local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)

local Menu = require(script.Parent)
local Roact = Resources:LoadLibrary("Roact")

return function(Target)
	local Tree = Roact.mount(Roact.createElement(Menu), Target, "MenuStory")
	return function()
		Roact.unmount(Tree)
	end
end