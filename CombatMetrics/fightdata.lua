local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger

local FightDataManager = ZO_InitializingObject:Subclass()

function FightDataManager:Initialize()
	if CMXint.fights then
		logger:Error("Cannot create another FightDataManager whn one already exists.")
		return
	end

    self.fights = {}
	CMXint.figths = self
end

function FightDataManager:GetFightData(fightIndex)
    return self.fights[fightIndex]
end

function FightDataManager:GetNumFights()
    return #self.fights
end

function FightDataManager:AddFight(fightData)
    -- TODO: Add logic for keeping / removing fights.
    table.insert(self.fights, fightData)
end

function FightDataManager:RemoveFight(fightIndex)
    table.remove(self.fights, fightIndex)
end

local isFileInitialized = false
function CMXint.InitializeFightDataHandler()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("Fights")

    FightDataManager:New()

    isFileInitialized = true
	return true
end