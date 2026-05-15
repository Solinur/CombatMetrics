-- Utilities: category constants and data query helpers.
---@class CMX
local CMX = CombatMetrics
---@class CMXint
local CMXint = CMX.internal
---@class CMXutil
local util = CMXint.util
---@type Logger
local logger

util.MainCategories = {
	CMX_CATEGORY_DAMAGE_DONE = "damageDone",
	CMX_CATEGORY_DAMAGE_RECEIVED = "damageReceived",
	CMX_CATEGORY_HEALING_DONE = "healingDone",
	CMX_CATEGORY_HEALING_RECEIVED = "healingReceived",
}
local cat = util.MainCategories

util.OppositionCategory = {
	[cat.CMX_CATEGORY_DAMAGE_DONE] = cat.CMX_CATEGORY_DAMAGE_RECEIVED,
	[cat.CMX_CATEGORY_DAMAGE_RECEIVED] = cat.CMX_CATEGORY_DAMAGE_DONE,
	[cat.CMX_CATEGORY_HEALING_DONE] = cat.CMX_CATEGORY_HEALING_RECEIVED,
	[cat.CMX_CATEGORY_HEALING_RECEIVED] = cat.CMX_CATEGORY_HEALING_DONE,
}

---@return boolean
function util.IsDamageCategory()
	local category = CMXint.settings.fightReport.category
	return category == cat.CMX_CATEGORY_DAMAGE_DONE or category == cat.CMX_CATEGORY_DAMAGE_RECEIVED
end

---@return boolean
function util.IsHealingCategory()
	local category = CMXint.settings.fightReport.category
	return category == cat.CMX_CATEGORY_HEALING_DONE or category == cat.CMX_CATEGORY_HEALING_RECEIVED
end

---@return boolean
function util.IsDefenseCategory()
	local category = CMXint.settings.fightReport.category
	return category == cat.CMX_CATEGORY_DAMAGE_RECEIVED
end

---@param fightData Fight
---@param category string
---@param unitIds? integer[]
---@param abilityIds? table<integer, boolean>
function util.GetCombinedPlayerCategoryData(fightData, category, unitIds, abilityIds)
	if category == cat.CMX_CATEGORY_DAMAGE_DONE then
		return LibCombat2.GetPlayerDamageDoneToUnits(fightData, unitIds, abilityIds)
	elseif category == cat.CMX_CATEGORY_DAMAGE_RECEIVED then
		return LibCombat2.GetPlayerDamageReceivedByUnits(fightData, unitIds, abilityIds)
	elseif category == cat.CMX_CATEGORY_HEALING_DONE then
		return LibCombat2.GetPlayerHealingDoneToUnits(fightData, unitIds, abilityIds)
	elseif category == cat.CMX_CATEGORY_HEALING_RECEIVED then
		return LibCombat2.GetPlayerHealingReceivedByUnits(fightData, unitIds, abilityIds)
	else
		logger:Error("unexpected value for category: %s", category)
	end
end

---@param fightData Fight
---@param category string
---@param unitIds? integer[]
function util.GetCombinedPlayerCategoryDataByAbility(fightData, category, unitIds)
	if category == cat.CMX_CATEGORY_DAMAGE_DONE then
		return LibCombat2.GetPlayerDamageDoneToUnitsByAbility(fightData, unitIds)
	elseif category == cat.CMX_CATEGORY_DAMAGE_RECEIVED then
		return LibCombat2.GetPlayerDamageReceivedByUnitsByAbility(fightData, unitIds)
	elseif category == cat.CMX_CATEGORY_HEALING_DONE then
		return LibCombat2.GetPlayerHealingDoneToUnitsByAbility(fightData, unitIds)
	elseif category == cat.CMX_CATEGORY_HEALING_RECEIVED then
		return LibCombat2.GetPlayerHealingReceivedByUnitsByAbility(fightData, unitIds)
	else
		logger:Error("unexpected value for category: %s", category)
	end
end

---@param fightData Fight
---@param category string
function util.GetCombinedGroupCategoryData(fightData, category)
	if category == cat.CMX_CATEGORY_DAMAGE_DONE then
		return LibCombat2.GetDamageDoneToUnits(fightData)
	elseif category == cat.CMX_CATEGORY_DAMAGE_RECEIVED then
		return LibCombat2.GetDamageReceivedByUnits(fightData)
	elseif category == cat.CMX_CATEGORY_HEALING_DONE then
		return LibCombat2.GetHealingDoneToUnits(fightData)
	elseif category == cat.CMX_CATEGORY_HEALING_RECEIVED then
		return LibCombat2.GetHealingReceivedByUnits(fightData)
	else
		logger:Error("unexpected value for category: %s", category)
	end
end

---@param fightData Fight
---@param category string
---@param unitId integer
function util.GetUnitCategoryData(fightData, category, unitId)
	if category == cat.CMX_CATEGORY_DAMAGE_DONE then
		return LibCombat2.GetUnitDamageDone(fightData, unitId)
	elseif category == cat.CMX_CATEGORY_DAMAGE_RECEIVED then
		return LibCombat2.GetUnitDamageReceived(fightData, unitId)
	elseif category == cat.CMX_CATEGORY_HEALING_DONE then
		return LibCombat2.GetUnitHealingDone(fightData, unitId)
	elseif category == cat.CMX_CATEGORY_HEALING_RECEIVED then
		return LibCombat2.GetUnitHealingReceived(fightData, unitId)
	else
		logger:Error("unexpected value for category: %s", category)
	end
end

---@param x number
---@param y number
---@return number
function util.SafeDivide(x, y)
	if y == 0 then
		return x
	end
	return zo_round(x / y)
end

---@param number number
---@return string
function util.GetShortFormattedNumber(number)
	if number == nil or number == 0 then
		return "0"
	end

	local exponent = zo_floor(math.log(zo_abs(number)) / math.log(10))
	local loweredNumber = zo_roundToNearest(number, zo_pow(10, exponent - 2))
	local shortNumber = ZO_AbbreviateNumber(loweredNumber, 2, exponent >= 6)

	return shortNumber
end

CMX_POSTTOCHAT_MODE_NONE = 0
CMX_POSTTOCHAT_MODE_SINGLE = 1
CMX_POSTTOCHAT_MODE_MULTI = 2
CMX_POSTTOCHAT_MODE_SINGLEANDMULTI = 3
CMX_POSTTOCHAT_MODE_SMART = 4
CMX_POSTTOCHAT_MODE_HEALING = 5
CMX_POSTTOCHAT_MODE_SELECTION = 6
CMX_POSTTOCHAT_MODE_SELECTION_HEALING = 7
CMX_POSTTOCHAT_MODE_SELECTED_UNIT = 8
CMX_POSTTOCHAT_MODE_SELECTED_UNITNAME = 9

local function slashCommandFunction(extra)
	if extra == "reset" then
		LibCombat2.ResetFight()
	-- elseif extra == "dps" then
	-- 	util.PosttoChat(CMX_POSTTOCHAT_MODE_SMART)
	-- elseif extra == "totdps" then
	-- 	util.PosttoChat(CMX_POSTTOCHAT_MODE_MULTI)
	-- elseif extra == "alldps" then
	-- 	util.PosttoChat(CMX_POSTTOCHAT_MODE_SINGLEANDMULTI)
	-- elseif extra == "hps" then
	-- 	util.PosttoChat(CMX_POSTTOCHAT_MODE_HEALING)
	else
		CombatMetricsReport:Toggle()
	end
end

SLASH_COMMANDS["/cmx"] = slashCommandFunction

-- local function GetSingleTargetDamage(data) -- Gets highest Single Target Damage and counts enemy units.
-- 	local damage, groupDamage, unittime, name = 0, 0, 0, ""

-- 	for unitId, unit in pairs(data.units) do
-- 		local totalUnitDamage = unit.damageOutTotal

-- 		if totalUnitDamage > 0 and unit.isFriendly == false then
-- 			if totalUnitDamage > damage then
-- 				name = unit.name
-- 				damage = totalUnitDamage
-- 				groupDamage = unit.groupDamageOut
-- 				unittime = (unit.dpsend or 0) - (unit.dpsstart or 0)
-- 			end
-- 		end
-- 	end

-- 	unittime = unittime > 0 and unittime / 1000 or data.dpstime
-- 	groupDamage = zo_max(damage, groupDamage)

-- 	return damage, groupDamage, name, unittime
-- end

-- local function GetBossTargetDamage(data) -- Gets Damage done to bosses and counts enemy boss units.
-- 	if not data.bossfight then
-- 		return 0, 0, 0, nil, 0
-- 	end

-- 	local totalBossDamage, bossDamage, bossUnits = 0, 0, 0
-- 	local totalBossGroupDamage = 0
-- 	local bossName
-- 	local starttime
-- 	local endtime

-- 	for unitId, unit in pairs(data.units) do
-- 		local totalUnitDamage = unit.damageOutTotal
-- 		local totalUnitGroupDamage = unit.groupDamageOut

-- 		if unit.bossId ~= nil and totalUnitDamage > 0 then
-- 			totalBossDamage = totalBossDamage + totalUnitDamage
-- 			totalBossGroupDamage = totalBossGroupDamage + totalUnitGroupDamage
-- 			bossUnits = bossUnits + 1

-- 			starttime = zo_min(starttime or unit.dpsstart or 0, unit.dpsstart or 0)
-- 			endtime = zo_max(endtime or unit.dpsend or 0, unit.dpsend or 0)

-- 			if totalUnitDamage > bossDamage then
-- 				bossName = unit.name
-- 				bossDamage = totalUnitDamage
-- 			end
-- 		end
-- 	end

-- 	if bossUnits == 0 then
-- 		return 0, 0, 0, nil, 0
-- 	end

-- 	local bossTime = (endtime - starttime) / 1000
-- 	bossTime = bossTime > 0 and bossTime or data.dpstime

-- 	return bossUnits, totalBossDamage, totalBossGroupDamage, bossName, bossTime
-- end

-- local function GetSelectionDamage(data, selection) -- Gets highest Single Target Damage and counts enemy units.
-- 	local units = 0
-- 	local damage = 0
-- 	local starttime
-- 	local endtime
-- 	local bossDamage = 0
-- 	local bossName = ""

-- 	local unitdata = data.units
-- 	selection = selection or unitdata

-- 	for unitId, _ in pairs(selection) do
-- 		local unit = unitdata[unitId]
-- 		local totalUnitDamage = unit.damageOutTotal

-- 		if totalUnitDamage > 0 and unit.isFriendly == false then
-- 			units = units + 1
-- 			damage = damage + totalUnitDamage
-- 			starttime = unit.dpsstart and zo_min(starttime or unit.dpsstart, unit.dpsstart) or starttime
-- 			endtime = unit.dpsend and zo_max(endtime or unit.dpsend, unit.dpsend) or endtime

-- 			if totalUnitDamage > bossDamage then
-- 				bossName = unit.name
-- 				bossDamage = totalUnitDamage
-- 			end
-- 		end
-- 	end

-- 	local damageTime = starttime and endtime and (endtime - starttime) / 1000 or 0
-- 	damageTime = damageTime > 0 and damageTime or data.dpstime

-- 	return units, damage, bossName, damageTime
-- end

-- local function GetSelectionHeal(data, selection) -- Gets highest Single Target Damage and counts enemy units.
-- 	local units = 0
-- 	local healing = 0
-- 	local starttime
-- 	local endtime

-- 	local unitdata = data.units
-- 	selection = selection or unitdata
-- 	local calcdata = data.calculated.units

-- 	if not calcdata then
-- 		return
-- 	end

-- 	for unitId, _ in pairs(selection) do
-- 		local unit = unitdata[unitId]
-- 		local totalUnitHeal = calcdata[unitId].healingOutTotal

-- 		if totalUnitHeal and unit.isFriendly == true then
-- 			units = units + 1
-- 			healing = healing + totalUnitHeal
-- 			starttime = zo_min(starttime or unit.hpsstart or 0, unit.hpsstart or 0)
-- 			endtime = zo_max(endtime or unit.hpsend or 0, unit.hpsend or 0)
-- 		end
-- 	end

-- 	local healTime = (endtime - starttime) / 1000
-- 	healTime = healTime > 0 and healTime or data.dpstime

-- 	return units, healing, healTime
-- end

-- local function GetUnitsByName(data, unitId) -- Gets all units that share the name with the one provided by unitId
-- 	local selectedUnits = {}
-- 	local unitName = data.units[unitId].name

-- 	for unitId, unit in pairs(data.units) do
-- 		if unit.name == unitName then
-- 			selectedUnits[unitId] = true
-- 		end
-- 	end

-- 	return selectedUnits
-- end

local function HasUnitType(unit, unitType)
	if unitType == "boss" and unit.bossId then
		return true
	end
	if
		unitType == "group" and (unit.unitType == COMBAT_UNIT_TYPE_GROUP or unit.unitType == COMBAT_UNIT_TYPE_PLAYER)
	then
		return true
	end
	return false
end

local function GetUnitsByType(unitType, fightData)
	if not unitType then
		return
	end
	local units = {}

	for unitId, unit in pairs(fightData.units) do
		if HasUnitType(unit, unitType) then
			units[unitId] = true
		end
	end

	return units
end

local function GetBuffDataAndUnits(unitType, fightData)
	local buffData
	local buffTypeSelection = CMXint.ui.selections.buffTypeSelection
	local units = 0
	local unitName = ""
	local settings = CMXint.settings.fightReport

	if buffTypeSelection == "buffsout" then
		local category = settings.category
		local tempSelections = {}

		ZO_DeepTableCopy(CMXint.ui.selections, tempSelections)
		if unitType then
			tempSelections.unit[category] = GetUnitsByType(unitType)
		end
		-- TODO: refactor
		-- buffData = CMX.GenerateSelectionStats(fightData, category, tempSelections) -- yeah, yeah I'm lazy.

		for unitId, _ in pairs(tempSelections.unit[category] or fightData.units) do
			local unit = fightData.calculated.units[unitId]
			local unitData = fightData.units[unitId]
			local unitTotalValue = unit[category .. "Total"]

			local isNotEmpty = unitTotalValue > 0 or not ZO_IsTableEmpty(unit.buffs)
			local isEnemy = unitData.unitType ~= COMBAT_UNIT_TYPE_GROUP
				and unitData.unitType ~= COMBAT_UNIT_TYPE_PLAYER_PET
				and unitData.unitType ~= COMBAT_UNIT_TYPE_PLAYER
			local isDamageCategory = util.IsDamageCategory()

			if isNotEmpty and (isEnemy == isDamageCategory) then
				units = units + 1
				unitName = unitData.name
			end
		end
	elseif buffTypeSelection == "buffs" then
		buffData = fightData.calculated
	end

	if units == 1 then
		return buffData, unitName
	end

	return buffData, units
end

function util.PostBuffUptime(fight, buffname, unitType)
	local data -- = fight and CMX.lastfights[fight] -- TODO: refactor
	if not data then
		return
	end

	local category = CMXint.settings.fightReport.category or cat.CMX_CATEGORY_DAMAGE_DONE
	local date = data.date
	local datestring = type(date) == "number" and GetDateStringFromTimestamp(date) or date
	local timedata = string.format("[%s, %s] ", datestring, data.time)

	local buffDataTable, units = GetBuffDataAndUnits(unitType) -- TODO provide the single unit if units is 1
	local buffData = buffDataTable.buffs[buffname]
	if buffData == nil then
		return
	end

	local totalUnitTime = buffDataTable.totalUnitTime
	if totalUnitTime then
		totalUnitTime = totalUnitTime / 1000
	end

	local activetime = totalUnitTime or data.dpstime

	if category == "healingOut" or category == "healingIn" then
		activetime = totalUnitTime or data.hpstime
	end

	local uptime = buffData.uptime / 1000
	local groupUptime = buffData.groupUptime / 1000

	local relativeUptimeString = string.format("%.1f%%", uptime / activetime * 100)
	local uptimeString = string.format("%d:%02d", uptime / 60, uptime % 60)

	local output

	if groupUptime > uptime then
		local relativeGroupUptimeString = string.format("%.1f%%", groupUptime / activetime * 100)
		local groupUptimeString = string.format("%d:%02d", groupUptime / 60, groupUptime % 60)
		output = zo_strformat(
			GetString(SI_COMBAT_METRICS_POSTBUFF_FORMAT_GROUP),
			buffname,
			relativeUptimeString,
			uptimeString,
			units,
			relativeGroupUptimeString,
			groupUptimeString
		)
	else
		output = zo_strformat(
			GetString(SI_COMBAT_METRICS_POSTBUFF_FORMAT),
			buffname,
			relativeUptimeString,
			uptimeString,
			units
		)
	end

	-- Determine appropriate channel
	local channel = CMXint.settings.autoSelectChatChannel == true
			and (IsUnitGrouped("player") and CHAT_CHANNEL_PARTY or CHAT_CHANNEL_SAY)
		or nil
	-- Log output to chat

	local outputtext = string.format("%s%s", timedata, output)

	StartChatInput(outputtext, channel)
end

-- TODO: reimplement

-- function util.PosttoChat(mode, fight, UnitContextMenuUnitId)
-- 	local data = fight and CMX.lastfights[fight] or CMXint.FightData:GetCurrentFight()
-- 	if data == nil then
-- 		return
-- 	end

-- 	local date = data.date
-- 	local datestring = type(date) == "number" and GetDateStringFromTimestamp(date) or date
-- 	local timedata = string.format("[%s, %s] ", datestring, data.time)

-- 	local output = ""
-- 	local unitSelection = mode == CMX_POSTTOCHAT_MODE_SELECTION and selections.unit["damageOut"]
-- 		or mode == CMX_POSTTOCHAT_MODE_SELECTED_UNIT and { [UnitContextMenuUnitId] = true }
-- 		or mode == CMX_POSTTOCHAT_MODE_SELECTED_UNITNAME and GetUnitsByName(data, UnitContextMenuUnitId)

-- 	local units, damage, name, dpstime = GetSelectionDamage(data, unitSelection)
-- 	local bossUnits, bossDamage, _, bossName, bossTime = GetBossTargetDamage(data)
-- 	local singleDamage, _, _, singleTime = GetSingleTargetDamage(data)

-- 	dpstime = zo_roundToNearest(dpstime, 0.1)
-- 	singleTime = zo_roundToNearest(singleTime, 0.1)

-- 	name = zo_strformat(SI_UNIT_NAME, (not unitSelection) and bossName or name)

-- 	local bossDamage = data.bossfight and bossDamage or singleDamage
-- 	local bossTime = zo_roundToNearest(data.bossfight and bossTime or singleTime, 0.1)

-- 	if mode == CMX_POSTTOCHAT_MODE_HEALING then
-- 		local hpstime = zo_roundToNearest(data.hpstime, 0.01)
-- 		local timeString = string.format("%d:%04.1f", hpstime / 60, hpstime % 60)
-- 		local totalHPSString = ZO_CommaDelimitNumber(data.HPSOut)
-- 		local totalHealingString = ZO_CommaDelimitNumber(data.healingOutTotal)

-- 		output = zo_strformat(
-- 			GetString(SI_COMBAT_METRICS_POSTHPS_FORMAT),
-- 			name,
-- 			totalHPSString,
-- 			totalHealingString,
-- 			timeString
-- 		)
-- 	elseif mode == CMX_POSTTOCHAT_MODE_SELECTION_HEALING then
-- 		local units, healing, healTime = GetSelectionHeal(data, selections.unit["healingOut"])
-- 		healTime = zo_roundToNearest(healTime, 0.1)

-- 		local timeString = string.format("%d:%04.1f", healTime / 60, healTime % 60)
-- 		local totalHealingString = ZO_CommaDelimitNumber(healing)
-- 		local totalHPSString = ZO_CommaDelimitNumber(zo_floor(healing / healTime))

-- 		output = zo_strformat(
-- 			GetString(SI_COMBAT_METRICS_POSTSELECTIONHPS_FORMAT),
-- 			name,
-- 			units,
-- 			totalHPSString,
-- 			totalHealingString,
-- 			timeString
-- 		)
-- 	elseif units == 1 or mode == CMX_POSTTOCHAT_MODE_SINGLE then
-- 		local damage = mode == CMX_POSTTOCHAT_MODE_SELECTED_UNIT and damage or singleDamage
-- 		local damageTime = mode == CMX_POSTTOCHAT_MODE_SELECTED_UNIT and dpstime or singleTime

-- 		local singleDPSString = ZO_CommaDelimitNumber(zo_floor(damage / damageTime))
-- 		local singleDamageString = ZO_CommaDelimitNumber(damage)
-- 		local timeString = string.format("%d:%04.1f", damageTime / 60, damageTime % 60)

-- 		output = zo_strformat(
-- 			GetString(SI_COMBAT_METRICS_POSTDPS_FORMAT),
-- 			name,
-- 			singleDPSString,
-- 			singleDamageString,
-- 			timeString
-- 		)
-- 	elseif bossUnits > 0 and mode == CMX_POSTTOCHAT_MODE_SMART then
-- 		local bosses = bossUnits > 1 and string.format(" (+%d)", (bossUnits - 1)) or ""
-- 		local bossTimeString = string.format("%d:%04.1f", bossTime / 60, bossTime % 60)

-- 		local bossDPSString = ZO_CommaDelimitNumber(zo_floor(bossDamage / bossTime))
-- 		local bossDamageString = ZO_CommaDelimitNumber(bossDamage)

-- 		output = zo_strformat(
-- 			GetString(SI_COMBAT_METRICS_POSTSMARTDPS_FORMAT),
-- 			name,
-- 			bosses,
-- 			bossDPSString,
-- 			bossDamageString,
-- 			bossTimeString
-- 		)
-- 	elseif units > 1 and (mode == CMX_POSTTOCHAT_MODE_MULTI or mode == CMX_POSTTOCHAT_MODE_SMART) then
-- 		local timeString = string.format("%d:%04.1f", dpstime / 60, dpstime % 60)

-- 		local totalDPSString = ZO_CommaDelimitNumber(zo_floor(data.DPSOut))
-- 		local totalDamageString = ZO_CommaDelimitNumber(damage)

-- 		output = zo_strformat(
-- 			GetString(SI_COMBAT_METRICS_POSTMULTIDPS_FORMAT),
-- 			name,
-- 			units - 1,
-- 			totalDPSString,
-- 			totalDamageString,
-- 			timeString
-- 		)
-- 	elseif mode == CMX_POSTTOCHAT_MODE_SINGLEANDMULTI then
-- 		local bossString = bossUnits > 1
-- 				and string.format("%s (+%d)", GetString(SI_COMBAT_METRICS_BOSS_DPS), bossUnits - 1)
-- 			or bossUnits == 1 and GetString(SI_COMBAT_METRICS_BOSS_DPS)
-- 			or GetString(SI_COMBAT_METRICS_DPS)
-- 		local timeString = string.format("%d:%04.1f", dpstime / 60, dpstime % 60)
-- 		local bossTimeString = string.format("%d:%04.1f", bossTime / 60, bossTime % 60)

-- 		local bossDPSString = ZO_CommaDelimitNumber(zo_floor(bossDamage / bossTime))
-- 		local bossDamageString = ZO_CommaDelimitNumber(bossDamage)

-- 		local totalDPSString = ZO_CommaDelimitNumber(zo_floor(data.DPSOut))
-- 		local totalDamageString = ZO_CommaDelimitNumber(damage)

-- 		local stringA = zo_strformat(
-- 			GetString(SI_COMBAT_METRICS_POSTALLDPS_FORMAT_A),
-- 			name,
-- 			units - 1,
-- 			totalDPSString,
-- 			totalDamageString,
-- 			timeString
-- 		)
-- 		local stringB = zo_strformat(
-- 			GetString(SI_COMBAT_METRICS_POSTALLDPS_FORMAT_B),
-- 			bossString,
-- 			bossDPSString,
-- 			bossDamageString,
-- 			bossTimeString
-- 		)

-- 		output = string.format("%s, %s", stringA, stringB)
-- 	elseif mode == CMX_POSTTOCHAT_MODE_SELECTION or mode == CMX_POSTTOCHAT_MODE_SELECTED_UNITNAME then
-- 		if not unitSelection then
-- 			return
-- 		end

-- 		local extraUnits = units > 1
-- 				and mode == CMX_POSTTOCHAT_MODE_SELECTED_UNITNAME
-- 				and string.format(" (x%d)", units)
-- 			or units > 1 and string.format(" (+%d)", (units - 1))
-- 			or ""

-- 		local DPSString = ZO_CommaDelimitNumber(zo_floor(damage / dpstime))
-- 		local DamageString = ZO_CommaDelimitNumber(damage)
-- 		local timeString = string.format("%d:%04.1f", dpstime / 60, dpstime % 60)

-- 		output = zo_strformat(
-- 			GetString(SI_COMBAT_METRICS_POSTSELECTIONDPS_FORMAT),
-- 			name,
-- 			extraUnits,
-- 			DPSString,
-- 			DamageString,
-- 			timeString
-- 		)
-- 	end

-- 	-- Determine appropriate channel
-- 	local channel = CMXint.settings.autoselectchatchannel == false and ""
-- 		or IsUnitGrouped("player") and "/p "
-- 		or "/say "

-- 	-- Log output to chat
-- 	local outputtext = string.format("%s%s", timedata, output)

-- 	CHAT_SYSTEM.textEntry:SetText(channel .. outputtext)
-- 	CHAT_SYSTEM:Maximize()
-- 	CHAT_SYSTEM.textEntry:Open()
-- 	CHAT_SYSTEM.textEntry:FadeIn()
-- end

function util.GetSelectionData()
	logger:Warn("util.GetSelectionData is not implemented yet.")
end

local isFileInitialized = false
function CMXint.InitializeUtils()
	if isFileInitialized == true then
		return false
	end
	logger = util.initSublogger("Utils")

	isFileInitialized = true
	return true
end
