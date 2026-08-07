-- SortFilterList base class (ZO_SortFilterList subclass) used by some data panels (units, abilities, buffs).
---@class CMX
local CMX = CombatMetrics
---@class CMXint
local CMXint = CMX.internal
---@class CMXutil
local util = CMXint.util
---@class CMXui
local ui = CMXint.ui

---@type Logger
local logger
local registeredLists = {}

local ANIMATE_INSTANTLY = true

-- https://github.com/esoui/esoui/blob/live/esoui/libraries/zo_templates/scrolltemplates.lua#L713
-- https://github.com/esoui/esoui/blob/live/esoui/ingame/contacts/keyboard/friendslist_keyboard.lua
-- https://github.com/esoui/esoui/blob/live/esoui/ingame/contacts/keyboard/friendslist_keyboard.xml#L99
-- https://github.com/esoui/esoui/blob/live/esoui/libraries/zo_sortheadergroup/zo_sortheadergroup.lua
-- https://github.com/esoui/esoui/blob/live/esoui/libraries/zo_sortfilterlist/zo_sortfilterlist.lua

local empty = {}
empty._DESCRIPTION_ = "WRITE_PROTECTED"
setmetatable(empty, {
	__newindex = function()
		error("This table cannot be written!")
	end,
})

local tableOfEmpty = {}
tableOfEmpty._DESCRIPTION_ = "ALWAYS_RETURN_EMPTY"
setmetatable(tableOfEmpty, {
	__index = function(table, key)
		return empty
	end,

	__newindex = function()
		error("This table cannot be written!")
	end,
})

---Custom variant of ZO_SortFilterList
---@class SortFilterList: ZO_SortFilterList
---@field New fun(self:SortFilterList, control: Control, rowTemplate: string, rowHeight: number?): SortFilterList
---@field panel Panel
---@field selections SelectionHandler
---@field MUST_IMPLEMENT fun()
local SortFilterList = ZO_SortFilterList:Subclass()
SortFilterList.UpdateRow = SortFilterList:MUST_IMPLEMENT()
SortFilterList.RecoverRow = SortFilterList:MUST_IMPLEMENT()
SortFilterList.BuildMasterList = SortFilterList:MUST_IMPLEMENT()

ui.SortFilterList = SortFilterList
ui.DEFAULT_ROWHEIGHT = 20

-- A row owns the shared controls it acquires (via ui.sharedControls:Acquire(rowControl, ...)) for
-- its entire lifetime: nothing else tracks or releases them, so this must run whenever the row is
-- rebuilt or handed back to its object pool. ReleaseAll only gives back what the row still owns,
-- so a second call (e.g. after SortFilterList:Clear's deferred-commit fallback) is a safe no-op.
local function ReleaseRowControls(rowControl)
	ui.sharedControls:ReleaseAll(rowControl)
	rowControl.controls = nil
end

local function onRowControlReset(self, pool)
	self.recovered = false
	ReleaseRowControls(self)
	ZO_ObjectPool_DefaultResetControl(self)
end

---@class RowControl: Control
---@field dataEntry table
---@field controls table
---@field panel Panel
---@field recovered boolean

---@param control Control
---@param rowTemplate string
---@param rowHeight number
function SortFilterList:Initialize(control, rowTemplate, rowHeight) -- TODO: is rowHeight neccessary ?
	ZO_SortFilterList.Initialize(self, control)

	local function UpdateRow(rowControl, data, scrollList)
		rowControl:SetHeight(scrollList.dataTypes[1].height)
		if not rowControl.recovered then
			rowControl.panel = self.panel
			self:RecoverRow(rowControl)
		end
		self:UpdateRow(rowControl, data, scrollList)
		local hl = rowControl:GetNamedChild("HighLight")
		if hl then
			hl:SetHidden(not self.selections:IsSelected(data.id))
		end
	end

	---@type Control
	local listControl = self.list
	listControl.sortFilterList = self ---@diagnostic disable-line: inject-field

	self.sortFunction = function(listEntry1, listEntry2)
		return self:CompareItems(listEntry1, listEntry2)
	end
	self.sortKeys = tableOfEmpty

	rowHeight = rowHeight or ui.DEFAULT_ROWHEIGHT
	self.rowHeight = rowHeight

	self.selections = ui.SelectionHandler:New(self)

	registeredLists[#registeredLists + 1] = self

	ZO_ScrollList_AddDataType(listControl, 1, rowTemplate, rowHeight, UpdateRow, nil, nil, onRowControlReset)
	ZO_ScrollList_EnableHighlight(listControl, "CombatMetrics_RowCursor")
	ZO_ScrollList_EnableSelection(listControl, "CombatMetrics_RowCursor", function(_, selectedData)
		self:OnCursorChanged(selectedData)
	end)

	ZO_ScrollList_SetEqualityFunction(listControl, 1, function(data1, data2)
		return self:AreDataEqual(data1, data2)
	end)
end

--- Whether two row data tables describe the same row across a rebuild. Panels can override this.
---@param data1 table
---@param data2 table
---@return boolean
function SortFilterList:AreDataEqual(data1, data2)
	return data1.id ~= nil and data1.id == data2.id
end

---@param selectedData table?
function SortFilterList:OnCursorChanged(selectedData)
	if selectedData ~= nil then
		self.lastCursorData = selectedData
	end

	local area = self.panel and self.panel.focusArea
	if area then
		area:OnCursorChanged(selectedData)
	end
end

function SortFilterList:RestoreCursor()
	if not self:HasEntries() then
		return
	end

	local reference = self.lastCursorData
	if reference ~= nil then
		for _, entry in ipairs(ZO_ScrollList_GetDataList(self.list)) do
			if self:AreDataEqual(entry.data, reference) then
				return ZO_ScrollList_SelectDataAndScrollIntoView(self.list, entry.data, nil, ANIMATE_INSTANTLY)
			end
		end
	end

	local SCROLL_INTO_VIEW = true
	ZO_ScrollList_AutoSelectData(self.list, ANIMATE_INSTANTLY, SCROLL_INTO_VIEW)
end

function SortFilterList:CommitScrollList()
	ZO_SortFilterList.CommitScrollList(self)

	local area = self.panel and self.panel.focusArea
	if area == nil or not area:IsFocused() then
		return
	end

	if self:HasEntries() then
		if ZO_ScrollList_GetSelectedData(self.list) == nil then
			self:RestoreCursor()
		end
	else
		ui.gamepad.navigator:CycleArea(1)
	end
end

function SortFilterList:MovePrevious()
	if ZO_ScrollList_AtTopOfList(self.list) then
		return
	end

	PlaySound(SOUNDS.GAMEPAD_MENU_UP)
	ZO_ScrollList_SelectPreviousData(self.list)
end

function SortFilterList:MoveNext()
	if ZO_ScrollList_AtBottomOfList(self.list) then
		return
	end

	PlaySound(SOUNDS.GAMEPAD_MENU_DOWN)
	ZO_ScrollList_SelectNextData(self.list)
end

function SortFilterList:Clear()
	local listControl = self.list
	ZO_ScrollList_Clear(listControl)
	ZO_ScrollList_Commit(listControl)

	for _, rowControl in ipairs(listControl.activeControls) do
		rowControl.recovered = false
		ReleaseRowControls(rowControl)
	end

	if self.selections then
		self.selections:Clear()
	end
end


---@diagnostic disable: lowercase-global, unknown-symbol, exp-in-action, miss-symbol
---@class DataEntryStruct
---@field typeId number;
---@field categoryId number;
---@field data table;
---@diagnostic disable-next-line: undefined-global
hstructure DataEntryStruct
	---@diagnostic disable-next-line: undefined-global
	typeId: number;
	---@diagnostic disable-next-line: undefined-global
	categoryId: number;
	---@diagnostic disable-next-line: undefined-global
	data: table;
end
---@diagnostic enable: lowercase-global, unknown-symbol, exp-in-action, miss-symbol

---@param typeId integer
---@param categoryId integer
---@param data table
---@return DataEntryStruct
function SortFilterList:CreateDataEntry(typeId, categoryId, data)
	---@type DataEntryStruct
	---@diagnostic disable-next-line: undefined-global
	local entry = hmake DataEntryStruct
	{
		typeId = typeId,
		categoryId = categoryId,
		data = data,
	}
	data.dataEntry = entry
	return entry
end

function SortFilterList:CompareItems(listEntry1, listEntry2)
	return ZO_TableOrderingFunction(
		listEntry1.data,
		listEntry2.data,
		self.currentSortKey,
		self.sortKeys,
		self.currentSortOrder
	)
end

function SortFilterList:UpdateRowHeight()
	local scaledRowHeight = (2 + self.rowHeight) * CMXint.settings.fightReport.scale
	local listControl = self.list
	if listControl.uniformControlHeight == scaledRowHeight then
		return
	end

	ZO_ScrollList_Clear(listControl)
	ZO_ScrollList_Commit(listControl)

	listControl.uniformControlHeight = scaledRowHeight

	for typeId, dataType in pairs(listControl.dataTypes) do
		dataType.height = scaledRowHeight
	end
end

function SortFilterList:GetRawHeight()
	return self.rowHeight
end

function SortFilterList:SortScrollList(...)
	if self.currentSortKey ~= nil and self.currentSortOrder ~= nil then
		local scrollData = ZO_ScrollList_GetDataList(self.list)
		table.sort(scrollData, self.sortFunction)
	end

	self:RefreshVisible()
end

---@param control Control
---@param key string
---@param initialDirection boolean
---@param highlightTemplate string
function CMX_SortHeader_Initialize(control, key, initialDirection, highlightTemplate)
	control["key"] = key
	control["initialDirection"] = initialDirection or ZO_SORT_ORDER_DOWN
	control["usesArrow"] = true
	control["highlightTemplate"] = highlightTemplate -- TODO: Find highlight template
	control:SetMouseEnabled(true)
end

--- TODO: with the handlers wired this still does not draw in game, though the same template does
--- draw as the gamepad cursor via EnableSelection. Deferred as PC-only polish; see docs §0.3.
---@param rowControl RowControl
local function UpdateRowHoverHighlight(rowControl, enter)
	if IsInGamepadPreferredMode() then
		return
	end

	local scrollListCtrl = rowControl:GetParent():GetParent()
	if enter then
		ZO_ScrollList_MouseEnter(scrollListCtrl, rowControl)
	else
		ZO_ScrollList_MouseExit(scrollListCtrl, rowControl)
	end
end

---@param rowControl RowControl
function CMXint.Row_OnMouseEnter(rowControl)
	UpdateRowHoverHighlight(rowControl, true)
end

---@param rowControl RowControl
function CMXint.Row_OnMouseExit(rowControl)
	UpdateRowHoverHighlight(rowControl, false)
end

function CMXint.IsSelectionActive()
	for _, list in ipairs(registeredLists) do
		if list.selections.active then
			return true
		end
	end
	return false
end

function CMXint.ClearSelections()
	for _, list in ipairs(registeredLists) do
		if list.selections.active then
			list.selections:Clear()
		end
	end
end


local function iterRange(scrollData, anchorId, clickedId)
	local iStart, iEnd
	for i = 1, #scrollData do
		local entryId = scrollData[i].data.id
		if not iStart and entryId == anchorId then
			iStart = i
		end
		if not iEnd and entryId == clickedId then
			iEnd = i
		end
		if iStart and iEnd then
			break
		end
	end
	if not iStart or not iEnd then
		return function() end
	end
	if iStart > iEnd then
		iStart, iEnd = iEnd, iStart
	end
	local i = iStart - 1
	return function()
		i = i + 1
		while i <= iEnd and scrollData[i].data.id == nil do
			i = i + 1
		end
		if i <= iEnd then
			return scrollData[i].data.id
		end
	end
end

---@class SelectionHandler: ZO_InitializingObject
---@field New fun(self: SelectionHandler, sortFilterList: SortFilterList): SelectionHandler
---@field sortFilterList SortFilterList
---@field selectedItems table<any, true>
---@field anchor any
---@field active boolean
local SelectionHandler = ZO_InitializingObject:Subclass()

function SelectionHandler:Initialize(sortFilterList)
	self.sortFilterList = sortFilterList
	self.selectedItems = {}
	self.anchor = nil
	self.active = false
end

function SelectionHandler:IsSelected(id)
	return self.selectedItems[id] == true
end

function SelectionHandler:OnChanged()
	local wasActive = self.active
	self.active = next(self.selectedItems) ~= nil

	if self.sortFilterList then
		self.sortFilterList:RefreshVisible()
	end

	if self.active ~= wasActive then
		ui.gamepad.navigator:UpdateKeybinds()
	end
end

---@param id any
---@param state boolean
function SelectionHandler:SetSelected(id, state)
	if id == nil then
		return
	end

	self.selectedItems[id] = state or nil
	self.anchor = state and id or nil
	self:OnChanged()
end

---@param id any
---@return boolean newState
function SelectionHandler:Toggle(id)
	local state = not self:IsSelected(id)
	self:SetSelected(id, state)
	return state
end

---@param id any
function SelectionHandler:SelectOnly(id)
	if id == nil then
		return
	end

	ZO_ClearTable(self.selectedItems)
	self.selectedItems[id] = true
	self.anchor = id
	self:OnChanged()
end

---@param id any
---@param keepExisting boolean?
function SelectionHandler:SelectRange(id, keepExisting)
	if id == nil then
		return
	end

	if self.anchor == nil then
		return self:SetSelected(id, true)
	end

	if not keepExisting then
		ZO_ClearTable(self.selectedItems)
	end

	local scrollData = ZO_ScrollList_GetDataList(self.sortFilterList.list)
	for entryId in iterRange(scrollData, self.anchor, id) do
		self.selectedItems[entryId] = true
	end

	self:OnChanged()
end

function SelectionHandler:Count()
	return NonContiguousCount(self.selectedItems)
end

function SelectionHandler:GetAll()
	local result = {}
	for id in pairs(self.selectedItems) do
		result[#result + 1] = id
	end
	return result
end

function SelectionHandler:Clear()
	ZO_ClearTable(self.selectedItems)
	self.anchor = nil
	self:OnChanged()

	if CMXint.fightReport then
		CMXint.fightReport:RequestUpdate()
	end
end

function SelectionHandler:HandleClick(data, button, upInside, ctrl, shift)
	if not upInside then
		return
	end

	local id = data.id
	if id == nil then
		return
	end

	if button == MOUSE_BUTTON_INDEX_MIDDLE then
		return self:Clear()
	end

	if button ~= MOUSE_BUTTON_INDEX_LEFT then
		return
	end

	if shift then
		self:SelectRange(id, ctrl)
	elseif ctrl then
		self:Toggle(id)
	elseif self:IsSelected(id) and self:Count() == 1 then
		self:SetSelected(id, false)
	else
		self:SelectOnly(id)
	end

	if CMXint.fightReport then
		CMXint.fightReport:RequestUpdate()
	end
end

ui.SelectionHandler = SelectionHandler

function CMXint.AddSelection(rowControl, button, upInside, ctrl, _, shift)
	local scrollListCtrl = rowControl:GetParent():GetParent()
	local sortFilterList = scrollListCtrl.sortFilterList
	if not sortFilterList then
		logger:Warn("AddSelection: no sortFilterList on scroll control '%s'", scrollListCtrl:GetName())
		return
	end
	if not sortFilterList.selections then
		logger:Warn("AddSelection: sortFilterList has no selections object")
		return
	end
	local dataEntry = rowControl.dataEntry
	if not dataEntry then
		logger:Warn("AddSelection: row control '%s' has no dataEntry", rowControl:GetName())
		return
	end
	sortFilterList.selections:HandleClick(dataEntry.data, button, upInside, ctrl, shift)
end

local isFileInitialized = false
function CMXint.InitializeScrollListHandler()
	if isFileInitialized == true then
		return true
	end
	logger = util.initSublogger("ScrollLists")

	isFileInitialized = true
	return true
end
