--[[
	HudController.lua
	Controlador para la Interfaz de Usuario principal (HUD).
	Gestiona las barras de vida, maná, XP y textos de estado.
	Ubicación: StarterPlayer/StarterPlayerScripts/controllers/
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Módulos compartidos
local Remotes = require(ReplicatedStorage.Shared.Remotes)

-- Referencias al jugador y la UI
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainHud = playerGui:WaitForChild("MainHudGui")
local statusUI = mainHud:WaitForChild("StatusUI")

-- Elementos específicos del HUD
local healthBar = statusUI.HealthBar.Bar
local healthText = statusUI.HealthBar.HealthText
local manaBar = statusUI.ManaBar.Bar
local manaText = statusUI.ManaBar.ManaText
local expBar = statusUI.ExpBar.Bar
local expText = statusUI.ExpBar.ExpText
local levelText = statusUI.LevelText
local zenText = statusUI.ZenText

local HudController = {}

-- Función privada para animar las barras
local function updateBar(bar, percentage)
	percentage = math.clamp(percentage, 0, 1)
	local goal = UDim2.new(percentage, 0, 1, 0)
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tween = TweenService:Create(bar, tweenInfo, {Size = goal})
	tween:Play()
end

-- Función principal que se ejecuta desde main.client.lua
function HudController:Start()
	-- Escuchamos el evento que envía TODOS los datos iniciales
	Remotes.PlayerStatUpdate.OnClientEvent:Connect(function(stats)
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
	end)

	print("[HudController] Listo y escuchando actualizaciones de stats.")
end

return HudController
