---@diagnostic disable: lowercase-global
---@diagnostic disable: unknown-symbol
---@diagnostic disable: exp-in-action
---@diagnostic disable: miss-symbol

---@class CMX
local CMX = CombatMetrics
---@class CMXint
local CMXint = CMX.internal
---@class CMXutil
local util = CMXint.util
---@type Logger
local logger


---@class DataEntryStruct
---@field typeId number;
---@field categoryId number;
---@field data table;

hstructure DataEntryStruct
	typeId: number;
	categoryId: number;
	data: table;
end

---@param typeId integer
---@param categoryId integer
---@param data table
---@return DataEntryStruct
function util.CreateDataEntry(typeId, categoryId, data)
	---@type DataEntryStruct
	local entry = hmake DataEntryStruct
	{
		typeId = typeId,
		categoryId = categoryId,
		data = data,
	}
	data.dataEntry = entry
	return entry
end

local empty = {}
empty._DESCRIPTION_ = "WRITE_PROTECTED"
setmetatable(empty, {
	__newindex = function() 
		error("This table cannot be written!")
	end
})

local tableOfEmpty = {}
tableOfEmpty._DESCRIPTION_ = "ALWAYS_RETURN_EMPTY"
setmetatable(tableOfEmpty, {
	__index = function(table, key)
		return empty
	end,

	__newindex = function() 
		error("This table cannot be written!")
	end
})

util.tableOfEmpty = tableOfEmpty

local isFileInitialized = false
function CMXint.InitializeStructs()
	if isFileInitialized == true then return false end
	logger = util.initSublogger("Structs")

	isFileInitialized = true
	return true
end