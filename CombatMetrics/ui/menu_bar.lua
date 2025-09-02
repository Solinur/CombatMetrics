local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger
local SVHandler

local ValidRaids = {

	[7] = true, -- vHoF
	[8] = true, -- vAS
	[9] = true, -- vCR
	[12] = true, -- vSS

}


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
		CMXint.panels["FightList"]:Update()
	end
end

function NavButtonFunctions.save(control, _, _, _, _, shiftkey )
	if control:GetState() == BSTATE_DISABLED then
		return
	else
		local numFights = SVHandler.GetNumFights()
		local lastsaved = SVHandler.GetFight(numFights)
		if lastsaved ~= nil and lastsaved.date == fightData.date then return end -- bail out if fight is already saved

		local spaceLeft = CMXint.settings.maxSavedFights - numFights
		assert(spaceLeft > 0, zo_strformat(SI_COMBAT_METRICS_SAVEDFIGHTS_FULL, 1-spaceLeft))

		SVHandler.Save(fightData, shiftkey)
		CombatMetrics_Report:Update()
	end
end

function NavButtonFunctions.delete(control)
	if control:GetState() == BSTATE_DISABLED then
		return
	else
		table.remove(CMX.lastfights, currentFight)
		CMXint.ClearSelections()
		if #CMX.lastfights == 0 then CombatMetrics_Report:Update() else CombatMetrics_Report:Update(zo_min(currentFight, #CMX.lastfights)) end
	end
end

function CMX.InitNavButtons(rowControl)
	for i=1, rowControl:GetNumChildren() do
		local child = rowControl:GetChild(i)
		if child then child:SetHandler( "OnMouseUp", NavButtonFunctions[child.func]) end
	end
end

do
	local function toggleShowIds()
		CMXint.settings.showDebugIds = not CMXint.settings.showDebugIds
		CombatMetrics_Report:Update()
	end

	local function toggleShowPets()
		CMXint.settings.FightReport.showPets = not CMXint.settings.FightReport.showPets
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
		local selections = CMXint.selections

		local showIdString = CMXint.settings.showDebugIds and SI_COMBAT_METRICS_HIDEIDS or SI_COMBAT_METRICS_SHOWIDS
		local showOverhealString = CMX.showOverHeal and SI_COMBAT_METRICS_HIDEOVERHEAL or SI_COMBAT_METRICS_SHOWOVERHEAL
		local showPetString = CMXint.settings.FightReport.showPets and SI_COMBAT_METRICS_MENU_HIDEPETS or SI_COMBAT_METRICS_MENU_SHOWPETS_NAME
		local postoptions = {}

		table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTSINGLEDPS), callback = postSingleDPS})

		local fight = CMX.lastfights[currentFight]

		if fight and fight.bossfight == true then
			table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTSMARTDPS), callback = postSmartDPS})
		end

		table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTMULTIDPS), callback = postMultiDPS})
		table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTALLDPS), callback = postAllDPS})

		local category = CMXint.settings.FightReport.category

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
		CMXint.settings.NotificationRead = CMXint.settings.currentNotificationVersion
		CombatMetrics_Report:Update(currentFight)
	end

	local function DisableNotifications()
		CMXint.settings.NotificationRead = CMXint.settings.currentNotificationVersion
		CMXint.settings.NotificationAllowed = false
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


function CMXint.InitializeMenuPanel(control)
	local MenuPanel = CMX.internal.PanelObject:New(control, "menu")
	local category = MenuPanel.settings.category

	function MenuPanel:Update(fightData)
		local notificationSettings = CMXint.settings.Notification
		notificationSettings.version = 1

		local date = GetDate()

		local isMe = GetDisplayName() == "@Solinur"
		local isGerman = GetCVar("Language.2") == "de"
		local isEUServer = GetWorldName() == "EU Megaserver"
		local isNotInGuild = not IsPlayerInGuild(64745)
		local isNotificationAllowed = notificationSettings.enabled and notificationSettings.version > notificationSettings.versionSeen
		local isVeteranRaid = ValidRaids[GetCurrentParticipatingRaidId()] == true
		local isWithinAllowedTime = date >= 20200417 and date <= 20200423

		local show = notificationSettings.force or ((isGerman or isMe) and isEUServer and isNotificationAllowed and isVeteranRaid and isWithinAllowedTime)
		self.control:GetNamedChild("NotificationButton"):SetHidden(not show)
	end

	do -- Nav Buttons

		-- local NavButtons = self:GetNamedChild("NavigationRow")
		-- local fightId = CMXint.currentFight or 0

		-- local ButtonStates = {

		-- 	["previous"] = CMX.lastfights[fightId - 1] ~= nil,
		-- 	["next"]     = CMX.lastfights[fightId + 1] ~= nil,
		-- 	["last"]     = CMX.lastfights[fightId + 1] ~= nil,
		-- 	["load"]     = SVHandler ~= nil and SVHandler.GetNumFights() > 0,
		-- 	["save"]     = CMX.lastfights[fightId] ~= nil and
		-- 	not CMXf.searchtable(SVHandler.GetFights(), "date", fightData.date),
		-- 	["delete"]   = CMX.lastfights[fightId] ~= nil and #CMX.lastfights > 0 ~= nil
		-- }

		-- for i = 1, NavButtons:GetNumChildren() do
		-- 	local child = NavButtons:GetChild(i)
		-- 	local state = ButtonStates[child.func]

		-- 	child:SetState(state and BSTATE_NORMAL or BSTATE_DISABLED, not state)
		-- end


		-- TODO: rework using scenes

		-- local mainPanel = CombatMetrics_Report_MainPanel
		-- local rightPanel = CombatMetrics_Report_RightPanel
		-- local unitPanel = CombatMetrics_Report_UnitPanel
		-- local abilityPanel = CombatMetrics_Report_AbilityPanel
		-- local setupPanel = CombatMetrics_Report_SetupPanel
		-- local graphPanel = CombatMetrics_Report_MainPanelGraph

		-- local isInfo = category == "Info"

		-- mainPanel:SetHidden(isInfo)
		-- rightPanel:SetHidden(isInfo)
		-- unitPanel:SetHidden(isInfo)
		-- abilityPanel:SetHidden(isInfo)
		-- setupPanel:SetHidden(not isInfo)

		-- local isGraph = category == "Graph"

		-- graphPanel:SetHidden(not isGraph)

		-- if not isInfo then
		-- 	local selected = mainPanel:GetNamedChild(category) -- Panel Content to show
		-- 	mainPanel.active = selected

		-- 	for i = 2, mainPanel:GetNumChildren() do
		-- 		local child = mainPanel:GetChild(i)
		-- 		child:SetHidden(child ~= selected) -- Hide all other panels except the selected panel
		-- 	end

		-- 	selected:Update()
		-- else
		-- 	setupPanel:Update()
		-- end
		
	end

	do -- Menu Buttons
		local function SelectCategory(button)
			local selectControl = button:GetParent()

			for i = 1, selectControl:GetNumChildren() do
				local child = selectControl:GetChild(i)

				if child and child.isMainCategory then
					local r, g, b, _ = child:GetColor()
					local a = child == button and 1 or .2
					child:SetColor(r, g, b, a)
				end
			end
			
			CMXint.settings.category = button.category
			if CMX and CMX.init then CombatMetrics_Report:Update(CMXint.currentFight) end
		end

		local function SelectMainPanel(button)
			local selectControl = button:GetParent()
			local category = button.category

			for i = 1, selectControl:GetNumChildren() do
				local child = selectControl:GetChild(i)

				if child and child.isSecondaryCategory then
					local a = child == button and 1 or .2
					child:SetColor(1, 1, 1, a)
				end
			end
		end

		for i = 1, control:GetNumChildren() do
			local button = control:GetChild(i)

			if button and button.isMainCategory then
				button:SetHandler( "OnMouseUp", SelectCategory)
				if button.category == category then SelectCategory(button) end
			elseif button and button.isSecondaryCategory then
				button:SetHandler( "OnMouseUp", SelectMainPanel)
			end

			SelectMainPanel(control:GetNamedChild("FightStatsButton"))
		end
	end
end

local isFileInitialized = false
function CMXint.InitializeMenu()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("Menu Bar")
	SVHandler = CMXint.SVHandler

    isFileInitialized = true
	return true
end