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

local GetFormattedAbilityIcon = util.GetFormattedAbilityIcon
local GetFormattedAbilityName = util.GetFormattedAbilityName
local GetDamageColor = util.GetDamageColor
local adjustRowSize = util.adjustRowSize

local ABILITY_NAME_FORMAT_ID = "(<<2>>) <<1>>"
local ABILITY_NAME_FORMAT_DEFAULT = "<<1>>"

local AbilityPanel

-- local hitCritLayoutTable = {
-- 	[1] = { "Critical", "Total", GetString(SI_COMBAT_METRICS_CRITS), GetString(SI_COMBAT_METRICS_HITS) },
-- 	[2] = { "Total", "Critical", GetString(SI_COMBAT_METRICS_HITS), GetString(SI_COMBAT_METRICS_CRITS) },
-- 	[3] = { "Normal", "Critical", GetString(SI_COMBAT_METRICS_NORM), GetString(SI_COMBAT_METRICS_CRITS) },
-- 	[4] = { "Blocked", "Total", GetString(SI_COMBAT_METRICS_BLOCKS), GetString(SI_COMBAT_METRICS_HITS) },
-- 	[5] = { "Total", "Blocked", GetString(SI_COMBAT_METRICS_HITS), GetString(SI_COMBAT_METRICS_BLOCKS) },
-- 	[6] = { "Normal", "Blocked", GetString(SI_COMBAT_METRICS_NORM), GetString(SI_COMBAT_METRICS_BLOCKS) },
-- }

-- do -- Context Menu for hit/crit column on ability panel
-- 	local function getMenuData(id)
-- 		local category = CMXint.settings.fightReport.category
-- 		local hitCritLayout = hitCritLayoutTable[id]
-- 		local text = string.format("%s/%s", hitCritLayout[3], hitCritLayout[4])

-- 		local function callback()
-- 			CMXint.settings.fightReport.hitCritLayout[category] = id
-- 			AbilityPanel:Update()
-- 		end

-- 		return text, callback
-- 	end

-- 	function CMX.HitCritContextMenu(control, button)
-- 		ClearMenu()

-- 		if CMXint.settings.fightReport.category == "damageIn" then
-- 			AddCustomMenuItem(getMenuData(4))
-- 			AddCustomMenuItem(getMenuData(5))
-- 			AddCustomMenuItem(getMenuData(6))
-- 		end

-- 		AddCustomMenuItem(getMenuData(1))
-- 		AddCustomMenuItem(getMenuData(2))
-- 		AddCustomMenuItem(getMenuData(3))

-- 		ShowMenu(control)
-- 	end
-- end

-- local averageLayoutTable = {
-- 	[1] = { "Total", GetString(SI_COMBAT_METRICS_AVE), GetString(SI_COMBAT_METRICS_HITS) },
-- 	[2] = { "Normal", GetString(SI_COMBAT_METRICS_AVE_N), GetString(SI_COMBAT_METRICS_NORMAL_HITS) },
-- 	[3] = { "Critical", GetString(SI_COMBAT_METRICS_AVE_C), GetString(SI_COMBAT_METRICS_CRITS) },
-- 	[4] = { "Blocked", GetString(SI_COMBAT_METRICS_AVE_B), GetString(SI_COMBAT_METRICS_BLOCKS) },
-- }

-- do -- Context Menu for average column on ability panel
-- 	local function getMenuData(id)
-- 		local averageLayout = averageLayoutTable[id]
-- 		local text = string.format("%s %s", GetString(SI_COMBAT_METRICS_AVERAGE), averageLayout[3])
-- 		local category = CMXint.settings.fightReport.category

-- 		local function callback()
-- 			CMXint.settings.fightReport.averageLayout[category] = id
-- 			AbilityPanel:Update()
-- 		end

-- 		return text, callback
-- 	end

-- 	function CMX.AverageContextMenu(control, button)
-- 		ClearMenu()

-- 		AddCustomMenuItem(getMenuData(1))
-- 		AddCustomMenuItem(getMenuData(2))
-- 		AddCustomMenuItem(getMenuData(3))

-- 		if CMXint.settings.fightReport.category == "damageIn" then
-- 			AddCustomMenuItem(getMenuData(4))
-- 		end

-- 		ShowMenu(control)
-- 	end
-- end

-- do -- Context Menu for Min/Max column on ability panel
-- 	local function selectMinMaxOption1()
-- 		local category = CMXint.settings.fightReport.category
-- 		CMXint.settings.fightReport.maxValue[category] = true
-- 		AbilityPanel:Update()
-- 	end

-- 	local function selectMinMaxOption2()
-- 		local category = CMXint.settings.fightReport.category
-- 		CMXint.settings.fightReport.maxValue[category] = false
-- 		AbilityPanel:Update()
-- 	end

-- 	local text1 = string.format("%s", GetString(SI_COMBAT_METRICS_MAX))
-- 	local text2 = string.format("%s", GetString(SI_COMBAT_METRICS_MIN))

-- 	function CMX.MinMaxContextMenu(control, button)
-- 		ClearMenu()

-- 		AddCustomMenuItem(text1, selectMinMaxOption1)
-- 		AddCustomMenuItem(text2, selectMinMaxOption2)

-- 		ShowMenu(control)
-- 	end
-- end

---@param panel AbilityPanel
---@return AbilityDataList
local function InitAbilitiesList(panel)
	---@class AbilityDataList: SortFilterList
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
		label:ApplyPosition(rowControl, 28, 0, 178)
		label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

		local bar = panel:AcquireSharedControl(CT_TEXTURE)
		bar:ApplyPosition(rowControl, 26, 0, 182, rowHeight)
		bar:SetTexture("esoui/art/unitframes/progressbar_raidhealth.dds")

		local perSecond = panel:AcquireSharedControl(CT_LABEL)
		perSecond:ApplyPosition(rowControl, 210, 0, 50)
		perSecond:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

		local total = panel:AcquireSharedControl(CT_LABEL)
		total:ApplyPosition(rowControl, 262, 0, 73)
		total:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

		local crits = panel:AcquireSharedControl(CT_LABEL)
		crits:ApplyPosition(rowControl, 337, 0, 42)
		crits:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

		local hits = panel:AcquireSharedControl(CT_LABEL)
		hits:ApplyPosition(rowControl, 381, 0, 42)
		hits:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

		local critRatio = panel:AcquireSharedControl(CT_LABEL)
		critRatio:ApplyPosition(rowControl, 425, 0, 35)
		critRatio:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

		local averageHit = panel:AcquireSharedControl(CT_LABEL)
		averageHit:ApplyPosition(rowControl, 462, 0, 50)
		averageHit:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

		local minMax = panel:AcquireSharedControl(CT_LABEL)
		minMax:ApplyPosition(rowControl, 514, 0, 50)
		minMax:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

		rowControl.controls = { icon, label, bar, perSecond, total, crits, hits, critRatio, averageHit, minMax }
		rowControl.recovered = true
	end

	---@param rowControl RowControl
	---@param data AbilityRowData
	---@param scrollList object
	function dataList:UpdateRow(rowControl, data, scrollList)
		local panel = self.panel

		if rowControl.recovered ~= true then
			self:RecoverRow(rowControl)
		end

		local icon, label, bar, perSecond, total, crits, hits, critRatio, averageHit, minMax =
			unpack(rowControl.controls)

		-- TODO: Implement
	end

	function dataList:BuildMasterList()
		local fightData = self.panel:GetCurrentFightData()
		local category = self.panel.settings.category
		local categoryData = util.GetCombinedPlayerCategoryDataByAbility(fightData, category) -- Add selected units
		local playerId = fightData.unitIds.player
		local playerData = util.GetUnitCategoryData(fightData, category, playerId)

		if categoryData == nil then
			return
		end

		CMX_CATEGORY_DATA = categoryData

		ZO_ClearTable(self.masterList)

		local durationMs = playerData.endTime - playerData.startTime
		local totalAmount = playerData.totalAmount

		for abilityId, abilityData in pairs(categoryData) do
			if type(abilityId) == "number" and type(abilityData) == "table" then
				self:UpdateDataEntry(abilityId, abilityData, durationMs, totalAmount)
			end
		end

		local scrollData = ZO_ScrollList_GetDataList(self.list)
		ZO_ScrollList_Clear(self.list)

		for i, data in ipairs(self.masterList) do
			scrollData[#scrollData + 1] = data
		end
	end

	---comment
	---@param abilityId number
	---@param abilityData DamageAbilityData|HealAbilityData
	---@param durationMs number
	---@param totalAmount number
	function dataList:UpdateDataEntry(abilityId, abilityData, durationMs, totalAmount)
		if abilityData.totalAmount <= 0 then
			return
		end

		local selected = false -- selectedunits ~= nil and (selectedunits[unitId] ~= nil) or false -- TODO: Selections

		local category = self.panel.settings.category
		local isOverheal = category == "healingOut" and self.panel.settings.includeOverheal
		local amount = isOverheal and abilityData.overflowAmount or abilityData.totalAmount

		local labelFormat = panel:ShowIds() and abilityId and ABILITY_NAME_FORMAT_ID or ABILITY_NAME_FORMAT_DEFAULT
		local name = ZO_CachedStrFormat(labelFormat, GetFormattedAbilityName(abilityId, false), abilityId)

		---@class AbilityRowData
		local rowData = {
			name = name,
			icon = GetFormattedAbilityIcon(abilityId, false),
			color = GetDamageColor(abilityData),
			perSecondValue = amount / (durationMs / 1000),
			selected = selected,
			amount = amount,
			-- TODO: add crit, min, max and so on
		}

		table.insert(self.masterList, ZO_ScrollList_CreateDataEntry(1, rowData))
	end

	function dataList:FilterScrollList() end

	dataList.sortHeaderGroup:SelectHeaderByKey("Total")

	return dataList
end

function CMXint.InitializeAbilitiesPanel(control)
	---@class AbilityPanel: Panel
	AbilitiesPanel = CMXint.PanelObject:New(control, "abilities")
	AbilitiesPanel.dataList = InitAbilitiesList(AbilitiesPanel)
	AbilitiesPanel.selections = {}

	function AbilitiesPanel:UpdateHeaderLabels()
		local isDamage = util.IsDamageCategory(self.settings.category)

		local headers = self.control:GetNamedChild("Headers")
		local perSecondControl = headers:GetNamedChild("PerSecond"):GetNamedChild("Name") --[[@as LabelControl]]
		local totalControl = headers:GetNamedChild("Total"):GetNamedChild("Name") --[[@as LabelControl]]

		local perSecondLabel = isDamage and GetString(SI_COMBAT_METRICS_DPS) or GetString(SI_COMBAT_METRICS_HPS)
		perSecondControl:SetText(perSecondLabel)
		local totalLabel = isDamage and GetString(SI_COMBAT_METRICS_DAMAGE) or GetString(SI_COMBAT_METRICS_HEALING)
		totalControl:SetText(totalLabel)
	end

	function AbilitiesPanel:Update()
		logger:Debug("Updating Ability Panel")

		if true then
			logger:Warn("Abilities panel update is not implemented yet.")
			return
		end

		logger:Info("Updating Unit Panel")

		self:UpdateHeaderLabels()

		self.dataList:UpdateRowHeight()
		self.dataList:RefreshData()
	end

	function AbilitiesPanel:Clear()
		logger:Debug("Clearing Units Panel")
		self.dataList:Clear()
	end

	function AbilitiesPanel:Recover() end

	-- self:ResetBars()

	-- local settings = self.settings
	-- local abilitySettings = settings.abilities

	-- local category = settings.category
	-- local hitCritLayoutId = abilitySettings.hitCritLayout[category]
	-- local averageLayoutId = abilitySettings.averageLayout[category]
	-- local hitCritLayout = hitCritLayoutTable[hitCritLayoutId]
	-- local averageLayout = averageLayoutTable[averageLayoutId]
	-- local minmax = abilitySettings.maxValue[category]

	-- local isDamage = category == "damageIn" or category == "damageOut"
	-- local showOverHeal = settings.showOverHeal and category == "healingOut"

	-- local valueColumnLabel = isDamage and GetString(SI_COMBAT_METRICS_DAMAGE)
	-- 	or GetString(SI_COMBAT_METRICS_HEALING)

	-- if showOverHeal then
	-- 	valueColumnLabel = valueColumnLabel .. "*"
	-- end

	-- local header = control:GetNamedChild("Header")

	-- header:GetNamedChild("Total"):SetText(valueColumnLabel)

	-- local headerCritString = showOverHeal and GetString(SI_COMBAT_METRICS_OH) or hitCritLayout[3]
	-- local headerHitString = showOverHeal and GetString(SI_COMBAT_METRICS_HEALS) or hitCritLayout[4]
	-- local headerCritRatioString = showOverHeal and GetString(SI_COMBAT_METRICS_OH)
	-- 	or hitCritLayoutId > 3 and GetString(SI_COMBAT_METRICS_BLOCKS)
	-- 	or GetString(SI_COMBAT_METRICS_CRITS)

	-- header:GetNamedChild("Crits"):SetText(headerCritString)
	-- header:GetNamedChild("Hits"):SetText("/" .. headerHitString)
	-- header:GetNamedChild("CritRatio"):SetText(headerCritRatioString .. "%")

	-- local headerAvg = header:GetNamedChild("Average")

	-- headerAvg:SetText(averageLayout[2])

	-- local headerMinMax = header:GetNamedChild("MinMax")

	-- headerMinMax:SetText(GetString(minmax and SI_COMBAT_METRICS_MAX or SI_COMBAT_METRICS_MIN))

	-- if fightData == nil then
	-- 	return
	-- end

	-- local data
	-- local totaldmg

	-- local selections = ui.selections

	-- local selectedabilities = selections["ability"][category]
	-- local selectedunits = selections["unit"][category]

	-- local totalkey = "Total"
	-- local totalAmountKey = showOverHeal and "healingOutAbsolute" or category .. totalkey
	-- local countString = CountStrings[category]

	-- if selectedunits ~= nil then
	-- 	local selectionData = util.GetSelectionData() -- TODO: Implement

	-- 	-- data = selectionData
	-- 	-- totaldmg = selectionData.totalValueSum
	-- else
	-- 	data = fightData.calculated
	-- 	totaldmg = data[totalAmountKey]
	-- end

	-- local scrollchild = GetControl(control, "PanelScrollChild")
	-- local currentanchor = { TOPLEFT, scrollchild, TOPLEFT, 0, 1 }

	-- local totalHitKey = showOverHeal and "healsOutAbsolute" or countString .. totalkey
	-- local critKey = showOverHeal and "healsOutOverflow"
	-- 	or hitCritLayoutId > 3 and countString .. "Blocked"
	-- 	or countString .. "Critical"

	-- local ratioKey1 = showOverHeal and "healsOutOverflow" or countString .. hitCritLayout[1] -- first value of the crits/hits column display
	-- local ratioKey2 = showOverHeal and "healsOutAbsolute" or countString .. hitCritLayout[2] -- second value of the crits/hits column display

	-- local avgKey1 = showOverHeal and "healingOutAbsolute" or category .. averageLayout[1] -- damage value of the avg column display
	-- local avgKey2 = showOverHeal and "healsOutAbsolute" or countString .. averageLayout[1] -- hits value of the avg column display

	-- local DPSKey = showOverHeal and "HPSAOut" or DPSstrings[category]

	-- local showids = settings.showDebugIds

	-- for abilityId, ability in
	-- 	util.spairs(data[category], function(t, a, b)
	-- 		return t[a][totalAmountKey] > t[b][totalAmountKey]
	-- 	end)
	-- do
	-- 	if ability[totalAmountKey] > 0 then
	-- 		local highlight = false

	-- 		if selectedabilities ~= nil then
	-- 			highlight = selectedabilities[abilityId] ~= nil
	-- 		end

	-- 		local icon = GetFormattedAbilityIcon(abilityId)

	-- 		local duration = GetAbilityDuration(abilityId)

	-- 		local dot = ((duration and duration > 0) or (IsAbilityPassive(abilityId) and isDamage)) and "*" or ""
	-- 		local pet = ability.pet and " (pet)" or ""
	-- 		local dbug = showids and string.format("(%d) ", abilityId) or ""
	-- 		local color = ability.damageType and CMX.GetDamageColor(ability.damageType) or ""

	-- 		local name = dbug .. color .. (ability.name or GetFormattedAbilityName(abilityId)) .. dot .. pet .. "|r"

	-- 		local dps = ability[DPSKey]
	-- 		local total = ability[totalAmountKey]
	-- 		local ratio = total and totaldmg and totaldmg > 0 and (total / totaldmg)

	-- 		local crits = ability[critKey]
	-- 		local hits = ability[totalHitKey]
	-- 		local critratio = crits and hits and hits > 0 and (100 * crits / hits)

	-- 		local ratio1 = ability[ratioKey1]
	-- 		local ratio2 = ability[ratioKey2]

	-- 		local avg1 = ability[avgKey1]
	-- 		local avg2 = ability[avgKey2] or 0

	-- 		local avg = avg2 ~= 0 and (avg1 / avg2)
	-- 		local minmaxValue = (showOverHeal and "-") or (minmax and ability.max) or (ability.min or 0)

	-- 		local rowId = #control.bars + 1

	-- 		local rowName = scrollchild:GetName() .. "Row" .. rowId
	-- 		local row = _G[rowName]
	-- 			or CreateControlFromVirtual(rowName, scrollchild, "CombatMetrics_AbilityRowTemplate")
	-- 		row:SetAnchor(unpack(currentanchor))
	-- 		row:SetHidden(false)

	-- 		adjustRowSize(row, header)

	-- 		local highlightControl = row:GetNamedChild("HighLight")
	-- 		highlightControl:SetHidden(not highlight)

	-- 		local iconControl = row:GetNamedChild("Icon")
	-- 		iconControl:SetTexture(icon)

	-- 		local nameControl = row:GetNamedChild("Name")
	-- 		nameControl:SetText(name)
	-- 		local maxwidth = nameControl:GetWidth()

	-- 		local barControl = row:GetNamedChild("Bar")
	-- 		barControl:SetWidth(maxwidth * ratio)

	-- 		local fractionControl = row:GetNamedChild("Fraction")
	-- 		fractionControl:SetText(ratio and string.format("%.1f%%", 100 * ratio) or "-")

	-- 		local rateControl = row:GetNamedChild("PerSecond")
	-- 		rateControl:SetText(dps and string.format("%.0f", dps) or "-")

	-- 		local amountControl = row:GetNamedChild("Total")
	-- 		amountControl:SetText(total or "-")

	-- 		local critControl = row:GetNamedChild("Crits")
	-- 		critControl:SetText(ratio1 or "-")

	-- 		local hitsControl = row:GetNamedChild("Hits")
	-- 		hitsControl:SetText(string.format("/%d", ratio2 or "-"))

	-- 		local critFractionControl = row:GetNamedChild("CritRatio")
	-- 		critFractionControl:SetText(critratio and string.format("%.0f%%", critratio) or "-")

	-- 		local avgControl = row:GetNamedChild("Average")
	-- 		avgControl:SetText(avg and string.format("%.0f", avg) or "-")

	-- 		local maxControl = row:GetNamedChild("MinMax")
	-- 		maxControl:SetText(minmaxValue)

	-- 		currentanchor = { TOPLEFT, row, BOTTOMLEFT, 0, ui.dx }

	-- 		control.bars[rowId] = row

	-- 		row.dataId = abilityId
	-- 		row.type = "ability"
	-- 		row.id = rowId
	-- 		row.panel = control
	-- 	end
	-- end
end

local isFileInitialized = false
function CMXint.InitializeAbilities()
	if isFileInitialized == true then
		return false
	end
	logger = util.initSublogger("Abilities")

	isFileInitialized = true
	return true
end
