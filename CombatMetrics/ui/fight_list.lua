local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger
local em = GetEventManager()

local adjustRowSize = CMXf.adjustRowSize
local DPSstrings = CMXint.DPSstrings
local dx = CMXint.dx

local FightListPanel = CMXint.PanelObject:New("FightList", CombatMetrics_Report_AbilitiesPanel)

function FightListPanel:Update()
	logger:Debug("Updating Ability Panel")

	local control = self.control
	if control:IsHidden() then return end

	local settings = self.settings
	local category = settings.category
	
	local recentPanel = control:GetNamedChild("Recent")
	local savedPanel = control:GetNamedChild("Saved")
	
	self:ResetBars(recentPanel)
	self:ResetBars(savedPanel)
	
	local label

	if category == "healingOut" or category == "healingIn" then
		label = GetString(SI_COMBAT_METRICS_HPS)
	else
		label = GetString(SI_COMBAT_METRICS_DPS)
	end

	GetControl(recentPanel, "HeaderDPS"):SetText(label)
	GetControl(savedPanel, "HeaderDPS"):SetText(label)

	self:UpdateSubPanel( false)
	self:UpdateSubPanel( true)
end


function FightListPanel:UpdateSubPanel(issaved)
	local stringId = issaved and "updateFightListPanelSaved" or "updateFightListPanelRecent"
	em:UnregisterForUpdate(stringId)

	local name, data
	if issaved then
		name = "Saved"
		data = CMX.lastfights
	else
		name = "Recent"
		data = CMXint.SVHandler.GetFights()
	end

	local panel = self.control:GetNamedChild(name)
	local category = self.settings.category

	local scrollchild = GetControl(panel, "PanelScrollChild")
	local currentanchor = {TOPLEFT, scrollchild, TOPLEFT, 0, 1}
	local rowBaseName = scrollchild:GetName() .. "Row"
	local DPSKey = DPSstrings[category]

	if #data > panel.numItems then
		for i = panel.numItems+1, #data do
			CreateControlFromVirtual(rowBaseName, scrollchild, "CombatMetrics_FightlistRowTemplate", i)
			panel.numItems = i
			if GetGameTimeSeconds() - GetFrameTimeSeconds() > 0.015 then
				em:RegisterForUpdate(stringId, 50, function() self:UpdateSubPanel(issaved) end)
				panel:GetNamedChild("LoadingLabel"):SetHidden(false)
				return
			end
		end
	end
	panel:GetNamedChild("LoadingLabel"):SetHidden(true)

	if #data > 0 then
		for id, fight in ipairs(data) do
			local label = zo_strgsub(fight.fightlabel or "", ".+%:%d%d %- ([A-Z])", "%1")
			local charname = fight.charData and fight.charData.name or fight.char or ""
			local zone = fight.zone or ""
			local subzone = fight.subzone or ""

			local zonestring = subzone ~= "" and string.format("%s, %s", subzone, zone) or nil
			local datestring = type(fight.date) == "number" and GetDateStringFromTimestamp(fight.date) or fight.date or ""
			local timestring = string.format("%s, %s", datestring, fight.time or "")

			local fightlog = issaved and fight.stringlog or fight.log
			local logState = fightlog and (fightlog == true or #fightlog>0)
			local activetime = 1

			if category == "healingOut" or category == "healingIn" then
				activetime = zo_roundToNearest(fight.hpstime or 1, 0.1)
			else
				activetime = zo_roundToNearest(fight.dpstime or 1, 0.1)
			end

			local durationstring = string.format("%d:%04.1f", activetime/60, activetime%60)		
			local dps = zo_round(fight.calculated and fight.calculated[DPSKey] or fight[DPSKey] or 0)

			-- CMX.Log(LOG_LEVEL_INFO, "Getting row: %s%d", rowBaseName, id)
			local row = GetControl(rowBaseName, id)
			row:SetAnchor(unpack(currentanchor))
			row:SetHidden(false)

			local header = panel:GetNamedChild("Header")
			adjustRowSize(row, header)

			local nameControl = row:GetNamedChild("Name")
			nameControl:SetText(label)

			local charControl = row:GetNamedChild("Char")
			charControl:SetText(charname)

			local zoneControl = row:GetNamedChild("Zone")
			zoneControl:SetText(zone)
			zoneControl.tooltip = zonestring

			local timeControl = row:GetNamedChild("Time")
			timeControl:SetText(timestring)

			local durationControl = row:GetNamedChild("Duration")
			durationControl:SetText(durationstring)

			local dpsControl = row:GetNamedChild("DPS")
			dpsControl:SetText(dps)

			local buttonControl = row:GetNamedChild("Buttons")
			local deleteLogControl = buttonControl:GetNamedChild("DeleteLog")
			deleteLogControl:SetState( logState and BSTATE_NORMAL or BSTATE_DISABLED )

			currentanchor = {TOPLEFT, row, BOTTOMLEFT, 0, dx}

			panel.bars[id] = row

			row.id = id
			row.issaved = issaved
		end
	end
end

function FightListPanel:Toggle(show)
	local control = self.control
	show = show or self.control:IsHidden()
	control:SetHidden(not show)
	if show then
		FightListPanel:Update()
	end

	CMXint.panels["InfoRow"]:Update()
end


function CMXint.LoadItem(listitem)
	local issaved = listitem.issaved
	local id = listitem.id
	local lastfights = CMX.lastfights

	local isLoaded, loadId
	local savedFight = CMXint.SVHandler.GetFight(id)

	if issaved and savedFight then
		-- returns false if nothing is found else it returns the id
		isLoaded, loadId = searchtable(lastfights, "date", savedFight["date"])
		if isLoaded then isLoaded = lastfights[loadId]["time"] == savedFight["time"] end		-- ensures old fights load correctly
	end

	CMXint.panels["FightList"]:Update()

	if issaved and isLoaded == false then
		local loadedfight = CMXint.SVHandler.Load(id)
		if loadedfight.log then CMX.AddFightCalculationFunctions(loadedfight) end
		table.insert(lastfights, loadedfight)

		CombatMetrics_Report:Update(#CMX.lastfights)
	else
		CombatMetrics_Report:Update((issaved and loadId or id))
	end

	CMXint.ClearSelections()
end

function CMXint.DeleteItem(control)
	local row = control:GetParent():GetParent()
	local issaved = row.issaved
	local id = row.id

	if issaved then
		CMXint.SVHandler.Delete(id)
		CombatMetrics_Report:Update()
	else
		table.remove(CMX.lastfights, id)
		if #CMX.lastfights == 0 then CombatMetrics_Report:Update() else CombatMetrics_Report:Update(zo_min(currentFight, #CMX.lastfights)) end
	end

	CMXint.panels["FightList"]:Update()
end


function CMXint.DeleteItemLog(control)
	local row = control:GetParent():GetParent()
	local issaved = row.issaved
	local id = row.id

	if issaved then
		CMXint.SVHandler.DeleteLog(id)
	else
		CMX.lastfights[id]["log"]={}
	end

	CMXint.panels["FightList"]:Update()
end

local isFileInitialized = false
function CMXint.InitializeFightListPanel()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("FightList")

    isFileInitialized = true
	return true
end