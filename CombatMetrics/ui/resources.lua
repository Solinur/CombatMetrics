local CMX = CombatMetrics
local CMXint = CMX.internal
local util = CMXint.util
local ui = CMXint.ui
local logger

local GetFormattedAbilityName = util.GetFormattedAbilityName
local adjustRowSize = util.adjustRowSize
local dx = CMXint.dx

local function UpdateResourceBars(panel, currentanchor, data, totalRate, selectedresources, color)
	local settings = CMXint.settings.fightReport
	local showids = settings.showDebugIds

	local scrollchild = GetControl(panel, "PanelScrollChild")

	for abilityId, ability in CMX.spairs(data, function(t, a, b) return t[a].value>t[b].value end) do
		if (ability.ticks or 0) > 0 then
			local label = GetFormattedAbilityName(abilityId)
			local highlight = false
			if selectedresources ~= nil then highlight = selectedresources[abilityId] ~= nil end

			local dbug = showids and string.format("(%d) ", abilityId) or ""
			local name = dbug..label

			local count = ability.ticks
			local rate = ability.rate
			local ratio = rate/totalRate

			local rowId = #panel.bars + 1
			local rowName = scrollchild:GetName() .. "Row" .. rowId
			local row = _G[rowName] or CreateControlFromVirtual(rowName, scrollchild, "CombatMetrics_ResourceRowTemplate")
			row:SetAnchor(unpack(currentanchor))
			row:SetHidden(false)

			local header = panel:GetNamedChild("Header")
			adjustRowSize(row, header)

			local highlightControl = row:GetNamedChild("HighLight")
			highlightControl:SetHidden(not highlight)

			local nameControl = row:GetNamedChild("Name")
			nameControl:SetText(name)
			local maxwidth = nameControl:GetWidth()

			local barControl = row:GetNamedChild("Bar")
			barControl:SetWidth(maxwidth * ratio)
			barControl:SetCenterColor(unpack(color))

			local countControl = row:GetNamedChild("Count")
			countControl:SetText(count)

			local rateControl = row:GetNamedChild("Rate")
			rateControl:SetText(string.format("%.0f", rate))

			currentanchor = {TOPLEFT, row, BOTTOMLEFT, 0, dx}

			panel.bars[rowId] = row

			row.dataId = abilityId
			row.type = "resource"
			row.id = rowId
			row.panel = panel
		end
	end

	return currentanchor
end


local function updateResourcePanel(self, fightData)
	logger:Debug("Updating Resource Panel")
	if fightData == nil then return end

	local control = self.control
	local settings = self.settings
	local selections = CMXint.selections
	local rightpanel = settings.rightpanel

	local subpanel1 = control:GetNamedChild("Gains")
	local subpanel2 = control:GetNamedChild("Drains")

	self:ResetBars(subpanel1)
	self:ResetBars(subpanel2)

	local key, color1, color2
    if rightpanel == "magicka" then
		key = POWERTYPE_MAGICKA
		color1 = {0.3, 0.4, 0.6, 1}
		color2 = {0.4, 0.3, 0.6, 1}
	elseif rightpanel == "stamina" then
		key = POWERTYPE_STAMINA
		color1 = {0.4, 0.6, 0.3, 1}
		color2 = {0.4, 0.45, 0.05, 1}
	else return end

	local data = fightData.calculated.resources[key]
	local selectedresources = selections["resource"]["resource"]

	local scrollchild = GetControl(subpanel1, "PanelScrollChild")
	local currentanchor = {TOPLEFT, scrollchild, TOPLEFT, 0, 1}

	UpdateResourceBars(subpanel1, currentanchor, data.gains, data.gainRate, selectedresources, color1) -- generate bars for resource gains

	local scrollchild = GetControl(subpanel2, "PanelScrollChild")
	local currentanchor = {TOPLEFT, scrollchild, TOPLEFT, 0, 1}

	UpdateResourceBars(subpanel2, currentanchor, data.drains, data.drainRate, selectedresources, color2) -- generate bars for resource drains
end

local isFileInitialized = false
function CMXint.InitializeResourcePanel()
	if isFileInitialized == true then return false end
	logger = util.initSublogger("Resources")
	
	-- TODO: make control
	-- ResourcePanel = CMXint.panels.resources
	-- ResourcePanel.Update = updateResourcePanel
	-- ResourcePanel.Release = function() end

    isFileInitialized = true
	return true
end