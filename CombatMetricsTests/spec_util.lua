-- TODO: Check unit tests in this file (sanity check)
if not Taneth then
	return
end

CMXTest.RequireCombatMetrics("util.lua")

-- In-game CombatMetrics is only an optional dependency, so it may not be there at all.
if not CombatMetrics then
	return
end

local CMXint = CombatMetrics.internal
local util = CMXint.util
local cat = util.MainCategories

CMXint.InitializeUtils()

-- Standalone nothing loads the SavedVariables; in the game client they must be left alone.
CMXint.settings = CMXint.settings or { fightReport = {} }

local function WithCategory(category, fn)
	local previous = CMXint.settings.fightReport.category
	CMXint.settings.fightReport.category = category
	local ok, err = pcall(fn)
	CMXint.settings.fightReport.category = previous
	assert(ok, err)
end

--- Stubs the named LibCombat2 queries with recorders that return their own name, so a dispatcher's
--- return value identifies which one it picked. fn receives the call log.
local function WithStubbedQueries(names, fn)
	local calls = {}
	local originals = {}

	for _, name in ipairs(names) do
		originals[name] = LibCombat2[name]
		LibCombat2[name] = function(...)
			calls[#calls + 1] = { name = name, args = { ... } }
			return name
		end
	end

	local ok, err = pcall(fn, calls)

	for _, name in ipairs(names) do
		LibCombat2[name] = originals[name]
	end

	assert(ok, err)
end

local function QueryNames(routes)
	local names = {}
	for _, name in pairs(routes) do
		names[#names + 1] = name
	end
	return names
end

--- Which query each category reached, shaped like the route table. Assertions stay in the tests:
--- Taneth's assert table is only reachable from inside an it body.
---@param dispatcher function taking (fightData, category, ...)
---@param routes table<string, string> category -> LibCombat2 function name
local function TakenRoutes(dispatcher, routes)
	local taken = {}

	WithStubbedQueries(QueryNames(routes), function()
		for category in pairs(routes) do
			taken[category] = dispatcher({}, category)
		end
	end)

	return taken
end

--- Whether an unknown category returns nil or raises depends on the logger behind it, so only the
--- dispatch is observed.
local function CallsForUnknownCategory(dispatcher, routes)
	local count

	WithStubbedQueries(QueryNames(routes), function(calls)
		pcall(dispatcher, {}, "notACategory")
		count = #calls
	end)

	return count
end

Taneth("CombatMetrics", function()
	describe("MainCategories", function()
		it("names all four categories", function()
			assert.same({
				CMX_CATEGORY_DAMAGE_DONE = "damageDone",
				CMX_CATEGORY_DAMAGE_RECEIVED = "damageReceived",
				CMX_CATEGORY_HEALING_DONE = "healingDone",
				CMX_CATEGORY_HEALING_RECEIVED = "healingReceived",
			}, cat)
		end)

		it("pairs every category with an opposite", function()
			for _, category in pairs(cat) do
				assert.is_not_nil(util.OppositionCategory[category])
			end
		end)

		it("is its own inverse", function()
			for _, category in pairs(cat) do
				local opposite = util.OppositionCategory[category]
				assert.equals(category, util.OppositionCategory[opposite])
			end
		end)

		it("never pairs a category with itself", function()
			for _, category in pairs(cat) do
				assert.equals(true, util.OppositionCategory[category] ~= category)
			end
		end)
	end)

	describe("category predicates", function()
		it("classifies damage done", function()
			WithCategory(cat.CMX_CATEGORY_DAMAGE_DONE, function()
				assert.equals(true, util.IsDamageCategory())
				assert.equals(false, util.IsHealingCategory())
				assert.equals(false, util.IsDefenseCategory())
			end)
		end)

		it("classifies damage received as both damage and defense", function()
			WithCategory(cat.CMX_CATEGORY_DAMAGE_RECEIVED, function()
				assert.equals(true, util.IsDamageCategory())
				assert.equals(false, util.IsHealingCategory())
				assert.equals(true, util.IsDefenseCategory())
			end)
		end)

		it("classifies healing done", function()
			WithCategory(cat.CMX_CATEGORY_HEALING_DONE, function()
				assert.equals(false, util.IsDamageCategory())
				assert.equals(true, util.IsHealingCategory())
				assert.equals(false, util.IsDefenseCategory())
			end)
		end)

		it("classifies healing received", function()
			WithCategory(cat.CMX_CATEGORY_HEALING_RECEIVED, function()
				assert.equals(false, util.IsDamageCategory())
				assert.equals(true, util.IsHealingCategory())
				assert.equals(false, util.IsDefenseCategory())
			end)
		end)

		it("classifies an unset category as nothing", function()
			WithCategory(nil, function()
				assert.equals(false, util.IsDamageCategory())
				assert.equals(false, util.IsHealingCategory())
				assert.equals(false, util.IsDefenseCategory())
			end)
		end)
	end)

	describe("GetCombinedPlayerCategoryData", function()
		local routes = {
			damageDone = "GetPlayerDamageDoneToUnits",
			damageReceived = "GetPlayerDamageReceivedByUnits",
			healingDone = "GetPlayerHealingDoneToUnits",
			healingReceived = "GetPlayerHealingReceivedByUnits",
		}

		it("routes each category to its query", function()
			assert.same(routes, TakenRoutes(util.GetCombinedPlayerCategoryData, routes))
		end)

		it("forwards the fight, units and abilities", function()
			local fight, unitIds, abilityIds = {}, { 1, 2 }, { [3] = true }

			WithStubbedQueries({ routes.damageDone }, function(calls)
				util.GetCombinedPlayerCategoryData(fight, cat.CMX_CATEGORY_DAMAGE_DONE, unitIds, abilityIds)
				assert.same({ fight, unitIds, abilityIds }, calls[1].args)
			end)
		end)

		it("does not dispatch an unknown category", function()
			assert.equals(0, CallsForUnknownCategory(util.GetCombinedPlayerCategoryData, routes))
		end)
	end)

	describe("GetCombinedPlayerCategoryDataByAbility", function()
		local routes = {
			damageDone = "GetPlayerDamageDoneToUnitsByAbility",
			damageReceived = "GetPlayerDamageReceivedByUnitsByAbility",
			healingDone = "GetPlayerHealingDoneToUnitsByAbility",
			healingReceived = "GetPlayerHealingReceivedByUnitsByAbility",
		}

		it("routes each category to its query", function()
			assert.same(routes, TakenRoutes(util.GetCombinedPlayerCategoryDataByAbility, routes))
		end)

		it("forwards the fight and units", function()
			local fight, unitIds = {}, { 1, 2 }

			WithStubbedQueries({ routes.healingDone }, function(calls)
				util.GetCombinedPlayerCategoryDataByAbility(fight, cat.CMX_CATEGORY_HEALING_DONE, unitIds)
				assert.same({ fight, unitIds }, calls[1].args)
			end)
		end)

		it("does not dispatch an unknown category", function()
			assert.equals(0, CallsForUnknownCategory(util.GetCombinedPlayerCategoryDataByAbility, routes))
		end)
	end)

	describe("GetCombinedGroupCategoryData", function()
		local routes = {
			damageDone = "GetDamageDoneToUnits",
			damageReceived = "GetDamageReceivedByUnits",
			healingDone = "GetHealingDoneToUnits",
			healingReceived = "GetHealingReceivedByUnits",
		}

		it("routes each category to its query", function()
			assert.same(routes, TakenRoutes(util.GetCombinedGroupCategoryData, routes))
		end)

		it("passes the fight on its own", function()
			local fight = {}

			WithStubbedQueries({ routes.damageReceived }, function(calls)
				util.GetCombinedGroupCategoryData(fight, cat.CMX_CATEGORY_DAMAGE_RECEIVED)
				assert.same({ fight }, calls[1].args)
			end)
		end)

		it("does not dispatch an unknown category", function()
			assert.equals(0, CallsForUnknownCategory(util.GetCombinedGroupCategoryData, routes))
		end)
	end)

	describe("GetUnitCategoryData", function()
		local routes = {
			damageDone = "GetUnitDamageDone",
			damageReceived = "GetUnitDamageReceived",
			healingDone = "GetUnitHealingDone",
			healingReceived = "GetUnitHealingReceived",
		}

		it("routes each category to its query", function()
			assert.same(routes, TakenRoutes(util.GetUnitCategoryData, routes))
		end)

		it("forwards the fight and the unit", function()
			local fight = {}

			WithStubbedQueries({ routes.healingReceived }, function(calls)
				util.GetUnitCategoryData(fight, cat.CMX_CATEGORY_HEALING_RECEIVED, 42)
				assert.same({ fight, 42 }, calls[1].args)
			end)
		end)

		it("does not dispatch an unknown category", function()
			assert.equals(0, CallsForUnknownCategory(util.GetUnitCategoryData, routes))
		end)
	end)

	describe("SafeDivide", function()
		it("divides", function()
			assert.equals(2.5, util.SafeDivide(5, 2))
		end)

		it("returns the numerator when the divisor is zero", function()
			assert.equals(5, util.SafeDivide(5, 0))
		end)

		it("returns zero for 0 / 0", function()
			assert.equals(0, util.SafeDivide(0, 0))
		end)

		it("divides by a negative", function()
			assert.equals(-2.5, util.SafeDivide(5, -2))
		end)
	end)

	describe("GetShortFormattedNumber", function()
		local function Suffix(number)
			return string.match(tostring(util.GetShortFormattedNumber(number)), "%a*$")
		end

		it("returns a zero string for nil", function()
			assert.equals("0", util.GetShortFormattedNumber(nil))
		end)

		it("returns a zero string for zero", function()
			assert.equals("0", util.GetShortFormattedNumber(0))
		end)

		it("leaves numbers below the abbreviation threshold alone", function()
			assert.equals(999, util.GetShortFormattedNumber(999))
			assert.equals("", Suffix(999))
		end)

		it("abbreviates thousands in lowercase", function()
			assert.equals("k", Suffix(1234))
			assert.equals("k", Suffix(12345))
		end)

		it("abbreviates millions and billions in uppercase", function()
			assert.equals("M", Suffix(1234567))
			assert.equals("B", Suffix(1500000000))
		end)

		it("picks the suffix case from the rounded value", function()
			assert.equals("M", Suffix(999999))
		end)

		it("does not abbreviate negatives", function()
			assert.equals(-1230000, util.GetShortFormattedNumber(-1234567))
		end)
	end)
end)
