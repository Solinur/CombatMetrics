local CMX = CombatMetrics
local CMXint = CMX.internal
local util = CMXint.util
local ui = CMXint.ui
local logger

local CountStrings = CMXint.CountStrings


local powerTypeLabels = {
	[POWERTYPE_MAGICKA] = "_MAGICKA",
	[POWERTYPE_STAMINA] = "_STAMINA",
	[POWERTYPE_HEALTH] = "_HEALTH",
}


local statKeysLegacy = {

[LIBCOMBAT_STAT_MAXMAGICKA] 		= "maxmagicka",
[LIBCOMBAT_STAT_SPELLPOWER] 		= "spellpower",
[LIBCOMBAT_STAT_SPELLCRIT] 			= "spellcrit",
[LIBCOMBAT_STAT_SPELLCRITBONUS] 	= "spellcritbonus",
[LIBCOMBAT_STAT_SPELLPENETRATION]	= "spellpen",
[LIBCOMBAT_STAT_MAXSTAMINA] 		= "maxstamina",
[LIBCOMBAT_STAT_WEAPONPOWER] 		= "weaponpower",
[LIBCOMBAT_STAT_WEAPONCRIT] 		= "weaponcrit",
[LIBCOMBAT_STAT_WEAPONCRITBONUS]	= "weaponcritbonus",
[LIBCOMBAT_STAT_WEAPONPENETRATION] 	= "weaponpen",
[LIBCOMBAT_STAT_MAXHEALTH] 			= "maxhealth",
[LIBCOMBAT_STAT_PHYSICALRESISTANCE] = "physres",
[LIBCOMBAT_STAT_SPELLRESISTANCE] 	= "spellres",
[LIBCOMBAT_STAT_CRITICALRESISTANCE] = "critres",
}

local statFormat = { 			-- {label, format, convert}

	[POWERTYPE_MAGICKA] = {
		[1] = {LIBCOMBAT_STAT_MAXMAGICKA, "%d"},
		[2] = {LIBCOMBAT_STAT_SPELLPOWER, "%d"},
		[3] = {LIBCOMBAT_STAT_SPELLCRIT, "%.1f%%", true},
		[4] = {LIBCOMBAT_STAT_SPELLCRITBONUS, "%.1f%%"},
		[5] = {LIBCOMBAT_STAT_SPELLPENETRATION, "%d"},
		[6] = {LIBCOMBAT_STAT_STATUS_EFFECT_CHANCE, "+%.1f%%"},
	},

	[POWERTYPE_STAMINA] = {
		[1] = {LIBCOMBAT_STAT_MAXSTAMINA, "%d"},
		[2] = {LIBCOMBAT_STAT_WEAPONPOWER, "%d"},
		[3] = {LIBCOMBAT_STAT_WEAPONCRIT, "%.1f%%", true},
		[4] = {LIBCOMBAT_STAT_WEAPONCRITBONUS, "%.1f%%"},
		[5] = {LIBCOMBAT_STAT_WEAPONPENETRATION, "%d"},
		[6] = {LIBCOMBAT_STAT_STATUS_EFFECT_CHANCE, "+%.1f%%"},
	},

	[POWERTYPE_HEALTH] = {
		[1] = {LIBCOMBAT_STAT_MAXHEALTH, "%d"},
		[2] = {LIBCOMBAT_STAT_PHYSICALRESISTANCE, "%d"},
		[3] = {LIBCOMBAT_STAT_SPELLRESISTANCE, "%d"},
		[4] = {LIBCOMBAT_STAT_CRITICALRESISTANCE, "%d", "%.1f%%"},
	},

}

function CMXint.InitializePlayerStatsPanel(control)
	PlayerStatsPanel = CMX.internal.PanelObject:New(control, "playerStats")

	function PlayerStatsPanel:Update(fightData)
		logger:Debug("Updating CombatStatsPanel")

		local data = fightData or {}
		local settings = self.settings
		local selections = ui.selections
		local selectionData = util.GetSelectionData()

		local powerType = settings.fightstatspanel  -- TODO: This should be obsolete!
		local category = settings.category
		category = category == "healingIn" and "healingOut" or category

		local calculated = data.calculated or {}
		local calcVersion = calculated.calcVersion or 1

		local stats = calculated.stats or {}
		local fightStats = data.stats or {}

		local avgkey = (category == "damageOut" or category == "damageIn") and "dmgavg" or "healavg"
		local avgvalues = (powerType == POWERTYPE_HEALTH and stats.dmginavg) or stats[avgkey] or {}
		local totalvalue = powerType == POWERTYPE_HEALTH and calculated.damageInTotal or calculated[category.."Total"]
		local countvalue = calculated[CountStrings[category].."Total"]

		local resources = calculated.resources or {}

		local magicka = resources[POWERTYPE_MAGICKA] or {}
		local stamina = resources[POWERTYPE_STAMINA] or {}
		local ultimate = resources[POWERTYPE_ULTIMATE] or {}

		local magickacontrol = control:GetNamedChild("ResourceMagicka")
		magickacontrol:GetNamedChild("Value"):SetText(string.format("%.0f", magicka.gainRate or 0))
		magickacontrol:GetNamedChild("Value2"):SetText(string.format("%.0f", magicka.drainRate or 0))

		local staminacontrol = control:GetNamedChild("ResourceStamina")
		staminacontrol:GetNamedChild("Value"):SetText(string.format("%.0f", stamina.gainRate or 0))
		staminacontrol:GetNamedChild("Value2"):SetText(string.format("%.0f", stamina.drainRate or 0))

		local ultimatecontrol = control:GetNamedChild("ResourceUltimate")
		ultimatecontrol:GetNamedChild("Value"):SetText(string.format("%.2f", ultimate.gainRate or 0))
		ultimatecontrol:GetNamedChild("Value2"):SetText(string.format("%.2f", ultimate.drainRate or 0))

		local stringKey = "SI_COMBAT_METRICS_STATS" .. powerTypeLabels[powerType]

		local statWindowControl = control:GetNamedChild("AttackStats")
		local keys = statFormat[powerType]

		local resdata = selections.unit[category] and selectionData or calculated or {}

		for i = 1, 4 do
			local text = ZO_CachedStrFormat("<<1>>:", GetString(stringKey, i))
			local rowcontrol = statWindowControl:GetNamedChild("Row"..i)
			local dataKey, displayformat, convert = unpack(keys[i] or {})
			local statData = stats[dataKey]
			if calcVersion < 2 then dataKey = statKeysLegacy[dataKey] end

			if text ~= nil and text ~= "" and dataKey ~= nil then
				local maxvalue = statData and statData.max or fightStats["max"..dataKey] or 0

				if convert == true then maxvalue = GetCriticalStrikeChance(maxvalue) end
				if dataKey == POWERTYPE_HEALTH and i == 4 then maxvalue = maxvalue / 68 end 	-- untested, but good agreement from multiple sources
				local maxvalue_str = tostring(maxvalue)
				if displayformat then maxvalue_str = string.format(displayformat, maxvalue) end

				local avgvalue = statData and statData[avgkey] or avgvalues["avg"..dataKey] or stats["avg"..dataKey]

				if avgvalue == nil then -- legacy
					local legacyvalue = avgvalues["sum"..dataKey]
					avgvalue = (legacyvalue and legacyvalue / zo_max(convert and countvalue or totalvalue or 1, 1)) or maxvalue_str
				end

				if type(avgvalue) == "number" then
					if convert then avgvalue = GetCriticalStrikeChance(avgvalue) end
					if displayformat then avgvalue = string.format(displayformat, avgvalue) end
				end

				if i == 4 and powerType ~= POWERTYPE_HEALTH then	-- Add a hint for backstabber
					rowcontrol.tooltip = nil
					local tooltiplines = {}
					local backstabberTT
					local CP = data.CP

					if CP and CP.version ~= nil and CP.version >= 2 then
						local backstabber = CP[1] and CP[1].stars and CP[1].stars[31] -- Backstabber CP

						if backstabber and backstabber[1] >= 10 and backstabber[2] == LIBCOMBAT_CPTYPE_SLOTTED then
							text = ZO_CachedStrFormat("<<1>>*:", GetString(stringKey, i))
							backstabberTT = GetString(SI_COMBAT_METRICS_BACKSTABBER_TT)
						end
					end

					local critvalues = powerType == POWERTYPE_MAGICKA and resdata.spellCrit or powerType == POWERTYPE_STAMINA and resdata.weaponCrit

					if critvalues then
						local sum = 0
						local effectiveSum = 0
						local totalDamage = 0
						local maxCritBonus = 125
						local trimmedCritValues = {[125] = 0}
						local stepsize = 10

						for crit, damage in pairs(critvalues) do
							sum = sum + crit * damage
							effectiveSum = effectiveSum + zo_min(crit, maxCritBonus) * damage
							totalDamage = totalDamage + damage

							if crit < 130 and crit >= 120 then stepsize = 5 end

							local trimmedkey = zo_ceil(crit/stepsize)*stepsize
							trimmedCritValues[trimmedkey] = (trimmedCritValues[trimmedkey] or 0) + damage
						end

						totalDamage = zo_max(totalDamage, 1)
						table.insert(tooltiplines, GetString(SI_COMBAT_METRICS_CRITBONUS_TT))

						local sumdamage = 0
						for crit, damage in CMX.spairs(trimmedCritValues) do
							sumdamage = sumdamage + damage

							local sumdamageRatio = 100 * (sumdamage/totalDamage)
							local damageRatio = 100 * damage/totalDamage
							local color = crit == 125 and "|cffbb88" or damageRatio > 5 and "|cffffff" or ""
							local newline = string.format("<%s%2d%%: %5.1f%%", color, crit, sumdamageRatio)
							table.insert(tooltiplines, newline)
						end

						avgvalue = string.format(displayformat, zo_max(effectiveSum / totalDamage, avgvalues["avg"..dataKey] or 0))

						rowcontrol.tooltip = #tooltiplines>2 and tooltiplines or nil
						if backstabberTT then table.insert(tooltiplines, 1, backstabberTT) end

						local newline = string.format("%s: %.1f%%", GetString(SI_COMBAT_METRICS_AVERAGE), sum / totalDamage)
						table.insert(tooltiplines, " ")
						table.insert(tooltiplines, newline)

					end
				else
					rowcontrol.tooltip = nil
				end

				rowcontrol:GetNamedChild("Label"):SetText(text)
				rowcontrol:GetNamedChild("Value"):SetText(avgvalue)
				rowcontrol:GetNamedChild("Value2"):SetText(maxvalue)
				rowcontrol:SetHidden(false)

			else

				rowcontrol:SetHidden(true)

			end
		end

		local row5 = statWindowControl:GetNamedChild("Row5")
		local row6 = statWindowControl:GetNamedChild("Row6")
		local row7 = statWindowControl:GetNamedChild("Row7")

		if category == "damageOut" and (powerType == POWERTYPE_MAGICKA or powerType == POWERTYPE_STAMINA) then

			local resistvalues = powerType == POWERTYPE_MAGICKA and resdata.spellResistance or powerType == POWERTYPE_STAMINA and resdata.physicalResistance or {}
			local statId = keys[5][1]
			local statData = stats[statId]

			local sum = 0
			local effectiveSum = 0
			local totalDamage = 0
			local maxvalue = statData and statData.max or fightStats["max"..statId] or 0
			local overpen = 0
			local maxpen = settings.stats.unitresistance

			local trimmedResistvalues = {[18] = 0}

			for penetration, damage in pairs(resistvalues) do

				sum = sum + penetration * damage
				effectiveSum = effectiveSum + zo_min(penetration, maxpen) * damage
				maxvalue = zo_max(maxvalue, penetration)
				totalDamage = totalDamage + damage

				if penetration - maxpen > 0 then overpen = overpen + damage end

				local trimmedkey = zo_floor((penetration+800)/1000)
				trimmedResistvalues[trimmedkey] = (trimmedResistvalues[trimmedkey] or 0) + damage

			end

			totalDamage = zo_max(totalDamage, 1)

			local tooltiplines = {GetString(SI_COMBAT_METRICS_PENETRATION_TT)}

			local sumdamage = 0

			for penetration, damage in CMX.spairs(trimmedResistvalues) do

				sumdamage = sumdamage + damage

				local sumdamageRatio = 100 * (sumdamage/totalDamage)
				local damageRatio = 100 * damage/totalDamage

				local color = penetration == 18 and "|cffbb88" or damageRatio > 5 and "|cffffff" or ""

				local newline = string.format("<%s%2d.2k: %5.1f%%", color, penetration, sumdamageRatio)
				table.insert(tooltiplines, newline)

			end

			local averagePenetration = string.format("%d", zo_max(zo_round(effectiveSum / totalDamage), avgvalues["avg"..statId] or 0))
			local overPenetrationRatio = string.format("%.1f%%", 100 * overpen / totalDamage)

			local newline = string.format("%s: %d", GetString(SI_COMBAT_METRICS_AVERAGE), zo_round(sum / totalDamage))
			table.insert(tooltiplines, " ")
			table.insert(tooltiplines, newline)

			row5:SetHidden(false)
			row6:SetHidden(false)
			row7:SetHidden(false)

			local text5 = ZO_CachedStrFormat("<<1>>:", GetString(stringKey, 5))

			row5:GetNamedChild("Label"):SetText(text5)
			row5:GetNamedChild("Value"):SetText(averagePenetration)
			row5:GetNamedChild("Value2"):SetText(maxvalue)

			local text6 = ZO_CachedStrFormat("<<1>>:", GetString(stringKey, 6))

			row6:GetNamedChild("Label"):SetText(text6)
			row6:GetNamedChild("Value"):SetText(overPenetrationRatio)
			row6.tooltip = #tooltiplines>4 and tooltiplines or nil

			local text7 = ZO_CachedStrFormat("<<1>>:", GetString(stringKey, 7))
			local dataKey, displayformat, convert = unpack(keys[6] or {})
			local statData = stats[dataKey]

			if text7 ~= nil and text7 ~= "" and dataKey ~= nil then
				local maxvalue = tostring(statData and statData.max or fightStats["max"..dataKey] or 0)
				local avgvalue = tostring(statData and statData[avgkey] or avgvalues["avg"..dataKey] or stats["avg"..dataKey] or 0)

				if displayformat then maxvalue = string.format(displayformat, maxvalue) end
				if displayformat then avgvalue = string.format(displayformat, avgvalue) end

				row7:GetNamedChild("Label"):SetText(text7)
				row7:GetNamedChild("Value"):SetText(avgvalue)
				row7:GetNamedChild("Value2"):SetText(maxvalue)
				row7:SetHidden(false)
			else
				row7:SetHidden(true)
			end
		else

			row5:SetHidden(true)
			row6:SetHidden(true)
			row7:SetHidden(true)
			row6.tooltip = nil

		end
	end
end

local isFileInitialized = false
function CMXint.InitializePlayerStats()
	if isFileInitialized == true then return false end
	logger = util.initSublogger("PlayerStats")
	


    isFileInitialized = true
	return true
end