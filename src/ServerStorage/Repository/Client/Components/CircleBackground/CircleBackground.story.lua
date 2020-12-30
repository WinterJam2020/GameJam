local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local CircleBackground = require(script.Parent)
local Roact = Resources:LoadLibrary("Roact")

local function CircleBackgroundStory()
	return Roact.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		CircleBackground = Roact.createElement(CircleBackground, {
			Speed = 1,
		}),
	})
end

return function(Target)
	local Tree = Roact.mount(Roact.createElement(CircleBackgroundStory), Target, "CircleBackgroundStory")

	return function()
		Roact.unmount(Tree)
	end
end