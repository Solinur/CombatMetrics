local CMX = CombatMetrics
local CMXint = CMX.internal
local util = CMXint.util
local ui = CMXint.ui
local logger

local ValidRaids = {

	[7] = true, -- vHoF
	[8] = true, -- vAS
	[9] = true, -- vCR
	[12] = true, -- vSS

}


local function initCategoryButtons(MenuPanel)
	local categoryButtons = {}
	local i = 1
	local anchorControl = MenuPanel.control

	local function onMouseUp(button)
		MenuPanel:SelectCategory(button)
	end

	local function initCategoryButton(category, texture, color, tooltip)
		local button = CreateControlFromVirtual("CombatMetricsReport_MenuCategoryButton", MenuPanel.control,
			"CombatMetrics_MenuButton", i)
		---@cast button TextureControl

		button:SetTexture(texture)
		button:SetColor(ZO_ColorDef.HexToFloats(color))
		local anchorSide = i == 1 and TOP or BOTTOM
		local offset = i == 1 and 0 or 4
		button:SetAnchor(TOP, anchorControl, anchorSide, nil, offset)
		button.tooltip = tooltip
		button.category = category
		button:SetHandler("OnMouseUp", onMouseUp, "CMX")
		anchorControl = button
		categoryButtons[category] = button

		i = i + 1
	end

	-- initCategoryButton("damageOut", "/esoui/art/icons/heraldrycrests_weapon_axe_02.dds", "FFFFCCCC",
	initCategoryButton("damageOut", "/EsoUI/Art/LFG/Gamepad/LFG_roleIcon_dps.dds", "FFFFCCCC",
		SI_COMBAT_METRICS_DAMAGE_CAUSED)
	initCategoryButton("healingOut", "/EsoUI/Art/LFG/Gamepad/LFG_roleIcon_healer.dds", "FFCCFFCC",
		SI_COMBAT_METRICS_HEALING_DONE)
	-- initCategoryButton("damageIn", "/esoui/art/icons/heraldrycrests_weapon_shield_01.dds", "FFCCCCFF",
	initCategoryButton("damageIn", "/EsoUI/Art/LFG/Gamepad/LFG_roleIcon_tank.dds", "FFCCCCFF",
		SI_COMBAT_METRICS_DAMAGE_CAUSED)
	initCategoryButton("healingIn", "/esoui/art/hud/gamepad/gp_radialicon_invitegroup_down.dds", "FFFFFFCC",
		SI_COMBAT_METRICS_HEALING_RECEIVED)

	MenuPanel.categoryButtons = categoryButtons
end

local function initSceneButtons(MenuPanel)
	local sceneButtons = {}
	local i = 1
	local anchorControl = MenuPanel.categoryButtons.healingIn

	local function onMouseUp(button)
		MenuPanel:SelectScene(button)
	end

	local function initSceneButton(scene, texture, tooltip)
		local button = CreateControlFromVirtual("CombatMetricsReport_MenuSceneButton", MenuPanel.control,
			"CombatMetrics_MenuButton", i)
		---@cast button TextureControl

		button:SetTexture(texture)
		local offset = i == 1 and 26 or 4
		button:SetAnchor(TOP, anchorControl, BOTTOM, nil, offset)
		button.tooltip = tooltip
		button.category = scene
		button:SetHandler("OnMouseUp", onMouseUp, "CMX")
		anchorControl = button
		sceneButtons[scene] = button

		i = i + 1
	end

	initSceneButton("fightStats", "esoui/art/menubar/gamepad/gp_playermenu_icon_skills.dds", SI_COMBAT_METRICS_TOGGLE_FIGHTSTATS)
	initSceneButton("combatLog", "esoui/art/guild/gamepad/gp_guild_menuicon_roster.dds", SI_COMBAT_METRICS_TOGGLE_COMBAT_LOG)
	initSceneButton("graph", "esoui/art/treeicons/gamepad/gp_tutorial_idexicon_charprogression.dds", SI_COMBAT_METRICS_TOGGLE_GRAPH)
	initSceneButton("info", "esoui/art/menubar/gamepad/gp_playermenu_icon_tutorial.dds", SI_COMBAT_METRICS_TOGGLE_INFO)

	MenuPanel.sceneButtons = sceneButtons
end


local function initSettingsButton(MenuPanel)
	local button = CreateControlFromVirtual("CombatMetricsReport_MenuSettingsButton", MenuPanel.control, "CombatMetrics_MenuButton")
	---@cast button TextureControl

	local function toggleShowIds()
		CMXint.settings.showDebugIds = not CMXint.settings.showDebugIds
		CombatMetricsReport:Update()
	end

	local function toggleShowPets()
		CMXint.settings.fightReport.showPets = not CMXint.settings.fightReport.showPets
		CombatMetricsReport:Update()
	end

	local function toggleOverhealMode()
		CMX.showOverHeal = not CMX.showOverHeal
		CombatMetricsReport:Update()
	end

	-- local function postSingleDPS()
	-- 	CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SINGLE, currentFight)
	-- end

	-- local function postSmartDPS()
	-- 	CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SMART, currentFight)
	-- end

	-- local function postMultiDPS()
	-- 	CMX.PosttoChat(CMX_POSTTOCHAT_MODE_MULTI, currentFight)
	-- end

	-- local function postAllDPS()
	-- 	CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SINGLEANDMULTI, currentFight)
	-- end

	-- local function postSelectionDPS()
	-- 	CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SELECTION, currentFight)
	-- end

	-- local function postHPS()
	-- 	CMX.PosttoChat(CMX_POSTTOCHAT_MODE_HEALING, currentFight)
	-- end

	-- local function postSelectionHPS()
	-- 	CMX.PosttoChat(CMX_POSTTOCHAT_MODE_SELECTION_HEALING, currentFight)
	-- end

	local function onMouseUp(button, _, upInside)
		if not upInside then return end
		local selections = ui.selections

		local showIdString = CMXint.settings.showDebugIds and SI_COMBAT_METRICS_HIDEIDS or SI_COMBAT_METRICS_SHOWIDS
		local showOverhealString = CMX.showOverHeal and SI_COMBAT_METRICS_HIDEOVERHEAL or SI_COMBAT_METRICS_SHOWOVERHEAL
		local showPetString = CMXint.settings.fightReport.showPets and SI_COMBAT_METRICS_MENU_HIDEPETS or
		SI_COMBAT_METRICS_MENU_SHOWPETS_NAME

		-- local postoptions = {}

		-- table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTSINGLEDPS), callback = postSingleDPS})

		-- local fight = CMX.lastfights[currentFight]

		-- if fight and fight.bossfight == true then
		-- 	table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTSMARTDPS), callback = postSmartDPS})
		-- end

		-- table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTMULTIDPS), callback = postMultiDPS})
		-- table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTALLDPS), callback = postAllDPS})

		-- local category = CMXint.settings.fightReport.category

		-- if category == "damageOut" and selections.unit[category] then
		-- 	table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTSELECTIONDPS), callback = postSelectionDPS})
		-- end

		-- table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTHPS), callback = postHPS})

		-- if category == "healingOut" and selections.unit[category] then
		-- 	table.insert(postoptions, {label = GetString(SI_COMBAT_METRICS_POSTSELECTIONHPS), callback = postSelectionHPS})
		-- end

		ClearMenu()

		AddCustomMenuItem(GetString(showIdString), toggleShowIds)
		AddCustomMenuItem(GetString(showOverhealString), toggleOverhealMode)
		AddCustomMenuItem(GetString(showPetString), toggleShowPets)
		-- AddCustomSubMenuItem(GetString(SI_COMBAT_METRICS_POSTDPS), postoptions)
		-- AddCustomMenuItem(GetString(SI_COMBAT_METRICS_SETTINGS), CMX.OpenSettings)

		ShowMenu(button)
		AnchorMenu(button)
	end

	button:SetTexture("esoui/art/tutorial/gamepad/gp_playermenu_icon_settings.dds")
	button:SetColor(ZO_ColorDef.HexToFloats("FFFFFFFF"))
	button:SetAnchor(TOP, MenuPanel.sceneButtons.info, BOTTOM, nil, 26)
	button.tooltip = SI_COMBAT_METRICS_TOGGLE_SETTINGS
	button:SetHandler("OnMouseUp", onMouseUp, "CMX")

	MenuPanel.settingsButton = button
end

local function initFeedbackButton(MenuPanel)
	local button = CreateControlFromVirtual("CombatMetricsReport_MenuFeedbackButton", MenuPanel.control, "CombatMetrics_MenuButton")
	---@cast button TextureControl

	local sendGold

	local function PrefillMail()
		local isDonation = sendGold and sendGold > 0
		local headerString = GetString(isDonation and SI_COMBAT_METRICS_DONATE_GOLD_HEADER or
		SI_COMBAT_METRICS_FEEDBACK_MAIL_HEADER)

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
		zo_callLater(PrefillMail, 250) -- TODO: Bind to onShowEvent ?
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
		zo_callLater(PrefillMail, 250)
	end

	local function GotoESOUIDonation()
		RequestOpenUnsafeURL(GetString(SI_COMBAT_METRICS_DONATE_ESOUIURL))
	end

	local function onMouseUp(button, _, upInside)
		if not upInside then return end
		ClearMenu()

		local isEUServer = GetWorldName() == "EU Megaserver"
		local stringFormatEU = isEUServer and "<<1>>" or SI_COMBAT_METRICS_FEEDBACK_EUONLY_FORMAT

		local feedbackSubItems = {
			{ label = ZO_CachedStrFormat(stringFormatEU, GetString(SI_COMBAT_METRICS_FEEDBACK_MAIL)), callback = SendIngameMail, disabled = not isEUServer },
			{ label = GetString(SI_COMBAT_METRICS_FEEDBACK_ESOUI), callback = GotoESOUI },
			{ label = GetString(SI_COMBAT_METRICS_FEEDBACK_GITHUB), callback = GotoGithub },
			{ label = GetString(SI_COMBAT_METRICS_FEEDBACK_DISCORD), callback = GotoDiscord },
		}

		local donationSubItems = {
			{ label = ZO_CachedStrFormat(stringFormatEU, GetString(SI_COMBAT_METRICS_DONATE_GOLD)), callback = DonateGold, disabled = not isEUServer },
			{ label = GetString(SI_COMBAT_METRICS_DONATE_ESOUI), callback = GotoESOUIDonation },
		}

		AddCustomSubMenuItem(GetString(SI_COMBAT_METRICS_FEEDBACK_SEND), feedbackSubItems, nil, nil, nil, 2)
		AddCustomSubMenuItem(GetString(SI_COMBAT_METRICS_DONATE), donationSubItems, nil, nil, nil, 2)

		ShowMenu(button)
		AnchorMenu(button)
	end

	button:SetTexture("CombatMetrics/icons/addonlogo.dds")
	button:SetColor(ZO_ColorDef.HexToFloats("FFFFC52A"))
	button:SetAnchor(TOP, MenuPanel.settingsButton, BOTTOM, nil, 8)
	button.tooltip = SI_COMBAT_METRICS_FEEDBACK
	button:SetHandler("OnMouseUp", onMouseUp, "CMX")

	MenuPanel.feedbackButton = button
end


local function initNotificationButton(MenuPanel)
	local button = CreateControlFromVirtual("CombatMetricsReport_MenuNotificationButton", MenuPanel.control, "CombatMetrics_MenuButton")
	---@cast button TextureControl

	local function ShowGuildInfo()
		GUILD_BROWSER_GUILD_INFO_KEYBOARD:SetGuildToShow(64745)
		MAIN_MENU_KEYBOARD:ShowSceneGroup("guildsSceneGroup", "linkGuildInfoKeyboard")
		GUILD_BROWSER_GUILD_INFO_KEYBOARD.closeCallback = CombatMetricsReport.Toggle
	end

	local function NotificationRead()
		CMXint.settings.notificationRead = CMXint.settings.currentNotificationVersion
		CombatMetricsReport:Update()
	end

	local function DisableNotifications()
		CMXint.settings.notificationRead = CMXint.settings.currentNotificationVersion
		CMXint.settings.notificationAllowed = false
		CombatMetricsReport:Update()
	end

	local function onMouseUp(button, _, upInside)
		if not upInside then return end
		ClearMenu()

		AddCustomMenuItem(GetString(SI_COMBAT_METRICS_NOTIFICATION_GUILD), ShowGuildInfo)
		AddCustomMenuItem(GetString(SI_COMBAT_METRICS_NOTIFICATION_ACCEPT), NotificationRead)
		AddCustomMenuItem(GetString(SI_COMBAT_METRICS_NOTIFICATION_DISCARD), DisableNotifications)

		ShowMenu(button)
		AnchorMenu(button)
	end

	button:SetTexture("esoui/art/mainmenu/menubar_notifications_down.dds")
	button:SetColor(ZO_ColorDef.HexToFloats("FFFFFFFF"))
	button:SetAnchor(TOP, MenuPanel.feedbackButton, BOTTOM, nil, 8)
	button.tooltip = SI_COMBAT_METRICS_NOTIFICATION
	button:SetHandler("OnMouseUp", onMouseUp, "CMX")

	MenuPanel.notificationButton = button
end

local function initFightNavButtons(MenuPanel)
	local navButtons = {}
	local i = 1
	local anchorControl = MenuPanel.notificationButton

	local function SelectPreviousFight()
		CMXint.fightData:SelectPreviousFight()
	end

	local function SelectNextFight()
		CMXint.fightData:SelectNextFight()
	end

	local function SelectMostRecentFight()
		CMXint.fightData:SelectMostRecentFight()
	end

	local function LoadFight()
		MenuPanel.fightReport:SelectScene("fightList")
	end

	local function SaveFight(_, _, _, _, _, shiftkey)
		CMXint.fightData:SaveFight(shiftkey)
	end

	local function DeleteFight()
		CMXint.fightData:RemoveCurrentFight()
	end

	local function initNavButton(name, texture, tooltip, func)
		local button = CreateControlFromVirtual("CombatMetricsReport_MenuFightNavigationButton", MenuPanel.control,
			"CombatMetrics_FightNavigationButton", i)
		---@cast button ButtonControl

		button:SetNormalTexture(	texture .. "up.dds")
		button:SetPressedTexture(	texture .. "down.dds")
		button:SetMouseOverTexture(	texture .. "over.dds")
		button:SetDisabledTexture(	texture .. "disabled.dds")
		local offset = i == 1 and 26 or 4
		button:SetAnchor(TOP, anchorControl, BOTTOM, nil, offset)
		button.tooltip = tooltip
		button.name = name
		button:SetHandler("OnMouseUp", func, "CMX")
		button:SetState(BSTATE_NORMAL, false)
		anchorControl = button
		
		navButtons[name] = button
		i = i + 1
	end

	initNavButton("previous", "CombatMetrics/icons/leftarrow", 	SI_COMBAT_METRICS_PREVIOUS_FIGHT, 								SelectPreviousFight)
	initNavButton("next", 	"CombatMetrics/icons/rightarrow", 	SI_COMBAT_METRICS_NEXT_FIGHT, 									SelectNextFight)
	initNavButton("last", 	"CombatMetrics/icons/endarrow", 	SI_COMBAT_METRICS_MOST_RECENT_FIGHT, 							SelectMostRecentFight)
	initNavButton("load", 	"CombatMetrics/icons/loadicon", 	SI_COMBAT_METRICS_LOAD_FIGHT, 									LoadFight)
	initNavButton("save", 	"CombatMetrics/icons/saveicon", 	{SI_COMBAT_METRICS_SAVE_FIGHT, SI_COMBAT_METRICS_SAVE_FIGHT2}, SaveFight)
	initNavButton("delete", 	"CombatMetrics/icons/deleteicon2", SI_COMBAT_METRICS_DELETE_FIGHT, 								DeleteFight)

	MenuPanel.navButtons = navButtons
end

function CMXint.InitializeMenuPanel(control)
	local MenuPanel = CMX.internal.PanelObject:New(control, "menu")
	SVHandler = CMXint.SVHandler

	function MenuPanel:Update()
		local notificationSettings = CMXint.settings.notification
		notificationSettings.version = 1

		local date = GetDate()

		local isMe = GetDisplayName() == "@Solinur"
		local isGerman = GetCVar("Language.2") == "de"
		local isEUServer = GetWorldName() == "EU Megaserver"
		local isNotificationAllowed = notificationSettings.enabled and
		notificationSettings.version > notificationSettings.versionSeen
		local isVeteranRaid = ValidRaids[GetCurrentParticipatingRaidId()] == true
		local isWithinAllowedTime = date >= 20200417 and date <= 20200423

		local show = notificationSettings.force or isMe or
		(isGerman and isEUServer and isNotificationAllowed and isVeteranRaid and isWithinAllowedTime)

		control:GetNamedChild("NotificationButton"):SetHidden(not show)

		self:UpdateButtonStates()
	end

	function MenuPanel:UpdateButtonStates()
		local fightData = CMXint.fightData
		local currentIndex = fightData.currentIndex or 0
		local maxIndex = fightData:GetNumFights()
		local navButtons = MenuPanel.navButtons
		local fight = fightData.data

		local previous = currentIndex > 1
		navButtons.previous:SetState(previous and BSTATE_NORMAL or BSTATE_DISABLED, not previous)

		local next = currentIndex < maxIndex
		navButtons.next:SetState(next and BSTATE_NORMAL or BSTATE_DISABLED, not next)
		navButtons.last:SetState(next and BSTATE_NORMAL or BSTATE_DISABLED, not next)

		local load = SVHandler ~= nil and SVHandler.GetNumFights() > 0
		navButtons.load:SetState(load and BSTATE_NORMAL or BSTATE_DISABLED, not load)

		local save = fight ~= nil and not util.searchtable(SVHandler.GetFights(), "date", fight.date) -- TODO: Make function of SVHandler to check for already saved fights
		navButtons.save:SetState(save and BSTATE_NORMAL or BSTATE_DISABLED, not save)

		local delete = fight ~= nil
		navButtons.delete:SetState(delete and BSTATE_NORMAL or BSTATE_DISABLED, not delete)
	end

	function MenuPanel:SelectCategory(selectedButton)
		for _, button in pairs(self.categoryButtons) do
			local r, g, b, _ = button:GetColor()
			local a = button == selectedButton and 1 or 0.2
			button:SetColor(r, g, b, a)
		end

		local oldCategory = self.settings.category
		local newCategory = selectedButton.category

		if oldCategory ~= newCategory then
			self.settings.category = newCategory
			self.fightReport:Update()
		end
	end

	function MenuPanel:SelectScene(selectedButton)
		local newScene
		for sceneName, button in pairs(self.sceneButtons) do
			local a = .2
			if button == selectedButton then
				a = 1
				newScene = sceneName
			end
			button:SetColor(1, 1, 1, a)
		end
		self.fightReport:SelectScene(newScene)
	end

	initCategoryButtons(MenuPanel)
	initSceneButtons(MenuPanel)
	initSettingsButton(MenuPanel)
	initFeedbackButton(MenuPanel)
	initNotificationButton(MenuPanel)
	initFightNavButtons(MenuPanel)
end

local isFileInitialized = false
function CMXint.InitializeMenu()
	if isFileInitialized == true then return false end
	logger = util.initSublogger("Menu")

	MenuPanel = ui:GetPanel("menu")

	MenuPanel:SelectScene(MenuPanel.sceneButtons.fightStats)
	MenuPanel:SelectCategory(MenuPanel.categoryButtons.damageOut)

	isFileInitialized = true
	return true
end
