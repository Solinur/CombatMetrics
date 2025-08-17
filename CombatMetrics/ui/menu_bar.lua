local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger

local ValidRaids = {

	[7] = true, -- vHoF
	[8] = true, -- vAS
	[9] = true, -- vCR
	[12] = true, -- vSS

}
local MenuBarPanel = CMXint.PanelObject:New("MenuBar", CombatMetrics_Report_Menubar)

function MenuBarPanel:Update()
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

function MenuBarPanel:Release() end

function MenuBarPanel:InitButtons()
	local category = self.settings.category
	local buttons = self.control

	for i = 1, buttons:GetNumChildren() do
		local button = buttons:GetChild(i)

		if button and button.isMainCategory then
			button:SetHandler( "OnMouseUp", self.SelectCategory)
			if button.category == category then self.SelectCategory(button) end
		elseif button and button.isSecondaryCategory then
			button:SetHandler( "OnMouseUp", self.selectMainPanel)
		end

		self.selectMainPanel(buttons:GetNamedChild("FightStatsButton"))
	end
end

function MenuBarPanel.SelectCategory(button)
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

function MenuBarPanel.SelectMainPanel(button)
	local selectControl = button:GetParent()
	local category = button.category

	for i = 1, selectControl:GetNumChildren() do
		local child = selectControl:GetChild(i)

		if child and child.isSecondaryCategory then
			local a = child == button and 1 or .2
			child:SetColor(1, 1, 1, a)
		end
	end

	local mainPanel = CombatMetrics_Report_MainPanel
	local rightPanel = CombatMetrics_Report_RightPanel
	local unitPanel = CombatMetrics_Report_UnitPanel
	local abilityPanel = CombatMetrics_Report_AbilityPanel
	local setupPanel = CombatMetrics_Report_SetupPanel
	local graphPanel = CombatMetrics_Report_MainPanelGraph

	local isInfo = category == "Info"

	mainPanel:SetHidden(isInfo)
	rightPanel:SetHidden(isInfo)
	unitPanel:SetHidden(isInfo)
	abilityPanel:SetHidden(isInfo)
	setupPanel:SetHidden(not isInfo)

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
		setupPanel:Update()
	end
end

local isFileInitialized = false
function CMXint.InitializeMenuBarPanel()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("MenuBarPanel")

	MenuBarPanel:InitButtons()

    isFileInitialized = true
	return true
end