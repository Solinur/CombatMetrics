local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger

function CMXint.InitializeTitlePanel(control)
	TitlePanel = CMXint.PanelObject:New(control, "title")
	function TitlePanel:Update(fightData)
		logger:Debug("Updating TitlePanel")

		-- update character info

		local charInfo = self:GetNamedChild("CharacterInfo")
		local charData = {}
		local fightlabel

		if fightData == nil then
			charData.name = GetUnitName("player")
			charData.raceId = GetUnitRaceId("player")
			charData.gender = GetUnitGender("player")
			charData.classId = GetUnitClassId("player")
			charData.level = GetUnitLevel("player")
			charData.CPtotal = GetUnitChampionPoints("player")

			fightlabel = "Combat Metrics"
		elseif (fightData.charData == nil or fightData.charData.classId == nil) and fightData.char == GetUnitName("player") then -- legacy
			charData.name = fightData.char
			charData.raceId = GetUnitRaceId("player")
			charData.gender = GetUnitGender("player")
			charData.classId = GetUnitClassId("player")
			charData.level = 0
			charData.CPtotal = 0

			fightData.charData = charData
			fightlabel = zo_strgsub(fightData.fightlabel, ".+%:%d%d %- ([A-Z])", "%1") or ""
		else
			charData = fightData.charData or {}
			charData.name = charData.name or fightData.char
			fightlabel = zo_strgsub(fightData.fightlabel, ".+%:%d%d %- ([A-Z])", "%1") or ""
		end

		-- RaceIcon

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

		local raceIcon = charInfo:GetNamedChild("RaceIcon")
		local raceId = charData.raceId
		local gender = charData.gender

		raceIcon:SetHidden(raceId == nil)
		raceIcon:SetTexture(racetextures[raceId])

		local race = GetRaceName(gender, raceId)
		raceIcon.tooltip = race

		-- ClassIcon

		local classIcon = charInfo:GetNamedChild("ClassIcon")
		local classId = charData.classId

		for i = 1, GetNumClasses() do
			local id, _, _, _, _, _, texture = GetClassInfo(i)

			if id == classId then
				local class = GetClassName(gender, id)

				classIcon:SetTexture(texture)
				classIcon.tooltip = { class }
				classIcon:SetHidden(false)

				break
			end

			classIcon:SetHidden(true)
		end

		-- charName

		local charName = charInfo:GetNamedChild("Charname")
		local name = charData.name

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

		-- Fight Title

		local fightTitle = self:GetNamedChild("FightTitle"):GetNamedChild("Name")
		fightTitle:SetText(fightlabel)
	end
end


local isFileInitialized = false
function CMXint.InitializeTitle()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("TitlePanel")
	isFileInitialized = true
	return true
end
