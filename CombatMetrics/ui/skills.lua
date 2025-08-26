local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger

local GetFormattedAbilityIcon = CMXf.GetFormattedAbilityIcon
local GetFormattedAbilityName = CMXf.GetFormattedAbilityName

local SkillBarItems = {"LightAttack", "HeavyAttack", "Ability1", "Ability2", "Ability3", "Ability4", "Ability5", "Ultimate"}
local DisabledColor = ZO_ColorDef:New("FF999999")
local WerewolfColor = ZO_ColorDef:New("FFf3c86e")
local WhiteColor = ZO_ColorDef:New("FFFFFFFF")

local SkillStatsPanel = CMXint.PanelObject:New("Skills", CombatMetrics_Report_SetupPanelSkillsPanel)

function SkillStatsPanel:Update(fightData)
	if fightData == nil then return end

	local charData = fightData.charData
	if charData == nil then return end
		
	local data = fightData.calculated
	if data == nil then return end
	
	local panel = self.control
	local settings = self.settings
	local category = settings.category
	local skillBars = charData.skillBars
	local skilldata = data.skills
	local barStatData = data.barStats

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

				if settings.showWereWolf then
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

function SkillStatsPanel:InitializeSkillStats()
	local control = self.control

	local block = control:GetNamedChild("ActionBar1")
	local title = block:GetNamedChild("Title")
	title:SetText(GetString(SI_COMBAT_METRICS_BAR) .. 1)

	local statPanel = block:GetNamedChild("Stats2")
	local label = statPanel:GetNamedChild("Label")
	local label2 = statPanel:GetNamedChild("Label2")

	label.tooltip = {SI_COMBAT_METRICS_SKILLAVG_TT}
	label:SetText(string.format("%s    -", GetString(SI_COMBAT_METRICS_AVERAGEC)))
	label2.tooltip = {SI_COMBAT_METRICS_SKILLTOTAL_TT}
	label2:SetText(string.format("%s    -", GetString(SI_COMBAT_METRICS_TOTALC)))

	local block2 = control:GetNamedChild("ActionBar2")
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


local ScribedSkillsPanel = CMXint.PanelObject:New("ScribedSkills", CombatMetrics_Report_SetupPanelScribedSkillsPanel)

---@param setHidden boolean
function ScribedSkillsPanel:Hide(setHidden)
	local panel = self.control
	panel:SetHidden(setHidden)
	panel:GetParent():GetNamedChild("Sep"):SetHidden(setHidden)
end

function ScribedSkillsPanel:Update(fightData)
	if fightData == nil then return self:Hide(true) end
	local control = self.control
	local scribedSkills = fightData.charData.scribedSkills or {}

	local index = 0
	for abilityId, data in CMX.spairs(scribedSkills) do
		index = index + 1
		local skillControl = control:GetNamedChild(tostring(index))
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

	for i = index + 1, control:GetNumChildren() do
		control:GetNamedChild(tostring(i)):SetHidden(true)
	end

	self:Hide(index == 0)
end


function ScribedSkillsPanel:InitializeControls()
	local control = self.control
	local nameBase = control:GetName()
	local anchor
	for i = 1, 10 do
		local scribedSkillControl = CreateControlFromVirtual(nameBase, control, "CombatMetrics_ScribedSkillTemplate", i)
		-- scribedSkillControl:SetHidden(false)

		if i == 1 then
			scribedSkillControl:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 4)
		else
			scribedSkillControl:SetAnchor(TOPLEFT, anchor, BOTTOMLEFT, 0, 4)
			scribedSkillControl:SetHidden(true)
		end

		anchor = scribedSkillControl
	end
end

function CMXint.SkillbarButtonMouseOver(control, isOver)
	local bg = control:GetNamedChild("Bg")
	local alpha = isOver and 1 or 0
	bg:SetCenterColor(0.2, 0.2, 0.2, alpha)
end

function CMXint.SkillbarToggleWerewolf()
	local settings = SkillStatsPanel.settings
	settings.showWereWolf = not settings.showWereWolf
	SkillStatsPanel:Update()
end


function CMXint.SkillTooltip_OnMouseEnter(control)
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

function CMXint.SkillTooltip_Clear()
	ClearTooltip(SkillTooltip)
end

function CMXint.ScribedSkillTooltip_OnMouseEnter(control)
	if control.scriptIds == nil then return end
	local abilityId = control.abilityId
	local scriptIds = control.scriptIds

	InitializeTooltip(SkillTooltip, control, TOPLEFT, 0, 5, BOTTOMLEFT)
	SetCraftedAbilityScriptSelectionOverride(GetAbilityCraftedAbilityId(abilityId), scriptIds[1], scriptIds[2], scriptIds[3])
	SkillTooltip:SetAbilityId(abilityId)
end


local isFileInitialized = false
function CMXint.InitializeSkillsPanel()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("Skills")

	SkillStatsPanel:InitializeSkillStats()
	ScribedSkillsPanel:InitializeControls()

    isFileInitialized = true
	return true
end