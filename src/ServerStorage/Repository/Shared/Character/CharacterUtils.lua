--- General character utility code.
-- @module CharacterUtils

local Players = game:GetService("Players")

local CharacterUtils = {}

function CharacterUtils.GetPlayerHumanoid(Player)
	local Character = Player.Character
	if not Character then
		return nil
	end

	return Character:FindFirstChildOfClass("Humanoid")
end

function CharacterUtils.GetAlivePlayerHumanoid(Player)
	local Humanoid = CharacterUtils.GetPlayerHumanoid(Player)
	if not Humanoid or Humanoid.Health <= 0 then
		return nil
	end

	return Humanoid
end

function CharacterUtils.GetAlivePlayerRootPart(Player)
	local Humanoid = CharacterUtils.GetPlayerHumanoid(Player)
	if not Humanoid or Humanoid.Health <= 0 then
		return nil
	end

	return Humanoid.RootPart
end

function CharacterUtils.GetPlayerRootPart(Player)
	local Humanoid = CharacterUtils.GetPlayerHumanoid(Player)
	if not Humanoid then
		return nil
	end

	return Humanoid.RootPart
end

function CharacterUtils.UnequipTools(Player)
	local Humanoid = CharacterUtils.GetPlayerHumanoid(Player)
	if Humanoid then
		Humanoid:UnequipTools()
	end
end

--- Returns the Player and Character that a descendent is part of, if it is part of one.
-- @param descendant A child of the potential character.
-- @treturn Player player
-- @treturn Character character
function CharacterUtils.GetPlayerFromCharacter(Descendant)
	local Character = Descendant
	local Player = Players:GetPlayerFromCharacter(Character)

	while not Player do
		if Character.Parent then
			Character = Character.Parent
			Player = Players:GetPlayerFromCharacter(Character)
		else
			return nil
		end
	end

	return Player
end

return CharacterUtils