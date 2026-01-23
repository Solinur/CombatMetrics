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
	if isFileInitialized == true then return false end
	logger = util.initSublogger("Selections")

	isFileInitialized = true
	return true
end