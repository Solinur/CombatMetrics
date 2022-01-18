local CMX = CMX
if CMX == nil then CMX = {} end
local _
--
-- Register with LibMenu and ESO

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

function CMX.MakeMenu(svdefaults)
    -- load the settings->addons menu library
	local menu = LibAddonMenu2
	if not LibAddonMenu2 then return end

	local db = CMX.db
	local def = svdefaults

    -- the panel for the addons menu
	local panelData = {
		type = "panel",
		name = "Combat Metrics",
		displayName = "Combat Metrics",
		author = "Solinur",
        version = "" .. CMX.version,
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
			getFunc = function() return db.fighthistory end,
			setFunc = function(value) db.fighthistory = value end,
		},
		{
			type = "slider",
			name = GetString(SI_COMBAT_METRICS_MENU_SVSIZE_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SVSIZE_TOOLTIP),
			warning = GetString(SI_COMBAT_METRICS_MENU_SVSIZE_WARNING),
			min = 5,
			max = 50,
			step = 1,
			default = def.maxSVsize,
			getFunc = function() return db.maxSVsize end,
			setFunc = function(value) db.maxSVsize = value end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_BOSSFIGHTS_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_BOSSFIGHTS_TOOLTIP),
			default = def.keepbossfights,
			getFunc = function() return db.keepbossfights end,
			setFunc = function(value)
				db.keepbossfights = value
			end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_MG_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_MG_TOOLTIP),
			default = def.recordgrp,
			getFunc = function() return db.recordgrp end,
			setFunc = function(value)
				db.recordgrp = value
				CMX.UpdateEvents()
			end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_GL_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_GL_TOOLTIP),
			default = def.recordgrpinlarge,
			getFunc = function() return db.recordgrpinlarge end,
			setFunc = function(value) db.recordgrpinlarge = value end,
			disabled = not db.recordgrp,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_STACKS_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_STACKS_TOOLTIP),
			default = def.showstacks,
			getFunc = function() return db.showstacks end,
			setFunc = function(value) db.showstacks = value end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_LM_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_LM_TOOLTIP),
			default = def.lightmode,
			getFunc = function() return db.lightmode end,
			setFunc = function(value)
				db.lightmode = value
				CMX.UpdateEvents()
			end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_NOPVP_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_NOPVP_TOOLTIP),
			default = def.offincyrodil,
			getFunc = function() return db.offincyrodil end,
			setFunc = function(value)
				db.offincyrodil = value
				CMX.UpdateEvents()
			end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_LMPVP_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_LMPVP_TOOLTIP),
			default = def.lightmodeincyrodil,
			getFunc = function() return db.lightmodeincyrodil end,
			setFunc = function(value)
				db.lightmodeincyrodil = value
				CMX.UpdateEvents()
			end,
			disabled = function() return (db.offincyrodil or db.lightmode) end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_ASCC_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_ASCC_TOOLTIP),
			default = def.autoselectchatchannel,
			getFunc = function() return db.autoselectchatchannel end,
			setFunc = function(value) db.autoselectchatchannel = value end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_AS_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_AS_TOOLTIP),
			default = def.autoscreenshot,
			getFunc = function() return db.autoscreenshot end,
			setFunc = function(value) db.autoscreenshot = value end,
		},
		{
			type = "slider",
			name = GetString(SI_COMBAT_METRICS_MENU_ML_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_ML_TOOLTIP),
			min = 1,
			max = 120,
			step = 1,
			disabled = function() return (not db.autoscreenshot) end,
			default = def.autoscreenshotmintime,
			getFunc = function() return db.autoscreenshotmintime end,
			setFunc = function(value) db.autoscreenshotmintime = value end,
		},
		{
			type = "slider",
			name = GetString(SI_COMBAT_METRICS_MENU_SF_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SF_TOOLTIP),
			min = 50,
			max = 300,
			step = 1,
			default = def.FightReport.scale,
			getFunc = function() return db.FightReport.scale*100  end,
			setFunc = function(value)
					db.FightReport.scale = value/100
					CombatMetrics_Report:Resize(value/100)
				end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_DISPLAYNAMES_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_DISPLAYNAMES_TOOLTIP),
			default = def.FightReport.useDisplayNames,
			getFunc = function() return db.FightReport.useDisplayNames end,
			setFunc = function(value) db.FightReport.useDisplayNames = value end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_SHOWPETS_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SHOWPETS_TOOLTIP),
			default = def.FightReport.showPets,
			getFunc = function() return db.FightReport.showPets end,
			setFunc = function(value) db.FightReport.showPets = value end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_NOTIFICATIONS),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_NOTIFICATIONS_TOOLTIP),
			default = def.NotificationAllowed,
			getFunc = function() return db.NotificationAllowed end,
			setFunc = function(value)
				db.NotificationAllowed = value
				if value == true then db.NotificationRead = 0 end
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
			getFunc = function() return db.crusherValue end,
			setFunc = function(value)
					if value then

						local number = zo_round(tonumber(value) or def.crusherValue)
						CMX.SetCrusher(number)

					end
				end
		},
		{
			type = "editbox",
			name = GetString(SI_COMBAT_METRICS_MENU_MOBRESISTANCE),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_MOBRESISTANCE_TOOLTIP),
			default = def.unitresistance,
			getFunc = function() return db.unitresistance end,
			setFunc = function(value)
					if value then

						local number = zo_round(tonumber(value) or def.unitresistance)
						db.unitresistance = number

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
			getFunc = function() return db.liveReport.enabled end,
			setFunc = function(value)
				db.liveReport.enabled = value
				CombatMetrics_LiveReport:Toggle(value)
			end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_LR_LOCK),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_LR_LOCK_TOOLTIP),
			default = def.liveReport.locked,
			getFunc = function() return db.liveReport.locked end,
			setFunc = function(value)
				CombatMetrics_LiveReport:GetNamedChild("ResizeFrame"):SetMouseEnabled(not value)
				db.liveReport.locked = value
			end,
		},
		{
			type = "dropdown",
			name = GetString(SI_COMBAT_METRICS_MENU_LAYOUT_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_LAYOUT_TOOLTIP),
			default = def.liveReport.layout,
			choices = {"Compact", "Horizontal", "Vertical"},
			getFunc = function() return db.liveReport.layout end,
			setFunc = function(value)
				db.liveReport.layout = value
				CombatMetrics_LiveReport:Refresh()
			end,
			disabled = function() return not db.liveReport.enabled end,
		},
		{
			type = "slider",
			name = GetString(SI_COMBAT_METRICS_MENU_SCALE_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SCALE_TOOLTIP),
			min = 50,
			max = 300,
			step = 10,
			default = def.liveReport.scale,
			getFunc = function() return db.liveReport.scale*100  end,
			setFunc = function(value)
					db.liveReport.scale = value/100
					CombatMetrics_LiveReport:Resize(value/100)
				end,
			disabled = function() return not db.liveReport.enabled end,
		},
		{
			type = "slider",
			name = GetString(SI_COMBAT_METRICS_MENU_BGALPHA_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_BGALPHA_TOOLTIP),
			min = 0,
			max = 100,
			step = 1,
			default = def.liveReport.bgalpha,
			getFunc = function() return db.liveReport.bgalpha end,
			setFunc = function(value)
				db.liveReport.bgalpha = value
				CombatMetrics_LiveReportBG:SetAlpha(value/100)
			end,
			disabled = function() return not db.liveReport.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_LR_ALIGNMENT),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_LR_ALIGNMENT_TOOLTIP),
			default = def.liveReport.alignmentleft,
			getFunc = function() return db.liveReport.alignmentleft end,
			setFunc = function(value)
				db.liveReport.alignmentleft = value
				CombatMetrics_LiveReport:Refresh()
			end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_SHOW_DPS_NAME),
			width = "half",
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SHOW_DPS_TOOLTIP),
			default = def.liveReport.damageOut,
			getFunc = function() return db.liveReport.damageOut end,
			setFunc = function(value)
				db.liveReport.damageOut = value
				CombatMetrics_LiveReport:Refresh()
			end,
			disabled = function() return not db.liveReport.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_SHOW_SDPS_NAME),
			width = "half",
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SHOW_SDPS_TOOLTIP),
			default = def.liveReport.damageOutSingle,
			getFunc = function() return db.liveReport.damageOutSingle end,
			setFunc = function(value)
				db.liveReport.damageOutSingle = value
				CombatMetrics_LiveReport:Refresh()
			end,
			disabled = function() return not db.liveReport.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_SHOW_HPSA_NAME),
			width = "half",
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SHOW_HPSA_TOOLTIP),
			default = def.liveReport.healOutAbsolute,
			getFunc = function() return db.liveReport.healOutAbsolute end,
			setFunc = function(value)
				db.liveReport.healOutAbsolute = value
				CombatMetrics_LiveReport:Refresh()
			end,
			disabled = function() return not db.liveReport.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_SHOW_HPS_NAME),
			width = "half",
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SHOW_HPS_TOOLTIP),
			default = def.liveReport.healOut,
			getFunc = function() return db.liveReport.healOut end,
			setFunc = function(value)
				db.liveReport.healOut = value
				CombatMetrics_LiveReport:Refresh()
			end,
			disabled = function() return not db.liveReport.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_NAME),
			width = "half",
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_TOOLTIP),
			default = def.liveReport.damageIn,
			getFunc = function() return db.liveReport.damageIn end,
			setFunc = function(value)
				db.liveReport.damageIn = value
				CombatMetrics_LiveReport:Refresh()
			end,
			disabled = function() return not db.liveReport.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_NAME),
			width = "half",
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_TOOLTIP),
			default = def.liveReport.healIn,
			getFunc = function() return db.liveReport.healIn end,
			setFunc = function(value)
				db.liveReport.healIn = value
				CombatMetrics_LiveReport:Refresh()
			end,
			disabled = function() return not db.liveReport.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_SHOW_TIME_NAME),
			width = "half",
			tooltip = GetString(SI_COMBAT_METRICS_MENU_SHOW_TIME_TOOLTIP),
			default = def.liveReport.time,
			getFunc = function() return db.liveReport.time end,
			setFunc = function(value)
				db.liveReport.time = value
				CombatMetrics_LiveReport:Refresh()
			end,
			disabled = function() return not db.liveReport.enabled end,
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
			getFunc = function() return db.chatLog.enabled end,
			setFunc = function(value) if value then CMX.InitializeChat() else CMX.RemoveCombatLog() end db.chatLog.enabled = value end,
		},
		{
			type = "editbox",
			name = GetString(SI_COMBAT_METRICS_MENU_CHAT_TITLE_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_CHAT_TITLE_TOOLTIP),
			default = def.chatLog.name,
			getFunc = function() return db.chatLog.name end,
			setFunc = function(value) if value then CMX.ChangeCombatLogLabel(value) end db.chatLog.name = value end,
			disabled = function() return not db.chatLog.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_CHAT_SD_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_CHAT_SD_TOOLTIP),
			default = def.chatLog.damageOut,
			getFunc = function() return db.chatLog.damageOut end,
			setFunc = function(value) db.chatLog.damageOut = value end,
			disabled = function() return not db.chatLog.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_CHAT_SH_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_CHAT_SH_TOOLTIP),
			default = def.chatLog.healingOut,
			getFunc = function() return db.chatLog.healingOut end,
			setFunc = function(value) db.chatLog.healingOut = value end,
			disabled = function() return not db.chatLog.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_CHAT_SID_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_CHAT_SID_TOOLTIP),
			default = def.chatLog.damageIn,
			getFunc = function() return db.chatLog.damageIn end,
			setFunc = function(value) db.chatLog.damageIn = value end,
			disabled = function() return not db.chatLog.enabled end,
		},
		{
			type = "checkbox",
			name = GetString(SI_COMBAT_METRICS_MENU_CHAT_SIH_NAME),
			tooltip = GetString(SI_COMBAT_METRICS_MENU_CHAT_SIH_TOOLTIP),
			default = def.chatLog.healingIn,
			getFunc = function() return db.chatLog.healingIn end,
			setFunc = function(value) db.chatLog.healingIn = value end,
			disabled = function() return not db.chatLog.enabled end,
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
			getFunc = function() return db.ForceNotification end,
			setFunc = function(value) db.ForceNotification = value end,

		}
	end

	local panel = menu:RegisterAddonPanel("CMX_Options", panelData)
	menu:RegisterOptionControls("CMX_Options", options)

	function CMX.OpenSettings()

		menu:OpenToPanel(panel)

	end
end