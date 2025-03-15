--!strict

local Workspace = game:GetService("Workspace")

local allowedNames = { "Rock", "Grass" }

for _, descendant in Workspace.Islands:GetDescendants() do
	if not descendant:IsA("BasePart") then
		continue
	end
	if not table.find(allowedNames, descendant.Name) then
		continue
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { descendant }

	local size = descendant.Size
	local position = descendant.Position
	local halfSize = size / 2

	local minX = position.X - halfSize.X
	local maxX = position.X + halfSize.X
	local topY = position.Y + halfSize.Y
	local minZ = position.Z - halfSize.Z
	local maxZ = position.Z + halfSize.Z

	local isUnderground = true
	for x = math.ceil(minX), math.floor(maxX) do
		for z = math.ceil(minZ), math.floor(maxZ) do
			local rayOrigin = Vector3.new(x, topY, z)
			local rayDirection = Vector3.new(0, 1000, 0)
			local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)

			if not result then
				isUnderground = false
				break
			end

			if descendant.Name == "Rock" then
				if result.Instance.Name ~= "Grass" then
					continue
				end
				isUnderground = false
			end
		end
		if not isUnderground then
			break
		end
	end

	if isUnderground then
		descendant:SetAttribute("oldName", descendant.Name)
		descendant.Name = "Underground"
		print(descendant)
	end
end
