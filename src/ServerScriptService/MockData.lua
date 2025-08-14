--[[
    Archivo: MockData.lua
    Tipo: ModuleScript
    Ubicacion: ServerScriptService/
    Descripcion: Simula la carga de datos para pruebas ropidas en Roblox Studio.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerConfig = require(ReplicatedStorage.Shared.PlayerConfig)

local function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end
		setmetatable(copy, deepcopy(getmetatable(orig)))
	else
		copy = orig
	end
	return copy
end

local MockData = {}

function MockData.LoadProfileAsync(player)
	print("--- USANDO DATOS SIMULADOS (MOCK DATA) PARA " .. player.Name .. " ---")

	local fakeProfile = {}
	fakeProfile.Data = deepcopy(PlayerConfig)

	function fakeProfile:ListenToRelease(callback) end
	function fakeProfile:Reconcile() end
	function fakeProfile:AddUserId(id) end
	function fakeProfile:Release()
		print("--- DATOS SIMULADOS LIBERADOS PARA " .. player.Name .. " ---")
	end

	return fakeProfile
end

return MockData
