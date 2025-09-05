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

function CMXint.SetLabelColor(control, setcolor)  -- setcolor can be hex or rgba, ZO_ColorDef takes care of this
	for i=1, control:GetNumChildren(control) do
		local child = control:GetChild(i)
		local color = ZO_ColorDef:New(setcolor)

		if child:GetType() == CT_LABEL and child.nocolor ~= true then
			child:SetColor(color.r, color.g, color.b, color.a)
		elseif child:GetType() == CT_CONTROL and child.nocolor ~= true then
			CMX.SetLabelColor(child, setcolor)
		end
	end
end

-- function CMXint.ClearSelections()
-- 	local category = CMXint.settings.FightReport.category or "damageOut"
-- 	local selections = CMXint.selections

-- 	selections.ability[category] = nil
-- 	selections.unit[category] = nil
-- 	selections.buff.buff = nil
-- 	selections.resource.resource = nil
-- end

-- function CMX.AddSelection( self, button, upInside, ctrlkey, alt, shiftkey )
-- 	local id = self.id
-- 	local dataId = self.dataId
-- 	local selecttype = self.type

-- 	if button ~= MOUSE_BUTTON_INDEX_LEFT and button ~= MOUSE_BUTTON_INDEX_MIDDLE then return end

-- 	local category = selecttype == "buff" and "buff" or selecttype == "resource" and "resource" or CMXint.settings.FightReport.category

-- 	local selections = CMXint.selections
-- 	local lastSelections = CMXint.lastSelections
-- 	local sel = selections[selecttype][category] -- can be nil so this is not always a reference
-- 	local lastsel = lastSelections[selecttype][category]
-- 	local bars = self.panel.bars

-- 	if button == MOUSE_BUTTON_INDEX_MIDDLE then
-- 		selections[selecttype][category] = nil
-- 		lastSelections[selecttype][category] = nil
-- 		CombatMetrics_Report:Update(currentFight)

-- 		return
-- 	end

-- 	if sel == nil then	-- if nothing is selected yet, just select this, disregarding all modifiers.
-- 		sel = {[dataId] = id}
-- 		lastsel = id
-- 	elseif shiftkey and not ctrlkey and lastsel ~= nil then 	-- select everything between this and the previous sel if shiftkey is pressed
-- 		local istart = zo_min(lastsel, id)
-- 		local iend = zo_max(lastsel, id)

-- 		sel = {} 	-- forget/disregard other selections

-- 		for i=istart, iend do
-- 			local irowcontrol = bars[i]
-- 			sel[irowcontrol.dataId] = i
-- 		end
-- 	elseif ctrlkey and not shiftkey then	-- toggle additional sel if ctrlkey is pressed
-- 		if sel[dataId] ~= nil then
-- 			lastsel = nil
-- 			sel[dataId] = nil
-- 		else
-- 			lastsel = id
-- 			sel[dataId] = id
-- 		end

-- 	elseif shiftkey and ctrlkey and lastsel ~= nil then  -- additionally select everything between this and the previous sel if ctrlkey + shift key is pressed
-- 		local istart = zo_min(lastsel, id)
-- 		local iend = zo_max(lastsel, id)

-- 		for i=istart, iend do
-- 			local irowcontrol = bars[i]
-- 			sel[irowcontrol.dataId] = i
-- 		end

-- 	elseif not shiftkey and not ctrlkey then -- normal LMB click
-- 		if lastsel == id and sel[dataId] ~= nil then -- remove sel if this was pressed just before
-- 			lastsel = nil
-- 			sel = nil
-- 		else
-- 			lastsel = id
-- 			sel = {[dataId] = id}
-- 		end
-- 	end

-- 	lastSelections[selecttype][category] = lastsel
-- 	selections[selecttype][category] = sel
-- 	CombatMetrics_Report:Update(currentFight)
-- end

function CMXf.GetCurrentData()
	local data = CMX.currentdata

	if data.units == nil then
		if #CMX.lastfights == 0 then return end
		data = CMX.lastfights[#CMX.lastfights]
	end

	return data
end

local lastResize
function CMXint.Resizing(control, resizing)
	if control:IsHidden() then return end
	if resizing then
		control:SetEdgeColor(1,1,1,1)
		control:SetCenterColor(1,1,1,.2)
		control:SetDrawTier(2)
	else
		control:SetEdgeColor(1,1,1,0)
		control:SetCenterColor(1,1,1,0)
		control:SetDrawTier(0)

		if lastResize == nil then return end

		local scale, newpos = unpack(lastResize)
		local parent = control:GetParent()

		CMXint.settings[parent:GetName()] = newpos

		parent:ClearAnchors()
		parent:SetAnchor(CENTER, nil , TOPLEFT, newpos.x, newpos.y)
		parent:Resize(scale)
	end
end


function CMXint.NewSize(control, newLeft, newTop, newRight, newBottom, oldLeft, oldTop, oldRight, oldBottom)
	if control.sizes == nil or control:IsHidden() then return end

	
	local newHeight = newBottom - newTop
	local newWidth = newRight - newLeft
	local oldHeight = oldBottom - oldTop
	local oldWidth = oldRight - oldLeft
	
	local baseWidth, baseHeight = unpack(control.sizes)
	local heightChange = (newHeight-oldHeight)/oldHeight
	local widthChange = (newWidth-oldWidth)/oldWidth
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
	local newpos = { x = centerX, y = centerY}

	lastResize = {newscale, newpos}
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

	-- CMXint.selections = {
	-- 	["ability"]		= {},
	-- 	["unit"] 		= {},
	-- 	["buff"] 		= {},
	-- 	["resource"] 	= {},
	-- }

	-- CMXint.lastSelections = {
	-- 	["ability"] 	= {},
	-- 	["unit"] 		= {},
	-- 	["buff"] 		= {},
	-- 	["resource"] 	= {},
	-- }
	
	-- assert(CMXint.InitializeTitle(), "Initialization of title ui failed")
	-- assert(CMXint.InitializeMenu(), "Initialization of menu ui failed")
	-- assert(CMXint.InitializeCombatStats(), "Initialization of combat stats ui failed")
	-- -- assert(CMXint.InitializeResource(), "Initialization of resource ui failed")
	-- assert(CMXint.InitializePlayerStats(), "Initialization of player stats ui failed")
	-- assert(CMXint.InitializeBuffs(), "Initialization of buffs ui failed")
	-- assert(CMXint.InitializeUnits(), "Initialization of units ui failed")
	-- assert(CMXint.InitializeAbilities(), "Initialization of abilities ui failed")
	
	-- assert(CMXint.InitializeSkills(), "Initialization of skills ui failed")
	-- assert(CMXint.InitializeEquipment(), "Initialization of equipment ui failed")
	-- assert(CMXint.InitializeChampionPoints(), "Initialization of champion points ui failed")
	-- assert(CMXint.InitializeConsumables(), "Initialization of consumables ui failed")
	
	-- assert(CMXint.InitializeCombatLog(), "Initialization of combat log ui failed")
	-- assert(CMXint.InitializeGraph(), "Initialization of graph ui failed")
	
	-- assert(CMXint.InitializeFightList(), "Initialization of fight list ui failed")
	-- assert(CMXint.InitializeDonations(), "Initialization of donations ui failed")
	-- assert(CMXint.InitializeInfoRow(), "Initialization of info row failed")
	
	assert(CMXint.InitializeFightReport(), "Initialization of fight report ui failed")
	-- assert(CMXint.InitializeLiveReport(), "Initialization of live report failed")

	CMXint.SVHandler = CombatMetricsFightData

	isFileInitialized = true
	return true
end
