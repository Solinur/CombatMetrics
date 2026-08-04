-- Mocks for the ESO API that ESOLua does not provide. Loads before any code under test.
--
-- Return values only have to be deterministic and testable, not faithful to the game. If a test
-- needs a specific value, override the mock in the test itself rather than making it clever here.

-- In the game client the real API is present and must never be replaced by these mocks.
-- ScriptBuildInfo exists only there; it is the same signal Taneth.IsExternal() uses, checked directly
-- because Taneth is an optional dependency and may not be loaded.
if ScriptBuildInfo then
	return
end

-- ESOLua supplies EVENT_MANAGER, CALLBACK_MANAGER, ZO_Object, GetGameTimeMilliseconds and the esoui
-- library layer, but none of the game's enum constants. Rather than hand-maintain them, merge in the
-- generated globals dump. Only fills gaps, so ESOLua's real objects always win.
-- Override the location with the ESO_LUA_DEFS environment variable.
local DEFAULT_DEFS = "/Documents/ESOdev/Tools/esolua/lua_defs/globals.lua"

local function MergeGeneratedGlobals()
	local home = os.getenv("USERPROFILE") or os.getenv("HOME") or "."
	local path = os.getenv("ESO_LUA_DEFS") or (home .. DEFAULT_DEFS)
	local chunk = loadfile(path)
	if not chunk then
		error(string.format("no globals dump at '%s'; set ESO_LUA_DEFS", path))
	end

	local env = {}
	setfenv(chunk, env)
	assert(pcall(chunk), "failed to execute globals dump")

	for name, value in pairs(env) do
		if _G[name] == nil then
			_G[name] = value
		end
	end
end

MergeGeneratedGlobals()

function GetDisplayName()
	return "@EsoLuaTest"
end

function GetRawUnitName()
	return "EsoLuaTest"
end

function GetAbilityName(abilityId)
	return "Ability" .. abilityId
end

function GetAbilityIcon(abilityId)
	return "icon/ability" .. abilityId .. ".dds"
end

-- ESOLua has no UI layer; init.lua builds its SavedVariables defaults from these at load time.
GuiRoot = {
	GetWidth = function()
		return 1920
	end,
	GetHeight = function()
		return 1080
	end,
}

SLASH_COMMANDS = SLASH_COMMANDS or {}

-- The game returns settings as strings.
function GetSetting()
	return "1"
end

-- Returns mantissa and suffix, which ZO_AbbreviateNumber concatenates. The rounding is not the
-- game's, so tests should assert on the suffix rather than the digits.
local ABBREVIATIONS = {
	{ 1e9, SI_NUMBER_SUFFIX_ONE_BILLION_LOWERCASE, SI_NUMBER_SUFFIX_ONE_BILLION_UPPERCASE },
	{ 1e6, SI_NUMBER_SUFFIX_ONE_MILLION_LOWERCASE, SI_NUMBER_SUFFIX_ONE_MILLION_UPPERCASE },
	{ 1e3, SI_NUMBER_SUFFIX_ONE_THOUSAND_LOWERCASE, SI_NUMBER_SUFFIX_ONE_THOUSAND_UPPERCASE },
}

function AbbreviateNumber(amount, precision, useUppercaseSuffixes)
	for _, abbreviation in ipairs(ABBREVIATIONS) do
		local factor, suffix, uppercaseSuffix = abbreviation[1], abbreviation[2], abbreviation[3]
		if amount >= factor then
			return zo_roundToNearest(amount / factor, zo_pow(10, -(precision or 0))),
				GetString(useUppercaseSuffixes and uppercaseSuffix or suffix)
		end
	end
	return amount, ""
end

EsoStrings = EsoStrings or {}
local nextCustomId = 200000

function ZO_CreateStringId(stringId, stringToAdd)
	_G[stringId] = nextCustomId
	EsoStrings[nextCustomId] = stringToAdd
	nextCustomId = nextCustomId + 1
end

-- ESOLua's own GetString always returns "" and its string table is not writable from Lua, so
-- everything lang/en.lua registers would be invisible.
function GetString(stringId, index)
	if type(stringId) == "string" then
		stringId = _G[stringId .. tostring(index)]
	end
	return EsoStrings[stringId] or ""
end

-- The globals dump has the client's SI_* ids but not their text. English values; other locales differ.
EsoStrings[SI_NUMBER_SUFFIX_ONE_THOUSAND_UPPERCASE] = "K"
EsoStrings[SI_NUMBER_SUFFIX_ONE_THOUSAND_LOWERCASE] = "k"
EsoStrings[SI_NUMBER_SUFFIX_ONE_MILLION_UPPERCASE] = "M"
EsoStrings[SI_NUMBER_SUFFIX_ONE_MILLION_LOWERCASE] = "m"
EsoStrings[SI_NUMBER_SUFFIX_ONE_BILLION_UPPERCASE] = "B"
EsoStrings[SI_NUMBER_SUFFIX_ONE_BILLION_LOWERCASE] = "b"

function SafeAddVersion() end

-- Used by ZO_CachedStrFormat to key its cache. Only has to be stable, not match the game's hash.
function HashString(text)
	local hash = 5381
	for i = 1, #text do
		hash = (hash * 33 + string.byte(text, i)) % 2147483648
	end
	return hash
end

-- Substitutes <<1>> / <<C:1>> placeholders. Ignores the case and gender modifiers the real one applies.
function LocalizeString(formatString, ...)
	local args = { ... }
	local result = string.gsub(tostring(formatString), "<<%a*:?(%d+)>>", function(index)
		return tostring(args[tonumber(index)] or "")
	end)
	return result
end
