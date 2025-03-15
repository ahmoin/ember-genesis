--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local enemyTemplates = ServerStorage:WaitForChild("EnemyTemplates")

local animations = ReplicatedStorage:WaitForChild("Animations")
local spearAttackOneAnimation = animations:WaitForChild("SpearAttackOne")
local spearAttackTwoAnimation = animations:WaitForChild("SpearAttackTwo")
local spearAttackThreeAnimation = animations:WaitForChild("SpearAttackThree")
local spearAttackFourAnimation = animations:WaitForChild("SpearAttackFour")
local spearAttackFiveAnimation = animations:WaitForChild("SpearAttackFive")
local spearIdle = animations:WaitForChild("SpearIdle")

local enemies = Workspace:WaitForChild("Enemies")

local enemiesOverlapParameters = OverlapParams.new()
enemiesOverlapParameters.FilterType = Enum.RaycastFilterType.Include
enemiesOverlapParameters.FilterDescendantsInstances = { enemies }

local charactersOverlapParameters = OverlapParams.new()
charactersOverlapParameters.FilterType = Enum.RaycastFilterType.Include
charactersOverlapParameters.FilterDescendantsInstances = {}

local Constants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Constants"))
local Quests = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Quests"))

local Enemies = {}

type Enemy = {
	damage: number,
	exp: number,
	questId: number,
	respawnTime: number,
	idleAnimation: Animation,
	hitboxSize: Vector3,
	hitboxOffset: CFrame,
	attackDelays: { number },
	attackDurations: { number },
	swingCooldowns: { number },
	attackAnimations: { Animation },
}

Enemies.enemyTemplates = {
	["Brigand"] = {
		damage = 16,
		exp = 5,
		questId = 1,
		respawnTime = 16,
		idleAnimation = spearIdle,
		hitboxSize = Vector3.new(3, 3, 6),
		hitboxOffset = CFrame.new(0, 0, -2),
		attackDelays = { 0.3, 0.3, 0.3, 0.5, 0.6 },
		attackDurations = { 0.7, 0.7, 0.7, 0.5, 0.9 },
		swingCooldowns = { 1.1, 1.17, 1.15, 1.2, 1.7 },
		attackAnimations = {
			spearAttackOneAnimation,
			spearAttackTwoAnimation,
			spearAttackThreeAnimation,
			spearAttackFourAnimation,
			spearAttackFiveAnimation,
		},
	},
	["Wandering Mage"] = {
		damage = 48,
		exp = 50,
		questId = 2,
		respawnTime = 16,
		idleAnimation = spearIdle,
		hitboxSize = Vector3.new(3, 3, 8),
		hitboxOffset = CFrame.new(0, 0, -6),
		attackDelays = { 0.3, 0.3, 0.3, 0.5, 0.6 },
		attackDurations = { 0.7, 0.7, 0.7, 0.5, 0.9 },
		swingCooldowns = { 1.1, 1.17, 1.15, 1.2, 1.7 },
		attackAnimations = {
			spearAttackOneAnimation,
			spearAttackTwoAnimation,
			spearAttackThreeAnimation,
			spearAttackFourAnimation,
			spearAttackFiveAnimation,
		},
	},
	["Bjorn"] = {
		damage = 64,
		exp = 100000,
		questId = 1,
		respawnTime = -1,
		idleAnimation = spearIdle,
		hitboxSize = Vector3.new(16, 16, 16),
		hitboxOffset = CFrame.new(0, 0, -6),
		attackDelays = { 0.3, 0.3, 0.3, 0.5, 0.6 },
		attackDurations = { 0.7, 0.7, 0.7, 0.5, 0.9 },
		swingCooldowns = { 1.1, 1.17, 1.15, 1.2, 1.7 },
		attackAnimations = {
			spearAttackOneAnimation,
			spearAttackTwoAnimation,
			spearAttackThreeAnimation,
			spearAttackFourAnimation,
			spearAttackFiveAnimation,
		},
	},
} :: {
	[string]: Enemy,
}

Enemies.respawnEnemy = function(enemyName: string, position: Vector3, orientation: Vector3)
	local enemyTemplate = enemyTemplates:FindFirstChild(enemyName)
	if not enemyTemplate or not enemyTemplate:IsA("Model") then
		return
	end

	local enemyTable = Enemies.enemyTemplates[enemyName]
	if type(enemyTable) ~= "table" then
		return
	end

	local respawnTime = enemyTable.respawnTime
	if respawnTime == -1 then
		return
	end

	local enemy = enemyTemplate:Clone()
	local positionCFrame = CFrame.new(position)
	local orientationX, orientationY, orientationZ =
		math.rad(orientation.X), math.rad(orientation.Y), math.rad(orientation.Z)
	local orientationCFrame = CFrame.fromOrientation(orientationX, orientationY, orientationZ)
	local pivot = positionCFrame * orientationCFrame
	enemy:SetAttribute(Constants.INITIAL_POSITION_ATTRIBUTE, position)
	enemy:SetAttribute(Constants.INITIAL_ORIENTATION_ATTRIBUTE, orientation)
	enemy:PivotTo(pivot)
	enemy.Parent = enemies
end

Enemies.getWorldAttachment = function(enemy: Instance)
	local id = enemy:GetAttribute(Constants.ID_ATTRIBUTE)
	if type(id) ~= "number" then
		return nil
	end
	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	if not terrain then
		return nil
	end

	return terrain:FindFirstChild(tostring(id))
end

local function doQuestProgress(player: Player, questId: number)
	local currentQuestProgress = player:GetAttribute(Constants.QUEST_PROGRESS_ATTRIBUTE) or 0
	if type(currentQuestProgress) ~= "number" then
		return
	end

	local quest = Quests[questId]
	if not quest then
		return
	end

	local amount = quest.amount
	if type(amount) ~= "number" then
		return
	end

	local newQuestProgress = currentQuestProgress + 1
	if newQuestProgress >= amount then
		player:SetAttribute(Constants.QUEST_ID_ATTRIBUTE, -1)
		player:SetAttribute(Constants.QUEST_PROGRESS_ATTRIBUTE, 0)

		local questExp = quest.exp
		if type(questExp) ~= "number" then
			return
		end

		local currentExp = player:GetAttribute(Constants.EXP_ATTRIBUTE) or 0
		if type(currentExp) ~= "number" then
			return
		end

		local newExp = currentExp + questExp
		player:SetAttribute(Constants.EXP_ATTRIBUTE, newExp)
		return
	end

	player:SetAttribute(Constants.QUEST_PROGRESS_ATTRIBUTE, newQuestProgress)
end

local function doEnemyExp(player: Player, enemy: Instance)
	local enemyTable = Enemies.enemyTemplates[enemy.Name]
	if type(enemyTable) ~= "table" then
		return
	end

	local enemyExp = enemyTable.exp

	local currentExp = player:GetAttribute(Constants.EXP_ATTRIBUTE) or 0
	if type(currentExp) ~= "number" then
		return
	end

	local newExp = currentExp + enemyExp
	player:SetAttribute(Constants.EXP_ATTRIBUTE, newExp)
end

local function onEnemyDeath(enemy: Instance, rootPart: BasePart, player: Player)
	if enemy:GetAttribute(Constants.IS_DEAD_ATTRIBUTE) then
		return
	end

	enemy:SetAttribute(Constants.IS_DEAD_ATTRIBUTE, true)

	doEnemyExp(player, enemy)

	local enemyTable = Enemies.enemyTemplates[enemy.Name]
	if type(enemyTable) ~= "table" then
		return
	end
	local enemyQuestId = enemyTable.questId

	local playerQuestId = player:GetAttribute(Constants.QUEST_ID_ATTRIBUTE)
	if type(enemyQuestId) == "number" and type(playerQuestId) == "number" and enemyQuestId == playerQuestId then
		doQuestProgress(player, enemyQuestId)
	end

	local deathParticles = rootPart:FindFirstChild("DeathParticles")
	if deathParticles and deathParticles:IsA("ParticleEmitter") then
		deathParticles:Emit(deathParticles.Rate)
	end
	local worldAttachment = Enemies.getWorldAttachment(enemy)
	if worldAttachment then
		worldAttachment:Destroy()
	end
	task.delay(Constants.ENEMEY_DESTROY_DELAY_DURATION, function()
		enemy:Destroy()
	end)
	local initialPosition = enemy:GetAttribute(Constants.INITIAL_POSITION_ATTRIBUTE)
	if typeof(initialPosition) ~= "Vector3" and type(initialPosition) ~= "vector" then
		return
	end

	local initialOrientation = enemy:GetAttribute(Constants.INITIAL_ORIENTATION_ATTRIBUTE)
	if typeof(initialOrientation) ~= "Vector3" and type(initialOrientation) ~= "vector" then
		return
	end

	task.delay(
		Constants.ENEMY_RESPAWN_DELAY_DURATION,
		Enemies.respawnEnemy,
		enemy.Name,
		initialPosition,
		initialOrientation
	)
end

local function updateCharacterOverlapParameters()
	local characters = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character or not character:IsDescendantOf(Workspace) then
			continue
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			continue
		end

		local rootPart = humanoid.RootPart
		if not rootPart then
			continue
		end

		table.insert(characters, rootPart)
	end
	charactersOverlapParameters.FilterDescendantsInstances = characters
end

local function onEnemyPartInHitbox(
	part: BasePart,
	enemiesDamaged: { Instance },
	player: Player,
	linearVelocity: Vector3?
)
	local parent = part.Parent
	if not parent or not parent:IsDescendantOf(Workspace) then
		return
	end

	if table.find(enemiesDamaged, parent) then
		return
	end

	local humanoid = parent:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local rootPart = humanoid.RootPart
	if not rootPart then
		return
	end

	table.insert(enemiesDamaged, parent)

	if linearVelocity then
		rootPart.AssemblyLinearVelocity = linearVelocity
	end

	local hitParticles = rootPart:FindFirstChild("HitParticles")
	if hitParticles and hitParticles:IsA("ParticleEmitter") then
		hitParticles:Emit(hitParticles.Rate)
	end

	local statPointsInMelee = player:GetAttribute("meleeStat") or 0
	if type(statPointsInMelee) ~= "number" then
		return
	end

	local damage = statPointsInMelee + 16
	local isGoingToDie = humanoid.Health - damage <= 0
	humanoid:TakeDamage(damage)

	local userId = player.UserId

	if isGoingToDie then
		onEnemyDeath(parent, rootPart, player)
	else
		parent:SetAttribute(Constants.AGGROED_PLAYER_USER_ID_ATTRIBUTE, userId)
	end
end

local function onPlayerPartInHitbox(part: BasePart, playersDamaged: { Player }, enemy: Instance)
	local parent = part.Parent
	if not parent or not parent:IsDescendantOf(Workspace) then
		return
	end

	local player = Players:GetPlayerFromCharacter(parent)
	if not player then
		return
	end

	if table.find(playersDamaged, player) then
		return
	end

	local humanoid = parent:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local rootPart = humanoid.RootPart
	if not rootPart then
		return
	end

	table.insert(playersDamaged, player)

	local enemyTable = Enemies.enemyTemplates[enemy.Name]
	if type(enemyTable) ~= "table" then
		return
	end

	local damage = enemyTable.damage

	humanoid:TakeDamage(damage)

	enemy:SetAttribute(Constants.AGGROED_PLAYER_USER_ID_ATTRIBUTE, player.UserId)
end

Enemies.doPlayerAttack = function(
	player: Player,
	hitboxOffset: CFrame,
	hitboxSize: Vector3,
	enemiesDamaged: { Instance },
	attackDuration: number?,
	linearVelocity: Vector3?
)
	if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	local playerHumanoid = character:FindFirstChildOfClass("Humanoid")
	if not playerHumanoid or playerHumanoid.Health <= 0 then
		return
	end
	local playerRootPart = playerHumanoid.RootPart
	if not playerRootPart then
		return
	end

	local hitboxPart = Instance.new("Part")
	hitboxPart.Size = hitboxSize
	hitboxPart.CFrame = playerRootPart.CFrame * hitboxOffset
	hitboxPart.Anchored = true
	hitboxPart.CanCollide = false
	hitboxPart.Transparency = 0.5
	hitboxPart.Color = Color3.new(1, 0, 0)
	hitboxPart.Parent = Workspace
	task.delay((attackDuration == 0 or not attackDuration) and 1 or attackDuration, function()
		hitboxPart:Destroy()
	end)
	if not attackDuration or attackDuration == 0 then
		local partsInBox =
			Workspace:GetPartBoundsInBox(playerRootPart.CFrame * hitboxOffset, hitboxSize, enemiesOverlapParameters)
		for _, part in partsInBox do
			onEnemyPartInHitbox(part, enemiesDamaged, player, linearVelocity)
		end
		return
	end

	local heartbeatConnection = nil :: RBXScriptConnection?
	local runningTime = 0

	heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
		runningTime += deltaTime

		if
			typeof(player) ~= "Instance"
			or player.Parent ~= Players
			or typeof(character) ~= "Instance"
			or character.Parent ~= Workspace
			or typeof(playerHumanoid) ~= "Instance"
			or playerHumanoid.Health <= 0
			or playerHumanoid.Parent ~= character
			or typeof(playerRootPart) ~= "Instance"
		then
			if typeof(heartbeatConnection) == "RBXScriptConnection" then
				heartbeatConnection:Disconnect()
			end
			heartbeatConnection = nil
			return
		end

		hitboxPart.CFrame = playerRootPart.CFrame * hitboxOffset

		local partsInBox =
			Workspace:GetPartBoundsInBox(playerRootPart.CFrame * hitboxOffset, hitboxSize, enemiesOverlapParameters)
		for _, part in partsInBox do
			onEnemyPartInHitbox(part, enemiesDamaged, player, linearVelocity)
		end

		if runningTime > attackDuration then
			if typeof(heartbeatConnection) == "RBXScriptConnection" then
				heartbeatConnection:Disconnect()
			end
			heartbeatConnection = nil
			return
		end
	end)
end

Enemies.doEnemyAttack = function(
	enemy: Instance,
	hitboxOffset: CFrame,
	hitboxSize: Vector3,
	playersDamaged: { Player },
	attackDuration: number?
)
	local enemyHumanoid = enemy:FindFirstChildOfClass("Humanoid")
	if not enemyHumanoid or enemyHumanoid.Health <= 0 then
		return
	end
	local enemyRootPart = enemyHumanoid.RootPart
	if not enemyRootPart then
		return
	end

	updateCharacterOverlapParameters()

	local hitboxPart = Instance.new("Part")
	hitboxPart.Size = hitboxSize
	hitboxPart.CFrame = enemyRootPart.CFrame * hitboxOffset
	hitboxPart.Anchored = true
	hitboxPart.CanCollide = false
	hitboxPart.Transparency = 0.5
	hitboxPart.Color = Color3.new(1, 0, 0)
	hitboxPart.Parent = Workspace
	task.delay((attackDuration == 0 or not attackDuration) and 1 or attackDuration, function()
		hitboxPart:Destroy()
	end)

	if not attackDuration or attackDuration == 0 then
		local partsInBox =
			Workspace:GetPartBoundsInBox(enemyRootPart.CFrame * hitboxOffset, hitboxSize, charactersOverlapParameters)
		for _, part in partsInBox do
			onPlayerPartInHitbox(part, playersDamaged, enemy)
		end
		return
	end

	local heartbeatConnection = nil :: RBXScriptConnection?
	local runningTime = 0

	heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
		runningTime += deltaTime

		if
			typeof(enemy) ~= "Instance"
			or enemy.Parent ~= enemies
			or typeof(enemyHumanoid) ~= "Instance"
			or enemyHumanoid.Health <= 0
			or enemyHumanoid.Parent ~= enemy
			or typeof(enemyRootPart) ~= "Instance"
		then
			if typeof(heartbeatConnection) == "RBXScriptConnection" then
				heartbeatConnection:Disconnect()
			end
			heartbeatConnection = nil
			return
		end

		hitboxPart.CFrame = enemyRootPart.CFrame * hitboxOffset

		local partsInBox =
			Workspace:GetPartBoundsInBox(enemyRootPart.CFrame * hitboxOffset, hitboxSize, charactersOverlapParameters)
		for _, part in partsInBox do
			onPlayerPartInHitbox(part, playersDamaged, enemy)
		end

		if runningTime > attackDuration then
			if typeof(heartbeatConnection) == "RBXScriptConnection" then
				heartbeatConnection:Disconnect()
			end
			heartbeatConnection = nil
			return
		end
	end)
end

return Enemies
