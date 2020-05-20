local em = GetEventManager()
local wm = GetWindowManager()
local dx = LIBCOMBAT_LINE_SIZE or math.ceil(GuiRoot:GetWidth()/tonumber(GetCVar("WindowedWidth"))*1000)/1000
COMBAT_METRICS_LINE_SIZE = tostring(dx)
local fontsize = tonumber(GetString(SI_COMBAT_METRICS_FONT_SIZE_SMALL))
local currentFight
local abilitystats
local abilitystatsversion = 3
local fightData, selectionData
local currentCLPage
local selections, lastSelections
local savedFights
local SVHandler
local ToggleFeedback
local barKeyOffset = 1
local enlargedGraph = false
local maxXYPlots = 5
local maxBarPlots = 8
local skillpage = 0
local uncollapsedBuffs = {

}

local LOG_LEVEL_VERBOSE, LOG_LEVEL_DEBUG, LOG_LEVEL_INFO, LOG_LEVEL_WARNING, LOG_LEVEL_ERROR = CMX.GetDebugLevels()

local CMX = CMX
if CMX == nil then CMX = {} end
local _
local db

function CMX.GetAbilityStats()

	local isSelection = selections.unit.damageOut ~= nil
	return abilitystats, abilitystatsversion, isSelection

end

local LC = LibCombat
if LC == nil then return end

local GetFormattedAbilityName = LC.GetFormattedAbilityName

local GetFormattedAbilityIcon = LC.GetFormattedAbilityIcon

local function searchtable(t, field, value)

	if value == nil then return false end

	for k, v in pairs(t) do

		if type(v) == "table" and field and v[field] == value then

			return true, k

		elseif v == value then

			return true, k

		end
	end

	return false, nil
end


local function storeOrigLayout(self)

	self.sizes = {self:GetDimensions()}
	self.anchors = {}
	--self.anchors = {{self:GetAnchor(0)}, {self:GetAnchor(1)}}

	local anchors = self.anchors

	for i = 1, 2 do

		local valid, point, relativeTo, relativePoint, x, y, constrains = self:GetAnchor(i-1)

		if valid then anchors[i] = {point, relativeTo, relativePoint, x, y, constrains} end

	end

	for i = 1, self:GetNumChildren() do

		local child = self:GetChild(i)
		if child then storeOrigLayout(child) end

	end
end

local function toggleFightList(panel, show)

	panel = panel or CombatMetrics_Report_FightList

	show = show or panel:IsHidden()

	panel:SetHidden(not show)

	if show then

		panel:Update()
		panel:GetParent():GetNamedChild("_InfoRow"):Update()

	end

end

function CMX.EditTitleStart(control)

	local label = control:GetNamedChild("Name")
	local editbox = control:GetNamedChild("Edit")

	label:SetHidden(true)
	editbox:SetHidden(false)

	editbox:SetText( label:GetText() )
	editbox:SelectAll()
	editbox:TakeFocus()

end

function CMX.EditTitleEnd(editbox)

	local control = editbox:GetParent()
	local label = control:GetNamedChild("Name")

	editbox:SetHidden(true)
	label:SetHidden(false)

	local newtext = editbox:GetText()

	label:SetText( newtext )

	if fightData then fightData.fightlabel = newtext end

end


local NavButtonFunctions = {}

function NavButtonFunctions.previous(control)

	if control:GetState() == BSTATE_DISABLED then
		return
	else
		CombatMetrics_Report:Update(currentFight-1)
	end

end

function NavButtonFunctions.next(control)

	if control:GetState() == BSTATE_DISABLED then
		return
	else
		CombatMetrics_Report:Update(currentFight+1)
	end

end

function NavButtonFunctions.last(control)

	if control:GetState() == BSTATE_DISABLED then
		return
	else
		CombatMetrics_Report:Update(#CMX.lastfights)
	end

end

function NavButtonFunctions.load(control)

	if control:GetState() == BSTATE_DISABLED then
		return
	else
		toggleFightList()
	end

end

local function checkSaveLimit(fight)

	local size = SVHandler.Check(fight)									-- if no table is passed it will check size of the SV

	if fight == nil then

		CMX.Print("save", LOG_LEVEL_DEBUG, "SV Size: %.3f MB, %.1f%%", size, size*100/db.maxSVsize)

	end

	local isvalid = (size < db.maxSVsize)

	return isvalid, size
end

function NavButtonFunctions.save(control, _, _, _, _, shiftkey )

	if control:GetState() == BSTATE_DISABLED then

		return

	else

		local lastsaved = savedFights[#savedFights]

		if lastsaved ~= nil and lastsaved.date == fightData.date then return end --bail out if fight is already saved

		SVHandler.Save(fightData, shiftkey)

		local isvalid, size = checkSaveLimit()

		if isvalid then

			db.SVsize = size
			CombatMetrics_Report:Update()

		else

			local removed = table.remove(savedFights)
			local _, removedSize = checkSaveLimit(removed)

			local errorstring = zo_strformat(SI_COMBAT_METRICS_STORAGE_FULL, removedSize)
			assert(false, errorstring)

			CombatMetrics_Report:Update()

		end
	end
end

local function ClearSelections()

	local category = db.FightReport.category or "damageOut"

	selections["ability"][category] = nil
	selections["unit"][category] = nil
	selections["buff"]["buff"] = nil
	selections["resource"]["resource"] = nil

end

function NavButtonFunctions.delete(control)

	if control:GetState() == BSTATE_DISABLED then

		return

	else

		table.remove(CMX.lastfights, currentFight)
		ClearSelections()

		if #CMX.lastfights == 0 then CombatMetrics_Report:Update() else CombatMetrics_Report:Update(math.min(currentFight, #CMX.lastfights)) end

	end
end

function CMX.InitNavButtons(rowControl)

	for i=1, rowControl:GetNumChildren() do

		local child = rowControl:GetChild(i)

		if child then child:SetHandler( "OnMouseUp", NavButtonFunctions[child.func]) end

	end
end

local function selectCategory(button)

	local control = button:GetParent()

	for i=1, 4 do

		local child = control:GetChild(i)

		local r, g, b, _ = child:GetColor()
		local a = child == button and 1 or .2

		child:SetColor(r, g, b, a)

	end

	db.FightReport.category = button.category

	if CMX and CMX.init then CombatMetrics_Report:Update(currentFight) end

end

local function selectMainPanel(button)

	local selectControl = button:GetParent()
	local category = button.category

	for i = 5, 8 do

		local child = selectControl:GetChild(i)

		local a = child == button and 1 or .2

		child:SetColor(1, 1, 1, a)

	end

	local mainPanel = CombatMetrics_Report_MainPanel
	local rightPanel = CombatMetrics_Report_RightPanel
	local unitPanel = CombatMetrics_Report_UnitPanel
	local abilityPanel = CombatMetrics_Report_AbilityPanel
	local infoPanel = CombatMetrics_Report_InfoPanel
	local graphPanel = CombatMetrics_Report_MainPanelGraph

	local isInfo = category == "Info"

	mainPanel:SetHidden(isInfo)
	rightPanel:SetHidden(isInfo)
	unitPanel:SetHidden(isInfo)
	abilityPanel:SetHidden(isInfo)
	infoPanel:SetHidden(not isInfo)

	local isGraph = category == "Graph"

	graphPanel:SetHidden(not isGraph)

	if not isInfo then

		local selected = mainPanel:GetNamedChild(category) -- Panel Content to show
		mainPanel.active = selected

		for i = 2, mainPanel:GetNumChildren() do

			local child = mainPanel:GetChild(i)

			child:SetHidden(child ~= selected) -- Hide all other panels except the selected panel

		end

		selected:Update()

	else

		infoPanel:Update()

	end
end

local function toggleInfoPanel(button)

	local selectControl = button:GetParent()

	for i=5, 8 do

		local child = selectControl:GetChild(i)

		local a = child == button and 1 or .2

		child:SetColor(1, 1, 1, a)

	end

	local mainpanel = CombatMetrics_Report_MainPanel
	local rightpanel = CombatMetrics_Report_RightPanel
	local infopanel = CombatMetrics_Report_InfoPanel

	mainpanel:SetHidden(true)
	rightpanel:SetHidden(true)
	infopanel:SetHidden(false)

end

local ValidRaids = {

	[7] = true, -- vHoF
	[8] = true, -- vAS
	[9] = true, -- vCR
	[12] = true, -- vSS

}

local function updateSelectorButtons(selectorButtons)

	db.currentNotificationVersion = 1

	local date = GetDate()

	local isMe = GetDisplayName() == "@Solinur"
	local isGerman = GetCVar("Language.2") == "de"
	local isEUServer = GetWorldName() == "EU Megaserver"
	local isNotInGuild = not IsPlayerInGuild(64745)
	local isNotificationAllowed = db.NotificationAllowed and db.currentNotificationVersion > db.NotificationRead
	local isVeteranRaid = ValidRaids[GetCurrentParticipatingRaidId()] == true
	local isWithinAllowedTime = date >= 20200417 and date <= 20200423

	local show = db.ForceNotification or ((isGerman or isMe) and isEUServer and isNotificationAllowed and isVeteranRaid and isWithinAllowedTime)

	if false then

		df("Result: %s, De: %s, EU: %s, G: %s, R: %s, T: %s, Set: %s (%s, %d / %d)",
			tostring(show),
			tostring(isGerman),
			tostring(isEUServer),
			tostring(isNotInGuild),
			tostring(isVeteranRaid),
			tostring(isWithinAllowedTime),
			tostring(isNotificationAllowed),
			tostring(db.NotificationAllowed),
			db.currentNotificationVersion,
			db.NotificationRead
		)

	end

	selectorButtons:GetNamedChild("NotificationButton"):SetHidden(not show)

end

local function initSelectorButtons(selectorButtons)

	for i = 1, 8 do

		local child = selectorButtons:GetChild(i)

		if child and i <= 4 then

			child:SetHandler( "OnMouseUp", selectCategory)
			if child.category == db.FightReport.category then selectCategory(child) end

		elseif child and i>4 then

			child:SetHandler( "OnMouseUp", selectMainPanel)
			selectMainPanel(selectorButtons:GetNamedChild("FightStatsButton"))

		end
	end
end

function CMX.InitializeCPRows(panel)

	for i = 1, 9 do

		local discipline = (7-i)%9+1	-- start with apprentice and then clockwise (seriously, how did they come up with those ids?)

		local color = GetString(SI_COMBAT_METRICS_MAGICKA_COLOR)

		if i > 6 then

			color = GetString(SI_COMBAT_METRICS_STAMINA_COLOR)

		elseif i > 3 then

			color = GetString(SI_COMBAT_METRICS_HEALTH_COLOR)

		end

		local signcontrol = panel:GetNamedChild("StarSign"..i)

		local title = signcontrol:GetNamedChild("Title")

		title:SetText(zo_strformat(SI_CHAMPION_CONSTELLATION_NAME_FORMAT, GetChampionDisciplineName(discipline)))

		local width = title:GetTextWidth() + 4
		local height = title:GetHeight()

		title:SetDimensions(width, height)

		CMX.SetLabelColor(signcontrol, color)

		for i = 1, 4 do

			local row = signcontrol:GetNamedChild("Row"..i)

			local label = row:GetNamedChild("Name")

			label:SetText(zo_strformat(SI_CHAMPION_CONSTELLATION_NAME_FORMAT, GetChampionSkillName(discipline, i)))

			row.discipline = discipline
			row.skillId = i
			row.points = 0

			local passive = signcontrol:GetNamedChild("Passive"..i)

			passive.discipline = discipline
			passive.skillId = i + 4
			passive.points = 0

		end
	end
end

function CMX.InitializeSkillStats(panel)

	local block = panel:GetNamedChild("AbilityBlock1")
	local title = block:GetNamedChild("Title")
	title:SetText(GetString(SI_COMBAT_METRICS_BAR) .. 1)

	local statPanel = block:GetNamedChild("Stats2")
	local label = statPanel:GetNamedChild("Label")
	local label2 = statPanel:GetNamedChild("Label2")

	label.tooltip = {SI_COMBAT_METRICS_SKILLAVG_TT}
	label:SetText(string.format("%s    -", GetString(SI_COMBAT_METRICS_AVERAGEC)))
	label2.tooltip = {SI_COMBAT_METRICS_SKILLTOTAL_TT}
	label2:SetText(string.format("%s    -", GetString(SI_COMBAT_METRICS_TOTALC)))

	local block2 = panel:GetNamedChild("AbilityBlock2")
	local title2 = block2:GetNamedChild("Title")
	title2:SetText(GetString(SI_COMBAT_METRICS_BAR) .. 2)

	local statPanel2 = block2:GetNamedChild("Stats2")
	local label3 = statPanel2:GetNamedChild("Label")
	local label4 = statPanel2:GetNamedChild("Label2")

	label3:SetText(string.format("%s    -", GetString(SI_COMBAT_METRICS_TOTALWA)))
	label3.tooltip = {SI_COMBAT_METRICS_TOTALWA_TT}

	label4:SetText(string.format("%s    -", GetString(SI_COMBAT_METRICS_TOTALSKILLS)))
	label4.tooltip = {SI_COMBAT_METRICS_TOTALSKILLS_TT}

end

local function CLNavButtonFunction(self)

	currentCLPage = tonumber(self.value or (currentCLPage + self.func))
	self:GetParent():GetParent():GetParent():Update()

end

function CMX.InitCLNavButtonRow(rowControl)

	for i=1, rowControl:GetNumChildren() do

		local button = rowControl:GetChild(i)

		if button.texture then button:GetNamedChild("Icon"):SetTexture(button.texture) end

		local value = button.value

		if value then

			button:GetNamedChild("Label"):SetText(value)
			button.tooltip = {zo_strformat(SI_COMBAT_METRICS_PAGE, value)}

		end

		button:SetHandler( "OnMouseUp", CLNavButtonFunction )

	end

end

local function CLFilterButtonFunction(self)

	local overlay = self:GetNamedChild("Overlay")
	local func = self.func

	db.FightReport.CLSelection[func] = not db.FightReport.CLSelection[func]	-- Update Filter Selection

	overlay:SetCenterColor( 0 , 0 , 0 , db.FightReport.CLSelection[func] and 0 or 0.8 ) -- Switch Button overlay (active = button darkened)
	overlay:SetEdgeColor( 1 , 1 , 1 , db.FightReport.CLSelection[func] and 1 or .4 )

	self:GetParent():GetParent():GetParent():Update()

end

local function initCLButtonRow(rowControl)

	for i=1, rowControl:GetNumChildren() do

		local button = rowControl:GetChild(i)

		if button.texture then button:GetNamedChild("Icon"):SetTexture(button.texture) end

		if button.label then button:GetNamedChild("Label"):SetText(button.label) end

		button:SetHandler( "OnMouseUp", CLFilterButtonFunction )

		local selected = db.FightReport.CLSelection[button.func]
		local overlay = button:GetNamedChild("Overlay")

		overlay:SetCenterColor( 0 , 0 , 0 , selected and 0 or 0.8 )
		overlay:SetEdgeColor( 1 , 1 , 1 , selected and 1 or .5 )

	end

end

local function adjustSlider(self)

	local buffer = self:GetNamedChild("Buffer")
	local slider = self:GetNamedChild("Slider")

	local numHistoryLines = buffer:GetNumHistoryLines()
	local numVisHistoryLines = math.floor((buffer:GetNumVisibleLines()+1)/dx) --it seems numVisHistoryLines is getting screwed by UI Scale
	local bufferScrollPos = buffer:GetScrollPosition()

	local sliderMin, sliderMax = slider:GetMinMax()
	local sliderValue = slider:GetValue()

	slider:SetMinMax(numVisHistoryLines, numHistoryLines)


	if sliderValue == sliderMax then -- If the sliders at the bottom, stay at the bottom to show new text

		slider:SetValue(numHistoryLines)

	elseif numHistoryLines == self:GetNamedChild("Buffer"):GetMaxHistoryLines() then -- If the buffer is full start moving the slider up

		slider:SetValue(sliderValue-1)

	end -- Else the slider does not move


	if numHistoryLines > numVisHistoryLines then -- If there are more history lines than visible lines show the slider

		slider:SetHidden(false)
		slider:SetThumbTextureHeight(math.max(20, math.floor(numVisHistoryLines/numHistoryLines*self:GetNamedChild("Slider"):GetHeight())))

	else -- else hide the slider

		slider:SetHidden(true)

	end
end

local function addColoredText(control, text, color)

	if not text or #color~=3 then return end

	local red 	= color[1] or 1
	local green = color[2] or 1
	local blue 	= color[3] or 1

	control:GetNamedChild("Buffer"):AddMessage(text, red, green, blue) -- Add message first

	if control:GetNamedChild("Slider") then adjustSlider(control) end -- Set new slider value & check visibility

end

function CMX.InitCombatLog(control)

	control.AddColoredText = addColoredText

	local buffer = control:GetNamedChild("Buffer")
	local slider = control:GetNamedChild("Slider")

	buffer:SetHandler("OnMouseWheel", function(self, delta, ctrl, alt, shift)

		local offset = delta
		local slider = buffer:GetParent():GetNamedChild("Slider")

		if shift then

			offset = offset * math.floor((buffer:GetNumVisibleLines())/dx) -- correct for ui scale

		elseif ctrl then

			offset = offset * buffer:GetNumHistoryLines()

		end

		buffer:SetScrollPosition(math.min(buffer:GetScrollPosition() + offset, math.floor(buffer:GetNumHistoryLines()-(buffer:GetNumVisibleLines())/dx))) -- correct for ui scale

		slider:SetValue(slider:GetValue() - offset)

	end)

	slider:SetHandler("OnValueChanged", function(self, value, eventReason)

		local numHistoryLines = buffer:GetNumHistoryLines()
		local sliderValue = math.max(slider:GetValue(), math.floor((buffer:GetNumVisibleLines()+1)/dx)) -- correct for ui scale

		if eventReason == EVENT_REASON_HARDWARE then
			buffer:SetScrollPosition(numHistoryLines-sliderValue)
		end
	end)

	-- Assign Button Functions

	local scrollUp = slider:GetNamedChild("ScrollUp")
	local scrollDown = slider:GetNamedChild("ScrollDown")
	local scrollEnd = slider:GetNamedChild("ScrollEnd")

	scrollUp:SetHandler("OnMouseDown", function(...)
		buffer:SetScrollPosition(math.min(buffer:GetScrollPosition()+1, math.floor(buffer:GetNumHistoryLines()-(buffer:GetNumVisibleLines())/dx))) -- correct for ui scale
		slider:SetValue(slider:GetValue()-1)
	end)

	scrollDown:SetHandler("OnMouseDown", function(...)
		buffer:SetScrollPosition(buffer:GetScrollPosition()-1)
		slider:SetValue(slider:GetValue()+1)
	end)

	scrollEnd:SetHandler("OnMouseDown", function(...)
		buffer:SetScrollPosition(0)
		slider:SetValue(buffer:GetNumHistoryLines())
	end)

end

local function AddTooltipLine(control, tooltipControl, tooltip)

	local tooltipTextType = type(tooltip)

	if tooltipTextType == "string" then

		if tooltip == "" then ZO_Options_OnMouseExit(control) return end

	elseif tooltipTextType == "number" then	tooltip = GetString(tooltip)

	elseif tooltipTextType == "function" then tooltip = tooltip()

	else ZO_Options_OnMouseExit(control) return end

	SetTooltipText(tooltipControl, tooltip)

end

function CMX.OnMouseEnter(control) --copy from ZO_Options_OnMouseEnter but modified to support multiple tooltip lines

	local tooltipText = control.tooltip

    if tooltipText ~= nil and #tooltipText>0 then

		InitializeTooltip(InformationTooltip, control, BOTTOMLEFT, 0, -2, TOPLEFT)

		if type(tooltipText) == "table" then

			for i=1, #tooltipText do

				AddTooltipLine(control, InformationTooltip, tooltipText[i])

			end

		else

			AddTooltipLine(control, InformationTooltip, tooltipText)

		end
	end
end

function CMX.SetLabelColor(control, setcolor)  -- setcolor can be hex or rgba, ZO_ColorDef takes care of this

	for i=1, control:GetNumChildren(control) do

		local child = control:GetChild(i)
		local color = ZO_ColorDef:New(setcolor)

		if child:GetType() == CT_LABEL and child.nocolor ~= true then

			child:SetColor(color.r, color.g, color.b, color.a)

		elseif child:GetType() == CT_CONTROL and child.nocolor ~= true then

			CMX.SetLabelColor(child, setcolor)

		end

	end

end

function CMX.UpdateAttackStatsSelector(control)

	local selector = control:GetParent()

	for _, powerType in pairs{"Magicka", "Stamina", "Health"} do

		local control = selector:GetNamedChild(powerType)

		control:GetNamedChild("Line"):SetColor(0.53, 0.53, 0.53, 1)
		control:GetNamedChild("Icon"):SetAlpha(0.5)

	end

	local line = control:GetNamedChild("Line")
	local color = line.color

	line:SetColor(color.r, color.g, color.b, color.a)
	control:GetNamedChild("Icon"):SetAlpha(1)

	local mainPanelRight = selector:GetParent()
	local labels = mainPanelRight:GetNamedChild("AttackStats")

	CMX.SetLabelColor(labels, color)

	db.FightReport.fightstatspanel = control.powerType

	mainPanelRight:Update()
end

function CMX.SelectRightPanel(control)

	local rightpanel = control.menukey
	db.FightReport.rightpanel = rightpanel

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

	panel:Update()
	CombatMetrics_Report_MainPanelGraph:Update()

end

function CMX.SavePosition(control)

	local x, y = control:GetCenter()

	-- Save the Position
	db[control:GetName()] = { ["x"] = x, ["y"] = y}

end

function CMX.LoadItem(listitem)

	local issaved = listitem.issaved
	local id = listitem.id

	local lastfights = CMX.lastfights

	local isLoaded, loadId

	if issaved and savedFights[id] then

		isLoaded, loadId = searchtable(lastfights, "date", savedFights[id]["date"])					-- returns false if nothing is found else it returns the id
		if isLoaded then isLoaded = lastfights[loadId]["time"] == savedFights[id]["time"] end		-- ensures old fights load correctly

	end

	toggleFightList()

	if issaved and isLoaded == false then

		local loadedfight = SVHandler.Load(id)

		if loadedfight.log then CMX.AddFightCalculationFunctions(loadedfight) end

		table.insert(lastfights, loadedfight)
		CombatMetrics_Report:Update(#CMX.lastfights)

	else

		CombatMetrics_Report:Update((issaved and loadId or id))

	end

	ClearSelections()

end

function CMX.DeleteItem(control)

	local row = control:GetParent():GetParent()
	local issaved = row.issaved
	local id = row.id

	if issaved then

		table.remove(savedFights, id)

		local _, size = checkSaveLimit()
		db.SVsize = size

		CombatMetrics_Report:Update()

	else

		table.remove(CMX.lastfights, id)
		if #CMX.lastfights == 0 then CombatMetrics_Report:Update() else CombatMetrics_Report:Update(math.min(currentFight, #CMX.lastfights)) end

	end

	toggleFightList(nil, true)

end

function CMX.DeleteItemLog(control)

	local row = control:GetParent():GetParent()
	local issaved = row.issaved
	local id = row.id

	if issaved then
		savedFights[id]["stringlog"]={}
	else
		CMX.lastfights[id]["log"]={}
	end

	toggleFightList(nil, true)

end

--Slash Commands

CMX_POSTTOCHAT_MODE_NONE = 0
CMX_POSTTOCHAT_MODE_SINGLE = 1
CMX_POSTTOCHAT_MODE_MULTI = 2
CMX_POSTTOCHAT_MODE_SINGLEANDMULTI = 3
CMX_POSTTOCHAT_MODE_SMART = 4
CMX_POSTTOCHAT_MODE_HEALING = 5
CMX_POSTTOCHAT_MODE_SELECTION = 6
CMX_POSTTOCHAT_MODE_SELECTION_HEALING = 7
CMX_POSTTOCHAT_MODE_SELECTED_UNIT = 8
CMX_POSTTOCHAT_MODE_SELECTED_UNITNAME = 9


local function slashCommandFunction(extra)

	if 		extra == "reset" 	then CMX.ResetFight()
	elseif 	extra == "dps" 		then CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SMART)
	elseif 	extra == "totdps" 	then CMX.PosttoChat(CMX_POSTTOCHAT_MODE_MULTI)
	elseif 	extra == "alldps" 	then CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SINGLEANDMULTI)
	elseif 	extra == "hps" 		then CMX.PosttoChat(CMX_POSTTOCHAT_MODE_HEALING)
	else 						CombatMetrics_Report:Toggle()
	end

end

SLASH_COMMANDS["/cmx"] = slashCommandFunction

do	-- Handling Buffs Context Menu

	local favs
	local buffname
	local unitType

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

		CombatMetrics_Report:GetNamedChild("_RightPanel"):GetNamedChild("BuffList"):Update()

	end

	function CMX.BuffContextMenu( bufflistitem, upInside )

		if not upInside then return end

		buffname = bufflistitem.dataId
		favs = db.FightReport.FavouriteBuffs
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

		local category = db.FightReport.category

		if (category == "damageOut" or category == "damageIn") and db.FightReport.rightpanel == "buffsout" then

			unitType = "boss"
			AddCustomMenuItem(GetString(SI_COMBAT_METRICS_POSTBUFF_BOSS), postSelectionBuffUptime)

		elseif (category == "healingOut" or category == "healingIn") and db.FightReport.rightpanel == "buffsout" then

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

	CombatMetrics_Report:GetNamedChild("_RightPanel"):GetNamedChild("BuffList"):Update()

end

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

		local category = db.FightReport.category

		if not (upInside or category == "damageOut" or category == "healingOut") then return end

		local dataId = unitItem.dataId

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

do

	local function toggleShowIds()

		db.showDebugIds = not db.showDebugIds
		CombatMetrics_Report:Update()

	end

	local function toggleShowPets()

		db.FightReport.showPets = not db.FightReport.showPets
		CombatMetrics_Report:Update()

	end

	local function toggleOverhealMode()

		CMX.showOverHeal = not CMX.showOverHeal
		CombatMetrics_Report:Update()

	end

	local function postSingleDPS()

		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SINGLE, currentFight)

	end

	local function postSmartDPS()

		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SMART, currentFight)

	end

	local function postMultiDPS()

		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_MULTI, currentFight)

	end

	local function postAllDPS()

		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SINGLEANDMULTI, currentFight)

	end

	local function postSelectionDPS()

		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SELECTION, currentFight)

	end

	local function postHPS()

		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_HEALING, currentFight)

	end

	local function postSelectionHPS()

		CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SELECTION_HEALING, currentFight)

	end

	function CMX.SettingsContextMenu( settingsbutton, upInside )

		if not upInside then return end

		local showIdString = db.showDebugIds and SI_COMBAT_METRICS_HIDEIDS or SI_COMBAT_METRICS_SHOWIDS
		local showOverhealString = CMX.showOverHeal and SI_COMBAT_METRICS_HIDEOVERHEAL or SI_COMBAT_METRICS_SHOWOVERHEAL
		local showPetString = db.FightReport.showPets and SI_COMBAT_METRICS_MENU_HIDEPETS or SI_COMBAT_METRICS_MENU_SHOWPETS_NAME

		local postoptions = {}

		table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTSINGLEDPS), callback = postSingleDPS})

		local fight = CMX.lastfights[currentFight]

		if fight and fight.bossfight == true then

			table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTSMARTDPS), callback = postSmartDPS})

		end

		table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTMULTIDPS), callback = postMultiDPS})
		table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTALLDPS), callback = postAllDPS})

		local category = db.FightReport.category

		if category == "damageOut" and selections.unit[category] then

			table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTSELECTIONDPS), callback = postSelectionDPS})

		end

		table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTHPS), callback = postHPS})

		if category == "healingOut" and selections.unit[category] then

			table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTSELECTIONHPS), callback = postSelectionHPS})

		end

		ClearMenu()

		AddCustomMenuItem(GetString(showIdString), toggleShowIds)
		AddCustomMenuItem(GetString(showOverhealString), toggleOverhealMode)
		AddCustomMenuItem(GetString(showPetString), toggleShowPets)
		AddCustomSubMenuItem(GetString(SI_COMBAT_METRICS_POSTDPS), postoptions)
		AddCustomMenuItem(GetString(SI_COMBAT_METRICS_SETTINGS), CMX.OpenSettings)

		if fight and fight.CalculateFight and (fight.svversion == nil or fight.svversion > 2) then

			local function calculate()

				fight:CalculateFight()
				CombatMetrics_Report:Update(currentFight)

			end

			AddCustomMenuItem(GetString(SI_COMBAT_METRICS_RECALCULATE), calculate)

		end

		if LibFeedback then AddCustomMenuItem(GetString(SI_COMBAT_METRICS_FEEDBACK), ToggleFeedback) end

		ShowMenu(settingsbutton)
		AnchorMenu(settingsbutton)

	end
end

do

	local function ShowGuildInfo()

		GUILD_BROWSER_GUILD_INFO_KEYBOARD:SetGuildToShow(64745)
        MAIN_MENU_KEYBOARD:ShowSceneGroup("guildsSceneGroup", "linkGuildInfoKeyboard")
        GUILD_BROWSER_GUILD_INFO_KEYBOARD.closeCallback = CombatMetrics_Report.Toggle

	end

	local function NotificationRead()

		db.NotificationRead = db.currentNotificationVersion
		CombatMetrics_Report:Update(currentFight)

	end

	local function DisableNotifications()

		db.NotificationRead = db.currentNotificationVersion
		db.NotificationAllowed = false
		CombatMetrics_Report:Update(currentFight)

	end

	function CMX.NotificationContextMenu( settingsbutton, upInside )

		if not upInside then return end

		ClearMenu()

		AddCustomMenuItem(GetString(SI_COMBAT_METRICS_NOTIFICATION_GUILD), ShowGuildInfo)
		AddCustomMenuItem(GetString(SI_COMBAT_METRICS_NOTIFICATION_ACCEPT), NotificationRead)
		AddCustomMenuItem(GetString(SI_COMBAT_METRICS_NOTIFICATION_DISCARD), DisableNotifications)

		ShowMenu(settingsbutton)
		AnchorMenu(settingsbutton)

	end
end

--function CMX.AddSelection( selecttype, id, dataId, shiftkey, controlkey, button )  -- IsShiftKeyDown() IsControlKeyDown() IsCommandKeyDown()

function CMX.AddSelection( self, button, upInside, ctrlkey, alt, shiftkey )

	local id = self.id
	local dataId = self.dataId
	local selecttype = self.type

	if button ~= MOUSE_BUTTON_INDEX_LEFT and button ~= MOUSE_BUTTON_INDEX_MIDDLE then return end

	local category = selecttype == "buff" and "buff" or selecttype == "resource" and "resource" or db.FightReport.category

	local sel = selections[selecttype][category] -- can be nil so this is not always a reference
	local lastsel = lastSelections[selecttype][category]
	local bars = self.panel.bars


	if button == MOUSE_BUTTON_INDEX_MIDDLE then

		selections[selecttype][category] = nil
		lastSelections[selecttype][category] = nil
		CombatMetrics_Report:Update(currentFight)

		return
	end

	if sel == nil then	-- if nothing is selected yet, just select this, disregarding all modifiers.

		sel = {[dataId] = id}
		lastsel = id

	elseif shiftkey and not ctrlkey and lastsel ~= nil then 	-- select everything between this and the previous sel if shiftkey is pressed

		local istart = math.min(lastsel, id)
		local iend = math.max(lastsel, id)

		sel = {} 	-- forget/disregard other selections

		for i=istart, iend do

			local irowcontrol = bars[i]
			sel[irowcontrol.dataId] = i

		end

	elseif ctrlkey and not shiftkey then	-- toggle additional sel if ctrlkey is pressed

		if sel[dataId] ~= nil then

			lastsel = nil
			sel[dataId] = nil

		else

			lastsel = id
			sel[dataId] = id

		end

	elseif shiftkey and ctrlkey and lastsel ~= nil then  -- additionally select everything between this and the previous sel if ctrlkey + shift key is pressed

		local istart = math.min(lastsel, id)
		local iend = math.max(lastsel, id)

		for i=istart, iend do

			local irowcontrol = bars[i]
			sel[irowcontrol.dataId] = i

		end

	elseif not shiftkey and not ctrlkey then -- normal LMB click

		if lastsel == id and sel[dataId] ~= nil then -- remove sel if this was pressed just before

			lastsel = nil
			sel = nil

		else

			lastsel = id
			sel = {[dataId] = id}

		end
	end

	lastSelections[selecttype][category] = lastsel
	selections[selecttype][category] = sel
	CombatMetrics_Report:Update(currentFight)
end

local function UpdateReport2()
	CombatMetrics_Report:Update()
end

local function updateTitlePanel(panel)

	CMX.Print("UI", LOG_LEVEL_DEBUG, "Updating TitlePanel")

	-- update character info

	local charInfo = panel:GetNamedChild("CharacterInfo")
	local charData = {}
	local fightlabel

	if fightData == nil then

		charData.name = GetUnitName("player")
		charData.raceId = GetUnitRaceId("player")
		charData.gender = GetUnitGender("player")
		charData.classId = GetUnitClassId("player")
		charData.level = GetUnitLevel("player")
		charData.CPtotal = GetUnitChampionPoints("player")

		fightlabel = "Combat Metrics"

	elseif (fightData.charData == nil or fightData.charData.classId == nil) and fightData.char == GetUnitName("player") then   -- legacy

		charData.name = fightData.char
		charData.raceId = GetUnitRaceId("player")
		charData.gender = GetUnitGender("player")
		charData.classId = GetUnitClassId("player")
		charData.level = 0
		charData.CPtotal = 0

		fightData.charData = charData
		fightlabel = string.gsub(fightData.fightlabel, ".+%:%d%d %- ([A-Z])", "%1") or ""

	else

		charData = fightData.charData or {}
		charData.name = charData.name or fightData.char
		fightlabel = string.gsub(fightData.fightlabel, ".+%:%d%d %- ([A-Z])", "%1") or ""

	end

	-- RaceIcon

	local racetextures = {
		"esoui/art/icons/heraldrycrests_race_breton_01.dds",
		"esoui/art/icons/heraldrycrests_race_redguard_01.dds",
		"esoui/art/icons/heraldrycrests_race_orc_01.dds",
		"esoui/art/icons/heraldrycrests_race_dunmer_01.dds",
		"esoui/art/icons/heraldrycrests_race_nord_01.dds",
		"esoui/art/icons/heraldrycrests_race_argonian_01.dds",
		"esoui/art/icons/heraldrycrests_race_altmer_01.dds",
		"esoui/art/icons/heraldrycrests_race_bosmer_01.dds",
		"esoui/art/icons/heraldrycrests_race_khajiit_01.dds",
		"esoui/art/icons/heraldrycrests_race_imperial_01.dds",
		}

	local raceIcon = charInfo:GetNamedChild("RaceIcon")
	local raceId = charData.raceId
	local gender = charData.gender

	raceIcon:SetHidden(raceId == nil)
	raceIcon:SetTexture(racetextures[raceId])

	local race = GetRaceName(gender, raceId)
	raceIcon.tooltip = race

	-- ClassIcon

	local classIcon = charInfo:GetNamedChild("ClassIcon")
	local classId = charData.classId

	for i=1, GetNumClasses() do

		local id, _, _, _, _, _, texture = GetClassInfo(i)

		if id == classId then

			local class = GetClassName(gender, id)

			classIcon:SetTexture(texture)
			classIcon.tooltip = {class}
			classIcon:SetHidden(false)

			break
		end

		classIcon:SetHidden(true)
	end

	-- charName

	local charName = charInfo:GetNamedChild("Charname")
	local name = charData.name

	charName:SetText(name)

	-- CPValue

	local CPIcon = charInfo:GetNamedChild("CPIcon")
	local CPValue = charInfo:GetNamedChild("CPValue")

	local level = charData.level
	local CP = charData.CPtotal

	if level == nil or level == 0 then

		CPIcon:SetHidden(true)
		CPValue:SetHidden(true)

	elseif level < 50 then

		CPIcon:SetHidden(true)
		CPValue:SetHidden(false)
		CPValue:SetText(level)

	else

		CPIcon:SetHidden(false)
		CPValue:SetHidden(false)
		CPValue:SetText(CP)

	end

	-- Fight Title

	local fightTitle = panel:GetNamedChild("FightTitle"):GetNamedChild("Name")
	fightTitle:SetText(fightlabel)

	-- Nav Buttons

	local NavButtons = panel:GetNamedChild("NavigationRow")

	local fightId = currentFight or 0

	local ButtonStates = {

		["previous"] 	= CMX.lastfights[fightId - 1] ~= nil,
		["next"] 		= CMX.lastfights[fightId + 1] ~= nil,
		["last"] 		= CMX.lastfights[fightId + 1] ~= nil,
		["load"] 		= savedFights ~= nil and #savedFights > 0,
		["save"] 		= CMX.lastfights[fightId] ~= nil and not searchtable(savedFights, "date", fightData.date),
		["delete"] 		= CMX.lastfights[fightId] ~= nil and #CMX.lastfights>0 ~= nil
	}

	for i = 1, NavButtons:GetNumChildren() do

		local child = NavButtons:GetChild(i)
		local state = ButtonStates[child.func]

		child:SetState(state and BSTATE_NORMAL or BSTATE_DISABLED, not state)

	end

end

local DPSstrings = {
	["damageOut"]  = "DPSOut",
	["damageIn"]   = "DPSIn",
	["healingOut"] = "HPSOut",
	["healingIn"]  = "HPSIn",
}

local CountStrings = {
	["damageOut"]  = "hitsOut",
	["damageIn"]   = "hitsIn",
	["healingOut"] = "healsOut",
	["healingIn"]  = "healsIn",
}

local function updateFightStatsPanelLeft(panel)

	CMX.Print("UI", LOG_LEVEL_DEBUG, "Updating FightStatsPanelLeft")

	local data = fightData and fightData.calculated or {}
	local category = db.FightReport.category

	local selectedabilities = selections["ability"][category]
	local selectedunits = selections["unit"][category]

	local noselection = selectedunits == nil and selectedabilities == nil

	local header2 = panel:GetNamedChild("StatHeaderLabel2")
	local headerstring = noselection and SI_COMBAT_METRICS_GROUP or SI_COMBAT_METRICS_SELECTION

	header2:SetText(GetString(headerstring))

	local label1, label2, label3, rowList, labelList
	local activetime

	local showOverHeal = category == "healingOut" and CMX.showOverHeal

	if category == "healingOut" or category == "healingIn" then

		label1 = GetString(showOverHeal and SI_COMBAT_METRICS_HPSA or SI_COMBAT_METRICS_HPS)
		label2 = GetString(SI_COMBAT_METRICS_HEALING)
		label3 = GetString(SI_COMBAT_METRICS_HEALS)

		rowList = {"Total", "Normal", "Critical", "Overflow", "Absolute"}
		labelList = {SI_COMBAT_METRICS_TOTALC, SI_COMBAT_METRICS_NORMAL, SI_COMBAT_METRICS_CRITICAL, SI_COMBAT_METRICS_OVERHEAL, SI_COMBAT_METRICS_ABSOLUTEC}

		activetime = fightData and fightData.hpstime or 1

	else

		label1 = GetString(SI_COMBAT_METRICS_DPS)
		label2 = GetString(SI_COMBAT_METRICS_DAMAGE)
		label3 = GetString(SI_COMBAT_METRICS_HIT)

		rowList = {"Total", "Normal", "Critical", "Blocked", "Shielded"}
		labelList = {SI_COMBAT_METRICS_TOTALC, SI_COMBAT_METRICS_NORMAL, SI_COMBAT_METRICS_CRITICAL, SI_COMBAT_METRICS_BLOCKED, SI_COMBAT_METRICS_SHIELDED}

		activetime = fightData and fightData.dpstime or 1

	end

	activetime = zo_roundToNearest(activetime, 0.01)

	local activetimestring = string.format("%d:%05.2f", activetime/60, activetime%60)

	local dpsRow = panel:GetNamedChild("StatRowAPS")

	dpsRow:GetNamedChild("Label"):SetText(label1) 	-- DPS or HPS
	panel:GetNamedChild("StatTitleAmount"):GetNamedChild("Label"):SetText(label2) 	-- Damage or Healing
	panel:GetNamedChild("StatTitleCount"):GetNamedChild("Label"):SetText(label3) 	-- Hits or Heals

	local combattime = zo_roundToNearest(fightData and fightData.combattime or 1, 0.01)
	local combattimestring = string.format("%d:%05.2f", combattime/60, combattime%60)

	panel:GetNamedChild("ActiveTimeValue"):SetText(activetimestring)
	panel:GetNamedChild("CombatTimeValue"):SetText(combattimestring)

	local key = showOverHeal and "HPSAOut" or DPSstrings[category]

	local aps1 = data[key] or 0
	local aps2, apsratio

	if not noselection or showOverHeal then

		aps2 = selectionData and selectionData[key] or 0
		apsratio = (aps1 == 0 and 0) or aps2/aps1*100

	else

		local groupkey = zo_strformat("group<<C:1>>", key)
		aps2 = data[groupkey] or 0
		apsratio = (aps2 == 0 and 0) or aps1/aps2*100

	end

	dpsRow:GetNamedChild("Value"):SetText(string.format("%.0f", aps1))
	dpsRow:GetNamedChild("Value2"):SetText(string.format("%.0f", aps2))
	dpsRow:GetNamedChild("Value3"):SetText(string.format("%.1f%%", apsratio))

	for k, v in ipairs(rowList) do

		local rowcontrol1 = panel:GetNamedChild("StatRowAmount"..k)
		local rowcontrol2 = panel:GetNamedChild("StatRowCount"..k)

		local amountlabel    = rowcontrol1:GetNamedChild("Label")
		amountlabel:SetText(GetString(labelList[k]))
		local amountcontrol1 = rowcontrol1:GetNamedChild("Value")
		local amountcontrol2 = rowcontrol1:GetNamedChild("Value2")
		local amountcontrol3 = rowcontrol1:GetNamedChild("Value3")

		local countlabel    = rowcontrol2:GetNamedChild("Label")
		countlabel:SetText(GetString(labelList[k]))
		local countcontrol1 = rowcontrol2:GetNamedChild("Value")
		local countcontrol2 = rowcontrol2:GetNamedChild("Value2")
		local countcontrol3 = rowcontrol2:GetNamedChild("Value3")

		local hide2 = false
		local hide3 = false
		local hide4 = false

		if v then

			local amountkey = category..v
			local countkey = CountStrings[category]..v
			local basekey

			if v == "Overflow" or v == "Absolute" then basekey = "Absolute" else basekey = rowList[1] end

			local amount1 = data[amountkey] or 0
			local amount2 = 0
			local amount3 = data[category..basekey] or 0
			local amountratio = 0

			local count1 = data[countkey] or 0
			local count2 = 0
			local count3 = data[CountStrings[category]..basekey] or 0
			local countratio = 0

			local groupAmountKey = zo_strformat("group<<C:1>>", category)

			if k == 1 and noselection then

				amount2 = data[groupAmountKey] or 0  -- first letter of category needs to be Capitalized
				amountratio = (amount2 == 0 and 0) or amount1/amount2*100

				hide2 = true

			elseif noselection and v == "Absolute" then

				amount2 = data[groupAmountKey] or 0  -- first letter of category needs to be Capitalized
				amountratio = (amount2 == 0 and 0) or amount1/amount2*100

				hide4 = true

			elseif noselection then

				hide3 = true

				amountratio = (amount3 == 0 and 0) or amount1/amount3*100
				countratio = (count3 == 0 and 0) or count1/count3*100

			elseif noselection == false then

				if (k ~= 1 and v ~= "Absolute") then

					amount3 = selectionData[category..basekey] or 0
					count3 = selectionData[CountStrings[category]..basekey] or 0

				end

				amount2 = selectionData[amountkey] or 0
				amountratio = (amount3 == 0 and 0) or amount2/amount3*100

				count2 = selectionData[countkey] or 0
				countratio = (count3 == 0 and 0) or count2/count3*100

			end

			amountcontrol1:SetText(string.format("%.0f", amount1))
			amountcontrol2:SetText(string.format("%.0f", amount2))
			amountcontrol3:SetText(string.format("%.1f%%", amountratio))

			countcontrol1:SetText(string.format("%.0f", count1))
			countcontrol2:SetText(string.format("%.0f", count2))
			countcontrol3:SetText(string.format("%.1f%%", countratio))

		end

		--amountlabel:SetHidden(hide)
		--amountcontrol1:SetHidden(hide)
		amountcontrol2:SetHidden(hide3 or hide4)
		amountcontrol3:SetHidden(hide4)

		--countlabel:SetHidden(hide)
		--countcontrol1:SetHidden(hide)
		countcontrol2:SetHidden(hide3 or hide2)
		countcontrol3:SetHidden(hide2)

	end

end


local powerTypeLabels = {
	[POWERTYPE_MAGICKA] = "_MAGICKA",
	[POWERTYPE_STAMINA] = "_STAMINA",
	[POWERTYPE_HEALTH] = "_HEALTH",
}

local attackStatsKeys = { 			-- {label, format, convert}

	[POWERTYPE_MAGICKA] = {
		[1] = {"maxmagicka", "%d"},
		[2] = {"spellpower", "%d"},
		[3] = {"spellcrit", "%.1f%%", true},
		[4] = {"spellcritbonus", "%.1f%%"},
		[5] = {"spellpen", "%d"},
	},

	[POWERTYPE_STAMINA] = {
		[1] = {"maxstamina", "%d"},
		[2] = {"weaponpower", "%d"},
		[3] = {"weaponcrit", "%.1f%%", true},
		[4] = {"weaponcritbonus", "%.1f%%"},
		[5] = {"weaponpen", "%d"},
	},

	[POWERTYPE_HEALTH] = {
		[1] = {"maxhealth", "%d"},
		[2] = {"physres", "%d"},
		[3] = {"spellres", "%d"},
		[4] = {"critres", "%d", "%.1f%%"},
	},

}


local function updateFightStatsPanelRight(panel)

	CMX.Print("UI", LOG_LEVEL_DEBUG, "Updating FightStatsPanelRight")

	local data = fightData or {}
	local powerType = db.FightReport.fightstatspanel
	local category = db.FightReport.category
	category = category == "healingIn" and "healingOut" or category

	local calculated  = data.calculated or {}

	local calcstats = calculated.stats or {}
	local stats = data.stats or {}

	local isdamage = category == "damageOut" or category == "damageIn"
	local avgvalues = (powerType == POWERTYPE_HEALTH and calcstats.dmginavg) or (isdamage and calcstats.dmgavg) or calcstats.healavg or {}
	local totalvalue = powerType == POWERTYPE_HEALTH and calculated.damageInTotal or calculated[category.."Total"]
	local countvalue = calculated[CountStrings[category].."Total"]

	local resources = calculated.resources or {}

	local magicka = resources[POWERTYPE_MAGICKA] or {}
	local stamina = resources[POWERTYPE_STAMINA] or {}
	local ultimate = resources[POWERTYPE_ULTIMATE] or {}

	local magickacontrol = panel:GetNamedChild("ResourceMagicka")
	magickacontrol:GetNamedChild("Value"):SetText(string.format("%.0f", magicka.gainRate or 0))
	magickacontrol:GetNamedChild("Value2"):SetText(string.format("%.0f", magicka.drainRate or 0))

	local staminacontrol = panel:GetNamedChild("ResourceStamina")
	staminacontrol:GetNamedChild("Value"):SetText(string.format("%.0f", stamina.gainRate or 0))
	staminacontrol:GetNamedChild("Value2"):SetText(string.format("%.0f", stamina.drainRate or 0))

	local ultimatecontrol = panel:GetNamedChild("ResourceUltimate")
	ultimatecontrol:GetNamedChild("Value"):SetText(string.format("%.2f", ultimate.gainRate or 0))
	ultimatecontrol:GetNamedChild("Value2"):SetText(string.format("%.2f", ultimate.drainRate or 0))

	local stringKey = "SI_COMBAT_METRICS_STATS" .. powerTypeLabels[powerType]

	local statWindowControl = panel:GetNamedChild("AttackStats")
	local keys = attackStatsKeys[powerType]

	for i = 1, 4 do

		local text = ZO_CachedStrFormat("<<1>>:", GetString(stringKey, i))
		local rowcontrol = statWindowControl:GetNamedChild("Row"..i)
		local dataKey, displayformat, convert = unpack(keys[i] or {})

		if text ~= nil and text ~= "" and dataKey ~= nil then

			local maxvalue = stats["max"..dataKey] or 0

			if convert == true then maxvalue = GetCriticalStrikeChance(maxvalue) end
			if dataKey == POWERTYPE_HEALTH and i == 4 then maxvalue = maxvalue / 68 end 	-- untested, but good agreement from multiple sources
			if displayformat then maxvalue = string.format(displayformat, maxvalue) end

			local avgvalue = avgvalues["avg"..dataKey] or calcstats["avg"..dataKey]

			if avgvalue == nil then

				local legacyvalue = avgvalues["sum"..dataKey]
				avgvalue = (legacyvalue and legacyvalue / math.max(convert and countvalue or totalvalue or 1, 1)) or maxvalue

			end

			if type(avgvalue) == "number" then -- legacy

				if convert then avgvalue = GetCriticalStrikeChance(avgvalue) end
				if displayformat then avgvalue = string.format(displayformat, avgvalue) end

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
	local resdata = selections.unit[category] and selectionData or calculated or {}

	if category == "damageOut" and (powerType == POWERTYPE_MAGICKA or powerType == POWERTYPE_STAMINA) then

		local resistvalues = powerType == POWERTYPE_MAGICKA and resdata.spellResistance or powerType == POWERTYPE_STAMINA and resdata.physicalResistance or {}
		local dataKey = keys[5][1]

		local sum = 0
		local totaldamage = 0
		local maxvalue = stats["max"..dataKey] or 0
		local overpen = 0

		for penetration, damage in pairs(resistvalues) do

			sum = sum + penetration * damage
			maxvalue = math.max(maxvalue, penetration)
			totaldamage = totaldamage + damage

			if penetration - db.unitresistance > 0 then overpen = overpen + damage end

		end

		totaldamage = math.max(totaldamage, 1)

		local tooltiplines = {GetString(SI_COMBAT_METRICS_PENETRATION_TT)}

		for penetration, damage in CMX.spairs(resistvalues) do

			local newline = string.format("%d: %.1f%%", penetration, 100 * damage/totaldamage)
			table.insert(tooltiplines, newline)

		end

		local averagePenetration = string.format("%d", math.max(zo_round(sum / totaldamage), avgvalues["avg"..dataKey] or 0))
		local overPenetrationRatio = string.format("%.1f%%", 100 * overpen / totaldamage)

		row5:SetHidden(false)
		row6:SetHidden(false)

		local text5 = GetString(stringKey, 5)

		row5:GetNamedChild("Label"):SetText(text5)
		row5:GetNamedChild("Value"):SetText(averagePenetration)
		row5:GetNamedChild("Value2"):SetText(maxvalue)

		local text6 = GetString(stringKey, 6)

		row6:GetNamedChild("Label"):SetText(text6)
		row6:GetNamedChild("Value"):SetText(overPenetrationRatio)
		row6.tooltip = #tooltiplines>1 and tooltiplines or nil

	else

		row5:SetHidden(true)
		row6:SetHidden(true)
		row6.tooltip = nil

	end
end

local function updateFightStatsPanel(panel)

	CMX.Print("UI", LOG_LEVEL_DEBUG, "Updating FightStatsPanel")

	panel:GetNamedChild("Left"):Update(fightData, selectionData)
	panel:GetNamedChild("Right"):Update(fightData)

end

local function updateMainPanel(mainpanel)

	CMX.Print("UI", LOG_LEVEL_DEBUG, "Updating MainPanel")

	mainpanel.active:Update()

end

local function adjustRowSize(row, header) 	-- this function resizes the row elements to match the size of the header elements of a scrolllist.
											-- It's important to maintain the naming and structure of the header elements to match those of the row elements.

	if row == nil or row.scale == db.FightReport.scale then return end	-- if sizes are good already, bail out.

	row.scale = db.FightReport.scale

	for i=1, header:GetNumChildren() do

		local child = header:GetChild(i)

		local childname = string.gsub(child:GetName(), header:GetName(), "")

		local template = header:GetNamedChild(childname)
		local rowchild = row:GetNamedChild(childname)

		if template and rowchild then

			local x, y = template:GetDimensions()
			rowchild:SetDimensions(x, y)

			local valid1, _, _, _, x, y, _ = template:GetAnchor(0)
			local valid2, point, relativeTo, relativePoint, _, _, _ = rowchild:GetAnchor(0)

			if valid1 and valid2 then

				rowchild:ClearAnchors()
				rowchild:SetAnchor(point, relativeTo, relativePoint, x, y)

			end

			if rowchild:GetType() == CT_LABEL then rowchild:SetFont(string.format("%s|%s|%s", GetString(SI_COMBAT_METRICS_STD_FONT), tonumber(GetString(SI_COMBAT_METRICS_FONT_SIZE)) * row.scale, "soft-shadow-thin")) end

		end
	end
end

local function ResetBars(panel)

	if panel.bars == nil then panel.bars = {} end

	if #panel.bars == 0 then return end

	for i=1, #panel.bars do

		panel.bars[i]:SetHidden(true)
		panel.bars[i] = nil

	end
end

local function buffSortFunction(data, a, b)

	local ishigher = false
	local favs = db.FightReport.FavouriteBuffs

	local isFavA = favs[a]
	local isFavB = favs[b]

	if isFavA and not isFavB then

		ishigher = true

	elseif isFavA == isFavB then

		ishigher = data[a]["groupUptime"] > data[b]["groupUptime"]

	end

	return ishigher

end

local function GetBuffData()

	local buffData

	local rightpanel = db.FightReport.rightpanel

	if rightpanel == "buffsout" then

		buffData = selectionData

	elseif rightpanel == "buffs" then

		buffData = fightData.calculated

	end

	return buffData
end

local function GetUnitsByType(unitType)

	if not unitType then return end

	local units = {}

	for unitId, unit in pairs(fightData.units) do

		if (unitType == "boss" and unit.bossId) or (unitType == "group" and (unit.unitType == COMBAT_UNIT_TYPE_GROUP or unit.unitType == COMBAT_UNIT_TYPE_PLAYER)) then

			units[unitId] = true

		end

	end

	return units

end

local function GetBuffDataAndUnits(unitType)

	local buffData

	local rightpanel = db.FightReport.rightpanel

	local units = 0
	local unitName = ""

	if rightpanel == "buffsout" then

		local category = db.FightReport.category

		local tempSelections = {}

		ZO_DeepTableCopy(selections, tempSelections)

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

	elseif rightpanel == "buffs" then

		buffData = fightData.calculated

	end

	if units == 1 then units = unitName end

	return buffData, units
end

local function updateBuffPanelLegacy(panel)

	CMX.Print("UI", LOG_LEVEL_DEBUG, "Updating BuffPanel")

	ResetBars(panel)

	if fightData == nil then return end

	local buffData = GetBuffData()

	if buffData == nil then return end

	local scrollchild = GetControl(panel, "PanelScrollChild")

	local selectedbuffs = selections["buff"]["buff"]
	local currentanchor = {TOPLEFT, scrollchild, TOPLEFT, 0, 1}

	local maxtime = math.max(fightData.activetime or 0, fightData.dpstime or 0, fightData.hpstime or 0)

	local totalUnitTime = buffData.totalUnitTime or maxtime * 1000
	local showids = db.showDebugIds
	local favs = db.FightReport.FavouriteBuffs

	for buffName, buff in CMX.spairs(buffData["buffs"], buffSortFunction) do

		if buff.groupUptime > 0 then

			-- prepare contents

			local color = (buff.effectType == BUFF_EFFECT_TYPE_BUFF and {0, 0.6, 0, 0.6}) or (buff.effectType == BUFF_EFFECT_TYPE_DEBUFF and {0.75, 0, 0.6, 0.6}) or {0.6, 0.6, 0.6, 0.6}
			local groupColor = (buff.effectType == BUFF_EFFECT_TYPE_BUFF and {0, 0.6, 0, 0.3}) or (buff.effectType == BUFF_EFFECT_TYPE_DEBUFF and {0.75, 0, 0.6, 0.3}) or {0.6, 0.6, 0.6, 0.3}

			local highlight = false
			if selectedbuffs ~= nil then highlight = (selectedbuffs[buffName] ~= nil) end

			local icon = GetFormattedAbilityIcon(buff.icon)
			local dbug = (showids and type(buff.icon) == "number") and string.format("(%d) ", buff.icon) or ""
			local name = dbug .. buffName

			local uptimeRatio = buff.uptime / totalUnitTime
			local groupUptimeRatio = buff.groupUptime / totalUnitTime

			local count = buff.count
			local groupCount = buff.groupCount

			local hideGroupValues = count == groupCount and uptimeRatio == groupUptimeRatio

			local countFormat = hideGroupValues and "%d" or "%d/%d"
			local uptimeFormat = hideGroupValues and "%.0f" or "%.0f/%.0f"

			local rowId = #panel.bars + 1

			local rowName = scrollchild:GetName() .. "Row" .. rowId
			local row = _G[rowName] or CreateControlFromVirtual(rowName, scrollchild, "CombatMetrics_BuffRowTemplate")
			row:SetAnchor(unpack(currentanchor))
			row:SetHidden(false)

			local header = panel:GetNamedChild("Header")
			adjustRowSize(row, header)

 			local textcolor = favs[buffName] and {1, .8, .3, 1} or {1, 1, 1, 1} -- show favs in different color

			-- update controls with contents

			local highlightControl = row:GetNamedChild("HighLight")
			highlightControl:SetHidden(not highlight)

			local iconControl = row:GetNamedChild("Icon")
			iconControl:SetTexture(icon)

			local nameControl = row:GetNamedChild("Name")
			nameControl:SetText(name)
			nameControl:SetColor(unpack(textcolor))

			local maxwidth = nameControl:GetWidth()

			local groupBarControl = row:GetNamedChild("GroupBar")
			groupBarControl:SetWidth(maxwidth * groupUptimeRatio)
			groupBarControl:SetCenterColor(unpack(groupColor))

			local playerBarControl = row:GetNamedChild("PlayerBar")
			playerBarControl:SetWidth(maxwidth * uptimeRatio)
			playerBarControl:SetCenterColor(unpack(color))

			local countControl = row:GetNamedChild("Count")
			countControl:SetText(string.format(countFormat, count, groupCount))

			local uptimeControl = row:GetNamedChild("Uptime")
			uptimeControl:SetText(string.format(uptimeFormat, uptimeRatio * 100, groupUptimeRatio * 100))

			currentanchor = {TOPLEFT, row, BOTTOMLEFT, 0, dx}

			panel.bars[rowId] = row

			row.dataId = buffName
			row.type = "buff"
			row.id = rowId
			row.panel = panel
		end
	end
end

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

local function updateBuffPanel(panel)

	CMX.Print("UI", LOG_LEVEL_DEBUG, "Updating BuffPanel")

	ResetBars(panel)

	if fightData == nil then return end

	local buffDataVersion = fightData.calculated.buffVersion or 0

	if buffDataVersion < 2 then updateBuffPanelLegacy(panel) return end

	local buffData = GetBuffData()

	if buffData == nil then return end

	local scrollchild = GetControl(panel, "PanelScrollChild")

	local selectedbuffs = selections["buff"]["buff"]
	local currentanchor = {TOPLEFT, scrollchild, TOPLEFT, 0, 1}

	local maxtime = math.max(fightData.activetime or 0, fightData.dpstime or 0, fightData.hpstime or 0)

	local totalUnitTime = buffData.totalUnitTime or maxtime * 1000
	local showids = db.showDebugIds
	local favs = db.FightReport.FavouriteBuffs

	local parentrow

	for buffName, buff in CMX.spairs(buffData["buffs"], buffSortFunction) do

		if buff.groupUptime > 0 then

			local labelFormat = showids and "(<<1>>) <<2>>" or "<<2>>"
			local rowdata = {}

			local shownUptime = buff.uptime
			local shownGroupUptime = buff.groupUptime

			local hasInstances = buff.instances and NonContiguousCount(buff.instances) > 1
			local hasStacks = buff.instances and buff.maxStacks > 1

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

			currentanchor, parentrow = addBuffPanelRow(panel, scrollchild, currentanchor, rowdata)

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

					currentanchor = addBuffPanelRow(panel, scrollchild, currentanchor, rowdata, parentrow)
				end
			end

			if hasStacks and uncollapsedBuffs[buffName] then

				rowdata.indent = 1
				rowdata.highlight = false
				rowdata.hasDetails = false

				for stacks, stackData in pairs(buff.instances[buff.iconId]) do

					if type(stacks) == "number" then

						rowdata.label = ZO_CachedStrFormat("<<1>>x <<2>>", stacks, buffName)

						rowdata.uptimeRatio = stackData.uptime / totalUnitTime
						rowdata.groupUptimeRatio = stackData.groupUptime / totalUnitTime
						rowdata.count = stackData.count
						rowdata.groupCount = stackData.groupCount

						currentanchor = addBuffPanelRow(panel, scrollchild, currentanchor, rowdata, parentrow)

					end
				end
			end
		end
	end
end

local function updateResourceBars(panel, currentanchor, data, totalRate, selectedresources, color)

	local scrollchild = GetControl(panel, "PanelScrollChild")

	local showids = db.showDebugIds

	for abilityId, ability in CMX.spairs(data, function(t, a, b) return t[a].value>t[b].value end) do

		if (ability.ticks or 0) > 0 then

			local label = GetFormattedAbilityName(abilityId)

			local highlight = false
			if selectedresources ~= nil then highlight = selectedresources[abilityId] ~= nil end

			local dbug = showids and string.format("(%d) ", abilityId) or ""
			local name = dbug..label

			local count = ability.ticks
			local rate = ability.rate
			local ratio = rate/totalRate

			local rowId = #panel.bars + 1

			local rowName = scrollchild:GetName() .. "Row" .. rowId
			local row = _G[rowName] or CreateControlFromVirtual(rowName, scrollchild, "CombatMetrics_ResourceRowTemplate")
			row:SetAnchor(unpack(currentanchor))
			row:SetHidden(false)

			local header = panel:GetNamedChild("Header")
			adjustRowSize(row, header)

			local highlightControl = row:GetNamedChild("HighLight")
			highlightControl:SetHidden(not highlight)

			local nameControl = row:GetNamedChild("Name")
			nameControl:SetText(name)
			local maxwidth = nameControl:GetWidth()

			local barControl = row:GetNamedChild("Bar")
			barControl:SetWidth(maxwidth * ratio)
			barControl:SetCenterColor(unpack(color))

			local countControl = row:GetNamedChild("Count")
			countControl:SetText(count)

			local rateControl = row:GetNamedChild("Rate")
			rateControl:SetText(string.format("%.0f", rate))

			currentanchor = {TOPLEFT, row, BOTTOMLEFT, 0, dx}

			panel.bars[rowId] = row

			row.dataId = abilityId
			row.type = "resource"
			row.id = rowId
			row.panel = panel

		end
	end

	return currentanchor
end

local function updateResourcePanel(panel)

	CMX.Print("UI", LOG_LEVEL_DEBUG, "Updating ResourcePanel")

	local subpanel1 = panel:GetNamedChild("Gains")
	local subpanel2 = panel:GetNamedChild("Drains")

	ResetBars(subpanel1)
	ResetBars(subpanel2)

	if fightData == nil then return end

	local key, color1, color2

	local rightpanel = db.FightReport.rightpanel

    if rightpanel == "magicka" then

		key = POWERTYPE_MAGICKA
		color1 = {0.3, 0.4, 0.6, 1}
		color2 = {0.4, 0.3, 0.6, 1}

	elseif rightpanel == "stamina" then

		key = POWERTYPE_STAMINA
		color1 = {0.4, 0.6, 0.3, 1}
		color2 = {0.4, 0.45, 0.05, 1}

	else return end

	local data = fightData.calculated.resources[key]

	local selectedresources = selections["resource"]["resource"]

	local scrollchild = GetControl(subpanel1, "PanelScrollChild")
	local currentanchor = {TOPLEFT, scrollchild, TOPLEFT, 0, 1}

	updateResourceBars(subpanel1, currentanchor, data.gains, data.gainRate, selectedresources, color1) -- generate bars for resource gains

	local scrollchild = GetControl(subpanel2, "PanelScrollChild")
	local currentanchor = {TOPLEFT, scrollchild, TOPLEFT, 0, 1}

	updateResourceBars(subpanel2, currentanchor, data.drains, data.drainRate, selectedresources, color2) -- generate bars for resource drains

end

local function updateRightPanel(rightPanel)

	CMX.Print("UI", LOG_LEVEL_DEBUG, "Updating RightPanel")

	rightPanel.active:Update()

end

local function GetShortFormattedNumber(number)

	local exponent = math.floor(math.log(number)/math.log(10))
	local loweredNumber = zo_roundToNearest(number, math.pow(10, exponent-2))

	local shortNumber = ZO_AbbreviateNumber(loweredNumber, 2, exponent>=6)

	return shortNumber

end

local function updateUnitPanel(panel)

	CMX.Print("UI", LOG_LEVEL_DEBUG, "Updating UnitPanel")

	ResetBars(panel)

	-- Update header labels
	local category = db.FightReport.category

	local isdamage = (category == "damageOut" or category == "damageIn")

	local label1 = ((category == "damageOut" or category == "healingOut") and GetString(SI_COMBAT_METRICS_TARGET)) or GetString(SI_COMBAT_METRICS_SOURCE)
	local label2 = (isdamage and GetString(SI_COMBAT_METRICS_DPS)) or GetString(SI_COMBAT_METRICS_HPS)
	local label3 = (isdamage and GetString(SI_COMBAT_METRICS_DAMAGE)) or GetString(SI_COMBAT_METRICS_HEALING)

	local header = panel:GetNamedChild("Header")

	header:GetNamedChild("Name"):SetText(label1)
	header:GetNamedChild("PerSecond"):SetText(label2)
	header:GetNamedChild("Total"):SetText(label3)

	-- prepare data

	if fightData == nil then return end

	local data = fightData.calculated

	local selectedunits = selections["unit"][db.FightReport.category]

	local totalAmountKey = category.."Total"
	local totalAmount = data[totalAmountKey] -- i.e. damageOutTotal
	local APSKey = DPSstrings[category]

	local scrollchild = GetControl(panel, "PanelScrollChild")
	local currentanchor = {TOPLEFT, scrollchild, TOPLEFT, 0, 1}

	local FRsettings = db.FightReport

	local rightpanel = FRsettings.rightpanel

	local showids = db.showDebugIds

	for unitId, unit in CMX.spairs(data.units, function(t, a, b) return t[a][totalAmountKey]>t[b][totalAmountKey] end) do -- i.e. for damageOut sort by damageOutTotal

		local totalUnitAmount = unit[totalAmountKey]

		local unitData = fightData.units[unitId]

		if (totalUnitAmount > 0 or (rightpanel == "buffsout" and NonContiguousCount(unit.buffs) > 0 and (unitData.isFriendly == false and isdamage) or (unitData.isFriendly and not isdamage))) and (not (unitData.unitType == 2 and FRsettings.showPets == false)) then

			local highlight = false
			if selectedunits ~= nil then highlight = selectedunits[unitId] ~= nil end

			local dbug = showids and string.format("(%d) ", unitId) or ""

			local name = dbug .. (FRsettings.useDisplayNames and unitData.displayname or unitData.name)

			local isboss = unitData.bossId
			local namecolor = (isboss and {1, .8, .3, 1}) or {1, 1, 1, 1}

			local unitTime = unitData.dpsend and unitData.dpsstart and math.max((unitData.dpsend - unitData.dpsstart) / 1000, 1) or 1
			local dps  = unitTime and totalUnitAmount / unitTime or unit[APSKey]
			local damage = totalUnitAmount
			local ratio = damage / totalAmount

			local rowId = #panel.bars + 1

			local rowName = scrollchild:GetName() .. "Row" .. rowId
			local row = _G[rowName] or CreateControlFromVirtual(rowName, scrollchild, "CombatMetrics_UnitRowTemplate")
			row:SetAnchor(unpack(currentanchor))
			row:SetHidden(false)

			local header = panel:GetNamedChild("Header")
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

			panel.bars[rowId] = row

			row.dataId = unitId
			row.type = "unit"
			row.id = rowId
			row.panel = panel

		end
	end
end

local hitCritLayoutTable = {

	[1] = {"Critical", "Total", GetString(SI_COMBAT_METRICS_CRITS), GetString(SI_COMBAT_METRICS_HITS)},
	[2] = {"Total", "Critical", GetString(SI_COMBAT_METRICS_HITS), GetString(SI_COMBAT_METRICS_CRITS)},
	[3] = {"Normal", "Critical", GetString(SI_COMBAT_METRICS_NORM), GetString(SI_COMBAT_METRICS_CRITS)},
	[4] = {"Blocked", "Total", GetString(SI_COMBAT_METRICS_BLOCKS), GetString(SI_COMBAT_METRICS_HITS)},
	[5] = {"Total", "Blocked", GetString(SI_COMBAT_METRICS_HITS), GetString(SI_COMBAT_METRICS_BLOCKS)},
	[6] = {"Normal", "Blocked", GetString(SI_COMBAT_METRICS_NORM), GetString(SI_COMBAT_METRICS_BLOCKS)},

}

do 	-- Context Menu for hit/crit column on ability panel

	local function getMenuData(id)

		local category = db.FightReport.category
		local hitCritLayout = hitCritLayoutTable[id]
		local text = string.format("%s/%s", hitCritLayout[3], hitCritLayout[4])

		local function callback()

			db.FightReport.hitCritLayout[category] = id

			CombatMetrics_Report_AbilityPanel:Update()

		end

		return text, callback

	end

	function CMX.HitCritContextMenu(control, button)

		ClearMenu()

		if db.FightReport.category == "damageIn" then

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

	[1] = {"Total", GetString(SI_COMBAT_METRICS_AVE), GetString(SI_COMBAT_METRICS_HITS)},
	[2] = {"Normal", GetString(SI_COMBAT_METRICS_AVE_N), GetString(SI_COMBAT_METRICS_NORMAL_HITS)},
	[3] = {"Critical", GetString(SI_COMBAT_METRICS_AVE_C), GetString(SI_COMBAT_METRICS_CRITS)},
	[4] = {"Blocked", GetString(SI_COMBAT_METRICS_AVE_B), GetString(SI_COMBAT_METRICS_BLOCKS)},

}

do 	-- Context Menu for average column on ability panel

	local function getMenuData(id)

		local averageLayout = averageLayoutTable[id]

		local text = string.format("%s %s", GetString(SI_COMBAT_METRICS_AVERAGE), averageLayout[3])

		local category = db.FightReport.category

		local function callback()

			db.FightReport.averageLayout[category] = id

			CombatMetrics_Report_AbilityPanel:Update()

		end

		return text, callback

	end

	function CMX.AverageContextMenu(control, button)

		ClearMenu()

		AddCustomMenuItem(getMenuData(1))
		AddCustomMenuItem(getMenuData(2))
		AddCustomMenuItem(getMenuData(3))

		if db.FightReport.category == "damageIn" then

			AddCustomMenuItem(getMenuData(4))

		end

		ShowMenu(control)

	end
end

do 	-- Context Menu for Min/Max column on ability panel

	local function selectMinMaxOption1()

		local category = db.FightReport.category

		db.FightReport.maxValue[category] = true

		CombatMetrics_Report_AbilityPanel:Update()

	end

	local function selectMinMaxOption2()

		local category = db.FightReport.category

		db.FightReport.maxValue[category] = false

		CombatMetrics_Report_AbilityPanel:Update()

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

local function updateAbilityPanel(panel)

	CMX.Print("UI", LOG_LEVEL_DEBUG, "Updating AbilityPanel")

	ResetBars(panel)

	local settings = db.FightReport

	local category = settings.category
	local hitCritLayoutId = settings.hitCritLayout[category]
	local averageLayoutId = settings.averageLayout[category]
	local hitCritLayout = hitCritLayoutTable[hitCritLayoutId]
	local averageLayout = averageLayoutTable[averageLayoutId]
	local minmax = settings.maxValue

	local isDamage = category == "damageIn" or category == "damageOut"
	local showOverHeal = CMX.showOverHeal and category == "healingOut"

	local valueColumnLabel = isDamage and GetString(SI_COMBAT_METRICS_DAMAGE) or GetString(SI_COMBAT_METRICS_HEALING)

	if showOverHeal then valueColumnLabel = valueColumnLabel .. "*" end

	local header = panel:GetNamedChild("Header")

	header:GetNamedChild("Total"):SetText(valueColumnLabel)

	local headerCritString = showOverHeal and GetString(SI_COMBAT_METRICS_OH) or hitCritLayout[3]
	local headerHitString = showOverHeal and GetString(SI_COMBAT_METRICS_HEALS) or hitCritLayout[4]
	local headerCritRatioString = showOverHeal and GetString(SI_COMBAT_METRICS_OH) or hitCritLayoutId > 3 and GetString(SI_COMBAT_METRICS_BLOCKS) or GetString(SI_COMBAT_METRICS_CRITS)

	header:GetNamedChild("Crits"):SetText(headerCritString)
	header:GetNamedChild("Hits"):SetText("/" ..  headerHitString)
	header:GetNamedChild("CritRatio"):SetText(headerCritRatioString.. "%")

	local headerAvg = header:GetNamedChild("Average")

	headerAvg:SetText(averageLayout[2])

	local headerMinMax = header:GetNamedChild("MinMax")

	headerMinMax:SetText(GetString(minmax and SI_COMBAT_METRICS_MAX or SI_COMBAT_METRICS_MIN))

	if fightData == nil then return end

	local data
	local totaldmg

	local selectedabilities = selections["ability"][category]
	local selectedunits = selections["unit"][category]

	local totalkey = "Total"
	local totalAmountKey = showOverHeal and "healingOutAbsolute" or category..totalkey
	local countString = CountStrings[category]

	if selectedunits ~= nil then

		data = selectionData
		totaldmg = selectionData.totalValueSum

	else

		data = fightData.calculated
		totaldmg = data[totalAmountKey]

	end

	local scrollchild = GetControl(panel, "PanelScrollChild")
	local currentanchor = {TOPLEFT, scrollchild, TOPLEFT, 0, 1}

	local totalHitKey = showOverHeal and "healsOutAbsolute" or countString..totalkey
	local critKey = showOverHeal and "healsOutOverflow" or hitCritLayoutId > 3 and countString.."Blocked" or countString.."Critical"

	local ratioKey1 = showOverHeal and "healsOutOverflow" or countString..hitCritLayout[1]	-- first value of the crits/hits column display
	local ratioKey2 = showOverHeal and "healsOutAbsolute" or countString..hitCritLayout[2]  -- second value of the crits/hits column display

	local avgKey1 = showOverHeal and "healingOutAbsolute" or category..averageLayout[1]		-- damage value of the avg column display
	local avgKey2 = showOverHeal and "healsOutAbsolute" or countString..averageLayout[1]	-- hits value of the avg column display

	local DPSKey = showOverHeal and "HPSAOut" or DPSstrings[category]

	local showids = db.showDebugIds

	for abilityId, ability in CMX.spairs(data[category], function(t, a, b) return t[a][totalAmountKey]>t[b][totalAmountKey] end) do

		if ability[totalAmountKey]>0 then

			local highlight = false

			if selectedabilities ~= nil then
				highlight = selectedabilities[abilityId] ~= nil
			end

			local icon = GetFormattedAbilityIcon(abilityId)

			local dot = (GetAbilityDuration(abilityId)>0 or (IsAbilityPassive(abilityId) and isDamage)) and "*" or ""
			local pet = ability.pet and " (pet)" or ""
			local dbug = showids and string.format("(%d) ", abilityId) or ""
			local color = ability.damageType and CMX.GetDamageColor(ability.damageType) or ""

			local name  = dbug..color..(ability.name or GetFormattedAbilityName(abilityId))..dot..pet.."|r"

			local dps = ability[DPSKey]
			local total = ability[totalAmountKey]
			local ratio = total and totaldmg and totaldmg > 0 and (total / totaldmg)

			local crits = ability[critKey]
			local hits = ability[totalHitKey]
			local critratio = crits and hits and hits > 0 and (100 * crits / hits)

			local ratio1 = ability[ratioKey1]
			local ratio2 = ability[ratioKey2]

			local avg1 = ability[avgKey1]
			local avg2 = ability[avgKey2] or 0

			local avg = avg2 ~= 0 and (avg1 / avg2)
			local minmaxValue = (showOverHeal and "-") or (minmax and ability.max) or (ability.min or 0)

			local rowId = #panel.bars + 1

			local rowName = scrollchild:GetName() .. "Row" .. rowId
			local row = _G[rowName] or CreateControlFromVirtual(rowName, scrollchild, "CombatMetrics_AbilityRowTemplate")
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

			currentanchor = {TOPLEFT, row, BOTTOMLEFT, 0, dx}

			panel.bars[rowId] = row

			row.dataId = abilityId
			row.type = "ability"
			row.id = rowId
			row.panel = panel

		end
	end
end

local logtypeCategories = {
	[LIBCOMBAT_EVENT_DAMAGE_OUT] = "damageOut",
	[LIBCOMBAT_EVENT_DAMAGE_IN] = "damageIn",
	[LIBCOMBAT_EVENT_DAMAGE_SELF] = "damageSelf",
	[LIBCOMBAT_EVENT_HEAL_OUT] = "healingOut",
	[LIBCOMBAT_EVENT_HEAL_IN] = "healingIn",
	[LIBCOMBAT_EVENT_HEAL_SELF] = "healSelf",
	[LIBCOMBAT_EVENT_EFFECTS_IN] = "buff",
	[LIBCOMBAT_EVENT_EFFECTS_OUT] = "buff",
	[LIBCOMBAT_EVENT_GROUPEFFECTS_IN] = "buff",
	[LIBCOMBAT_EVENT_GROUPEFFECTS_OUT] = "buff",
	[LIBCOMBAT_EVENT_PLAYERSTATS] = "stats",
	[LIBCOMBAT_EVENT_RESOURCES] = "resource",
	[LIBCOMBAT_EVENT_MESSAGES] = "message",
}

local function updateCLPageButtons(buttonrow, page, maxpage)

	local first = math.max(page-2, 1)
	local last = first + 4

	buttonrow:GetNamedChild("PageLeft"):SetHidden(page == 1)
	buttonrow:GetNamedChild("PageRight"):SetHidden(page >= maxpage)

	for i = first, last do

		local key = "Page" .. (i - first + 1)

		local button = buttonrow:GetNamedChild(key)

		button.tooltip = {zo_strformat(SI_COMBAT_METRICS_PAGE, i)}
		button.value = i

		button:SetHidden(i > maxpage)

		buttonrow:GetNamedChild(key .. "Label"):SetText(i)

		local bg = buttonrow:GetNamedChild(key.."Overlay")

		bg:SetCenterColor( 0 , 0 , 0 , page == i and 0 or 0.8 )
		bg:SetEdgeColor( 1 , 1 , 1 , page == i and 1 or .4 )

	end
end

local function updateCombatLog(panel)

	if fightData == nil or panel:IsHidden() then return end

	CMX.Print("UI", LOG_LEVEL_DEBUG, "Updating CombatLog")

	local CLSelection = db.FightReport.CLSelection

	local window = panel:GetNamedChild("Window")
	local buffer = window:GetNamedChild("Buffer")
	local slider = window:GetNamedChild("Slider")

	local logdata = fightData.log or {}
	local loglength = #logdata

	buffer:Clear()
	if loglength == 0 then return end

	buffer:SetMaxHistoryLines(math.min(loglength, 1000))
	buffer:SetFont(string.format("%s|%s|%s", GetString(SI_COMBAT_METRICS_STD_FONT), tonumber(GetString(SI_COMBAT_METRICS_FONT_SIZE)) * db.FightReport.scale, ""))

	local maxpage = math.ceil(loglength/1000)
	local page = (currentCLPage or 1) <= maxpage and currentCLPage or 1

	local writtenlines = 0

	local unitSelection = selections.unit
	local abilitySelection = selections.ability
	local buffSelection = selections.buff.buff
	local resourceSelection = selections.resource.resource

	local unitSelectionAll = {}

	local unitsSelected = false

	for _, category in pairs({"healingIn", "healingOut", "damageIn", "damageOut"}) do

		local subcategory = unitSelection[category]

		if subcategory ~= nil then

			for unitId, bool in pairs(subcategory) do

				unitSelectionAll[unitId] = bool
				unitsSelected = true

			end

		end
	end

	for k, logline in ipairs(logdata) do

		local condition1, condition2 = false, false

		local logtype = logline[1]

		local condition1 =
			CLSelection[logtype]
			or (logtype == LIBCOMBAT_EVENT_DAMAGE_SELF and (CLSelection[LIBCOMBAT_EVENT_DAMAGE_IN] or CLSelection[LIBCOMBAT_EVENT_DAMAGE_OUT]))
			or (logtype == LIBCOMBAT_EVENT_HEAL_SELF and (CLSelection[LIBCOMBAT_EVENT_HEAL_IN] or CLSelection[LIBCOMBAT_EVENT_HEAL_OUT]))
			or (logtype == LIBCOMBAT_EVENT_BOSSHP and (CLSelection[LIBCOMBAT_EVENT_MESSAGES]))
			or (logtype == LIBCOMBAT_EVENT_DEATH and (CLSelection[LIBCOMBAT_EVENT_MESSAGES]))

		if condition1 == true then

			local category = logtypeCategories[logtype]
			local unitSelCat = unitSelection[category]

			if logtype == LIBCOMBAT_EVENT_DAMAGE_IN or logtype == LIBCOMBAT_EVENT_DAMAGE_OUT or logtype == LIBCOMBAT_EVENT_HEAL_IN or logtype == LIBCOMBAT_EVENT_HEAL_OUT then

				local sourceUnitId = logline[4]
				local targetUnitId = logline[5]
				local abilityId = logline[6]

				condition2 = (

						unitSelCat == nil
						or (unitSelCat[targetUnitId]~= nil and (logtype == LIBCOMBAT_EVENT_HEAL_OUT or logtype == LIBCOMBAT_EVENT_DAMAGE_OUT))
						or (unitSelCat[sourceUnitId]~= nil and (logtype == LIBCOMBAT_EVENT_HEAL_IN or logtype == LIBCOMBAT_EVENT_DAMAGE_IN))
					) and (
						abilitySelection[category] == nil
						or abilitySelection[category][abilityId] ~= nil
					)

			elseif logtype == LIBCOMBAT_EVENT_HEAL_SELF then

				local sourceUnitId = logline[4]
				local targetUnitId = logline[5]
				local abilityId = logline[6]

				condition2 = (

						   (unitSelection.healingIn == nil 	and CLSelection[LIBCOMBAT_EVENT_HEAL_IN])
						or (unitSelection.healingIn ~= nil	and unitSelection.healingIn[sourceUnitId] ~= nil)
						or (unitSelection.healingOut == nil and CLSelection[LIBCOMBAT_EVENT_HEAL_OUT])
						or (unitSelection.healingOut ~= nil	and unitSelection.healingOut[targetUnitId] ~= nil)
					) and (
						   (abilitySelection.healingIn == nil 	and CLSelection[LIBCOMBAT_EVENT_HEAL_IN])
						or (abilitySelection.healingIn ~= nil	and abilitySelection.healingIn[abilityId] ~= nil)
						or (abilitySelection.healingOut == nil 	and CLSelection[LIBCOMBAT_EVENT_HEAL_OUT])
						or (abilitySelection.healingOut ~= nil	and abilitySelection.healingOut[abilityId] ~= nil)
					)

			elseif logtype == LIBCOMBAT_EVENT_EFFECTS_IN or logtype == LIBCOMBAT_EVENT_EFFECTS_OUT or logtype == LIBCOMBAT_EVENT_GROUPEFFECTS_IN or logtype == LIBCOMBAT_EVENT_GROUPEFFECTS_OUT then

				local unitId = logline[3]
				local abilityId = logline[4]

				local ability = GetFormattedAbilityName(abilityId)

				condition2 = (
					buffSelection == nil and unitsSelected==false)
					or (buffSelection ~= nil and buffSelection[ability]~= nil and unitsSelected == false)
					or (buffSelection == nil and unitSelectionAll[unitId]~= nil)
					or (buffSelection ~= nil and buffSelection[ability] ~= nil and unitsSelected == true and unitSelectionAll[unitId] ~= nil
				)

			elseif logtype == LIBCOMBAT_EVENT_RESOURCES then

				local abilityId = logline[3]
				local powerType = logline[5]

				condition2 = powerType ~= POWERTYPE_HEALTH and (resourceSelection == nil or resourceSelection[abilityId or 0] ~= nil)

			elseif logtype == LIBCOMBAT_EVENT_PLAYERSTATS or logtype == LIBCOMBAT_EVENT_MESSAGES or logtype == LIBCOMBAT_EVENT_SKILL_TIMINGS or logtype == LIBCOMBAT_EVENT_BOSSHP or logtype == LIBCOMBAT_EVENT_DEATH or logtype == LIBCOMBAT_EVENT_PERFORMANCE then

				condition2 = true

			end

			if condition2 == true then

				writtenlines = writtenlines + 1

				if writtenlines >= (page-1)*1000 and writtenlines < page*1000 then

					local text, color = CMX.GetCombatLogString(fightData, logline, fontsize)

					window:AddColoredText(text, color)

				end
			end
		end
	end

	maxpage = math.max(math.ceil(writtenlines/1000), 1)

	local buttonrow = GetControl(panel, "HeaderPageButtonRow")

	buttonrow:Update(page, maxpage)

	local offset = buffer:GetNumHistoryLines()

	buffer:SetScrollPosition(math.min(buffer:GetScrollPosition() + offset, math.floor(buffer:GetNumHistoryLines()-(buffer:GetNumVisibleLines())/dx))) -- correct for ui scale
	slider:SetValue(slider:GetValue() - offset)
end

local CMX_PLOT_DIMENSION_X = 1
local CMX_PLOT_DIMENSION_Y = 2

local function MapValue(plotWindow, dimension, value, norm)

	local minRange, maxRange

	if norm then

		minRange = 0
		maxRange = 1

	else

		local range = dimension == CMX_PLOT_DIMENSION_X and plotWindow.RangesX or plotWindow.RangesY

		minRange, maxRange = unpack(range)

	end

	local controlSize = dimension == CMX_PLOT_DIMENSION_X and plotWindow:GetWidth() or plotWindow:GetHeight()

	local IsInRange = (value < maxRange) and (value > minRange)
	local offset = controlSize * ((value - minRange)/(maxRange - minRange))

	return offset, IsInRange

end

local function MapValueXY(plotWindow, x, y, normX, normY)

	local XOffset, IsInRangeX = plotWindow:MapValue(CMX_PLOT_DIMENSION_X, x, normX)
	local YOffset, IsInRangeY = plotWindow:MapValue(CMX_PLOT_DIMENSION_Y, y, normY)

	local IsInRange = IsInRangeX and IsInRangeY

	return XOffset, YOffset, IsInRange

end

local function MapUIPos(plotWindow, dimension, value)

	local range = dimension == CMX_PLOT_DIMENSION_X and plotWindow.RangesX or plotWindow.RangesY
	local minRange, maxRange = unpack(range)

	local minCoord = dimension == CMX_PLOT_DIMENSION_X and plotWindow:GetLeft() or plotWindow:GetTop()
	local maxCoord = dimension == CMX_PLOT_DIMENSION_X and plotWindow:GetRight() or plotWindow:GetBottom()

	local IsInRange = (value < maxCoord) and (value > minCoord)

	local relpos = (value - minCoord) / (maxCoord - minCoord)

	if dimension == CMX_PLOT_DIMENSION_Y then relpos = 1 - relpos end -- since coords start at topleft but a plot from bottom left

	local value = relpos * (maxRange - minRange) + minRange

	return value, IsInRange

end

local function MapUIPosXY(plotWindow, x, y)

	local t, IsInRangeX = plotWindow:MapUIPos(CMX_PLOT_DIMENSION_X, x)
	local v, IsInRangeY = plotWindow:MapUIPos(CMX_PLOT_DIMENSION_Y, y)

	local IsInRange = IsInRangeX and IsInRangeY

	return t, v, IsInRange

end

local function DrawLine(plot, coords, id)

	local plotid = plot.id
	local lineControls = plot.lineControls

	if lineControls[id] == nil then

		lineControls[id] = CreateControlFromVirtual("$(parent)Line", plot, "CombatMetrics_PlotLine", id)

	end

	local line = lineControls[id]

	local PlotColors = db.FightReport.PlotColors

	line:SetThickness(dx * 2)
	line:SetColor(unpack(db.FightReport.PlotColors[plotid]))
	line:ClearAnchors()

	local x1, y1, x2, y2, inRange1, inRange2 = unpack(coords)

	local minX = 0
	local minY = 0

	local maxX, maxY = plot:GetDimensions()

	local outOfRange =

		( x1 < minX and x2 < minX ) or
		( x1 > maxX and x2 > maxX ) or
		( y1 < minY and y2 < minY ) or
		( y1 > maxY and y2 > maxY )

	if outOfRange then	-- line is completely out of drawing area

		line:SetHidden(false)
		return

	elseif not (inRange1 and inRange2) then -- line is partially out of drawing area

		local m = (y2 - y1) / (x2 - x1)
		local n = y1 - (m * x1)

		if y1 > maxY then

			x1 = m == 0 and x1 or (maxY - n) / m
			y1 = maxY

		elseif y1 < minY then

			x1 = m == 0 and x1 or (minY - n) / m
			y1 = minY

		end

		if y2 > maxY then

			x2 = m == 0 and x2 or (maxY - n) / m
			y2 = maxY

		elseif y2 < minY then

			x2 = m == 0 and x2 or (minY - n) / m
			y2 = minY

		end

		if x1 < minX then

			x1 = minX
			y1 = m * minX + n

		end

		if x2 > maxX then

			x2 = maxX
			y2 = m * maxX + n

		end
	end

	-- in the end it is still possible that y values are out of range, in this case, the line doesn't touch the window.

	local inRange = y1 >= minY and y1 <= maxY and y2 >= minY and y2 <= maxY and x2 >= minX and x1 <= maxX

	if not inRange then

		line:SetHidden(false)
		return

	end

	local side1 = BOTTOMLEFT
	local side2 = TOPRIGHT

	if y1 > y2 then

		side1 = TOPLEFT
		side2 = BOTTOMRIGHT

	end

	line:SetAnchor(side1, plot, BOTTOMLEFT, x1, -y1)
	line:SetAnchor(side2, plot, BOTTOMLEFT, x2, -y2)
	line:SetHidden(false)

end

local function DrawBar(plot, x1, x2, id)

	local plotid = plot.id
	local barControls = plot.barControls

	if barControls[id] == nil then

		barControls[id] = CreateControlFromVirtual("$(parent)Bar", plot, "CombatMetrics_PlotBar", id)

	end

	local bar = barControls[id]

	bar:ClearAnchors()

	local minX = 0

	local xoffset = plot.xoffset

	local maxX, _ = plot:GetDimensions() - xoffset

	local outOfRange = ( x2 < minX ) or ( x1 > maxX )

	if outOfRange then	-- bar is completely out of drawing area

		bar:SetHidden(false)
		return

	end

	local left = math.max(x1, minX) + xoffset
	local right = math.min(x2, maxX) + xoffset

	local PlotColors = db.FightReport.PlotColors

	local color = plot.effectType == BUFF_EFFECT_TYPE_BUFF and PlotColors[6] or PlotColors[7]

	bar:SetAnchor(TOPLEFT, plot, TOPLEFT, left, 0)
	bar:SetAnchor(BOTTOMRIGHT, plot, BOTTOMLEFT, right, 0)
	bar:SetCenterColor(unpack(color))
	bar:SetHidden(false)

end

local COMBAT_METRICS_YAXIS_LEFT = 1
local COMBAT_METRICS_YAXIS_RIGHT = 2

local function DrawXYPlot(plot)

	local plotWindow = plot:GetParent()

	local XYData = plot.XYData

	if XYData == nil then return end

	local coordinates = {}
	plot.coordinates = coordinates

	for id, line in ipairs(plot.lineControls) do	-- hide previous Plot

		line:SetHidden(true)

	end

	local x0
	local y0
	local inRange0
	local normY = plot.YAxisSide == COMBAT_METRICS_YAXIS_RIGHT

	for i, dataPair in ipairs(XYData) do

		local t, v = unpack(dataPair)
		local x, y, inRange = plotWindow:MapValueXY(t, v, false, normY)
		coordinates[i] = {x, y, inRange}

		if i > 1 then

			local lineCoords = {x0, y0, x, y, inRange0, inRange}
			local id = i - 1

			DrawLine(plot, lineCoords, id)

		end

		x0 = x
		y0 = y
		inRange0 = inRange

	end
end

local function DrawBarPlot(plot)

	local plotWindow = plot:GetParent()

	local bardata = plot.bardata

	if bardata == nil then return end

	for id, bar in ipairs(plot.barControls) do	-- hide previous Plot

		bar:SetHidden(true)

	end

	for id, times in ipairs(bardata) do

		local t1, t2 = unpack(times)
		local x1, inRange1 = plotWindow:MapValue(CMX_PLOT_DIMENSION_X, t1, false)
		local x2, inRange2 = plotWindow:MapValue(CMX_PLOT_DIMENSION_X, t2, false)

		DrawBar(plot, x1, x2, id)

	end

end

local CMX_PLOT_TYPE_XY = 1
local CMX_PLOT_TYPE_BAR = 2

local plotTypeTemplates = {

	[CMX_PLOT_TYPE_XY] = "CombatMetrics_PlotControlXY",
	[CMX_PLOT_TYPE_BAR] = "CombatMetrics_PlotControlBar",

}

local function Smooth(category)

	if fightData == nil then return end

	local calcData = fightData.calculated

	local category = category or db.FightReport.category

	local data = calcData.graph and calcData.graph[category] or nil -- DPS data, one value per second

	if data == nil then return end

	local totaltime = fightData.combattime

	local smoothWindow = db.FightReport.SmoothWindow

	local XYData = {}

	local t2 = math.ceil(totaltime) - smoothWindow

	for t = 0, t2 do

		local sum = 0

		for i = 0, smoothWindow - 1 do

			sum = sum + (data[t + i] or 0)

		end

		local x = t + smoothWindow / 2

		local y = sum / smoothWindow

		if t == 0 then table.insert(XYData, {0, y}) end

		table.insert(XYData, {x, y})

		if t == t2 then table.insert(XYData, {totaltime, y}) end
	end

	return XYData, COMBAT_METRICS_YAXIS_LEFT, 1
end

local function Total(category)

	if fightData == nil then return end

	local calcData = fightData.calculated

	local category = category or db.FightReport.category

	local data = calcData.graph and calcData.graph[category] or nil -- DPS data, one value per second

	if data == nil then return end

	local totaltime = fightData.combattime

	local XYData = {}

	local t2 = math.ceil(totaltime)

	local sum = 0

	local t0
	local tmax

	local combatstart = fightData.combatstart

	if category == "healingOut" or category == "healingIn" then

		t0 = ((fightData.hpsstart - combatstart) / 1000) or 0
		tmax = ((fightData.hpsend - combatstart) / 1000) or 1

	else

		t0 = ((fightData.dpsstart - combatstart) / 1000) or 0
		tmax = ((fightData.dpsend - combatstart) / 1000) or 1

	end

	local startpoint = math.max(db.FightReport.SmoothWindow / 2, t0)

	for t = 0, t2 do

		sum = sum + (data[t] or 0)

		if t >= startpoint and t <= math.ceil(tmax) then

			local x = t

			local y = sum / (math.min(tmax, t) - t0)

			table.insert(XYData, {x, y})

		end
	end

	return XYData, COMBAT_METRICS_YAXIS_LEFT, 1
end

local function Absolute(category)

	if fightData == nil then return end

	local calcData = fightData.calculated

	local category = category or db.FightReport.category

	local data = calcData.graph and calcData.graph[category] or nil -- DPS data, one value per second

	if data == nil then return end

	local totaltime = fightData.combattime

	local XYData = {}

	local t2 = math.ceil(totaltime)

	local sum = 0

	for t = 0, t2 do

		sum = sum + (data[t] or 0)

		table.insert(XYData, {t, sum})

	end

	for i, xyData in ipairs(XYData) do

		xyData[2] = xyData[2]/sum

	end

	return XYData, COMBAT_METRICS_YAXIS_RIGHT, sum
end

local powerTypeKeyTable = {

	[POWERTYPE_HEALTH] = "maxmaxhealth",
	[POWERTYPE_MAGICKA] = "maxmaxmagicka",
	[POWERTYPE_STAMINA] = "maxmaxstamina",

}

local oldX, oldY

local function updateXYData(XYData, x, y)

	if #XYData == 0 then

		oldX = -1
		oldY = y

	end

	if x - 1 > oldX and oldY and oldY ~= y then

		table.insert(XYData, {oldX + 1, oldY})

	end

	if x - 2 > oldX and oldY then

		table.insert(XYData, {x - 1, oldY})

	end

	if x > oldX then

		table.insert(XYData, {x, y})

		oldX = x

	end

	oldY = y
end

local function ResourceAbsolute(powerType)

	if powerType == nil or fightData == nil or fightData.log == nil then return end

	local logData = fightData.log

	local combatstart = fightData.combatstart/1000

	local XYData = {}

	local value

	for line, lineData in ipairs(logData) do

		if lineData[1] == LIBCOMBAT_EVENT_RESOURCES and lineData[5] == powerType and lineData[6] then

			local deltatime = math.floor(lineData[2]/1000 - combatstart)

			value = lineData[6] or 0

			updateXYData(XYData, deltatime, value)

		end
	end

	if value then updateXYData(XYData, fightData.combattime, value) end

	local key = powerTypeKeyTable[powerType]

	local maxValue = powerType == POWERTYPE_ULTIMATE and 500 or fightData.stats[key]

	for i, xyData in ipairs(XYData) do

		xyData[2] = xyData[2]/maxValue

	end

	return XYData, COMBAT_METRICS_YAXIS_RIGHT, maxValue
end

local function BossHPAbsolute()

	if fightData == nil or fightData.log == nil then return end

	local logData = fightData.log

	local combatstart = fightData.combatstart/1000

	local XYData = {}

	local x	= -1
	local y

	local maxhp = 0

	for line, lineData in ipairs(logData) do

		if lineData[1] == LIBCOMBAT_EVENT_BOSSHP then

			local deltatime = math.floor(lineData[2]/1000 - combatstart)

			if deltatime > x then

				x = deltatime

				y = lineData[4]/lineData[5]

				table.insert(XYData, {x, y})
			end
		end
	end

	return XYData, COMBAT_METRICS_YAXIS_RIGHT, maxhp
end

local function PerformancePlot(dataType)

	if fightData == nil or fightData.log == nil then return end

	local logData = fightData.log

	local combatstart = fightData.combatstart/1000

	local XYData = {}

	local x	= -1
	local y

	local event = dataType == 7 and LIBCOMBAT_EVENT_SKILL_TIMINGS or LIBCOMBAT_EVENT_PERFORMANCE	-- skill delay is recorded with another logtype
	local key = dataType == 7 and 6 or dataType

	for line, lineData in ipairs(logData) do

		if lineData[1] == event and lineData[key] then

			local deltatime = math.floor(lineData[2]/1000 - combatstart)

			if deltatime > x then

				x = deltatime
				y = lineData[key]

				table.insert(XYData, {x, y})
			end
		end
	end

	return XYData, COMBAT_METRICS_YAXIS_LEFT, 1
end

local function StatAbsolute(statId)

	if fightData == nil or fightData.log == nil then return end

	local logData = fightData.log

	local combatstart = fightData.combatstart/1000

	local XYData = {}

	local maxvalue = 0

	local value

	for line, lineData in ipairs(logData) do

		if lineData[1] == LIBCOMBAT_EVENT_PLAYERSTATS and lineData[5] == statId then

			value = lineData[4]

			maxvalue = math.max(value, maxvalue)

			local deltatime = math.floor(lineData[2]/1000 - combatstart)

			updateXYData(XYData, deltatime, value)

		end
	end

	updateXYData(XYData, fightData.combattime, value)

	for i, xyData in ipairs(XYData) do

		xyData[2] = xyData[2]/maxvalue

	end

	return XYData, COMBAT_METRICS_YAXIS_RIGHT, maxvalue
end

local function AcquireBuffData(buffName)

	if fightData == nil or fightData.log == nil then return end

	local rightpanel = db.FightReport.rightpanel

	local category = db.FightReport.category

	local unitselections = rightpanel == "buffs" and {[fightData.playerid] = 1} or selections.unit[category]

	local logData = fightData.log

	if logData == nil then return end

	local combatstart = fightData.combatstart/1000
	local combattime = fightData.combattime

	local timeData = {}

	local first = true
	local lastSlot
	local lastUnit

	local slots = {}

	local showGroupBuffs = db.FightReport.ShowGroupBuffsInPlots

	for line, lineData in ipairs(logData) do

		local result, timems, unitId, abilityId, changeType = unpack(lineData)	-- unpack only runs until it encounters nil
		local effectSlot = lineData[9]											-- so effectSlot has to be taken separately

		local isResult = result == LIBCOMBAT_EVENT_EFFECTS_IN or result == LIBCOMBAT_EVENT_EFFECTS_OUT
		local isGroupResult = showGroupBuffs and (result == LIBCOMBAT_EVENT_GROUPEFFECTS_IN or result == LIBCOMBAT_EVENT_GROUPEFFECTS_OUT)

		if (isResult or isGroupResult) and GetFormattedAbilityName(abilityId) == buffName and ((unitselections and unitselections[unitId]) or (unitselections == nil)) then

			local deltatime = timems/1000 - combatstart

			if changeType == EFFECT_RESULT_GAINED and deltatime < combattime then

				slots[effectSlot] = deltatime
				first = false
				lastSlot = effectSlot
				lastUnit = unitId

			elseif changeType == EFFECT_RESULT_FADED then

				local starttime = first and 0 or slots[effectSlot] or nil

				if starttime and deltatime > starttime and deltatime > 0 then

					local previoustimes = timeData[#timeData]

					local prevend = previoustimes and previoustimes[2] or nil
					local prevunit = previoustimes and previoustimes[3] or nil

					if prevend and (math.abs(starttime - prevend)) < 0.02 and prevunit == unitId then 		-- to avoid drawing too many controls: if a buff is renewed within 20 ms, consider it continious

						previoustimes[2] = deltatime

					else

						table.insert(timeData, {starttime, deltatime, unitId})

					end
				end

				lastSlot = nil

			end
		end
	end

	if lastSlot then

		local unittime = fightData.calculated.units[lastUnit].endtime
		local endtime = unittime and (unittime/1000 - combatstart) or fightData.combattime

		if slots[lastSlot] < endtime then table.insert(timeData, {slots[lastSlot], endtime}) end

	end

	return timeData

end

local function GetScale(x1, x2)	-- e.g. 34596 and 42693

	local distance = math.max(x2 - x1, 1)	-- 8097

	local power = math.pow(10, math.floor(math.log10(distance/2)))	-- math.pow(10, math.floor(3.61) = math.pow(10, 3) = 1000

	local high = math.ceil(x2 / power) * power	-- 43000
	local low = math.floor(x1 / power) * power	-- 34000

	local size = (high - low) / power 	-- 9000 / 1000 = 9

	local cleansize = math.floor(size)
	--[[
	local rangesizes = {1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20}

	local cleansize = rangesizes[#rangesizes]

	for i, value in ipairs(rangesizes) do

		if size <= value then

			cleansize = value	-- 10
			break

		end -- sometimes somehow a too big value comes out ??
	end
	--]]

	local delta = cleansize - size -- 1

	local cleanLow = low - math.floor(delta / 2) * power 	-- 34000 - math.floor(0.5) * 1000 = 34000
	local cleanHigh = high + math.ceil(delta / 2) * power 	-- 34000 - math.ceil(0.5) * 1000 = 44000

	if cleanLow < 0 then

		cleanHigh = cleanHigh - cleanLow
		cleanLow = 0

	end

	local cleanDist = cleanHigh - cleanLow

	return cleanLow, cleanHigh

end

local function GetTickValues(low, high)

	local tickValues = {low, 0, 0, 0, high}

	for i = 2,4 do

		tickValues[i] = math.floor(low + (high - low) * (i - 1) / 4)

	end

	return tickValues

end

local function UpdateScales(plotWindow, ranges, exact)

	local xMin, xMax, yMin, yMax = unpack(ranges)

	if not exact then

		xMin, xMax = GetScale(xMin, xMax)
		yMin, yMax = GetScale(yMin, yMax)

	end

	local ticksX = GetTickValues(xMin, xMax)
	local ticksY = GetTickValues(yMin, yMax)

	plotWindow.RangesX = {xMin, xMax, ticksX}
	plotWindow.RangesY = {yMin, yMax, ticksY}

	for i = 1,5 do

		local ticklabelX = GetControl(plotWindow:GetName(), "XTick" .. i .. "Label")
		local ticklabelY = GetControl(plotWindow:GetName(), "YTick" .. i .. "Label")

		ticklabelX:SetText(tostring(ticksX[i]))
		ticklabelY:SetText(tostring(ticksY[i]))

	end
end

local function AcquireRange(XYData)

	local minX = 0
	local maxX = 0
	local minY = 0
	local maxY = 0

	for i, coords in ipairs(XYData) do

		local x, y = unpack(coords)

		minX = math.min(minX, x)
		maxX = math.max(maxX, x)
		minY = math.max(minY, y)
		maxY = math.max(maxY, y)

	end

	local range = {minX, maxX, minY, maxY}

	return range

end

local function GetRequiredRange(plotWindow, newRange, startZero)

	local oldRangeX = plotWindow.RangesX
	local oldRangeY = plotWindow.RangesY

	local minXOld = oldRangeX[1]
	local maxXOld = oldRangeX[2]
	local minYOld = oldRangeY[1]
	local maxYOld = oldRangeY[2]

	local minX, maxX, minY, maxY = unpack(newRange)

	local minXNew = startZero and 0 or math.min(minXOld, minX)
	local maxXNew = math.max(maxXOld, maxX)
	local minYNew = startZero and 0 or math.min(minYOld, minY)
	local maxYNew = math.max(maxYOld, maxY)

	local isChanged = minXOld ~= minXNew or maxXOld ~= maxXNew or minYOld ~= minYNew or maxYOld ~= maxYNew

	return {minXNew, maxXNew, minYNew, maxYNew}, isChanged

end

local function UpdateXYPlot(plot)

	local func = plot.func

	local XYData, YAxisSide

	if func then

		XYData, YAxisSide, plot.AbsoluteYRange = func()

	end

	if XYData == nil then

		plot:SetHidden(true)

		return

	end

	plot:SetHidden(false)

	local range = AcquireRange(XYData)

	if YAxisSide == COMBAT_METRICS_YAXIS_RIGHT then

		range[3] = 0
		range[4] = 1

	end

	local plotWindow = plot:GetParent()

	if plot.autoRange then

		local newRange, isChanged = plotWindow:GetRequiredRange(range, true)

		if isChanged then plotWindow:UpdateScales(newRange) end

	end

	plot.range = range

	plot.XYData = XYData
	plot.YAxisSide = YAxisSide

end

local PlotBuffSelection = {}

local function UpdatePlotBuffSelection()

	PlotBuffSelection = {}

	local selectedbuffs = selections["buff"]["buff"]

	local buffData = GetBuffData()

	if buffData == nil or buffData.buffs == nil then return end

	for buffName, buff in CMX.spairs(buffData.buffs, buffSortFunction) do

		if selectedbuffs and selectedbuffs[buffName] ~= nil then PlotBuffSelection[#PlotBuffSelection + 1] = buffName end

		if #PlotBuffSelection >= maxBarPlots then return end

	end
end

local function UpdateBarPlot(plot)

	local barId = plot.barId or 0

	local buffName = PlotBuffSelection[barId]
	local buffData = GetBuffData()

	local data = buffName and buffData and buffData.buffs[buffName] or nil

	if buffName == nil then

		plot:SetHidden(true)

		return

	end

	local bardata = AcquireBuffData(buffName)

	plot:SetHidden(false)

	local plotWindow = plot:GetParent()

	local plotheight = plotWindow:GetHeight()

	local totalSlots = #PlotBuffSelection > 4 and 8 or 4

	local position = plotheight * (barId - 0.5)/totalSlots

	local scale = db.FightReport.scale
	local xoffset = scale * 24

	plot:SetAnchor(LEFT, plotWindow, TOPLEFT, -xoffset, position)
	plot:SetAnchor(RIGHT, plotWindow, TOPRIGHT, 0, position)
	plot:SetHeight(scale * 20)

	local icon = plot:GetNamedChild("Icon")

	icon:SetTexture(GetFormattedAbilityIcon(data.iconId))
	icon.tooltip = {buffName}

	plot.bardata = bardata
	plot.xoffset = xoffset
	plot.effectType = data.effectType

	plot:DrawPlot()

end

local function updateGraphPanel(panel)

	if panel:IsHidden() then return end

	if enlargedGraph == true then

		panel:SetParent(CombatMetrics_Report)
		panel:SetAnchor(BOTTOMRIGHT, CombatMetrics_Report_InfoPanel, BOTTOMRIGHT, 0, 0)

	else

		panel:SetParent(CombatMetrics_Report_MainPanel)
		panel:SetAnchor(BOTTOMRIGHT, CombatMetrics_Report_MainPanel, BOTTOMRIGHT, 0, 0)

	end

	CombatMetrics_Report:GetNamedChild("_AbilityPanel"):SetHidden(enlargedGraph)
	CombatMetrics_Report:GetNamedChild("_UnitPanel"):SetHidden(enlargedGraph)
	CombatMetrics_Report:GetNamedChild("_RightPanel"):SetHidden(enlargedGraph)
	CombatMetrics_Report:GetNamedChild("_MainPanel"):SetHidden(enlargedGraph)

	local plotWindow = panel:GetNamedChild("PlotWindow")
	local toolbar = panel:GetNamedChild("Toolbar")
	local smoothSlider = toolbar:GetNamedChild("SmoothControl"):GetNamedChild("Slider")

	local SmoothWindow = db.FightReport.SmoothWindow

	smoothSlider:SetValue(SmoothWindow)

	local groupSelector = toolbar:GetNamedChild("BuffSelector1"):GetNamedChild("GroupSelector")
	groupSelector:SetHidden(db.FightReport.rightpanel ~= "buffsout")

	if fightData == nil then plotWindow:SetHidden(true) return end

	plotWindow:SetHidden(false)
	plotWindow.RangesX = {0, 0, {}}
	plotWindow.RangesY = {0, 0, {}}

	UpdatePlotBuffSelection()

	for id, plot in ipairs(plotWindow.plots) do

		plot:Update()

	end

	for id, plot in pairs(plotWindow.plots) do

		if plot.DrawPlot then

			plot:DrawPlot()

		end
	end
end

function CMX.SetSliderValue(self, value)

	local labelControl = self:GetParent():GetNamedChild("Label")

	labelControl:SetText(string.format(GetString(SI_COMBAT_METRICS_SMOOTH_LABEL), value))

	db.FightReport.SmoothWindow = value

	local graphPanel = self:GetParent():GetParent():GetParent()

	graphPanel:Update()

end

local function limit(value, minValue, maxValue)

	local coercedValue = math.min(math.max(value, minValue), maxValue)

	return coercedValue

end

do

	local startX, startY, plotWindow

	local function UpdateZoomControl()

		local zoomcontrol = plotWindow:GetNamedChild("Zoom")

		local x2, y2 = GetUIMousePosition()

		local minX, minY, maxX, maxY = plotWindow:GetScreenRect()

		limit(x2, minX, maxX)
		limit(y2, minY, maxY)

		local width = math.abs(x2 - startX)
		local height = math.abs(y2 - startY)

		zoomcontrol:SetAnchor(TOPLEFT, GuiRoot , TOPLEFT, math.min(startX, x2), math.min(startY, y2))
		zoomcontrol:SetDimensions(width, height)

	end

	local oldx, oldy

	local function updatePlotCursor()

		local x, y = GetUIMousePosition()

		if x == oldx and y == oldy then return end

		oldx, oldy = x, y

		local cursorTime, cursorValue = plotWindow:MapUIPosXY(x, y)

		local dataAtCursorTime = {}

		for _, plot in pairs(plotWindow.plots) do

			if plot.plotType == CMX_PLOT_TYPE_XY and plot.XYData then

				local coords = {0, 0, 0}

				for i, data in pairs(plot.XYData) do

					local t, v = unpack(data)

					if t > cursorTime then

						dataAtCursorTime[plot.id] = coords
						break

					end

					local percentV

					if plot.YAxisSide == COMBAT_METRICS_YAXIS_RIGHT then

						percentV = v * 100

						v = v * plot.AbsoluteYRange

					end

					coords = {v, percentV}

				end
			end
		end

		InitializeTooltip(InformationTooltip, GuiRoot, TOPLEFT, x + 30, y + 30, TOPLEFT)

		local tooltipText = string.format("|cddddddTime: %d:%02d", cursorTime/60, math.floor(cursorTime%60))

		AddTooltipLine(plotWindow, InformationTooltip, tooltipText)

		for plotId, data in CMX.spairs(dataAtCursorTime) do

			local r,g,b = unpack(db.FightReport.PlotColors[plotId])

			local formatter = data[2] and "|c%.2x%.2x%.2x%s: %d (%.1f%%)|r" or "|c%.2x%.2x%.2x%s: %d|r"

			local label = plotWindow.plots[plotId].label

			tooltipText = string.format(formatter, math.floor(r * 255), math.floor(g * 255), math.floor(b * 255), label, unpack(data))

			AddTooltipLine(plotWindow, InformationTooltip, tooltipText)

		end

		local cursor = plotWindow:GetNamedChild("Cursor")

		cursor:ClearAnchors()
		cursor:SetAnchor(TOPLEFT, plotWindow, TOPLEFT, x - plotWindow:GetLeft(), 0)
		cursor:SetAnchor(BOTTOMLEFT, plotWindow, BOTTOMLEFT, x - plotWindow:GetLeft(), 0)

	end

	function CMX.onPlotMouseDown(plotWindowControl, button)

		if button ~= MOUSE_BUTTON_INDEX_LEFT then return end

		CMX.onPlotMouseExit(plotWindowControl)

		local zoomcontrol = plotWindow:GetNamedChild("Zoom")

		local x, y = GetUIMousePosition()

		zoomcontrol:SetAnchor(TOPLEFT, GuiRoot , TOPLEFT, x, y)
		zoomcontrol:SetDimensions(0, 0)
		zoomcontrol:SetHidden(false)

		startX = x
		startY = y

		plotWindow = plotWindowControl

		em:RegisterForUpdate("CMX_Report_Zoom_Control", 40, UpdateZoomControl)

	end

	function CMX.onPlotMouseUp(plotWindow, button, upInside)

		if button == MOUSE_BUTTON_INDEX_LEFT then

			local x, y = GetUIMousePosition()

			em:UnregisterForUpdate("CMX_Report_Zoom_Control")
			local zoomcontrol = plotWindow:GetNamedChild("Zoom")
			zoomcontrol:SetHidden(true)

			if x == startX and y == startY then

				CMX.onPlotMouseEnter(plotWindow)
				return

			end

			local t1, v1 = plotWindow:MapUIPosXY(startX, startY)
			local t2, v2 = plotWindow:MapUIPosXY(x, y)

			local minT, maxT = unpack(plotWindow.RangesX)
			local minV, maxV = unpack(plotWindow.RangesY)

			t2 = limit(t2, minT, maxT)
			v2 = limit(v2, minV, maxV)

			local tMin = math.min(t1, t2)
			local tMax = math.max(t1, t2)
			local vMin = math.min(v1, v2)
			local vMax = math.max(v1, v2)

			plotWindow:UpdateScales({tMin, tMax, vMin, vMax})

			for id, plot in pairs(plotWindow.plots) do

				if plot.DrawPlot then

					plot:DrawPlot()

				end
			end

		elseif button == MOUSE_BUTTON_INDEX_RIGHT then

			plotWindow.RangesX = {0, 0, {}}
			plotWindow.RangesY = {0, 0, {}}

			for id, plot in pairs(plotWindow.plots) do

				if plot.XYData and plot.autoRange and plot:IsHidden() == false then

					local newRange = plotWindow:GetRequiredRange(plot.range, true)

					plotWindow:UpdateScales(newRange)

				end
			end

			for id, plot in pairs(plotWindow.plots) do

				if plot.DrawPlot then

					plot:DrawPlot()

				end
			end
		end

		if upInside then CMX.onPlotMouseEnter(plotWindow) end
	end

	function CMX.onPlotMouseEnter(plotWindowControl)

		plotWindow = plotWindowControl

		if db.FightReport.Cursor then

			local cursor = plotWindow:GetNamedChild("Cursor")
			cursor:SetHidden(false)

			em:RegisterForUpdate("CMX_Report_Cursor_Control", 40, updatePlotCursor)

		end
	end

	function CMX.onPlotMouseExit(plotWindowControl)

		em:UnregisterForUpdate("CMX_Report_Cursor_Control")
		ZO_Options_OnMouseExit(plotWindowControl)

		local cursor = plotWindow:GetNamedChild("Cursor")
		cursor:SetHidden(true)

	end

	function CMX.EditLabelStart(label)

		local editbox = label:GetParent():GetNamedChild("Edit")

		label:SetHidden(true)
		editbox:SetHidden(false)

		editbox:SetText( label:GetText() )
		editbox:SelectAll()
		editbox:TakeFocus()

	end

	function CMX.EditLabelEnd(editbox)

		local tickControl = editbox:GetParent()
		local plotWindow = tickControl:GetParent()
		local label = tickControl:GetNamedChild("Label")

		editbox:SetHidden(true)
		label:SetHidden(false)

		local newtext = tonumber(editbox:GetText())
		label:SetText(newtext)

		local t1 = tonumber(plotWindow:GetNamedChild("XTick1"):GetNamedChild("Label"):GetText())
		local t2 = tonumber(plotWindow:GetNamedChild("XTick5"):GetNamedChild("Label"):GetText())
		local v1 = tonumber(plotWindow:GetNamedChild("YTick1"):GetNamedChild("Label"):GetText())
		local v2 = tonumber(plotWindow:GetNamedChild("YTick5"):GetNamedChild("Label"):GetText())

		local tMin = math.min(t1, t2)
		local tMax = math.max(t1, t2)
		local vMin = math.min(v1, v2)
		local vMax = math.max(v1, v2)

		plotWindow:UpdateScales({tMin, tMax, vMin, vMax}, true)

		for id, plot in pairs(plotWindow.plots) do

			if plot.DrawPlot then

				plot:DrawPlot()

			end
		end

	end

end

local PlotFunctions = {}

local MainCategoryFunctions = {

	[1] = {label = SI_COMBAT_METRICS_SMOOTHED, 		func = Smooth},
	[2] = {label = SI_COMBAT_METRICS_TOTAL, 		func = Total},
	[3] = {label = SI_COMBAT_METRICS_ABSOLUTE, 		func = Absolute},

}

local CategoryStrings = {

	[1] = {label = SI_COMBAT_METRICS_DPS, 			category = "damageOut"},
	[2] = {label = SI_COMBAT_METRICS_HPS, 			category = "healingOut"},
	[3] = {label = SI_COMBAT_METRICS_INCOMING_DPS, 	category = "damageIn"},
	[4] = {label = SI_COMBAT_METRICS_INCOMING_HPS, 	category = "healingIn"},

}

--[[local ResourceFunctions = {

	[1] = {label = SI_COMBAT_METRICS_ABSOLUTE, 	func = ResourceAbsolute},

}--]]

local ResourceStrings = {

	[1] = {label = SI_COMBAT_METRICS_HEALTH, 	powerType = POWERTYPE_HEALTH},
	[2] = {label = SI_COMBAT_METRICS_MAGICKA, 	powerType = POWERTYPE_MAGICKA},
	[3] = {label = SI_COMBAT_METRICS_STAMINA, 	powerType = POWERTYPE_STAMINA},
	[4] = {label = SI_COMBAT_METRICS_ULTIMATE, 	powerType = POWERTYPE_ULTIMATE},

}

local StatStrings = {

	[1] = {label = SI_COMBAT_METRICS_STATS_MAGICKA1, 	statId = LIBCOMBAT_STAT_MAXMAGICKA},
	[2] = {label = SI_COMBAT_METRICS_STATS_MAGICKA2, 	statId = LIBCOMBAT_STAT_SPELLPOWER},
	[3] = {label = SI_COMBAT_METRICS_STATS_MAGICKA3, 	statId = LIBCOMBAT_STAT_SPELLCRIT},
	[4] = {label = SI_COMBAT_METRICS_STATS_MAGICKA4, 	statId = LIBCOMBAT_STAT_SPELLCRITBONUS},
	[5] = {label = SI_COMBAT_METRICS_STATS_MAGICKA5, 	statId = LIBCOMBAT_STAT_SPELLPENETRATION},
	[6] = {label = SI_COMBAT_METRICS_STATS_STAMINA1, 	statId = LIBCOMBAT_STAT_MAXSTAMINA},
	[7] = {label = SI_COMBAT_METRICS_STATS_STAMINA2, 	statId = LIBCOMBAT_STAT_WEAPONPOWER},
	[8] = {label = SI_COMBAT_METRICS_STATS_STAMINA3, 	statId = LIBCOMBAT_STAT_WEAPONCRIT},
	[9] = {label = SI_COMBAT_METRICS_STATS_STAMINA4, 	statId = LIBCOMBAT_STAT_WEAPONCRITBONUS},
	[10] = {label = SI_COMBAT_METRICS_STATS_STAMINA5, 	statId = LIBCOMBAT_STAT_WEAPONPENETRATION},
	[11] = {label = SI_COMBAT_METRICS_STATS_HEALTH1, 	statId = LIBCOMBAT_STAT_MAXHEALTH},
	[12] = {label = SI_COMBAT_METRICS_STATS_HEALTH2, 	statId = LIBCOMBAT_STAT_PHYSICALRESISTANCE},
	[13] = {label = SI_COMBAT_METRICS_STATS_HEALTH3, 	statId = LIBCOMBAT_STAT_SPELLRESISTANCE},
	[14] = {label = SI_COMBAT_METRICS_STATS_HEALTH4, 	statId = LIBCOMBAT_STAT_CRITICALRESISTANCE},

}

local PerformanceStrings = {

	[1] = {label = SI_COMBAT_METRICS_PERFORMANCE_FPSAVG, 	statId = 3},
	[2] = {label = SI_COMBAT_METRICS_PERFORMANCE_FPSMIN, 	statId = 4},
	[3] = {label = SI_COMBAT_METRICS_PERFORMANCE_FPSMAX, 	statId = 5},
	[4] = {label = SI_COMBAT_METRICS_PERFORMANCE_FPSPING, 	statId = 6},
	[5] = {label = SI_COMBAT_METRICS_PERFORMANCE_DESYNC, 	statId = 7},

}

local lastPlotSelector

local function RemovePlotSelection()

	local selector = lastPlotSelector

	local control = selector:GetParent()
	local id = control.id

	local label = control:GetNamedChild("Label")
	label:SetText("-")

	local plotwindow = control:GetParent():GetParent():GetNamedChild("PlotWindow")

	local plot = plotwindow.plots[id]

	plot.func = nil

	plot:Update()

end

function CMX.PlotSelectionMenu(selector)

	ClearMenu()

	lastPlotSelector = selector

	AddCustomMenuItem(GetString(SI_COMBAT_METRICS_NONE), RemovePlotSelection)

	local funcId = 1

	for id, data in ipairs(CategoryStrings) do

		local submenu = {}

		for id2, data2 in ipairs(MainCategoryFunctions) do

			local stringid2 = data2.label

			table.insert(submenu, {label = GetString(stringid2), callback = PlotFunctions[funcId]})

			funcId = funcId + 1

		end

		local stringid = data.label

		AddCustomSubMenuItem(GetString(stringid), submenu)

	end

	AddCustomMenuItem(GetString(SI_COMBAT_METRICS_BOSS_HP), PlotFunctions[funcId])
	funcId = funcId + 1

	local submenu2 = {}

	for id, data in ipairs(ResourceStrings) do

		table.insert(submenu2, {label = GetString(data.label).." %", callback = PlotFunctions[funcId]})

		funcId = funcId + 1

	end

	AddCustomSubMenuItem(GetString(SI_COMBAT_METRICS_RESOURCES), submenu2)

	local submenu3 = {}

	for id, data in ipairs(StatStrings) do

		table.insert(submenu3, {label = GetString(data.label).." %", callback = PlotFunctions[funcId]})

		funcId = funcId + 1

		if id == 5 or id == 10 then table.insert(submenu3, {label = "-"}) end

	end

	AddCustomSubMenuItem(GetString(SI_COMBAT_METRICS_STATS), submenu3)

	local submenu4 = {}

	for id, data in ipairs(PerformanceStrings) do

		table.insert(submenu4, {label = GetString(data.label), callback = PlotFunctions[funcId]})

		funcId = funcId + 1

	end

	AddCustomSubMenuItem(GetString(SI_COMBAT_METRICS_PERFORMANCE), submenu4)

	ShowMenu(selector)
	AnchorMenu(selector)

end

local plotDefaultFunction = {

	[1] = Smooth,
	[2] = Total,

}

local function InitBarPlot(plotWindow, id)

	local plots = plotWindow.plots

	local newPlot = plots[id]

	if newPlot == nil then

		newPlot = CreateControlFromVirtual("CombatMetrics_Report_MainPanelGraphPlot", plotWindow, plotTypeTemplates[CMX_PLOT_TYPE_BAR], id)

		newPlot.plotType = CMX_PLOT_TYPE_BAR

		newPlot.barControls = {}
		newPlot.DrawPlot = DrawBarPlot

		newPlot.Update = UpdateBarPlot

		newPlot.id = id
		newPlot.barId = id - maxXYPlots

		plots[id] = newPlot

	end

	return newPlot
end

local function InitXYPlot(plotWindow, id)

	local plots = plotWindow.plots

	local newPlot = plots[id]

	if newPlot == nil then

		newPlot = CreateControlFromVirtual("CombatMetrics_Report_MainPanelGraphPlot", plotWindow, plotTypeTemplates[CMX_PLOT_TYPE_XY], id)

		newPlot.plotType = CMX_PLOT_TYPE_XY

		newPlot.lineControls = {}
		newPlot.DrawPlot = DrawXYPlot

		newPlot.Update = UpdateXYPlot
		newPlot.autoRange = true

		newPlot.id = id

		local category = db.FightReport.category

		local catId = 1

		while CategoryStrings[catId].category ~= category do

			catId = catId + 1

		end

		if id <= 2 then

			local selectorLabel = plotWindow:GetParent():GetNamedChild("Toolbar"):GetNamedChild("DataSelector" .. id):GetNamedChild("Label")

			local labelString = zo_strformat("<<1>> - <<2>>", GetString(CategoryStrings[catId].label), GetString(MainCategoryFunctions[id].label))

			selectorLabel:SetText(labelString)

			newPlot.func = function() return plotDefaultFunction[id](category) end
			newPlot.label = labelString

		end

		plots[id] = newPlot

	end

	return newPlot
end

local function getCustomMenuFunction(basefunc, parameter, labelString)

	local function newFunc()

		local selector = lastPlotSelector

		local control = selector:GetParent()
		local id = control.id

		local label = control:GetNamedChild("Label")

		label:SetText(labelString)

		local plotwindow = control:GetParent():GetParent():GetNamedChild("PlotWindow")

		local plot = plotwindow.plots[id]

		plot.func = function() return basefunc(parameter) end
		plot.label = labelString:gsub(" %%", "")

		plot:Update()

		local plotWindow = plot:GetParent()

		for id, plot in pairs(plotWindow.plots) do

			if plot.DrawPlot then

				plot:DrawPlot()

			end
		end

	end

	return newFunc

end

local function initPlotWindow(plotWindow)

	plotWindow.MapValue = MapValue
	plotWindow.MapValueXY = MapValueXY
	plotWindow.MapUIPos = MapUIPos
	plotWindow.MapUIPosXY = MapUIPosXY
	plotWindow.InitXYPlot = InitXYPlot
	plotWindow.InitBarPlot = InitBarPlot
	plotWindow.UpdateScales = UpdateScales
	plotWindow.GetRequiredRange = GetRequiredRange

	plotWindow.plots = {}

	for i = 1, 5 do

		local labelR = plotWindow:GetNamedChild("YTick" .. i):GetNamedChild("LabelR")

		local text = string.format("%d%%", (i - 1) * 25)

		labelR:SetText(text)

	end

	local editableControls = {"XTick1", "XTick5", "YTick1", "YTick5"}

	for i = 1, 4 do

		local name = editableControls[i]
		local control = plotWindow:GetNamedChild(name)
		local label = control:GetNamedChild("Label")

		local editControlName = control:GetName() .. "Edit"

		local editControl = CreateControlFromVirtual(editControlName, control, "CombatMetrics_GraphTickLabel_Edit")
		editControl:SetAnchorFill(label)

		local font, size, style = unpack(editControl:GetNamedChild("Font").font)			-- Need to manually scale font since it's created late

		if size then size = tonumber(size) * (db.FightReport.scale + 0.2)/1.2 end

		editControl:SetFont(string.format("%s|%s|%s", font, size, style))

		label:SetHandler("OnMouseDoubleClick", CMX.EditLabelStart)

	end

	local funcId = 1

	for id, data in ipairs(CategoryStrings) do

		for id2, data2 in ipairs(MainCategoryFunctions) do

			local categoryString = data.label
			local category = data.category

			local labelString = zo_strformat("<<1>> - <<2>>", GetString(categoryString), GetString(data2.label))

			local basefunc = data2.func

			PlotFunctions[funcId] = getCustomMenuFunction(basefunc, category, labelString)

			funcId = funcId + 1

		end
	end

	PlotFunctions[funcId] = getCustomMenuFunction(BossHPAbsolute, nil, GetString(SI_COMBAT_METRICS_BOSS_HP))

	funcId = funcId + 1

	for id, data in ipairs(ResourceStrings) do

		local resourceString = data.label
		local powerType = data.powerType

		local labelString = GetString(resourceString) .. " %"

		PlotFunctions[funcId] = getCustomMenuFunction(ResourceAbsolute, powerType, labelString)

		funcId = funcId + 1

	end

	for id, data in ipairs(StatStrings) do

		local statString = data.label
		local statId = data.statId

		local labelString = GetString(statString) .. " %"

		PlotFunctions[funcId] = getCustomMenuFunction(StatAbsolute, statId, labelString)

		funcId = funcId + 1

	end

	for id, data in ipairs(PerformanceStrings) do

		local perfString = data.label
		local perfId = data.statId

		local labelString = GetString(perfString)

		PlotFunctions[funcId] = getCustomMenuFunction(PerformancePlot, perfId, labelString)

		funcId = funcId + 1

	end

	for id = 1, maxXYPlots do

		plotWindow:InitXYPlot(id)

	end

	for id = maxXYPlots + 1, maxXYPlots + maxBarPlots do

		plotWindow:InitBarPlot(id)

	end
end

local function initPlotToolbar(toolbar)

	local PlotColors = db.FightReport.PlotColors

	local cursorToggle = toolbar:GetNamedChild("ToggleCursor")

	cursorToggle:SetAlpha(db.FightReport.Cursor and 1 or 0.3)

	for i = 1,5 do

		local selector = toolbar:GetNamedChild("DataSelector" .. i)

		selector.id = i

		local colorbox = selector:GetNamedChild("ColorBox")

		local color = PlotColors[i]

		colorbox:SetCenterColor(unpack(color))
		selector.color = color

		local function updateColor(r, g, b, a)

			colorbox:SetCenterColor(r, g, b, a)

			selector.color = {r, g, b, a}

			PlotColors[i] = {r, g, b, a}

			toolbar:GetParent():Update()

		end

		colorbox:SetHandler("OnMouseUp", function(self, button, upInside)

				if upInside then

					local r, g, b, a = unpack(selector.color)
					COLOR_PICKER:Show(updateColor, r, g, b, a)

				end
			end
		)
	end

	local labeltexts = {GetString(SI_COMBAT_METRICS_BUFFS), GetString(SI_COMBAT_METRICS_DEBUFFS)}
	local showGroupBuffs = db.FightReport.ShowGroupBuffsInPlots

	for i = 1,2 do

		local selector = toolbar:GetNamedChild("BuffSelector" .. i)

		selector.id = i

		local label = selector:GetNamedChild("Label")

		label:SetText(labeltexts[i])

		local colorbox = selector:GetNamedChild("ColorBox")

		local color = PlotColors[i + 5]

		colorbox:SetCenterColor(unpack(color))
		selector.color = color

		local function updateColor(r, g, b, a)

			colorbox:SetCenterColor(r, g, b, a)

			selector.color = {r, g, b, a}

			PlotColors[i + 5] = {r, g, b, a}

			toolbar:GetParent():Update()

		end

		colorbox:SetHandler("OnMouseUp", function(self, button, upInside)

				if upInside then

					local r, g, b, a = unpack(selector.color)
					COLOR_PICKER:Show(updateColor, r, g, b, a)

				end
			end
		)

		local groupSelector = selector:GetNamedChild("GroupSelector")

		groupSelector:SetAlpha(showGroupBuffs and 1 or 0.2)

		if i == 1 then

			groupSelector:SetHidden(db.FightReport.rightpanel ~= "buffsout")

			groupSelector.tooltip = {SI_COMBAT_METRICS_GRAPH_BUFF_GROUP_SELECTOR}

			groupSelector:SetHandler("OnMouseUp", function(self, button, upInside)

					if upInside then

						showGroupBuffs = not showGroupBuffs
						db.FightReport.ShowGroupBuffsInPlots = showGroupBuffs

						groupSelector:SetAlpha(showGroupBuffs and 1 or 0.2)

						toolbar:GetParent():Update()

					end
				end
			)

		else

			groupSelector:SetHidden(true)

		end
	end
end

function CMX.ToggleGraphSize(self)

	enlargedGraph = not enlargedGraph

	local labelText = enlargedGraph and GetString(SI_COMBAT_METRICS_SHRINK) or GetString(SI_COMBAT_METRICS_ENLARGE)

	self:GetNamedChild("Label"):SetText(labelText)

	local graphPanel = self:GetParent():GetParent()
	graphPanel:Update()

end


function CMX.ToggleCursorDisplay(self)

	local enable = not db.FightReport.Cursor

	self:SetAlpha(enable and 1 or 0.3)

	db.FightReport.Cursor = enable

end


function CMX.SkillTooltip_OnMouseEnter(control)

	InitializeTooltip(SkillTooltip, control, TOPLEFT, 0, 5, BOTTOMLEFT)

	local rowControl = control:GetParent()

	local id = rowControl.id
	local delay = rowControl.delay
	local font = string.format("%s|%s|%s", GetString(SI_COMBAT_METRICS_STD_FONT), 16, "soft-shadow-thin")

	SkillTooltip:SetAbilityId(id)
	SkillTooltip:AddVerticalPadding(15)
	SkillTooltip:AddLine(string.format("ID: %d", id), font, .7, .7, .8 , TOP, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER)
	if delay then SkillTooltip:AddLine(string.format("Average delay: %d ms", delay), font, .7, .7, .8 , TOP, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER) end
end

function CMX.SkillTooltip_OnMouseExit(control)

	ClearTooltip(SkillTooltip)

end

function CMX.CPTooltip_OnMouseEnter(control)

	InitializeTooltip(SkillTooltip, control, TOPLEFT, 0, 5, BOTTOMLEFT)

	SkillTooltip:SetChampionSkillAbility(control.discipline, control.skillId, control.points)

end

function CMX.CPTooltip_OnMouseExit(control)

	ClearTooltip(SkillTooltip)

end

function CMX.ItemTooltip_OnMouseEnter(control)

	local itemLink = control.itemLink

	if itemLink == "" or itemLink == nil then return end

	InitializeTooltip(ItemTooltip, control:GetParent(), TOPLEFT, 5, 0, TOPRIGHT)
	ItemTooltip:SetLink(itemLink)

end

function CMX.ItemTooltip_OnMouseExit(control)

	ClearTooltip(ItemTooltip)

end

local equipslots = {

	EQUIP_SLOT_MAIN_HAND,
	EQUIP_SLOT_OFF_HAND,
	EQUIP_SLOT_BACKUP_MAIN,
	EQUIP_SLOT_BACKUP_OFF,
	EQUIP_SLOT_HEAD,
	EQUIP_SLOT_SHOULDERS,
	EQUIP_SLOT_CHEST,
	EQUIP_SLOT_HAND,
	EQUIP_SLOT_WAIST,
	EQUIP_SLOT_LEGS,
	EQUIP_SLOT_FEET,
	EQUIP_SLOT_NECK,
	EQUIP_SLOT_RING1,
	EQUIP_SLOT_RING2,
}

local equipicons = {

	"EsoUI/Art/CharacterWindow/gearslot_mainhand.dds",
	"EsoUI/Art/CharacterWindow/gearslot_offhand.dds",
	"EsoUI/Art/CharacterWindow/gearslot_mainhand.dds",
	"EsoUI/Art/CharacterWindow/gearslot_offhand.dds",
	"EsoUI/Art/CharacterWindow/gearslot_head.dds",
	"EsoUI/Art/CharacterWindow/gearslot_shoulders.dds",
	"EsoUI/Art/CharacterWindow/gearslot_chest.dds",
	"EsoUI/Art/CharacterWindow/gearslot_hands.dds",
	"EsoUI/Art/CharacterWindow/gearslot_belt.dds",
	"EsoUI/Art/CharacterWindow/gearslot_legs.dds",
	"EsoUI/Art/CharacterWindow/gearslot_feet.dds",
	"EsoUI/Art/CharacterWindow/gearslot_neck.dds",
	"EsoUI/Art/CharacterWindow/gearslot_ring.dds",
	"EsoUI/Art/CharacterWindow/gearslot_ring.dds",
}

local armorcolors = {

	[ARMORTYPE_NONE] = {1, 1, 1, 1},
	[ARMORTYPE_HEAVY] = {1, 0.3, 0.3, 1},
	[ARMORTYPE_MEDIUM] = {0.3, 1, 0.3, 1},
	[ARMORTYPE_LIGHT] = {0.3, 0.3, 1, 1},
}

local skillkeys = { "count", "weaponAttackBeforeAvg", "skillBeforeAvg", "weaponAttackNextAvg", "skillNextAvg", "difftimesAvg"}

local function updateLeftInfoPanel(panel)

	if fightData == nil then return end

	local charData = fightData.charData

	if charData == nil then return end

	local skillBars = charData.skillBars

	local data = fightData.calculated

	if data == nil then return end

	local skilldata = data.skills
	local barStatData = data.barStats

	local barkeys = {}

	for bar, data in CMX.spairs(skillBars or {}) do

		table.insert(barkeys, bar)

	end

	local category = db.FightReport.category

	for i = 0, 1 do

		local row = panel:GetNamedChild("AbilityBlock" .. i+1)

		local barkey = barkeys and barkeys[i + barKeyOffset] or i

		local bardata = skillBars and skillBars[barkey] or nil
		local barStats = barStatData and barStatData[barkey] or nil

		local skilltimingbefore = db.FightReport.skilltimingbefore

		local dpsratio, timeratio

		if barStats and type(barStats[category]) == "number" then

			dpsratio = (barStats[category] or 0) / data[category.."Total"]

			local totalTime = (category == "healingIn" or category == "healingOut") and fightData.hpstime or fightData.dpstime or 1

			timeratio = (barStats.totalTime or 0) / totalTime

		end

		local statControl = row:GetNamedChild("Stats")
		local ratioControl = statControl:GetNamedChild("Value1")
		local timeControl = statControl:GetNamedChild("Value2")

		ratioControl:SetText(string.format("%.1f%%", (timeratio or 0) * 100))
		timeControl:SetText(string.format("%.1f%%", (dpsratio or 0) * 100))

		for j = 5, row:GetNumChildren() - 2 do

			local strings = {"-", "-", "-", "-", "-", "-"}

			local control = row:GetChild(j)

			local icon = control:GetNamedChild("Icon"):GetNamedChild("Texture")

			local name = control:GetNamedChild("Label")

			local abilityId = bardata and bardata[j-4] or nil

			control.id = abilityId

			local texture = abilityId and abilityId > 0 and GetFormattedAbilityIcon(abilityId) or "EsoUI/Art/crafting/gamepad/crafting_alchemy_trait_unknown.dds"

			icon:SetTexture(texture)

			local abilityName = abilityId and abilityId > 0 and GetFormattedAbilityName(abilityId) or ""

			name:SetText(abilityName)

			local reducedslot = (barkey - 1) * 10 + j - 4

			local slotdata = skilldata and skilldata[reducedslot] or nil

			if slotdata then

				strings[1] = string.format("%d", slotdata[skillkeys[1]])
				control.delay = slotdata.delayAvg

				for k = 2, #skillkeys do

					local value = slotdata[skillkeys[k]]

					if type(value) == "number" then

						strings[k] = string.format("%.2f", value / 1000)

					end
				end
			end

			local keymod = skilltimingbefore and 0 or 2

			local valuestring = string.format("%s/%s", strings[2+keymod], strings[3+keymod])

			control:GetNamedChild("Value1"):SetText(strings[1])
			control:GetNamedChild("Value2"):SetText(valuestring)
			control:GetNamedChild("Value3"):SetText(strings[6])
		end

		local header3 = row:GetNamedChild("Header"):GetNamedChild("3")

		local HeaderStringKey = skilltimingbefore and 2 or 3

		header3:SetText(GetString("SI_COMBAT_METRICS_SKILLTIME_LABEL", HeaderStringKey))

		header3.tooltip = GetString("SI_COMBAT_METRICS_SKILLTIME_TT", HeaderStringKey)
	end

	local statrow = panel:GetNamedChild("AbilityBlock1"):GetNamedChild("Stats2")
	local statrow2 = panel:GetNamedChild("AbilityBlock2"):GetNamedChild("Stats2")

	local totalSkills = data.totalSkills
	local totalTime = data.totalSkillTime
	local totalWeaponAttacks = data.totalWeaponAttacks
	local totalSkillsFired = data.totalSkillsFired

	local value1string = " -"
	local value2string = " -"

	if totalSkills and totalSkills > 0 and totalTime then

		value1string = (totalTime and totalSkills) and string.format("%.3f s", totalTime / (1000 * totalSkills)) or "-"
		value2string = totalTime and string.format("%.3f s", totalTime / 1000) or "-"

	end

	local value3string = totalWeaponAttacks or " -"
	local value4string = totalSkillsFired or " -"

	statrow:GetNamedChild("Label"):SetText(string.format("%s  %s", GetString(SI_COMBAT_METRICS_AVERAGEC), value1string))
	statrow:GetNamedChild("Label2"):SetText(string.format("%s  %s", GetString(SI_COMBAT_METRICS_TOTALC), value2string))
	statrow2:GetNamedChild("Label"):SetText(string.format("%s  %s", GetString(SI_COMBAT_METRICS_TOTALWA), value3string))
	statrow2:GetNamedChild("Label2"):SetText(string.format("%s  %s", GetString(SI_COMBAT_METRICS_TOTALSKILLS), value4string))
end

function CMX.ToggleSkillTimingData(control)

	db.FightReport.skilltimingbefore = not db.FightReport.skilltimingbefore

	updateLeftInfoPanel(CombatMetrics_Report_InfoPanelLeft)

end

local passiveRequirements = {10, 30, 75, 120}

local function updateRightInfoPanel(panel)

	if fightData == nil then return end

	local CPData = fightData.CP

	if CPData == nil then return end

	for i = 1, 9 do

		local discipline = (7-i)%9+1	-- start with apprentice and then clockwise (seriously, how did they come up with those ids?)

		local signcontrol = panel:GetNamedChild("StarSign"..i)

		local sum = 0

		for id = 1, 4 do

			local cpvalue = CPData[discipline][id]

			local row = signcontrol:GetNamedChild("Row" .. id)

			row.points = cpvalue - GetNumPointsSpentOnChampionSkill(discipline, id)

			local value = row:GetNamedChild("Value")

			sum = sum + cpvalue

			value:SetText(tostring(cpvalue))

		end

		for k = 1, 4 do

			local passiveControl = signcontrol:GetNamedChild("Passive" .. k)

			local show = sum >= passiveRequirements[k]

			local texture = show and "esoui/art/mainmenu/menubar_champion_down.dds" or "esoui/art/mainmenu/menubar_champion_up.dds"
			local alpha = show and 1 or 0.4

			passiveControl:SetTexture(texture)
			passiveControl:SetAlpha(alpha)
		end
	end
end

local function updateBottomInfoPanel(panel)

	if fightData == nil then return end

	local charData = fightData.charData

	if charData == nil then return end

	local equipdata = charData and charData.equip or {}

	local poison1 = equipdata[EQUIP_SLOT_POISON]
	local poison2 = equipdata[EQUIP_SLOT_BACKUP_POISON]

	for i = 1, 14 do

		local equipline = panel:GetNamedChild("EquipLine" .. i)
		local label = equipline:GetNamedChild("ItemLink")
		local icon = equipline:GetNamedChild("Icon")
		local icon2 = equipline:GetNamedChild("Icon2")	-- textures are added twice since icons are so low in contrast
		local trait = equipline:GetNamedChild("Trait")
		local enchant = equipline:GetNamedChild("Enchant")

		local slot = equipslots[i]

		local item = equipdata[slot] or ""
		local texture = equipicons[i]

		local armortype = GetItemLinkArmorType(item)
		local color = item:len() > 0 and armorcolors[armortype] or {0, 0, 0, 1}
		local color2 = item:len() > 0 and {1, 1, 1, 1} or {0.5, 0.5, 0.5, 1}

		label:SetText(item)

		label.itemLink = item == "" and nil or item

		icon:SetTexture(texture)
		icon:SetColor(unpack(color))
		icon:SetBlendMode(TEX_BLEND_MODE_ADD)

		icon2:SetTexture(texture)
		icon2:SetColor(unpack(color2))
		icon2:SetBlendMode(TEX_BLEND_MODE_ADD)

		local traitType, _ = GetItemLinkTraitInfo(item)
		local traitName = traitType > 0 and GetString("SI_ITEMTRAITTYPE", traitType) or ""

		trait:SetText(traitName)

		local enchantstring

		if (slot == EQUIP_SLOT_MAIN_HAND or slot == EQUIP_SLOT_OFF_HAND) and poison1:len() > 0 then

			enchantstring = poison1
			enchant.itemLink = poison1

		elseif (slot == EQUIP_SLOT_BACKUP_MAIN or slot == EQUIP_SLOT_BACKUP_OFF) and poison2:len() > 0 then

			enchantstring = poison2
			enchant.itemLink = poison2

		else

			_, enchantstring = GetItemLinkEnchantInfo(item)
			enchantstring = enchantstring:gsub(GetString(SI_COMBAT_METRICS_ENCHANTMENT_TRIM), "")
			enchant.itemLink = ""

		end

		enchant:SetText(enchantstring)

	end
end

local function updateInfoPanel(panel)

	if panel:IsHidden() then return end

	updateLeftInfoPanel(panel:GetNamedChild("Left"))
	updateRightInfoPanel(panel:GetNamedChild("Right"))
	updateBottomInfoPanel(panel:GetNamedChild("Bottom"))

end

local function updateInfoRowPanel(panel)

	CMX.Print("UI", LOG_LEVEL_DEBUG, "Updating InfoRow")

	local datetimecontrol = panel:GetNamedChild("DateTime")
	local versioncontrol = panel:GetNamedChild("ESOVersion")
	local barcontrol = panel:GetNamedChild("Bar")
	local performancecontrol = panel:GetNamedChild("Performance")

	local data = fightData or {

		["date"] = GetTimeStamp(),
		["time"] = GetTimeString(),
		["ESOversion"] = GetESOVersionString(),
		["account"] = GetDisplayName()

	}

	local date = data.date
	local account = data.account

	local accountstring = account and string.format("%s, ", account) or ""

	local datestring = type(date) == "number" and GetDateStringFromTimestamp(date) or date
	local timestring = string.format("%s%s, %s", accountstring, datestring, data.time)
	local versionstring = string.format("%s / CMX %s", data.ESOversion or "<= 3.2" , CMX.version)

	datetimecontrol:SetText(timestring)
	versioncontrol:SetText(versionstring)

	local hideBar = fightData ~= nil and panel:GetParent():GetNamedChild("_FightList"):IsHidden()

	barcontrol:SetHidden(hideBar)

	if not hideBar then

		performancecontrol:SetHidden(true)

		local usedSpace = db.SVsize/db.maxSVsize
		barcontrol:SetValue(usedSpace)

		local barlabelcontrol = barcontrol:GetNamedChild("Label")
		barlabelcontrol:SetText(string.format("%s: %.1f MB / %d MB (%.1f%%)", GetString(SI_COMBAT_METRICS_SAVED_DATA), db.SVsize, db.maxSVsize, usedSpace * 100))

	else	-- show performance stats

		local data = fightData and fightData.calculated
		local performance = data and data.performance
		local count = performance and performance.count or 0

		if count > 0 then

			performancecontrol:SetHidden(false)

			local fpsString = string.format("FPS: %d  |cAAAAAA(%d - %d)|r ", performance.avgAvg, performance.minAvg, performance.maxAvg)
			local pingString = string.format("Ping: %d ms", performance.avgPing)

			local delayString = data.delayAvg and string.format(" - Desync: %d ms", data.delayAvg) or ""

			local fullString = string.format("%s - %s%s", fpsString, pingString, delayString)

			performancecontrol:SetText(fullString)

		end
	end
end

local function updateFightReport(control, fightId)

	CMX.Print("UI", LOG_LEVEL_DEBUG, "Updating FightReport")

	em:UnregisterForUpdate("CMX_Report_Update_Delay")

	local category = db.FightReport.category or "damageOut"

	-- clear selections of abilities, buffs or units when selecting a different fight to display --

	if fightId == nil or fightId ~= currentFight then

		ClearSelections()

	end

	-- determine which fight to show

	fightId = fightId or currentFight  -- if no fightId was given, use the previous one (this will also select the next fight if one is deleted)

	if fightId == nil or fightId < 0 or CMX.lastfights[fightId] == nil then -- if no valid fight is selected, fall back to the most recent one, if it exists.

		if #CMX.lastfights == 0 then

			fightId = -1 -- there is no fight saved in pos. -1, it will be nil.

		else

			fightId = #CMX.lastfights

		end
	end

	currentFight = fightId

	fightData = CMX.lastfights[fightId] -- this is the fight of interest, can be nil

	if fightData and fightData.calculated == nil and fightData.CalculateFight then -- if it wasn't calculated yet, do so now

		fightData:CalculateFight()
		UpdateReport2()
		return

	elseif fightData and fightData.calculating == true then  -- if it is still calculating wait for it to finish

		em:RegisterForUpdate("CMX_Report_Update_Delay", 500, UpdateReport2)
		return

	end

	-- Generate Filtered Dataset

	selectionData = fightData and CMX.GenerateSelectionStats(fightData, category, selections) or nil

	abilitystats = {fightData, selectionData}

	-- Update Panels

	for i = 2, control:GetNumChildren() do

		local child = control:GetChild(i)

		if child.Update then child:Update() end

	end
end

local function updateFightListPanel(panel, data, issaved)

	local scrollchild = GetControl(panel, "PanelScrollChild")
	local currentanchor = {TOPLEFT, scrollchild, TOPLEFT, 0, 1}

	if #data>0 then

		for id, fight in ipairs(data) do

			local label = string.gsub(fight.fightlabel or "", ".+%:%d%d %- ([A-Z])", "%1")
			local charname = fight.charData and fight.charData.name or fight.char or ""
			local zone = fight.zone or ""
			local subzone = fight.subzone or ""

			local zonestring = subzone ~= "" and string.format("%s, %s", subzone, zone) or nil

			local datestring = type(fight.date) == "number" and GetDateStringFromTimestamp(fight.date) or fight.date
			local timestring = string.format("%s, %s", datestring, fight.time)

			local fightlog = issaved and fight.stringlog or fight.log
			local logState = fightlog and #fightlog>0

			local activetime = 1
			local category = db.FightReport.category

			if category == "healingOut" or category == "healingIn" then

				activetime = zo_roundToNearest(fight.hpstime or 1, 0.1)

			else

				activetime = zo_roundToNearest(fight.dpstime or 1, 0.1)

			end

			local durationstring = string.format("%d:%04.1f", activetime/60, activetime%60)

			local DPSKey = DPSstrings[db.FightReport.category]
			local dps = fight[DPSKey] or 0

			local rowName = scrollchild:GetName() .. "Row" .. id
			local row = _G[rowName] or CreateControlFromVirtual(rowName, scrollchild, "CombatMetrics_FightlistRowTemplate")
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

local function updateFightList(panel)

	CMX.Print("UI", LOG_LEVEL_DEBUG, "Updating FightListPanel")

	if panel:IsHidden() then return end

	local recentPanel = panel:GetNamedChild("Recent")
	local savedPanel = panel:GetNamedChild("Saved")

	ResetBars(recentPanel)
	ResetBars(savedPanel)

	local label

	if category == "healingOut" or category == "healingIn" then

		label = GetString(SI_COMBAT_METRICS_HPS)

	else

		label = GetString(SI_COMBAT_METRICS_DPS)

	end

	GetControl(recentPanel, "HeaderDPS"):SetText(label)
	GetControl(savedPanel, "HeaderDPS"):SetText(label)

	updateFightListPanel(recentPanel, CMX.lastfights, false)
	updateFightListPanel(savedPanel, savedFights, true)
end

local function GetCurrentData()

	local data = CMX.currentdata

	if data.units == nil then

		if #CMX.lastfights == 0 then return end
		data = CMX.lastfights[#CMX.lastfights]

	end

	return data
end

local function GetSingleTargetDamage(data)	-- Gets highest Single Target Damage and counts enemy units.

	local damage, groupDamage, units, unittime, name = 0, 0, 0, 0, ""

	for unitId, unit in pairs(data.units) do

		local totalUnitDamage = unit.damageOutTotal

		if totalUnitDamage > 0 and unit.isFriendly == false then

			if totalUnitDamage > damage then

				name = unit.name
				damage = totalUnitDamage
				groupDamage = unit.groupDamageOut
				unittime = (unit.dpsend or 0) - (unit.dpsstart or 0)

			end
		end
	end

	unittime = unittime > 0 and unittime/1000 or data.dpstime

	return damage, groupDamage, name, unittime
end

local function GetBossTargetDamage(data) -- Gets Damage done to bosses and counts enemy boss units.

	if not data.bossfight then return 0, 0, nil, 0 end

	local totalBossDamage, bossDamage, bossUnits = 0, 0, 0
	local bossName
	local starttime
	local endtime

	for unitId, unit in pairs(data.units) do

		local totalUnitDamage = unit.damageOutTotal

		if (unit.bossId ~= nil and totalUnitDamage>0) then

			totalBossDamage = totalBossDamage + totalUnitDamage
			bossUnits = bossUnits + 1

			starttime = math.min(starttime or unit.dpsstart or 0, unit.dpsstart or 0)
			endtime = math.max(endtime or unit.dpsend or 0, unit.dpsend or 0)

			if totalUnitDamage > bossDamage then

				bossName = unit.name
				bossDamage = totalUnitDamage

			end
		end
	end

	if bossUnits == 0 then return 0, 0, nil, 0 end

	local bossTime = (endtime - starttime)/1000
	bossTime = bossTime > 0 and bossTime or data.dpstime

	return bossUnits, totalBossDamage, bossName, bossTime
end

local function GetSelectionDamage(data, selection)	-- Gets highest Single Target Damage and counts enemy units.

	local units = 0
	local damage = 0
	local starttime
	local endtime
	local bossDamage = 0
	local bossName = ""

	local unitdata = data.units
	selection = selection or unitdata

	for unitId, _ in pairs(selection) do

		local unit = unitdata[unitId]
		local totalUnitDamage = unit.damageOutTotal

		if totalUnitDamage > 0 and unit.isFriendly == false then

			units = units + 1
			damage = damage + totalUnitDamage
			starttime = math.min(starttime or unit.dpsstart or 0, unit.dpsstart or 0)
			endtime = math.max(endtime or unit.dpsend or 0, unit.dpsend or 0)

			if totalUnitDamage > bossDamage then

				bossName = unit.name
				bossDamage = totalUnitDamage

			end

		end
	end

	local damageTime = (endtime - starttime)/1000
	damageTime = damageTime > 0 and damageTime or data.dpstime

	return units, damage, bossName, damageTime
end

local function GetSelectionHeal(data, selection)	-- Gets highest Single Target Damage and counts enemy units.

	local units = 0
	local healing = 0
	local starttime
	local endtime

	local unitdata = data.units
	selection = selection or unitdata
	local calcdata = data.calculated.units

	if not calcdata then return end

	for unitId, _ in pairs(selection) do

		local unit = unitdata[unitId]
		local totalUnitHeal = calcdata[unitId].healingOutTotal

		if totalUnitHeal and unit.isFriendly == true then

			units = units + 1
			healing = healing + totalUnitHeal
			starttime = math.min(starttime or unit.hpsstart or 0, unit.hpsstart or 0)
			endtime = math.max(endtime or unit.hpsend or 0, unit.hpsend or 0)

		end
	end

	local healTime = (endtime - starttime)/1000
	healTime = healTime > 0 and healTime or data.dpstime

	return units, healing, healTime
end

local function GetUnitsByName(data, unitId)	-- Gets all units that share the name with the one provided by unitId

	local selectedUnits = {}

	local unitName = data.units[unitId].name

	for unitId, unit in pairs(data.units) do

		if unit.name == unitName then

			selectedUnits[unitId] = true

		end
	end

	return selectedUnits
end

function CMX.PostBuffUptime(fight, buffname, unitType)

	local data = fight and CMX.lastfights[fight]

	local category = db.FightReport.category or "damageOut"

	if not data then return end

	local timedata = ""

	if data ~= GetCurrentData() then

		local date = data.date

		local datestring = type(date) == "number" and GetDateStringFromTimestamp(date) or date
		timedata = string.format("[%s, %s] ", datestring, data.time)

	end

	local buffDataTable, units = GetBuffDataAndUnits(unitType) -- TODO provide the single unit if units is 1
	local buffData = buffDataTable.buffs[buffname]
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

	local channel = db.autoselectchatchannel == true and (IsUnitGrouped('player') and CHAT_CHANNEL_PARTY or CHAT_CHANNEL_SAY) or nil

	-- Print output to chat

	local outputtext = string.format("%s%s", timedata, output)
	StartChatInput(outputtext, channel)
end

function CMX.PosttoChat(mode, fight, UnitContextMenuUnitId)

	local data = fight and CMX.lastfights[fight] or GetCurrentData()

	if data == nil then return end

	local timedata = ""

	if data ~= GetCurrentData() then

		local date = data.date

		local datestring = type(date) == "number" and GetDateStringFromTimestamp(date) or date
		timedata = string.format("[%s, %s] ", datestring, data.time)

	end

	local output = ""

	local unitSelection = mode == CMX_POSTTOCHAT_MODE_SELECTION and selections.unit["damageOut"]
		or mode == CMX_POSTTOCHAT_MODE_SELECTED_UNIT and {[UnitContextMenuUnitId] = true}
		or mode == CMX_POSTTOCHAT_MODE_SELECTED_UNITNAME and GetUnitsByName(data, UnitContextMenuUnitId)

	local units, damage, name, dpstime = GetSelectionDamage(data, unitSelection)
	local bossUnits, bossDamage, bossName, bossTime = GetBossTargetDamage(data)
	local singleDamage, _, _, singleTime = GetSingleTargetDamage(data)

	dpstime = zo_roundToNearest(dpstime, 0.1)
	singleTime = zo_roundToNearest(singleTime, 0.1)

	name = zo_strformat(SI_UNIT_NAME, (not unitSelection) and bossName or name)

	local bossDamage = data.bossfight and bossDamage or singleDamage
	local bossTime = zo_roundToNearest(data.bossfight and bossTime or singleTime, 0.1)

	local totalDPSString = ZO_CommaDelimitNumber(math.floor(data.DPSOut))
	local totalDamageString = ZO_CommaDelimitNumber(damage)

	if mode == CMX_POSTTOCHAT_MODE_HEALING then

		local hpstime = zo_roundToNearest(data.hpstime, 0.01)
		local timeString = string.format("%d:%04.1f", hpstime/60, hpstime%60)

		local totalHPSString = ZO_CommaDelimitNumber(data.HPSOut)
		local totalHealingString = ZO_CommaDelimitNumber(data.healingOutTotal)

		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTHPS_FORMAT), name, totalHPSString, totalHealingString, timeString)

	elseif mode == CMX_POSTTOCHAT_MODE_SELECTION_HEALING then

		local units, healing, healTime = GetSelectionHeal(data, selections.unit["healingOut"])

		healTime = zo_roundToNearest(healTime, 0.1)

		local timeString = string.format("%d:%04.1f", healTime/60, healTime%60)

		local totalHealingString = ZO_CommaDelimitNumber(healing)
		local totalHPSString = ZO_CommaDelimitNumber(math.floor(healing / healTime))

		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTSELECTIONHPS_FORMAT), name, units, totalHPSString, totalHealingString, timeString)

	elseif units == 1 or mode == CMX_POSTTOCHAT_MODE_SINGLE then

		local damage = mode == CMX_POSTTOCHAT_MODE_SELECTED_UNIT and damage or singleDamage
		local damageTime = mode == CMX_POSTTOCHAT_MODE_SELECTED_UNIT and dpstime or singleTime

		local singleDPSString = ZO_CommaDelimitNumber(math.floor(damage / damageTime))
		local singleDamageString = ZO_CommaDelimitNumber(damage)
		local timeString = string.format("%d:%04.1f", damageTime/60, damageTime%60)

		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTDPS_FORMAT), name, singleDPSString, singleDamageString, timeString)

	elseif bossUnits > 0 and mode == CMX_POSTTOCHAT_MODE_SMART then

		local bosses = bossUnits > 1 and string.format(" (+%d)", (bossUnits-1) )  or ""
		local bossTimeString = string.format("%d:%04.1f", bossTime/60, bossTime%60)

		local bossDPSString = ZO_CommaDelimitNumber(math.floor(bossDamage / bossTime))
		local bossDamageString = ZO_CommaDelimitNumber(bossDamage)

		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTSMARTDPS_FORMAT), name, bosses, bossDPSString, bossDamageString, bossTimeString)

	elseif units > 1 and (mode == CMX_POSTTOCHAT_MODE_MULTI or mode == CMX_POSTTOCHAT_MODE_SMART) then

		local timeString = string.format("%d:%04.1f", dpstime/60, dpstime%60)

		local totalDPSString = ZO_CommaDelimitNumber(math.floor(data.DPSOut))
		local totalDamageString = ZO_CommaDelimitNumber(damage)

		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTMULTIDPS_FORMAT), name, units-1, totalDPSString, totalDamageString, timeString)

	elseif mode == CMX_POSTTOCHAT_MODE_SINGLEANDMULTI then

		local bossString = bossUnits > 1 and string.format("%s (+%d)", GetString(SI_COMBAT_METRICS_BOSS_DPS), bossUnits-1) or bossUnits == 1 and GetString(SI_COMBAT_METRICS_BOSS_DPS) or GetString(SI_COMBAT_METRICS_DPS)
		local timeString = string.format("%d:%04.1f", dpstime/60, dpstime%60)
		local bossTimeString = string.format("%d:%04.1f", bossTime/60, bossTime%60)

		local bossDPSString = ZO_CommaDelimitNumber(math.floor(bossDamage / bossTime))
		local bossDamageString = ZO_CommaDelimitNumber(bossDamage)

		local totalDPSString = ZO_CommaDelimitNumber(math.floor(data.DPSOut))
		local totalDamageString = ZO_CommaDelimitNumber(damage)

		local stringA = zo_strformat(GetString(SI_COMBAT_METRICS_POSTALLDPS_FORMAT_A), name, units-1, totalDPSString, totalDamageString, timeString)
		local stringB = zo_strformat(GetString(SI_COMBAT_METRICS_POSTALLDPS_FORMAT_B), bossString, bossDPSString, bossDamageString, bossTimeString)

		output = string.format("%s, %s", stringA, stringB)

	elseif mode == CMX_POSTTOCHAT_MODE_SELECTION or mode == CMX_POSTTOCHAT_MODE_SELECTED_UNITNAME then

		if not unitSelection then return end

		local extraUnits = units > 1 and mode == CMX_POSTTOCHAT_MODE_SELECTED_UNITNAME and string.format(" (x%d)", units )
			or units > 1 and string.format(" (+%d)", (units-1) )
			or ""

		local DPSString = ZO_CommaDelimitNumber(math.floor(damage / dpstime))
		local DamageString = ZO_CommaDelimitNumber(damage)
		local timeString = string.format("%d:%04.1f", dpstime/60, dpstime%60)

		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTSELECTIONDPS_FORMAT), name, extraUnits, DPSString, DamageString, timeString)

	end

	-- Determine appropriate channel

	local channel = db.autoselectchatchannel == false and "" or IsUnitGrouped('player') and "/p " or "/say "

	-- Print output to chat

	local outputtext = string.format("%s%s", timedata, output)

	CHAT_SYSTEM.textEntry:SetText( channel .. outputtext )
	CHAT_SYSTEM:Maximize()
	CHAT_SYSTEM.textEntry:Open()
	CHAT_SYSTEM.textEntry:FadeIn()
end

local function maxStat()

	local _, magicka = GetUnitPower("player", POWERTYPE_MAGICKA )
	local _, stamina = GetUnitPower("player", POWERTYPE_STAMINA )
	local _, health = GetUnitPower("player", POWERTYPE_HEALTH )

	local maxPower = "Magicka"

	if stamina > magicka then maxPower = "Stamina" end
	if health > magicka and health > stamina then maxPower = "Health" end

	return maxPower

end

-- Update the mini DPS meter

local function updateLiveReport(self, data)

	local livereport = self

	local DPSOut = data.DPSOut
	local DPSIn = data.DPSIn
	local HPSOut = data.HPSOut
	local HPSAOut = data.HPSAOut
	local HPSIn = data.HPSIn
	local dpstime = data.dpstime
	local hpstime = data.hpstime
	local groupDPSOut = data.groupDPSOut
	local groupDPSIn = data.groupDPSIn
	local groupHPSOut = data.groupHPSOut

	-- Bail out if there is no damage to report
	if (DPSOut == 0 and HPSOut == 0 and DPSIn == 0) or livereport:IsHidden() then return end

	local SDPS = 0
	local groupSDPS = 0

	if db.liveReport.damageOutSingle then

		local singleTargetDamage, singleTargetDamageGroup, _, damageTime = GetSingleTargetDamage(data)

		SDPS = zo_round(singleTargetDamage / damageTime)
		groupSDPS = zo_round(singleTargetDamageGroup / damageTime)

	end

	local DPSString
	local HPSString
	local DPSInString
	local SDPSString
	local maxtime = zo_roundToNearest(math.max(dpstime, hpstime), 0.1)
	local timeString = string.format("%d:%04.1f", maxtime/60, maxtime%60)

	-- maybe add data from group
	if db.recordgrp == true and (groupDPSOut > 0 or groupDPSIn > 0 or groupHPSOut > 0) then

		local dpsratio, hpsratio, idpsratio, sdpsratio = 0, 0, 0, 0

		if groupDPSOut > 0  then dpsratio  = (math.floor(DPSOut / groupDPSOut * 1000) / 10) end
		if groupDPSIn > 0 then idpsratio = (math.floor(DPSIn / groupDPSIn * 1000) / 10) end
		if groupSDPS > 0  then sdpsratio  = (math.floor(SDPS / groupSDPS * 1000) / 10) end
		if groupHPSOut > 0 then hpsratio  = (math.floor(HPSOut / groupHPSOut * 1000) / 10) end

		DPSString = zo_strformat(GetString(SI_COMBAT_METRICS_SHOW_XPS), DPSOut, groupDPSOut, dpsratio)
		DPSInString = zo_strformat(GetString(SI_COMBAT_METRICS_SHOW_XPS), DPSIn, groupDPSIn, idpsratio)
		HPSString = zo_strformat(GetString(SI_COMBAT_METRICS_SHOW_XPS), HPSOut, groupHPSOut, hpsratio)
		SDPSString = zo_strformat(GetString(SI_COMBAT_METRICS_SHOW_XPS), SDPS, groupSDPS, sdpsratio)

	else

		DPSString  = DPSOut
		DPSInString = DPSIn
		HPSString  = HPSOut
		SDPSString = SDPS

	end

	-- Update the values

	livereport:GetNamedChild("DamageOutSingle"):GetNamedChild("Label"):SetText( SDPSString )
	livereport:GetNamedChild("DamageOut"):GetNamedChild("Label"):SetText( DPSString )
	livereport:GetNamedChild("HealOut"):GetNamedChild("Label"):SetText( HPSString )
	livereport:GetNamedChild("HealOutAbsolute"):GetNamedChild("Label"):SetText( HPSAOut )
	livereport:GetNamedChild("DamageIn"):GetNamedChild("Label"):SetText( DPSInString )
	livereport:GetNamedChild("HealIn"):GetNamedChild("Label"):SetText( HPSIn )
	livereport:GetNamedChild("Time"):GetNamedChild("Label"):SetText( timeString )

end

local function toggleFightReport()

	if not SCENE_MANAGER:IsShowing("CMX_REPORT_SCENE") then

		SCENE_MANAGER:Toggle("CMX_REPORT_SCENE")

		CombatMetrics_Report:Update(#CMX.lastfights>0 and #CMX.lastfights or nil)

		SCENE_MANAGER:SetInUIMode(true)

		if #CMX.lastfights>0 and not CMX.inCombat and db.autoscreenshot and (db.autoscreenshotmintime ==0 or CMX.lastfights[#CMX.lastfights]["combattime"]>db.autoscreenshotmintime) then zo_callLater(TakeScreenshot, 400) end

	else

		SCENE_MANAGER:Toggle("CMX_REPORT_SCENE")

	end
end

function CMX.GetCMXData(dataType)	-- for external access to fightData

	local data = {}

    if dataType == "selectionData" then

		ZO_DeepTableCopy(selectionData, data)

    elseif dataType == "fightData" then

		ZO_DeepTableCopy(fightData, data)

    else

        data = nil

    end

	return data
end

local lastResize

function CMX.Resizing(control, resizing)

	if control:IsHidden() then return end

	if resizing then

		control:SetEdgeColor(1,1,1,1)
		control:SetCenterColor(1,1,1,.2)

	else

		control:SetEdgeColor(1,1,1,0)
		control:SetCenterColor(1,1,1,0)

		local scale, newpos = unpack(lastResize)
		local parent = control:GetParent()

		db[parent:GetName()] = newpos

		parent:ClearAnchors()
		parent:SetAnchor(CENTER, nil , TOPLEFT, newpos.x, newpos.y)
		parent:Resize(scale)
		parent:Update()

	end
end

function CMX.NewSize(control, newLeft, newTop, newRight, newBottom, oldLeft, oldTop, oldRight, oldBottom)

	if control.sizes == nil or control:IsHidden() then return end

	TEST = control

	local baseWidth, baseHeight = unpack(control.sizes)

	local newHeight = newBottom - newTop
	local newWidth = newRight - newLeft

	local oldHeight = oldBottom - oldTop
	local oldWidth = oldRight - oldLeft

	local heightChange = (newHeight-oldHeight)/oldHeight
	local widthChange = (newWidth-oldWidth)/oldWidth

	local newscale

	if math.abs(heightChange) > math.abs(widthChange) then

		newscale = newHeight / baseHeight
		newWidth = baseWidth * newscale

		control:SetWidth(newWidth)

	else

		newscale = newWidth / baseWidth
		newHeight = baseHeight * newscale

		control:SetHeight(newHeight)

	end

	newscale = zo_roundToNearest(newscale, 0.01)

	local centerX, centerY = control:GetCenter()
	local newpos = { x = centerX, y = centerY}

	lastResize = {newscale, newpos}
end

local scene = ZO_Scene:New("CMX_REPORT_SCENE", SCENE_MANAGER)

local function initFightReport()

	local fightReport = CombatMetrics_Report

	storeOrigLayout(fightReport)

	local pos = db[fightReport:GetName()]

	fightReport:ClearAnchors()
	fightReport:SetAnchor(CENTER, nil , TOPLEFT, pos.x, pos.y)

	local fragment = ZO_HUDFadeSceneFragment:New(fightReport)

	scene:AddFragment(fragment)

	local function resize(control, scale)

		db.FightReport.scale = scale

		if control.sizes == nil and control.anchors == nil then return end

		local width, height = unpack(control.sizes)

		if width then control:SetWidth(width*scale) end
		if height then control:SetHeight(height*scale) end

		local anchors = {}
		local oldanchors = control.anchors

		if oldanchors then ZO_DeepTableCopy(control.anchors, anchors) end

		local anchor1 = anchors[1]
		local anchor2 = anchors[2]

		if anchor1 or anchor2 then control:ClearAnchors() end

		if anchor1 ~= nil then

			anchor1[4] = anchor1[4] * scale
			anchor1[5] = anchor1[5] * scale

			control:SetAnchor(unpack(anchor1))

		end

		if anchor2 ~= nil then

			anchor2[4] = anchor2[4] * scale
			anchor2[5] = anchor2[5] * scale

			control:SetAnchor(unpack(anchor2))

		end

		local fontcontrol = control:GetNamedChild("Font")

		if fontcontrol ~= nil then

			local font, size, style = unpack(fontcontrol.font)

			if size then size = tonumber(size) * (scale + 0.2)/1.2 end			-- Don't Scale fonts as much

			control:SetFont(string.format("%s|%s|%s", font, size, style))

		end

		for i = 1, control:GetNumChildren() do

			local child = control:GetChild(i)
			if child then resize(child, scale) end

		end
	end

	fightReport.Resize = resize

	-- assign update functions for panels

	fightReport.Update = updateFightReport
	fightReport.Toggle = toggleFightReport

	local titlePanel = fightReport:GetNamedChild("_Title")
	titlePanel.Update = updateTitlePanel

	local mainPanel = fightReport:GetNamedChild("_MainPanel")
	mainPanel.Update = updateMainPanel

		local fightStatsPanel = mainPanel:GetNamedChild("FightStats")
		fightStatsPanel.Update = updateFightStatsPanel
		mainPanel.active = fightStatsPanel

			local fightStatsPanelLeft = fightStatsPanel:GetNamedChild("Left")
			fightStatsPanelLeft.Update = updateFightStatsPanelLeft

			local fightStatsPanelRight = fightStatsPanel:GetNamedChild("Right")
			fightStatsPanelRight.Update = updateFightStatsPanelRight

			local fightStatsButton = fightStatsPanelRight:GetNamedChild("SelectRow"):GetNamedChild(maxStat())
			CMX.UpdateAttackStatsSelector(fightStatsButton)

		local combatLogPanel = mainPanel:GetNamedChild("CombatLog")
		combatLogPanel.Update = updateCombatLog

			local combatLogPageButtonRow = GetControl(combatLogPanel, "HeaderPageButtonRow")
			combatLogPageButtonRow.Update = updateCLPageButtons

			local combatLogFilterButtonRow = GetControl(combatLogPanel, "HeaderFilterButtonRow")
			initCLButtonRow(combatLogFilterButtonRow)

		local graphPanel = mainPanel:GetNamedChild("Graph")
		graphPanel.Update = updateGraphPanel

			local plotToolBar = graphPanel:GetNamedChild("Toolbar")
			initPlotToolbar(plotToolBar)

			local plotWindow = graphPanel:GetNamedChild("PlotWindow")
			initPlotWindow(plotWindow)

	local infoPanel = fightReport:GetNamedChild("_InfoPanel")
	infoPanel.Update = updateInfoPanel

	local rightPanel = fightReport:GetNamedChild("_RightPanel")
	rightPanel.Update = updateRightPanel

		local buffPanel = rightPanel:GetNamedChild("BuffList")
		buffPanel.Update = updateBuffPanel

		local buffbutton = rightPanel:GetNamedChild("Selector"):GetNamedChild("BuffsIn")
		CMX.SelectRightPanel(buffbutton)

		local resourcePanel = rightPanel:GetNamedChild("ResourceList")
		resourcePanel.Update = updateResourcePanel

	local unitPanel = fightReport:GetNamedChild("_UnitPanel")
	unitPanel.Update = updateUnitPanel

	local abilityPanel = fightReport:GetNamedChild("_AbilityPanel")
	abilityPanel.Update = updateAbilityPanel

	local infoRowPanel = fightReport:GetNamedChild("_InfoRow")
	infoRowPanel.Update = updateInfoRowPanel

	local fightListPanel = fightReport:GetNamedChild("_FightList")
	fightListPanel.Update = updateFightList

	-- setup buttons:

	local selectorButtons = fightReport:GetNamedChild("_SelectorRow")
	selectorButtons.Update = updateSelectorButtons
	initSelectorButtons(selectorButtons)

	fightReport:Resize(db.FightReport.scale)

	local left = selectorButtons:GetLeft()

	if left < 0 then

		fightReport:ClearAnchors()
		fightReport:SetAnchor(CENTER, nil , TOPLEFT, pos.x - left, pos.y)

	end
end

local function initLiveReport()

	local liveReport = CombatMetrics_LiveReport

	storeOrigLayout(liveReport)

	local pos = db[liveReport:GetName()]

	liveReport:ClearAnchors()
	liveReport:SetAnchor(CENTER, nil , TOPLEFT, pos.x, pos.y)

	local fragment = ZO_HUDFadeSceneFragment:New(liveReport)

	function liveReport.Toggle(liveReport, value)

		if value == nil then value = liveReport:IsHidden() end

		liveReport:SetHidden(not value)

		if value == true then

			SCENE_MANAGER:GetScene("hud"):AddFragment( fragment )
			SCENE_MANAGER:GetScene("hudui"):AddFragment( fragment )
			SCENE_MANAGER:GetScene("siegeBar"):AddFragment( fragment )

		else

			SCENE_MANAGER:GetScene("hud"):RemoveFragment( fragment )
			SCENE_MANAGER:GetScene("hudui"):RemoveFragment( fragment )
			SCENE_MANAGER:GetScene("siegeBar"):RemoveFragment( fragment )

		end

	end

	local setLR = db.liveReport
	local bg = liveReport:GetNamedChild("BG")

	function liveReport.Refresh(liveReport)

		local anchors = (setLR.layout == "Horizontal" and {

			{TOPLEFT, TOPLEFT, 0, 0, liveReport},
			{LEFT, RIGHT, 0, 0},
			{LEFT, RIGHT, 0, 0}

		}) or (setLR.layout == "Vertical" and {

			{TOPLEFT, TOPLEFT, 0, 0, liveReport},
			{TOPLEFT, BOTTOMLEFT, 0, 0},
			{LEFT, RIGHT, 0, 0}

		}) or { -- layout = compact

			{TOPLEFT, TOPLEFT, 0, 0, liveReport},
			{LEFT, RIGHT, 0, 0},
			{TOPLEFT, BOTTOMLEFT, 0, 0},
		}

		local liveReport = liveReport

		local scale = setLR.scale

		local last = liveReport

		liveReport:SetDimensions(1, 1)

		local totalBlocks = 0

		for i = 2, liveReport:GetNumChildren() do

			local child = liveReport:GetChild(i)
			local name = string.gsub(string.gsub(child:GetName(), liveReport:GetName(), ""), "^%u", string.lower) -- difference in names is the child name e.g. "DamageOut". Outer gsub changes first letter to lowercase to match the settings, e.g. "damageOut".

			local shown = setLR[name]

			if shown == true then

				local addspace = child.blocksize

				totalBlocks = totalBlocks + addspace

			end

		end

		local halfway = (setLR.layout == "Compact" and (math.ceil(totalBlocks / 2) + 1)) or nil

		local blocks = 0

		local firstBlock = nil	-- to anchor 2nd row to

		for i = 3, liveReport:GetNumChildren() do

			local child = liveReport:GetChild(i)
			local name = string.gsub(string.gsub(child:GetName(), liveReport:GetName(), ""), "^%u", string.lower) -- difference in names is the child name e.g. "DamageOut". Outer gsub changes first letter to lowercase to match the settings, e.g. "damageOut".

			local shown = setLR[name]
			child:SetHidden(not shown)

			if shown then

				local addspace = child.blocksize

				local isnotfull = ( math.ceil(blocks) - math.ceil(blocks + addspace)) == 0

				blocks = blocks + addspace

				local is

				if firstBlock == nil then firstBlock = child end

				local anchorIndex = (blocks == 1 and 1) or ((blocks == halfway or (isnotfull and setLR.layout ~= "Compact")) and 3) or 2

				local anchor = anchors[anchorIndex]

				anchor[5] = (not isnotfull) and anchorIndex == 3 and firstBlock or last

				child:ClearAnchors()

				local width, height = unpack(child.sizes)

				child:SetDimensions(width*scale, height*scale)
				child:SetAnchor(anchor[1], anchor[5], anchor[2], anchor[3]*scale, anchor[4]*scale)

				last = child

				-- set label alignments

				local label = child:GetNamedChild("Label")
				local alignment = setLR.alignmentleft and TEXT_ALIGN_LEFT or TEXT_ALIGN_RIGHT

				label:SetHorizontalAlignment(alignment)

			end
		end

		zo_callLater(function() bg:SetDimensions(liveReport:GetWidth(), liveReport:GetHeight()) end, 1)

	end

	local function resize(control, scale)

		db.liveReport.scale = scale

		local width, height = unpack(control.sizes)

		if width then control:SetWidth(width*scale) end
		if height then control:SetHeight(height*scale) end

		local fontcontrol = control:GetNamedChild("Font")

		if fontcontrol ~= nil then

			local font, size, style = unpack(fontcontrol.font)

			if size then size = tonumber(size) * (scale + 0.1)/1.2 end			-- Don't Scale fonts as much

			control:SetFont(string.format("%s|%s|%s", font, size, style))

		end

		for i = 1, control:GetNumChildren() do

			local child = control:GetChild(i)
			if child then resize(child, scale) end

		end
	end

	function liveReport.Resize(liveReport, scale)

		resize(liveReport, scale)
		liveReport:Refresh()

	end

	liveReport.Update = updateLiveReport

	liveReport:Toggle(setLR.enabled)
	liveReport:Resize(setLR.scale)
	liveReport:SetMovable(not setLR.locked)

	bg:SetAlpha(setLR.bgalpha/100)

end

function CMX.InitializeUI()

	db = CMX.db

	SVHandler = CombatMetricsFightData
	savedFights = SVHandler.GetFights()

	local _, size = checkSaveLimit()
	db.SVsize = size

	selections = {
		["ability"]		= {},
		["unit"] 		= {},
		["buff"] 		= {},
		["resource"] 	= {},
	}

	lastSelections = {
		["ability"] 	= {},
		["unit"] 		= {},
		["buff"] 		= {},
		["resource"] 	= {},
	}

	currentFight = nil
	currentCLPage = 1

	initFightReport()
	initLiveReport()

	local settingsbutton = CombatMetrics_Report_SelectorRowSettingsButton

	if LibFeedback then

		local data = CMX.GetFeedBackData(settingsbutton)

		local button, feedbackWindow = LibFeedback:initializeFeedbackWindow(unpack(data))
		button:SetHidden(true)

		function ToggleFeedback()

			feedbackWindow:ToggleHidden()

		end
	end
end