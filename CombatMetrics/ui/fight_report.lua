local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger
local fightReport

local em = GetEventManager()
-- local 

local function InitializeFightReport()
	fightReport = CombatMetrics_Report
	CMXf.storeOrigLayout(fightReport)

	local settings = CMXint.settings.FightReport
	local pos_x = settings.pos_x
	local pos_y = settings.pos_y

	fightReport:ClearAnchors()
	fightReport:SetAnchor(CENTER, nil , TOPLEFT, pos_x, pos_y)

	local fragment = ZO_HUDFadeSceneFragment:New(fightReport)

	local scene = ZO_Scene:New("CMX_REPORT_SCENE", SCENE_MANAGER)
	scene:AddFragment(fragment)

	local function resize(control, scale)
		if control.sizes == nil and control.anchors == nil then return end
		local width, height = unpack(control.sizes)
		local maxwidth, maxheight = GuiRoot:GetDimensions()

		scale = zo_min(zo_max(scale or 1, 0.5), 3, maxwidth/width, maxheight/height)
		settings.scale = scale

		if width and control:GetResizeToFitDescendents() == false then control:SetWidth(width*scale) end
		if height and control:GetResizeToFitDescendents() == false then control:SetHeight(height*scale) end

		local anchors = {}
		local oldanchors = control.anchors
		if oldanchors then ZO_DeepTableCopy(control.anchors, anchors) end

		local anchor1 = anchors[1]
		local anchor2 = anchors[2]
		if anchor1 or anchor2 then control:ClearAnchors() end

		if anchor1 ~= nil then
			anchor1[4] = anchor1[4] * scale
			anchor1[5] = anchor1[5] * scale

			control:SetAnchor(unpack(anchor1))
		end

		if anchor2 ~= nil then
			anchor2[4] = anchor2[4] * scale
			anchor2[5] = anchor2[5] * scale

			control:SetAnchor(unpack(anchor2))
		end

		local fontcontrol = control:GetNamedChild("Font")

		if fontcontrol ~= nil then
			local font, size, style = unpack(fontcontrol.font)
			if size then size = tonumber(size) * (scale + 0.2)/1.2 end			-- Don't Scale fonts as much
			control:SetFont(string.format("%s|%s|%s", font, size, style))
		end

		for i = 1, control:GetNumChildren() do
			local child = control:GetChild(i)
			if child then resize(child, scale) end
		end
	end

	function fightReport:Resize(scale)
		resize(fightReport, scale)
		if not fightReport:IsHidden() then fightReport:Update() end
	end

	-- TODO: Update Panels

	fightReport:Resize(settings.scale)
end

function CMXint.ToggleFightReport()
	if not SCENE_MANAGER:IsShowing("CMX_REPORT_SCENE") then
		CombatMetrics_Report_DonateDialog:SetHidden(true)
		SCENE_MANAGER:Toggle("CMX_REPORT_SCENE")

		CombatMetrics_Report:Update(#CMX.lastfights>0 and #CMX.lastfights or nil)
		SCENE_MANAGER:SetInUIMode(true)
	else
		SCENE_MANAGER:Toggle("CMX_REPORT_SCENE")
	end
end

function CMXint.UpdateFightReport(control, fightId)
	logger:Debug("Updating Fight Report")
	em:UnregisterForUpdate("CMX_Report_Update_Delay")

	local settings = CMXint.settings.FightReport
	local category = settings.category or "damageOut"

	-- clear selections of abilities, buffs or units when selecting a different fight to display --

	if fightId == nil or fightId ~= currentFight then
		CMXint.ClearSelections()
	end

	-- determine which fight to show
	fightId = fightId or currentFight  -- if no fightId was given, use the previous one (this will also select the next fight if one is deleted)
	if fightId == nil or fightId < 0 or CMX.lastfights[fightId] == nil then -- if no valid fight is selected, fall back to the most recent one, if it exists.
		if #CMX.lastfights == 0 then
			fightId = -1 -- there is no fight saved in pos. -1, it will be nil.
		else
			fightId = #CMX.lastfights
		end
	end

	currentFight = fightId

	fightData = CMX.lastfights[fightId] -- this is the fight of interest, can be nil

	if fightData and fightData.calculated == nil and fightData.CalculateFight then -- if it wasn't calculated yet, do so now

		fightData:CalculateFight()
		UpdateReport2()
		return

	elseif fightData and fightData.calculating == true then  -- if it is still calculating wait for it to finish

		em:RegisterForUpdate("CMX_Report_Update_Delay", 500, UpdateReport2)
		return

	end

	-- Generate Filtered Dataset

	selectionData = fightData and CMX.GenerateSelectionStats(fightData, category, selections) or nil

	abilitystats = {fightData, selectionData}

	-- Update Panels

	for i = 2, control:GetNumChildren() do

		local child = control:GetChild(i)

		if child.Update then child:Update() end

	end
end

local isFileInitialized = false
function CMXint.InitializeFightReport()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("FightReport")

	InitializeFightReport()

    isFileInitialized = true
	return true
end