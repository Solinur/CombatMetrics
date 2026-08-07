-- Gamepad navigation: the report's single directional-input consumer and the focus area base class.
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

---@class CMXgamepad
local gamepad = {}
ui.gamepad = gamepad

--- One panel's worth of gamepad focus. The stick moves within an area; leaving one is the
--- shoulders' job, so an area needs no map of its surroundings beyond the manager's chain.
---@class CMXFocusArea : ZO_GamepadMultiFocusArea_Base
---@field panel Panel
local FocusArea = ZO_GamepadMultiFocusArea_Base:Subclass()
ui.FocusArea = FocusArea

---@param panel Panel
function FocusArea:Initialize(panel)
	-- The navigator is a singleton, so an area is never told which manager it belongs to.
	ZO_GamepadMultiFocusArea_Base.Initialize(self, gamepad.navigator)
	self.panel = panel
end

---@param horizontal integer
---@param vertical integer
---@return boolean consumed
function FocusArea:HandleMovementInternal(horizontal, vertical)
	local manager = self.manager

	if self:HandleMovement(horizontal, vertical) then
		manager:StampMovement()
		return true
	end

	local delta
	if horizontal == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
		delta = -1
	elseif horizontal == MOVEMENT_CONTROLLER_MOVE_NEXT then
		delta = 1
	else
		return false
	end

	if manager:IsMovementOnCooldown() then
		return true
	end

	manager:CycleArea(delta)
	return true
end

---@return boolean
function FocusArea:CanBeSelected()
	return not self.panel.control:IsHidden()
end

--- Called when the panel hides while this area holds the focus.
function FocusArea:OnPanelReleased() end

--- A scroll list panel's focus area: the ZO_ScrollList cursor is the focus, the stick's vertical
--- axis walks it and the horizontal axis steps the sort column.
---@class CMXListFocusArea : CMXFocusArea
---@field New fun(self: CMXListFocusArea, panel: Panel): CMXListFocusArea
---@field paintMode boolean? nil = not painting, true = the sweep selects, false = it deselects
local ListFocusArea = FocusArea:Subclass()
ui.ListFocusArea = ListFocusArea

---@param panel Panel
function ListFocusArea:Initialize(panel)
	FocusArea.Initialize(self, panel)
	self:SetKeybindDescriptor(self:BuildKeybindDescriptor())
end

---@return SortFilterList
function ListFocusArea:GetList()
	return self.panel.dataList
end

---@return table? the row data under the cursor
function ListFocusArea:GetFocusedData()
	return ZO_ScrollList_GetSelectedData(self:GetList().list)
end

function ListFocusArea:BuildKeybindDescriptor()
	return {
		alignment = KEYBIND_STRIP_ALIGN_LEFT,

		{
			name = function()
				local data = self:GetFocusedData()
				local isSelected = data ~= nil and self:GetList().selections:IsSelected(data.id)
				return GetString(isSelected and SI_COMBAT_METRICS_DESELECT_ROW or SI_COMBAT_METRICS_SELECT_ROW)
			end,
			keybind = "UI_SHORTCUT_PRIMARY",
			handlesKeyUp = true, -- Holding this and moving paints a range.
			enabled = function()
				local data = self:GetFocusedData()
				return data ~= nil and data.id ~= nil
			end,
			callback = function(up)
				if up then
					self:EndPaint()
				else
					self:BeginPaint()
				end
			end,
		},
	}
end

function ListFocusArea:BeginPaint()
	local data = self:GetFocusedData()
	if data == nil or data.id == nil then
		return
	end

	local selections = self:GetList().selections
	self.paintMode = not selections:IsSelected(data.id)
	selections:SetSelected(data.id, self.paintMode)
	self:UpdateKeybinds()
end

function ListFocusArea:EndPaint()
	if self.paintMode == nil then
		return
	end

	self.paintMode = nil
	CMXint.fightReport:RequestUpdate()
end

function ListFocusArea:OnPanelReleased()
	self:EndPaint()
end

---@param selectedData table?
function ListFocusArea:OnCursorChanged(selectedData)
	if self.paintMode ~= nil and selectedData ~= nil and selectedData.id ~= nil then
		self:GetList().selections:SetSelected(selectedData.id, self.paintMode)
	end

	self:UpdateKeybinds()
end

---@param _ integer horizontal, unused
---@param vertical integer
---@return boolean consumed
function ListFocusArea:HandleMovement(_, vertical)
	if vertical == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
		self:GetList():MovePrevious()
		return true
	elseif vertical == MOVEMENT_CONTROLLER_MOVE_NEXT then
		self:GetList():MoveNext()
		return true
	end

	return false
end

---@return boolean
function ListFocusArea:CanBeSelected()
	return FocusArea.CanBeSelected(self) and self:GetList():HasEntries()
end

function ListFocusArea:Activate()
	if self.active then
		return
	end

	FocusArea.Activate(self)
	self:GetList():RestoreCursor()
end

function ListFocusArea:Deactivate()
	if not self.active then
		return
	end

	self:EndPaint()
	FocusArea.Deactivate(self)
	ZO_ScrollList_SelectData(self:GetList().list, nil)
end

---@param direction integer
---@return number
local function GetLeftStickMagnitude(direction)
	if direction == MOVEMENT_CONTROLLER_DIRECTION_VERTICAL then
		return DIRECTIONAL_INPUT:GetY(ZO_DI_LEFT_STICK)
	end
	return -DIRECTIONAL_INPUT:GetX(ZO_DI_LEFT_STICK)
end

--- The report's only directional-input consumer, holding the focus areas of whichever panels the
--- current view shows and dispatching stick movement to them. One instance, at ui.gamepad.navigator.
---@class CMXNavigator : ZO_GamepadMultiFocusArea_Manager
---@field isActive boolean
---@field sceneKey string? the view scene the current focus areas were built for
---@field lastStickInputMs integer?
---@field lastMoveMs integer?
local Navigator = ZO_GamepadMultiFocusArea_Manager:Subclass()

function Navigator:Initialize()
	ZO_GamepadMultiFocusArea_Manager.Initialize(self)

	local DEFAULT_ACCUMULATION = nil
	self.horizontalFocusAreaMovementController =
		ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL, DEFAULT_ACCUMULATION, GetLeftStickMagnitude)
	self.verticalFocusAreaMovementController =
		ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL, DEFAULT_ACCUMULATION, GetLeftStickMagnitude)

	self.isActive = false
	self:InitializeKeybinds()
end

--- General keybinds that are not panel-specific
function Navigator:InitializeKeybinds()
	---@return MenuPanel
	local function menuPanel()
		local panel = ui:GetPanel("menu")
		---@cast panel MenuPanel
		return panel
	end

	---@param name string for the debug log only; ethereal binds draw nothing
	---@param keybind string
	---@param callback function
	local function ethereal(name, keybind, callback)
		return { name = name, keybind = keybind, ethereal = true, callback = callback }
	end

	--- Wrapper to create keybinds that only fire on a real d-pad press but not on stick movement
	---@param name string
	---@param keybind string
	---@param callback function
	local function dpadOnly(name, keybind, callback)
		return ethereal(name, keybind, function()
			if self:IsStickActive() then
				return
			end
			callback()
		end)
	end

	self.keybindDescriptor = {
		alignment = KEYBIND_STRIP_ALIGN_LEFT,

		{
			name = function()
				return GetString(
					CMXint.IsSelectionActive() and SI_COMBAT_METRICS_CLEAR_SELECTIONS or SI_COMBAT_METRICS_CLOSE
				)
			end,
			keybind = "UI_SHORTCUT_NEGATIVE",
			callback = function()
				if CMXint.IsSelectionActive() then
					CMXint.ClearSelections()
					self:UpdateKeybinds()
				else
					CMXint.fightReport:Toggle()
				end
			end,
		},

		-- QUATERNARY is physically a hold, so the confirm-intent gesture is the binding itself.
		{
			name = function()
				local fightData = CMXint.FightData
				local alreadySaved = fightData.data ~= nil and not fightData:CanSaveFight()
				return GetString(alreadySaved and SI_COMBAT_METRICS_FIGHT_SAVED or SI_COMBAT_METRICS_SAVE_FIGHT_BIND)
			end,
			keybind = "UI_SHORTCUT_QUATERNARY",
			enabled = function()
				return CMXint.FightData:CanSaveFight()
			end,
			callback = function()
				local SAVE_LOG = false
				CMXint.FightData:SaveFight(SAVE_LOG)
				self:UpdateKeybinds()
			end,
		},

		ethereal("CMX Previous View", "UI_SHORTCUT_LEFT_SHOULDER", function()
			menuPanel():CycleView(-1)
		end),
		ethereal("CMX Next View", "UI_SHORTCUT_RIGHT_SHOULDER", function()
			menuPanel():CycleView(1)
		end),

		ethereal("CMX Previous Fight", "UI_SHORTCUT_LEFT_TRIGGER", function()
			CMXint.FightData:SelectPreviousFight()
			self:UpdateKeybinds()
		end),
		ethereal("CMX Next Fight", "UI_SHORTCUT_RIGHT_TRIGGER", function()
			CMXint.FightData:SelectNextFight()
			self:UpdateKeybinds()
		end),

		dpadOnly("CMX Focus Up", "UI_SHORTCUT_INPUT_UP", function()
			self:HandleMoveCurrentFocus(MOVEMENT_CONTROLLER_NO_CHANGE, MOVEMENT_CONTROLLER_MOVE_PREVIOUS)
		end),
		dpadOnly("CMX Focus Down", "UI_SHORTCUT_INPUT_DOWN", function()
			self:HandleMoveCurrentFocus(MOVEMENT_CONTROLLER_NO_CHANGE, MOVEMENT_CONTROLLER_MOVE_NEXT)
		end),
		dpadOnly("CMX Focus Left", "UI_SHORTCUT_INPUT_LEFT", function()
			self:HandleMoveCurrentFocus(MOVEMENT_CONTROLLER_MOVE_PREVIOUS, MOVEMENT_CONTROLLER_NO_CHANGE)
		end),
		dpadOnly("CMX Focus Right", "UI_SHORTCUT_INPUT_RIGHT", function()
			self:HandleMoveCurrentFocus(MOVEMENT_CONTROLLER_MOVE_NEXT, MOVEMENT_CONTROLLER_NO_CHANGE)
		end),
	}
end

---@return CMXFocusArea?
function Navigator:GetFirstSelectableArea()
	for _, area in ipairs(self.focusAreas) do
		if area:CanBeSelected() then
			return area
		end
	end
end

---@param delta integer
function Navigator:CycleArea(delta)
	local areas = self.focusAreas
	local count = #areas
	if count == 0 then
		return
	end

	if self.currentFocalArea == nil then
		return self:ActivateFocusArea(self:GetFirstSelectableArea())
	end

	local index = 1
	for i, area in ipairs(areas) do
		if area == self.currentFocalArea then
			index = i
			break
		end
	end

	for step = 1, count do
		local area = areas[(index - 1 + delta * step) % count + 1]
		if area:CanBeSelected() then
			self:SelectFocusArea(area)
			return
		end
	end
end

function Navigator:UpdateKeybinds()
	KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindDescriptor)
end

local AREA_SWITCH_COOLDOWN_MS = 400

function Navigator:RegisterMovement()
	self.lastMoveMs = GetFrameTimeMilliseconds()
end

---@return boolean
function Navigator:IsMovementOnCooldown()
	local lastMs = self.lastMoveMs
	return lastMs ~= nil and (GetFrameTimeMilliseconds() - lastMs) < AREA_SWITCH_COOLDOWN_MS
end

function Navigator:OnFocusChanged()
	self:RegisterMovement()
end

local STICK_SETTLE_MS = 50

---@return boolean isActive
function Navigator:IsStickActive()
	local lastMs = self.lastStickInputMs
	return lastMs ~= nil and (GetFrameTimeMilliseconds() - lastMs) < STICK_SETTLE_MS
end

function Navigator:UpdateDirectionalInput()
	ZO_GamepadMultiFocusArea_Manager.UpdateDirectionalInput(self)

	local isDeflected = self.horizontalFocusAreaMovementController.lastMagnitude ~= 0
		or self.verticalFocusAreaMovementController.lastMagnitude ~= 0

	if isDeflected then
		self.lastStickInputMs = GetFrameTimeMilliseconds()
	end
end

---@param sceneKey string?
function Navigator:Rebuild(sceneKey)
	if self.currentFocalArea then
		self.currentFocalArea:Deactivate()
	end

	self.focusAreas = {}
	self.currentFocalArea = nil
	self.sceneKey = sceneKey

	local areas = {}
	for _, panel in pairs(ui.panels) do
		local area = panel:GetFocusArea()
		if area and not panel.control:IsHidden() then
			areas[#areas + 1] = area
		end
	end

	table.sort(areas, function(a, b)
		local aLeft, bLeft = a.panel.control:GetLeft(), b.panel.control:GetLeft()
		if aLeft ~= bLeft then
			return aLeft < bLeft
		end
		return a.panel.control:GetTop() < b.panel.control:GetTop()
	end)

	for _, area in ipairs(areas) do
		self:AddNextFocusArea(area)
	end

	if self.isActive then
		self:ActivateFocusArea(self:GetFirstSelectableArea())
	end
end

function Navigator:Activate()
	if self.isActive or not IsInGamepadPreferredMode() then
		return
	end
	self.isActive = true

	DIRECTIONAL_INPUT:Activate(self, CMXint.fightReport)
	KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindDescriptor)
	self:ActivateFocusArea(self:GetFirstSelectableArea())

	logger:Debug("Navigator activated with %d focus area(s)", #self.focusAreas)
end

function Navigator:Deactivate()
	if not self.isActive then
		return
	end
	self.isActive = false

	self:ActivateFocusArea(nil)
	DIRECTIONAL_INPUT:Deactivate(self)
	KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindDescriptor)

	logger:Debug("Navigator deactivated")
end

local function forEachReportScene(callback)
	callback(CMXint.scenes.report)
	for _, scene in pairs(CMXint.scenes.views) do
		callback(scene)
	end
end

function gamepad.ApplyFragmentGroups()
	local useGamepad = IsInGamepadPreferredMode()

	forEachReportScene(function(scene)
		if useGamepad then
			scene:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
		else
			scene:RemoveFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
		end
	end)

	logger:Debug("Gamepad fragment group %s", useGamepad and "added" or "removed")
end

local function onGamepadPreferredModeChanged()
	-- ZO_IngameSceneManager:OnGamepadPreferredModeChanged force-closes the report, so the scenes are
	-- always hidden by the time this runs.
	gamepad.navigator:Deactivate()
	gamepad.ApplyFragmentGroups()
end

local function registerViewSceneCallbacks()
	for key, scene in pairs(CMXint.scenes.views) do
		scene:RegisterCallback("StateChange", function(_, newState)
			if newState == SCENE_SHOWN then
				gamepad.navigator:Rebuild(key)
				gamepad.navigator:Activate()
			elseif newState == SCENE_HIDDEN and not ui.IsAnyViewShowing() then
				gamepad.navigator:Deactivate()
			end
		end)
	end
end

local isFileInitialized = false
function CMXint.InitializeGamepad()
	if isFileInitialized == true then
		return true
	end
	logger = util.initSublogger("Gamepad")

	gamepad.navigator = Navigator:New()

	registerViewSceneCallbacks()

	EVENT_MANAGER:RegisterForEvent("CMX_Gamepad", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, onGamepadPreferredModeChanged)
	gamepad.ApplyFragmentGroups()

	isFileInitialized = true
	return true
end
