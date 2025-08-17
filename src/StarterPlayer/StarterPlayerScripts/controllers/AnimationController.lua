--[[
	AnimationController.lua
	Controla la reproducción de animaciones en el personaje del jugador.
	Ubicación: StarterPlayer/StarterPlayerScripts/controllers/
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local AnimationController = {}
AnimationController.isReady = true -- Flag para saber si se puede iniciar otra acción

function AnimationController:Start()
	Remotes.PlayAnimation.OnClientEvent:Connect(function(animationId)
		local character = player.Character
		if not character or not character:FindFirstChildOfClass("Humanoid") then return end
		
		local humanoid = character.Humanoid
		local animator = humanoid:WaitForChild("Animator")
		
		self.isReady = false -- Bloqueamos nuevas acciones
		
		local animation = Instance.new("Animation")
		animation.AnimationId = animationId
		
		local animationTrack = animator:LoadAnimation(animation)
		animationTrack:Play()

		animationTrack.Stopped:Connect(function()
			self.isReady = true -- Desbloqueamos acciones
			animation:Destroy()
		end)
	end)

	print("[AnimationController] Listo para reproducir animaciones.")
end

function AnimationController:IsReadyForCombat()
	return self.isReady
end

return AnimationController
