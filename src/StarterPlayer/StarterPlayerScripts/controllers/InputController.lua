--[[
	InputController.lua
	Controlador para toda la entrada del jugador (teclado y ratón).
	Gestiona ataques, uso de habilidades, selección de skills y cámara.
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Módulos
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SkillConfig = require(ReplicatedStorage.Shared.config.SkillConfig)

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local InputController = {}
InputController.TargetingController = nil
InputController.SkillBarController = nil
InputController.AnimationController = nil
InputController.StatsController = nil

local cameraMode = 1 -- 1: Default, 2: Locked, 3: First Person

-- Lógica completa de la cámara
local function updateCameraMode()
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if cameraMode == 1 then -- Default
		workspace.CurrentCamera.CameraType = Enum.CameraType.Follow
		workspace.CurrentCamera.CameraSubject = humanoid
		player.CameraMode = Enum.CameraMode.Classic
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	elseif cameraMode == 2 then -- Locked
		workspace.CurrentCamera.CameraType = Enum.CameraType.Follow
		workspace.CurrentCamera.CameraSubject = humanoid
		player.CameraMode = Enum.CameraMode.Classic
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	elseif cameraMode == 3 then -- First Person
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	end
end

function InputController:Start(controllers)
	-- Obtenemos referencias a otros controladores que necesitamos
	self.TargetingController = controllers.TargetingController
	self.SkillBarController = controllers.SkillBarController
	self.AnimationController = controllers.AnimationController
	self.StatsController = controllers.StatsController

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		-- Lógica de teclado que debe funcionar siempre
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.X then
				cameraMode = (cameraMode % 3) + 1
				updateCameraMode()
				return
			end
			if input.KeyCode == Enum.KeyCode.C then
				if self.StatsController then
					self.StatsController:Toggle()
				end
				return
			end
		end

		if gameProcessed or not self.AnimationController:IsReadyForCombat() then return end
		
		-- Clic Izquierdo: Ataque básico
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			Remotes.RequestBasicAttack:FireServer()
		end
		
		-- Clic Derecho: Usar habilidad seleccionada
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			local selectedSkillId = self.SkillBarController:GetSelectedSkill()
			if not selectedSkillId then return end

			local skillData = SkillConfig[selectedSkillId]
			if not skillData then return end

			local target = mouse.Target
			if skillData.TargetType == "Enemy" then
				if target and target.Parent and target.Parent:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(target.Parent) then
					self.TargetingController:SetTarget(target.Parent)
					local currentTarget = self.TargetingController:GetCurrentTarget()
					
					local distance = (player.Character.PrimaryPart.Position - currentTarget.PrimaryPart.Position).Magnitude
					if distance <= skillData.MaxRange then
						Remotes.RequestSkillUse:FireServer(selectedSkillId, currentTarget)
					else
						print("Objetivo fuera de rango.")
					end
				else
					self.TargetingController:ClearTarget()
				end
			else
				-- Habilidad sin objetivo (ej. un buff)
				Remotes.RequestSkillUse:FireServer(selectedSkillId)
			end
		end

		-- Teclado: Seleccionar habilidad (1, 2, 3, 4)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			self.SkillBarController:HandleKeyPress(input.KeyCode)
		end
	end)

	print("[InputController] Listo y escuchando entradas.")
end

return InputController
