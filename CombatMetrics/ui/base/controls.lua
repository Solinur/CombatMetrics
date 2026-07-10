-- Shared control classes
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

local function InitializeSharedControl(control, pool, objectKey)
	control.pool = pool
	control.objectKey = objectKey
	control.shared = true
end

local function ReleaseSharedControl(control)
	-- A control reaches this twice: the row control pool releases the controls of a recycled row,
	-- and the panel that acquired them releases them again when it is hidden. Without this guard
	-- the second release hands a control that another panel has meanwhile acquired back to the
	-- pool, so two panels end up owning it.
	if control.owner == nil then
		if ui.debugSharedControls then
			logger:Debug("Release: %s was already free (positioned by %s)", control:GetName(), control.positionedBy)
		end
		return
	end

	if ui.debugSharedControls then
		logger:Debug("Release: %s from %s", control:GetName(), control.owner.name)
	end
	control.owner.sharedControls[control] = nil
	control.owner = nil
	control.positionedBy = nil

	control:SetParent(CombatMetricsReport)
	control.pool:ReleaseObject(control.objectKey)

	-- Reset each pooled control to a neutral default so a panel reusing it doesn't
	-- inherit stale color/blend/alignment/interaction state from the previous owner.
	local controlType = control:GetType()
	if controlType == CT_TEXTURE then
		control:SetTexture("")
		control:SetTextureCoords(0, 0, 1, 1)
		control:SetColor(1, 1, 1, 1)
		control:SetBlendMode(TEX_BLEND_MODE_ALPHA)
		control:SetMouseEnabled(false)
		control:SetHandler("OnMouseEnter", nil)
		control:SetHandler("OnMouseExit", nil)
		control:SetHandler("OnMouseUp", nil)
		control.abilityId = nil
		control.scriptIds = nil
		control.starId = nil
		control.points = nil
		control.slotted = nil
	elseif controlType == CT_LABEL then
		control:SetText("")
		control:SetColor(1, 1, 1, 1)
		control:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
		control:SetMouseEnabled(false)
		control:SetLinkEnabled(false)
		control:SetHandler("OnMouseEnter", nil)
		control:SetHandler("OnMouseExit", nil)
		control:SetHandler("OnLinkClicked", nil)
		control.itemLink = nil
		control.enchantDescription = nil
		control.abilityId = nil
		control.starId = nil
		control.points = nil
		control.slotted = nil
	end
end

local function ApplyPosition(control, parent, offsetX, offsetY, width, height)
	if ui.debugSharedControls then
		if control.owner == nil then
			logger:Error(
				"ApplyPosition: %s is not owned by any panel; positioning into %s",
				control:GetName(),
				parent:GetName()
			)
		end
		control.positionedBy = parent:GetName()
	end

	local scale = CMXint.settings.fightReport.scale
	control:SetParent(parent)
	control:SetAnchor(TOPLEFT, parent, TOPLEFT, offsetX * scale, offsetY * scale)

	if control:GetType() == CT_LINE then
		local offsetX2 = offsetX + (width or 0)
		local offsetY2 = offsetY + (height or 0)
		control:SetAnchor(BOTTOMRIGHT, parent, TOPLEFT, offsetX2 * scale, offsetY2 * scale)
	end

	if width then
		control:SetWidth(width * scale)
	end

	if height then
		control:SetHeight(height * scale)
	end
end

---@param control Control
---@param indent number
local function ApplyIndent(control, indent)
	local scale = CMXint.settings.fightReport.scale

	indent = indent * scale

	local _, point, relTo, relPoint, offsX, offsY, _ = control:GetAnchor(0)
	---@diagnostic disable-next-line: missing-parameter
	control:SetAnchor(point, relTo, relPoint, offsX + indent, offsY)
	control:SetWidth(control:GetWidth() - indent)
end

local function ShowControlOnAcquire(control)
	control:SetHidden(false)
end

local function CreateSharedControlType(template)
	local function CreateControl(pool, objectKey)
		---@class SharedControl: Control
		---@field pool object
		---@field objectKey integer
		---@field owner Panel?
		---@field positionedBy string?
		---@field shared true
		local newControl = ZO_ObjectPool_CreateControl(template, pool, CombatMetricsReport)
		InitializeSharedControl(newControl, pool, objectKey)

		newControl.Release = ReleaseSharedControl
		newControl.ApplyPosition = ApplyPosition
		newControl.ApplyIndent = ApplyIndent

		return newControl
	end

	---@diagnostic disable-next-line: redundant-parameter
	local pool = ZO_ObjectPool:New(CreateControl, ZO_ObjectPool_DefaultResetControl)
	pool:SetCustomAcquireBehavior(ShowControlOnAcquire)

	return pool
end

local isFileInitialized = false
function CMXint.InitializeControlHandler()
	if isFileInitialized == true then
		return false
	end
	logger = util.initSublogger("Controls")

	-- Traces shared control ownership: double releases, foreign acquires, positioning of
	-- released controls. Toggle with /cmxdebugcontrols.
	ui.debugSharedControls = false

	ui.sharedTextures = CreateSharedControlType("CombatMetrics_SharedTexture")
	ui.sharedLabels = CreateSharedControlType("CombatMetrics_SharedLabel")
	ui.sharedSeparators = CreateSharedControlType("CombatMetrics_SharedSeparator")

	isFileInitialized = true
	return true
end
