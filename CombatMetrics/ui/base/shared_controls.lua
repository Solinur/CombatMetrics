-- Shared control pool + lifetime manager (SharedControlManager) and per-control geometry helpers.
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

-- ============================================================================
-- Per-control helpers (bookkeeping fields + geometry)
-- ============================================================================

-- Geometry is recorded before it is applied. `layout` holds the pristine unscaled arguments, while
-- `sizes` / `anchors` hold the effective (indent-adjusted, still unscaled) layout in exactly the
-- shape ResizeControl in fight_report.lua consumes. That is what makes shared controls visible to
-- the resize pass: it walks the live control tree and skips anything without those two records.
-- applyLayout is the only place the scale factor is multiplied in.
local function InitializeGeometry(control)
	control.layout = {}
	control.sizes = {}
	control.anchors = {}
	control.indent = 0
	control.font = nil
end

local function ClearGeometry(control)
	ZO_ClearTable(control.layout)
	ZO_ClearTable(control.sizes)
	ZO_ClearTable(control.anchors)
	control.indent = 0
	control.font = nil
end

local function InitializeSharedControl(control, pool, objectKey)
	control.pool = pool
	control.objectKey = objectKey
	control.shared = true
	-- Per-lease custom state (abilityId, itemLink, starId, …) lives here so releasing a control is
	-- a single ZO_ClearTable rather than a list of field nils. Created once; cleared, not replaced.
	control.data = {}
	InitializeGeometry(control)
end

local function applyLayout(control)
	local anchors = control.anchors
	if anchors[1] == nil then
		return
	end

	local scale = CMXint.settings.fightReport.scale
	local width, height = control.sizes[1], control.sizes[2]

	control:SetParent(control.layout.parent)
	control:ClearAnchors()

	for i = 1, #anchors do
		local point, relativeTo, relativePoint, x, y = unpack(anchors[i])
		control:SetAnchor(point, relativeTo, relativePoint, x * scale, y * scale)
	end

	if width then
		control:SetWidth(width * scale)
	end

	if height then
		control:SetHeight(height * scale)
	end
end

local function TraceGeometry(control, parent)
	if not ui.debugSharedControls then
		return
	end
	-- A row container is owned by its panel directly rather than leased from the manager, so only a
	-- shared control without an owner is a genuine bug here.
	if control.shared and control.owner == nil then
		logger:Error(
			"ApplyPosition: %s is not owned by any panel; positioning into %s",
			control:GetName(),
			parent:GetName()
		)
	end
	control.positionedBy = parent:GetName()
end

local function ApplyPosition(control, parent, offsetX, offsetY, width, height)
	TraceGeometry(control, parent)

	local layout = control.layout
	layout.parent, layout.x, layout.y, layout.w, layout.h = parent, offsetX, offsetY, width, height
	control.indent = 0

	local anchors = control.anchors
	anchors[1] = { TOPLEFT, parent, TOPLEFT, offsetX, offsetY }
	anchors[2] = nil

	if control:GetType() == CT_LINE then
		-- A line is defined by its two end points rather than by its dimensions.
		anchors[2] = { BOTTOMRIGHT, parent, TOPLEFT, offsetX + (width or 0), offsetY + (height or 0) }
	end

	control.sizes[1], control.sizes[2] = width, height

	applyLayout(control)
end

-- Anchors the control to both sides of its parent so its width follows the parent, for a column that
-- has to fill whatever space is left instead of taking a fixed width.
local function ApplyStretch(control, parent, offsetX, offsetY, rightInset)
	TraceGeometry(control, parent)

	local layout = control.layout
	layout.parent, layout.x, layout.y, layout.w, layout.h = parent, offsetX, offsetY, nil, nil
	control.indent = 0

	local anchors = control.anchors
	anchors[1] = { TOPLEFT, parent, TOPLEFT, offsetX, offsetY }
	anchors[2] = { TOPRIGHT, parent, TOPRIGHT, -(rightInset or 0), offsetY }

	control.sizes[1], control.sizes[2] = nil, nil

	applyLayout(control)
end

-- Shifts the control right and narrows it by the same amount, on top of its recorded base layout.
-- Absolute rather than incremental: repeats are no-ops and SetIndent(0) restores the base, so no
-- caller has to track the indent it applied last. Folding it into the effective record is also what
-- lets ResizeControl re-apply base + indent together without knowing that indents exist.
---@param control Control
---@param indent number
local function SetIndent(control, indent)
	local layout = control.layout
	local anchors = control.anchors

	if anchors[1] == nil then
		logger:Error("SetIndent: %s has no recorded layout; ApplyPosition must run first", control:GetName())
		return
	end

	control.indent = indent
	anchors[1][4] = layout.x + indent
	control.sizes[1] = layout.w and layout.w - indent or nil

	applyLayout(control)
end

-- ui.GetFont bakes the current scale into the font string, so a stored string would go stale on a
-- resize. Record the base size instead and let ResizeControl rebuild the string at the new scale.
---@param control Control
---@param baseSize number
---@param bold boolean?
local function ApplyFont(control, baseSize, bold)
	control.font = { baseSize, bold }
	control:SetFont(ui.GetFont(baseSize, bold))
end

local function ShowControlOnAcquire(control)
	control:SetHidden(false)
end

-- ============================================================================
-- SharedControlManager — single-owner lifetime tracking
-- ============================================================================

-- The owner of a shared control is whoever manages its lifetime: a Panel (for panel-level
-- controls) or a RowControl (for controls a scroll-list row builds). Ownership is unambiguous —
-- exactly one owner holds a control at a time — so a control released by anyone other than its
-- owner is a genuine bug rather than something to tolerate.
---@alias SharedControlOwner Panel|RowControl

local function ownerLabel(owner)
	if owner == nil then
		return "nobody"
	end
	if owner.name then
		return owner.name
	end
	if owner.GetName then
		return owner:GetName()
	end
	return tostring(owner)
end

-- Pool reset callbacks. These run on pool:ReleaseObject, so Release never has to remember to reset
-- a control. Pass one to AddSharedControlType; omit it (e.g. for separators) to get defaultReset.
-- defaultReset hides the control and drops its per-lease data; the type-specific variants build on
-- it, adding the mutable ESO properties panel code changes. A released control must not inherit
-- stale texture/color/blend/alignment/interaction state, hence the neutral defaults below.
local function defaultReset(control)
	ZO_ObjectPool_DefaultResetControl(control) -- hides the control
	ZO_ClearTable(control.data)
	-- A released control keeps sitting in the tree (reparented to CombatMetricsReport), so its
	-- geometry record has to go too or the resize pass would re-anchor it while it is idle.
	ClearGeometry(control)
end

---@param control TextureControl | SharedControl
local function resetTextureControl(control)
	defaultReset(control)
	control:SetTexture("")
	control:SetTextureCoords(0, 0, 1, 1)
	control:SetColor(1, 1, 1, 1)
	control:SetBlendMode(TEX_BLEND_MODE_ALPHA)
	control:SetMouseEnabled(false)
	control:SetHandler("OnMouseEnter", nil)
	control:SetHandler("OnMouseExit", nil)
	control:SetHandler("OnMouseUp", nil)
end

---@param control LabelControl | SharedControl
local function resetLabelControl(control)
	defaultReset(control)
	control:SetText("")
	control:SetColor(1, 1, 1, 1)
	control:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
	control:SetMouseEnabled(false)
	control:SetLinkEnabled(false)
	control:SetHandler("OnMouseEnter", nil)
	control:SetHandler("OnMouseExit", nil)
	control:SetHandler("OnLinkClicked", nil)
end

---@class SharedControlManager: ZO_InitializingObject
---@field New fun(self: SharedControlManager): SharedControlManager
---@field pools table<integer, object>
---@field owners table<SharedControlOwner, table<SharedControl, true>>
local SharedControlManager = ZO_InitializingObject:Subclass()

function SharedControlManager:Initialize()
	self.owners = {}
	self.pools = {}
end

-- Registers an object pool for one shared control template under controlType, so Acquire can hand
-- out controls of that type. Each created control is wired with its bookkeeping fields and the
-- per-control geometry helpers. resetFunction is the pool reset callback (run on release);
-- defaults to defaultReset (hide + clear data) when omitted.
---@param controlType integer
---@param template string
---@param resetFunction? fun(control: SharedControl)
function SharedControlManager:AddSharedControlType(controlType, template, resetFunction)
	local function CreateControl(pool, objectKey)
		---@class SharedControl: Control
		---@field pool object
		---@field objectKey integer
		---@field owner SharedControlOwner?
		---@field positionedBy string?
		---@field shared true
		---@field data table
		---@field layout table
		---@field sizes table
		---@field anchors table
		---@field indent number
		---@field font table?
		local newControl = ZO_ObjectPool_CreateControl(template, pool, CombatMetricsReport)
		InitializeSharedControl(newControl, pool, objectKey)

		newControl.ApplyPosition = ApplyPosition
		newControl.ApplyStretch = ApplyStretch
		newControl.SetIndent = SetIndent
		newControl.ApplyFont = ApplyFont

		return newControl
	end

	---@diagnostic disable-next-line: redundant-parameter
	local pool = ZO_ObjectPool:New(CreateControl, resetFunction or defaultReset)
	pool:SetCustomAcquireBehavior(ShowControlOnAcquire)

	self.pools[controlType] = pool
end

-- Leases a pooled control of controlType to owner, recording owner as its single owner until it
-- (and only it) releases the control again.
---@param owner SharedControlOwner
---@param controlType integer
---@return LabelControl|LineControl|TextureControl|SharedControl
function SharedControlManager:Acquire(owner, controlType)
	local pool = self.pools[controlType]
	if pool == nil then
		logger:Error("Attempt to acquire unsupported control type: %d", controlType)
		---@diagnostic disable-next-line: missing-return-value
		return
	end

	local control = pool:AcquireObject()

	if ui.debugSharedControls then
		local prevOwner = control.owner
		if prevOwner ~= nil then
			logger:Error(
				"Acquire: %s handed to '%s' while still owned by '%s' (positioned into %s)",
				control:GetName(),
				ownerLabel(owner),
				ownerLabel(prevOwner),
				tostring(control.positionedBy)
			)
		end
		logger:Debug("Acquire: %s for %s", control:GetName(), ownerLabel(owner))
	end

	---@diagnostic disable-next-line: inject-field
	control.owner = owner

	local set = self.owners[owner]
	if set == nil then
		set = {}
		self.owners[owner] = set
	end
	set[control] = true

	return control
end

-- Releases a single control back to its pool. An owner may only give back what it owns:
--   * already free (owner == nil) -> benign no-op, returns false
--   * owned by someone else       -> hard error (the real two-owner bug)
--   * owned by the caller         -> released and reset, returns true
---@param owner SharedControlOwner
---@param control SharedControl
---@return boolean released
function SharedControlManager:Release(owner, control)
	local current = control.owner

	if current == nil then
		if ui.debugSharedControls then
			logger:Debug(
				"Release: %s was already free (positioned by %s)",
				control:GetName(),
				tostring(control.positionedBy)
			)
		end
		return false
	end

	if current ~= owner then
		error(
			string.format(
				"Shared control %s released by '%s' but owned by '%s' (positioned into %s)",
				control:GetName(),
				ownerLabel(owner),
				ownerLabel(current),
				tostring(control.positionedBy)
			)
		)
	end

	if ui.debugSharedControls then
		logger:Debug("Release: %s from %s", control:GetName(), ownerLabel(owner))
	end

	local set = self.owners[owner]
	if set then
		set[control] = nil
		if next(set) == nil then
			self.owners[owner] = nil
		end
	end

	control.owner = nil
	control.positionedBy = nil

	control:SetParent(CombatMetricsReport)
	control.pool:ReleaseObject(control.objectKey) -- runs the pool reset (hide + property + data)

	return true
end

-- Releases every control owned by owner. Both the row-reset path and the panel-hide path call
-- this; because owners are disjoint (a row owns its row controls, a panel owns its own), no
-- control is ever released twice.
---@param owner SharedControlOwner
function SharedControlManager:ReleaseAll(owner)
	local set = self.owners[owner]
	if set == nil then
		return
	end
	-- Release prunes the set, so drain it with next rather than iterating a snapshot.
	while true do
		local control = next(set)
		if control == nil then
			break
		end
		self:Release(owner, control)
	end
end

-- Debug check: every control the map credits to owner must still point back at owner.
---@param owner SharedControlOwner
function SharedControlManager:Verify(owner)
	local set = self.owners[owner]
	if set == nil then
		return
	end
	for control in pairs(set) do
		if control.owner ~= owner then
			logger:Error(
				"Verify '%s': owned set holds %s, owned by '%s', positioned into %s",
				ownerLabel(owner),
				control:GetName(),
				ownerLabel(control.owner),
				tostring(control.positionedBy)
			)
		end
	end
end

-- ============================================================================
-- Initialization
-- ============================================================================

local isFileInitialized = false
function CMXint.InitializeSharedControls()
	if isFileInitialized == true then
		return false
	end
	logger = util.initSublogger("Controls")

	-- Traces shared control ownership: double releases, foreign acquires, positioning of
	-- released controls. Toggle with /cmxdebugcontrols.
	ui.debugSharedControls = false

	local sharedControls = SharedControlManager:New()
	sharedControls:AddSharedControlType(CT_TEXTURE, "CombatMetrics_SharedTexture", resetTextureControl)
	sharedControls:AddSharedControlType(CT_LABEL, "CombatMetrics_SharedLabel", resetLabelControl)
	sharedControls:AddSharedControlType(CT_LINE, "CombatMetrics_SharedSeparator")
	ui.sharedControls = sharedControls

	isFileInitialized = true
	return true
end
