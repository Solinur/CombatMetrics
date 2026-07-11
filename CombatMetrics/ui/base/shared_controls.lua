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
-- TODO: review geometry saving / remove comment
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
		anchors[2] = { BOTTOMRIGHT, parent, TOPLEFT, offsetX + (width or 0), offsetY + (height or 0) }
	end

	control.sizes[1], control.sizes[2] = width, height

	applyLayout(control)
end

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

-- Absolute rather than incremental: repeats are no-ops and SetIndent(0) restores the base. Folding
-- it into the effective record is what lets ResizeControl re-apply base + indent together without
-- knowing that indents exist.
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

-- The owner of a shared control is whoever manages its lifetime: a Panel (for panel-level controls),
-- a RowControl (for controls a scroll-list row builds) or a RowContainer (for controls a free-form
-- panel's row builds). Ownership is unambiguous — exactly one owner holds a control at a time — so a
-- control released by anyone other than its owner is a genuine bug rather than something to tolerate.
---@alias SharedControlOwner Panel|RowControl|RowContainer

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

local function defaultReset(control)
	ZO_ObjectPool_DefaultResetControl(control) -- hides the control
	ZO_ClearTable(control.data)

	ClearGeometry(control)
end

---@param control TextureControl | SharedControl
local function resetTextureControl(control)
	defaultReset(control)
	control:SetTexture("")
	control:SetTextureCoords(0, 1, 0, 1)
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

-- A row container groups the shared controls making up one row. It owns them, so handing the whole
-- row back is a single call, and it parents them, so their offsets are written once in container-
-- local coordinates and only the container is repositioned afterwards. Containers are not shared
-- controls: they belong to their panel, which is why they carry the geometry helpers but none of the
-- pool bookkeeping.
local ROW_CONTAINER_TEMPLATE = "CombatMetrics_SharedRowContainer"

---@class RowContainer: Control
---@field data table
---@field layout table
---@field sizes table
---@field anchors table
---@field indent number
---@field font table?
---@field poolKey integer?
---@field ApplyPosition fun(self: RowContainer, parent: Control, x: number, y: number, w: number?, h: number?)
---@field ApplyStretch fun(self: RowContainer, parent: Control, x: number, y: number, rightInset: number?)
---@field SetIndent fun(self: RowContainer, indent: number)
---@field ApplyFont fun(self: RowContainer, baseSize: number, bold: boolean?)
---@field AcquireSharedControl fun(self: RowContainer, controlType: integer): LabelControl|LineControl|TextureControl|SharedControl
---@field ReleaseSharedControls fun(self: RowContainer)

local function ContainerAcquireSharedControl(container, controlType)
	return ui.sharedControls:Acquire(container, controlType)
end

local function ContainerReleaseSharedControls(container)
	ui.sharedControls:ReleaseAll(container)
end

---@param control Control
---@return RowContainer
local function InitializeRowContainer(control)
	---@cast control RowContainer
	control.data = {}
	InitializeGeometry(control)

	control.ApplyPosition = ApplyPosition
	control.ApplyStretch = ApplyStretch
	control.SetIndent = SetIndent
	control.ApplyFont = ApplyFont
	control.AcquireSharedControl = ContainerAcquireSharedControl
	control.ReleaseSharedControls = ContainerReleaseSharedControls

	return control
end

-- For a panel whose row count is fixed: the containers are created once on first open and kept for
-- the panel's lifetime. Only the shared controls inside them are released when the panel hides.
---@param name string
---@param parent Control
---@return RowContainer
function ui.CreateRowContainer(name, parent)
	return InitializeRowContainer(WINDOW_MANAGER:CreateControlFromVirtual(name, parent, ROW_CONTAINER_TEMPLATE, ""))
end

-- For a panel whose row count varies with the fight: rows the current fight does not need go back to
-- the pool, and the reset hands their shared controls back with them.
---@class RowContainerPool: ZO_InitializingObject
---@field New fun(self: RowContainerPool, parent: Control): RowContainerPool
local RowContainerPool = ZO_InitializingObject:Subclass()
ui.RowContainerPool = RowContainerPool

---@param parent Control
function RowContainerPool:Initialize(parent)
	local function Create(pool)
		return InitializeRowContainer(ZO_ObjectPool_CreateControl(ROW_CONTAINER_TEMPLATE, pool, parent))
	end

	local function Reset(container)
		ContainerReleaseSharedControls(container)
		ZO_ClearTable(container.data)
		ClearGeometry(container)
		container:SetMouseEnabled(false)
		container:SetHandler("OnMouseEnter", nil)
		container:SetHandler("OnMouseExit", nil)
		container:SetParent(parent)
		ZO_ObjectPool_DefaultResetControl(container) -- hides the container
	end

	---@diagnostic disable-next-line: redundant-parameter
	self.pool = ZO_ObjectPool:New(Create, Reset)
	self.pool:SetCustomAcquireBehavior(ShowControlOnAcquire)
end

---@return RowContainer
function RowContainerPool:Acquire()
	local container, key = self.pool:AcquireObject()
	container.poolKey = key
	return container
end

---@param container RowContainer
function RowContainerPool:Release(container)
	self.pool:ReleaseObject(container.poolKey)
end

function RowContainerPool:ReleaseAll()
	self.pool:ReleaseAllObjects()
end

---@return table<any, RowContainer>
function RowContainerPool:GetActiveObjects()
	return self.pool:GetActiveObjects()
end

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
