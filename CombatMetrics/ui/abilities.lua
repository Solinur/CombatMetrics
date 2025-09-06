local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger

local GetFormattedAbilityIcon = CMXf.GetFormattedAbilityIcon
local GetFormattedAbilityName = CMXf.GetFormattedAbilityName
local adjustRowSize = CMXf.adjustRowSize

local DPSstrings = CMXint.DPSstrings
local CountStrings = CMXint.CountStrings
local dx = CMXint.dx
local AbilityPanel

local hitCritLayoutTable = {
	[1] = { "Critical", "Total", GetString(SI_COMBAT_METRICS_CRITS), GetString(SI_COMBAT_METRICS_HITS) },
	[2] = { "Total", "Critical", GetString(SI_COMBAT_METRICS_HITS), GetString(SI_COMBAT_METRICS_CRITS) },
	[3] = { "Normal", "Critical", GetString(SI_COMBAT_METRICS_NORM), GetString(SI_COMBAT_METRICS_CRITS) },
	[4] = { "Blocked", "Total", GetString(SI_COMBAT_METRICS_BLOCKS), GetString(SI_COMBAT_METRICS_HITS) },
	[5] = { "Total", "Blocked", GetString(SI_COMBAT_METRICS_HITS), GetString(SI_COMBAT_METRICS_BLOCKS) },
	[6] = { "Normal", "Blocked", GetString(SI_COMBAT_METRICS_NORM), GetString(SI_COMBAT_METRICS_BLOCKS) },
}

do -- Context Menu for hit/crit column on ability panel
	local function getMenuData(id)
		local category = CMXint.settings.fightReport.category
		local hitCritLayout = hitCritLayoutTable[id]
		local text = string.format("%s/%s", hitCritLayout[3], hitCritLayout[4])

		local function callback()
			CMXint.settings.fightReport.hitCritLayout[category] = id
			AbilityPanel:Update()
		end

		return text, callback
	end

	function CMX.HitCritContextMenu(control, button)
		ClearMenu()

		if CMXint.settings.fightReport.category == "damageIn" then
			AddCustomMenuItem(getMenuData(4))
			AddCustomMenuItem(getMenuData(5))
			AddCustomMenuItem(getMenuData(6))
		end

		AddCustomMenuItem(getMenuData(1))
		AddCustomMenuItem(getMenuData(2))
		AddCustomMenuItem(getMenuData(3))

		ShowMenu(control)
	end
end

local averageLayoutTable = {
	[1] = { "Total", GetString(SI_COMBAT_METRICS_AVE), GetString(SI_COMBAT_METRICS_HITS) },
	[2] = { "Normal", GetString(SI_COMBAT_METRICS_AVE_N), GetString(SI_COMBAT_METRICS_NORMAL_HITS) },
	[3] = { "Critical", GetString(SI_COMBAT_METRICS_AVE_C), GetString(SI_COMBAT_METRICS_CRITS) },
	[4] = { "Blocked", GetString(SI_COMBAT_METRICS_AVE_B), GetString(SI_COMBAT_METRICS_BLOCKS) },
}

do -- Context Menu for average column on ability panel
	local function getMenuData(id)
		local averageLayout = averageLayoutTable[id]
		local text = string.format("%s %s", GetString(SI_COMBAT_METRICS_AVERAGE), averageLayout[3])
		local category = CMXint.settings.fightReport.category

		local function callback()
			CMXint.settings.fightReport.averageLayout[category] = id
			AbilityPanel:Update()
		end

		return text, callback
	end

	function CMX.AverageContextMenu(control, button)
		ClearMenu()

		AddCustomMenuItem(getMenuData(1))
		AddCustomMenuItem(getMenuData(2))
		AddCustomMenuItem(getMenuData(3))

		if CMXint.settings.fightReport.category == "damageIn" then AddCustomMenuItem(getMenuData(4)) end

		ShowMenu(control)
	end
end

do -- Context Menu for Min/Max column on ability panel
	local function selectMinMaxOption1()
		local category = CMXint.settings.fightReport.category
		CMXint.settings.fightReport.maxValue[category] = true
		AbilityPanel:Update()
	end

	local function selectMinMaxOption2()
		local category = CMXint.settings.fightReport.category
		CMXint.settings.fightReport.maxValue[category] = false
		AbilityPanel:Update()
	end

	local text1 = string.format("%s", GetString(SI_COMBAT_METRICS_MAX))
	local text2 = string.format("%s", GetString(SI_COMBAT_METRICS_MIN))

	function CMX.MinMaxContextMenu(control, button)
		ClearMenu()

		AddCustomMenuItem(text1, selectMinMaxOption1)
		AddCustomMenuItem(text2, selectMinMaxOption2)

		ShowMenu(control)
	end
end

function CMXint.InitializeAbilitiesPanel(control)
	AbilitiesPanel = CMXint.PanelObject:New(control, "abilities")

	function AbilitiesPanel:Update(fightData)
		logger:Debug("Updating Ability Panel")

		self:ResetBars()

		local settings = self.settings
		local abilitySettings = settings.abilities

		local category = settings.category
		local hitCritLayoutId = abilitySettings.hitCritLayout[category]
		local averageLayoutId = abilitySettings.averageLayout[category]
		local hitCritLayout = hitCritLayoutTable[hitCritLayoutId]
		local averageLayout = averageLayoutTable[averageLayoutId]
		local minmax = abilitySettings.maxValue[category]

		local isDamage = category == "damageIn" or category == "damageOut"
		local showOverHeal = CMX.showOverHeal and category == "healingOut"

		local valueColumnLabel = isDamage and GetString(SI_COMBAT_METRICS_DAMAGE) or GetString(SI_COMBAT_METRICS_HEALING)

		if showOverHeal then valueColumnLabel = valueColumnLabel .. "*" end

		local header = control:GetNamedChild("Header")

		header:GetNamedChild("Total"):SetText(valueColumnLabel)

		local headerCritString = showOverHeal and GetString(SI_COMBAT_METRICS_OH) or hitCritLayout[3]
		local headerHitString = showOverHeal and GetString(SI_COMBAT_METRICS_HEALS) or hitCritLayout[4]
		local headerCritRatioString = showOverHeal and GetString(SI_COMBAT_METRICS_OH) or
		hitCritLayoutId > 3 and GetString(SI_COMBAT_METRICS_BLOCKS) or GetString(SI_COMBAT_METRICS_CRITS)

		header:GetNamedChild("Crits"):SetText(headerCritString)
		header:GetNamedChild("Hits"):SetText("/" .. headerHitString)
		header:GetNamedChild("CritRatio"):SetText(headerCritRatioString .. "%")

		local headerAvg = header:GetNamedChild("Average")

		headerAvg:SetText(averageLayout[2])

		local headerMinMax = header:GetNamedChild("MinMax")

		headerMinMax:SetText(GetString(minmax and SI_COMBAT_METRICS_MAX or SI_COMBAT_METRICS_MIN))

		if fightData == nil then return end

		local data
		local totaldmg

		local selections = CMXint.selections

		local selectedabilities = selections["ability"][category]
		local selectedunits = selections["unit"][category]

		local totalkey = "Total"
		local totalAmountKey = showOverHeal and "healingOutAbsolute" or category .. totalkey
		local countString = CountStrings[category]



		if selectedunits ~= nil then
			local selectionData = CMXf.GetSelectionData() -- TODO: Implement

			data = selectionData
			totaldmg = selectionData.totalValueSum
		else
			data = fightData.calculated
			totaldmg = data[totalAmountKey]
		end

		local scrollchild = GetControl(control, "PanelScrollChild")
		local currentanchor = { TOPLEFT, scrollchild, TOPLEFT, 0, 1 }

		local totalHitKey = showOverHeal and "healsOutAbsolute" or countString .. totalkey
		local critKey = showOverHeal and "healsOutOverflow" or hitCritLayoutId > 3 and countString .. "Blocked" or
		countString .. "Critical"

		local ratioKey1 = showOverHeal and "healsOutOverflow" or
		countString .. hitCritLayout[1]                                                     -- first value of the crits/hits column display
		local ratioKey2 = showOverHeal and "healsOutAbsolute" or
		countString .. hitCritLayout[2]                                                     -- second value of the crits/hits column display

		local avgKey1 = showOverHeal and "healingOutAbsolute" or
		category .. averageLayout[1]                                                        -- damage value of the avg column display
		local avgKey2 = showOverHeal and "healsOutAbsolute" or
		countString .. averageLayout[1]                                                     -- hits value of the avg column display

		local DPSKey = showOverHeal and "HPSAOut" or DPSstrings[category]

		local showids = settings.showDebugIds

		for abilityId, ability in CMX.spairs(data[category], function(t, a, b) return t[a][totalAmountKey] >
			t[b][totalAmountKey] end) do
			if ability[totalAmountKey] > 0 then
				local highlight = false

				if selectedabilities ~= nil then
					highlight = selectedabilities[abilityId] ~= nil
				end

				local icon        = GetFormattedAbilityIcon(abilityId)

				local duration    = GetAbilityDuration(abilityId)

				local dot         = ((duration and duration > 0) or (IsAbilityPassive(abilityId) and isDamage)) and "*" or ""
				local pet         = ability.pet and " (pet)" or ""
				local dbug        = showids and string.format("(%d) ", abilityId) or ""
				local color       = ability.damageType and CMX.GetDamageColor(ability.damageType) or ""

				local name        = dbug .. color .. (ability.name or GetFormattedAbilityName(abilityId)) .. dot .. pet ..
				"|r"

				local dps         = ability[DPSKey]
				local total       = ability[totalAmountKey]
				local ratio       = total and totaldmg and totaldmg > 0 and (total / totaldmg)

				local crits       = ability[critKey]
				local hits        = ability[totalHitKey]
				local critratio   = crits and hits and hits > 0 and (100 * crits / hits)

				local ratio1      = ability[ratioKey1]
				local ratio2      = ability[ratioKey2]

				local avg1        = ability[avgKey1]
				local avg2        = ability[avgKey2] or 0

				local avg         = avg2 ~= 0 and (avg1 / avg2)
				local minmaxValue = (showOverHeal and "-") or (minmax and ability.max) or (ability.min or 0)

				local rowId       = #control.bars + 1

				local rowName     = scrollchild:GetName() .. "Row" .. rowId
				local row         = _G[rowName] or
				CreateControlFromVirtual(rowName, scrollchild, "CombatMetrics_AbilityRowTemplate")
				row:SetAnchor(unpack(currentanchor))
				row:SetHidden(false)

				adjustRowSize(row, header)

				local highlightControl = row:GetNamedChild("HighLight")
				highlightControl:SetHidden(not highlight)

				local iconControl = row:GetNamedChild("Icon")
				iconControl:SetTexture(icon)

				local nameControl = row:GetNamedChild("Name")
				nameControl:SetText(name)
				local maxwidth = nameControl:GetWidth()

				local barControl = row:GetNamedChild("Bar")
				barControl:SetWidth(maxwidth * ratio)

				local fractionControl = row:GetNamedChild("Fraction")
				fractionControl:SetText(ratio and string.format("%.1f%%", 100 * ratio) or "-")

				local rateControl = row:GetNamedChild("PerSecond")
				rateControl:SetText(dps and string.format("%.0f", dps) or "-")

				local amountControl = row:GetNamedChild("Total")
				amountControl:SetText(total or "-")

				local critControl = row:GetNamedChild("Crits")
				critControl:SetText(ratio1 or "-")

				local hitsControl = row:GetNamedChild("Hits")
				hitsControl:SetText(string.format("/%d", ratio2 or "-"))

				local critFractionControl = row:GetNamedChild("CritRatio")
				critFractionControl:SetText(critratio and string.format("%.0f%%", critratio) or "-")

				local avgControl = row:GetNamedChild("Average")
				avgControl:SetText(avg and string.format("%.0f", avg) or "-")

				local maxControl = row:GetNamedChild("MinMax")
				maxControl:SetText(minmaxValue)

				currentanchor = { TOPLEFT, row, BOTTOMLEFT, 0, dx }

				control.bars[rowId] = row

				row.dataId = abilityId
				row.type = "ability"
				row.id = rowId
				row.panel = control
			end
		end
	end
end

local isFileInitialized = false
function CMXint.InitializeAbilities()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("Abilities")

	isFileInitialized = true
	return true
end
