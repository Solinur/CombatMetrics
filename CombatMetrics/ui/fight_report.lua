local CMX = CombatMetrics
local CMXint = CMX.internal
CMXint.scenes = {}
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger
local FightReport
local _

local em = GetEventManager()

local function ResizeControl(control, scale)
	if control.sizes == nil and control.anchors == nil then return end
	local width, height = unpack(control.sizes)
	local maxwidth, maxheight = GuiRoot:GetDimensions()

	scale = zo_min(zo_max(scale or 1, 0.5), 3, maxwidth / width, maxheight / height)

	if width and control:GetResizeToFitDescendents() == false then control:SetWidth(width * scale) end
	if height and control:GetResizeToFitDescendents() == false then control:SetHeight(height * scale) end

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
		if size then size = tonumber(size) * (scale + 0.2) / 1.2 end -- Don't Scale fonts as much
		control:SetFont(string.format("%s|%s|%s", font, size, style))
	end

	for i = 1, control:GetNumChildren() do
		local child = control:GetChild(i)
		if child then ResizeControl(child, scale) end
	end
end


local function InitializeFightReport()
	FightReport = CombatMetricsReport
	CMXf.storeOrigLayout(FightReport)

	local settings = CMXint.settings.fightReport
	local pos_x = settings.pos_x
	local pos_y = settings.pos_y
	FightReport:ClearAnchors()
	FightReport:SetAnchor(CENTER, nil, TOPLEFT, pos_x, pos_y)
	
	FightReport.settings = settings
	FightReport.panels = CMXint.panels

	local fragment = ZO_HUDFadeSceneFragment:New(FightReport)
	local scene = ZO_Scene:New("CMX_REPORT_SCENE", SCENE_MANAGER)
	scene:AddFragment(fragment)
	CMXint.scenes.report = scene

	local function savePos()
		settings.pos_x, settings.pos_y = FightReport:GetCenter()
	end

	local function onShow()
		FightReport:Update()
		SCENE_MANAGER:SetInUIMode(true)
	end

	FightReport:SetHandler("OnMoveStop", savePos)
	FightReport:SetHandler("OnShow", onShow)

	function FightReport:Resize(scale)
		ResizeControl(FightReport, scale)
		settings.scale = scale
		FightReport:Update()
	end

	function FightReport:Toggle()
		SCENE_MANAGER:Toggle("CMX_REPORT_SCENE")
	end

	function FightReport:Update()
		if FightReport:IsHidden() then return end
		logger:Debug("Updating Fight Report")

		if CMXint.fightData.currentIndex == nil then FightReport:Clear() end

		for _, panel in pairs(CMXint.panels) do
			panel:Update()
		end
	end

	function FightReport:Clear()
		for _, panel in pairs(CMXint.panels) do
			panel:Clear()
		end
	end

	function FightReport:SelectScene(newScene)
		-- TODO: implement
	end

	FightReport:Resize(settings.scale)
	return FightReport
end

local isFileInitialized = false
function CMXint.InitializeFightReport()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("FightReport")

	CMXint.fightReport = InitializeFightReport()

	isFileInitialized = true
	return true
end
