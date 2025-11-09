local CMX = CombatMetrics
local CMXint = CMX.internal
local util = CMXint.util
local ui = CMXint.ui
local logger

local CountStrings = CMXint.CountStrings
local DPSstrings = CMXint.DPSstrings

local ROW_KEY_FORMAT = "<<1>>Row<<2>>Value"
local higlightColor = ZO_ColorDef:New("FFFFFFCC")
local DPSLabelText = GetString(SI_COMBAT_METRICS_DPS)..":"

local ZERO = "0"
local ZERO_SECONDS = "0.000 s"
local ZERO_PER_CENT = "0.0 %"

function CMXint.InitializeCombatStatsPanel(control)
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

		for rowId = 1,5 do
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
		self.maxHeight = zo_max(self.maxHeight, label:GetHeight()/self.settings.scale)

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
				SI_COMBAT_METRICS_SHIELDED 
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
				SI_COMBAT_METRICS_ABSOLUTEC
			}
			return amountLabel, countLabel, labelList
		end

		logger:Error("unexpected value for category: %s", category)
	end

	function CombatStatsPanel:UpdateLabels()
		local category = self.settings.category

		self.activeTimeLabel:SetText(GetString(SI_COMBAT_METRICS_ACTIVE_TIME))
		self.combatTimeLabel:SetText(GetString(SI_COMBAT_METRICS_IN_COMBAT))

		local SecondaryColumnHeader = CMXint.IsSelectionActive() and SI_COMBAT_METRICS_SELECTION or SI_COMBAT_METRICS_GROUP

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



	-- function CombatStatsPanel:Update(fightData)

	-- 	local data = fightData and fightData.calculated or {}
	-- 	local settings = self.settings
	-- 	local category = settings.category

	-- 	local selectedabilities = ui.selections["ability"][category]
	-- 	local selectedunits = ui.selections["unit"][category]
	-- 	local noselection = selectedunits == nil and selectedabilities == nil

	-- 	local header2 = control:GetNamedChild("StatHeaderLabel2")
	-- 	local headerstring = noselection and SI_COMBAT_METRICS_GROUP or SI_COMBAT_METRICS_SELECTION
	-- 	header2:SetText(GetString(headerstring))

	-- 	local label1, label2, label3, rowList, labelList
	-- 	local activetime
	-- 	local showOverHeal = category == "healingOut" and CMX.showOverHeal

	-- 	if category == "healingOut" or category == "healingIn" then
	-- 		label1 = GetString(showOverHeal and SI_COMBAT_METRICS_HPSA or SI_COMBAT_METRICS_HPS)
	-- 		label2 = GetString(SI_COMBAT_METRICS_HEALING)
	-- 		label3 = GetString(SI_COMBAT_METRICS_HEALS)

	-- 		rowList = { "Total", "Normal", "Critical", "Overflow", "Absolute" }
	-- 		labelList = { SI_COMBAT_METRICS_TOTALC, SI_COMBAT_METRICS_NORMAL, SI_COMBAT_METRICS_CRITICAL,
	-- 			SI_COMBAT_METRICS_OVERHEAL, SI_COMBAT_METRICS_ABSOLUTEC }

	-- 		activetime = fightData and fightData.hpstime or 1
	-- 	else
	-- 		label1 = GetString(SI_COMBAT_METRICS_DPS)
	-- 		label2 = GetString(SI_COMBAT_METRICS_DAMAGE)
	-- 		label3 = GetString(SI_COMBAT_METRICS_HIT)

	-- 		rowList = { "Total", "Normal", "Critical", "Blocked", "Shielded" }
	-- 		labelList = { SI_COMBAT_METRICS_TOTALC, SI_COMBAT_METRICS_NORMAL, SI_COMBAT_METRICS_CRITICAL,
	-- 			SI_COMBAT_METRICS_BLOCKED, SI_COMBAT_METRICS_SHIELDED }

	-- 		activetime = fightData and fightData.dpstime or 1
	-- 	end

	-- 	activetime = zo_roundToNearest(activetime, 0.01)
	-- 	local activetimestring = string.format("%d:%05.2f", activetime / 60, activetime % 60)
	-- 	local dpsRow = control:GetNamedChild("StatRowAPS")

	-- 	dpsRow:GetNamedChild("Label"):SetText(label1)                             -- DPS or HPS
	-- 	control:GetNamedChild("StatTitleAmount"):GetNamedChild("Label"):SetText(label2) -- Damage or Healing
	-- 	control:GetNamedChild("StatTitleCount"):GetNamedChild("Label"):SetText(label3) -- Hits or Heals

	-- 	local combattime = zo_roundToNearest(fightData and fightData.combattime or 1, 0.01)
	-- 	local combattimestring = string.format("%d:%05.2f", combattime / 60, combattime % 60)

	-- 	control:GetNamedChild("ActiveTimeValue"):SetText(activetimestring)
	-- 	control:GetNamedChild("CombatTimeValue"):SetText(combattimestring)

	-- 	local key = showOverHeal and "HPSAOut" or DPSstrings[category]

	-- 	local aps1 = data[key] or 0
	-- 	local aps2, apsratio

	-- 	local selectionData = util.GetSelectionData()
	-- 	if not noselection or showOverHeal then
	-- 		aps2 = selectionData and selectionData[key] or 0
	-- 		apsratio = (aps1 == 0 and 0) or aps2 / aps1 * 100
	-- 	else
	-- 		local groupkey = zo_strformat("group<<C:1>>", key)
	-- 		aps2 = data[groupkey] or 0
	-- 		apsratio = (aps2 == 0 and 0) or aps1 / aps2 * 100
	-- 	end

	-- 	dpsRow:GetNamedChild("Value"):SetText(string.format("%.0f", aps1))
	-- 	dpsRow:GetNamedChild("Value2"):SetText(string.format("%.0f", aps2))
	-- 	dpsRow:GetNamedChild("Value3"):SetText(string.format("%.1f%%", apsratio))

	-- 	for k, v in ipairs(rowList) do
	-- 		local rowcontrol1 = control:GetNamedChild("StatRowAmount" .. k)
	-- 		local rowcontrol2 = control:GetNamedChild("StatRowCount" .. k)

	-- 		local amountlabel = rowcontrol1:GetNamedChild("Label")
	-- 		amountlabel:SetText(GetString(labelList[k]))
	-- 		local amountcontrol1 = rowcontrol1:GetNamedChild("Value")
	-- 		local amountcontrol2 = rowcontrol1:GetNamedChild("Value2")
	-- 		local amountcontrol3 = rowcontrol1:GetNamedChild("Value3")

	-- 		local countlabel     = rowcontrol2:GetNamedChild("Label")
	-- 		countlabel:SetText(GetString(labelList[k]))
	-- 		local countcontrol1 = rowcontrol2:GetNamedChild("Value")
	-- 		local countcontrol2 = rowcontrol2:GetNamedChild("Value2")
	-- 		local countcontrol3 = rowcontrol2:GetNamedChild("Value3")

	-- 		local hide2 = false
	-- 		local hide3 = false
	-- 		local hide4 = false

	-- 		if v then
	-- 			local amountkey = category .. v
	-- 			local countkey = CountStrings[category] .. v
	-- 			local basekey

	-- 			if v == "Overflow" or v == "Absolute" then basekey = "Absolute" else basekey = rowList[1] end

	-- 			local amount1 = data[amountkey] or 0
	-- 			local amount2 = 0
	-- 			local amount3 = data[category .. basekey] or 0
	-- 			local amountratio = 0

	-- 			local count1 = data[countkey] or 0
	-- 			local count2 = 0
	-- 			local count3 = data[CountStrings[category] .. basekey] or 0
	-- 			local countratio = 0

	-- 			local groupAmountKey = zo_strformat("group<<C:1>>", category)

	-- 			if k == 1 and noselection then
	-- 				amount2 = data[groupAmountKey] or 0 -- first letter of category needs to be Capitalized
	-- 				amountratio = (amount2 == 0 and 0) or amount1 / amount2 * 100
	-- 				hide2 = true
	-- 			elseif noselection and v == "Absolute" then
	-- 				amount2 = data[groupAmountKey] or 0 -- first letter of category needs to be Capitalized
	-- 				amountratio = (amount2 == 0 and 0) or amount1 / amount2 * 100
	-- 				hide4 = true
	-- 			elseif noselection then
	-- 				hide3 = true
	-- 				amountratio = (amount3 == 0 and 0) or amount1 / amount3 * 100
	-- 				countratio = (count3 == 0 and 0) or count1 / count3 * 100
	-- 			elseif noselection == false then
	-- 				if (k ~= 1 and v ~= "Absolute") then
	-- 					amount3 = selectionData[category .. basekey] or 0
	-- 					count3 = selectionData[CountStrings[category] .. basekey] or 0
	-- 				end

	-- 				amount2 = selectionData[amountkey] or 0
	-- 				amountratio = (amount3 == 0 and 0) or amount2 / amount3 * 100

	-- 				count2 = selectionData[countkey] or 0
	-- 				countratio = (count3 == 0 and 0) or count2 / count3 * 100
	-- 			end

	-- 			amountcontrol1:SetText(string.format("%.0f", amount1))
	-- 			amountcontrol2:SetText(string.format("%.0f", amount2))
	-- 			amountcontrol3:SetText(string.format("%.1f%%", amountratio))

	-- 			countcontrol1:SetText(string.format("%.0f", count1))
	-- 			countcontrol2:SetText(string.format("%.0f", count2))
	-- 			countcontrol3:SetText(string.format("%.1f%%", countratio))
	-- 		end

	-- 		amountcontrol2:SetHidden(hide3 or hide4)
	-- 		amountcontrol3:SetHidden(hide4)

	-- 		countcontrol2:SetHidden(hide3 or hide2)
	-- 		countcontrol3:SetHidden(hide2)
	-- 	end
	-- end
end

local isFileInitialized = false
function CMXint.InitializeCombatStats()
	if isFileInitialized == true then return false end
	logger = util.initSublogger("CombatStats")
	isFileInitialized = true
	return true
end
