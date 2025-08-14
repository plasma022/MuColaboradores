--[[
    Archivo: CombatService.lua
    Tipo: Script
    Ubicaci�n: ServerScriptService/
    Descripci�n: Maneja toda la l�gica de combate del lado del servidor.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")

local DataManager = require(ServerScriptService.PlayerDataManager)
local Comm = require(ReplicatedStorage.Shared.Comm)
local Formulas = require(ReplicatedStorage.Shared.CharacterFormulas)
local SkillConfig = require(ReplicatedStorage.Shared.SkillConfig)
-- local ItemConfig = require(ReplicatedStorage.Shared.ItemConfig) -- Necesitar�s un m�dulo para los datos de �tems

local playerCooldowns = {}
local isAttacking = {} -- Para evitar que los jugadores se muevan mientras atacan

local MINIMUM_ATTACK_COOLDOWN = 0.2 

Comm.Server:On("RequestBasicAttack", function(player)
	local profile = DataManager:GetProfile(player)
	if not profile or not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 or isAttacking[player] then
		return
	end

	-- Validaciones de cooldown
	local now = os.clock()
	local baseCooldown = 1.5
	local timeMultiplier = profile.DerivedStats.TimeMultiplier
	local actualCooldown = math.max(MINIMUM_ATTACK_COOLDOWN, baseCooldown * timeMultiplier)

	if playerCooldowns[player] and now - playerCooldowns[player] < actualCooldown then
		return
	end
	playerCooldowns[player] = now

	-- == L�GICA DE SELECCI�N DE ANIMACI�N ==
	local animID
	local equippedWeaponId = profile.Data.Equipo.Arma

	if equippedWeaponId then
		-- Aqu� necesitar�as obtener los datos del �tem desde un ItemConfig
		-- local weaponData = ItemConfig[equippedWeaponId]
		-- local weaponType = weaponData.Type -- "Sword", "Bow", etc.

		-- *** L�gica de ejemplo hasta que tengas un ItemConfig ***
		local weaponType = "Sword" -- Cambia esto para probar

		animID = Formulas.CLASS_BASE_STATS[profile.Data.Clase].WeaponAttackAnims[weaponType]
	end

	-- Si no se encontr� una animaci�n para el arma, usamos la por defecto.
	if not animID then
		animID = Formulas.DefaultAnimations.HitMelee
	end

	-- Si es v�lido, le decimos al cliente que reproduzca la animaci�n
	if animID then
		isAttacking[player] = true -- Bloqueamos el movimiento
		Comm.Server:Fire(player, "PlayAnimation", animID, timeMultiplier, "BasicAttack", nil)
	end
end)

Comm.Server:On("RequestSkillUse", function(player, skillId)
	local profile = DataManager:GetProfile(player)
	if not profile or not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 or isAttacking[player] then
		return
	end

	local skillData = SkillConfig[skillId]
	if not skillData then return end

	-- Validaciones de Mana, Cooldown, etc.
	-- ...

	local timeMultiplier = profile.DerivedStats.TimeMultiplier
	if skillData.AnimationID then
		isAttacking[player] = true -- Bloqueamos el movimiento
		Comm.Server:Fire(player, "PlayAnimation", skillData.AnimationID, timeMultiplier, "Skill", skillId)
	end
end)

Comm.Server:On("SkillActionTriggered", function(player, actionType, actionId)
	local profile = DataManager:GetProfile(player)
	if not profile or not player.Character then return end

	if actionType == "BasicAttack" then
		-- L�gica del hitbox para el ataque b�sico...
	elseif actionType == "Skill" then
		-- L�gica para el da�o del skill...
	end
end)

-- El cliente nos avisa que la animaci�n ha terminado para desbloquear al jugador.
Comm.Server:On("AnimationFinished", function(player)
	isAttacking[player] = false
end)
