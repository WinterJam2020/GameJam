local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local Debug = Resources:LoadLibrary("Debug")
local PseudoInstance = Resources:LoadLibrary("PseudoInstance")
local Scheduler = Resources:LoadLibrary("Scheduler")
local SortedArray = Resources:LoadLibrary("SortedArray")

Resources:LoadLibrary("Enumerations")

local Templates = Resources:GetLocalTable("Templates")

local RemoteEvent = Resources:GetRemoteEvent("PseudoInstanceReplicator")
local RemoteFunction = Resources:GetRemoteFunction("PseudoInstanceStartupVerify")

local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()

local AutoReplicatedInstances = {}
local LoadedPlayers = setmetatable({}, {__mode = "k"})

local FireClient

local function YieldUntilReadyToFire(Player, ...)
	repeat until LoadedPlayers[Player] or not Scheduler.Wait2(0.03)
	FireClient(Player, ...)
end

function FireClient(Player, ...)
	local Old = LoadedPlayers[Player]

	if Old then
		LoadedPlayers[Player] = Old + 1
		RemoteEvent:FireClient(Player, Old + 1, ...)
	else
		local Thread = coroutine.create(YieldUntilReadyToFire)
		local Success, Error = coroutine.resume(Thread, Player, ...)
		if not Success then
			warn(debug.traceback(Thread, Error))
		end
	end
end

local function FireAllClientsExcept(Player1, ...)
	for _, Player2 in ipairs(Players:GetPlayers()) do
		if Player1 ~= Player2 then
			FireClient(Player2, ...)
		end
	end
end

local SubscribingIndividuals = {} -- For when only ONE player receives updates
local ParentalDepths = {}

-- A SortedArray of Ids to objects sorted according to Parental depth
-- This will ensure that you don't replicate child instances and try to set their parents before the parents exist
local ReplicationOrder = SortedArray.new(nil, function(A, B)
	local DepthA = ParentalDepths[A]
	local DepthB = ParentalDepths[B]

	if DepthA == DepthB then
		return A < B
	else
		return DepthA < DepthB
	end
end)

local function ReplicateUpdateToInterestedParties(self, Id, Index, Value)
	if AutoReplicatedInstances[Id] then
		FireAllClientsExcept(nil, self.__Class.ClassName, Id, Index, Value)
	else
		local PlayerToReplicateTo = SubscribingIndividuals[Id]

		if PlayerToReplicateTo then
			FireClient(PlayerToReplicateTo, self.__Class.ClassName, Id, Index, Value)
		end
	end
end

local function OnPropertyChanged(self, Index)
	local Value = self[Index]
	local Id = self.__Id

	if Index == "Parent" then
		local PlayerToReplicateTo

		if Value then
			local ReplicateToAllPlayers = Value == Players or Value == Workspace or Value == ReplicatedStorage or Value:IsDescendantOf(Workspace) or Value:IsDescendantOf(ReplicatedStorage)

			if not ReplicateToAllPlayers and Value:IsDescendantOf(Players) then
				PlayerToReplicateTo = Value
				while not PlayerToReplicateTo:IsA("Player") do
					PlayerToReplicateTo = PlayerToReplicateTo.Parent
				end
			end

			-- If replicating to the server, we want to cache these and replicate them upon player joining (conditional upon parent)
			if ReplicateToAllPlayers then
				-- Get parental depth and cache it
				local ParentalDepth = 0
				local Current = self

				repeat
					Current = Current.Parent
					ParentalDepth += 1
				until Current == nil

				local Position = ReplicationOrder:Find(Id)
				ParentalDepths[Id] = ParentalDepth
				AutoReplicatedInstances[Id] = self

				if Position then
					ReplicationOrder:SortIndex(Position)
				else
					ReplicationOrder:Insert(Id)
				end

				FireAllClientsExcept(SubscribingIndividuals[Id], self.__Class.ClassName, Id, self.__RawData)
				SubscribingIndividuals[Id] = nil

				return
			elseif PlayerToReplicateTo then
				SubscribingIndividuals[Id] = PlayerToReplicateTo
				FireClient(PlayerToReplicateTo, self.__Class.ClassName, Id, self.__RawData)
			end
		end

		if not PlayerToReplicateTo then
			local PreviousSubscriber = SubscribingIndividuals[Id]

			if PreviousSubscriber then
				FireClient(PreviousSubscriber, self.__Class.ClassName, Id)
				SubscribingIndividuals[Id] = nil
			end
		end

		if AutoReplicatedInstances[Id] then
			FireAllClientsExcept(PlayerToReplicateTo, self.__Class.ClassName, Id)
			AutoReplicatedInstances[Id] = nil
			ReplicationOrder:RemoveElement(Id)
		end
	else
		ReplicateUpdateToInterestedParties(self, Id, Index, Value)
	end
end

if IsServer then
	Players.PlayerAdded:Connect(function(Player)
		local Success, Value = pcall(RemoteFunction.InvokeClient, RemoteFunction, Player)
		if Success and Value then
			local NumReplicationOrder = #ReplicationOrder

			for Index, Id in ipairs(ReplicationOrder) do
				local self = AutoReplicatedInstances[Id]
				RemoteEvent:FireClient(Player, Index, self.__Class.ClassName, Id, self.__RawData)
			end

			LoadedPlayers[Player] = NumReplicationOrder
		end
	end)

	RemoteEvent.OnServerEvent:Connect(function(Player, ClassName, Id, Event, ...) -- Fire events on the Server after they are fired on the client
		Event = (Templates[ClassName].Storage[Id] or Debug.Error("Object not found"))[Event]
		-- On the server, the first parameter will always be Player. This removes a duplicate.
		-- This also adds some security because a client cannot simply spoof it

		Event:Fire(Player, select(2, ...))
	end)
elseif IsClient then
	local OnClientEventNumber = 1 -- Guarenteed that this will resolve in the order in which replication is intended to occur

	RemoteEvent.OnClientEvent:Connect(function(EventNumber, ClassName, Id, RawData, Assigned) -- Handle objects being replicated to clients
		repeat until OnClientEventNumber == EventNumber or not Scheduler.Wait2(0.03)

		local Template = Templates[ClassName]

		if not Template then
			Resources:LoadLibrary(ClassName)
			Template = Templates[ClassName] or Debug.Error("Invalid ClassName")
		end

		local Object = Template.Storage[Id]

		if not Object then
			Object = PseudoInstance.new(ClassName, Id)
			Template.Storage[Id] = Object
		end

		local RawDataType = type(RawData)

		if RawDataType == "table" then
			for Property, Value in next, RawData do
				if Object[Property] ~= Value then
					Object[Property] = Value
				end
			end
		elseif RawDataType == "nil" then
			Object:Destroy()
		elseif RawDataType == "string" then
			Object[RawData] = Assigned
		else
			Debug.Error("Invalid RawData type, expected table, nil, or string, got %s", RawDataType)
		end

		OnClientEventNumber += 1
	end)

	function RemoteFunction.OnClientInvoke()
		return true
	end
end

local Ids = 0 -- Globally shared Id for instances, would break beyond 2^53 instances ever

return PseudoInstance:Register("ReplicatedPseudoInstance", {
	Storage = false; -- Mark this Class as abstract
	Internals = table.create(1, "__Id");
	Properties = {};
	Events = {};

	Methods = {
		Destroy = function(self)
			local Id = self.__Id

			if Id then
				self.__Class.Storage[Id] = nil
				ReplicationOrder:RemoveElement(Id)

				if IsServer then -- Replicate Destroy
					ReplicateUpdateToInterestedParties(self, Id)
				end

				SubscribingIndividuals[Id] = nil
				AutoReplicatedInstances[Id] = nil
			end

			self:Super("Destroy")
		end;
	};

	Init = function(self, Id)
		self:SuperInit()

		if IsServer then
			if not Id then
				Id = Ids + 1
				Ids = Id
			end

			self.Changed:Connect(OnPropertyChanged, self)
		elseif IsClient then
			if Id then
				for Event in next, self.__Class.Events do
					if Event ~= "Changed" then
						self[Event]:Connect(function(...)
							RemoteEvent:FireServer(self.__Class.ClassName, Id, Event, ...)
						end)
					end
				end
			end
		end

		if Id then
			(self.__Class.Storage or Debug.Error(self.__Class.ClassName .. " is an abstract class and cannot be instantiated"))[Id] = self
			self.__Id = Id
		end
	end;
})