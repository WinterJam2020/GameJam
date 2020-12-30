local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local ServerHandler = Resources:LoadLibrary("ServerHandler"):Initialize():StartGameLoop()