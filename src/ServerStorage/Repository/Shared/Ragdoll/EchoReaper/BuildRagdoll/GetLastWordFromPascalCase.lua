local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Typer = Resources:LoadLibrary("Typer")

local GetLastWordFromPascalCase = Typer.AssignSignature(Typer.String, function(String: string): string
	return (string.gsub(string.sub(String, #String - ((string.find(string.reverse(String), "%u") or #String + 1) - 1)), "%d+$", ""))
end)

return GetLastWordFromPascalCase