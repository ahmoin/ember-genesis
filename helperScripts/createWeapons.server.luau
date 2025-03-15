local weaponTemplate = workspace.Weapon

local enemies = workspace.Enemies:GetChildren()

for _, enemy in enemies do
	if enemy:FindFirstChild("Weapon") then
		return
	end
	if enemy.Name ~= "Brigand" then
		return
	end
	local weapon = weaponTemplate:Clone()
	weapon.Parent = enemy
	weapon.RigidConstraint.Attachment0 = enemy.RightHand.RightGripAttachment
	weapon.RigidConstraint.Attachment1 = weapon.Attachment
end
