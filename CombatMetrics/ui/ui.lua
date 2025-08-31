local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local logger

CMXint.dx = zo_ceil(GuiRoot:GetWidth() / tonumber(GetCVar("WindowedWidth")) * 1000) / 1000
CMXint.fontSize = tonumber(GetString(SI_COMBAT_METRICS_FONT_SIZE_SMALL))

CMXint.DPSstrings = {
	["damageOut"]  = "DPSOut",
	["damageIn"]   = "DPSIn",
	["healingOut"] = "HPSOut",
	["healingIn"]  = "HPSIn",
}

CMXint.CountStrings = {
	["damageOut"]  = "hitsOut",
	["damageIn"]   = "hitsIn",
	["healingOut"] = "healsOut",
	["healingIn"]  = "healsIn",
}

local function storeOrigLayout(tlc)
	tlc.sizes = {tlc:GetDimensions()}
	tlc.anchors = {}

	for i = 1, 2 do
		local valid, point, relativeTo, relativePoint, x, y, constrains = tlc:GetAnchor(i-1)
		if valid then tlc.anchors[i] = {point, relativeTo, relativePoint, x, y, constrains} end
	end

	for i = 1, tlc:GetNumChildren() do
		local child = tlc:GetChild(i)
		if child then storeOrigLayout(child) end
	end
end
CMXf.storeOrigLayout = storeOrigLayout

-- this function resizes the row elements to match the size of the header elements of a scrolllist.
-- It's important to maintain the naming and structure of the header elements to match those of the row elements.
function CMXf.adjustRowSize(row, header)
	local settings = CMXint.settings.FightReport
	if row == nil or row.scale == settings.scale then return end -- if sizes are good already, bail out.
	row.scale = settings.scale

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
				rowchild:SetAnchor(point, relativeTo, relativePoint, x, y)
			end

			if rowchild:GetType() == CT_LABEL then rowchild:SetFont(string.format("%s|%s|%s",
					GetString(SI_COMBAT_METRICS_STD_FONT), tonumber(GetString(SI_COMBAT_METRICS_FONT_SIZE)) * row.scale,
					"soft-shadow-thin")) end
		end
	end
end

local function AddTooltipLine(control, tooltipControl, tooltip)
	local tooltipTextType = type(tooltip)

	if tooltipTextType == "string" then
		if tooltip == "" then ZO_Options_OnMouseExit(control) return end
	elseif tooltipTextType == "number" then	tooltip = GetString(tooltip)
	elseif tooltipTextType == "function" then tooltip = tooltip()
	else ZO_Options_OnMouseExit(control) return end

	SetTooltipText(tooltipControl, tooltip)
end
CMXf.AddTooltipLine = AddTooltipLine

function CMXint.OnMouseEnter(control) --copy from ZO_Options_OnMouseEnter but modified to support multiple tooltip lines
	local tooltipText = control.tooltip

    if tooltipText ~= nil and #tooltipText>0 then
		InitializeTooltip(InformationTooltip, control, BOTTOMLEFT, 0, -2, TOPLEFT)

		if type(tooltipText) == "table" then
			for i=1, #tooltipText do
				AddTooltipLine(control, InformationTooltip, tooltipText[i])
			end
		else
			AddTooltipLine(control, InformationTooltip, tooltipText)
		end
	end
end

local PanelObject = ZO_Object:InitializingObject()
CMXint.PanelObject = PanelObject

PanelObject.Update = PanelObject:MUST_IMPLEMENT()

function PanelObject:Initialize(control, name)
	if CMXint.panels[name] then
		logger:Error("Cannot create %s panel. A panel with this name already exists.", name)
		return
	end

	self.name = name
	self.control = control
	self.settings = CMXint.settings.FightReport
	control.panel = self
	CMXint.panels[name] = self
end

function PanelObject:Release()
end

function PanelObject:GetParentControl()
	local parentControl = self.control:GetParent()
	if parentControl then return parentControl.panel end
end

function PanelObject:ResetBars(panel) -- TODO: Probably can be removed when ScrollList implementation is done
	if panel == nil then panel = self.control end
	if panel.bars == nil or #panel.bars == 0 then return end

	for i = 1, #panel.bars do
		panel.bars[i]:SetHidden(true)
		panel.bars[i] = nil
	end
end

function PanelObject:SetHidden(hide)
	return self.control:SetHidden(hide)
end


local isFileInitialized = false
function CMXint.InitializeUI()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("UI")

	
	assert(CMXint.InitializeTitle(), "Initialization of title ui failed")
	assert(CMXint.InitializeMenu(), "Initialization of menu ui failed")
	assert(CMXint.InitializeCombatStats(), "Initialization of combat stats ui failed")
	-- assert(CMXint.InitializeResource(), "Initialization of resource ui failed")
	assert(CMXint.InitializePlayerStats(), "Initialization of player stats ui failed")
	assert(CMXint.InitializeBuffs(), "Initialization of buffs ui failed")
	assert(CMXint.InitializeUnits(), "Initialization of units ui failed")
	assert(CMXint.InitializeAbilities(), "Initialization of abilities ui failed")
	
	assert(CMXint.InitializeSkills(), "Initialization of skills ui failed")
	assert(CMXint.InitializeEquipment(), "Initialization of equipment ui failed")
	assert(CMXint.InitializeChampionPoints(), "Initialization of champion points ui failed")
	assert(CMXint.InitializeConsumables(), "Initialization of consumables ui failed")
	
	assert(CMXint.InitializeCombatLog(), "Initialization of combat log ui failed")
	assert(CMXint.InitializeGraph(), "Initialization of graph ui failed")
	
	assert(CMXint.InitializeFightList(), "Initialization of fight list ui failed")
	assert(CMXint.InitializeDonations(), "Initialization of donations ui failed")
	assert(CMXint.InitializeInfoRow(), "Initialization of info row failed")
	
	assert(CMXint.InitializeFightReport(), "Initialization of fight report ui failed")
	assert(CMXint.InitializeLiveReport(), "Initialization of live report failed")

	CMXint.SVHandler = CombatMetricsFightData

	isFileInitialized = true
	return true
end
