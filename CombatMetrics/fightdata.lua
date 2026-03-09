---@class CMX
local CMX = CombatMetrics
---@class CMXint
local CMXint = CMX.internal
---@class CMXutil
local util = CMXint.util
---@type Logger
local logger
local SVHandler

---@class FightDataManager
---@field data Fight?
---@field currentIndex number?
---@field New fun(): FightDataManager
local FightDataManager = ZO_InitializingObject:Subclass()

function FightDataManager:Initialize()
	if CMXint.FightData then
		logger:Error("Cannot create another FightDataManager when one already exists.")
		return
	end

	---@type Fight[]
	self.fights = {}
	self.data = nil
	self.currentIndex = nil
end

function FightDataManager:GetCurrentFight()
	return self.data
end

function FightDataManager:GetNumFights()
	return #self.fights
end

---@param fightData Fight
function FightDataManager:AddFight(fightData)
	-- TODO: Add logic for keeping / removing fights.
	table.insert(self.fights, fightData)
	self:SelectMostRecentFight()
end

---@param fightIndex integer
function FightDataManager:SelectFightByIndex(fightIndex)
	local fightData = self.fights[fightIndex]
	if fightData == nil then
		logger:Warn("Trying to load non-existent fightdata. Index: %d / %d", fightIndex, self:GetNumFights())
		return
	end
	self.data = fightData
	self.currentIndex = fightIndex

	CMXint.ClearSelections()
	CombatMetricsReport:Update()
end

function FightDataManager:SelectMostRecentFight()
	local fightIndex = self:GetNumFights()
	self:SelectFightByIndex(fightIndex)
end

function FightDataManager:SelectNextFight()
	local currentIndex = self.currentIndex
	if currentIndex >= self:GetNumFights() then
		return
	end
	self:SelectFightByIndex(currentIndex + 1)
end

function FightDataManager:SelectPreviousFight()
	local currentIndex = self.currentIndex
	if currentIndex <= 1 then
		return
	end
	self:SelectFightByIndex(currentIndex - 1)
end

function FightDataManager:RemoveFight(fightIndex)
	local currentIndex = self.currentIndex
	if fightIndex == currentIndex then
		self:SelectFightByIndex(currentIndex - 1)
	elseif fightIndex < currentIndex then
		self.currentIndex = currentIndex - 1
	end

	table.remove(self.fights, fightIndex)
end

function FightDataManager:RemoveCurrentFight()
	self:RemoveFight(self.currentIndex)
end

function FightDataManager:SaveFight(saveLog)
	local fightData = self.data

	if fightData == nil then
		return
	end

	local saveLog = saveLog or false
	local SVHandler = CMXint.SVHandler
	local numFights = SVHandler.GetNumFights()
	local lastsaved = SVHandler.GetFight(numFights)

	--TODO: Update timestamp location in data structure
	if lastsaved ~= nil and lastsaved.date == fightData.info.date then
		return
	end -- bail out if fight is already saved

	local spaceLeft = CMXint.settings.fights.maxSavedFights - numFights
	assert(spaceLeft > 0, zo_strformat(SI_COMBAT_METRICS_SAVEDFIGHTS_FULL, 1 - spaceLeft))

	SVHandler.Save(fightData, saveLog)
end

---@param fight Fight
local function OnFightSummary(_, fight)
	CMXint.FightData:AddFight(fight)
end

local isFileInitialized = false
function CMXint.InitializeFightDataHandler()
	if isFileInitialized == true then
		return false
	end
	logger = util.initSublogger("Fights")

	CMXint.FightData = FightDataManager:New()

	LibCombat2:RegisterCallbackType(LIBCOMBAT_EVENT_FIGHTSUMMARY, OnFightSummary, CMX.name)

	isFileInitialized = true
	return true
end
