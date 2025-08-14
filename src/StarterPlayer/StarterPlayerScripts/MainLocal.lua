--[[
    Archivo: MainLocal.lua
    Tipo: LocalScript
    Ubicacion: StarterPlayer/StarterPlayerScripts/
    Descripcion: El cerebro del cliente. Controla la UI, los inputs y los efectos visuales.
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Comm = require(ReplicatedStorage.Shared.Comm)
local SkillConfig = require(ReplicatedStorage.Shared.SkillConfig)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local assignedSkills = {}

-- == GESTI�N DE UI ==
local StatusUI = playerGui:WaitForChild("MainHudGui"):WaitForChild("StatusUI")
local HealthBar = StatusUI:WaitForChild("HealthBar"):WaitForChild("Bar")
local HealthText = StatusUI:WaitForChild("HealthBar"):WaitForChild("HealthText")
local ManaBar = StatusUI:WaitForChild("ManaBar"):WaitForChild("Bar")
local ManaText = StatusUI:WaitForChild("ManaBar"):WaitForChild("ManaText")
local ExpBar = StatusUI:WaitForChild("ExpBar"):WaitForChild("Bar")
local ExpText = StatusUI:WaitForChild("ExpBar"):WaitForChild("ExpText")
local LevelText = StatusUI:WaitForChild("LevelText")
local ZenText = StatusUI:WaitForChild("ZenText")

local SkillBarFrame = playerGui:WaitForChild("SkillBarGui"):WaitForChild("SkillBarFrame")
local SkillSlots = {
	SkillBarFrame:WaitForChild("SkillSlot1"),
	SkillBarFrame:WaitForChild("SkillSlot2"),
	SkillBarFrame:WaitForChild("SkillSlot3"),
	SkillBarFrame:WaitForChild("SkillSlot4"),
}

local function updateBar(bar, percentage)
	percentage = math.clamp(percentage, 0, 1)
	local goal = UDim2.new(percentage, 0, 1, 0)
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tween = TweenService:Create(bar, tweenInfo, {Size = goal})
	tween:Play()
end

local function updateSkillBar()
	for i, slot in ipairs(SkillSlots) do
		local skillId = assignedSkills[i]
		if skillId and SkillConfig[skillId] then
			slot.Image = SkillConfig[skillId].IconID
		else
			slot.Image = ""
		end
	end
end

Comm.Client:On("InitialStatsUpdate", function(data)
	print("Recibiendo datos iniciales:", data)
	LevelText.Text = "Lv. " .. tostring(data.Nivel)
	ZenText.Text = "Zen: " .. tostring(data.Zen)
	HealthText.Text = tostring(data.CurrentHP) .. " / " .. tostring(data.MaxHP)
	updateBar(HealthBar, data.CurrentHP / data.MaxHP)
	ManaText.Text = tostring(data.CurrentMP) .. " / " .. tostring(data.MaxMP)
	updateBar(ManaBar, data.CurrentMP / data.MaxMP)

	assignedSkills = data.Skills or {}
	updateSkillBar()
end)

Comm.Client:On("PlayerStatChanged", function(statName, newValue, maxValue)
	if statName == "CurrentHP" then
		HealthText.Text = tostring(newValue) .. " / " .. tostring(maxValue)
		updateBar(HealthBar, newValue / maxValue)
	elseif statName == "CurrentMP" then
		ManaText.Text = tostring(newValue) .. " / " .. tostring(maxValue)
		updateBar(ManaBar, newValue / maxValue)
	elseif statName == "Zen" then
		ZenText.Text = "Zen: " .. tostring(newValue)
	elseif statName == "Nivel" then
		LevelText.Text = "Lv. " .. tostring(newValue)
	end
end)

-- == GESTI�N DE INPUT ==
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Comm.Client:Fire("RequestBasicAttack")
	end

	if input.UserInputType == Enum.UserInputType.Keyboard then
		local skillIndex
		if input.KeyCode == Enum.KeyCode.One then skillIndex = 1
		elseif input.KeyCode == Enum.KeyCode.Two then skillIndex = 2
		elseif input.KeyCode == Enum.KeyCode.Three then skillIndex = 3
		elseif input.KeyCode == Enum.KeyCode.Four then skillIndex = 4
		end

		if skillIndex then
			local skillId = assignedSkills[skillIndex]
			if skillId then
				print("Solicitando usar skill:", skillId)
				Comm.Client:Fire("RequestSkillUse", skillId)
			end
		end
	end
end)

-- == GESTI�N DE ANIMACIONES Y EFECTOS ==
Comm.Client:On("PlayAnimation", function(animationId, timeMultiplier)
	local character = player.Character
	if not character or not character:FindFirstChild("Humanoid") then return end
	local humanoid = character.Humanoid
	local animator = humanoid:WaitForChild("Animator")

	local animation = Instance.new("Animation")
	animation.AnimationId = animationId

	local animationTrack = animator:LoadAnimation(animation)
	animationTrack:Play()
	animationTrack:AdjustSpeed(1 / timeMultiplier)
end)

Comm.Client:On("ShowDamageIndicator", function(target, damage, isCritical)
	-- L�gica futura para mostrar n�meros de da�o flotantes.
end)
