local CMX = CombatMetrics
local CMXint = CMX.internal
local util = CMXint.util
local ui = CMXint.ui
local logger

local racetextures = {
	"esoui/art/icons/heraldrycrests_race_breton_01.dds",
	"esoui/art/icons/heraldrycrests_race_redguard_01.dds",
	"esoui/art/icons/heraldrycrests_race_orc_01.dds",
	"esoui/art/icons/heraldrycrests_race_dunmer_01.dds",
	"esoui/art/icons/heraldrycrests_race_nord_01.dds",
	"esoui/art/icons/heraldrycrests_race_argonian_01.dds",
	"esoui/art/icons/heraldrycrests_race_altmer_01.dds",
	"esoui/art/icons/heraldrycrests_race_bosmer_01.dds",
	"esoui/art/icons/heraldrycrests_race_khajiit_01.dds",
	"esoui/art/icons/heraldrycrests_race_imperial_01.dds",
}

function CMXint.InitializeTitlePanel(control)
	TitlePanel = CMXint.PanelObject:New(control, "title")

	---@cast control Control
	local fightTitleControl = control:GetNamedChild("FightTitle")
	local label = fightTitleControl:GetNamedChild("Name")
	local editbox = fightTitleControl:GetNamedChild("Edit")
	fightTitleControl.tooltip = SI_COMBAT_METRICS_EDIT_TITLE

	local function OnEditTitleStart()
		label:SetHidden(true)
		editbox:SetHidden(false)

		editbox:SetText(label:GetText())
		editbox:SelectAll()
		editbox:TakeFocus()
	end

	local function OnEditTitleEnd()
		editbox:SetHidden(true)
		label:SetHidden(false)

		local newtext = editbox:GetText()

		label:SetText(newtext)

		local fightData = CMXint.fightData.data
		if fightData then fightData.fightlabel = newtext end
	end

	fightTitleControl:SetHandler("OnMouseDoubleClick", OnEditTitleStart, "CMX")
	editbox:SetHandler("OnFocusLost", OnEditTitleEnd, "CMX")

	function TitlePanel:Update(fightData)
		logger:Debug("Updating TitlePanel")

		local charInfo = control:GetNamedChild("CharacterInfo")
		local charData = {}
		local fightlabel
		local account 

		if fightData == nil then
			account = GetDisplayName()
			charData.name = GetUnitName("player")
			charData.raceId = GetUnitRaceId("player")
			charData.gender = GetUnitGender("player")
			charData.classId = GetUnitClassId("player")
			charData.level = GetUnitLevel("player")
			charData.CPtotal = GetUnitChampionPoints("player")

			fightlabel = "Combat Metrics"
		else
			charData = fightData.charData
			charData.name = charData.name or fightData.char
			fightlabel = zo_strgsub(fightData.fightlabel, ".+%:%d%d %- ([A-Z])", "%1") or ""
			account = fightData.info.accountname
		end
		
		label:SetText(fightlabel)

		-- Custom Icon

		local customIconControl = charInfo:GetNamedChild("CustomIcon")
		local customIcon = LibCustomIcons and LibCustomIcons.GetStatic(account)

		customIconControl:SetHidden(customIcon == nil)
		if customIcon then
			customIconControl:SetTexture(customIcon)
		end

		-- Char Name

		local charName = charInfo:GetNamedChild("Charname")
		
		local customName = LibCustomNames and LibCustomNames.Get(account, true)
		local name = customName or charData.name

		charName:SetText(name)

		-- CPValue

		local CPIcon = charInfo:GetNamedChild("CPIcon")
		local CPValue = charInfo:GetNamedChild("CPValue")

		local level = charData.level
		local CP = charData.CPtotal

		if level == nil or level == 0 then
			CPIcon:SetHidden(true)
			CPValue:SetHidden(true)
		elseif level < 50 then
			CPIcon:SetHidden(true)
			CPValue:SetHidden(false)
			CPValue:SetText(level)
		else
			CPIcon:SetHidden(false)
			CPValue:SetHidden(false)
			CPValue:SetText(CP)
		end

		local classInfo = control:GetNamedChild("ClassInfo")

		-- Race Icon

		local raceIcon = classInfo:GetNamedChild("RaceIcon")
		local raceId = charData.raceId
		local gender = charData.gender

		raceIcon:SetHidden(raceId == nil)
		raceIcon:SetTexture(racetextures[raceId])

		local race = GetRaceName(gender, raceId)
		raceIcon.tooltip = race

		-- Class Icon

		local classIcon = classInfo:GetNamedChild("ClassIcon")
		local classId = charData.classId
		local class = GetClassName(gender, classId)
		local texture = ZO_GetGamepadClassIcon(classId)

		classIcon:SetTexture(texture)
		classIcon.tooltip = class
		classIcon:SetHidden(false)

		-- Subclass Icons:

		local subClassingLines = SKILLS_DATA_MANAGER.activeClassSkillLineDataList
		for i = 1,3 do
			local lineData = subClassingLines[i]
			local iconControl = classInfo:GetNamedChild("SubClassIcon" .. i)
			---@cast iconControl TextureControl
			iconControl.tooltip = ZO_CachedStrFormat(SI_SKILLS_ENTRY_LINE_NAME_FORMAT, lineData:GetName())

			local texture = lineData:GetSkillDataByIndex(3):GetProgressionData(0).icon
			iconControl:SetTexture(texture)
		end
	end
end

local isFileInitialized = false
function CMXint.InitializeTitle()
	if isFileInitialized == true then return false end
	logger = util.initSublogger("TitlePanel")
	isFileInitialized = true
	return true
end
