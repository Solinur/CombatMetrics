local _
local em = GetEventManager()
local sv
CombatMetricsFightData = {}
 
local AddonName = "CombatMetricsFightData"
local AddonVersion = 2

local constants = 0

local charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"

local chars = {}
local values = {}

for i = 1, 64 do

	newchar = string.sub(charset, i, i) 
	chars[i-1] = newchar
	values[newchar] = i-1

end

local function GetChar(value, logstringdata, length)

	table.insert(logstringdata, chars[value%64])
	
	local newvalue = math.floor(value/64)
	
	if length > 1 then GetChar(newvalue, logstringdata, length - 1) end
	
end

local function Encode(line, layout)

	local logstringdata = {}

	for i,value in ipairs(line) do
	
		GetChar(value, logstringdata, layout[i]) 
		
	end
	
	local logstring = table.concat(logstringdata,"")
	
	return logstring
end

local function GetValue(value, logstring, length, offset)

	local newchar = string.sub(logstring, offset, offset)

	value = value * 64 + values[newchar]

	offset = offset - 1 

	if length > 1 then offset, value = GetValue(value, logstring, length - 1, offset) end
	
	return offset, value
end

local function Decode(logstring, layout)

	local offset = -1	-- walking trough the string backwards, ignoring the separator...
	local line = {}

	for i = #layout, 1, -1 do
	
		offset, value = GetValue(0, logstring, layout[i], offset)
		line[i] = value
		
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

local statTableLoad = {

	[1] = "spellpower",
	[2] = "spellcrit",
	[3] = "maxmagicka",
	[4] = "spellcritbonus",
	[5] = "spellpen",
	[6] = "weaponpower",
	[7] = "weaponcrit",
	[8] = "maxstamina",
	[9] = "weaponcritbonus",
	[10] = "weaponpen",
	[11] = "maxhealth",
	[12] = "physres",
	[13] = "spellres",
	[14] = "critres",
}

local statTableSave = {}

for key, value in pairs(statTableLoad) do

	statTableSave[value] = key

end

local LAYOUT_COMBAT = 4
local LAYOUT_EVENT = 10
local LAYOUT_STATS = 14
local LAYOUT_POWER = 15
local LAYOUT_MESSAGE = 16

local logTypeToLayout = {

	[4] = LAYOUT_COMBAT,
	[5] = LAYOUT_COMBAT,
	[6] = LAYOUT_COMBAT,
	[7] = LAYOUT_COMBAT,
	[8] = LAYOUT_COMBAT,
	[9] = LAYOUT_COMBAT,
	[10] = LAYOUT_EVENT,
	[11] = LAYOUT_EVENT,
	[12] = LAYOUT_EVENT,
	[13] = LAYOUT_EVENT,
	[14] = LAYOUT_STATS,
	[15] = LAYOUT_POWER,
	[16] = LAYOUT_MESSAGE,
	
}
	
local layouts = {

	[LAYOUT_COMBAT] = {1, 4, 1, 2, 2, 3, 4, 1}, 		-- (19) type, timems, result, sourceUnitId, targetUnitId, abilityId, hitValue, damageType
	[LAYOUT_EVENT] = {1, 4, 2, 3, 1, 1, 1, 1},			-- (15) type, timems, unitId, abilityId, changeType, effectType, stacks, sourceType
	[LAYOUT_STATS] = {1, 4, 4, 4, 1},		 			-- (15) type, timems, statchange, newvalue, statname
	[LAYOUT_POWER] = {1, 4, 3, 3, 1},		 			-- (13) type, timems, abilityId, powerValueChange, powerType
	[LAYOUT_MESSAGE] = {1, 4, 1}, 						-- (7)  type, timems, message (e.g. "weapon swap")
}

local layoutsize = {} -- get total sizes of layouts

for id, layout in pairs(layouts) do

	-- sum layout
	local sum = 1 -- offset by one due to separator
	
	for _, size in ipairs(layout) do
	
		sum = sum + size
		
	end
	
	layoutsize[id] = sum
end

local function encodeCombatLogLine(line, unitConversion)

	local layoutId = logTypeToLayout[line[1]]
	
	if layoutId == nil then

		return
		
	elseif layoutId == LAYOUT_COMBAT then			-- type, timems, result, sourceUnitId, targetUnitId, abilityId, hitValue, damageType
	
		line[3] = CombatResultTableSave[line[3]]
		line[4] = unitConversion[line[4]]
		line[5] = unitConversion[line[5]]		
	
	elseif layoutId == LAYOUT_EVENT then			-- type, timems, unitId, abilityId, changeType, effectType, stacks, sourceType
		
		line[3] = unitConversion[line[3]] or 0
		line[8] = line[8] or 0
		
	elseif layoutId == LAYOUT_STATS then			-- type, timems, statchange, newvalue, statname
		
		line[5] = statTableSave[line[5]]
		line[3] = line[3] + 8388608					-- avoid negative numbers
	
	elseif layoutId == LAYOUT_POWER then			-- type, timems, abilityId, powerValueChange, powerType

		line[3] = line[3] or 0
	
	elseif layoutId == LAYOUT_MESSAGE and type(line[3]) ~= "number" then					-- type, timems, messageId

		return
		
	elseif layoutId ~= LAYOUT_MESSAGE then 

		return
	
	end	
	
	local layout = layouts[layoutId]
	local size = layoutsize[layoutId]
	
	local logstring = Encode(line, layout)
	
	return logstring, size
end

local limiter = 0

local function decodeCombatLogLine(line)

	local linetype = values[string.sub(line, 1, 1)]
	
	local layoutId = logTypeToLayout[linetype]
	
	if layoutId == nil then return end 
		
	layout = layouts[layoutId]
	
	if CMX.db.debuginfo.save then df("%d, %s", linetype, line) end
	
	local logdata = Decode(line, layout)
		
	if layoutId == LAYOUT_COMBAT then						-- type, timems, result, sourceUnitId, targetUnitId, abilityId, hitValue, damageType
	
		logdata[3] = CombatResultTableLoad[logdata[3]]
	
	elseif layoutId == LAYOUT_EVENT then					-- type, timems, unitId, abilityId, changeType, effectType, stacks, sourceType
		
		if logdata[3] == 0 then logdata[3] = nil end
		if logdata[8] == 0 then logdata[8] = nil end
		
	elseif layoutId == LAYOUT_STATS then					-- type, timems, statchange, newvalue, statname
		
		logdata[5] = statTableLoad[logdata[5]]
		logdata[3] = logdata[3] - 8388608					-- recover negative numbers
	
	elseif layoutId == LAYOUT_POWER then					-- type, timems, abilityId, powerValueChange, powerType

		if logdata[3] == 0 then logdata[3] = nil end
	
	elseif layoutId ~= LAYOUT_MESSAGE then					-- type, timems, message (e.g. "weapon swap")

		return
	
	end	
	
	return logdata

end
	
local function convertCombatLog(savedFight, filters)

	local combatlog = savedFight.log
	savedFight.log = nil 

	if filters == false or combatlog == nil or #combatlog == 0 then 
	
		return 	
		
	elseif filters == nil then 
	
		filters = true 
		
	end
	
	savedFight.starttime = combatlog[1][2] or 0 -- use this to store only times relative to the first time entry.
	local starttime = savedFight.starttime
	
	local tempLogTable = {}
	local tempLog = {}
	local currentsize = 0
	
	local unitConversion = savedFight.unitConversion
	
	if filters == true then
		
		for i, line in ipairs(combatlog) do
			
			line[2] = line[2] - starttime	
			
			local logstring, size = encodeCombatLogLine(line, unitConversion)
			
			if logstring then 
			
				table.insert(tempLog, logstring)
				
				currentsize = currentsize + size
				
			end
			
			if currentsize > 975 then
			
				local longstring = table.concat(tempLog, ",")
				table.insert(tempLogTable, longstring)
				
				tempLog = {}
				currentsize = 0
				
			end
		end	
		
	elseif type(filters) == "table" then
	
		for i, line in ipairs(combatlog) do
		
			if filters[line[1]] == true then 
			
				line[2] = line[2] - starttime	
			
				local logstring, size = encodeCombatLogLine(line, unitConversion)
				
				if logstring then 
				
					table.insert(tempLog, logstring)
					
					currentsize = currentsize + size
					
				end
				
				if currentsize > 975 then
				
					local longstring = table.concat(tempLog, ",")
					table.insert(tempLogTable, longstring)
					
					tempLog = {}
					currentsize = 0
					
				end
				
			end
		end
	end
	
	if currentsize > 0 then 
	
		local longstring = table.concat(tempLog, ",")
		table.insert(tempLogTable, longstring)
		
	end
	
	savedFight.stringlog = tempLogTable	-- pin converted log on saved fight 
end

local function recoverCombatLog(loadedFight)

	local strings = loadedFight.stringlog
	
	if strings == nil or #strings == 0 then return end
	
	local combatlog = {}
	local starttime = loadedFight.starttime
	
	for i, data in ipairs(strings) do
	
		for line in string.gfind(data, ",?(.-),") do
		
			local logline = decodeCombatLogLine(line)
			logline[2] = logline[2] + starttime
			table.insert(combatlog, logline)
			
		end
	end
	
	loadedFight.log = combatlog
	loadedFight.stringlog = nil
	
end

local function reduceUnitIds(fight) 

	local newUnits = {}
	local newCalcUnits = {}
	local unitConversion = {}

	local calcData = fight.calculated
	local calcUnits = calcData.units
	
	local count = 1

	for id, unit in pairs(fight.units) do
	
		newUnits[count] = unit
		newCalcUnits[count] = calcUnits[id]
		unitConversion[id] = count
		
		count = count + 1
		
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
	
	collectgarbage()
	
	copy = nil
	
	return size
	
end

local function countSavedVariableConstants(sv)

	if constantTable == nil then 
	
		constantTable = {} 
		constants = 0
		
	end

	if type(sv) ~= "table" then return 1 end
	
	for key, value in pairs(sv) do
	
		if constantTable[key] == nil then 
		
			constantTable[key] = true
			constants = constants + 1 
			
		end
	
		local dtype = type(value)
		
		if (dtype == "number" or dtype == "string" or  dtype == "boolean") and constantTable[value] == nil then 
		
			constantTable[value] = true 
			constants = constants + 1 
			
		elseif dtype == "table" then 
		
			countSavedVariableConstants(value, constantTable) 
			
		end
	end
	
	return constants
end

local function checkSavedVariable(data)

	data = data or sv

	local size = getSavedVariableSize(data)
		
	local constants = countSavedVariableConstants(data)
	
	return size, constants
	
end

local function saveFight(fight, filters)

	newSavedFight = {}

	ZO_DeepTableCopy(fight, newSavedFight)
	
	newSavedFight.svversion = AddonVersion
	
	reduceUnitIds(newSavedFight)
	
	convertCombatLog(newSavedFight, filters)
	
	table.insert(sv, newSavedFight)
end

local function loadFight(id)

	loadedFight = {}

	ZO_DeepTableCopy(sv[id], loadedFight)
	
	recoverCombatLog(loadedFight)
	
	loadedFight.svversion = nil
	
	return loadedFight
end

local function GetFights()

	return sv
	
end

local function ConvertSV(version)

	if version < 2 then -- convert format if coming from CombatMetrics < 0.8

		for i = 1, #sv do
		
			saveFight(sv[1])
			table.remove(sv, 1)
			
		end
	
	end
	
	sv.version = version

end

CombatMetricsFightData.Check = checkSavedVariable
CombatMetricsFightData.Save = saveFight
CombatMetricsFightData.Load = loadFight
CombatMetricsFightData.Convert = ConvertSV
CombatMetricsFightData.GetFights = GetFights

local function Initialize(event, addon)

	if addon ~= AddonName then return end
	
	em:UnregisterForEvent(AddonName, EVENT_ADD_ON_LOADED)
	
	sv = CombatMetricsFightDataSV
	
	if sv == nil or sv.version == nil then sv = {["version"] = AddonVersion} end
	
	local svversion = sv.version
	
	if svversion ~= AddonVersion then ConvertSV(svversion) end
	
end

em:RegisterForEvent(AddonName, EVENT_ADD_ON_LOADED, function(...) Initialize(...) end)