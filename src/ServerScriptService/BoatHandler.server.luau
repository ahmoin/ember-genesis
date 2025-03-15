--!strict

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local boats = Workspace:WaitForChild("Boats")

local function onBoatHeartbeat(boat: Instance)
	local vehicleSeat = boat:FindFirstChildOfClass("VehicleSeat")
	if not vehicleSeat then
		return
	end

	local base = boat:FindFirstChild("Base")
	if not base then
		return
	end

	local motorForce = base:FindFirstChild("MotorForce")
	local dampingForce = base:FindFirstChild("DampingForce")
	local torque = base:FindFirstChildOfClass("Torque")
	if
		not motorForce
		or not dampingForce
		or not torque
		or not motorForce:IsA("VectorForce")
		or not dampingForce:IsA("VectorForce")
		or not torque:IsA("Torque")
	then
		return
	end

	local thrust = vehicleSeat.ThrottleFloat * 8000

	motorForce.Force = CFrame.Angles(0, math.pi / 32 * vehicleSeat.SteerFloat, 0).RightVector * thrust
	dampingForce.Force = -vehicleSeat.AssemblyLinearVelocity * 200
	torque.Torque = -vehicleSeat.AssemblyAngularVelocity * 7000
end

local function onHeartbeat()
	for _, boat in boats:GetChildren() do
		onBoatHeartbeat(boat)
	end
end

local function initialize()
	RunService.Heartbeat:Connect(onHeartbeat)
end

initialize()
