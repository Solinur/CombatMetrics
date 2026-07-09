if not Taneth then return end

CMXTest.RequireLibCombat("utility.lua")

local lf = LibCombat2.internal.functions

Taneth("LibCombat2", function()
	describe("spairs", function()
		it("iterates keys in sorted order", function()
			local seen = {}
			for key in lf.spairs({ c = 3, a = 1, b = 2 }) do
				seen[#seen + 1] = key
			end
			assert.same({ "a", "b", "c" }, seen)
		end)
	end)

	describe("IsCPStarSlotted", function()
		-- Shaped like fights.lua GetCurrentCP: star id at odd indices, spent points at even ones,
		-- maxSlotIndex being the last index of the champion bar slots. Discipline 2 leaves its
		-- second slot empty, which is stored as 0, 0. Passive stars follow the slots.
		local CP = {
			version = 2,
			maxSlotIndex = 4,
			[1] = { 101, 50, 102, 20, 301, 10 },
			[2] = { 201, 50, 0, 0, 302, 10 },
		}

		it("finds a star in the first slot", function()
			assert.equals(true, lf.IsCPStarSlotted(CP, 101))
		end)

		it("finds a star in a later slot", function()
			assert.equals(true, lf.IsCPStarSlotted(CP, 102))
		end)

		it("finds a star in another discipline", function()
			assert.equals(true, lf.IsCPStarSlotted(CP, 201))
		end)

		it("does not treat a spent-points value as a star id", function()
			assert.equals(false, lf.IsCPStarSlotted(CP, 50))
		end)

		it("does not treat a passive star as slotted", function()
			assert.equals(false, lf.IsCPStarSlotted(CP, 301))
		end)

		it("does not match the 0 of an empty slot", function()
			assert.equals(false, lf.IsCPStarSlotted(CP, 0))
		end)

		it("returns false for an unslotted star", function()
			assert.equals(false, lf.IsCPStarSlotted(CP, 999))
		end)
	end)

	describe("CreateQueue", function()
		it("pops in FIFO order", function()
			local queue = lf.CreateQueue()
			queue:Push("a")
			queue:Push("b")
			assert.equals(2, queue:Size())
			assert.equals("a", queue:Pop())
			assert.equals("b", queue:Pop())
			assert.equals(0, queue:Size())
		end)
	end)
end)
