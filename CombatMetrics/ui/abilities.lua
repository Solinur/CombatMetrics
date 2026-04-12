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

local CRIT_LAYOUT_RATIO = 1
local CRIT_LAYOUT_REVERSED = 2
local CRIT_LAYOUT_NORMAL_RATIO = 3

local critLayoutTable = {
	[CRIT_LAYOUT_RATIO] = {
		"Critical",
		"Total",
		GetString(SI_COMBAT_METRICS_CRITS) .. "/",
		GetString(SI_COMBAT_METRICS_HITS),
	},
	[CRIT_LAYOUT_REVERSED] = {
		"Total",
		"Critical",
		GetString(SI_COMBAT_METRICS_HITS) .. "/",
		GetString(SI_COMBAT_METRICS_CRITS),
	},
	[CRIT_LAYOUT_NORMAL_RATIO] = {
		"Normal",
		"Critical",
		GetString(SI_COMBAT_METRICS_NORM) .. "/",
		GetString(SI_COMBAT_METRICS_CRITS),
	},
}

local BLOCKED_LAYOUT_RATIO = 1
local BLOCKED_LAYOUT_REVERSED = 2
local BLOCKED_LAYOUT_NORMAL_RATIO = 3

local blockedLayoutTable = {
	[BLOCKED_LAYOUT_RATIO] = {
		"Blocked",
		"Total",
		GetString(SI_COMBAT_METRICS_BLOCKS) .. "/",
		GetString(SI_COMBAT_METRICS_HITS),
	},
	[BLOCKED_LAYOUT_REVERSED] = {
		"Total",
		"Blocked",
		GetString(SI_COMBAT_METRICS_HITS) .. "/",
		GetString(SI_COMBAT_METRICS_BLOCKS),
	},
	[BLOCKED_LAYOUT_NORMAL_RATIO] = {
		"Normal",
		"Blocked",
		GetString(SI_COMBAT_METRICS_NORM) .. "/",
		GetString(SI_COMBAT_METRICS_BLOCKS),
	},
}

local AVERAGE_LAYOUT_TOTAL = 1
local AVERAGE_LAYOUT_NORMAL = 2
local AVERAGE_LAYOUT_CRITICAL = 3
local AVERAGE_LAYOUT_BLOCKED = 3

local averageLayoutTable = {
	[AVERAGE_LAYOUT_TOTAL] = { "Total", GetString(SI_COMBAT_METRICS_AVE), GetString(SI_COMBAT_METRICS_HITS) },
	[AVERAGE_LAYOUT_NORMAL] = {
		"Normal",
		GetString(SI_COMBAT_METRICS_AVE_N),
		GetString(SI_COMBAT_METRICS_NORMAL_HITS),
	},
	[AVERAGE_LAYOUT_CRITICAL] = { "Critical", GetString(SI_COMBAT_METRICS_AVE_C), GetString(SI_COMBAT_METRICS_CRITS) },
}

local averageBlockedLayoutTable = {
	[AVERAGE_LAYOUT_TOTAL] = averageLayoutTable[AVERAGE_LAYOUT_TOTAL],
	[AVERAGE_LAYOUT_NORMAL] = averageLayoutTable[AVERAGE_LAYOUT_NORMAL],
	[AVERAGE_LAYOUT_BLOCKED] = { "Blocked", GetString(SI_COMBAT_METRICS_AVE_B), GetString(SI_COMBAT_METRICS_BLOCKS) },
}

local minMaxLayoutTable = {
	[true] = { "max", GetString(SI_COMBAT_METRICS_MAX) },
	[false] = { "min", GetString(SI_COMBAT_METRICS_MIN) },
}

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

		--[[
		TODO: consider rearranging columns: 
			* Merge Min/Max/Avg? 
			* Reorder % / DPS ? 
			* Remove hit/crit and show as TT on ratio instead (format via settings)?
			* Show tick rate ? 
		]]

		local icon = panel:AcquireSharedControl(CT_TEXTURE)
		icon:ApplyPosition(rowControl, 2, 0, rowHeight, rowHeight)

		local label = panel:AcquireSharedControl(CT_LABEL)
		label:ApplyPosition(rowControl, 28, 0, 190)
		label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

		local bar = panel:AcquireSharedControl(CT_TEXTURE)
		bar:ApplyPosition(rowControl, 26, 0, 194, rowHeight)
		bar:SetTexture("esoui/art/unitframes/progressbar_raidhealth.dds")

		local fraction = panel:AcquireSharedControl(CT_LABEL)
		fraction:ApplyPosition(rowControl, 220, 0, 38)
		fraction:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

		local perSecond = panel:AcquireSharedControl(CT_LABEL)
		perSecond:ApplyPosition(rowControl, 260, 0, 50)
		perSecond:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

		local total = panel:AcquireSharedControl(CT_LABEL)
		total:ApplyPosition(rowControl, 312, 0, 73)
		total:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

		local crits = panel:AcquireSharedControl(CT_LABEL)
		crits:ApplyPosition(rowControl, 387, 0, 46)
		crits:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

		local hits = panel:AcquireSharedControl(CT_LABEL)
		hits:ApplyPosition(rowControl, 433, 0, 42)
		hits:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

		local critRatio = panel:AcquireSharedControl(CT_LABEL)
		critRatio:ApplyPosition(rowControl, 477, 0, 37)
		critRatio:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

		local averageHit = panel:AcquireSharedControl(CT_LABEL)
		averageHit:ApplyPosition(rowControl, 516, 0, 50)
		averageHit:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

		local minMax = panel:AcquireSharedControl(CT_LABEL)
		minMax:ApplyPosition(rowControl, 568, 0, 50)
		minMax:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

		rowControl.controls =
			{ icon, label, bar, fraction, perSecond, total, crits, hits, critRatio, averageHit, minMax }
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

		local icon, label, bar, fraction, perSecond, total, crits, hits, critRatio, averageHit, minMax =
			unpack(rowControl.controls)

		---@cast icon TextureControl
		local iconTexture = data.icon
		icon:SetHidden(iconTexture == nil)
		if iconTexture then
			icon:SetTexture(iconTexture)
		end

		---@cast label LabelControl
		local font = ui.GetFont(ui.fontSize, false)
		label:SetText(data.name)
		label:SetFont(font)

		---@cast bar TextureControl
		local maxwidth = label:GetWidth()
		bar:SetWidth(maxwidth * data.fraction)
		bar:SetColor(data.color:UnpackRGBA())

		fraction:SetText(string.format("%.0f%%", data.fraction * 100))
		fraction:SetFont(font)

		perSecond:SetText(string.format("%.0f", data.perSecond))
		perSecond:SetFont(font)

		total:SetText(data.amount)
		total:SetFont(font)

		crits:SetText(string.format("%d/", data.ratio1))
		crits:SetFont(font)

		hits:SetText(data.ratio2)
		hits:SetFont(font)

		critRatio:SetText(string.format("%.0f%%", 100 * data.critRatio))
		critRatio:SetFont(font)

		---@cast averageHit LabelControl
		averageHit:SetText(string.format("%.0f", data.average))
		averageHit:SetFont(font)

		---@cast minMax LabelControl
		minMax:SetText(data.minmax)
		minMax:SetFont(font)

		-- TODO: Fix misalignment!
	end

	function dataList:BuildMasterList()
		local fightData = panel:GetCurrentFightData()
		local category = panel.settings.category
		local categoryData = util.GetCombinedPlayerCategoryDataByAbility(fightData, category) -- Add selected units
		local playerId = fightData.unitIds.player
		local playerData = util.GetUnitCategoryData(fightData, category, playerId)

		CMX_ABILITY_PANEL = panel
		CMX_ABILITY_DATA = categoryData

		if categoryData == nil then
			return
		end

		ZO_ClearTable(self.masterList)

		local durationMs = playerData.endTime - playerData.startTime
		local totalAmount = playerData.totalAmount

		for abilityId, abilityData in pairs(categoryData) do
			if type(abilityId) == "number" and type(abilityData) == "table" then
				self:AddDataEntry(abilityId, abilityData, durationMs, totalAmount)
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
	function dataList:AddDataEntry(abilityId, abilityData, durationMs, totalAmount)
		if abilityData.totalAmount <= 0 then
			return
		end

		local settings = panel.settings
		local selected = false -- selectedunits ~= nil and (selectedunits[unitId] ~= nil) or false -- TODO: Selections

		local category = settings.category
		local isOverheal = category == cat.CMX_CATEGORY_HEALING_DONE and settings.includeOverheal
		local amount = isOverheal and abilityData.overflowAmount or abilityData.totalAmount
		local abilityType = util.IsHealingCategory() and abilityData.powerType or abilityData.damageType

		local critLayout = panel:GetRatioLayout()
		local ratio1 = abilityData[ZO_CachedStrFormat("<<c:1>>Count", critLayout[1])]
		local ratio2 = abilityData[ZO_CachedStrFormat("<<c:1>>Count", critLayout[2])]
		local crits = abilityData.criticalCount
		local totalHits = abilityData.totalCount
		local critRatio = util.SafeDivide(crits, totalHits)

		local labelFormat = panel:ShowIds() and abilityId and ABILITY_NAME_FORMAT_ID or ABILITY_NAME_FORMAT_DEFAULT
		local name = ZO_CachedStrFormat(labelFormat, GetFormattedAbilityName(abilityId, false), abilityId)
		local color = GetDamageColor(abilityType)

		if color == nil then
			logger:Warn(
				"No color for damage type %s. Ability: %s (%d)",
				abilityData.damageType or "Unknown",
				GetFormattedAbilityName(abilityId, false),
				abilityId
			)
		end

		local averageLayout = self.panel:GetAverageLayout()
		local averageCount = abilityData[ZO_CachedStrFormat("<<c:1>>Count", averageLayout[1])]
		local averageAmount = abilityData[ZO_CachedStrFormat("<<c:1>>Amount", averageLayout[1])]
		local average = util.SafeDivide(averageAmount, averageCount)

		local minMaxLayout = panel:GetMinMaxLayout()
		local minmax = abilityData[ZO_CachedStrFormat("<<c:1>>", minMaxLayout[1])]

		---@class AbilityRowData
		local rowData = {
			icon = GetFormattedAbilityIcon(abilityId, false),
			name = name,
			color = color,
			fraction = util.SafeDivide(amount, totalAmount),
			perSecond = util.SafeDivide(amount, durationMs / 1000),
			amount = amount,
			ratio1 = ratio1,
			ratio2 = ratio2,
			critRatio = critRatio,
			average = average,
			minmax = minmax,
			selected = selected,
		}

		table.insert(self.masterList, ZO_ScrollList_CreateDataEntry(1, rowData))
	end

	function dataList:FilterScrollList() end

	dataList.sortHeaderGroup:SelectHeaderByKey("amount")

	return dataList
end

function CMXint.InitializeAbilitiesPanel(control)
	---@class AbilityPanel: Panel
	AbilitiesPanel = CMXint.PanelObject:New(control, "abilities")
	AbilitiesPanel.dataList = InitAbilitiesList(AbilitiesPanel)
	AbilitiesPanel.selections = {}

	function AbilitiesPanel:GetRatioLayout()
		local settings = self.settings
		local category = settings.category
		local layoutKey = settings.abilities.hitCritLayout[category]

		local ratioLayoutTable = util.IsDefenseCategory() and blockedLayoutTable or critLayoutTable

		return ratioLayoutTable[layoutKey]
	end

	function AbilitiesPanel:GetAverageLayout()
		local settings = self.settings
		local category = settings.category
		local layoutKey = settings.abilities.averageLayout[category]

		local avgLayoutTable = util.IsDefenseCategory() and averageBlockedLayoutTable or averageLayoutTable

		return avgLayoutTable[layoutKey]
	end

	function AbilitiesPanel:GetMinMaxLayout()
		local settings = self.settings
		local category = settings.category
		local isMax = settings.abilities.maxValue[category]

		return minMaxLayoutTable[isMax]
	end

	function AbilitiesPanel:UpdateHeaderLabels()
		local isDamage = util.IsDamageCategory()
		local isDefense = util.IsDefenseCategory()
		local headers = self.control:GetNamedChild("Headers")

		local perSecondControl = headers:GetNamedChild("PerSecond"):GetNamedChild("Name") --[[@as LabelControl]]
		local perSecondLabel = isDamage and GetString(SI_COMBAT_METRICS_DPS) or GetString(SI_COMBAT_METRICS_HPS)
		perSecondControl:SetText(perSecondLabel)

		local totalControl = headers:GetNamedChild("Total"):GetNamedChild("Name") --[[@as LabelControl]]
		local totalLabel = isDamage and GetString(SI_COMBAT_METRICS_DAMAGE) or GetString(SI_COMBAT_METRICS_HEALING)
		totalControl:SetText(totalLabel)

		local critRatioControl1 = headers:GetNamedChild("Crits") --[[@as LabelControl]]
		local critRatioControl2 = headers:GetNamedChild("Hits") --[[@as LabelControl]]
		local ratioLayoutTable = self:GetRatioLayout()
		critRatioControl1:SetText(ratioLayoutTable[3])
		critRatioControl2:SetText(ratioLayoutTable[4])

		local critPercentControl = headers:GetNamedChild("CritRatio"):GetNamedChild("Name") --[[@as LabelControl]]
		local critPercentString = isDefense and SI_COMBAT_METRICS_BLOCKS_PER or SI_COMBAT_METRICS_CRITS_PER
		critPercentControl:SetText(GetString(critPercentString))

		local avgControl = headers:GetNamedChild("Average"):GetNamedChild("Name") --[[@as LabelControl | TooltipControl]]
		local avgLayoutTable = self:GetAverageLayout()
		avgControl:SetText(avgLayoutTable[2])
		avgControl.tooltip = avgLayoutTable[3]

		local minControl = headers:GetNamedChild("MinMax"):GetNamedChild("Name") --[[@as LabelControl | TooltipControl]]
		local minMaxLayout = self:GetMinMaxLayout()
		minControl:SetText(minMaxLayout[2])
	end

	function AbilitiesPanel:Update()
		logger:Info("Updating Ability Panel")

		self:UpdateHeaderLabels()

		self.dataList:UpdateRowHeight()
		self.dataList:RefreshData()
	end

	function AbilitiesPanel:Clear()
		logger:Info("Clearing Ability Panel")
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
