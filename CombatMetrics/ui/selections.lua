local CMX = CombatMetrics
local CMXint = CMX.internal
local util = CMXint.util
CMXint.selections = {}
local CMXSel = CMXint.selections
local logger

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
	if isFileInitialized == true then return false end
	logger = util.initSublogger("Selections")

    isFileInitialized = true
	return true
end