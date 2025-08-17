--[[
    Archivo: MainLocal.lua
    Tipo: LocalScript
    Ubicacin: StarterPlayer/StarterPlayerScripts/
    Descripcin: El cerebro del cliente. Controla la UI, los inputs y los efectos visuales.
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Helper seguro para require que espera al ModuleScript dentro de ReplicatedStorage.Shared
local function safeRequireShared(moduleName)
	local shared = ReplicatedStorage:WaitForChild("Shared", 5)
	if not shared then
		warn("[MainLocal] ReplicatedStorage.Shared no disponible (timeout)")
		return nil
	end
	local module = shared:FindFirstChild(moduleName)
	if not module then
		warn("[MainLocal] Módulo '"..moduleName.."' no encontrado en ReplicatedStorage.Shared")
		return nil
	end
	local ok, res = pcall(require, module)
	if not ok then
		warn("[MainLocal] Error al require de ", moduleName, res)
		return nil
	end
	return res
end

local Comm = safeRequireShared("comm")
local SkillConfig = safeRequireShared("skill_config")

local player = Players.LocalPlayer
local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 5)
local mouse = player:GetMouse()

-- Flags y estados
local isReadyForCombat = false
local originalWalkSpeed = 16
local skillSlotConnections = {}
local selectedSkill = nil
local cameraMode = 1 -- 1: Default, 2: Locked, 3: First Person
local currentTarget = nil
local selectionBox = nil

-- == OBTENER ELEMENTOS DE LA UI ==
local mainHud = playerGui:FindFirstChild("MainHudGui") or playerGui:WaitForChild("MainHudGui", 5)
local statusUI = mainHud and (mainHud:FindFirstChild("StatusUI") or mainHud:WaitForChild("StatusUI", 5))
if not mainHud or not statusUI then
	warn("[MainLocal] No se encontraron elementos de HUD. Algunas funcionalidades quedarán deshabilitadas hasta que el HUD esté presente.")
end
local healthBar = statusUI and (statusUI:FindFirstChild("HealthBar") and statusUI.HealthBar:FindFirstChild("Bar"))
local healthText = statusUI and (statusUI:FindFirstChild("HealthBar") and statusUI.HealthBar:FindFirstChild("HealthText"))
local manaBar = statusUI and (statusUI:FindFirstChild("ManaBar") and statusUI.ManaBar:FindFirstChild("Bar"))
local manaText = statusUI and (statusUI:FindFirstChild("ManaBar") and statusUI.ManaBar:FindFirstChild("ManaText"))
local expBar = statusUI and (statusUI:FindFirstChild("ExpBar") and statusUI.ExpBar:FindFirstChild("Bar"))
local expText = statusUI and (statusUI:FindFirstChild("ExpBar") and statusUI.ExpBar:FindFirstChild("ExpText"))
local levelText = statusUI and statusUI:FindFirstChild("LevelText")
local zenText = statusUI and statusUI:FindFirstChild("ZenText")
local skillBarGui = playerGui and (playerGui:FindFirstChild("SkillBarGui") or playerGui:WaitForChild("SkillBarGui", 5))
local skillBarFrame = skillBarGui and (skillBarGui:FindFirstChild("SkillBarFrame") or skillBarGui:WaitForChild("SkillBarFrame", 5))

-- == FUNCIONES DE UI, CMARA Y TARGETING ==
local function updateBar(bar, percentage)
	percentage = math.clamp(percentage, 0, 1)
	local goal = UDim2.new(percentage, 0, 1, 0)
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tween = TweenService:Create(bar, tweenInfo, {Size = goal})
	tween:Play()
end

local function updateCameraMode()
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

	if cameraMode == 1 then -- Default
		print("[CAMARA] Modo Libre")
        workspace.CurrentCamera.CameraType = Enum.CameraType.Follow
        workspace.CurrentCamera.CameraSubject = humanoid
		player.CameraMode = Enum.CameraMode.Classic
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	elseif cameraMode == 2 then -- Locked
		print("[CAMARA] Modo Bloqueado")
        workspace.CurrentCamera.CameraType = Enum.CameraType.Follow
        workspace.CurrentCamera.CameraSubject = humanoid
		player.CameraMode = Enum.CameraMode.Classic
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	elseif cameraMode == 3 then -- First Person
		print("[CAMARA] Modo Primera Persona")
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	end
end

local function clearTarget()
    currentTarget = nil
    if selectionBox then
        selectionBox.Adornee = nil
    end
end

local function setTarget(target)
    if not target or not target:FindFirstChildOfClass("Humanoid") then
        clearTarget()
        return
    end
    currentTarget = target
    if not selectionBox then
        selectionBox = Instance.new("SelectionBox")
        selectionBox.Color3 = Color3.new(1, 0, 0)
        selectionBox.LineThickness = 0.2
        selectionBox.Parent = playerGui
    end
    selectionBox.Adornee = target
end



local function updateSkillBar(skills)
	for _, connection in ipairs(skillSlotConnections) do
		connection:Disconnect()
	end
	skillSlotConnections = {}

	for _, slot in ipairs(skillBarFrame:GetChildren()) do
		if slot:IsA("ImageButton") then
			slot:SetAttribute("SkillId", nil)
			slot.Image = ""
		end
	end

	for i, skillId in ipairs(skills) do
		local skillSlot = skillBarFrame:FindFirstChild("SkillSlot" .. i)
		if skillSlot and SkillConfig[skillId] then
			local skillData = SkillConfig[skillId]
			skillSlot.Image = skillData.IconID
			skillSlot:SetAttribute("SkillId", skillId)
		end
	end
end

-- == RECEPCIN DE EVENTOS DEL SERVIDOR ==
Comm.Client:On("InitialStatsUpdate", function(stats)
	levelText.Text = "Lv. " .. tostring(stats.Nivel)
	zenText.Text = "Zen: " .. tostring(stats.Zen)
	healthText.Text = tostring(stats.CurrentHP) .. " / " .. tostring(stats.MaxHP)
	updateBar(healthBar, stats.CurrentHP / stats.MaxHP)
	manaText.Text = tostring(stats.CurrentMP) .. " / " .. tostring(stats.MaxMP)
	updateBar(manaBar, stats.CurrentMP / stats.MaxMP)
	
	if stats.MaxEXP and stats.MaxEXP > 0 then
		expText.Text = tostring(stats.CurrentEXP) .. " / " .. tostring(stats.MaxEXP)
		updateBar(expBar, stats.CurrentEXP / stats.MaxEXP)
	else
		expText.Text = "EXP: " .. tostring(stats.CurrentEXP)
		updateBar(expBar, 0)
	end

	updateSkillBar(stats.Skills or {})
	isReadyForCombat = true
end)

Comm.Client:On("PlayerStatChanged", function(statName, newValue, maxValue)
	if statName == "CurrentHP" then
		healthText.Text = tostring(newValue) .. " / " .. tostring(maxValue)
		updateBar(healthBar, newValue / maxValue)
	elseif statName == "CurrentMP" then
		manaText.Text = tostring(newValue) .. " / " .. tostring(maxValue)
		updateBar(manaBar, newValue / maxValue)
	elseif statName == "Zen" then
		zenText.Text = "Zen: " .. tostring(newValue)
	elseif statName == "Nivel" then
		levelText.Text = "Lv. " .. tostring(newValue)
	end
end)

-- == GESTIN DE INPUT (LgICA FINAL) ==
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- La tecla X para la cmara debe funcionar incluso si el combate no est listo
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.X then
		cameraMode = (cameraMode % 3) + 1
		updateCameraMode()
		return -- Detener para no procesar otros inputs de teclado
	end

	if gameProcessed then return end
	if not isReadyForCombat then return end
	
	-- Clic Izquierdo: Siempre ataque bsico
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Comm.Client:Fire("RequestBasicAttack")
	end
	
	-- Clic Derecho: Usa la habilidad seleccionada o establece un objetivo
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if not selectedSkill then return end

        local skillData = SkillConfig[selectedSkill]
        if not skillData then return end

        if skillData.TargetType == "Enemy" then
            local target = mouse.Target
            if target and target.Parent and target.Parent:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(target.Parent) then
                setTarget(target.Parent)
                -- Comprobar rango
                local distance = (player.Character.PrimaryPart.Position - currentTarget.PrimaryPart.Position).Magnitude
                if distance <= skillData.MaxRange then
                    Comm.Client:Fire("RequestSkillUse", selectedSkill, currentTarget)
                    clearTarget()
                else
                    print("Objetivo fuera de rango.")
                end
            else
                clearTarget()
            end
        else
            -- Habilidad sin objetivo
            Comm.Client:Fire("RequestSkillUse", selectedSkill)
        end
	end

	-- Teclado: Selecciona la habilidad
	if input.UserInputType == Enum.UserInputType.Keyboard then
		local keyToSkillIndex = {
			[Enum.KeyCode.One] = 1,
			[Enum.KeyCode.Two] = 2,
			[Enum.KeyCode.Three] = 3,
			[Enum.KeyCode.Four] = 4,
		}
		local skillIndex = keyToSkillIndex[input.KeyCode]
		
		if skillIndex then
			local skillSlot = skillBarFrame:FindFirstChild("SkillSlot" .. skillIndex)
			local skillId = skillSlot and skillSlot:GetAttribute("SkillId")
			if skillId then
                if selectedSkill == skillId then
                    -- Deseleccionar si se presiona la misma tecla
                    selectedSkill = nil
                    clearTarget()
                    print("[CLIENTE] Habilidad deseleccionada.")
                else
				    selectedSkill = skillId
                    clearTarget()
                    print("[CLIENTE] Habilidad preparada: " .. tostring(selectedSkill))
                end
				-- Aqu podras aadir un efecto visual para resaltar el slot seleccionado
			end
		end
	end
end)

local StatsController = require(script.Parent.controllers.StatsController)
StatsController:init()

-- == GESTIN DE ANIMACIONES Y EVENTOS ==
Comm.Client:On("PlayAnimation", function(animationId, timeMultiplier, actionType, actionData)
	local character = player.Character
	if not character or not character:FindFirstChild("Humanoid") then return end
	local humanoid = character.Humanoid
	local animator = humanoid:WaitForChild("Animator")
	
	originalWalkSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = 0

	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	
	local animationTrack = animator:LoadAnimation(animation)
	
	animationTrack.Looped = false
	
	animationTrack:Play()
	animationTrack:AdjustSpeed(1 / timeMultiplier)

	local keyframeConnection
	keyframeConnection = animationTrack.KeyframeReached:Connect(function(keyframeName)
		if keyframeName == "Hit" then
			Comm.Client:Fire("SkillActionTriggered", actionType, actionData)
		elseif keyframeName == "Cast" then
			-- Lgica para VFX de casteo
		end
	end)

	animationTrack.Stopped:Connect(function()
		if keyframeConnection then
			keyframeConnection:Disconnect()
		end
		humanoid.WalkSpeed = originalWalkSpeed
		Comm.Client:Fire("AnimationFinished")
	end)
end)

Comm.Client:On("ShowDamageIndicator", function(target, damage, isCritical)
    -- Lgica futura para mostrar nmeros de dao flotantes.
end)