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

local ROW_KEY_FORMAT = "<<1>>Row<<2>>Value"
local higlightColor = ZO_ColorDef:New("FFFFFFCC")
local DPSLabelText = GetString(SI_COMBAT_METRICS_DPS) .. ":"

local ZERO = "0"
local ZERO_SECONDS = "0.000 s"
local ZERO_PER_CENT = "0.0 %"

local VALUE_FORMAT = "%.0f"
local PERCENT_FORMAT = "%.1f%%"

local FightDataFieldPerCategory = {
	[damageOut] = "damageDone",
	[damageIn] = "damageReceived",
	[healingOut] = "healingDone",
	[healingIn] = "healingReceived",
}

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

---@param unitIds [integer]
local function GetHealData(unitIds) end

function CMXint.InitializeCombatStatsPanel(control)
	---@class CombatStatsPanel: Panel
	CombatStatsPanel = CMX.internal.PanelObject:New(control, "combatStats")

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

		---@type LineControl
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
		---@type LineControl
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

		---@type LineControl
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
		---@type LabelControl
		local label = self:AcquireSharedControl(CT_LABEL)
		label:ApplyPosition(control, self.xOffset, self.yOffset, width, nil)

		local font = ui.GetFont(ui.fontSize, bold)
		label:SetFont(font)
		label:SetText("-")
		label:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

		self.xOffset = self.xOffset + 4 + width
		self.maxHeight = zo_max(self.maxHeight, label:GetHeight() / self.settings.scale)

		return label
	end

	function CombatStatsPanel:NewLine()
		self.yOffset = self.yOffset + self.maxHeight + 4
		self.maxHeight = 0
		self.xOffset = 4
	end

	function CombatStatsPanel:Update(fightData)
		logger:Debug("Updating Combat Stats Panel")
		self:UpdateLabels()
	end

	function CombatStatsPanel:Clear()
		self:UpdateLabels()
		self.activeTimeValue:SetText(ZERO_SECONDS)
		self.combatTimeValue:SetText(ZERO_SECONDS)
		self.dpsValue1:SetText(ZERO)
		self.dpsValue2:SetText(ZERO)
		self.dpsValue3:SetText(ZERO_PER_CENT)

		for rowId = 1, 5 do
			local amount_key = ZO_CachedStrFormat(ROW_KEY_FORMAT, "amount", rowId)
			local count_key = ZO_CachedStrFormat(ROW_KEY_FORMAT, "count", rowId)

			self[amount_key .. "2"]:SetText(ZERO)
			self[count_key .. "2"]:SetText(ZERO)
			self[amount_key .. "3"]:SetText(ZERO)
			self[count_key .. "3"]:SetText(ZERO)
			self[amount_key .. "4"]:SetText(ZERO_PER_CENT)
			self[count_key .. "4"]:SetText(ZERO_PER_CENT)
		end
	end

	function CombatStatsPanel:GetLabelStrings()
		local category = self.settings.category

		if category == "damageOut" or category == "damageIn" then
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

		if category == "healingOut" or category == "healingIn" then
			local amountLabel = SI_COMBAT_METRICS_HEALING
			local countLabel = SI_COMBAT_METRICS_HEALS

			local labelList = {
				SI_COMBAT_METRICS_TOTALC,
				SI_COMBAT_METRICS_NORMAL,
				SI_COMBAT_METRICS_CRITICAL,
				SI_COMBAT_METRICS_OVERHEAL,
				SI_COMBAT_METRICS_ABSOLUTEC,
			}
			return amountLabel, countLabel, labelList
		end

		logger:Error("unexpected value for category: %s", category)
	end

	function CombatStatsPanel:UpdateLabels()
		self.activeTimeLabel:SetText(GetString(SI_COMBAT_METRICS_ACTIVE_TIME))
		self.combatTimeLabel:SetText(GetString(SI_COMBAT_METRICS_IN_COMBAT))

		local SecondaryColumnHeader = CMXint.IsSelectionActive() and SI_COMBAT_METRICS_SELECTION
			or SI_COMBAT_METRICS_GROUP

		-- Add DPS label ? If yes, consider Overheal!

		self.dpsLabel:SetText(DPSLabelText)
		self.dpsHeader1:SetText(GetString(SI_COMBAT_METRICS_PLAYER))
		self.dpsHeader2:SetText(GetString(SecondaryColumnHeader))
		self.dpsHeader3:SetText("%")

		local amountLabel, countLabel, labelList = CombatStatsPanel:GetLabelStrings()

		self.amountLabel:SetText(GetString(amountLabel))
		self.countLabel:SetText(GetString(countLabel))

		for rowId = 1, 5 do
			local amount_key = ZO_CachedStrFormat(ROW_KEY_FORMAT, "amount", rowId)
			local count_key = ZO_CachedStrFormat(ROW_KEY_FORMAT, "count", rowId)

			self[amount_key .. "1"]:SetText(GetString(labelList[rowId]))
			self[count_key .. "1"]:SetText(GetString(labelList[rowId]))
		end
	end

	---@return UnitDamageData|UnitHealData
	function CombatStatsPanel:GetCurrentCategoryCombatData()
		local category = self.settings.category
		local fightData = self:GetCurrentFightData()
		local categoryKey = FightDataFieldPerCategory[category]
		return fightData[category]
	end

	function CombatStatsPanel:UpdateTimeStats()
		local fightInfoData = self:GetCurrentFightData().info
		local data = self:GetCurrentCategoryCombatData()

		local activetime = zo_roundToNearest(data.endTime - data.startTime, 0.001)
		local activetimestring = string.format("%d:%06.3f", activetime / 60, activetime % 60)
		self.activeTimeValue:SetText(activetimestring)

		local combattime = zo_roundToNearest(fightInfoData.combatEnd - fightInfoData.combatStart, 0.001)
		local combattimestring = string.format("%d:%06.3f", combattime / 60, combattime % 60)
		self.combatTimeValue:SetText(combattimestring)
	end

	function CombatStatsPanel:UpdateCombatStatValues()
		local category = self.settings.category
		local fightData = self:GetCurrentFightData()
		local categoryData = self:GetCurrentCategoryCombatData()
		local playerId = fightData.unitIds.player
		local playerData = categoryData[playerId]
		local valueKeys, hitKeys = CombatStatsPanel:GetValueKeys()

		local aps1, aps2, apsratio, amountValueKeys, countValueKeys
		if category == "healingOut" then
			playerData = LibCombat2.GetPlayerHealingDoneToUnits(fight)
			groupData = LibCombat2.GetAllHealingDoneToUnits(fight)
			amountValueKeys = AMOUNT_HEALING_KEYS
			countValueKeys = COUNT_HEALING_KEYS
		elseif category == "healingIn" then
			playerData = LibCombat2.GetPlayerHealingReceivedByUnits(fight)
			groupData = LibCombat2.GetAllHealingReceivedByUnits(fight)
			amountValueKeys = AMOUNT_HEALING_KEYS
			countValueKeys = COUNT_HEALING_KEYS
		elseif category == "damageOut" then
			playerData = LibCombat2.GetPlayerDamageDoneToUnits(fight)
			groupData = LibCombat2.GetAllDamageDoneToUnits(fight)
			amountValueKeys = AMOUNT_DAMAGE_KEYS
			countValueKeys = COUNT_DAMAGE_KEYS
		elseif category == "damageIn" then
			playerData = LibCombat2.GetPlayerDamageReceivedByUnits(fight)
			groupData = LibCombat2.GetAllDamageReceivedByUnits(fight)
			amountValueKeys = AMOUNT_DAMAGE_KEYS
			countValueKeys = COUNT_DAMAGE_KEYS
		else
			logger:Error("unexpected value for category: %s", category)
			return
		end

		if category == "healingOut" and self.settings.includeOverheal then
			playerValue = playerData.totalAmount + playerData.overflowAmount
			groupValue = groupData.totalAmount + groupData.overflowAmount
		else
			playerValue = playerData.totalAmount
			groupValue = groupData.totalAmount
		end

		aps1 = playerValue / playerData.activeTime * 1000
		aps2 = groupValue / groupData.activeTime * 1000
		apsratio = (aps1 / aps2) * 100

		self.dpsValue1:SetText(string.format("%.0f", aps1))
		self.dpsValue2:SetText(string.format("%.0f", aps2))
		self.dpsValue3:SetText(string.format("%.1f%%", apsratio))


		for rowId = 1, 5 do
			local amount_key = ZO_CachedStrFormat(ROW_KEY_FORMAT, "amount", rowId)
			local count_key = ZO_CachedStrFormat(ROW_KEY_FORMAT, "count", rowId)
			local valueKey = ZO_CachedStrFormat(ROW_KEY_FORMAT, "amount", rowId)
			local hitKey = ZO_CachedStrFormat(ROW_KEY_FORMAT, "amount", rowId)

			local playerAmount = playerData[amountValueKeys[rowId]] or 0
			local groupAmount = groupData[amountValueKeys[rowId]] or 0
			local playerCount = playerData[countValueKeys[rowId]] or 0
			local groupCount = groupData[countValueKeys[rowId]] or 0
			local amountPercent = groupAmount > 0 and (playerAmount / groupAmount) * 100 or 0
			local countPercent = groupCount > 0 and (playerCount / groupCount) * 100 or 0

			self[amount_key .. "2"]:SetText(playerAmount)
			self[count_key .. "2"]:SetText(groupAmount)
			self[amount_key .. "3"]:SetText(playerCount)
			self[count_key .. "3"]:SetText(groupCount)
			self[amount_key .. "4"]:SetText(amountPercent)
			self[count_key .. "4"]:SetText(countPercent)
		end
	end

	function CombatStatsPanel:Update()
		self:UpdateTimeStats()
		self:UpdateCombatStatValues
	end
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
