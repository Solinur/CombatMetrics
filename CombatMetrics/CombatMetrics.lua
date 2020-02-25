local wm = GetWindowManager()
local em = GetEventManager()
local _
local db
local desiredtime = 0.010  -- desired calculation time (s) for a chunk of the log.
local stepsize = 20 	-- stepsize for chunks of the log.
local chatContainer
local chatWindow

local lastUsedSkill
local lastUsedWeaponAttack

local currentbar


-- localize some module functions for performance

local stringformat = string.format
local mathfloor = math.floor
local mathmax = math.max
local mathmin = math.min
local mathabs = math.abs
local mathceil = math.ceil
local infinity = math.huge

-- init Lib

local LC = LibCombat
if LC == nil then return end

-- namespace for thg addon
if CMX == nil then CMX = {} end
local CMX = CMX

-- Basic values
CMX.name = "CombatMetrics"
CMX.version = "0.9.13"

function CMX.GetFeedBackData(parentcontrol)

	local data = {

		CMX,
		CMX.name .. " " .. CMX.version,
		parentcontrol,
		"@Solinur",
		{TOPLEFT, parentcontrol, TOPRIGHT, 10, 0},
		{
			{0, GetString(SI_COMBAT_METRICS_FEEDBACK_MAIL), false},
			{5000, GetString(SI_COMBAT_METRICS_FEEDBACK_GOLD), true},
			{25000, GetString(SI_COMBAT_METRICS_FEEDBACK_GOLD2), true},
			{"https://www.esoui.com/downloads/info1360-CombatMetrics.html", GetString(SI_COMBAT_METRICS_FEEDBACK_ESOUI), false},
			{"https://github.com/Solinur/CombatMetrics", GetString(SI_COMBAT_METRICS_FEEDBACK_GITHUB), false},
		},
		GetString(SI_COMBAT_METRICS_FEEDBACK_TEXT),
		700,
		245,
		145
	}

	return data
end

local GetFormattedAbilityName = LC.GetFormattedAbilityName

local GetFormattedAbilityIcon = LC.GetFormattedAbilityIcon

local function Print(category, message, ...)
	if db.debuginfo[category] then df("[%.2f - %s] %s", GetGameTimeSeconds(), "CMX", message:format(...)) end
end

CMX.Print = Print

local offstatlist= {
	"maxmagicka",
	"spellpower",
	"spellcrit",
	"spellcritbonus",
	"spellpen",
	"maxstamina",
	"weaponpower",
	"weaponcrit",
	"weaponcritbonus",
	"weaponpen",
}

local STATTYPE_NORMAL = 0
local STATTYPE_CRITICAL = 1
local STATTYPE_CRITICALBONUS = 2
local STATTYPE_PENETRATION = 3
local STATTYPE_INCSPELL = 4
local STATTYPE_INCWEAPON = 5

local StatListTable = {

	["Spell"] = {

		["maxmagicka"] = STATTYPE_NORMAL,
		["spellpower"] = STATTYPE_NORMAL,
		["spellcrit"] = STATTYPE_CRITICAL,
		["spellcritbonus"] = STATTYPE_CRITICALBONUS,
		["spellpen"] = STATTYPE_PENETRATION,

	},

	["Weapon"] = {

		["maxstamina"] = STATTYPE_NORMAL,
		["weaponpower"] = STATTYPE_NORMAL,
		["weaponcrit"] = STATTYPE_CRITICAL,
		["weaponcritbonus"] = STATTYPE_CRITICALBONUS,
		["weaponpen"] = STATTYPE_PENETRATION,

	},
}

local IncomingStatList = {

	["maxhealth"] = STATTYPE_NORMAL,
	["spellres"] = STATTYPE_INCSPELL,
	["physres"] = STATTYPE_INCWEAPON,
	["critres"] = STATTYPE_CRITICALBONUS,

}

local IsMagickaAbility = {				-- nil for oblivion and other damage types that are not covered by spell damage

	[DAMAGE_TYPE_MAGIC] = true,
	[DAMAGE_TYPE_FIRE] = true,
	[DAMAGE_TYPE_COLD] = true,
	[DAMAGE_TYPE_SHOCK] = true,
	[DAMAGE_TYPE_PHYSICAL] = false,
	[DAMAGE_TYPE_POISON] = false,
	[DAMAGE_TYPE_DISEASE] = false,

}

local SpellResistDebuffs = {

	[GetFormattedAbilityName(62787)] = 5280, --Major Breach
	[GetFormattedAbilityName(68588)] = 1320, --Minor Breach

	[GetFormattedAbilityName(17906)] = 2108, -- Crusher, can get changed by settings !
	[GetFormattedAbilityName(75753)] = 3010, -- Alkosh

}

local PhysResistDebuffs = {

	[GetFormattedAbilityName(62484)] = 5280, --Major Fracture
	[GetFormattedAbilityName(64144)] = 1320, --Minor Fracture

	[GetFormattedAbilityName(17906)] = 2108, -- Crusher, can get changed by settings !
	[GetFormattedAbilityName(75753)] = 3010, -- Alkosh

	--Corrosive Armor ignores all resistance

}


function CMX.SetCrusher(value)

	db.crusherValue = value

	local crushername = GetFormattedAbilityName(17906)

	SpellResistDebuffs[crushername] = value
	PhysResistDebuffs[crushername] = value

end

function CMX.spairs(t, order) -- from https://stackoverflow.com/questions/15706270/sort-a-table-in-lua

    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

local function NewObject(subclass, ...)

	local object = ZO_Object.New(subclass)
	object:Initialize(...)

	return object

end

local function NewSubclass()

	local subclass = ZO_Object:Subclass()

	subclass.New = NewObject

	return subclass
end

local UnitHandler = NewSubclass()			-- define classes
local AbilityHandler = NewSubclass()
local ResourceTable = NewSubclass()
local ResourceHandler = NewSubclass()
local EffectHandler = NewSubclass()
local SkillTimingHandler = NewSubclass()
local BarStatsHandler = NewSubclass()

local function AcquireUnitData(self, unitId, timems)

	local units = self.calculated.units

	local unit = units[unitId]

	if unit == nil then

		unit = UnitHandler:New()
		units[unitId] = unit

		unit.starttime = timems

	end

	unit.endtime = timems

	return unit
end

local function AcquireAbilityData(self, abilityId, ispet, damageType, tableKey)

	local data = self[tableKey]

	if data[abilityId] == nil then

		data[abilityId] = AbilityHandler:New(abilityId, ispet, damageType, tableKey)

	end

	return data[abilityId]
end

local function AcquireEffectData(self, abilityId, effectType, stacks)

	local stacktext = (stacks <= 1 or db.showstacks == false) and "" or (" (x"..stacks..")")
	local name = GetFormattedAbilityName(abilityId)..stacktext

	local buffs = self.buffs

	if buffs[name] == nil then

		buffs[name] = EffectHandler:New(effectType, abilityId, stacks)

	end

	return buffs[name]

end

local function AcquireResourceData(self, abilityId, powerValueChange, powerType)

	local tablekey = powerValueChange>=0 and "gains" or "drains"
	local resource = self.calculated.resources[powerType]

	local resourceData = resource[tablekey]

	if powerType == POWERTYPE_ULTIMATE then

		return resource

	elseif resourceData[abilityId] == nil then

		resourceData[abilityId] = ResourceHandler:New()

	end

	return resourceData[abilityId]
end

local function AcquireSkillTimingData(self, reducedslot)

	local skilldata = self.calculated.skills

	if skilldata[reducedslot] == nil then

		skilldata[reducedslot] = SkillTimingHandler:New()

	end

	return skilldata[reducedslot]
end

local function AcquireBarStats(self, bar)

	local bardata = self.calculated.barStats

	if bardata[bar] == nil then

		bardata[bar] = BarStatsHandler:New()

	end

	return bardata[bar]

end

local CategoryList = {

	damageOut = {

		"DPSOut",
		"damageOutNormal",
		"damageOutCritical",
		"damageOutBlocked",
		"damageOutShielded",
		"damageOutTotal",
		"hitsOutNormal",
		"hitsOutCritical",
		"hitsOutBlocked",
		"hitsOutShielded",
		"hitsOutTotal",

	},

	damageIn = {

		"DPSIn",
		"damageInNormal",
		"damageInCritical",
		"damageInBlocked",
		"damageInShielded",
		"damageInTotal",
		"hitsInNormal",
		"hitsInCritical",
		"hitsInBlocked",
		"hitsInShielded",
		"hitsInTotal",

	},

	healingOut = {

		"HPSOut",
		"HPSAOut",
		"healingOutNormal",
		"healingOutCritical",
		"healingOutTotal",
		"healingOutOverflow",
		"healingOutAbsolute",
		"healsOutNormal",
		"healsOutCritical",
		"healsOutTotal",
		"healsOutOverflow",
		"healsOutAbsolute",

	},

	healingIn = {

		"HPSIn",
		"healingInNormal",
		"healingInCritical",
		"healingInTotal",
		"healingInOverflow",
		"healingInAbsolute",
		"healsInNormal",
		"healsInCritical",
		"healsInTotal",
		"healsInOverflow",
		"healsInAbsolute",

	},
}


local function InitBasicValues(self)

	for tablekey,list in pairs(CategoryList) do -- i.e. tablekey = "healingOut"

		self[tablekey] = {}

		for _,key in pairs(list) do -- i.e. key = "healingOutTotal"

			self[key] = 0

		end

	end

	self.spellResistance = {}
	self.physicalResistance = {}
end

local basicTable = {}
InitBasicValues(basicTable)

function UnitHandler:Initialize()

	InitBasicValues(self)
	self.AcquireAbilityData = AcquireAbilityData
	self.AcquireEffectData = AcquireEffectData
	self.buffs = {}
	self.currentPhysicalResistance = 0
	self.currentSpellResistance = 0
	self.spellResDebuffs = {}
	self.physResDebuffs = {}

end

function UnitHandler:UpdateResistance(ismagic, debuffName)

	local debuffData = self.physResDebuffs
	local valuekey = "currentPhysicalResistance"
	local value = PhysResistDebuffs[debuffName]

	if ismagic then

		debuffData = self.spellResDebuffs
		valuekey = "currentSpellResistance"
		value = SpellResistDebuffs[debuffName]

	end

	local debuff = self.buffs[debuffName]

	local isactive = debuff.groupLastGain ~= nil or debuff.lastGain ~= nil

	if isactive == true and debuffData[debuffName] ~= true then

		debuffData[debuffName] = true

		self[valuekey] = self[valuekey] + value

	elseif isactive == false and debuffData[debuffName] == true then

		debuffData[debuffName] = false

		self[valuekey] = self[valuekey] - value

	end
end

local function initBaseAbility(self, tablekey)

	local list = CategoryList[tablekey]

	self.max = 0 -- max hit
	self.min = infinity -- min hit

	for _,key in pairs(list) do

		self[key] = 0

	end
end

local baseAbilities = {} -- prepare an empty ability, since it has to be used a few times later

for key,_ in pairs(CategoryList) do

	baseAbilities[key] = {}
	initBaseAbility(baseAbilities[key], key)

end

function AbilityHandler:Initialize(abilityId, pet, damageType, tablekey)

	self.name = GetFormattedAbilityName(abilityId)		-- ability name
	self.pet = pet
	self.damageType = damageType or ""
	self.isheal = (tablekey == "healingOut" or tablekey == "healingIn")

	initBaseAbility(self, tablekey)

end

function EffectHandler:Initialize(effectType, abilityId, stacks)

	self.name = GetFormattedAbilityName(abilityId)
	self.uptime = 0						-- uptime of effect caused by player
	self.count = 0						-- count of effect applications caused by player
	self.groupUptime = 0				-- uptime of effect caused by the whole group
	self.groupCount = 0					-- count of effect applications caused by the whole group
	self.lastGain = nil					-- temp var for storing when effect was last gained
	self.effectType = effectType		-- buff or debuff
	self.icon = abilityId				-- icon of this effect
	self.stacks = stacks				-- stacks = 0 if the effect wasn't tracked trough EVENT_EFFECT_CHANGED

end

function ResourceTable:Initialize()

	self[POWERTYPE_MAGICKA] = {

		["gains"]={},
		["drains"]={},
		["totalgains"]=0,
		["totaldrains"]=0,

	}

	self[POWERTYPE_STAMINA] = {

		["gains"]={},
		["drains"]={},
		["totalgains"]=0,
		["totaldrains"]=0,

	}
	self[POWERTYPE_ULTIMATE] = {

		["gains"]={},
		["totalgains"]=0,
		["totaldrains"]=0,

	}
end

function ResourceHandler:Initialize()

	self.ticks = 0
	self.value = 0

end

function SkillTimingHandler:Initialize()

	self.times = {}  				-- holds times a skill gets used
	self.skillBefore = {} 			-- holds times since last skill completed
	self.weaponAttackBefore = {} 	-- holds times since last light or heavy attack completed
	self.skillNext = {} 			-- holds times until a new skill is cast afterwards
	self.weaponAttackNext = {} 		-- holds times until a new light or heavy attack is cast afterwards

end

function BarStatsHandler:Initialize()

	self.onTimes = {}  		-- holds times the bar gets used
	self.offTimes = {}  	-- holds times the bar gets used
	self.damageOut = 0 		-- holds damage done on the bar
	self.damageIn = 0 		-- holds damage received on the bar
	self.healingOut = 0 	-- holds healing done on the bar
	self.healingIn = 0 		-- holds healing received on the bar

end

local function GetEmtpyFightStats()

	local data = {}

	InitBasicValues(data)

	data.units = {}

	data.stats = {dmgavg={}, healavg ={}, dmginavg = {}}	-- stat tracking

	data.resources = ResourceTable:New()

	data.skills = {}
	data.barStats = {}

	data.totalSkillTime = 0
	data.totalSkills = 0
	data.totalWeaponAttacks = 0
	data.totalSkillsFired =  0

	data.graph = {
		damageOut = {},
		damageIn = {},
		healingOut = {},
		healingIn = {},
	}

	lastUsedSkill = nil
	lastUsedWeaponAttack = nil

	return data

end

local function CalculateFight(fight) -- called by CMX.update or on user interaction

	fight.cindex = 0
	fight.calculated = GetEmtpyFightStats()

	local data = fight.calculated

	currentbar = fight.startBar

	local barStats = fight:AcquireBarStats(currentbar)
	barStats.onTimes = {fight.dpsstart}

	-- copy group values (since they won't get calculated)

	data.groupDamageOut = fight.groupDamageOut
	data.groupDamageIn 	= fight.groupDamageIn
	data.groupHealOut 	= fight.groupHealOut
	data.groupHealIn 	= fight.groupHealIn
	data.groupDPSOut 	= fight.groupDPSOut
	data.groupHPSOut 	= fight.groupHPSOut
	data.groupHPSIn 	= fight.groupHPSIn
	data.groupDPSIn 	= fight.groupDPSIn

	fight.calculating = true

	local titleBar = CombatMetrics_Report_TitleFightTitleBar
	local titleBarBg = CombatMetrics_Report_TitleFightTitleBarBG

	titleBar:SetValue(0)
	titleBar:SetHidden(false)

	fight:CalculateChunk()

end

local function sumUnitTables(target, source, reference) -- adds values from source to those in target using reference to determine the objects to sum

	for key,object in pairs(reference) do

		if type(object)=="table" then

			if key == "damageOut" or key == "damageIn" or key == "healingOut" or key == "healingIn" then

				for id,ability in pairs(source[key]) do

					if target[key][id] == nil then

						target[key][id] = {}
						ZO_DeepTableCopy(ability, target[key][id])

					else

						sumUnitTables(target[key][id], ability, baseAbilities[key])

					end
				end

			elseif key == "spellResistance" or key == "physicalResistance" then

				sumUnitTables(target[key], source[key], source[key])

			end

		elseif type(object)=="number" then

			if key == "max" then

				target[key] = mathmax((target[key] or 0), (source[key] or 0))

			elseif key == "min" then

				target[key] = mathmin((target[key] or infinity), (source[key] or infinity))

			else

				target[key] = (target[key] or 0) + (source[key] or 0)

			end
		end
	end
end

local function AccumulateStats(fight)

	local data = fight.calculated

	for _,unit in pairs(data.units) do	-- iterate over the units

		for tablekey,list in pairs(CategoryList) do -- iterate over categories, i.e. damageOut, list is a category specific list of tablekeys, which each of the abilities h

			for _,ability in pairs(unit[tablekey]) do -- iterate over abilities

				-- calculate totals

				if tablekey == "damageOut" then

					ability.damageOutTotal = ability.damageOutNormal + ability.damageOutCritical + ability.damageOutShielded + ability.damageOutBlocked
					ability.hitsOutTotal = ability.hitsOutNormal + ability.hitsOutCritical + ability.hitsOutShielded + ability.hitsOutBlocked
					ability.DPSOut = ability.damageOutTotal / fight.dpstime

				elseif tablekey == "damageIn" then

					ability.damageInTotal = ability.damageInNormal + ability.damageInCritical + ability.damageInShielded + ability.damageInBlocked
					ability.hitsInTotal = ability.hitsInNormal + ability.hitsInCritical + ability.hitsInShielded + ability.hitsInBlocked
					ability.DPSIn = ability.damageInTotal / fight.dpstime

				elseif tablekey == "healingOut" then

					ability.healingOutTotal = ability.healingOutNormal + ability.healingOutCritical
					ability.healsOutTotal = ability.healsOutNormal + ability.healsOutCritical
					ability.healingOutAbsolute = ability.healingOutTotal + ability.healingOutOverflow
					ability.healsOutAbsolute = ability.healsOutTotal + ability.healsOutOverflow
					ability.HPSOut = ability.healingOutTotal / fight.hpstime
					ability.HPSAOut = ability.healingOutAbsolute / fight.hpstime

				elseif tablekey == "healingIn" then

					ability.healingInTotal = ability.healingInNormal + ability.healingInCritical
					ability.healsInTotal = ability.healsInNormal + ability.healsInCritical
					ability.healingInAbsolute = ability.healingInTotal + ability.healingInOverflow
					ability.healsInAbsolute = ability.healsInTotal + ability.healsInOverflow
					ability.HPSIn = ability.healingInTotal / fight.hpstime

				end

				-- add ability stats to unit sum

				for _, key in pairs(list) do

					unit[key] = unit[key] + ability[key]

				end
			end
		end

		-- add unit stats to fight sum

		sumUnitTables(data, unit, basicTable)

	end
end

function CMX.GenerateSelectionStats(fight, menuItem, selections) -- this is similar to the function above, but instead it sums up stats from already calculated data.

	if fight == nil then return end

	local abilityselection = selections.ability[menuItem]
	local unitselection = selections.unit[menuItem]

	local showOverHeal = CMX.showOverHeal and menuItem == "healingOut"

	-- if abilityselection == nil and unitselection == nil then return end

	local data = fight.calculated

	local selectiondata = {}
	InitBasicValues(selectiondata)
	selectiondata.units = {}
	selectiondata.buffs = {}

	local totalValueSum = 0
	local totalkey = showOverHeal and "healingOutAbsolute" or ZO_CachedStrFormat("<<1>>Total", menuItem)

	for unitId,_ in pairs(unitselection or data.units) do	-- if a selection was made the content of the value will be "true" and not the table from the original data.

		local unitTotalValue = 0

		local unit = data.units[unitId]

		if (abilityselection ~= nil or unitselection ~= nil) and unit ~= nil then

			local selectedunit = {[menuItem]={}}
			InitBasicValues(selectedunit)
			local abilitytable = unit[menuItem] -- retrieve original unit data

			for abilityId,ability in pairs(abilitytable) do

				selectedunit[menuItem][abilityId] = ability

				if abilityselection==nil then

					ZO_DeepTableCopy(unit, selectedunit)

				elseif ability ~= nil and abilityselection ~= nil and abilityselection[abilityId] ~= nil then

					for _, key in pairs(CategoryList[menuItem]) do

						selectedunit[key] = (selectedunit[key] or 0) + ability[key]  -- add ability stats (from data) to unit sum (from selectiondata).

					end
				end
			end

			selectiondata.units[unitId] = selectedunit

			unitTotalValue = unit[totalkey]
			totalValueSum = totalValueSum + unitTotalValue

			-- add unit stats to fight sum

			sumUnitTables(selectiondata, selectedunit, basicTable)

		end

		-- calculate averaged buff uptimes

		local unitData = fight.units[unitId]

		local isNotEmpty = unitTotalValue > 0 or NonContiguousCount(unit.buffs) > 0
		local isEnemy = unitData and (unitData.unitType ~= COMBAT_UNIT_TYPE_GROUP and unitData.unitType ~= COMBAT_UNIT_TYPE_PLAYER_PET and unitData.unitType ~= COMBAT_UNIT_TYPE_PLAYER) -- some user had unitData go to nil so make sure that unit will be ignored
		local isDamageCategory = menuItem == "damageIn" or menuItem == "damageOut"

		if isNotEmpty and (isEnemy == isDamageCategory) and unitData then

			for name, buff in pairs(unit.buffs) do

				local selectedbuff = selectiondata.buffs[name] or { uptime = 0, count = 0, groupUptime = 0, groupCount = 0 }

				for key,value in pairs(selectedbuff) do

					selectedbuff[key] = value + buff[key]

				end

				selectedbuff.effectType = buff.effectType
				selectedbuff.icon = buff.icon

				selectiondata.buffs[name] = selectedbuff
			end

			selectiondata.totalUnitTime = (selectiondata.totalUnitTime or 0) + (mathmin(fight.endtime, unit.endtime or unitData.dpsend) - mathmax(fight.starttime, unit.starttime or unitData.dpsstart))

		end
	end

	selectiondata.totalValueSum = totalValueSum

	CMX.selectiondata = selectiondata

	return selectiondata
end

-- Combat Log Processing functions, define for each callbacktype

local ProcessLog = {}

-- Damage

local damageResultCategory={
	[ACTION_RESULT_DAMAGE] = "Normal",
	[ACTION_RESULT_DOT_TICK] = "Normal",
	[ACTION_RESULT_CRITICAL_DAMAGE] = "Critical",
	[ACTION_RESULT_DOT_TICK_CRITICAL] = "Critical",
	[ACTION_RESULT_BLOCKED_DAMAGE] = "Blocked",
	[ACTION_RESULT_DAMAGE_SHIELDED] = "Shielded",
}

local function IncrementStatSum(fight, damageType, resultkey, isDamageOut, hitValue, isheal, unit)

	local ismagical = IsMagickaAbility[damageType]				-- is nil for uncategorized damage, e.g. Oblivion Damage

	local statlist = IncomingStatList

	if isDamageOut then

		local useMagickaList = (isheal and damageType == POWERTYPE_MAGICKA) or ((isheal == false) and ismagical) -- for heals damageType is replaced with powerType.

		if useMagickaList == nil then return end

		local key = useMagickaList and "Spell" or "Weapon"

		statlist = StatListTable[key]

	end

	local barStats = fight:AcquireBarStats(currentbar)

	local stats = fight.calculated.stats

	local values

	if isheal == true  and isDamageOut == true then

		values = stats.healavg
		barStats.healingOut = barStats.healingOut + hitValue

	elseif 	isheal == true and isDamageOut == false then

		barStats.healingIn = barStats.healingIn + hitValue
		return

	elseif 	isheal == false and isDamageOut == true then

		values = stats.dmgavg
		barStats.damageOut = barStats.damageOut + hitValue

	elseif 	isheal == false and isDamageOut == false then

		values = stats.dmginavg
		barStats.damageIn = barStats.damageIn + hitValue

	else return end

	for statkey, stattype in pairs(statlist) do

		local sumkey = "sum"..statkey
		local currentkey = "current"..statkey

		local currentValue = stats[currentkey]
		local value = hitValue

		if stattype == STATTYPE_CRITICAL and resultkey ~= "Blocked" and resultkey ~= "Shielded" then value = 1	-- they can't crit so they don't matter

		elseif stattype == STATTYPE_CRITICAL then value = 0

		elseif stattype == STATTYPE_CRITICALBONUS and resultkey ~= "Critical" then value = 0

		elseif stattype == STATTYPE_INCSPELL and ismagical ~= true then value = 0

		elseif stattype == STATTYPE_INCWEAPON and ismagical ~= false then value = 0

		elseif stattype == STATTYPE_PENETRATION then

			if isheal == true then

				value = 0

			elseif ismagical ~= nil then

				local resistancekey = "currentPhysicalResistance"
				local resistDataKey = "physicalResistance"

				if ismagical == true then

					resistancekey = "currentSpellResistance"
					resistDataKey = "spellResistance"

				end

				local effectiveValue = currentValue + unit[resistancekey]

				local data = unit[resistDataKey]

				data[effectiveValue] = (data[effectiveValue] or 0) + value

			end
		end

		values[sumkey] = (values[sumkey] or 0) + (value * (currentValue or 0)) -- sum up stats multplied by value, later this is divided by value to get a weighted average
	end
end


local function ProcessLogDamage(fight, callbacktype, timems, result, sourceUnitId, targetUnitId, abilityId, hitValue, damageType)

	if timems < (fight.combatstart-500) or fight.units[sourceUnitId] == nil or fight.units[targetUnitId] == nil then return end

	local ispet = fight.units[sourceUnitId].unittype == COMBAT_UNIT_TYPE_PLAYER_PET 										-- determine if this is pet damage

	local abilitydata
	local isDamageOut
	local unit

	local resultkey = damageResultCategory[result]

	local dmgkey
	local hitkey
	local graphkey

	if callbacktype == LIBCOMBAT_EVENT_DAMAGE_OUT then

		unit = fight:AcquireUnitData(targetUnitId, timems)
		abilitydata = unit:AcquireAbilityData(abilityId, ispet, damageType, "damageOut")	-- get table for ability (within the unittable)
		isDamageOut = true

		dmgkey = ZO_CachedStrFormat("damageOut<<1>>", resultkey)	-- determine categories. For normal incoming damage: dmgkey = "damageNormal", for critical outgoing damage: dmgkey = "damageCritical" ...
		hitkey = ZO_CachedStrFormat("hitsOut<<1>>", resultkey)
		graphkey = "damageOut"

	else																												-- incoming and self inflicted Damage are consolidated.

		abilitydata = fight:AcquireUnitData(sourceUnitId, timems):AcquireAbilityData(abilityId, ispet, damageType, "damageIn")
		isDamageOut = false

		dmgkey = ZO_CachedStrFormat("damageIn<<1>>", resultkey)	-- determine categories. For normal incoming damage: dmgkey = "damageNormal", for critical outgoing damage: dmgkey = "damageCritical" ...
		hitkey = ZO_CachedStrFormat("hitsIn<<1>>", resultkey)
		graphkey = "damageIn"

	end

	abilitydata[dmgkey] = abilitydata[dmgkey] + hitValue
	abilitydata[hitkey] = abilitydata[hitkey] + 1

	local inttime = mathfloor((timems - fight.combatstart)/1000)

	if inttime >= 0 then

		local data = fight.calculated.graph[graphkey]
		data[inttime] = (data[inttime] or 0) + hitValue

	end

	abilitydata.max = mathmax(abilitydata.max, hitValue)
	abilitydata.min = mathmin(abilitydata.min, hitValue)

	IncrementStatSum(fight, damageType, resultkey, isDamageOut, hitValue, false, unit)
end

ProcessLog[LIBCOMBAT_EVENT_DAMAGE_OUT] = ProcessLogDamage
ProcessLog[LIBCOMBAT_EVENT_DAMAGE_IN] = ProcessLogDamage
ProcessLog[LIBCOMBAT_EVENT_DAMAGE_SELF] = ProcessLogDamage

-- Heal

local healResultCategory={
	[ACTION_RESULT_HEAL] = "Normal",
	[ACTION_RESULT_HOT_TICK] = "Normal",
	[ACTION_RESULT_CRITICAL_HEAL] = "Critical",
	[ACTION_RESULT_HOT_TICK_CRITICAL] = "Critical",
}

local function ProcessLogHeal(fight, callbacktype, timems, result, sourceUnitId, targetUnitId, abilityId, hitValue, powerType, overflow)
	if timems < (fight.combatstart-500) or fight.units[sourceUnitId] == nil or fight.units[targetUnitId] == nil then return end

	local ispet = fight.units[sourceUnitId].unittype == COMBAT_UNIT_TYPE_PLAYER_PET 										-- determine if this is healing from a pet

	local abilitydata
	local isHealingOut

	local resultkey = healResultCategory[result]

	local valuekey
	local hitkey
	local overFlowValuekey
	local overFlowHitkey

	if callbacktype == LIBCOMBAT_EVENT_HEAL_OUT then

		abilitydata = fight:AcquireUnitData(targetUnitId, timems):AcquireAbilityData(abilityId, ispet, powerType, "healingOut")	-- get table for ability (within the unittable)
		isHealingOut = true

		valuekey = "healingOut"
		hitkey = "healsOut"

	else

		abilitydata = fight:AcquireUnitData(sourceUnitId, timems):AcquireAbilityData(abilityId, ispet, powerType, "healingIn")
		isHealingOut = false

		valuekey = "healingIn"
		hitkey = "healsIn"

	end

	local healingkey = ZO_CachedStrFormat("<<1>><<2>>", valuekey, resultkey)	-- determine categories. For normal incoming healing: healkey = "healingInNormal", for critical outgoing healing: healkey = "healingOutCritical" ...
	local healskey = ZO_CachedStrFormat("<<1>><<2>>", hitkey, resultkey)
	local overflowHealingKey = ZO_CachedStrFormat("<<1>>Overflow", valuekey)
	local overflowHealskey = ZO_CachedStrFormat("<<1>>Overflow", hitkey)

	overflow = overflow or 0

	abilitydata[healingkey] = abilitydata[healingkey] + hitValue
	abilitydata[healskey] = abilitydata[healskey] + 1
	abilitydata[overflowHealingKey] = abilitydata[overflowHealingKey] + overflow

	if hitValue == 0 and overflow > 0 then abilitydata[overflowHealskey] = abilitydata[overflowHealskey] + 1 end

	local inttime = mathfloor((timems - fight.combatstart)/1000)

	if inttime >= 0 then

		local data = fight.calculated.graph[valuekey]
		data[inttime] = (data[inttime] or 0) + hitValue

	end

	abilitydata.max = mathmax(abilitydata.max, hitValue)
	abilitydata.min = mathmin(abilitydata.min, hitValue)

	IncrementStatSum(fight, powerType, resultkey, isHealingOut, hitValue, true)
end

ProcessLog[LIBCOMBAT_EVENT_HEAL_OUT] = ProcessLogHeal
ProcessLog[LIBCOMBAT_EVENT_HEAL_IN] = ProcessLogHeal

local function ProcessLogHealSelf (fight,callbacktype,...)

	ProcessLogHeal(fight,LIBCOMBAT_EVENT_HEAL_OUT,...)
	ProcessLogHeal(fight,LIBCOMBAT_EVENT_HEAL_IN,...)

end

ProcessLog[LIBCOMBAT_EVENT_HEAL_SELF] = ProcessLogHealSelf

-- Buffs/Debuffs

local function ProcessLogEffects(fight, callbacktype, timems, unitId, abilityId, changeType, effectType, stacks, sourceType, slotId)

	if timems < (fight.combatstart - 500) or fight.units[unitId] == nil then return end

	local unit = fight:AcquireUnitData(unitId, timems)
	local effectdata = unit:AcquireEffectData(abilityId, effectType, stacks)

	if (changeType == EFFECT_RESULT_GAINED or changeType == EFFECT_RESULT_UPDATED) and timems < fight.endtime then

		if sourceType == COMBAT_UNIT_TYPE_PLAYER or sourceType == COMBAT_UNIT_TYPE_PLAYER_PET then

			effectdata.lastGain = mathmax(effectdata.lastGain or timems, fight.starttime)
			effectdata.lastSlot = slotId

		--[[elseif effectdata.lastGain ~= nil then	-- treat this as if the player effect stopped, the group timer will continue though.

			effectdata.uptime = effectdata.uptime + (mathmin(timems, fight.endtime) - effectdata.lastGain)
			effectdata.lastGain = nil
			effectdata.count = effectdata.count + 1]]

		end

		effectdata.groupLastGain = mathmax(effectdata.groupLastGain or timems, fight.starttime)
		effectdata.groupLastSlot = slotId

	elseif changeType == EFFECT_RESULT_FADED then

		for i = 1, stacks do

			local effectdata = unit:AcquireEffectData(abilityId, effectType, i)

			if timems <= fight.starttime and (effectdata.lastGain ~= nil or effectdata.groupLastGain ~= nil) then

				if slotId == effectdata.lastSlot then effectdata.lastGain = nil end
				if slotId == effectdata.groupLastSlot then effectdata.groupLastGain = nil end

			end

			if effectdata.lastGain ~= nil and slotId == effectdata.lastSlot and (sourceType == COMBAT_UNIT_TYPE_PLAYER or sourceType == COMBAT_UNIT_TYPE_PLAYER_PET) then

				effectdata.uptime = effectdata.uptime + (mathmin(timems,fight.endtime) - effectdata.lastGain)
				effectdata.lastGain = nil
				effectdata.count = effectdata.count + 1

			end

			if effectdata.groupLastGain ~= nil and slotId == effectdata.groupLastSlot then

				effectdata.groupUptime = effectdata.groupUptime + (mathmin(timems,fight.endtime) - effectdata.groupLastGain)
				effectdata.groupLastGain = nil
				effectdata.groupCount = effectdata.groupCount + 1

			end
		end
	end

	local buffname = effectdata.name

	local spellres = SpellResistDebuffs[buffname]
	local physres = PhysResistDebuffs[buffname]

	if spellres then

		unit:UpdateResistance(true, buffname)
		--Print("dev", "SR: %d", unit.currentSpellResistance)

	end

	if physres then

		unit:UpdateResistance(false, buffname)
		--Print("dev", "PR: %d", unit.currentPhysicalResistance)

	end
end

ProcessLog[LIBCOMBAT_EVENT_EFFECTS_IN] = ProcessLogEffects
ProcessLog[LIBCOMBAT_EVENT_EFFECTS_OUT] = ProcessLogEffects
ProcessLog[LIBCOMBAT_EVENT_GROUPEFFECTS_IN] = ProcessLogEffects
ProcessLog[LIBCOMBAT_EVENT_GROUPEFFECTS_OUT] = ProcessLogEffects


local function ProcessLogResources(fight, callbacktype, timems, abilityId, powerValueChange, powerType)

	if powerType == POWERTYPE_HEALTH then return end

	abilityId = abilityId or 0

	local resourceData = fight:AcquireResourceData(abilityId, powerValueChange, powerType)

	local change = mathabs(powerValueChange)

	if powerType == POWERTYPE_ULTIMATE then

		local tablekey = powerValueChange >= 0 and "totalgains" or "totaldrains"
		resourceData[tablekey] = resourceData[tablekey] + change

	else

		resourceData.value = resourceData.value + change
		resourceData.ticks = resourceData.ticks + 1

	end
end

ProcessLog[LIBCOMBAT_EVENT_RESOURCES] = ProcessLogResources

local function ProcessLogStats(fight, callbacktype, timems, statchange, newvalue, stat)

	local key = LC.GetStatNameCurrent(stat)

	fight.calculated.stats[key] = newvalue

end

ProcessLog[LIBCOMBAT_EVENT_PLAYERSTATS] = ProcessLogStats

local abilityDelay = {[63044] = 100, [63029] = 100, [63046] = 100} -- Radiant Destruction and morphs have a 100ms delay after casting.

---[[
local function ProcessLogSkillTimings(fight, callbacktype, timems, reducedslot, abilityId, status)

	if reducedslot == nil then return end

	--Print("misc", "[%d], %s: %d", timems, GetAbilityName(abilityId), status)

	local isWeaponAttack = reducedslot%10 < 3

	local newdata = {}

	local slotdata = fight:AcquireSkillTimingData(reducedslot)

	local lastSkillTime, lastSkillSlot, lastSkillSuccessTime
	local lastWeaponAttackTime, lastWeaponAttackSlot, lastWeaponAttackSuccessTime

	if lastUsedSkill then

		lastSkillTime, lastSkillSlot, lastSkillSuccessTime = unpack(lastUsedSkill)

	end

	if lastUsedWeaponAttack then

		lastWeaponAttackTime, lastWeaponAttackSlot, lastWeaponAttackSuccessTime = unpack(lastUsedWeaponAttack)

	end

	local doubleWeaponAttack = isWeaponAttack and lastUsedWeaponAttack and lastUsedSkill and (lastWeaponAttackTime > lastSkillTime)
	local doubleSkillUse = (not isWeaponAttack) and lastUsedWeaponAttack and lastUsedSkill and (lastSkillTime > lastWeaponAttackTime)

	local timenow = GetGameTimeMilliseconds()/1000

	local key = isWeaponAttack and "weaponAttackNext" or "skillNext"
	local data = fight.calculated

	if lastSkillSuccessTime and not doubleWeaponAttack and status ~= LIBCOMBAT_SKILLSTATUS_SUCCESS then

		local timeDifference = timems - lastSkillSuccessTime

		table.insert(slotdata.skillBefore, timeDifference)
		table.insert(fight:AcquireSkillTimingData(lastSkillSlot)[key], timeDifference)

	end

	if lastWeaponAttackSuccessTime and not doubleSkillUse and status ~= LIBCOMBAT_SKILLSTATUS_SUCCESS then

		local timeDifference = timems - lastWeaponAttackSuccessTime

		table.insert(slotdata.weaponAttackBefore, timeDifference)
		table.insert(fight:AcquireSkillTimingData(lastWeaponAttackSlot)[key], timeDifference)

	end

	if status ~= LIBCOMBAT_SKILLSTATUS_SUCCESS then

		table.insert(slotdata.times, timems)

		if isWeaponAttack then

			local successTime = status == LIBCOMBAT_SKILLSTATUS_INSTANT and timems or nil

			lastUsedWeaponAttack = {timems, reducedslot, successTime}

		else

			local successTime = status == LIBCOMBAT_SKILLSTATUS_INSTANT and timems + 1000 or nil

			lastUsedSkill = {timems, reducedslot, successTime}

		end

	else

		local channeled, castTime = GetAbilityCastInfo(abilityId)

		local delay = abilityDelay[abilityId] or 0

		if isWeaponAttack and lastUsedWeaponAttack then

			lastUsedWeaponAttack[3] = timems + delay

		elseif lastUsedSkill then

			lastUsedSkill[3] = timems + delay

		end

	end
end

ProcessLog[LIBCOMBAT_EVENT_SKILL_TIMINGS] = ProcessLogSkillTimings

local function ProcessMessages(fight, callbacktype, timems, messageId, value)

	if messageId ~= LIBCOMBAT_MESSAGE_WEAPONSWAP then return end

	local barStatsOld = fight:AcquireBarStats(currentbar)

	table.insert(barStatsOld.offTimes, timems)

	currentbar = value

	local barStatsNew = fight:AcquireBarStats(currentbar)

	table.insert(barStatsNew.onTimes, timems)

end

ProcessLog[LIBCOMBAT_EVENT_MESSAGES] = ProcessMessages

ProcessLog[LIBCOMBAT_EVENT_BOSSHP] = function() end

--]]

local function CalculateChunk(fight)  -- called by CalculateFight or itself
	em:UnregisterForUpdate("CMX_chunk")

	local scalcms = GetGameTimeSeconds()

	local logdata = fight.log

	local istart = fight.cindex
	local iend = mathmin(istart+db.chunksize, #logdata)

	for i=istart+1,iend do

		local logline = logdata[i]

		if ProcessLog[logline[1]] then ProcessLog[logline[1]](fight,unpack(logline)) end -- logline[1] is the callbacktype e.g. LIBCOMBAT_EVENT_DAMAGEOUT

	end

	local titleBar = CombatMetrics_Report_TitleFightTitleBar
	local fightlabel = CombatMetrics_Report_TitleFightTitleName

	if iend >= #logdata then

		Print("calculationtime", "Start end routine")

		fightlabel:SetText(GetString(SI_COMBAT_METRICS_FINALIZING))

		local data = fight.calculated

		for k,unitData in pairs(fight.units) do

			local unitCalc = data.units[k] -- calculated info is not stored in fight.units but in fight.calculated.units

			if unitData.name == "Offline" then -- delete unknown units. Should only happen to units that did not participate in the fight

				unitData[k] = nil
				data.units[k] = nil

			elseif unitCalc ~= nil then

				local endtime = mathmin(unitCalc.endtime, fight.endtime)

				for k,effectdata in pairs(unitCalc.buffs) do	-- finish buffs

					if effectdata.lastGain ~= nil and fight.starttime ~= 0 then

						effectdata.uptime = effectdata.uptime + (endtime - effectdata.lastGain)
						effectdata.lastGain = nil
						effectdata.count = effectdata.count + 1

					end

					if effectdata.groupLastGain ~= nil and fight.starttime ~= 0 then

						effectdata.groupUptime = effectdata.groupUptime + (endtime - effectdata.groupLastGain)
						effectdata.groupLastGain = nil
						effectdata.groupCount = effectdata.groupCount + 1

					end
				end
			end
		end

		fight:AccumulateStats()

		local stats = data.stats
		local resources = data.resources

		-- calculate resource stats

		for k, resource in pairs(resources) do

			for id, ability in pairs(resource.gains or {}) do
				resource.totalgains = ability.value + resource.totalgains
				ability.rate = ability.value / fight.combattime
			end

			for id, ability in pairs(resource.drains or {}) do
				resource.totaldrains = ability.value + resource.totaldrains
				ability.rate = ability.value / fight.combattime
			end

			resource.gainRate = (resource.totalgains or 0) / fight.combattime
			resource.drainRate = (resource.totaldrains or 0) / fight.combattime

		end

		-- calculate fight stats (like Spell Damage)

		local fightstats = fight.stats
		local dmgavg = stats.dmgavg
		local dmginavg = stats.dmginavg
		local healavg = stats.healavg

		local damageOut = data.damageOut

		data.damageOutSpells = {}
		initBaseAbility(data.damageOutSpells, "damageOut")

		data.damageOutWeapon = {}
		initBaseAbility(data.damageOutWeapon, "damageOut")

		for id, ability in pairs(damageOut) do

			local isMagic = IsMagickaAbility[ability.damageType]

			local datatable = isMagic == true and data.damageOutSpells or isMagic == false and data.damageOutWeapon

			for key, value in pairs(datatable or {}) do

				datatable[key] = ability[key] + datatable[key]

			end

		end

		for key, list in pairs(StatListTable) do

			for statname, stattype in pairs(list) do

				local damagevalues = key == "Spell" and data.damageOutSpells or data.damageOutWeapon

				local sumkey = "sum"..statname
				local avgkey = "avg"..statname

				local value = fightstats["max"..statname]
				local value2 = fightstats["max"..statname]

				local totaldmgvalue = mathmax(damagevalues.damageOutTotal, 1)
				local totalhealvalue = mathmax(data.healingOutTotal, 1)

				if stattype == STATTYPE_CRITICAL then

					local critablehits = damagevalues.hitsOutNormal + damagevalues.hitsOutCritical
					totaldmgvalue = mathmax(critablehits, 1)
					totalhealvalue = mathmax(data.healsOutTotal, 1)

				elseif stattype == STATTYPE_CRITICALBONUS then

					totaldmgvalue = mathmax(damagevalues.damageOutCritical, 1)
					totalhealvalue = mathmax(data.healingOutCritical, 1)

				end

				if dmgavg[sumkey] ~= nil then value = dmgavg[sumkey] / totaldmgvalue end

				dmgavg[avgkey] = value

				if healavg[sumkey] ~= nil and stattype ~= STATTYPE_PENETRATION then value2 = healavg[sumkey] / totalhealvalue end

				healavg[avgkey] = value2
			end
		end

		local damageIn = data.damageIn

		data.damageInSpells = 0
		data.damageInWeapon = 0

		for id, ability in pairs(damageIn) do

			local isMagic = IsMagickaAbility[ability.damageType]

			if isMagic == true then

				data.damageInSpells = data.damageInSpells + ability.damageInTotal

			elseif isMagic == false then

				data.damageInWeapon = data.damageInWeapon + ability.damageInTotal

			end
		end

		for statname, stattype in pairs(IncomingStatList) do

			local sumkey = "sum"..statname
			local avgkey = "avg"..statname

			local value = fightstats["max"..statname]

			local totaldmgvalue = mathmax(data.damageInTotal, 1)

			if stattype == STATTYPE_CRITICALBONUS then

				totaldmgvalue = mathmax(data.damageInCritical, 1)

			elseif stattype == STATTYPE_INCSPELL then

				totaldmgvalue = mathmax(data.damageInSpells, 1)

			elseif stattype == STATTYPE_INCWEAPON then

				totaldmgvalue = mathmax(data.damageInWeapon, 1)

			end

			if dmginavg[sumkey] ~= nil then	value = dmginavg[sumkey] / totaldmgvalue end

			dmginavg[avgkey] = value

		end

		-- calculate skill timings

		local skilldata = data.skills

		local totalSkillTime = 0
		local totalSkills = 0
		local totalWeaponAttacks = 0
		local totalSkillsFired = 0

		for reducedslot, skill in pairs(skilldata) do

			local isWeaponAttack = reducedslot%10 == 1 or reducedslot%10 == 2

			local difftimes = {}

			local timedata = skill["times"]

			skill.count = #timedata

			for i = 1, #timedata - 1 do

				difftimes[i] = timedata[i+1] - timedata[i]

			end

			skill.difftimes = difftimes

			if isWeaponAttack then

				totalWeaponAttacks = totalWeaponAttacks + skill.count

			else

				totalSkillsFired = totalSkillsFired + skill.count

			end

			for i, key in ipairs({"skillBefore", "weaponAttackBefore", "skillNext", "weaponAttackNext", "difftimes"}) do

				local times = skill[key]

				local avgkey = ZO_CachedStrFormat("<<1>>Avg", key)

				local sum = 0
				local count = 0

				for _, v in pairs(times) do

					if type(v) == 'number' then

						sum = sum + v
						count = count + 1

					end

				end

				skill[avgkey] = count > 0 and sum / count or 0

				if i == 1 and not isWeaponAttack then

					totalSkillTime = totalSkillTime + sum
					totalSkills = totalSkills + count

					--Print("misc", "Slot %d: Total: %d | Timing %d", reducedslot, skill.count, count)

				end
			end
		end

		-- calculate bardata

		local barData = data.barStats

		local barStats = barData[currentbar]

		table.insert(barStats.offTimes, fight.dpsend) -- add endtime for last used bar

		for bar, barStats in pairs(barData) do

			local totalTime =  0

			local onTimes  = barStats.onTimes
			local offTimes = barStats.offTimes

			if #onTimes == #offTimes then

				for i, onTime in ipairs(onTimes) do

					totalTime = totalTime + offTimes[i] - onTime

				end

				barStats.totalTime = totalTime / 1000

			else

				Print("misc", "Time Array lengthes doesn't match for bar %d", bar)

			end
		end

		data.buffs = fight.playerid ~= nil and data.units[fight.playerid] and data.units[fight.playerid].buffs or {}

		data.totalSkillTime = totalSkillTime
		data.totalSkills = totalSkills
		data.totalWeaponAttacks = totalWeaponAttacks
		data.totalSkillsFired = totalSkillsFired

		fight.calculating = false
		fight.cindex = nil

		titleBar:SetHidden(true)

		Print("calculationtime", "Time for final calculations: %.2f ms", (GetGameTimeSeconds() - scalcms) * 1000)

		return

	else

		fight.cindex = iend
		em:RegisterForUpdate("CMX_chunk", 20, function() fight:CalculateChunk() end )

	end

	local chunktime = GetGameTimeSeconds() - scalcms

	local newchunksize = mathmin(mathceil(desiredtime / mathmax(chunktime, 0.001) * db.chunksize / stepsize) * stepsize, 20000)

	Print("calculationtime", "Chunk calculation time: %.2f ms, new chunk size: %d", chunktime * 1000, newchunksize)

	db.chunksize = newchunksize

	local progress = iend/#logdata

	fightlabel:SetText(stringformat("%s (%.1f%%)", GetString(SI_COMBAT_METRICS_CALC), 100 * progress))

	titleBar:SetValue(progress)

	return
end

local function InitCurrentData()
	CMX.currentdata = {log={}, DPSOut = 0, DPSIn = 0, HPSOut = 0, HPSAOut = 0, HPSIn = 0, dpstime = 0, hpstime = 0, groupDPSOut = 0, groupDPSIn = 0, groupHPSOut = 0, groupHPS = 0}	-- reset currentdata, the previous log is now only linked to the fight.
end

local function AddtoChatLog(...)

	local logLine = {...}
	local logType = logLine[1]

	local isEnabled =
	((logType == LIBCOMBAT_EVENT_DAMAGE_OUT or logType == LIBCOMBAT_EVENT_DAMAGE_SELF) and db.chatLog.damageOut == true)
	or ((logType == LIBCOMBAT_EVENT_HEAL_OUT or logType == LIBCOMBAT_EVENT_HEAL_SELF) and db.chatLog.healingOut == true)
	or ((logType == LIBCOMBAT_EVENT_DAMAGE_IN or logType == LIBCOMBAT_EVENT_DAMAGE_SELF) and db.chatLog.damageIn == true)
	or ((logType == LIBCOMBAT_EVENT_HEAL_IN or logType == LIBCOMBAT_EVENT_HEAL_SELF) and db.chatLog.healingIn == true)
	or logType == LIBCOMBAT_EVENT_MESSAGES

	if isEnabled then

		local text, color = CMX.GetCombatLogString(nil, {...}, 12)

		if chatContainer then chatContainer:AddMessageToWindow(chatWindow, text, unpack(color)) end -- in case the container got removed by the user or an addon

	end
end

local function AddToLog(...)
	table.insert(CMX.currentdata.log,{...})

	if db.chatLog.enabled then AddtoChatLog(...) end
end

local function UnitsCallback(_, units)

	CMX.currentdata.units = units

end

local function FightRecapCallback(_, newdata)

	local data = CMX.currentdata

	ZO_DeepTableCopy(newdata, data)

	CombatMetrics_LiveReport:Update(data)

end

local function GroupFightRecapCallback(_, newdata)

	local data = CMX.currentdata

	ZO_DeepTableCopy(newdata, data)

end

local function CheckNumberOfFights()

	local lastfights = CMX.lastfights

	if #lastfights > db.fighthistory then

		local fighttodelete = 1

		if db.keepbossfights then

			for i = 1, #lastfights - 1 do

				if not lastfights[i].bossfight then fighttodelete = i break end

			end
		end

		table.remove(lastfights, fighttodelete)

	end
end

local function GetFightName(fight)

	local bigunitname = "Unkown"
	local dmgmax = 0

	for k,unitData in pairs(fight.units) do

		if fight.bossfight == true and unitData.bossId ~= nil and unitData.damageOutTotal > dmgmax then -- find the "biggest" enemy

			bigunitname = unitData.name

			if unitData.bossId == 1 then break end		-- this should be the name of the main boss

			dmgmax = unitData.damageOutTotal

		elseif unitData.unitType == COMBAT_UNIT_TYPE_NONE and unitData.damageOutTotal > dmgmax then

			bigunitname = unitData.name
			dmgmax = unitData.damageOutTotal

		end
	end

	fight.fightlabel = fight.fightlabel or bigunitname
end

local function AddFightCalculationFunctions(fight)

	fight.CalculateFight = CalculateFight
	fight.CalculateChunk = CalculateChunk
	fight.AcquireUnitData = AcquireUnitData
	fight.AcquireResourceData = AcquireResourceData
	fight.AccumulateStats = AccumulateStats
	fight.AcquireSkillTimingData = AcquireSkillTimingData
	fight.AcquireBarStats = AcquireBarStats

end

CMX.AddFightCalculationFunctions = AddFightCalculationFunctions

local function FightSummaryCallback(_, fight)

	AddFightCalculationFunctions(fight)

	fight.grouplog = nil

	GetFightName(fight)

	fight.log = CMX.currentdata.log -- copy combatlog

	InitCurrentData() 	-- reset currentdata, the previous log is now only linked to the fight.

	if fight.dpsstart ~= nil or fight.hpsstart ~= nil then table.insert(CMX.lastfights, fight) end

	CheckNumberOfFights()

	if SCENE_MANAGER.currentScene.name == "CMX_REPORT_SCENE" then CombatMetrics_Report:Update() end
end

local CMX_STATUS_DISABLED = 0
local CMX_STATUS_LIGHTMODE = 1
local CMX_STATUS_ENABLED = 2

local registrationStatus
local registeredGroup

local function UpdateEvents()

	local isGrouped = IsUnitGrouped("player")
	local ava = IsPlayerInAvAWorld()

	local IsLightMode = db.lightmode or (db.lightmodeincyrodil and ava == true)
	local isOff = ava == true and db.offincyrodil == true

	local newstatus = (isOff and CMX_STATUS_DISABLED) or (IsLightMode and CMX_STATUS_LIGHTMODE) or CMX_STATUS_ENABLED

	CombatMetrics_LiveReport:Toggle(newstatus ~= CMX_STATUS_DISABLED and db.liveReport.enabled)

	if registrationStatus ~= newstatus then

		if newstatus == CMX_STATUS_DISABLED then

			for i = LIBCOMBAT_EVENT_DAMAGE_OUT, LIBCOMBAT_EVENT_BOSSHP do
				LC:UnregisterCallbackType(i, AddToLog, CMX.name)
			end

			LC:UnregisterCallbackType(LIBCOMBAT_EVENT_UNITS, UnitsCallback, CMX.name)
			LC:UnregisterCallbackType(LIBCOMBAT_EVENT_FIGHTRECAP, FightRecapCallback, CMX.name)
			LC:UnregisterCallbackType(LIBCOMBAT_EVENT_FIGHTSUMMARY, FightSummaryCallback, CMX.name)

		elseif newstatus == CMX_STATUS_LIGHTMODE then

			for i = LIBCOMBAT_EVENT_DAMAGE_OUT, LIBCOMBAT_EVENT_BOSSHP do
				LC:UnregisterCallbackType(i, AddToLog, CMX.name)
			end

			LC:UnregisterCallbackType(LIBCOMBAT_EVENT_FIGHTSUMMARY, FightSummaryCallback, CMX.name)

			LC:RegisterCallbackType(LIBCOMBAT_EVENT_UNITS, UnitsCallback, CMX.name)
			LC:RegisterCallbackType(LIBCOMBAT_EVENT_FIGHTRECAP, FightRecapCallback, CMX.name)

		elseif newstatus == CMX_STATUS_ENABLED then

			for i = LIBCOMBAT_EVENT_DAMAGE_OUT, LIBCOMBAT_EVENT_BOSSHP do

				LC:RegisterCallbackType(i, AddToLog ,CMX.name)

			end

			LC:RegisterCallbackType(LIBCOMBAT_EVENT_UNITS, UnitsCallback, CMX.name)
			LC:RegisterCallbackType(LIBCOMBAT_EVENT_FIGHTRECAP, FightRecapCallback, CMX.name)
			LC:RegisterCallbackType(LIBCOMBAT_EVENT_FIGHTSUMMARY, FightSummaryCallback, CMX.name)

		end

		registrationStatus = newstatus
	end

	local loadgroupevents = isGrouped and db.recordgrp == true and (GetGroupSize()<5 or db.recordgrpinlarge==true) and newstatus ~= CMX_STATUS_DISABLED

	if loadgroupevents and registeredGroup ~= true then

		LC:RegisterCallbackType(LIBCOMBAT_EVENT_GROUPRECAP, GroupFightRecapCallback, CMX.name)
		registeredGroup = true

	elseif loadgroupevents == false and registeredGroup == true then

		LC:UnregisterCallbackType(LIBCOMBAT_EVENT_GROUPRECAP, GroupFightRecapCallback, CMX.name)
		registeredGroup = false
	end

	Print("special", "State: %d, Group: %s", registrationStatus or 0, tostring(registeredGroup or false))
end

do
	--[[ from LUI Extended
	 * Fix Combat Log window settings
	 ]]--
	local function fixCombatLog(cc, window)

		local tabIndex = window.tab.index

		cc:SetInteractivity(tabIndex, true)
		cc:SetLocked(tabIndex, true)

		for category = 1, GetNumChatCategories() do

			cc:SetWindowFilterEnabled(tabIndex, category, false)

		end
	end


	--[[ from LUI Extended
	 * Prepare Combat Log window
	 ]]--
	local function getCombatLog()

		for k, cc in ipairs(CHAT_SYSTEM.containers) do

			for i = 1, #cc.windows do

				if cc:GetTabName(i) == db.chatLog.name then

					return cc, cc.windows[i]

				end
			end
		end

		-- previous lookup did not find proper window, so create it in primary container

		local cc = CHAT_SYSTEM.primaryContainer
		local window, key = cc.windowPool:AcquireObject()

		window.key = key

		cc:AddRawWindow(window, db.chatLog.name)

		fixCombatLog(cc, window)

		return cc, window
	end

	local cc, window

	function CMX.InitializeChat()

		if CHAT_SYSTEM.containers[1] then

			cc, window = getCombatLog()

			chatContainer = cc
			chatWindow = window

		else

			zo_callLater(CMX.InitializeChat, 200)

		end
	end

	function CMX.ChangeCombatLogLabel(name)

		if not (cc and window) then return end

		cc:SetTabName(window.key, name)

	end

	function CMX.RemoveCombatLog()

		cc:RemoveWindow(window.key)

		cc = nil
		window = nil
	end

end

local function maxStat()

	local _, magicka = GetUnitPower("player", POWERTYPE_MAGICKA )
	local _, stamina = GetUnitPower("player", POWERTYPE_STAMINA )
	local _, health = GetUnitPower("player", POWERTYPE_HEALTH )

	local maxPower = POWERTYPE_MAGICKA

	if stamina > magicka then maxPower = POWERTYPE_STAMINA end
	if health > magicka and health > stamina then maxPower = POWERTYPE_HEALTH end

	return maxPower

end

local svdefaults = {

	["accountwide"] = false,

	["fighthistory"] = 25,
	["maxSVsize"] = 10,
	["SVsize"] = 0,
	["keepbossfights"] = false,
	["chunksize"] = 1000,

	["recordgrp"] = true,
	["recordgrpinlarge"] = true,

	["showstacks"] = true,
	["crusherValue"] = 2108,
	["unitresistance"] = 18200,

	["lightmode"] = false,
	["offincyrodil"] = false,
	["lightmodeincyrodil"] = true,

	["autoselectchatchannel"] = true,

	["autoscreenshot"] = false,
	["autoscreenshotmintime"] = 30,

	["CombatMetrics_LiveReport"] = { x = 0, y = -500},
	["CombatMetrics_Report"] = { x = GuiRoot:GetWidth()/2, y = GuiRoot:GetHeight()/2-75},

	["FightReport"] = {

		["scale"] 				= zo_roundToNearest(1 / GetSetting(SETTING_TYPE_UI, UI_SETTING_CUSTOM_SCALE), 0.1),
		["category"] 			= "damageOut",
		["mainpanel"] 			= "FightStats",
		["rightpanel"] 			= "buffs",
		["fightstatspanel"] 	= maxStat(),
		["skilltimingbefore"] 	= true,

		["SmoothWindow"] 		= 5,

		["Cursor"]				= true,

		["PlotColors"]				= {

			[1]	= {1, 1, 0, 0.66},	-- yellow
			[2]	= {1, 0, 0, 0.66},	-- red
			[3]	= {0, 1, 0, 0.66},	-- green
			[4]	= {0, 0, 1, 0.66},	-- blue
			[5]	= {1, 0, 1, 0.66},	-- violet
			[6]	= {0.4, 1, 0.4, 0.4},	-- Buffs: green
			[7]	= {1, 0.4, 0.9, 0.4},	-- Debuffs: violet

		},

		["ShowGroupBuffsInPlots"]	= true,

		["FavouriteBuffs"] = {},

		["CLSelection"] = {

			[LIBCOMBAT_EVENT_DAMAGE_OUT] 		= true,
			[LIBCOMBAT_EVENT_DAMAGE_IN] 		= false,
			[LIBCOMBAT_EVENT_HEAL_OUT] 			= false,
			[LIBCOMBAT_EVENT_HEAL_IN] 			= false,
			[LIBCOMBAT_EVENT_EFFECTS_IN] 		= false,
			[LIBCOMBAT_EVENT_EFFECTS_OUT] 		= false,
			[LIBCOMBAT_EVENT_GROUPEFFECTS_IN] 	= false,
			[LIBCOMBAT_EVENT_GROUPEFFECTS_OUT] 	= false,
			[LIBCOMBAT_EVENT_PLAYERSTATS] 		= false,
			[LIBCOMBAT_EVENT_RESOURCES] 		= false,
			[LIBCOMBAT_EVENT_MESSAGES] 			= false,

		},

		["hitCritLayout"] = {
			damageOut = 1,
			damageIn = 1,
			healingOut = 1,
			healingIn = 1,
		},

		["averageLayout"] = {
			damageOut = 1,
			damageIn = 1,
			healingOut = 1,
			healingIn = 1,
		},

		["maxValue"] = {
			damageOut = true,
			damageIn = true,
			healingOut = true,
			healingIn = true,
		}
	},

	["liveReport"] = {

		["enabled"] 		= true,
		["locked"] 			= false,
		["layout"]			="Compact",
		["scale"]			= zo_roundToNearest(1 / GetSetting(SETTING_TYPE_UI, UI_SETTING_CUSTOM_SCALE), 0.1),
		["bgalpha"]			= 95,
		["alignmentleft"] 	= false,
		["damageOut"] 		= true,
		["damageOutSingle"] = false,
		["healOut"] 		= true,
		["damageIn"] 		= true,
		["healIn"] 			= true,
		["time"] 			= true,
		["healOutAbsolute"]	= false,

	},

	["chatLog"] = {

		["enabled"] 	= false,
		["name"] 		= "CMX Combat Log",
		["damageOut"] 	= true,
		["healingOut"] 	= false,
		["damageIn"] 	= false,
		["healingIn"] 	= false,

	},

	["debuginfo"] = {

		["fightsummary"] 	= false,
		["ids"] 			= false,
		["calculationtime"] = false,
		["buffs"] 			= false,
		["skills"] 			= false,
		["group"] 			= false,
		["misc"] 			= false,
		["special"] 		= false,
		["save"] 			= false,
		["dev"] 			= false,

	},
}

-- Next we create a function that will initialize our addon
local function Initialize(event, addon)
  -- filter for just CMX addon event
	if addon ~= CMX.name then return end

	em:UnregisterForEvent(CMX.name, EVENT_ADD_ON_LOADED)

	-- remove old saved variables

	local svmain = _G[CMX.name.."_Save"]
	local svtable = svmain and svmain.Default and svmain.Default[GetDisplayName()] or nil

	if svtable then

		for k,v in pairs(svtable) do

			if v.version and v.version < 5 then svtable[k] = nil end

		end
	end

	-- load saved variables

	CMX.db = ZO_SavedVars:NewAccountWide("CombatMetrics_Save", 5, "Settings", svdefaults)
	if not CMX.db.accountwide then CMX.db = ZO_SavedVars:NewCharacterIdSettings("CombatMetrics_Save", 5, "Settings", svdefaults) end

	db = CMX.db

	local fightdata = CombatMetricsFightData

	-- convert legacy data into new format

	if type(db.FightReport.hitCritLayout) == "number" then

		local oldValue1 = db.FightReport.hitCritLayout
		local oldValue2 = db.FightReport.averageLayout
		local oldValue3 = db.FightReport.maxValue

		db.FightReport.hitCritLayout = {
			["damageOut"] 	= oldValue1,
			["damageIn"] 	= oldValue1,
			["healingOut"] 	= oldValue1,
			["healingIn"] 	= oldValue1,
		}

		db.FightReport.averageLayout = {
			["damageOut"] 	= oldValue2,
			["damageIn"] 	= oldValue2,
			["healingOut"] 	= oldValue2,
			["healingIn"] 	= oldValue2,
		}

		db.FightReport.maxValue = {
			["damageOut"] 	= oldValue3,
			["damageIn"] 	= oldValue3,
			["healingOut"] 	= oldValue3,
			["healingIn"] 	= oldValue3,
		}

	end

	local oldsv = CombatMetrics_Save["Default"][GetDisplayName()]["$AccountWide"]

	local olddata = oldsv["Fights"]

	if olddata ~= nil and olddata.fights ~= nil then

		for id, fight in ipairs(olddata.fights) do

			fightdata.Save(fight)

		end

		oldsv["Fights"] = nil

	end

	--

	local crushername = GetFormattedAbilityName(17906)

	SpellResistDebuffs[crushername] = db.crusherValue
	PhysResistDebuffs[crushername] = db.crusherValue

	if db.chatLog.enabled then zo_callLater(CMX.InitializeChat, 500) end

	CMX.playername = zo_strformat(SI_UNIT_NAME,GetUnitName("player"))
	CMX.inCombat = IsUnitInCombat("player")

	CMX.InitializeUI()

	em:RegisterForEvent(CMX.name.."zone", EVENT_ZONE_CHANGED, UpdateEvents)
	em:RegisterForEvent(CMX.name.."group1", EVENT_UNIT_CREATED, UpdateEvents)
	em:RegisterForEvent(CMX.name.."group2", EVENT_UNIT_DESTROYED, UpdateEvents)
	em:RegisterForEvent(CMX.name.."port", EVENT_PLAYER_ACTIVATED, UpdateEvents)

	CMX.UpdateEvents = UpdateEvents

	CMX.lastfights = {}

	InitCurrentData()

	-- make addon options menu
	CMX.MakeMenu(svdefaults)

	if CMX.LoadCustomizations then CMX.LoadCustomizations() end

	function CMX.GetCombatLogString(fight, logline, fontsize)

		local text, color = LC:GetCombatLogString(fight, logline, fontsize)
		return text, color

	end

	CMX.ResetFight = LC.ResetFight
	CMX.GetDamageColor = LC.GetDamageColor

	CMX.showOverHeal = false

	CMX.init = true
end

-- register event handler function to initialize when addon is loaded
em:RegisterForEvent(CMX.name, EVENT_ADD_ON_LOADED, function(...) Initialize(...) end)
