local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger
local currentCLPage
local toggleCopyPaste

local fontSize = CMXint.fontSize
local GetFormattedAbilityName = CMXf.GetFormattedAbilityName

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



local function CLNavButtonFunction(self)
	currentCLPage = tonumber(self.value or (currentCLPage + self.func))
	self:GetParent():GetParent():GetParent():Update()
end

function CMX.InitCLNavButtonRow(rowControl)
	for i = 1, rowControl:GetNumChildren() do
		local button = rowControl:GetChild(i)
		if button.texture then button:GetNamedChild("Icon"):SetTexture(button.texture) end

		local value = button.value
		if value then
			button:GetNamedChild("Label"):SetText(value)
			button.tooltip = { zo_strformat(SI_COMBAT_METRICS_PAGE, value) }
		end

		button:SetHandler("OnMouseUp", CLNavButtonFunction)
	end
end

local function CLFilterButtonFunction(self)
	local overlay = self:GetNamedChild("Overlay")
	local func = self.func

	local settings = CMXint.settings.fightReport
	local CLSelection = settings.CLSelection

	local newState = not CLSelection[func] -- Update Filter Selection
	CLSelection[func] = newState

	overlay:SetCenterColor(0, 0, 0, newState and 0 or 0.8) -- Switch Button overlay (active = button darkened)
	overlay:SetEdgeColor(1, 1, 1, newState and 1 or .4)

	if func ~= "CopyPaste" and CLSelection["CopyPaste"] then
		toggleCopyPaste(self:GetParent():GetNamedChild("CopyPaste"))
	end

	self:GetParent():GetParent():GetParent():Update()
end

function toggleCopyPaste(self)
	local combatLog = self:GetParent():GetParent():GetParent()
	local settings = CMXint.settings.fightReport

	---@type TextBufferControl
	local textWindow = combatLog:GetNamedChild("Window")
	---@type EditControl
	local copyPasteBox = combatLog:GetNamedChild("CopyPasteBox")
	copyPasteBox:SetFont(string.format("%s|%s|%s", GetString(SI_COMBAT_METRICS_STD_FONT),
		tonumber(GetString(SI_COMBAT_METRICS_FONT_SIZE)) * settings.scale, ""))

	if textWindow:IsHidden() then
		textWindow:SetHidden(false)
		copyPasteBox:SetHidden(true)
	else
		textWindow:SetHidden(true)
		copyPasteBox:SetHidden(false)
	end

	CLFilterButtonFunction(self)
end



local function adjustSlider(self)
	local buffer = self:GetNamedChild("Buffer")
	local slider = self:GetNamedChild("Slider")

	local numHistoryLines = buffer:GetNumHistoryLines()
	local numVisHistoryLines = buffer:GetNumVisibleLines() --it seems numVisHistoryLines is getting screwed by UI Scale

	local sliderMin, sliderMax = slider:GetMinMax()
	local sliderValue = slider:GetValue()

	slider:SetMinMax(numVisHistoryLines, numHistoryLines)


	if sliderValue == sliderMax then                                              -- If the sliders at the bottom, stay at the bottom to show new text
		slider:SetValue(numHistoryLines)
	elseif numHistoryLines == self:GetNamedChild("Buffer"):GetMaxHistoryLines() then -- If the buffer is full start moving the slider up
		slider:SetValue(sliderValue - 1)
	end                                                                           -- Else the slider does not move


	if numHistoryLines > numVisHistoryLines then -- If there are more history lines than visible lines show the slider
		slider:SetHidden(false)
		slider:SetThumbTextureHeight(zo_max(20,
			zo_floor(numVisHistoryLines / numHistoryLines * self:GetNamedChild("Slider"):GetHeight())))
	else -- else hide the slider
		slider:SetHidden(true)
	end
end

local function addColoredText(control, text, color)
	if not text or #color ~= 3 then return end

	local red   = color[1] or 1
	local green = color[2] or 1
	local blue  = color[3] or 1

	control:GetNamedChild("Buffer"):AddMessage(text, red, green, blue) -- Add message first
	if control:GetNamedChild("Slider") then adjustSlider(control) end -- Set new slider value & check visibility
end

function CMXf.InitCombatLog(control)
	control.AddColoredText = addColoredText

	local buffer = control:GetNamedChild("Buffer")
	local slider = control:GetNamedChild("Slider")

	buffer:SetHandler("OnMouseWheel", function(self, delta, ctrl, alt, shift)
		local offset = delta
		local slider = buffer:GetParent():GetNamedChild("Slider")

		if shift then
			offset = offset * zo_floor((buffer:GetNumVisibleLines()))
		elseif ctrl then
			offset = offset * buffer:GetNumHistoryLines()
		end

		buffer:SetScrollPosition(zo_min(buffer:GetScrollPosition() + offset,
			zo_floor(buffer:GetNumHistoryLines() - buffer:GetNumVisibleLines())))

		slider:SetValue(slider:GetValue() - offset)
	end)

	slider:SetHandler("OnValueChanged", function(self, value, eventReason)
		local numHistoryLines = buffer:GetNumHistoryLines()
		local sliderValue = zo_max(slider:GetValue(), zo_floor((buffer:GetNumVisibleLines() + 1)))

		if eventReason == EVENT_REASON_HARDWARE then
			buffer:SetScrollPosition(numHistoryLines - sliderValue)
		end
	end)

	-- Assign Button Functions

	local scrollUp = slider:GetNamedChild("ScrollUp")
	local scrollDown = slider:GetNamedChild("ScrollDown")
	local scrollEnd = slider:GetNamedChild("ScrollEnd")

	scrollUp:SetHandler("OnMouseDown", function(...)
		buffer:SetScrollPosition(zo_min(buffer:GetScrollPosition() + 1,
			zo_floor(buffer:GetNumHistoryLines() - buffer:GetNumVisibleLines())))
		slider:SetValue(slider:GetValue() - 1)
	end)

	scrollDown:SetHandler("OnMouseDown", function(...)
		buffer:SetScrollPosition(buffer:GetScrollPosition() - 1)
		slider:SetValue(slider:GetValue() + 1)
	end)

	scrollEnd:SetHandler("OnMouseDown", function(...)
		buffer:SetScrollPosition(0)
		slider:SetValue(buffer:GetNumHistoryLines())
	end)
end

function CMXint.InitializeCombatLogPanel(control)
	if true then return end

	-- TODO: refactor

	CombatLogPanel = CMX.internal.PanelObject:New(control, "combatLog")
	local settings = CombatLogPanel.settings
	local currentCLPage = 1

	function CombatLogPanel:Update(fightData)
		if fightData == nil or self:IsHidden() then return end

		logger:Debug("Updating CombatLog")
		local CLSelection = settings.CLSelection

		local window = control:GetNamedChild("Window")
		local copyPasteBox = control:GetNamedChild("CopyPasteBox")
		local buffer = window:GetNamedChild("Buffer")
		local slider = window:GetNamedChild("Slider")

		local logdata = fightData.log or {}
		local loglength = #logdata

		local isCopyPasteMode = buffer:IsHidden()
		local lastLine = buffer:GetNumHistoryLines() - buffer:GetScrollPosition()
		local firstLine = lastLine - buffer:GetNumVisibleLines()
		local copyPasteText = {}

		buffer:Clear()
		if loglength == 0 then return end

		buffer:SetMaxHistoryLines(zo_min(loglength, 1000))
		buffer:SetFont(string.format("%s|%s|%s", GetString(SI_COMBAT_METRICS_STD_FONT),
			tonumber(GetString(SI_COMBAT_METRICS_FONT_SIZE)) * settings.scale, ""))

		local maxpage = zo_ceil(loglength / 1000)
		local page = zo_clamp(currentCLPage, 1, maxpage)

		local writtenlines = 0

		local selections = CMXint.selections
		local unitSelection = selections.unit
		local abilitySelection = selections.ability
		local buffSelection = selections.buff.buff
		local resourceSelection = selections.resource.resource

		local unitSelectionAll = {}

		local unitsSelected = false

		for _, category in pairs({ "healingIn", "healingOut", "damageIn", "damageOut" }) do
			local subcategory = unitSelection[category]

			if subcategory ~= nil then
				for unitId, bool in pairs(subcategory) do
					unitSelectionAll[unitId] = bool
					unitsSelected = true
				end
			end
		end

		for k, logline in ipairs(logdata) do
			local condition2 = false
			local logtype = logline[1]

			local condition1 =
				CLSelection[logtype]
				or
				(logtype == LIBCOMBAT_EVENT_DAMAGE_SELF and (CLSelection[LIBCOMBAT_EVENT_DAMAGE_IN] or CLSelection[LIBCOMBAT_EVENT_DAMAGE_OUT]))
				or
				(logtype == LIBCOMBAT_EVENT_HEAL_SELF and (CLSelection[LIBCOMBAT_EVENT_HEAL_IN] or CLSelection[LIBCOMBAT_EVENT_HEAL_OUT]))
				or (logtype == LIBCOMBAT_EVENT_BOSSHP and (CLSelection[LIBCOMBAT_EVENT_MESSAGES]))
				or (logtype == LIBCOMBAT_EVENT_DEATH and (CLSelection[LIBCOMBAT_EVENT_MESSAGES]))

			if condition1 == true then
				local category = logtypeCategories[logtype]
				local unitSelCat = unitSelection[category]

				if logtype == LIBCOMBAT_EVENT_DAMAGE_IN or logtype == LIBCOMBAT_EVENT_DAMAGE_OUT or logtype == LIBCOMBAT_EVENT_HEAL_IN or logtype == LIBCOMBAT_EVENT_HEAL_OUT then
					local sourceUnitId = logline[4]
					local targetUnitId = logline[5]
					local abilityId = logline[6]

					condition2 = (

						unitSelCat == nil
						or (unitSelCat[targetUnitId] ~= nil and (logtype == LIBCOMBAT_EVENT_HEAL_OUT or logtype == LIBCOMBAT_EVENT_DAMAGE_OUT))
						or (unitSelCat[sourceUnitId] ~= nil and (logtype == LIBCOMBAT_EVENT_HEAL_IN or logtype == LIBCOMBAT_EVENT_DAMAGE_IN))
					) and (
						abilitySelection[category] == nil
						or abilitySelection[category][abilityId] ~= nil
					)
				elseif logtype == LIBCOMBAT_EVENT_HEAL_SELF then
					local sourceUnitId = logline[4]
					local targetUnitId = logline[5]
					local abilityId = logline[6]

					condition2 = (

						(unitSelection.healingIn == nil and CLSelection[LIBCOMBAT_EVENT_HEAL_IN])
						or (unitSelection.healingIn ~= nil and unitSelection.healingIn[sourceUnitId] ~= nil)
						or (unitSelection.healingOut == nil and CLSelection[LIBCOMBAT_EVENT_HEAL_OUT])
						or (unitSelection.healingOut ~= nil and unitSelection.healingOut[targetUnitId] ~= nil)
					) and (
						(abilitySelection.healingIn == nil and CLSelection[LIBCOMBAT_EVENT_HEAL_IN])
						or (abilitySelection.healingIn ~= nil and abilitySelection.healingIn[abilityId] ~= nil)
						or (abilitySelection.healingOut == nil and CLSelection[LIBCOMBAT_EVENT_HEAL_OUT])
						or (abilitySelection.healingOut ~= nil and abilitySelection.healingOut[abilityId] ~= nil)
					)
				elseif logtype == LIBCOMBAT_EVENT_EFFECTS_IN or logtype == LIBCOMBAT_EVENT_EFFECTS_OUT or logtype == LIBCOMBAT_EVENT_GROUPEFFECTS_IN or logtype == LIBCOMBAT_EVENT_GROUPEFFECTS_OUT then
					local unitId = logline[3]
					local abilityId = logline[4]

					local ability = GetFormattedAbilityName(abilityId)

					condition2 = (
							buffSelection == nil and unitsSelected == false)
						or (buffSelection ~= nil and buffSelection[ability] ~= nil and unitsSelected == false)
						or (buffSelection == nil and unitSelectionAll[unitId] ~= nil)
						or (buffSelection ~= nil and buffSelection[ability] ~= nil and unitsSelected == true and unitSelectionAll[unitId] ~= nil
						)
				elseif logtype == LIBCOMBAT_EVENT_RESOURCES then
					local abilityId = logline[3]
					local powerType = logline[5]

					condition2 = powerType ~= POWERTYPE_HEALTH and
						(resourceSelection == nil or resourceSelection[abilityId or 0] ~= nil)
				elseif logtype == LIBCOMBAT_EVENT_PLAYERSTATS or logtype == LIBCOMBAT_EVENT_MESSAGES or logtype == LIBCOMBAT_EVENT_SKILL_TIMINGS or logtype == LIBCOMBAT_EVENT_BOSSHP or logtype == LIBCOMBAT_EVENT_DEATH or logtype == LIBCOMBAT_EVENT_PERFORMANCE then
					condition2 = true
				end

				if condition2 == true then
					writtenlines = writtenlines + 1
					if isCopyPasteMode then
						if writtenlines >= (page - 1) * 1000 + firstLine and writtenlines <= (page - 1) * 1000 + lastLine then
							local text, color = CMX.GetCombatLogString(fightData, logline, fontSize)
							copyPasteText[#copyPasteText + 1] = text:gsub("|c......", ""):gsub("|r", ""):gsub("|t.-|t ",
								"")
						end
					else
						if writtenlines > (page - 1) * 1000 and writtenlines <= page * 1000 then
							local text, color = CMX.GetCombatLogString(fightData, logline, fontSize)
							window:AddColoredText(text, color)
						end
					end
				end
			end
		end

		maxpage = zo_max(zo_ceil(writtenlines / 1000), 1)
		local buttonrow = GetControl(control, "HeaderPageButtonRow")

		buttonrow:Update(page, maxpage)
		local totalLines = buffer:GetNumHistoryLines()

		buffer:SetScrollPosition(zo_min(buffer:GetScrollPosition() + totalLines,
			zo_floor(buffer:GetNumHistoryLines() - buffer:GetNumVisibleLines())))
		slider:SetValue(slider:GetValue() - totalLines)

		if isCopyPasteMode then
			local text = table.concat(copyPasteText, "\n")
			copyPasteBox:SetText(text)
			copyPasteBox:SelectAll(text)
			copyPasteBox:TakeFocus()
		end
	end

	CombatLogPanel.currentCLPage = 1
	local combatLogFilterButtonRow = GetControl(CombatLogPanel.control, "HeaderFilterButtonRow")
	local CLSelection = settings.CLSelection

	for i = 1, combatLogFilterButtonRow:GetNumChildren() do
		local button = combatLogFilterButtonRow:GetChild(i)

		if button.texture then button:GetNamedChild("Icon"):SetTexture(button.texture) end
		if button.label then button:GetNamedChild("Label"):SetText(button.label) end

		local func = (button.func == "CopyPaste") and toggleCopyPaste or CLFilterButtonFunction
		button:SetHandler("OnMouseUp", func)

		CLSelection["CopyPaste"] = false
		local selected = CLSelection[button.func]
		local overlay = button:GetNamedChild("Overlay")

		overlay:SetCenterColor(0, 0, 0, selected and 0 or 0.8)
		overlay:SetEdgeColor(1, 1, 1, selected and 1 or .5)
	end

	
	function CombatLogPanel:UpdatePageButtons(page, maxpage)
		local buttonrow = GetControl(self.control, "HeaderPageButtonRow")

		local first = zo_max(page - 2, 1)
		local last = first + 4

		buttonrow:GetNamedChild("PageLeft"):SetHidden(page == 1)
		buttonrow:GetNamedChild("PageRight"):SetHidden(page >= maxpage)

		for i = first, last do
			local key = "Page" .. (i - first + 1)

			local button = buttonrow:GetNamedChild(key)

			button.tooltip = { zo_strformat(SI_COMBAT_METRICS_PAGE, i) }
			button.value = i

			button:SetHidden(i > maxpage)

			buttonrow:GetNamedChild(key .. "Label"):SetText(i)

			local bg = buttonrow:GetNamedChild(key .. "Overlay")

			bg:SetCenterColor(0, 0, 0, page == i and 0 or 0.8)
			bg:SetEdgeColor(1, 1, 1, page == i and 1 or .4)
		end
	end	
end

local isFileInitialized = false
function CMXint.InitializeCombatLog()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("Combat Log Panel")

	isFileInitialized = true
	return true
end
