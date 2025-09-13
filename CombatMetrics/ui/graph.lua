local CMX = CombatMetrics
local CMXint = CMX.internal
local util = CMXint.util
local ui = CMXint.ui
local logger
local fightData

local enlargedGraph = false
local maxXYPlots = 5
local maxBarPlots = 8
local EM = GetEventManager()

local GetFormattedAbilityIcon = util.GetFormattedAbilityIcon
local GetFormattedAbilityName = util.GetFormattedAbilityName
local dx = CMXint.dx

local CMX_PLOT_DIMENSION_X = 1
local CMX_PLOT_DIMENSION_Y = 2

local function MapValue(plotWindow, dimension, value, norm)
	local minRange, maxRange

	if norm then
		minRange = 0
		maxRange = 1
	else
		local range = dimension == CMX_PLOT_DIMENSION_X and plotWindow.RangesX or plotWindow.RangesY
		minRange, maxRange = unpack(range)
	end

	local controlSize = dimension == CMX_PLOT_DIMENSION_X and plotWindow:GetWidth() or plotWindow:GetHeight()
	local IsInRange = (value < maxRange) and (value > minRange)
	local offset = controlSize * ((value - minRange)/(maxRange - minRange))

	return offset, IsInRange
end

local function MapValueXY(plotWindow, x, y, normX, normY)
	local XOffset, IsInRangeX = plotWindow:MapValue(CMX_PLOT_DIMENSION_X, x, normX)
	local YOffset, IsInRangeY = plotWindow:MapValue(CMX_PLOT_DIMENSION_Y, y, normY)
	local IsInRange = IsInRangeX and IsInRangeY

	return XOffset, YOffset, IsInRange
end

local function MapUIPos(plotWindow, dimension, value)
	local range = dimension == CMX_PLOT_DIMENSION_X and plotWindow.RangesX or plotWindow.RangesY
	local minRange, maxRange = unpack(range)
	local minCoord = dimension == CMX_PLOT_DIMENSION_X and plotWindow:GetLeft() or plotWindow:GetTop()
	local maxCoord = dimension == CMX_PLOT_DIMENSION_X and plotWindow:GetRight() or plotWindow:GetBottom()
	local IsInRange = (value < maxCoord) and (value > minCoord)
	local relpos = (value - minCoord) / (maxCoord - minCoord)

	if dimension == CMX_PLOT_DIMENSION_Y then relpos = 1 - relpos end -- since coords start at topleft but a plot from bottom left
	local value = relpos * (maxRange - minRange) + minRange
	return value, IsInRange
end

local function DrawLine(plot, coords, id)
	local plotid = plot.id
	local lineControls = plot.lineControls

	if lineControls[id] == nil then
		lineControls[id] = CreateControlFromVirtual("$(parent)Line", plot, "CombatMetrics_PlotLine", id)
	end

	local line = lineControls[id]

	line:SetThickness(dx * 16)
	line:SetColor(unpack(CMXint.settings.fightReport.PlotColors[plotid]))
	line:ClearAnchors()

	local x1, y1, x2, y2, inRange1, inRange2 = unpack(coords)

	local minX = 0
	local minY = 0
	local maxX, maxY = plot:GetDimensions()

	local outOfRange =
		( x1 < minX and x2 < minX ) or
		( x1 > maxX and x2 > maxX ) or
		( y1 < minY and y2 < minY ) or
		( y1 > maxY and y2 > maxY )

	if outOfRange then	-- line is completely out of drawing area
		line:SetHidden(false)
		return
	elseif not (inRange1 and inRange2) then -- line is partially out of drawing area
		local m = (y2 - y1) / (x2 - x1)
		local n = y1 - (m * x1)

		if y1 > maxY then
			x1 = m == 0 and x1 or (maxY - n) / m
			y1 = maxY
		elseif y1 < minY then
			x1 = m == 0 and x1 or (minY - n) / m
			y1 = minY
		end

		if y2 > maxY then
			x2 = m == 0 and x2 or (maxY - n) / m
			y2 = maxY
		elseif y2 < minY then
			x2 = m == 0 and x2 or (minY - n) / m
			y2 = minY
		end

		if x1 < minX then
			x1 = minX
			y1 = m * minX + n
		end

		if x2 > maxX then
			x2 = maxX
			y2 = m * maxX + n
		end
	end

	-- in the end it is still possible that y values are out of range, in this case, the line doesn't touch the window.
	local inRange = y1 >= minY and y1 <= maxY and y2 >= minY and y2 <= maxY and x2 >= minX and x1 <= maxX

	if not inRange then
		line:SetHidden(false)
		return
	end

	local side1 = BOTTOMLEFT
	local side2 = TOPRIGHT

	if y1 > y2 then
		side1 = TOPLEFT
		side2 = BOTTOMRIGHT
	end

	line:SetAnchor(side1, plot, BOTTOMLEFT, x1, -y1)
	line:SetAnchor(side2, plot, BOTTOMLEFT, x2, -y2)
	line:SetHidden(false)
end

local function DrawBar(plot, x1, x2, id)
	local barControls = plot.barControls

	if barControls[id] == nil then
		barControls[id] = CreateControlFromVirtual("$(parent)Bar", plot, "CombatMetrics_PlotBar", id)
	end

	local bar = barControls[id]
	bar:ClearAnchors()

	local minX = 0
	local xoffset = plot.xoffset
	local maxX, _ = plot:GetDimensions()
	maxX = maxX - xoffset

	local outOfRange = ( x2 < minX ) or ( x1 > maxX )
	if outOfRange then	-- bar is completely out of drawing area
		bar:SetHidden(false)
		return
	end

	local left = zo_max(x1, minX) + xoffset
	local right = zo_min(x2, maxX) + xoffset

	local PlotColors = CMXint.settings.fightReport.PlotColors
	local color = plot.effectType == BUFF_EFFECT_TYPE_BUFF and PlotColors[6] or PlotColors[7]

	bar:SetAnchor(TOPLEFT, plot, TOPLEFT, left, 0)
	bar:SetAnchor(BOTTOMRIGHT, plot, BOTTOMLEFT, right, 0)
	bar:SetCenterColor(unpack(color))
	bar:SetHidden(false)
end

local COMBAT_METRICS_YAXIS_LEFT = 1
local COMBAT_METRICS_YAXIS_RIGHT = 2

local function DrawXYPlot(plot)
	local plotWindow = plot:GetParent()
	local XYData = plot.XYData

	if XYData == nil then return end

	local coordinates = {}
	plot.coordinates = coordinates

	for id, line in ipairs(plot.lineControls) do	-- hide previous Plot
		line:SetHidden(true)
	end

	local x0
	local y0
	local inRange0
	local normY = plot.YAxisSide == COMBAT_METRICS_YAXIS_RIGHT

	for i, dataPair in ipairs(XYData) do
		local t, v = unpack(dataPair)
		local x, y, inRange = plotWindow:MapValueXY(t, v, false, normY)
		coordinates[i] = {x, y, inRange}

		if i > 1 then
			local lineCoords = {x0, y0, x, y, inRange0, inRange}
			local id = i - 1
			DrawLine(plot, lineCoords, id)
		end

		x0 = x
		y0 = y
		inRange0 = inRange
	end
end

local function DrawBarPlot(plot)
	local plotWindow = plot:GetParent()
	local bardata = plot.bardata

	if bardata == nil then return end

	for id, bar in ipairs(plot.barControls) do	-- hide previous Plot
		bar:SetHidden(true)
	end

	for id, times in ipairs(bardata) do
		local t1, t2 = unpack(times)
		local x1, inRange1 = plotWindow:MapValue(CMX_PLOT_DIMENSION_X, t1, false)
		local x2, inRange2 = plotWindow:MapValue(CMX_PLOT_DIMENSION_X, t2, false)

		DrawBar(plot, x1, x2, id)
	end

end

local CMX_PLOT_TYPE_XY = 1
local CMX_PLOT_TYPE_BAR = 2

local plotTypeTemplates = {
	[CMX_PLOT_TYPE_XY] = "CombatMetrics_PlotControlXY",
	[CMX_PLOT_TYPE_BAR] = "CombatMetrics_PlotControlBar",
}

local function Smooth(category)
	if fightData == nil then return end

	local calcData = fightData.calculated
	local category = category or CMXint.settings.fightReport.category
	local data = calcData.graph and calcData.graph[category] or nil -- DPS data, one value per second

	if data == nil then return end

	local totaltime = fightData.combattime
	local smoothWindow = CMXint.settings.fightReport.SmoothWindow
	local XYData = {}

	local t2 = zo_ceil(totaltime) - smoothWindow

	for t = 0, t2 do
		local sum = 0

		for i = 0, smoothWindow - 1 do
			sum = sum + (data[t + i] or 0)
		end

		local x = t + smoothWindow / 2
		local y = sum / smoothWindow

		if t == 0 then table.insert(XYData, {0, y}) end
		table.insert(XYData, {x, y})
		if t == t2 then table.insert(XYData, {totaltime, y}) end
	end

	return XYData, COMBAT_METRICS_YAXIS_LEFT, 1
end

local function Total(category)
	if fightData == nil then return end

	local calcData = fightData.calculated
	local category = category or CMXint.settings.fightReport.category
	local data = calcData.graph and calcData.graph[category] or nil -- DPS data, one value per second

	if data == nil then return end

	local totaltime = fightData.combattime
	local XYData = {}
	local t2 = zo_ceil(totaltime)
	local sum = 0
	local t0
	local tmax

	local combatstart = fightData.combatstart or fightData.dpsstart or fightData.hpsstart or 0
	local dpsstart = fightData.dpsstart or combatstart
	local dpsend = fightData.dpsend or (combatstart + 1)
	local hpsstart = fightData.hpsstart or combatstart
	local hpsend = fightData.hpsend or (combatstart + 1)

	if category == "healingOut" or category == "healingIn" then
		t0 = (hpsstart - combatstart) / 1000
		tmax = (hpsend - combatstart) / 1000
	else
		t0 = (dpsstart - combatstart) / 1000
		tmax = (dpsend - combatstart) / 1000
	end

	local startpoint = zo_max(CMXint.settings.fightReport.SmoothWindow / 2, t0)

	for t = 0, t2 do
		sum = sum + (data[t] or 0)

		if t >= startpoint and t <= zo_ceil(tmax) then
			local x = t
			local y = sum / (zo_min(tmax, t) - t0)
			table.insert(XYData, {x, y})
		end
	end

	return XYData, COMBAT_METRICS_YAXIS_LEFT, 1
end

local function Absolute(category)
	if fightData == nil then return end

	local calcData = fightData.calculated
	local category = category or CMXint.settings.fightReport.category
	local data = calcData.graph and calcData.graph[category] or nil -- DPS data, one value per second

	if data == nil then return end

	local totaltime = fightData.combattime
	local XYData = {}
	local t2 = zo_ceil(totaltime)
	local sum = 0

	for t = 0, t2 do
		sum = sum + (data[t] or 0)
		table.insert(XYData, {t, sum})
	end

	for i, xyData in ipairs(XYData) do
		xyData[2] = xyData[2]/sum
	end

	return XYData, COMBAT_METRICS_YAXIS_RIGHT, sum
end

local powerTypeKeyTable = {
	[POWERTYPE_HEALTH] = LIBCOMBAT_STAT_MAXHEALTH,
	[POWERTYPE_MAGICKA] = LIBCOMBAT_STAT_MAXMAGICKA,
	[POWERTYPE_STAMINA] = LIBCOMBAT_STAT_MAXSTAMINA,
}

local oldX, oldY

local function updateXYData(XYData, x, y)
	if #XYData == 0 then
		oldX = -1
		oldY = y
	end

	if x - 1 > oldX and oldY and oldY ~= y then
		table.insert(XYData, {oldX + 1, oldY})
	end

	if x - 2 > oldX and oldY then
		table.insert(XYData, {x - 1, oldY})
	end

	if x > oldX then
		table.insert(XYData, {x, y})
		oldX = x
	end

	oldY = y
end

local function ResourceAbsolute(powerType)
	if powerType == nil or fightData == nil or fightData.log == nil then return end

	local logData = fightData.log
	local combatstart = fightData.combatstart/1000
	local XYData = {}
	local value

	for line, lineData in ipairs(logData) do
		if lineData[1] == LIBCOMBAT_EVENT_RESOURCES and lineData[5] == powerType and lineData[6] then
			local deltatime = zo_floor(lineData[2]/1000 - combatstart)
			value = lineData[6] or 0
			updateXYData(XYData, deltatime, value)
		end
	end

	if value then updateXYData(XYData, fightData.combattime, value) end
	local key = powerTypeKeyTable[powerType]
	local maxValue = powerType == POWERTYPE_ULTIMATE and 500 or fightData.calculated.stats[key].max

	for i, xyData in ipairs(XYData) do
		xyData[2] = xyData[2]/maxValue
	end

	return XYData, COMBAT_METRICS_YAXIS_RIGHT, maxValue
end

local function BossHPAbsolute()
	if fightData == nil or fightData.log == nil then return end

	local logData = fightData.log
	local combatstart = fightData.combatstart/1000
	local XYData = {}
	local x	= -1
	local y
	local maxhp = 0

	for line, lineData in ipairs(logData) do
		if lineData[1] == LIBCOMBAT_EVENT_BOSSHP then
			local deltatime = zo_floor(lineData[2]/1000 - combatstart)
			if deltatime > x then
				x = deltatime
				y = lineData[4]/lineData[5]
				table.insert(XYData, {x, y})
			end
		end
	end

	return XYData, COMBAT_METRICS_YAXIS_RIGHT, maxhp
end

local function PerformancePlot(dataType)
	if fightData == nil or fightData.log == nil then return end

	local logData = fightData.log
	local combatstart = fightData.combatstart/1000
	local XYData = {}
	local x	= -1
	local y
	local event = dataType == 7 and LIBCOMBAT_EVENT_SKILL_TIMINGS or LIBCOMBAT_EVENT_PERFORMANCE	-- skill delay is recorded with another logtype
	local key = dataType == 7 and 6 or dataType

	for line, lineData in ipairs(logData) do
		if lineData[1] == event and lineData[key] then
			local deltatime = lineData[2]/1000 - combatstart
			local isSkill = dataType ~= 7 or (lineData[3]%10) > 2

			if deltatime > x and isSkill then
				x = deltatime
				y = lineData[key]
				table.insert(XYData, {x, y})
			end
		end
	end

	return XYData, COMBAT_METRICS_YAXIS_LEFT, 1
end

local function StatAbsolute(statId)
	if fightData == nil or fightData.log == nil then return end

	local logData = fightData.log
	local combatstart = fightData.combatstart/1000
	local XYData = {}
	local maxvalue = 0
	local value

	for line, lineData in ipairs(logData) do
		if lineData[1] == LIBCOMBAT_EVENT_PLAYERSTATS and lineData[5] == statId then
			value = lineData[4]
			maxvalue = zo_max(value, maxvalue)
			local deltatime = zo_floor(lineData[2]/1000 - combatstart)
			updateXYData(XYData, deltatime, value)
		end
	end

	updateXYData(XYData, fightData.combattime, value)

	for i, xyData in ipairs(XYData) do
		xyData[2] = xyData[2]/maxvalue
	end

	return XYData, COMBAT_METRICS_YAXIS_RIGHT, maxvalue
end

local function AcquireBuffData(buffName)
	if fightData == nil or fightData.log == nil then return end

	local rightpanel = CMXint.settings.fightReport.rightpanel
	local category = CMXint.settings.fightReport.category
	local unitselections = rightpanel == "buffs" and {[fightData.playerid] = 1} or CMXint.selections.unit[category]
	local logData = fightData.log

	if logData == nil then return end

	local combatstart = fightData.combatstart/1000
	local combattime = fightData.combattime
	local timeData = {}
	local first = true
	local lastSlot
	local lastUnit
	local slots = {}
	local showGroupBuffs = CMXint.settings.fightReport.ShowGroupBuffsInPlots

	for line, lineData in ipairs(logData) do
		local result, timems, unitId, abilityId, changeType = unpack(lineData)	-- unpack only runs until it encounters nil
		local effectSlot = lineData[9]											-- so effectSlot has to be taken separately

		local isResult = result == LIBCOMBAT_EVENT_EFFECTS_IN or result == LIBCOMBAT_EVENT_EFFECTS_OUT
		local isGroupResult = showGroupBuffs and (result == LIBCOMBAT_EVENT_GROUPEFFECTS_IN or result == LIBCOMBAT_EVENT_GROUPEFFECTS_OUT)

		if (isResult or isGroupResult) and GetFormattedAbilityName(abilityId) == buffName and ((unitselections and unitselections[unitId]) or (unitselections == nil)) then
			local deltatime = timems/1000 - combatstart

			if changeType == EFFECT_RESULT_GAINED and deltatime < combattime then
				slots[effectSlot] = deltatime
				first = false
				lastSlot = effectSlot
				lastUnit = unitId
			elseif changeType == EFFECT_RESULT_FADED then
				local starttime = first and 0 or slots[effectSlot] or nil

				if starttime and deltatime > starttime and deltatime > 0 then
					local previoustimes = timeData[#timeData]
					local prevend = previoustimes and previoustimes[2] or nil
					local prevunit = previoustimes and previoustimes[3] or nil

					if prevend and (zo_abs(starttime - prevend)) < 0.02 and prevunit == unitId then 		-- to avoid drawing too many controls: if a buff is renewed within 20 ms, consider it continious
						previoustimes[2] = deltatime
					else
						table.insert(timeData, {starttime, deltatime, unitId})
					end
				end

				lastSlot = nil
			end
		end
	end

	if lastSlot then
		local unittime = fightData.calculated.units[lastUnit].endtime
		local endtime = unittime and (unittime/1000 - combatstart) or fightData.combattime

		if slots[lastSlot] < endtime then table.insert(timeData, {slots[lastSlot], endtime}) end
	end

	return timeData
end

local function GetScale(x1, x2)	-- e.g. 34596 and 42693
	local distance = zo_max(x2 - x1, 1)	-- 8097
	local power = zo_pow(10, zo_floor(math.log10(distance/2)))	-- zo_pow(10, zo_floor(3.61) = zo_pow(10, 3) = 1000
	local high = zo_ceil(x2 / power) * power	-- 43000
	local low = zo_floor(x1 / power) * power	-- 34000
	local size = (high - low) / power 	-- 9000 / 1000 = 9
	local cleansize = zo_floor(size)

	local delta = cleansize - size -- 1
	local cleanLow = low - zo_floor(delta / 2) * power 	-- 34000 - zo_floor(0.5) * 1000 = 34000
	local cleanHigh = high + zo_ceil(delta / 2) * power 	-- 34000 - zo_ceil(0.5) * 1000 = 44000

	if cleanLow < 0 then
		cleanHigh = cleanHigh - cleanLow
		cleanLow = 0
	end

	local cleanDist = cleanHigh - cleanLow
	return cleanLow, cleanHigh
end

local function GetTickValues(low, high)
	local tickValues = {low, 0, 0, 0, high}

	for i = 2,4 do
		tickValues[i] = zo_floor(low + (high - low) * (i - 1) / 4)
	end

	return tickValues
end

local function AcquireRange(XYData)
	local minX = 0
	local maxX = 0
	local minY = 0
	local maxY = 0

	for i, coords in ipairs(XYData) do
		local x, y = unpack(coords)

		minX = zo_min(minX, x)
		maxX = zo_max(maxX, x)
		minY = zo_max(minY, y)
		maxY = zo_max(maxY, y)
	end

	return {minX, maxX, minY, maxY}
end

local function GetRequiredRange(plotWindow, newRange, startZero)
	local oldRangeX = plotWindow.RangesX
	local oldRangeY = plotWindow.RangesY

	local minXOld = oldRangeX[1]
	local maxXOld = oldRangeX[2]
	local minYOld = oldRangeY[1]
	local maxYOld = oldRangeY[2]

	local minX, maxX, minY, maxY = unpack(newRange)

	local minXNew = startZero and 0 or zo_min(minXOld, minX)
	local maxXNew = zo_max(maxXOld, maxX)
	local minYNew = startZero and 0 or zo_min(minYOld, minY)
	local maxYNew = zo_max(maxYOld, maxY)

	local isChanged = minXOld ~= minXNew or maxXOld ~= maxXNew or minYOld ~= minYNew or maxYOld ~= maxYNew

	return {minXNew, maxXNew, minYNew, maxYNew}, isChanged
end

local PlotBuffSelection = {}

local function UpdatePlotBuffSelection()
	PlotBuffSelection = {}

	local selectedbuffs = CMXint.selections["buff"]["buff"]
	local buffData = util.GetBuffData()

	if buffData == nil or buffData.buffs == nil then return end

	for buffName, buff in CMX.spairs(buffData.buffs, util.buffSortFunction) do
		if selectedbuffs and selectedbuffs[buffName] ~= nil then PlotBuffSelection[#PlotBuffSelection + 1] = buffName end
		if #PlotBuffSelection >= maxBarPlots then return end
	end
end

local function UpdateBarPlot(plot)
	local barId = plot.barId or 0
	local buffName = PlotBuffSelection[barId]
	local buffData = util.GetBuffData()
	local data = buffName and buffData and buffData.buffs[buffName] or nil

	if buffName == nil or data == nil then
		plot:SetHidden(true)
		return
	end

	plot:SetHidden(false)
	local bardata = AcquireBuffData(buffName)
	local plotWindow = plot:GetParent()
	local plotheight = plotWindow:GetHeight()
	local totalSlots = #PlotBuffSelection > 4 and 8 or 4
	local position = plotheight * (barId - 0.5)/totalSlots

	local scale = CMXint.settings.fightReport.scale
	local xoffset = scale * 24

	plot:SetAnchor(LEFT, plotWindow, TOPLEFT, -xoffset, position)
	plot:SetAnchor(RIGHT, plotWindow, TOPRIGHT, 0, position)
	plot:SetHeight(scale * 20)

	local icon = plot:GetNamedChild("Icon")

	icon:SetTexture(GetFormattedAbilityIcon(data.iconId))
	icon.tooltip = buffName

	plot.bardata = bardata
	plot.xoffset = xoffset
	plot.effectType = data.effectType

	plot:DrawPlot()
end

local function MapUIPosXY(plotWindow, x, y)
	local t, IsInRangeX = plotWindow:MapUIPos(CMX_PLOT_DIMENSION_X, x)
	local v, IsInRangeY = plotWindow:MapUIPos(CMX_PLOT_DIMENSION_Y, y)

	local IsInRange = IsInRangeX and IsInRangeY

	return t, v, IsInRange
end

local function UpdateScales(plotWindow, ranges, exact)
	local xMin, xMax, yMin, yMax = unpack(ranges)

	if not exact then
		xMin, xMax = GetScale(xMin, xMax)
		yMin, yMax = GetScale(yMin, yMax)
	end

	local ticksX = GetTickValues(xMin, xMax)
	local ticksY = GetTickValues(yMin, yMax)

	plotWindow.RangesX = {xMin, xMax, ticksX}
	plotWindow.RangesY = {yMin, yMax, ticksY}

	for i = 1,5 do
		local ticklabelX = GetControl(plotWindow:GetName(), "XTick" .. i .. "Label")
		local ticklabelY = GetControl(plotWindow:GetName(), "YTick" .. i .. "Label")

		ticklabelX:SetText(tostring(ticksX[i]))
		ticklabelY:SetText(tostring(ticksY[i]))
	end
end

function CMXint.SetSliderValue(control, value)
	local labelControl = control:GetParent():GetNamedChild("Label")
	labelControl:SetText(string.format(GetString(SI_COMBAT_METRICS_SMOOTH_LABEL), value))
	CMXint.settings.fightReport.SmoothWindow = value
	ui:UpdatePanel("graph")
end

do
	local startX, startY, plotWindow

	local function UpdateZoomControl()
		local zoomcontrol = plotWindow:GetNamedChild("Zoom")
		local x2, y2 = GetUIMousePosition()
		local minX, minY, maxX, maxY = plotWindow:GetScreenRect()

		zo_clamp(x2, minX, maxX)
		zo_clamp(y2, minY, maxY)

		local width = zo_abs(x2 - startX)
		local height = zo_abs(y2 - startY)

		zoomcontrol:SetAnchor(TOPLEFT, GuiRoot , TOPLEFT, zo_min(startX, x2), zo_min(startY, y2))
		zoomcontrol:SetDimensions(width, height)
	end

	local oldx, oldy

	local function updatePlotCursor()
		local x, y = GetUIMousePosition()
		if x == oldx and y == oldy then return end

		oldx, oldy = x, y
		local plotWindow = ui:GetPanel("graph").plotWindow
		local cursorTime, cursorValue = MapUIPosXY(plotWindow, x, y)
		local dataAtCursorTime = {}

		for _, plot in pairs(plotWindow.plots) do
			if plot.plotType == CMX_PLOT_TYPE_XY and plot.XYData then
				local coords = {0, 0, 0}

				for i, data in pairs(plot.XYData) do
					local t, v = unpack(data)
					if t > cursorTime then
						dataAtCursorTime[plot.id] = coords
						break
					end

					local percentV
					if plot.YAxisSide == COMBAT_METRICS_YAXIS_RIGHT then
						percentV = v * 100
						v = v * plot.AbsoluteYRange
					end

					coords = {v, percentV}
				end
			end
		end

		InitializeTooltip(InformationTooltip, GuiRoot, TOPLEFT, x + 30, y + 30, TOPLEFT)
		local tooltipText = string.format("|cddddddTime: %d:%02d", cursorTime/60, zo_floor(cursorTime%60))
		util.AddTooltipLine(plotWindow, InformationTooltip, tooltipText)

		for plotId, data in CMX.spairs(dataAtCursorTime) do
			local r,g,b = unpack(CMXint.settings.fightReport.PlotColors[plotId])
			local formatter = data[2] and "|c%.2x%.2x%.2x%s: %d (%.1f%%)|r" or "|c%.2x%.2x%.2x%s: %d|r"
			local label = plotWindow.plots[plotId].label

			tooltipText = string.format(formatter, zo_floor(r * 255), zo_floor(g * 255), zo_floor(b * 255), label, unpack(data))
			util.AddTooltipLine(plotWindow, InformationTooltip, tooltipText)
		end

		local cursor = plotWindow:GetNamedChild("Cursor")

		cursor:ClearAnchors()
		cursor:SetAnchor(TOPLEFT, plotWindow, TOPLEFT, x - plotWindow:GetLeft(), 0)
		cursor:SetAnchor(BOTTOMLEFT, plotWindow, BOTTOMLEFT, x - plotWindow:GetLeft(), 0)
	end

	function CMXint.onPlotMouseDown(plotWindowControl, button)
		if button ~= MOUSE_BUTTON_INDEX_LEFT then return end

		CMXint.onPlotMouseExit(plotWindowControl)
		local zoomcontrol = plotWindow:GetNamedChild("Zoom")
		local x, y = GetUIMousePosition()

		zoomcontrol:SetAnchor(TOPLEFT, GuiRoot , TOPLEFT, x, y)
		zoomcontrol:SetDimensions(0, 0)
		zoomcontrol:SetHidden(false)

		startX = x
		startY = y

		plotWindow = plotWindowControl
		EM:RegisterForUpdate("CMX_Report_Zoom_Control", 40, UpdateZoomControl)
	end

	function CMXint.onPlotMouseUp(plotWindow, button, upInside)
		if button == MOUSE_BUTTON_INDEX_LEFT then

			local x, y = GetUIMousePosition()

			EM:UnregisterForUpdate("CMX_Report_Zoom_Control")
			local zoomcontrol = plotWindow:GetNamedChild("Zoom")
			zoomcontrol:SetHidden(true)

			if x == startX and y == startY then
				CMXint.onPlotMouseEnter(plotWindow)
				return
			end

			local t1, v1 = MapUIPosXY(plotWindow, startX, startY)
			local t2, v2 = MapUIPosXY(plotWindow, x, y)
			local minT, maxT = unpack(plotWindow.RangesX)
			local minV, maxV = unpack(plotWindow.RangesY)

			t2 = zo_clamp(t2, minT, maxT)
			v2 = zo_clamp(v2, minV, maxV)

			local tMin = zo_min(t1, t2)
			local tMax = zo_max(t1, t2)
			local vMin = zo_min(v1, v2)
			local vMax = zo_max(v1, v2)

			UpdateScales(plotWindow, {tMin, tMax, vMin, vMax})

			for id, plot in pairs(plotWindow.plots) do
				if plot.DrawPlot then
					plot:DrawPlot()
				end
			end

		elseif button == MOUSE_BUTTON_INDEX_RIGHT then

			plotWindow.RangesX = {0, 0, {}}
			plotWindow.RangesY = {0, 0, {}}

			for id, plot in pairs(plotWindow.plots) do
				if plot.XYData and plot.autoRange and plot:IsHidden() == false then
					local newRange = plotWindow:GetRequiredRange(plot.range, true)
					UpdateScales(plotWindow, newRange)
				end
			end

			for id, plot in pairs(plotWindow.plots) do
				if plot.DrawPlot then
					plot:DrawPlot()
				end
			end
		end

		if upInside then CMXint.onPlotMouseEnter(plotWindow) end
	end

	function CMXint.onPlotMouseEnter(plotWindowControl)
		plotWindow = plotWindowControl

		if CMXint.settings.fightReport.Cursor then
			local cursor = plotWindow:GetNamedChild("Cursor")
			cursor:SetHidden(false)
			EM:RegisterForUpdate("CMX_Report_Cursor_Control", 40, updatePlotCursor)
		end
	end

	function CMXint.onPlotMouseExit(plotWindowControl)
		EM:UnregisterForUpdate("CMX_Report_Cursor_Control")
		ZO_Options_OnMouseExit(plotWindowControl)

		local cursor = plotWindow:GetNamedChild("Cursor")
		cursor:SetHidden(true)
	end

	function CMXint.EditLabelStart(label)
		local editbox = label:GetParent():GetNamedChild("Edit")

		label:SetHidden(true)
		editbox:SetHidden(false)
		editbox:SetText( label:GetText() )
		editbox:SelectAll()
		editbox:TakeFocus()
	end

	function CMXint.EditLabelEnd(editbox)
		local tickControl = editbox:GetParent()
		local plotWindow = tickControl:GetParent()
		local label = tickControl:GetNamedChild("Label")

		editbox:SetHidden(true)
		label:SetHidden(false)

		local newtext = tonumber(editbox:GetText())
		label:SetText(newtext)

		local t1 = tonumber(plotWindow:GetNamedChild("XTick1"):GetNamedChild("Label"):GetText())
		local t2 = tonumber(plotWindow:GetNamedChild("XTick5"):GetNamedChild("Label"):GetText())
		local v1 = tonumber(plotWindow:GetNamedChild("YTick1"):GetNamedChild("Label"):GetText())
		local v2 = tonumber(plotWindow:GetNamedChild("YTick5"):GetNamedChild("Label"):GetText())

		local tMin = zo_min(t1, t2)
		local tMax = zo_max(t1, t2)
		local vMin = zo_min(v1, v2)
		local vMax = zo_max(v1, v2)

		UpdateScales(plotWindow, {tMin, tMax, vMin, vMax}, true)

		for id, plot in pairs(plotWindow.plots) do
			if plot.DrawPlot then

				plot:DrawPlot()

			end
		end
	end
end

local PlotFunctions = {}

local MainCategoryFunctions = {
	[1] = {label = SI_COMBAT_METRICS_SMOOTHED, 		func = Smooth},
	[2] = {label = SI_COMBAT_METRICS_TOTAL, 		func = Total},
	[3] = {label = SI_COMBAT_METRICS_ABSOLUTE, 		func = Absolute},
}

local CategoryStrings = {
	[1] = {label = SI_COMBAT_METRICS_DPS, 			category = "damageOut"},
	[2] = {label = SI_COMBAT_METRICS_HPS, 			category = "healingOut"},
	[3] = {label = SI_COMBAT_METRICS_INCOMING_DPS, 	category = "damageIn"},
	[4] = {label = SI_COMBAT_METRICS_INCOMING_HPS, 	category = "healingIn"},
}

local ResourceStrings = {
	[1] = {label = SI_COMBAT_METRICS_HEALTH, 	powerType = POWERTYPE_HEALTH},
	[2] = {label = SI_COMBAT_METRICS_MAGICKA, 	powerType = POWERTYPE_MAGICKA},
	[3] = {label = SI_COMBAT_METRICS_STAMINA, 	powerType = POWERTYPE_STAMINA},
	[4] = {label = SI_COMBAT_METRICS_ULTIMATE, 	powerType = POWERTYPE_ULTIMATE},
}

local StatStrings = {
	[1] = {label = SI_COMBAT_METRICS_STATS_MAGICKA1, 	statId = LIBCOMBAT_STAT_MAXMAGICKA},
	[2] = {label = SI_COMBAT_METRICS_STATS_MAGICKA2, 	statId = LIBCOMBAT_STAT_SPELLPOWER},
	[3] = {label = SI_COMBAT_METRICS_STATS_MAGICKA3, 	statId = LIBCOMBAT_STAT_SPELLCRIT},
	[4] = {label = SI_COMBAT_METRICS_STATS_MAGICKA4, 	statId = LIBCOMBAT_STAT_SPELLCRITBONUS},
	[5] = {label = SI_COMBAT_METRICS_STATS_MAGICKA5, 	statId = LIBCOMBAT_STAT_SPELLPENETRATION},
	[6] = {label = SI_COMBAT_METRICS_STATS_STAMINA1, 	statId = LIBCOMBAT_STAT_MAXSTAMINA},
	[7] = {label = SI_COMBAT_METRICS_STATS_STAMINA2, 	statId = LIBCOMBAT_STAT_WEAPONPOWER},
	[8] = {label = SI_COMBAT_METRICS_STATS_STAMINA3, 	statId = LIBCOMBAT_STAT_WEAPONCRIT},
	[9] = {label = SI_COMBAT_METRICS_STATS_STAMINA4, 	statId = LIBCOMBAT_STAT_WEAPONCRITBONUS},
	[10] = {label = SI_COMBAT_METRICS_STATS_STAMINA5, 	statId = LIBCOMBAT_STAT_WEAPONPENETRATION},
	[11] = {label = SI_COMBAT_METRICS_STATS_HEALTH1, 	statId = LIBCOMBAT_STAT_MAXHEALTH},
	[12] = {label = SI_COMBAT_METRICS_STATS_HEALTH2, 	statId = LIBCOMBAT_STAT_PHYSICALRESISTANCE},
	[13] = {label = SI_COMBAT_METRICS_STATS_HEALTH3, 	statId = LIBCOMBAT_STAT_SPELLRESISTANCE},
	[14] = {label = SI_COMBAT_METRICS_STATS_HEALTH4, 	statId = LIBCOMBAT_STAT_CRITICALRESISTANCE},
}

local PerformanceStrings = {
	[1] = {label = SI_COMBAT_METRICS_PERFORMANCE_FPSAVG, 	statId = 3},
	[2] = {label = SI_COMBAT_METRICS_PERFORMANCE_FPSMIN, 	statId = 4},
	[3] = {label = SI_COMBAT_METRICS_PERFORMANCE_FPSMAX, 	statId = 5},
	[4] = {label = SI_COMBAT_METRICS_PERFORMANCE_FPSPING, 	statId = 6},
	[5] = {label = SI_COMBAT_METRICS_PERFORMANCE_DESYNC, 	statId = 7},
}

local lastPlotSelector

local function RemovePlotSelection()
	local selector = lastPlotSelector
	local control = selector:GetParent()
	local id = control.id

	local label = control:GetNamedChild("Label")
	label:SetText("-")

	local plotwindow = control:GetParent():GetParent():GetNamedChild("PlotWindow")
	local plot = plotwindow.plots[id]

	plot.func = nil
	plot:Update()
end

function CMX.PlotSelectionMenu(selector)
	ClearMenu()

	lastPlotSelector = selector
	AddCustomMenuItem(GetString(SI_COMBAT_METRICS_NONE), RemovePlotSelection)

	local funcId = 1
	for id, data in ipairs(CategoryStrings) do
		local submenu = {}
		for id2, data2 in ipairs(MainCategoryFunctions) do
			local stringid2 = data2.label
			table.insert(submenu, {label = GetString(stringid2), callback = PlotFunctions[funcId]})
			funcId = funcId + 1
		end

		local stringid = data.label
		AddCustomSubMenuItem(GetString(stringid), submenu)
	end

	AddCustomMenuItem(GetString(SI_COMBAT_METRICS_BOSS_HP), PlotFunctions[funcId])
	funcId = funcId + 1

	local submenu2 = {}
	for id, data in ipairs(ResourceStrings) do
		table.insert(submenu2, {label = GetString(data.label).." %", callback = PlotFunctions[funcId]})
		funcId = funcId + 1
	end

	AddCustomSubMenuItem(GetString(SI_COMBAT_METRICS_RESOURCES), submenu2)

	local submenu3 = {}
	for id, data in ipairs(StatStrings) do
		table.insert(submenu3, {label = GetString(data.label).." %", callback = PlotFunctions[funcId]})
		funcId = funcId + 1
		if id == 5 or id == 10 then table.insert(submenu3, {label = "-"}) end
	end

	AddCustomSubMenuItem(GetString(SI_COMBAT_METRICS_STATS), submenu3)
	local submenu4 = {}

	for id, data in ipairs(PerformanceStrings) do
		table.insert(submenu4, {label = GetString(data.label), callback = PlotFunctions[funcId]})
		funcId = funcId + 1
	end

	AddCustomSubMenuItem(GetString(SI_COMBAT_METRICS_PERFORMANCE), submenu4)

	ShowMenu(selector)
	AnchorMenu(selector)
end

local plotDefaultFunction = {
	[1] = Smooth,
	[2] = Total,
}

local function InitBarPlot(plotWindow, id)
	local plots = plotWindow.plots
	local newPlot = plots[id]

	if newPlot == nil then
		newPlot = CreateControlFromVirtual("CombatMetricsReport_MainPanelGraphPlot", plotWindow, plotTypeTemplates[CMX_PLOT_TYPE_BAR], id)

		newPlot.plotType = CMX_PLOT_TYPE_BAR
		newPlot.barControls = {}
		newPlot.DrawPlot = DrawBarPlot
		newPlot.Update = UpdateBarPlot
		newPlot.id = id
		newPlot.barId = id - maxXYPlots

		plots[id] = newPlot
	end

	return newPlot
end

local function UpdateXYPlot(plot)
	local func = plot.func
	local XYData, YAxisSide

	if func then
		XYData, YAxisSide, plot.AbsoluteYRange = func()
	end

	if XYData == nil then
		plot:SetHidden(true)
		return
	end

	plot:SetHidden(false)

	local range = AcquireRange(XYData)

	if YAxisSide == COMBAT_METRICS_YAXIS_RIGHT then
		range[3] = 0
		range[4] = 1
	end

	local plotWindow = plot.plotWindow

	if plot.autoRange then
		local newRange, isChanged = plotWindow:GetRequiredRange(range, true)
		if isChanged then UpdateScales(plotWindow, newRange) end
	end

	plot.range = range
	plot.XYData = XYData
	plot.YAxisSide = YAxisSide
end

local function InitXYPlot(plotWindow, id)
	local plots = plotWindow.plots
	local newPlot = plots[id]

	if newPlot == nil then
		newPlot = CreateControlFromVirtual("CombatMetricsReport_MainPanelGraphPlot", plotWindow, plotTypeTemplates[CMX_PLOT_TYPE_XY], id)
		newPlot.plotType = CMX_PLOT_TYPE_XY
		newPlot.lineControls = {}
		newPlot.DrawPlot = DrawXYPlot
		newPlot.Update = UpdateXYPlot
		newPlot.autoRange = true
		newPlot.id = id
		newPlot.plotWindow = plotWindow

		local category = CMXint.settings.fightReport.category
		local catId = 1

		while CategoryStrings[catId].category ~= category do
			catId = catId + 1
		end

		if id <= 2 then
			local selectorLabel = plotWindow:GetParent():GetNamedChild("Toolbar"):GetNamedChild("DataSelector" .. id):GetNamedChild("Label")
			local labelString = zo_strformat("<<1>> - <<2>>", GetString(CategoryStrings[catId].label), GetString(MainCategoryFunctions[id].label))

			selectorLabel:SetText(labelString)

			newPlot.func = function() return plotDefaultFunction[id](category) end
			newPlot.label = labelString
		end

		plots[id] = newPlot
	end

	return newPlot
end

local function GetCustomMenuFunction(basefunc, parameter, labelString)
	local function newFunc()
		local selector = lastPlotSelector
		local control = selector:GetParent()
		local id = control.id

		local label = control:GetNamedChild("Label")
		label:SetText(labelString)

		local plotwindow = control:GetParent():GetParent():GetNamedChild("PlotWindow")
		local plot = plotwindow.plots[id]

		plot.func = function() return basefunc(parameter) end
		plot.label = labelString:gsub(" %%", "")
		plot:Update()

		local plotWindow = plot:GetParent()
		for id, plot in pairs(plotWindow.plots) do
			if plot.DrawPlot then
				plot:DrawPlot()
			end
		end
	end

	return newFunc
end

local function initPlotWindow(panel)
	local plotWindow = panel.control:GetNamedChild("PlotWindow")
	panel.plotWindow = plotWindow

	plotWindow.MapValue = MapValue
	plotWindow.MapValueXY = MapValueXY
	plotWindow.MapUIPos = MapUIPos
	plotWindow.GetRequiredRange = GetRequiredRange
	plotWindow.plots = {}

	for i = 1, 5 do
		local labelR = plotWindow:GetNamedChild("YTick" .. i):GetNamedChild("LabelR")
		local text = string.format("%d%%", (i - 1) * 25)
		labelR:SetText(text)
	end

	local editableControls = {"XTick1", "XTick5", "YTick1", "YTick5"}

	for i = 1, 4 do
		local name = editableControls[i]
		local control = plotWindow:GetNamedChild(name)
		local label = control:GetNamedChild("Label")
		local editControlName = control:GetName() .. "Edit"

		local editControl = CreateControlFromVirtual(editControlName, control, "CombatMetrics_GraphTickLabel_Edit")
		editControl:SetAnchorFill(label)

		local font, size, style = unpack(editControl:GetNamedChild("Font").font)			-- Need to manually scale font since it's created late
		if size then size = tonumber(size) * (CMXint.settings.fightReport.scale + 0.2)/1.2 end

		editControl:SetFont(string.format("%s|%s|%s", font, size, style))

		label:SetHandler("OnMouseDoubleClick", CMXint.EditLabelStart)
	end

	local funcId = 1

	for id, data in ipairs(CategoryStrings) do
		for id2, data2 in ipairs(MainCategoryFunctions) do
			local categoryString = data.label
			local category = data.category
			local labelString = zo_strformat("<<1>> - <<2>>", GetString(categoryString), GetString(data2.label))
			local basefunc = data2.func

			PlotFunctions[funcId] = GetCustomMenuFunction(basefunc, category, labelString)
			funcId = funcId + 1
		end
	end

	PlotFunctions[funcId] = GetCustomMenuFunction(BossHPAbsolute, nil, GetString(SI_COMBAT_METRICS_BOSS_HP))
	funcId = funcId + 1

	for id, data in ipairs(ResourceStrings) do
		local resourceString = data.label
		local powerType = data.powerType
		local labelString = GetString(resourceString) .. " %"

		PlotFunctions[funcId] = GetCustomMenuFunction(ResourceAbsolute, powerType, labelString)
		funcId = funcId + 1
	end

	for id, data in ipairs(StatStrings) do
		local statString = data.label
		local statId = data.statId
		local labelString = GetString(statString) .. " %"

		PlotFunctions[funcId] = GetCustomMenuFunction(StatAbsolute, statId, labelString)
		funcId = funcId + 1
	end

	for id, data in ipairs(PerformanceStrings) do
		local perfString = data.label
		local perfId = data.statId
		local labelString = GetString(perfString)

		PlotFunctions[funcId] = GetCustomMenuFunction(PerformancePlot, perfId, labelString)
		funcId = funcId + 1
	end

	for id = 1, maxXYPlots do
		InitXYPlot(plotWindow, id)
	end

	for id = maxXYPlots + 1, maxXYPlots + maxBarPlots do
		InitBarPlot(plotWindow, id)
	end
end

local function initToolbar(panel)
	local toolbar = panel.control:GetNamedChild("Toolbar")
	panel.toolbar = toolbar

	local PlotColors = CMXint.settings.fightReport.PlotColors
	local cursorToggle = toolbar:GetNamedChild("ToggleCursor")
	cursorToggle:SetAlpha(CMXint.settings.fightReport.Cursor and 1 or 0.3)

	for i = 1,5 do
		local selector = toolbar:GetNamedChild("DataSelector" .. i)
		selector.id = i
		local colorbox = selector:GetNamedChild("ColorBox")
		local color = PlotColors[i]

		colorbox:SetCenterColor(unpack(color))
		selector.color = color

		local function updateColor(r, g, b, a)
			colorbox:SetCenterColor(r, g, b, a)
			selector.color = {r, g, b, a}
			PlotColors[i] = {r, g, b, a}
			toolbar:GetParent():Update()
		end

		colorbox:SetHandler("OnMouseUp", function(self, button, upInside)
				if upInside then
					local r, g, b, a = unpack(selector.color)
					COLOR_PICKER:Show(updateColor, r, g, b, a)
				end
			end
		)
	end

	local labeltexts = {GetString(SI_COMBAT_METRICS_BUFFS), GetString(SI_COMBAT_METRICS_DEBUFFS)}
	local showGroupBuffs = CMXint.settings.fightReport.ShowGroupBuffsInPlots

	for i = 1,2 do
		local selector = toolbar:GetNamedChild("BuffSelector" .. i)
		selector.id = i

		local label = selector:GetNamedChild("Label")
		label:SetText(labeltexts[i])

		local colorbox = selector:GetNamedChild("ColorBox")
		local color = PlotColors[i + 5]

		colorbox:SetCenterColor(unpack(color))
		selector.color = color

		local function updateColor(r, g, b, a)
			colorbox:SetCenterColor(r, g, b, a)
			selector.color = {r, g, b, a}
			PlotColors[i + 5] = {r, g, b, a}
			panel:Update()
		end

		colorbox:SetHandler("OnMouseUp", function(self, button, upInside)
				if upInside then
					local r, g, b, a = unpack(selector.color)
					COLOR_PICKER:Show(updateColor, r, g, b, a)

				end
			end
		)

		local groupSelector = selector:GetNamedChild("GroupSelector")
		groupSelector:SetAlpha(showGroupBuffs and 1 or 0.2)

		if i == 1 then
			groupSelector:SetHidden(CMXint.settings.fightReport.rightpanel ~= "buffsout")
			groupSelector.tooltip = SI_COMBAT_METRICS_GRAPH_BUFF_GROUP_SELECTOR
			groupSelector:SetHandler("OnMouseUp", function(self, button, upInside)

					if upInside then
						showGroupBuffs = not showGroupBuffs
						CMXint.settings.fightReport.ShowGroupBuffsInPlots = showGroupBuffs
						groupSelector:SetAlpha(showGroupBuffs and 1 or 0.2)
						self:Update()
					end
				end
			)
		else
			groupSelector:SetHidden(true)
		end
	end
end


function CMXint.InitializeGraphPanel(control)
	GraphPanel = CMX.internal.PanelObject:New(control, "graph")

	function GraphPanel:Update(fightData)
		local control = self.control
		if control:IsHidden() then return end
		
		local settings = self.settings

		if enlargedGraph == true then
			control:SetParent(CombatMetricsReport)
			control:SetAnchor(BOTTOMRIGHT, CombatMetricsReport_SetupPanel, BOTTOMRIGHT, 0, 0)
		else
			control:SetParent(CombatMetricsReport_MainPanel)
			control:SetAnchor(BOTTOMRIGHT, CombatMetricsReport_MainPanel, BOTTOMRIGHT, 0, 0)
		end

		CombatMetricsReport:GetNamedChild("_AbilityPanel"):SetHidden(enlargedGraph)
		CombatMetricsReport:GetNamedChild("_UnitPanel"):SetHidden(enlargedGraph)
		CombatMetricsReport:GetNamedChild("_BuffPanel"):SetHidden(enlargedGraph)
		CombatMetricsReport:GetNamedChild("_MainPanel"):SetHidden(enlargedGraph)

		local plotWindow = control:GetNamedChild("PlotWindow")
		local toolbar = control:GetNamedChild("Toolbar")
		local smoothSlider = toolbar:GetNamedChild("SmoothControl"):GetNamedChild("Slider")
		local SmoothWindow = settings.SmoothWindow

		smoothSlider:SetValue(SmoothWindow)

		local groupSelector = toolbar:GetNamedChild("BuffSelector1"):GetNamedChild("GroupSelector")
		groupSelector:SetHidden(settings.rightpanel ~= "buffsout")

		if fightData == nil then plotWindow:SetHidden(true) return end

		plotWindow:SetHidden(false)
		plotWindow.RangesX = {0, 0, {}}
		plotWindow.RangesY = {0, 0, {}}

		UpdatePlotBuffSelection()

		for id, plot in ipairs(plotWindow.plots) do
			plot:Update()
		end

		for id, plot in pairs(plotWindow.plots) do
			if plot.DrawPlot then
				plot:DrawPlot()
			end
		end
	end

	initPlotWindow(GraphPanel)
	initToolbar(GraphPanel)
end


function CMX.ToggleGraphSize(self)
	enlargedGraph = not enlargedGraph

	local labelText = enlargedGraph and GetString(SI_COMBAT_METRICS_SHRINK) or GetString(SI_COMBAT_METRICS_ENLARGE)
	self:GetNamedChild("Label"):SetText(labelText)

	ui:UpdatePanel("graph")
end


function CMX.ToggleCursorDisplay(self)
	local enable = not CMXint.settings.fightReport.Cursor
	self:SetAlpha(enable and 1 or 0.3)
	CMXint.settings.fightReportCursor = enable
end


local isFileInitialized = false
function CMXint.InitializeGraph()
	if isFileInitialized == true then return false end
	logger = util.initSublogger("Graph")

    isFileInitialized = true
	return true
end