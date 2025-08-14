--[[
    Archivo: MainLocal.lua
    Tipo: LocalScript
    Ubicaci�n: StarterPlayer/StarterPlayerScripts/
    Descripci�n: El cerebro del cliente. Controla la UI, los inputs y los efectos visuales.
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Comm = require(ReplicatedStorage.Shared.Comm)
local SkillConfig = require(ReplicatedStorage.Shared.SkillConfig)

local player = Players.LocalPlayer
local assignedSkills = {}
local originalWalkSpeed = 16 -- Velocidad de caminar por defecto de un Humanoide

-- == GESTI�N DE UI ==
-- ... (toda tu l�gica de UI sigue igual) ...

-- == GESTI�N DE INPUT ==
-- ... (toda tu l�gica de Input sigue igual) ...

-- == GESTI�N DE ANIMACIONES Y EVENTOS ==
Comm.Client:On("PlayAnimation", function(animationId, timeMultiplier, actionType, actionId)
	local character = player.Character
	if not character or not character:FindFirstChild("Humanoid") then return end
	local humanoid = character.Humanoid
	local animator = humanoid:WaitForChild("Animator")

	-- Guardamos la velocidad original y congelamos al jugador.
	originalWalkSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = 0

	local animation = Instance.new("Animation")
	animation.AnimationId = animationId

	local animationTrack = animator:LoadAnimation(animation)

	-- == SOLUCI�N AL BUG DE BUCLE ==
	-- Nos aseguramos de que la animaci�n no se repita.
	animationTrack.Looped = false

	animationTrack:Play()
	animationTrack:AdjustSpeed(1 / timeMultiplier)

	local keyframeConnection
	keyframeConnection = animationTrack.KeyframeReached:Connect(function(keyframeName)
		if keyframeName == "Hit" then
			Comm.Client:Fire("SkillActionTriggered", actionType, actionId)
			-- Llamar a tus VFX de impacto aqu�
		elseif keyframeName == "Cast" then
			-- Llamar a tus VFX de casteo aqu�
		end
	end)

	-- == SOLUCI�N AL BUG DE PERSONAJE CONGELADO ==
	-- Cuando la animaci�n termina, desconectamos los listeners y devolvemos el movimiento.
	animationTrack.Stopped:Connect(function()
		if keyframeConnection then
			keyframeConnection:Disconnect()
		end
		humanoid.WalkSpeed = originalWalkSpeed -- Devolvemos la velocidad.
		Comm.Client:Fire("AnimationFinished") -- Le avisamos al servidor que ya no estamos atacando.
	end)
end)

-- El resto de tus listeners de Comm.Client...
