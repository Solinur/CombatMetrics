local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger

local isFileInitialized = false
function CMXint.InitializeXXX()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("XXX")

    isFileInitialized = true
	return true
end