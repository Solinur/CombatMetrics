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

local GetFormattedAbilityIcon = util.GetFormattedAbilityIcon
local GetFormattedAbilityName = util.GetFormattedAbilityName

local BARS_PER_PAGE = 2
local SKILL_ROW_HEIGHT = 24
local ICON_SIZE = 22
local TITLE_HEIGHT = 20
local COLUMN_WIDTH = 300
local COLUMN_GAP = 14
local LEFT_MARGIN = 6
local TOP_MARGIN = 4

local UNKNOWN_ICON = "EsoUI/Art/crafting/gamepad/crafting_alchemy_trait_unknown.dds"
local ABILITY_FRAME = "EsoUI/Art/ActionBar/abilityframe64_up.dds"
local PAGE_ARROW = "EsoUI/Art/Buttons/large_rightArrow_up.dds"
local PAGE_ARROW_DOWN = "EsoUI/Art/Buttons/large_rightArrow_down.dds"
local PAGE_ARROW_OVER = "EsoUI/Art/Buttons/large_rightArrow_over.dds"

-- Slot render order within a bar: weapon-bound slots (1, 2), the five ability
-- slots (3-7) and the ultimate (8). See LibCombat GetBarData in fights.lua.
local SLOT_ORDER = { 1, 2, 3, 4, 5, 6, 7, 8 }

local SCRIBED_SKILL_COUNT = 10

-- Scribed skill row layout (mirrors CombatMetrics_ScribedSkillTemplate in templates.xml):
-- a framed ability icon + name, with three script sub-rows (small icon + name).
local SCRIBED_ROW_HEIGHT = 35
local SCRIBED_ROW_GAP = 4
local SCRIBED_ROW_X = 4
local SCRIBED_TOP = 4
local SCRIBED_ICON_SIZE = 18
local SCRIBED_NAME_X = SCRIBED_ROW_X + SCRIBED_ICON_SIZE + 4
local SCRIBED_NAME_WIDTH = 154
local SCRIBED_SCRIPT_X = SCRIBED_NAME_X + SCRIBED_NAME_WIDTH + 4
local SCRIBED_SCRIPT_ROW2_Y = SCRIBED_ICON_SIZE + 1
local SCRIBED_SCRIPT_ICON_SIZE = 16
local SCRIBED_SCRIPT_NAME_WIDTH = 120
local SCRIBED_BOTTOM = 4
local SCRIBED_EMPTY_HEIGHT = SCRIBED_TOP + SCRIBED_ICON_SIZE + SCRIBED_BOTTOM

local function GetBarName(category, barNumber)
	local name = GetString("SI_HOTBARCATEGORY", category)
	if name == nil or name == "" then
		return string.format("%s%d", GetString(SI_COMBAT_METRICS_BAR), barNumber)
	end
	return name
end

function CMXint.InitializeSkillsPanel(control)
	---@class SkillsPanel: Panel
	local SkillsPanel = CMXint.PanelObject:New(control, "skills")
	SkillsPanel.scenes = { "info" }
	SkillsPanel.page = 1

	function SkillsPanel:RecoverSkillLine(parent, x, y)
		local iconBg = self:AcquireSharedControl(CT_TEXTURE)
		iconBg:ApplyPosition(parent, x, y, ICON_SIZE, ICON_SIZE)
		iconBg:SetTexture(ABILITY_FRAME)

		local icon = self:AcquireSharedControl(CT_TEXTURE)
		icon:ApplyPosition(parent, x + 2, y + 2, ICON_SIZE - 4, ICON_SIZE - 4)
		icon:SetMouseEnabled(true)
		icon:SetHandler("OnMouseEnter", CMXint.SkillTooltip_OnMouseEnter)
		icon:SetHandler("OnMouseExit", CMXint.SkillTooltip_Clear)

		local labelX = x + ICON_SIZE + 4
		local label = self:AcquireSharedControl(CT_LABEL)
		label:ApplyPosition(parent, labelX, y, COLUMN_WIDTH - ICON_SIZE - 8, nil)
		label:SetFont(ui.GetFont(ui.fontSize))
		label:SetMouseEnabled(true)
		label:SetHandler("OnMouseEnter", CMXint.SkillTooltip_OnMouseEnter)
		label:SetHandler("OnMouseExit", CMXint.SkillTooltip_Clear)

		return { iconBg = iconBg, icon = icon, label = label }
	end

	function SkillsPanel:RecoverColumn(columnIndex)
		local x = LEFT_MARGIN + (columnIndex - 1) * (COLUMN_WIDTH + COLUMN_GAP)
		local y = TOP_MARGIN

		local title = self:AcquireSharedControl(CT_LABEL)
		title:ApplyPosition(self.control, x, y, COLUMN_WIDTH, nil)
		title:SetFont(ui.GetFont(ui.fontSize, true))

		local separator = self:AcquireSharedControl(CT_LINE)
		separator:ApplyPosition(self.control, x, y + TITLE_HEIGHT + 1, COLUMN_WIDTH, 0)

		local lines = {}
		y = y + TITLE_HEIGHT + 4
		for _, slot in ipairs(SLOT_ORDER) do
			lines[slot] = self:RecoverSkillLine(self.control, x, y)
			y = y + SKILL_ROW_HEIGHT
		end

		-- Divider below the skills; a stats section will go here later.
		local bottomSeparator = self:AcquireSharedControl(CT_LINE)
		bottomSeparator:ApplyPosition(self.control, x, y + 2, COLUMN_WIDTH, 0)

		return { title = title, separator = separator, bottomSeparator = bottomSeparator, lines = lines }
	end

	function SkillsPanel:Recover()
		self.columns = {}
		for columnIndex = 1, BARS_PER_PAGE do
			self.columns[columnIndex] = self:RecoverColumn(columnIndex)
		end

		-- Vertical divider between the two bar columns.
		local centerX = LEFT_MARGIN + COLUMN_WIDTH + COLUMN_GAP / 2
		local contentHeight = TITLE_HEIGHT + 4 + #SLOT_ORDER * SKILL_ROW_HEIGHT
		self.centerSeparator = self:AcquireSharedControl(CT_LINE)
		self.centerSeparator:ApplyPosition(self.control, centerX, TOP_MARGIN, 0, contentHeight)

		self:Update()
	end

	function SkillsPanel:NextPage()
		self.page = self.page + 1
		self:Update()
	end

	local function UpdateLine(line, abilityId, showRow)
		line.iconBg:SetHidden(not showRow)
		line.icon:SetHidden(not showRow)
		line.label:SetHidden(not showRow)
		if not showRow then
			return
		end

		if abilityId and abilityId > 0 then
			line.icon:SetTexture(GetFormattedAbilityIcon(abilityId))
			line.label:SetText(GetFormattedAbilityName(abilityId))
			line.icon.abilityId = abilityId
			line.label.abilityId = abilityId
		else
			line.icon:SetTexture(UNKNOWN_ICON)
			line.label:SetText("")
			line.icon.abilityId = nil
			line.label.abilityId = nil
		end
	end

	function SkillsPanel:Update()
		if not self.columns then
			return
		end

		local fightData = self:GetCurrentFightData()
		local skills = fightData and fightData.skills
		local skillBars = skills and skills.skillBars

		-- Ordered list of the hotbar categories actually present.
		local bars = {}
		if skillBars then
			for category in pairs(skillBars) do
				bars[#bars + 1] = category
			end
			table.sort(bars)
		end

		local numBars = #bars
		local numPages = math.max(1, math.ceil(numBars / BARS_PER_PAGE))
		if self.page > numPages then
			self.page = 1
		elseif self.page < 1 then
			self.page = numPages
		end

		self.pageButton:SetHidden(numPages <= 1)

		local baseIndex = (self.page - 1) * BARS_PER_PAGE

		for columnIndex = 1, BARS_PER_PAGE do
			local column = self.columns[columnIndex]
			local barListIndex = baseIndex + columnIndex
			local category = bars[barListIndex]
			local bar = category and skillBars[category] or nil

			column.title:SetHidden(bar == nil)
			column.separator:SetHidden(bar == nil)
			column.bottomSeparator:SetHidden(bar == nil)
			if bar then
				column.title:SetText(GetBarName(category, barListIndex))
			end

			for _, slot in ipairs(SLOT_ORDER) do
				UpdateLine(column.lines[slot], bar and bar[slot] or nil, bar ~= nil)
			end
		end

		-- The divider only makes sense when both columns hold a bar.
		self.centerSeparator:SetHidden(bars[baseIndex + 2] == nil)
	end

	function SkillsPanel:Clear()
		if not self.columns then
			return
		end
		for _, column in ipairs(self.columns) do
			column.title:SetText("")
			column.separator:SetHidden(true)
			column.bottomSeparator:SetHidden(true)
			for _, slot in ipairs(SLOT_ORDER) do
				UpdateLine(column.lines[slot], nil, false)
			end
		end
		if self.centerSeparator then
			self.centerSeparator:SetHidden(true)
		end
		if self.pageButton then
			self.pageButton:SetHidden(true)
		end
	end

	-- The page button persists across show/hide (it is not a pooled shared control),
	-- so it is created once here and its visibility toggled in Update.
	local pageButton = WINDOW_MANAGER:CreateControl(control:GetName() .. "PageButton", control, CT_BUTTON)
	pageButton:SetDimensions(ICON_SIZE, ICON_SIZE)
	pageButton:SetAnchor(TOPRIGHT, control, TOPRIGHT, -6, 6)
	pageButton:SetNormalTexture(PAGE_ARROW)
	pageButton:SetPressedTexture(PAGE_ARROW_DOWN)
	pageButton:SetMouseOverTexture(PAGE_ARROW_OVER)
	pageButton:SetHandler("OnClicked", function()
		SkillsPanel:NextPage()
	end)
	pageButton:SetHidden(true)
	SkillsPanel.pageButton = pageButton
end

function CMXint.InitializeScribedSkillsPanel(control)
	---@class ScribedSkillsPanel:Panel
	local ScribedSkillsPanel = CMXint.PanelObject:New(control, "scribedSkills")
	ScribedSkillsPanel.scenes = { "info" }

	function ScribedSkillsPanel:AcquireScriptControls(parent, x, y)
		local icon = self:AcquireSharedControl(CT_TEXTURE)
		icon:ApplyPosition(parent, x, y, SCRIBED_SCRIPT_ICON_SIZE, SCRIBED_SCRIPT_ICON_SIZE)

		local name = self:AcquireSharedControl(CT_LABEL)
		name:ApplyPosition(parent, x + SCRIBED_SCRIPT_ICON_SIZE + 2, y, SCRIBED_SCRIPT_NAME_WIDTH, nil)
		name:SetFont(ui.GetFont(ui.fontSizeSmall))

		return { icon = icon, name = name }
	end

	-- Builds one scribed-skill row (framed icon + name + three script sub-rows) from
	-- pooled shared controls. Rows are created lazily by Update as data requires.
	function ScribedSkillsPanel:AcquireScribedRow(rowIndex)
		local parent = self.control
		local y = SCRIBED_TOP + (rowIndex - 1) * (SCRIBED_ROW_HEIGHT + SCRIBED_ROW_GAP)

		local iconBg = self:AcquireSharedControl(CT_TEXTURE)
		iconBg:ApplyPosition(parent, SCRIBED_ROW_X, y, SCRIBED_ICON_SIZE, SCRIBED_ICON_SIZE)
		iconBg:SetTexture(ABILITY_FRAME)

		local icon = self:AcquireSharedControl(CT_TEXTURE)
		icon:ApplyPosition(parent, SCRIBED_ROW_X + 2, y + 2, SCRIBED_ICON_SIZE - 4, SCRIBED_ICON_SIZE - 4)
		icon:SetMouseEnabled(true)
		icon:SetHandler("OnMouseEnter", CMXint.ScribedSkillTooltip_OnMouseEnter)
		icon:SetHandler("OnMouseExit", CMXint.SkillTooltip_Clear)

		local name = self:AcquireSharedControl(CT_LABEL)
		name:ApplyPosition(parent, SCRIBED_NAME_X, y, SCRIBED_NAME_WIDTH, nil)
		name:SetFont(ui.GetFont(ui.fontSize))
		name:SetMouseEnabled(true)
		name:SetHandler("OnMouseEnter", CMXint.ScribedSkillTooltip_OnMouseEnter)
		name:SetHandler("OnMouseExit", CMXint.SkillTooltip_Clear)

		local scripts = {
			self:AcquireScriptControls(parent, SCRIBED_SCRIPT_X, y),
			self:AcquireScriptControls(parent, SCRIBED_NAME_X, y + SCRIBED_SCRIPT_ROW2_Y),
			self:AcquireScriptControls(parent, SCRIBED_SCRIPT_X, y + SCRIBED_SCRIPT_ROW2_Y),
		}

		return { iconBg = iconBg, icon = icon, name = name, scripts = scripts }
	end

	-- Shown instead of the rows when the fight was fought without any scribed skill.
	function ScribedSkillsPanel:AcquireEmptyLabel()
		local label = self:AcquireSharedControl(CT_LABEL)
		label:SetFont(ui.GetFont(ui.fontSize))
		label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
		label:SetColor(0.6, 0.6, 0.6, 1)
		label:SetText(GetString(SI_COMBAT_METRICS_NO_SCRIBED_SKILLS))

		return label
	end

	local function HideRow(row)
		row.iconBg:SetHidden(true)
		row.icon:SetHidden(true)
		row.name:SetHidden(true)
		for i = 1, 3 do
			row.scripts[i].icon:SetHidden(true)
			row.scripts[i].name:SetHidden(true)
		end
	end

	function ScribedSkillsPanel:Update()
		self.rows = self.rows or {}

		local fightData = self:GetCurrentFightData()
		local scribedSkills = fightData and fightData.skills and fightData.skills.scribedSkills or {}

		local index = 0
		for abilityId, data in util.spairs(scribedSkills) do
			index = index + 1

			local row = self.rows[index]
			if row == nil then
				row = self:AcquireScribedRow(index)
				self.rows[index] = row
			end

			row.iconBg:SetHidden(false)
			row.icon:SetHidden(false)
			row.name:SetHidden(false)
			row.name:SetText(GetFormattedAbilityName(abilityId))
			row.icon:SetTexture(GetFormattedAbilityIcon(abilityId))

			-- The tooltip handler reads these off the hovered control.
			row.name.abilityId, row.name.scriptIds = abilityId, data
			row.icon.abilityId, row.icon.scriptIds = abilityId, data

			for i = 1, 3 do
				local script = row.scripts[i]
				local scriptId = data[i]
				script.icon:SetHidden(false)
				script.name:SetHidden(false)
				script.name:SetText(GetFormattedAbilityName(scriptId, true))
				script.icon:SetTexture(GetFormattedAbilityIcon(scriptId, true))
			end

			if index == SCRIBED_SKILL_COUNT then
				break
			end
		end

		-- Hide any rows left over from a previous (larger) fight.
		for i = index + 1, #self.rows do
			HideRow(self.rows[i])
		end

		local scale = CMXint.settings.fightReport.scale

		if self.emptyLabel == nil then
			self.emptyLabel = self:AcquireEmptyLabel()
		end
		self.emptyLabel:ApplyPosition(self.control, 0, SCRIBED_TOP, self.control:GetWidth() / scale, nil)
		self.emptyLabel:SetHidden(index > 0)

		-- The panel has no dimensions of its own in XML: the champion points panel anchors
		-- below it, so its height has to track the row count.
		local height = index > 0
				and SCRIBED_TOP + index * SCRIBED_ROW_HEIGHT + (index - 1) * SCRIBED_ROW_GAP + SCRIBED_BOTTOM
			or SCRIBED_EMPTY_HEIGHT
		self.control:SetHeight(height * scale)
	end

	function ScribedSkillsPanel:Recover()
		self.rows = {}
		self.emptyLabel = nil
		self:Update()
	end

	function ScribedSkillsPanel:Clear()
		if self.rows then
			for _, row in ipairs(self.rows) do
				HideRow(row)
			end
		end

		if self.emptyLabel then
			self.emptyLabel:SetHidden(true)
		end

		self.control:SetHeight(SCRIBED_EMPTY_HEIGHT * CMXint.settings.fightReport.scale)
	end
end

function CMXint.SkillTooltip_OnMouseEnter(control)
	local abilityId = control.abilityId
	if not abilityId or abilityId <= 0 then
		return
	end

	InitializeTooltip(SkillTooltip, control, TOPLEFT, 0, 5, BOTTOMLEFT)

	local font = string.format("%s|%s|%s", GetString(SI_COMBAT_METRICS_STD_FONT), 16, "soft-shadow-thin")
	SkillTooltip:SetAbilityId(abilityId)
	SkillTooltip:AddVerticalPadding(15)
	SkillTooltip:AddLine(
		string.format("ID: %d", abilityId),
		font,
		0.7,
		0.7,
		0.8,
		TOP,
		MODIFY_TEXT_TYPE_NONE,
		TEXT_ALIGN_CENTER
	)
end

function CMXint.SkillTooltip_Clear()
	ClearTooltip(SkillTooltip)
end

function CMXint.ScribedSkillTooltip_OnMouseEnter(control)
	if control.scriptIds == nil then
		return
	end
	local abilityId = control.abilityId
	local scriptIds = control.scriptIds

	InitializeTooltip(SkillTooltip, control, TOPLEFT, 0, 5, BOTTOMLEFT)
	SetCraftedAbilityScriptSelectionOverride(
		GetAbilityCraftedAbilityId(abilityId),
		scriptIds[1],
		scriptIds[2],
		scriptIds[3]
	)
	SkillTooltip:SetAbilityId(abilityId)
end

local isFileInitialized = false
function CMXint.InitializeSkills()
	if isFileInitialized == true then
		return false
	end
	logger = util.initSublogger("Skills")

	isFileInitialized = true
	return true
end
