local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger
local uncollapsedBuffs = {}

local dx = CMXint.dx
local adjustRowSize = CMXf.adjustRowSize
local GetFormattedAbilityIcon = CMXf.GetFormattedAbilityIcon


local SigilAbilities = { -- Ailities to display a warning icon in the buff list to indicate it cannot be considered a "clean" parse
	[236960] = true, -- Sigil of Power
	[236968] = true, -- Sigil of Defense
	[236994] = true, -- Sigil of Ultimate
	[237014] = true, -- Sigil of Speed
} 

local function isSigilAbility(buffAbilityIds)
	if type(buffAbilityIds) ~= "table" then return false end

	for abilityId, _ in pairs(buffAbilityIds) do
		if SigilAbilities[abilityId] then return true end
	end

	return false
end


do	-- Handling Buffs Context Menu
	local favs
	local buffname
	local unitType
	local currentFight

	local function addFavouriteBuff()
		if buffname then favs[buffname] = true end
		CombatMetrics_Report:Update()
	end

	local function removeFavouriteBuff()
		if buffname then favs[buffname] = nil end
		CombatMetrics_Report:Update()
	end

	local function postBuffUptime()
		if buffname then CMX.PostBuffUptime(currentFight, buffname) end
	end

	local function postSelectionBuffUptime()
		if buffname then CMX.PostBuffUptime(currentFight, buffname, unitType) end
	end

	local function toggleCollapseBuff()
		if buffname then
			if uncollapsedBuffs[buffname] == true then
				uncollapsedBuffs[buffname] = nil
			else
				uncollapsedBuffs[buffname] = true
			end
		end

		CombatMetrics_Report:GetNamedChild("_BuffPanel"):GetNamedChild("BuffList"):Update()
	end

	function CMX.BuffContextMenu( bufflistitem, upInside )
		if not upInside then return end

		buffname = bufflistitem.dataId
		local settings = CMXint.settings.FightReport
		favs = settings.buffs.favourites
		currentFight = CMXint.currentFight
		local func, text

		if favs[buffname] == nil then
			func = addFavouriteBuff
			text = GetString(SI_COMBAT_METRICS_FAVOURITE_ADD)
		else
			func = removeFavouriteBuff
			text = GetString(SI_COMBAT_METRICS_FAVOURITE_REMOVE)
		end

		ClearMenu()
		AddCustomMenuItem(text, func)
		AddCustomMenuItem(GetString(SI_COMBAT_METRICS_POSTBUFF), postBuffUptime)

		local category = settings.category

		if (category == "damageOut" or category == "damageIn") and settings.rightpanel == "buffsout" then
			unitType = "boss"
			AddCustomMenuItem(GetString(SI_COMBAT_METRICS_POSTBUFF_BOSS), postSelectionBuffUptime)
		elseif (category == "healingOut" or category == "healingIn") and settings.rightpanel == "buffsout" then
			unitType = "group"
			AddCustomMenuItem(GetString(SI_COMBAT_METRICS_POSTBUFF_GROUP), postSelectionBuffUptime)
		end

		if bufflistitem.hasDetails == true then
			local stringId = uncollapsedBuffs[buffname] and SI_COMBAT_METRICS_COLLAPSE or SI_COMBAT_METRICS_UNCOLLAPSE
			AddCustomMenuItem(GetString(stringId), toggleCollapseBuff)
		end

		ShowMenu(bufflistitem)
	end
end

function CMX.CollapseButton( button, upInside )
	local buffname = button:GetParent().dataId

	if buffname then
		if uncollapsedBuffs[buffname] == true then
			uncollapsedBuffs[buffname] = nil
		else
			uncollapsedBuffs[buffname] = true
		end
	end

	CombatMetrics_Report:GetNamedChild("_BuffPanel"):GetNamedChild("BuffList"):Update()
end

local function GetUnitsByType(unitType, fightData)
	if not unitType then return end
	local units = {}

	for unitId, unit in pairs(fightData.units) do
		if (unitType == "boss" and unit.bossId) or (unitType == "group" and (unit.unitType == COMBAT_UNIT_TYPE_GROUP or unit.unitType == COMBAT_UNIT_TYPE_PLAYER)) then
			units[unitId] = true
		end
	end

	return units
end

local function GetBuffDataAndUnits(unitType, fightData)
	local buffData
	local buffTypeSelection = CMXint.selection.buffTypeSelection
	local units = 0
	local unitName = ""
	local settings = CMXint.settings.FightReport

	if buffTypeSelection == "buffsout" then
		local category = settings.category
		local tempSelections = {}

		ZO_DeepTableCopy(CMXint.selections, tempSelections)
		if unitType then tempSelections.unit[category] = GetUnitsByType(unitType) end
		buffData = CMX.GenerateSelectionStats(fightData, category, tempSelections) -- yeah, yeah I'm lazy.

		for unitId, _ in pairs(tempSelections.unit[category] or fightData.units) do
			local unit = fightData.calculated.units[unitId]
			local unitData = fightData.units[unitId]
			local unitTotalValue = unit[category.."Total"]

			local isNotEmpty = unitTotalValue > 0 or NonContiguousCount(unit.buffs) > 0
			local isEnemy = unitData.unitType ~= COMBAT_UNIT_TYPE_GROUP and unitData.unitType ~= COMBAT_UNIT_TYPE_PLAYER_PET and unitData.unitType ~= COMBAT_UNIT_TYPE_PLAYER
			local isDamageCategory = category == "damageIn" or category == "damageOut"

			if isNotEmpty and (isEnemy == isDamageCategory) then
				units = units + 1
				unitName = unitData.name
			end
		end

	elseif buffTypeSelection == "buffs" then
		buffData = fightData.calculated
	end

	if units == 1 then 
		return buffData, unitName 
	end

	return buffData, units
end

local function GetCurrentData()
	local data = CMX.currentdata

	if data.units == nil then
		if #CMX.lastfights == 0 then return end
		data = CMX.lastfights[#CMX.lastfights]
	end

	return data
end

function CMX.PostBuffUptime(fight, buffname, unitType)
	local data = fight and CMX.lastfights[fight]
	if not data then return end

	local settings = CMXint.settings
	local category = settings.FightReport.category or "damageOut"
	local timedata = ""

	if data ~= GetCurrentData() then
		local date = data.date
		local datestring = type(date) == "number" and GetDateStringFromTimestamp(date) or date
		timedata = string.format("[%s, %s] ", datestring, data.time)
	end

	local buffDataTable, units = GetBuffDataAndUnits(unitType) -- TODO provide the single unit if units is 1
	local buffData = buffDataTable.buffs[buffname]
	if buffData == nil then return end
	local totalUnitTime = buffDataTable.totalUnitTime

	if totalUnitTime then totalUnitTime = totalUnitTime / 1000 end
	local activetime = totalUnitTime or data.dpstime

	if category == "healingOut" or category == "healingIn" then activetime = totalUnitTime or data.hpstime end

	local uptime = buffData.uptime / 1000
	local groupUptime = buffData.groupUptime / 1000
	local relativeUptimeString = string.format("%.1f%%", uptime / activetime * 100)
	local uptimeString = string.format("%d:%02d", uptime/60, uptime%60)

	local output
	if groupUptime > uptime then
		local relativeGroupUptimeString = string.format("%.1f%%", groupUptime / activetime * 100)
		local groupUptimeString = string.format("%d:%02d", groupUptime/60, groupUptime%60)
		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTBUFF_FORMAT_GROUP), buffname, relativeUptimeString, uptimeString, units, relativeGroupUptimeString, groupUptimeString)
	else
		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTBUFF_FORMAT), buffname, relativeUptimeString, uptimeString, units)
	end

	-- Determine appropriate channel
	local channel = CMXint.settings.autoSelectChatChannel == true and (IsUnitGrouped('player') and CHAT_CHANNEL_PARTY or CHAT_CHANNEL_SAY) or nil

	-- Log output to chat
	local outputtext = string.format("%s%s", timedata, output)
	StartChatInput(outputtext, channel)
end

local function buffSortFunction(data, a, b)
	local ishigher = false
	local favs = CMXint.settings.FightReport.buffs.favourites

	local isFavA = favs[a]
	local isFavB = favs[b]

	if isFavA and not isFavB then
		ishigher = true
	elseif isFavA == isFavB then
		ishigher = data[a]["groupUptime"] > data[b]["groupUptime"]
	end

	return ishigher
end
CMXf.buffSortFunction = buffSortFunction

local function GetBuffData()
	local buffData
	-- TODO: redo
	-- local rightpanel = db.FightReport.rightpanel

	-- if rightpanel == "buffsout" then
	-- 	buffData = selectionData
	-- elseif rightpanel == "buffs" then
	-- 	buffData = fightData.calculated
	-- end

	return buffData
end
CMXf.GetBuffData = GetBuffData

local function addBuffPanelRow(panel, scrollchild, anchor, rowdata, parentrow)
	local hideGroupValues = rowdata.count == rowdata.groupCount and rowdata.uptimeRatio == rowdata.groupUptimeRatio

	local countFormat = hideGroupValues and "%d" or "%d/%d"
	local uptimeFormat = hideGroupValues and "%d" or "%d/%d"

	local rowId = #panel.bars + 1

	local rowName = scrollchild:GetName() .. "Row" .. rowId
	local row = _G[rowName] or CreateControlFromVirtual(rowName, scrollchild, "CombatMetrics_BuffRowTemplate")
	row:SetAnchor(unpack(anchor))
	row:SetHidden(false)

	local header = panel:GetNamedChild("Header")
	adjustRowSize(row, header)

	-- update controls with contents

	local highlightControl = row:GetNamedChild("HighLight")
	highlightControl:SetHidden(not rowdata.highlight)

	local iconControl = row:GetNamedChild("Icon")
	iconControl:SetTexture(rowdata.icon)

	local nameControl = row:GetNamedChild("Name")
	nameControl:SetText(rowdata.label)
	nameControl:SetColor(unpack(rowdata.textcolor))

	local maxwidth = header:GetNamedChild("Name"):GetWidth()
	local indent = rowdata.indent * iconControl:GetWidth() / 2
	if indent > 0 then maxwidth = maxwidth - indent end
	nameControl:SetWidth(maxwidth)

	local anchor = {select(2, iconControl:GetAnchor(0))}

	anchor[4] = 2 * dx + indent
	iconControl:ClearAnchors()
	iconControl:SetAnchor(unpack(anchor))

	local groupBarControl = row:GetNamedChild("GroupBar")
	groupBarControl:SetWidth(maxwidth * rowdata.groupUptimeRatio)
	groupBarControl:SetCenterColor(unpack(rowdata.groupColor))

	local playerBarControl = row:GetNamedChild("PlayerBar")
	playerBarControl:SetWidth(maxwidth * rowdata.uptimeRatio)
	playerBarControl:SetCenterColor(unpack(rowdata.color))

	local countControl = row:GetNamedChild("Count")
	countControl:SetText(string.format(countFormat, rowdata.count, rowdata.groupCount))

	local uptimeControl = row:GetNamedChild("Uptime")
	uptimeControl:SetText(string.format(uptimeFormat, rowdata.uptimeRatio * 100, rowdata.groupUptimeRatio * 100))

	-- local indicatorControl = row:GetNamedChild("Indicator")
	-- indicatorControl:SetHidden(not rowdata.hasDetails)

	local indicatorSwitchControl = row:GetNamedChild("IndicatorSwitch")
	indicatorSwitchControl:SetHidden(not rowdata.hasDetails)

	panel.bars[rowId] = row

	row.dataId = rowdata.buffName
	row.type = "buff"
	row.id = rowId
	row.panel = panel
	row.parentrow = parentrow
	row.hasDetails = rowdata.hasDetails

	local currentanchor = {TOPLEFT, row, BOTTOMLEFT, 0, dx}
	return currentanchor, row
end

local BuffPanel = CMXint.PanelObject:New("Buffs", CombatMetrics_Report_BuffPanel)

function BuffPanel:Update(fightData)
	logger:Debug("Updating Buff Panel")

	self:ResetBars()
	local sigilIcon = GetControl(self, "HeaderIconTexture")
	sigilIcon:SetHidden(true)

	if fightData == nil then return end
	local buffData = GetBuffData()
	if buffData == nil then return end

	local settings = CMXint.settings.FightReport
	local showids = settings.showDebugIds
	
	local selectedbuffs = CMXint.selections.buff.buff
	local maxtime = zo_max(fightData.activetime or 0, fightData.dpstime or 0, fightData.hpstime or 0)
	local totalUnitTime = buffData.totalUnitTime or maxtime * 1000
	local favs = CMXint.settings.FightReport.buffs.favourites
	
	local scrollchild = GetControl(self, "PanelScrollChild")
	local currentanchor = {TOPLEFT, scrollchild, TOPLEFT, 0, 1}
	local parentrow

	for buffName, buff in CMX.spairs(buffData["buffs"], buffSortFunction) do
		if buff.groupUptime > 0 then
			if isSigilAbility(buff.instances) then sigilIcon:SetHidden(false) end

			local labelFormat = showids and "(<<1>>) <<2>>" or "<<2>>"
			local rowdata = {}

			local shownUptime = buff.uptime
			local shownGroupUptime = buff.groupUptime

			local hasInstances = buff.instances and NonContiguousCount(buff.instances) > 1
			local hasStacks = buff.instances and (buff.iconId == 126597 or buff.maxStacks > 1)

			local showName = buffName
			if hasStacks then
				local mainInstance = buff.instances[buff.iconId]

				shownUptime = mainInstance.uptime
				shownGroupUptime = mainInstance.groupUptime

				showName = ZO_CachedStrFormat("<<2>>x <<1>>", buffName, buff.maxStacks)
			end

			rowdata.buffName = buffName
			rowdata.color = (buff.effectType == BUFF_EFFECT_TYPE_BUFF and {0, 0.6, 0, 0.6}) or (buff.effectType == BUFF_EFFECT_TYPE_DEBUFF and {0.75, 0, 0.6, 0.6}) or {0.6, 0.6, 0.6, 0.6}
			rowdata.groupColor = (buff.effectType == BUFF_EFFECT_TYPE_BUFF and {0, 0.6, 0, 0.3}) or (buff.effectType == BUFF_EFFECT_TYPE_DEBUFF and {0.75, 0, 0.6, 0.3}) or {0.6, 0.6, 0.6, 0.3}
			rowdata.highlight = selectedbuffs ~= nil and (selectedbuffs[buffName] ~= nil) or false
			rowdata.icon = GetFormattedAbilityIcon(buff.iconId)
			rowdata.label = ZO_CachedStrFormat(labelFormat, buff.iconId, showName)
			rowdata.uptimeRatio = shownUptime / totalUnitTime
			rowdata.groupUptimeRatio = shownGroupUptime / totalUnitTime
			rowdata.count = buff.count
			rowdata.groupCount = buff.groupCount
			rowdata.textcolor = favs[buffName] and {1, .8, .3, 1} or {1, 1, 1, 1} -- show favs in different color
			rowdata.indent = 0
			rowdata.hasDetails = hasInstances or hasStacks

			currentanchor, parentrow = addBuffPanelRow(self, scrollchild, currentanchor, rowdata)

			if hasInstances and uncollapsedBuffs[buffName] then
				rowdata.indent = 1
				rowdata.highlight = false
				rowdata.hasDetails = false

				for abilityId, instance in pairs(buff.instances) do
					rowdata.icon = GetFormattedAbilityIcon(abilityId)
					rowdata.label = ZO_CachedStrFormat("(<<1>>) <<2>>", abilityId, buffName)

					rowdata.uptimeRatio = instance.uptime / totalUnitTime
					rowdata.groupUptimeRatio = instance.groupUptime / totalUnitTime
					rowdata.count = instance.count
					rowdata.groupCount = instance.groupCount

					currentanchor = addBuffPanelRow(self, scrollchild, currentanchor, rowdata, parentrow)
				end
			end

			if hasStacks and uncollapsedBuffs[buffName] then
				rowdata.indent = 1
				rowdata.highlight = false
				rowdata.hasDetails = false

				local keys = {}
				local instanceData = buff.instances[buff.iconId]

				for stacks, stackData in pairs(instanceData) do
					if type(stacks) == "number" then keys[#keys+1] = stacks end
				end

				table.sort(keys)

				for i = 1, #keys do
					local stacks = keys[i]
					local stackData = instanceData[stacks]

					rowdata.label = ZO_CachedStrFormat("<<1>>x <<2>>", stacks, buffName)

					rowdata.uptimeRatio = stackData.uptime / totalUnitTime
					rowdata.groupUptimeRatio = stackData.groupUptime / totalUnitTime
					rowdata.count = stackData.count
					rowdata.groupCount = stackData.groupCount

					currentanchor = addBuffPanelRow(self, scrollchild, currentanchor, rowdata, parentrow)
				end
			end
		end
	end
end

function BuffPanel:Release() end

function CMXint.SelectRightPanel(control)
	local rightpanel = control.menukey
	CMXint.settings.FightReport.rightpanel = rightpanel
	local menubar = control:GetParent()

	for i=1, menubar:GetNumChildren() do
		local child = menubar:GetChild(i)

		if child:GetType() == CT_CONTROL then
			child:GetNamedChild("Overlay"):SetHidden(child == control)
		end
	end

	local isbuffpanel = rightpanel == "buffs" or rightpanel == "buffsout"
	local panel = menubar:GetParent()

	local buffList = panel:GetNamedChild("BuffList")
	buffList:SetHidden(not isbuffpanel)
	local resourceList = panel:GetNamedChild("ResourceList")
	resourceList:SetHidden(isbuffpanel)

	panel.active = isbuffpanel and buffList or resourceList

	BuffPanel:Update(CMXint.currentFight)
	CombatMetrics_Report_MainPanelGraph:Update()
end

local isFileInitialized = false
function CMXint.InitializeBuffPanel()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("BuffPanel")

	local buffbutton = GetControl(BuffPanel.control, "SelectorBuffsIn")
	CMXint.SelectRightPanel(buffbutton)

    isFileInitialized = true
	return true
end