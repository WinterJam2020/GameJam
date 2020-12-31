local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Roact = Resources:LoadLibrary("Roact")
local Table = Resources:LoadLibrary("Table")

local Roact_createElement = Roact.createElement
local Table_DeepCopy = Table.DeepCopy

local function SlicedImage(props)
	local newProps = Table_DeepCopy(props)
	local slice = newProps.Slice

	return Roact_createElement("ImageLabel", {
		AnchorPoint = newProps.AnchorPoint,
		BackgroundTransparency = 1,

		Image = slice.Image,
		ImageColor3 = newProps.Color,
		ImageTransparency = newProps.Transparency,

		LayoutOrder = newProps.LayoutOrder,
		Position = newProps.Position,
		ScaleType = Enum.ScaleType.Slice,
		Size = newProps.Size,

		SliceCenter = slice.Center,
		SliceScale = slice.Scale,
		ZIndex = newProps.ZIndex,
	}, newProps[Roact.Children])
end

return SlicedImage