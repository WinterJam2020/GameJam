-- local Madwork = _G.Madwork
--[[
{Madwork}

-[ProfileService]---------------------------------------
	(STANDALONE VERSION)
	DataStore profiles - universal session-locked savable table API

	Official documentation:
		https://madstudioroblox.github.io/ProfileService/

	DevForum discussion:
		https://devforum.roblox.com/t/ProfileService/667805

	WARNINGS FOR "Profile.Data" VALUES:
	 	! Do not create numeric tables with gaps - attempting to replicate such tables will result in an error;
		! Do not create mixed tables (some values indexed by number and others by string key), as only
		     the data indexed by number will be replicated.
		! Do not index tables by anything other than numbers and strings.
		! Do not reference Roblox Instances
		! Do not reference userdata (Vector3, Color3, CFrame...) - Serialize userdata before referencing
		! Do not reference functions

	WARNING: Calling ProfileStore:LoadProfileAsync() with a "profile_key" which wasn't released in the SAME SESSION will result
		in an error! If you want to "ProfileStore:LoadProfileAsync()" instead of using the already loaded profile, :Release()
		the old Profile object.

	Members:

		ProfileService.ServiceLocked         [bool]

		ProfileService.IssueSignal           [ScriptSignal](error_message)
		ProfileService.CorruptionSignal      [ScriptSignal](profile_store_name, profile_key)
		ProfileService.CriticalStateSignal   [ScriptSignal](is_critical_state)

	Functions:

		ProfileService.GetProfileStore(profile_store_name, profile_template) --> [ProfileStore]
			-- WARNING: Only one ProfileStore can exist for a given profile_store_name in a game session!

		* Parameter description for "ProfileService.GetProfileStore()":

			profile_store_name   [string] -- DataStore name
			profile_template     []:
				{}                        [table] -- Profiles will default to given table (hard-copy) when no data was saved previously

	Members [ProfileStore]:

		ProfileStore.Mock   [ProfileStore] -- Reflection of ProfileStore methods, but the methods will use a mock DataStore

	Methods [ProfileStore]:

		ProfileStore:LoadProfileAsync(profile_key, not_released_handler) --> [Profile / nil] not_released_handler(place_id, game_job_id)
		ProfileStore:GlobalUpdateProfileAsync(profile_key, update_handler) --> [GlobalUpdates / nil] (update_handler(GlobalUpdates))
			-- Returns GlobalUpdates object if update was successful, otherwise returns nil

		ProfileStore:ViewProfileAsync(profile_key) --> [Profile / nil] -- Notice #1: Profile object methods will not be available;
			Notice #2: Profile object members will be nil (Profile.Data = nil, Profile.Metadata = nil) if the profile hasn't
			been created, with the exception of Profile.GlobalUpdates which could be empty or populated by
			ProfileStore:GlobalUpdateProfileAsync()

		ProfileStore:WipeProfileAsync(profile_key) --> is_wipe_successful [bool] -- Completely wipes out profile data from the
			DataStore / mock DataStore with no way to recover it.

		* Parameter description for "ProfileStore:LoadProfileAsync()":

			profile_key            [string] -- DataStore key
			not_released_handler = "ForceLoad" -- Force loads profile on first call
			OR
			not_released_handler = "Steal" -- Steals the profile ignoring it's session lock
			OR
			not_released_handler   [function] (place_id, game_job_id) --> [string] ("Repeat" / "Cancel" / "ForceLoad")
				-- "not_released_handler" will be triggered in cases where the profile is not released by a session. This
				function may yield for as long as desirable and must return one of three string values:
					["Repeat"] - ProfileService will repeat the profile loading proccess and may trigger the release handler again
					["Cancel"] - ProfileStore:LoadProfileAsync() will immediately return nil
					["ForceLoad"] - ProfileService will repeat the profile loading call, but will return Profile object afterwards
						and release the profile for another session that has loaded the profile
					["Steal"] - The profile will usually be loaded immediately, ignoring an existing remote session lock and applying
						a session lock for this session.

		* Parameter description for "ProfileStore:GlobalUpdateProfileAsync()":

			profile_key      [string] -- DataStore key
			update_handler   [function] (GlobalUpdates) -- This function gains access to GlobalUpdates object methods
				(update_handler can't yield)

	Members [Profile]:

		Profile.Data            [table] -- Writable table that gets saved automatically and once the profile is released
		Profile.Metadata        [table] (Read-only) -- Information about this profile

			Profile.Metadata.ProfileCreateTime   [number] (Read-only) -- os.time() timestamp of profile creation
			Profile.Metadata.SessionLoadCount    [number] (Read-only) -- Amount of times the profile was loaded
			Profile.Metadata.ActiveSession       [table] (Read-only) {place_id, game_job_id} / nil -- Set to a session link if a
				game session is currently having this profile loaded; nil if released
			Profile.Metadata.Metatags            [table] {["tag_name"] = tag_value, ...} -- Saved and auto-saved just like Profile.Data
			Profile.Metadata.MetatagsLatest      [table] (Read-only) -- Latest version of Metadata.Metatags that was definetly saved to DataStore
				(You can use Profile.Metadata.MetatagsLatest for product purchase save confirmation, but create a system to clear old tags after
				they pile up)

		Profile.GlobalUpdates   [GlobalUpdates]

	Methods [Profile]:

		-- SAFE METHODS - Will not error after profile expires:
		Profile:IsActive() --> [bool] -- Returns true while the profile is active and can be written to

		Profile:GetMetaTag(tag_name) --> value

		Profile:Reconcile() -- Fills in missing (nil) [string_key] = [value] pairs to the Profile.Data structure

		Profile:ListenToRelease(listener) --> [ScriptConnection] (place_id / nil, game_job_id / nil) -- WARNING: Profiles can be released externally if another session
			force-loads this profile - use :ListenToRelease() to handle player leaving cleanup.

		Profile:Release() -- Call after the session has finished working with this profile
			e.g., after the player leaves (Profile object will become expired) (Does not yield)

		-- DANGEROUS METHODS - Will error if the profile is expired:
		-- Metatags - Save and read values stored in Profile.Metadata for storing info about the
			profile itself like "Profile:SetMetaTag("FirstTimeLoad", true)"
		Profile:SetMetaTag(tag_name, value)

		Profile:Save() -- Call to quickly progress global update state or to speed up save validation processes (Does not yield)


	Methods [GlobalUpdates]:

	-- ALWAYS PUBLIC:
		GlobalUpdates:GetActiveUpdates() --> [table] {{update_id, update_data}, ...}
		GlobalUpdates:GetLockedUpdates() --> [table] {{update_id, update_data}, ...}

	-- ONLY WHEN FROM "Profile.GlobalUpdates":
		GlobalUpdates:ListenToNewActiveUpdate(listener) --> [ScriptConnection] listener(update_id, update_data)
		GlobalUpdates:ListenToNewLockedUpdate(listener) --> [ScriptConnection] listener(update_id, update_data)
		-- WARNING: GlobalUpdates:LockUpdate() and GlobalUpdates:ClearLockedUpdate() will error after profile expires
		GlobalUpdates:LockActiveUpdate(update_id)
		GlobalUpdates:ClearLockedUpdate(update_id)

	-- EXPOSED TO "update_handler" DURING ProfileStore:GlobalUpdateProfileAsync() CALL
		GlobalUpdates:AddActiveUpdate(update_data)
		GlobalUpdates:ChangeActiveUpdate(update_id, update_data)
		GlobalUpdates:ClearActiveUpdate(update_id)

--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local DataStoreService = Resources:LoadLibrary("DataStoreService")
local Enumeration = Resources:LoadLibrary("Enumerations")
local Janitor = Resources:LoadLibrary("Janitor")
local Promise = Resources:LoadLibrary("Promise")
local Scheduler = Resources:LoadLibrary("Scheduler")
local Table = Resources:LoadLibrary("Table")

local SETTINGS = {
	AutoSaveProfiles = 30; -- Seconds (This value may vary - ProfileService will split the auto save load evenly in the given time)
	LoadProfileRepeatDelay = 15; -- Seconds between successive DataStore calls for the same key
	ForceLoadMaxSteps = 4; -- Steps taken before ForceLoad request steals the active session for a profile
	AssumeDeadSessionLock = 30 * 60; -- (seconds) If a profile hasn't been updated for 30 minutes, assume the session lock is dead
	-- As of writing, os.time() is not completely reliable, so we can only assume session locks are dead after a significant amount of time.

	IssueCountForCriticalState = 5; -- Issues to collect to announce critical state
	IssueLast = 120; -- Seconds
	CriticalStateLast = 120; -- Seconds
}

local Madwork -- Standalone Madwork reference for portable version of ProfileService
do
	-- ScriptConnection object:
	local ScriptConnection = {}

	function ScriptConnection:Disconnect()
		local listener = self._listener
		if listener ~= nil then
			local listener_table = self._listener_table
			for i, v in ipairs(listener_table) do
				if listener == v then
					Table.FastRemove(listener_table, i)
					break
				end
			end

			self._listener = nil
		end
	end

	function ScriptConnection.NewScriptConnection(listener_table, listener) --> [ScriptConnection]
		return {
			_listener = listener;
			_listener_table = listener_table;
			Disconnect = ScriptConnection.Disconnect;
		}
	end

	-- ScriptSignal object:
	local ScriptSignal = {}

	function ScriptSignal:Connect(listener) --> [ScriptConnection]
		if type(listener) ~= "function" then
			error("[ScriptSignal]: Only functions can be passed to ScriptSignal:Connect()")
		end

		table.insert(self._listeners, listener)
		return {
			_listener = listener;
			_listener_table = self._listeners;
			Disconnect = ScriptConnection.Disconnect;
		}
	end

	function ScriptSignal:Fire(...)
		for _, listener in ipairs(self._listeners) do
			listener(...)
		end
	end

	function ScriptSignal.NewScriptSignal() --> [ScriptSignal]
		return {
			_listeners = {};
			Connect = ScriptSignal.Connect;
			Fire = ScriptSignal.Fire;
		}
	end

	local Heartbeat = RunService.Heartbeat

	Madwork = {
		NewScriptSignal = ScriptSignal.NewScriptSignal;
		NewScriptConnection = ScriptConnection.NewScriptConnection;
		HeartbeatWait = function(wait_time) --> time_elapsed
			if wait_time == nil or wait_time == 0 then
				return Heartbeat:Wait()
			else
				local time_elapsed = 0
				while time_elapsed <= wait_time do
					time_elapsed += Heartbeat:Wait()
				end

				return time_elapsed
			end
		end;

		ConnectToOnClose = function(task, run_in_studio_mode)
			if not RunService:IsStudio() or run_in_studio_mode then
				game:BindToClose(task)
			end
		end;
	}
end

----- Service Table -----

local ProfileService = {

	ServiceLocked = false, -- Set to true once the server is shutting down

	IssueSignal = Madwork.NewScriptSignal(), -- (error_message) -- Fired when a DataStore API call throws an error
	CorruptionSignal = Madwork.NewScriptSignal(), -- (profile_store_name, profile_key) -- Fired when DataStore key returns a value that has
	-- all or some of it's profile components set to invalid data types. E.g., accidentally setting Profile.Data to a noon table value

	CriticalState = false, -- Set to true while DataStore service is throwing too many errors
	CriticalStateSignal = Madwork.NewScriptSignal(), -- (is_critical_state) -- Fired when CriticalState is set to true
	-- (You may alert players with this, or set up analytics)

	ServiceIssueCount = 0,

	_active_profile_stores = {
		--[[
			{
				_profile_store_name = "", -- [string] -- DataStore name
				_profile_template = {} / nil, -- [table / nil]
				_global_data_store = global_data_store, -- [GlobalDataStore] -- Object returned by DataStoreService:GetDataStore(_profile_store_name)

				_loaded_profiles = {
					[profile_key] = {
						Data = {}, -- [table] -- Loaded once after ProfileStore:LoadProfileAsync() finishes
						Metadata = {}, -- [table] -- Updated with every auto-save
						GlobalUpdates = {, -- [GlobalUpdates]
							_updates_latest = {}, -- [table] {update_index, {{update_id, version_id, update_locked, update_data}, ...}}
							_pending_update_lock = {update_id, ...} / nil, -- [table / nil]
							_pending_update_clear = {update_id, ...} / nil, -- [table / nil]

							_new_active_update_listeners = {listener, ...} / nil, -- [table / nil]
							_new_locked_update_listeners = {listener, ...} / nil, -- [table / nil]

							_profile = Profile / nil, -- [Profile / nil]

							_update_handler_mode = true / nil, -- [bool / nil]
						}

						_profile_store = ProfileStore, -- [ProfileStore]
						_profile_key = "", -- [string]

						_release_listeners = {listener, ...} / nil, -- [table / nil]

						_view_mode = true / nil, -- [bool / nil]

						_load_timestamp = os.clock(),

						_is_user_mock = false, -- ProfileStore.Mock
					},
					...
				},
				_profile_load_jobs = {[profile_key] = {load_id, loaded_data}, ...},

				_mock_loaded_profiles = {[profile_key] = Profile, ...},
				_mock_profile_load_jobs = {[profile_key] = {load_id, loaded_data}, ...},
			},
			...
		--]]
	},

	_auto_save_list = { -- loaded profile table which will be circularly auto-saved
		--[[
			Profile,
			...
		--]]
	},

	_issue_queue = {}, -- [table] {issue_time, ...}
	_critical_state_start = 0, -- [number] 0 = no critical state / os.clock() = critical state start

	-- Debug:
	_mock_data_store = {},
	_user_mock_data_store = {},

	_use_mock_data_store = false,
}

--[[
	Saved profile structure:

	DataStoreProfile = {
		Data = {},
		Metadata = {
			ProfileCreateTime = 0,
			SessionLoadCount = 0,
			ActiveSession = {place_id, game_job_id} / nil,
			ForceLoadSession = {place_id, game_job_id} / nil,
			Metatags = {},
			LastUpdate = 0, -- os.time()
		},
		GlobalUpdates = {
			update_index,
			{
				{update_id, version_id, update_locked, update_data},
				...
			}
		},
	}

	OR

	DataStoreProfile = {
		GlobalUpdates = {
			update_index,
			{
				{update_id, version_id, update_locked, update_data},
				...
			}
		},
	}
--]]

----- Private Variables -----

local ActiveProfileStores = ProfileService._active_profile_stores
local AutoSaveList = ProfileService._auto_save_list
local IssueQueue = ProfileService._issue_queue

local PlaceId = game.PlaceId
local JobId = game.JobId

local AutoSaveIndex = 1 -- Next profile to auto save
local LastAutoSave = os.clock()

local LoadIndex = 0

local ActiveProfileLoadJobs = 0 -- Number of active threads that are loading in profiles
local ActiveProfileSaveJobs = 0 -- Number of active threads that are saving profiles

local CriticalStateStart = 0 -- os.clock()

local UseMockDataStore = false
local MockDataStore = ProfileService._mock_data_store -- Mock data store used when API access is disabled

local UserMockDataStore = ProfileService._user_mock_data_store -- Separate mock data store accessed via ProfileStore.Mock
local UseMockTag = {}

----- Utils -----

local function DeepCopyTable(t)
	local copy = {}
	for key, value in next, t do
		if type(value) == "table" then
			copy[key] = DeepCopyTable(value)
		else
			copy[key] = value
		end
	end

	return copy
end

local function ReconcileTable(target, template)
	for k, v in next, template do
		if type(k) == "string" then -- Only string keys will be reconciled
			if target[k] == nil then
				if type(v) == "table" then
					target[k] = DeepCopyTable(v)
				else
					target[k] = v
				end
			elseif type(target[k]) == "table" and type(v) == "table" then
				ReconcileTable(target[k], v)
			end
		end
	end
end

----- Private functions -----

local function RegisterIssue(error_message) -- Called when a DataStore API call errors
	error_message = tostring(error_message)
	warn("[ProfileService]: DataStore API error - \"" .. error_message .. "\"")
	table.insert(IssueQueue, os.clock()) -- Adding issue time to queue
	ProfileService.IssueSignal:Fire(error_message)
end

local function RegisterCorruption(profile_store_name, profile_key) -- Called when a corrupted profile is loaded
	warn("[ProfileService]: Profile corruption - ProfileStore = \"" .. profile_store_name .. "\", Key = \"" .. profile_key .. "\"")
	ProfileService.CorruptionSignal:Fire(profile_store_name, profile_key)
end

local function MockUpdateAsync(mock_data_store, profile_store_name, key, transform_function)
	local profile_store = mock_data_store[profile_store_name]
	if profile_store == nil then
		profile_store = {}
		mock_data_store[profile_store_name] = profile_store
	end

	local transform = transform_function(profile_store[key])
	if transform == nil then
		return nil
	else
		profile_store[key] = DeepCopyTable(transform)
		return DeepCopyTable(profile_store[key])
	end
end

local function IsThisSession(session_tag)
	return session_tag[1] == PlaceId and session_tag[2] == JobId
end

--[[
update_settings = {
	ExistingProfileHandle = function(latest_data),
	MissingProfileHandle = function(latest_data),
	EditProfile = function(lastest_data),

	WipeProfile = nil / true,
}
--]]
local function StandardProfileUpdateAsyncDataStore(profile_store, profile_key, update_settings, is_user_mock)
	local loaded_data
	local wipe_status = false
	local success, error_message = pcall(function()
		if update_settings.WipeProfile ~= true then
			local transform_function = function(latest_data)
				if latest_data == "PROFILE_WIPED" then
					latest_data = nil -- Profile was previously wiped - ProfileService will act like it was empty
				end

				local missing_profile = false
				local data_corrupted = false
				local global_updates_data = {0, {}}

				if latest_data == nil then
					missing_profile = true
				elseif type(latest_data) ~= "table" then
					missing_profile = true
					data_corrupted = true
				end

				if type(latest_data) == "table" then
					-- Case #1: Profile was loaded
					if type(latest_data.Data) == "table" and
						type(latest_data.Metadata) == "table" and
						type(latest_data.GlobalUpdates) == "table"
					then
						latest_data.WasCorrupted = false -- Must be set to false if set previously
						global_updates_data = latest_data.GlobalUpdates
						if update_settings.ExistingProfileHandle then
							update_settings.ExistingProfileHandle(latest_data)
						end

						-- Case #2: Profile was not loaded but GlobalUpdate data exists
					elseif latest_data.Data == nil and
						latest_data.Metadata == nil and
						type(latest_data.GlobalUpdates) == "table"
					then
						latest_data.WasCorrupted = false -- Must be set to false if set previously
						global_updates_data = latest_data.GlobalUpdates
						missing_profile = true
					else
						missing_profile = true
						data_corrupted = true
					end
				end

				-- Case #3: Profile was not created or corrupted and no GlobalUpdate data exists
				if missing_profile then
					latest_data = {
						-- Data = nil,
						-- Metadata = nil,
						GlobalUpdates = global_updates_data;
					}

					if update_settings.MissingProfileHandle then
						update_settings.MissingProfileHandle(latest_data)
					end
				end

				-- Editing profile:
				if update_settings.EditProfile then
					update_settings.EditProfile(latest_data)
				end

				-- Data corruption handling (Silently override with empty profile) (Also run Case #1)
				if data_corrupted then
					latest_data.WasCorrupted = true -- Temporary tag that will be removed on first save
				end

				return latest_data
			end

			if is_user_mock then -- Used when the profile is accessed through ProfileStore.Mock
				loaded_data = MockUpdateAsync(UserMockDataStore, profile_store._profile_store_name, profile_key, transform_function)
				Promise.Delay(0.03):Wait() -- Simulate API call yield
			elseif UseMockDataStore then -- Used when API access is disabled
				loaded_data = MockUpdateAsync(MockDataStore, profile_store._profile_store_name, profile_key, transform_function)
				Promise.Delay(0.03):Wait() -- Simulate API call yield
			else
				loaded_data = profile_store._global_data_store:UpdateAsync(profile_key, transform_function)
			end
		else
			if is_user_mock then -- Used when the profile is accessed through ProfileStore.Mock
				profile_store = UserMockDataStore[profile_store._profile_store_name]
				if profile_store ~= nil then
					profile_store[profile_key] = nil
				end

				wipe_status = true
				Promise.Delay(0.03):Wait() -- Simulate API call yield
			elseif UseMockDataStore then -- Used when API access is disabled
				profile_store = MockDataStore[profile_store._profile_store_name]
				if profile_store ~= nil then
					profile_store[profile_key] = nil
				end

				wipe_status = true
				Promise.Delay(0.03):Wait() -- Simulate API call yield
			else
				loaded_data = profile_store._global_data_store:UpdateAsync(profile_key, function()
					return "PROFILE_WIPED" -- It's impossible to set DataStore keys to nil after they have been set
				end)

				wipe_status = loaded_data == "PROFILE_WIPED"
			end
		end
	end)

	if update_settings.WipeProfile then
		return wipe_status
	elseif success and type(loaded_data) == "table" then
		-- Corruption handling:
		if loaded_data.WasCorrupted then
			RegisterCorruption(profile_store._profile_store_name, profile_key)
		end

		-- Return loaded_data:
		return loaded_data
	else
		RegisterIssue(error_message ~= nil and error_message or "Undefined error")
		-- Return nothing:
		return nil
	end
end

local function RemoveProfileFromAutoSave(profile)
	local auto_save_index = table.find(AutoSaveList, profile)
	if auto_save_index ~= nil then
		Table.FastRemove(AutoSaveList, auto_save_index)
		if auto_save_index < AutoSaveIndex then
			AutoSaveIndex -= 1 -- Table contents were moved left before AutoSaveIndex so move AutoSaveIndex left as well
		end

		if AutoSaveList[AutoSaveIndex] == nil then -- AutoSaveIndex was at the end of the AutoSaveList - reset to 1
			AutoSaveIndex = 1
		end
	end
end

local function AddProfileToAutoSave(profile) -- Notice: Makes sure this profile isn't auto-saved too soon
	-- Add at AutoSaveIndex and move AutoSaveIndex right:
	table.insert(AutoSaveList, AutoSaveIndex, profile)
	if #AutoSaveList > 1 then
		AutoSaveIndex += 1
	elseif #AutoSaveList == 1 then
		-- First profile created - make sure it doesn't get immediately auto saved:
		LastAutoSave = os.clock()
	end
end

local function ReleaseProfileInternally(profile)
	-- 1) Remove profile object from ProfileService references: --
	-- Clear reference in ProfileStore:
	local profile_store = profile._profile_store
	local loaded_profiles = profile._is_user_mock and profile_store._mock_loaded_profiles or profile_store._loaded_profiles
	loaded_profiles[profile._profile_key] = nil
	if next(profile_store._loaded_profiles) == nil and next(profile_store._mock_loaded_profiles) == nil then -- ProfileStore has turned inactive
		local index = table.find(ActiveProfileStores, profile_store)
		if index then
			Table.FastRemove(ActiveProfileStores, index)
		end
	end

	-- Clear auto update reference:
	RemoveProfileFromAutoSave(profile)
	-- 2) Trigger release listeners: --
	local place_id
	local game_job_id
	local active_session = profile.Metadata.ActiveSession
	if active_session ~= nil then
		place_id = active_session[1]
		game_job_id = active_session[2]
	end

	for _, listener in ipairs(profile._release_listeners) do
		listener(place_id, game_job_id)
	end

	profile._release_listeners = {}
end

local function CheckForNewGlobalUpdates(profile, old_global_updates_data, new_global_updates_data)
	local global_updates_object = profile.GlobalUpdates -- [GlobalUpdates]
	local pending_update_lock = global_updates_object._pending_update_lock -- {update_id, ...}
	local pending_update_clear = global_updates_object._pending_update_clear -- {update_id, ...}
	-- "old_" or "new_" global_updates_data = {update_index, {{update_id, version_id, update_locked, update_data}, ...}}
	for _, new_global_update in ipairs(new_global_updates_data[2]) do
		-- Find old global update with the same update_id:
		local old_global_update
		for _, global_update in ipairs(old_global_updates_data[2]) do
			if global_update[1] == new_global_update[1] then
				old_global_update = global_update
				break
			end
		end

		-- A global update is new when it didn't exist before or its version_id or update_locked state changed:
		local is_new = false
		if old_global_update == nil or new_global_update[2] > old_global_update[2] or new_global_update[3] ~= old_global_update[3] then
			is_new = true
		end

		if is_new then
			-- Active global updates:
			if new_global_update[3] == false then
				-- Check if update is not pending to be locked: (Preventing firing new active update listeners more than necessary)
				local is_pending_lock = false
				for _, update_id in ipairs(pending_update_lock) do
					if new_global_update[1] == update_id then
						is_pending_lock = true
						break
					end
				end

				if not is_pending_lock then
					-- Trigger new active update listeners:
					for _, listener in ipairs(global_updates_object._new_active_update_listeners) do
						listener(new_global_update[1], new_global_update[4])
					end
				end
			end

			-- Locked global updates:
			if new_global_update[3] then
				-- Check if update is not pending to be cleared: (Preventing firing new locked update listeners after marking a locked update for clearing)
				local is_pending_clear = false
				for _, update_id in ipairs(pending_update_clear) do
					if new_global_update[1] == update_id then
						is_pending_clear = true
						break
					end
				end

				if not is_pending_clear then
					-- Trigger new locked update listeners:
					for _, listener in ipairs(global_updates_object._new_locked_update_listeners) do
						listener(new_global_update[1], new_global_update[4])
						-- Check if listener marked the update to be cleared:
						-- Normally there should be only one listener per profile for new locked global updates, but
						-- in case several listeners are connected we will not trigger more listeners after one listener
						-- marks the locked global update to be cleared.
						for _, update_id in ipairs(pending_update_clear) do
							if new_global_update[1] == update_id then
								is_pending_clear = true
								break
							end
						end

						if is_pending_clear then
							break
						end
					end
				end
			end
		end
	end
end

local function SaveProfileAsync(profile, release_from_session)
	if type(profile.Data) ~= "table" then
		RegisterCorruption(profile._profile_store._profile_store_name, profile._profile_key)
		error("[ProfileService]: PROFILE DATA CORRUPTED DURING RUNTIME! ProfileStore = \"" .. profile._profile_store._profile_store_name .. "\", Key = \"" .. profile._profile_key .. "\"")
	end

	if release_from_session then
		ReleaseProfileInternally(profile)
	end

	ActiveProfileSaveJobs += 1
	local last_session_load_count = profile.Metadata.SessionLoadCount
	-- Compare "SessionLoadCount" when writing to profile to prevent a rare case of repeat last save when the profile is loaded on the same server again
	local repeat_save_flag = true -- Released Profile save calls have to repeat until they succeed
	while repeat_save_flag do
		if release_from_session ~= true then
			repeat_save_flag = false
		end

		local loaded_data = StandardProfileUpdateAsyncDataStore(
			profile._profile_store,
			profile._profile_key,
			{
				ExistingProfileHandle = nil;
				MissingProfileHandle = nil;
				EditProfile = function(latest_data)
					-- 1) Check if this session still owns the profile: --
					local active_session = latest_data.Metadata.ActiveSession
					local force_load_session = latest_data.Metadata.ForceLoadSession
					local session_load_count = latest_data.Metadata.SessionLoadCount
					local session_owns_profile = false
					local force_load_pending = false
					if type(active_session) == "table" then
						session_owns_profile = IsThisSession(active_session) and session_load_count == last_session_load_count
					end

					if type(force_load_session) == "table" then
						force_load_pending = not IsThisSession(force_load_session)
					end

					if session_owns_profile then -- We may only edit the profile if this session has ownership of the profile
						-- 2) Manage global updates: --
						local latest_global_updates_data = latest_data.GlobalUpdates -- {update_index, {{update_id, version_id, update_locked, update_data}, ...}}
						local latest_global_updates_list = latest_global_updates_data[2]

						local global_updates_object = profile.GlobalUpdates -- [GlobalUpdates]
						local pending_update_lock = global_updates_object._pending_update_lock -- {update_id, ...}
						local pending_update_clear = global_updates_object._pending_update_clear -- {update_id, ...}
						-- Active update locking:
						for _, global_update in ipairs(latest_global_updates_list) do
							for _, lock_id in ipairs(pending_update_lock) do
								if global_update[1] == lock_id then
									global_update[3] = true
									break
								end
							end
						end

						-- Locked update clearing:
						for _, clear_id in ipairs(pending_update_clear) do
							for i, global_update in ipairs(latest_global_updates_list) do
								if global_update[1] == clear_id and global_update[3] then
									Table.FastRemove(latest_global_updates_list, i)
									break
								end
							end
						end

						-- 3) Save profile data: --
						latest_data.Data = profile.Data
						latest_data.Metadata.Metatags = profile.Metadata.Metatags -- Metadata.Metatags is the only actively savable component of Metadata
						latest_data.Metadata.LastUpdate = os.time()
						if release_from_session or force_load_pending then
							latest_data.Metadata.ActiveSession = nil
						end
					end
				end;
			},
			profile._is_user_mock
		)

		if loaded_data ~= nil then
			repeat_save_flag = false
			-- 4) Set latest data in profile: --
			-- Setting global updates:
			local global_updates_object = profile.GlobalUpdates -- [GlobalUpdates]
			local old_global_updates_data = global_updates_object._updates_latest
			local new_global_updates_data = loaded_data.GlobalUpdates
			global_updates_object._updates_latest = new_global_updates_data
			-- Setting Metadata:
			local keep_session_meta_tag_reference = profile.Metadata.Metatags
			profile.Metadata = loaded_data.Metadata
			profile.Metadata.MetatagsLatest = profile.Metadata.Metatags
			profile.Metadata.Metatags = keep_session_meta_tag_reference
			-- 5) Check if session still owns the profile: --
			local active_session = loaded_data.Metadata.ActiveSession
			local session_load_count = loaded_data.Metadata.SessionLoadCount
			local session_owns_profile = false
			if type(active_session) == "table" then
				session_owns_profile = IsThisSession(active_session) and session_load_count == last_session_load_count
			end

			local is_active = profile:IsActive()
			if session_owns_profile then
				-- 6) Check for new global updates: --
				if is_active then -- Profile could've been released before the saving thread finished
					CheckForNewGlobalUpdates(profile, old_global_updates_data, new_global_updates_data)
				end
			else
				-- Session no longer owns the profile:
				-- 7) Release profile if it hasn't been released yet: --
				if is_active then
					ReleaseProfileInternally(profile)
				end
			end
		elseif repeat_save_flag then
			Promise.Delay(0.03):Wait() -- Prevent infinite loop in case DataStore API does not yield
		end
	end

	ActiveProfileSaveJobs -= 1
end

----- Public functions -----

-- GlobalUpdates object:

local GlobalUpdates = {
	--[[
		_updates_latest = {}, -- [table] {update_index, {{update_id, version_id, update_locked, update_data}, ...}}
		_pending_update_lock = {update_id, ...} / nil, -- [table / nil]
		_pending_update_clear = {update_id, ...} / nil, -- [table / nil]

		_new_active_update_listeners = {listener, ...} / nil, -- [table / nil]
		_new_locked_update_listeners = {listener, ...} / nil, -- [table / nil]

		_profile = Profile / nil, -- [Profile / nil]

		_update_handler_mode = true / nil, -- [bool / nil]
	--]]
}

GlobalUpdates.__index = GlobalUpdates

-- ALWAYS PUBLIC:
function GlobalUpdates:GetActiveUpdates() --> [table] {{update_id, update_data}, ...}
	local query_list = {}
	for _, global_update in ipairs(self._updates_latest[2]) do
		if global_update[3] == false then
			local is_pending_lock = false
			if self._pending_update_lock ~= nil then
				for _, update_id in ipairs(self._pending_update_lock) do
					if global_update[1] == update_id then
						is_pending_lock = true -- Exclude global updates pending to be locked
						break
					end
				end
			end

			if not is_pending_lock then
				local array = table.create(2, global_update[1])
				array[2] = global_update[4]
				table.insert(query_list, array)
			end
		end
	end

	return query_list
end

function GlobalUpdates:GetLockedUpdates() --> [table] {{update_id, update_data}, ...}
	local query_list = {}
	for _, global_update in ipairs(self._updates_latest[2]) do
		if global_update[3] then
			local is_pending_clear = false
			if self._pending_update_clear ~= nil then
				for _, update_id in ipairs(self._pending_update_clear) do
					if global_update[1] == update_id then
						is_pending_clear = true -- Exclude global updates pending to be cleared
						break
					end
				end
			end

			if not is_pending_clear then
				local array = table.create(2, global_update[1])
				array[2] = global_update[4]
				table.insert(query_list, array)
			end
		end
	end

	return query_list
end

-- ONLY WHEN FROM "Profile.GlobalUpdates":
function GlobalUpdates:ListenToNewActiveUpdate(listener) --> [ScriptConnection] listener(update_id, update_data)
	if type(listener) ~= "function" then
		error("[ProfileService]: Only a function can be set as listener in GlobalUpdates:ListenToNewActiveUpdate()")
	end

	local profile = self._profile
	if self._update_handler_mode then
		error("[ProfileService]: Can't listen to new global updates in ProfileStore:GlobalUpdateProfileAsync()")
	elseif self._new_active_update_listeners == nil then
		error("[ProfileService]: Can't listen to new global updates in view mode")
	elseif not profile:IsActive() then -- Check if profile is expired
		return { -- Do not connect listener if the profile is expired
			Disconnect = function()
			end;
		}
	end

	-- Connect listener:
	table.insert(self._new_active_update_listeners, listener)
	return Madwork.NewScriptConnection(self._new_active_update_listeners, listener)
end

function GlobalUpdates:ListenToNewLockedUpdate(listener) --> [ScriptConnection] listener(update_id, update_data)
	if type(listener) ~= "function" then
		error("[ProfileService]: Only a function can be set as listener in GlobalUpdates:ListenToNewLockedUpdate()")
	end

	local profile = self._profile
	if self._update_handler_mode then
		error("[ProfileService]: Can't listen to new global updates in ProfileStore:GlobalUpdateProfileAsync()")
	elseif self._new_locked_update_listeners == nil then
		error("[ProfileService]: Can't listen to new global updates in view mode")
	elseif not profile:IsActive() then -- Check if profile is expired
		return { -- Do not connect listener if the profile is expired
			Disconnect = function()
			end;
		}
	end

	-- Connect listener:
	table.insert(self._new_locked_update_listeners, listener)
	return Madwork.NewScriptConnection(self._new_locked_update_listeners, listener)
end

function GlobalUpdates:LockActiveUpdate(update_id)
	if type(update_id) ~= "number" then
		error("[ProfileService]: Invalid update_id")
	end

	local profile = self._profile
	if self._update_handler_mode then
		error("[ProfileService]: Can't lock active global updates in ProfileStore:GlobalUpdateProfileAsync()")
	elseif self._pending_update_lock == nil then
		error("[ProfileService]: Can't lock active global updates in view mode")
	elseif not profile:IsActive() then -- Check if profile is expired
		error("[ProfileService]: PROFILE EXPIRED - Can't lock active global updates")
	end

	-- Check if global update exists with given update_id
	local global_update_exists = nil
	for _, global_update in ipairs(self._updates_latest[2]) do
		if global_update[1] == update_id then
			global_update_exists = global_update
			break
		end
	end

	if global_update_exists ~= nil then
		local is_pending_lock = false
		for _, lock_update_id in ipairs(self._pending_update_lock) do
			if update_id == lock_update_id then
				is_pending_lock = true -- Exclude global updates pending to be locked
				break
			end
		end

		if not is_pending_lock and global_update_exists[3] == false then -- Avoid id duplicates in _pending_update_lock
			table.insert(self._pending_update_lock, update_id)
		end
	else
		error("[ProfileService]: Passed non-existant update_id")
	end
end

function GlobalUpdates:ClearLockedUpdate(update_id)
	if type(update_id) ~= "number" then
		error("[ProfileService]: Invalid update_id")
	end

	local profile = self._profile
	if self._update_handler_mode then
		error("[ProfileService]: Can't clear locked global updates in ProfileStore:GlobalUpdateProfileAsync()")
	elseif self._pending_update_clear == nil then
		error("[ProfileService]: Can't clear locked global updates in view mode")
	elseif not profile:IsActive() then -- Check if profile is expired
		error("[ProfileService]: PROFILE EXPIRED - Can't clear locked global updates")
	end

	-- Check if global update exists with given update_id
	local global_update_exists = nil
	for _, global_update in ipairs(self._updates_latest[2]) do
		if global_update[1] == update_id then
			global_update_exists = global_update
			break
		end
	end

	if global_update_exists then
		local is_pending_clear = false
		for _, clear_update_id in ipairs(self._pending_update_clear) do
			if update_id == clear_update_id then
				is_pending_clear = true -- Exclude global updates pending to be cleared
				break
			end
		end

		if not is_pending_clear and global_update_exists[3] then -- Avoid id duplicates in _pending_update_clear
			table.insert(self._pending_update_clear, update_id)
		end
	else
		error("[ProfileService]: Passed non-existant update_id")
	end
end

-- EXPOSED TO "update_handler" DURING ProfileStore:GlobalUpdateProfileAsync() CALL
function GlobalUpdates:AddActiveUpdate(update_data)
	if type(update_data) ~= "table" then
		error("[ProfileService]: Invalid update_data")
	end

	if self._new_active_update_listeners ~= nil then
		error("[ProfileService]: Can't add active global updates in loaded Profile; Use ProfileStore:GlobalUpdateProfileAsync()")
	elseif self._update_handler_mode ~= true then
		error("[ProfileService]: Can't add active global updates in view mode; Use ProfileStore:GlobalUpdateProfileAsync()")
	end

	-- self._updates_latest = {}, -- [table] {update_index, {{update_id, version_id, update_locked, update_data}, ...}}
	local updates_latest = self._updates_latest
	local update_index = updates_latest[1] + 1 -- Incrementing global update index
	updates_latest[1] = update_index

	-- Add new active global update:
	local array = table.create(4, update_index)
	array[2], array[3], array[4] = 1, false, update_data
	table.insert(updates_latest[2], array)
end

function GlobalUpdates:ChangeActiveUpdate(update_id, update_data)
	if type(update_id) ~= "number" then
		error("[ProfileService]: Invalid update_id")
	end

	if type(update_data) ~= "table" then
		error("[ProfileService]: Invalid update_data")
	end

	if self._new_active_update_listeners ~= nil then
		error("[ProfileService]: Can't change active global updates in loaded Profile; Use ProfileStore:GlobalUpdateProfileAsync()")
	elseif self._update_handler_mode ~= true then
		error("[ProfileService]: Can't change active global updates in view mode; Use ProfileStore:GlobalUpdateProfileAsync()")
	end

	-- self._updates_latest = {}, -- [table] {update_index, {{update_id, version_id, update_locked, update_data}, ...}}
	local updates_latest = self._updates_latest
	local get_global_update = nil
	for _, global_update in ipairs(updates_latest[2]) do
		if update_id == global_update[1] then
			get_global_update = global_update
			break
		end
	end

	if get_global_update ~= nil then
		if get_global_update[3] then
			error("[ProfileService]: Can't change locked global update")
		end

		get_global_update[2] += 1 -- Increment version id
		get_global_update[4] = update_data -- Set new global update data
	else
		error("[ProfileService]: Passed non-existant update_id")
	end
end

function GlobalUpdates:ClearActiveUpdate(update_id)
	if type(update_id) ~= "number" then
		error("[ProfileService]: Invalid update_id argument")
	end

	if self._new_active_update_listeners ~= nil then
		error("[ProfileService]: Can't clear active global updates in loaded Profile; Use ProfileStore:GlobalUpdateProfileAsync()")
	elseif self._update_handler_mode ~= true then
		error("[ProfileService]: Can't clear active global updates in view mode; Use ProfileStore:GlobalUpdateProfileAsync()")
	end

	-- self._updates_latest = {}, -- [table] {update_index, {{update_id, version_id, update_locked, update_data}, ...}}
	local updates_latest = self._updates_latest
	local get_global_update_index = nil
	local get_global_update = nil
	for index, global_update in ipairs(updates_latest[2]) do
		if update_id == global_update[1] then
			get_global_update_index = index
			get_global_update = global_update
			break
		end
	end

	if get_global_update ~= nil then
		if get_global_update[3] then
			error("[ProfileService]: Can't clear locked global update")
		end

		Table.FastRemove(updates_latest[2], get_global_update_index) -- Remove active global update
	else
		error("[ProfileService]: Passed non-existant update_id")
	end
end

-- Profile object:

local Profile = {
	--[[
		Data = {}, -- [table] -- Loaded once after ProfileStore:LoadProfileAsync() finishes
		Metadata = {}, -- [table] -- Updated with every auto-save
		GlobalUpdates = GlobalUpdates, -- [GlobalUpdates]

		Janitor = Janitor;
		UsedKeys = Map<String, Boolean>;

		_profile_store = ProfileStore, -- [ProfileStore]
		_profile_key = "", -- [string]

		_release_listeners = {listener, ...} / nil, -- [table / nil]

		_view_mode = true / nil, -- [bool / nil]

		_load_timestamp = os.clock(),

		_is_user_mock = false, -- ProfileStore.Mock
	--]]
}

Profile.__index = Profile

--[[**
	Returns `true` while the profile is session-locked and saving of changes to Profile.Data is guaranteed.
	@returns [boolean] Whether or not the profile is locked and saving.
**--]]
function Profile:IsActive() --> [bool]
	local loaded_profiles = self._is_user_mock and self._profile_store._mock_loaded_profiles or self._profile_store._loaded_profiles
	return loaded_profiles[self._profile_key] == self
end

--[[**
	Equivalent of `Profile.Metadata.Metatags[tag_name]`. See `Profile:SetMetatag()` for more info. 
	@param [string] TagName The tag name string.
	@returns [any]
**--]]
function Profile:GetMetatag(tag_name) --> value
	local meta_data = self.Metadata
	if meta_data == nil then
		return nil
		-- error("[ProfileService]: This Profile hasn't been loaded before - Metadata not available")
	end

	return self.Metadata.Metatags[tag_name]
end

function Profile:SetMetatag(tag_name, value: any)
	if type(tag_name) ~= "string" then
		error("[ProfileService]: tag_name must be a string")
	elseif #tag_name == 0 then
		error("[ProfileService]: Invalid tag_name")
	end

	if self._view_mode then
		error("[ProfileService]: Can't set meta tag in view mode")
	end

	if not self:IsActive() then
		error("[ProfileService]: PROFILE EXPIRED - Meta tags can't be set")
	end

	self.Metadata.Metatags[tag_name] = value
end

function Profile:Reconcile()
	ReconcileTable(self.Data, self._profile_store._profile_template)
	return self
end

type ValueBase = BoolValue | BrickColorValue | CFrameValue | Color3Value | DoubleConstrainedValue | IntConstrainedValue | IntValue | NumberValue | ObjectValue | RayValue | StringValue | Vector3Value

function Profile:StoreOnValueChange(Name: string, ValueBase: ValueBase)
	if self.UsedKeys[Name] then
		error(string.format("[Profile.StoreOnValueChange] - Already have a writer for %q", Name), 2)
	end

	self.UsedKeys[Name] = true
	return self.Janitor:Add(ValueBase.Changed:Connect(function(NewValue)
		self.Data[Name] = NewValue
	end), "Disconnect")
end

function Profile:ListenToRelease(listener) --> [ScriptConnection] (place_id / nil, game_job_id / nil)
	if type(listener) ~= "function" then
		error("[ProfileService]: Only a function can be set as listener in Profile:ListenToRelease()")
	end

	if self._view_mode then
		error("[ProfileService]: Can't listen to Profile release in view mode")
	end

	if not self:IsActive() then
		-- Call release listener immediately if profile is expired
		local place_id
		local game_job_id
		local active_session = self.Metadata.ActiveSession
		if active_session ~= nil then
			place_id = active_session[1]
			game_job_id = active_session[2]
		end

		listener(place_id, game_job_id)
		return {
			Disconnect = function()
			end;
		}
	else
		table.insert(self._release_listeners, listener)
		return self.Janitor:Add(Madwork.NewScriptConnection(self._release_listeners, listener), "Disconnect")
	end
end

function Profile:Save()
	if self._view_mode then
		error("[ProfileService]: Can't save Profile in view mode")
	end

	if not self:IsActive() then
		error("[ProfileService]: PROFILE EXPIRED - Can't save Profile")
	end

	-- We don't want auto save to trigger too soon after manual saving - this will reset the auto save timer:
	RemoveProfileFromAutoSave(self)
	AddProfileToAutoSave(self)

	-- Call save function in a new thread:
	Scheduler.Spawn(SaveProfileAsync, self)
end

function Profile:SaveAsync()
	if self._view_mode then
		error("[ProfileService]: Can't save Profile in view mode")
	end

	if not self:IsActive() then
		error("[ProfileService]: PROFILE EXPIRED - Can't save Profile")
	end

	-- We don't want auto save to trigger too soon after manual saving - this will reset the auto save timer:
	RemoveProfileFromAutoSave(self)
	AddProfileToAutoSave(self)

	return Promise.Promisify(function()
		SaveProfileAsync(self)
	end)()
end

function Profile:Release()
	if self._view_mode then
		error("[ProfileService]: Can't release Profile in view mode")
	end

	if self:IsActive() then
		return Promise.Resolve(Scheduler.Spawn(SaveProfileAsync, self, true)):Finally(function()
			self.Janitor = self.Janitor:Destroy()
		end) -- Call save function in a new thread with release_from_session = true
	end
end

function Profile:ReleaseAsync()
	if self._view_mode then
		error("[ProfileService]: Can't release Profile in view mode")
	end

	if self:IsActive() then
		return Promise.Promisify(function()
			SaveProfileAsync(self, true)
		end)():Finally(function()
			self.Janitor = self.Janitor:Destroy()
		end)
	end
end

local function free()
end

-- ProfileStore object:

local ProfileStore = {
	--[[
		Mock = {},

		_profile_store_name = "", -- [string] -- DataStore name
		_profile_template = {}, -- [table]
		_global_data_store = global_data_store, -- [GlobalDataStore] -- Object returned by DataStoreService:GetDataStore(_profile_store_name)

		_loaded_profiles = {[profile_key] = Profile, ...},
		_profile_load_jobs = {[profile_key] = {load_id, loaded_data}, ...},

		_mock_loaded_profiles = {[profile_key] = Profile, ...},
		_mock_profile_load_jobs = {[profile_key] = {load_id, loaded_data}, ...},
	--]]
}

ProfileStore.__index = ProfileStore

--[[**
	Loads a Profile.
	@param [Typer.String] ProfileKey The DataStore key to use.
	@param [Typer.EnumerationOfTypeDataStoreHandlerOrFunction] NotReleasedHandler For basic usage, pass `Enumeration.DataStoreHandler.ForceLoad`. This can be a function with the signature `(PlaceId: number, GameJobId: string) -> Enumeration.DataStoreHandler` for more advanced usage.
	@returns [Profile?]
**--]]
function ProfileStore:LoadProfile(profile_key, not_released_handler, _use_mock) --> [Profile / nil] not_released_handler(place_id, game_job_id)
	if self._profile_template == nil then
		error("[ProfileService]: Profile template not set - ProfileStore:LoadProfileAsync() locked for this ProfileStore")
	end

	if type(profile_key) ~= "string" then
		error("[ProfileService]: profile_key must be a string")
	elseif #profile_key == 0 then
		error("[ProfileService]: Invalid profile_key")
	end

	if type(not_released_handler) ~= "function" and not_released_handler ~= Enumeration.DataStoreHandler.ForceLoad and not_released_handler ~= Enumeration.DataStoreHandler.Steal then
		error("[ProfileService]: Invalid not_released_handler")
	end

	if ProfileService.ServiceLocked then
		return nil
	end

	local is_user_mock = _use_mock == UseMockTag

	-- Check if profile with profile_key isn't already loaded in this session:
	for _, profile_store in ipairs(ActiveProfileStores) do
		if profile_store._profile_store_name == self._profile_store_name then
			local loaded_profiles = is_user_mock and profile_store._mock_loaded_profiles or profile_store._loaded_profiles
			if loaded_profiles[profile_key] ~= nil then
				error("[ProfileService]: Profile of ProfileStore \"" .. self._profile_store_name .. "\" with key \"" .. profile_key .. "\" is already loaded in this session")
				-- Are you using Profile:Release() properly?
			end
		end
	end

	ActiveProfileLoadJobs += 1
	local force_load = not_released_handler == Enumeration.DataStoreHandler.ForceLoad
	local force_load_steps = 0
	local request_force_load = force_load -- First step of ForceLoad
	local steal_session = false -- Second step of ForceLoad
	local aggressive_steal = not_released_handler == Enumeration.DataStoreHandler.Steal -- Developer invoked steal

	while not ProfileService.ServiceLocked do
		-- Load profile:
		-- SPECIAL CASE - If LoadProfileAsync is called for the same key before another LoadProfileAsync finishes,
		-- yoink the DataStore return for the new call. The older call will return nil. This would prevent very rare
		-- game breaking errors where a player rejoins the server super fast.
		local profile_load_jobs = is_user_mock and self._mock_profile_load_jobs or self._profile_load_jobs
		local loaded_data
		local load_id = LoadIndex + 1
		LoadIndex = load_id

		local profile_load_job = profile_load_jobs[profile_key] -- {load_id, loaded_data}
		if profile_load_job then
			profile_load_job[1] = load_id -- Yoink load job
			while profile_load_job[2] == nil do -- Wait for job to finish
				Promise.Delay(0.03):Wait()
			end

			if profile_load_job[1] == load_id then -- Load job hasn't been double-yoinked
				loaded_data = profile_load_job[2]
				profile_load_jobs[profile_key] = nil
			else
				return nil
			end
		else
			profile_load_job = table.create(2, load_id)
			profile_load_job[2] = nil
			--profile_load_job = {load_id, nil}
			profile_load_jobs[profile_key] = profile_load_job
			profile_load_job[2] = StandardProfileUpdateAsyncDataStore(
				self,
				profile_key,
				{
					ExistingProfileHandle = function(latest_data)
						if not ProfileService.ServiceLocked then
							local active_session = latest_data.Metadata.ActiveSession
							local force_load_session = latest_data.Metadata.ForceLoadSession
							-- IsThisSession(active_session)
							if active_session == nil then
								local array = table.create(2, PlaceId)
								array[2] = JobId

								latest_data.Metadata.ActiveSession = array
								latest_data.Metadata.ForceLoadSession = nil
							elseif type(active_session) == "table" then
								if not IsThisSession(active_session) then
									local last_update = latest_data.Metadata.LastUpdate
									if last_update ~= nil then
										if os.time() - last_update > SETTINGS.AssumeDeadSessionLock then
											local array = table.create(2, PlaceId)
											array[2] = JobId

											latest_data.Metadata.ActiveSession = array
											latest_data.Metadata.ForceLoadSession = nil
											return
										end
									end

									if steal_session or aggressive_steal then
										local force_load_uninterrupted = false
										if force_load_session ~= nil then
											force_load_uninterrupted = IsThisSession(force_load_session)
										end

										if force_load_uninterrupted or aggressive_steal then
											local array = table.create(2, PlaceId)
											array[2] = JobId

											latest_data.Metadata.ActiveSession = array
											latest_data.Metadata.ForceLoadSession = nil
										end
									elseif request_force_load then
										local array = table.create(2, PlaceId)
										array[2] = JobId
										latest_data.Metadata.ForceLoadSession = array
									end
								else
									latest_data.Metadata.ForceLoadSession = nil
								end
							end
						end
					end;

					MissingProfileHandle = function(latest_data)
						latest_data.Data = DeepCopyTable(self._profile_template)
						latest_data.Metadata = {
							ProfileCreateTime = os.time();
							SessionLoadCount = 0;
							ActiveSession = {PlaceId, JobId};
							ForceLoadSession = nil;
							Metatags = {};
						}
					end;

					EditProfile = function(latest_data)
						if not ProfileService.ServiceLocked then
							local active_session = latest_data.Metadata.ActiveSession
							if active_session ~= nil and IsThisSession(active_session) then
								latest_data.Metadata.SessionLoadCount += 1
								latest_data.Metadata.LastUpdate = os.time()
							end
						end
					end;
				},
				is_user_mock
			)

			if profile_load_job[1] == load_id then -- Load job hasn't been yoinked
				loaded_data = profile_load_job[2]
				profile_load_jobs[profile_key] = nil
			else
				return nil -- Load job yoinked
			end
		end

		-- Handle load_data:
		if loaded_data ~= nil then
			local active_session = loaded_data.Metadata.ActiveSession
			if type(active_session) == "table" then
				if IsThisSession(active_session) then
					-- Special component in Metatags:
					loaded_data.Metadata.MetatagsLatest = DeepCopyTable(loaded_data.Metadata.Metatags)
					-- Case #1: Profile is now taken by this session:
					-- Create Profile object:
					local global_updates_object = setmetatable({
						_updates_latest = loaded_data.GlobalUpdates;
						_pending_update_lock = {};
						_pending_update_clear = {};

						_new_active_update_listeners = {};
						_new_locked_update_listeners = {};

						_profile = nil;
					}, GlobalUpdates)

					local profile = setmetatable({
						Data = loaded_data.Data;
						Metadata = loaded_data.Metadata;
						GlobalUpdates = global_updates_object;

						Janitor = Janitor.new();
						UsedKeys = {};

						_profile_store = self;
						_profile_key = profile_key;

						_release_listeners = {};

						_load_timestamp = os.clock();

						_is_user_mock = is_user_mock;
					}, Profile)

					global_updates_object._profile = profile
					-- Referencing Profile object in ProfileStore:
					if next(self._loaded_profiles) == nil and next(self._mock_loaded_profiles) == nil then -- ProfileStore object was inactive
						table.insert(ActiveProfileStores, self)
					end

					if is_user_mock then
						self._mock_loaded_profiles[profile_key] = profile
					else
						self._loaded_profiles[profile_key] = profile
					end

					-- Adding profile to AutoSaveList;
					AddProfileToAutoSave(profile)
					-- Special case - finished loading profile, but session is shutting down:
					if ProfileService.ServiceLocked then
						SaveProfileAsync(profile, true) -- Release profile and yield until the DataStore call is finished
						profile = free() -- nil will be returned by this call
					end

					-- Return Profile object:
					ActiveProfileLoadJobs -= 1
					return profile
				else
					-- Case #2: Profile is taken by some other session:
					if force_load then
						local force_load_session = loaded_data.Metadata.ForceLoadSession
						local force_load_uninterrupted = false
						if force_load_session ~= nil then
							force_load_uninterrupted = IsThisSession(force_load_session)
						end

						if force_load_uninterrupted then
							if not request_force_load then
								force_load_steps += 1
								if force_load_steps == SETTINGS.ForceLoadMaxSteps then
									steal_session = true
								end
							end

							Promise.Delay(SETTINGS.LoadProfileRepeatDelay):Wait() -- Let the cycle repeat again after a delay
						else
							-- Another session tried to force load this profile:
							ActiveProfileLoadJobs -= 1
							return nil
						end

						request_force_load = false -- Only request a force load once
					elseif aggressive_steal then
						Promise.Delay(SETTINGS.LoadProfileRepeatDelay):Wait() -- Let the cycle repeat again after a delay
					else
						local handler_result = not_released_handler(active_session[1], active_session[2])
						if handler_result == Enumeration.DataStoreHandler.Repeat then
							Promise.Delay(SETTINGS.LoadProfileRepeatDelay):Wait() -- Let the cycle repeat again after a delay
						elseif handler_result == Enumeration.DataStoreHandler.Cancel then
							ActiveProfileLoadJobs -= 1
							return nil
						elseif handler_result == Enumeration.DataStoreHandler.ForceLoad then
							force_load = true
							request_force_load = true
							Promise.Delay(SETTINGS.LoadProfileRepeatDelay):Wait() -- Let the cycle repeat again after a delay
						elseif handler_result == Enumeration.DataStoreHandler.Steal then
							aggressive_steal = true
							Promise.Delay(SETTINGS.LoadProfileRepeatDelay):Wait() -- Let the cycle repeat again after a delay
						else
							error("[ProfileService]: Invalid return from not_released_handler")
						end
					end
				end
			else
				ActiveProfileLoadJobs -= 1
				error("[ProfileService]: Invalid ActiveSession value in Profile.Metadata - Fatal corruption") -- It's unlikely this will ever fire
			end
		else
			Promise.Delay(SETTINGS.LoadProfileRepeatDelay):Wait() -- Let the cycle repeat again after a delay
		end
	end

	ActiveProfileLoadJobs -= 1
	return nil -- If loop breaks return nothing
end

function ProfileStore:GlobalUpdateProfile(profile_key, update_handler, _use_mock) --> [GlobalUpdates / nil] (update_handler(GlobalUpdates))
	if type(profile_key) ~= "string" or #profile_key == 0 then
		error("[ProfileService]: Invalid profile_key")
	end

	if type(update_handler) ~= "function" then
		error("[ProfileService]: Invalid update_handler")
	end

	if ProfileService.ServiceLocked then
		return nil
	end

	while not ProfileService.ServiceLocked do
		-- Updating profile:
		local loaded_data = StandardProfileUpdateAsyncDataStore(
			self,
			profile_key,
			{
				ExistingProfileHandle = nil;
				MissingProfileHandle = nil;
				EditProfile = function(latest_data)
					-- Running update_handler:
					update_handler(setmetatable({
						_updates_latest = latest_data.GlobalUpdates;
						_update_handler_mode = true;
					}, GlobalUpdates))
				end;
			},
			_use_mock == UseMockTag
		)

		-- Handling loaded_data:
		if loaded_data ~= nil then
			-- Return GlobalUpdates object (Update successful):
			return setmetatable({
				_updates_latest = loaded_data.GlobalUpdates;
			}, GlobalUpdates)
		else
			Promise.Delay(SETTINGS.LoadProfileRepeatDelay):Wait() -- Let the cycle repeat again
		end
	end

	return nil -- Return nothing (Update unsuccessful)
end

function ProfileStore:ViewProfile(profile_key, _use_mock) --> [Profile / nil]
	if type(profile_key) ~= "string" or #profile_key == 0 then
		error("[ProfileService]: Invalid profile_key")
	end

	if ProfileService.ServiceLocked then
		return nil
	end

	while not ProfileService.ServiceLocked do
		-- Load profile:
		local loaded_data = StandardProfileUpdateAsyncDataStore(
			self,
			profile_key,
			{
				ExistingProfileHandle = nil;
				MissingProfileHandle = nil;
				EditProfile = nil;
			},
			_use_mock == UseMockTag
		)

		-- Handle load_data:
		if loaded_data ~= nil then
			-- Create Profile object:
			local global_updates_object = setmetatable({
				_updates_latest = loaded_data.GlobalUpdates;
				_profile = nil;
			}, GlobalUpdates)

			local profile = setmetatable({
				Data = loaded_data.Data;
				Metadata = loaded_data.Metadata;
				GlobalUpdates = global_updates_object;

				Janitor = Janitor.new();
				UsedKeys = {};

				_profile_store = self;
				_profile_key = profile_key;

				_view_mode = true;

				_load_timestamp = os.clock();
			}, Profile)

			global_updates_object._profile = profile
			-- Returning Profile object:
			return profile
		else
			Promise.Delay(SETTINGS.LoadProfileRepeatDelay):Wait() -- Let the cycle repeat again after a delay
		end
	end

	return nil -- If loop breaks return nothing
end

function ProfileStore:WipeProfile(profile_key, _use_mock) --> is_wipe_successful [bool]
	if type(profile_key) ~= "string" or #profile_key == 0  then
		error("[ProfileService]: Invalid profile_key")
	end

	if ProfileService.ServiceLocked then
		return false
	end

	return StandardProfileUpdateAsyncDataStore(
		self,
		profile_key,
		{WipeProfile = true},
		_use_mock == UseMockTag
	)
end

ProfileStore.LoadProfileAsync = Promise.Promisify(ProfileStore.LoadProfile)
ProfileStore.GlobalUpdateProfileAsync = Promise.Promisify(ProfileStore.GlobalUpdateProfile)
ProfileStore.ViewProfileAsync = Promise.Promisify(ProfileStore.ViewProfile)
ProfileStore.WipeProfileAsync = Promise.Promisify(ProfileStore.WipeProfile)

-- New ProfileStore:

function ProfileService.GetProfileStore(profile_store_name, profile_template) --> [ProfileStore]
	if type(profile_store_name) ~= "string" then
		error("[ProfileService]: profile_store_name must be a string")
	elseif #profile_store_name == 0 then
		error("[ProfileService]: Invalid profile_store_name")
	end

	if type(profile_template) ~= "table" then
		error("[ProfileService]: Invalid profile_template")
	end

	local profile_store
	profile_store = {
		Mock = {
			LoadProfileAsync = function(_, profile_key, not_released_handler)
				return profile_store:LoadProfileAsync(profile_key, not_released_handler, UseMockTag)
			end;

			GlobalUpdateProfileAsync = function(_, profile_key, update_handler)
				return profile_store:GlobalUpdateProfileAsync(profile_key, update_handler, UseMockTag)
			end;

			ViewProfileAsync = function(_, profile_key)
				return profile_store:ViewProfileAsync(profile_key, UseMockTag)
			end;

			WipeProfileAsync = function(_, profile_key)
				return profile_store:WipeProfileAsync(profile_key, UseMockTag)
			end;

			-- Non-Promise
			LoadProfile = function(_, profile_key, not_released_handler)
				return profile_store:LoadProfile(profile_key, not_released_handler, UseMockTag)
			end;

			GlobalUpdateProfile = function(_, profile_key, update_handler)
				return profile_store:GlobalUpdateProfile(profile_key, update_handler, UseMockTag)
			end;

			ViewProfile = function(_, profile_key)
				return profile_store:ViewProfile(profile_key, UseMockTag)
			end;

			WipeProfile = function(_, profile_key)
				return profile_store:WipeProfile(profile_key, UseMockTag)
			end;
		};

		_profile_store_name = profile_store_name;
		_profile_template = profile_template;
		_global_data_store = DataStoreService:GetDataStore(profile_store_name);
		_loaded_profiles = {};
		_profile_load_jobs = {};
		_mock_loaded_profiles = {};
		_mock_profile_load_jobs = {};
	}

	return setmetatable(profile_store, ProfileStore)
end

-- Auto saving and issue queue managing:
RunService.Heartbeat:Connect(function()
	-- 1) Auto saving: --
	local auto_save_list_length = #AutoSaveList
	if auto_save_list_length > 0 then
		local auto_save_index_speed = SETTINGS.AutoSaveProfiles / auto_save_list_length
		local os_clock = os.clock()
		while os_clock - LastAutoSave > auto_save_index_speed do
			LastAutoSave += auto_save_index_speed
			local profile = AutoSaveList[AutoSaveIndex]
			if os_clock - profile._load_timestamp < SETTINGS.AutoSaveProfiles then
				-- This profile is freshly loaded - auto-saving immediately after loading will cause a warning in the log:
				profile = nil
				for _ = 1, auto_save_list_length - 1 do
					-- Move auto save index to the right:
					AutoSaveIndex += 1
					if AutoSaveIndex > auto_save_list_length then
						AutoSaveIndex = 1
					end

					profile = AutoSaveList[AutoSaveIndex]
					if os_clock - profile._load_timestamp >= SETTINGS.AutoSaveProfiles then
						break
					else
						profile = nil
					end
				end
			end

			-- Move auto save index to the right:
			AutoSaveIndex += 1
			if AutoSaveIndex > auto_save_list_length then
				AutoSaveIndex = 1
			end

			-- Perform save call:
			-- print("[ProfileService]: Auto updating profile - profile_store_name = \"" .. profile._profile_store._profile_store_name .. "\"; profile_key = \"" .. profile._profile_key .. "\"")
			if profile ~= nil then
				Scheduler.Spawn(SaveProfileAsync, profile) -- Auto save profile in new thread
			end
		end
	end

	-- 2) Issue queue: --
	-- Critical state handling:
	if not ProfileService.CriticalState then
		if #IssueQueue >= SETTINGS.IssueCountForCriticalState then
			ProfileService.CriticalState = true
			ProfileService.CriticalStateSignal:Fire(true)
			CriticalStateStart = os.clock()
			warn("[ProfileService]: Entered critical state")
		end
	else
		if #IssueQueue >= SETTINGS.IssueCountForCriticalState then
			CriticalStateStart = os.clock()
		elseif os.clock() - CriticalStateStart > SETTINGS.CriticalStateLast then
			ProfileService.CriticalState = false
			ProfileService.CriticalStateSignal:Fire(false)
			warn("[ProfileService]: Critical state ended")
		end
	end

	-- Issue queue:
	while true do
		local issue_time = IssueQueue[1]
		if issue_time == nil then
			break
		elseif os.clock() - issue_time > SETTINGS.IssueLast then
			Table.FastRemove(IssueQueue, 1)
		else
			break
		end
	end
end)

-- Release all loaded profiles when the server is shutting down:
Madwork.ConnectToOnClose(
	function()
		ProfileService.ServiceLocked = true
		-- 1) Release all active profiles: --
		-- Clone AutoSaveList to a new table because AutoSaveList changes when profiles are released:
		local on_close_save_job_count = 0
		local active_profiles = {}
		for index, profile in ipairs(AutoSaveList) do
			active_profiles[index] = profile
		end

		-- Release the profiles; Releasing profiles can trigger listeners that release other profiles, so check active state:
		for _, profile in ipairs(active_profiles) do
			if profile:IsActive() then
				on_close_save_job_count += 1
				-- Promise.Defer(function(Resolve)
				-- 	SaveProfileAsync(profile, true)
				-- 	Resolve()
				-- end):Catch(function(Error)
				-- 	warn("Error saving profile:", tostring(Error))
				-- end):Finally(function()
				-- 	on_close_save_job_count -= 1
				-- end)

				local thread = coroutine.create(function() -- Save profile on new thread
					SaveProfileAsync(profile, true)
					on_close_save_job_count -= 1
				end)

				coroutine.resume(thread)
			end
		end

		-- 2) Yield until all active profile jobs are finished: --
		while on_close_save_job_count > 0 or ActiveProfileLoadJobs > 0 or ActiveProfileSaveJobs > 0 do
			Promise.Delay(0.03):Wait()
		end

		return -- We're done!
	end,
	UseMockDataStore == false -- Always run this OnClose task if using Roblox API services
)

return ProfileService