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

-- function CMXint.ClearSelections()
-- 	local category = CMXint.settings.fightReport.category or "damageOut"
-- 	local selections = ui.selections

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

-- 	local category = selecttype == "buff" and "buff" or selecttype == "resource" and "resource" or CMXint.settings.fightReport.category

-- 	local selections = ui.selections
-- 	local lastSelections = CMXint.lastSelections
-- 	local sel = selections[selecttype][category] -- can be nil so this is not always a reference
-- 	local lastsel = lastSelections[selecttype][category]
-- 	local bars = self.panel.bars

-- 	if button == MOUSE_BUTTON_INDEX_MIDDLE then
-- 		selections[selecttype][category] = nil
-- 		lastSelections[selecttype][category] = nil
-- 		CombatMetricsReport:Update(currentFight)

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
-- 	CombatMetricsReport:Update(currentFight)
-- end

ui.selections = {}
local CMXSel = ui.selections

local SelectionsObject = ZO_InitializingObject:Subclass()

function SelectionsObject:Initialize(panel)
	self.panel = panel
	CMXSel[panel.name] = self
end

function CMXint.IsSelectionActive()
	for name, selections in pairs(CMXSel) do
		if selections.active then
			return true
		end
	end
	return false
end

local isFileInitialized = false
function CMXint.InitializeSelectionsHandler()
	if isFileInitialized == true then
		return false
	end
	logger = util.initSublogger("Selections")

	isFileInitialized = true
	return true
end
