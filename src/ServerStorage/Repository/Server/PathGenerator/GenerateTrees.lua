local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadShared("Constants").SKI_PATH

local TERRAIN_WIDTH = Constants.TERRAIN_WIDTH
local NUM_TREES = Constants.NUM_TREES

local TreeSmall = ServerStorage.Props.TreeSmall
local TreeBig = ServerStorage.Props.TreeBig

return function(spline, parent)
    local container = Instance.new("Model")
    container.Name = "Trees"
    container.Parent = parent

    local random = Random.new()
    for i = 1, NUM_TREES do
        local alpha = (i / NUM_TREES) + random:NextNumber(-1e-3, 1e-3)
        alpha = math.clamp(alpha, 0, 1)
        local offsetDirection = random:NextNumber() > 0.5 and 1 or -1
        local rightOffset = offsetDirection * (TERRAIN_WIDTH / 2 + random:NextNumber(0, 20))
        local scale = random:NextNumber(0.8, 2)
        local cframe = spline:GetRotCFrame(alpha)
        local tree = random:NextNumber() > 0.5 and TreeSmall:Clone() or TreeBig:Clone()
        tree.Size *= scale
        tree.CFrame = CFrame.new(cframe.Position)
            + cframe.UpVector * (tree.Size.Y / 2 - 2)
            + cframe.RightVector * rightOffset
        tree.Parent = container
    end
end