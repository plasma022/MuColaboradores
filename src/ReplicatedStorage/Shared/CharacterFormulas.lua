--[[
    Archivo: CharacterFormulas.lua
    Tipo: ModuleScript
    Ubicaci�n: ReplicatedStorage/Shared/
    Descripci�n: Centraliza TODOS los c�lculos matem�ticos y animaciones base del personaje.
--]]

local Formulas = {}

-- Animaciones por defecto que todas las clases pueden usar.
Formulas.DefaultAnimations = {
	HitMelee = "rbxassetid://80458845151117"
}

-- == CORRECCI�N CLAVE: Nombres de stats estandarizados a espa�ol ==
-- Stats y animaciones base de cada clase al Nivel 1.
Formulas.CLASS_BASE_STATS = {
	["DarkKnight"] = {
		HP=79, MP=32, Fuerza=15, Agilidad=10, Vitalidad=12, Energia=5,
		RunAnimID = "rbxassetid://127681785238768",
		RecoilAnimID = "rbxassetid://99256836368216",
		DeathAnimID = "rbxassetid://104083807651488",
		WeaponAttackAnims = {
			Sword = "rbxassetid://93241459333840"
		}
	},
	["DarkWizard"] = {
		HP=63, MP=18, Fuerza=5, Agilidad=10, Vitalidad=8, Energia=20,
		RunAnimID = "rbxassetid://119542539921749",
		RecoilAnimID = "rbxassetid://92766645817090",
		DeathAnimID = "rbxassetid://103898651293300",
		WeaponAttackAnims = {}
	},
	["FairyElf"] = {
		HP=74, MP=30, Fuerza=10, Agilidad=15, Vitalidad=10, Energia=10,
		RunAnimID = "rbxassetid://120898088288165",
		RecoilAnimID = "rbxassetid://92766645817090",
		DeathAnimID = "rbxassetid://104083807651488",
		WeaponAttackAnims = {
			Bow = "rbxassetid://129612779287723"
		}
	},
}

function Formulas.calculateMaxHP(className, level, vit)
	local base = Formulas.CLASS_BASE_STATS[className] or Formulas.CLASS_BASE_STATS["DarkKnight"]
	local calculatedHP
	if className == "DarkWizard" then calculatedHP = base.HP + math.floor(level * 1.5 + vit * 2)
	elseif className == "DarkKnight" then calculatedHP = base.HP + math.floor(level * 2.2 + vit * 3) * 1.1
	elseif className == "FairyElf" then calculatedHP = base.HP + math.floor(level * 1.8 + vit * 2.5)
	else calculatedHP = base.HP + math.floor(level * 2.2 + vit * 3) * 1.1 end
	return math.floor(calculatedHP)
end

function Formulas.calculateMaxMP(className, level, ene)
	local base = Formulas.CLASS_BASE_STATS[className] or Formulas.CLASS_BASE_STATS["DarkKnight"]
	local calculatedMP
	if className == "DarkWizard" then calculatedMP = base.MP + math.floor(level * 2 + ene * 3)
	elseif className == "DarkKnight" then calculatedMP = base.MP + math.floor(level * 1 + ene * 1.5)
	elseif className == "FairyElf" then calculatedMP = base.MP + math.floor(level * 1.2 + ene * 2)
	else calculatedMP = base.MP + math.floor(level * 1 + ene * 1.5) end
	return math.floor(calculatedMP)
end

function Formulas.calculateDamageRange(className, str, agi)
	local minDamage, maxDamage
	if className == "DarkKnight" then
		minDamage = math.floor(str / 8)
		maxDamage = math.floor(str / 4)
	elseif className == "DarkWizard" then
		minDamage = math.floor(str / 10)
		maxDamage = math.floor(str / 6)
	elseif className == "FairyElf" then
		minDamage = math.floor((agi * 2 + str) / 12)
		maxDamage = math.floor((agi * 2 + str) / 7)
	else
		minDamage = 1
		maxDamage = 2
	end
	return minDamage, maxDamage
end

function Formulas.calculateAttackSpeed(agi)
	local speedFromAgi
	if agi <= 2000 then
		speedFromAgi = math.floor(agi / 20)
	else
		local baseSpeed = 2000 / 20
		local extraSpeed = (agi - 2000) / 40
		speedFromAgi = math.floor(baseSpeed + extraSpeed)
	end
	return speedFromAgi
end

function Formulas.calculateTimeMultiplier(attackSpeedStat)
	return 1 / (1 + (attackSpeedStat * 0.01)) 
end

return Formulas
