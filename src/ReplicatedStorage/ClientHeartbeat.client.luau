--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local AnimationController = require(ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("AnimationController"))
local CharacterAnimate = require(ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("CharacterAnimate"))
local Constants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Constants"))

local animations = ReplicatedStorage:WaitForChild("Animations")
local frontDashAnimation = animations:WaitForChild("FrontDash")
local backDashAnimation = animations:WaitForChild("BackDash")
local leftDashAnimation = animations:WaitForChild("LeftDash")
local rightDashAnimation = animations:WaitForChild("RightDash")

local player = Players.LocalPlayer

local function setupAlignOrientation(alignOrientation: AlignOrientation)
	if alignOrientation.Attachment0 then
		return
	end

	alignOrientation.Enabled = false
	alignOrientation.MaxTorque = math.huge
	alignOrientation.MaxAngularVelocity = math.huge
	alignOrientation.RigidityEnabled = true
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	local parent = alignOrientation.Parent
	if not parent then
		return
	end

	local rootRigAttachment = parent:FindFirstChild("RootRigAttachment")
	if not rootRigAttachment or not rootRigAttachment:IsA("Attachment") then
		return
	end

	alignOrientation.Attachment0 = rootRigAttachment
end

local function setupPlaneConstraint(planeConstraint: PlaneConstraint)
	local parent = planeConstraint.Parent
	if not parent then
		return
	end

	local parentsParent = parent.Parent
	if not parentsParent then
		return
	end

	local humanoid = parentsParent:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local waterAttachment = parent:FindFirstChild(Constants.WATER_ATTACHMENT_NAME)
	if not waterAttachment or not waterAttachment:IsA("Attachment") then
		local newWaterAttachment = Instance.new("Attachment")
		newWaterAttachment.Name = Constants.WATER_ATTACHMENT_NAME
		newWaterAttachment.Parent = parent
		waterAttachment = newWaterAttachment
	end
	if not waterAttachment or not waterAttachment:IsA("Attachment") then
		return
	end

	local waterModel = Workspace:FindFirstChild(Constants.WATER_MODEL_NAME)
	if not waterModel then
		return
	end

	local waterPart = waterModel:FindFirstChildWhichIsA("BasePart")
	if not waterPart then
		return
	end

	local attachment0 = waterPart:FindFirstChildOfClass("Attachment")
	if not attachment0 then
		return
	end

	planeConstraint.Attachment0 = attachment0
	planeConstraint.Attachment1 = waterAttachment
	local isInWater = waterAttachment.WorldPosition.Y < attachment0.WorldPosition.Y
	local shouldEnable = isInWater and not planeConstraint:GetAttribute(Constants.DISABLED_ATTRIBUTE)
	planeConstraint.Enabled = shouldEnable
end

local function onNPCHeartbeat(npc: Instance)
	local isAnimating = npc:GetAttribute(Constants.IS_ANIMATING_ATTRIBUTE)
	if isAnimating then
		return
	end

	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	npc:SetAttribute(Constants.IS_ANIMATING_ATTRIBUTE, true)
	CharacterAnimate.animate(humanoid, humanoid, nil)
end

local function getClosestZoneHitboxToRootPart(rootPart: BasePart): BasePart?
	local zoneHitboxes = Workspace:FindFirstChild("ZoneHitboxes")
	if not zoneHitboxes then
		return nil
	end

	local closestZoneHitbox = nil :: BasePart?
	local closestDistance = math.huge

	for _, zoneHitbox in zoneHitboxes:GetChildren() do
		if not zoneHitbox:IsA("BasePart") then
			continue
		end

		local distance = (zoneHitbox.Position - rootPart.Position).Magnitude
		if distance < closestDistance then
			closestDistance = distance
			closestZoneHitbox = zoneHitbox
		end
	end

	return closestZoneHitbox
end

local function setupCharacter()
	local character = player.Character
	if not character or not character:IsDescendantOf(Workspace) then
		AnimationController.loadedAnimations = {}
		return
	end

	for _, descendant in character:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end

		descendant.Massless = true
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or not humanoid:IsDescendantOf(Workspace) or humanoid.Health <= 0 then
		AnimationController.loadedAnimations = {}
		return
	end

	local rootPart = humanoid.RootPart
	if not rootPart or not rootPart:IsDescendantOf(Workspace) then
		AnimationController.loadedAnimations = {}
		return
	end

	local closestZoneHitbox = getClosestZoneHitboxToRootPart(rootPart)

	if closestZoneHitbox then
		local zoneSize = closestZoneHitbox.Size
		local zonePos = closestZoneHitbox.Position

		local isInZone = math.abs(rootPart.Position.X - zonePos.X) <= zoneSize.X / 2
			and math.abs(rootPart.Position.Y - zonePos.Y) <= zoneSize.Y / 2
			and math.abs(rootPart.Position.Z - zonePos.Z) <= zoneSize.Z / 2

		if isInZone then
			player:SetAttribute(Constants.ZONE_ATTRIBUTE, closestZoneHitbox.Name)
		else
			player:SetAttribute(Constants.ZONE_ATTRIBUTE, "")
		end
	end

	AnimationController.loadAnimation(frontDashAnimation)
	AnimationController.loadAnimation(backDashAnimation)
	AnimationController.loadAnimation(leftDashAnimation)
	AnimationController.loadAnimation(rightDashAnimation)

	local existingAlignOrientation = rootPart:FindFirstChildOfClass("AlignOrientation")
	if existingAlignOrientation then
		setupAlignOrientation(existingAlignOrientation)
	else
		local alignOrientation = Instance.new("AlignOrientation")
		alignOrientation.Parent = rootPart
		setupAlignOrientation(alignOrientation)
	end

	local existingPlaneConstraint = rootPart:FindFirstChildOfClass("PlaneConstraint")
	if existingPlaneConstraint then
		setupPlaneConstraint(existingPlaneConstraint)
		return
	end

	local planeConstraint = Instance.new("PlaneConstraint")
	planeConstraint.Parent = rootPart
	setupPlaneConstraint(planeConstraint)
end

local touchObject: InputObject? = nil

local function onDashButtonInputBegan(dashButton: ImageButton, inputObject: InputObject)
	if
		touchObject
		or inputObject.UserInputType ~= Enum.UserInputType.Touch
		or inputObject.UserInputState ~= Enum.UserInputState.Begin
	then
		return
	end

	touchObject = inputObject
	dashButton.ImageRectOffset = Vector2.new(146, 146)
end

local function onDashButtonInputEnded(dashButton: ImageButton, inputObject: InputObject)
	if touchObject ~= inputObject then
		return
	end

	touchObject = nil
	dashButton.ImageRectOffset = Vector2.new(1, 146)
end

local function createDashButton(jumpButton: GuiObject)
	local dashButton = jumpButton:Clone()
	dashButton.Name = "DashButton"
	dashButton.Position = UDim2.fromScale(0.1, 0.1)
	dashButton.AnchorPoint = Vector2.new(1, 1)
	if not dashButton:IsA("ImageButton") then
		return
	end

	dashButton.Image = "rbxassetid://131302447024369"
	dashButton.InputBegan:Connect(function(inputObject: InputObject)
		onDashButtonInputBegan(dashButton, inputObject)
	end)
	dashButton.InputEnded:Connect(function(inputObject: InputObject)
		onDashButtonInputEnded(dashButton, inputObject)
	end)
	dashButton.Parent = jumpButton
end

local function setupMobileGui()
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return
	end

	local touchGui = playerGui:FindFirstChild("TouchGui")
	if not touchGui then
		return
	end

	local touchControlFrame = touchGui:FindFirstChild("TouchControlFrame")
	if not touchControlFrame then
		return
	end

	local jumpButton = touchControlFrame:FindFirstChild("JumpButton")
	if not jumpButton then
		return
	end

	local dashButton = jumpButton:FindFirstChild("DashButton")
	if not dashButton then
		createDashButton(jumpButton)
		return
	end

	dashButton.Size = jumpButton.Size
end

local function onHeartbeat()
	local enemies = Workspace:FindFirstChild("Enemies")

	if enemies then
		for _, enemy in enemies:GetChildren() do
			onNPCHeartbeat(enemy)
		end
	end
	local npcs = Workspace:FindFirstChild("NPCs")
	if npcs then
		for _, npc in npcs:GetChildren() do
			onNPCHeartbeat(npc)
		end
	end

	setupCharacter()
	setupMobileGui()
end

local function initialize()
	RunService.Heartbeat:Connect(onHeartbeat)
end

initialize()
