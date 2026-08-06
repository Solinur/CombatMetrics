-- Units panel with scroll list.
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

local cat = util.MainCategories
local cat_opp = util.OppositionCategory

local UNIT_NAME_FORMAT_ID = "(<<2>>) <<1>>"
local UNIT_NAME_FORMAT_DEFAULT = "<<1>>"

local UNIT_COLOR_DEFAULT = ZO_ColorDef:New("FFFFFFFF")
local UNIT_COLOR_BOSS = ZO_ColorDef:New("FFFF5555")
local UNIT_COLOR_GROUP = ZO_ColorDef:New("FF99FF99")
local UNIT_COLOR_PLAYER = ZO_ColorDef:New("FFFFFFAA")

local UNIT_BAR_COLOR_DAMAGE = ZO_ColorDef:New("99CC0000")
local UNIT_BAR_COLOR_HEAL = ZO_ColorDef:New("9900CC00")

do -- Handling Unit Context Menu
	local UnitContextMenuUnitId
	-- local function postUnitDPS()
	-- 	CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SELECTED_UNIT, currentFight, UnitContextMenuUnitId)
	-- end

	-- local function postUnitNameDPS()
	-- 	CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SELECTED_UNITNAME, currentFight, UnitContextMenuUnitId)
	-- end

	-- local function postSelectionDPS()
	-- 	CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SELECTION, currentFight)
	-- end

	-- local function postSelectionHPS()
	-- 	CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SELECTION_HEALING, currentFight)
	-- end

	-- function CMX.UnitContextMenu(unitItem, upInside)
	-- 	local category = CMXint.settings.fightReport.category
	-- 	if not (upInside or category == "damageOut" or category == "healingOut") then
	-- 		return
	-- 	end
	-- 	local dataId = unitItem.dataId
	-- 	local selections = ui.selections

	-- 	ClearMenu()

	-- 	if category == "damageOut" then
	-- 		UnitContextMenuUnitId = dataId

	-- 		local unitName = fightData.units[dataId].name

	-- 		AddCustomMenuItem(GetString(SI_COMBAT_METRICS_POSTUNITDPS), postUnitDPS)
	-- 		AddCustomMenuItem(zo_strformat(GetString(SI_COMBAT_METRICS_POSTUNITNAMEDPS), unitName, 2), postUnitNameDPS)

	-- 		if selections.unit[category] then
	-- 			AddCustomMenuItem(GetString(SI_COMBAT_METRICS_POSTSELECTIONDPS), postSelectionDPS)
	-- 		end
	-- 	elseif category == "healingOut" and selections.unit[category] then
	-- 		AddCustomMenuItem(GetString(SI_COMBAT_METRICS_POSTSELECTIONHPS), postSelectionHPS)
	-- 	end

	-- 	ShowMenu(unitItem)
	-- end
end

---@param unitData UnitData
---@return string?
local function GetUnitIcon(unitData)
	if unitData.isBoss then
		return "esoui/art/icons/poi/poi_groupboss_complete.dds"
	elseif unitData.unitType == COMBAT_UNIT_TYPE_GROUP then
		return "esoui/art/journal/gamepad/gp_questtypeicon_group.dds"
	end
end

---@param unitData UnitData
---@return ZO_ColorDef
local function GetUnitColor(unitData)
	if unitData.unitType == COMBAT_UNIT_TYPE_PLAYER then
		return UNIT_COLOR_PLAYER
	elseif unitData.isBoss then
		return UNIT_COLOR_BOSS
	elseif unitData.unitType == COMBAT_UNIT_TYPE_GROUP then
		return UNIT_COLOR_GROUP
	end
	return UNIT_COLOR_DEFAULT
end

---@param panel UnitsPanel
---@return UnitDataList
local function InitUnitsList(panel)
	---@class UnitDataList: SortFilterList
	local dataList = ui.SortFilterList:New(panel.control, "CombatMetrics_RowTemplate")
	panel.dataList = dataList
	dataList.panel = panel
	dataList.masterList = {}

	---@param rowControl RowControl
	function dataList:RecoverRow(rowControl)
		local rowHeight = self:GetRawHeight()

		local icon = ui.sharedControls:Acquire(rowControl, CT_TEXTURE)
		icon:ApplyPosition(rowControl, 2, 0, rowHeight, rowHeight)

		local label = ui.sharedControls:Acquire(rowControl, CT_LABEL)
		label:ApplyPosition(rowControl, 32, 0, 162)
		label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

		local bar = ui.sharedControls:Acquire(rowControl, CT_TEXTURE)
		bar:ApplyPosition(rowControl, 30, 0, 166, rowHeight)
		bar:SetTexture("esoui/art/unitframes/progressbar_raidhealth.dds")

		local perSecond = ui.sharedControls:Acquire(rowControl, CT_LABEL)
		perSecond:ApplyPosition(rowControl, 198, 0, 48)
		perSecond:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

		local total = ui.sharedControls:Acquire(rowControl, CT_LABEL)
		total:ApplyPosition(rowControl, 248, 0, 60)
		total:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

		local perCent = ui.sharedControls:Acquire(rowControl, CT_LABEL)
		perCent:ApplyPosition(rowControl, 310, 0, 32)
		perCent:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

		-- TODO: Fix Column widths

		rowControl.controls = { icon, label, bar, perSecond, total, perCent }
		rowControl.recovered = true
	end

	---@param rowControl RowControl
	---@param data UnitRowData
	---@param scrollList object
	function dataList:UpdateRow(rowControl, data, scrollList)
		local panel = self.panel

		local icon, label, bar, perSecond, total, perCent = unpack(rowControl.controls)

		---@cast icon TextureControl
		local iconTexture = data.icon
		icon:SetHidden(iconTexture == nil)
		if iconTexture then
			icon:SetTexture(iconTexture)
		end

		---@cast label LabelControl
		local namecolor = data.color
		local font = ui.GetFont(ui.fontSize, false)
		label:SetText(data.name)
		label:SetColor(namecolor:UnpackRGBA())
		label:SetFont(font)

		local playerAmount = data.playerAmount
		local perSecondValue = data.perSecondValue
		local ratio = data.playerAmount / self.playerAmountSum

		-- local highlightControl = row:GetNamedChild("HighLight")
		-- highlightControl:SetHidden(not highlight)

		---@cast bar TextureControl
		local barColor = util.IsDamageCategory() and UNIT_BAR_COLOR_DAMAGE or UNIT_BAR_COLOR_HEAL
		local maxwidth = label:GetWidth()
		bar:SetWidth(maxwidth * ratio)
		bar:SetColor(barColor:UnpackRGBA())

		perSecond:SetText(string.format("%.0f", perSecondValue))
		perSecond:SetFont(font)

		total:SetText(util.GetShortFormattedNumber(playerAmount))
		total:SetFont(font)

		perCent:SetText(string.format("%.0f%%", 100 * ratio))
		perCent:SetFont(font)
	end

	---@param unitData UnitData
	---@param playerData UnitDamageData|UnitHealData
	---@param groupData UnitDamageData|UnitHealData
	---@param durationMs integer
	function dataList:AddDataEntry(unitData, playerData, groupData, durationMs)
		if playerData.totalAmount <= 0 then
			return
		end

		local panelSettings = self.panel.settings
		local category = panelSettings.category
		local isOverheal = category == cat.CMX_CATEGORY_HEALING_DONE and panelSettings.showOverHeal
		local playerAmount = isOverheal and (playerData.totalAmount + playerData.overflowAmount)
			or playerData.totalAmount

		local groupAmount = playerAmount
		if groupData then
			groupAmount = isOverheal and (groupData.totalAmount + groupData.overflowAmount) or groupData.totalAmount
		end

		local labelFormat = panel:ShowIds() and unitData.unitId and UNIT_NAME_FORMAT_ID or UNIT_NAME_FORMAT_DEFAULT
		local name = ZO_CachedStrFormat(labelFormat, unitData.name, unitData.unitId)

		---@class UnitRowData
		local rowData = {
			id = unitData.unitId,
			name = name,
			icon = GetUnitIcon(unitData),
			color = GetUnitColor(unitData),
			perSecondValue = playerAmount / (durationMs / 1000),
			playerAmount = playerAmount,
			groupAmount = groupAmount,
		}

		dataList.playerAmountSum = dataList.playerAmountSum + playerAmount
		dataList.groupAmountSum = dataList.groupAmountSum + groupAmount

		table.insert(self.masterList, ZO_ScrollList_CreateDataEntry(1, rowData))
	end

	function dataList:BuildMasterList()
		local fightData = self.panel:GetCurrentFightData()
		if fightData == nil then
			error("UnitsPanel:BuildMasterList() called without active fight data", 2)
		end
		local category = self.panel.settings.category
		local playerId = fightData.unitIds.player
		local categoryData = util.GetUnitCategoryData(fightData, category, playerId)

		if categoryData == nil then
			return
		end

		ZO_ClearTable(self.masterList)

		local durationMs = categoryData.endTime - categoryData.startTime
		local oppositionCategory = cat_opp[category]

		dataList.playerAmountSum = 0
		dataList.groupAmountSum = 0

		local abilitiesPanel = ui.panels["abilities"]
		local abilitySel = abilitiesPanel and abilitiesPanel:GetSelections()
		local abilityIds = (abilitySel and abilitySel.active) and abilitySel.selectedItems or nil

		for unitId, playerUnitData in pairs(categoryData) do
			if type(playerUnitData) == "table" then
				if abilityIds then
					playerUnitData = util.GetCombinedPlayerCategoryData(fightData, category, { unitId }, abilityIds)
				end
				if playerUnitData ~= nil and playerUnitData.totalAmount > 0 then
					local groupData = util.GetUnitCategoryData(fightData, oppositionCategory, unitId)
					local unitInfo = fightData.units[unitId]
					if unitInfo then -- TODO: check why this can be nil
						self:AddDataEntry(unitInfo, playerUnitData, groupData, durationMs)
					else
						logger:Error("Unit info not found for unit ID: %s", unitId)
					end
				end
			end
		end

		local scrollData = ZO_ScrollList_GetDataList(self.list)
		ZO_ScrollList_Clear(self.list)

		for i, data in ipairs(self.masterList) do
			scrollData[#scrollData + 1] = data
		end
	end

	function dataList:FilterScrollList() end

	dataList.sortHeaderGroup:SelectHeaderByKey("playerAmount")

	return dataList
end

function CMXint.InitializeUnitsPanel(control)
	---@class UnitsPanel: Panel
	UnitsPanel = CMXint.PanelObject:New(control, "units")
	UnitsPanel.scenes = { "fightStats", "combatLog" }

	UnitsPanel.dataList = InitUnitsList(UnitsPanel)

	function UnitsPanel:UpdateHeaderLabels()
		local isDamage = util.IsDamageCategory()

		local headers = self.control:GetNamedChild("Headers")
		local nameControl = headers:GetNamedChild("Name"):GetNamedChild("Name") --[[@as LabelControl]]
		local perSecondControl = headers:GetNamedChild("PerSecond"):GetNamedChild("Name") --[[@as LabelControl]]
		local totalControl = headers:GetNamedChild("Total"):GetNamedChild("Name") --[[@as LabelControl]]

		local unitLabel = isDamage and GetString(SI_COMBAT_METRICS_TARGET) or GetString(SI_COMBAT_METRICS_SOURCE)
		nameControl:SetText(unitLabel)
		local perSecondLabel = isDamage and GetString(SI_COMBAT_METRICS_DPS) or GetString(SI_COMBAT_METRICS_HPS)
		perSecondControl:SetText(perSecondLabel)
		local totalLabel = isDamage and GetString(SI_COMBAT_METRICS_DAMAGE) or GetString(SI_COMBAT_METRICS_HEALING)
		totalControl:SetText(totalLabel)
	end

	function UnitsPanel:Update()
		logger:Info("Updating Unit Panel")

		self:UpdateHeaderLabels()

		self.dataList:UpdateRowHeight()
		self.dataList:RefreshData()
	end

	function UnitsPanel:Clear()
		logger:Info("Clearing Units Panel")
		self.dataList:Clear()
	end

	function UnitsPanel:Recover() end
end

local isFileInitialized = false
function CMXint.InitializeUnits()
	if isFileInitialized == true then
		return true
	end
	logger = util.initSublogger("UnitsPanel")

	isFileInitialized = true
	return true
end
