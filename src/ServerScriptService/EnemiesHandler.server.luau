--!strict

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Constants"))
local Enemies = require(ServerStorage.Enemies)

local enemies = Workspace:WaitForChild("Enemies")
local npcs = Workspace:WaitForChild("NPCs")
local enemyTemplates = ServerStorage.EnemyTemplates

local mapRaycastParameters = RaycastParams.new()
mapRaycastParameters.FilterType = Enum.RaycastFilterType.Include
mapRaycastParameters.FilterDescendantsInstances = { Workspace:WaitForChild("Islands") }

local cachedAnimations = {} :: { [Instance]: { [Animation]: AnimationTrack } }

local random = Random.new()

local function cleanupCachedAnimations()
	for enemy, _ in cachedAnimations do
		if not enemy:IsDescendantOf(Workspace) then
			cachedAnimations[enemy] = nil
		end
	end
end

local function onAggroedPlayerHeartbeat(enemy: Instance, userId: number)
	local player = Players:GetPlayerByUserId(userId)
	if not player then
		enemy:SetAttribute(Constants.AGGROED_PLAYER_USER_ID_ATTRIBUTE, 0)
		return
	end
	local character = player.Character
	if not character or not character:IsDescendantOf(Workspace) then
		enemy:SetAttribute(Constants.AGGROED_PLAYER_USER_ID_ATTRIBUTE, 0)
		return
	end

	local playerHumanoid = character:FindFirstChildOfClass("Humanoid")
	if not playerHumanoid or playerHumanoid.Health <= 0 then
		enemy:SetAttribute(Constants.AGGROED_PLAYER_USER_ID_ATTRIBUTE, 0)
		return
	end
	local playerRootPart = playerHumanoid.RootPart
	if not playerRootPart or not playerRootPart:IsDescendantOf(Workspace) then
		enemy:SetAttribute(Constants.AGGROED_PLAYER_USER_ID_ATTRIBUTE, 0)
		return
	end

	local enemyHumanoid = enemy:FindFirstChildOfClass("Humanoid")
	if not enemyHumanoid then
		return
	end
	if enemyHumanoid.Health <= 0 then
		return
	end
	local enemyRootPart = enemyHumanoid.RootPart
	if not enemyRootPart then
		return
	end
	local enemyRootRigAttachment = enemyRootPart:FindFirstChild("RootRigAttachment")
	if not enemyRootRigAttachment or not enemyRootRigAttachment:IsA("Attachment") then
		return
	end

	local worldAttachment = Enemies.getWorldAttachment(enemy)
	if not worldAttachment or not worldAttachment:IsDescendantOf(Workspace) then
		local terrain = Workspace:FindFirstChildOfClass("Terrain")
		if terrain then
			local newAttachment = Instance.new("Attachment")
			local id = random:NextNumber()
			newAttachment.Name = tostring(id)
			enemy:SetAttribute(Constants.ID_ATTRIBUTE, id)
			newAttachment.Parent = terrain
		end
		return
	end
	local alignOrientation = enemyRootPart:FindFirstChildOfClass("AlignOrientation")
	if not alignOrientation then
		local newAlignOrientation = Instance.new("AlignOrientation")
		newAlignOrientation.Enabled = false
		newAlignOrientation.Mode = Enum.OrientationAlignmentMode.TwoAttachment
		newAlignOrientation.PrimaryAxisOnly = true
		newAlignOrientation.ReactionTorqueEnabled = false
		newAlignOrientation.RigidityEnabled = true
		newAlignOrientation.Attachment0 = enemyRootRigAttachment
		newAlignOrientation.Attachment1 = worldAttachment
		newAlignOrientation.Parent = enemyRootPart
		alignOrientation = newAlignOrientation
	end
	if not alignOrientation then
		return
	end

	local lookVector = playerRootPart.CFrame.LookVector
	alignOrientation.Enabled = true
	worldAttachment.CFrame = CFrame.new(enemyRootPart.Position, playerRootPart.Position)
	-- TODO: add different movement types
	-- local offsetVector = (lookVector * 6):Cross(Vector3.yAxis)
	local offsetVector = lookVector * 4
	local newPosition = playerRootPart.Position + offsetVector
	local raycastResult = Workspace:Raycast(newPosition, Vector3.new(0, -32, 0), mapRaycastParameters)
	if raycastResult and raycastResult.Instance then
		enemyHumanoid:MoveTo(newPosition)
	end

	local playersDamaged = {}

	if enemy:GetAttribute(Constants.IS_ON_COOLDOWN_ATTRIBUTE) then
		return
	end

	local enemyTable = Enemies.enemyTemplates[enemy.Name]
	if type(enemyTable) ~= "table" then
		return
	end

	local attackAnimations = enemyTable.attackAnimations

	local currentAnimationIndex = enemy:GetAttribute(Constants.ANIMATION_INDEX_ATTRIBUTE) or 0
	if type(currentAnimationIndex) ~= "number" then
		return
	end

	local newAnimationIndex = (currentAnimationIndex % #attackAnimations) + 1
	enemy:SetAttribute(Constants.ANIMATION_INDEX_ATTRIBUTE, newAnimationIndex)

	enemy:SetAttribute(Constants.IS_ON_COOLDOWN_ATTRIBUTE, true)
	local swingCooldowns = enemyTable.swingCooldowns
	local swingCooldown = swingCooldowns[newAnimationIndex] or swingCooldowns[#swingCooldowns]
	print(swingCooldown)
	task.delay(swingCooldown, function()
		enemy:SetAttribute(Constants.IS_ON_COOLDOWN_ATTRIBUTE, false)
	end)

	local hitboxSize = enemyTable.hitboxSize
	local hitboxOffset = enemyTable.hitboxOffset

	local enemyCachedAnimations = cachedAnimations[enemy] or {}
	cachedAnimations[enemy] = enemyCachedAnimations
	cleanupCachedAnimations()

	local attackAnimation = attackAnimations[newAnimationIndex]
	local animator = enemyHumanoid:FindFirstChildOfClass("Animator")
	if attackAnimation and attackAnimation:IsA("Animation") and animator then
		local cachedAnimation = cachedAnimations[enemy][attackAnimation]
		if cachedAnimation then
			cachedAnimation:Play()
		else
			local loadedAnimation = animator:LoadAnimation(attackAnimation)
			cachedAnimations[enemy][attackAnimation] = loadedAnimation
			loadedAnimation:Play()
		end
	end

	local attackDelays = enemyTable.attackDelays
	local attackDelay = attackDelays[newAnimationIndex] or attackDelays[#attackDelays]

	local attackDurations = enemyTable.attackDurations
	local attackDuration = attackDurations[newAnimationIndex] or attackDurations[#attackDurations]

	task.delay(attackDelay, Enemies.doEnemyAttack, enemy, hitboxOffset, hitboxSize, playersDamaged, attackDuration)
end

local function onEnemyHeartbeat(enemy: Instance)
	local initialPosition = enemy:GetAttribute(Constants.INITIAL_POSITION_ATTRIBUTE)
	local initialOrientation = enemy:GetAttribute(Constants.INITIAL_ORIENTATION_ATTRIBUTE)

	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	if not humanoid or not humanoid:IsDescendantOf(Workspace) then
		enemy:Destroy()
		if
			(typeof(initialPosition) == "Vector3" or type(initialPosition) == "vector")
			and (typeof(initialOrientation) == "Vector3" or type(initialOrientation) == "vector")
		then
			task.delay(Constants.ENEMY_RESPAWN_DELAY_DURATION, Enemies.respawnEnemy, enemy.Name, initialPosition, initialOrientation)
		end
		return
	end

	local rootPart = humanoid.RootPart

	if not rootPart or not rootPart:IsDescendantOf(Workspace) then
		enemy:Destroy()
		if
			(typeof(initialPosition) == "Vector3" or type(initialPosition) == "vector")
			and (typeof(initialOrientation) == "Vector3" or type(initialOrientation) == "vector")
		then
			task.delay(Constants.ENEMY_RESPAWN_DELAY_DURATION, Enemies.respawnEnemy, enemy.Name, initialPosition, initialOrientation)
		end
		return
	end

	if typeof(initialPosition) ~= "Vector3" and type(initialPosition) ~= "vector" then
		enemy:SetAttribute(Constants.INITIAL_POSITION_ATTRIBUTE, rootPart.Position)
	end

	if typeof(initialOrientation) ~= "Vector3" and type(initialOrientation) ~= "vector" then
		enemy:SetAttribute(Constants.INITIAL_ORIENTATION_ATTRIBUTE, rootPart.Orientation)
	end

	local aggroedPlayerUserId = enemy:GetAttribute(Constants.AGGROED_PLAYER_USER_ID_ATTRIBUTE)
	if type(aggroedPlayerUserId) == "number" then
		onAggroedPlayerHeartbeat(enemy, aggroedPlayerUserId)
	end

	local head = enemy:FindFirstChild("Head")
	if not head then
		return
	end

	local billboardGui = head:FindFirstChildOfClass("BillboardGui")
	if not billboardGui then
		return
	end

	local healthFrame = billboardGui:FindFirstChild("HealthFrame")
	if not healthFrame or not healthFrame:IsA("GuiObject") then
		return
	end

	healthFrame.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 0.3, 0)
end

-- TODO: add a better way to enemy and npc idle animations
local function onNPCDescendantAdded(npc: Instance, descendant: Instance): AnimationTrack?
	if descendant:IsA("BasePart") then
		descendant:SetNetworkOwner(nil)
		return nil
	end

	if not descendant:IsA("Animator") then
		return nil
	end

	local npcTable = Enemies.enemyTemplates[npc.Name]
	if type(npcTable) ~= "table" then
		return
	end

	local idleAnimation = npcTable.idleAnimation

	local loadedAnimation = descendant:LoadAnimation(idleAnimation)
	loadedAnimation:Play()

	return loadedAnimation
end

local function onNPCAdded(npc: Instance)
	for _, descendant in npc:GetDescendants() do
		local loadedAnimation = onNPCDescendantAdded(npc, descendant)
		if not loadedAnimation then
			continue
		end

		npc:GetAttributeChangedSignal(Constants.AGGROED_PLAYER_USER_ID_ATTRIBUTE):Once(function()
			loadedAnimation:Stop()
		end)
	end

	npc.DescendantAdded:Connect(function(descendant: Instance)
		local loadedAnimation = onNPCDescendantAdded(npc, descendant)
		if loadedAnimation then
			npc:GetAttributeChangedSignal(Constants.AGGROED_PLAYER_USER_ID_ATTRIBUTE):Once(function()
				loadedAnimation:Stop()
			end)
		end
	end)
end

local function onHeartbeat()
	for _, enemy in enemies:GetChildren() do
		onEnemyHeartbeat(enemy)
	end
end

local function onCharacterAdded(character: Model)
	character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = Constants.CHARACTER_COLLISION_GROUP
		end
	end)

	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = Constants.CHARACTER_COLLISION_GROUP
		end
	end
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)

	if player.Character then
		onCharacterAdded(player.Character)
	end
end

local function initialize()
	PhysicsService:RegisterCollisionGroup(Constants.CHARACTER_COLLISION_GROUP)
	PhysicsService:RegisterCollisionGroup(Constants.NPC_COLLISION_GROUP)

	PhysicsService:CollisionGroupSetCollidable(
		Constants.CHARACTER_COLLISION_GROUP,
		Constants.CHARACTER_COLLISION_GROUP,
		false
	)
	PhysicsService:CollisionGroupSetCollidable(
		Constants.NPC_COLLISION_GROUP,
		Constants.CHARACTER_COLLISION_GROUP,
		false
	)
	PhysicsService:CollisionGroupSetCollidable(Constants.NPC_COLLISION_GROUP, Constants.NPC_COLLISION_GROUP, false)

	for _, enemy in enemies:GetChildren() do
		onNPCAdded(enemy)
	end
	for _, npc in npcs:GetChildren() do
		onNPCAdded(npc)
	end

	for _, descendant in enemies:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = Constants.NPC_COLLISION_GROUP
		end
	end
	for _, descendant in enemyTemplates:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = Constants.NPC_COLLISION_GROUP
		end
	end
	for _, descendant in npcs:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = Constants.NPC_COLLISION_GROUP
		end
	end

	enemies.ChildAdded:Connect(onNPCAdded)
	RunService.Heartbeat:Connect(onHeartbeat)

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
end

initialize()
