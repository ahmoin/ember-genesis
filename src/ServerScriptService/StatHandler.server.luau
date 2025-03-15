--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Constants"))
local Levels = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Levels"))

local remotes = ReplicatedStorage.Remotes
local refundStatsRemote = remotes.RefundStats
local spendStatsRemote = remotes.SpendStatPoints

local function onRefundStats(player: Player)
	local exp = player:GetAttribute(Constants.EXP_ATTRIBUTE)
	if type(exp) ~= "number" then
		return
	end
	local playerLevel = Levels.getLevel(exp)
	if type(playerLevel) ~= "number" then
		return
	end
	player:SetAttribute(Constants.STAT_POINTS_ATTRIBUTE, playerLevel * 3)
	player:SetAttribute("meleeStat", 0)
	player:SetAttribute("defenseStat", 0)
	player:SetAttribute("swordStat", 0)
	player:SetAttribute("gunStat", 0)
	player:SetAttribute("fruitStat", 0)
end

local function onSpendStats(player: Player, statType: number, amount: number)
	local statName = statType == 1 and "Melee"
		or statType == 2 and "Defense"
		or statType == 3 and "Sword"
		or statType == 4 and "Gun"
		or statType == 5 and "Fruit"
	if type(statName) ~= "string" then
		return
	end

	local statAttribute = statName:lower() .. "Stat"
	local statValue = player:GetAttribute(statAttribute) or 0
	if type(statValue) ~= "number" then
		return
	end

	local statPointsAvailable = player:GetAttribute(Constants.STAT_POINTS_ATTRIBUTE)
	if type(statPointsAvailable) ~= "number" then
		return
	end

	if statPointsAvailable < amount then
		amount = statPointsAvailable
	end

	if statPointsAvailable - amount < 0 then
		return
	end

	if amount < 0 then
		return
	end

	if statValue + amount > Constants.MAX_LEVEL then
		amount = Constants.MAX_LEVEL - statValue
	end

	player:SetAttribute(Constants.STAT_POINTS_ATTRIBUTE, statPointsAvailable - amount)
	local newAmount = statValue + amount
	player:SetAttribute(statAttribute, newAmount)
	if statAttribute ~= "defenseState" then
		return
	end
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local isAlreadyMaxHealth = humanoid.Health == humanoid.MaxHealth
	local maxHealth = 100 + (newAmount + 1) * 10
	humanoid.MaxHealth = maxHealth
	if isAlreadyMaxHealth then
		humanoid.Health = maxHealth
	end
end

local function onPlayerHeartbeat(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local statPointsInDefense = player:GetAttribute("defenseStat") or 0
	if type(statPointsInDefense) ~= "number" then
		return
	end

	local maxHealth = 100 + (statPointsInDefense + 1) * 10
	humanoid.MaxHealth = maxHealth
end

local function onHeartbeat()
	for _, player in Players:GetPlayers() do
		onPlayerHeartbeat(player)
	end
end

local function initialize()
	refundStatsRemote.OnServerEvent:Connect(onRefundStats)
	spendStatsRemote.OnServerEvent:Connect(onSpendStats)
	RunService.Heartbeat:Connect(onHeartbeat)
end

initialize()
