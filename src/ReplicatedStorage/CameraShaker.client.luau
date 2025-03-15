--!strict

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CameraShakeInstance = require(ReplicatedStorage:WaitForChild("CameraShakeInstance"))

local CameraShakeState = CameraShakeInstance.CameraShakeState

local player = Players.LocalPlayer

type CameraShakeInstanceType = {
	Magnitude: number,
	Roughness: number,
	PositionInfluence: Vector3,
	RotationInfluence: Vector3,
	DeleteOnInactive: boolean,
	roughMod: number,
	magnMod: number,
	fadeOutDuration: number,
	fadeInDuration: number,
	sustain: boolean,
	currentFadeTime: number,
	tick: number,
	_camShakeInstance: boolean,

	UpdateShake: (self: any, deltaTime: number) -> Vector3,
	StartFadeIn: (self: any, fadeInTime: number?) -> (),
	StartFadeOut: (self: any, fadeOutTime: number) -> (),
	GetScaleRoughness: (self: any) -> number,
	SetScaleRoughness: (self: any, v: number) -> (),
	GetScaleMagnitude: (self: any) -> number,
	SetScaleMagnitude: (self: any, v: number) -> (),
	GetNormalizedFadeTime: (self: any) -> number,
	IsShaking: (self: any) -> boolean,
	IsFadingOut: (self: any) -> boolean,
	IsFadingIn: (self: any) -> boolean,
	GetState: (self: any) -> number,
}

local renderName = "CameraShaker"
local renderPriority = Enum.RenderPriority.Camera.Value + 1
local cameraShakeInstances = {} :: { CameraShakeInstanceType }
local removeInstances = {}

local callback = function(shakeCFrame: CFrame)
	local camera = Workspace.CurrentCamera
	if camera then
		camera.CFrame = camera.CFrame * shakeCFrame
	end
end

local function updateCameraShaker(deltaTime: number)
	local positionalAddShake = Vector3.zero
	local rotationalAddShake = Vector3.zero

	local instances = cameraShakeInstances

	for i = 1, #instances do
		local c = instances[i]
		local state = c:GetState()

		if state == CameraShakeState.Inactive and c.DeleteOnInactive then
			removeInstances[#removeInstances + 1] = i
		elseif state ~= CameraShakeState.Inactive then
			local shake: Vector3 = c:UpdateShake(deltaTime)
			positionalAddShake = positionalAddShake + (shake * c.PositionInfluence)
			rotationalAddShake = rotationalAddShake + (shake * c.RotationInfluence)
		end
	end

	for i = #removeInstances, 1, -1 do
		local instIndex = removeInstances[i]
		table.remove(instances, instIndex)
		removeInstances[i] = nil
	end

	return CFrame.new(positionalAddShake)
		* CFrame.Angles(0, math.rad(rotationalAddShake.Y), 0)
		* CFrame.Angles(math.rad(rotationalAddShake.X), 0, math.rad(rotationalAddShake.Z))
end

local function shakeOnce(
	magnitude: number,
	roughness: number,
	fadeInTime: number,
	fadeOutTime: number,
	positionalInfluence: Vector3,
	rotationalInfluence: Vector3
)
	local shakeInstance = CameraShakeInstance.new(magnitude, roughness, fadeInTime, fadeOutTime)
	shakeInstance.PositionInfluence = positionalInfluence
	shakeInstance.RotationInfluence = rotationalInfluence
	cameraShakeInstances[#cameraShakeInstances + 1] = shakeInstance

	return shakeInstance
end

local lastHealth = 0

local function onHealthChanged()
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local health = humanoid.Health
	if health >= lastHealth then
		return
	end
	local healthLost = lastHealth - health
	local percentageOfMaxHealth = healthLost / humanoid.MaxHealth
	lastHealth = health
	local magnitude = 10 * percentageOfMaxHealth
	local roughness = 8 * percentageOfMaxHealth
	shakeOnce(magnitude, roughness, 0, 0.5, Vector3.one, Vector3.new(0.1, 0.1, 0.1))
end

local function onCharacterChildAdded(child: Instance)
	if not child:IsA("Humanoid") then
		return
	end
	lastHealth = child.Health
	child.HealthChanged:Connect(onHealthChanged)
end

local function onCharacterAdded(character: Model)
	for _, child in character:GetChildren() do
		onCharacterChildAdded(child)
	end

	character.ChildAdded:Connect(onCharacterChildAdded)
end

local function initialize()
	RunService:BindToRenderStep(renderName, renderPriority, function(deltaTime: number)
		local cf = updateCameraShaker(deltaTime)
		callback(cf)
	end)

	local character = player.Character
	if character then
		onCharacterAdded(character)
	end

	player.CharacterAdded:Connect(onCharacterAdded)
end

initialize()
