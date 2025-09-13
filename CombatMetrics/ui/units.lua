local CMX = CombatMetrics
local CMXint = CMX.internal
local util = CMXint.util
local ui = CMXint.ui
local logger

local dx = CMXint.dx
local DPSstrings = CMXint.DPSstrings
local adjustRowSize = util.adjustRowSize

do	-- Handling Unit Context Menu
	local UnitContextMenuUnitId
	local function postUnitDPS()
		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SELECTED_UNIT, currentFight, UnitContextMenuUnitId)
	end

	local function postUnitNameDPS()
		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SELECTED_UNITNAME, currentFight, UnitContextMenuUnitId)
	end

	local function postSelectionDPS()
		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SELECTION, currentFight)
	end

	local function postSelectionHPS()
		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SELECTION_HEALING, currentFight)
	end

	function CMX.UnitContextMenu( unitItem, upInside )
		local category = CMXint.settings.fightReport.category
		if not (upInside or category == "damageOut" or category == "healingOut") then return end
		local dataId = unitItem.dataId
		local selections = CMXint.selections

		ClearMenu()

		if category == "damageOut" then
			UnitContextMenuUnitId = dataId

			local unitName = fightData.units[dataId].name

			AddCustomMenuItem(GetString(SI_COMBAT_METRICS_POSTUNITDPS), postUnitDPS)
			AddCustomMenuItem(zo_strformat(GetString(SI_COMBAT_METRICS_POSTUNITNAMEDPS), unitName, 2), postUnitNameDPS)

			if selections.unit[category] then AddCustomMenuItem(GetString(SI_COMBAT_METRICS_POSTSELECTIONDPS), postSelectionDPS) end

		elseif category == "healingOut" and selections.unit[category] then
			AddCustomMenuItem(GetString(SI_COMBAT_METRICS_POSTSELECTIONHPS), postSelectionHPS)
		end

		ShowMenu(unitItem)
	end
end

local function GetShortFormattedNumber(number)
	local exponent = zo_floor(math.log(number)/math.log(10))
	local loweredNumber = zo_roundToNearest(number, zo_pow(10, exponent-2))
	local shortNumber = ZO_AbbreviateNumber(loweredNumber, 2, exponent>=6)

	return shortNumber
end

function CMXint.InitializeUnitsPanel(control)
	UnitsPanel = CMXint.PanelObject:New(control, "units")

	function UnitsPanel:Update(fightData)
		logger:Debug("Updating Unit Panel")

		self:ResetBars()

		local settings = self.settings
		local category = settings.category
		local isdamage = (category == "damageOut" or category == "damageIn")

		local label1 = ((category == "damageOut" or category == "healingOut") and GetString(SI_COMBAT_METRICS_TARGET)) or GetString(SI_COMBAT_METRICS_SOURCE)
		local label2 = (isdamage and GetString(SI_COMBAT_METRICS_DPS)) or GetString(SI_COMBAT_METRICS_HPS)
		local label3 = (isdamage and GetString(SI_COMBAT_METRICS_DAMAGE)) or GetString(SI_COMBAT_METRICS_HEALING)

		local header = control:GetNamedChild("Header")

		header:GetNamedChild("Name"):SetText(label1)
		header:GetNamedChild("PerSecond"):SetText(label2)
		header:GetNamedChild("Total"):SetText(label3)

		-- prepare data

		if fightData == nil then return end
		local data = fightData.calculated
		local selectedunits = CMXint.selections.unit[category]

		local totalAmountKey = category.."Total"
		local totalAmount = data[totalAmountKey] -- i.e. damageOutTotal
		local APSKey = DPSstrings[category]

		local scrollchild = GetControl(control, "PanelScrollChild")
		local currentanchor = {TOPLEFT, scrollchild, TOPLEFT, 0, 1}

		local rightpanel = settings.rightpanel
		local showids = settings.showDebugIds

		for unitId, unit in CMX.spairs(data.units, function(t, a, b) return t[a][totalAmountKey]>t[b][totalAmountKey] end) do -- i.e. for damageOut sort by damageOutTotal
			local totalUnitAmount = unit[totalAmountKey]
			local unitData = fightData.units[unitId]

			if (totalUnitAmount > 0 or (rightpanel == "buffsout" and NonContiguousCount(unit.buffs) > 0 and (unitData.isFriendly == false and isdamage) or (unitData.isFriendly and not isdamage))) and (not (unitData.unitType == 2 and settings.showPets == false)) then
				local highlight = false
				if selectedunits ~= nil then highlight = selectedunits[unitId] ~= nil end
				
				local dbug = showids and string.format("(%d) ", unitId) or ""

				local name = dbug .. (settings.useDisplayNames and unitData.displayname or unitData.name)

				local isboss = unitData.bossId
				local namecolor = (isboss and {1, .8, .3, 1}) or {1, 1, 1, 1}

				local unitTime = unitData.dpsend and unitData.dpsstart and zo_max((unitData.dpsend - unitData.dpsstart) / 1000, 1) or 1
				local dps  = unitTime and totalUnitAmount / unitTime or unit[APSKey]
				local damage = totalUnitAmount
				local ratio = damage / totalAmount

				local rowId = #control.bars + 1

				local rowName = scrollchild:GetName() .. "Row" .. rowId
				local row = _G[rowName] or CreateControlFromVirtual(rowName, scrollchild, "CombatMetrics_UnitRowTemplate")
				row:SetAnchor(unpack(currentanchor))
				row:SetHidden(false)

				local header = control:GetNamedChild("Header")
				adjustRowSize(row, header)

				local highlightControl = row:GetNamedChild("HighLight")
				highlightControl:SetHidden(not highlight)

				local nameControl = row:GetNamedChild("Name")
				nameControl:SetText(name)
				--nameControl:SetFont(font)
				nameControl:SetColor(unpack(namecolor))

				local maxwidth = nameControl:GetWidth()

				local barControl = row:GetNamedChild("Bar")
				barControl:SetWidth(maxwidth * ratio)

				local rateControl = row:GetNamedChild("PerSecond")
				rateControl:SetText(string.format("%.0f", dps))

				local amountControl = row:GetNamedChild("Total")
				amountControl:SetText(GetShortFormattedNumber(damage))

				local fractionControl = row:GetNamedChild("Fraction")
				fractionControl:SetText(string.format("%.1f%%", 100 * ratio))

				currentanchor = {TOPLEFT, row, BOTTOMLEFT, 0, dx}

				control.bars[rowId] = row

				row.dataId = unitId
				row.type = "unit"
				row.id = rowId
				row.self = control

			end
		end
	end
end

local isFileInitialized = false
function CMXint.InitializeUnits()
	if isFileInitialized == true then return false end
	logger = util.initSublogger("UnitPanel")

    isFileInitialized = true
	return true
end