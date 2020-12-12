local Spritesheets = script.Spritesheets
local SpritesheetHandler = {}

local Cache = setmetatable({}, {
	__index = function(self, Index)
		local Spritesheet = Spritesheets:FindFirstChild(Index)

		if Spritesheet then
			local Value = require(Spritesheet).new()
			self[Index] = Value
			return Value
		end
	end;
})

local function GetImageInstance(InstanceType, Index, Style)
	local Stylesheet = Cache[Style]
	return Stylesheet and Stylesheet:GetSprite(InstanceType, Index)
end

--[[**
	Gets an ImageLabel with the given sprite.
	@param [t:string] Index The index of the sprite. Also known as the sprite name.
	@param [t:string] Style The style of the sprite. Also known as the spritesheet name.
	@returns [t:instanceIsA<ImageLabel>] A new ImageLabel.
**--]]
function SpritesheetHandler.GetImageLabel(Index, Style): ImageLabel
	return GetImageInstance("ImageLabel", Index, Style)
end

--[[**
	Gets an ImageLabel with the given sprite that has the correct aspect ratio.
	@param [t:string] Index The index of the sprite. Also known as the sprite name.
	@param [t:string] Style The style of the sprite. Also known as the spritesheet name.
	@returns [t:instanceIsA<ImageLabel>] A new ImageLabel.
**--]]
function SpritesheetHandler.GetScaledImageLabel(Index: string, Style: string): ImageLabel
	local ImageLabel: ImageLabel = GetImageInstance("ImageLabel", Index, Style)
	if ImageLabel then
		local Size = ImageLabel.Size
		local Ratio do
			local YOffset = Size.Y.Offset
			local XOffset = Size.X.Offset
			if YOffset > XOffset then
				Ratio = YOffset / XOffset
			else
				Ratio = XOffset / YOffset
			end
		end

		local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
		UIAspectRatioConstraint.DominantAxis = Enum.DominantAxis.Height
		UIAspectRatioConstraint.AspectRatio = Ratio
		UIAspectRatioConstraint.Parent = ImageLabel

		ImageLabel.Size = UDim2.fromScale(1, 1)

		return ImageLabel
	end
end

function SpritesheetHandler.GetImageButton(Index, Style)
	return GetImageInstance("ImageButton", Index, Style)
end

return SpritesheetHandler