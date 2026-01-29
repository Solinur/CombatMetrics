---@class CMX
local CMX = CombatMetrics
---@class CMXint
local CMXint = CMX.internal
---@class CMXutil
local util = CMXint.util
---@type Logger
local logger
---@class CMXui
local ui = CMXint.ui

local uncollapsedBuffs = {}
local BuffPanel

local GetFormattedAbilityIcon = util.GetFormattedAbilityIcon
local GetFormattedAbilityName = util.GetFormattedAbilityName

local NameToAbilityIDs = {}

local BUFF_NAME_FORMAT_ID = "(<<2>>) <<1>>"
local BUFF_NAME_FORMAT_DEFAULT = "<<1>>"
local BUFF_NAME_FORMAT_STACKS = "<<2>>x <<1>>"

local BUFF_VALUE_FORMAT_SINGLE = "%d"
local BUFF_VALUE_FORMAT_GROUP = "%d/%d"

local BUFF_CATEGORY_PLAYER = "Player"
local BUFF_CATEGORY_GROUP = "Group"
local BUFF_CATEGORY_ENEMY = "Enemy"

local SigilAbilities =
	{ -- Abilities to display a warning icon in the buff list to indicate it cannot be considered a "clean" parse
		[236960] = true, -- Sigil of Power
		[236968] = true, -- Sigil of Defense
		[236994] = true, -- Sigil of Ultimate
		[237014] = true, -- Sigil of Speed
	}

local BUFF_LABEL_COLOR_DEFAULT = { 1, 1, 1, 1 }
local BUFF_LABEL_COLOR_FAV = { 1, 0.8, 0.3, 1 }

local BUFF_BAR_COLORS = {
	[BUFF_EFFECT_TYPE_BUFF] = { 0, 0.6, 0, 0.6 },
	[BUFF_EFFECT_TYPE_DEBUFF] = { 0.75, 0, 0.6, 0.6 },
	[BUFF_EFFECT_TYPE_NOT_AN_EFFECT] = { 0.6, 0.6, 0.6, 0.6 },
}

local BUFF_BAR_GROUP_COLORS = {
	[BUFF_EFFECT_TYPE_BUFF] = { 0, 0.6, 0, 0.3 },
	[BUFF_EFFECT_TYPE_DEBUFF] = { 0.75, 0, 0.6, 0.3 },
	[BUFF_EFFECT_TYPE_NOT_AN_EFFECT] = { 0.6, 0.6, 0.6, 0.3 },
}

BUfF_LIST_SORT_KEYS = {
	["name"] = { tiebreaker = "abilityId" },
	["count"] = { tiebreaker = "groupCount", isNumeric = true },
	["uptime"] = { tiebreaker = "groupUptime", isNumeric = true },
}

do -- Handling Buffs Context Menu
	local favs
	local abilityId
	local unitType
	local currentFight

	local function addFavouriteBuff()
		if abilityId then
			favs[abilityId] = true
		end
		CombatMetricsReport:Update()
	end

	local function removeFavouriteBuff()
		if abilityId then
			favs[abilityId] = nil
		end
		CombatMetricsReport:Update()
	end

	local function postBuffUptime()
		if abilityId then
			util.PostBuffUptime(currentFight, abilityId)
		end
	end

	local function postSelectionBuffUptime()
		if abilityId then
			util.PostBuffUptime(currentFight, abilityId, unitType)
		end
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

	function CMX.BuffContextMenu(bufflistitem, upInside)
		if not upInside then
			return
		end

		abilityId = bufflistitem.dataId
		local settings = CMXint.settings.fightReport
		favs = settings.buffs.favourites
		currentFight = CMXint.FightData:GetCurrentFight()
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

function CMX.CollapseButton(button, upInside)
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

local function CombineEffects(source, dest)
	assert(
		dest.name == source.name,
		debug.traceback(string.format("Name mismatch when combining buff data: %s ~= %s.", dest.name, source.name))
	)
	assert(
		dest.iconId == source.iconId,
		debug.traceback(string.format("ID mismatch when combining buff data: %d ~= %d.", dest.iconId, source.iconId))
	)
	dest.uptime = dest.uptime + source.uptime
	dest.count = dest.count + source.count
	dest.groupUptime = dest.groupUptime + source.groupUptime
	dest.groupCount = dest.groupCount + source.groupCount
	dest.effectType = dest.effectType + source.effectType
	dest.maxStacks = dest.maxStacks + source.maxStacks
	local destStacks = dest.stacks
	for stacks, stackData in pairs(source.stacks) do
		if destStacks[stacks] == nil then
			destStacks[stacks] = ZO_ShallowTableCopy(stackData)
		else
			local destData = destStacks[stacks]
			destData.uptime = destData.uptime + stackData.uptime
			destData.count = destData.count + stackData.count
			destData.groupUptime = destData.groupUptime + stackData.groupUptime
			destData.groupCount = destData.groupCount + stackData.groupCount
		end
	end
end

local effectData = {}
local unitIds = {}
local function GetBuffData(fightData, category)
	local totalUnitTime = 0

	CMX_EFFECT_DATA = { fightData, category, effectData, unitIds }
	ZO_ClearTable(unitIds)
	ZO_ClearTable(effectData)

	if fightData == nil then
		return effectData, totalUnitTime
	end

	if category == BUFF_CATEGORY_PLAYER then
		unitIds[#unitIds + 1] = fightData.unitIds.player
	elseif category == BUFF_CATEGORY_GROUP then
		local group = fightData.unitIds.group
		if group and #group > 0 then
			ZO_ShallowTableCopy(fightData.unitIds, unitIds)
		else
			unitIds[#unitIds + 1] = fightData.unitIds.player
		end
	elseif category == BUFF_CATEGORY_ENEMY then
		ZO_ShallowTableCopy(util:GetEnemyUnits(fightData.units), unitIds)
	end

	for i, unitId in ipairs(unitIds) do
		-- TODO: replace unit time with info stored in unit table
		local startTime = math.huge
		local endTime = 0

		local unitData = fightData.damageDone[unitId]
		if unitData then
			endTime = zo_max(unitData.endTime, endTime)
			startTime = zo_min(unitData.startTime, startTime)
		end

		local unitData2 = fightData.damageReceived[unitId]
		if unitData2 then
			endTime = zo_max(unitData2.endTime, endTime)
			startTime = zo_min(unitData2.startTime, startTime)
		end

		if endTime > startTime then
			totalUnitTime = totalUnitTime + (endTime - startTime)

			local unitEffectData = fightData.effects[unitId]
			for abilityId, data in pairs(unitEffectData) do
				if effectData[abilityId] == nil then
					effectData[abilityId] = ZO_ShallowTableCopy(data)
				else
					CombineEffects(data, effectData[abilityId])
				end
			end
		end
	end
	return effectData, totalUnitTime
end
util.GetBuffData = GetBuffData

local buffCategoryTextures = {
	[BUFF_CATEGORY_ENEMY] = "esoui/art/mainmenu/menubar_skills",
	[BUFF_CATEGORY_GROUP] = "esoui/art/mainmenu/menubar_group",
	[BUFF_CATEGORY_PLAYER] = "esoui/art/mainmenu/menubar_character",
}

function CMXint.InitializeBuffCategoryButton(control, buffCategory)
	local baseTexture = buffCategoryTextures[buffCategory]

	control:SetNormalTexture(string.format("%s_up.dds", baseTexture))
	control:SetPressedTexture(string.format("%s_down.dds", baseTexture))
	control:SetMouseOverTexture(string.format("%s_over.dds", baseTexture))
	control:SetDisabledTexture(string.format("%s_disabled.dds", baseTexture))

	control.buffCategory = buffCategory
end

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

---@param panel BuffPanel
---@return SortFilterList
local function InitBuffsList(panel)
	---@class BuffDataList: SortFilterList
	local dataList = ui.SortFilterList:New(panel.control, "CombatMetrics_BuffsPanelRowTemplate")
	panel.dataList = dataList
	dataList.panel = panel
	dataList.groupList = {}
	dataList.masterList = {}

	local function ToggleBuffDetails(self, mouseButton, upInside, shift, ctrl, alt, command)
		local rowControl = self:GetParent()
		local abilityId = rowControl.dataEntry.data.abilityId

		if abilityId then
			self:Toggle()

			if self.state then
				uncollapsedBuffs[abilityId] = true
			else
				uncollapsedBuffs[abilityId] = nil
			end
		end

		dataList:RefreshFilters()
	end

	local function CreateExpandButton(pool, objectKey)
		---@class ExpandButton: ButtonControl
		local newControl = ZO_ObjectPool_CreateControl("CombatMetrics_BuffsPanelExpandButton", pool, panel.control)

		---@diagnostic disable-next-line: missing-parameter
		newControl:SetHandler("OnMouseDown", ToggleBuffDetails)
		newControl.key = objectKey

		newControl.SetExpandState = ZO_ToggleButton_SetState
		newControl.Toggle = ZO_ToggleButton_Toggle
		return newControl
	end

	local expandButtonPool = ZO_ObjectPool:New(CreateExpandButton, ZO_ObjectPool_DefaultResetControl)

	---@class RowControl: Control
	---@field dataEntry table
	---@field controls table
	---@field indent number
	---@field expandButton ExpandButton
	---@field recovered boolean

	---@param rowControl RowControl
	function dataList:RecoverRow(rowControl)
		local panel = self.panel
		local rowHeight = self:GetHeight()
		local rowHeightHalf = rowHeight / 2

		-- local expandButton = panel:AcquireSharedControl(CT_TEXTURE)
		-- expandButton:ApplyPosition(rowControl, 2, rowHeightHalf/2, rowHeightHalf, rowHeightHalf)
		-- expandButton:SetTexture("esoui/art/buttons/dropbox_arrow_normal.dds")

		local icon = panel:AcquireSharedControl(CT_TEXTURE)
		icon:ApplyPosition(rowControl, 14, 0, rowHeight, rowHeight)

		local label = panel:AcquireSharedControl(CT_LABEL)
		label:ApplyPosition(rowControl, 40, 0, 170)
		label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

		local bar = panel:AcquireSharedControl(CT_TEXTURE)
		bar:ApplyPosition(rowControl, 38, 0, 174, rowHeight)
		bar:SetTexture("esoui/art/unitframes/progressbar_raidhealth.dds")

		local bar_group = panel:AcquireSharedControl(CT_TEXTURE)
		bar_group:ApplyPosition(rowControl, 38, 0, 174, rowHeight)
		bar_group:SetTexture("esoui/art/unitframes/progressbar_raidhealth.dds")

		---@type LabelControl|SharedControl
		local count = panel:AcquireSharedControl(CT_LABEL)
		count:ApplyPosition(rowControl, 216, 0, 58)
		count:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

		local uptime = panel:AcquireSharedControl(CT_LABEL)
		uptime:ApplyPosition(rowControl, 276, 0, 58)
		uptime:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

		rowControl.controls = { icon, label, bar, bar_group, count, uptime }
		rowControl.recovered = true
		rowControl.indent = 0
	end

	---@param rowControl RowControl
	---@param data table
	---@param scrollList object
	function dataList:UpdateRow(rowControl, data, scrollList)
		local panel = self.panel

		if rowControl.recovered ~= true then
			self:RecoverRow(rowControl)
		end
		local icon, label, bar, bar_group, count, uptime = unpack(rowControl.controls)

		local labelFormat = panel:ShowIds() and data.abilityId and BUFF_NAME_FORMAT_ID or BUFF_NAME_FORMAT_DEFAULT
		local labelText = ZO_CachedStrFormat(labelFormat, data.labelText, data.abilityId)

		local rowHeight = icon:GetHeight()
		local deltaIndent = (data.indent - rowControl.indent) * rowHeight / 2
		rowControl.indent = data.indent

		local textcolor = panel.favs[data.abilityId] and BUFF_LABEL_COLOR_FAV or BUFF_LABEL_COLOR_DEFAULT
		local font = ui.GetFont(ui.fontSize, false)

		local expandButton = rowControl.expandButton

		if data.hasDetails then
			if expandButton == nil then
				local scale = self.panel.settings.scale
				expandButton = expandButtonPool:AcquireObject()
				expandButton:SetHidden(false)
				expandButton:SetParent(rowControl)
				expandButton:SetAnchor(TOPLEFT, rowControl, TOPLEFT, -2 * scale, scale)
				expandButton:SetDimensions(rowHeight, rowHeight)
				rowControl.expandButton = expandButton
			end

			expandButton:SetExpandState(uncollapsedBuffs[data.abilityId] == true)
		else
			if expandButton then
				expandButton:ClearAnchors()
				expandButtonPool:ReleaseObject(expandButton.key)
				rowControl.expandButton = nil
			end
		end

		icon:SetTexture(GetFormattedAbilityIcon(data.abilityId))

		label:SetText(labelText)
		label:ApplyIndent(deltaIndent)
		label:SetColor(unpack(textcolor))
		label:SetFont(font)

		local maxwidth = label:GetWidth()

		bar:SetColor(unpack(BUFF_BAR_COLORS[data.effectType]))
		bar:ApplyIndent(deltaIndent)
		bar:SetWidth(maxwidth * data.uptime)

		bar_group:SetColor(unpack(BUFF_BAR_GROUP_COLORS[data.effectType]))
		bar_group:ApplyIndent(deltaIndent)
		bar_group:SetWidth(maxwidth * data.groupUptime)

		local hideGroupValues = data.count == data.groupCount and data.uptime == data.groupUptime
		local valueFormat = hideGroupValues and BUFF_VALUE_FORMAT_SINGLE or BUFF_VALUE_FORMAT_GROUP

		count:SetText(string.format(valueFormat, data.count, data.groupCount))
		count:SetFont(font)
		uptime:SetText(string.format(valueFormat, data.uptime * 100, data.groupUptime * 100))
		uptime:SetFont(font)
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
		if data.groupUptime <= 0 then
			return
		end

		local hasStacks = data.stacks and (data.iconId == 126597 or data.maxStacks > 1)
		local selected = false -- selectedbuffs ~= nil and (selectedbuffs[buffName] ~= nil) or false -- TODO: Selections

		local name = GetFormattedAbilityName(abilityId)
		local labelText = name

		local mainAbilityId = NameToAbilityIDs[name]
		local hasOtherId = mainAbilityId ~= abilityId

		if hasStacks then
			labelText = ZO_CachedStrFormat(BUFF_NAME_FORMAT_STACKS, name, data.maxStacks)
			if hasOtherId then
				logger:Warn("Ability %s (%d) has stacks as well as another Id: %d", name, abilityId, mainAbilityId)
			end
		end

		local rowData = {
			indent = 0,
			selected = selected,
			hasDetails = hasStacks,

			abilityId = abilityId,
			effectType = data.effectType,
			labelText = labelText,
			name = name,

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
				if type(stacks) == "number" then
					keys[#keys + 1] = stacks
				end
			end

			table.sort(keys)

			if data.maxStacks > #keys then
				logger:Warn(
					"Missing stacks data for %s (%d). Expected %d entries but only got %d.",
					name,
					abilityId,
					data.maxStacks,
					#keys
				)
			end

			local groupData = {}
			self.groupList[abilityId] = groupData

			for i = 1, #keys do
				local stacks = keys[i]
				local stackData = stackDataTable[stacks]
				local labeltext = ZO_CachedStrFormat(BUFF_NAME_FORMAT_STACKS, name, stacks)

				local rowData = {
					indent = 1,
					selected = false,
					hasDetails = false,

					effectType = data.effectType,
					labelText = labeltext,
					name = labeltext,
					abilityId = abilityId,

					uptime = stackData.uptime / totalUnitTime,
					groupUptime = stackData.groupUptime / totalUnitTime,
					count = stackData.count,
					groupCount = stackData.groupCount,
					stacks = stacks,
				}

				table.insert(groupData, ZO_ScrollList_CreateDataEntry(1, rowData))
			end
		end
	end

	function dataList:BuildMasterList()
		local fightData = self.panel:GetCurrentFightData()
		local category = self.panel.category
		local effectData, totalUnitTime = GetBuffData(fightData, category)

		self:UpdateAbilityNames(effectData)

		ZO_ClearTable(self.masterList)
		ZO_ClearTable(self.groupList)

		local hasSigil = false

		for abilityId, data in pairs(effectData) do
			self:AddDataEntry(abilityId, data, totalUnitTime)
			if SigilAbilities[abilityId] then
				hasSigil = true
			end
		end

		local sigilIcon = self.control:GetNamedChild("Headers"):GetNamedChild("Icon")
		sigilIcon:SetHidden(not hasSigil)
	end

	function dataList:ProcessGroupData(entryData, groupData)
		if groupData[1].data.stacks ~= nil then
			local sumUptime = 0
			local sumGroupUptime = 0
			local maxStacks = 0

			for i, groupEntry in ipairs(groupData) do
				local groupEntryData = groupEntry.data
				sumUptime = sumUptime + groupEntryData.uptime
				sumGroupUptime = sumGroupUptime + groupEntryData.groupUptime
				maxStacks = zo_max(maxStacks, groupEntryData.stacks)
			end

			entryData.uptime = sumUptime / maxStacks
			entryData.groupUptime = sumGroupUptime / maxStacks

			-- TODO: Check if more elaborate analysis needed (parallel buffs ?)
		elseif groupData[1].mainAbilityId then
			for i, groupEntry in groupData do
				local groupEntryData = groupEntry.data
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
		-- TODO: Add searchbar filter.
	end

	function dataList:SortScrollList()
		local scrollData = ZO_ScrollList_GetDataList(self.list)
		ZO_ScrollList_Clear(self.list)

		for i, data in ipairs(self.masterList) do
			scrollData[#scrollData + 1] = data
		end

		table.sort(scrollData, self.sortFunction)

		local groupList = self.groupList

		for i = #scrollData, 1, -1 do
			local dataEntry = scrollData[i].data
			local abilityId = dataEntry.abilityId
			local groupData = groupList[abilityId]

			if groupData then
				dataList:ProcessGroupData(dataEntry, groupData)

				if uncollapsedBuffs[abilityId] then
					table.sort(groupData, self.sortFunction)
					for j = #groupData, 1, -1 do
						table.insert(scrollData, i + 1, groupData[j])
					end
				end
			end
		end
	end

	dataList.sortHeaderGroup:SelectHeaderByKey("uptime")

	return dataList
end

---@param control Control
function CMXint.InitializeBuffsPanel(control)
	---@class BuffPanel: Panel
	BuffPanel = CMXint.PanelObject:New(control, "buffs")

	BuffPanel.radioButtons = ZO_RadioButtonGroup:New(false)

	local function onBuffCategoryClicked(control, buttonId, ignoreCallback)
		BuffPanel.category = control.buffCategory
		BuffPanel.dataList:RefreshData()
	end

	BuffPanel.radioButtons:SetCustomClickHandler(onBuffCategoryClicked)

	local searchBar = control:GetNamedChild("SearchBar")
	for i = 1, searchBar:GetNumChildren() do
		local child = searchBar:GetChild(i)
		---@diagnostic disable-next-line: undefined-field
		if child.buffCategory then
			BuffPanel.radioButtons:Add(child)
		end
	end

	BuffPanel.dataList = InitBuffsList(BuffPanel)
	BuffPanel.selections = {}

	function BuffPanel:Update()
		logger:Debug("Updating Buff Panel")

		self.dataList:UpdateRowHeight()
		self.dataList:RefreshData()
	end

	BuffPanel.radioButtons:SetClickedButton(searchBar:GetNamedChild("Player"))
end

local isFileInitialized = false
function CMXint.InitializeBuffs()
	if isFileInitialized == true then
		return false
	end
	logger = util.initSublogger("BuffPanel")

	BuffPanel.favs = CMXint.settings.fightReport.buffs.favourites
	BuffPanel.uncollapsedBuffs = uncollapsedBuffs

	CMX_BUFF_PANEL = BuffPanel

	isFileInitialized = true
	return true
end
