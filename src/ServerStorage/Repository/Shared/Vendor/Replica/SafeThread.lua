local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local FastSignal = Resources:LoadLibrary("FastSignal")

local YieldPayload = {}
local ResumeSignal = FastSignal.new()

local SafeThread = {Running = coroutine.running}

function SafeThread.Resume(Thread, ...)
    ResumeSignal:Fire(Thread, table.pack(...))

    local Returns = YieldPayload[Thread]
    YieldPayload[Thread] = nil

    if Returns ~= nil then
        return table.unpack(Returns, 1, Returns.n)
    end
end

function SafeThread.Yield(...)
    local Thread = coroutine.running()
    YieldPayload[Thread] = table.pack(...)

    while true do
        local ResumedThread, Returns = ResumeSignal:Wait()
        if ResumedThread == Thread then
            return table.unpack(Returns, 1, Returns.n)
        end
    end
end

return SafeThread