local em = GetEventManager()
local wm = GetWindowManager()
local dx = 1/(tonumber(GetCVar("WindowedWidth"))/GuiRoot:GetWidth())
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
local ToggleFeedback
local barKeyOffset = 1

local CMX = CMX
if CMX == nil then CMX = {} end
local _
local db

function CMX.GetAbilityStats()
	return abilitystats, abilitystatsversion
end

local LC = LibStub:GetLibrary("LibCombat")
if LC == nil then return end 

local LibFeedback = LibStub:GetLibrary('LibFeedback')

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

	local size = SVHandler.Check(fight)									-- if no table is passed it will check size of the SV
	
	if fight == nil then 
	
		CMX.Print("save", "SV Size: %.3f MB, %.1f%%", size, size*100/db.maxSVsize)
	
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
			
			errorstring = zo_strformat(SI_COMBAT_METRICS_STORAGE_FULL, removedSize)
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
	
	local isInfo = category == "Info"
	
	mainPanel:SetHidden(isInfo)
	rightPanel:SetHidden(isInfo)
	unitPanel:SetHidden(isInfo)
	abilityPanel:SetHidden(isInfo)
	infoPanel:SetHidden(not isInfo)
	
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
		
		title:SetText(GetChampionDisciplineName(discipline))
		
		local width = title:GetTextWidth() + 4
		local height = title:GetHeight() 
		
		title:SetDimensions(width, height)
		
		CMX.SetLabelColor(signcontrol, color)
		
		for i = 1, 4 do
		
			local row = signcontrol:GetNamedChild("Row"..i)
		
			local label = row:GetNamedChild("Name")
			label:SetText(GetChampionSkillName(discipline, i))
			
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

	for i = 1,2 do
	
		local title = panel:GetNamedChild("AbilityBlock" .. i):GetNamedChild("Title")
		title:SetText(GetString(SI_COMBAT_METRICS_BAR) .. i)
		
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
	
	local isLoaded, loadId
	
	if issaved and savedFights[id] then 
	
		isLoaded, loadId = searchtable(lastfights, "date", savedFights[id]["date"])					-- returns false if nothing is found else it returns the id
		if isLoaded then isLoaded = lastfights[loadId]["time"] == savedFights[id]["time"] end		-- ensures old fights load correctly
	
	end
	
	if issaved and isLoaded == false then
	
		local loadedfight = SVHandler.Load(id)
		
		if loadedfight.log then CMX.AddFightCalculationFunctions(loadedfight) end
		
		table.insert(lastfights, loadedfight)
		CombatMetrics_Report:Update(#CMX.lastfights)
		
	else
		
		CombatMetrics_Report:Update((issaved and loadId or id))
	
	end
	
	local category = db.FightReport.category
	
	ClearSelections()	
	
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
	
	local function postSingleDPS()
	
		CMX.PosttoChat("DPSS", currentFight)
		
	end
	
	local function postSmartDPS()
	
		CMX.PosttoChat("SmartDPS", currentFight)
		
	end
	
	local function postMultiDPS()
	
		CMX.PosttoChat("DPSM", currentFight)
		
	end
	
	local function postAllDPS()
	
		CMX.PosttoChat("DPST", currentFight)
		
	end
	
	local function postHPS()
	
		CMX.PosttoChat("HPS", currentFight)
		
	end
	
	local function requestLuaSave()
	
		GetAddOnManager():RequestAddOnSavedVariablesPrioritySave(CMX.name)
		GetAddOnManager():RequestAddOnSavedVariablesPrioritySave("CombatMetricsFightData")
		d("Save Requested: " .. CMX.name)
		
	end

	function CMX.SettingsContextMenu( settingsbutton, upInside )

		if not upInside then return end
		
		local showIdString = db.debuginfo.ids and SI_COMBAT_METRICS_HIDEIDS or SI_COMBAT_METRICS_SHOWIDS
		
		local postoptions = {}
		
		table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTMULTIDPS), callback = postMultiDPS})
		
		local fight = CMX.lastfights[currentFight]
		
		if fight and fight.bossfight == true then 

			table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTSMARTDPS), callback = postSmartDPS}) 
			
		end
		
		table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTMULTIDPS), callback = postMultiDPS})
		table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTALLDPS), callback = postAllDPS})
		table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTHPS), callback = postHPS})
		
		ClearMenu()
		
		AddCustomMenuItem(GetString(showIdString), toggleshowids)		
		AddCustomSubMenuItem(GetString(SI_COMBAT_METRICS_POSTDPS), postoptions)
		AddCustomMenuItem(GetString(SI_COMBAT_METRICS_SETTINGS), CMX.OpenSettings)
		
		if fight and fight.CalculateFight and (fight.svversion == nil or fight.svversion > 2) then
		
			local function calculate()
			
				fight:CalculateFight()
				CombatMetrics_Report:Update(currentFight)
				
			end
		
			AddCustomMenuItem(GetString(SI_COMBAT_METRICS_RECALCULATE), calculate)
			
		end
		
		AddCustomMenuItem(GetString(SI_COMBAT_METRICS_FEEDBACK), ToggleFeedback)
		
		if GetAPIVersion() > 100024 then AddCustomMenuItem(GetString(SI_COMBAT_METRICS_SAVEHDD), requestLuaSave) end 

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
		
		activetime = fightData and fightData.hpstime or 1
		
	else	
	
		label1 = GetString(SI_COMBAT_METRICS_DPS)
		label2 = GetString(SI_COMBAT_METRICS_DAMAGE)
		label3 = GetString(SI_COMBAT_METRICS_HIT)
		
		rowlist = {Total = true, Normal = true, Critical = true, Blocked = true, Shielded = true}
		
		activetime = fightData and fightData.dpstime or 1
		
	end
	
	local activetimestring = string.format("%d:%05.2f", activetime/60, activetime%60)
	
	local dpsRow = panel:GetNamedChild("StatRowAPS")
	
	dpsRow:GetNamedChild("Label"):SetText(label1) 	-- DPS or HPS
	panel:GetNamedChild("StatTitleAmount"):GetNamedChild("Label"):SetText(label2) 	-- Damage or Healing
	panel:GetNamedChild("StatTitleCount"):GetNamedChild("Label"):SetText(label3) 	-- Hits or Heals
	
	local combattime = fightData and fightData.combattime or 1	
	local combattimestring = string.format("%d:%05.2f", combattime/60, combattime%60)
	
	panel:GetNamedChild("ActiveTimeValue"):SetText(activetimestring)
	panel:GetNamedChild("CombatTimeValue"):SetText(combattimestring)
	
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
		[4] = {"critres", "%d", "%.1f%%"}, 
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

local function updateMainPanel(mainpanel)

	CMX.Print("dev", "Updating MainPanel")

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
			
			local icon = GetFormattedAbilityIcon(buff.icon)
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
			
			local label = abilityId ~= 0 and GetFormattedAbilityName(abilityId) or GetString(SI_COMBAT_METRICS_BASE_REG)
			
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

local function selectHitCritOption1()

	db.FightReport.hitCritLayout = {"Critical", "Total", "SI_COMBAT_METRICS_HITS", "SI_COMBAT_METRICS_CRITS"}
	
	CombatMetrics_Report_AbilityPanel:Update()
	
end

local function selectHitCritOption2()

	db.FightReport.hitCritLayout = {"Total", "Critical", "SI_COMBAT_METRICS_CRITS", "SI_COMBAT_METRICS_HITS"}
	
	CombatMetrics_Report_AbilityPanel:Update()
	
end

local function selectHitCritOption3()

	db.FightReport.hitCritLayout = {"Normal", "Critical", "SI_COMBAT_METRICS_NORM", "SI_COMBAT_METRICS_CRITS"}
	
	CombatMetrics_Report_AbilityPanel:Update()
	
end

function CMX.HitCritContextMenu(control, button)

	ClearMenu()
	
	local text1 = string.format("%s/%s", GetString(SI_COMBAT_METRICS_HITS), GetString(SI_COMBAT_METRICS_CRITS))
	local text2 = string.format("%s/%s", GetString(SI_COMBAT_METRICS_CRITS), GetString(SI_COMBAT_METRICS_HITS))
	local text3 = string.format("%s/%s", GetString(SI_COMBAT_METRICS_NORM), GetString(SI_COMBAT_METRICS_CRITS))
	
	AddCustomMenuItem(text1, selectHitCritOption1)
	AddCustomMenuItem(text2, selectHitCritOption2)
	AddCustomMenuItem(text3, selectHitCritOption3)
	
	ShowMenu(control)

end

local function selectAverageOption1()

	db.FightReport.averageLayout = {"Total", ""}
	
	CombatMetrics_Report_AbilityPanel:Update()
	
end

local function selectAverageOption2()

	db.FightReport.averageLayout = {"Normal", " N"}
	
	CombatMetrics_Report_AbilityPanel:Update()
	
end

local function selectAverageOption3()

	db.FightReport.averageLayout = {"Critical", " C"}
	
	CombatMetrics_Report_AbilityPanel:Update()
	
end

function CMX.AverageContextMenu(control, button)

	ClearMenu()
	
	local text1 = string.format("%s %s", GetString(SI_COMBAT_METRICS_AVERAGE), GetString(SI_COMBAT_METRICS_HITS))
	local text2 = string.format("%s %s", GetString(SI_COMBAT_METRICS_AVERAGE), GetString(SI_COMBAT_METRICS_NORMAL_HITS))
	local text3 = string.format("%s %s", GetString(SI_COMBAT_METRICS_AVERAGE), GetString(SI_COMBAT_METRICS_CRITS))
	
	AddCustomMenuItem(text1, selectAverageOption1)
	AddCustomMenuItem(text2, selectAverageOption2)
	AddCustomMenuItem(text3, selectAverageOption3)
	
	ShowMenu(control)

end

local function selectMinMaxOption1()

	db.FightReport.maxValue = true
	
	CombatMetrics_Report_AbilityPanel:Update()
	
end

local function selectMinMaxOption2()

	db.FightReport.maxValue = false
	
	CombatMetrics_Report_AbilityPanel:Update()
	
end

function CMX.MinMaxContextMenu(control, button)

	ClearMenu()
	
	local text1 = string.format("%s", GetString(SI_COMBAT_METRICS_MAX))
	local text2 = string.format("%s", GetString(SI_COMBAT_METRICS_MIN))
	
	AddCustomMenuItem(text1, selectMinMaxOption1)
	AddCustomMenuItem(text2, selectMinMaxOption2)
	
	ShowMenu(control)

end

local function updateAbilityPanel(panel)

	CMX.Print("dev", "Updating AbilityPanel")

	ResetBars(panel)
	
	local settings = db.FightReport
	
	local category = settings.category
	local hitCritLayout = settings.hitCritLayout
	local averageLayout = settings.averageLayout
	local minmax = settings.maxValue
	
	local isDamage = category == "damageIn" or category == "damageOut"
	
	local ratioColumnLabel = category == "damageIn" and GetString(SI_COMBAT_METRICS_BLOCKS) or category == "damageOut" and GetString(SI_COMBAT_METRICS_CRITS) or GetString(SI_COMBAT_METRICS_HEALS) 
	local valueColumnLabel = isDamage and GetString(SI_COMBAT_METRICS_DAMAGE) or GetString(SI_COMBAT_METRICS_HEALING)

	local header = panel:GetNamedChild("Header")
	
	header:GetNamedChild("Total"):SetText(valueColumnLabel)
	header:GetNamedChild("Crits"):SetText(ratioColumnLabel)
	
	local headerCrit = header:GetNamedChild("Crits")
	local headerHit = header:GetNamedChild("Hits")
	
	headerCrit:SetText(GetString(_G[hitCritLayout[3]]))
	headerHit:SetText("/" .. GetString(_G[hitCritLayout[4]]))
	
	local headerAvg = header:GetNamedChild("Average")
	
	headerAvg:SetText(GetString(SI_COMBAT_METRICS_AVE) .. averageLayout[2])
	
	local headerMinMax = header:GetNamedChild("MinMax")
	
	headerMinMax:SetText(GetString(minmax and SI_COMBAT_METRICS_MAX or SI_COMBAT_METRICS_MIN))
	
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
	
	local ratioKey1 = CountStrings[category]..hitCritLayout[1]	-- first value of the crits/hits column display
	local ratioKey2 = CountStrings[category]..hitCritLayout[2]  -- second value of the crits/hits column display
	
	local avgKey1 = category..averageLayout[1]					-- damage value of the avg column display
	local avgKey2 = CountStrings[category]..averageLayout[1]	-- hits value of the avg column display
	
	local DPSKey = DPSstrings[category]	
	
	local showids = db.debuginfo.ids
	
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
			local ratio = total / totaldmg
			
			local crits = ability[critKey]
			local hits = ability[totalHitKey]
			local critratio = 100 * crits / hits
			
			local ratio1 = ability[ratioKey1]
			local ratio2 = ability[ratioKey2]
			
			local avg1 = ability[avgKey1] 
			local avg2 = ability[avgKey2]
			
			local avg = avg2 == 0 and 0 or (avg1 / avg2)
			local minmaxValue = minmax and ability.max or (ability.min or 0)
			
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
			fractionControl:SetText(string.format("%.1f%%", 100 * ratio))
			
			local rateControl = row:GetNamedChild("PerSecond")
			rateControl:SetText(string.format("%.0f", dps))
			
			local amountControl = row:GetNamedChild("Total")
			amountControl:SetText(total)
			
			local critControl = row:GetNamedChild("Crits")
			critControl:SetText(ratio1)
			
			local hitsControl = row:GetNamedChild("Hits")
			hitsControl:SetText(string.format("/%d", ratio2))			
			
			local critFractionControl = row:GetNamedChild("CritRatio")
			critFractionControl:SetText(string.format("%.0f%%", critratio))
			
			local avgControl = row:GetNamedChild("Average")
			avgControl:SetText(string.format("%.0f", avg))
			
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

	if fightData == nil or panel:IsHidden() then return end
	
	CMX.Print("dev", "Updating CombatLog")
	
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
				
				condition2 = resourceSelection == nil or resourceSelection[abilityId or 0] ~= nil
				
			elseif logtype == LIBCOMBAT_EVENT_PLAYERSTATS or logtype == LIBCOMBAT_EVENT_MESSAGES or logtype == LIBCOMBAT_EVENT_SKILL_TIMINGS then
			
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

local function MapValue(plotwindow, dimension, value)

	local range = dimension == CMX_PLOT_DIMENSION_X and plotwindow.RangesX or plotwindow.RangesY
	local minRange, maxRange = unpack(range)
	
	local controlSize = dimension == CMX_PLOT_DIMENSION_X and plotwindow:GetWidth() or plotwindow:GetHeight()

	local IsInRange = (value < maxRange) and (value > minRange)
	local offset = controlSize * ((value - minRange)/(maxRange - minRange))
	
	return offset, IsInRange

end

local function MapValueXY(plotwindow, x, y)

	local XOffset, IsInRangeX = plotwindow:MapValue(CMX_PLOT_DIMENSION_X, x)
	local YOffset, IsInRangeY = plotwindow:MapValue(CMX_PLOT_DIMENSION_Y, y)

	local IsInRange = IsInRangeX and IsInRangeY
	
	return XOffset, YOffset, IsInRange

end

local function MapUIPos(plotwindow, dimension, value)

	local range = dimension == CMX_PLOT_DIMENSION_X and plotwindow.RangesX or plotwindow.RangesY
	local minRange, maxRange = unpack(range)
	
	local minCoord = dimension == CMX_PLOT_DIMENSION_X and plotwindow:GetLeft() or plotwindow:GetTop()
	local maxCoord = dimension == CMX_PLOT_DIMENSION_X and plotwindow:GetRight() or plotwindow:GetBottom()

	local IsInRange = (value < maxCoord) and (value > minCoord)
	
	local relpos = (value - minCoord) / (maxCoord - minCoord)
	
	if dimension == CMX_PLOT_DIMENSION_Y then relpos = 1 - relpos end -- since coords start at topleft but a plot from bottom left 
	
	local value = relpos * (maxRange - minRange) + minRange
	
	return value, IsInRange

end

local function MapUIPosXY(plotwindow, x, y)

	local t, IsInRangeX = plotwindow:MapUIPos(CMX_PLOT_DIMENSION_X, x)
	local v, IsInRangeY = plotwindow:MapUIPos(CMX_PLOT_DIMENSION_Y, y)

	local IsInRange = IsInRangeX and IsInRangeY
	
	return t, v, IsInRange

end

local Plotcolors = {

	[1] = {1, 1, 0, 0.66},	-- yellow
	[2] = {1, 0, 0, 0.66},	-- red
	[3] = {0, 1, 0, 0.66},	-- green
	[4] = {0, 0, 1, 0.66},	-- blue
	[5] = {1, 0, 1, 0.66},	-- violet
	[6] = {0, 1, 1, 0.66},	-- cyan

}

local function DrawLine(plot, coords, id, colorId)

	local plotid = plot.id
	local lineControls = plot.lineControls

	if lineControls[id] == nil then
	
		lineControls[id] = CreateControlFromVirtual("$(parent)Line", plot, "CombatMetrics_PlotLine", id)
		
	end	
	
	local line = lineControls[id]
	
	line:SetThickness(dx * 2) 
	line:SetColor(unpack(Plotcolors[colorId])) 
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

local function DrawXYPlot(plot)

	local plotwindow = plot:GetParent()

	local XYData = plot.XYData
	local colorId = plot.colorId
	
	local coordinates = {}
	plot.coordinates = coordinates
	
	for id, line in ipairs(plot.lineControls) do
	
		line:SetHidden(true)
		
	end
	
	local x0
	local y0
	local inRange0
		
	for i, dataPair in ipairs(XYData) do
	
		local t, v = unpack(dataPair)
		local x, y, inRange = plotwindow:MapValueXY(t, v)
		coordinates[i] = {x, y, inRange}
		
		if i > 1 then			
		
			local lineCoords = {x0, y0, x, y, inRange0, inRange}
			local id = i - 1

			DrawLine(plot, lineCoords, id, colorId)
		
		end
			
		x0 = x
		y0 = y
		inRange0 = inRange
	
	end
end

local CMX_PLOT_TYPE_XY = 1
local CMX_PLOT_TYPE_BAR = 2

local plotTypeTemplates = {

	[CMX_PLOT_TYPE_XY] = "CombatMetrics_PlotControlXY",
	[CMX_PLOT_TYPE_BAR] = "CombatMetrics_PlotControlBar",

}

local function AddPlot(plotwindow, id, plotType, height)

	local plots = plotwindow.plots

	if plots[id] == nil then
	
		local newplot = CreateControlFromVirtual("CombatMetrics_Report_MainPanelGraphPlot", plotwindow, plotTypeTemplates[plotType], id)
		
		newplot.plotType = plotType
		
		if plotType == CMX_PLOT_TYPE_XY then 
		
			newplot.lineControls = {} 
			newplot.DrawXYPlot = DrawXYPlot			
			
		end
		
		plots[id] = newplot
		
	elseif plotType ~= plots[id].plotType then	-- if plottype is different, get rid of the control.
	
		plots[id]:SetParent(nil)
		
		local plot = plots[id]
		
		if plotType ~= CMX_PLOT_TYPE_XY and plot.lineControls then
		
			for id, line in pairs(plot.lineControls) do
	
				line:SetParent(nil)
				plot.lineControls[id] = nil
				
			end
			
		else 
			
			plot.lineControls = {}
			plot.DrawXYPlot = DrawXYPlot
			
		end
		
		plots[id] = CreateControlFromVirtual("CombatMetrics_Report_MainPanelGraphPlot", plotwindow, plotTypeTemplates[plotType], id)
		plots[id].plotType = plotType
		
	end
	
	local plot = plots[id]
	
	if plotType == CMX_PLOT_TYPE_XY then
	
		for id, line in ipairs(plot.lineControls) do
	
			line:SetHidden(true)
			
		end
	
	elseif plotType == CMX_PLOT_TYPE_BAR then
	
		plot:ClearAnchors()
		plot:SetAnchor(TOPLEFT, plotwindow, TOPLEFT, -24, height)
		plot:SetAnchor(TOPRIGHT, plotwindow, TOPRIGHT, 0, height)
		plot:SetHeight(20 * dx)
	
	end
	
	return plot
end

local function GetScale(x1, x2)	-- e.g. 34596 and 42693

	local distance = math.max(x2 - x1, 1)	-- 8097

	local power = math.pow(10, math.floor(math.log10(distance)))	-- math.pow(10, math.floor(3.91) = math.pow(10, 3) = 1000
	
	local high = math.ceil(x2 / power) * power	-- 43000
	local low = math.floor(x1 / power) * power	-- 34000
	
	local size = (high - low) / power 	-- 9000 / 1000 = 9
	
	local rangesizes = {1, 2, 4, 8, 10, 20}
	
	local cleansize
	
	for i, value in ipairs(rangesizes) do
	
		if size <= value then 
		
			cleansize = value	-- 10
			break
			
		end
		
	end
	
	local delta = cleansize - size -- 1
	
	local cleanLow = low - math.floor(delta / 2) * power 	-- 34000 - math.floor(0.5) * 1000 = 34000
	local cleanHigh = high + math.ceil(delta / 2) * power 	-- 34000 - math.ceil(0.5) * 1000 = 44000
	
	if cleanLow < 0 then
	
		cleanHigh = cleanHigh - cleanLow	
		cleanLow = 0
	
	end
	
	local cleanDist = cleanHigh - cleanLow
	
	local tickValues = {cleanLow, 0, 0, 0, cleanHigh}
	
	for i = 2,4 do
	
		tickValues[i] = cleanLow + cleanDist * (i - 1) / 4
	
	end
	
	return cleanLow, cleanHigh, tickValues

end

local function UpdateScales(plotwindow, ranges)

	local x1, x2, y1, y2 = unpack(ranges)	
	
	local RangesX = {GetScale(x1, x2)}
	local RangesY = {GetScale(y1, y2)}
	
	plotwindow.RangesX = RangesX
	plotwindow.RangesY = RangesY
	
	local ticksX = RangesX[3]
	local ticksY = RangesY[3]
	
	for i = 1,5 do
	
		local ticklabelX = GetControl(plotwindow:GetName(), "XTick" .. i .. "Label")
		local ticklabelY = GetControl(plotwindow:GetName(), "YTick" .. i .. "Label")
		
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

local function GetRequiredRange(plotwindow, newRange, startZero)

	local oldRangeX = plotwindow.RangesX
	local oldRangeY = plotwindow.RangesY
	
	local minXOld = oldRangeX[1]
	local maxXOld = oldRangeX[2]
	local minYOld = oldRangeY[1]
	local maxYOld = oldRangeY[2]
	
	local minX, maxX, minY, maxY = unpack(newRange) 

	local minXNew = startZero and 0 or math.min(minXOld, minX)
	local maxXNew = math.max(maxXOld, maxX)
	local minYNew = startZero and 0 or math.min(minYOld, minY)
	local maxYNew = math.max(maxYOld, maxY)
	
	return {minXNew, maxXNew, minYNew, maxYNew}

end


local function PlotXY(plotwindow, plotid, XYData, autoRange, colorId)

	local range = AcquireRange(XYData) 

	if autoRange then 
		
		local newRange = plotwindow:GetRequiredRange(range, true)
		
		plotwindow:UpdateScales(newRange)
		
	end

	local plot = plotwindow:AddPlot(plotid, CMX_PLOT_TYPE_XY)
	
	plot.range = range
	plot.XYData = XYData
	plot.colorId = colorId
	plot.autoRange = autoRange
	
	plot:DrawXYPlot()
	
end

local function Smooth(data, smoothWindow, totaltime)

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
	
	return XYData
end

local function Accumulate(data, startpoint, totaltime)

	local XYData = {}
	
	local t2 = math.ceil(totaltime)
	
	local sum = 0
	
	for t = 0, t2 do		
	
		sum = sum + (data[t] or 0)
		
		if t >= startpoint then 
		
			local x = t
			
			local y = sum / t
			
			table.insert(XYData, {x, y})
		
		end
	end
	
	ACCDATA = XYData
	
	return XYData
end

local function updateGraphPanel(panel)

	local plotwindow = panel:GetNamedChild("PlotWindow")
	local smoothSlider = panel:GetNamedChild("SmoothControl"):GetNamedChild("Slider")
	
	local SmoothWindow = db.FightReport.SmoothWindow
	
	smoothSlider:SetValue(SmoothWindow)
	
	local category = db.FightReport.category
	
	if fightData == nil then plotwindow:SetHidden(true) return end
	
	plotwindow:SetHidden(false)
	plotwindow.RangesX = {0, 0, {}}
	plotwindow.RangesY = {0, 0, {}}
	
	local data = fightData.calculated
	
	local RawData = data.graph and data.graph[category] or nil -- DPS data, one value per second
	
	if RawData == nil then return end
	
	local combattime = fightData.combattime
	
	local SmoothData = Smooth(RawData, SmoothWindow, combattime)
	
	plotwindow:PlotXY(1, SmoothData, true, 1)
	
	local AccData = Accumulate(RawData, SmoothWindow/2, combattime)
	
	plotwindow:PlotXY(2, AccData, true, 2)
	
end

function CMX.SetSliderValue(self, value)
	
	local labelControl = self:GetParent():GetNamedChild("Label")
	
	labelControl:SetText(string.format(GetString(SI_COMBAT_METRICS_SMOOTH), value))
	
	db.FightReport.SmoothWindow = value
	
	local graphPanel = self:GetParent():GetParent()
	
	graphPanel:Update() 
	
end

local function limit(value, minValue, maxValue)

	local coercedValue = math.min(math.max(value, minValue), maxValue)

	return coercedValue

end

do

	local startX, startY

	local function UpdateZoomControl()

		local plotwindow = _G["CombatMetrics_Report_MainPanelGraphPlotWindow"]
		local zoomcontrol = plotwindow:GetNamedChild("Zoom")
		
		local x2, y2 = GetUIMousePosition()
		
		local minX, minY, maxX, maxY = plotwindow:GetScreenRect()
		
		limit(x2, minX, maxX)
		limit(y2, minY, maxY)
		
		local width = math.abs(x2 - startX)
		local height = math.abs(y2 - startY)
		
		zoomcontrol:SetAnchor(TOPLEFT, GuiRoot , TOPLEFT, math.min(startX, x2), math.min(startY, y2))
		zoomcontrol:SetDimensions(width, height)
		
	end

	function CMX.onPlotMouseDown(plotwindow, button)

		if button ~= MOUSE_BUTTON_INDEX_LEFT then return end
		
		local zoomcontrol = plotwindow:GetNamedChild("Zoom")
		
		local x, y = GetUIMousePosition()
		
		zoomcontrol:SetAnchor(TOPLEFT, GuiRoot , TOPLEFT, x, y)
		zoomcontrol:SetDimensions(0, 0)
		zoomcontrol:SetHidden(false)
		
		startX = x
		startY = y
		
		em:RegisterForUpdate("CMX_Report_Zoom_Control", 25, UpdateZoomControl)
		
	end

	function CMX.onPlotMouseUp(plotwindow, button, upInside)

		if button == MOUSE_BUTTON_INDEX_LEFT then
		
			local x, y = GetUIMousePosition()
			
			local t1, v1 = plotwindow:MapUIPosXY(startX, startY)
			local t2, v2 = plotwindow:MapUIPosXY(x, y)
			
			local minT, maxT = unpack(plotwindow.RangesX)
			local minV, maxV = unpack(plotwindow.RangesY)
			
			limit(t2, minT, maxT)
			limit(v2, minV, maxV)
			
			em:UnregisterForUpdate("CMX_Report_Zoom_Control")
			local zoomcontrol = plotwindow:GetNamedChild("Zoom")
			zoomcontrol:SetHidden(true)
			
			local tMin = math.min(t1, t2)
			local tMax = math.max(t1, t2)
			local vMin = math.min(v1, v2)
			local vMax = math.max(v1, v2)
			
			plotwindow:UpdateScales({tMin, tMax, vMin, vMax})
			
			for id, plot in pairs(plotwindow.plots) do
			
				if plot.DrawXYPlot then
				
					plot:DrawXYPlot()
					
				end
			end

		elseif button == MOUSE_BUTTON_INDEX_RIGHT then
		
			for id, plot in pairs(plotwindow.plots) do
			
				if plot.XYData and plot.autoRange then
				
					local range = AcquireRange(plot.XYData) 
						
					local newRange = plotwindow:GetRequiredRange(range, true)
						
					plotwindow:UpdateScales(newRange)
					
				end
			end	

			for id, plot in pairs(plotwindow.plots) do
			
				if plot.DrawXYPlot then
				
					plot:DrawXYPlot()
					
				end
			end
		end
	end
end
	
function CMX.initPlotWindow(plotwindow)

	plotwindow.plots = {}
	
	plotwindow.MapValue = MapValue
	plotwindow.MapValueXY = MapValueXY
	plotwindow.MapUIPos = MapUIPos
	plotwindow.MapUIPosXY = MapUIPosXY
	plotwindow.AddPlot = AddPlot
	plotwindow.PlotXY = PlotXY
	plotwindow.UpdateScales = UpdateScales
	plotwindow.GetRequiredRange = GetRequiredRange
	
end


function CMX.SkillTooltip_OnMouseEnter(control)
	
	InitializeTooltip(SkillTooltip, control, TOPLEFT, 0, 5, BOTTOMLEFT)
	SkillTooltip:SetAbilityId(control:GetParent().id)
	
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
		
		if barStats then
		
			dpsratio = (barStats[category] or 0) / data[category.."Total"]
			
			local totalTime = (category == "healingIn" or category == "healingOut") and fightData.hpstime or fightData.dpstime or 1
			
			timeratio = (barStats.totalTime or 0) / totalTime
		
		end
		
		local statControl = row:GetNamedChild("Stats")
		local ratioControl = statControl:GetNamedChild("Value1")
		local timeControl = statControl:GetNamedChild("Value2")
		
		ratioControl:SetText(string.format("%.1f%%", (timeratio or 0) * 100))
		timeControl:SetText(string.format("%.1f%%", (dpsratio or 0) * 100))
		
		for j = 4, row:GetNumChildren() - 1 do
		
			local strings = {"-", "-", "-", "-", "-", "-"}
			
			local control = row:GetChild(j)
			
			local icon = control:GetNamedChild("Icon"):GetNamedChild("Texture")
			
			local name = control:GetNamedChild("Label")
			
			local abilityId = bardata and bardata[j-3] or nil
			
			control.id = abilityId
			
			local texture = abilityId and GetFormattedAbilityIcon(abilityId) or "EsoUI/Art/crafting/gamepad/crafting_alchemy_trait_unknown.dds"
			
			icon:SetTexture(texture)
			
			local abilityName = abilityId and GetFormattedAbilityName(abilityId) or ""

			name:SetText(abilityName)
			
			local reducedslot = (barkey - 1) * 10 + j - 3 
			
			local slotdata = skilldata and skilldata[reducedslot] or nil
			
			if slotdata then
			
				strings[1] = string.format("%d", slotdata[skillkeys[1]])
			
				for k = 2, #skillkeys do
				
					local value = slotdata[skillkeys[k]]
					
					if type(value) == "number" and k > 1 then
					
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
	
	local statrow = panel:GetNamedChild("Stats")	
	
	local totalSkills = data.totalSkills
	
	local totalTime = data.totalSkillTime
	
	local value1string = "-"
	local value2string = "-"
	
	if totalSkills and totalSkills > 0 and totalTime then 
	
		value1string = (totalTime and totalSkills) and string.format("%.3f s", totalTime / (1000 * totalSkills)) or "-"
		value2string = totalTime and string.format("%.3f s", totalTime / 1000) or "-"
		
	end
	
	statrow:GetNamedChild("Value1"):SetText(value1string)
	statrow:GetNamedChild("Value2"):SetText(value2string)
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
		
		local _, enchantstring = GetItemLinkEnchantInfo(item) 
		
		enchant:SetText(enchantstring:gsub(GetString(SI_COMBAT_METRICS_ENCHANTMENT_TRIM), ""))
		
	end
end

local function updateInfoPanel(panel)

	if panel:IsHidden() then return end

	updateLeftInfoPanel(panel:GetNamedChild("Left"))
	updateRightInfoPanel(panel:GetNamedChild("Right"))
	updateBottomInfoPanel(panel:GetNamedChild("Bottom"))
	
end

local function updateInfoRowPanel(panel)

	CMX.Print("dev", "Updating InfoRow")

	local datetimecontrol = panel:GetNamedChild("DateTime")
	local versioncontrol = panel:GetNamedChild("ESOVersion")
	local barcontrol = panel:GetNamedChild("Bar")
	local barlabelcontrol = barcontrol:GetNamedChild("Label")
	
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
	
	local usedSpace = db.SVsize/db.maxSVsize
	
	barcontrol:SetValue(usedSpace)
	barlabelcontrol:SetText(string.format("%s: %.1f MB / %d MB (%.1f%%)", GetString(SI_COMBAT_METRICS_SAVED_DATA), db.SVsize, db.maxSVsize, usedSpace * 100))

end

local function updateFightReport(control, fightId)

	CMX.Print("dev", "Updating FightReport")

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

local function GetCurrentData()

	local data = CMX.currentdata
	
	if data.units == nil then 
	
		if #CMX.lastfights == 0 then return end
		data = CMX.lastfights[#CMX.lastfights]
	
	end
	
	return data
end

local function GetSingleTargetDamage(data)	-- Gets highest Single Target Damage and counts enemy units.

	local damage, groupDamage, units, name = 0, 0, 0, ""
	
	for unitId, unit in pairs(data.units) do
	
		local totalUnitDamage = unit.damageOutTotal
		
		if totalUnitDamage > 0 and unit.isFriendly == false then
		
			if totalUnitDamage > damage then 
			
				name = unit.name
				damage = totalUnitDamage
				groupDamage = unit.groupDamageOut
				
			end
		end
	end
	
	return damage, groupDamage, name
end

local function GetBossTargetDamage(data) -- Gets Damage done to bosses and counts enemy boss units.

	local totalBossDamage, bossDamage, bossUnits, bossName = 0, 0, 0, ""
	
	for unitId, unit in pairs(data.units) do
	
		local totalUnitDamage = unit.damageOutTotal
		
		if (unit.bossId ~= nil and totalUnitDamage>0) then 
		
			totalBossDamage = totalBossDamage + totalUnitDamage
			bossUnits = bossUnits + 1 
			
			if totalUnitDamage > bossDamage then 
			
				bossName = unit.name
				bossDamage = totalUnitDamage
				
			end
		end
	end
	
	return totalBossDamage, bossUnits, bossName
end

local function GetFullDamage(data)	-- Gets highest Single Target Damage and counts enemy units.

	local units, damage = 0, 0
	
	for unitId, unit in pairs(data.units) do
	
		local totalUnitDamage = unit.damageOutTotal
		
		if totalUnitDamage > 0 and unit.isFriendly == false then
		
			units = units + 1
			damage = damage + totalUnitDamage
			
		end
	end
	
	return units, damage
end
	
function CMX.PosttoChat(mode, fight)

	local data = fight and CMX.lastfights[fight] or GetCurrentData()
	
	if data == nil then return end
	
	local timedata = ""
	
	if data ~= GetCurrentData() then 

		local date = data.date
	
		local datestring = type(date) == "number" and GetDateStringFromTimestamp(date) or date
		local timedata = string.format("[%s, %s] ", datestring, data.time)

	end
	
	local output = ""
	
	local dpstime = data.dpstime
	local timeString = string.format("%d:%04.1f", dpstime/60, dpstime%60)
	
	local singleDamage, _, name = GetSingleTargetDamage(data)
	local units, totalDamage = GetFullDamage(data)
	local bossDamage, bossUnits, bossName = GetBossTargetDamage(data)
	
	name = zo_strformat(SI_UNIT_NAME, (bossName ~= "" and bossName) or name)
	
	local singleDPSString = ZO_CommaDelimitNumber(math.floor(singleDamage / dpstime))
	local singleDamageString = ZO_CommaDelimitNumber(singleDamage)
	
	local bossDamage = bossUnits > 0 and bossDamage or singleDamage
	local bossDPSString = ZO_CommaDelimitNumber(math.floor(bossDamage / dpstime))
	local bossDamageString = ZO_CommaDelimitNumber(bossDamage)
	
	local totalDPSString = ZO_CommaDelimitNumber(math.floor(data.DPSOut))
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
	
		local singleTargetDamage, singleTargetDamageGroup = GetSingleTargetDamage(data)
		
		SDPS = math.floor(singleTargetDamage / dpstime + 0.5)
		groupSDPS = math.floor(singleTargetDamageGroup / dpstime + 0.5)
		
	end

	local DPSString
	local HPSString
	local DPSInString
	local maxtime = math.max(dpstime, hpstime)
	local timeString = string.format("%d:%04.1f", maxtime/60, maxtime%60)
		
	-- maybe add data from group
	if db.recordgrp == true and (groupDPSOut > 0 or groupDPSIn > 0 or groupHPSOut > 0) then
	
		local dpsratio, hpsratio, idpsratio , sdpsratio = 0, 0, 0, 0
		
		if groupDPSOut > 0  then dpsratio  = (math.floor(DPSOut / groupDPSOut * 1000) / 10) end 
		if groupDPSIn > 0 then idpsratio = (math.floor(DPSIn / groupDPSIn * 1000) / 10) end 
		if groupHPSOut > 0  then hpsratio  = (math.floor(HPSOut / groupHPSOut * 1000) / 10) end
		if groupSDPS > 0  then sdpsratio  = (math.floor(SDPS / groupSDPS * 1000) / 10) end

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
	initSelectorButtons(selectorButtons)
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
		
		for i = 2, liveReport:GetNumChildren() do
		
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
				local alignment = db.liveReport.alignmentleft and TEXT_ALIGN_LEFT or TEXT_ALIGN_RIGHT
				
				label:SetHorizontalAlignment(alignment)
			
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
	
	CombatMetrics_LiveReport:Toggle(db.liveReport.enabled)
	CombatMetrics_LiveReport:Resize(db.liveReport.scale)
	CombatMetrics_LiveReportBG:SetAlpha(db.liveReport.bgalpha/100)
	CombatMetrics_LiveReport:SetMovable(not db.liveReport.locked) 
				
	CombatMetrics_Report:Resize(db.FightReport.scale)
	
	local settingsbutton = CombatMetrics_Report_SelectorRowSettingsButton
	
	local data = CMX.GetFeedBackData(settingsbutton)
					
	local button, feedbackWindow = LibFeedback:initializeFeedbackWindow(unpack(data))
	button:SetHidden(true)
			
	function ToggleFeedback() 
		
		feedbackWindow:ToggleHidden()
		
	end	
end