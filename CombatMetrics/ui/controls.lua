local CMX = CombatMetrics
local CMXint = CMX.internal
local util = CMXint.util
local ui = CMXint.ui
local logger



local function InitializeSharedControl(control, pool, objectKey)
	control.pool = pool
	control.objectKey = objectKey
	control.shared = true
end

function ReleaseSharedControl(control)
	control:SetParent(CombatMetricsReport)
	control.pool:ReleaseObject(control.objectKey)
end

local function ApplyPosition(control, parent, offsetX, offsetY, width, height)
	local scale = CMXint.settings.fightReport.scale
	control:SetParent(parent)
	control:SetAnchor(TOPLEFT, parent, TOPLEFT, offsetX*scale, offsetY*scale)

	if control:GetType() == CT_LINE then
		local offsetX2 = offsetX + (width or 0)
		local offsetY2 = offsetY + (height or 0)
		control:SetAnchor(BOTTOMRIGHT, parent, TOPLEFT, offsetX2*scale, offsetY2*scale)
	end

	if width then
		control:SetWidth(width*scale)
	end

	if height then
		control:SetHeight(height*scale)
	end
end

local function ShowControlOnAcquire(control)
    control:SetHidden(false)
end


local function CreateSharedControlType(template)
	function CreateControl(pool, objectKey)
		local newControl = ZO_ObjectPool_CreateControl(template, pool, CombatMetricsReport)
		InitializeSharedControl(newControl, pool, objectKey)

		newControl.Release = ReleaseSharedControl
		newControl.ApplyPosition = ApplyPosition

		return newControl
	end

	local pool = ZO_ObjectPool:New(CreateControl, ZO_ObjectPool_DefaultResetControl)
	pool:SetCustomAcquireBehavior(ShowControlOnAcquire)

	return pool
end

local isFileInitialized = false
function CMXint.InitializeControlHandler()
	if isFileInitialized == true then return false end
	logger = util.initSublogger("Controls")

	ui.sharedTextures = CreateSharedControlType("CombatMetrics_SharedTexture")
	ui.sharedLabels = CreateSharedControlType("CombatMetrics_SharedLabel")
	ui.sharedSeparators = CreateSharedControlType("CombatMetrics_SharedSeparator")

    isFileInitialized = true
	return true
end