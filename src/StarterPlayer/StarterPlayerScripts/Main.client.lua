local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local ClientHandler = Resources:LoadLibrary("ClientHandler"):Initialize()

if not ClientHandler.CanMount.Value then
	ClientHandler.CanMount.Changed:Wait()
end

print("Ready!")
ClientHandler:Mount()

ClientHandler.LocalPlayer.CharacterAdded:Connect(function()
	print("CharacterAdded")
end)