--!strict

local Levels = {}

function Levels.getLevel(exp: number): number
	local level = 1
	while exp >= (level - 1) * level * 50 do
		level += 1
	end
	return level - 1
end

function Levels.getExpForLevel(level: number): number
	return (level - 1) * level * 50
end

return Levels
