--[[
	StatsController.lua
	Controla la lógica de la interfaz de usuario de estadísticas del personaje (CharacterStatsGui).
	Ubicación: StarterPlayer/StarterPlayerScripts/controllers/
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Módulos y Remotes
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Referencias a la UI de Stats
local statsGui = playerGui:WaitForChild("CharacterStatsGui")
local statsFrame = statsGui:WaitForChild("StatsFrame")
local pointsLabel = statsFrame:WaitForChild("PointsAvailableText")
local levelLabel = statsFrame:WaitForChild("LevelText")

-- Labels de cada stat
local strLabel = statsFrame:WaitForChild("STR_Text")
local agiLabel = statsFrame:WaitForChild("AGI_Text")
local vitLabel = statsFrame:WaitForChild("VIT_Text")
local eneLabel = statsFrame:WaitForChild("ENE_Text")

-- Botones para añadir stats
local strButton = statsFrame:WaitForChild("STR_Button")
local agiButton = statsFrame:WaitForChild("AGI_Button")
local vitButton = statsFrame:WaitForChild("VIT_Button")
local eneButton = statsFrame:WaitForChild("ENE_Button")

local StatsController = {}

-- Función para actualizar toda la información en la UI
local function updateStatsUI(playerData)
	if not playerData then return end

	pointsLabel.Text = "Puntos: " .. tostring(playerData.PuntosDeStatsDisponibles or 0)
	levelLabel.Text = "Nivel: " .. tostring(playerData.Nivel or 1)

	local baseStats = playerData.EstadisticasBase
	if baseStats then
		strLabel.Text = "Fuerza: " .. tostring(baseStats.Fuerza or 0)
		agiLabel.Text = "Agilidad: " .. tostring(baseStats.Agilidad or 0)
		vitLabel.Text = "Vitalidad: " .. tostring(baseStats.Vitalidad or 0)
		eneLabel.Text = "Energía: " .. tostring(baseStats.Energia or 0)
	end
	
	-- Habilitar o deshabilitar los botones si hay puntos disponibles
	local hasPoints = (playerData.PuntosDeStatsDisponibles or 0) > 0
	strButton.Visible = hasPoints
	agiButton.Visible = hasPoints
	vitButton.Visible = hasPoints
	eneButton.Visible = hasPoints
end

-- Función para asignar un punto
local function assignPoint(statName)
	-- Deshabilitamos los botones para evitar doble click
	strButton.Interactable = false
	agiButton.Interactable = false
	vitButton.Interactable = false
	eneButton.Interactable = false

	-- Llamamos al servidor
	local result = Remotes.AssignStatPoint:InvokeServer(statName)
	
	if result and not result.success then
		warn("No se pudo asignar el punto de stat: " .. result.message)
	end

	-- Rehabilitamos los botones
	strButton.Interactable = true
	agiButton.Interactable = true
	vitButton.Interactable = true
	eneButton.Interactable = true
end

function StatsController:Start()
	-- Conectar los botones
	strButton.MouseButton1Click:Connect(function() assignPoint("Fuerza") end)
	agiButton.MouseButton1Click:Connect(function() assignPoint("Agilidad") end)
	vitButton.MouseButton1Click:Connect(function() assignPoint("Vitalidad") end)
	eneButton.MouseButton1Click:Connect(function() assignPoint("Energia") end)

	-- Escuchar las actualizaciones de datos del servidor
	Remotes.PlayerStatUpdate.OnClientEvent:Connect(updateStatsUI)

	print("[StatsController] Iniciado.")
end

-- Función para abrir/cerrar la ventana
function StatsController:Toggle()
	statsGui.Enabled = not statsGui.Enabled
end

return StatsController
