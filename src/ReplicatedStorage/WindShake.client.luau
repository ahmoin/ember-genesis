--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Terrain = Workspace:WaitForChild("Terrain")

local Constants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Constants"))

local WIND_DIRECTION = Vector3.new(1, 0, 0.3)
local WIND_SPEED = 20
local WIND_POWER = 0.1
local WIND_LIFETIME = 1.5
local WIND_SPAWN_RATE = 0.1

local WIND_LINES_OFFSET = Vector3.new(0, 0.1, 0)
local TRAIL_WIDTH_SEQUENCE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.3),
	NumberSequenceKeypoint.new(0.2, 1),
	NumberSequenceKeypoint.new(0.8, 1),
	NumberSequenceKeypoint.new(1, 0.3),
})
local TRAIL_TRANSPARENCY = NumberSequence.new(0.7)
local TRAIL_MAX_LENGTH = 20
local RANDOM_POSITION_DISTANCE_MIN = 200
local RANDOM_POSITION_DISTANCE_MAX = 600
local RANDOM_POSITION_DISTANCE_MULTIPLIER = -0.1
local RANDOM_ANGLE_Y_MIN = -80
local RANDOM_ANGLE_Y_MAX = 80
local RANDOM_ANGLE_X_MIN = -30
local RANDOM_ANGLE_X_MAX = 70

local RENDER_DISTANCE = 150
local MAX_REFRESH_RATE = 1 / 60
local INITIAL_TABLE_CAPACITY = 500

local windLinesQueue = table.create(10)
local lastWindLineSpawned = 0

local objectMetadata = {} :: { [BasePart]: ObjectMetadata }
local partList = table.create(INITIAL_TABLE_CAPACITY)
local cframeList = table.create(INITIAL_TABLE_CAPACITY)

type WindLine = {
	Attachment0: Attachment,
	Attachment1: Attachment,
	Trail: Trail,
	Lifetime: number,
	Position: Vector3,
	Direction: Vector3,
	Speed: number,
	StartClock: number,
	Seed: number,
}

type ObjectSettings = {
	WindPower: number?,
	WindSpeed: number?,
	WindDirection: Vector3?,
	PivotOffset: CFrame?,
	PivotOffsetInverse: CFrame?,
	cleanup: () -> (),
}

type ObjectMetadata = {
	Settings: ObjectSettings,
	Seed: number,
	Origin: CFrame,
	LastUpdate: number,
}

local function createObjectSettings(object: BasePart): ObjectSettings
	local objectSettings = {} :: ObjectSettings

	local windPower = object:GetAttribute("WindPower")
	local windSpeed = object:GetAttribute("WindSpeed")
	local windDirection = object:GetAttribute("WindDirection")

	if type(windPower) == "number" then
		objectSettings.WindPower = windPower
	else
		objectSettings.WindPower = WIND_POWER
	end

	if type(windSpeed) == "number" then
		objectSettings.WindSpeed = windSpeed
	else
		objectSettings.WindSpeed = WIND_SPEED
	end

	if typeof(windDirection) == "Vector3" or type(windDirection) == "vector" then
		if windDirection.Magnitude > 0 then
			objectSettings.WindDirection = windDirection.Unit
		else
			objectSettings.WindDirection = WIND_DIRECTION
		end
	else
		objectSettings.WindDirection = WIND_DIRECTION
	end

	if object:IsA("BasePart") then
		objectSettings.PivotOffset = object.PivotOffset
		objectSettings.PivotOffsetInverse = object.PivotOffset:Inverse()
	else
		objectSettings.PivotOffset = nil
		objectSettings.PivotOffsetInverse = nil
	end

	local powerConnection = object:GetAttributeChangedSignal("WindPower"):Connect(function()
		windPower = object:GetAttribute("WindPower")
		if type(windPower) == "number" then
			objectSettings.WindPower = windPower
		else
			objectSettings.WindPower = WIND_POWER
		end
	end)

	local speedConnection = object:GetAttributeChangedSignal("WindSpeed"):Connect(function()
		windSpeed = object:GetAttribute("WindSpeed")
		if type(windSpeed) == "number" then
			objectSettings.WindSpeed = windSpeed
		else
			objectSettings.WindSpeed = WIND_SPEED
		end
	end)

	local directionConnection = object:GetAttributeChangedSignal("WindDirection"):Connect(function()
		windDirection = object:GetAttribute("WindDirection")
		if typeof(windDirection) == "Vector3" or type(windDirection) == "vector" then
			if windDirection.Magnitude > 0 then
				objectSettings.WindDirection = windDirection.Unit
			else
				objectSettings.WindDirection = WIND_DIRECTION
			end
		else
			objectSettings.WindDirection = WIND_DIRECTION
		end
	end)

	local pivotConnection = nil :: RBXScriptConnection?
	if object:IsA("BasePart") then
		pivotConnection = object:GetPropertyChangedSignal("PivotOffset"):Connect(function()
			objectSettings.PivotOffset = object.PivotOffset
			objectSettings.PivotOffsetInverse = object.PivotOffset:Inverse()
		end)
	end

	function objectSettings.cleanup()
		powerConnection:Disconnect()
		speedConnection:Disconnect()
		directionConnection:Disconnect()
		if pivotConnection then
			pivotConnection:Disconnect()
		end

		table.clear(objectSettings)
	end

	return objectSettings
end

local function createWindLine()
	local position = (
		Workspace.CurrentCamera.CFrame
		* CFrame.Angles(
			math.rad(math.random(RANDOM_ANGLE_X_MIN, RANDOM_ANGLE_X_MAX)),
			math.rad(math.random(RANDOM_ANGLE_Y_MIN, RANDOM_ANGLE_Y_MAX)),
			0
		)
	)
		* CFrame.new(
			0,
			0,
			math.random(RANDOM_POSITION_DISTANCE_MIN, RANDOM_POSITION_DISTANCE_MAX)
				* RANDOM_POSITION_DISTANCE_MULTIPLIER
		).Position

	local attachment0 = Instance.new("Attachment")
	local attachment1 = Instance.new("Attachment")

	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.WidthScale = TRAIL_WIDTH_SEQUENCE
	trail.Transparency = TRAIL_TRANSPARENCY
	trail.FaceCamera = true
	trail.Parent = attachment0

	attachment0.WorldPosition = position
	attachment1.WorldPosition = position + WIND_LINES_OFFSET

	local windLine: WindLine = {
		Attachment0 = attachment0,
		Attachment1 = attachment1,
		Trail = trail,
		Lifetime = WIND_LIFETIME + (math.random(-10, 10) * 0.1),
		Position = position,
		Direction = WIND_DIRECTION,
		Speed = WIND_SPEED + (math.random(-10, 10) * 0.1),
		StartClock = os.clock(),
		Seed = math.random(1, 1000) * 0.1,
	}

	windLinesQueue[#windLinesQueue + 1] = windLine

	attachment0.Parent = Terrain
	attachment1.Parent = Terrain
end

local function addObjectShake(object: Instance)
	if typeof(object) ~= "Instance" then
		return
	end

	if not object:IsA("BasePart") then
		return
	end

	if objectMetadata[object] then
		return
	end

	objectMetadata[object] = {
		Settings = createObjectSettings(object),
		Seed = math.random(5000) * 0.32,
		Origin = object.CFrame,
		LastUpdate = os.clock(),
	}
end

local function removeObjectShake(object: Instance)
	if typeof(object) ~= "Instance" then
		return
	end

	if not object:IsA("BasePart") then
		return
	end

	local objMeta = objectMetadata[object]
	if not objMeta then
		return
	end

	objectMetadata[object] = nil
	objMeta.Settings.cleanup()

	object.CFrame = objMeta.Origin
end

local function onHeartbeat()
	local clock = os.clock()

	if clock - lastWindLineSpawned > WIND_SPAWN_RATE then
		createWindLine()
		lastWindLineSpawned = clock
	end

	for i, windLine in windLinesQueue do
		local aliveTime = clock - windLine.StartClock
		if aliveTime >= windLine.Lifetime then
			windLine.Attachment0:Destroy()
			windLine.Attachment1:Destroy()
			windLine.Trail:Destroy()

			local length = #windLinesQueue
			windLinesQueue[i] = windLinesQueue[length]
			windLinesQueue[length] = nil

			continue
		end

		windLine.Trail.MaxLength = TRAIL_MAX_LENGTH - (TRAIL_MAX_LENGTH * (aliveTime / windLine.Lifetime))

		local seededClock = (clock + windLine.Seed) * (windLine.Speed * 0.2)
		local startPos = windLine.Position
		windLine.Attachment0.WorldPosition = (CFrame.new(startPos, startPos + windLine.Direction) * CFrame.new(
			0,
			0,
			windLine.Speed * -aliveTime
		)).Position + Vector3.new(
			math.sin(seededClock) * 0.5,
			math.sin(seededClock) * 0.8,
			math.sin(seededClock) * 0.5
		)

		windLine.Attachment1.WorldPosition = windLine.Attachment0.WorldPosition + WIND_LINES_OFFSET
	end

	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	local cameraPosition = camera.CFrame.Position

	table.clear(partList)
	table.clear(cframeList)
	local bulkMoveIndex = 0

	for object, metadata in objectMetadata do
		if not object:IsDescendantOf(game) then
			objectMetadata[object] = nil
			continue
		end

		if (object.Position - cameraPosition).Magnitude > RENDER_DISTANCE then
			continue
		end

		local objectSettings = metadata.Settings
		local windPower = objectSettings.WindPower or WIND_POWER
		local windSpeed = objectSettings.WindSpeed or WIND_SPEED

		local timeSinceLastUpdate = clock - metadata.LastUpdate
		if timeSinceLastUpdate < MAX_REFRESH_RATE then
			continue
		end

		metadata.LastUpdate = clock

		local seed = metadata.Seed
		local time = clock * windSpeed * 0.5

		local windEffect = CFrame.new(
			math.sin(time + seed) * windPower * 0.1,
			math.sin(time * 0.7 + seed * 2) * windPower * 0.05,
			math.sin(time * 1.1 + seed * 0.7) * windPower * 0.1
		) * CFrame.Angles(
			math.sin(time * 0.9 + seed) * windPower * 0.05,
			math.sin(time * 0.8 + seed * 1.1) * windPower * 0.05,
			math.sin(time * 1.2 + seed * 0.6) * windPower * 0.05
		)

		local pivotOffset = objectSettings.PivotOffset
		local pivotOffsetInverse = objectSettings.PivotOffsetInverse

		local newCFrame = metadata.Origin * windEffect
		if pivotOffset and pivotOffsetInverse then
			newCFrame = metadata.Origin * pivotOffset * windEffect * pivotOffsetInverse
		end

		bulkMoveIndex += 1
		partList[bulkMoveIndex] = object
		cframeList[bulkMoveIndex] = newCFrame
	end

	if bulkMoveIndex > 0 then
		Workspace:BulkMoveTo(partList, cframeList, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

local function initializeWindSystems()
	lastWindLineSpawned = os.clock()

	CollectionService:GetInstanceAddedSignal(Constants.WIND_COLLECTION_TAG):Connect(addObjectShake)

	CollectionService:GetInstanceRemovedSignal(Constants.WIND_COLLECTION_TAG):Connect(removeObjectShake)

	for _, object in CollectionService:GetTagged(Constants.WIND_COLLECTION_TAG) do
		addObjectShake(object)
	end

	RunService.Heartbeat:Connect(onHeartbeat)
end

initializeWindSystems()
