--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Constants"))
local Specials = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Specials"))
local Enemies = require(ServerStorage.Enemies)

local remotes = ReplicatedStorage.Remotes
local useSpecialRemote = remotes.UseSpecial

local function onUseSpecialEvent(player: Player, index: number)
	local character = player.Character
	if not character then
		return
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then
		return
	end
	local actionAttribute = (index == 1 and Constants.SPECIAL_ONE_ATTRIBUTE)
		or (index == 2 and Constants.SPECIAL_TWO_ATTRIBUTE)
	if type(actionAttribute) ~= "string" then
		return
	end
	local action = tool:GetAttribute(actionAttribute)
	if type(action) ~= "string" then
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

	local enemiesDamaged = {}

	local specialTable = Specials.specialMoves[action]
	if type(specialTable) ~= "table" then
		return
	end

	local cooldownString = player:GetAttribute(Constants.SPECIAL_COOLDOWNS_ATTRIBUTE)
	if type(cooldownString) ~= "string" then
		cooldownString = Constants.DEFAULT_SPECIAL_COOLDOWNS_STRING
		player:SetAttribute(Constants.SPECIAL_COOLDOWNS_ATTRIBUTE, Constants.DEFAULT_SPECIAL_COOLDOWNS_STRING)
	end
	if type(cooldownString) ~= "string" then
		return
	end

	local specialIndex = specialTable.specialIndex
	local cooldownValue = tonumber(Specials.getValueAtIndex(specialIndex, cooldownString))
	if type(cooldownValue) ~= "number" then
		cooldownValue = 0
		local newCooldownString = Specials.setValueAtIndex(specialIndex, 0, cooldownString)
		player:SetAttribute(Constants.SPECIAL_COOLDOWNS_ATTRIBUTE, newCooldownString)
	end
	if type(cooldownValue) ~= "number" then
		return
	end
	if cooldownValue > 0 then
		return
	end

	local newCooldownString = Specials.setValueAtIndex(specialIndex, 5, cooldownString)
	player:SetAttribute(Constants.SPECIAL_COOLDOWNS_ATTRIBUTE, newCooldownString)

	local delayDuration = specialTable.delayDuration
	local attackDuration = specialTable.attackDuration
	local linearVelocity = specialTable.linearVelocity

	local hitboxSize = Vector3.new(12, 4, 16)
	if typeof(hitboxSize) ~= "Vector3" and type(hitboxSize) ~= "vector" then
		return
	end
	local hitboxOffset = CFrame.new(0, -3, -2)
	if typeof(hitboxOffset) ~= "CFrame" then
		return
	end

	if type(delayDuration) ~= "number" then
		Enemies.doPlayerAttack(player, hitboxOffset, hitboxSize, enemiesDamaged, attackDuration, linearVelocity)
		return
	end
	task.delay(
		delayDuration,
		Enemies.doPlayerAttack,
		player,
		hitboxOffset,
		hitboxSize,
		enemiesDamaged,
		attackDuration,
		linearVelocity
	)
end

local function onPlayerHeartbeat(player: Player, deltaTime: number)
	local cooldownString = player:GetAttribute(Constants.SPECIAL_COOLDOWNS_ATTRIBUTE)
	if type(cooldownString) ~= "string" then
		return
	end

	local newCooldownString = cooldownString
	local values = {} :: { number }
	for value in string.gmatch(cooldownString, "[^,]+") do
		local numberValue = tonumber(value)
		if type(numberValue) == "number" then
			table.insert(values, numberValue)
		end
	end

	for specialIndex, cooldownValue in values do
		if cooldownValue > 0 then
			values[specialIndex] = math.max(cooldownValue - deltaTime, 0)
		end
	end

	newCooldownString = table.concat(values, ",")

	player:SetAttribute(Constants.SPECIAL_COOLDOWNS_ATTRIBUTE, newCooldownString)
end

local function onHeartbeat(deltaTime: number)
	for _, player in Players:GetPlayers() do
		onPlayerHeartbeat(player, deltaTime)
	end
end

local function initialize()
	RunService.Heartbeat:Connect(onHeartbeat)
	useSpecialRemote.OnServerEvent:Connect(onUseSpecialEvent)
end

initialize()
