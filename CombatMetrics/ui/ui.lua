---@class CMX
local CMX = CombatMetrics
---@class CMXint
local CMXint = CMX.internal
---@class CMXutil
local util = CMXint.util

---@class CMXui
CMXint.ui = {}
---@class CMXui
local ui = CMXint.ui
ui.panels = {}
local panels = ui.panels
ui.selections = {}
local selections = ui.selections
---@type Logger
local logger
local _

ui.dx = zo_ceil(GuiRoot:GetWidth() / tonumber(GetCVar("WindowedWidth")) * 1000) / 1000
ui.fontSizeSmall = tonumber(GetString(SI_COMBAT_METRICS_FONT_SIZE_SMALL))
ui.fontSize = tonumber(GetString(SI_COMBAT_METRICS_FONT_SIZE))

function ui.GetFont(base_size, bold)
	local scale = CMXint.settings.fightReport.scale
	local size = base_size * (scale + 0.2) / 1.2
	local base_font = bold == true and "BOLD_FONT" or "MEDIUM_FONT"

	return string.format("$(%s)|%s|%s", base_font, size, "soft-shadow-thin")
end

-- CMXint.DPSstrings = {
-- 	["damageOut"] = "DPSOut",
-- 	["damageIn"] = "DPSIn",
-- 	["healingOut"] = "HPSOut",
-- 	["healingIn"] = "HPSIn",
-- }

-- CMXint.CountStrings = {
-- 	["damageOut"] = "hitsOut",
-- 	["damageIn"] = "hitsIn",
-- 	["healingOut"] = "healsOut",
-- 	["healingIn"] = "healsIn",
-- }

---@param control Control
local function storeOrigLayout(control)
	control.sizes = { control:GetDimensions() }
	control.anchors = {}

	for i = 1, 2 do
		local valid, point, relativeTo, relativePoint, x, y, constrains = control:GetAnchor(i - 1)
		if valid then
			control.anchors[i] = { point, relativeTo, relativePoint, x, y, constrains }
		end
	end

	for i = 1, control:GetNumChildren() do
		local child = control:GetChild(i)
		if child then
			storeOrigLayout(child)
		end
	end
end
util.storeOrigLayout = storeOrigLayout

--- this function resizes the row elements to match the size of the header elements of a scrolllist.
---
--- It's important to maintain the naming and structure of the header elements to match those of the row elements.

---@param row Control
---@param header Control
function util.adjustRowSize(row, header)
	local settings = CMXint.settings.fightReport
	if row == nil or row.scale == settings.scale then
		return
	end -- if sizes are good already, bail out.
	row["scale"] = settings.scale

	for i = 1, header:GetNumChildren() do
		local child = header:GetChild(i)
		local childname = zo_strgsub(child:GetName(), header:GetName(), "")
		local template = header:GetNamedChild(childname)
		local rowchild = row:GetNamedChild(childname)

		if template and rowchild then
			local x, y = template:GetDimensions()
			rowchild:SetDimensions(x, y)

			local valid1, _, _, _, x, y, _ = template:GetAnchor(0)
			local valid2, point, relativeTo, relativePoint, _, _, _ = rowchild:GetAnchor(0)

			if valid1 and valid2 then
				rowchild:ClearAnchors()
				---@diagnostic disable-next-line: missing-parameter
				rowchild:SetAnchor(point, relativeTo, relativePoint, x, y)
			end

			if rowchild:GetType() == CT_LABEL then
				---@cast rowchild LabelControl
				local font = string.format(
					"%s|%s|%s",
					GetString(SI_COMBAT_METRICS_STD_FONT),
					tonumber(GetString(SI_COMBAT_METRICS_FONT_SIZE)) * row.scale,
					"soft-shadow-thin"
				)
				rowchild:SetFont(font)
			end
		end
	end
end

---@param control Control
---@param tooltipControl TooltipControl
---@param tooltip string
local function AddTooltipLine(control, tooltipControl, tooltip)
	local tooltipTextType = type(tooltip)

	if tooltipTextType == "string" then
		if tooltip == "" then
			ZO_Options_OnMouseExit(control)
			return
		end
	elseif tooltipTextType == "number" then
		tooltip = GetString(tooltip)
	elseif tooltipTextType == "function" then
		tooltip = tooltip()
	else
		ZO_Options_OnMouseExit(control)
		return
	end

	SetTooltipText(tooltipControl, tooltip)
end
util.AddTooltipLine = AddTooltipLine

---@param control Control
function CMXint.OnMouseEnter(control) --copy from ZO_Options_OnMouseEnter but modified to support multiple tooltip lines
	---@type table | string
	local tooltipText = control["tooltip"]
	if tooltipText == nil then
		return
	end

	InitializeTooltip(InformationTooltip, control, BOTTOMLEFT, 0, -2, TOPLEFT)
	if type(tooltipText) == "table" then
		for i = 1, #tooltipText do
			AddTooltipLine(control, InformationTooltip, tooltipText[i])
		end
	else
		AddTooltipLine(control, InformationTooltip, tooltipText)
	end
end

---@param control Control
---@param setcolor any can be hex or rgba, ZO_ColorDef takes care of this
function CMXint.SetLabelColor(control, setcolor)
	for i = 1, control:GetNumChildren() do
		local child = control:GetChild(i)
		local color = ZO_ColorDef:New(setcolor)

		if child:GetType() == CT_LABEL and child["nocolor"] ~= true then
			---@cast child LabelControl
			child:SetColor(color.r, color.g, color.b, color.a)
		elseif child:GetType() == CT_CONTROL and child["nocolor"] ~= true then
			CMXint.SetLabelColor(child, setcolor)
		end
	end
end

local lastResize

---@param control BackdropControl
---@param resizing boolean
function CMXint.Resizing(control, resizing)
	if control:IsHidden() then
		return
	end
	if resizing then
		control:SetEdgeColor(1, 1, 1, 1)
		control:SetCenterColor(1, 1, 1, 0.2)
		control:SetDrawTier(2)
	else
		control:SetEdgeColor(1, 1, 1, 0)
		control:SetCenterColor(1, 1, 1, 0)
		control:SetDrawTier(0)

		if lastResize == nil then
			return
		end

		local scale, newpos = unpack(lastResize)
		local parent = control:GetParent()
		logger:Info("Resizing: %s", parent:GetName())

		parent:ClearAnchors()
		---@diagnostic disable-next-line: missing-parameter, param-type-mismatch
		parent:SetAnchor(CENTER, nil, TOPLEFT, newpos.x, newpos.y)
		---@diagnostic disable-next-line: undefined-field
		parent:Resize(scale)
	end
end

---@param control Control
function CMXint.NewSize(control, newLeft, newTop, newRight, newBottom, oldLeft, oldTop, oldRight, oldBottom)
	if control.sizes == nil or control:IsHidden() then
		return
	end

	local newHeight = newBottom - newTop
	local newWidth = newRight - newLeft
	local oldHeight = oldBottom - oldTop
	local oldWidth = oldRight - oldLeft

	local baseWidth, baseHeight = unpack(control.sizes)
	local heightChange = (newHeight - oldHeight) / oldHeight
	local widthChange = (newWidth - oldWidth) / oldWidth
	local newscale

	if zo_abs(heightChange) > zo_abs(widthChange) then
		newscale = newHeight / baseHeight
		newWidth = baseWidth * newscale

		control:SetWidth(newWidth)
	else
		newscale = newWidth / baseWidth
		newHeight = baseHeight * newscale

		control:SetHeight(newHeight)
	end

	newscale = zo_roundToNearest(newscale, 0.01)

	local centerX, centerY = control:GetCenter()
	local newpos = { x = centerX, y = centerY }

	lastResize = { newscale, newpos }
end

---@class Panel
---@field New fun(self: Panel, control: Control, name: string): Panel
---@field MUST_IMPLEMENT fun()
---@field dataList SortFilterList?
local PanelObject = ZO_InitializingObject:Subclass()
CMXint.PanelObject = PanelObject

PanelObject.Update = PanelObject:MUST_IMPLEMENT()
PanelObject.Clear = PanelObject:MUST_IMPLEMENT()
PanelObject.Recover = PanelObject:MUST_IMPLEMENT()

local function onShow(control)
	control.panel:Recover()
end

local function onHide(control)
	control.panel:Release()
end

---@class PanelControl: Control
---@field panel Panel
---@field sharedControls Control[]
---@field dataList SortFilterList?

---@param control PanelControl
---@param name string
function PanelObject:Initialize(control, name)
	if ui.panels[name] then
		logger:Error("Cannot create %s panel. A panel with this name already exists.", name)
		return
	end

	self.name = name
	self.control = control
	self.sharedControls = {}

	control.panel = self

	---@diagnostic disable-next-line: missing-parameter
	control:SetHandler("OnEffectivelyShown", onShow)
	---@diagnostic disable-next-line: missing-parameter
	control:SetHandler("OnEffectivelyHidden", onHide)

	ui.panels[name] = self
end

---@param controlType integer
---@return LabelControl|LineControl|TextureControl|SharedControl
function PanelObject:AcquireSharedControl(controlType)
	local control
	if controlType == CT_LABEL then
		---@type LabelControl
		control, _ = ui.sharedLabels:AcquireObject()
	elseif controlType == CT_TEXTURE then
		---@type TextureControl
		control, _ = ui.sharedTextures:AcquireObject()
	elseif controlType == CT_LINE then
		---@type LineControl
		control, _ = ui.sharedSeparators:AcquireObject()
	else
		logger:Error("Attempt to acquire unsupported control type: %d", controlType)
	end

	table.insert(self.sharedControls, control)
	return control
end

---@param control PanelControl
function PanelObject.OnShow(control)
	logger:Info("OnShow, Panel: %s", control.panel.name)
	return control.panel:Recover()
end

---@param control PanelControl
function PanelObject:OnHide(control)
	return control.panel:Release()
end

function PanelObject:GetCurrentFightData()
	if CMXint.fightReport then
		return CMXint.fightReport.currentFight
	end
end

---@return UnitDamageData|UnitHealData
function PanelObject:GetCurrentCategoryCombatData()
	local category = self.settings.category
	local fightData = self:GetCurrentFightData()
	local categoryData = fightData[category]

	if categoryData == nil then
		logger:Error("No data for category: %s", category)
	end

	return categoryData
end

function PanelObject:Release()
	self:ReleaseSharedControls()
end

function PanelObject:ReleaseSharedControls()
	for _, control in pairs(self.sharedControls) do
		control:Release()
	end

	ZO_ClearTable(self.sharedControls)

	if self.dataList then
		self.dataList:Clear()
	end
end

function PanelObject:Clear()
	logger:Warn("Calling 'clear' on %s panel, but method is not set", self.name) -- Remove, once panels are implemented
end

function PanelObject:Recover()
	logger:Warn("Calling 'recover' on %s panel, but method is not set", self.name) -- Remove, once panels are implemented
end

function PanelObject:GetParentControl()
	return self.control:GetParent()
end

function PanelObject:ResetBars(panel) -- TODO: Probably can be removed when ScrollList implementation is done
	if panel == nil then
		panel = self.control
	end
	if panel.bars == nil or #panel.bars == 0 then
		return
	end

	for i = 1, #panel.bars do
		panel.bars[i]:SetHidden(true)
		panel.bars[i] = nil
	end
end

---@param hide boolean
function PanelObject:SetHidden(hide)
	return self.control:SetHidden(hide)
end

function PanelObject:ShowIds()
	local settings = self.settings

	if settings then
		return settings.showDebugIds
	end

	return false
end

---@param name string
---@return Panel
function ui:GetPanel(name)
	local panel = panels[name]
	if panel then
		return panels[name]
	end
	---@diagnostic disable-next-line: missing-return
	logger:Error("Attempt to access unknown panel: %s", name)
end

---@param name string
function ui:UpdatePanel(name)
	return self:GetPanel(name):Update()
end

local isFileInitialized = false
function CMXint.InitializeUI()
	if isFileInitialized == true then
		return false
	end
	logger = util.initSublogger("UI")

	-- ui.selections = {
	-- 	["ability"]		= {},
	-- 	["resource"] 	= {},
	-- }

	-- CMXint.lastSelections = {
	-- 	["ability"] 	= {},
	-- 	["unit"] 		= {},
	-- 	["buff"] 		= {},
	-- 	["resource"] 	= {},
	-- }

	assert(CMXint.InitializeControlHandler(), "Initialization of control handler failed")
	assert(CMXint.InitializeSelectionsHandler(), "Initialization of selections handler failed")
	assert(CMXint.InitializeFightReport(), "Initialization of fight report UI failed")
	assert(CMXint.InitializeLiveReport(), "Initialization of live report failed")

	PanelObject.fightReport = CMXint.fightReport
	PanelObject.settings = CMXint.fightReport.settings

	assert(CMXint.InitializeTitle(), "Initialization of title UI failed")
	assert(CMXint.InitializeMenu(), "Initialization of menu UI failed")
	assert(CMXint.InitializeInfoRow(), "Initialization of info row UI failed")

	assert(CMXint.InitializeCombatStats(), "Initialization of combat stats UI failed")
	-- -- assert(CMXint.InitializeResource(), "Initialization of resource UI failed")
	-- assert(CMXint.InitializePlayerStats(), "Initialization of player stats UI failed")
	assert(CMXint.InitializeBuffs(), "Initialization of buffs UI failed")

	assert(CMXint.InitializeUnits(), "Initialization of units UI failed")
	-- assert(CMXint.InitializeAbilities(), "Initialization of abilities UI failed")

	-- assert(CMXint.InitializeSkills(), "Initialization of skills UI failed")
	-- assert(CMXint.InitializeEquipment(), "Initialization of equipment UI failed")
	-- assert(CMXint.InitializeChampionPoints(), "Initialization of champion points UI failed")
	-- assert(CMXint.InitializeConsumables(), "Initialization of consumables UI failed")

	-- assert(CMXint.InitializeCombatLog(), "Initialization of combat log UI failed")
	-- assert(CMXint.InitializeGraph(), "Initialization of graph UI failed")

	-- assert(CMXint.InitializeFightList(), "Initialization of fight list UI failed")
	-- assert(CMXint.InitializeDonations(), "Initialization of donations UI failed")

	isFileInitialized = true
	return true
end
