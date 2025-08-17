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

local PanelObject = ZO_Object:InitializingObject()
CMXint.PanelObject = PanelObject

PanelObject.Update = PanelObject:MUST_IMPLEMENT()
PanelObject.Release = PanelObject:MUST_IMPLEMENT()

function PanelObject:Initialize(name, control)
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

function PanelObject:GetParent()
	local parentControl = self.control:GetParent()
	if parentControl then return parentControl.panel end
end

function PanelObject:ResetBars(panel) -- TODO: Probably can be removed when ScrollList implementation is done
	if panel.bars == nil or #panel.bars == 0 then return end

	for i = 1, #panel.bars do
		panel.bars[i]:SetHidden(true)
		panel.bars[i] = nil
	end
end

local isFileInitialized = false
function CMXint.InitializeUI()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("UI")

	assert(CMXint.InitializeTitlePanel(), "Initialization of title panel failed")
	assert(CMXint.InitializeCombatStatsPanel(), "Initialization of combat stats panel failed")
	assert(CMXint.InitializePlayerStatsPanel(), "Initialization of player stats panel failed")
	assert(CMXint.InitializeAbilitiesPanel(), "Initialization of abilities panel failed")
	assert(CMXint.InitializeCombatLogPanel(), "Initialization of combat log panel failed")

	CMXint.SVHandler = CombatMetricsFightData

	isFileInitialized = true
	return true
end
