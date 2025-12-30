local CMX = CombatMetrics
local CMXint = CMX.internal
local util = CMXint.util
local ui = CMXint.ui
local logger
local SVHandler
local LC = CMXint.LibCombat2


function CMXint.InitializeInfoRowPanel(control)
	local InfoRowPanel = CMX.internal.PanelObject:New(control, "infoRow")

	
	function InfoRowPanel:Update(fightData)
		logger:Debug("Updating Info Row")

		local datetimecontrol = control:GetNamedChild("DateTime")
		local versioncontrol = control:GetNamedChild("ESOVersion")
		local barcontrol = control:GetNamedChild("Bar")
		local performancecontrol = control:GetNamedChild("Performance")

		local data = fightData and fightData.info or {
			["date"] = GetTimeStamp(),
			["time"] = GetTimeString(),
			["ESOversion"] = GetESOVersionString(),
			["account"] = GetDisplayName()
		}

		local date = data.date
		local account = data.account
		local name = fightData and fightData.charData.name or ZO_CachedStrFormat(SI_UNIT_NAME,  GetRawUnitName("player"))
		local accountstring = account and string.format("%s%s, ", name, account) or ""

		local datestring = type(date) == "number" and GetDateStringFromTimestamp(date) or date
		local timestring = string.format("%s%s, %s", accountstring, datestring, data.time)
		local versionstring = string.format("%s / CMX %s / LC %s", data.ESOversion or "<= 3.2" , CMX.version, tostring(LC.version))

		datetimecontrol:SetText(timestring)
		versioncontrol:SetText(versionstring)

		local hideBar = fightData ~= nil and control:GetParent():GetNamedChild("_FightList"):IsHidden()

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
end

local isFileInitialized = false
function CMXint.InitializeInfoRow()
	if isFileInitialized == true then return false end
	logger = util.initSublogger("InfoRow")
	
	SVHandler = CMXint.SVHandler

	isFileInitialized = true
	return true
end