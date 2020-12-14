local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Table = Resources:LoadLibrary("Table")

return Table.Lock({
	REMOTE_EVENT_NAME = "RagdollHumanoidOnFallRemoteEvent";
}, nil, script.Name)