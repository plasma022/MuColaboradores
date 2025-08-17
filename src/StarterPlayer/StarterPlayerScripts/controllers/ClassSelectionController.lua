--[[
	ClassSelectionController.lua
	Controla la interfaz de usuario para la selección de clase.
	Ubicación: StarterPlayer/StarterPlayerScripts/controllers/
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui = playerGui:WaitForChild("ClassSelectionGui")
local frame = gui:WaitForChild("Frame")

local dkButton = frame:WaitForChild("DarkKnightButton")
local dwButton = frame:WaitForChild("DarkWizardButton")
local feButton = frame:WaitForChild("FairyElfButton")
local confirmButton = frame:WaitForChild("ConfirmButton")
local descriptionLabel = frame:WaitForChild("DescriptionLabel")

local ClassSelectionController = {}

local selectedClass = nil

local DESCRIPTIONS = {
	["DarkKnight"] = "Dark Knight: Maestro del combate cuerpo a cuerpo, con gran fuerza y vitalidad.",
	["DarkWizard"] = "Dark Wizard: Conjurador de poderosa magia arcana, su poder reside en su energía.",
	["FairyElf"] = "Fairy Elf: Arquera ágil y precisa, capaz de atacar desde la distancia y dar soporte."
}

local function updateDescription(className)
	selectedClass = className
	descriptionLabel.Text = DESCRIPTIONS[className] or "Selecciona una clase..."
	confirmButton.Visible = true
end

function ClassSelectionController:Start()
	dkButton.MouseButton1Click:Connect(function() updateDescription("DarkKnight") end)
	dwButton.MouseButton1Click:Connect(function() updateDescription("DarkWizard") end)
	feButton.MouseButton1Click:Connect(function() updateDescription("FairyElf") end)

	confirmButton.MouseButton1Click:Connect(function()
		if selectedClass then
			Remotes.SelectClass:FireServer(selectedClass)
			gui.Enabled = false
		end
	end)

	Remotes.ShowClassSelection.OnClientEvent:Connect(function()
		gui.Enabled = true
	end)

	-- Estado inicial
	confirmButton.Visible = false
	descriptionLabel.Text = "Selecciona una clase para comenzar tu aventura."
	gui.Enabled = false
	
	print("[ClassSelectionController] Iniciado.")
end

return ClassSelectionController
