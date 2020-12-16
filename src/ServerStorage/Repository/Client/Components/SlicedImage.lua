local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Roact = Resources:LoadLibrary("Roact")

local function SlicedImage(props)
	local slice = props.Slice

	return Roact.createElement("ImageLabel", {
		Image = slice.Image,
		ImageColor3 = props.Color,
		ImageTransparency = props.Transparency,

		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = slice.Center,
		SliceScale = slice.Scale,

		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,

		ZIndex = props.ZIndex,
		LayoutOrder = props.LayoutOrder,
		BackgroundTransparency = 1,
	}, props[Roact.Children])
end

return SlicedImage