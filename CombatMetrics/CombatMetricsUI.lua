local em = GetEventManager()
local wm = GetWindowManager()
local dx = 1/GetSetting(SETTING_TYPE_UI, UI_SETTING_CUSTOM_SCALE)
COMBAT_METRICS_LINE_SIZE = tostring(dx)
local fontsize = 14
local currentFight
local abilitystats
local abilitystatsversion = 2
local fightData, selectionData
local currentCLPage
local selections, lastSelections
local savedFights
local SVHandler

local CMX = CMX
if CMX == nil then CMX = {} end
local _
local db

function CMX.GetAbilityStats()
	return abilitystats, abilitystatsversion
end
 
local function GetFormatedAbilityName(id)

	local name = CMX.CustomAbilityName[id] or zo_strformat(SI_ABILITY_NAME, GetAbilityName(id))
	
	return name
	
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

	if show then panel:Update() end
	
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

	local size, constants = SVHandler.Check(fight)
	
	CMX.Print("save", "SV Size: %.3f MB, %.1f%%", size, size*100/db.maxSVsize)
	CMX.Print("save", "SV Keys: %d, %.1f%%", constants, constants/1310.71) --131071 is the maximum possible number of constants

	local isvalid = (size < db.maxSVsize and constants < 131071)
	
	return isvalid, size, constants
	
end

function NavButtonFunctions.save(control, _, _, _, _, shiftkey )

	if control:GetState() == BSTATE_DISABLED then
	
		return
		
	else 
	
		local lastsaved = savedFights[#savedFights]
	
		if lastsaved ~= nil and lastsaved.date == fightData.date then return end --bail out if fight is already saved
		
		SVHandler.Save(fightData, shiftkey)
		
		if checkSaveLimit() then 
			
			CombatMetrics_Report:Update()
			
		else 
			
			local removed = table.remove(savedFights)
			local size, constants = SVHandler.Check(removed)
			
			errorstring = zo_strformat(SI_COMBAT_METRICS_STORAGE_FULL, size, constants)
			assert(false, errorstring) 
			
		end
	end
end

function NavButtonFunctions.delete(control)

	if control:GetState() == BSTATE_DISABLED then 
	
		return 
		
	else 
	
		table.remove(CMX.lastfights, currentFight)
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
		local a = child==button and 1 or .2
		
		child:SetColor(r, g, b, a)
	
	end
	
	db.FightReport.category = button.category
	
	if CMX and CMX.init then CombatMetrics_Report:Update(currentFight) end
	
end

local function selectMainPanel(button)

	local selectControl = button:GetParent()

	for i=5, 8 do
		
		local child = selectControl:GetChild(i)
		
		local a = child == button and 1 or .2
		
		child:SetColor(1, 1, 1, a)
	
	end
	
	local mainpanel = CombatMetrics_Report_MainPanel
	
	local selected = mainpanel:GetNamedChild(button.category) -- Panel Content to show
	mainpanel.active = selected
	
	for i = 2, mainpanel:GetNumChildren() do
	
		local child = mainpanel:GetChild(i)
		
		child:SetHidden(child ~= selected) -- Hide all other panels except the selected panel

	end
	
	selectControl:GetParent():GetNamedChild("_MainPanel"):Update()
	
end
	
local function initSelectorButtons(rowControl) 

	for i=1, 8 do
	
		local child = rowControl:GetChild(i)
		
		if child and i<=4 then 
			
			child:SetHandler( "OnMouseUp", selectCategory) 
			if child.category == db.FightReport.category then selectCategory(child) end
			
		elseif child and i>4 then 
		
			child:SetHandler( "OnMouseUp", selectMainPanel)
			
		end
	end
end 

local function CLNavButtonFunction(self)
	
	currentCLPage = (currentCLPage - 1 + self.func)
	self:GetParent():GetParent():GetParent():Update()
	
end 

function CMX.InitCLNavButtonRow(rowControl)

	for i=1, rowControl:GetNumChildren() do
	
		local button = rowControl:GetChild(i)
		
		if button.texture then button:GetNamedChild("Icon"):SetTexture(button.texture) end
		
		if button.label then button:GetNamedChild("Label"):SetText(button.label) end
		
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

local function initCLButtonRow() 

	local rowControl = GetControl(CombatMetrics_Report, "_MainPanelCombatLogHeaderFilterButtonRow")

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

	for _, powertype in pairs{"Magicka", "Stamina", "Health"} do
	
		local control = selector:GetNamedChild(powertype)
		
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
	
	local isLoaded, loadId = searchtable(lastfights, "date", savedFights[id]["date"])	-- returns false if nothing is found else it returns the id
	if isLoaded then isLoaded = lastfights[loadId]["time"] == savedFights[id]["time"] end					-- ensures old fights load correctly
	
	if issaved and isLoaded == false then
		
		table.insert(lastfights, SVHandler.Load(id))
		CombatMetrics_Report:Update(#CMX.lastfights)
		
	else
		
		CombatMetrics_Report:Update((issaved and loadId or id))
	
	end
	
	local category = db.FightReport.category
	
	selections["ability"][category] = nil
	selections["unit"][category] = nil
	selections["buff"]["buff"] = nil	
	selections["resource"]["resource"] = nil	
	
	toggleFightList()
	
end

function CMX.DeleteItem(control)

	local row = control:GetParent():GetParent()
	local issaved = row.issaved
	local id = row.id

	if issaved then
	
		table.remove(savedFights, id)
		
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

local function slashCommandFunction(extra)
	
	if 		extra == "reset" 	then CMX.ResetFight()
	elseif 	extra == "dps" 		then CMX.PosttoChat("SmartDPS")
	elseif 	extra == "totdps" 	then CMX.PosttoChat("DPSM")
	elseif 	extra == "alldps" 	then CMX.PosttoChat("DPST")
	elseif 	extra == "hps" 		then CMX.PosttoChat("HPS")
	else 						CombatMetrics_Report:Toggle()
	end
	
end

SLASH_COMMANDS["/cmx"] = slashCommandFunction

do	-- Handling Favourite Buffs

	local favs
	local buffname

	local function addFavouriteBuff()
		
		if buffname then favs[buffname] = true end
		CombatMetrics_Report:Update()
		
	end

	local function removeFavouriteBuff()
		
		if buffname then favs[buffname] = nil end
		CombatMetrics_Report:Update()
		
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
		ShowMenu(bufflistitem)
		
	end
end

do

	local function toggleshowids()
	
		db.debuginfo.ids = not db.debuginfo.ids
		CombatMetrics_Report:Update()
		
	end

	function CMX.SettingsContextMenu( settingsbutton, upInside )

		if not upInside then return end
		
		local func = toggleshowids
		local stringid = db.debuginfo.ids and SI_COMBAT_METRICS_HIDEIDS or SI_COMBAT_METRICS_SHOWIDS
		local text = GetString(stringid)
		
		ClearMenu()
		AddCustomMenuItem(text, func)
		ShowMenu(settingsbutton)
		

	end
end

--function CMX.AddSelection( selecttype, id, dataId, shiftkey, controlkey, button )  -- IsShiftKeyDown() IsControlKeyDown() IsCommandKeyDown()

function CMX.AddSelection( self, button, upInside, ctrlkey, alt, shiftkey )
	
	local id = self.id
	local dataId = self.dataId
	local selecttype = self.type
	
	if button ~= MOUSE_BUTTON_INDEX_LEFT and button ~= MOUSE_BUTTON_INDEX_RIGHT then return end
	
	local category = selecttype == "buff" and "buff" or selecttype == "resource" and "resource" or db.FightReport.category
	
	local sel = selections[selecttype][category] -- can be nil so this is not always a reference
	local lastsel = lastSelections[selecttype][category]
	local bars = self.panel.bars
	
	
	if button == MOUSE_BUTTON_INDEX_RIGHT then
	
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

-- Update the mini DPS meter

local function updateLiveReport(self, dps, hps, idps, ihps, dpstime, hpstime, gdps, igdps, ghps)

	local livereport = self

	-- Bail out if there is no damage to report
	if (dps == 0 and hps == 0 and idps == 0) or livereport:IsHidden() then return end

	local showdps
	local showhps
	local showidps
	local maxtime = math.max(dpstime, hpstime)
	local showtime = string.format("%d:%04.1f", maxtime/60, maxtime%60)
		
	-- maybe add data from group
	if db.recordgrp == true and ((gdps+igdps+ghps)>0) then
		local dpsratio, hpsratio, idpsratio = 0, 0, 0
		if gdps>0  then dpsratio  = (math.floor(dps/gdps*1000)/10) end 
		if igdps>0 then idpsratio = (math.floor(idps/igdps*1000)/10) end 
		if ghps>0  then hpsratio  = (math.floor(hps/ghps*1000)/10) end

		showdps = zo_strformat(GetString(SI_COMBAT_METRICS_SHOW_XPS), dps, gdps, dpsratio)
		showhps = zo_strformat(GetString(SI_COMBAT_METRICS_SHOW_XPS), hps, ghps, hpsratio)
		showidps = zo_strformat(GetString(SI_COMBAT_METRICS_SHOW_XPS), idps, gidps, idpsratio)
	else
		showdps  = dps 
		showhps  = hps
		showidps = idps
	end
	
	-- Update the values
	
	livereport:GetNamedChild("DamageOut"):GetNamedChild("Label"):SetText( showdps )
	livereport:GetNamedChild("HealOut"):GetNamedChild("Label"):SetText( showhps )
	livereport:GetNamedChild("DamageIn"):GetNamedChild("Label"):SetText( showidps )
	livereport:GetNamedChild("HealIn"):GetNamedChild("Label"):SetText( ihps )
	livereport:GetNamedChild("Time"):GetNamedChild("Label"):SetText( showtime )
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

function searchtable(t, field, value)

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

local function UpdateReport2()
	CombatMetrics_Report:Update()
end

local function updateTitlePanel(panel)

	CMX.Print("dev", "Updating TitlePanel")

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

	CMX.Print("dev", "Updating FightStatsPanelLeft")

	local data = fightData and fightData.calculated or {}
	local category = db.FightReport.category
	
	local selectedabilities = selections["ability"][category]
	local selectedunits = selections["unit"][category]
	
	local noselection = selectedunits == nil and selectedabilities == nil
	
	local header2 = panel:GetNamedChild("StatHeaderLabel2")
	local headerstring = noselection and SI_COMBAT_METRICS_GROUP or SI_COMBAT_METRICS_SELECTION
	
	header2:SetText(GetString(headerstring))
	
	local label1, label2, label3, rowlist
	local activetime
	
	if category == "healingOut" or category == "healingIn" then
	
		label1 = GetString(SI_COMBAT_METRICS_HPS)
		label2 = GetString(SI_COMBAT_METRICS_HEALING)
		label3 = GetString(SI_COMBAT_METRICS_HEALS)
		
		rowlist = {Total = true, Normal = true, Critical = true, Blocked = false, Shielded = false}
		
		activetime = string.format("%.2f", fightData and fightData.hpstime or 1)
		
	else	
	
		label1 = GetString(SI_COMBAT_METRICS_DPS)
		label2 = GetString(SI_COMBAT_METRICS_DAMAGE)
		label3 = GetString(SI_COMBAT_METRICS_HIT)
		
		rowlist = {Total = true, Normal = true, Critical = true, Blocked = true, Shielded = true}
		
		activetime = string.format("%.2f", fightData and fightData.dpstime or 1)
		
	end
	
	local dpsRow = panel:GetNamedChild("StatRowAPS")
	
	dpsRow:GetNamedChild("Label"):SetText(label1) 	-- DPS or HPS
	panel:GetNamedChild("StatTitleAmount"):GetNamedChild("Label"):SetText(label2) 	-- Damage or Healing
	panel:GetNamedChild("StatTitleCount"):GetNamedChild("Label"):SetText(label3) 	-- Hits or Heals
	
	local combattime = string.format("%.2f", fightData and fightData.combattime or 0)
	
	panel:GetNamedChild("ActiveTimeValue"):SetText(activetime)
	panel:GetNamedChild("CombatTimeValue"):SetText(combattime)
	
	local key = DPSstrings[category]
	
	local aps1 = data[key] or 0
	local aps2, apsratio
	
	if not noselection then 
	
		aps2 = selectionData and selectionData[key] or 0
		apsratio = (aps1 == 0 and 0) or aps2/aps1*100
	
	else
	
		aps2 = data["group"..zo_strformat("<<C:1>>", key)] or 0
		apsratio = (aps2 == 0 and 0) or aps1/aps2*100
	
	end
	
	dpsRow:GetNamedChild("Value"):SetText(string.format("%.0f", aps1))
	dpsRow:GetNamedChild("Value2"):SetText(string.format("%.0f", aps2))
	dpsRow:GetNamedChild("Value3"):SetText(string.format("%.1f%%", apsratio))
	
	for k, v in pairs(rowlist) do
	
		local rowcontrol1 = panel:GetNamedChild("StatRowAmount"..k)
		local rowcontrol2 = panel:GetNamedChild("StatRowCount"..k)
		
		local amountlabel    = rowcontrol1:GetNamedChild("Label")
		local amountcontrol1 = rowcontrol1:GetNamedChild("Value")
		local amountcontrol2 = rowcontrol1:GetNamedChild("Value2")
		local amountcontrol3 = rowcontrol1:GetNamedChild("Value3")
		
		local countlabel    = rowcontrol2:GetNamedChild("Label")
		local countcontrol1 = rowcontrol2:GetNamedChild("Value")
		local countcontrol2 = rowcontrol2:GetNamedChild("Value2")
		local countcontrol3 = rowcontrol2:GetNamedChild("Value3")
		
		local hide2 = not v
		local hide3 = not v
		
		if v == true then 
		
			local amountkey = category..k
			local countkey = CountStrings[category]..k
			
			local amount1 = data[amountkey] or 0
			local amount2 = 0
			local amount3 = data[category.."Total"] or 0
			local amountratio = 0
			
			local count1 = data[countkey] or 0
			local count2 = 0
			local count3 = data[CountStrings[category].."Total"] or 0
			local countratio = 0
			
			if k == "Total" and noselection then 
			
				amount2 = data["group"..zo_strformat("<<C:1>>", category)] or 0  -- first letter of category needs to be Capitalized
				amountratio = (amount2 == 0 and 0) or amount1/amount2*100
				
				hide2 = true
				
			elseif noselection then
				
				hide3 = true
				
				amountratio = (amount3 == 0 and 0) or amount1/amount3*100
				countratio = (count3 == 0 and 0) or count1/count3*100
				
			elseif noselection == false then
			
				amount2 = (selectionData and selectionData[amountkey]) or 0
				if k ~= "Total" then amount3 = selectionData[category.."Total"] or 0 end
				amountratio = (amount1 == 0 and 0) or amount2/amount3*100
				
				count2 = (selectionData and selectionData[countkey]) or 0
				if k ~= "Total" then count3 = (selectionData and selectionData[CountStrings[category].."Total"]) or 0 end
				countratio = (count1 == 0 and 0) or count2/count3*100
			
			end
			
			amountcontrol1:SetText(string.format("%.0f", amount1))
			amountcontrol2:SetText(string.format("%.0f", amount2))
			amountcontrol3:SetText(string.format("%.1f%%", amountratio))
			
			countcontrol1:SetText(string.format("%.0f", count1))
			countcontrol2:SetText(string.format("%.0f", count2))
			countcontrol3:SetText(string.format("%.1f%%", countratio))
			
		end
			
		local hide = not v
		
		amountlabel:SetHidden(hide)
		amountcontrol1:SetHidden(hide)
		amountcontrol2:SetHidden(hide3)
		amountcontrol3:SetHidden(hide)
		
		countlabel:SetHidden(hide)
		countcontrol1:SetHidden(hide)
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
		[4] = {"critres", "%.1f%%", true}, 
	}, 

}


local function updateFightStatsPanelRight(panel)

	CMX.Print("dev", "Updating FightStatsPanelRight")

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
	
	for i=1, 4 do
	
		local text = GetString(stringKey, i)
		local rowcontrol = statWindowControl:GetNamedChild("Row"..i)
		local dataKey, displayformat, convert = unpack(keys[i] or {})
		
		if text ~= nil and text ~= "" and dataKey ~= nil then
		
			local maxvalue = stats["max"..dataKey] or 0
			
			if convert then maxvalue = GetCriticalStrikeChance(maxvalue) end
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
		
		local tooltiplines = {"Penetration: Damage"}  -- TODO use String
		
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

local function updateFightStatsPanel(control)

	CMX.Print("dev", "Updating FightStatsPanel")

	control:GetNamedChild("Left"):Update(fightData, selectionData)
	control:GetNamedChild("Right"):Update(fightData)

end

local function updateMainPanel(mainpanel, fightData, selectionData)

	CMX.Print("dev", "Updating MainPanel")

	mainpanel.active:Update(fightData, selectionData)

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

local function updateBuffPanel(panel)

	CMX.Print("dev", "Updating BuffPanel")

	ResetBars(panel)
	
	if fightData == nil then return end
	
	local buffdata
	local rightpanel = db.FightReport.rightpanel
	
	if rightpanel == "buffsout" then 
	
		buffdata = selectionData
		
	elseif rightpanel == "buffs" then 
	
		buffdata = fightData.calculated 
		
	else return	end
	
	if buffdata == nil then return end
	
	local scrollchild = GetControl(panel, "PanelScrollChild")
	
	local selectedbuffs = selections["buff"]["buff"] 
	local currentanchor = {TOPLEFT, scrollchild, TOPLEFT, 0, 1}
	
	local maxtime = math.max(fightData.activetime or 0, fightData.dpstime or 0, fightData.hpstime or 0)
	
	local buffcount = buffdata.buffcount or 1
	local showids = db.debuginfo.ids
	local favs = db.FightReport.FavouriteBuffs
	
	for buffName, buff in CMX.spairs(buffdata["buffs"], buffSortFunction) do
		if buff.groupUptime > 0 then

			-- prepare contents
			
			local color = (buff.effectType == BUFF_EFFECT_TYPE_BUFF and {0, 0.6, 0, 0.6}) or (buff.effectType == BUFF_EFFECT_TYPE_DEBUFF and {0.75, 0, 0.6, 0.6}) or {0.6, 0.6, 0.6, 0.6}
			local groupColor = (buff.effectType == BUFF_EFFECT_TYPE_BUFF and {0, 0.6, 0, 0.3}) or (buff.effectType == BUFF_EFFECT_TYPE_DEBUFF and {0.75, 0, 0.6, 0.3}) or {0.6, 0.6, 0.6, 0.3}
			
			local highlight = false
			if selectedbuffs ~= nil then highlight = (selectedbuffs[buffName] ~= nil) end
			
			local icon = CMX.GetAbilityIcon(buff.icon)
			local dbug = (showids and type(buff.icon) == "number") and string.format("(%d) ", buff.icon) or ""
			local name = dbug .. buffName
			
			local uptimeRatio = buff.uptime / (1000 * maxtime * buffcount)
			local groupUptimeRatio = buff.groupUptime / (1000 * maxtime * buffcount)
			
			local count = buff.count
			local groupCount = buff.groupCount
			
			local hideGroupValues = count == groupCount and uptimeRatio == groupUptimeRatio
			
			local countFormat = hideGroupValues and "%d" or "%d/%d"
			local uptimeFormat = hideGroupValues and "%.0f%%" or "%.0f%%/%.0f%%"
			
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

local function updateResourceBars(panel, currentanchor, data, totalRate, selectedresources, color)

	local scrollchild = GetControl(panel, "PanelScrollChild")
	
	local showids = db.debuginfo.ids
	
	for abilityId, ability in CMX.spairs(data, function(t, a, b) return t[a].value>t[b].value end) do
	
		if (ability.ticks or 0) > 0 then
			
			local label = abilityId > 0 and GetFormatedAbilityName(abilityId) or GetString(SI_COMBAT_METRICS_BASE_REG)
			
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

	CMX.Print("dev", "Updating ResourcePanel")
	
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

	CMX.Print("dev", "Updating RightPanel")

	rightPanel.active:Update()

end

local function GetShortFormattedNumber(number)
 
	local exponent = math.floor(math.log(number)/math.log(10))
	local loweredNumber = zo_roundToNearest(number, math.pow(10, exponent-2))
	
	local shortNumber = ZO_AbbreviateNumber(loweredNumber, 2, exponent>=6)
	
	return shortNumber
	
end

local function updateUnitPanel(panel)

	CMX.Print("dev", "Updating UnitPanel")

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
	
	local rightpanel = db.FightReport.rightpanel
	
	local showids = db.debuginfo.ids
	local scale = db.FightReport.scale
		
	for unitId, unit in CMX.spairs(data.units, function(t, a, b) return t[a][totalAmountKey]>t[b][totalAmountKey] end) do -- i.e. for damageOut sort by damageOutTotal
	
		local totalUnitAmount = unit[totalAmountKey]
		
		local unitData = fightData.units[unitId]
	
		if (totalUnitAmount > 0 or (rightpanel == "buffsout" and NonContiguousCount(unit.buffs) > 0 and (fightData.units[unitId].isFriendly == false and isdamage) or (unitData.isFriendly and not isdamage))) then
			
			local highlight = false
			if selectedunits ~= nil then highlight = selectedunits[unitId] ~= nil end
			
			local dbug = showids and string.format("(%d) ", unitId) or ""
			
			local name = dbug .. unitData.name
			
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

local function updateAbilityPanel(panel)

	CMX.Print("dev", "Updating AbilityPanel")

	ResetBars(panel)
	
	local category = db.FightReport.category
	
	local isDamage = category == "damageIn" or category == "damageOut"
	
	local ratioColumnLabel = category == "damageIn" and GetString(SI_COMBAT_METRICS_BLOCKS) or category == "damageOut" and GetString(SI_COMBAT_METRICS_CRITS) or GetString(SI_COMBAT_METRICS_HEALS) 
	local valueColumnLabel = isDamage and GetString(SI_COMBAT_METRICS_DAMAGE) or GetString(SI_COMBAT_METRICS_HEALING)

	local header = panel:GetNamedChild("Header")
	
	header:GetNamedChild("Total"):SetText(valueColumnLabel)
	header:GetNamedChild("Crits"):SetText(ratioColumnLabel)
	
	if fightData == nil then return end
	
	local data
	local totaldmg
	
	local selectedabilities = selections["ability"][category]
	local selectedunits = selections["unit"][category]
	
	if selectedunits ~= nil then
	
		data = selectionData 
		totaldmg = selectionData.totalValueSum
		
	else 
	
		data = fightData.calculated
		totaldmg = data[category.."Total"]
		
	end
	
	local scrollchild = GetControl(panel, "PanelScrollChild")
	local currentanchor = {TOPLEFT, scrollchild, TOPLEFT, 0, 1}
	
	local totalAmountKey = category.."Total"
	local totalHitKey = CountStrings[category].."Total"
	local critKey = CountStrings[category].."Critical"
	local DPSKey = DPSstrings[category]	
	
	local showids = db.debuginfo.ids
	
	for abilityId, ability in CMX.spairs(data[category], function(t, a, b) return t[a][totalAmountKey]>t[b][totalAmountKey] end) do
	
		if ability[totalAmountKey]>0 then 
			
			local highlight = false
			
			if selectedabilities ~= nil then 
				highlight = selectedabilities[abilityId] ~= nil 
			end
			
			local icon = CMX.GetAbilityIcon(abilityId)
			
			local dot = (GetAbilityDuration(abilityId)>0 or (IsAbilityPassive(abilityId) and isDamage)) and "*" or ""
			local pet = ability.pet and " (pet)" or ""
			local dbug = showids and string.format("(%d) ", abilityId) or ""
			local color = ability.damageType and CMX.GetDamageColor(ability.damageType) or ""
			
			local name  = dbug..color..(ability.name or GetFormatedAbilityName(abilityId))..dot..pet.."|r"
			
			local dps = ability[DPSKey]
			local total = ability[totalAmountKey]
			local ratio = total / totaldmg
			
			local crits = ability[critKey]
			local hits = ability[totalHitKey]
			local critratio = 100 * crits / hits
			
			local avg = total / hits
			local max = ability.max
			
			local rowId = #panel.bars + 1
			
			local rowName = scrollchild:GetName() .. "Row" .. rowId
			local row = _G[rowName] or CreateControlFromVirtual(rowName, scrollchild, "CombatMetrics_AbilityRowTemplate")
			row:SetAnchor(unpack(currentanchor))
			row:SetHidden(false)
			
			local header = panel:GetNamedChild("Header")
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
			fractionControl:SetText(string.format("%.1f%%", 100 * ratio))
			
			local rateControl = row:GetNamedChild("PerSecond")
			rateControl:SetText(string.format("%.0f", dps))
			
			local amountControl = row:GetNamedChild("Total")
			amountControl:SetText(total)
			
			local critControl = row:GetNamedChild("Crits")
			critControl:SetText(crits)
			
			local hitsControl = row:GetNamedChild("Hits")
			hitsControl:SetText(string.format("/%d", hits))			
			
			local critFractionControl = row:GetNamedChild("CritRatio")
			critFractionControl:SetText(string.format("%.0f%%", critratio))
			
			local avgControl = row:GetNamedChild("Average")
			avgControl:SetText(string.format("%.0f", avg))
			
			local maxControl = row:GetNamedChild("Maximum")
			maxControl:SetText(max)
			
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
	
	buttonrow:GetNamedChild("PageLeft"):SetHidden(first==1)
	buttonrow:GetNamedChild("PageRight"):SetHidden(last>=maxpage)
	
	for i = first, last do
	
		local key = "Page" .. (i - first + 1)
		
		buttonrow:GetNamedChild(key):SetHidden(i>maxpage)
		buttonrow:GetNamedChild(key .. "Label"):SetText(i)
		
		local bg = buttonrow:GetNamedChild(key.."Overlay")
		
		bg:SetCenterColor( 0 , 0 , 0 , page == i and 0 or 0.8 )
		bg:SetEdgeColor( 1 , 1 , 1 , page == i and 1 or .4 )
		
	end
end

local function updateCombatLog(panel)

	CMX.Print("dev", "Updating CombatLog")
	
	local CLSelection = db.FightReport.CLSelection	
	
	if fightData == nil then return end
	
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
			
				local ability = GetFormatedAbilityName(abilityId)
				
				condition2 = (
					buffSelection == nil and unitsSelected==false)
					or (buffSelection ~= nil and buffSelection[ability]~= nil and unitsSelected == false) 
					or (buffSelection == nil and unitSelectionAll[unitId]~= nil) 
					or (buffSelection ~= nil and buffSelection[ability] ~= nil and unitsSelected == true and unitSelectionAll[unitId] ~= nil
				)
				
			elseif logtype == LIBCOMBAT_EVENT_RESOURCES then
			
				local abilityId = logline[3]
				
				condition2 = resourceSelection == nil or resourceSelection[abilityId or 0] ~= nil
				
			elseif logtype == LIBCOMBAT_EVENT_PLAYERSTATS or logtype == LIBCOMBAT_EVENT_MESSAGES then
			
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

local function updateInfoRowPanel(panel)

	CMX.Print("dev", "Updating InfoRow")

	local datetimecontrol = panel:GetNamedChild("DateTime")
	local versioncontrol = panel:GetNamedChild("ESOVersion")
	
	local data = fightData or {
	
		["date"] = GetTimeStamp(), 
		["time"] = GetTimeString(), 
		["ESOversion"] = GetESOVersionString(), 
	
	}
	
	local date = data.date
	
	local datestring = type(date) == "number" and GetDateStringFromTimestamp(date) or date
	local timestring = string.format("%s, %s", datestring, data.time)
	local versionstring = data.ESOversion or "<= 3.2"
	
	datetimecontrol:SetText(timestring)
	versioncontrol:SetText(versionstring)

end

local function updateFightReport(control, fightId)

	CMX.Print("dev", "Updating FightReport")

	em:UnregisterForUpdate("CMX_Report_Update_Delay")
	
	local category = db.FightReport.category or "damageOut"
	
	-- clear selections of abilities, buffs or units when selecting a different fight to display -- 
	
	if fightId == nil or fightId ~= currentFight then
	
		selections["ability"][category] = nil
		selections["unit"][category] = nil
		selections["buff"]["buff"] = nil	
		selections["resource"]["resource"] = nil
		
	end
	
	-- determine which fight to show
	
	fightId = fightId or currentFight  -- if no fightId was given, use the previous one (this will also select the next fight if one is deleted)
	
	if fightId == nil or fightId < 0 or CMX.lastfights[fightId] == nil then -- if no valid fight is selected, fall back to the most recent one, if it exists.
		
		if #CMX.lastfights == 0 then 
			
			fightId = -1 -- there si no fight saved in pos. -1, it will be nil.
		
		else 
			
			fightId = #CMX.lastfights 
		
		end
	end
	
	currentFight = fightId
	
	fightData = CMX.lastfights[fightId] -- this is the fight of interest, can be nil
	
	if fightData and fightData.calculated == nil then -- if it wasn't calculated yet, do so now
		
		fightData:CalculateFight() 
		UpdateReport2()
		return 
		
	elseif fightData and fightData.calculating == true then  -- if it is still calculating wait for it to finish

		em:RegisterForUpdate("CMX_Report_Update_Delay", 500, UpdateReport2)
		return
		
	end

	-- Generate Filtered Dataset
	
	selectionData = fightData and CMX.GenerateSelectionStats(fightData, category, selections) or nil
	
	abilitystats = {fightData, selections.unit.damageOut ~= nil and selectionData or nil}
	
	-- Update Panels
	
	for i = 2, control:GetNumChildren() do
	
		local child = control:GetChild(i)
		
		if child.Update then child:Update(fightData, selectionData) end
		
	end	
end

local function updateFightListPanel(panel, data, issaved)
	
	local scrolllist = GetControl(panel, "PanelScrollChild")
	local currentanchor = {TOPLEFT, scrolllist, TOPLEFT, 0, 1} 
	
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
			
				activetime = fight.hpstime or 1
			
			else 
			
				activetime = fight.dpstime or 1
			
			end

			local durationstring = string.format("%d:%04.1f", activetime/60, activetime%60)
			
			local DPSKey = DPSstrings[db.FightReport.category]
			local dps = fight[DPSKey] or 0
			
			local rowName = scrolllist:GetName() .. "Row" .. id
			local row = _G[rowName] or CreateControlFromVirtual(rowName, scrolllist, "CombatMetrics_FightlistRowTemplate")
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

	CMX.Print("dev", "Updating FightListPanel")

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

function CMX.PosttoChat(mode)

	local data = CMX.currentdata
	
	if data.units == nil then 
	
		if #CMX.lastfights == 0 then return end
		data = CMX.lastfights[#CMX.lastfights]
	
	end
	
	local output = ""
	
	local dpstime = data.dpstime
	local timeString = string.format("%d:%04.1f", dpstime/60, dpstime%60)
	
	local totalDPS, totalDamage, maxDamage, units, name, bossName = 0, 0, 0, 0, "", ""
	local bossDPS, bossDamage, maxBossDamage, bossUnits = 0, 0, 0, 0
	
	for unitId, unit in pairs(data.units) do
	
		local totalUnitDamage = unit.damageOutTotal
		
		if (unit.bossId ~= nil and totalUnitDamage>0) then 
		
			bossDamage = bossDamage + totalUnitDamage
			bossUnits = bossUnits + 1 
			
			if totalUnitDamage > maxBossDamage then 
			
				bossName = unit.name
				maxBossDamage = totalUnitDamage
				
			end
		end
		
		if totalUnitDamage > 0 and unit.isFriendly == false then
		
			totalDamage = totalDamage + totalUnitDamage
			units = units + 1
			
			if totalUnitDamage > maxDamage then 
			
				name = unit.name
				maxDamage = totalUnitDamage
				
			end
		end
	end
	
	name = zo_strformat(SI_UNIT_NAME, (bossName ~= "" and bossName) or name)
	
	local singleDamage = maxDamage
	local singleDamageString = ZO_CommaDelimitNumber(singleDamage)
	local singleDPSString = ZO_CommaDelimitNumber(math.floor(singleDamage / dpstime))
	
	local bossDamage = bossUnits > 0 and bossDamage or singleDamage
	local bossDPSString = ZO_CommaDelimitNumber(math.floor(bossDamage / dpstime))
	local bossDamageString = ZO_CommaDelimitNumber(bossDamage)
	
	local totalDPSString = ZO_CommaDelimitNumber(math.floor(totalDamage / dpstime))
	local totalDamageString = ZO_CommaDelimitNumber(totalDamage)
	
	if mode == "HPS" then 
	
		local hpstime = data.hpstime
		local timeString = string.format("%d:%04.1f", hpstime/60, hpstime%60)
	
		local totalHPSString = ZO_CommaDelimitNumber(data.HPSOut)
		local totalHealingString = ZO_CommaDelimitNumber(data.healingOutTotal)
		
		output = string.format("%s - HPS: %s (%s in %s)", name, totalHPSString, totalHealingString, timeString)
		
	elseif units == 1 or mode == "DPSS" then 
	
		output = string.format("%s - DPS: %s (%s in %s)", name, singleDPSString, singleDamageString, timeString)
		
	elseif bossUnits > 0 and mode == "SmartDPS" then
	
		local bosses = bossUnits > 1 and string.format("(+%d)", (bossUnits-1) )  or ""
		output = string.format("%s %s - Boss DPS: %s (%s in %s)", name, bosses, bossDPSString, bossDamage, timeString)
		
	elseif units > 1 and (mode == "DPSM" or mode == "SmartDPS") then
	
		output = string.format("%s (+%d) - DPS: %s (%s in %s)", name, units-1, totalDPSString, totalDamageString, timeString)
		
	elseif mode == "DPST" then 
		
		local bossString = bossUnits > 0 and string.format("Boss DPS (+%d)", bossUnits-1) or  bossUnits == 1 and "Boss DPS" or "DPS"
		output = string.format("%s (%s) - Total DPS (+%d): %s (%s Damage), %s: %s (%s Damage)", name, timeString, units-1, totalDPSString, totalDamageString, bossString, bossDPSString, bossDamageString)
	
	end
		
	-- Determine appropriate channel
	
	local channel = db.autoselectchatchannel==false and "" or IsUnitGrouped('player') and "/p " or "/say "

	-- Print output to chat

	CHAT_SYSTEM.textEntry:SetText( channel .. output )
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

local function initFightReport()

	local fightReport = CombatMetrics_Report

	storeOrigLayout(fightReport)
	
	local pos = db[fightReport:GetName()]
	
	fightReport:ClearAnchors()
	fightReport:SetAnchor(CENTER, nil , TOPLEFT, pos.x, pos.y)
	
	local fragment = ZO_HUDFadeSceneFragment:New(fightReport)

	local scene = ZO_Scene:New("CMX_REPORT_SCENE", SCENE_MANAGER)
	
	scene:AddFragment(fragment)

	local function resize(control, scale)
	
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
	initSelectorButtons(selectorButtons)
	
	initCLButtonRow()
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
	
	function liveReport.Refresh(liveReport)
	
		local liveReport = liveReport
		
		local setLR = db.liveReport		
		local scale = setLR.scale
		
		local anchors = (setLR.layout == "Horizontal" and {
		
							{TOPLEFT, TOPLEFT, 0, 0, liveReport}, 
							{LEFT, RIGHT, 0, 0}, 
							{LEFT, RIGHT, 0, 0}, 
							{LEFT, RIGHT, 0, 0}, 
							{LEFT, RIGHT, 0, 0}
							
						}) or (setLR.layout == "Vertical" and {
						
							{TOPLEFT, TOPLEFT, 0, 0, liveReport}, 
							{TOPLEFT, BOTTOMLEFT, 0, 0}, 
							{TOPLEFT, BOTTOMLEFT, 0, 0}, 
							{TOPLEFT, BOTTOMLEFT, 0, 0}, 
							{LEFT, RIGHT, 0, 0}
							
						}) or { -- layout = compact
						
							{TOPLEFT, TOPLEFT, 0, 0, liveReport}, 
							{LEFT, RIGHT, 0, 0}, 
							{TOPRIGHT, BOTTOMLEFT, 0, 0}, 
							{LEFT, RIGHT, 0, 0}, 
							{LEFT, RIGHT, 0, 0}
						
						}
		
		local last = liveReport
		
		liveReport:SetDimensions(1, 1)
		
		local blocks = 0
		
		for i = 2, liveReport:GetNumChildren() do
		
			local child = liveReport:GetChild(i)
			local name = string.gsub(string.gsub(child:GetName(), liveReport:GetName(), ""), "^%u", string.lower) -- difference in names is the child name e.g. "DamageOut". Outer gsub changes first letter to lowercase to match the settings, e.g. "damageOut".
			
			local shown = setLR[name]
			child:SetHidden(not shown)
			
			if shown then 
			
				blocks = blocks + 1
				
				local anchor = anchors[blocks]
				
				if blocks == 3 and i == 5 and setLR.layout == "Compact" then anchor = anchors[5] end
				
				anchor[5] = last
				
				child:ClearAnchors()
				
				local width, height = unpack(child.sizes)
				
				child:SetDimensions(width*scale, height*scale)
				child:SetAnchor(anchor[1], anchor[5], anchor[2], anchor[3]*scale, anchor[4]*scale)
				
				last = child
			
			end
		end
		
		zo_callLater(function() liveReport:GetNamedChild("BG"):SetDimensions(liveReport:GetWidth(), liveReport:GetHeight()) end, 1)
		
	end
	
	local function resize(control, scale)
	
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
	
end

function convertCurrentToSave(fight)	-- this function compresses the log a little and does a few things to attempt to reduce the ammount of keys that are saved. 

end

function CMX.InitializeUI()

	db = CMX.db
	
	SVHandler = CombatMetricsFightData
	savedFights = SVHandler.GetFights()
	
	checkSaveLimit()

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
	
	CombatMetrics_LiveReport:Toggle(db.liveReport.enabled)
	CombatMetrics_LiveReport:Resize(db.liveReport.scale)
	CombatMetrics_LiveReportBG:SetAlpha(db.liveReport.bgalpha/100)
	CombatMetrics_LiveReport:SetMovable(not db.liveReport.locked) 
				
	CombatMetrics_Report:Resize(db.FightReport.scale)
	
end