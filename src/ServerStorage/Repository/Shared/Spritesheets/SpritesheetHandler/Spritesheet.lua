local Spritesheet = {ClassName = "Spritesheet"}
Spritesheet.__index = Spritesheet

function Spritesheet.new(Texture)
	return setmetatable({
		Texture = Texture;
		Sprites = {};
	}, Spritesheet)
end

function Spritesheet:AddSprite(Index, Position, Size)
	self.Sprites[Index] = {Position = Position, Size = Size}
end

function Spritesheet:GetSprite(InstanceType, Index)
	local Sprite = self.Sprites[Index]
	if not Sprite then
		return warn("Couldn't find a sprite with index", Index)
	end

	local Element = Instance.new(InstanceType)
	Element.BackgroundTransparency = 1
	Element.Image = self.Texture
	Element.Size = UDim2.fromOffset(Sprite.Size.X, Sprite.Size.Y)
	Element.ImageRectOffset = Sprite.Position
	Element.ImageRectSize = Sprite.Size
	return Element
end

return Spritesheet