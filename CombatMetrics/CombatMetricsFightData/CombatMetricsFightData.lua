local _
local em = GetEventManager()
local sv

local LOG_LEVEL_VERBOSE = "V"
local LOG_LEVEL_DEBUG = "D"
local LOG_LEVEL_INFO = "I"
local LOG_LEVEL_WARNING ="W"
local LOG_LEVEL_ERROR = "E"

if LibDebugLogger then
	LOG_LEVEL_VERBOSE = LibDebugLogger.LOG_LEVEL_VERBOSE
	LOG_LEVEL_DEBUG = LibDebugLogger.LOG_LEVEL_DEBUG
	LOG_LEVEL_INFO = LibDebugLogger.LOG_LEVEL_INFO
	LOG_LEVEL_WARNING = LibDebugLogger.LOG_LEVEL_WARNING
	LOG_LEVEL_ERROR = LibDebugLogger.LOG_LEVEL_ERROR
end

local function Log(...)
	if not CMX then 
		d("[CombatMetricsFightData]: CMX not found!")
		return
	end
	return CMX.Log("save", ...)
end


CombatMetricsFightData = {}

local AddonName = "CombatMetricsFightData"
local AddonVersion = 22

local charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"

local chars = {}
local values = {}
local sv_default = { ["version"] = AddonVersion }

local globalDict = {
	"name",
	"max",
	"min",
	"count",
	"uptime",
	"groupCount",
	"groupUptime",
	"effectType",
	"maxStacks",
	"iconId",
	"instances",
	"unitId",
	"pet",
	"isheal",
	"starttime",
	"endtime",
	"debuffs",
	"value",
	"damageType",
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
	"HPSIn",
	"healingInNormal",
	"healingInOverflow",
	"healingInCritical",
	"healingInAbsolute",
	"healingInTotal",
	"healsInNormal",
	"healsInOverflow",
	"healsInCritical",
	"healsInAbsolute",
	"healsInTotal",
	"HPSOut",
	"HPSAOut",
	"healingOutNormal",
	"healingOutOverflow",
	"healingOutCritical",
	"healingOutAbsolute",
	"healingOutTotal",
	"healsOutNormal",
	"healsOutOverflow",
	"healsOutCritical",
	"healsOutAbsolute",
	"healsOutTotal",
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
	"damageOut",
	"groupDamageOut",
	"damageIn",
	"healingIn",
	"healingOut",
	"dpsstart",
	"dpsend",
	"unitType",
	"isFriendly",
	"buffs",
	"spellCrit",
	"spellResistance",
	"weaponCrit",
	"physicalResistance",
	"statData",
	"ticks",
	"rate",
	"times",
	"delayAvg",
	"delayCount",
	"delaySum",
	"diffTimeAvg",
	"failedCount",
	"weavingErrors",
	"weavingTimeCount",
	"weavingTimeSum",
	"weavingTimeAvg",
	"unitTag",
	"isDead",
	"displayname",
	"dmgavg",
	"dmgsum",
	"healavg",
	"healsum",
	"gains",
	"gainRate",
	"totalgains",
	"drainRate",
	"totaldrains",
	"stars",
	"slotted",
	"total",
}

assert(LibDataEncode ~= nil, "LibDataEncode wasn't found")
local LDE = LibDataEncode

for i = 1, 64 do
	local newchar = string.sub(charset, i, i)
	chars[i - 1] = newchar
	values[newchar] = i - 1
end

local lastid = 0

local function GetChar(value, logstringdata, length)
	local char = chars[zo_floor(value) % 64]
	if char == nil then return true end
	table.insert(logstringdata, char)

	local newvalue = zo_floor(value / 64)
	if length > 1 then GetChar(newvalue, logstringdata, length - 1) end
end

local function Encode(line, layout)
	local logstringdata = {}
	for i, size in ipairs(layout) do
		if line[i] then
			local error = GetChar(line[i], logstringdata, size)
			if error then Log("save", LOG_LEVEL_WARNING,
					"Invalid value during log encoding: %s (type: %d, value %d) ", tostring(line[i]), line[1], i) end
		end
	end

	local logstring = table.concat(logstringdata, "")
	return logstring
end

local function GetValue(value, logstring, length, offset)
	local newchar = string.sub(logstring, offset, offset)
	if newchar == "" or newchar == nil then return end
	value = value * 64 + values[newchar]
	offset = offset - 1
	if length > 1 then offset, value = GetValue(value, logstring, length - 1, offset) end
	return offset, value
end

local function Decode(logstring, layout)
	local offset = 0
	local line = {}

	for i, chars in ipairs(layout) do
		offset = offset + chars
		local _, value = GetValue(0, logstring, chars, offset)
		line[i] = value or nil
	end
	return line
end

local CombatResultTableLoad = {
	[1] = ACTION_RESULT_DAMAGE,
	[2] = ACTION_RESULT_DOT_TICK,
	[3] = ACTION_RESULT_CRITICAL_DAMAGE,
	[4] = ACTION_RESULT_DOT_TICK_CRITICAL,
	[5] = ACTION_RESULT_BLOCKED_DAMAGE,
	[6] = ACTION_RESULT_DAMAGE_SHIELDED,
	[7] = ACTION_RESULT_HEAL,
	[8] = ACTION_RESULT_HOT_TICK,
	[9] = ACTION_RESULT_CRITICAL_HEAL,
	[10] = ACTION_RESULT_HOT_TICK_CRITICAL,
	[11] = ACTION_RESULT_EFFECT_GAINED_DURATION,
	[12] = ACTION_RESULT_EFFECT_FADED,
}

local CombatResultTableSave = {}
for key, value in pairs(CombatResultTableLoad) do
	CombatResultTableSave[value] = key
end

CombatMechnicFlagTableLoad = {
	[1] = COMBAT_MECHANIC_FLAGS_HEALTH,
	[2] = COMBAT_MECHANIC_FLAGS_MAGICKA,
	[3] = COMBAT_MECHANIC_FLAGS_STAMINA,
	[4] = COMBAT_MECHANIC_FLAGS_ULTIMATE,
	[5] = COMBAT_MECHANIC_FLAGS_WEREWOLF,
	[6] = COMBAT_MECHANIC_FLAGS_DAEDRIC,
	[7] = COMBAT_MECHANIC_FLAGS_MOUNT_STAMINA,
}

local CombatMechnicFlagTableSave = {}
for key, value in pairs(CombatMechnicFlagTableLoad) do
	CombatMechnicFlagTableSave[value] = key
end

CombatMechnicFlagTableLoadLegacy = {
	[-2] = COMBAT_MECHANIC_FLAGS_HEALTH,
	[0]  = COMBAT_MECHANIC_FLAGS_MAGICKA,
	[6]  = COMBAT_MECHANIC_FLAGS_STAMINA,
	[10] = COMBAT_MECHANIC_FLAGS_ULTIMATE,
	[1]  = COMBAT_MECHANIC_FLAGS_WEREWOLF,
	[13] = COMBAT_MECHANIC_FLAGS_DAEDRIC,
	[11] = COMBAT_MECHANIC_FLAGS_MOUNT_STAMINA,
}

local statTableConvert = {
	[1] = LIBCOMBAT_STAT_SPELLPOWER,
	[2] = LIBCOMBAT_STAT_SPELLCRIT,
	[3] = LIBCOMBAT_STAT_MAXMAGICKA,
	[4] = LIBCOMBAT_STAT_SPELLCRITBONUS,
	[5] = LIBCOMBAT_STAT_SPELLPENETRATION,
	[6] = LIBCOMBAT_STAT_WEAPONPOWER,
	[7] = LIBCOMBAT_STAT_WEAPONCRIT,
	[8] = LIBCOMBAT_STAT_MAXSTAMINA,
	[9] = LIBCOMBAT_STAT_WEAPONCRITBONUS,
	[10] = LIBCOMBAT_STAT_WEAPONPENETRATION,
	[11] = LIBCOMBAT_STAT_MAXHEALTH,
	[12] = LIBCOMBAT_STAT_PHYSICALRESISTANCE,
	[13] = LIBCOMBAT_STAT_SPELLRESISTANCE,
	[14] = LIBCOMBAT_STAT_CRITICALRESISTANCE,
}

local LAYOUT_COMBAT = 4
local LAYOUT_EVENT = 10
local LAYOUT_STATS = 14
local LAYOUT_POWER = 15
local LAYOUT_MESSAGE = 16
local LAYOUT_DEATH = 17
local LAYOUT_STATS_ADV = 18
local LAYOUT_SKILL = 19
local LAYOUT_BOSSHP = 20
local LAYOUT_PERFORMANCE = 21
local LAYOUT_QUICKSLOT = 23

local logTypeToLayout = {
	[LIBCOMBAT_EVENT_DAMAGE_OUT] = LAYOUT_COMBAT,
	[LIBCOMBAT_EVENT_DAMAGE_IN] = LAYOUT_COMBAT,
	[LIBCOMBAT_EVENT_DAMAGE_SELF] = LAYOUT_COMBAT,
	[LIBCOMBAT_EVENT_HEAL_OUT] = LAYOUT_COMBAT,
	[LIBCOMBAT_EVENT_HEAL_IN] = LAYOUT_COMBAT,
	[LIBCOMBAT_EVENT_HEAL_SELF] = LAYOUT_COMBAT,
	[LIBCOMBAT_EVENT_EFFECTS_IN] = LAYOUT_EVENT,
	[LIBCOMBAT_EVENT_EFFECTS_OUT] = LAYOUT_EVENT,
	[LIBCOMBAT_EVENT_GROUPEFFECTS_IN] = LAYOUT_EVENT,
	[LIBCOMBAT_EVENT_GROUPEFFECTS_OUT] = LAYOUT_EVENT,
	[LIBCOMBAT_EVENT_PLAYERSTATS] = LAYOUT_STATS,
	[LIBCOMBAT_EVENT_RESOURCES] = LAYOUT_POWER,
	[LIBCOMBAT_EVENT_MESSAGES] = LAYOUT_MESSAGE,
	[LIBCOMBAT_EVENT_DEATH] = LAYOUT_DEATH,
	[LIBCOMBAT_EVENT_PLAYERSTATS_ADVANCED] = LAYOUT_STATS_ADV,
	[LIBCOMBAT_EVENT_SKILL_TIMINGS] = LAYOUT_SKILL,
	[LIBCOMBAT_EVENT_BOSSHP] = LAYOUT_BOSSHP,
	[LIBCOMBAT_EVENT_PERFORMANCE] = LAYOUT_PERFORMANCE,
	[LIBCOMBAT_EVENT_QUICKSLOT] = LAYOUT_QUICKSLOT,
}

local layouts = {
	[LAYOUT_COMBAT] = { 1, 4, 1, 2, 2, 3, 4, 1, 4 }, 				-- (23) type, timems, result, sourceUnitId, targetUnitId, abilityId, hitValue, damageType, overflow
	[LAYOUT_EVENT] = { 1, 4, 2, 3, 1, 1, 1, 1, 4, 3 }, 	-- (23) type, timems, unitId, abilityId, changeType, effectType, stacks, sourceType, slot, hitValue
	[LAYOUT_STATS] = { 1, 4, 4, 4, 1 },											-- (15) type, timems, statchange, newvalue, statId
	[LAYOUT_STATS_ADV] = { 1, 4, 4, 4, 2 },										-- (16) type, timems, statchange, newvalue, statId
	[LAYOUT_POWER] = { 1, 4, 3, 3, 1, 3 },									-- (16) type, timems, abilityId, powerValueChange, powerType, powerValue
	[LAYOUT_MESSAGE] = { 1, 4, 1, 1 },												--  (8) type, timems, messageId (e.g. "weapon swap"), bar
	[LAYOUT_DEATH] = { 1, 4, 1, 2, 3 },											--  (8) type, timems, state, unitId, abilityId/unitId
	[LAYOUT_SKILL] = { 1, 4, 1, 3, 1, 2 },									-- (13) type, timems, reducedslot, abilityId, status, skillDelay
	[LAYOUT_BOSSHP] = { 1, 4, 1, 5, 5 },											-- (17) type, timems, bossId, currenthp, maxhp
	[LAYOUT_PERFORMANCE] = { 1, 4, 2, 2, 2, 2 },  							-- (14) type, timems, avg, min, max, ping
	[LAYOUT_QUICKSLOT] = { 1, 4, 3 },  															--  (9) type, timems, abilityId
}

local layoutsize = {} -- get total sizes of layouts
for id, layout in pairs(layouts) do
	local sum = 0
	for _, size in ipairs(layout) do
		sum = sum + size
	end
	layoutsize[id] = sum + 1 -- offset by one due to separator
end

local function encodeCombatLogLine(line, fight)
	local unitConversion = fight.unitConversion
	local layoutId = logTypeToLayout[line[1]]
	if layoutId == nil then
		return
	elseif layoutId == LAYOUT_COMBAT then -- type, timems, result, sourceUnitId, targetUnitId, abilityId, hitValue, damageType
		line[3] = CombatResultTableSave[line[3]]
		line[4] = unitConversion[line[4]]
		line[5] = unitConversion[line[5]]
		line[6] = line[6] > 0 and line[6] or 0
		line[8] = line[8] or 0
	elseif layoutId == LAYOUT_EVENT then -- type, timems, unitId, abilityId, changeType, effectType, stacks, sourceType, slot
		line[3] = unitConversion[line[3]] or 0
		line[8] = line[8] or 0
	elseif layoutId == LAYOUT_STATS then  -- type, timems, statchange, newvalue, statname
		if line[5] == LIBCOMBAT_STAT_STATUS_EFFECT_CHANCE then 
			line[3] = line[3] * 100
			line[4] = line[4] * 100
		end
		line[3] = zo_round(line[3]) + 8388608  -- avoid negative numbers
	elseif layoutId == LAYOUT_STATS_ADV then  -- type, timems, statchange, newvalue, statname
		line[3] = zo_round(10 * (line[3] + 838860)) -- avoid negative/float numbers
		line[4] = zo_round(line[4] * 10)
	elseif layoutId == LAYOUT_POWER then -- type, timems, abilityId, powerValueChange, powerType
		line[3] = line[3] or -3
		line[4] = line[4] + 131072  -- avoid negative numbers
		line[5] = CombatMechnicFlagTableSave[line[5]]
		line[6] = line[6] or 0
	elseif layoutId == LAYOUT_MESSAGE and type(line[3]) ~= "number" then -- type, timems, messageId
		return
	elseif layoutId == LAYOUT_MESSAGE then
		line[4] = line[4] or 0
	elseif layoutId == LAYOUT_DEATH then
		line[4] = unitConversion[line[4]]
		line[5] = line[5] or 0

		if line[3] > 2 then
			line[5] = unitConversion[line[5]]
		end
	elseif layoutId == LAYOUT_SKILL then -- type, timems, reducedslot, abilityId, status, skillDelay
		line[6] = line[6] or 0
		if line[3] > 64 then line[3] = line[3] - 40 end
	elseif layoutId == LAYOUT_PERFORMANCE then -- type, timems, avg, min, max, ping
		line[3] = zo_floor(line[3])
		line[4] = zo_floor(line[4])
		line[5] = zo_floor(line[5])
		line[6] = zo_floor(line[6])
	elseif layoutId ~= LAYOUT_SKILL and layoutId ~= LAYOUT_BOSSHP then
		return
	end

	local layout = layouts[layoutId]
	local size = layoutsize[layoutId]
	local logstring = Encode(line, layout)

	return logstring, size
end

local function decodeCombatLogLine(line, fight)
	local linetype = values[string.sub(line, 1, 1)]
	local layoutId = logTypeToLayout[linetype]
	if layoutId == nil then return end
	local layout = layouts[layoutId]
	local logdata = Decode(line, layout)

	if layoutId == LAYOUT_COMBAT then -- type, timems, result, sourceUnitId, targetUnitId, abilityId, hitValue, damageType
		logdata[3] = CombatResultTableLoad[logdata[3]]
		logdata[8] = logdata[8] or 0
	elseif layoutId == LAYOUT_EVENT then -- type, timems, unitId, abilityId, changeType, effectType, stacks, sourceType
		if logdata[3] == 0 then logdata[3] = nil end
	elseif layoutId == LAYOUT_STATS or layoutId == LAYOUT_STATS_ADV then -- type, timems, statchange, newvalue, statname
		if fight.svversion < 5 then logdata[5] = statTableConvert[logdata[5]] end
		logdata[3] = logdata[3] - 8388608  -- recover negative numbers		
		if logdata[5] == LIBCOMBAT_STAT_STATUS_EFFECT_CHANCE then 
			logdata[3] = logdata[3] / 100
			logdata[4] = logdata[4] / 100
		end
	elseif layoutId == LAYOUT_STATS_ADV then  -- type, timems, statchange, newvalue, statname
		line[3] = (line[3] / 10) - 838860  -- avoid negative/float numbers
		line[4] = (line[4] / 10)
	elseif layoutId == LAYOUT_POWER then -- type, timems, abilityId, powerValueChange, powerType
		if logdata[3] == 262141 then
			logdata[3] = nil
		elseif logdata[3] > 262140 then
			logdata[3] = logdata[3] - 262144
		end

		logdata[4] = logdata[4] - 131072
		if fight.svversion >= 12 then
			logdata[5] = CombatMechnicFlagTableLoad[logdata[5]]
		else
			if logdata[5] > (COMBAT_MECHANIC_FLAGS_ITERATION_END or 64) then
				logdata[5] = logdata[5] - 64 -- POWERTYPE_HEALTH is -2
			end

			if (GetAPIVersion() or 0) >= 101034 and (fight.APIversion or 0) < 101034 then
				logdata[5] = CombatMechnicFlagTableLoadLegacy[logdata[5]]
			end
		end

		if logdata[6] == 0 then logdata[6] = nil end
	elseif layoutId == LAYOUT_MESSAGE then
		logdata[4] = logdata[4] or 0
	elseif layoutId == LAYOUT_DEATH then
		if logdata[5] == 0 then logdata[5] = nil end
	elseif layoutId == LAYOUT_SKILL then
		if logdata[6] == 0 then logdata[6] = nil end
		if logdata[3] > 30 then logdata[3] = logdata[3] + 40 end
	elseif layoutId ~= LAYOUT_PERFORMANCE and layoutId ~= LAYOUT_BOSSHP then -- type, timems, message (e.g. "weapon swap")
		return
	end

	return logdata
end

local function convertCombatLog(savedFight, filters)
	local combatlog = savedFight.log

	if filters == false or combatlog == nil or #combatlog == 0 then
		return
	elseif filters == nil then
		filters = true
	end

	local starttime = (savedFight.starttime or combatlog[1][2] or 0) - 1000 -- prevent negative numbers

	local stringlog = {}
	local tempLog = {}
	local currentsize = 0

	if filters == true then
		for i, line in ipairs(combatlog) do
			line[2] = line[2] - starttime
			local logstring, size = encodeCombatLogLine(line, savedFight)
			if logstring then
				table.insert(tempLog, logstring)
				currentsize = currentsize + size
			end

			if currentsize > 975 then
				local longstring = table.concat(tempLog, ",")
				table.insert(stringlog, longstring)

				tempLog = {}
				currentsize = 0
			end
		end
	elseif type(filters) == "table" then
		for i, line in ipairs(combatlog) do
			if filters[line[1]] == true then
				line[2] = line[2] - starttime
				local logstring, size = encodeCombatLogLine(line, savedFight)
				if logstring then
					table.insert(tempLog, logstring)
					currentsize = currentsize + size
				end

				if currentsize > 975 then
					local longstring = table.concat(tempLog, ",")
					table.insert(stringlog, longstring)

					tempLog = {}
					currentsize = 0
				end
			end
		end
	end

	if currentsize > 0 then
		local longstring = table.concat(tempLog, ",")
		table.insert(stringlog, longstring)
	end

	savedFight.log = nil
	return stringlog
end

local function recoverCombatLog(loadedFight)
	local strings = loadedFight.stringlog
	local timeOffset = 0
	if loadedFight.svversion >= 3 then timeOffset = 1000 end
	if loadedFight.svversion < 12 and loadedFight.APIversion == nil then
		if loadedFight.ESOversion ~= nil then
			local _, _, ESOMainVersion = string.find(loadedFight.ESOversion, "eso%.%w+%.(%d+)")
			loadedFight.APIversion = (tonumber(ESOMainVersion) or 0) + 101026
		else
			loadedFight.APIversion = 0
		end
	end

	if GetAPIVersion() >= 101034 and loadedFight.APIversion < 101034 then
		local resources = {}
		for oldkey, data in pairs(loadedFight.calculated.resources) do
			local newkey = CombatMechnicFlagTableLoadLegacy[oldkey]
			if newkey == nil then
				resources = loadedFight.calculated.resources
				break
			end
			resources[newkey] = data
		end

		loadedFight.calculated.resources = resources
	end

	if strings == nil or #strings == 0 then return end

	local combatlog = {}
	local starttime = loadedFight.starttime - timeOffset

	for i, data in ipairs(strings) do
		for line in string.gmatch(data, "([^,]+)") do
			local logline = decodeCombatLogLine(line, loadedFight)
			if logline and logline[2] < 16600000 then
				logline[2] = logline[2] + starttime
			elseif logline then
				logline[2] = logline[2] + starttime - 16777216
			end

			table.insert(combatlog, logline)
		end
	end

	loadedFight.log = combatlog
	loadedFight.stringlog = nil
	loadedFight.unitConversion = nil
end

local function reduceUnitIds(fight)
	if fight.units == nil then fight.units = {} end
	local newUnits = {}
	local newCalcUnits = {}
	local unitConversion = {}
	local calcData = fight.calculated
	local calcUnits = calcData.units
	local newId = 1

	for id, unit in pairs(fight.units) do
		unit.zenEffectSlot = nil
		unit.stacksOfZen = nil
		unit.forceOfNature = nil
		unit.forceOfNatureStacks = nil

		newUnits[newId] = unit
		newCalcUnits[newId] = calcUnits[id]
		unitConversion[id] = newId

		if unit.unitType == 1 then fight.playerid = newId end
		newId = newId + 1
	end

	if fight.bosses == nil then fight.bosses = {} end
	local bosses = fight.bosses
	for bossid, unitId in pairs(bosses) do
		bosses[bossid] = unitConversion[unitId]
	end

	fight.units = newUnits
	fight.unitConversion = unitConversion
	calcData.units = newCalcUnits
end


local function getSavedVariableSize(sv)
	local copy = {}
	collectgarbage("stop")
	local before = collectgarbage("count")
	ZO_DeepTableCopy(sv, copy)
	local after = collectgarbage("count")
	local size = (after - before) / 1024
	collectgarbage("restart")
	copy = nil
	collectgarbage()
	return size
end

local function checkSavedVariable(data)
	data = data or sv
	local size = getSavedVariableSize(data)
	return size
end

local function copyFightMetaData(sourceFight, destFight)
	if destFight == nil then destFight = {} end

	destFight.fightlabel = sourceFight.fightlabel
	local charName = sourceFight.charData and sourceFight.charData.name or sourceFight.char or ""
	destFight.charData = {name = charName}
	destFight.zone = sourceFight.zone
	destFight.subzone = sourceFight.subzone
	destFight.date = sourceFight.date
	destFight.time = sourceFight.time
	destFight.calculated = {
		DPSOut = sourceFight.calculated.DPSOut,
		DPSIn = sourceFight.calculated.DPSIn,
		HPSOut = sourceFight.calculated.HPSOut,
		HPSIn = sourceFight.calculated.HPSIn,

	}
	destFight.hpstime = sourceFight.hpstime
	destFight.dpstime = sourceFight.dpstime

	return destFight
end


local function saveFight(fight, filters)
	local fightCopy = ZO_DeepTableCopy(fight)
	reduceUnitIds(fightCopy)
	local stringlog = convertCombatLog(fightCopy, filters)
	local savedData = {}
	savedData.encodedStrings = LDE.Encode(fightCopy, true, globalDict)
	savedData.stringlog = stringlog
	savedData.svversion = AddonVersion
	savedData.log = (stringlog ~= nil)
	copyFightMetaData(fightCopy, savedData)
	table.insert(sv, savedData)
end

local function loadFight(id)
	local loadedFight = {}
	local savedFight = sv[id]
	if savedFight.encodedStrings ~= nil and savedFight.svversion >= 14 then
		loadedFight = LDE.Decode(savedFight.encodedStrings, globalDict)
		loadedFight.stringlog = savedFight.stringlog
		loadedFight.svversion = savedFight.svversion
	else
		ZO_DeepTableCopy(sv[id], loadedFight)
	end
	recoverCombatLog(loadedFight)
	return loadedFight
end

local function deleteFight(id)
	table.remove(sv, id)
end

local function deleteLog(id)
	sv[id]["stringlog"] = {}
end

local function getNumFights()
	if sv == nil then return 0 end
	return #sv
end

local function GetFight(id)
	if id == -1 then
		return sv[#sv]
	end
	return sv[id]
end

local function GetFights()
	return sv
end

local function CleanupFight(fight)
	local calculated = fight.calculated

	local barStats = calculated.barStats
	if barStats ~= nil then
		if barStats[1] then
			barStats[1].onTimes = nil
			barStats[1].offTimes = nil
		end
		if barStats[2] then
			barStats[2].onTimes = nil
			barStats[2].offTimes = nil
		end
	end

	for _, buff in pairs(calculated.buffs) do
		buff.firstStartTime = nil
		buff.firstGroupStartTime = nil
	end

	for _, unit in pairs(calculated.units) do
		for _, buff in pairs(unit.buffs) do
			buff.firstStartTime = nil
			buff.firstGroupStartTime = nil
		end
	end
end

local nextEncodeId = 1
local oldSV

local function FinishEncoding()
	for _ = 1, #oldSV do
		table.remove(sv, 1)
	end
	sv.version = AddonVersion
	Log(LOG_LEVEL_INFO, "Conversion Finished!")

	local titleBar = CombatMetrics_Report_TitleFightTitleBar
	titleBar:SetValue(0)
	titleBar:SetHidden(true)

	local fightlabel = CombatMetrics_Report_TitleFightTitleName
	fightlabel:SetText(zo_strformat(SI_COMBAT_METRICS_CONVERSION_FINISHED_TEXT))
	oldSV = nil
end

local function EncodeNextFight()
	local titleBar = CombatMetrics_Report_TitleFightTitleBar
	local fightlabel = CombatMetrics_Report_TitleFightTitleName

	if nextEncodeId <= #oldSV then
		fightlabel:SetText(zo_strformat(SI_COMBAT_METRICS_CONVERSION_TITLE_TEXT, nextEncodeId, #oldSV))
		local loaded = loadFight(nextEncodeId)
		CleanupFight(loaded)
		local log = loaded.log
		loaded.log = nil
		local testresult = LDE.PerformTest("Testfight" .. nextEncodeId, loaded, true, globalDict)
		loaded.log = log
		if testresult and testresult.result then
			saveFight(loaded)
			titleBar:SetValue(nextEncodeId / #oldSV)
			nextEncodeId = nextEncodeId + 1
			zo_callLater(EncodeNextFight, 100)
		else
			sv = oldSV
			_G["CombatMetricsFightDataSV"] = sv
			assert(false, string.format("Test encoding on fight %d failed! Aborting ...", nextEncodeId))
			return
		end
	else
		FinishEncoding()
	end
end

local function StartEncodingSavedFights()
	Log(LOG_LEVEL_INFO, "Converting saved fight from version %d to %d ...", sv.version, AddonVersion)
	oldSV = ZO_ShallowTableCopy(sv)

	local titleBar = CombatMetrics_Report_TitleFightTitleBar
	titleBar:SetValue(0)
	titleBar:SetHidden(false)

	local fightlabel = CombatMetrics_Report_TitleFightTitleName
	fightlabel:SetText(zo_strformat(SI_COMBAT_METRICS_CONVERSION_TITLE_TEXT, 1, #oldSV))

	if SCENE_MANAGER:IsShowing("CMX_REPORT_SCENE") == false then CombatMetrics_Report.Toggle() end
	zo_callLater(EncodeNextFight, 100)
end

local function InitConversionDialog()
	ESO_Dialogs["CMX_ConvertSV_Dialog"] = {
		canQueue = true,
		uniqueIdentifier = "CMX_ConvertSV_Dialog",
		title = { text = SI_COMBAT_METRICS_CONVERT_DB_TITLE },
		mainText = { text = SI_COMBAT_METRICS_CONVERT_DB_TEXT },
		buttons = {
			[1] = {
				text = SI_COMBAT_METRICS_CONVERT_DB_BUTTON1_TEXT,
				callback = StartEncodingSavedFights
			},
			[2] = {
				text = SI_COMBAT_METRICS_CONVERT_DB_BUTTON2_TEXT,
				callback = function() end
			},
		},
	}
end

local function ConvertSV()
	local version = sv.version
	local converted = false
	if version < 2 then -- convert format if coming from CombatMetrics < 0.8
		Log(LOG_LEVEL_INFO, "Converting saved fight from version %d to %d ...", version, 13)
		for i = 1, #sv do
			saveFight(sv[1])
			table.remove(sv, 1)
		end
		converted = true
		sv.version = 13
	end

	if version < 14 then
		ZO_Dialogs_ShowDialog("CMX_ConvertSV_Dialog")
	end

	if converted then Log(LOG_LEVEL_INFO, "Conversion Finished!") end
end

CombatMetricsFightData.Check = checkSavedVariable
CombatMetricsFightData.Save = saveFight
CombatMetricsFightData.Load = loadFight
CombatMetricsFightData.GetFights = GetFights
CombatMetricsFightData.GetFight = GetFight
CombatMetricsFightData.Delete = deleteFight
CombatMetricsFightData.DeleteLog = deleteLog
CombatMetricsFightData.GetNumFights = getNumFights

function CMX_CopyFight(n)
	for i = 1, n do
		table.insert(sv, sv[#sv])
	end
end

function InitializeCMXFightData()
	Log(LOG_LEVEL_INFO, "Starting init of fight data ...")

	sv = _G["CombatMetricsFightDataSV"]
	if sv == nil or sv.version == nil then
		sv = sv_default
		_G["CombatMetricsFightDataSV"] = sv
	end

	if sv.version ~= AddonVersion then
		InitConversionDialog()
		ConvertSV()
	end

	Log(LOG_LEVEL_INFO, "Init of fight data complete.")
	_G["InitializeCMXFightData"] = nil
end

