--[[
    Archivo: CombatService.lua
    Tipo: Script
    Ubicacin: ServerScriptService/
    Descripcin: Maneja toda la lgica de combate del lado del servidor.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local DataManager = require(ServerScriptService.PlayerDataManager)
local Comm = require(ReplicatedStorage.Shared.Comm)
local Formulas = require(ReplicatedStorage.Shared.CharacterFormulas)
local SkillConfig = require(ReplicatedStorage.Shared.SkillConfig)

local attackCooldowns = {}
local skillCooldowns = {}
local isAttacking = {}

local MINIMUM_ATTACK_COOLDOWN = 0.2

local function playerAdded(player)
	isAttacking[player] = false
	attackCooldowns[player] = 0
	skillCooldowns[player] = {}
end

local function playerRemoving(player)
	isAttacking[player] = nil
	attackCooldowns[player] = nil
	skillCooldowns[player] = nil
end

Comm.Server:On("RequestBasicAttack", function(player)
	local profile = DataManager:GetProfile(player)
	if not profile or not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 or isAttacking[player] then
		return
	end

	local now = os.clock()
	local baseCooldown = 1.5
	local timeMultiplier = profile.DerivedStats.TimeMultiplier
	local actualCooldown = math.max(MINIMUM_ATTACK_COOLDOWN, baseCooldown * timeMultiplier)

	if now - (attackCooldowns[player] or 0) < actualCooldown then
		return
	end
	attackCooldowns[player] = now

	local animID
	local equippedWeaponId = profile.Data.Equipo.Arma

	if equippedWeaponId then
		local weaponType = "Sword" -- Placeholder
		animID = Formulas.CLASS_BASE_STATS[profile.Data.Clase].WeaponAttackAnims[weaponType]
	end

	if not animID then
		animID = Formulas.DefaultAnimations.HitMelee
	end

	if animID and animID ~= "rbxassetid://" then
		isAttacking[player] = true
		Comm.Server:Fire(player, "PlayAnimation", animID, timeMultiplier, "BasicAttack", nil)
	end
end)

Comm.Server:On("RequestSkillUse", function(player, skillId)
	print("[SERVER] Se solicit la habilidad: " .. tostring(skillId))
	local profile = DataManager:GetProfile(player)
	if not profile or not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 or isAttacking[player] then
		return
	end

	local skillData = SkillConfig[skillId]
	if not skillData then 
		print("[SERVER] Error: No se encontraron datos para el skillId: " .. tostring(skillId))
		return 
	end

	print("[SERVER] Mana actual: " .. tostring(profile.Data.CurrentMP) .. ", Coste de man: " .. tostring(skillData.ManaCost))

	local now = os.clock()
	local lastUsed = skillCooldowns[player][skillId] or 0
	if now - lastUsed < skillData.BaseCooldown then
		Comm.Server:Fire(player, "ShowNotification", "Habilidad en cooldown.")
		return
	end

	if profile.Data.CurrentMP < skillData.ManaCost then
		Comm.Server:Fire(player, "ShowNotification", "No tienes suficiente man.")
		return
	end

	print("[SERVER] Validacin de man y cooldown superada.")

	-- Actualizar estado y cooldowns
	profile.Data.CurrentMP = profile.Data.CurrentMP - skillData.ManaCost
	skillCooldowns[player][skillId] = now
	print("[SERVER] Nuevo mana: " .. tostring(profile.Data.CurrentMP))

	-- Notificar al cliente del cambio de stat
	print("[SERVER] Enviando PlayerStatChanged al cliente...")
	Comm.Server:Fire(player, "PlayerStatChanged", "CurrentMP", profile.Data.CurrentMP, profile.DerivedStats.MaxMP)

	local timeMultiplier = profile.DerivedStats.TimeMultiplier
	if skillData.AnimationID and skillData.AnimationID ~= "rbxassetid://" then
		isAttacking[player] = true
		Comm.Server:Fire(player, "PlayAnimation", skillData.AnimationID, timeMultiplier, "Skill", skillId)
	else
		print("Usando skill sin animacin:", skillId)
	end
end)

Comm.Server:On("SkillActionTriggered", function(player, actionType, actionId)
	local profile = DataManager:GetProfile(player)
	if not profile or not player.Character then return end

	if actionType == "BasicAttack" then
		-- Lgica del hitbox para el ataque bsico...
	elseif actionType == "Skill" then
		-- Lgica para el dao del skill...
	end
end)

Comm.Server:On("AnimationFinished", function(player)
	isAttacking[player] = false
end)

-- Conectar eventos de jugador
Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(playerRemoving)