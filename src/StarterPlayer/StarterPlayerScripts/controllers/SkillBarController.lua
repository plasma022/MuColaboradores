--[[
	SkillBarController.lua
	Gestiona la UI de la barra de habilidades y la habilidad seleccionada.
	Ubicación: StarterPlayer/StarterPlayerScripts/controllers/
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SkillConfig = require(ReplicatedStorage.Shared.config.SkillConfig)

local skillBarGui = playerGui:WaitForChild("SkillBarGui")
local skillBarFrame = skillBarGui:WaitForChild("SkillBarFrame")

local SkillBarController = {}
SkillBarController.selectedSkillId = nil
SkillBarController.skillSlots = {}

local keyToSkillIndex = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
}

function SkillBarController:Start()
	-- Guardamos una referencia a los slots de la UI
	for i = 1, 4 do
		self.skillSlots[i] = skillBarFrame:FindFirstChild("SkillSlot" .. i)
	end

	-- Escuchamos la actualización inicial de stats que contiene las habilidades
	Remotes.PlayerStatUpdate.OnClientEvent:Connect(function(stats)
		self:UpdateSkillBar(stats.Skills or {})
	end)

	print("[SkillBarController] Listo.")
end

function SkillBarController:UpdateSkillBar(skills)
	-- Limpiamos los slots actuales
	for _, slot in ipairs(self.skillSlots) do
		if slot then
			slot:SetAttribute("SkillId", nil)
			slot.Image = ""
		end
	end

	-- Poblamos con las nuevas habilidades
	for i, skillId in ipairs(skills) do
		local slot = self.skillSlots[i]
		local skillData = SkillConfig[skillId]
		if slot and skillData then
			slot.Image = skillData.IconID
			slot:SetAttribute("SkillId", skillId)
		end
	end
end

function SkillBarController:HandleKeyPress(keyCode)
	local skillIndex = keyToSkillIndex[keyCode]
	if not skillIndex then return end

	local skillSlot = self.skillSlots[skillIndex]
	local skillId = skillSlot and skillSlot:GetAttribute("SkillId")

	if skillId then
		if self.selectedSkillId == skillId then
			self.selectedSkillId = nil -- Deseleccionar
			print("[SkillBar] Habilidad deseleccionada.")
			-- Aquí puedes añadir un efecto visual para deseleccionar
		else
			self.selectedSkillId = skillId -- Seleccionar
			print("[SkillBar] Habilidad preparada: " .. tostring(skillId))
			-- Aquí puedes añadir un efecto visual para resaltar el slot seleccionado
		end
	end
end

function SkillBarController:GetSelectedSkill()
	return self.selectedSkillId
end

return SkillBarController
