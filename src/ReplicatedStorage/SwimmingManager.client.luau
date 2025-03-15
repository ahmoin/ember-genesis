--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Constants"))

local player = Players.LocalPlayer

local function reenablePlaneConstraint(
	planeConstraint: PlaneConstraint,
	waterAttachment: Attachment,
	attachment0: Attachment
)
	while
		planeConstraint
		and planeConstraint:IsDescendantOf(Workspace)
		and waterAttachment
		and waterAttachment:IsDescendantOf(Workspace)
		and attachment0
		and attachment0:IsDescendantOf(Workspace)
	do
		local isInWater = waterAttachment.WorldPosition.Y < attachment0.WorldPosition.Y
		if isInWater then
			planeConstraint:SetAttribute(Constants.DISABLED_ATTRIBUTE, false)
			break
		end
		task.wait()
	end
end

function onJumpRequest()
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local rootPart = humanoid.RootPart
	if not rootPart then
		return
	end

	local planeConstraint = rootPart:FindFirstChildOfClass("PlaneConstraint")
	if not planeConstraint then
		return
	end

	local waterAttachment = rootPart:FindFirstChild(Constants.WATER_ATTACHMENT_NAME)
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

	local isInWater = waterAttachment.WorldPosition.Y < attachment0.WorldPosition.Y
	if not isInWater then
		return
	end

	planeConstraint:SetAttribute(Constants.DISABLED_ATTRIBUTE, true)
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

	task.delay(0.05, reenablePlaneConstraint, planeConstraint, waterAttachment, attachment0)
end

UserInputService.JumpRequest:Connect(onJumpRequest)
