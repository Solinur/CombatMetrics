-- Menu bar panel: Buttons bar on the left for switching between fights and different data views (scenes).
---@class CMX
local CMX = CombatMetrics
---@class CMXint
local CMXint = CMX.internal
---@class CMXutil
local util = CMXint.util
---@type Logger
local logger
---@class CMXui
local ui = CMXint.ui
local cat = util.MainCategories

local function initCategoryButtons(MenuPanel)
	local buttons = {}
	local categoryButtons = {}
	local categoryOrder = {}

	local function onMouseUp(button)
		MenuPanel:SelectCategory(button.category)
	end

	local function initCategoryButton(category, texture, color, tooltip)
		local i = #buttons + 1
		local button = CreateControlFromVirtual(
			"CombatMetricsReport_MenuCategoryButton",
			MenuPanel.control,
			"CombatMetrics_MenuButton",
			i
		)
		---@cast button TextureControl

		button:SetTexture(texture)
		local r, g, b = ZO_ColorDef.HexToFloats(color)
		button["baseColor"] = { r, g, b }
		button:SetColor(r, g, b, 1)
		button["tooltip"] = tooltip
		button["category"] = category
		button["action"] = function()
			MenuPanel:SelectCategory(category)
		end
		---@diagnostic disable-next-line: missing-parameter
		button:SetHandler("OnMouseUp", onMouseUp, "CMX")

		buttons[i] = button
		categoryButtons[category] = button
		categoryOrder[i] = category
	end

	-- initCategoryButton("damageOut", "/esoui/art/icons/heraldrycrests_weapon_axe_02.dds", "FFFFCCCC",
	initCategoryButton(
		cat.CMX_CATEGORY_DAMAGE_DONE,
		"/EsoUI/Art/LFG/Gamepad/LFG_roleIcon_dps.dds",
		"FFFFCCCC",
		SI_COMBAT_METRICS_DAMAGE_DONE
	)
	initCategoryButton(
		cat.CMX_CATEGORY_HEALING_DONE,
		"/EsoUI/Art/LFG/Gamepad/LFG_roleIcon_healer.dds",
		"FFCCFFCC",
		SI_COMBAT_METRICS_HEALING_DONE
	)
	-- initCategoryButton("damageIn", "/esoui/art/icons/heraldrycrests_weapon_shield_01.dds", "FFCCCCFF",
	initCategoryButton(
		cat.CMX_CATEGORY_DAMAGE_RECEIVED,
		"/EsoUI/Art/LFG/Gamepad/LFG_roleIcon_tank.dds",
		"FFCCCCFF",
		SI_COMBAT_METRICS_DAMAGE_RECEIVED
	)
	initCategoryButton(
		cat.CMX_CATEGORY_HEALING_RECEIVED,
		"/esoui/art/hud/gamepad/gp_radialicon_invitegroup_down.dds",
		"FFFFFFCC",
		SI_COMBAT_METRICS_HEALING_RECEIVED
	)

	MenuPanel.categoryButtons = categoryButtons
	MenuPanel.categoryOrder = categoryOrder
	return buttons
end

local function initSceneButtons(MenuPanel)
	local buttons = {}
	local sceneButtons = {}
	local sceneOrder = {}

	local function onMouseUp(button)
		MenuPanel:SelectScene(button.scene)
	end

	local function initSceneButton(scene, texture, tooltip)
		local i = #buttons + 1
		local button = CreateControlFromVirtual(
			"CombatMetricsReport_MenuSceneButton",
			MenuPanel.control,
			"CombatMetrics_MenuButton",
			i
		)
		---@cast button TextureControl

		button:SetTexture(texture)
		button["tooltip"] = tooltip
		button["scene"] = scene
		button["action"] = function()
			MenuPanel:SelectScene(scene)
		end
		---@diagnostic disable-next-line: missing-parameter
		button:SetHandler("OnMouseUp", onMouseUp, "CMX")

		buttons[i] = button
		sceneButtons[scene] = button
		sceneOrder[i] = scene
	end

	initSceneButton(
		"fightStats",
		"esoui/art/menubar/gamepad/gp_playermenu_icon_skills.dds",
		SI_COMBAT_METRICS_TOGGLE_FIGHTSTATS
	)
	initSceneButton(
		"combatLog",
		"esoui/art/guild/gamepad/gp_guild_menuicon_roster.dds",
		SI_COMBAT_METRICS_TOGGLE_COMBAT_LOG
	)
	initSceneButton(
		"graph",
		"esoui/art/treeicons/gamepad/gp_tutorial_idexicon_charprogression.dds",
		SI_COMBAT_METRICS_TOGGLE_GRAPH
	)
	initSceneButton("info", "esoui/art/menubar/gamepad/gp_playermenu_icon_tutorial.dds", SI_COMBAT_METRICS_TOGGLE_INFO)

	MenuPanel.sceneButtons = sceneButtons
	MenuPanel.sceneOrder = sceneOrder
	return buttons
end

local function initSettingsButton(MenuPanel)
	local button = CreateControlFromVirtual(
		"CombatMetricsReport_MenuSettingsButton",
		MenuPanel.control,
		"CombatMetrics_MenuButton"
	)
	---@cast button TextureControl

	local function toggleShowIds()
		MenuPanel.settings.showDebugIds = not MenuPanel.settings.showDebugIds
		CombatMetricsReport:Update()
	end

	local function toggleShowPets()
		MenuPanel.settings.showPets = not MenuPanel.settings.showPets
		CombatMetricsReport:Update()
	end

	local function toggleOverhealMode()
		MenuPanel.settings.showOverHeal = not MenuPanel.settings.showOverHeal
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

	local function openMenu(button)
		local settings = CMXint.settings.fightReport

		local showIdString = settings.showDebugIds and SI_COMBAT_METRICS_HIDEIDS or SI_COMBAT_METRICS_SHOWIDS
		local showOverhealString = settings.showOverHeal and SI_COMBAT_METRICS_HIDEOVERHEAL
			or SI_COMBAT_METRICS_SHOWOVERHEAL
		local showPetString = settings.showPets and SI_COMBAT_METRICS_MENU_HIDEPETS
			or SI_COMBAT_METRICS_MENU_SHOWPETS_NAME

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

	local function onMouseUp(button, _, upInside)
		if upInside then
			openMenu(button)
		end
	end

	button:SetTexture("esoui/art/tutorial/gamepad/gp_playermenu_icon_settings.dds")
	button:SetColor(ZO_ColorDef.HexToFloats("FFFFFFFF"))
	button["tooltip"] = SI_COMBAT_METRICS_TOGGLE_SETTINGS
	button["action"] = function()
		openMenu(button)
	end
	---@diagnostic disable-next-line: missing-parameter
	button:SetHandler("OnMouseUp", onMouseUp, "CMX")

	return { button }
end

local function initFeedbackButton(MenuPanel)
	local button = CreateControlFromVirtual(
		"CombatMetricsReport_MenuFeedbackButton",
		MenuPanel.control,
		"CombatMetrics_MenuButton"
	)
	---@cast button TextureControl

	local sendGold

	local function PrefillMail()
		local isDonation = sendGold and sendGold > 0
		local headerString =
			GetString(isDonation and SI_COMBAT_METRICS_DONATE_GOLD_HEADER or SI_COMBAT_METRICS_FEEDBACK_MAIL_HEADER)

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
		SCENE_MANAGER:Show("mailSend")
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
		SCENE_MANAGER:Show("mailSend")
		zo_callLater(PrefillMail, 250)
	end

	local function GotoESOUIDonation()
		RequestOpenUnsafeURL(GetString(SI_COMBAT_METRICS_DONATE_ESOUIURL))
	end

	local function openMenu(button)
		ClearMenu()

		local isEUServer = GetWorldName() == "EU Megaserver"
		local stringFormatEU = isEUServer and "<<1>>" or SI_COMBAT_METRICS_FEEDBACK_EUONLY_FORMAT

		local feedbackSubItems = {
			{
				label = ZO_CachedStrFormat(stringFormatEU, GetString(SI_COMBAT_METRICS_FEEDBACK_MAIL)),
				callback = SendIngameMail,
				disabled = not isEUServer,
			},
			{ label = GetString(SI_COMBAT_METRICS_FEEDBACK_ESOUI), callback = GotoESOUI },
			{ label = GetString(SI_COMBAT_METRICS_FEEDBACK_GITHUB), callback = GotoGithub },
			{ label = GetString(SI_COMBAT_METRICS_FEEDBACK_DISCORD), callback = GotoDiscord },
		}

		local donationSubItems = {
			{
				label = ZO_CachedStrFormat(stringFormatEU, GetString(SI_COMBAT_METRICS_DONATE_GOLD)),
				callback = DonateGold,
				disabled = not isEUServer,
			},
			{ label = GetString(SI_COMBAT_METRICS_DONATE_ESOUI), callback = GotoESOUIDonation },
		}

		AddCustomSubMenuItem(GetString(SI_COMBAT_METRICS_FEEDBACK_SEND), feedbackSubItems, nil, nil, nil, 2)
		AddCustomSubMenuItem(GetString(SI_COMBAT_METRICS_DONATE), donationSubItems, nil, nil, nil, 2)

		ShowMenu(button)
		AnchorMenu(button)
	end

	-- TODO: point action at the Y menu in phase 2; ZO_Menu has no gamepad path.
	local function onMouseUp(button, _, upInside)
		if upInside then
			openMenu(button)
		end
	end

	button:SetTexture("CombatMetrics/icons/addonlogo.dds")
	button:SetColor(ZO_ColorDef.HexToFloats("FFFFC52A"))
	button["tooltip"] = SI_COMBAT_METRICS_FEEDBACK
	button["action"] = function()
		openMenu(button)
	end
	---@diagnostic disable-next-line: missing-parameter
	button:SetHandler("OnMouseUp", onMouseUp, "CMX")

	return { button }
end

local function initFightNavButtons(MenuPanel)
	local buttons = {}
	local navButtons = {}

	local function SelectPreviousFight()
		CMXint.FightData:SelectPreviousFight()
	end

	local function SelectNextFight()
		CMXint.FightData:SelectNextFight()
	end

	local function SelectMostRecentFight()
		CMXint.FightData:SelectMostRecentFight()
	end

	local function LoadFight()
		MenuPanel:SelectScene("fightList")
	end

	local function SaveFight(withLog)
		CMXint.FightData:SaveFight(withLog)
	end

	local function onSaveMouseUp(_, _, _, _, _, shiftkey)
		SaveFight(shiftkey)
	end

	local function SaveFightPlain()
		SaveFight(false)
	end

	local function DeleteFight()
		CMXint.FightData:RemoveCurrentFight()
	end

	---@param onMouseUp function? defaults to `action`
	local function initNavButton(name, texture, tooltip, action, onMouseUp)
		local i = #buttons + 1
		local button = CreateControlFromVirtual(
			"CombatMetricsReport_MenuFightNavigationButton",
			MenuPanel.control,
			"CombatMetrics_FightNavigationButton",
			i
		)
		---@cast button ButtonControl

		button:SetNormalTexture(texture .. "up.dds")
		button:SetPressedTexture(texture .. "down.dds")
		button:SetMouseOverTexture(texture .. "over.dds")
		button:SetDisabledTexture(texture .. "disabled.dds")
		button["tooltip"] = tooltip
		button["action"] = action
		---@diagnostic disable-next-line: missing-parameter
		button:SetHandler("OnMouseUp", onMouseUp or action, "CMX")
		button:SetState(BSTATE_NORMAL, false)

		buttons[i] = button
		navButtons[name] = button
	end

	initNavButton("previous", "CombatMetrics/icons/leftarrow", SI_COMBAT_METRICS_PREVIOUS_FIGHT, SelectPreviousFight)
	initNavButton("next", "CombatMetrics/icons/rightarrow", SI_COMBAT_METRICS_NEXT_FIGHT, SelectNextFight)
	initNavButton("last", "CombatMetrics/icons/endarrow", SI_COMBAT_METRICS_MOST_RECENT_FIGHT, SelectMostRecentFight)
	initNavButton("load", "CombatMetrics/icons/loadicon", SI_COMBAT_METRICS_LOAD_FIGHT, LoadFight)
	initNavButton(
		"save",
		"CombatMetrics/icons/saveicon",
		-- TODO: phrased for the mouse ("Click:" / "Shift+Click:"); the phase 2 focus area needs a
		-- gamepad wording, and the combat log variant does not exist there at all.
		{ SI_COMBAT_METRICS_SAVE_FIGHT, SI_COMBAT_METRICS_SAVE_FIGHT2 },
		SaveFightPlain,
		onSaveMouseUp
	)
	initNavButton("delete", "CombatMetrics/icons/deleteicon2", SI_COMBAT_METRICS_DELETE_FIGHT, DeleteFight)

	MenuPanel.navButtons = navButtons
	return buttons
end

local BUTTON_GAP = 4
local MENU_GROUPS = {
	{ gap = 0, build = initCategoryButtons },
	{ gap = 26, build = initSceneButtons },
	{ gap = 26, build = initSettingsButton },
	{ gap = 8, build = initFeedbackButton },
	{ gap = 26, build = initFightNavButtons },
}

---@param MenuPanel MenuPanel
local function buildMenuBar(MenuPanel)
	---@type any, integer
	local anchorControl, anchorPoint = MenuPanel.control, TOP
	local order = {}

	for _, group in ipairs(MENU_GROUPS) do
		for i, button in ipairs(group.build(MenuPanel)) do
			---@diagnostic disable-next-line: missing-parameter
			button:SetAnchor(TOP, anchorControl, anchorPoint, nil, i == 1 and group.gap or BUTTON_GAP)
			anchorControl, anchorPoint = button, BOTTOM
			order[#order + 1] = button
		end
	end

	MenuPanel.buttonOrder = order
end

function CMXint.InitializeMenuPanel(control)
	---@class MenuPanel: Panel
	---@field categoryButtons table<string, TextureControl>
	---@field categoryOrder string[]
	---@field sceneButtons table<string, TextureControl>
	---@field sceneOrder string[]
	---@field navButtons table<string, ButtonControl>
	---@field buttonOrder Control[]
	local MenuPanel = CMX.internal.PanelObject:New(control, "menu")

	function MenuPanel:Update()
		self:UpdateButtonStates()
	end

	function MenuPanel:UpdateButtonStates()
		local fightData = CMXint.FightData
		local SVHandler = CMXint.SVHandler
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

		local save = fightData:CanSaveFight()
		navButtons.save:SetState(save and BSTATE_NORMAL or BSTATE_DISABLED, not save)

		local delete = fight ~= nil
		navButtons.delete:SetState(delete and BSTATE_NORMAL or BSTATE_DISABLED, not delete)
	end

	---@param key string one of util.MainCategories
	function MenuPanel:SelectCategory(key)
		for category, button in pairs(self.categoryButtons) do
			local r, g, b = unpack(button["baseColor"])
			button:SetColor(r, g, b, category == key and 1 or 0.2)
		end

		if self.settings.category ~= key then
			self.settings.category = key
			self.fightReport:Update()
		end
	end

	---@param order string[]
	---@param current string?
	---@return integer
	local function indexOf(order, current)
		for i, key in ipairs(order) do
			if key == current then
				return i
			end
		end
		return 1
	end

	---@param delta integer
	function MenuPanel:CycleCategory(delta)
		local order = self.categoryOrder
		local index = (indexOf(order, self.settings.category) - 1 + delta) % #order + 1
		self:SelectCategory(order[index])
	end

	--- Skips views no panel is registered for, so the cycle never lands on a blank screen. Views
	--- rejoin it on their own as their panels come online.
	---@param delta integer
	function MenuPanel:CycleView(delta)
		local order = self.sceneOrder
		local count = #order
		local index = indexOf(order, self.settings.scene)

		for step = 1, count - 1 do
			local key = order[(index - 1 + delta * step) % count + 1]
			if ui.ViewHasPanels(key) then
				self:SelectScene(key)
				return
			end
		end
	end

	---@param key string
	function MenuPanel:SelectScene(key)
		self.fightReport:SelectScene(key)
	end

	---@param key string
	function MenuPanel:SetActiveView(key)
		for scene, button in pairs(self.sceneButtons) do
			button:SetColor(1, 1, 1, scene == key and 1 or 0.2)
		end
		self.settings.scene = key
	end

	buildMenuBar(MenuPanel)
end

local isFileInitialized = false
function CMXint.InitializeMenu()
	if isFileInitialized == true then
		return true
	end
	logger = util.initSublogger("Menu")

	local MenuPanel = ui:GetPanel("menu") --[[@as MenuPanel]]

	MenuPanel:SelectCategory(MenuPanel.settings.category or cat.CMX_CATEGORY_DAMAGE_DONE)
	MenuPanel:SetActiveView("fightStats")

	isFileInitialized = true
	return true
end
