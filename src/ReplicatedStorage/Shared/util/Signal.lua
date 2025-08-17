--[[
	Signal.lua
	Un módulo simple para crear y gestionar eventos (señales) globales.
	Este módulo actúa como un singleton para que todos los scripts compartan las mismas señales.
	Ubicación: ReplicatedStorage/Shared/util/
]]

local Signal = {}

local connections = {}

function Signal:Connect(func)
	local connectionId = tostring({}) -- Creamos un ID único para la conexión
	connections[connectionId] = func
	
	return {
		Disconnect = function()
			connections[connectionId] = nil
		end
	}
end

function Signal:Fire(...)
	for id, func in pairs(connections) do
		task.spawn(func, ...)
	end
end

return Signal
