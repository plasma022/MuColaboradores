--[[
    Archivo: CombatService.lua
    Tipo: Script
    Ubicacin: ServerScriptService/
    Descripcin: Maneja toda la lgica de combate del lado del servidor.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local function safeRequireShared(name)
	local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 5)
	if not shared then warn("[CombatService] ReplicatedStorage.Shared no disponible") return nil end
	local module = shared:FindFirstChild(name) or shared:WaitForChild(name, 5)
	if not module then warn("[CombatService] Módulo '"..name.."' no encontrado en Shared") return nil end
	local ok, res = pcall(require, module)
	if not ok then warn("[CombatService] Error al require: ", res) return nil end
	return res
end

local function safeRequireServer(pathParts)
	local current = ServerScriptService
	for _, part in ipairs(pathParts) do
		current = current:FindFirstChild(part) or current:WaitForChild(part, 5)
		if not current then
			warn("[CombatService] No se encontró: " .. table.concat(pathParts, "."))
			return nil
		end
	end
		if not current:IsA("ModuleScript") then
			local targetName = pathParts[#pathParts]
			local variants = {targetName, targetName..".server", targetName..".server.lua", targetName..".lua"}
			local found = nil
			for _, d in ipairs(current:GetDescendants()) do
				if d:IsA("ModuleScript") then
					local lname = string.lower(d.Name)
					local ok = false
					for _, v in ipairs(variants) do
						if lname == string.lower(v) or string.find(lname, string.lower(v), 1, true) then ok = true break end
					end
					if ok then found = d break end
				end
			end
			if not found then
				for _, d in ipairs(ServerScriptService:GetDescendants()) do
					if d:IsA("ModuleScript") then
						local lname = string.lower(d.Name)
						local ok = false
						for _, v in ipairs(variants) do
							if lname == string.lower(v) or string.find(lname, string.lower(v), 1, true) then ok = true break end
						end
						if ok then found = d break end
					end
				end
			end
			if found then
				current = found
			else
				warn("[CombatService] Objeto encontrado no es ModuleScript: " .. tostring(current.Name))
				return nil
			end
		end
	local ok, res = pcall(require, current)
	if not ok then warn("[CombatService] Error al require: ", res) return nil end
	return res
end

local DataManager = safeRequireServer({"core", "player_data_manager"})
local Comm = safeRequireShared("comm")
local Formulas = safeRequireShared("character_formulas")
local SkillConfig = safeRequireShared("skill_config")

if not DataManager then warn("[CombatService] player_data_manager no disponible, abortando inicializacion.") return end
if not Comm or not Comm.Server then warn("[CombatService] Comm no disponible, abortando inicializacion.") return end

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