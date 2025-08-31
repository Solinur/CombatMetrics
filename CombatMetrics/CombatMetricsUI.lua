---@diagnostic disable: assign-type-mismatch
local em = GetEventManager()
local wm = GetWindowManager()
local dx = zo_ceil(GuiRoot:GetWidth()/tonumber(GetCVar("WindowedWidth"))*1000)/1000
COMBAT_METRICS_LINE_SIZE = dx

local currentFight
local abilitystats
local abilitystatsversion = 3
local fightData, selectionData
local currentCLPage
local selections, lastSelections
local savedFights
local SVHandler
local uncollapsedBuffs = {}

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

if GetAPIVersion() < 100034 then CHAMPION_DISCIPLINE_TYPE_COMBAT, CHAMPION_DISCIPLINE_TYPE_CONDITIONING, CHAMPION_DISCIPLINE_TYPE_WORLD = 0, 1, 2 end

local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger
local db
local _

function CMX.GetAbilityStats()

	local isSelection = selections.unit.damageOut ~= nil
	return abilitystats, abilitystatsversion, isSelection

end

local LC = LibCombat
if LC == nil then return end

local GetFormattedAbilityName = LC.GetFormattedAbilityName
local GetFormattedAbilityIcon = LC.GetFormattedAbilityIcon

local SigilAbilities = { -- Ailities to display a warning icon in the buff list to indicate it cannot be considered a "clean" parse
	[236960] = true, -- Sigil of Power
	[236968] = true, -- Sigil of Defense
	[236994] = true, -- Sigil of Ultimate
	[237014] = true, -- Sigil of Speed
} 

local function isSigilAbility(buffAbilityIds)
	if type(buffAbilityIds) ~= "table" then return false end

	for abilityId, _ in pairs(buffAbilityIds) do
		if SigilAbilities[abilityId] then return true end
	end

	return false
end





function CMX.EditTitleStart(control)

	local label = control:GetNamedChild("Name")
	local editbox = control:GetNamedChild("Edit")

	label:SetHidden(true)
	editbox:SetHidden(false)

	editbox:SetText( label:GetText() )
	editbox:SelectAll()
	editbox:TakeFocus()

end

function CMX.EditTitleEnd(editbox)

	local control = editbox:GetParent()
	local label = control:GetNamedChild("Name")

	editbox:SetHidden(true)
	label:SetHidden(false)

	local newtext = editbox:GetText()

	label:SetText( newtext )

	if fightData then fightData.fightlabel = newtext end

end

function CMXint.ClearSelections()

	local category = db.FightReport.category or "damageOut"

	selections["ability"][category] = nil
	selections["unit"][category] = nil
	selections["buff"]["buff"] = nil
	selections["resource"]["resource"] = nil

end


function CMX.SetLabelColor(control, setcolor)  -- setcolor can be hex or rgba, ZO_ColorDef takes care of this

	for i=1, control:GetNumChildren(control) do

		local child = control:GetChild(i)
		local color = ZO_ColorDef:New(setcolor)

		if child:GetType() == CT_LABEL and child.nocolor ~= true then

			child:SetColor(color.r, color.g, color.b, color.a)

		elseif child:GetType() == CT_CONTROL and child.nocolor ~= true then

			CMX.SetLabelColor(child, setcolor)

		end

	end

end

function CMX.UpdateAttackStatsSelector(control)

	local selector = control:GetParent()

	for _, powerType in pairs{"Magicka", "Stamina", "Health"} do

		local control = selector:GetNamedChild(powerType)

		control:GetNamedChild("Line"):SetColor(0.53, 0.53, 0.53, 1)
		control:GetNamedChild("Icon"):SetAlpha(0.5)

	end

	local line = control:GetNamedChild("Line")
	local color = line.color

	line:SetColor(color.r, color.g, color.b, color.a)
	control:GetNamedChild("Icon"):SetAlpha(1)

	local mainPanelRight = selector:GetParent()
	local labels = mainPanelRight:GetNamedChild("AttackStats")

	CMX.SetLabelColor(labels, color)

	db.FightReport.fightstatspanel = control.powerType

	mainPanelRight:Update()
end

function CMXint.SavePosition(control)

	local x, y = control:GetCenter()

	-- Save the Position
	db[control:GetName()] = { ["x"] = x, ["y"] = y}

end

--Slash Commands

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

	if 		extra == "reset" 	then CMX.ResetFight()
	elseif 	extra == "dps" 		then CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SMART)
	elseif 	extra == "totdps" 	then CMX.PosttoChat(CMX_POSTTOCHAT_MODE_MULTI)
	elseif 	extra == "alldps" 	then CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SINGLEANDMULTI)
	elseif 	extra == "hps" 		then CMX.PosttoChat(CMX_POSTTOCHAT_MODE_HEALING)
	else 						CombatMetrics_Report:Toggle()
	end

end

SLASH_COMMANDS["/cmx"] = slashCommandFunction


do	-- Handling Unit Context Menu

	local UnitContextMenuUnitId

	local function postUnitDPS()

		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SELECTED_UNIT, currentFight, UnitContextMenuUnitId)

	end

	local function postUnitNameDPS()

		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SELECTED_UNITNAME, currentFight, UnitContextMenuUnitId)

	end

	local function postSelectionDPS()

		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SELECTION, currentFight)

	end

	local function postSelectionHPS()

		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SELECTION_HEALING, currentFight)

	end

	function CMX.UnitContextMenu( unitItem, upInside )

		local category = db.FightReport.category

		if not (upInside or category == "damageOut" or category == "healingOut") then return end

		local dataId = unitItem.dataId

		ClearMenu()

		if category == "damageOut" then

			UnitContextMenuUnitId = dataId

			local unitName = fightData.units[dataId].name

			AddCustomMenuItem(GetString(SI_COMBAT_METRICS_POSTUNITDPS), postUnitDPS)
			AddCustomMenuItem(zo_strformat(GetString(SI_COMBAT_METRICS_POSTUNITNAMEDPS), unitName, 2), postUnitNameDPS)

			if selections.unit[category] then AddCustomMenuItem(GetString(SI_COMBAT_METRICS_POSTSELECTIONDPS), postSelectionDPS) end

		elseif category == "healingOut" and selections.unit[category] then

			AddCustomMenuItem(GetString(SI_COMBAT_METRICS_POSTSELECTIONHPS), postSelectionHPS)

		end

		ShowMenu(unitItem)

	end

end

do

	local function toggleShowIds()

		db.showDebugIds = not db.showDebugIds
		CombatMetrics_Report:Update()

	end

	local function toggleShowPets()

		db.FightReport.showPets = not db.FightReport.showPets
		CombatMetrics_Report:Update()

	end

	local function toggleOverhealMode()

		CMX.showOverHeal = not CMX.showOverHeal
		CombatMetrics_Report:Update()

	end

	local function postSingleDPS()

		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SINGLE, currentFight)

	end

	local function postSmartDPS()

		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SMART, currentFight)

	end

	local function postMultiDPS()

		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_MULTI, currentFight)

	end

	local function postAllDPS()

		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SINGLEANDMULTI, currentFight)

	end

	local function postSelectionDPS()

		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SELECTION, currentFight)

	end

	local function postHPS()

		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_HEALING, currentFight)

	end

	local function postSelectionHPS()

		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SELECTION_HEALING, currentFight)

	end

	function CMX.SettingsContextMenu( settingsbutton, upInside )

		if not upInside then return end

		local showIdString = db.showDebugIds and SI_COMBAT_METRICS_HIDEIDS or SI_COMBAT_METRICS_SHOWIDS
		local showOverhealString = CMX.showOverHeal and SI_COMBAT_METRICS_HIDEOVERHEAL or SI_COMBAT_METRICS_SHOWOVERHEAL
		local showPetString = db.FightReport.showPets and SI_COMBAT_METRICS_MENU_HIDEPETS or SI_COMBAT_METRICS_MENU_SHOWPETS_NAME

		local postoptions = {}

		table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTSINGLEDPS), callback = postSingleDPS})

		local fight = CMX.lastfights[currentFight]

		if fight and fight.bossfight == true then

			table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTSMARTDPS), callback = postSmartDPS})

		end

		table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTMULTIDPS), callback = postMultiDPS})
		table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTALLDPS), callback = postAllDPS})

		local category = db.FightReport.category

		if category == "damageOut" and selections.unit[category] then

			table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTSELECTIONDPS), callback = postSelectionDPS})

		end

		table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTHPS), callback = postHPS})

		if category == "healingOut" and selections.unit[category] then

			table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTSELECTIONHPS), callback = postSelectionHPS})

		end

		ClearMenu()

		AddCustomMenuItem(GetString(showIdString), toggleShowIds)
		AddCustomMenuItem(GetString(showOverhealString), toggleOverhealMode)
		AddCustomMenuItem(GetString(showPetString), toggleShowPets)
		AddCustomSubMenuItem(GetString(SI_COMBAT_METRICS_POSTDPS), postoptions)
		AddCustomMenuItem(GetString(SI_COMBAT_METRICS_SETTINGS), CMX.OpenSettings)

		if fight and fight.CalculateFight and (fight.svversion == nil or fight.svversion > 2) then

			local function calculate()

				fight:CalculateFight()
				CombatMetrics_Report:Update(currentFight)

			end

			AddCustomMenuItem(GetString(SI_COMBAT_METRICS_RECALCULATE), calculate)

		end

		ShowMenu(settingsbutton)
		AnchorMenu(settingsbutton)

	end
end

do
	local function ShowGuildInfo()
		GUILD_BROWSER_GUILD_INFO_KEYBOARD:SetGuildToShow(64745)
        MAIN_MENU_KEYBOARD:ShowSceneGroup("guildsSceneGroup", "linkGuildInfoKeyboard")
        GUILD_BROWSER_GUILD_INFO_KEYBOARD.closeCallback = CombatMetrics_Report.Toggle
	end

	local function NotificationRead()
		db.NotificationRead = db.currentNotificationVersion
		CombatMetrics_Report:Update(currentFight)
	end

	local function DisableNotifications()
		db.NotificationRead = db.currentNotificationVersion
		db.NotificationAllowed = false
		CombatMetrics_Report:Update(currentFight)
	end

	function CMX.NotificationContextMenu( settingsbutton, upInside )
		if not upInside then return end
		ClearMenu()

		AddCustomMenuItem(GetString(SI_COMBAT_METRICS_NOTIFICATION_GUILD), ShowGuildInfo)
		AddCustomMenuItem(GetString(SI_COMBAT_METRICS_NOTIFICATION_ACCEPT), NotificationRead)
		AddCustomMenuItem(GetString(SI_COMBAT_METRICS_NOTIFICATION_DISCARD), DisableNotifications)

		ShowMenu(settingsbutton)
		AnchorMenu(settingsbutton)
	end
end


--function CMX.AddSelection( selecttype, id, dataId, shiftkey, controlkey, button )  -- IsShiftKeyDown() IsControlKeyDown() IsCommandKeyDown()

function CMX.AddSelection( self, button, upInside, ctrlkey, alt, shiftkey )
	local id = self.id
	local dataId = self.dataId
	local selecttype = self.type

	if button ~= MOUSE_BUTTON_INDEX_LEFT and button ~= MOUSE_BUTTON_INDEX_MIDDLE then return end

	local category = selecttype == "buff" and "buff" or selecttype == "resource" and "resource" or db.FightReport.category

	local sel = selections[selecttype][category] -- can be nil so this is not always a reference
	local lastsel = lastSelections[selecttype][category]
	local bars = self.panel.bars

	if button == MOUSE_BUTTON_INDEX_MIDDLE then
		selections[selecttype][category] = nil
		lastSelections[selecttype][category] = nil
		CombatMetrics_Report:Update(currentFight)

		return
	end

	if sel == nil then	-- if nothing is selected yet, just select this, disregarding all modifiers.
		sel = {[dataId] = id}
		lastsel = id
	elseif shiftkey and not ctrlkey and lastsel ~= nil then 	-- select everything between this and the previous sel if shiftkey is pressed
		local istart = zo_min(lastsel, id)
		local iend = zo_max(lastsel, id)

		sel = {} 	-- forget/disregard other selections

		for i=istart, iend do
			local irowcontrol = bars[i]
			sel[irowcontrol.dataId] = i
		end
	elseif ctrlkey and not shiftkey then	-- toggle additional sel if ctrlkey is pressed
		if sel[dataId] ~= nil then
			lastsel = nil
			sel[dataId] = nil
		else
			lastsel = id
			sel[dataId] = id
		end

	elseif shiftkey and ctrlkey and lastsel ~= nil then  -- additionally select everything between this and the previous sel if ctrlkey + shift key is pressed
		local istart = zo_min(lastsel, id)
		local iend = zo_max(lastsel, id)

		for i=istart, iend do
			local irowcontrol = bars[i]
			sel[irowcontrol.dataId] = i
		end

	elseif not shiftkey and not ctrlkey then -- normal LMB click
		if lastsel == id and sel[dataId] ~= nil then -- remove sel if this was pressed just before
			lastsel = nil
			sel = nil
		else
			lastsel = id
			sel = {[dataId] = id}
		end
	end

	lastSelections[selecttype][category] = lastsel
	selections[selecttype][category] = sel
	CombatMetrics_Report:Update(currentFight)
end

local function UpdateReport2()
	CombatMetrics_Report:Update()
end




local function GetCurrentData()
	local data = CMX.currentdata

	if data.units == nil then
		if #CMX.lastfights == 0 then return end
		data = CMX.lastfights[#CMX.lastfights]
	end

	return data
end

local function GetSingleTargetDamage(data)	-- Gets highest Single Target Damage and counts enemy units.

	local damage, groupDamage, unittime, name = 0, 0, 0, ""

	for unitId, unit in pairs(data.units) do

		local totalUnitDamage = unit.damageOutTotal

		if totalUnitDamage > 0 and unit.isFriendly == false then

			if totalUnitDamage > damage then

				name = unit.name
				damage = totalUnitDamage
				groupDamage = unit.groupDamageOut
				unittime = (unit.dpsend or 0) - (unit.dpsstart or 0)

			end
		end
	end

	unittime = unittime > 0 and unittime/1000 or data.dpstime
	groupDamage = zo_max(damage, groupDamage)

	return damage, groupDamage, name, unittime
end

local function GetBossTargetDamage(data) -- Gets Damage done to bosses and counts enemy boss units.

	if not data.bossfight then return 0, 0, 0, nil, 0 end

	local totalBossDamage, bossDamage, bossUnits = 0, 0, 0
	local totalBossGroupDamage = 0
	local bossName
	local starttime
	local endtime

	for unitId, unit in pairs(data.units) do

		local totalUnitDamage = unit.damageOutTotal
		local totalUnitGroupDamage = unit.groupDamageOut

		if (unit.bossId ~= nil and totalUnitDamage>0) then

			totalBossDamage = totalBossDamage + totalUnitDamage
			totalBossGroupDamage = totalBossGroupDamage + totalUnitGroupDamage
			bossUnits = bossUnits + 1

			starttime = zo_min(starttime or unit.dpsstart or 0, unit.dpsstart or 0)
			endtime = zo_max(endtime or unit.dpsend or 0, unit.dpsend or 0)

			if totalUnitDamage > bossDamage then

				bossName = unit.name
				bossDamage = totalUnitDamage

			end
		end
	end

	if bossUnits == 0 then return 0, 0, 0, nil, 0 end

	local bossTime = (endtime - starttime)/1000
	bossTime = bossTime > 0 and bossTime or data.dpstime

	return bossUnits, totalBossDamage, totalBossGroupDamage, bossName, bossTime
end

local function GetSelectionDamage(data, selection)	-- Gets highest Single Target Damage and counts enemy units.

	local units = 0
	local damage = 0
	local starttime
	local endtime
	local bossDamage = 0
	local bossName = ""

	local unitdata = data.units
	selection = selection or unitdata

	for unitId, _ in pairs(selection) do

		local unit = unitdata[unitId]
		local totalUnitDamage = unit.damageOutTotal

		if totalUnitDamage > 0 and unit.isFriendly == false then

			units = units + 1
			damage = damage + totalUnitDamage
			starttime = unit.dpsstart and zo_min(starttime or unit.dpsstart, unit.dpsstart) or starttime
			endtime = unit.dpsend and zo_max(endtime or unit.dpsend, unit.dpsend) or endtime

			if totalUnitDamage > bossDamage then

				bossName = unit.name
				bossDamage = totalUnitDamage

			end

		end
	end

	local damageTime = starttime and endtime and (endtime - starttime)/1000 or 0
	damageTime = damageTime > 0 and damageTime or data.dpstime

	return units, damage, bossName, damageTime
end

local function GetSelectionHeal(data, selection)	-- Gets highest Single Target Damage and counts enemy units.

	local units = 0
	local healing = 0
	local starttime
	local endtime

	local unitdata = data.units
	selection = selection or unitdata
	local calcdata = data.calculated.units

	if not calcdata then return end

	for unitId, _ in pairs(selection) do

		local unit = unitdata[unitId]
		local totalUnitHeal = calcdata[unitId].healingOutTotal

		if totalUnitHeal and unit.isFriendly == true then

			units = units + 1
			healing = healing + totalUnitHeal
			starttime = zo_min(starttime or unit.hpsstart or 0, unit.hpsstart or 0)
			endtime = zo_max(endtime or unit.hpsend or 0, unit.hpsend or 0)

		end
	end

	local healTime = (endtime - starttime)/1000
	healTime = healTime > 0 and healTime or data.dpstime

	return units, healing, healTime
end

local function GetUnitsByName(data, unitId)	-- Gets all units that share the name with the one provided by unitId

	local selectedUnits = {}

	local unitName = data.units[unitId].name

	for unitId, unit in pairs(data.units) do

		if unit.name == unitName then

			selectedUnits[unitId] = true

		end
	end

	return selectedUnits
end

function CMX.PostBuffUptime(fight, buffname, unitType)
	local data = fight and CMX.lastfights[fight]

	local category = db.FightReport.category or "damageOut"

	if not data then return end

	local timedata = ""

	if data ~= GetCurrentData() then

		local date = data.date

		local datestring = type(date) == "number" and GetDateStringFromTimestamp(date) or date
		timedata = string.format("[%s, %s] ", datestring, data.time)

	end

	local buffDataTable, units = GetBuffDataAndUnits(unitType) -- TODO provide the single unit if units is 1
	local buffData = buffDataTable.buffs[buffname]
	if buffData == nil then return end
	local totalUnitTime = buffDataTable.totalUnitTime

	if totalUnitTime then totalUnitTime = totalUnitTime / 1000 end

	local activetime = totalUnitTime or data.dpstime

	if category == "healingOut" or category == "healingIn" then activetime = totalUnitTime or data.hpstime end

	local uptime = buffData.uptime / 1000
	local groupUptime = buffData.groupUptime / 1000

	local relativeUptimeString = string.format("%.1f%%", uptime / activetime * 100)
	local uptimeString = string.format("%d:%02d", uptime/60, uptime%60)

	local output

	if groupUptime > uptime then

		local relativeGroupUptimeString = string.format("%.1f%%", groupUptime / activetime * 100)
		local groupUptimeString = string.format("%d:%02d", groupUptime/60, groupUptime%60)

		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTBUFF_FORMAT_GROUP), buffname, relativeUptimeString, uptimeString, units, relativeGroupUptimeString, groupUptimeString)

	else

		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTBUFF_FORMAT), buffname, relativeUptimeString, uptimeString, units)

	end

	-- Determine appropriate channel

	local channel = db.autoselectchatchannel == true and (IsUnitGrouped('player') and CHAT_CHANNEL_PARTY or CHAT_CHANNEL_SAY) or nil

	-- Log output to chat

	local outputtext = string.format("%s%s", timedata, output)
	StartChatInput(outputtext, channel)
end

function CMX.PosttoChat(mode, fight, UnitContextMenuUnitId)

	local data = fight and CMX.lastfights[fight] or GetCurrentData()

	if data == nil then return end

	local timedata = ""

	if data ~= GetCurrentData() then

		local date = data.date

		local datestring = type(date) == "number" and GetDateStringFromTimestamp(date) or date
		timedata = string.format("[%s, %s] ", datestring, data.time)

	end

	local output = ""

	local unitSelection = mode == CMX_POSTTOCHAT_MODE_SELECTION and selections.unit["damageOut"]
		or mode == CMX_POSTTOCHAT_MODE_SELECTED_UNIT and {[UnitContextMenuUnitId] = true}
		or mode == CMX_POSTTOCHAT_MODE_SELECTED_UNITNAME and GetUnitsByName(data, UnitContextMenuUnitId)

	local units, damage, name, dpstime = GetSelectionDamage(data, unitSelection)
	local bossUnits, bossDamage, _, bossName, bossTime = GetBossTargetDamage(data)
	local singleDamage, _, _, singleTime = GetSingleTargetDamage(data)

	dpstime = zo_roundToNearest(dpstime, 0.1)
	singleTime = zo_roundToNearest(singleTime, 0.1)

	name = zo_strformat(SI_UNIT_NAME, (not unitSelection) and bossName or name)

	local bossDamage = data.bossfight and bossDamage or singleDamage
	local bossTime = zo_roundToNearest(data.bossfight and bossTime or singleTime, 0.1)

	local totalDPSString = ZO_CommaDelimitNumber(zo_floor(data.DPSOut))
	local totalDamageString = ZO_CommaDelimitNumber(damage)

	if mode == CMX_POSTTOCHAT_MODE_HEALING then

		local hpstime = zo_roundToNearest(data.hpstime, 0.01)
		local timeString = string.format("%d:%04.1f", hpstime/60, hpstime%60)

		local totalHPSString = ZO_CommaDelimitNumber(data.HPSOut)
		local totalHealingString = ZO_CommaDelimitNumber(data.healingOutTotal)

		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTHPS_FORMAT), name, totalHPSString, totalHealingString, timeString)

	elseif mode == CMX_POSTTOCHAT_MODE_SELECTION_HEALING then

		local units, healing, healTime = GetSelectionHeal(data, selections.unit["healingOut"])

		healTime = zo_roundToNearest(healTime, 0.1)

		local timeString = string.format("%d:%04.1f", healTime/60, healTime%60)

		local totalHealingString = ZO_CommaDelimitNumber(healing)
		local totalHPSString = ZO_CommaDelimitNumber(zo_floor(healing / healTime))

		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTSELECTIONHPS_FORMAT), name, units, totalHPSString, totalHealingString, timeString)

	elseif units == 1 or mode == CMX_POSTTOCHAT_MODE_SINGLE then

		local damage = mode == CMX_POSTTOCHAT_MODE_SELECTED_UNIT and damage or singleDamage
		local damageTime = mode == CMX_POSTTOCHAT_MODE_SELECTED_UNIT and dpstime or singleTime

		local singleDPSString = ZO_CommaDelimitNumber(zo_floor(damage / damageTime))
		local singleDamageString = ZO_CommaDelimitNumber(damage)
		local timeString = string.format("%d:%04.1f", damageTime/60, damageTime%60)

		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTDPS_FORMAT), name, singleDPSString, singleDamageString, timeString)

	elseif bossUnits > 0 and mode == CMX_POSTTOCHAT_MODE_SMART then

		local bosses = bossUnits > 1 and string.format(" (+%d)", (bossUnits-1) )  or ""
		local bossTimeString = string.format("%d:%04.1f", bossTime/60, bossTime%60)

		local bossDPSString = ZO_CommaDelimitNumber(zo_floor(bossDamage / bossTime))
		local bossDamageString = ZO_CommaDelimitNumber(bossDamage)

		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTSMARTDPS_FORMAT), name, bosses, bossDPSString, bossDamageString, bossTimeString)

	elseif units > 1 and (mode == CMX_POSTTOCHAT_MODE_MULTI or mode == CMX_POSTTOCHAT_MODE_SMART) then

		local timeString = string.format("%d:%04.1f", dpstime/60, dpstime%60)

		local totalDPSString = ZO_CommaDelimitNumber(zo_floor(data.DPSOut))
		local totalDamageString = ZO_CommaDelimitNumber(damage)

		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTMULTIDPS_FORMAT), name, units-1, totalDPSString, totalDamageString, timeString)

	elseif mode == CMX_POSTTOCHAT_MODE_SINGLEANDMULTI then

		local bossString = bossUnits > 1 and string.format("%s (+%d)", GetString(SI_COMBAT_METRICS_BOSS_DPS), bossUnits-1) or bossUnits == 1 and GetString(SI_COMBAT_METRICS_BOSS_DPS) or GetString(SI_COMBAT_METRICS_DPS)
		local timeString = string.format("%d:%04.1f", dpstime/60, dpstime%60)
		local bossTimeString = string.format("%d:%04.1f", bossTime/60, bossTime%60)

		local bossDPSString = ZO_CommaDelimitNumber(zo_floor(bossDamage / bossTime))
		local bossDamageString = ZO_CommaDelimitNumber(bossDamage)

		local totalDPSString = ZO_CommaDelimitNumber(zo_floor(data.DPSOut))
		local totalDamageString = ZO_CommaDelimitNumber(damage)

		local stringA = zo_strformat(GetString(SI_COMBAT_METRICS_POSTALLDPS_FORMAT_A), name, units-1, totalDPSString, totalDamageString, timeString)
		local stringB = zo_strformat(GetString(SI_COMBAT_METRICS_POSTALLDPS_FORMAT_B), bossString, bossDPSString, bossDamageString, bossTimeString)

		output = string.format("%s, %s", stringA, stringB)

	elseif mode == CMX_POSTTOCHAT_MODE_SELECTION or mode == CMX_POSTTOCHAT_MODE_SELECTED_UNITNAME then

		if not unitSelection then return end

		local extraUnits = units > 1 and mode == CMX_POSTTOCHAT_MODE_SELECTED_UNITNAME and string.format(" (x%d)", units )
			or units > 1 and string.format(" (+%d)", (units-1) )
			or ""

		local DPSString = ZO_CommaDelimitNumber(zo_floor(damage / dpstime))
		local DamageString = ZO_CommaDelimitNumber(damage)
		local timeString = string.format("%d:%04.1f", dpstime/60, dpstime%60)

		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTSELECTIONDPS_FORMAT), name, extraUnits, DPSString, DamageString, timeString)

	end

	-- Determine appropriate channel

	local channel = db.autoselectchatchannel == false and "" or IsUnitGrouped('player') and "/p " or "/say "

	-- Log output to chat

	local outputtext = string.format("%s%s", timedata, output)

	CHAT_SYSTEM.textEntry:SetText( channel .. outputtext )
	CHAT_SYSTEM:Maximize()
	CHAT_SYSTEM.textEntry:Open()
	CHAT_SYSTEM.textEntry:FadeIn()
end

local function maxStat()

	local _, magicka = GetUnitPower("player", POWERTYPE_MAGICKA )
	local _, stamina = GetUnitPower("player", POWERTYPE_STAMINA )
	local _, health = GetUnitPower("player", POWERTYPE_HEALTH )

	local maxPower = "Magicka"

	if stamina > magicka then maxPower = "Stamina" end
	if health > magicka and health > stamina then maxPower = "Health" end

	return maxPower

end



function CMX.GetCMXData(dataType)	-- for external access to fightData

	local data = {}

    if dataType == "selectionData" then

		ZO_DeepTableCopy(selectionData, data)

    elseif dataType == "fightData" then

		ZO_DeepTableCopy(fightData, data)

    else

        data = nil

    end

	return data
end

local lastResize
function CMX.Resizing(control, resizing)
	if control:IsHidden() then return end
	if resizing then
		control:SetEdgeColor(1,1,1,1)
		control:SetCenterColor(1,1,1,.2)
		control:SetDrawTier(2)
	else
		control:SetEdgeColor(1,1,1,0)
		control:SetCenterColor(1,1,1,0)
		control:SetDrawTier(0)

		if lastResize == nil then return end

		local scale, newpos = unpack(lastResize)
		local parent = control:GetParent()

		db[parent:GetName()] = newpos

		parent:ClearAnchors()
		parent:SetAnchor(CENTER, nil , TOPLEFT, newpos.x, newpos.y)
		parent:Resize(scale)
	end
end

function CMX.NewSize(control, newLeft, newTop, newRight, newBottom, oldLeft, oldTop, oldRight, oldBottom)

	if control.sizes == nil or control:IsHidden() then return end

	local baseWidth, baseHeight = unpack(control.sizes)

	local newHeight = newBottom - newTop
	local newWidth = newRight - newLeft

	local oldHeight = oldBottom - oldTop
	local oldWidth = oldRight - oldLeft

	local heightChange = (newHeight-oldHeight)/oldHeight
	local widthChange = (newWidth-oldWidth)/oldWidth

	local newscale

	if zo_abs(heightChange) > zo_abs(widthChange) then

		newscale = newHeight / baseHeight
		newWidth = baseWidth * newscale

		control:SetWidth(newWidth)

	else

		newscale = newWidth / baseWidth
		newHeight = baseHeight * newscale

		control:SetHeight(newHeight)

	end

	newscale = zo_roundToNearest(newscale, 0.01)

	local centerX, centerY = control:GetCenter()
	local newpos = { x = centerX, y = centerY}

	lastResize = {newscale, newpos}
end


function CMX.InitializeUI()
	initFightReport()
end