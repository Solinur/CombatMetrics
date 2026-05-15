-- SortFilterList base class (ZO_SortFilterList subclass) by some data panels (units, abilities, buffs).
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
---@field panel Panel
---@field selections SelectionsObject
---@field MUST_IMPLEMENT fun()
local SortFilterList = ZO_SortFilterList:Subclass()
SortFilterList.UpdateRow = SortFilterList:MUST_IMPLEMENT()
SortFilterList.RecoverRow = SortFilterList:MUST_IMPLEMENT()
SortFilterList.BuildMasterList = SortFilterList:MUST_IMPLEMENT()

ui.SortFilterList = SortFilterList
ui.DEFAULT_ROWHEIGHT = 20

local registeredLists = {}

local function onRowControlReset(self, pool)
	self.recovered = false

	local controls = self.controls

	for k, control in pairs(controls) do
		if control:GetType() == CT_LABEL or control:GetType() == CT_TEXTURE then
			control:SetColor(1, 1, 1, 1)
		end
		if control.shared then
			control:Release()
		end
		controls[k] = nil
	end

	ZO_ObjectPool_DefaultResetControl(self)
end

---@class RowControl: Control
---@field dataEntry table
---@field controls table
---@field recovered boolean

---@param control Control
---@param rowTemplate string
---@param rowHeight number
function SortFilterList:Initialize(control, rowTemplate, rowHeight) -- TODO: is rowHeight neccessary ?
	ZO_SortFilterList.Initialize(self, control)

	local function UpdateRow(rowControl, data, scrollList)
		if not rowControl.recovered then
			self:RecoverRow(rowControl)
		end
		self:UpdateRow(rowControl, data, scrollList)
		local hl = rowControl:GetNamedChild("HighLight")
		if hl then
			if self.selections:IsSelected(data.id) then
				hl:SetCenterColor(0.25, 0.45, 1.0, 0.45)
			else
				hl:SetCenterColor(1, 1, 1, 0.2)
			end
		end
	end

	---@type Control
	local listControl = self.list
	listControl.sortFilterList = self ---@diagnostic disable-line: inject-field

	self.sortFunction = function(listEntry1, listEntry2)
		return self:CompareItems(listEntry1, listEntry2)
	end
	self.sortKeys = util.tableOfEmpty

	rowHeight = rowHeight or ui.DEFAULT_ROWHEIGHT
	self.rowHeight = rowHeight

	self.selections = ui.SelectionsObject:New(self)

	registeredLists[#registeredLists + 1] = self

	ZO_ScrollList_AddDataType(listControl, 1, rowTemplate, rowHeight, UpdateRow, nil, nil, onRowControlReset)
	ZO_ScrollList_EnableHighlight(listControl, "ZO_ThinListHighlight")
end

function SortFilterList:Clear()
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
	control["key"] = key
	control["initialDirection"] = initialDirection or ZO_SORT_ORDER_DOWN
	control["usesArrow"] = true
	control["highlightTemplate"] = highlightTemplate -- TODO: Find highlight template
	control:SetMouseEnabled(true)
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
