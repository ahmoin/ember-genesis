--!strict

local Workspace = game:GetService("Workspace")

local function isOrientationAligned(orientation: Vector3): boolean
	local function isAngleAligned(angle: number): boolean
		angle = angle % 360
		if angle < 0 then
			angle += 360
		end
		return angle % 90 < 0.1 or angle % 90 > 89.9
	end

	return isAngleAligned(orientation.X) and isAngleAligned(orientation.Y) and isAngleAligned(orientation.Z)
end

local partsByTopPoint: { [number]: { BasePart } } = {}

for _, descendant in Workspace.Islands:GetDescendants() do
	if not descendant:IsA("BasePart") then
		continue
	end

	if not isOrientationAligned(descendant.Orientation) then
		continue
	end

	local size = descendant.Size
	local position = descendant.Position
	local topPoint = position.Y + (size.Y / 2)

	topPoint = math.floor(topPoint * 1000 + 0.5) / 1000

	if not partsByTopPoint[topPoint] then
		partsByTopPoint[topPoint] = {}
	end
	table.insert(partsByTopPoint[topPoint], descendant)
end

local function isPartZFighting(part1: BasePart, part2: BasePart): boolean
	local p1min = part1.Position - (part1.Size / 2)
	local p1max = part1.Position + (part1.Size / 2)
	local p2min = part2.Position - (part2.Size / 2)
	local p2max = part2.Position + (part2.Size / 2)

	return p1max.X >= p2min.X and p1min.X <= p2max.X and p1max.Z >= p2min.Z and p1min.Z <= p2max.Z
end

local function checkForZFighting(parts: { BasePart })
	for i = 1, #parts do
		for j = i + 1, #parts do
			local part1, part2 = parts[i], parts[j]

			if isPartZFighting(parts[i], part2) then
				print(part1, part2)
			end
		end
	end
end

for _, parts in partsByTopPoint do
	if #parts < 2 then
		continue
	end

	checkForZFighting(parts)
end
