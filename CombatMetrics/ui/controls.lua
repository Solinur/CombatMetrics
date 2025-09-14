local CMX = CombatMetrics
local CMXint = CMX.internal
local util = CMXint.util
local ui = CMXint.ui
local logger

local function CreateSharedControlType(template)
	local SharedControlType = ZO_Object:Subclass()

	function SharedControlType:New(pool, objectKey)
		local newControl = ZO_ObjectPool_CreateControl(template, pool, CombatMetricsReport)
		local controlMeta = getmetatable(newControl)
		newControl = setmetatable(newControl, {
			__index = function(table, key)
				local entry = controlMeta[key]
				if entry ~= nil then
					return entry
				else
					return self[key]
				end
			end
		})
		newControl.__index = newControl
		newControl:Initialize(pool, objectKey)
		return newControl
	end

	function SharedControlType:Initialize(pool, objectKey)
		self.pool = pool
		self.objectKey = objectKey
		self.template = template
		self.shared = true
	end

	function SharedControlType:Release()
		self:SetParent(CombatMetricsReport)
		self.pool:ReleaseObject(self.objectKey)
	end
	
	function SharedControlType:ApplyPosition(parent, offsetX, offsetY, width, height)
		local scale = CMXint.settings.FightReport.scale
		self:SetParent(parent)
		self:SetAnchor(TOPLEFT,  offsetX, TOPLEFT, offsetX*scale, offsetY*scale)
		self:SetDimensions(width*scale, height*scale)
	end

	return ZO_ObjectPool:New(SharedControlType, ZO_ObjectPool_DefaultResetControl)
end

local isFileInitialized = false
function CMXint.InitializeControlHandler()
	if isFileInitialized == true then return false end
	logger = util.initSublogger("Controls")

	ui.sharedTextures = CreateSharedControlType("CombatMetrics_SharedTexture")
	ui.sharedLabels = CreateSharedControlType("CombatMetrics_SharedLabel")

    isFileInitialized = true
	return true
end