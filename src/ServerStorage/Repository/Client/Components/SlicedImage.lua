local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Roact = Resources:LoadLibrary("Roact")
local Table = Resources:LoadLibrary("Table")

local function SlicedImage(props)
	local newProps = Table.DeepCopy(props)
	local slice = newProps.Slice

	return Roact.createElement("ImageLabel", {
		Image = slice.Image,
		ImageColor3 = newProps.Color,
		ImageTransparency = newProps.Transparency,

		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = slice.Center,
		SliceScale = slice.Scale,

		Size = newProps.Size,
		Position = newProps.Position,
		AnchorPoint = newProps.AnchorPoint,

		ZIndex = newProps.ZIndex,
		LayoutOrder = newProps.LayoutOrder,
		BackgroundTransparency = 1,
	}, newProps[Roact.Children])
end

return SlicedImage