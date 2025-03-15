--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local animations = ReplicatedStorage:WaitForChild("Animations")
local combatIdleAnimation = animations:WaitForChild("CombatIdle")
local combatAttackOneAnimation = animations:WaitForChild("CombatAttackOne")
local combatAttackTwoAnimation = animations:WaitForChild("CombatAttackTwo")
local combatAttackThreeAnimation = animations:WaitForChild("CombatAttackThree")
local combatAttackFourAnimation = animations:WaitForChild("CombatAttackFour")

type Tool = {
	attackAnimations: { Animation },
	idleAnimation: Animation,
	specialOne: string,
	specialTwo: string,
	hitboxSize: Vector3,
	hitboxOffset: CFrame,
}

local Tools = {
	["Combat"] = {
		attackAnimations = {
			combatAttackOneAnimation,
			combatAttackTwoAnimation,
			combatAttackThreeAnimation,
			combatAttackFourAnimation,
		},
		idleAnimation = combatIdleAnimation,
		specialOne = "Quick Tackle",
		specialTwo = "Ground Smash",
		hitboxSize = Vector3.new(3, 3, 8),
		hitboxOffset = CFrame.new(0, 0, -6),
	},
} :: { [string]: Tool }

return Tools
