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

Comm.Server:On("RequestSkillUse", function(player, skillId, target)
	local profile = DataManager:GetProfile(player)
	local character = player.Character
	if not profile or not character or not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 or isAttacking[player] then
		return
	end

	local skillData = SkillConfig[skillId]
	if not skillData then return end

    -- Validacin de objetivo
    if skillData.TargetType == "Enemy" then
        if not target or not target:IsA("Model") or not target:FindFirstChildOfClass("Humanoid") or not target.PrimaryPart then
            return -- El objetivo no es vlido
        end
        local distance = (character.PrimaryPart.Position - target.PrimaryPart.Position).Magnitude
        if distance > skillData.MaxRange then
            Comm.Server:Fire(player, "ShowNotification", "Objetivo fuera de rango.")
            return
        end
    end

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

	profile.Data.CurrentMP = profile.Data.CurrentMP - skillData.ManaCost
	skillCooldowns[player][skillId] = now
	Comm.Server:Fire(player, "PlayerStatChanged", "CurrentMP", profile.Data.CurrentMP, profile.DerivedStats.MaxMP)

    -- Encarar al objetivo si es necesario
    if target and target.PrimaryPart then
        local lookAtPos = target.PrimaryPart.Position
        character:SetPrimaryPartCFrame(CFrame.new(character.PrimaryPart.Position, Vector3.new(lookAtPos.X, character.PrimaryPart.Position.Y, lookAtPos.Z)))
    end

	local timeMultiplier = profile.DerivedStats.TimeMultiplier
	if skillData.AnimationID and skillData.AnimationID ~= "rbxassetid://" then
		isAttacking[player] = true
        -- Pasamos el objetivo a PlayAnimation para que se use en SkillActionTriggered
		Comm.Server:Fire(player, "PlayAnimation", skillData.AnimationID, timeMultiplier, "Skill", {skillId = skillId, target = target})
	else
		-- Lgica para skills sin animacin
	end
end)

Comm.Server:On("SkillActionTriggered", function(player, actionType, actionData)
	local profile = DataManager:GetProfile(player)
	if not profile or not player.Character then return end

	if actionType == "BasicAttack" then
		-- Lgica del hitbox para el ataque bsico...
	elseif actionType == "Skill" then
        local skillId = actionData.skillId
        local target = actionData.target
        local skillData = SkillConfig[skillId]

        if not skillData then return end

        if skillData.TargetType == "Enemy" and target then
            -- Lgica de dao para habilidad con objetivo
            print("Aplicando dao de '"..skillId.."' al objetivo: "..target.Name)
            -- Aqu ira la lgica de dao, AoE alrededor del target, etc.
        else
            -- Lgica de dao para habilidad sin objetivo (AoE alrededor del jugador, etc)
            print("Aplicando dao de '"..skillId.."' (sin objetivo)")
        end
	end
end)

Comm.Server:On("AnimationFinished", function(player)
	isAttacking[player] = false
end)

-- Conectar eventos de jugador
Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(playerRemoving)