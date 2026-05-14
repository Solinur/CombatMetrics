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

local function iterRange(scrollData, anchorId, clickedId)
	local iStart, iEnd
	for i = 1, #scrollData do
		local entryId = scrollData[i].data.id
		if entryId == anchorId then
			iStart = i
		end
		if entryId == clickedId then
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

---@class SelectionsObject: ZO_InitializingObject
---@field New fun(self: SelectionsObject): SelectionsObject
---@field sortFilterList SortFilterList
---@field selectedItems table<any, true>
---@field anchor any
---@field active boolean
local SelectionsObject = ZO_InitializingObject:Subclass()

function SelectionsObject:Initialize()
	self.selectedItems = {}
	self.anchor = nil
	self.active = false
end

function SelectionsObject:SelectItem(id)
	self.selectedItems[id] = true
	self.anchor = id
end

function SelectionsObject:IsSelected(id)
	return self.selectedItems[id] == true
end

function SelectionsObject:Count()
	local n = 0
	for _ in pairs(self.selectedItems) do
		n = n + 1
	end
	return n
end

function SelectionsObject:Count2()
	return NonContiguousCount(self.selectedItems)
end

function SelectionsObject:GetAll()
	local result = {}
	for id in pairs(self.selectedItems) do
		result[#result + 1] = id
	end
	return result
end

function SelectionsObject:Clear()
	ZO_ClearTable(self.selectedItems)
	self.anchor = nil
	self.active = false
	if self.sortFilterList then
		self.sortFilterList:RefreshVisible()
	end
end

function SelectionsObject:HandleClick(data, button, upInside, ctrl, shift)
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

	if not ctrl and not shift then
		if self.selectedItems[id] and self:Count() == 1 then
			return self:Clear()
		else
			self:SelectItem(id)
		end
	elseif ctrl and not shift then
		if self.selectedItems[id] then
			self.selectedItems[id] = nil
			self.anchor = nil
		else
			self:SelectItem(id)
		end
	else -- shift or ctrl+shift: range selection
		if self.anchor == nil then
			self:SelectItem(id)
		else
			if not ctrl then
				ZO_ClearTable(self.selectedItems)
			end
			local scrollData = ZO_ScrollList_GetDataList(self.sortFilterList.list)
			for entryId in iterRange(scrollData, self.anchor, id) do
				self.selectedItems[entryId] = true
			end
		end
	end

	self.active = next(self.selectedItems) ~= nil
	self.sortFilterList:RefreshVisible()
end

ui.SelectionsObject = SelectionsObject

function CMXint.AddSelection(rowControl, button, upInside, ctrl, _, shift)
	local scrollListCtrl = rowControl.scrollList
	if not scrollListCtrl then
		return
	end

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
function CMXint.InitializeSelectionsHandler()
	if isFileInitialized == true then
		return false
	end
	logger = util.initSublogger("Selections")

	isFileInitialized = true
	return true
end
