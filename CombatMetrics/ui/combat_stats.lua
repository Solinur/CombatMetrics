local CMX = CombatMetrics
local CMXint = CMX.internal
local util = CMXint.util
local ui = CMXint.ui
local logger

local CountStrings = CMXint.CountStrings
local DPSstrings = CMXint.DPSstrings





function CMXint.InitializeCombatStatsPanel(control)
	CombatStatsPanel = CMX.internal.PanelObject:New(control, "combatStats")

	function CombatStatsPanel:RecoverControls()
		self.sharedControls = {}

		self.activeTimeLabel = self:AcquirePositionedSharedLabel(control, 4, 4, 86, nil)
		self.activeTimeValue = self:AcquirePositionedSharedLabel(control, 94, 4, 76, nil)
		self.combatTimeLabel = self:AcquirePositionedSharedLabel(control, 176, 4, 86, nil)
		self.combatTimeValue = self:AcquirePositionedSharedLabel(control, 266, 4, 76, nil)

		-- add separator

	end

	function CombatStatsPanel:Update(fightData)
		logger:Debug("Updating Combat Stats Panel")

		local data = fightData and fightData.calculated or {}
		local settings = self.settings
		local category = settings.category

		local selectedabilities = CMXint.selections["ability"][category]
		local selectedunits = CMXint.selections["unit"][category]
		local noselection = selectedunits == nil and selectedabilities == nil

		local header2 = control:GetNamedChild("StatHeaderLabel2")
		local headerstring = noselection and SI_COMBAT_METRICS_GROUP or SI_COMBAT_METRICS_SELECTION
		header2:SetText(GetString(headerstring))

		local label1, label2, label3, rowList, labelList
		local activetime
		local showOverHeal = category == "healingOut" and CMX.showOverHeal

		if category == "healingOut" or category == "healingIn" then
			label1 = GetString(showOverHeal and SI_COMBAT_METRICS_HPSA or SI_COMBAT_METRICS_HPS)
			label2 = GetString(SI_COMBAT_METRICS_HEALING)
			label3 = GetString(SI_COMBAT_METRICS_HEALS)

			rowList = { "Total", "Normal", "Critical", "Overflow", "Absolute" }
			labelList = { SI_COMBAT_METRICS_TOTALC, SI_COMBAT_METRICS_NORMAL, SI_COMBAT_METRICS_CRITICAL,
				SI_COMBAT_METRICS_OVERHEAL, SI_COMBAT_METRICS_ABSOLUTEC }

			activetime = fightData and fightData.hpstime or 1
		else
			label1 = GetString(SI_COMBAT_METRICS_DPS)
			label2 = GetString(SI_COMBAT_METRICS_DAMAGE)
			label3 = GetString(SI_COMBAT_METRICS_HIT)

			rowList = { "Total", "Normal", "Critical", "Blocked", "Shielded" }
			labelList = { SI_COMBAT_METRICS_TOTALC, SI_COMBAT_METRICS_NORMAL, SI_COMBAT_METRICS_CRITICAL,
				SI_COMBAT_METRICS_BLOCKED, SI_COMBAT_METRICS_SHIELDED }

			activetime = fightData and fightData.dpstime or 1
		end

		activetime = zo_roundToNearest(activetime, 0.01)
		local activetimestring = string.format("%d:%05.2f", activetime / 60, activetime % 60)
		local dpsRow = control:GetNamedChild("StatRowAPS")

		dpsRow:GetNamedChild("Label"):SetText(label1)                             -- DPS or HPS
		control:GetNamedChild("StatTitleAmount"):GetNamedChild("Label"):SetText(label2) -- Damage or Healing
		control:GetNamedChild("StatTitleCount"):GetNamedChild("Label"):SetText(label3) -- Hits or Heals

		local combattime = zo_roundToNearest(fightData and fightData.combattime or 1, 0.01)
		local combattimestring = string.format("%d:%05.2f", combattime / 60, combattime % 60)

		control:GetNamedChild("ActiveTimeValue"):SetText(activetimestring)
		control:GetNamedChild("CombatTimeValue"):SetText(combattimestring)

		local key = showOverHeal and "HPSAOut" or DPSstrings[category]

		local aps1 = data[key] or 0
		local aps2, apsratio

		local selectionData = util.GetSelectionData()
		if not noselection or showOverHeal then
			aps2 = selectionData and selectionData[key] or 0
			apsratio = (aps1 == 0 and 0) or aps2 / aps1 * 100
		else
			local groupkey = zo_strformat("group<<C:1>>", key)
			aps2 = data[groupkey] or 0
			apsratio = (aps2 == 0 and 0) or aps1 / aps2 * 100
		end

		dpsRow:GetNamedChild("Value"):SetText(string.format("%.0f", aps1))
		dpsRow:GetNamedChild("Value2"):SetText(string.format("%.0f", aps2))
		dpsRow:GetNamedChild("Value3"):SetText(string.format("%.1f%%", apsratio))

		for k, v in ipairs(rowList) do
			local rowcontrol1 = control:GetNamedChild("StatRowAmount" .. k)
			local rowcontrol2 = control:GetNamedChild("StatRowCount" .. k)

			local amountlabel = rowcontrol1:GetNamedChild("Label")
			amountlabel:SetText(GetString(labelList[k]))
			local amountcontrol1 = rowcontrol1:GetNamedChild("Value")
			local amountcontrol2 = rowcontrol1:GetNamedChild("Value2")
			local amountcontrol3 = rowcontrol1:GetNamedChild("Value3")

			local countlabel     = rowcontrol2:GetNamedChild("Label")
			countlabel:SetText(GetString(labelList[k]))
			local countcontrol1 = rowcontrol2:GetNamedChild("Value")
			local countcontrol2 = rowcontrol2:GetNamedChild("Value2")
			local countcontrol3 = rowcontrol2:GetNamedChild("Value3")

			local hide2 = false
			local hide3 = false
			local hide4 = false

			if v then
				local amountkey = category .. v
				local countkey = CountStrings[category] .. v
				local basekey

				if v == "Overflow" or v == "Absolute" then basekey = "Absolute" else basekey = rowList[1] end

				local amount1 = data[amountkey] or 0
				local amount2 = 0
				local amount3 = data[category .. basekey] or 0
				local amountratio = 0

				local count1 = data[countkey] or 0
				local count2 = 0
				local count3 = data[CountStrings[category] .. basekey] or 0
				local countratio = 0

				local groupAmountKey = zo_strformat("group<<C:1>>", category)

				if k == 1 and noselection then
					amount2 = data[groupAmountKey] or 0 -- first letter of category needs to be Capitalized
					amountratio = (amount2 == 0 and 0) or amount1 / amount2 * 100
					hide2 = true
				elseif noselection and v == "Absolute" then
					amount2 = data[groupAmountKey] or 0 -- first letter of category needs to be Capitalized
					amountratio = (amount2 == 0 and 0) or amount1 / amount2 * 100
					hide4 = true
				elseif noselection then
					hide3 = true
					amountratio = (amount3 == 0 and 0) or amount1 / amount3 * 100
					countratio = (count3 == 0 and 0) or count1 / count3 * 100
				elseif noselection == false then
					if (k ~= 1 and v ~= "Absolute") then
						amount3 = selectionData[category .. basekey] or 0
						count3 = selectionData[CountStrings[category] .. basekey] or 0
					end

					amount2 = selectionData[amountkey] or 0
					amountratio = (amount3 == 0 and 0) or amount2 / amount3 * 100

					count2 = selectionData[countkey] or 0
					countratio = (count3 == 0 and 0) or count2 / count3 * 100
				end

				amountcontrol1:SetText(string.format("%.0f", amount1))
				amountcontrol2:SetText(string.format("%.0f", amount2))
				amountcontrol3:SetText(string.format("%.1f%%", amountratio))

				countcontrol1:SetText(string.format("%.0f", count1))
				countcontrol2:SetText(string.format("%.0f", count2))
				countcontrol3:SetText(string.format("%.1f%%", countratio))
			end

			amountcontrol2:SetHidden(hide3 or hide4)
			amountcontrol3:SetHidden(hide4)

			countcontrol2:SetHidden(hide3 or hide2)
			countcontrol3:SetHidden(hide2)
		end
	end
end

local isFileInitialized = false
function CMXint.InitializeCombatStats()
	if isFileInitialized == true then return false end
	logger = util.initSublogger("CombatStats")
	isFileInitialized = true
	return true
end
