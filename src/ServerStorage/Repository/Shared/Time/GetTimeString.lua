local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Fmt = Resources:LoadLibrary("Fmt")
local Typer = Resources:LoadLibrary("Typer")

-- bad code
local GetTimeString = Typer.AssignSignature(Typer.Number, function(Milliseconds)
	local Hours = math.floor(Milliseconds / 3600)
	local Minutes = math.floor((Milliseconds - Hours * 3600) / 60)
	local Seconds = math.floor(Milliseconds - Hours * 3600 - Minutes * 60)

	return Fmt("{:02}:{:02}:{:02}", Minutes, Seconds, math.round((Milliseconds + (Milliseconds % 1 - Milliseconds)) * 100))
end)

return GetTimeString