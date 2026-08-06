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

local SKILL_SLOT_ORDER = { 1, 2, 3, 4, 5, 6, 7, 8 }

local SCRIBED_SKILL_COUNT = 10

-- Scribed skill row layout: a framed ability icon + name, with three script sub-rows (small icon +
-- name). Offsets are container-local; see AcquireScribedRow.
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
local SCRIBED_ROW_WIDTH = SCRIBED_SCRIPT_X + SCRIBED_SCRIPT_ICON_SIZE + 2 + SCRIBED_SCRIPT_NAME_WIDTH

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

	function SkillsPanel:RecoverSkillLine(line)
		local container = line.container
		container:SetMouseEnabled(true)
		container:SetHandler("OnMouseEnter", CMXint.SkillTooltip_OnMouseEnter)
		container:SetHandler("OnMouseExit", CMXint.SkillTooltip_Clear)

		local iconBg = container:AcquireSharedControl(CT_TEXTURE)
		iconBg:ApplyPosition(container, 0, 0, ICON_SIZE, ICON_SIZE)
		iconBg:SetTexture(ABILITY_FRAME)

		local icon = container:AcquireSharedControl(CT_TEXTURE)
		icon:ApplyPosition(container, 2, 2, ICON_SIZE - 4, ICON_SIZE - 4)

		local label = container:AcquireSharedControl(CT_LABEL)
		label:ApplyPosition(container, ICON_SIZE + 4, 0, COLUMN_WIDTH - ICON_SIZE - 8, nil)
		label:ApplyFont(ui.fontSize)

		line.iconBg, line.icon, line.label = iconBg, icon, label
	end

	function SkillsPanel:RecoverColumn(columnIndex)
		local column = self.columns[columnIndex]

		if column == nil then
			column = { lines = {} }
			self.columns[columnIndex] = column

			for _, slot in ipairs(SKILL_SLOT_ORDER) do
				local name = string.format("%sColumn%dSlot%d", control:GetName(), columnIndex, slot)
				column.lines[slot] = { container = self:CreateRowContainer(name) }
			end
		end

		local x = LEFT_MARGIN + (columnIndex - 1) * (COLUMN_WIDTH + COLUMN_GAP)
		local y = TOP_MARGIN

		column.title = self:AcquireSharedControl(CT_LABEL)
		column.title:ApplyPosition(control, x, y, COLUMN_WIDTH, nil)
		column.title:ApplyFont(ui.fontSize, true)

		column.separator = self:AcquireSharedControl(CT_LINE)
		column.separator:ApplyPosition(control, x, y + TITLE_HEIGHT + 1, COLUMN_WIDTH, 0)

		y = y + TITLE_HEIGHT + 4
		for _, slot in ipairs(SKILL_SLOT_ORDER) do
			local line = column.lines[slot]
			self:RecoverSkillLine(line)
			line.container:ApplyPosition(control, x, y, COLUMN_WIDTH, SKILL_ROW_HEIGHT)
			y = y + SKILL_ROW_HEIGHT
		end

		-- Divider below the skills; a stats section will go here later.
		column.bottomSeparator = self:AcquireSharedControl(CT_LINE)
		column.bottomSeparator:ApplyPosition(control, x, y + 2, COLUMN_WIDTH, 0)
	end

	function SkillsPanel:Recover()
		self.columns = self.columns or {}

		for columnIndex = 1, BARS_PER_PAGE do
			self:RecoverColumn(columnIndex)
		end

		local centerX = LEFT_MARGIN + COLUMN_WIDTH + COLUMN_GAP / 2
		local contentHeight = TITLE_HEIGHT + 4 + #SKILL_SLOT_ORDER * SKILL_ROW_HEIGHT
		self.centerSeparator = self:AcquireSharedControl(CT_LINE)
		self.centerSeparator:ApplyPosition(control, centerX, TOP_MARGIN, 0, contentHeight)

		self:Update()
	end

	function SkillsPanel:NextPage()
		self.page = self.page + 1
		self:Update()
	end

	-- Hiding the container hides the whole row with it, so this is also safe to call on a hidden panel
	-- whose shared controls have been released: it returns before touching any of them.
	local function UpdateLine(line, abilityId, showRow)
		line.container:SetHidden(not showRow)
		if not showRow then
			return
		end

		if abilityId and abilityId > 0 then
			line.icon:SetTexture(GetFormattedAbilityIcon(abilityId))
			line.label:SetText(GetFormattedAbilityName(abilityId))
			line.container.data.abilityId = abilityId
		else
			line.icon:SetTexture(UNKNOWN_ICON)
			line.label:SetText("")
			line.container.data.abilityId = nil
		end
	end

	function SkillsPanel:Update()
		if not self.columns then
			return
		end

		local fightData = self:GetCurrentFightData()
		local skills = fightData and fightData.skills
		local skillBars = skills and skills.skillBars

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

			for _, slot in ipairs(SKILL_SLOT_ORDER) do
				UpdateLine(column.lines[slot], bar and bar[slot] or nil, bar ~= nil)
			end
		end

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
			for _, slot in ipairs(SKILL_SLOT_ORDER) do
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

	local scribedRowPool = ScribedSkillsPanel:CreateRowPool(control)

	function ScribedSkillsPanel:AcquireScriptControls(container, x, y)
		local icon = container:AcquireSharedControl(CT_TEXTURE)
		icon:ApplyPosition(container, x, y, SCRIBED_SCRIPT_ICON_SIZE, SCRIBED_SCRIPT_ICON_SIZE)

		local name = container:AcquireSharedControl(CT_LABEL)
		name:ApplyPosition(container, x + SCRIBED_SCRIPT_ICON_SIZE + 2, y, SCRIBED_SCRIPT_NAME_WIDTH, nil)
		name:ApplyFont(ui.fontSizeSmall)

		return { icon = icon, name = name }
	end

	-- Builds one scribed-skill row (framed icon + name + three script sub-rows) in container-local
	-- coordinates. Rows are created lazily by Update as the data requires, and only the container is
	-- moved afterwards, so the row's own layout is written just once, here.
	function ScribedSkillsPanel:AcquireScribedRow()
		local container = scribedRowPool:Acquire()
		container:SetMouseEnabled(true)
		container:SetHandler("OnMouseEnter", CMXint.ScribedSkillTooltip_OnMouseEnter)
		container:SetHandler("OnMouseExit", CMXint.SkillTooltip_Clear)

		local iconBg = container:AcquireSharedControl(CT_TEXTURE)
		iconBg:ApplyPosition(container, SCRIBED_ROW_X, 0, SCRIBED_ICON_SIZE, SCRIBED_ICON_SIZE)
		iconBg:SetTexture(ABILITY_FRAME)

		local icon = container:AcquireSharedControl(CT_TEXTURE)
		icon:ApplyPosition(container, SCRIBED_ROW_X + 2, 2, SCRIBED_ICON_SIZE - 4, SCRIBED_ICON_SIZE - 4)

		local name = container:AcquireSharedControl(CT_LABEL)
		name:ApplyPosition(container, SCRIBED_NAME_X, 0, SCRIBED_NAME_WIDTH, nil)
		name:ApplyFont(ui.fontSize)

		local scripts = {
			self:AcquireScriptControls(container, SCRIBED_SCRIPT_X, 0),
			self:AcquireScriptControls(container, SCRIBED_NAME_X, SCRIBED_SCRIPT_ROW2_Y),
			self:AcquireScriptControls(container, SCRIBED_SCRIPT_X, SCRIBED_SCRIPT_ROW2_Y),
		}

		return { container = container, iconBg = iconBg, icon = icon, name = name, scripts = scripts }
	end

	function ScribedSkillsPanel:AcquireEmptyLabel()
		local label = self:AcquireSharedControl(CT_LABEL)
		label:ApplyFont(ui.fontSize)
		label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
		label:SetColor(0.6, 0.6, 0.6, 1)
		label:SetText(GetString(SI_COMBAT_METRICS_NO_SCRIBED_SKILLS))

		return label
	end

	function ScribedSkillsPanel:Update()
		self.rows = self.rows or {}

		local fightData = self:GetCurrentFightData()
		local scribedSkills = fightData and fightData.skills and fightData.skills.scribedSkills or {}

		local index = 0
		for abilityId, scriptIds in util.spairs(scribedSkills) do
			index = index + 1

			local row = self.rows[index]
			if row == nil then
				row = self:AcquireScribedRow()
				self.rows[index] = row
			end

			local y = SCRIBED_TOP + (index - 1) * (SCRIBED_ROW_HEIGHT + SCRIBED_ROW_GAP)
			row.container:ApplyPosition(control, 0, y, SCRIBED_ROW_WIDTH, SCRIBED_ROW_HEIGHT)

			local rowData = row.container.data
			rowData.abilityId, rowData.scriptIds = abilityId, scriptIds

			row.name:SetText(GetFormattedAbilityName(abilityId))
			row.icon:SetTexture(GetFormattedAbilityIcon(abilityId))

			for i = 1, 3 do
				local script = row.scripts[i]
				local scriptId = scriptIds[i]
				script.name:SetText(GetFormattedAbilityName(scriptId, true))
				script.icon:SetTexture(GetFormattedAbilityIcon(scriptId, true))
			end

			if index == SCRIBED_SKILL_COUNT then
				break
			end
		end

		for i = #self.rows, index + 1, -1 do
			scribedRowPool:Release(self.rows[i].container)
			self.rows[i] = nil
		end

		local scale = CMXint.settings.fightReport.scale

		if self.emptyLabel == nil then
			self.emptyLabel = self:AcquireEmptyLabel()
		end
		self.emptyLabel:ApplyPosition(control, 0, SCRIBED_TOP, control:GetWidth() / scale, nil)
		self.emptyLabel:SetHidden(index > 0)

		-- The panel has no dimensions of its own in XML: the champion points panel anchors
		-- below it, so its height has to track the row count.
		local height = index > 0
				and SCRIBED_TOP + index * SCRIBED_ROW_HEIGHT + (index - 1) * SCRIBED_ROW_GAP + SCRIBED_BOTTOM
			or SCRIBED_EMPTY_HEIGHT
		control:SetHeight(height * scale)
	end

	function ScribedSkillsPanel:Recover()
		self.rows = {}
		self.emptyLabel = nil
		self:Update()
	end

	function ScribedSkillsPanel:Clear()
		if self.rows then
			scribedRowPool:ReleaseAll()
			ZO_ClearNumericallyIndexedTable(self.rows)
		end

		if self.emptyLabel then
			self.emptyLabel:SetHidden(true)
		end

		control:SetHeight(SCRIBED_EMPTY_HEIGHT * CMXint.settings.fightReport.scale)
	end
end

function CMXint.SkillTooltip_OnMouseEnter(control)
	local abilityId = control.data.abilityId
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
	local data = control.data
	if data.scriptIds == nil then
		return
	end
	local abilityId = data.abilityId
	local scriptIds = data.scriptIds

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
		return true
	end
	logger = util.initSublogger("Skills")

	isFileInitialized = true
	return true
end
