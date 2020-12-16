local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Llama = Resources:LoadLibrary("Llama")
local Roact = Resources:LoadLibrary("Roact")

local Pill = Roact.Component:extend("Pill")
Pill.defaultProps = {
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.new(1, 1, 1),
	CreateShadow = false,
	LayoutOrder = 0,
	Position = UDim2.new(),
	ShadowTransparency = 0.85,
	ShadowZIndex = 1,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 2,
}

function Pill:render()
	local size = self.props.Size
	local diameter = size.Y
	-- local width = size.X

	-- local addedScale = 0
	-- if width.Scale ~= 0 then
	-- 	addedScale = diameter.Scale / width.Scale / 2
	-- end

	return Roact.createElement("Frame", {
		AnchorPoint = self.props.AnchorPoint,
		BackgroundTransparency = 1,
		LayoutOrder = self.props.LayoutOrder,
		Position = self.props.Position,
		Size = size,
		ZIndex = self.props.ZIndex,
	}, {
		PillHolder = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1 - diameter.Scale, -diameter.Offset, 1, 0),
			ZIndex = self.props.ZIndex,
		}, Llama.Dictionary.join({
			PillBacking = Roact.createElement("Frame", {
				BackgroundColor3 = self.props.BackgroundColor3,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
				ZIndex = self.props.ZIndex,
			}, {
				UISizeConstraint = Roact.createElement("UISizeConstraint", {
					MaxSize = Vector2.new(math.huge, math.huge),
					MinSize = Vector2.new(),
				}),

				LeftHalfCircle = Roact.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundTransparency = 1,
					Image = "rbxassetid://633244888",
					ImageColor3 = self.props.BackgroundColor3,
					ImageRectSize = Vector2.new(128, 256),
					Position = UDim2.fromScale(0, 0.5),
					Size = UDim2.fromScale(0.5, 1),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					ZIndex = self.props.ZIndex,
				}),

				RightHalfCircle = Roact.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundTransparency = 1,
					Image = "rbxassetid://633244888",
					ImageColor3 = self.props.BackgroundColor3,
					ImageRectOffset = Vector2.new(128, 0),
					ImageRectSize = Vector2.new(128, 256),
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.fromScale(0.5, 1),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					ZIndex = self.props.ZIndex,
				}),
			}),
		}, self.props[Roact.Children])),

		PillShadow = self.props.CreateShadow and Roact.createElement("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "rbxassetid://1304004290",
			ImageTransparency = self.props.ShadowTransparency,
			ZIndex = self.props.ShadowZIndex,
			SizeConstraint = Enum.SizeConstraint.RelativeXY,
			AnchorPoint = Vector2.new(0.5, 0.5),
			ImageRectSize = Vector2.new(128, 128),
			ImageRectOffset = Vector2.new(64, 0),
			Position = UDim2.fromScale(0.5, 0.55),
			Size = UDim2.new(1 - diameter.Scale, -diameter.Offset, 2, 0),
		}, {
			UISizeConstraint = Roact.createElement("UISizeConstraint", {
				MaxSize = Vector2.new(math.huge, math.huge),
				MinSize = Vector2.new(),
			}),

			LeftShadow = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				Image = "rbxassetid://1304004290",
				ImageRectSize = Vector2.new(64, 128),
				ImageTransparency = self.props.ShadowTransparency,
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromScale(0.5, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ZIndex = self.props.ShadowZIndex,
			}),

			RightShadow = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Image = "rbxassetid://1304004290",
				ImageRectOffset = Vector2.new(192, 0),
				ImageRectSize = Vector2.new(64, 128),
				ImageTransparency = self.props.ShadowTransparency,
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromScale(0.5, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ZIndex = self.props.ShadowZIndex,
			}),
		}) or nil,
	})

	-- return Roact.createElement("Frame", {
	-- 	AnchorPoint = self.props.AnchorPoint,
	-- 	BackgroundTransparency = 1,
	-- 	LayoutOrder = self.props.LayoutOrder,
	-- 	Position = self.props.Position,
	-- 	Size = size,
	-- 	ZIndex = self.props.ZIndex,
	-- }, {
	-- 	PillContainer = Roact.createElement("Frame", {
	-- 		BackgroundTransparency = 1,
	-- 		Size = UDim2.fromScale(1, 1),
	-- 	}, {
	-- 		PillBacking = Roact.createElement("ImageLabel", {
	-- 			BackgroundTransparency = 1,
	-- 			Image = "rbxassetid://633244888",
	-- 			ImageColor3 = self.props.BackgroundColor3,
	-- 			ScaleType = Enum.ScaleType.Slice,
	-- 			Size = UDim2.fromScale(1, 1),
	-- 			SliceCenter = Rect.new(128, 128, 128, 128),
	-- 			SliceScale = 1024,
	-- 			ZIndex = self.props.ZIndex,
	-- 		}, self.props[Roact.Children]),
	-- 	}),

	-- 	PillShadow = self.props.CreateShadow and Roact.createElement("ImageLabel", {
	-- 		AnchorPoint = Vector2.new(0.5, 0.5),
	-- 		BackgroundTransparency = 1,
	-- 		Image = "rbxassetid://707852973",
	-- 		ImageTransparency = self.props.ShadowTransparency,
	-- 		Position = UDim2.fromScale(0.5, 0.55),
	-- 		ScaleType = Enum.ScaleType.Slice,
	-- 		Size = UDim2.new(1 + addedScale, diameter.Offset / 2, 2, 0),
	-- 		SliceCenter = Rect.new(64, 64, 64, 64),
	-- 		SliceScale = 1024,
	-- 		ZIndex = self.props.ShadowZIndex,
	-- 	}) or nil,
	-- })

	-- return Roact.createElement("ImageLabel", {
	-- 	AnchorPoint = self.props.AnchorPoint,
	-- 	BackgroundTransparency = 1,
	-- 	Image = "rbxassetid://633244888",
	-- 	ImageColor3 = self.props.BackgroundColor3,
	-- 	LayoutOrder = self.props.LayoutOrder,
	-- 	Position = self.props.Position,
	-- 	ScaleType = Enum.ScaleType.Slice,
	-- 	Size = size,
	-- 	SliceCenter = Rect.new(128, 128, 128, 128),
	-- 	SliceScale = 1024,
	-- 	ZIndex = self.props.ZIndex,
	-- }, {
	-- 	PillShadow = self.props.CreateShadow and Roact.createElement("ImageLabel", {
	-- 		AnchorPoint = Vector2.new(0.5, 0.5),
	-- 		BackgroundTransparency = 1,
	-- 		ImageTransparency = self.props.ShadowTransparency,
	-- 		Position = UDim2.fromScale(0.5, 0.55),
	-- 		Size = UDim2.new(1 + addedScale, diameter.Offset / 2, 2, 0),
	-- 		ZIndex = self.props.ShadowZIndex,
	-- 		ScaleType = Enum.ScaleType.Slice,
	-- 		SliceCenter = Rect.new(64, 64, 64, 64),
	-- 		SliceScale = 1024,
	-- 		Image = "rbxassetid://707852973",
	-- 	}) or nil,
	-- })
end

return Pill