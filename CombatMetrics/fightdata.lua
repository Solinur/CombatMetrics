-- FightDataManager: fight list storage, current selection, and save/remove via SavedVariables.
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
	-- TODO: Add logic for keeping / removing fights (e.g. prioritise bossfights ... ).
	table.insert(self.fights, fightData)
	local max = math.max(1, CMXint.settings.fights.maxLiveFights)
	while #self.fights > max do
		table.remove(self.fights, 1)
	end
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
	if currentIndex == nil or currentIndex >= self:GetNumFights() then
		return
	end
	self:SelectFightByIndex(currentIndex + 1)
end

function FightDataManager:SelectPreviousFight()
	local currentIndex = self.currentIndex
	if currentIndex == nil or currentIndex <= 1 then
		return
	end
	self:SelectFightByIndex(currentIndex - 1)
end

function FightDataManager:RemoveFight(fightIndex)
	if fightIndex == nil then
		return
	end
	local currentIndex = self.currentIndex
	local needsPostSelect = false

	if currentIndex ~= nil then
		if fightIndex == currentIndex then
			if currentIndex > 1 then
				self:SelectFightByIndex(currentIndex - 1)
			else
				needsPostSelect = true
			end
		elseif fightIndex < currentIndex then
			self.currentIndex = currentIndex - 1
		end
	end

	table.remove(self.fights, fightIndex)

	if needsPostSelect then
		if #self.fights > 0 then
			self:SelectFightByIndex(1)
		else
			self.data = nil
			self.currentIndex = nil
			CMXint.ClearSelections()
			CombatMetricsReport:Update()
		end
	end
end

function FightDataManager:RemoveCurrentFight()
	self:RemoveFight(self.currentIndex)
end

--- Whether SaveFight would do anything: drives both the menu bar's save button state and the
--- gamepad bind's enabled flag and label.
---@return boolean
function FightDataManager:CanSaveFight()
	local fightData = self.data
	local SVHandler = CMXint.SVHandler

	if fightData == nil or SVHandler == nil then
		return false
	end

	-- TODO: Make function of SVHandler to check for already saved fights
	return not util.searchtable(SVHandler.GetFights(), "date", fightData.info.date)
end

function FightDataManager:SaveFight(saveLog)
	-- The already-saved test used to be SVHandler.GetFight(GetNumFights()), which throws before the
	-- first save has ever happened: getNumFights guards a nil sv and returns 0, GetFight does not.
	-- CanSaveFight goes through GetFights instead, and also catches a fight saved earlier in the
	-- list rather than only the most recent one.
	if not self:CanSaveFight() then
		return
	end

	local SVHandler = CMXint.SVHandler
	local spaceLeft = CMXint.settings.fights.maxSavedFights - SVHandler.GetNumFights()
	assert(spaceLeft > 0, zo_strformat(SI_COMBAT_METRICS_SAVEDFIGHTS_FULL, 1 - spaceLeft))

	-- TODO: Re-enable once CombatMetricsFightData is ported to the v2 fight shape. saveFight ->
	-- reduceUnitIds reads fight.calculated, which a v2 fight does not have, so this throws.
	-- SVHandler.Save(self.data, saveLog or false)
	logger:Warn("Saving is not implemented for v2 fight data yet.")
end

---@param fight Fight
local function OnFightSummary(_, fight)
	CMXint.FightData:AddFight(fight)
end

local isFileInitialized = false
function CMXint.InitializeFightDataHandler()
	if isFileInitialized == true then
		return true
	end
	logger = util.initSublogger("Fights")

	CMXint.FightData = FightDataManager:New()

	LibCombat2:RegisterCallbackType(LIBCOMBAT_EVENT_FIGHTSUMMARY, OnFightSummary, CMX.name)

	isFileInitialized = true
	return true
end
