local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local BaseObject = Resources:LoadLibrary("BaseObject")
local Debug = Resources:LoadLibrary("Debug")
local Janitor = Resources:LoadLibrary("Janitor")

local Debug_Assert = Debug.Assert

local AnimatedSpritesheetPlayer = setmetatable({ClassName = "AnimatedSpritesheetPlayer"}, BaseObject)
AnimatedSpritesheetPlayer.__index = AnimatedSpritesheetPlayer

function AnimatedSpritesheetPlayer.new(ImageLabel: ImageLabel, AnimatedSpritesheet)
	local self = setmetatable(BaseObject.new(AnimatedSpritesheet), AnimatedSpritesheetPlayer)
	self.ImageLabel = ImageLabel
	if AnimatedSpritesheet then
		self:SetSheet(AnimatedSpritesheet)
	end

	return self
end

local function Play(self)
	local PlayJanitor = self.Janitor:Add(Janitor.new(), "Destroy", "PlayJanitor")
	local Fps = self.AnimatedSpritesheet:GetFramesPerSecond()
	local Frames = self.AnimatedSpritesheet:GetFrames()

	PlayJanitor:Add(RunService.RenderStepped:Connect(function()
		local Frame = math.floor(time() * Fps) % Frames + 1
		self.AnimatedSpritesheet:GetSprite(Frame):Style(self.ImageLabel)
	end), "Disconnect")
end

function AnimatedSpritesheetPlayer:SetSheet(AnimatedSpritesheet)
	Debug_Assert(AnimatedSpritesheet, "AnimatedSpritesheet was not provided!")
	self.AnimatedSpritesheet = AnimatedSpritesheet
	Play(self)
end

return AnimatedSpritesheetPlayer