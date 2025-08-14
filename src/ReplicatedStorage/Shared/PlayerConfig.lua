--[[
    Archivo: PlayerConfig.lua
    Tipo: ModuleScript
    Ubicacion: ReplicatedStorage/Shared/
    Descripcion: Define la plantilla de datos para un jugador que aun no ha elegido clase.
--]]

local PlayerTemplate = {
	ProfileVersion = 1.0,

	Clase = "Default", -- La clase inicial siempre es "Default".
	Nivel = 1,
	Experiencia = 0,
	Resets = 0,
	Zen = 500,

	EstadisticasBase = {
		Fuerza = 10,
		Agilidad = 10,
		Vitalidad = 10,
		Energia = 10,
	},
	PuntosDeStatsDisponibles = 0,

	Inventario = {},
	Equipo = {
		Arma = nil,
		Casco = nil,
		Armadura = nil,
		Pantalones = nil,
		Guantes = nil,
		Botas = nil,
	},

	Skills = {} -- Un jugador "Default" no tiene skills al empezar.
}

return PlayerTemplate
