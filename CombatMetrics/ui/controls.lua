local CMX = CombatMetrics
local CMXint = CMX.internal
local util = CMXint.util
local ui = CMXint.ui
local logger

local ControlHandler = ZO_InitializingObject:Subclass()
CMXint.ControlHandler = ControlHandler



local isFileInitialized = false
function CMXint.InitializeEControlHandler()
	if isFileInitialized == true then return false end
	logger = util.initSublogger("Controls")

    isFileInitialized = true
	return true
end