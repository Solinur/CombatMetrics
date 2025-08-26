local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger


local labelcolors = {
	[CHAMPION_DISCIPLINE_TYPE_COMBAT] = GetString(SI_COMBAT_METRICS_MAGICKA_COLOR),
	[CHAMPION_DISCIPLINE_TYPE_CONDITIONING] = GetString(SI_COMBAT_METRICS_HEALTH_COLOR),
	[CHAMPION_DISCIPLINE_TYPE_WORLD] = GetString(SI_COMBAT_METRICS_STAMINA_COLOR),
}

local starcolors = {
	[CHAMPION_DISCIPLINE_TYPE_COMBAT] = ZO_ColorDef:New(0.8, 0.8, 1),
	[CHAMPION_DISCIPLINE_TYPE_CONDITIONING] = ZO_ColorDef:New(1, 0.80, 0.8),
	[CHAMPION_DISCIPLINE_TYPE_WORLD] = ZO_ColorDef:New(0.8, 1, 0.7),
}

---@param t table
---@param a any key1
---@param b any key2
---@return boolean isHigher
local function starOrder(t, a, b)
	local typeA = t[a][2]
	local typeB = t[b][2]

	if typeA > typeB or (typeA == typeB and a < b) then return true end
	return false
end

local function SetStarControlEmpty(starControl)
	starControl:GetNamedChild("Icon"):SetHidden(true)
	starControl:GetNamedChild("Name"):SetHidden(true)
	starControl:GetNamedChild("Value"):SetHidden(true)
	starControl:GetNamedChild("Ring"):SetTexture("/esoui/art/champion/actionbar/champion_bar_slot_frame_disabled.dds")

	starControl.slotted = nil
	starControl.starId = nil
	starControl.points = nil
end

local ChampionPointsPanel = CMXint.PanelObject:New("ChampionPoints", CombatMetrics_Report_SetupPanelChampionPointsPanel)

function ChampionPointsPanel:Update(fightData)
	logger:Debug("Updating Champion Points Panel")
	if fightData == nil then return end
	local CPData = fightData.CP
	if CPData == nil then return end

	self:SetHidden(false)
	local scrollchild = GetControl(self.control, "PanelScrollChild")

	for disciplineId, discipline in pairs(CPData) do
		if type(discipline) == "table" then
			local constellationControl = scrollchild:GetNamedChild("Panel"..disciplineId)
			local itemNo = 1
			local title = constellationControl:GetNamedChild("Title")
			local top = title:GetTop()
			local disciplineName = zo_strformat(SI_CHAMPION_CONSTELLATION_NAME_FORMAT, GetChampionDisciplineName(disciplineId))

			title:SetText(ZO_CachedStrFormat("<<1>> (<<2>>)", disciplineName, discipline.total))

			for starId, starData in CMX.spairs(discipline.stars, starOrder) do
				local points, state = unpack(starData)

				if state == LIBCOMBAT_CPTYPE_SLOTTED then -- slotted
					local starControl = constellationControl:GetNamedChild("StarControl" .. itemNo)
					starControl:GetNamedChild("Icon"):SetHidden(false)
					starControl:GetNamedChild("Ring"):SetTexture("/esoui/art/champion/actionbar/champion_bar_slot_frame.dds")

					local nameControl = starControl:GetNamedChild("Name")
					local valueControl = starControl:GetNamedChild("Value")

					nameControl:SetHidden(false)
					nameControl:SetText(zo_strformat(SI_CHAMPION_CONSTELLATION_NAME_FORMAT, GetChampionSkillName(starId)))

					valueControl:SetHidden(false)
					valueControl:SetText(points)

					starControl.slotted = true
					starControl.starId = starId
					starControl.points = points
					itemNo = itemNo + 1

				elseif state == LIBCOMBAT_CPTYPE_PASSIVE then
					if itemNo <= 4 then
						for i = itemNo, 4 do
							local starControl = constellationControl:GetNamedChild("StarControl" .. i)
							SetStarControlEmpty(starControl)
						end

						itemNo = 5
					end

					local starControl = constellationControl:GetNamedChild("StarControl" .. itemNo)
					if starControl == nil then break end
					starControl:SetHidden(false)
					starControl:GetNamedChild("Ring"):SetHidden(true)

					local starLabel = starControl:GetNamedChild("Name")
					starLabel:SetText(zo_strformat(SI_CHAMPION_CONSTELLATION_NAME_FORMAT, GetChampionSkillName(starId)))
					starLabel:SetHidden(false)
					
					local starIcon = starControl:GetNamedChild("Icon")
					starIcon:SetTextureCoords(0.25, 0.5, 0.25, 0.5)
					starIcon:SetHidden(false)
					
					local starValue = starControl:GetNamedChild("Value")
					starValue:SetText(points)
					starValue:SetHidden(false)
					
					starControl.slotted = false
					starControl.starId = starId
					starControl.points = points
					itemNo = itemNo + 1
				end
			end
			if itemNo <= 4 then
				for i = itemNo, 4 do
					local starControl = constellationControl:GetNamedChild("StarControl" .. i)
					SetStarControlEmpty(starControl)
				end
				itemNo = 5
			end
			local bottom = constellationControl:GetNamedChild("StarControl" .. (itemNo-1)):GetBottom()
			constellationControl:SetHeight(bottom-top)

			local starControl = constellationControl:GetNamedChild("StarControl" .. itemNo)
			while starControl do
				starControl:SetHidden(true)
				SetStarControlEmpty(starControl)
				itemNo = itemNo + 1
				starControl = constellationControl:GetNamedChild("StarControl" .. itemNo)
			end
		end
	end
end

function ChampionPointsPanel:InitRows()
	local scrollchild = GetControl(self.control, "ScrollChild")
	scrollchild:SetResizeToFitPadding(0, 20)
	scrollchild:SetAnchor(TOPRIGHT, nil, TOPRIGHT, 0, 0)
	local currentanchor = {TOPLEFT, scrollchild, TOPLEFT, 0, dx}
	local currentanchor2 = {TOPRIGHT, scrollchild, TOPRIGHT, 0, dx}

	for disciplineId = 1,3 do
		local disciplineType = GetChampionDisciplineType(disciplineId)
		local color = labelcolors[disciplineType]

		local selfName = scrollchild:GetName() .. "Panel" .. disciplineId
		local constellationControl = _G[selfName] or CreateControlFromVirtual(selfName, scrollchild, "CombatMetrics_ConstellationTemplate")
		constellationControl:SetAnchor(unpack(currentanchor))
		constellationControl:SetAnchor(unpack(currentanchor2))
		constellationControl:SetHidden(false)

		currentanchor = {TOPLEFT, constellationControl, BOTTOMLEFT, 0, 4}
		currentanchor2 = {TOPRIGHT, constellationControl, BOTTOMRIGHT, 0, 4}

		local title = constellationControl:GetNamedChild("Title")
		local top = title:GetTop()
		title:SetText(zo_strformat(SI_CHAMPION_CONSTELLATION_NAME_FORMAT, GetChampionDisciplineName(disciplineId)))

		local nameBase = constellationControl:GetName() .. "StarControl"
		local anchor

		for i = 1, 24 do
			local starControl = CreateControlFromVirtual(nameBase, constellationControl, "CombatMetrics_StarTemplate", i)

			if i == 1 then
				starControl:SetAnchor(TOPLEFT, title, BOTTOMLEFT, 0, 4)
			elseif i%2 == 0 then
				starControl:SetAnchor(TOPLEFT, anchor, TOPRIGHT, 7, 0)
			elseif i%2 == 1 then
				starControl:SetAnchor(TOPRIGHT, anchor, BOTTOMLEFT, -7, 2)
			end

			anchor = starControl
			local coords = {0.75, 1, 0.5, 0.75}

			if i > 4 then
				coords = {0.25, 0.5, 0.25, 0.5}
				starControl:GetNamedChild("Ring"):SetHidden(true)
				starControl:SetHidden(true)
			else
				starControl:GetNamedChild("Icon"):SetHidden(true)
				starControl:GetNamedChild("Name"):SetHidden(true)
				starControl:GetNamedChild("Value"):SetHidden(true)
			end

			local starIcon = starControl:GetNamedChild("Icon")
			starIcon:SetTextureCoords(unpack(coords))
			starIcon:SetColor(starcolors[disciplineType]:UnpackRGB())
		end
		local bottom = constellationControl:GetNamedChild("StarControl4"):GetBottom()
		constellationControl:SetHeight(bottom-top)

		CMX.SetLabelColor(constellationControl, color)
	end
end

function CMXint.CPTooltip_OnMouseEnter(starControl)
	if starControl.starId == nil then return end
	InitializeTooltip(ChampionSkillTooltip, starControl, TOPLEFT, 0, 5, BOTTOMLEFT)
	ChampionSkillTooltip:SetChampionSkill(starControl.starId, starControl.points, nil, starControl.slotted)
end

function CMXint.CPTooltip_OnMouseExit()
	ClearTooltip(ChampionSkillTooltip)
end

local isFileInitialized = false
function CMXint.InitializeChampionPoints()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("CP")

	ChampionPointsPanel:InitRows()

    isFileInitialized = true
	return true
end