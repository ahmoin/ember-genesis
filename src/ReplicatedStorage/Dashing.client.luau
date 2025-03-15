--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local AnimationController = require(ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("AnimationController"))
local Constants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Constants"))
local Signals = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Signals"))

local animations = ReplicatedStorage:WaitForChild("Animations")
local frontDashAnimation = animations:WaitForChild("FrontDash")
local backDashAnimation = animations:WaitForChild("BackDash")
local leftDashAnimation = animations:WaitForChild("LeftDash")
local rightDashAnimation = animations:WaitForChild("RightDash")

local player = Players.LocalPlayer

local function onDashFinished()
	local character = player.Character
	if not character or not character:IsDescendantOf(Workspace) then
		return
	end

	character:SetAttribute(Constants.DASH_DEBOUNCE_ATTRIBUTE, false)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or not humanoid:IsDescendantOf(Workspace) then
		return
	end

	local rootPart = humanoid.RootPart
	if not rootPart or not rootPart:IsDescendantOf(Workspace) then
		return
	end

	local alignOrientation = rootPart:FindFirstChildOfClass("AlignOrientation")
	if not alignOrientation or not alignOrientation:IsDescendantOf(Workspace) then
		return
	end

	alignOrientation.Enabled = false
end

local function doDash(checkDebounce: boolean)
	local character = player.Character
	if not character or not character:IsDescendantOf(Workspace) then
		return
	end

	if checkDebounce and character:GetAttribute(Constants.DASH_DEBOUNCE_ATTRIBUTE) then
		return
	end
	character:SetAttribute(Constants.DASH_DEBOUNCE_ATTRIBUTE, true)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or not humanoid:IsDescendantOf(Workspace) then
		return
	end

	local rootPart = humanoid.RootPart
	if not rootPart or not rootPart:IsDescendantOf(Workspace) then
		return
	end

	local camera = Workspace.CurrentCamera
	if not camera or not camera:IsDescendantOf(Workspace) then
		return
	end

	local alignOrientation = rootPart:FindFirstChildOfClass("AlignOrientation")
	if not alignOrientation then
		return
	end

	local cameraLookVector = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
	local moveDirection = humanoid.MoveDirection
	local impulseDirection = cameraLookVector

	local dashDirection = Vector2.new(1, 0)

	if moveDirection.Magnitude > 0 then
		impulseDirection = moveDirection
		local normalizedLookVector = cameraLookVector.Unit
		local normalizedMoveDir = moveDirection.Unit
		dashDirection =
			Vector2.new(normalizedLookVector:Dot(normalizedMoveDir), normalizedLookVector:Cross(normalizedMoveDir).Y)
	end

	impulseDirection = impulseDirection.Unit * Constants.DASH_IMPULSE_MAGNITUDE

	alignOrientation.Enabled = true
	alignOrientation.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + impulseDirection)

	rootPart.AssemblyLinearVelocity = impulseDirection

	local animationToPlay = frontDashAnimation
	if dashDirection.X < -0.1 then
		animationToPlay = backDashAnimation
	elseif dashDirection.X > 0.1 then
		animationToPlay = frontDashAnimation
	elseif dashDirection.Y > 0.1 then
		animationToPlay = leftDashAnimation
	elseif dashDirection.Y < -0.1 then
		animationToPlay = rightDashAnimation
	end

	AnimationController.playAnimation(animationToPlay)

	task.delay(Constants.DASH_DURATION, onDashFinished)
end

local function onDashButtonActivated()
	doDash(true)
end

local function onDashSignalActivated()
	doDash(false)
end

local function onInputEnded(input: InputObject, isGameProcessed: boolean)
	if isGameProcessed then
		return
	end

	if input.KeyCode ~= Constants.DASH_KEY_CODE then
		return
	end

	doDash(true)
end

local function initialize()
	UserInputService.InputEnded:Connect(onInputEnded)
	Signals.doDashSignal:Connect(onDashSignalActivated)

	local playerGui = player:WaitForChild("PlayerGui")
	local touchGui = playerGui:WaitForChild("TouchGui")
	local touchControlFrame = touchGui:WaitForChild("TouchControlFrame")
	local jumpButton = touchControlFrame:WaitForChild("JumpButton")
	local dashButton = jumpButton:WaitForChild("DashButton")

	dashButton.Activated:Connect(onDashButtonActivated)
end

initialize()
