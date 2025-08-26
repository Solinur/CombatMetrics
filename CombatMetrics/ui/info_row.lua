local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger
local SVHandler
local InfoRowPanel = CMXint.PanelObject:New("InfoRow", CombatMetrics_Report_InfoRow)

assert(LibCombat, "Could not find LibCombat")
local LC = LibCombat

function InfoRowPanel:Update(fightData)
	logger:Debug("Updating Info Row")

	local datetimecontrol = self:GetNamedChild("DateTime")
	local versioncontrol = self:GetNamedChild("ESOVersion")
	local barcontrol = self:GetNamedChild("Bar")
	local performancecontrol = self:GetNamedChild("Performance")

	local data = fightData or {
		["date"] = GetTimeStamp(),
		["time"] = GetTimeString(),
		["ESOversion"] = GetESOVersionString(),
		["account"] = GetDisplayName()
	}

	local date = data.date
	local account = data.account
	local accountstring = account and string.format("%s, ", account) or ""

	local datestring = type(date) == "number" and GetDateStringFromTimestamp(date) or date
	local timestring = string.format("%s%s, %s", accountstring, datestring, data.time)
	local versionstring = string.format("%s / CMX %s / LC %s", data.ESOversion or "<= 3.2" , CMX.version, tostring(LC.version))

	datetimecontrol:SetText(timestring)
	versioncontrol:SetText(versionstring)

	local hideBar = fightData ~= nil and self:GetParent():GetNamedChild("_FightList"):IsHidden()

	barcontrol:SetHidden(hideBar)

	if not hideBar then
		local maxSavedFights = CMXint.settings.fights.maxSavedFights
		performancecontrol:SetHidden(true)

		local numSaved = SVHandler.GetNumFights()
		local usedSpace = numSaved/maxSavedFights
		barcontrol:SetValue(usedSpace)

		local barlabelcontrol = barcontrol:GetNamedChild("Label")
		barlabelcontrol:SetText(string.format("%s: %d / %d", GetString(SI_COMBAT_METRICS_SAVED_FIGHTS), SVHandler.GetNumFights(), maxSavedFights))

	else	-- show performance stats

		local data = fightData and fightData.calculated
		local performance = data and data.performance
		local count = performance and performance.count or 0

		if count > 0 then

			performancecontrol:SetHidden(false)

			local fpsString = string.format("FPS: %d  |cAAAAAA(%d - %d)|r ", performance.avgAvg, performance.minAvg, performance.maxAvg)
			local pingString = string.format("Ping: %d ms", performance.avgPing)

			local delayString = data.delayAvg and string.format(" - Desync: %d ms", data.delayAvg) or ""

			local fullString = string.format("%s - %s%s", fpsString, pingString, delayString)

			performancecontrol:SetText(fullString)

		end
	end
end

function InfoRowPanel:Release() end

local isFileInitialized = false
function CMXint.InitializeInfoRow()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("InfoRow")

	SVHandler = CMXint.SVHandler

    isFileInitialized = true
	return true
end