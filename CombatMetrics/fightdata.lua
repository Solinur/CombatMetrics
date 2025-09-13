local CMX = CombatMetrics
local CMXint = CMX.internal
local util = CMXint.util
local logger
local SVHandler

local FightDataManager = ZO_InitializingObject:Subclass()

function FightDataManager:Initialize()
	if CMXint.fightData then
		logger:Error("Cannot create another FightDataManager when one already exists.")
		return
	end

    self.fights = {}
    self.data = nil
    self.currentIndex = nil
end

function FightDataManager:GetFightData()
    return self.data
end

function FightDataManager:GetNumFights()
    return #self.fights
end

function FightDataManager:AddFight(fightData)
    -- TODO: Add logic for keeping / removing fights.
    table.insert(self.fights, fightData)
    self:SelectMostRecentFight()
end

function FightDataManager:SelectFightByIndex(fightIndex)
    local fightData = self.fights[fightIndex]
    if fightData == nil then
        logger:Warn("Trying to load non-existent fightdata. Index: %d / %d", fightIndex, FightDataManager:GetNumFights())
        return
    end
    self.data = fightData
    self.currentIndex = fightIndex

	CMXint.ClearSelections()
    CombatMetricsReport:Update()
end

function FightDataManager:SelectMostRecentFight()
    local fightIndex = FightDataManager:GetNumFights()
    FightDataManager:SelectFightByIndex(fightIndex)
end

function FightDataManager:SelectNextFight()
    local currentIndex = self.currentIndex
    if currentIndex <= 1 then return end
    FightDataManager:SelectFightByIndex(currentIndex + 1)
end

function FightDataManager:SelectPreviousFight()
    local currentIndex = self.currentIndex
    if currentIndex >= FightDataManager:GetNumFights() then return end
    FightDataManager:SelectFightByIndex(currentIndex - 1)
end

function FightDataManager:RemoveFight(fightIndex)
    local currentIndex = self.currentIndex
    if fightIndex == currentIndex then
        FightDataManager:SelectFightByIndex(currentIndex - 1)
    elseif fightIndex < currentIndex then
        self.currentIndex = currentIndex - 1
    end

    table.remove(self.fights, fightIndex)
end

function FightDataManager:RemoveCurrentFight()
    local currentIndex = self.currentIndex
    FightDataManager:RemoveFight(currentIndex)
end

function FightDataManager:SaveFight(saveLog)
    local saveLog = saveLog or false
    local SVHandler = CMXint.SVHandler
    local numFights = SVHandler.GetNumFights()
    local lastsaved = SVHandler.GetFight(numFights)
    local fightData = self.data

    --TODO: Update timestamp location in data structure
    if lastsaved ~= nil and lastsaved.date == fightData.date then return end -- bail out if fight is already saved

    local spaceLeft = CMXint.settings.maxSavedFights - numFights
    assert(spaceLeft > 0, zo_strformat(SI_COMBAT_METRICS_SAVEDFIGHTS_FULL, 1 - spaceLeft))

    SVHandler.Save(fightData, saveLog)
end

local isFileInitialized = false
function CMXint.InitializeFightDataHandler()
	if isFileInitialized == true then return false end
	logger = util.initSublogger("Fights")

    CMXint.fightData = FightDataManager:New()

    isFileInitialized = true
	return true
end