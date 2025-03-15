--!strict

local Specials = {}

Specials.specialMoves = {
	["Quick Tackle"] = { attackDuration = 1, doDash = true, specialIndex = 1 },
	["Ground Smash"] = { delayDuration = 0.35, linearVelocity = Vector3.new(0, 64, 0), specialIndex = 2 },
} :: {
	[string]: {
		delayDuration: number?,
		attackDuration: number,
		specialIndex: number,
		linearVelocity: Vector3?,
		doDash: boolean?,
	},
}

Specials.setValueAtIndex = function(specialIndex: number, newCooldown: number, cooldownString: string)
	local values = {}
	for value in string.gmatch(cooldownString, "[^,]+") do
		table.insert(values, tonumber(value))
	end

	if values[specialIndex] then
		values[specialIndex] = newCooldown
	end

	local newCooldownString = table.concat(values, ",")

	return newCooldownString
end

Specials.getValueAtIndex = function(specialIndex: number, cooldownString: string)
	local values = {}
	for value in string.gmatch(cooldownString, "[^,]+") do
		table.insert(values, tonumber(value))
	end

	return values[specialIndex]
end

return Specials
