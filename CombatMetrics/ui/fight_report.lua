-- Fight report panel, top level window containing all other panels.
---@class CMX
local CMX = CombatMetrics
---@class CMXint
local CMXint = CMX.internal
---@class CMXutil
local util = CMXint.util
---@type Logger
local logger
---@class CMXui
local ui = CMXint.ui

CMXint.scenes = {}
local _

local em = GetEventManager()

---@class Control
---@field sizes number[]
---@field anchors table[]
---@field font table?
local function ResizeControl(control, scale)
	if control.sizes == nil and control.anchors == nil then
		return
	end
	-- Shared controls record their base layout too (see ApplyPosition in shared_controls.lua), and
	-- they may leave a dimension unset — a label sizes its own height from the font. So unlike the
	-- XML controls storeOrigLayout captures, width/height are not guaranteed to be present here.
	local width, height = control.sizes[1], control.sizes[2]
	local maxwidth, maxheight = GuiRoot:GetDimensions()

	if (width and width < 0) or (height and height < 0) then
		logger:Error("Invalid default dimensions for %s: %s, %s", control:GetName(), width, height)
	end

	local wscale = width and width > 0 and maxwidth / width or math.huge
	local hscale = height and height > 0 and maxheight / height or math.huge
	scale = zo_clamp(scale or 1, 0.5, zo_min(scale or 1, wscale, hscale, 3))

	if width and control:GetResizeToFitDescendents() == false then
		control:SetWidth(width * scale)
	end
	if height and control:GetResizeToFitDescendents() == false then
		control:SetHeight(height * scale)
	end

	local anchors = {}
	local oldanchors = control.anchors
	if oldanchors then
		ZO_DeepTableCopy(control.anchors, anchors)
	end

	local anchor1 = anchors[1]
	local anchor2 = anchors[2]
	if anchor1 or anchor2 then
		control:ClearAnchors()
	end

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

	-- Shared controls have no $(parent)Font child; they record their base size on the control itself.
	-- ui.GetFont bakes the scale in, so the string has to be rebuilt rather than reused, and it takes
	-- the scale explicitly because settings.scale is only updated after this pass has run.
	if control.font ~= nil then
		---@cast control LabelControl
		control:SetFont(ui.GetFont(control.font[1], control.font[2], scale))
	else
		local fontcontrol = control:GetNamedChild("Font")

		if fontcontrol ~= nil then
			---@diagnostic disable-next-line: param-type-mismatch
			local font, size, style = unpack(fontcontrol.fontData)
			if size then
				size = tonumber(size) * (scale + 0.2) / 1.2
			end -- Don't Scale fonts as much
			---@cast control LabelControl
			control:SetFont(string.format("%s|%s|%s", font, size, style))
		end
	end

	for i = 1, control:GetNumChildren() do
		local child = control:GetChild(i)
		if child then
			ResizeControl(child, scale)
		end
	end
end

local function InitializeFightReport() -- TODO: Decide on a common TLW/Object scheme
	---@class FightReport: TopLevelWindow
	---@field currentFight Fight?
	local FightReport = CombatMetricsReport
	CMXint.fightReport = FightReport
	util.storeOrigLayout(FightReport)

	local settings = CMXint.settings.fightReport
	local pos_x = settings.pos_x
	local pos_y = settings.pos_y
	FightReport:ClearAnchors()
	---@diagnostic disable-next-line: missing-parameter, param-type-mismatch
	FightReport:SetAnchor(CENTER, nil, TOPLEFT, pos_x, pos_y)

	FightReport.settings = settings

	local fragment = ZO_HUDFadeSceneFragment:New(FightReport)
	local scene = ZO_Scene:New("CMX_REPORT_SCENE", SCENE_MANAGER)
	scene:AddFragment(fragment)
	CMXint.scenes.report = scene
	CMXint.scenes.reportFragment = fragment  -- shared with view scenes in scenes.lua

	-- When CMX_REPORT_SCENE becomes visible it either pushes the saved view (opening) or
	-- bounces straight back to HUD (Escape popped the view scene back to base).
	local openingCMX = false
	scene:RegisterCallback("StateChange", function(_, newState)
		if newState == SCENE_SHOWN then
			if openingCMX then
				openingCMX = false
				local key = settings.scene or "fightStats"
				local targetName = CMXint.viewSceneNames[key] or CMXint.viewSceneNames.fightStats
				if targetName then
					SCENE_MANAGER:Push(targetName)
				end
			else
				SCENE_MANAGER:PopScenes(1)
			end
		end
	end)

	local function savePos()
		settings.pos_x, settings.pos_y = FightReport:GetCenter()
	end

	local function onShow()
		FightReport:Update()
		SCENE_MANAGER:SetInUIMode(true)
	end

	---@diagnostic disable-next-line: missing-parameter
	FightReport:SetHandler("OnMoveStop", savePos)
	---@diagnostic disable-next-line: missing-parameter
	FightReport:SetHandler("OnShow", onShow)

	function FightReport:Resize(scale)
		ResizeControl(FightReport, scale)
		settings.scale = scale
		FightReport:Update()
		savePos()
	end

	function FightReport:Toggle()
		if SCENE_MANAGER:IsSceneOnStack("CMX_REPORT_SCENE") then
			SCENE_MANAGER:PopScenes(2)
		elseif not SCENE_MANAGER:IsShowing("CMX_REPORT_SCENE") then
			openingCMX = true
			SCENE_MANAGER:Push("CMX_REPORT_SCENE")
		end
	end

	function FightReport:Update()
		if FightReport:IsHidden() or ui.sceneTransitioning then
			return
		end
		logger:Info("Updating Fight Report")

		self.currentFight = CMXint.FightData:GetCurrentFight()

		if self.currentFight == nil then
			FightReport:Clear()
			return
		end

		for _, panel in pairs(ui.panels) do
			if ui.debugSharedControls then
				panel:VerifySharedControls()
			end
			if not panel.control:IsHidden() then
				panel:Update()
			end
		end
	end

	function FightReport:Clear()
		-- A hidden panel has released its shared controls; touching its cached references would
		-- write into controls that belong to a visible panel now. It clears itself on Recover.
		for _, panel in pairs(ui.panels) do
			if not panel.control:IsHidden() then
				panel:Clear()
			end
		end
	end

	function FightReport:SelectScene(key)
		local targetName = CMXint.viewSceneNames[key]
		if not targetName then return end
		settings.scene = key
		if ui.IsAnyViewShowing() then
			SCENE_MANAGER:SwapCurrentScene(targetName)
		end
	end

	FightReport:Resize(settings.scale)
	return FightReport
end

local isFileInitialized = false
function CMXint.InitializeFightReport()
	if isFileInitialized == true then
		return true
	end
	logger = util.initSublogger("FightReport")

	InitializeFightReport()

	isFileInitialized = true
	return true
end
