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
---@field canEscape boolean whether a boundary crossing is allowed, see HandleMovementInternal
local FocusArea = ZO_GamepadMultiFocusArea_Base:Subclass()
ui.FocusArea = FocusArea

---@param manager CMXNavigator
---@param panel Panel
---@param activateCallback function?
---@param deactivateCallback function?
function FocusArea:Initialize(manager, panel, activateCallback, deactivateCallback)
	ZO_GamepadMultiFocusArea_Base.Initialize(self, manager, activateCallback, deactivateCallback)
	self.panel = panel
end

function FocusArea:Activate()
	self.canEscape = false -- A stick still held from the previous area must not carry on through this one.
	ZO_GamepadMultiFocusArea_Base.Activate(self)
end

--- Offers the move to the panel first, then sideways to the adjoining area. Vertical never leaves:
--- the manager's chain is ordered left to right, so stepping it on an up/down push would jump
--- sideways, and the shoulders already leave a panel in one press from any scroll position.
---
--- A held stick stops at the boundary and only a fresh push crosses it; without that, the movement
--- controller's acceleration flings the focus out of a long list and into the next panel at speed.
---@param horizontal integer
---@param vertical integer
---@return boolean consumed
function FocusArea:HandleMovementInternal(horizontal, vertical)
	if self:HandleMovement(horizontal, vertical) then
		-- The hold belongs to the interior now, so it may no longer leave.
		self.canEscape = false
		return true
	end

	local neighbour
	if horizontal == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
		neighbour = self.manager:GetPreviousSelectableFocusArea(self)
	elseif horizontal == MOVEMENT_CONTROLLER_MOVE_NEXT then
		neighbour = self.manager:GetNextSelectableFocusArea(self)
	end

	if neighbour == nil then
		return false
	end

	if not self.canEscape then
		return true
	end

	self.manager:SelectFocusArea(neighbour)
	return true
end

---@return boolean
function FocusArea:CanBeSelected()
	return not self.panel.control:IsHidden()
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
local Navigator = ZO_GamepadMultiFocusArea_Manager:Subclass()

function Navigator:Initialize()
	ZO_GamepadMultiFocusArea_Manager.Initialize(self)

	local DEFAULT_ACCUMULATION = nil
	self.horizontalFocusAreaMovementController =
		ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL, DEFAULT_ACCUMULATION, GetLeftStickMagnitude)
	self.verticalFocusAreaMovementController =
		ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL, DEFAULT_ACCUMULATION, GetLeftStickMagnitude)

	self.isActive = false

	-- On the navigator rather than a focus area, so these stay available with nothing focused.
	self.keybindDescriptor = {
		alignment = KEYBIND_STRIP_ALIGN_LEFT,
		{
			name = GetString(SI_COMBAT_METRICS_CLOSE),
			keybind = "UI_SHORTCUT_NEGATIVE",
			callback = function()
				CMXint.fightReport:Toggle()
			end,
		},
	}
end

function Navigator:UpdateDirectionalInput()
	ZO_GamepadMultiFocusArea_Manager.UpdateDirectionalInput(self)

	-- Neutral is read off the cached lastMagnitude, not GetMagnitude(): that goes through
	-- DIRECTIONAL_INPUT:GetX/GetY, which consume the device for the frame and would starve the
	-- CheckMovement calls above.
	local area = self.currentFocalArea
	if
		area
		and self.horizontalFocusAreaMovementController.lastMagnitude == 0
		and self.verticalFocusAreaMovementController.lastMagnitude == 0
	then
		area.canEscape = true
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

	-- Left to right, then top to bottom, read off the live layout rather than hardcoded, so the
	-- order cannot drift from it. This is both the stick's sideways chain and the shoulders' ring.
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

	-- A view swap rebuilds while already active and the Activate() that follows early-returns, so
	-- the new first area has to be focused here.
	if self.isActive then
		self:ActivateFocusArea(self.focusAreas[1])
	end
end

function Navigator:Activate()
	if self.isActive or not IsInGamepadPreferredMode() then
		return
	end
	self.isActive = true

	-- Exactly one consumer for the whole report: DIRECTIONAL_INPUT hands the stick to every
	-- registered object in turn, and the first to read a non-zero value eats it.
	DIRECTIONAL_INPUT:Activate(self, CMXint.fightReport)
	KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindDescriptor)
	self:ActivateFocusArea(self.focusAreas[1])

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

--- Brings the report and view scenes in line with the current input mode. Only the gamepad group is
--- toggled: adding MOUSE_DRIVEN_UI_WINDOW_NO_COMBAT_OVERLAY in keyboard mode gives the report a
--- "Menu: Exit" prompt it never had. The group is not re-evaluated on its own, so without this a
--- report reopened after a mode switch still wears the strip it opened with.
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

--- Ties navigator activation to scene visibility. Only the view scenes are hooked: the view is
--- pushed over the report scene, so both would fire for one open.
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
	-- The event does not fire on load.
	gamepad.ApplyFragmentGroups()

	isFileInitialized = true
	return true
end
