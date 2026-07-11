-- Buffs panel with scroll list.
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
local LC = LibCombat2

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

BUFF_LIST_SORT_KEYS = {
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

	function CMXint.BuffContextMenu(bufflistitem, upInside)
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

		if util.IsDamageCategory() and BuffPanel.buffCategory == "Enemy" then
			unitType = "boss"
			AddCustomMenuItem(GetString(SI_COMBAT_METRICS_POSTBUFF_BOSS), postSelectionBuffUptime)
		elseif util.IsHealingCategory() and BuffPanel.buffCategory == "Group" then
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

---@param source EffectData
---@param dest EffectData
local function CombineEffects(source, dest)
	if dest.name ~= source.name then
		error(string.format("Name mismatch when combining buff data: %s ~= %s.", dest.name, source.name), 2)
	end
	if dest.iconId ~= source.iconId then
		error(
			string.format(
				"ID mismatch when combining buff data: %s ~= %s.",
				tostring(dest.iconId),
				tostring(source.iconId)
			),
			2
		)
	end
	dest.uptime = dest.uptime + source.uptime
	dest.count = dest.count + source.count
	dest.groupUptime = dest.groupUptime + source.groupUptime
	dest.groupCount = dest.groupCount + source.groupCount

	if dest.effectType and dest.effectType ~= source.effectType then
		logger:Error("Mismatching effect types.")
	end
	dest.effectType = source.effectType
	dest.maxStacks = zo_max(dest.maxStacks, source.maxStacks)

	local sourceStacks = source.stacks
	if sourceStacks == nil then
		return
	end

	local destStacks = dest.stacks
	if destStacks == nil then
		destStacks = {}
		dest.stacks = destStacks
	end

	for stacks, stackData in pairs(sourceStacks) do
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

---@type EffectData
local effectData = {}
local unitIds = {}

---comment
---@param fightData Fight
---@param category buffCategory
---@return EffectData
---@return integer
local function GetBuffData(fightData, category, filterIds)
	local totalUnitTime = 0

	ZO_ClearTable(unitIds)
	ZO_ClearTable(effectData)

	if fightData == nil then
		return effectData, totalUnitTime
	end

	if category == BUFF_CATEGORY_PLAYER then
		unitIds[#unitIds + 1] = fightData.unitIds.player
	elseif category == BUFF_CATEGORY_GROUP then
		local group = fightData.unitIds.group
		if ZO_IsTableEmpty(group) == false then
			for unitId in pairs(group) do
				if not filterIds or filterIds[unitId] then
					unitIds[#unitIds + 1] = unitId
				end
			end
		else
			unitIds[#unitIds + 1] = fightData.unitIds.player
		end
	elseif category == BUFF_CATEGORY_ENEMY then
		for _, unitId in ipairs(LC.GetEnemyUnits(fightData)) do
			if not filterIds or filterIds[unitId] then
				unitIds[#unitIds + 1] = unitId
			end
		end
	end

	for i, unitId in ipairs(unitIds) do
		local unitEffectData = fightData.effects[unitId]
		if unitEffectData then
			local startTime = unitEffectData.startTime or math.huge
			local endTime = unitEffectData.endTime or 0
			if endTime > startTime then
				totalUnitTime = totalUnitTime + (endTime - startTime)
				for abilityId, data in pairs(unitEffectData) do
					if type(abilityId) == "number" then
						if effectData[abilityId] == nil then
							local effectCopy = ZO_ShallowTableCopy(data) -- TODO: Review this code
							if data.stacks then
								effectCopy.stacks = {}
								for stacks, stackData in pairs(data.stacks) do
									effectCopy.stacks[stacks] = ZO_ShallowTableCopy(stackData)
								end
							end
							effectData[abilityId] = effectCopy
						else
							CombineEffects(data, effectData[abilityId])
						end
					end
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

---@alias buffCategory "Enemy" | "Group" | "Player"
---@class BuffCategoryButton: ButtonControl
---@field buffCategory buffCategory

---@param control BuffCategoryButton
---@param buffCategory "Enemy" | "Group" | "Player"
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

local isFileInitialized = false

---@param panel BuffPanel
---@return BuffDataList
local function InitBuffsList(panel)
	---@class BuffDataList: SortFilterList
	local dataList = ui.SortFilterList:New(panel.control, "CombatMetrics_RowTemplate")
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

	---@diagnostic disable-next-line: redundant-parameter
	local expandButtonPool = ZO_ObjectPool:New(CreateExpandButton, ZO_ObjectPool_DefaultResetControl)

	---@class BuffRowControl: RowControl
	---@field expandButton ExpandButton

	---@param rowControl BuffRowControl
	function dataList:RecoverRow(rowControl)
		local rowHeight = self:GetRawHeight()

		local icon = ui.sharedControls:Acquire(rowControl, CT_TEXTURE)
		icon:ApplyPosition(rowControl, 14, 0, rowHeight, rowHeight)

		local label = ui.sharedControls:Acquire(rowControl, CT_LABEL)
		label:ApplyPosition(rowControl, 40, 0, 186)
		label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

		local bar = ui.sharedControls:Acquire(rowControl, CT_TEXTURE)
		bar:ApplyPosition(rowControl, 38, 0, 190, rowHeight)
		bar:SetTexture("esoui/art/unitframes/progressbar_raidhealth.dds")

		local bar_group = ui.sharedControls:Acquire(rowControl, CT_TEXTURE)
		bar_group:ApplyPosition(rowControl, 38, 0, 190, rowHeight)
		bar_group:SetTexture("esoui/art/unitframes/progressbar_raidhealth.dds")

		local count = ui.sharedControls:Acquire(rowControl, CT_LABEL)
		count:ApplyPosition(rowControl, 230, 0, 58)
		count:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

		local uptime = ui.sharedControls:Acquire(rowControl, CT_LABEL)
		uptime:ApplyPosition(rowControl, 290, 0, 58)
		uptime:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

		rowControl.controls = { icon, label, bar, bar_group, count, uptime }
		rowControl.recovered = true
	end

	---@param rowControl BuffRowControl
	---@param data BuffRowData
	---@param scrollList object
	function dataList:UpdateRow(rowControl, data, scrollList)
		local panel = self.panel

		local icon, label, bar, bar_group, count, uptime = unpack(rowControl.controls)

		local labelFormat = panel:ShowIds() and data.abilityId and BUFF_NAME_FORMAT_ID or BUFF_NAME_FORMAT_DEFAULT
		local labelText = ZO_CachedStrFormat(labelFormat, data.labelText, data.abilityId)

		-- SetIndent is absolute and takes unscaled units, so the raw row height is the one to use;
		-- icon:GetHeight() is already scaled.
		local indent = data.indent * self:GetRawHeight() / 2

		local textcolor = panel.favs[data.abilityId] and BUFF_LABEL_COLOR_FAV or BUFF_LABEL_COLOR_DEFAULT
		local font = ui.GetFont(ui.fontSize, false)

		local expandButton = rowControl.expandButton

		if data.hasDetails then
			if expandButton == nil then
				local scale = self.panel.settings.scale
				local buttonSize = icon:GetHeight()
				expandButton = expandButtonPool:AcquireObject()
				expandButton:SetHidden(false)
				expandButton:SetParent(rowControl)
				expandButton:SetAnchor(TOPLEFT, rowControl, TOPLEFT, -2 * scale, scale)
				expandButton:SetDimensions(buttonSize, buttonSize)
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
		label:SetIndent(indent)
		label:SetColor(unpack(textcolor))
		label:SetFont(font)

		local maxwidth = label:GetWidth()

		bar:SetColor(unpack(BUFF_BAR_COLORS[data.effectType]))
		bar:SetIndent(indent)
		bar:SetWidth(maxwidth * data.uptime)

		bar_group:SetColor(unpack(BUFF_BAR_GROUP_COLORS[data.effectType]))
		bar_group:SetIndent(indent)
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

	---comment
	---@param abilityId integer
	---@param data EffectData
	---@param totalUnitTime integer
	function dataList:AddDataEntry(abilityId, data, totalUnitTime)
		if data.groupUptime <= 0 then
			return
		end

		local hasStacks = data.stacks and (data.iconId == 126597 or data.maxStacks > 1)

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

		---@class BuffRowData
		local rowData = {
			id = abilityId,
			indent = 0,
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

			--  TODO: Check if still necessary
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

				---@type BuffRowData
				local rowData = {
					indent = 1,
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
		if fightData == nil then
			if not isFileInitialized then
				return
			end
			error("BuffPanel:BuildMasterList() called without active fight data")
		end
		local buffCategory = self.panel.buffCategory
		local unitsPanel = ui.panels["units"]
		local unitSel = unitsPanel and unitsPanel:GetSelections()
		local filterIds = nil

		if unitSel and unitSel.active then
			local isEnemyFiltered = buffCategory == BUFF_CATEGORY_ENEMY and util.IsDamageCategory()
			local isGroupFiltered = buffCategory == BUFF_CATEGORY_GROUP and util.IsHealingCategory()
			if isEnemyFiltered or isGroupFiltered then
				filterIds = unitSel.selectedItems
			end
		end

		local effectData, totalUnitTime = GetBuffData(fightData, buffCategory, filterIds)

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
			for i, groupEntry in ipairs(groupData) do
				local groupEntryData = groupEntry.data
				if groupEntryData.uptime > entryData.uptime then
					entryData.uptime = groupEntryData.uptime
					entryData.groupUptime = groupEntryData.groupUptime
					entryData.count = groupEntryData.count
					entryData.groupCount = groupEntryData.groupCount
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

		local groupList = self.groupList

		-- Correct parent uptimes from group data before sorting
		for i = 1, #scrollData do
			local groupData = groupList[scrollData[i].data.abilityId]
			if groupData then
				dataList:ProcessGroupData(scrollData[i].data, groupData)
			end
		end

		table.sort(scrollData, self.sortFunction) -- TODO: include sorting favourites

		-- Insert expanded children after sort
		for i = #scrollData, 1, -1 do
			local abilityId = scrollData[i].data.abilityId
			local groupData = groupList[abilityId]
			if groupData and uncollapsedBuffs[abilityId] then
				table.sort(groupData, self.sortFunction)
				for j = #groupData, 1, -1 do
					table.insert(scrollData, i + 1, groupData[j])
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
	BuffPanel.scenes = { "fightStats", "combatLog" }

	BuffPanel.radioButtons = ZO_RadioButtonGroup:New(false)

	local function onBuffCategoryClicked(control, buttonId, ignoreCallback)
		BuffPanel.buffCategory = control.buffCategory
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

	function BuffPanel:Update()
		logger:Debug("Updating Buff Panel")

		self.dataList:UpdateRowHeight()
		self.dataList:RefreshData()
	end

	function BuffPanel:Clear()
		logger:Debug("Clearing Buff Panel")
		self.dataList:Clear()
	end

	function BuffPanel:Recover() end

	BuffPanel.radioButtons:SetClickedButton(searchBar:GetNamedChild("Player"))
end

function CMXint.InitializeBuffs()
	if isFileInitialized == true then
		return false
	end
	logger = util.initSublogger("BuffPanel")

	BuffPanel.favs = CMXint.settings.fightReport.buffs.favourites
	BuffPanel.uncollapsedBuffs = uncollapsedBuffs

	isFileInitialized = true
	return true
end
