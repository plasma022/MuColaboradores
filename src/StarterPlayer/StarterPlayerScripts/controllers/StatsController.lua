--[[
    StatsController.lua
    Maneja la lgica de la UI de estadsticas del personaje.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Comm = require(ReplicatedStorage.Shared.Comm)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local StatsController = {}

function StatsController:init()
    -- Referencias a la UI
    local statsGui = playerGui:WaitForChild("CharacterStatsGui")
    local statsFrame = statsGui:WaitForChild("StatsFrame")
    local openStatsButton = playerGui:WaitForChild("MainHudGui"):WaitForChild("StatusUI"):WaitForChild("OpenStatsButton")

    -- Referencias a los TextLabels de valores
    local levelText = statsFrame:WaitForChild("LevelText")
    local pointsText = statsFrame:WaitForChild("PointsAvailableText")
    local strText = statsFrame:WaitForChild("STR_Text")
    local agiText = statsFrame:WaitForChild("AGI_Text")
    local vitText = statsFrame:WaitForChild("VIT_Text")
    local eneText = statsFrame:WaitForChild("ENE_Text")

    -- Referencias a los TextLabels de descripciones
    local strDesc = statsFrame:WaitForChild("STR_Desc")
    local agiDesc = statsFrame:WaitForChild("AGI_Desc")
    local vitDesc = statsFrame:WaitForChild("VIT_Desc")
    local eneDesc = statsFrame:WaitForChild("ENE_Desc")

    -- Referencias a los Botones
    local strButton = statsFrame:WaitForChild("STR_Button")
    local agiButton = statsFrame:WaitForChild("AGI_Button")
    local vitButton = statsFrame:WaitForChild("VIT_Button")
    local eneButton = statsFrame:WaitForChild("ENE_Button")

    -- Funcin para actualizar la UI
    local function updateStatsUI(stats)
        if not stats then return end

        levelText.Text = "Nivel: " .. tostring(stats.Level or 1)
        pointsText.Text = "Puntos Disponibles: " .. tostring(stats.StatPoints or 0)
        strText.Text = "Fuerza: " .. tostring(stats.STR or 0)
        agiText.Text = "Agilidad: " .. tostring(stats.AGI or 0)
        vitText.Text = "Vitalidad: " .. tostring(stats.VIT or 0)
        eneText.Text = "Energa: " .. tostring(stats.ENE or 0)

        local playerClass = stats.ClassName
        local damageType = (playerClass == "DarkWizard") and "Mgico" or "Fsico"

        strDesc.Text = string.format("Dao %s: %s\nVelocidad de Ataque: %s", damageType, tostring(stats.TotalDamage or 0), tostring(stats.TotalAttackSpeed or 0))
        agiDesc.Text = "Defensa Total: " .. tostring(stats.TotalDefense or 0)
        vitDesc.Text = string.format("Vida Mxima: %d/%d", math.floor(stats.HP or 0), math.floor(stats.MaxHP or 0))
        eneDesc.Text = string.format("Man Mximo: %d/%d", math.floor(stats.MP or 0), math.floor(stats.MaxMP or 0))

        local hasPoints = (stats.StatPoints or 0) > 0
        strButton.Visible = hasPoints
        agiButton.Visible = hasPoints
        vitButton.Visible = hasPoints
        eneButton.Visible = hasPoints
    end

    -- Conectar botones
    strButton.MouseButton1Click:Connect(function() Comm.Client:Fire("AssignStatPoint", "Fuerza") end)
    agiButton.MouseButton1Click:Connect(function() Comm.Client:Fire("AssignStatPoint", "Agilidad") end)
    vitButton.MouseButton1Click:Connect(function() Comm.Client:Fire("AssignStatPoint", "Vitalidad") end)
    eneButton.MouseButton1Click:Connect(function() Comm.Client:Fire("AssignStatPoint", "Energa") end)

    -- Abrir/cerrar ventana
    local function toggleStatsWindow()
        statsGui.Enabled = not statsGui.Enabled
    end

    openStatsButton.MouseButton1Click:Connect(toggleStatsWindow)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.C then
            toggleStatsWindow()
        end
    end)

    -- Suscribirse a eventos
    Comm.Client:On("UpdateStats", updateStatsUI)

    -- Estado inicial
    statsGui.Enabled = false
end

return StatsController
Controller