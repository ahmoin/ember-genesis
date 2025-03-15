--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tools = require(ReplicatedStorage.Modules.Tools)
local AnimationController = require(ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("AnimationController"))
local Constants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Constants"))

local player = Players.LocalPlayer

local remotes = ReplicatedStorage.Remotes
local activateToolRemote = remotes.ActivateTool

local backpackChildAddedConnection: RBXScriptConnection?
local toolActivatedConnection: RBXScriptConnection?

local function onToolActivated(tool: Tool)
	if tool:GetAttribute(Constants.IS_ON_COOLDOWN_ATTRIBUTE) then
		return
	end

	local toolTable = Tools[tool.Name]
	if type(toolTable) ~= "table" then
		return
	end

	local attackAnimations = toolTable.attackAnimations
	if type(attackAnimations) ~= "table" or #attackAnimations < 1 then
		return
	end
	local currentAnimationIndex = tool:GetAttribute(Constants.ANIMATION_INDEX_ATTRIBUTE) or 0
	if type(currentAnimationIndex) ~= "number" then
		return
	end

	local newAnimationIndex = (currentAnimationIndex % #attackAnimations) + 1
	local attackAnimation = attackAnimations[newAnimationIndex]
	if not attackAnimation or not attackAnimation:IsA("Animation") then
		return
	end

	activateToolRemote:FireServer()

	AnimationController.playAnimation(attackAnimation)
end

local function onChildAdded(child: Instance)
	if not child:IsA("Tool") then
		return
	end

	local toolTable = Tools[child.Name]
	if type(toolTable) ~= "table" then
		return
	end

	local idleAnimation = toolTable.idleAnimation
	local attackAnimations = toolTable.attackAnimations

	for _, attackAnimation in attackAnimations do
		AnimationController.loadAnimation(attackAnimation)
	end

	if toolActivatedConnection then
		toolActivatedConnection:Disconnect()
	end
	toolActivatedConnection = child.Activated:Connect(function()
		onToolActivated(child)
	end)

	AnimationController.playAnimation(idleAnimation)
end

local function onBackpackChildAdded(child: Instance)
	if not child:IsA("Tool") then
		return
	end

	local toolTable = Tools[child.Name]
	if type(toolTable) ~= "table" then
		return
	end

	local idleAnimation = toolTable.idleAnimation

	AnimationController.stopAnimation(idleAnimation)
end

local function onCharacterAdded(character: Model)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack and backpack:IsA("Backpack") then
		for _, child in backpack:GetChildren() do
			task.spawn(onBackpackChildAdded, child)
		end
		if backpackChildAddedConnection then
			backpackChildAddedConnection:Disconnect()
		end
		backpackChildAddedConnection = backpack.ChildAdded:Connect(onBackpackChildAdded)
	end

	for _, child in character:GetChildren() do
		task.spawn(onChildAdded, child)
	end

	character.ChildAdded:Connect(onChildAdded)
end

local function initialize()
	local character = player.Character
	if character then
		onCharacterAdded(character)
	end

	player.CharacterAdded:Connect(onCharacterAdded)
end

initialize()
