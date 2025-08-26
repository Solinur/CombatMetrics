local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger
local sendGold

local donateDialog = CombatMetrics_Report_DonateDialog

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
	donateDialog:SetHidden(true)
end

local function DonateCrowns()
	local dialog = donateDialog
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

local isFileInitialized = false
function CMXint.InitializeDonations()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("Donation")

    isFileInitialized = true
	return true
end