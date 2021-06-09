local wm = GetWindowManager()
local em = GetEventManager()
local _
local db
local desiredtime = 0.010  -- desired calculation time (s) for a chunk of the log.
local stepsize = 20 	-- stepsize for chunks of the log.
local chatContainer
local chatWindow

local currentbar
local abilityDurations = {}

local ProcessLog = {}

-- localize some module functions for performance

local stringformat = string.format
local mathfloor = math.floor
local mathmax = math.max
local mathmin = math.min
local mathabs = math.abs
local mathceil = math.ceil
local infinity = math.huge

-- namespace for thg addon
if CMX == nil then CMX = {} end
local CMX = CMX

-- Basic values
CMX.name = "CombatMetrics"
CMX.version = "1.4.3"

-- Logger

local mainlogger
local subloggers = {}
local LOG_LEVEL_VERBOSE = "V"
local LOG_LEVEL_DEBUG = "D"
local LOG_LEVEL_INFO = "I"
local LOG_LEVEL_WARNING ="W"
local LOG_LEVEL_ERROR = "E"

if LibDebugLogger then

	mainlogger = LibDebugLogger.Create(CMX.name)

	LOG_LEVEL_VERBOSE = LibDebugLogger.LOG_LEVEL_VERBOSE
	LOG_LEVEL_DEBUG = LibDebugLogger.LOG_LEVEL_DEBUG
	LOG_LEVEL_INFO = LibDebugLogger.LOG_LEVEL_INFO
	LOG_LEVEL_WARNING = LibDebugLogger.LOG_LEVEL_WARNING
	LOG_LEVEL_ERROR = LibDebugLogger.LOG_LEVEL_ERROR

	subloggers["main"] = mainlogger
	subloggers["calc"] = mainlogger:Create("calc")
	subloggers["group"] = mainlogger:Create("group")
	subloggers["other"] = mainlogger:Create("other")
	subloggers["UI"] = mainlogger:Create("UI")
	subloggers["save"] = mainlogger:Create("save")

end

local function Print(category, level, ...)

	if mainlogger == nil then return end

	local logger = category and subloggers[category] or mainlogger

	if type(logger.Log)=="function" then logger:Log(level, ...) end

end

CMX.Print = Print

function CMX.GetDebugLevels()

	return 	LOG_LEVEL_VERBOSE, LOG_LEVEL_DEBUG, LOG_LEVEL_INFO, LOG_LEVEL_WARNING, LOG_LEVEL_ERROR

end

-- init and check for libs

local LC = LibCombat
if LC == nil then

	Print("main", LOG_LEVEL_ERROR, "LibCombat not found!")
	return

end

local GetFormattedAbilityName = LC.GetFormattedAbilityName

local GetFormattedAbilityIcon = LC.GetFormattedAbilityIcon

local STATTYPE_NORMAL = 0
local STATTYPE_CRITICAL = 1
local STATTYPE_CRITICALBONUS = 2
local STATTYPE_PENETRATION = 3
local STATTYPE_INCSPELL = 4
local STATTYPE_INCWEAPON = 5

local StatListTable = {

	["Spell"] = {

		[LIBCOMBAT_STAT_MAXMAGICKA] = STATTYPE_NORMAL,
		[LIBCOMBAT_STAT_SPELLPOWER] = STATTYPE_NORMAL,
		[LIBCOMBAT_STAT_SPELLCRIT] = STATTYPE_CRITICAL,
		[LIBCOMBAT_STAT_SPELLCRITBONUS] = STATTYPE_CRITICALBONUS,
		[LIBCOMBAT_STAT_SPELLPENETRATION] = STATTYPE_PENETRATION,

	},

	["Weapon"] = {

		[LIBCOMBAT_STAT_MAXSTAMINA] = STATTYPE_NORMAL,
		[LIBCOMBAT_STAT_WEAPONPOWER] = STATTYPE_NORMAL,
		[LIBCOMBAT_STAT_WEAPONCRIT] = STATTYPE_CRITICAL,
		[LIBCOMBAT_STAT_WEAPONCRITBONUS] = STATTYPE_CRITICALBONUS,
		[LIBCOMBAT_STAT_WEAPONPENETRATION] = STATTYPE_PENETRATION,

	},
}

local IncomingStatList = {

	[LIBCOMBAT_STAT_MAXHEALTH] = STATTYPE_NORMAL,
	[LIBCOMBAT_STAT_PHYSICALRESISTANCE] = STATTYPE_INCWEAPON,
	[LIBCOMBAT_STAT_SPELLRESISTANCE] = STATTYPE_INCSPELL,
	[LIBCOMBAT_STAT_CRITICALRESISTANCE] = STATTYPE_CRITICALBONUS,

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

-- EC Flame: 142610
-- EC Shock: 142653
-- EC Frost: 142652

local StatDebuffs = {

	[GetFormattedAbilityName(61743)] = {[LIBCOMBAT_STAT_SPELLPENETRATION] = 5948, [LIBCOMBAT_STAT_WEAPONPENETRATION] = 5948}, --Major Breach
	[GetFormattedAbilityName(61742)] = {[LIBCOMBAT_STAT_SPELLPENETRATION] = 2974, [LIBCOMBAT_STAT_WEAPONPENETRATION] = 2974}, --Minor Breach
	[GetFormattedAbilityName(120007)] = {[LIBCOMBAT_STAT_SPELLPENETRATION] = 2740, [LIBCOMBAT_STAT_WEAPONPENETRATION] = 2740}, -- Crusher, Target Dummy (the following line might overwrite this. If LUI extended is used, both declarations are necessary)
	[GetFormattedAbilityName(17906)] = {[LIBCOMBAT_STAT_SPELLPENETRATION] = 2108, [LIBCOMBAT_STAT_WEAPONPENETRATION] = 2108}, -- Crusher, can get changed by settings !
	[GetFormattedAbilityName(143808)] = {[LIBCOMBAT_STAT_SPELLPENETRATION] = 1000, [LIBCOMBAT_STAT_WEAPONPENETRATION] = 1000}, -- Crystal Weapon
	[GetFormattedAbilityName(120018)] = {[LIBCOMBAT_STAT_SPELLPENETRATION] = 3000, [LIBCOMBAT_STAT_WEAPONPENETRATION] = 3010}, -- Alkosh, Target Dummy (the following line might overwrite this. If LUI extended is used, both declarations are necessary)
	[GetFormattedAbilityName(76667)] = {[LIBCOMBAT_STAT_SPELLPENETRATION] = 3000, [LIBCOMBAT_STAT_WEAPONPENETRATION] = 3000}, -- Alkosh

	[GetFormattedAbilityName(79087)] = {[LIBCOMBAT_STAT_SPELLPENETRATION] = 1320}, -- Spell Resistance Reduction by Poison
	[GetFormattedAbilityName(79090)] = {[LIBCOMBAT_STAT_WEAPONPENETRATION] = 1320}, -- Physical Resistance Reduction by Poison

	[GetFormattedAbilityName(80866)] = {[LIBCOMBAT_STAT_WEAPONPENETRATION] = 2395}, -- Tremorscale

	[GetFormattedAbilityName(142610)] = {[LIBCOMBAT_STAT_SPELLCRITBONUS] = 5, [LIBCOMBAT_STAT_WEAPONCRITBONUS] = 5}, -- Flame Weakness
	[GetFormattedAbilityName(142653)] = {[LIBCOMBAT_STAT_SPELLCRITBONUS] = 5, [LIBCOMBAT_STAT_WEAPONCRITBONUS] = 5}, -- Shock Weakness
	[GetFormattedAbilityName(142652)] = {[LIBCOMBAT_STAT_SPELLCRITBONUS] = 5, [LIBCOMBAT_STAT_WEAPONCRITBONUS] = 5}, -- Frost Weakness

	[GetFormattedAbilityName(145975)] = {[LIBCOMBAT_STAT_SPELLCRITBONUS] = 10, [LIBCOMBAT_STAT_WEAPONCRITBONUS] = 10}, -- Minor Brittle

	[GetFormattedAbilityName(113382)] = {[LIBCOMBAT_STAT_SPELLPOWER] = 460}, -- Spell Strategist

}

local ignoredAbilityTiming = { -- Skills which ignore global cooldown

    [132141] = true,    -- Blood Frenzy (Vampire Toggle)
    [134160] = true,    -- Simmering Frenzy (Vampire Toggle)
    [135841] = true,    -- Sated Fury (Vampire Toggle)

}

local ChangingAbilities = { -- Skills which can change un use

    [61902] = 61907,    -- Grim Focus --> Assasins Will
    [61919] = 61930,    -- Merciless Resolve --> Assasins Will
	[61927] = 61932,    -- Relentless Focus --> Assasins Scourge
	[117749] = 117773,  -- Stalking Blastbones (When greyed out)
	[117690] = 117693,  -- Blighted Blastbones (When greyed out)
	[46324] = 114716,  	-- Crystal Fragments Proc
}

for k,v in pairs(ChangingAbilities) do

	ChangingAbilities[v] = k

end

local abilityDelay = {	-- Radiant Destruction and morphs have a 100ms delay after casting. 50ms for Jabs
    [63044] = 100,
    [63029] = 100,
    [63046] = 100,
    [26797] = 50,
    [38857] = 200
}

local TrialDummyBuffs = {

	[61743] = true, -- Major Breach
	[61742] = true, -- Minor Breach
	[79717] = true, -- Minor Vulnerability
	[120007] = true, -- Crusher
	[145975] = true, -- Minor Brittle
	[106754] = true, -- Major Vulnerability
	[120011] = true, -- Engulfing Flames
	[120018] = true, -- Roar of Alkosh
	[88401] = true, -- Minor Magickasteal
}

function CMX.SetCrusher(value)

	db.crusherValue = value

	local crushername = GetFormattedAbilityName(17906)

	local StatDebuffCrusher = StatDebuffs[crushername]

	StatDebuffCrusher[LIBCOMBAT_STAT_SPELLPENETRATION] = value
	StatDebuffCrusher[LIBCOMBAT_STAT_WEAPONPENETRATION] = value

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
local SkillCastHandler = NewSubclass()
local BarStatsHandler = NewSubclass()
local StatDataHandler = NewSubclass()
local UnitStatHandler = NewSubclass()

local function AcquireUnitData(fight, unitId, timems)

	local units = fight.calculated.units

	local unit = units[unitId]

	if unit == nil then

		unit = UnitHandler:New()
		units[unitId] = unit

		unit.starttime = timems
		unit.unitId = unitId

	end

	unit.endtime = timems

	return unit
end

local function AcquireAbilityData(unit, abilityId, ispet, damageType, tableKey)

	local data = unit[tableKey]

	if data[abilityId] == nil then

		data[abilityId] = AbilityHandler:New(abilityId, ispet, damageType, tableKey)

	end

	return data[abilityId]
end

local function AcquireEffectData(unit, abilityId, effectType, stacks)

	local name = GetFormattedAbilityName(abilityId)

	local buffs = unit.buffs

	if buffs[name] == nil then

		buffs[name] = EffectHandler:New(effectType, name, abilityId)

	end

	local buffdata = buffs[name]

	buffdata:CheckInstance(abilityId, stacks)

	buffdata.maxStacks = mathmax(stacks, buffdata.maxStacks)

	return buffs[name]

end

local function AcquireResourceData(fight, abilityId, powerValueChange, powerType)

	local tablekey = powerValueChange>=0 and "gains" or "drains"
	local resource = fight.calculated.resources[powerType]

	local resourceData = resource[tablekey]

	if powerType == POWERTYPE_ULTIMATE then

		return resource

	elseif resourceData[abilityId] == nil then

		resourceData[abilityId] = ResourceHandler:New()

	end

	return resourceData[abilityId]
end

local function AcquireSkillCastData(fight, reducedslot)

	local skilldata = fight.calculated.skills

	if skilldata[reducedslot] == nil then

		skilldata[reducedslot] = SkillCastHandler:New()

	end

	return skilldata[reducedslot]
end

local function AcquireBarStats(fight, bar)

	local bardata = fight.calculated.barStats

	if bardata[bar] == nil then

		bardata[bar] = BarStatsHandler:New()

	end

	return bardata[bar]

end

local function AcquireStatData(fight, statId)

	local statData = fight.calculated.stats

	if statData[statId] == nil then

		statData[statId] = StatDataHandler:New()

	end

	return statData[statId]

end

local function AcquireUnitStatData(unit, statId)

	local statData = unit.statData

	if statData[statId] == nil then

		statData[statId] = UnitStatHandler:New()

	end

	return statData[statId]

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
	self.AcquireUnitStatData = AcquireUnitStatData
	self.buffs = {}
	self.currentPhysicalResistance = 0
	self.currentSpellResistance = 0
	self.statData = {}

end

local overridevalues = {

	[120018] = 3010, -- Alkosh on Dummy
	[120007] = 2740, -- Crusher on Dummy

}

function UnitHandler:UpdateStats(fight, effectdata, abilityId)

	local debuffName = effectdata.name

	local debuffStatData = StatDebuffs[debuffName]

	if debuffStatData == nil then return end

	for stat, value in pairs(debuffStatData) do

		value = overridevalues[abilityId] or value

		local statData = self:AcquireUnitStatData(stat)
		local debuffData = statData.debuffs

		local debuff = self.buffs[debuffName]
		local isactive = NonContiguousCount(debuff.slots) > 0

		if isactive == true and (not debuffData[debuffName]) then

			if value == nil then

				Print("calc", LOG_LEVEL_WARNING, "Debuff stat value missing: %s (%d)", debuffName or "nil", effectdata.iconId or 0)
				return

			end

			debuffData[debuffName] = value

			statData.value = statData.value + value

		elseif isactive == false and debuffData[debuffName] then

			value = debuffData[debuffName]
			debuffData[debuffName] = nil

			statData.value = statData.value - value

		end
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

function EffectHandler:Initialize(effectType, name, abilityId)

	self.name = name
	self.iconId = abilityId
	self.uptime = 0						-- uptime of effect caused by player
	self.count = 0						-- count of effect applications caused by player
	self.groupUptime = 0				-- uptime of effect caused by the whole group
	self.groupCount = 0					-- count of effect applications caused by the whole group
	self.effectType = effectType		-- buff or debuff
	self.maxStacks = 0					-- stacks = 0 if the effect wasn't tracked trough EVENT_EFFECT_CHANGED
	self.firstStartTime = nil			-- temp variable to track when uptime for a buff initially started
	self.firstGroupStartTime = nil		-- temp variable to track when uptime for a buff from the group initially started
	self.slots = {}						-- slotid is unique for each application, this is the temporary place to track them
	self.instances = {}					-- some buff, epecially major/minor ones can be applied via several buff Id's

end

function EffectHandler:CheckInstance(abilityId, stacks)

	local instances = self.instances
	local instance = instances[abilityId]

	if instance == nil then

		instance = {}
		instances[abilityId] = instance

	end

	local stackData = instance[stacks]

	if stackData == nil then

		stackData = {

			uptime = 0,			-- uptime of effect caused by player
			count = 0,			-- count of effect applications caused by player
			groupUptime = 0,	-- uptime of effect caused by the whole group
			groupCount = 0,		-- count of effect applications caused by the whole group}

		}

		instance[stacks] = stackData

	end
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

function SkillCastHandler:Initialize()

	self.started = {}
	self.times = {}
	self.delaySum = 0
	self.delayCount = 0
	self.weavingTimeSum = 0
	self.weavingTimeCount = 0
	self.failedCount = 0
	self.weavingErrors = 0

end

function BarStatsHandler:Initialize()

	self.onTimes = {}  		-- holds times the bar gets used
	self.offTimes = {}  	-- holds times the bar gets used
	self.damageOut = 0 		-- holds damage done on the bar
	self.damageIn = 0 		-- holds damage received on the bar
	self.healingOut = 0 	-- holds healing done on the bar
	self.healingIn = 0 		-- holds healing received on the bar

end

function StatDataHandler:Initialize()

	self.min = infinity
	self.max = 0
	self.dmgsum = 0
	self.healsum = 0

end

function UnitStatHandler:Initialize()

	self.value = 0
	self.debuffs = {}

end

local function GetEmtpyFightStats()

	local data = {}

	InitBasicValues(data)

	data.temp =	{
		["stats"] = {}
	}

	data.units = {}

	data.stats = {}	-- stat tracking

	data.resources = ResourceTable:New()

	data.skills = {}
	data.casts = {}
	data.lastIndex = {}
	abilityDurations = {}
	data.barStats = {}

	data.totalWeavingTimeSum = 0
	data.totalWeavingTimeCount = 0
	data.totalWeaponAttacks = 0
	data.totalSkillsFired =  0

	data.performance = {count = 0}

	data.graph = {
		damageOut = {},
		damageIn = {},
		healingOut = {},
		healingIn = {},
	}

	data.buffVersion = 2
	data.calcVersion = 2

	return data

end

local function InitTrialDummies(fight)

	local units = fight.units

	for unitId, unit in pairs(units) do

		if unit.isTrialDummy then

			for abilityId, _ in pairs(TrialDummyBuffs) do

				local fakeLogLine = {LIBCOMBAT_EVENT_GROUPEFFECTS_OUT, fight.combatstart, unitId, abilityId, EFFECT_RESULT_GAINED, BUFF_EFFECT_TYPE_DEBUFF, 0, COMBAT_UNIT_TYPE_TARGET_DUMMY, 0}

				ProcessLog[LIBCOMBAT_EVENT_GROUPEFFECTS_OUT](fight, fakeLogLine)

			end
		end
	end
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

	titleBar:SetValue(0)
	titleBar:SetHidden(false)

	fight:InitTrialDummies()

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

					ability.damageOutTotal = ability.damageOutNormal + ability.damageOutCritical + ability.damageOutBlocked
					ability.hitsOutTotal = ability.hitsOutNormal + ability.hitsOutCritical + ability.hitsOutBlocked
					ability.DPSOut = ability.damageOutTotal / fight.dpstime

				elseif tablekey == "damageIn" then

					ability.damageInTotal = ability.damageInNormal + ability.damageInCritical + ability.damageInBlocked
					ability.hitsInTotal = ability.hitsInNormal + ability.hitsInCritical + ability.hitsInBlocked
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

		local isNotEmpty = unitTotalValue > 0 or (unit and NonContiguousCount(unit.buffs) > 0)
		local isEnemy = unitData and (unitData.unitType ~= COMBAT_UNIT_TYPE_GROUP and unitData.unitType ~= COMBAT_UNIT_TYPE_PLAYER_PET and unitData.unitType ~= COMBAT_UNIT_TYPE_PLAYER)
		local isDamageCategory = menuItem == "damageIn" or menuItem == "damageOut"

		if isNotEmpty and (isEnemy == isDamageCategory) and unitData then

			for name, buff in pairs(unit.buffs) do

				local selectedbuff = selectiondata.buffs[name] or { uptime = 0, count = 0, groupUptime = 0, groupCount = 0, maxStacks = 0 }

				selectedbuff.uptime = selectedbuff.uptime + buff.uptime
				selectedbuff.count = selectedbuff.count + buff.count
				selectedbuff.groupUptime = selectedbuff.groupUptime + buff.groupUptime
				selectedbuff.groupCount = selectedbuff.groupCount + buff.groupCount

				selectedbuff.maxStacks = mathmax(selectedbuff.maxStacks, buff.maxStacks or 0)

				if buff.instances then

					local selinstances = selectedbuff.instances

					if selinstances == nil then

						selectedbuff.instances = {}
						ZO_DeepTableCopy(buff.instances, selectedbuff.instances)

					else

						for abilityId, instance in pairs(buff.instances) do

							local selInstance = selinstances[abilityId]

							if instance and selInstance == nil then

								selinstances[abilityId] = {}
								ZO_DeepTableCopy(instance, selinstances[abilityId])

							elseif instance then
								for stacks = 1, selectedbuff.maxStacks do

									local stackdata = instance[stacks]
									local selstackdata = selInstance[stacks]

									if stackdata and selstackdata == nil then

										selInstance[stacks] = {}
										ZO_DeepTableCopy(stackdata, selInstance[stacks])

									elseif stackdata then

										selstackdata.uptime = selstackdata.uptime + stackdata.uptime
										selstackdata.count = selstackdata.count + stackdata.count
										selstackdata.groupUptime = selstackdata.groupUptime + stackdata.groupUptime
										selstackdata.groupCount = selstackdata.groupCount + stackdata.groupCount

									end
								end

								selInstance.uptime = selInstance.uptime + instance.uptime
								selInstance.count = selInstance.count + instance.count
								selInstance.groupUptime = selInstance.groupUptime + instance.groupUptime
								selInstance.groupCount = selInstance.groupCount + instance.groupCount
							end
						end
					end
				end

				selectedbuff.effectType = buff.effectType

				if data.buffVersion == nil then

					selectedbuff.icon = buff.icon

				elseif data.buffVersion >= 2 then

					selectedbuff.iconId = data.buffVersion and (selectedbuff.iconId or buff.iconId) or buff.icon

				end

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

	local data = fight.calculated
	local currentStats = data.temp.stats

	local key

	if isheal == true and isDamageOut == true then

		barStats.healingOut = barStats.healingOut + hitValue
		key = "healsum"

	elseif isheal == true and isDamageOut == false then

		barStats.healingIn = barStats.healingIn + hitValue
		return

	elseif isheal == false and isDamageOut == true then

		barStats.damageOut = barStats.damageOut + hitValue
		key = "dmgsum"

	elseif isheal == false and isDamageOut == false then

		barStats.damageIn = barStats.damageIn + hitValue
		key = "dmgsum"

	else return end

	for statId, stattype in pairs(statlist) do

		local unitData = unit and unit.statData[statId]
		local unitValue = unitData and unitData.value or 0

		local currentValue = (currentStats[statId] or 0) + unitValue
		local value = hitValue

		local statData = fight:AcquireStatData(statId)
		statData.max = math.max(currentValue, statData.max)

		if stattype == STATTYPE_PENETRATION then

			if isheal == true then

				value = 0

			elseif ismagical ~= nil then

				local resistDataKey = ismagical and "spellResistance" or "physicalResistance"

				local data = unit[resistDataKey]

				data[currentValue] = (data[currentValue] or 0) + value

			end
		end

		if stattype == STATTYPE_CRITICAL then

			value = resultkey == "Blocked" and 0 or 1	-- they can't crit so they don't matter

		elseif stattype == STATTYPE_CRITICALBONUS and resultkey ~= "Critical" then

			value = 0

		elseif stattype == STATTYPE_INCSPELL and ismagical ~= true then

			value = 0

		elseif stattype == STATTYPE_INCWEAPON and ismagical ~= false then

			value = 0

		end

		local statData = fight:AcquireStatData(statId)
		statData[key] = statData[key] + (value * currentValue) -- sum up stats multplied by value, later this is divided by value to get a weighted average
	end
end

local function unpackLogline(t, i, j)
	if i <= j then
		return t[i], unpackLogline(t, i + 1, j)
	end
end

local function ProcessLogDamage(fight, logline)

	local callbacktype, timems, result, sourceUnitId, targetUnitId, abilityId, hitValue, damageType, overflow = unpackLogline(logline, 1, 9)

	if timems < (fight.combatstart-500) or fight.units[sourceUnitId] == nil or fight.units[targetUnitId] == nil then return end

	local ispet = fight.units[sourceUnitId].unittype == COMBAT_UNIT_TYPE_PLAYER_PET 										-- determine if this is pet damage

	local abilitydata
	local isDamageOut
	local unit

	local resultkey = damageResultCategory[result]

	local dmgkey
	local hitkey
	local graphkey

	hitValue = hitValue + overflow

	if callbacktype == LIBCOMBAT_EVENT_DAMAGE_OUT then

		unit = fight:AcquireUnitData(targetUnitId, timems)
		abilitydata = unit:AcquireAbilityData(abilityId, ispet, damageType, "damageOut")	-- get table for ability (within the unittable)
		isDamageOut = true

		dmgkey = ZO_CachedStrFormat("damageOut<<1>>", resultkey)	-- determine categories. For normal incoming damage: dmgkey = "damageNormal", for critical outgoing damage: dmgkey = "damageCritical" ...
		hitkey = ZO_CachedStrFormat("hitsOut<<1>>", resultkey)
		graphkey = "damageOut"

		if overflow > 0 then -- shielded damage

			local shieldResult = damageResultCategory[ACTION_RESULT_DAMAGE_SHIELDED]

			local shieldkey = ZO_CachedStrFormat("damageOut<<1>>", shieldResult)
			abilitydata[shieldkey] = abilitydata[shieldkey] + overflow

			local shieldhitkey = ZO_CachedStrFormat("hitsOut<<1>>", shieldResult)
			abilitydata[shieldhitkey] = abilitydata[shieldhitkey] + 1

		end

	else																												-- incoming and self inflicted Damage are consolidated.

		abilitydata = fight:AcquireUnitData(sourceUnitId, timems):AcquireAbilityData(abilityId, ispet, damageType, "damageIn")
		isDamageOut = false

		dmgkey = ZO_CachedStrFormat("damageIn<<1>>", resultkey)	-- determine categories. For normal incoming damage: dmgkey = "damageNormal", for critical outgoing damage: dmgkey = "damageCritical" ...
		hitkey = ZO_CachedStrFormat("hitsIn<<1>>", resultkey)
		graphkey = "damageIn"

		if overflow > 0 then -- shielded damage

			local shieldResult = damageResultCategory[ACTION_RESULT_DAMAGE_SHIELDED]

			local shieldkey = ZO_CachedStrFormat("damageIn<<1>>", shieldResult)
			abilitydata[shieldkey] = abilitydata[shieldkey] + overflow

			local shieldhitkey = ZO_CachedStrFormat("hitsIn<<1>>", shieldResult)
			abilitydata[shieldhitkey] = abilitydata[shieldhitkey] + 1

		end

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
	[ACTION_RESULT_DAMAGE_SHIELDED] = "Normal",
}

local function ProcessLogHeal(fight, logline, overrideCallbackType)

	local callbacktype, timems, result, sourceUnitId, targetUnitId, abilityId, hitValue, powerType, overflow = unpackLogline(logline, 1, 9)

	callbacktype = overrideCallbackType or callbacktype

	if timems < (fight.combatstart-500) or fight.units[sourceUnitId] == nil or fight.units[targetUnitId] == nil then return end

	local ispet = fight.units[sourceUnitId].unittype == COMBAT_UNIT_TYPE_PLAYER_PET 										-- determine if this is healing from a pet

	local abilitydata
	local isHealingOut

	local resultkey = healResultCategory[result]

	local valuekey
	local hitkey

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

local function ProcessLogHealSelf (fight, logline)

	ProcessLogHeal(fight, logline, LIBCOMBAT_EVENT_HEAL_OUT)
	ProcessLogHeal(fight, logline, LIBCOMBAT_EVENT_HEAL_IN)

end

ProcessLog[LIBCOMBAT_EVENT_HEAL_SELF] = ProcessLogHealSelf

-- Buffs/Debuffs

local function CountSlots(slots)

	local slotcount = 0
	local groupSlotCount = 0

	for _, slotData in pairs(slots) do

		if slotData.isPlayerSource then slotcount = slotcount + 1 end
		groupSlotCount = groupSlotCount + 1

	end

	return slotcount, groupSlotCount
end

local function ProcessLogEffects(fight, logline)

	local callbacktype, timems, unitId, abilityId, changeType, effectType, stacks, sourceType, slotId, hitValue = unpackLogline(logline, 1, 10)

	stacks = stacks or 0

	if timems < (fight.combatstart - 500) or fight.units[unitId] == nil then return end

	local unit = fight:AcquireUnitData(unitId, timems)
	local effectdata = unit:AcquireEffectData(abilityId, effectType, stacks)

	local isPlayerSource = sourceType == COMBAT_UNIT_TYPE_PLAYER or sourceType == COMBAT_UNIT_TYPE_PLAYER_PET

	local slots = effectdata.slots
	local slotcount, groupSlotCount = CountSlots(slots)

	local slotdata = slots[slotId]

	if (changeType == EFFECT_RESULT_GAINED or changeType == EFFECT_RESULT_UPDATED) and timems < fight.endtime then

		local starttime = mathmax(effectdata.lastGain or timems, fight.starttime)

		if slotcount == 0 and isPlayerSource then effectdata.firstStartTime = starttime end
		if groupSlotCount == 0 then effectdata.firstGroupStartTime = starttime end

		if slotdata == nil then

			slotdata = {
				["isPlayerSource"] = isPlayerSource,
				["abilityId"] = abilityId,
			}

			slots[slotId] = slotdata

		end

		slotdata[stacks] = slotdata[stacks] or starttime

	elseif changeType == EFFECT_RESULT_FADED then

		slots[slotId] = nil

		local instance = effectdata.instances[abilityId]

		if slotdata and timems > fight.starttime then

			if slotdata.isPlayerSource then slotcount = slotcount - 1 end
			groupSlotCount = groupSlotCount - 1

			slotdata.isPlayerSource = nil	-- remove, so the loop gets only stackData
			slotdata.abilityId = nil

			for stacks, starttime in pairs(slotdata) do

				local stackData = instance[stacks]
				local duration = mathmin(timems, fight.endtime) - starttime

				if isPlayerSource then

					stackData.uptime = stackData.uptime + duration
					stackData.count = stackData.count + 1
					effectdata.count = effectdata.count + 1

				end

				stackData.groupUptime = stackData.groupUptime + duration
				stackData.groupCount = stackData.groupCount + 1
				effectdata.groupCount = effectdata.groupCount + 1
			end

			if slotcount == 0 and effectdata.firstStartTime then

				local duration = mathmin(timems, fight.endtime) - effectdata.firstStartTime

				effectdata.uptime = effectdata.uptime + duration

				effectdata.firstStartTime = nil

			end

			if groupSlotCount == 0 and effectdata.firstGroupStartTime then

				local duration = mathmin(timems,fight.endtime) - effectdata.firstGroupStartTime

				effectdata.groupUptime = effectdata.groupUptime + duration

				effectdata.firstGroupStartTime = nil

			end

		end
	end

	unit:UpdateStats(fight, effectdata, abilityId, hitValue)
end

ProcessLog[LIBCOMBAT_EVENT_EFFECTS_IN] = ProcessLogEffects
ProcessLog[LIBCOMBAT_EVENT_EFFECTS_OUT] = ProcessLogEffects
ProcessLog[LIBCOMBAT_EVENT_GROUPEFFECTS_IN] = ProcessLogEffects
ProcessLog[LIBCOMBAT_EVENT_GROUPEFFECTS_OUT] = ProcessLogEffects


local function ProcessLogResources(fight, logline)

	local callbacktype, timems, abilityId, powerValueChange, powerType = unpackLogline(logline, 1, 5)

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

local function ProcessLogStats(fight, logline)

	local callbacktype, timems, statchange, newvalue, statId = unpackLogline(logline, 1, 5)

	local data = fight.calculated

	data.temp.stats[statId] = newvalue

	local statData = fight:AcquireStatData(statId)

	statData.max = math.max(newvalue, statData.max)
	statData.min = math.min(newvalue, statData.min)

end

ProcessLog[LIBCOMBAT_EVENT_PLAYERSTATS] = ProcessLogStats

local abilityExtraDelay = {[63044] = 100, [63029] = 100, [63046] = 100} -- Radiant Destruction and morphs have a 100ms delay after casting.

local function GetAbilityDuration(abilityId)

	local duration

	if abilityDurations[abilityId] == nil then

		local channeled, castTime, channelTime = GetAbilityCastInfo(abilityId)

		if castTime == 0 then castTime = 1000 end

		abilityDurations[abilityId] = channeled and channelTime or castTime

	end

	return abilityDurations[abilityId] + (abilityExtraDelay[abilityId] or 0)

end

---[[
local function ProcessLogSkillTimings(fight, logline)

	local _, timems, reducedslot, abilityId, status = unpackLogline(logline, 1, 6)

	local skill = fight:AcquireSkillCastData(reducedslot)

	local castData = fight.calculated.casts
	local indexData = fight.calculated.lastIndex
	local lastRegisteredIndex = indexData[abilityId]
	local started = skill.started

	-- Print("calc", LOG_LEVEL_INFO, "[%.3f s] Skill Event: %s (%d), Status: %d, Slot: %d", (timems - fight.combatstart)/1000, GetFormattedAbilityName(abilityId), abilityId, status, reducedslot)

	if status == LIBCOMBAT_SKILLSTATUS_REGISTERED then

		local newCast = {reducedslot, timems}	-- reducedslot, registered, queued, start, end

		local index = #castData + 1

		castData[index] = newCast
		indexData[abilityId] = index   -- keep track of most recent registered instance, since an ability can fail to fire (for example due to poor weaving)

	elseif status == LIBCOMBAT_SKILLSTATUS_QUEUE then

		lastRegisteredIndex = lastRegisteredIndex or indexData[ChangingAbilities[abilityId]]

		if lastRegisteredIndex == nil then

			-- Print("calc", LOG_LEVEL_WARNING, "Missing registered ability on queue event: [%.3f s] %s (%d), Slot: %d", (timems - fight.combatstart)/1000, GetFormattedAbilityName(abilityId), abilityId, reducedslot)
			return

		end

		castData[lastRegisteredIndex][3] = timems

	elseif status == LIBCOMBAT_SKILLSTATUS_INSTANT then

		lastRegisteredIndex = lastRegisteredIndex or indexData[ChangingAbilities[abilityId]]

		if lastRegisteredIndex == nil then

			Print("calc", LOG_LEVEL_WARNING, "[%.3f s] Missing registered ability on instant event: %s (%d), Slot: %d", (timems - fight.combatstart)/1000, GetFormattedAbilityName(abilityId), abilityId, reducedslot)
			return

		else

			local isWeaponAttack = reducedslot%10 == 1 or reducedslot%10 == 2
			local duration = isWeaponAttack and 0 or 1000

			castData[lastRegisteredIndex][4] = timems
			table.insert(skill.times, timems)
			castData[lastRegisteredIndex][5] = timems + duration
			indexData[abilityId] = nli

		end

	elseif status == LIBCOMBAT_SKILLSTATUS_BEGIN_DURATION or status == LIBCOMBAT_SKILLSTATUS_BEGIN_CHANNEL then

		lastRegisteredIndex = lastRegisteredIndex or indexData[ChangingAbilities[abilityId]]

		if lastRegisteredIndex == nil then

			Print("calc", LOG_LEVEL_WARNING, "[%.3f s] Missing registered ability on start event: %s (%d), Slot: %d", (timems - fight.combatstart)/1000, GetFormattedAbilityName(abilityId), abilityId, reducedslot)
			return

		else

			castData[lastRegisteredIndex][4] = timems
			castData[lastRegisteredIndex][5] = timems + GetAbilityDuration(abilityId) + (abilityDelay[abilityId] or 0)
			table.insert(skill.times, timems)
			table.insert(started, lastRegisteredIndex)
			indexData[abilityId] = nil

		end

	elseif status == LIBCOMBAT_SKILLSTATUS_SUCCESS then

		-- looking for suitable start event. Let's assume that every start event will have an end event. Search from earliest time event, until one is found that is within the expected time window

		local indexFound = false

		for k, castindex in ipairs(started) do

			local starttime = castData[castindex][4]
			local timeDiff = timems - starttime

			if timeDiff < (GetAbilityDuration(abilityId) + 250) then

				castData[castindex][5] = math.max(timems, starttime + 1000)
				indexFound = k

				table.remove(started, k)

				break

			end
		end

		if not indexFound then

			Print("calc", LOG_LEVEL_WARNING, "[%.3f s] Missing started ability on success event: %s (%d), Slot: %d", (timems - fight.combatstart)/1000, GetFormattedAbilityName(abilityId), abilityId, reducedslot)
			return

		elseif indexFound > 3 then

			Print("calc", LOG_LEVEL_WARNING, "[%.3f s] Large number of unfinished skills (%d): %s (%d), Slot: %d", indexFound, (timems - fight.combatstart)/1000, GetFormattedAbilityName(abilityId), abilityId, reducedslot)

		end
	end
end

ProcessLog[LIBCOMBAT_EVENT_SKILL_TIMINGS] = ProcessLogSkillTimings --ProcessLogSkillTimingsOld

local function ProcessMessages(fight, logline)

	local callbacktype, timems, messageId, value = unpackLogline(logline, 1, 4)

	if messageId ~= LIBCOMBAT_MESSAGE_WEAPONSWAP then return end

	local barStatsOld = fight:AcquireBarStats(currentbar)

	table.insert(barStatsOld.offTimes, timems)

	currentbar = value

	local barStatsNew = fight:AcquireBarStats(currentbar)

	table.insert(barStatsNew.onTimes, timems)

end

ProcessLog[LIBCOMBAT_EVENT_MESSAGES] = ProcessMessages

ProcessLog[LIBCOMBAT_EVENT_BOSSHP] = function() end

local function ProcessPerformanceStats(fight, logline)

	local callbacktype, timems, avg, min, max, ping = unpackLogline(logline, 1, 6)

	if not (avg and min and max and ping) then return end

	local performance = fight.calculated.performance

	performance.count = performance.count + 1

	performance.minMin = mathmin(performance.minMin or min, min)
	performance.maxMin = mathmax(performance.maxMin or min, min)
	performance.sumMin = min + (performance.sumMin or 0)

	performance.minMax = mathmin(performance.minMax or max, max)
	performance.maxMax = mathmax(performance.maxMax or max, max)
	performance.sumMax = max + (performance.sumMax or 0)

	performance.minAvg = mathmin(performance.minAvg or avg, avg)
	performance.maxAvg = mathmax(performance.maxAvg or avg, avg)
	performance.sumAvg = avg + (performance.sumAvg or 0)

	performance.minPing = mathmin(performance.minPing or ping, ping)
	performance.maxPing = mathmax(performance.maxPing or ping, ping)
	performance.sumPing = ping + (performance.sumPing or 0)
end

ProcessLog[LIBCOMBAT_EVENT_PERFORMANCE] = ProcessPerformanceStats

--]]

local function CalculateChunk(fight)  -- called by CalculateFight or itself
	em:UnregisterForUpdate("CMX_chunk")

	local scalcms = GetGameTimeSeconds()

	local logdata = fight.log

	local istart = fight.cindex
	local iend = mathmin(istart+db.chunksize, #logdata)

	for i=istart+1,iend do

		local logline = logdata[i]
		local logType = logline[1] -- logline[1] is the callbacktype e.g. LIBCOMBAT_EVENT_DAMAGEOUT

		if ProcessLog[logType] then ProcessLog[logType](fight, logline) end

		--if logType == LIBCOMBAT_EVENT_PLAYERSTATS_ADVANCED then Print("debug", LOG_LEVEL_DEBUG, "Advanced Stat!") end

	end

	local titleBar = CombatMetrics_Report_TitleFightTitleBar
	local fightlabel = CombatMetrics_Report_TitleFightTitleName

	if iend >= #logdata then

		Print("calc", LOG_LEVEL_DEBUG, "Start end routine")

		fightlabel:SetText(GetString(SI_COMBAT_METRICS_FINALIZING))

		local data = fight.calculated

		for k,unitData in pairs(fight.units) do

			local unitCalc = data.units[k] -- calculated info is not stored in fight.units but in fight.calculated.units

			if unitData.name == "Offline" then -- delete unknown units. Should only happen to units that did not participate in the fight

				unitData[k] = nil
				data.units[k] = nil

			elseif unitCalc ~= nil then

				local endtime = mathmin(unitCalc.endtime, fight.endtime)

				for _, effectdata in pairs(unitCalc.buffs) do	-- finish buffs that didn't end before end of combat

					local instances = effectdata.instances

					local slots = effectdata.slots

					local slotcount, groupSlotCount = CountSlots(effectdata.slots)

					if groupSlotCount > 0 and fight.starttime ~= 0 then

						for slotId, slotdata in pairs(slots) do

							local abilityId = slotdata.abilityId
							local isPlayerSource = slotdata.isPlayerSource

							local instance = instances[abilityId]

							slotdata.abilityId = nil
							slotdata.isPlayerSource = nil

							for stacks, starttime in pairs(slotdata) do

								local stackData = instance[stacks]
								local duration = endtime - starttime

								if isPlayerSource then

									stackData.uptime = stackData.uptime + duration
									stackData.count = stackData.count + 1

								end

								stackData.groupUptime = stackData.groupUptime + duration
								stackData.groupCount = stackData.groupCount + 1
							end
						end

						if slotcount > 0 then

							local duration = endtime - effectdata.firstStartTime

							effectdata.uptime = effectdata.uptime + duration
							effectdata.count = effectdata.count + slotcount

						end

						local duration = endtime - effectdata.firstGroupStartTime

						effectdata.groupUptime = effectdata.groupUptime + duration
						effectdata.groupCount = effectdata.groupCount + groupSlotCount

					end

					effectdata.slots = nil

					-- calculate efective instance and stack uptime

					local maxDuration = 0

					for abilityId, instance in pairs(instances) do

						local sumStackUptime = 0
						local sumStackGroupUptime = 0

						local maxStacks = 1

						local count = 0
						local groupCount = 0

						local minStacks = math.huge
						local minStackDuration
						local minStackDurationGroup

						for stacks, stackData in pairs(instance) do

							if stacks < minStacks then

								minStacks = stacks
								minStackDuration = stackData.uptime
								minStackDurationGroup = stackData.groupUptime

							end

							sumStackUptime = sumStackUptime + stackData.uptime
							sumStackGroupUptime = sumStackGroupUptime + stackData.groupUptime

							maxStacks = mathmax(maxStacks, stacks)
							count = mathmax(stackData.count, count)
							groupCount = mathmax(stackData.groupCount, groupCount)

						end

						local uptime = (sumStackUptime + (minStackDuration and ((minStacks - 1) * minStackDuration) or 0))/maxStacks
						local groupUptime = (sumStackGroupUptime + (minStackDurationGroup and ((minStacks - 1) * minStackDurationGroup) or 0))/maxStacks

						instance.uptime = uptime
						instance.groupUptime = groupUptime
						instance.count = count
						instance.groupCount = groupCount

						if uptime > maxDuration or groupUptime > maxDuration then

							maxDuration = mathmax(maxDuration, uptime, maxDuration)
							effectdata.iconId = abilityId

						end
					end
				end
			end
		end

		fight:AccumulateStats()

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

		local stats = data.stats

		-- calculate damage sums for the relevant categories

		local damageOut = data.damageOut

		data.damageOutSpells = {}
		initBaseAbility(data.damageOutSpells, "damageOut")

		data.damageOutWeapon = {}
		initBaseAbility(data.damageOutWeapon, "damageOut")

		for id, ability in pairs(damageOut) do

			local isMagic = IsMagickaAbility[ability.damageType]

			local datatable = isMagic == true and data.damageOutSpells or isMagic == false and data.damageOutWeapon

			for key, value in pairs(datatable or {}) do

				if key == "min" or key == "max" then

					datatable[key] = math[key](ability[key], datatable[key])

				else

					datatable[key] = ability[key] + datatable[key]

				end
			end
		end

		if data.damageOutSpells.min == infinity then data.damageOutSpells.min = 0 end
		if data.damageOutWeapon.min == infinity then data.damageOutWeapon.min = 0 end

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

		for key, list in pairs(StatListTable) do

			for statId, stattype in pairs(list) do

				local damagevalues = key == "Spell" and data.damageOutSpells or data.damageOutWeapon

				local statdata = stats[statId]

				local dmgValue = statdata.max
				local healValue = statdata.max

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

				if statdata.dmgsum ~= nil then dmgValue = statdata.dmgsum / totaldmgvalue end

				statdata.dmgavg = dmgValue

				if statdata.healsum ~= nil and stattype ~= STATTYPE_PENETRATION then healValue = statdata.healsum / totalhealvalue end

				statdata.healavg = healValue

				if statdata.min == infinity then statdata.min = 0 end
			end
		end

		for statId, stattype in pairs(IncomingStatList) do

			local statdata = stats[statId]

			local value = statdata.max

			local totaldmgvalue = mathmax(data.damageInTotal, 1)

			if stattype == STATTYPE_CRITICALBONUS then

				totaldmgvalue = mathmax(data.damageInCritical, 1)

			elseif stattype == STATTYPE_INCSPELL then

				totaldmgvalue = mathmax(data.damageInSpells, 1)

			elseif stattype == STATTYPE_INCWEAPON then

				totaldmgvalue = mathmax(data.damageInWeapon, 1)

			end

			if statdata.dmgsum ~= nil then value = statdata.dmgsum / totaldmgvalue end

			statdata.dmgavg = value

		end

		-- calculate skill timings

		local skillData = data.skills
		local castData = data.casts

		local lastValidSkill
		local lastValidWeaponAttack

		local skillBars = fight.charData.skillBars

		for i = #castData, 1, -1 do	-- go backwards to allow deleting without messing up indices

			local reducedslot, registered, queued, startTime, endTime = unpackLogline(castData[i], 1, 5)
			local skill = skillData[reducedslot]

			local bar = mathfloor(reducedslot/10) + 1
			local skillId = skillBars[bar][reducedslot%10]

			if startTime and not ignoredAbilityTiming[skillId] then

				endTime = endTime or (startTime + 1000)

				local isWeaponAttack = reducedslot%10 == 1 or reducedslot%10 == 2

				local delay = startTime - (queued or registered)

				skill.delaySum = skill.delaySum + delay
				skill.delayCount = skill.delayCount + 1

				if lastValidSkill then

					local weavingTime = endTime and castData[lastValidSkill][4] - endTime

					skill.weavingTimeSum = skill.weavingTimeSum + weavingTime
					skill.weavingTimeCount = skill.weavingTimeCount + 1

				end

				if isWeaponAttack then

					if lastValidWeaponAttack and lastValidWeaponAttack - i == 1 then skill.weavingErrors = skill.weavingErrors + 1 end

					lastValidWeaponAttack = i

				else

					if lastValidSkill and lastValidSkill - i == 1 then skill.weavingErrors = skill.weavingErrors + 1 end

					lastValidSkill = i

				end

			else

				table.remove(castData, i)
				skill.failedCount = skill.failedCount + 1

				if lastValidSkill then lastValidSkill = lastValidSkill - 1 end
				if lastValidWeaponAttack then lastValidWeaponAttack = lastValidWeaponAttack - 1 end

			end
		end

		local totalWeavingTimeSum = 0
		local totalWeavingTimeCount = 0
		local totalWeaponAttacks = 0
		local totalSkillsFired = 0
		local totalDelay = 0
		local totalDelayCount = 0

		for reducedslot, skill in pairs(skillData) do

			local isWeaponAttack = reducedslot%10 == 1 or reducedslot%10 == 2
			local timedata = skill.times
			local bar = mathfloor(reducedslot/10) + 1

			local skillId = skillBars[bar][reducedslot%10]

			local ignored = ignoredAbilityTiming[skillId]

			if ignored then skill.ignored = true end

			if skillId then

				local count = #timedata

				skill.count = count

				local delayCount = skill.delayCount

				if delayCount and delayCount > 0 then skill.delayAvg = skill.delaySum / delayCount end

				local weavingTimeCount = skill.weavingTimeCount

				if weavingTimeCount and weavingTimeCount > 0 then skill.weavingTimeAvg = skill.weavingTimeSum / weavingTimeCount end

				if isWeaponAttack then

					totalWeaponAttacks = totalWeaponAttacks + count

				elseif not ignored then

					totalSkillsFired = totalSkillsFired + count
					totalDelay = totalDelay + skill.delaySum
					totalDelayCount = totalDelayCount + delayCount

				end

				if count > 1 then skill.diffTimeAvg = (timedata[#timedata] - timedata[1])/(count - 1) end

				if not (isWeaponAttack or ignored) then

					totalWeavingTimeSum = totalWeavingTimeSum + skill.weavingTimeSum
					totalWeavingTimeCount = totalWeavingTimeCount + skill.weavingTimeCount

				end
			end

			skill.started = nil
		end

		data.totalWeavingTimeSum = totalWeavingTimeSum
		data.totalWeavingTimeCount = totalWeavingTimeCount
		data.totalWeaponAttacks = totalWeaponAttacks
		data.totalSkillsFired = totalSkillsFired
		data.delayAvg = (totalDelayCount > 0 and totalDelay / totalDelayCount) or 0

		data.casts = nil
		data.lastIndex = nil

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

				Print("misc", LOG_LEVEL_WARNING, "Time Array lengths don't match for bar %d", bar)

			end
		end

		-- calculate avh performance values

		local performance = data.performance
		local count = performance.count

		if count > 0 then

			performance.avgMin   = performance.sumMin/count
			performance.avgMax   = performance.sumMax/count
			performance.avgAvg   = performance.sumAvg/count
			performance.avgPing  = performance.sumPing/count

		end

		-- remaining stuff

		data.buffs = fight.playerid ~= nil and data.units[fight.playerid] and data.units[fight.playerid].buffs or {}

		fight.calculating = false
		fight.cindex = nil

		titleBar:SetHidden(true)

		data.temp = nil

		Print("calc", LOG_LEVEL_DEBUG, "Time for final calculations: %.2f ms", (GetGameTimeSeconds() - scalcms) * 1000)

		return

	else

		fight.cindex = iend
		em:RegisterForUpdate("CMX_chunk", 20, function() fight:CalculateChunk() end )

	end

	local chunktime = GetGameTimeSeconds() - scalcms

	local newchunksize = mathmin(mathceil(desiredtime / mathmax(chunktime, 0.001) * db.chunksize / stepsize) * stepsize, 20000)

	Print("calc", LOG_LEVEL_DEBUG, "Chunk calculation time: %.2f ms, new chunk size: %d", chunktime * 1000, newchunksize)

	db.chunksize = newchunksize

	local progress = iend/#logdata

	fightlabel:SetText(stringformat("%s (%.1f%%)", GetString(SI_COMBAT_METRICS_CALC), 100 * progress))

	titleBar:SetValue(progress)

	return
end

local function InitCurrentData()
	CMX.currentdata = {log={}, DPSOut = 0, DPSIn = 0, HPSOut = 0, HPSAOut = 0, HPSIn = 0, dpstime = 0, hpstime = 0, groupDPSOut = 0, groupDPSIn = 0, groupHPSOut = 0, groupHPS = 0}	-- reset currentdata, the previous log is now only linked to the fight.
end

local function AddtoChatLog(logType, ...)

	local logLine = {logType, ...}

	local isEnabled =
	((logType == LIBCOMBAT_EVENT_DAMAGE_OUT or logType == LIBCOMBAT_EVENT_DAMAGE_SELF) and db.chatLog.damageOut == true)
	or ((logType == LIBCOMBAT_EVENT_HEAL_OUT or logType == LIBCOMBAT_EVENT_HEAL_SELF) and db.chatLog.healingOut == true)
	or ((logType == LIBCOMBAT_EVENT_DAMAGE_IN or logType == LIBCOMBAT_EVENT_DAMAGE_SELF) and db.chatLog.damageIn == true)
	or ((logType == LIBCOMBAT_EVENT_HEAL_IN or logType == LIBCOMBAT_EVENT_HEAL_SELF) and db.chatLog.healingIn == true)
	or logType == LIBCOMBAT_EVENT_MESSAGES

	if isEnabled then

		local text, color = CMX.GetCombatLogString(nil, logLine, 12)

		if chatContainer then chatContainer:AddMessageToWindow(chatWindow, text, unpack(color)) end -- in case the container got removed by the user or an addon

	end
end

local function AddToLog(logType, ...)

	if LC.data.inCombat ~= true and logType == LIBCOMBAT_EVENT_PERFORMANCE then return end

	table.insert(CMX.currentdata.log,{logType, ...})

	if db.chatLog.enabled then AddtoChatLog(logType, ...) end
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
	fight.AcquireSkillCastData = AcquireSkillCastData
	fight.AcquireBarStats = AcquireBarStats
	fight.AcquireStatData = AcquireStatData
	fight.InitTrialDummies = InitTrialDummies

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

local function UpdateEvents(event)

	local isGrouped = IsUnitGrouped("player")
	local ava = IsPlayerInAvAWorld() or IsActiveWorldBattleground()

	local IsLightMode = db.lightmode or (db.lightmodeincyrodil and ava == true)
	local isOff = ava == true and db.offincyrodil == true

	local newstatus = (isOff and CMX_STATUS_DISABLED) or (IsLightMode and CMX_STATUS_LIGHTMODE) or CMX_STATUS_ENABLED

	CombatMetrics_LiveReport:Toggle(newstatus ~= CMX_STATUS_DISABLED and db.liveReport.enabled)

	if registrationStatus ~= newstatus then

		if newstatus == CMX_STATUS_DISABLED then

			for i = LIBCOMBAT_EVENT_DAMAGE_OUT, LIBCOMBAT_EVENT_PERFORMANCE do
				LC:UnregisterCallbackType(i, AddToLog, CMX.name)
			end

			LC:UnregisterCallbackType(LIBCOMBAT_EVENT_UNITS, UnitsCallback, CMX.name)
			LC:UnregisterCallbackType(LIBCOMBAT_EVENT_FIGHTRECAP, FightRecapCallback, CMX.name)
			LC:UnregisterCallbackType(LIBCOMBAT_EVENT_FIGHTSUMMARY, FightSummaryCallback, CMX.name)

		elseif newstatus == CMX_STATUS_LIGHTMODE then

			for i = LIBCOMBAT_EVENT_DAMAGE_OUT, LIBCOMBAT_EVENT_PERFORMANCE do
				LC:UnregisterCallbackType(i, AddToLog, CMX.name)
			end

			LC:UnregisterCallbackType(LIBCOMBAT_EVENT_FIGHTSUMMARY, FightSummaryCallback, CMX.name)

			LC:RegisterCallbackType(LIBCOMBAT_EVENT_UNITS, UnitsCallback, CMX.name)
			LC:RegisterCallbackType(LIBCOMBAT_EVENT_FIGHTRECAP, FightRecapCallback, CMX.name)

		elseif newstatus == CMX_STATUS_ENABLED then

			for i = LIBCOMBAT_EVENT_DAMAGE_OUT, LIBCOMBAT_EVENT_PERFORMANCE do

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

	Print("group", LOG_LEVEL_DEBUG, "State: %d, Group: %s", registrationStatus or 0, tostring(registeredGroup or false))
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

	["currentNotificationVersion"] = 0,
	["NotificationRead"] = 0,
	["NotificationAllowed"] = true,
	["ForceNotification"] = false,	-- for dev use

	["showDebugIds"] = false,

	["CombatMetrics_LiveReport"] = { x = 700, y = 500},
	["CombatMetrics_Report"] = { x = GuiRoot:GetWidth()/2, y = GuiRoot:GetHeight()/2-75},

	["FightReport"] = {

		["scale"] 				= zo_roundToNearest(1 / GetSetting(SETTING_TYPE_UI, UI_SETTING_CUSTOM_SCALE), 0.1),
		["category"] 			= "damageOut",
		["mainpanel"] 			= "FightStats",
		["rightpanel"] 			= "buffs",
		["fightstatspanel"] 	= maxStat(),

		["useDisplayNames"] 	= false,
		["showPets"] 			= true,

		["SmoothWindow"] 		= 5,

		["Cursor"]				= true,

		["showWereWolf"] 		= false,

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
		},
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

	if type(db.FightReport.hitCritLayout) == "number" or type(db.FightReport.maxValue) == "boolean" then

		db.FightReport.hitCritLayout = {
			["damageOut"] 	= 1,
			["damageIn"] 	= 1,
			["healingOut"] 	= 1,
			["healingIn"] 	= 1,
		}

		db.FightReport.averageLayout = {
			["damageOut"] 	= 2,
			["damageIn"] 	= 2,
			["healingOut"] 	= 2,
			["healingIn"] 	= 2,
		}

		db.FightReport.maxValue = {
			["damageOut"] 	= true,
			["damageIn"] 	= true,
			["healingOut"] 	= true,
			["healingIn"] 	= true,
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

	CMX.SetCrusher(db.crusherValue)

	if db.chatLog.enabled then zo_callLater(CMX.InitializeChat, 500) end

	CMX.playername = zo_strformat(SI_UNIT_NAME,GetUnitName("player"))
	CMX.inCombat = IsUnitInCombat("player")

	CMX.InitializeUI()

	em:RegisterForEvent(CMX.name.."zone", EVENT_ZONE_CHANGED, UpdateEvents)
	em:RegisterForEvent(CMX.name.."group1", EVENT_GROUP_UPDATE, UpdateEvents)
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

	if GetDisplayName() == "@Solinur" then db.NotificationRead = 0 end -- for dev purposes

	CMX.init = true

	if LibFeedback == nil then

		Print("main", LOG_LEVEL_ERROR, "LibFeedback not found! Make sure the latest version is installed.")

	end
end

-- register event handler function to initialize when addon is loaded
em:RegisterForEvent(CMX.name, EVENT_ADD_ON_LOADED, function(...) Initialize(...) end)