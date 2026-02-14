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

-- https://github.com/esoui/esoui/blob/live/esoui/libraries/zo_templates/scrolltemplates.lua#L713
-- https://github.com/esoui/esoui/blob/live/esoui/ingame/contacts/keyboard/friendslist_keyboard.lua
-- https://github.com/esoui/esoui/blob/live/esoui/ingame/contacts/keyboard/friendslist_keyboard.xml#L99
-- https://github.com/esoui/esoui/blob/live/esoui/libraries/zo_sortheadergroup/zo_sortheadergroup.lua
-- https://github.com/esoui/esoui/blob/live/esoui/libraries/zo_sortfilterlist/zo_sortfilterlist.lua

---Custom variant of ZO_SortFilterList
---@class SortFilterList: ZO_SortFilterList
---@field New fun(self:SortFilterList, control: Control, rowTemplate: string, rowHeight: number?): SortFilterList
local SortFilterList = ZO_SortFilterList:Subclass()
SortFilterList.UpdateRow = SortFilterList:MUST_IMPLEMENT()
SortFilterList.BuildMasterList = SortFilterList:MUST_IMPLEMENT()

ui.SortFilterList = SortFilterList
ui.DEFAULT_ROWHEIGHT = 20

local function onRowControlReset(self, pool)
	self.recovered = false

	local controls = self.controls

	for k, control in pairs(controls) do
		if control.shared then
			control:Release()
		end
		controls[k] = nil
	end

	ZO_ObjectPool_DefaultResetControl(self)
end

---@param control Control
---@param rowTemplate string
---@param rowHeight number
function SortFilterList:Initialize(control, rowTemplate, rowHeight) -- TODO: is rowHeight neccessary ?
	ZO_SortFilterList.Initialize(self, control)

	local function UpdateRow(...)
		self:UpdateRow(...)
	end

	---@type Control
	local listControl = self.list
	self.sortFunction = function(listEntry1, listEntry2)
		return self:CompareItems(listEntry1, listEntry2)
	end
	self.sortKeys = util.tableOfEmpty

	rowHeight = rowHeight or ui.DEFAULT_ROWHEIGHT
	self.rowHeight = rowHeight

	ZO_ScrollList_AddDataType(listControl, 1, rowTemplate, rowHeight, UpdateRow, nil, nil, onRowControlReset)
	ZO_ScrollList_EnableHighlight(listControl, "ZO_ThinListHighlight")
end

function SortFilterList:Release()
	local listControl = self.list
	ZO_ScrollList_Clear(listControl)
	ZO_ScrollList_Commit(listControl)
end

function SortFilterList:CreateDataEntry(...)
	return util.CreateDataEntry(...)
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

function SortFilterList:GetHeight()
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
	control.key = key
	control.initialDirection = initialDirection or ZO_SORT_ORDER_DOWN
	control.usesArrow = true
	control.highlightTemplate = highlightTemplate -- TODO: Find highlight template
	control:SetMouseEnabled(true)
end
