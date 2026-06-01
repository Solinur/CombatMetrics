-- Combat stats panel: Damage and healing stats.
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

local ROW_KEY_FORMAT = "<<1>>Row<<2>>Value"
local higlightColor = ZO_ColorDef:New("FFFFFFCC")
local DPSLabelText = GetString(SI_COMBAT_METRICS_DPS) .. ":"

local ZERO = "0"
local ZERO_SECONDS = "0.000 s"
local ZERO_PER_CENT = "0.0 %"

local VALUE_FORMAT = "%.0f"
local PERCENT_FORMAT = "%.1f%%"

local DAMAGE_KEYS = {
	"total",
	"normal",
	"critical",
	"blocked",
	"absorbed",
}

local AMOUNT_DAMAGE_KEYS = {}
for i, key in ipairs(DAMAGE_KEYS) do
	AMOUNT_DAMAGE_KEYS[i] = key .. "Amount"
end

local COUNT_DAMAGE_KEYS = {}
for i, key in ipairs(DAMAGE_KEYS) do
	COUNT_DAMAGE_KEYS[i] = key .. "Count"
end

local HEALING_KEYS = {
	"total",
	"normal",
	"critical",
	"overflow",
	"absorbed",
}

local AMOUNT_HEALING_KEYS = {}
for i, key in ipairs(HEALING_KEYS) do
	AMOUNT_HEALING_KEYS[i] = key .. "Amount"
end

local COUNT_HEALING_KEYS = {}
for i, key in ipairs(HEALING_KEYS) do
	COUNT_HEALING_KEYS[i] = key .. "Count"
end

function CMXint.InitializeCombatStatsPanel(control)
	---@class CombatStatsPanel: Panel
	CombatStatsPanel = CMX.internal.PanelObject:New(control, "combatStats")
	CombatStatsPanel.scenes = { "fightStats" }

	function CombatStatsPanel:Recover()
		logger:Info("CombatStatsPanel:Recover")

		self.sharedControls = {}

		self.xOffset = 4
		self.yOffset = 4
		self.maxHeight = 0

		self:RecoverTimeControls()
		self:RecoverDPSControls()
		self:RecoverStatBlock("amount")
		self:RecoverStatBlock("count")
	end

	function CombatStatsPanel:RecoverTimeControls()
		self.activeTimeLabel = self:AddLabel(86, true)
		self.activeTimeLabel:SetColor(higlightColor:UnpackRGBA())
		self.activeTimeValue = self:AddLabel(76, true)
		self.activeTimeValue:SetColor(higlightColor:UnpackRGBA())
		self.combatTimeLabel = self:AddLabel(86, true)
		self.combatTimeValue = self:AddLabel(76, true)
		self:NewLine()

		local separator = self:AcquireSharedControl(CT_LINE)
		separator:ApplyPosition(control, self.xOffset, self.yOffset, 336, 0)
		self:NewLine()
	end

	function CombatStatsPanel:RecoverDPSControls()
		self.xOffset = 120
		self.dpsHeader1 = self:AddLabel(78, true)
		self.dpsHeader1:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
		self.dpsHeader2 = self:AddLabel(78, true)
		self.dpsHeader2:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
		self.dpsHeader3 = self:AddLabel(52, true)
		self.dpsHeader3:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
		self:NewLine()

		self.xOffset = 120
		local separator = self:AcquireSharedControl(CT_LINE)
		separator:ApplyPosition(control, self.xOffset, self.yOffset, 216, 0)
		self:NewLine()

		self.dpsLabel = self:AddLabel(116, true)
		self.dpsValue1 = self:AddLabel(78, true)
		self.dpsValue1:SetColor(higlightColor:UnpackRGBA())
		self.dpsValue2 = self:AddLabel(78)
		self.dpsValue3 = self:AddLabel(52)
		self:NewLine()
	end

	function CombatStatsPanel:RecoverStatBlock(key)
		local header = self:AddLabel(116, true)
		header:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
		self[key .. "Label"] = header
		self:NewLine()

		---@type LineControl|SharedControl
		local separator = self:AcquireSharedControl(CT_LINE)
		separator:ApplyPosition(control, self.xOffset, self.yOffset, 336, 0)
		self:NewLine()

		for rowId = 1, 5 do
			self:RecoverStatBlockRow(key, rowId)
		end
	end

	function CombatStatsPanel:RecoverStatBlockRow(key, rowId, isHeader)
		local row_key = ZO_CachedStrFormat(ROW_KEY_FORMAT, key, rowId)

		self[row_key .. "1"] = self:AddLabel(116, true)
		self[row_key .. "2"] = self:AddLabel(78)
		self[row_key .. "3"] = self:AddLabel(78)
		self[row_key .. "4"] = self:AddLabel(52)

		self:NewLine()
	end

	function CombatStatsPanel:AddLabel(width, bold)
		---@type LabelControl|SharedControl
		local label = self:AcquireSharedControl(CT_LABEL)
		label:ApplyPosition(control, self.xOffset, self.yOffset, width, nil)

		local font = ui.GetFont(ui.fontSize, bold)
		label:SetFont(font)
		label:SetText("-")
		label:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

		self.xOffset = self.xOffset + 4 + width
		local scale = self.settings.scale > 0 and self.settings.scale or 1
		self.maxHeight = zo_max(self.maxHeight, label:GetHeight() / scale)

		return label
	end

	function CombatStatsPanel:NewLine()
		self.yOffset = self.yOffset + self.maxHeight + 4
		self.maxHeight = 0
		self.xOffset = 4
	end

	function CombatStatsPanel:ClearTimeStats()
		self.activeTimeValue:SetText(ZERO_SECONDS)
		self.combatTimeValue:SetText(ZERO_SECONDS)
	end

	function CombatStatsPanel:ClearDPSStats()
		self.dpsValue1:SetText(ZERO)
		self.dpsValue2:SetText(ZERO)
		self.dpsValue3:SetText(ZERO_PER_CENT)

		self.dpsValue1:SetText(ZERO)
		self.dpsValue2:SetText(ZERO)
		self.dpsValue3:SetText(ZERO_PER_CENT)

		for rowId = 1, 5 do
			local amount_key = ZO_CachedStrFormat(ROW_KEY_FORMAT, "amount", rowId)
			local count_key = ZO_CachedStrFormat(ROW_KEY_FORMAT, "count", rowId)

			self[amount_key .. "2"]:SetText(ZERO)
			self[amount_key .. "3"]:SetText(ZERO)
			self[amount_key .. "4"]:SetText(ZERO_PER_CENT)

			self[count_key .. "2"]:SetText(ZERO)
			self[count_key .. "3"]:SetText(ZERO)
			self[count_key .. "4"]:SetText(ZERO_PER_CENT)
		end
	end

	function CombatStatsPanel:Clear()
		self:UpdateLabels()
		self:ClearTimeStats()
		self:ClearDPSStats()
	end

	function CombatStatsPanel:GetLabelStrings()
		local category = self.settings.category

		if util.IsDamageCategory() then
			local amountLabel = SI_COMBAT_METRICS_DAMAGE
			local countLabel = SI_COMBAT_METRICS_HIT

			local labelList = {
				SI_COMBAT_METRICS_TOTALC,
				SI_COMBAT_METRICS_NORMAL,
				SI_COMBAT_METRICS_CRITICAL,
				SI_COMBAT_METRICS_BLOCKED,
				SI_COMBAT_METRICS_SHIELDED,
			}
			return amountLabel, countLabel, labelList
		end

		if util.IsHealingCategory() then
			local amountLabel = SI_COMBAT_METRICS_HEALING
			local countLabel = SI_COMBAT_METRICS_HEALS

			local labelList = {
				SI_COMBAT_METRICS_TOTALC,
				SI_COMBAT_METRICS_NORMAL,
				SI_COMBAT_METRICS_CRITICAL,
				SI_COMBAT_METRICS_OVERHEAL,
				SI_COMBAT_METRICS_ABSOLUTE,
			}
			return amountLabel, countLabel, labelList
		end

		logger:Error("unexpected value for category: %s", category)
	end

	function CombatStatsPanel:UpdateLabels()
		self.activeTimeLabel:SetText(GetString(SI_COMBAT_METRICS_ACTIVE_TIME))
		self.combatTimeLabel:SetText(GetString(SI_COMBAT_METRICS_IN_COMBAT))

		-- Add DPS label ? If yes, consider Overheal!

		local isSelectionActive = CMXint.IsSelectionActive()
		self.dpsLabel:SetText(DPSLabelText)
		self.dpsHeader1:SetText(
			GetString(isSelectionActive and SI_COMBAT_METRICS_SELECTION or SI_COMBAT_METRICS_PLAYER)
		)
		self.dpsHeader2:SetText(GetString(isSelectionActive and SI_COMBAT_METRICS_TOTAL or SI_COMBAT_METRICS_GROUP))
		self.dpsHeader3:SetText("%")

		local amountLabel, countLabel, labelList = self:GetLabelStrings()

		self["amountLabel"]:SetText(GetString(amountLabel))
		self["countLabel"]:SetText(GetString(countLabel))

		for rowId = 1, 5 do
			local amount_key = ZO_CachedStrFormat(ROW_KEY_FORMAT, "amount", rowId)
			local count_key = ZO_CachedStrFormat(ROW_KEY_FORMAT, "count", rowId)

			self[amount_key .. "1"]:SetText(GetString(labelList[rowId]))
			self[count_key .. "1"]:SetText(GetString(labelList[rowId]))
		end
	end

	---@param fightData Fight
	function CombatStatsPanel:UpdateTimeStats(fightData)
		local categoryData = self:GetCurrentCategoryCombatData()

		if categoryData == nil then
			self:ClearTimeStats()
			return
		end

		local playerId = fightData.unitIds.player
		local playerData = categoryData[playerId]

		if playerData == nil then
			self:ClearTimeStats()
			return
		end

		local fightInfoData = fightData.info
		local activeTime = zo_round(playerData.endTime - playerData.startTime) / 1000
		local combatTime = zo_round(fightInfoData.combatEnd - fightInfoData.combatStart) / 1000

		local activeTimeString, combatTimeString
		if activeTime < 60 and combatTime < 60 then
			combatTimeString = string.format("%.3f s", combatTime % 60)
			activeTimeString = string.format("%.3f s", activeTime % 60)
		else
			activeTimeString = string.format("%d:%06.3f", activeTime / 60, activeTime % 60)
			combatTimeString = string.format("%d:%06.3f", combatTime / 60, combatTime % 60)
		end

		self.activeTimeValue:SetText(activeTimeString)
		self.combatTimeValue:SetText(combatTimeString)
	end

	---@param fightData Fight
	function CombatStatsPanel:UpdateCombatStatValues(fightData)
		local category = self.settings.category

		local aps1, aps2, apsratio, amountValueKeys, countValueKeys

		local unitsPanel = ui.panels["units"]
		local unitSel = unitsPanel and unitsPanel:GetSelections()
		local unitIds = (unitSel and unitSel.active) and unitSel:GetAll() or nil

		local abilitiesPanel = ui.panels["abilities"]
		local abilitySel = abilitiesPanel and abilitiesPanel:GetSelections()
		local abilityIds = (abilitySel and abilitySel.active) and abilitySel.selectedItems or nil

		local isSelectionActive = unitIds ~= nil or abilityIds ~= nil
		local partialData = util.GetCombinedPlayerCategoryData(fightData, category, unitIds, abilityIds)
		local fullData = isSelectionActive and util.GetCombinedPlayerCategoryData(fightData, category)
			or util.GetCombinedGroupCategoryData(fightData, category)
		---@cast fullData -nil

		if util.IsDamageCategory() then
			amountValueKeys = AMOUNT_DAMAGE_KEYS
			countValueKeys = COUNT_DAMAGE_KEYS
		elseif util.IsHealingCategory() then
			amountValueKeys = AMOUNT_HEALING_KEYS
			countValueKeys = COUNT_HEALING_KEYS
		else
			logger:Error("unexpected value for category: %s", category)
			return
		end

		local partialValue, fullValue
		if category == cat.CMX_CATEGORY_HEALING_DONE and self.settings.showOverHeal then
			partialValue = partialData and (partialData.totalAmount + partialData.overflowAmount) or 0
			fullValue = fullData.totalAmount + fullData.overflowAmount
		else
			partialValue = partialData and partialData.totalAmount or 0
			fullValue = fullData.totalAmount
		end

		-- When a selection is active, fullData holds the unfiltered player data; use its time
		-- range so the per-second value isn't inflated by the narrower filtered window.
		local partialTime = isSelectionActive
			and (fullData.endTime - fullData.startTime)
			or (partialData and (partialData.endTime - partialData.startTime) or 0)
		local fullTime = fullData.endTime - fullData.startTime

		aps1 = util.SafeDivide(partialValue, partialTime / 1000)
		aps2 = util.SafeDivide(fullValue, fullTime / 1000)
		apsratio = fullValue > 0 and partialValue / fullValue * 100 or 0

		self.dpsValue1:SetText(string.format(VALUE_FORMAT, aps1))
		self.dpsValue2:SetText(string.format(VALUE_FORMAT, aps2))
		self.dpsValue3:SetText(string.format(PERCENT_FORMAT, apsratio))

		for rowId = 1, 5 do
			local amount_key = ZO_CachedStrFormat(ROW_KEY_FORMAT, "amount", rowId)
			local count_key = ZO_CachedStrFormat(ROW_KEY_FORMAT, "count", rowId)

			local amountValueKey = amountValueKeys[rowId]
			local countValueKey = countValueKeys[rowId]

			local partialAmount = partialData and partialData[amountValueKey] or 0
			local fullAmount = fullData[amountValueKey] or 0
			local partialCount = partialData and partialData[countValueKey] or 0
			local fullCount = fullData[countValueKey] or 0
			local amountPercent = fullAmount > 0 and (partialAmount / fullAmount) * 100 or 0
			local countPercent = fullCount > 0 and (partialCount / fullCount) * 100 or 0

			self[amount_key .. "2"]:SetText(string.format(VALUE_FORMAT, partialAmount))
			self[amount_key .. "3"]:SetText(string.format(VALUE_FORMAT, fullAmount))
			self[amount_key .. "4"]:SetText(string.format(PERCENT_FORMAT, amountPercent))

			self[count_key .. "2"]:SetText(string.format(VALUE_FORMAT, partialCount))
			self[count_key .. "3"]:SetText(string.format(VALUE_FORMAT, fullCount))
			self[count_key .. "4"]:SetText(string.format(PERCENT_FORMAT, countPercent))
		end
	end

	function CombatStatsPanel:Update()
		local fightData = self:GetCurrentFightData()
		if fightData == nil then error("CombatStatsPanel:Update() called without active fight data", 2) end
		self:UpdateLabels()
		self:UpdateTimeStats(fightData)
		self:UpdateCombatStatValues(fightData)
	end

	CMX_COMBAT_PANEL = CombatStatsPanel
end

local isFileInitialized = false
function CMXint.InitializeCombatStats()
	if isFileInitialized == true then
		return false
	end
	logger = util.initSublogger("CombatStats")
	isFileInitialized = true
	return true
end
