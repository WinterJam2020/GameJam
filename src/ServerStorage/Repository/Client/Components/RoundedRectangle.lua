local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Enumeration = Resources:LoadLibrary("Enumerations")
local Roact = Resources:LoadLibrary("Roact")
local t = Resources:LoadLibrary("t")

local TARGET_SCALE = 2
local CIRCLE_IMAGES = {
	[16] = "rbxassetid://3056541177",
	[32] = "rbxassetid://3088713341",
	[64] = "rbxassetid://4918677124",
	[128] = "rbxassetid://2600845734",
	[500] = "rbxassetid://2609138523",
}

local SINGLE_EDGE_PROPS = {
	Top = {
		Center = Vector2.new(0.5, 0.5),
		Size = Vector2.new(1, 0.5),
		Offset = Vector2.new(),
	},

	Bottom = {
		Center = Vector2.new(0.5, 0),
		Size = Vector2.new(1, 0.5),
		Offset = Vector2.new(0, 0.5),
	},

	Left = {
		Center = Vector2.new(0.5, 0.5),
		Size = Vector2.new(0.5, 1),
		Offset = Vector2.new(),
	},

	Right = {
		Center = Vector2.new(0, 0.5),
		Size = Vector2.new(0.5, 1),
		Offset = Vector2.new(0.5, 0),
	},
}

local SINGLE_CORNER_PROPS = {
	TopLeft = {
		Center = Vector2.new(0.5, 0.5),
		Offset = Vector2.new(0, 0.5),
	},

	TopRight = {
		Center = Vector2.new(0, 0.5),
		Offset = Vector2.new(0.5, 0),
	},

	BottomLeft = {
		Center = Vector2.new(0.5, 0),
		Offset = Vector2.new(0, 0.5),
	},

	BottomRight = {
		Center = Vector2.new(),
		Offset = Vector2.new(0.5, 0.5),
	},
}

local function GetTargetSize(radius)
	local scaledRadius = radius / TARGET_SCALE
	for size, image in next, CIRCLE_IMAGES do
		if size > scaledRadius then
			return size, image
		end
	end

	error(string.format("Couldn't find circle image for radius %d", radius))
end

local RoundedRectangle = Roact.Component:extend("RoundedRectangle")
RoundedRectangle.defaultProps = {
	Mode = Enumeration.RectangleMode.AllCorners,
}

RoundedRectangle.validateProps = t.interface({
	Activated = t.optional(t.callback),
	Active = t.optional(t.boolean),
	AnchorPoint = t.optional(t.Vector2),
	ClipsDescendants = t.optional(t.boolean),
	Color = t.optional(t.Color3),
	Edge = t.optional(t.union(t.keyOf(SINGLE_EDGE_PROPS), t.keyOf(SINGLE_CORNER_PROPS))),
	LayoutOrder = t.optional(t.integer),
	Mode = t.enumerationByString("RectangleMode"),
	Position = t.optional(t.UDim2),
	Radius = t.integer,
	Rotation = t.optional(t.number),
	Size = t.optional(t.UDim2),
	Transparency = t.optional(t.number),
	ZIndex = t.optional(t.integer),
})

local Roact_createElement = Roact.createElement

function RoundedRectangle:render()
	local radius = self.props.Radius
	local mode = self.props.Mode

	local targetSize, image = GetTargetSize(radius)
	local halfTargetSize = targetSize / 2

	local sliceCenter, imageRectSize, imageRectOffset

	if mode == Enumeration.RectangleMode.AllCorners then
		sliceCenter = Rect.new(halfTargetSize, halfTargetSize, halfTargetSize, halfTargetSize)
	else
		local props
		if mode == Enumeration.RectangleMode.SingleEdge then
			props = SINGLE_EDGE_PROPS[self.props.Edge]
		elseif mode == Enumeration.RectangleMode.SingleCorner then
			props = SINGLE_CORNER_PROPS[self.props.Corner]
		end

		if props.Center then
			local center = props.Center * targetSize
			sliceCenter = Rect.new(center, center)
		end

		if props.Size then
			imageRectSize = props.Size * targetSize
		end

		if props.Offset then
			imageRectOffset = props.Offset * targetSize
		end
	end

	return Roact_createElement(self.props.Activated and "ImageButton" or "ImageLabel", {
		Image = image,
		ImageColor3 = self.props.Color,
		ImageTransparency = self.props.Transparency,
		ImageRectSize = imageRectSize,
		ImageRectOffset = imageRectOffset,

		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = sliceCenter,
		SliceScale = radius / targetSize * 2,

		Size = self.props.Size,
		Position = self.props.Position,
		AnchorPoint = self.props.AnchorPoint,
		Rotation = self.props.Rotation,

		Active = self.props.Active,
		ClipsDescendants = self.props.ClipsDescendants,
		LayoutOrder = self.props.LayoutOrder,
		ZIndex = self.props.ZIndex,
		BackgroundTransparency = 1,

		AutoButtonColor = self.props.Activated and false or nil,
		[Roact.Event.Activated] = self.props.Activated,
	}, self.props[Roact.Children])
end

return RoundedRectangle