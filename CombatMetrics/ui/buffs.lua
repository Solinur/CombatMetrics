local CMX = CombatMetrics
local CMXint = CMX.internal
local ui = CMXint.ui
local util = CMXint.util
local logger
local uncollapsedBuffs = {}
local BuffPanel

local dx = CMXint.dx
local adjustRowSize = util.adjustRowSize
local GetFormattedAbilityIcon = util.GetFormattedAbilityIcon


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
		CombatMetricsReport:Update()
	end

	local function removeFavouriteBuff()
		if buffname then favs[buffname] = nil end
		CombatMetricsReport:Update()
	end

	local function postBuffUptime()
		if buffname then util.PostBuffUptime(currentFight, buffname) end
	end

	local function postSelectionBuffUptime()
		if buffname then util.PostBuffUptime(currentFight, buffname, unitType) end
	end

	local function toggleCollapseBuff()
		if buffname then
			if uncollapsedBuffs[buffname] == true then
				uncollapsedBuffs[buffname] = nil
			else
				uncollapsedBuffs[buffname] = true
			end
		end

		CombatMetricsReport:GetNamedChild("_BuffPanel"):GetNamedChild("BuffList"):Update()
	end

	function CMX.BuffContextMenu( bufflistitem, upInside )
		if not upInside then return end

		buffname = bufflistitem.dataId
		local settings = CMXint.settings.fightReport
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

	CombatMetricsReport:GetNamedChild("_BuffPanel"):GetNamedChild("BuffList"):Update()
end





local function GetBuffData()
	local buffData
	-- TODO: redo
	-- local rightpanel = db.fightReport.rightpanel

	-- if rightpanel == "buffsout" then
	-- 	buffData = selectionData
	-- elseif rightpanel == "buffs" then
	-- 	buffData = fightData.calculated
	-- end

	return buffData
end
util.GetBuffData = GetBuffData

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

function util.buffSortFunction(data, a, b)
	local ishigher = false
	local favs = CMXint.settings.fightReport.buffs.favourites

	local isFavA = favs[a]
	local isFavB = favs[b]

	if isFavA and not isFavB then
		ishigher = true
	elseif isFavA == isFavB then
		ishigher = data[a]["groupUptime"] > data[b]["groupUptime"]
	end

	return ishigher
end

function CMXint.InitializeBuffsPanel(control)
	BuffPanel = CMXint.PanelObject:New(control, "buffs")

	function BuffPanel:Update(fightData)
		logger:Debug("Updating Buff Panel")

		self:ResetBars()
		local sigilIcon = GetControl(control, "HeaderIconTexture")
		sigilIcon:SetHidden(true)

		if fightData == nil then return end
		local buffData = GetBuffData()
		if buffData == nil then return end

		local settings = CMXint.settings.fightReport
		local showids = settings.showDebugIds
		
		local selectedbuffs = ui.selections.buff.buff
		local maxtime = zo_max(fightData.activetime or 0, fightData.dpstime or 0, fightData.hpstime or 0)
		local totalUnitTime = buffData.totalUnitTime or maxtime * 1000
		local favs = CMXint.settings.fightReport.buffs.favourites
		
		local scrollchild = GetControl(control, "PanelScrollChild")
		local currentanchor = {TOPLEFT, scrollchild, TOPLEFT, 0, 1}
		local parentrow

		for buffName, buff in CMX.spairs(buffData["buffs"], util.buffSortFunction) do
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

				currentanchor, parentrow = addBuffPanelRow(control, scrollchild, currentanchor, rowdata)

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

						currentanchor = addBuffPanelRow(control, scrollchild, currentanchor, rowdata, parentrow)
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

						currentanchor = addBuffPanelRow(control, scrollchild, currentanchor, rowdata, parentrow)
					end
				end
			end
		end
	end
end

function CMXint.SelectRightPanel(control)
	local rightpanel = control.menukey
	CMXint.settings.fightReport.rightpanel = rightpanel
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
	CombatMetricsReport_MainPanelGraph:Update()
end

local isFileInitialized = false
function CMXint.InitializeBuffs()
	if isFileInitialized == true then return false end
	logger = util.initSublogger("BuffPanel")

	local buffbutton = GetControl(BuffPanel.control, "SelectorBuffsIn")
	CMXint.SelectRightPanel(buffbutton)

    isFileInitialized = true
	return true
end