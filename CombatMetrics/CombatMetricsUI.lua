---@diagnostic disable: assign-type-mismatch
local em = GetEventManager()
local wm = GetWindowManager()
local dx = zo_ceil(GuiRoot:GetWidth()/tonumber(GetCVar("WindowedWidth"))*1000)/1000
COMBAT_METRICS_LINE_SIZE = dx

local currentFight
local abilitystats
local abilitystatsversion = 3
local fightData, selectionData
local currentCLPage
local selections, lastSelections
local savedFights
local SVHandler
local enlargedGraph = false
local maxXYPlots = 5
local maxBarPlots = 8
local uncollapsedBuffs = {}

local LOG_LEVEL_VERBOSE = "V"
local LOG_LEVEL_DEBUG = "D"
local LOG_LEVEL_INFO = "I"
local LOG_LEVEL_WARNING ="W"
local LOG_LEVEL_ERROR = "E"

if LibDebugLogger then
	LOG_LEVEL_VERBOSE = LibDebugLogger.LOG_LEVEL_VERBOSE
	LOG_LEVEL_DEBUG = LibDebugLogger.LOG_LEVEL_DEBUG
	LOG_LEVEL_INFO = LibDebugLogger.LOG_LEVEL_INFO
	LOG_LEVEL_WARNING = LibDebugLogger.LOG_LEVEL_WARNING
	LOG_LEVEL_ERROR = LibDebugLogger.LOG_LEVEL_ERROR
end

if GetAPIVersion() < 100034 then CHAMPION_DISCIPLINE_TYPE_COMBAT, CHAMPION_DISCIPLINE_TYPE_CONDITIONING, CHAMPION_DISCIPLINE_TYPE_WORLD = 0, 1, 2 end

local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger
local db
local _

function CMX.GetAbilityStats()

	local isSelection = selections.unit.damageOut ~= nil
	return abilitystats, abilitystatsversion, isSelection

end

local LC = LibCombat
if LC == nil then return end

local GetFormattedAbilityName = LC.GetFormattedAbilityName
local GetFormattedAbilityIcon = LC.GetFormattedAbilityIcon

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




local function toggleFightList(panel, show)
	panel = panel or CombatMetrics_Report_FightList
	show = show or panel:IsHidden()
	panel:SetHidden(not show)
	if show then
		panel:Update()
	end

	panel:GetParent():GetNamedChild("_InfoRow"):Update()
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

function NavButtonFunctions.save(control, _, _, _, _, shiftkey )
	if control:GetState() == BSTATE_DISABLED then
		return
	else
		local numFights = SVHandler.GetNumFights()
		local lastsaved = SVHandler.GetFight(numFights)
		if lastsaved ~= nil and lastsaved.date == fightData.date then return end -- bail out if fight is already saved

		local spaceLeft = db.maxSavedFights - numFights
		assert(spaceLeft > 0, zo_strformat(SI_COMBAT_METRICS_SAVEDFIGHTS_FULL, 1-spaceLeft))

		SVHandler.Save(fightData, shiftkey)
		CombatMetrics_Report:Update()
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

		if #CMX.lastfights == 0 then CombatMetrics_Report:Update() else CombatMetrics_Report:Update(zo_min(currentFight, #CMX.lastfights)) end

	end
end

function CMX.InitNavButtons(rowControl)

	for i=1, rowControl:GetNumChildren() do

		local child = rowControl:GetChild(i)

		if child then child:SetHandler( "OnMouseUp", NavButtonFunctions[child.func]) end

	end
end


local labelcolors = {
	[CHAMPION_DISCIPLINE_TYPE_COMBAT] = GetString(SI_COMBAT_METRICS_MAGICKA_COLOR),
	[CHAMPION_DISCIPLINE_TYPE_CONDITIONING] = GetString(SI_COMBAT_METRICS_HEALTH_COLOR),
	[CHAMPION_DISCIPLINE_TYPE_WORLD] = GetString(SI_COMBAT_METRICS_STAMINA_COLOR),
}

local starcolors = {
	[CHAMPION_DISCIPLINE_TYPE_COMBAT] = ZO_ColorDef:New(0.8, 0.8, 1),
	[CHAMPION_DISCIPLINE_TYPE_CONDITIONING] = ZO_ColorDef:New(1, 0.80, 0.8),
	[CHAMPION_DISCIPLINE_TYPE_WORLD] = ZO_ColorDef:New(0.8, 1, 0.7),
}


function CMX.InitializeScribedSkillsPanel(panel)
	local nameBase = panel:GetName()
	local anchor
	for i = 1, 10 do
		local scribedSkillControl = CreateControlFromVirtual(nameBase, panel, "CombatMetrics_ScribedSkillTemplate", i)
		-- scribedSkillControl:SetHidden(false)

		if i == 1 then
			scribedSkillControl:SetAnchor(TOPLEFT, panel, TOPLEFT, 0, 4)
		else
			scribedSkillControl:SetAnchor(TOPLEFT, anchor, BOTTOMLEFT, 0, 4)
			scribedSkillControl:SetHidden(true)
		end

		anchor = scribedSkillControl
	end
end

function CMX.InitializeChampionPointsPanel(panel)
	local scrollchild = GetControl(panel, "ScrollChild")
	scrollchild:SetResizeToFitPadding(0, 20)
	scrollchild:SetAnchor(TOPRIGHT, nil, TOPRIGHT, 0, 0)
	local currentanchor = {TOPLEFT, scrollchild, TOPLEFT, 0, dx}
	local currentanchor2 = {TOPRIGHT, scrollchild, TOPRIGHT, 0, dx}

	for disciplineId = 1,3 do
		local disciplineType = GetChampionDisciplineType(disciplineId)
		local color = labelcolors[disciplineType]

		local panelName = scrollchild:GetName() .. "Panel" .. disciplineId
		local constellationControl = _G[panelName] or CreateControlFromVirtual(panelName, scrollchild, "CombatMetrics_ConstellationTemplate")
		constellationControl:SetAnchor(unpack(currentanchor))
		constellationControl:SetAnchor(unpack(currentanchor2))
		constellationControl:SetHidden(false)

		currentanchor = {TOPLEFT, constellationControl, BOTTOMLEFT, 0, 4}
		currentanchor2 = {TOPRIGHT, constellationControl, BOTTOMRIGHT, 0, 4}

		---@type LabelControl
		local title = constellationControl:GetNamedChild("Title")
		local top = title:GetTop()
		title:SetText(zo_strformat(SI_CHAMPION_CONSTELLATION_NAME_FORMAT, GetChampionDisciplineName(disciplineId)))

		local nameBase = constellationControl:GetName() .. "StarControl"
		local anchor

		for i = 1, 24 do
			local starControl = CreateControlFromVirtual(nameBase, constellationControl, "CombatMetrics_StarTemplate", i)

			if i == 1 then
				starControl:SetAnchor(TOPLEFT, title, BOTTOMLEFT, 0, 4)
			elseif i%2 == 0 then
				starControl:SetAnchor(TOPLEFT, anchor, TOPRIGHT, 7, 0)
			elseif i%2 == 1 then
				starControl:SetAnchor(TOPRIGHT, anchor, BOTTOMLEFT, -7, 2)
			end

			anchor = starControl
			local coords = {0.75, 1, 0.5, 0.75}

			if i > 4 then
				coords = {0.25, 0.5, 0.25, 0.5}
				starControl:GetNamedChild("Ring"):SetHidden(true)
				starControl:SetHidden(true)
			else
				starControl:GetNamedChild("Icon"):SetHidden(true)
				starControl:GetNamedChild("Name"):SetHidden(true)
				starControl:GetNamedChild("Value"):SetHidden(true)
			end

			local starIcon = starControl:GetNamedChild("Icon")
			starIcon:SetTextureCoords(unpack(coords))
			starIcon:SetColor(starcolors[disciplineType]:UnpackRGB())
		end
		local bottom = constellationControl:GetNamedChild("StarControl4"):GetBottom()
		constellationControl:SetHeight(bottom-top)

		CMX.SetLabelColor(constellationControl, color)
	end
end


function CMX.InitializeSkillStats(panel)

	local block = panel:GetNamedChild("ActionBar1")
	local title = block:GetNamedChild("Title")
	title:SetText(GetString(SI_COMBAT_METRICS_BAR) .. 1)

	local statPanel = block:GetNamedChild("Stats2")
	local label = statPanel:GetNamedChild("Label")
	local label2 = statPanel:GetNamedChild("Label2")

	label.tooltip = {SI_COMBAT_METRICS_SKILLAVG_TT}
	label:SetText(string.format("%s    -", GetString(SI_COMBAT_METRICS_AVERAGEC)))
	label2.tooltip = {SI_COMBAT_METRICS_SKILLTOTAL_TT}
	label2:SetText(string.format("%s    -", GetString(SI_COMBAT_METRICS_TOTALC)))

	local block2 = panel:GetNamedChild("ActionBar2")
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
	local savedFight = SVHandler.GetFight(id)

	if issaved and savedFight then
		-- returns false if nothing is found else it returns the id
		isLoaded, loadId = searchtable(lastfights, "date", savedFight["date"])
		if isLoaded then isLoaded = lastfights[loadId]["time"] == savedFight["time"] end		-- ensures old fights load correctly
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
		SVHandler.Delete(id)
		CombatMetrics_Report:Update()
	else
		table.remove(CMX.lastfights, id)
		if #CMX.lastfights == 0 then CombatMetrics_Report:Update() else CombatMetrics_Report:Update(zo_min(currentFight, #CMX.lastfights)) end
	end

	toggleFightList(nil, true)
end

function CMX.DeleteItemLog(control)
	local row = control:GetParent():GetParent()
	local issaved = row.issaved
	local id = row.id

	if issaved then
		SVHandler.DeleteLog(id)
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

do
	local sendGold

	local function PrefillMail()

		local isDonation = sendGold and sendGold > 0
		local headerString = GetString(isDonation and SI_COMBAT_METRICS_DONATE_GOLD_HEADER or SI_COMBAT_METRICS_FEEDBACK_MAIL_HEADER)

		ZO_MailSendToField:SetText("@Solinur")
		ZO_MailSendSubjectField:SetText(string.format(headerString, CMX.version))
		ZO_MailSendBodyField:TakeFocus()

		if sendGold and sendGold > 0 then

			QueueMoneyAttachment(sendGold)
			ZO_MailSendSendCurrency:OnBeginInput()

		else

			ZO_MailSendBodyField:TakeFocus()

		end

	end

	local function SendIngameMail()

		sendGold = 0
		SCENE_MANAGER:Show('mailSend')
		zo_callLater(PrefillMail, 250)

	end

	local function GotoESOUI()

		RequestOpenUnsafeURL(GetString(SI_COMBAT_METRICS_FEEDBACK_ESOUIURL))

	end

	local function GotoGithub()

		RequestOpenUnsafeURL(GetString(SI_COMBAT_METRICS_FEEDBACK_GITHUBURL))

	end

	local function GotoDiscord()

		RequestOpenUnsafeURL(GetString(SI_COMBAT_METRICS_FEEDBACK_DISCORDURL))

	end

	local function DonateGold()

		sendGold = 5000
		SCENE_MANAGER:Show('mailSend')
		zo_callLater(PrefillMail, 200)

	end

	local function CloseDialog()

		CombatMetrics_Report_DonateDialog:SetHidden(true)

	end

	local function DonateCrowns()

		local dialog = CombatMetrics_Report_DonateDialog
		local button = dialog:GetNamedChild("Button")
		local editbox = dialog:GetNamedChild("AccountInfo"):GetNamedChild("EditBox")

		dialog:SetHidden(false)

		button:SetHandler("OnClicked", CloseDialog, "CombatMetrics")
		editbox:SetText("@Solinur")
		editbox:TakeFocus()
		editbox:SelectAll()

	end

	local function GotoESOUIDonation()

		RequestOpenUnsafeURL(GetString(SI_COMBAT_METRICS_DONATE_ESOUIURL))

	end

	function CMX.FeedbackContextMenu( settingsbutton, upInside )

		if not upInside then return end

		ClearMenu()

		local isEUServer = GetWorldName() == "EU Megaserver"
		local stringFormatEU = isEUServer and "<<1>>" or SI_COMBAT_METRICS_FEEDBACK_EUONLY_FORMAT

		local feedbackSubItems = {
			{label = ZO_CachedStrFormat(stringFormatEU, GetString(SI_COMBAT_METRICS_FEEDBACK_MAIL)), callback = SendIngameMail, disabled = not isEUServer},
			{label = GetString(SI_COMBAT_METRICS_FEEDBACK_ESOUI), callback = GotoESOUI},
			{label = GetString(SI_COMBAT_METRICS_FEEDBACK_GITHUB), callback = GotoGithub},
			{label = GetString(SI_COMBAT_METRICS_FEEDBACK_DISCORD), callback = GotoDiscord},
		}

		local donationSubItems = {
			{label = ZO_CachedStrFormat(stringFormatEU, GetString(SI_COMBAT_METRICS_DONATE_GOLD)), callback = DonateGold, disabled = not isEUServer},
			{label = ZO_CachedStrFormat(stringFormatEU, GetString(SI_COMBAT_METRICS_DONATE_CROWNS)), callback = DonateCrowns, disabled = not isEUServer},
			{label = GetString(SI_COMBAT_METRICS_DONATE_ESOUI), callback = GotoESOUIDonation},
		}

		AddCustomSubMenuItem(GetString(SI_COMBAT_METRICS_FEEDBACK_SEND), feedbackSubItems, nil, nil, nil, 2)
		AddCustomSubMenuItem(GetString(SI_COMBAT_METRICS_DONATE), donationSubItems, nil, nil, nil, 2)

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

		local istart = zo_min(lastsel, id)
		local iend = zo_max(lastsel, id)

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

		local istart = zo_min(lastsel, id)
		local iend = zo_max(lastsel, id)

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

	CMX.Log("UI", LOG_LEVEL_DEBUG, "Updating ResourcePanel")

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

	line:SetThickness(dx * 16)
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

	local maxX, _ = plot:GetDimensions()
	maxX = maxX - xoffset

	local outOfRange = ( x2 < minX ) or ( x1 > maxX )

	if outOfRange then	-- bar is completely out of drawing area

		bar:SetHidden(false)
		return

	end

	local left = zo_max(x1, minX) + xoffset
	local right = zo_min(x2, maxX) + xoffset

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

	local t2 = zo_ceil(totaltime) - smoothWindow

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

	local t2 = zo_ceil(totaltime)

	local sum = 0

	local t0
	local tmax

	local combatstart = fightData.combatstart or fightData.dpsstart or fightData.hpsstart or 0
	local dpsstart = fightData.dpsstart or combatstart
	local dpsend = fightData.dpsend or (combatstart + 1)
	local hpsstart = fightData.hpsstart or combatstart
	local hpsend = fightData.hpsend or (combatstart + 1)

	if category == "healingOut" or category == "healingIn" then

		t0 = (hpsstart - combatstart) / 1000
		tmax = (hpsend - combatstart) / 1000

	else

		t0 = (dpsstart - combatstart) / 1000
		tmax = (dpsend - combatstart) / 1000

	end

	local startpoint = zo_max(db.FightReport.SmoothWindow / 2, t0)

	for t = 0, t2 do

		sum = sum + (data[t] or 0)

		if t >= startpoint and t <= zo_ceil(tmax) then

			local x = t

			local y = sum / (zo_min(tmax, t) - t0)

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

	local t2 = zo_ceil(totaltime)

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

	[POWERTYPE_HEALTH] = LIBCOMBAT_STAT_MAXHEALTH,
	[POWERTYPE_MAGICKA] = LIBCOMBAT_STAT_MAXMAGICKA,
	[POWERTYPE_STAMINA] = LIBCOMBAT_STAT_MAXSTAMINA,

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

			local deltatime = zo_floor(lineData[2]/1000 - combatstart)

			value = lineData[6] or 0

			updateXYData(XYData, deltatime, value)

		end
	end

	if value then updateXYData(XYData, fightData.combattime, value) end

	local key = powerTypeKeyTable[powerType]

	local maxValue = powerType == POWERTYPE_ULTIMATE and 500 or fightData.calculated.stats[key].max

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

			local deltatime = zo_floor(lineData[2]/1000 - combatstart)

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

			local deltatime = lineData[2]/1000 - combatstart

			local isSkill = dataType ~= 7 or (lineData[3]%10) > 2

			if deltatime > x and isSkill then

				x = deltatime
				y = lineData[key]

				table.insert(XYData, {x, y})
			end
		end
	end

	TEST = XYData

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

			maxvalue = zo_max(value, maxvalue)

			local deltatime = zo_floor(lineData[2]/1000 - combatstart)

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

					if prevend and (zo_abs(starttime - prevend)) < 0.02 and prevunit == unitId then 		-- to avoid drawing too many controls: if a buff is renewed within 20 ms, consider it continious

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

	local distance = zo_max(x2 - x1, 1)	-- 8097

	local power = zo_pow(10, zo_floor(math.log10(distance/2)))	-- zo_pow(10, zo_floor(3.61) = zo_pow(10, 3) = 1000

	local high = zo_ceil(x2 / power) * power	-- 43000
	local low = zo_floor(x1 / power) * power	-- 34000

	local size = (high - low) / power 	-- 9000 / 1000 = 9

	local cleansize = zo_floor(size)
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

	local cleanLow = low - zo_floor(delta / 2) * power 	-- 34000 - zo_floor(0.5) * 1000 = 34000
	local cleanHigh = high + zo_ceil(delta / 2) * power 	-- 34000 - zo_ceil(0.5) * 1000 = 44000

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

		tickValues[i] = zo_floor(low + (high - low) * (i - 1) / 4)

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

		minX = zo_min(minX, x)
		maxX = zo_max(maxX, x)
		minY = zo_max(minY, y)
		maxY = zo_max(maxY, y)

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

	local minXNew = startZero and 0 or zo_min(minXOld, minX)
	local maxXNew = zo_max(maxXOld, maxX)
	local minYNew = startZero and 0 or zo_min(minYOld, minY)
	local maxYNew = zo_max(maxYOld, maxY)

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
		panel:SetAnchor(BOTTOMRIGHT,     CombatMetrics_Report_SetupPanel, BOTTOMRIGHT, 0, 0)

	else

		panel:SetParent(CombatMetrics_Report_MainPanel)
		panel:SetAnchor(BOTTOMRIGHT, CombatMetrics_Report_MainPanel, BOTTOMRIGHT, 0, 0)

	end

	CombatMetrics_Report:GetNamedChild("_AbilityPanel"):SetHidden(enlargedGraph)
	CombatMetrics_Report:GetNamedChild("_UnitPanel"):SetHidden(enlargedGraph)
	CombatMetrics_Report:GetNamedChild("_BuffPanel"):SetHidden(enlargedGraph)
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

	local coercedValue = zo_min(zo_max(value, minValue), maxValue)

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

		local width = zo_abs(x2 - startX)
		local height = zo_abs(y2 - startY)

		zoomcontrol:SetAnchor(TOPLEFT, GuiRoot , TOPLEFT, zo_min(startX, x2), zo_min(startY, y2))
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

		local tooltipText = string.format("|cddddddTime: %d:%02d", cursorTime/60, zo_floor(cursorTime%60))

		AddTooltipLine(plotWindow, InformationTooltip, tooltipText)

		for plotId, data in CMX.spairs(dataAtCursorTime) do

			local r,g,b = unpack(db.FightReport.PlotColors[plotId])

			local formatter = data[2] and "|c%.2x%.2x%.2x%s: %d (%.1f%%)|r" or "|c%.2x%.2x%.2x%s: %d|r"

			local label = plotWindow.plots[plotId].label

			tooltipText = string.format(formatter, zo_floor(r * 255), zo_floor(g * 255), zo_floor(b * 255), label, unpack(data))

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

			local tMin = zo_min(t1, t2)
			local tMax = zo_max(t1, t2)
			local vMin = zo_min(v1, v2)
			local vMax = zo_max(v1, v2)

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

		local tMin = zo_min(t1, t2)
		local tMax = zo_max(t1, t2)
		local vMin = zo_min(v1, v2)
		local vMax = zo_max(v1, v2)

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

	local format = rowControl.ignored and "ID: %d (Off GCD)" or "ID: %d"

	SkillTooltip:SetAbilityId(id)
	SkillTooltip:AddVerticalPadding(15)
	SkillTooltip:AddLine(string.format(format, id), font, .7, .7, .8 , TOP, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER)
	if delay then SkillTooltip:AddLine(string.format("Average delay: %d ms", delay), font, .7, .7, .8 , TOP, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER) end
end

function CMX.SkillTooltip_OnMouseExit(control)

	ClearTooltip(SkillTooltip)

end

function CMX.ScribedSkillTooltip_OnMouseEnter(control)
	if control.scriptIds == nil then return end
	local abilityId = control.abilityId
	local scriptIds = control.scriptIds

	InitializeTooltip(SkillTooltip, control, TOPLEFT, 0, 5, BOTTOMLEFT)
	SetCraftedAbilityScriptSelectionOverride(GetAbilityCraftedAbilityId(abilityId), scriptIds[1], scriptIds[2], scriptIds[3])
	SkillTooltip:SetAbilityId(abilityId)
end

function CMX.ScribedSkillTooltip_OnMouseExit(control)
	ClearTooltip(SkillTooltip)
end

function CMX.CPTooltip_OnMouseEnter(starControl)

	if starControl.starId == nil then return end

	InitializeTooltip(ChampionSkillTooltip, starControl, TOPLEFT, 0, 5, BOTTOMLEFT)

	ChampionSkillTooltip:SetChampionSkill(starControl.starId, starControl.points, nil, starControl.slotted)

end

function CMX.CPTooltip_OnMouseExit(control)

	ClearTooltip(ChampionSkillTooltip)

end

function CMX.ItemTooltip_OnMouseEnter(control)

	local itemLink = control.itemLink
	local enchantDescription = control.enchantDescription

	if itemLink ~= "" and itemLink ~= nil then

		InitializeTooltip(ItemTooltip, control:GetParent(), TOPLEFT, 5, 0, TOPRIGHT)
		ItemTooltip:SetLink(itemLink)

	elseif enchantDescription ~= "" and enchantDescription ~= nil then

		InitializeTooltip(SkillTooltip, control:GetParent(), TOPLEFT, 5, 0, TOPRIGHT)
		SkillTooltip:AddVerticalPadding(5)
		SkillTooltip:AddLine(enchantDescription)

	end

end

function CMX.ItemTooltip_OnMouseExit(control)

	ClearTooltip(ItemTooltip)
	ClearTooltip(SkillTooltip)

end

local equipslots = {

	{EQUIP_SLOT_MAIN_HAND, "EsoUI/Art/CharacterWindow/gearslot_mainhand.dds"},
	{EQUIP_SLOT_OFF_HAND, "EsoUI/Art/CharacterWindow/gearslot_offhand.dds"},
	{EQUIP_SLOT_BACKUP_MAIN, "EsoUI/Art/CharacterWindow/gearslot_mainhand.dds"},
	{EQUIP_SLOT_BACKUP_OFF, "EsoUI/Art/CharacterWindow/gearslot_offhand.dds"},
	{EQUIP_SLOT_HEAD, "EsoUI/Art/CharacterWindow/gearslot_head.dds"},
	{EQUIP_SLOT_SHOULDERS, "EsoUI/Art/CharacterWindow/gearslot_shoulders.dds"},
	{EQUIP_SLOT_CHEST, "EsoUI/Art/CharacterWindow/gearslot_chest.dds"},
	{EQUIP_SLOT_HAND, "EsoUI/Art/CharacterWindow/gearslot_hands.dds"},
	{EQUIP_SLOT_WAIST, "EsoUI/Art/CharacterWindow/gearslot_belt.dds"},
	{EQUIP_SLOT_LEGS, "EsoUI/Art/CharacterWindow/gearslot_legs.dds"},
	{EQUIP_SLOT_FEET, "EsoUI/Art/CharacterWindow/gearslot_feet.dds"},
	{EQUIP_SLOT_NECK, "EsoUI/Art/CharacterWindow/gearslot_neck.dds"},
	{EQUIP_SLOT_RING1, "EsoUI/Art/CharacterWindow/gearslot_ring.dds"},
	{EQUIP_SLOT_RING2, "EsoUI/Art/CharacterWindow/gearslot_ring.dds"},
}

local armorcolors = {

	[ARMORTYPE_NONE] = {1, 1, 1, 1},
	[ARMORTYPE_HEAVY] = {1, 0.3, 0.3, 1},
	[ARMORTYPE_MEDIUM] = {0.3, 1, 0.3, 1},
	[ARMORTYPE_LIGHT] = {0.3, 0.3, 1, 1},
}

local SkillBarItems = {"LightAttack", "HeavyAttack", "Ability1", "Ability2", "Ability3", "Ability4", "Ability5", "Ultimate"}

local DisabledColor = ZO_ColorDef:New("FF999999")
local WerewolfColor = ZO_ColorDef:New("FFf3c86e")
local WhiteColor = ZO_ColorDef:New("FFFFFFFF")

local function updateSkillsPanel(panel)

	if fightData == nil then return end

	local charData = fightData.charData

	if charData == nil then return end

	local skillBars = charData.skillBars

	local data = fightData.calculated

	if data == nil then return end

	local skilldata = data.skills
	local barStatData = data.barStats

	local category = db.FightReport.category

	for subPanelIndex = 1, 2 do

		local subPanel = panel:GetNamedChild("ActionBar" .. subPanelIndex)

		if subPanelIndex == 2 then	-- show extra option for werewolf bar

			local hasWerewolfData = skillBars[HOTBAR_CATEGORY_WEREWOLF+1] ~= nil

			local titleControl = subPanel:GetNamedChild("Title")
			local werewolfButton = subPanel:GetNamedChild("Werewolf")

			werewolfButton:SetHidden(not hasWerewolfData)

			local titleString
			local titleColor = WhiteColor

			if hasWerewolfData then

				local color = DisabledColor

				if db.FightReport.showWereWolf then

					color = WerewolfColor
					subPanelIndex = HOTBAR_CATEGORY_WEREWOLF + 1
					titleString = GetString(SI_HOTBARCATEGORY8)
					titleColor = WerewolfColor

				end

				werewolfButton:GetNamedChild("Texture"):SetColor(color:UnpackRGB())
				werewolfButton:GetNamedChild("Bg"):SetEdgeColor(color:UnpackRGB())

			end

			titleControl:SetText(titleString or zo_strformat("<<1>> 2", GetString(SI_COMBAT_METRICS_BAR)))
			titleControl:SetColor(titleColor:UnpackRGB())
		end

		local bardata = skillBars and skillBars[subPanelIndex] or nil
		local barStats = barStatData and barStatData[subPanelIndex] or nil

		local dpsratio, timeratio

		if barStats and type(barStats[category]) == "number" then

			dpsratio = (barStats[category] or 0) / data[category.."Total"]

			local totalTime = (category == "healingIn" or category == "healingOut") and fightData.hpstime or fightData.dpstime or 1

			timeratio = (barStats.totalTime or 0) / totalTime

		end

		local ratioControl = subPanel:GetNamedChild("Value1")
		local timeControl = subPanel:GetNamedChild("Value2")

		ratioControl:SetText(string.format("%.1f%%", (timeratio or 0) * 100))
		timeControl:SetText(string.format("%.1f%%", (dpsratio or 0) * 100))

		for line, controlName in ipairs(SkillBarItems) do
			local control = subPanel:GetNamedChild(controlName)
			local abilityId = bardata and bardata[line] or nil
			
			control.id = abilityId
			
			local icon = GetControl(control, "IconTexture")
			local texture = abilityId and abilityId > 0 and GetFormattedAbilityIcon(abilityId) or "EsoUI/Art/crafting/gamepad/crafting_alchemy_trait_unknown.dds"
			icon:SetTexture(texture)
			
			local name = control:GetNamedChild("Label")
			local abilityName = abilityId and abilityId > 0 and GetFormattedAbilityName(abilityId) or ""
			name:SetText(abilityName)

			local reducedslot = (subPanelIndex-1) * 10 + line
			local slotdata = skilldata and skilldata[reducedslot] or nil
			local strings = {"-", "-", "-", "-"}
			local color = WhiteColor

			if slotdata and slotdata.count and slotdata.count > 0 then
				strings[1] = string.format("%d", slotdata.count) or "-"

				local weave = slotdata.weavingTimeAvg or slotdata.skillNextAvg
				strings[2] = weave and string.format("%.2f", weave/1000) or "-"

				local errors = slotdata.weavingErrors
				strings[3] = weave and errors and string.format("%d", errors) or "-"

				local diff = slotdata.diffTimeAvg or slotdata.difftimesAvg
				strings[4] = diff and string.format("%.2f", diff/1000) or "-"

				control.delay = slotdata.delayAvg
				if slotdata.ignored then color = DisabledColor end
				control.ignored = slotdata.ignored
			end

			name:SetColor(color:UnpackRGB())

			for k = 1, 4 do
				local label = control:GetNamedChild("Value" .. k)

				label:SetText(strings[k])
				label:SetColor(color:UnpackRGB())
			end
		end
	end

	local statrow = panel:GetNamedChild("ActionBar1"):GetNamedChild("Stats2")
	local statrow2 = panel:GetNamedChild("ActionBar2"):GetNamedChild("Stats2")

	local totalWeavingTimeCount = data.totalWeavingTimeCount or data.totalSkills
	local totalWeavingTimeSum = data.totalWeavingTimeSum or data.totalSkillTime
	local totalWeaponAttacks = data.totalWeaponAttacks
	local totalSkillsFired = data.totalSkillsFired

	local value1string = " -"
	local value2string = " -"

	if totalWeavingTimeCount and totalWeavingTimeCount > 0 and totalWeavingTimeSum then

		value1string = (totalWeavingTimeSum and totalWeavingTimeCount) and string.format("%.3f s", totalWeavingTimeSum / (1000 * totalWeavingTimeCount)) or " -"
		value2string = totalWeavingTimeSum and string.format("%.3f s", totalWeavingTimeSum / 1000) or " -"

	end

	local value3string = totalWeaponAttacks or " -"
	local value4string = totalSkillsFired or " -"

	statrow:GetNamedChild("Label"):SetText(string.format("%s  %s", GetString(SI_COMBAT_METRICS_SKILLTIME_WEAVING), value1string))
	statrow:GetNamedChild("Label2"):SetText(string.format("%s  %s", GetString(SI_COMBAT_METRICS_TOTALC), value2string))
	statrow2:GetNamedChild("Label"):SetText(string.format("%s  %s", GetString(SI_COMBAT_METRICS_TOTALWA), value3string))
	statrow2:GetNamedChild("Label2"):SetText(string.format("%s  %s", GetString(SI_COMBAT_METRICS_TOTALSKILLS), value4string))
end

function CMX.SkillbarButtonMouseOver(control, isOver)

	local bg = control:GetNamedChild("Bg")

	local alpha = isOver and 1 or 0

	bg:SetCenterColor(0.2, 0.2, 0.2, alpha)

end

function CMX.SkillbarToggleWerewolf(control)

	db.FightReport.showWereWolf = not db.FightReport.showWereWolf

	updateSkillsPanel(control:GetParent():GetParent())

end

---@param panel Control
---@param setHidden boolean
local function setScribedSkillsPanelHidden(panel, setHidden)
	panel:SetHidden(setHidden)
	panel:GetParent():GetNamedChild("Sep"):SetHidden(setHidden)
end

local function updateScribedSkillsPanel(panel)
	if fightData == nil then return setScribedSkillsPanelHidden(panel, true) end
	local scribedSkills = fightData.charData.scribedSkills or {}

	local index = 0
	for abilityId, data in CMX.spairs(scribedSkills) do
		index = index + 1
		local skillControl = panel:GetNamedChild(tostring(index))
		skillControl:SetHidden(false)
		local abilityName = GetFormattedAbilityName(abilityId)
		local iconTexture = GetFormattedAbilityIcon(abilityId)

		skillControl:GetNamedChild("Name"):SetText(abilityName)
		skillControl.abilityId = abilityId
		skillControl.scriptIds = data
		GetControl(skillControl, "IconTexture"):SetTexture(iconTexture)

		for i = 1, 3 do
			local scriptId = data[i]
			local scriptControl = skillControl:GetNamedChild("Script" .. i)
			local scriptName = GetFormattedAbilityName(scriptId, true)
			local iconTexture = GetFormattedAbilityIcon(scriptId, true)

			scriptControl:GetNamedChild("Name"):SetText(scriptName)
			scriptControl:GetNamedChild("Icon"):SetTexture(iconTexture)
		end
		if index == 10 then break end
	end

	for i = index + 1, panel:GetNumChildren() do
		panel:GetNamedChild(tostring(i)):SetHidden(true)
	end

	setScribedSkillsPanelHidden(panel, index == 0)
end


---@param t table
---@param a any key1
---@param b any key2
---@return boolean isHigher
local function starOrder(t, a, b)
	local typeA = t[a][2]
	local typeB = t[b][2]

	if typeA > typeB or (typeA == typeB and a < b) then return true end
	return false
end

local function SetStarControlEmpty(starControl)
	starControl:GetNamedChild("Icon"):SetHidden(true)
	starControl:GetNamedChild("Name"):SetHidden(true)
	starControl:GetNamedChild("Value"):SetHidden(true)
	starControl:GetNamedChild("Ring"):SetTexture("/esoui/art/champion/actionbar/champion_bar_slot_frame_disabled.dds")

	starControl.slotted = nil
	starControl.starId = nil
	starControl.points = nil
end

local function updateChampionPointsPanel(panel)
	if fightData == nil then return end
	local CPData = fightData.CP
	if CPData == nil then return end

	panel:SetHidden(false)
	local scrollchild = GetControl(panel, "PanelScrollChild")

	for disciplineId, discipline in pairs(CPData) do
		if type(discipline) == "table" then
			local constellationControl = scrollchild:GetNamedChild("Panel"..disciplineId)
			local itemNo = 1
			local title = constellationControl:GetNamedChild("Title")
			local top = title:GetTop()
			local disciplineName = zo_strformat(SI_CHAMPION_CONSTELLATION_NAME_FORMAT, GetChampionDisciplineName(disciplineId))

			title:SetText(ZO_CachedStrFormat("<<1>> (<<2>>)", disciplineName, discipline.total))

			for starId, starData in CMX.spairs(discipline.stars, starOrder) do
				local points, state = unpack(starData)

				if state == LIBCOMBAT_CPTYPE_SLOTTED then -- slotted
					local starControl = constellationControl:GetNamedChild("StarControl" .. itemNo)
					starControl:GetNamedChild("Icon"):SetHidden(false)
					starControl:GetNamedChild("Ring"):SetTexture("/esoui/art/champion/actionbar/champion_bar_slot_frame.dds")

					local nameControl = starControl:GetNamedChild("Name")
					local valueControl = starControl:GetNamedChild("Value")

					nameControl:SetHidden(false)
					nameControl:SetText(zo_strformat(SI_CHAMPION_CONSTELLATION_NAME_FORMAT, GetChampionSkillName(starId)))

					valueControl:SetHidden(false)
					valueControl:SetText(points)

					starControl.slotted = true
					starControl.starId = starId
					starControl.points = points
					itemNo = itemNo + 1

				elseif state == LIBCOMBAT_CPTYPE_PASSIVE then
					if itemNo <= 4 then
						for i = itemNo, 4 do
							local starControl = constellationControl:GetNamedChild("StarControl" .. i)
							SetStarControlEmpty(starControl)
						end

						itemNo = 5
					end

					local starControl = constellationControl:GetNamedChild("StarControl" .. itemNo)
					if starControl == nil then break end
					starControl:SetHidden(false)
					starControl:GetNamedChild("Ring"):SetHidden(true)

					local starLabel = starControl:GetNamedChild("Name")
					starLabel:SetText(zo_strformat(SI_CHAMPION_CONSTELLATION_NAME_FORMAT, GetChampionSkillName(starId)))
					starLabel:SetHidden(false)
					
					local starIcon = starControl:GetNamedChild("Icon")
					starIcon:SetTextureCoords(0.25, 0.5, 0.25, 0.5)
					starIcon:SetHidden(false)
					
					local starValue = starControl:GetNamedChild("Value")
					starValue:SetText(points)
					starValue:SetHidden(false)
					
					starControl.slotted = false
					starControl.starId = starId
					starControl.points = points
					itemNo = itemNo + 1
				end
			end
			if itemNo <= 4 then
				for i = itemNo, 4 do
					local starControl = constellationControl:GetNamedChild("StarControl" .. i)
					SetStarControlEmpty(starControl)
				end
				itemNo = 5
			end
			local bottom = constellationControl:GetNamedChild("StarControl" .. (itemNo-1)):GetBottom()
			constellationControl:SetHeight(bottom-top)

			local starControl = constellationControl:GetNamedChild("StarControl" .. itemNo)
			while starControl do
				starControl:SetHidden(true)
				SetStarControlEmpty(starControl)
				itemNo = itemNo + 1
				starControl = constellationControl:GetNamedChild("StarControl" .. itemNo)
			end
		end
	end
end

local subIdToQuality = {}

local function GetEnchantQuality(itemLink)	-- From Enchanted Quality (Rhyono, votan)

	local itemId, itemIdSub, enchantSub = itemLink:match("|H[^:]+:item:([^:]+):([^:]+):[^:]+:[^:]+:([^:]+):")
	if not itemId then return 0 end

	enchantSub = tonumber(enchantSub)

	if enchantSub == 0 and not IsItemLinkCrafted(itemLink) then

		local hasSet = GetItemLinkSetInfo(itemLink, false)
		if hasSet then enchantSub = tonumber(itemIdSub) end -- For non-crafted sets, the "built-in" enchantment has the same quality as the item itself

	end

	if enchantSub > 0 then

		local quality = subIdToQuality[enchantSub]

		if not quality then

			-- Create a fake itemLink to get the quality from built-in function
			local itemLink = string.format("|H1:item:%i:%i:50:0:0:0:0:0:0:0:0:0:0:0:0:1:1:0:0:10000:0|h|h", itemId, enchantSub)
			quality = GetItemLinkQuality(itemLink)
			subIdToQuality[enchantSub] = quality

		end

		return quality
	end

	return 0
end

local function updateGearInfoPanel(panel)
	if fightData == nil then return end

	local charData = fightData.charData
	if charData == nil then return end

	local equipdata = charData and charData.equip or {}

	local poison1 = equipdata[EQUIP_SLOT_POISON]
	local poison2 = equipdata[EQUIP_SLOT_BACKUP_POISON]

	for i, slotData in ipairs(equipslots) do

		local slot = slotData[1]
		local texture = slotData[2]

		local equipline = panel:GetNamedChild("EquipLine" .. i)
		local label = equipline:GetNamedChild("ItemLink")
		local icon = equipline:GetNamedChild("Icon")
		local icon2 = equipline:GetNamedChild("Icon2")	-- textures are added twice since icons are so low in contrast
		local trait = equipline:GetNamedChild("Trait")
		local enchant = equipline:GetNamedChild("Enchant")

		local item = equipdata[slot] or ""

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

		local enchantString, enchantDescription
		local enchantColor = {1, 1, 1, 1}

		if (slot == EQUIP_SLOT_MAIN_HAND or slot == EQUIP_SLOT_OFF_HAND) and poison1:len() > 0 then

			enchantString = poison1
			enchant.itemLink = poison1

		elseif (slot == EQUIP_SLOT_BACKUP_MAIN or slot == EQUIP_SLOT_BACKUP_OFF) and poison2:len() > 0 then

			enchantString = poison2
			enchant.itemLink = poison2

		else

			_, enchantString, enchantDescription = GetItemLinkEnchantInfo(item)
			enchantString = enchantString:gsub(GetString(SI_COMBAT_METRICS_ENCHANTMENT_TRIM), "")
			local enchantId = GetItemLinkAppliedEnchantId(item)
			enchant.enchantDescription = enchantDescription
			enchant.itemLink = ""
			local quality = GetEnchantQuality(item)
			enchantColor = {GetItemQualityColor(quality):UnpackRGBA()}

		end

		enchant:SetText(enchantString)
		enchant:SetColor(unpack(enchantColor))

		-- GetEnchantProcAbilityId(GetItemLinkAppliedEnchantId())
		-- GetItemLinkAppliedEnchantId

	end
end

local function valueOrder(t,a,b)
	return t[a] < t[b]
end

local function updateConsumablesPanelItem(control, data, childName)
	local numItems = NonContiguousCount(data)

	if numItems == 0 then
		control:SetHidden(true)
	else
		local num = 0
		for key, _ in CMX.spairs(data, valueOrder) do
			num = num + 1
			local label, texture
			if childName == "Mundus" then
				label = GetFormattedAbilityName(key)
				texture = GetFormattedAbilityIcon(key)
			elseif childName == "DrinkFood" then
				label = LC.GetFoodDrinkItemLinkFromAbilityId(key)
				texture = GetItemLinkIcon(label)
			else
				label = key
				texture = GetItemLinkIcon(key)
			end
			control:GetNamedChild("Name"..num):SetText(label)
			control:GetNamedChild("Icon"..num):SetTexture(texture)
			if num >= 2 then break end
		end

		local icon1 = control:GetNamedChild("Icon1")
		local iconSize = control:GetNamedChild("Icon2"):GetWidth()
		icon1:ClearAnchors()
		if numItems == 1 then
			icon1:SetDimensions(1.3*iconSize, 1.3*iconSize)
			icon1:SetAnchor(LEFT)
			control:GetNamedChild("Name2"):SetHidden(true)
			control:GetNamedChild("Icon2"):SetHidden(true)
		else
			icon1:SetDimensions(iconSize, iconSize)
			icon1:SetAnchor(TOPLEFT)
			control:GetNamedChild("Name2"):SetHidden(false)
			control:GetNamedChild("Icon2"):SetHidden(false)
		end
		control:SetHidden(false)
	end
end

local function updateConsumablesPanel(panel)
	local mundusControl = panel:GetNamedChild("Mundus")
	local drinksFoodsControl = panel:GetNamedChild("DrinkFood")
	local potionsControl = panel:GetNamedChild("Potions")

	if fightData == nil or fightData.calculated == nil or fightData.calculated.buildInfo == nil then
		mundusControl:SetHidden(true)
		drinksFoodsControl:SetHidden(true)
		potionsControl:SetHidden(true)
		return
	end

	local buildInfo = fightData.calculated.buildInfo
	updateConsumablesPanelItem(mundusControl, buildInfo.mundus, "Mundus")
	updateConsumablesPanelItem(drinksFoodsControl, buildInfo.drinkFood, "DrinkFood")
	updateConsumablesPanelItem(potionsControl, buildInfo.potions, "Potions")
end

local function updateSetupPanel(panel)
	if panel:IsHidden() then return end

	updateSkillsPanel(panel:GetNamedChild("SkillsPanel")) -- TODO: Rename
	updateChampionPointsPanel(panel:GetNamedChild("ChampionPoints")) -- TODO: Rename
	updateScribedSkillsPanel(panel:GetNamedChild("ScribedSkillsPanel"))
	updateGearInfoPanel(panel:GetNamedChild("GearPanel")) -- TODO: Rename
	updateConsumablesPanel(panel:GetNamedChild("ConsumablesPanel"))
end

local function updateFightReport(control, fightId)

	CMX.Log("UI", LOG_LEVEL_DEBUG, "Updating FightReport")

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
	local stringId = issaved and "updateFightListPanelSaved" or "updateFightListPanelRecent"
	em:UnregisterForUpdate(stringId)

	local scrollchild = GetControl(panel, "PanelScrollChild")
	local currentanchor = {TOPLEFT, scrollchild, TOPLEFT, 0, 1}

	local rowBaseName = scrollchild:GetName() .. "Row"

	if #data > panel.numItems then
		for i = panel.numItems+1, #data do
			CreateControlFromVirtual(rowBaseName, scrollchild, "CombatMetrics_FightlistRowTemplate", i)
			panel.numItems = i
			if GetGameTimeSeconds() - GetFrameTimeSeconds() > 0.015 then
				em:RegisterForUpdate(stringId, 50, function() updateFightListPanel(panel, data, issaved) end)
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
			local category = db.FightReport.category

			if category == "healingOut" or category == "healingIn" then

				activetime = zo_roundToNearest(fight.hpstime or 1, 0.1)

			else

				activetime = zo_roundToNearest(fight.dpstime or 1, 0.1)

			end

			local durationstring = string.format("%d:%04.1f", activetime/60, activetime%60)

			local DPSKey = DPSstrings[db.FightReport.category]
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

local function updateFightList(panel)	
	CMX.Log("UI", LOG_LEVEL_DEBUG, "Updating FightListPanel")
	
	if panel:IsHidden() then return end
	
	local recentPanel = panel:GetNamedChild("Recent")
	local savedPanel = panel:GetNamedChild("Saved")
	
	ResetBars(recentPanel)
	ResetBars(savedPanel)
	
	local label
	local category = db.FightReport.category

	if category == "healingOut" or category == "healingIn" then

		label = GetString(SI_COMBAT_METRICS_HPS)

	else

		label = GetString(SI_COMBAT_METRICS_DPS)

	end

	GetControl(recentPanel, "HeaderDPS"):SetText(label)
	GetControl(savedPanel, "HeaderDPS"):SetText(label)

	updateFightListPanel(recentPanel, CMX.lastfights, false)
	updateFightListPanel(savedPanel, SVHandler.GetFights(), true)
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

	local damage, groupDamage, unittime, name = 0, 0, 0, ""

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
	groupDamage = zo_max(damage, groupDamage)

	return damage, groupDamage, name, unittime
end

local function GetBossTargetDamage(data) -- Gets Damage done to bosses and counts enemy boss units.

	if not data.bossfight then return 0, 0, 0, nil, 0 end

	local totalBossDamage, bossDamage, bossUnits = 0, 0, 0
	local totalBossGroupDamage = 0
	local bossName
	local starttime
	local endtime

	for unitId, unit in pairs(data.units) do

		local totalUnitDamage = unit.damageOutTotal
		local totalUnitGroupDamage = unit.groupDamageOut

		if (unit.bossId ~= nil and totalUnitDamage>0) then

			totalBossDamage = totalBossDamage + totalUnitDamage
			totalBossGroupDamage = totalBossGroupDamage + totalUnitGroupDamage
			bossUnits = bossUnits + 1

			starttime = zo_min(starttime or unit.dpsstart or 0, unit.dpsstart or 0)
			endtime = zo_max(endtime or unit.dpsend or 0, unit.dpsend or 0)

			if totalUnitDamage > bossDamage then

				bossName = unit.name
				bossDamage = totalUnitDamage

			end
		end
	end

	if bossUnits == 0 then return 0, 0, 0, nil, 0 end

	local bossTime = (endtime - starttime)/1000
	bossTime = bossTime > 0 and bossTime or data.dpstime

	return bossUnits, totalBossDamage, totalBossGroupDamage, bossName, bossTime
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
			starttime = unit.dpsstart and zo_min(starttime or unit.dpsstart, unit.dpsstart) or starttime
			endtime = unit.dpsend and zo_max(endtime or unit.dpsend, unit.dpsend) or endtime

			if totalUnitDamage > bossDamage then

				bossName = unit.name
				bossDamage = totalUnitDamage

			end

		end
	end

	local damageTime = starttime and endtime and (endtime - starttime)/1000 or 0
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
			starttime = zo_min(starttime or unit.hpsstart or 0, unit.hpsstart or 0)
			endtime = zo_max(endtime or unit.hpsend or 0, unit.hpsend or 0)

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

	local channel = db.autoselectchatchannel == true and (IsUnitGrouped('player') and CHAT_CHANNEL_PARTY or CHAT_CHANNEL_SAY) or nil

	-- Log output to chat

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
	local bossUnits, bossDamage, _, bossName, bossTime = GetBossTargetDamage(data)
	local singleDamage, _, _, singleTime = GetSingleTargetDamage(data)

	dpstime = zo_roundToNearest(dpstime, 0.1)
	singleTime = zo_roundToNearest(singleTime, 0.1)

	name = zo_strformat(SI_UNIT_NAME, (not unitSelection) and bossName or name)

	local bossDamage = data.bossfight and bossDamage or singleDamage
	local bossTime = zo_roundToNearest(data.bossfight and bossTime or singleTime, 0.1)

	local totalDPSString = ZO_CommaDelimitNumber(zo_floor(data.DPSOut))
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
		local totalHPSString = ZO_CommaDelimitNumber(zo_floor(healing / healTime))

		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTSELECTIONHPS_FORMAT), name, units, totalHPSString, totalHealingString, timeString)

	elseif units == 1 or mode == CMX_POSTTOCHAT_MODE_SINGLE then

		local damage = mode == CMX_POSTTOCHAT_MODE_SELECTED_UNIT and damage or singleDamage
		local damageTime = mode == CMX_POSTTOCHAT_MODE_SELECTED_UNIT and dpstime or singleTime

		local singleDPSString = ZO_CommaDelimitNumber(zo_floor(damage / damageTime))
		local singleDamageString = ZO_CommaDelimitNumber(damage)
		local timeString = string.format("%d:%04.1f", damageTime/60, damageTime%60)

		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTDPS_FORMAT), name, singleDPSString, singleDamageString, timeString)

	elseif bossUnits > 0 and mode == CMX_POSTTOCHAT_MODE_SMART then

		local bosses = bossUnits > 1 and string.format(" (+%d)", (bossUnits-1) )  or ""
		local bossTimeString = string.format("%d:%04.1f", bossTime/60, bossTime%60)

		local bossDPSString = ZO_CommaDelimitNumber(zo_floor(bossDamage / bossTime))
		local bossDamageString = ZO_CommaDelimitNumber(bossDamage)

		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTSMARTDPS_FORMAT), name, bosses, bossDPSString, bossDamageString, bossTimeString)

	elseif units > 1 and (mode == CMX_POSTTOCHAT_MODE_MULTI or mode == CMX_POSTTOCHAT_MODE_SMART) then

		local timeString = string.format("%d:%04.1f", dpstime/60, dpstime%60)

		local totalDPSString = ZO_CommaDelimitNumber(zo_floor(data.DPSOut))
		local totalDamageString = ZO_CommaDelimitNumber(damage)

		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTMULTIDPS_FORMAT), name, units-1, totalDPSString, totalDamageString, timeString)

	elseif mode == CMX_POSTTOCHAT_MODE_SINGLEANDMULTI then

		local bossString = bossUnits > 1 and string.format("%s (+%d)", GetString(SI_COMBAT_METRICS_BOSS_DPS), bossUnits-1) or bossUnits == 1 and GetString(SI_COMBAT_METRICS_BOSS_DPS) or GetString(SI_COMBAT_METRICS_DPS)
		local timeString = string.format("%d:%04.1f", dpstime/60, dpstime%60)
		local bossTimeString = string.format("%d:%04.1f", bossTime/60, bossTime%60)

		local bossDPSString = ZO_CommaDelimitNumber(zo_floor(bossDamage / bossTime))
		local bossDamageString = ZO_CommaDelimitNumber(bossDamage)

		local totalDPSString = ZO_CommaDelimitNumber(zo_floor(data.DPSOut))
		local totalDamageString = ZO_CommaDelimitNumber(damage)

		local stringA = zo_strformat(GetString(SI_COMBAT_METRICS_POSTALLDPS_FORMAT_A), name, units-1, totalDPSString, totalDamageString, timeString)
		local stringB = zo_strformat(GetString(SI_COMBAT_METRICS_POSTALLDPS_FORMAT_B), bossString, bossDPSString, bossDamageString, bossTimeString)

		output = string.format("%s, %s", stringA, stringB)

	elseif mode == CMX_POSTTOCHAT_MODE_SELECTION or mode == CMX_POSTTOCHAT_MODE_SELECTED_UNITNAME then

		if not unitSelection then return end

		local extraUnits = units > 1 and mode == CMX_POSTTOCHAT_MODE_SELECTED_UNITNAME and string.format(" (x%d)", units )
			or units > 1 and string.format(" (+%d)", (units-1) )
			or ""

		local DPSString = ZO_CommaDelimitNumber(zo_floor(damage / dpstime))
		local DamageString = ZO_CommaDelimitNumber(damage)
		local timeString = string.format("%d:%04.1f", dpstime/60, dpstime%60)

		output = zo_strformat(GetString(SI_COMBAT_METRICS_POSTSELECTIONDPS_FORMAT), name, extraUnits, DPSString, DamageString, timeString)

	end

	-- Determine appropriate channel

	local channel = db.autoselectchatchannel == false and "" or IsUnitGrouped('player') and "/p " or "/say "

	-- Log output to chat

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


local function toggleFightReport()

	if not SCENE_MANAGER:IsShowing("CMX_REPORT_SCENE") then

		CombatMetrics_Report_DonateDialog:SetHidden(true)
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
		control:SetDrawTier(2)
	else
		control:SetEdgeColor(1,1,1,0)
		control:SetCenterColor(1,1,1,0)
		control:SetDrawTier(0)

		if lastResize == nil then return end

		local scale, newpos = unpack(lastResize)
		local parent = control:GetParent()

		db[parent:GetName()] = newpos

		parent:ClearAnchors()
		parent:SetAnchor(CENTER, nil , TOPLEFT, newpos.x, newpos.y)
		parent:Resize(scale)
	end
end

function CMX.NewSize(control, newLeft, newTop, newRight, newBottom, oldLeft, oldTop, oldRight, oldBottom)

	if control.sizes == nil or control:IsHidden() then return end

	local baseWidth, baseHeight = unpack(control.sizes)

	local newHeight = newBottom - newTop
	local newWidth = newRight - newLeft

	local oldHeight = oldBottom - oldTop
	local oldWidth = oldRight - oldLeft

	local heightChange = (newHeight-oldHeight)/oldHeight
	local widthChange = (newWidth-oldWidth)/oldWidth

	local newscale

	if zo_abs(heightChange) > zo_abs(widthChange) then

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

		if control.sizes == nil and control.anchors == nil then return end

		local width, height = unpack(control.sizes)

		local maxwidth, maxheight = GuiRoot:GetDimensions()

		scale = zo_min(zo_max(scale or 1, 0.5), 3, maxwidth/width, maxheight/height)

		db.FightReport.scale = scale

		if width and control:GetResizeToFitDescendents() == false then control:SetWidth(width*scale) end
		if height and control:GetResizeToFitDescendents() == false then control:SetHeight(height*scale) end

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

	function fightReport:Resize(scale)

		resize(fightReport, scale)

		if not fightReport:IsHidden() then fightReport:Update() end

	end

	-- assign update functions for panels

	fightReport.Update = updateFightReport
	fightReport.Toggle = toggleFightReport

	local titlePanel = fightReport:GetNamedChild("_Title")
	titlePanel.Update = updateTitlePanel

	local mainPanel = fightReport:GetNamedChild("_MainPanel")
	mainPanel.Update = updateMainPanel

		local combatStatsPanel = mainPanel:GetNamedChild("CombatStats")
		combatStatsPanel.Update = updateCombatStatsPanel
		mainPanel.active = combatStatsPanel

		local playerStatsPanel = combatStatsPanel:GetNamedChild("PlayerStats")
		playerStatsPanel.Update = updatePlayerStatsPanel

		local playerStatsButton = playerStatsPanel:GetNamedChild("SelectRow"):GetNamedChild(maxStat())
		CMX.UpdateAttackStatsSelector(playerStatsButton) -- TODO: Unify stats window -> this button becomes obsolete

		local combatLogPanel = mainPanel:GetNamedChild("CombatLog")
		combatLogPanel.Update = updateCombatLog

		local graphPanel = mainPanel:GetNamedChild("Graph")
		graphPanel.Update = updateGraphPanel

			local plotToolBar = graphPanel:GetNamedChild("Toolbar")
			initPlotToolbar(plotToolBar)

			local plotWindow = graphPanel:GetNamedChild("PlotWindow")
			initPlotWindow(plotWindow)

	local setupPanel = fightReport:GetNamedChild("_SetupPanel")
	setupPanel.Update = updateSetupPanel

	local rightPanel = fightReport:GetNamedChild("_BuffPanel")
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

	local selectorButtons = fightReport:GetNamedChild("_MenuBar")
	selectorButtons.Update = updateSelectorButtons
	initSelectorButtons(selectorButtons)

	fightReport:Resize(db.FightReport.scale)

	local left = selectorButtons:GetLeft()

	if left < 0 then

		fightReport:ClearAnchors()
		fightReport:SetAnchor(CENTER, nil , TOPLEFT, pos.x - left, pos.y)

	end
end



function CMX.InitializeUI()
	initFightReport()
end