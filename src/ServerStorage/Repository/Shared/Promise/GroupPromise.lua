local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local CatchFactory = Resources:LoadLibrary("CatchFactory")
local Constants = Resources:LoadLibrary("Constants")
local Promise = Resources:LoadLibrary("Promise")
local Services = Resources:LoadLibrary("Services")

local GroupService: GroupService = Services.GroupService

local GroupPromise = {}

function GroupPromise.PromiseGroups(PlayerOrUserId)
	local UserId = type(PlayerOrUserId) == "number" and PlayerOrUserId or PlayerOrUserId.UserId
	return Promise.Defer(function(Resolve, Reject)
		local Success, Groups = pcall(GroupService.GetGroupsAsync, GroupService, UserId);
		(Success and Resolve or Reject)(Groups)
	end)
end

function GroupPromise.PromiseRankInGroup(PlayerOrUserId, GroupId)
	return GroupPromise.PromiseGroups(PlayerOrUserId):Then(function(Groups)
		for _, Group in ipairs(Groups) do
			if Group.Id == GroupId then
				return Group.Rank
			end
		end

		return 0
	end):Catch(CatchFactory("GroupPromise.PromiseGroups"))
end

function GroupPromise.PromiseRoleInGroup(PlayerOrUserId, GroupId)
	return GroupPromise.PromiseGroups(PlayerOrUserId):Then(function(Groups)
		for _, Group in ipairs(Groups) do
			if Group.Id == GroupId then
				return Group.Role
			end
		end

		return Constants.CONFIGURATION.DEFAULT_ROLE
	end):Catch(CatchFactory("GroupPromise.PromiseGroups"))
end

function GroupPromise.PromiseGroupInfo(GroupId)
	return Promise.Defer(function(Resolve, Reject)
		local Success, GroupInfo = pcall(GroupService.GetGroupInfoAsync, GroupService, GroupId);
		(Success and Resolve or Reject)(GroupInfo)
	end)
end

return GroupPromise