local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")
local ScriptContext = game:GetService("ScriptContext")

local Resources = require(ReplicatedStorage.Resources)

Resources:LoadLibrary("ParticleEngine"):Initialize()
Resources:LoadLibrary("TimeSyncService"):Initialize()
Resources:LoadLibrary("PlayerDataHandler"):Initialize()

-- print(string.format("\n\t%s\n", Resources:LoadLibrary("BigNum").new("0"):ToString64()))

LogService.MessageOut:Connect(function(Message, MessageType)
	local Traceback
	if MessageType == Enum.MessageType.MessageError then
		local Array = {}
		local Length = 0
		repeat
			local Message2, MessageType2 = LogService.MessageOut:Wait()
			if MessageType2 == Enum.MessageType.MessageInfo then
				Length += 1
				Array[Length] = Message2
			end
		until Message2 == "Stack End" and MessageType2 == Enum.MessageType.MessageInfo
		Traceback = table.concat(Array, "\n")
	end

	print(string.format("\nMessageOut:\nMessage: %s\nTraceback: %s\nMessageType: %s\n", Message, Traceback or debug.traceback(), tostring(MessageType)))
end)

ScriptContext.Error:Connect(function(Message, StackTrace, Script)
	print(string.format("\nError:\nMessage: %s\nStackTrace: %s\nScript: %s\n", Message, StackTrace, tostring(Script)))
end)

do
	warn("HELLO!")
	print("HI!")
	error("BYE!")
end

--[[
local BigNum = Resources:LoadLibrary("BigNum")
local BitBuffer = Resources:LoadLibrary("BitBuffer")

local DAYS_IN_YEAR = BigNum.new("365")
local ONE_FRACTION = BigNum.NewFraction("1", "1")

local function BirthdayProblem(NumberOfPeople: number)
	local Chance = BigNum.NewFraction(DAYS_IN_YEAR, DAYS_IN_YEAR)
	for Index = 2, NumberOfPeople do
		Chance *= BigNum.NewFraction(DAYS_IN_YEAR + (1 - Index), DAYS_IN_YEAR)
	end

	return ONE_FRACTION - Chance
end

local Result = BirthdayProblem(70)
print(TypeOf(Result))

print(Result:ToScientificNotation(6))
]]