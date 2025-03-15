--!strict

local Workspace = game:GetService("Workspace")

local SEA_LEVEL = -0.6

for _, descendant in Workspace:GetDescendants() do
	if not descendant:IsA("BasePart") then
		continue
	end
	local size = descendant.Size
	local position = descendant.Position

	local topPoint = position.Y + (size.Y / 2)

	if topPoint < SEA_LEVEL then
		descendant:SetAttribute("oldName", descendant.Name)
		descendant.Name = "UnderSea"
		print(descendant)
	end
end
