--[[
	CombatService.lua
	Servicio que maneja toda la lógica de combate.
	Procesa las solicitudes de ataque y uso de habilidades, calcula el daño y lo aplica.
	Ubicación: ServerScriptService/services/
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Módulos
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SkillConfig = require(ReplicatedStorage.Shared.config.SkillConfig)
local CharacterFormulas = require(ReplicatedStorage.Shared.util.character_formulas)

local CombatService = {}

-- CONSTANTES
local MINIMUM_ATTACK_COOLDOWN = 0.2

-- ATRIBUTOS DEL SERVICIO
CombatService.PlayerDataService = nil
CombatService.StatsService = nil

-- Tablas para gestionar el estado de combate de cada jugador
CombatService.attackCooldowns = {}
CombatService.skillCooldowns = {}
CombatService.isAttacking = {}

-- MÉTODOS
function CombatService:Init()
	-- No se necesita nada en la inicialización
end

function CombatService:Start(ServiceManager)
	-- Obtenemos referencias a otros servicios
	self.PlayerDataService = ServiceManager:GetService("PlayerDataService")
	self.StatsService = ServiceManager:GetService("StatsService")

	-- Conectamos los RemoteEvents que el cliente dispara
	Remotes.RequestBasicAttack.OnServerEvent:Connect(function(player)
		self:_onBasicAttack(player)
	end)

	Remotes.RequestSkillUse.OnServerEvent:Connect(function(player, skillId, target)
		self:_onSkillUse(player, skillId, target)
	end)

	Remotes.SkillActionTriggered.OnServerEvent:Connect(function(player, actionType, actionData)
		self:_onSkillActionTriggered(player, actionType, actionData)
	end)

	Remotes.AnimationFinished.OnServerEvent:Connect(function(player)
		self:_onAnimationFinished(player)
	end)

	-- Conectar eventos para inicializar y limpiar datos de combate del jugador
	Players.PlayerAdded:Connect(function(player) self:_onPlayerAdded(player) end)
	Players.PlayerRemoving:Connect(function(player) self:_onPlayerRemoving(player) end)
	
	-- Inicializar para jugadores que ya están en el servidor
	for _, player in ipairs(Players:GetPlayers()) do
		self:_onPlayerAdded(player)
	end

	print("[CombatService] Listo y escuchando peticiones de combate.")
end

-- Funciones para manejar la entrada y salida de jugadores
function CombatService:_onPlayerAdded(player)
	self.isAttacking[player] = false
	self.attackCooldowns[player] = 0
	self.skillCooldowns[player] = {}
end

function CombatService:_onPlayerRemoving(player)
	self.isAttacking[player] = nil
	self.attackCooldowns[player] = nil
	self.skillCooldowns[player] = nil
end

-- Función privada para manejar un ataque básico
function CombatService:_onBasicAttack(player)
	local playerData = self.PlayerDataService:GetData(player)
	if not playerData or not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 or self.isAttacking[player] then
		return
	end

	local now = os.clock()
	local derivedStats = self.StatsService:GetDerivedStats(player) -- Asumiendo que StatsService tiene esta función
	local baseCooldown = 1.5
	local timeMultiplier = derivedStats.TimeMultiplier or 1
	local actualCooldown = math.max(MINIMUM_ATTACK_COOLDOWN, baseCooldown * timeMultiplier)

	if now - (self.attackCooldowns[player] or 0) < actualCooldown then
		return
	end
	self.attackCooldowns[player] = now

	local animID = CharacterFormulas.DefaultAnimations.HitMelee -- Animación por defecto
	-- Aquí iría la lógica para obtener la animación del arma equipada
	
	if animID and animID ~= "rbxassetid://" then
		self.isAttacking[player] = true
		Remotes.PlayAnimation:FireClient(player, animID, timeMultiplier, "BasicAttack", nil)
	end
end

-- Función privada para manejar el uso de una habilidad
function CombatService:_onSkillUse(player, skillId, target)
	local playerData = self.PlayerDataService:GetData(player)
	local character = player.Character
	if not playerData or not character or not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 or self.isAttacking[player] then
		return
	end

	local skillData = SkillConfig[skillId]
	if not skillData then return end

	-- Validación de objetivo
	if skillData.TargetType == "Enemy" then
		if not target or not target:IsA("Model") or not target:FindFirstChildOfClass("Humanoid") or not target.PrimaryPart then
			return -- El objetivo no es válido
		end
		local distance = (character.PrimaryPart.Position - target.PrimaryPart.Position).Magnitude
		if distance > skillData.MaxRange then
			-- Remotes.ShowNotification:FireClient(player, "Objetivo fuera de rango.")
			return
		end
	end

	local now = os.clock()
	local lastUsed = self.skillCooldowns[player][skillId] or 0
	if now - lastUsed < skillData.BaseCooldown then
		-- Remotes.ShowNotification:FireClient(player, "Habilidad en cooldown.")
		return
	end

	if playerData.CurrentMP < skillData.ManaCost then
		-- Remotes.ShowNotification:FireClient(player, "No tienes suficiente maná.")
		return
	end

	playerData.CurrentMP = playerData.CurrentMP - skillData.ManaCost
	self.skillCooldowns[player][skillId] = now
	Remotes.PlayerStatUpdate:FireClient(player, {CurrentMP = playerData.CurrentMP, MaxMP = playerData.MaxMP})

	-- Encarar al objetivo si es necesario
	if target and target.PrimaryPart then
		local lookAtPos = target.PrimaryPart.Position
		character:SetPrimaryPartCFrame(CFrame.new(character.PrimaryPart.Position, Vector3.new(lookAtPos.X, character.PrimaryPart.Position.Y, lookAtPos.Z)))
	end

	local derivedStats = self.StatsService:GetDerivedStats(player)
	local timeMultiplier = derivedStats.TimeMultiplier or 1
	if skillData.AnimationID and skillData.AnimationID ~= "rbxassetid://" then
		self.isAttacking[player] = true
		Remotes.PlayAnimation:FireClient(player, skillData.AnimationID, timeMultiplier, "Skill", {skillId = skillId, target = target})
	else
		-- Lógica para skills sin animación (ej. buffs instantáneos)
		self:_onSkillActionTriggered(player, "Skill", {skillId = skillId, target = target})
	end
end

-- Función que se llama desde la animación en el cliente
function CombatService:_onSkillActionTriggered(player, actionType, actionData)
	local playerData = self.PlayerDataService:GetData(player)
	if not playerData or not player.Character then return end

	if actionType == "BasicAttack" then
		-- Lógica del hitbox para el ataque básico...
		print("Aplicando daño de ataque básico")
	elseif actionType == "Skill" then
		local skillId = actionData.skillId
		local target = actionData.target
		local skillData = SkillConfig[skillId]
		if not skillData then return end

		if skillData.TargetType == "Enemy" and target then
			-- Lógica de daño para habilidad con objetivo
			local damage = CharacterFormulas.CalculateSkillDamage(playerData, skillData)
			local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
			if targetHumanoid then
				targetHumanoid:TakeDamage(damage)
				-- Remotes.ShowDamageIndicator:FireAllClients(target, damage, false)
			end
			print("Aplicando daño de '"..skillId.."' al objetivo: "..target.Name)
		else
			-- Lógica de daño para habilidad sin objetivo (AoE alrededor del jugador, etc)
			print("Aplicando efecto de '"..skillId.."' (sin objetivo)")
		end
	end
end

-- Función que se llama cuando la animación termina en el cliente
function CombatService:_onAnimationFinished(player)
	self.isAttacking[player] = false
end

return CombatService
