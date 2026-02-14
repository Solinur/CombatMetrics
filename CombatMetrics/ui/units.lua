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

local function GetShortFormattedNumber(number)
	local exponent = zo_floor(math.log(number) / math.log(10))
	local loweredNumber = zo_roundToNearest(number, zo_pow(10, exponent - 2))
	local shortNumber = ZO_AbbreviateNumber(loweredNumber, 2, exponent >= 6)

	return shortNumber
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
		local panel = self.panel
		local rowHeight = self:GetHeight()

		local icon = panel:AcquireSharedControl(CT_TEXTURE)
		icon:ApplyPosition(rowControl, 2, 0, rowHeight, rowHeight)

		local label = panel:AcquireSharedControl(CT_LABEL)
		label:ApplyPosition(rowControl, 28, 0, 172)
		label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

		local bar = panel:AcquireSharedControl(CT_TEXTURE)
		bar:ApplyPosition(rowControl, 26, 0, 176, rowHeight)
		bar:SetTexture("esoui/art/unitframes/progressbar_raidhealth.dds")

		local perSecond = panel:AcquireSharedControl(CT_LABEL)
		perSecond:ApplyPosition(rowControl, 204, 0, 46)
		perSecond:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

		local total = panel:AcquireSharedControl(CT_LABEL)
		total:ApplyPosition(rowControl, 252, 0, 58)
		total:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

		local perCent = panel:AcquireSharedControl(CT_LABEL)
		perCent:ApplyPosition(rowControl, 312, 0, 46)
		perCent:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

		rowControl.controls = { icon, label, bar, perSecond, total, perCent }
		rowControl.recovered = true
	end

	---@param rowControl RowControl
	---@param data table
	---@param scrollList object
	function dataList:UpdateRow(rowControl, data, scrollList)
		local panel = self.panel

		if rowControl.recovered ~= true then
			self:RecoverRow(rowControl)
		end
		local icon, label, bar, perSecond, total, perCent = unpack(rowControl.controls)

		-- TODO: Implement controls
	end

	function dataList:AddDataEntry(unitId, data)
		if data.groupUptime <= 0 then
			return
		end

		local selected = false -- selectedbuffs ~= nil and (selectedbuffs[buffName] ~= nil) or false -- TODO: Selections

		local rowData = {
			selected = selected,
		}

		table.insert(self.masterList, ZO_ScrollList_CreateDataEntry(1, rowData))
	end

	function dataList:BuildMasterList()
		local fightData = self.panel:GetCurrentFightData()
		local category = self.panel.settings.category
		-- local categoryData = util.GetPlayerCategoryData(fightData, category) --TODO: Needs to get the table

		ZO_ClearTable(self.masterList)

		for unitId, unitData in pairs(categoryData) do
			self:AddDataEntry(unitId, unitData)
		end
	end

	function dataList:FilterScrollList() end

	dataList.sortHeaderGroup:SelectHeaderByKey("") -- TODO; pick initial sort key

	return dataList
end

function CMXint.InitializeUnitsPanel(control)
	---@class UnitsPanel: Panel
	UnitsPanel = CMXint.PanelObject:New(control, "units")

	UnitsPanel.dataList = InitUnitsList(UnitsPanel)

	function UnitsPanel:UpdateHeaderLabels()
		local isDamage = util.IsDamageCategory(self.settings.category)

		local headers = self.control:GetNamedChild("Headers")
		local nameControl = headers:GetNamedChild("Name") --[[@as LabelControl]]
		local perSecondControl = headers:GetNamedChild("PerSecond") --[[@as LabelControl]]
		local totalControl = headers:GetNamedChild("Total") --[[@as LabelControl]]

		local label1 = isDamage and GetString(SI_COMBAT_METRICS_TARGET) or GetString(SI_COMBAT_METRICS_SOURCE)
		nameControl:SetText(label1)
		local label2 = isDamage and GetString(SI_COMBAT_METRICS_DPS) or GetString(SI_COMBAT_METRICS_HPS)
		perSecondControl:SetText(label2)
		local label3 = isDamage and GetString(SI_COMBAT_METRICS_DAMAGE) or GetString(SI_COMBAT_METRICS_HEALING)
		totalControl:SetText(label3)
	end

	function UnitsPanel:Update(fightData)
		logger:Debug("Updating Unit Panel")

		self:UpdateHeaderLabels()

		self.dataList:UpdateRowHeight()
		self.dataList:RefreshData()

		if true then
			return
		end

		self:ResetBars()

		-- prepare data

		if fightData == nil then
			return
		end
		local data = fightData.calculated
		local selectedunits = ui.selections.unit[category]

		local totalAmountKey = category .. "Total"
		local totalAmount = data[totalAmountKey] -- i.e. damageOutTotal
		local APSKey = DPSstrings[category]

		local scrollchild = GetControl(control, "PanelScrollChild")
		local currentanchor = { TOPLEFT, scrollchild, TOPLEFT, 0, 1 }

		local rightpanel = settings.rightpanel
		local showids = settings.showDebugIds

		for unitId, unit in
			util.spairs(data.units, function(t, a, b)
				return t[a][totalAmountKey] > t[b][totalAmountKey]
			end)
		do -- i.e. for damageOut sort by damageOutTotal
			local totalUnitAmount = unit[totalAmountKey]
			local unitData = fightData.units[unitId]

			if
				(
					totalUnitAmount > 0
					or (
						rightpanel == "buffsout"
							and NonContiguousCount(unit.buffs) > 0
							and (unitData.isFriendly == false and isdamage)
						or (unitData.isFriendly and not isdamage)
					)
				) and not (unitData.unitType == 2 and settings.showPets == false)
			then
				local highlight = false
				if selectedunits ~= nil then
					highlight = selectedunits[unitId] ~= nil
				end

				local dbug = showids and string.format("(%d) ", unitId) or ""

				local name = dbug .. (settings.useDisplayNames and unitData.displayname or unitData.name)

				local isboss = unitData.bossId
				local namecolor = (isboss and { 1, 0.8, 0.3, 1 }) or { 1, 1, 1, 1 }

				local unitTime = unitData.dpsend
						and unitData.dpsstart
						and zo_max((unitData.dpsend - unitData.dpsstart) / 1000, 1)
					or 1
				local dps = unitTime and totalUnitAmount / unitTime or unit[APSKey]
				local damage = totalUnitAmount
				local ratio = damage / totalAmount

				local rowId = #control.bars + 1

				local rowName = scrollchild:GetName() .. "Row" .. rowId
				local row = _G[rowName]
					or CreateControlFromVirtual(rowName, scrollchild, "CombatMetrics_UnitRowTemplate")
				row:SetAnchor(unpack(currentanchor))
				row:SetHidden(false)

				local header = control:GetNamedChild("Header")
				adjustRowSize(row, header)

				local highlightControl = row:GetNamedChild("HighLight")
				highlightControl:SetHidden(not highlight)

				local nameControl = row:GetNamedChild("Name")--[[@as LabelControl]]
				nameControl:SetText(name)
				--nameControl:SetFont(font)
				nameControl:SetColor(unpack(namecolor))

				local maxwidth = nameControl:GetWidth()

				local barControl = row:GetNamedChild("Bar")
				barControl:SetWidth(maxwidth * ratio)

				local rateControl = row:GetNamedChild("PerSecond")--[[@as LabelControl]]
				rateControl:SetText(string.format("%.0f", dps))

				local amountControl = row:GetNamedChild("Total")--[[@as LabelControl]]
				amountControl:SetText(GetShortFormattedNumber(damage))

				local fractionControl = row:GetNamedChild("Fraction")--[[@as LabelControl]]
				fractionControl:SetText(string.format("%.1f%%", 100 * ratio))

				currentanchor = { TOPLEFT, row, BOTTOMLEFT, 0, dx }

				control.bars[rowId] = row

				row["dataId"] = unitId
				row["type"] = "unit"
				row["id"] = rowId
				row["self"] = control
			end
		end
	end

	function UnitsPanel:Clear()
		logger:Debug("Clearing Units Panel")
		self.dataList:Clear()
	end

	function UnitsPanel:Recover() end
end

local isFileInitialized = false
function CMXint.InitializeUnits()
	if isFileInitialized == true then
		return false
	end
	logger = util.initSublogger("UnitsPanel")

	isFileInitialized = true
	return true
end
