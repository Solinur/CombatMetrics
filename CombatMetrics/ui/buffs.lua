local CMX = CombatMetrics
local CMXint = CMX.internal
local ui = CMXint.ui
local util = CMXint.util
local logger
local uncollapsedBuffs = {}
local BuffPanel

local dx = CMXint.dx
local adjustRowSize = util.adjustRowSize
local GetFormattedAbilityIcon = util.GetFormattedAbilityIcon
local GetFormattedAbilityName = util.GetFormattedAbilityName

local NameToAbilityIDs = {}

local BUFF_LIST_ROWHEIGHT = 20
local BUFF_LIST_ROWHEIGHT_HALF = 10

local BUFF_NAME_FORMAT_ID = "(<<2>>) <<1>>"
local BUFF_NAME_FORMAT_DEFAULT = "<<1>>"
local BUFF_NAME_FORMAT_STACKS = "<<2>>x <<1>>"

local BUFF_VALUE_FORMAT_SINGLE = "%d"
local BUFF_VALUE_FORMAT_GROUP = "%d/%d"


local SigilAbilities = { -- Abilities to display a warning icon in the buff list to indicate it cannot be considered a "clean" parse
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

local BUFF_LABEL_COLOR_DEFAULT = {1, 1, 1, 1}
local BUFF_LABEL_COLOR_FAV = {1, .8, .3, 1}

local BUFF_BAR_COLORS = {
	[BUFF_EFFECT_TYPE_BUFF] = {0, 0.6, 0, 0.6},
	[BUFF_EFFECT_TYPE_DEBUFF] = {0, 0.6, 0, 0.6},
	[BUFF_EFFECT_TYPE_NOT_AN_EFFECT] = {0, 0.6, 0, 0.6},
}

local BUFF_BAR_GROUP_COLORS = {
	[BUFF_EFFECT_TYPE_BUFF] = {0, 0.6, 0, 0.3},
	[BUFF_EFFECT_TYPE_DEBUFF] = {0.75, 0, 0.6, 0.3},
	[BUFF_EFFECT_TYPE_NOT_AN_EFFECT] = {0.6, 0.6, 0.6, 0.3},
}

BUfF_LIST_SORT_KEYS =
{
    ["name"] = { tiebreaker = "abilityId"},
    ["count"] = { tiebreaker = "groupCount", isNumeric = true  },
    ["uptime"]  = { tiebreaker = "groupUptime", isNumeric = true  },

}

do	-- Handling Buffs Context Menu
	local favs
	local abilityId
	local unitType
	local currentFight

	local function addFavouriteBuff()
		if abilityId then favs[abilityId] = true end
		CombatMetricsReport:Update()
	end

	local function removeFavouriteBuff()
		if abilityId then favs[abilityId] = nil end
		CombatMetricsReport:Update()
	end

	local function postBuffUptime()
		if abilityId then util.PostBuffUptime(currentFight, abilityId) end
	end

	local function postSelectionBuffUptime()
		if abilityId then util.PostBuffUptime(currentFight, abilityId, unitType) end
	end

	local function toggleCollapseBuff()
		if abilityId then
			if uncollapsedBuffs[abilityId] == true then
				uncollapsedBuffs[abilityId] = nil
			else
				uncollapsedBuffs[abilityId] = true
			end
		end

		CombatMetricsReport:GetNamedChild("_BuffPanel"):GetNamedChild("BuffList"):Update()
	end

	function CMX.BuffContextMenu( bufflistitem, upInside )
		if not upInside then return end

		abilityId = bufflistitem.dataId
		local settings = CMXint.settings.fightReport
		favs = settings.buffs.favourites
		currentFight = CMXint.currentFight
		local func, text

		if favs[abilityId] == nil then
			func = addFavouriteBuff
			text = GetString(SI_COMBAT_METRICS_FAVOURITE_ADD)
		else
			func = removeFavouriteBuff
			text = GetString(SI_COMBAT_METRICS_FAVOURITE_REMOVE)
		end

		ClearMenu()
		AddCustomMenuItem(text, func)
		AddCustomMenuItem(GetString(SI_COMBAT_METRICS_POSTBUFF), postBuffUptime)

		local category = settings.category

		if (category == "damageOut" or category == "damageIn") and settings.rightpanel == "buffsout" then
			unitType = "boss"
			AddCustomMenuItem(GetString(SI_COMBAT_METRICS_POSTBUFF_BOSS), postSelectionBuffUptime)
		elseif (category == "healingOut" or category == "healingIn") and settings.rightpanel == "buffsout" then
			unitType = "group"
			AddCustomMenuItem(GetString(SI_COMBAT_METRICS_POSTBUFF_GROUP), postSelectionBuffUptime)
		end

		if bufflistitem.hasDetails == true then
			local stringId = uncollapsedBuffs[abilityId] and SI_COMBAT_METRICS_COLLAPSE or SI_COMBAT_METRICS_UNCOLLAPSE
			AddCustomMenuItem(GetString(stringId), toggleCollapseBuff)
		end

		ShowMenu(bufflistitem)
	end
end

function CMX.CollapseButton( button, upInside )
	local buffname = button:GetParent().dataId

	if buffname then
		if uncollapsedBuffs[buffname] == true then
			uncollapsedBuffs[buffname] = nil
		else
			uncollapsedBuffs[buffname] = true
		end
	end

	CombatMetricsReport:GetNamedChild("_BuffPanel"):GetNamedChild("BuffList"):Update()
end

local function GetBuffData()
	local buffData
	-- TODO: redo
	-- local rightpanel = db.fightReport.rightpanel

	-- if rightpanel == "buffsout" then
	-- 	buffData = selectionData
	-- elseif rightpanel == "buffs" then
	-- 	buffData = fightData.calculated
	-- end

	return buffData
end
util.GetBuffData = GetBuffData


function util.buffSortFunction(data, a, b)
	local ishigher = false
	local favs = CMXint.settings.fightReport.buffs.favourites

	local isFavA = favs[a]
	local isFavB = favs[b]

	if isFavA and not isFavB then
		ishigher = true
	elseif isFavA == isFavB then
		ishigher = data[a]["groupUptime"] > data[b]["groupUptime"]
	end

	return ishigher
end

local function InitBuffsList(panel)
	local dataList = panel.dataList
	local listControl = dataList.list
	dataList.groupList = {}
	dataList.masterList = {}

	function dataList:RecoverRow(rowControl)
		local expandButton = panel:AcquireSharedControl(CT_TEXTURE)
		expandButton:ApplyPosition(rowControl, 0, BUFF_LIST_ROWHEIGHT_HALF/2, BUFF_LIST_ROWHEIGHT_HALF, BUFF_LIST_ROWHEIGHT_HALF)

		local icon = panel:AcquireSharedControl(CT_TEXTURE)
		icon:ApplyPosition(rowControl, 12, 0, BUFF_LIST_ROWHEIGHT, BUFF_LIST_ROWHEIGHT)

		local label = panel:AcquireSharedControl(CT_LABEL)
		label:ApplyPosition(rowControl, 36, 0, 176)

		local bar = panel:AcquireSharedControl(CT_TEXTURE)
		bar:ApplyPosition(rowControl, 36, 0, 176, BUFF_LIST_ROWHEIGHT)

		local bar_group = panel:AcquireSharedControl(CT_TEXTURE)
		bar_group:ApplyPosition(rowControl, 36, 0, 176, BUFF_LIST_ROWHEIGHT)

		local count = panel:AcquireSharedControl(CT_LABEL)
		count:ApplyPosition(rowControl, 216, 0, 58)

		local uptime = panel:AcquireSharedControl(CT_LABEL)
		uptime:ApplyPosition(rowControl, 276, 0, 58)

		rowControl.controls = {expandButton, icon, label, bar, bar_group, count, uptime}
		rowControl.recovered = true
		rowControl.indent = 0
	end

	function dataList:UpdateRow(rowControl, data, scrollList)
		if rowControl.recovered ~= true then self:RecoverRow(rowControl) end
		local expandButton, icon, label, bar, bar_group, count, uptime = unpack(rowControl.controls)

		local labelFormat = panel.ShowIds() and BUFF_NAME_FORMAT_ID or BUFF_NAME_FORMAT_DEFAULT
		local labelText = ZO_CachedStrFormat(labelFormat, data.labelText, data.abilityId)
		
		local deltaIndent = (data.indent - rowControl.indent) * BUFF_LIST_ROWHEIGHT_HALF
		rowControl.indent = data.indent
		
		local textcolor = favs[abilityId] and BUFF_LABEL_COLOR_FAV or BUFF_LABEL_COLOR_DEFAULT

		expandButton:SetHidden(not data.hasDetails)
		icon:SetTexture(GetFormattedAbilityIcon(data.abilityId))
		
		label:SetText(labelText)
		label:ApplyIndent(deltaIndent)
		label:SetColor(unpack(textcolor))

		local maxwidth = label:GetWidth()
		
		bar:SetCenterColor(unpack(BUFF_BAR_COLORS[data.effectType]))
		bar:ApplyIndent(deltaIndent)
		bar:SetWidth(maxwidth * data.uptimeRatio)
		
		bar_group:SetCenterColor(unpack(BUFF_BAR_GROUP_COLORS[data.effectType]))
		bar_group:ApplyIndent(deltaIndent)
		bar_group:SetWidth(maxwidth * data.groupUptimeRatio)

		local hideGroupValues = data.count == data.groupCount and data.uptime == data.groupUptime
		local valueFormat = hideGroupValues and BUFF_VALUE_FORMAT_SINGLE or BUFF_VALUE_FORMAT_GROUP

		count:SetText(string.format(valueFormat, data.count, data.groupCount))
		uptime:SetText(string.format(valueFormat, data.uptimeRatio * 100, data.groupUptimeRatio * 100))
	end

	function dataList:UpdateAbilityNames(effectData)
		for abilityId, _ in pairs(effectData) do
			local name = GetFormattedAbilityName(abilityId)
			local nameId = NameToAbilityIDs[name]

			if nameId == nil or abilityId < nameId then
				NameToAbilityIDs[name] = abilityId
			end
		end
	end

	function dataList:AddDataEntry(abilityId, data, totalUnitTime)
		if data.groupUptime <= 0 then return end

		local hasStacks = effectData.stacks and (effectData.iconId == 126597 or effectData.maxStacks > 1) -- TODO: implement stack info !
		local selected = false -- selectedbuffs ~= nil and (selectedbuffs[buffName] ~= nil) or false -- TODO: Selections

		local name = GetFormattedAbilityName(abilityId)
		local labelText = name

		local mainAbilityId = NameToAbilityIDs[name]
		local hasOtherId = mainAbilityId ~= abilityId
		
		if hasStacks then
			labelText = ZO_CachedStrFormat(BUFF_NAME_FORMAT_STACKS, name, data.maxStacks)
			if hasOtherId then logger:Warning("Ability %s (%d) has stacks as well as another Id: %d", name, abilityId, mainAbilityId) end
		end

		local rowData = {
			indent = 0,
			selected = selected,
			hasDetails = hasStacks,

			abilityId = abilityId,
			effectType = data.effectType,
			labelText = labelText,

			uptime = data.uptime / totalUnitTime,
			groupUptime = data.groupUptime / totalUnitTime,
			count = data.count,
			groupCount = data.groupCount,
		}

		if hasOtherId and not hasStacks then
			local groupData = self.groupList[mainAbilityId]
			if groupData == nil then
				groupData = {}
				self.groupList[mainAbilityId] = groupData
			end
			rowData.mainAbilityId = mainAbilityId
			table.insert(groupData, ZO_ScrollList_CreateDataEntry(1, rowData))
		else
			table.insert(self.masterList, ZO_ScrollList_CreateDataEntry(1, rowData))
		end

		if hasStacks then
			local keys = {}
			local stackDataTable = data.stacks

			--  TODO: Check if still n neccessary
			for stacks, data in pairs(stackDataTable) do
				if type(stacks) == "number" then keys[#keys+1] = stacks end
			end

			table.sort(keys)

			if effectData.maxStacks > #keys then
				logger:Warning("Missing stacks data for %s (%d). Expected %d entries but only got %d.", name, abilityId, effectData.maxStacks, #keys)
			end

			local groupData = {}
			self.groupList[abilityId] = groupData

			for i = 1, #keys do
				local stacks = keys[i]
				local stackData = stackDataTable[stacks]

				local rowData = {
					indent = 1,
					selected = false,
					hasDetails = false,

					abilityId = abilityId,
					effectType = data.effectType,
					labelText = ZO_CachedStrFormat(BUFF_NAME_FORMAT_STACKS, name, stacks),

					uptime = stackData.uptime / totalUnitTime,
					groupUptime = stackData.groupUptime / totalUnitTime,
					count = stackData.count,
					groupCount = stackData.groupCount,
					stacks = stacks
				}

				table.insert(groupData, ZO_ScrollList_CreateDataEntry(1, rowData))
			end
		end
	end

	function dataList:BuildMasterList(effectData)
		self:UpdateAbilityNames(effectData)

		ZO_ClearTable(self.masterList)
		ZO_ClearTable(self.groupList)

		local hasSigil = false

		for abilityId, data in pairs(effectData) do
			self:AddDataEntry(abilityId, data, totalUnitTime)
			if isSigilAbility(buff.instances) then hasSigil = true end
		end

		sigilIcon:SetHidden(not hasSigil)
	end

	function dataList:ProcessGroupData(entryData, groupData)
		local isStackData = groupData[1].stacks ~= nil

		if isStackData then
			local sumUptime = 0
			local sumGroupUptime = 0
			local maxStacks = #groupData
			
			for i, groupEntryData in groupData do
				sumUptime = sumUptime + groupEntryData.uptime
				sumGroupUptime = sumGroupUptime + groupEntryData.groupUptime
			end

			entryData.uptime = sumUptime / maxStacks
			entryData.groupUptime = sumGroupUptime / maxStacks

			-- TODO: Check if more elaborate analysis needed (parallel buffs ?)
		end
		
		-- multiple Id data
		if isStackData then
			for i, groupEntryData in groupData do
				if groupEntryData.uptime > entryData.uptime then
					entryData.uptime = groupEntryData.uptime
					entryData.groupUptime = groupEntryData.uptime
					entryData.count = groupEntryData.uptime
					entryData.groupCount = groupEntryData.uptime
				end
			end
		end
	end

	function dataList:FilterScrollList()    
		local scrollData = ZO_ScrollList_GetDataList(self.list)
		ZO_ScrollList_Clear(self.list)

		for i, data in ipairs(self.masterList) do
			scrollData[#scrollData + 1] = data
		end
	end

	function dataList:SortScrollList()
		local scrollData = ZO_ScrollList_GetDataList(self.list)
		table.sort(scrollData, self.sortFunction)

		local groupList = self.groupList

		for i = #scrollData, 1, -1 do
			local abilityId = masterList.abilityId
			local groupData = groupList[abilityId]

			if groupData then
				dataList:ProcessGroupData(scrollData[i], groupData)
			end

			if uncollapsedBuffs[abilityId] then
				table.sort(groupData, self.sortFunction)
				for j, groupEntry in ipairs(groupData) do
					scrollData[i+j] = groupEntry
				end 
			end
		end
	end

	return dataList
end


function CMXint.InitializeBuffsPanel(control)
	BuffPanel = CMXint.PanelObject:New(control, "buffs")
	BuffPanel:CreateSortFilterList("CombatMetrics_BuffsPanelRowTemplate", BUFF_LIST_ROWHEIGHT, InitBuffsList)

	BuffPanel.selections = {}
	BuffPanel.favs = CMXint.settings.fightReport.buffs.favourites

	function BuffPanel:Update(fightData)
		if true then return end

		logger:Debug("Updating Buff Panel")

		self:ResetBars()
		local sigilIcon = GetControl(control, "HeaderIconTexture")
		sigilIcon:SetHidden(true)

		if fightData == nil then return end
		local buffData = GetBuffData()
		if buffData == nil then return end
		
		local maxtime = zo_max(fightData.activetime or 0, fightData.dpstime or 0, fightData.hpstime or 0)
		local totalUnitTime = buffData.totalUnitTime or maxtime * 1000

		-- TODO: Get Selection Data

		-- self.list:BuildMasterList(effectData, totalUnitTime)
	end
end

local isFileInitialized = false
function CMXint.InitializeBuffs()
	if isFileInitialized == true then return false end
	logger = util.initSublogger("BuffPanel")

    isFileInitialized = true
	return true
end