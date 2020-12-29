local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
Resources:LoadLibrary("ClientHandler")
local ParticleEngine = Resources:LoadLibrary("ParticleEngine"):Initialize(Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainGui"))

local CatchFactory = Resources:LoadLibrary("CatchFactory")
local ParticleEngineHelper = Resources:LoadLibrary("ParticleEngineHelper")
local Promise = Resources:LoadLibrary("Promise")
local PromiseChild = Resources:LoadLibrary("PromiseChild")

local function Debounce(Function)
	local IsRunning = false
	return function(...)
		if not IsRunning then
			IsRunning = true
			local Arguments = table.pack(Function(...))
			IsRunning = false
			return table.unpack(Arguments, 1, Arguments.n)
		end
	end
end

local Array = table.create(2)
Array[1], Array[2] = PromiseChild(Players.LocalPlayer.PlayerGui.MainGui, "MaxParticles", 5), PromiseChild(Workspace, "ReflectPart", 5)

Promise.All(Array):Spread(function(MaxParticles: TextBox, ReflectPart: Part)
	MaxParticles.FocusLost:Connect(function(EnterPressed)
		if EnterPressed then
			local NewAmount = tonumber(string.match(MaxParticles.Text, "%d+"))
			if NewAmount then
				ParticleEngine.MaxParticles.Value = NewAmount
			end
		end
	end)

	ReflectPart.Touched:Connect(Debounce(function(Hit)
		if Hit:IsDescendantOf(Players.LocalPlayer.Character) then
			local Position = Hit.Position
			local BackVector = -Hit.CFrame.LookVector

			for _ = 1, ParticleEngine.MaxParticles.Value do
				ParticleEngineHelper.ReflectableSnowParticle(Position, BackVector)
			end
		end

		return Promise.Delay(2):Wait()
	end))
end):Catch(CatchFactory("Promise.All"))