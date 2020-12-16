local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local SwShButton = require(script.Parent)
local Roact = Resources:LoadLibrary("Roact")

return function(Target)
	local Tree = Roact.mount(Roact.createElement("Frame", {
		BackgroundTransparency = 1,
		-- BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, {
		Button = Roact.createElement(SwShButton, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.5, 0.125),
		}),
	}), Target, "SwShButtonDemmo")

	return function()
		Roact.unmount(Tree)
	end
end