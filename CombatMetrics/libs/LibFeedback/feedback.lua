-- Modified by Dolgubon based off code from Master Merchant with permission
-- Master Merchant was written by Dan Stone (aka @khaibit) / Chris Lasswell (aka @Philgo68)

--[[

Use:

local LibFeedback = LibStub:GetLibrary('LibFeedback')
-- The button is returned so you can modify the button if needed
-- ExampleAddonNameSpace.feedbackButton = LibFeedback:initializeFeedbackWindow(
ExampleAddonNameSpace, -- namespace of the addon
"Example Addon", -- The title string for the feedback window and the mails it sends
parentControl, -- The parent control to anchor the feedback button(s) + label(s) to
"@AddonAuthor", -- If this parameter is no table: [1st parameter] like desribed below:
                    -- The destination for feedback (0 gold attachment) and donation mails, valid for all servers
                -- If this parameter is a table:
                -- Example: { addonVars.addonAuthorDisplayNameEU, addonVars.addonAuthorDisplayNameNA, addonVars.addonAuthorDisplayNamePTS },
                    -- [1st parameter]Addon author name or character name at the EU Megaserver
                    -- [2nd parameter]Addon author name or character name at the NA Megaserver
                    -- [3rd parameter]Addon author name or character name at the PTS (Testserver)
{TOPLEFT, owningWindow, TOPLEFT, x, y}, -- The position of the mail button icon. owningWindow: Parent control for the button. x and y: Integer values for the offsets
{0,5000,50000, "https://www.genericexampleurl.com/somemoregenericiness"} -- The button info:
            -- Can theoretically do any number of options, it *should* handle them
            -- If this parameter is no table: [1st parameter] like desribed below:
                -- If 0: Will not attach any gold, and will say 'Send Note'
                -- If non zero: Will auto attach that amount of gold
                -- If URL: Will show a dialog box and ask the user if they want to go to the URL.
            -- If this parameter is a table:
                -- Example: [index]= {[1st parameter]            [2nd parameter]                                 [3rd parameter] },
                --            [1] = { 0,                         localization.feedbackSendNote,                  false },    -- Send ingame mail
                --            [2] = { 10000,                     localization.feedbackSendGold,                  true },     -- Send 10000 gold
                --            [3] = { addonVars.authorPortal,    localization.feedbackOpenAddonAuthorWebsite,    false },    -- Open URL
                --            [4] = { addonVars.FAQwebsite,      localization.feedbackOpenAddonFAQ,              false }     -- Open URL
                -- [1st parameter]Integer. When >0: Gold value to send/Integer. Gold will only be send if 3rd parameter is true. / When Integer==0: Show the 2nd parameter string as button text and send ingame mail. / When String <> "": Show the 2nd parameter string as button text and open the URL from 1st parameter in Webbrowser
                -- [2nd parameter]String to show as button text.
                -- [3rd parameter]Boolean send gold. True: Send mail with attached gold value from 1st parameter/False: Send normal mail without gold attached

"If you found a bug, have a request or a suggestion, or simply wish to donate, send a mail.", -- Will be displayed as a message below the title.
600, -- The default width of the feedback window. If more than 4 buttons this should be increased.
150  -- The default height of the feedback window
150, -- The default width of the feedback window's buttons
28   -- The default height of the feedback window's buttons
)
]]


local libLoaded
local LIB_NAME, VERSION = "LibFeedback", 1.1
local LibFeedback, oldminor = LibStub:NewLibrary(LIB_NAME, VERSION)
if not LibFeedback then return end
LibFeedback.debug = false

local function SendNote(self)

	local p = self.parent
	if type(self.amount)=="string" then
		RequestOpenUnsafeURL(self.amount)
	else
		p.parentControl:SetHidden(true)
		p:SetHidden(true)
		SCENE_MANAGER:Show('mailSend')
		zo_callLater(function()
			ZO_MailSendToField:SetText(p.mailDestination)
			ZO_MailSendSubjectField:SetText(p.parentAddonName)
			QueueMoneyAttachment(self.amount)
			ZO_MailSendBodyField:TakeFocus() end, 200)
	end
end

local function createFeedbackButton(name, owningWindow, feedbackWindowButtonWidth, feedbackWindowButtonHeight)
	local button = WINDOW_MANAGER:CreateControlFromVirtual(name, owningWindow, "ZO_DefaultButton")
	local b = button
	b:SetDimensions(feedbackWindowButtonWidth, feedbackWindowButtonHeight)
	b:SetHandler("OnClicked",function()SendNote(b) end)
	b:SetAnchor(BOTTOMLEFT,owningWindow, BOTTOMLEFT,5,5)
	return button
end

local function createShowFeedbackWindow(owningWindow)
	local showButton = WINDOW_MANAGER:CreateControl(owningWindow:GetName().."ShowFeedbackWindowButton", owningWindow, CT_BUTTON)
	local b = showButton
	b:SetDimensions(34, 34)
	b:SetNormalTexture("ESOUI/art/chatwindow/chat_mail_up.dds")
	b:SetMouseOverTexture("ESOUI/art/chatwindow/chat_mail_over.dds")
	b:SetHandler("OnClicked", function(self) self.feedbackWindow:ToggleHidden() end )
	return showButton
end

local function createFeedbackWindow(owningWindow, messageText, feedbackWindowWidth, feedbackWindowHeight)
	local feedbackWindow = WINDOW_MANAGER:CreateTopLevelWindow(owningWindow:GetName().."FeedbackWindow")
	local c = feedbackWindow
	c:SetDimensions(feedbackWindowWidth, feedbackWindowHeight)
	c:SetMouseEnabled(true)
	c:SetClampedToScreen(true)
	c:SetMovable(true)

	WINDOW_MANAGER:CreateControlFromVirtual(c:GetName().."BG", c, "ZO_DefaultBackdrop"):SetAnchorFill(c)
	local l = WINDOW_MANAGER:CreateControl(c:GetName().."Label", c, CT_LABEL)
	l:SetFont("ZoFontGame")
	l:SetAnchor(TOP, c,TOP0, 0, 5)
	l:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
	l:SetColor(0.83, 0.76, 0.16)
	local b = WINDOW_MANAGER:CreateControl(c:GetName().."Close", c, CT_BUTTON)
	b:SetAnchor(CENTER, c, TOPRIGHT, -20, 20)
	b:SetDimensions(48, 48)
	b:SetNormalTexture("/esoui/art/hud/radialicon_cancel_up.dds")
	b:SetMouseOverTexture("/esoui/art/hud/radialicon_cancel_over.dds")
	b:SetHandler("OnClicked", function(self) self:GetParent():SetHidden(true) end)
	local n = WINDOW_MANAGER:CreateControl(c:GetName().."Note", c, CT_LABEL)
    n:SetAnchor(TOPLEFT, c, TOPLEFT, 10, 30)
    n:SetDimensions(feedbackWindowWidth - 20, feedbackWindowHeight - 30)
    n:SetText(messageText)
    --n:SetAnchorFill()
	n:SetColor(1, 1, 1)
	n:SetFont("ZoFontGame")
	n:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
	return feedbackWindow
end

function LibFeedback:initializeFeedbackWindow(parentAddonNameSpace, parentAddonName, parentControl, mailDestination,  mailButtonPosition, buttonInfo,  messageText, feedbackWindowWidth, feedbackWindowHeight, feedbackWindowButtonWidth, feedbackWindowButtonHeight)
	-- Create Default settings
	if parentAddonNameSpace == nil or parentAddonNameSpace == "" then
		d("|cFF0000[LibFeedback] - ERROR:|r Obligatory addon namespace is missing!")
		return nil
	end
	if parentControl == nil or parentControl.GetName == nil then
		d("|cFF0000[LibFeedback] - ERROR:|r Parent control not found for addon namespace: \"|cFFFFFF" .. tostring(parentAddonName) .. "|r\"")
		return nil
	end

	if mailButtonPosition == nil or mailButtonPosition[2] == nil then
		d("|cFF0000[LibFeedback] - ERROR:|r Mail button data is missing for addon namespace: \"|cFFFFFF" .. tostring(parentAddonName) .. "|r\"")
		return nil
	end
    feedbackWindowHeight = feedbackWindowHeight or 150
    feedbackWindowWidth = feedbackWindowWidth or 600
    feedbackWindowButtonWidth = feedbackWindowButtonWidth or 150
    feedbackWindowButtonHeight = feedbackWindowButtonHeight or 28

	local feedbackWindow = createFeedbackWindow(parentControl, messageText, feedbackWindowWidth, feedbackWindowHeight)
	parentAddonNameSpace.feedbackWindow = feedbackWindow
	feedbackWindow.parentControl = parentControl
	if type(mailDestination) == "table" then
		--Get the current server and get the email address from the appropriate index of mailDestination[] then
		--1: EU, 2: NA, 3: PTS
		local mailAtServer = ""
		local world = GetWorldName()
		if world == 'PTS' then
		    mailAtServer = mailDestination[3] or mailDestination[1] or mailDestination[2]
		elseif world == 'EU Megaserver' then
		    mailAtServer = mailDestination[1]
		else
		    mailAtServer = mailDestination[2]
		end
		-- No destination sepcified for this server, so exit.
		if not mailAtServer then
			return
		end
		feedbackWindow.mailDestination = mailAtServer
    else
	    feedbackWindow.mailDestination = mailDestination
    end
	feedbackWindow.parentAddonName = parentAddonName

	feedbackWindow:SetAnchor(TOPLEFT,parentControl, TOPLEFT, 0,0)
	feedbackWindow:SetHidden(true)

	feedbackWindow:SetDimensions(math.max(#buttonInfo*feedbackWindowHeight, feedbackWindowWidth) , feedbackWindowHeight)
	feedbackWindow:GetNamedChild("Label"):SetText(parentAddonName)

	local buttons = {}
	for i = 1, #buttonInfo do

		buttons[#buttons+1] =  createFeedbackButton(feedbackWindow:GetName().."Button"..#buttons, feedbackWindow, feedbackWindowButtonWidth, feedbackWindowButtonHeight)
		buttons[i]:SetAnchor(BOTTOM, feedbackWindow, BOTTOMLEFT, (i-1)*feedbackWindowHeight+70,-10)
        local buttonData = buttonInfo[i]
        if buttonData ~= nil then
            local amount
            buttons[i].SendNote = SendNote
            buttons[i].parent = feedbackWindow

            local buttonText = ""
            local isButtonInfoDeep = (type(buttonData) == "table") or false
            if isButtonInfoDeep then
                if buttonData[2] == nil then buttonData[2] = "n/a" end -- Button text
                buttonData[3] = buttonData[3] or false -- Send gold
            end
            local isString = (not isButtonInfoDeep and (type(buttonData) == "string") or (isButtonInfoDeep and type(buttonData[1]) == "string")) or false
            local sendGold = (not isButtonInfoDeep and (type(buttonData) == "number" and buttonData > 0) or (isButtonInfoDeep and buttonData[3])) or false

            if LibFeedback.debug then
                d(zo_strformat("|cFF0000[LibFeedback]|r <<1>> - Button <<2>>: isButtonInfoDeep: <<3>>, isString: <<4>>, sendGold: <<5>>,", tostring(parentAddonName), tostring(i), tostring(isButtonInfoDeep), tostring(isString), tostring(sendGold)))
                if isButtonInfoDeep then
                    d(zo_strformat("> Param1: <<1>>, Param2: <<2>>, Param3: <<3>>,", tostring(buttonData[1]), tostring(buttonData[2]), tostring(buttonData[3])))
                else
                    d(zo_strformat("> Value: <<1>>", tostring(buttonData)))
                end
            end

            --Send gold via mail
            if sendGold then
                if isButtonInfoDeep then
                    buttonText = zo_strformat(buttonData[2], buttonData[1])
                    amount = buttonData[1]
                else
                    buttonText = "Send "..tostring(buttonData).." gold"
                    amount = buttonData
                end
            else
                --Open URL
                if isString then
                    if isButtonInfoDeep then
                        buttonText = buttonData[2]
                        amount = buttonData[1]
                    else
                        buttonText = "Send $$"
                        amount = buttonData
                    end
                --Show a text and open mail
                else
                    if isButtonInfoDeep then
                        if buttonData[1] == 0 or  buttonData[1] == "" then
                            buttonText = buttonData[2]
                            amount = buttonData[1]
                        end
                    else
                        if buttonData == 0 or  buttonData == "" then
                            buttonText = "Send note"
                            amount = buttonData
                        end
                    end
                end
            end
            buttons[i].amount = amount
            buttons[i]:SetText(buttonText)
        end
	end
	local showButton = createShowFeedbackWindow(parentControl)

	showButton.feedbackWindow = feedbackWindow
	showButton:SetAnchor(unpack(mailButtonPosition))
	showButton:SetDimensions(40,40)

	return showButton, feedbackWindow
end

function LibFeedback:setDebug(debugValue)
    debugValue = debugValue or false
    LibFeedback.debug = debugValue
end
