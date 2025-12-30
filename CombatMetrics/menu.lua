local CMXint = CMX
if CMXint == nil then CMXint = {} end
local _
--
-- Register with LibMenu and ESO

local sendGold

local function PrefillMail()
	local isDonation = sendGold and sendGold > 0
	local headerString = GetString(isDonation and SI_COMBAT_METRICS_DONATE_GOLD_HEADER or SI_COMBAT_METRICS_FEEDBACK_MAIL_HEADER)

	ZO_MailSendToField:SetText("@Solinur")
	ZO_MailSendSubjectField:SetText(string.format(headerString, CMXint.version))
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

local function GotoESOUIDonation()
	RequestOpenUnsafeURL(GetString(SI_COMBAT_METRICS_DONATE_ESOUIURL))
end

local function FeedbackContextMenu()
	ClearMenu()

	local isEUServer = GetWorldName() == "EU Megaserver"
	if isEUServer then AddCustomMenuItem(GetString(SI_COMBAT_METRICS_FEEDBACK_MAIL), SendIngameMail) end

	AddCustomMenuItem(GetString(SI_COMBAT_METRICS_FEEDBACK_ESOUI), GotoESOUI)
	AddCustomMenuItem(GetString(SI_COMBAT_METRICS_FEEDBACK_GITHUB), GotoGithub)
	AddCustomMenuItem(GetString(SI_COMBAT_METRICS_FEEDBACK_DISCORD), GotoDiscord)

	ShowMenu()
end

local function DonationContextMenu()
	ClearMenu()

	local isEUServer = GetWorldName() == "EU Megaserver"
	if isEUServer then AddCustomMenuItem(GetString(SI_COMBAT_METRICS_DONATE_GOLD), DonateGold) end

	AddCustomMenuItem(GetString(SI_COMBAT_METRICS_DONATE_ESOUI), GotoESOUIDonation)
	ShowMenu()
end

function CMXint.InitMenu(svdefaults)
	-- load the settings->addons menu library
	local menu = LibAddonMenu2
	if not LibAddonMenu2 then return end

	local settings = CMXint.settings
	local def = svdefaults

	-- the panel for the addons menu
	local panelData = {
		type = "panel",
		name = "Combat Metrics",
		displayName = "Combat Metrics",
		author = "Solinur",
		version = "" .. CMXint.version,
		registerForRefresh = true,
		registerForDefaults = true,
		website = "https://www.esoui.com/downloads/info1360-CombatMetrics.html",
		feedback = FeedbackContextMenu,
		donation = DonationContextMenu,
	}

	--this adds entries in the addon menu
	local options = {
		{
			type = "header",
			name = GetString(SI_COMBAT_METRICS_MENU_PROFILES)
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_AC_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_AC_TOOLTIP),
			default = def.accountwide,
			getFunc = function() return CombatMetrics_Save.Default[GetDisplayName()]['$AccountWide']["Settings"]["accountwide"] end,
			setFunc = function(value) CombatMetrics_Save.Default[GetDisplayName()]['$AccountWide']["Settings"]["accountwide"] = value end,
			requiresReload = true,
		},
		{
			type = "custom",
		},
		{
			type = "header",
			name = GetString(SI_COMBAT_METRICS_MENU_GS_NAME)
		},
		{
			type = "slider",
			name = GetString(SI_COMBAT_METRICS_MENU_FH_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_FH_TOOLTIP),
			min = 1,
			max = 40,
			step = 1,
			default = def.fighthistory,
			getFunc = function() return settings.fighthistory end,
			setFunc = function(value) settings.fighthistory = value end,
		},
		{
			type = "slider",
			name = GetString(SI_COMBAT_METRICS_MENU_MAXSAVEDFIGHTS_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_MAXSAVEDFIGHTS_TOOLTIP),
			warning = GetString(SI_COMBAT_METRICS_MENU_MAXSAVEDFIGHTS_WARNING),
			min = 20,
			max = 250,
			step = 10,
			default = def.maxSavedFights,
			getFunc = function() return settings.maxSavedFights end,
			setFunc = function(value) settings.maxSavedFights = value end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_BOSSFIGHTS_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_BOSSFIGHTS_TOOLTIP),
			default = def.keepbossfights,
			getFunc = function() return settings.keepbossfights end,
			setFunc = function(value)
				settings.keepbossfights = value
			end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_MG_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_MG_TOOLTIP),
			default = def.recordgrp,
			getFunc = function() return settings.recordgrp end,
			setFunc = function(value)
				settings.recordgrp = value
				CMXint.UpdateEvents()
			end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_GL_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_GL_TOOLTIP),
			default = def.recordgrpinlarge,
			getFunc = function() return settings.recordgrpinlarge end,
			setFunc = function(value) settings.recordgrpinlarge = value end,
			disabled = not settings.recordgrp,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_STACKS_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_STACKS_TOOLTIP),
			default = def.showstacks,
			getFunc = function() return settings.showstacks end,
			setFunc = function(value) settings.showstacks = value end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_LM_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_LM_TOOLTIP),
			default = def.lightmode,
			getFunc = function() return settings.lightmode end,
			setFunc = function(value)
				settings.lightmode = value
				CMXint.UpdateEvents()
			end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_NOPVP_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_NOPVP_TOOLTIP),
			default = def.offincyrodil,
			getFunc = function() return settings.offincyrodil end,
			setFunc = function(value)
				settings.offincyrodil = value
				CMXint.UpdateEvents()
			end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_LMPVP_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_LMPVP_TOOLTIP),
			default = def.lightmodeincyrodil,
			getFunc = function() return settings.lightmodeincyrodil end,
			setFunc = function(value)
				settings.lightmodeincyrodil = value
				CMXint.UpdateEvents()
			end,
			disabled = function() return (settings.offincyrodil or settings.lightmode) end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_ASCC_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_ASCC_TOOLTIP),
			default = def.autoselectchatchannel,
			getFunc = function() return settings.autoselectchatchannel end,
			setFunc = function(value) settings.autoselectchatchannel = value end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_AS_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_AS_TOOLTIP),
			default = def.autoscreenshot,
			getFunc = function() return settings.autoscreenshot end,
			setFunc = function(value) settings.autoscreenshot = value end,
		},
		{
			type = "slider",
			name = GetString(SI_COMBAT_METRICS_MENU_ML_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_ML_TOOLTIP),
			min = 1,
			max = 120,
			step = 1,
			disabled = function() return (not settings.autoscreenshot) end,
			default = def.autoscreenshotmintime,
			getFunc = function() return settings.autoscreenshotmintime end,
			setFunc = function(value) settings.autoscreenshotmintime = value end,
		},
		{
			type = "slider",
			name = GetString(SI_COMBAT_METRICS_MENU_SF_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SF_TOOLTIP),
			min = 50,
			max = 300,
			step = 1,
			default = def.fightReport.scale,
			getFunc = function() return settings.fightReport.scale*100  end,
			setFunc = function(value)
					settings.fightReport.scale = value/100
					CombatMetricsReport:Resize(value/100)
				end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_DISPLAYNAMES_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_DISPLAYNAMES_TOOLTIP),
			default = def.fightReport.useDisplayNames,
			getFunc = function() return settings.fightReport.useDisplayNames end,
			setFunc = function(value) settings.fightReport.useDisplayNames = value end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_SHOWPETS_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SHOWPETS_TOOLTIP),
			default = def.fightReport.showPets,
			getFunc = function() return settings.fightReport.showPets end,
			setFunc = function(value) settings.fightReport.showPets = value end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_NOTIFICATIONS),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_NOTIFICATIONS_TOOLTIP),
			default = def.notification.enabled,
			getFunc = function() return settings.notification.enabled end,
			setFunc = function(value)
				settings.notification.enabled = value
				if value == true then settings.notification.versionSeen = 0 end
			end,
		},
		{
			type = "custom",
		},
		{
			type = "header",
			name = GetString(SI_COMBAT_METRICS_MENU_RESPEN_NAME)
		},
		{
			type = "editbox",
			name = GetString(SI_COMBAT_METRICS_MENU_CRUSHER),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_CRUSHER_TOOLTIP),
			default = def.crusherValue,
			getFunc = function() return settings.crusherValue end,
			setFunc = function(value)
					if value then

						local number = zo_round(tonumber(value) or def.crusherValue)
						CMXint.SetPenetrationDebuffValue("crusherValue", number)

					end
				end
		},
		{
			type = "editbox",
			name = GetString(SI_COMBAT_METRICS_MENU_ALKOSH),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_ALKOSH_TOOLTIP),
			default = def.alkoshValue,
			getFunc = function() return settings.alkoshValue end,
			setFunc = function(value)
					if value then

						local number = zo_round(tonumber(value) or def.alkoshValue)
						CMXint.SetPenetrationDebuffValue("alkoshValue", number)

					end
				end
		},
		{
			type = "editbox",
			name = GetString(SI_COMBAT_METRICS_MENU_TREMORSCALE),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_TREMORSCALE_TOOLTIP),
			default = def.tremorscaleValue,
			getFunc = function() return settings.tremorscaleValue end,
			setFunc = function(value)
					if value then

						local number = zo_round(tonumber(value) or def.tremorscaleValue)
						CMXint.SetPenetrationDebuffValue("tremorscaleValue", number)

					end
				end
		},
		{
			type = "editbox",
			name = GetString(SI_COMBAT_METRICS_MENU_MOBRESISTANCE),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_MOBRESISTANCE_TOOLTIP),
			default = def.unitresistance,
			getFunc = function() return settings.unitresistance end,
			setFunc = function(value)
					if value then

						local number = zo_round(tonumber(value) or def.unitresistance)
						settings.unitresistance = number

					end
				end
		},
		{
			type = "header",
			name = GetString(SI_COMBAT_METRICS_MENU_LR_NAME),
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_ENABLE_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_ENABLE_TOOLTIP),
			default = def.liveReport.enabled,
			getFunc = function() return settings.liveReport.enabled end,
			setFunc = function(value)
				settings.liveReport.enabled = value
				CombatMetrics_LiveReport:Toggle(value)
			end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_LR_LOCK),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_LR_LOCK_TOOLTIP),
			default = def.liveReport.locked,
			getFunc = function() return settings.liveReport.locked end,
			setFunc = function(value)
				CombatMetrics_LiveReport:GetNamedChild("ResizeFrame"):SetMouseEnabled(not value)
				CombatMetrics_LiveReport:SetMovable(not value)
				settings.liveReport.locked = value
			end,
		},
		{
			type = "dropdown",
			name = GetString(SI_COMBAT_METRICS_MENU_LAYOUT_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_LAYOUT_TOOLTIP),
			default = def.liveReport.layout,
			choices = {"Compact", "Horizontal", "Vertical"},
			getFunc = function() return settings.liveReport.layout end,
			setFunc = function(value)
				settings.liveReport.layout = value
				CombatMetrics_LiveReport:Refresh()
			end,
			disabled = function() return not settings.liveReport.enabled end,
		},
		{
			type = "slider",
			name = GetString(SI_COMBAT_METRICS_MENU_SCALE_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SCALE_TOOLTIP),
			min = 50,
			max = 300,
			step = 10,
			default = def.liveReport.scale,
			getFunc = function() return settings.liveReport.scale*100  end,
			setFunc = function(value)
					settings.liveReport.scale = value/100
					CombatMetrics_LiveReport:Resize(value/100)
				end,
			disabled = function() return not settings.liveReport.enabled end,
		},
		{
			type = "slider",
			name = GetString(SI_COMBAT_METRICS_MENU_BGALPHA_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_BGALPHA_TOOLTIP),
			min = 0,
			max = 100,
			step = 1,
			default = def.liveReport.bgalpha,
			getFunc = function() return settings.liveReport.bgalpha end,
			setFunc = function(value)
				settings.liveReport.bgalpha = value
				CombatMetrics_LiveReportBG:SetAlpha(value/100)
			end,
			disabled = function() return not settings.liveReport.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_LR_ALIGNMENT),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_LR_ALIGNMENT_TOOLTIP),
			default = def.liveReport.alignmentleft,
			getFunc = function() return settings.liveReport.alignmentleft end,
			setFunc = function(value)
				settings.liveReport.alignmentleft = value
				CombatMetrics_LiveReport:Refresh()
			end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_SHOW_DPS_NAME),
			width = "half",
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SHOW_DPS_TOOLTIP),
			default = def.liveReport.damageOut,
			getFunc = function() return settings.liveReport.damageOut end,
			setFunc = function(value)
				settings.liveReport.damageOut = value
				CombatMetrics_LiveReport:Refresh()
			end,
			disabled = function() return not settings.liveReport.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_SHOW_SDPS_NAME),
			width = "half",
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SHOW_SDPS_TOOLTIP),
			default = def.liveReport.damageOutSingle,
			getFunc = function() return settings.liveReport.damageOutSingle end,
			setFunc = function(value)
				settings.liveReport.damageOutSingle = value
				CombatMetrics_LiveReport:Refresh()
			end,
			disabled = function() return not settings.liveReport.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_SHOW_HPSA_NAME),
			width = "half",
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SHOW_HPSA_TOOLTIP),
			default = def.liveReport.healOutAbsolute,
			getFunc = function() return settings.liveReport.healOutAbsolute end,
			setFunc = function(value)
				settings.liveReport.healOutAbsolute = value
				CombatMetrics_LiveReport:Refresh()
			end,
			disabled = function() return not settings.liveReport.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_SHOW_HPS_NAME),
			width = "half",
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SHOW_HPS_TOOLTIP),
			default = def.liveReport.healOut,
			getFunc = function() return settings.liveReport.healOut end,
			setFunc = function(value)
				settings.liveReport.healOut = value
				CombatMetrics_LiveReport:Refresh()
			end,
			disabled = function() return not settings.liveReport.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_NAME),
			width = "half",
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_TOOLTIP),
			default = def.liveReport.damageIn,
			getFunc = function() return settings.liveReport.damageIn end,
			setFunc = function(value)
				settings.liveReport.damageIn = value
				CombatMetrics_LiveReport:Refresh()
			end,
			disabled = function() return not settings.liveReport.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_NAME),
			width = "half",
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_TOOLTIP),
			default = def.liveReport.healIn,
			getFunc = function() return settings.liveReport.healIn end,
			setFunc = function(value)
				settings.liveReport.healIn = value
				CombatMetrics_LiveReport:Refresh()
			end,
			disabled = function() return not settings.liveReport.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_SHOW_TIME_NAME),
			width = "half",
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SHOW_TIME_TOOLTIP),
			default = def.liveReport.time,
			getFunc = function() return settings.liveReport.time end,
			setFunc = function(value)
				settings.liveReport.time = value
				CombatMetrics_LiveReport:Refresh()
			end,
			disabled = function() return not settings.liveReport.enabled end,
		},
		{
			type = "custom",
			width = "half",

		},
		{
			type = "custom",
		},
		{
			type = "header",
			name = GetString(SI_COMBAT_METRICS_MENU_CHAT_TITLE),
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_ENABLE_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_CHAT_DH_TOOLTIP),
			default = def.chatLog.enabled,
			warning = GetString(SI_COMBAT_METRICS_MENU_CHAT_WARNING),
			getFunc = function() return settings.chatLog.enabled end,
			setFunc = function(value) if value then CMXint.InitializeChat() else CMXint.RemoveCombatLog() end settings.chatLog.enabled = value end,
		},
		{
			type = "editbox",
			name = GetString(SI_COMBAT_METRICS_MENU_CHAT_TITLE_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_CHAT_TITLE_TOOLTIP),
			default = def.chatLog.name,
			getFunc = function() return settings.chatLog.name end,
			setFunc = function(value) if value then CMXint.ChangeCombatLogLabel(value) end settings.chatLog.name = value end,
			disabled = function() return not settings.chatLog.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_CHAT_SD_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_CHAT_SD_TOOLTIP),
			default = def.chatLog.damageOut,
			getFunc = function() return settings.chatLog.damageOut end,
			setFunc = function(value) settings.chatLog.damageOut = value end,
			disabled = function() return not settings.chatLog.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_CHAT_SH_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_CHAT_SH_TOOLTIP),
			default = def.chatLog.healingOut,
			getFunc = function() return settings.chatLog.healingOut end,
			setFunc = function(value) settings.chatLog.healingOut = value end,
			disabled = function() return not settings.chatLog.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_CHAT_SID_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_CHAT_SID_TOOLTIP),
			default = def.chatLog.damageIn,
			getFunc = function() return settings.chatLog.damageIn end,
			setFunc = function(value) settings.chatLog.damageIn = value end,
			disabled = function() return not settings.chatLog.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_CHAT_SIH_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_CHAT_SIH_TOOLTIP),
			default = def.chatLog.healingIn,
			getFunc = function() return settings.chatLog.healingIn end,
			setFunc = function(value) settings.chatLog.healingIn = value end,
			disabled = function() return not settings.chatLog.enabled end,
		},
		{
			type = "custom",
		},
	}

	if GetDisplayName() == "@Solinur" then

		options[#options+1] = {
			type = "custom",
		}

		options[#options+1] = {

			type = "checkbox",
			name = "Force Notification",
			tooltip = "Force Notification",
			default = def.ForceNotification,
			getFunc = function() return settings.ForceNotification end,
			setFunc = function(value) settings.ForceNotification = value end,

		}
	end

	local panel = menu:RegisterAddonPanel("CMX_Options", panelData)
	menu:RegisterOptionControls("CMX_Options", options)

	function CMXint.OpenSettings()
		menu:OpenToPanel(panel)
	end

	return true
end