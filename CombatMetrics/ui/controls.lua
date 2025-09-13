local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger

local ControlHandler = ZO_InitializingObject:Subclass()
CMXint.ControlHandler = ControlHandler



local isFileInitialized = false
function CMXint.InitializeEControlHandler()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("Controls")

    isFileInitialized = true
	return true
end