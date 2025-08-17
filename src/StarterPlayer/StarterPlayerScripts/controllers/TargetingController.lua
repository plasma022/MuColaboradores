--[[
	TargetingController.lua
	Gestiona la lógica de selección de objetivos y el feedback visual (SelectionBox).
	Ubicación: StarterPlayer/StarterPlayerScripts/controllers/
]]

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TargetingController = {}
TargetingController.currentTarget = nil
TargetingController.selectionBox = nil

function TargetingController:Start()
	-- Preparamos el SelectionBox para usarlo después
	self.selectionBox = Instance.new("SelectionBox")
	self.selectionBox.Color3 = Color3.new(1, 0, 0)
	self.selectionBox.LineThickness = 0.2
	self.selectionBox.Parent = playerGui
	self.selectionBox.Adornee = nil -- Oculto al inicio

	print("[TargetingController] Listo.")
end

function TargetingController:ClearTarget()
	self.currentTarget = nil
	if self.selectionBox then
		self.selectionBox.Adornee = nil
	end
end

function TargetingController:SetTarget(target)
	if not target or not target:FindFirstChildOfClass("Humanoid") then
		self:ClearTarget()
		return
	end
	self.currentTarget = target
	if self.selectionBox then
		self.selectionBox.Adornee = target
	end
end

function TargetingController:GetCurrentTarget()
	return self.currentTarget
end

return TargetingController
