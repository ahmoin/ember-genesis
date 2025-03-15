--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Enemies = require(ServerStorage:WaitForChild("Enemies"))
local Constants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Constants"))
local Tools = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Tools"))

local remotes = ReplicatedStorage.Remotes
local activateToolRemote = remotes.ActivateTool

local function setCooldownOnFalse(tool: Tool)
	if tool and tool:IsDescendantOf(Workspace) then
		tool:SetAttribute(Constants.IS_ON_COOLDOWN_ATTRIBUTE, false)
	end
end

local function onActivateToolEvent(player: Player)
	print("onActivateToolEvent", player)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local rootPart = humanoid.RootPart
	if not rootPart then
		return
	end

	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then
		return
	end

	if tool:GetAttribute(Constants.IS_ON_COOLDOWN_ATTRIBUTE) then
		return
	end

	local toolTable = Tools[tool.Name]
	if type(toolTable) ~= "table" then
		return
	end

	local attackAnimations = toolTable.attackAnimations

	local currentAnimationIndex = tool:GetAttribute(Constants.ANIMATION_INDEX_ATTRIBUTE) or 0
	if type(currentAnimationIndex) ~= "number" then
		return
	end

	local newAnimationIndex = (currentAnimationIndex % #attackAnimations) + 1
	tool:SetAttribute(Constants.ANIMATION_INDEX_ATTRIBUTE, newAnimationIndex)

	tool:SetAttribute(Constants.IS_ON_COOLDOWN_ATTRIBUTE, true)
	local delayDuration = newAnimationIndex == 4 and 1 or 0.5
	task.delay(delayDuration, setCooldownOnFalse, tool)

	local enemiesDamaged = {}

	local hitboxSize = toolTable.hitboxSize
	local hitboxOffset = toolTable.hitboxOffset

	Enemies.doPlayerAttack(player, hitboxOffset, hitboxSize, enemiesDamaged)
end

local function initialize()
	activateToolRemote.OnServerEvent:Connect(onActivateToolEvent)
end

initialize()
