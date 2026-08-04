-- Loads only the LibCombat2 files a suite needs, instead of the whole addon.
--
-- Standalone (ESOLua) only. In the game client the addon is already fully loaded by the time the
-- suites run, so RequireLibCombat has nothing to do and the `eso` module does not exist at all.

CMXTest = CMXTest or {}

local IN_GAME = ScriptBuildInfo ~= nil

local loaded = {}

--- Loads a single Lua file relative to the AddOns directory.
---
--- Uses eso.LoadLuaFile rather than eso.LoadAddon: LoadAddon swallows per-file errors, so a manifest
--- reports success while every file in it aborted mid-load. LoadLuaFile returns a success flag.
---@param path string
function CMXTest.Require(path)
	if IN_GAME or loaded[path] then
		return
	end
	assert(eso.LoadLuaFile(path, true), "failed to load " .. path)
	loaded[path] = true
end

--- Loads the named LibCombat2 files, plus the init chain they depend on.
---@param ... string file names within LibCombat2, e.g. "utility.lua"
function CMXTest.RequireLibCombat(...)
	if IN_GAME then
		return
	end

	CMXTest.Require("LibCombat2/lang/en.lua")
	CMXTest.Require("LibCombat2/init.lua")
	CMXTest.Require("LibCombat2/constants.lua")
	assert(LibCombat2.internal.InitializeGlobals(), "InitializeGlobals failed")

	for i = 1, select("#", ...) do
		CMXTest.Require("LibCombat2/" .. select(i, ...))
	end
end

--- Loads the named CombatMetrics files. CombatMetrics/init.lua bails out when LibCombat2 is missing
--- and reads the formatting helpers off it at load time, so the library comes first.
---@param ... string file names within CombatMetrics, e.g. "util.lua"
function CMXTest.RequireCombatMetrics(...)
	if IN_GAME then
		return
	end

	CMXTest.RequireLibCombat("utility.lua")
	CMXTest.Require("CombatMetrics/lang/en.lua")
	CMXTest.Require("CombatMetrics/init.lua")

	for i = 1, select("#", ...) do
		CMXTest.Require("CombatMetrics/" .. select(i, ...))
	end
end
