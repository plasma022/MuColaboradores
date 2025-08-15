--[[
    Archivo: CombatService.lua
    Tipo: Script
    Ubicacion: ServerScriptService/
    Descripcion: Maneja toda la logica de combate del lado del servidor.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")

local DataManager = require(ServerScriptService.PlayerDataManager)
local Comm = require(ReplicatedStorage.Shared.Comm)
local Formulas = require(ReplicatedStorage.Shared.CharacterFormulas)
local SkillConfig = require(ReplicatedStorage.Shared.SkillConfig)

local playerCooldowns = {}

local MINIMUM_ATTACK_COOLDOWN = 0.2 

Comm.Server:On("RequestBasicAttack", function(player)
	local profile = DataManager:GetProfile(player)
	if not profile or not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then
		return
	end

	local now = os.clock()
	local baseCooldown = 1.5
	local timeMultiplier = profile.DerivedStats.TimeMultiplier
	local actualCooldown = math.max(MINIMUM_ATTACK_COOLDOWN, baseCooldown * timeMultiplier)

	if playerCooldowns[player] and now - playerCooldowns[player] < actualCooldown then
		return
	end
	playerCooldowns[player] = now

	local char = player.Character
	local rootPart = char.PrimaryPart

	local hitbox = Instance.new("Part")
	hitbox.Size = Vector3.new(4, 6, 8)
	hitbox.CFrame = rootPart.CFrame * CFrame.new(0, 0, -hitbox.Size.Z / 2)
	hitbox.CanCollide = false
	hitbox.Transparency = 1 
	hitbox.Anchored = true
	hitbox.Parent = workspace

	local alreadyHit = {}
	hitbox.Touched:Connect(function(hit)
		if not hit.Parent or table.find(alreadyHit, hit.Parent) then return end

		local enemyHumanoid = hit.Parent:FindFirstChild("Humanoid")
		if enemyHumanoid and enemyHumanoid.Health > 0 and hit.Parent.Name ~= player.Name then
			table.insert(alreadyHit, hit.Parent)

			local minDmg, maxDmg = Formulas.calculateDamageRange(profile.Data.Clase, profile.Data.EstadisticasBase.Fuerza, profile.Data.EstadisticasBase.Agilidad)
			local damage = math.random(minDmg, maxDmg)
			enemyHumanoid:TakeDamage(damage)

			Comm.Server:FireAll("ShowDamageIndicator", hit.Parent, damage, false)
		end
	end)

	Debris:AddItem(hitbox, 0.2)

	local animID = Formulas.CLASS_BASE_STATS[profile.Data.Clase].BasicAttackAnimID

	if animID and not string.find(animID, "YOUR_") and not string.find(animID, "PEGA_") then
		Comm.Server:Fire(player, "PlayAnimation", animID, timeMultiplier)
	end
end)

Comm.Server:On("RequestSkillUse", function(player, skillId)
	local profile = DataManager:GetProfile(player)
	if not profile or not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then
		return
	end

	local skillData = SkillConfig[skillId]
	if not skillData then return end

	local timeMultiplier = profile.DerivedStats.TimeMultiplier
	if skillData.AnimationID and not string.find(skillData.AnimationID, "YOUR_") then
		Comm.Server:Fire(player, "PlayAnimation", skillData.AnimationID, timeMultiplier)
	end
end)

Comm.Server:On("SkillActionTriggered", function(player, skillId, actionCFrame)
	-- L�gica futura
end)
