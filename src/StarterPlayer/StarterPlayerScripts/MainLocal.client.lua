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

local Comm = require(ReplicatedStorage.Shared.Comm)
local SkillConfig = require(ReplicatedStorage.Shared.SkillConfig)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Flags y estados
local isReadyForCombat = false
local originalWalkSpeed = 16
local skillSlotConnections = {}
local selectedSkill = nil
local cameraMode = 1 -- 1: Default, 2: Locked, 3: First Person

-- == OBTENER ELEMENTOS DE LA UI ==
local mainHud = playerGui:WaitForChild("MainHudGui")
local statusUI = mainHud:WaitForChild("StatusUI")
local healthBar = statusUI:WaitForChild("HealthBar"):WaitForChild("Bar")
local healthText = statusUI:WaitForChild("HealthBar"):WaitForChild("HealthText")
local manaBar = statusUI:WaitForChild("ManaBar"):WaitForChild("Bar")
local manaText = statusUI:WaitForChild("ManaBar"):WaitForChild("ManaText")
local expBar = statusUI:WaitForChild("ExpBar"):WaitForChild("Bar")
local expText = statusUI:WaitForChild("ExpBar"):WaitForChild("ExpText")
local levelText = statusUI:WaitForChild("LevelText")
local zenText = statusUI:WaitForChild("ZenText")
local skillBarGui = playerGui:WaitForChild("SkillBarGui")
local skillBarFrame = skillBarGui:WaitForChild("SkillBarFrame")

-- == FUNCIONES DE UI Y CMARA ==
local function updateBar(bar, percentage)
	percentage = math.clamp(percentage, 0, 1)
	local goal = UDim2.new(percentage, 0, 1, 0)
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tween = TweenService:Create(bar, tweenInfo, {Size = goal})
	tween:Play()
end

local function updateCameraMode()
	if cameraMode == 1 then -- Default
		print("[CAMARA] Modo Libre")
		player.CameraMode = Enum.CameraMode.Classic
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	elseif cameraMode == 2 then -- Locked
		print("[CAMARA] Modo Bloqueado")
		player.CameraMode = Enum.CameraMode.Classic
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	elseif cameraMode == 3 then -- First Person
		print("[CAMARA] Modo Primera Persona")
		-- No es necesario cambiar MouseBehavior aqu, LockFirstPerson lo gestiona
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	end
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
	
	-- Clic Derecho: Usa la habilidad seleccionada
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if selectedSkill then
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
				selectedSkill = skillId
				print("[CLIENTE] Habilidad preparada: " .. tostring(selectedSkill))
				-- Aqu podras aadir un efecto visual para resaltar el slot seleccionado
			end
		end
	end
end)

local StatsController = require(script.Parent.controllers.StatsController)
StatsController:init()

-- == GESTIN DE ANIMACIONES Y EVENTOS ==
Comm.Client:On("PlayAnimation", function(animationId, timeMultiplier, actionType, actionId)
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
			Comm.Client:Fire("SkillActionTriggered", actionType, actionId)
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