-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
-- local Resources = require(ReplicatedStorage.Resources)

local Tent = ServerStorage.Props.Tent

return function(spline, parent)
    local tent = Tent:Clone()
    local cframe = spline:GetCFrame(0)
    tent.CFrame = cframe * tent.Attachment.CFrame:Inverse()
    tent.Parent = parent
end