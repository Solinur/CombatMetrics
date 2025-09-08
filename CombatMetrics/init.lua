-- This file contains the initialziation code 

CombatMetrics = CombatMetrics or {}
local CMX = CombatMetrics

-- Basic values
CMX.name = "CombatMetrics"
CMX.version = 85

CMX.internal = {}
local CMXint = CMX.internal
CMXint.debug = false or GetDisplayName() == "@Solinur"
CMXint.functions = {}
CMXint.data = {}
CMXint.logger = {}
local CMXf = CMXint.functions

-- Logger

if LibDebugLogger then
	CMXint.logger.main = LibDebugLogger.Create(CMX.name)
else
	local internalLogger = {}
	function internalLogger:Debug(...)
		df(...)
	end
	internalLogger.Warn = internalLogger.Debug
	internalLogger.Info = internalLogger.Debug
	internalLogger.Error = internalLogger.Debug
	internalLogger.Verbose = internalLogger.Debug
	CMXint.logger.main = internalLogger
end

function CMXf.initSublogger(name)
	local mainlogger = CMXint.logger.main
	if mainlogger.Create == nil or name == nil or name == "" then return mainlogger end
	if CMXint.logger[name] ~= nil then
		CMXint.logger.main:Warn("Sublogger %s already exists!", name)
		return CMXint.logger[name]
	end

	local sublogger = CMXint.logger.main:Create(name)
	mainlogger:Info("Sublogger %s created", name)
	CMXint.logger[name] = sublogger
	return sublogger
end

local LC = LibCombat
if LC == nil then
	CMXint.logger.main:Error("LibCombat not found!")
	return
end

CMXf.GetFormattedAbilityIcon = LC.GetFormattedAbilityIcon
CMXf.GetFormattedAbilityName = LC.GetFormattedAbilityName

function CMXf.spairs(t, order) -- from https://stackoverflow.com/questions/15706270/sort-a-table-in-lua
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function CMXf.searchtable(t, field, value)
	if value == nil then return false end

	for k, v in pairs(t) do
		if type(v) == "table" and field and v[field] == value then
			return true, k
		elseif v == value then
			return true, k
		end
	end

	return false, nil
end

local svdefaults = {
	["accountwide"] = false,

	["modes"] = {
		["lightmode"] = false,
		["enablePvP"] = "light",
	},

	["autoSelectChatChannel"] = true,

	["fights"] = {
		["maxLiveFights"] = 25,
		["maxSavedFights"] = 50,
		["keepBossFights"] = false,
	},

	["group"] = {
		["enableGroupData"] = true,
		["enableLargeGroupData"] = true,
	},

	["stats"] = {
		["crusherValue"] = 2108,
		["alkoshValue"] = 6000,
		["tremorscaleValue"] = 2640,
		["unitresistance"] = 18200,
	},
	
	
	["notification"] = {
		["version"] = 0,
		["versionSeen"] = 0,
		["enabled"] = true,
		["force"] = false,	-- for dev use
	},
	

	["fightReport"] = {
		["pos_x"] = GuiRoot:GetWidth()/2,
		["pos_y"] = GuiRoot:GetHeight()/2-75,

		["scale"] 				= zo_roundToNearest(1 / GetSetting(SETTING_TYPE_UI, UI_SETTING_CUSTOM_SCALE), 0.1),
		["category"] 			= "damageOut",

		["showDebugIds"] 		= false,
		["useDisplayNames"] 	= false,
		["showPets"] 			= true,

		["abilities"] = {
			["hitCritLayout"] = {
				damageOut = 1,
				damageIn = 1,
				healingOut = 1,
				healingIn = 1,
			},

			["averageLayout"] = {
				damageOut = 1,
				damageIn = 1,
				healingOut = 1,
				healingIn = 1,
			},

			["maxValue"] = {
				damageOut = true,
				damageIn = true,
				healingOut = true,
				healingIn = true,
			},
		},

		["buffs"] = {
			["favourites"] = {},
			["showstacks"] = true,
		},

		["graph"] = {
			["SmoothWindow"] 	= 5,
			["Cursor"]			= true,
			["showGroupBuffs"]	= true,
			["PlotColors"]			= {
				[1]	= "1, 1, 0, 0.66",	-- yellow
				[2]	= "1, 0, 0, 0.66",	-- red
				[3]	= "0, 1, 0, 0.66",	-- green
				[4]	= "0, 0, 1, 0.66",	-- blue
				[5]	= "1, 0, 1, 0.66",	-- violet
				[6]	= "0.4, 1, 0.4, 0.4",	-- Buffs: green
				[7]	= "1, 0.4, 0.9, 0.4",	-- Debuffs: violet
			},
		},

		["showWereWolf"] 		= false,

		-- ["CombatLog"] = {
		-- 	["Filters"] = {
		-- 		[LIBCOMBAT_EVENT_DAMAGE_OUT] 		= true,
		-- 		[LIBCOMBAT_EVENT_DAMAGE_IN] 		= false,
		-- 		[LIBCOMBAT_EVENT_HEAL_OUT] 			= false,
		-- 		[LIBCOMBAT_EVENT_HEAL_IN] 			= false,
		-- 		[LIBCOMBAT_EVENT_EFFECTS_IN] 		= false,
		-- 		[LIBCOMBAT_EVENT_EFFECTS_OUT] 		= false,
		-- 		[LIBCOMBAT_EVENT_GROUPEFFECTS_IN] 	= false,
		-- 		[LIBCOMBAT_EVENT_GROUPEFFECTS_OUT] 	= false,
		-- 		[LIBCOMBAT_EVENT_PLAYERSTATS] 		= false,
		-- 		[LIBCOMBAT_EVENT_RESOURCES] 		= false,
		-- 		[LIBCOMBAT_EVENT_MESSAGES] 			= false,
		-- 	},
		-- },
	},

	["liveReport"] = {
		["pos_x"] = 700,
		["pos_y"] = 500,

		["enabled"] 		= true,
		["locked"] 			= false,
		["layout"]			="Compact",
		["scale"]			= zo_roundToNearest(1 / GetSetting(SETTING_TYPE_UI, UI_SETTING_CUSTOM_SCALE), 0.1),
		["bgalpha"]			= 95,
		["alignmentleft"] 	= false,
		["damageOut"] 		= true,	-- TODO: Capitalize first letter 
		["damageOutSingle"] = false,
		["healOut"] 		= true,
		["damageIn"] 		= true,
		["healIn"] 			= true,
		["time"] 			= true,
		["healOutAbsolute"]	= false,
	},
}

local function loadSV()
	CMXint.settings = ZO_SavedVars:NewAccountWide("CombatMetrics_Save", 6, "Settings", svdefaults)
	if not CMXint.settings.accountwide then CMXint.settings = ZO_SavedVars:NewCharacterIdSettings("CombatMetrics_Save", 6, "Settings", svdefaults) end
end

local function Initialize(eventId, addon)
	if addon ~= CMX.name then return end

	loadSV()

	CMXint.SVHandler = CombatMetricsFightData

	assert(CMXint.InitializeFightDataHandler(), "Initialization of fight data module failed")
	assert(CMXint.InitializeUtils(), "Initialization of utils module failed")
	assert(CMXint.InitializeUI(), "Initialization of ui module failed")
	-- assert(CMXint.InitMenu(svdefaults), "Initialization of settings menu failed")

	EVENT_MANAGER:UnregisterForEvent("CombatMetrics_Initialize", EVENT_ADD_ON_LOADED)
end

EVENT_MANAGER:RegisterForEvent("CombatMetrics_Initialize", EVENT_ADD_ON_LOADED, Initialize)