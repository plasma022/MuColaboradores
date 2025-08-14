--[[
    Archivo: CharacterFormulas.lua
    Tipo: ModuleScript
    Ubicacion: ReplicatedStorage/Shared/
    Descripcion: Centraliza TODOS los calculos matematicos del personaje.
--]]

local Formulas = {}

-- Stats y animaciones base de cada clase al Nivel 1.
Formulas.CLASS_BASE_STATS = {
	["DarkKnight"] = {
		HP=79, MP=32, STR=15, AGI=10, VIT=12, ENE=5,
		BasicAttackAnimID = "rbxassetid://129612779287723"
	},
	["DarkWizard"] = {
		HP=63, MP=18, STR=5, AGI=10, VIT=8, ENE=20,
		BasicAttackAnimID = "rbxassetid://129612779287723"
	},
	["FairyElf"] = {
		HP=74, MP=30, STR=10, AGI=15, VIT=10, ENE=10,
		BasicAttackAnimID = "rbxassetid://129612779287723"
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
