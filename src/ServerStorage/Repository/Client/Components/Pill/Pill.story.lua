local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Pill = require(script.Parent)
local Roact = Resources:LoadLibrary("Roact")

local FONTS_TO_USE = {
	Enum.Font.SourceSans,
	Enum.Font.GothamSemibold,
	Enum.Font.Oswald,
	Enum.Font.Roboto,
	Enum.Font.RobotoCondensed,
	Enum.Font.TitilliumWeb,
}

return function(Target)
	local Pills = table.create(6)
	Pills.UIListLayout = Roact.createElement("UIListLayout", {
		Padding = UDim.new(0, 15),
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})

	for Index = 1, 6 do
		Pills[Index] = Roact.createElement(Pill, {
			BackgroundColor3 = Color3.new(1, 1, 1),
			CreateShadow = Index % 2 == 0,
			LayoutOrder = Index,
			Size = UDim2.new(0.5, 0, 0, 60),
		}, {
			PillLabel = Roact.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(0.85, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundTransparency = 1,

				Font = FONTS_TO_USE[Index],
				TextScaled = true,
				Text = string.format("Pill #%d", Index),
				ZIndex = 3,
			}),
		})
	end

	local Tree = Roact.mount(Roact.createElement("ScrollingFrame", {
		-- BackgroundTransparency = 1,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ScrollBarThickness = 0,
	}, Pills), Target, "PillsDemo")

	return function()
		Roact.unmount(Tree)
	end
end