local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local Metatable = {}
local Resources = setmetatable({}, Metatable)
local Caches = {}

local LocalResourcesLocation

local COMMAND_BAR = {Name = "Command bar"}

local ipairs = ipairs
local next = next

local SERVER_SIDE = RunService:IsServer()
local UNINSTANTIABLE_INSTANCES = setmetatable({
	Folder = false, RemoteEvent = false, BindableEvent = false;
	RemoteFunction = false, BindableFunction = false, Library = true;
}, {
	__index = function(self, InstanceType)
		local Instantiable, GeneratedInstance = pcall(Instance.new, InstanceType)
		local Uninstantiable

		if Instantiable and GeneratedInstance then
			GeneratedInstance:Destroy()
			Uninstantiable = false
		else
			Uninstantiable = true
		end

		self[InstanceType] = Uninstantiable
		return Uninstantiable
	end;
})

if false then
	function Resources:GetRemoteEvent(_Name: string): RemoteEvent
	end

	function Resources:GetBindableEvent(_Name: string): BindableEvent
	end

	function Resources:GetRemoteFunction(_Name: string): RemoteFunction
	end

	function Resources:GetBindableFunction(_Name: string): BindableFunction
	end

	function Resources:GetRagdollConstraint(_Name: string): Constraint
	end
end

function Resources:GetLocalTable(TableName)
	TableName = self ~= Resources and self or TableName
	local Table = Caches[TableName]

	if not Table then
		Table = {}
		Caches[TableName] = Table
	end

	return Table
end

local function GetFirstChild(Folder, InstanceName, InstanceType)
	local Object = Folder:FindFirstChild(InstanceName)

	if not Object then
		if UNINSTANTIABLE_INSTANCES[InstanceType] then
			error("[Resources] " .. InstanceType .. " \"" .. InstanceName .. "\" is not installed within " .. Folder:GetFullName() .. ".", 2)
		end

		Object = Instance.new(InstanceType)
		Object.Name = InstanceName
		Object.Parent = Folder
	end

	return Object
end

function Metatable:__index(MethodName)
	if type(MethodName) ~= "string" then
		error("[Resources] Attempt to index Resources with invalid key: string expected, got " .. typeof(MethodName), 2)
	end

	if string.sub(MethodName, 1, 3) ~= "Get" then
		error("[Resources] Methods should begin with \"Get\"", 2)
	end

	local InstanceType = string.sub(MethodName, 4)

	local A, B = string.byte(InstanceType, -2, -1)
	local CacheName = B == 121 and A ~= 97 and A ~= 101 and A ~= 105 and A ~= 111 and A ~= 117 and string.sub(InstanceType, 1, -2) .. "ies" or InstanceType .. "s"
	local IsLocal = string.sub(InstanceType, 1, 5) == "Local"
	local Cache, Folder, FolderGetter

	if IsLocal then
		InstanceType = string.sub(InstanceType, 6)

		if InstanceType == "Folder" then
			function FolderGetter()
				return GetFirstChild(LocalResourcesLocation, "Resources", "Folder")
			end
		else
			FolderGetter = Resources.GetLocalFolder
		end
	else
		if InstanceType == "Folder" then
			function FolderGetter()
				return script
			end
		else
			FolderGetter = Resources.GetFolder
		end
	end

	local function GetFunction(this, InstanceName)
		InstanceName = this ~= self and this or InstanceName
		if type(InstanceName) ~= "string" then
			error("[Resources] " .. MethodName .. " expected a string parameter, got " .. typeof(InstanceName), 2)
		end

		if not Folder then
			Cache = Caches[CacheName]
			Folder = FolderGetter(IsLocal and string.sub(CacheName, 6) or CacheName)

			if not Cache then
				Cache = Folder:GetChildren()
				Caches[CacheName] = Cache

				for Index, Child in ipairs(Cache) do
					Cache[Child.Name] = Child
					Cache[Index] = nil
				end
			end
		end

		local Object = Cache[InstanceName]

		if not Object then
			if SERVER_SIDE or IsLocal then
				Object = GetFirstChild(Folder, InstanceName, InstanceType)
			else
				Object = Folder:WaitForChild(InstanceName, 5)

				if not Object then
					local Caller = nil
					if Caller and Caller.Parent and Caller.Parent.Parent == script then
						warn("[Resources] Make sure a Script in ServerScriptService calls `Resources:LoadLibrary(\"" .. Caller.Name .. "\")`")
					else
						if InstanceType == "Library" then
							warn("[Resources] Did you forget to install", InstanceName .. "?")
						elseif InstanceType == "Folder" then
							warn("[Resources] Make sure a Script in ServerScriptService calls `require(ReplicatedStorage.Resources)`")
						end
					end

					Object = Folder:WaitForChild(InstanceName)
				end
			end

			Cache[InstanceName] = Object
		end

		return Object
	end

	Resources[MethodName] = GetFunction
	return GetFunction
end

if SERVER_SIDE and RunService:IsClient() or (not RunService:IsRunning()) then
	if RunService:IsRunning() then
		warn("Warning: Loading all modules in PlaySolo. It's recommended you use accurate play solo.")
	end

	LocalResourcesLocation = ServerStorage
	local LibraryRepository = LocalResourcesLocation:FindFirstChild("Repository")

	local function CacheLibrary(Storage, Library, StorageName)
		if Storage[Library.Name] then
			error(
				"[Resources] Duplicate " .. StorageName .. " Found:\n\t"
				.. Storage[Library.Name]:GetFullName() .. " and \n\t"
				.. Library:GetFullName()
				.. "\nOvershadowing is only permitted when a server-only library overshadows a replicated library"
			, 0)
		else
			Storage[Library.Name] = Library
		end
	end

	if LibraryRepository then
		local ServerLibraries = {}
		local ReplicatedLibraries = Resources:GetLocalTable("Libraries")
		local FoldersToHandle = {}
		local FolderChildren, ExclusivelyServer = LibraryRepository:GetChildren(), false

		while FolderChildren do
			FoldersToHandle[FolderChildren] = nil

			for _, Child in ipairs(FolderChildren) do
				local ClassName = Child.ClassName
				local ServerOnly = ExclusivelyServer or (string.find(Child.Name, "Server", 1, true) and true or false)

				if ClassName == "ModuleScript" then
					if ServerOnly then
						CacheLibrary(ServerLibraries, Child, "ServerLibraries")
					else
						CacheLibrary(ReplicatedLibraries, Child, "ReplicatedLibraries")
					end
				elseif ClassName == "Folder" then
					FoldersToHandle[Child:GetChildren()] = ServerOnly
				else
					error("[Resources] Instances within your Repository must be either a ModuleScript or a Folder, found: " .. ClassName .. " " .. Child:GetFullName(), 0)
				end
			end

			FolderChildren, ExclusivelyServer = next(FoldersToHandle)
		end

		for Name, Library in next, ServerLibraries do
			ReplicatedLibraries[Name] = Library
		end
	end
else
	if not SERVER_SIDE then
		local LocalPlayer
		repeat
			LocalPlayer = Players.LocalPlayer
		until LocalPlayer or not wait()

		repeat
			LocalResourcesLocation = LocalPlayer:FindFirstChildOfClass("PlayerScripts")
		until LocalResourcesLocation or not wait()
	else
		LocalResourcesLocation = ServerStorage
		local LibraryRepository = LocalResourcesLocation:FindFirstChild("Repository")

		local function CacheLibrary(Storage, Library, StorageName)
			if Storage[Library.Name] then
				error(
					"[Resources] Duplicate " .. StorageName .. " Found:\n\t"
					.. Storage[Library.Name]:GetFullName() .. " and \n\t"
					.. Library:GetFullName()
					.. "\nOvershadowing is only permitted when a server-only library overshadows a replicated library"
				, 0)
			else
				Storage[Library.Name] = Library
			end
		end

		if LibraryRepository then
			local ServerLibraries = {}
			local ReplicatedLibraries = Resources:GetLocalTable("Libraries")
			local FoldersToHandle = {}
			local FolderChildren, ExclusivelyServer = LibraryRepository:GetChildren(), false

			while FolderChildren do
				FoldersToHandle[FolderChildren] = nil

				for _, Child in ipairs(FolderChildren) do
					local ClassName = Child.ClassName
					local ServerOnly = ExclusivelyServer or (string.find(Child.Name, "Server", 1, true) and true or false)

					if ClassName == "ModuleScript" then
						if ServerOnly then
							Child.Parent = Resources:GetLocalFolder("Libraries")
							CacheLibrary(ServerLibraries, Child, "ServerLibraries")
						else
							local TemplateObject

							for _, Descendant in ipairs(Child:GetDescendants()) do
								if string.find(Descendant.Name, "Server", 1, true) then
									if not TemplateObject then
										TemplateObject = Child:Clone()
									end

									Descendant:Destroy()
								end
							end

							if TemplateObject then
								TemplateObject.Parent = Resources:GetLocalFolder("Libraries")
								CacheLibrary(ServerLibraries, TemplateObject, "ServerLibraries")
							end

							Child.Parent = Resources:GetFolder("Libraries")
							CacheLibrary(ReplicatedLibraries, Child, "ReplicatedLibraries")
						end
					elseif ClassName == "Folder" then
						FoldersToHandle[Child:GetChildren()] = ServerOnly
					else
						error("[Resources] Instances within your Repository must be either a ModuleScript or a Folder, found: " .. ClassName .. " " .. Child:GetFullName(), 0)
					end
				end

				FolderChildren, ExclusivelyServer = next(FoldersToHandle)
			end

			for Name, Library in next, ServerLibraries do
				ReplicatedLibraries[Name] = Library
			end

			LibraryRepository:Destroy()
		end
	end
end

local LoadedLibraries = Resources:GetLocalTable("LoadedLibraries")
local CurrentlyLoading = {}

function Resources:LoadLibrary(LibraryName)
	LibraryName = self ~= Resources and self or LibraryName
	local Data = LoadedLibraries[LibraryName]

	if Data == nil then
		local Caller = COMMAND_BAR
		local Library = Resources:GetLibrary(LibraryName)

		CurrentlyLoading[Caller] = Library

		local Current = Library
		local Count = 0

		while Current do
			Count += 1
			Current = CurrentlyLoading[Current]

			if Current == Library then
				local String = Current.Name

				for _ = 1, Count do
					Current = CurrentlyLoading[Current]
					String ..= " -> " .. Current.Name
				end

				error("[Resources] Circular dependency chain detected: " .. String)
			end
		end

		Data = require(Library)
		if CurrentlyLoading[Caller] == Library then
			CurrentlyLoading[Caller] = nil
		end

		if Data == nil then
			error("[Resources] " .. LibraryName .. " must return a non-nil value. Return false instead.")
		end

		LoadedLibraries[LibraryName] = Data
	end

	return Data
end

Metatable.__call = Resources.LoadLibrary
return Resources