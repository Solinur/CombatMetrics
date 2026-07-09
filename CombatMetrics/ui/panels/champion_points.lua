---@diagnostic disable: inject-field, undefined-field, missing-parameter
---@class CMX
local CMX = CombatMetrics
---@class CMXint
local CMXint = CMX.internal
---@class CMXutil
local util = CMXint.util
---@type Logger
local logger
---@class CMXui
local ui = CMXint.ui

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

local STAR_ROW_HEIGHT = 20
local STARS_PER_ROW = 2
local COLUMN_WIDTH = 165
local ICON_SIZE = 20
local VALUE_WIDTH = 24
local TITLE_HEIGHT = 20
local SECTION_GAP = 8
local LEFT_MARGIN = 4
local TOP_MARGIN = 4

local RING_SLOTTED = "/esoui/art/champion/actionbar/champion_bar_slot_frame.dds"
local RING_EMPTY = "/esoui/art/champion/actionbar/champion_bar_slot_frame_disabled.dds"
local STAR_ICON = "/esoui/art/champion/champion_star_pulse.dds"

-- Regions of champion_star_pulse.dds: the bright glyph for a slotted star, the dim one for a passive.
local SLOTTED_COORDS = { 0.75, 1, 0.5, 0.75 }
local PASSIVE_COORDS = { 0.25, 0.5, 0.25, 0.5 }

local function GetStarName(starId)
	return zo_strformat(SI_CHAMPION_CONSTELLATION_NAME_FORMAT, GetChampionSkillName(starId))
end

function CMXint.InitializeChampionPointsPanel(control)
	---@class ChampionPointsPanel: Panel
	local ChampionPointsPanel = CMXint.PanelObject:New(control, "championPoints")
	ChampionPointsPanel.scenes = { "info" }

	local container = control:GetNamedChild("Container")
	local scrollChild = container:GetNamedChild("ScrollChild")

	-- Leftover rows are hidden rather than released, and hidden children still count towards
	-- the auto-computed extents, so the scroll child would never shrink. Size it explicitly.
	scrollChild:SetResizeToFitDescendents(false)

	function ChampionPointsPanel:AcquireStarRow()
		local ring = self:AcquireSharedControl(CT_TEXTURE)

		local icon = self:AcquireSharedControl(CT_TEXTURE)
		icon:SetTexture(STAR_ICON)
		icon:SetMouseEnabled(true)
		icon:SetHandler("OnMouseEnter", CMXint.CPTooltip_OnMouseEnter)
		icon:SetHandler("OnMouseExit", CMXint.CPTooltip_OnMouseExit)

		local name = self:AcquireSharedControl(CT_LABEL)
		name:SetFont(ui.GetFont(ui.fontSize))
		name:SetMouseEnabled(true)
		name:SetHandler("OnMouseEnter", CMXint.CPTooltip_OnMouseEnter)
		name:SetHandler("OnMouseExit", CMXint.CPTooltip_OnMouseExit)

		local value = self:AcquireSharedControl(CT_LABEL)
		value:SetFont(ui.GetFont(ui.fontSize))
		value:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

		return { ring = ring, icon = icon, name = name, value = value }
	end

	function ChampionPointsPanel:AcquireSection()
		local title = self:AcquireSharedControl(CT_LABEL)
		title:SetFont(ui.GetFont(ui.fontSize, true))

		local separator = self:AcquireSharedControl(CT_LINE)

		return { title = title, separator = separator }
	end

	-- A section's origin depends on how many passive stars the previous discipline had,
	-- so every row is repositioned on each update rather than once when it is acquired.
	local function PositionRow(row, starIndex, y)
		local column = (starIndex - 1) % STARS_PER_ROW
		local x = LEFT_MARGIN + column * COLUMN_WIDTH
		local nameWidth = COLUMN_WIDTH - ICON_SIZE - VALUE_WIDTH - 12

		row.ring:ApplyPosition(scrollChild, x, y, ICON_SIZE, ICON_SIZE)
		row.icon:ApplyPosition(scrollChild, x + 2, y + 2, ICON_SIZE - 4, ICON_SIZE - 4)
		row.name:ApplyPosition(scrollChild, x + ICON_SIZE + 4, y, nameWidth, nil)
		row.value:ApplyPosition(scrollChild, x + COLUMN_WIDTH - VALUE_WIDTH - 4, y, VALUE_WIDTH, nil)
	end

	-- The tooltip handler reads starId/points/slotted off whichever control is hovered.
	local function SetRowTooltipData(row, starId, points, slotted)
		row.icon.starId, row.icon.points, row.icon.slotted = starId, points, slotted
		row.name.starId, row.name.points, row.name.slotted = starId, points, slotted
	end

	local function SetRowStar(row, starId, points, slotted, disciplineType)
		row.ring:SetHidden(not slotted)
		row.icon:SetHidden(false)
		row.name:SetHidden(false)
		row.value:SetHidden(false)

		if slotted then
			row.ring:SetTexture(starId > 0 and RING_SLOTTED or RING_EMPTY)
		end

		if starId > 0 then
			row.icon:SetTextureCoords(unpack(slotted and SLOTTED_COORDS or PASSIVE_COORDS))
			row.icon:SetColor(starcolors[disciplineType]:UnpackRGB())
			row.name:SetText(GetStarName(starId))
			row.value:SetText(points)
			SetRowTooltipData(row, starId, points, slotted)
		else
			-- An unused champion bar slot: keep the dim ring, drop everything else.
			row.icon:SetHidden(true)
			row.name:SetText("")
			row.value:SetText("")
			SetRowTooltipData(row, nil, nil, nil)
		end
	end

	local function HideRow(row)
		row.ring:SetHidden(true)
		row.icon:SetHidden(true)
		row.name:SetHidden(true)
		row.value:SetHidden(true)
	end

	function ChampionPointsPanel:Update()
		if not self.rows then
			return
		end

		local fightData = self:GetCurrentFightData()
		local CPData = fightData and fightData.CP

		if CPData == nil or CPData.maxSlotIndex == nil then
			self:Clear()
			return
		end

		-- Taken from the fight rather than the live game: it records the champion bar layout
		-- the fight was fought with, which a saved fight may no longer share.
		local maxSlotIndex = CPData.maxSlotIndex

		local rowIndex = 0
		local y = TOP_MARGIN

		for disciplineId = 1, #self.sections do
			local discipline = CPData[disciplineId]

			if discipline then
				local disciplineType = GetChampionDisciplineType(disciplineId)
				local section = self.sections[disciplineId]
				local color = ZO_ColorDef:New(labelcolors[disciplineType])

				section.title:SetHidden(false)
				section.title:ApplyPosition(scrollChild, LEFT_MARGIN, y, COLUMN_WIDTH * STARS_PER_ROW, nil)
				section.title:SetColor(color:UnpackRGBA())
				section.title:SetText(
					zo_strformat(SI_CHAMPION_CONSTELLATION_NAME_FORMAT, GetChampionDisciplineName(disciplineId))
				)

				section.separator:SetHidden(false)
				section.separator:ApplyPosition(
					scrollChild,
					LEFT_MARGIN,
					y + TITLE_HEIGHT + 1,
					COLUMN_WIDTH * STARS_PER_ROW,
					0
				)

				y = y + TITLE_HEIGHT + 4

				-- The champion bar slots first, then every passive star with points spent.
				local starIndex = 0
				for i = 1, #discipline, 2 do
					local slotted = i < maxSlotIndex

					starIndex = starIndex + 1
					rowIndex = rowIndex + 1

					local row = self.rows[rowIndex]
					if row == nil then
						row = self:AcquireStarRow()
						self.rows[rowIndex] = row
					end

					PositionRow(row, starIndex, y + zo_floor((starIndex - 1) / STARS_PER_ROW) * STAR_ROW_HEIGHT)
					SetRowStar(row, discipline[i], discipline[i + 1], slotted, disciplineType)
				end

				y = y + zo_ceil(starIndex / STARS_PER_ROW) * STAR_ROW_HEIGHT + SECTION_GAP
			else
				self.sections[disciplineId].title:SetHidden(true)
				self.sections[disciplineId].separator:SetHidden(true)
			end
		end

		-- Hide the rows left over from a previous, larger fight.
		for i = rowIndex + 1, #self.rows do
			HideRow(self.rows[i])
		end

		local scale = CMXint.settings.fightReport.scale
		scrollChild:SetHeight(y * scale)
		ZO_Scroll_UpdateScrollBar(container)
	end

	function ChampionPointsPanel:Recover()
		self.rows = {}
		self.sections = {}

		for disciplineId = 1, GetNumChampionDisciplines() do
			self.sections[disciplineId] = self:AcquireSection()
		end

		ZO_Scroll_ResetToTop(container)
		self:Update()
	end

	function ChampionPointsPanel:Clear()
		if not self.rows then
			return
		end

		for _, section in ipairs(self.sections) do
			section.title:SetText("")
			section.title:SetHidden(true)
			section.separator:SetHidden(true)
		end

		for _, row in ipairs(self.rows) do
			HideRow(row)
		end

		scrollChild:SetHeight(0)
		ZO_Scroll_UpdateScrollBar(container)
		ZO_Scroll_ResetToTop(container)
	end
end

function CMXint.CPTooltip_OnMouseEnter(starControl)
	if starControl.starId == nil then
		return
	end
	InitializeTooltip(ChampionSkillTooltip, starControl, TOPLEFT, 0, 5, BOTTOMLEFT)
	ChampionSkillTooltip:SetChampionSkill(starControl.starId, starControl.points, nil, starControl.slotted)
end

function CMXint.CPTooltip_OnMouseExit()
	ClearTooltip(ChampionSkillTooltip)
end

local isFileInitialized = false
function CMXint.InitializeChampionPoints()
	if isFileInitialized == true then
		return false
	end
	logger = util.initSublogger("CP")

	isFileInitialized = true
	return true
end
