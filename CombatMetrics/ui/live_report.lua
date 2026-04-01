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
local LC = LibCombat2
-- Update the mini DPS meter

---@class LiveReportPanelData
---@field name string
---@field tooltip string
---@field tooltipBoss string?
---@field iconTexture string
---@field iconTextureBoss string?
---@field blockSize number
---@field panelSize number
---@field iconSize number
---@field labelSize number
---@field updateFunc fun(panel: LiveReportPanel)

---@param playerTime number
---@param playerAmount integer
---@param totalTime number
---@param totalAmount integer
---@return string XPSString
local function FormatXPSLabel(playerTime, playerAmount, totalTime, totalAmount)
	local playerXPS = zo_roundToZero(util.SafeDivide(playerAmount, playerTime), 0.01)
	local totalXPS = zo_roundToZero(util.SafeDivide(totalAmount, totalTime), 0.01)
	if playerAmount > totalAmount then
		logger:Warn("Player amount is larger than total amount: %d > %d", playerAmount, totalAmount)
	end
	local ratio = zo_roundToZero(util.SafeDivide(playerAmount, totalAmount) * 100)
	return zo_strformat(GetString(SI_COMBAT_METRICS_SHOW_XPS), playerXPS, totalXPS, ratio)
end

---@param panel LiveReportPanel
local function UpdateSingleTargetDamage(panel)
	local panelControl = panel.control
	local iconControl = panelControl:GetNamedChild("Icon")
	---@cast iconControl TextureControl
	local tooltipControl = panelControl:GetNamedChild("Tooltip")
	local labelControl = panelControl:GetNamedChild("Label")
	---@cast labelControl LabelControl
	local layout = panel.layout

	if LC.IsLatestFightBossFight() then
		iconControl:SetTexture(layout.iconTextureBoss)
		---@diagnostic disable-next-line: undefined-field
		tooltipControl.tooltip[1] = layout.tooltipBoss
	else
		iconControl:SetTexture(layout.iconTexture)
		---@diagnostic disable-next-line: undefined-field
		tooltipControl.tooltip[1] = layout.tooltip
	end

	local playerTime, playerDamage, totalTime, totalDamage = LC.GetLatestMainTargetDamageDone()
	local labelText = FormatXPSLabel(playerTime, playerDamage, totalTime, totalDamage)
	labelControl:SetText(labelText)
end

---@param panel LiveReportPanel
local function UpdateMultiTargetDamage(panel)
	local panelControl = panel.control
	local labelControl = panelControl:GetNamedChild("Label")
	---@cast labelControl LabelControl

	local playerTime, playerDamage, totalTime, totalDamage = LC.GetLatestTotalDamageDone()
	local labelText = FormatXPSLabel(playerTime, playerDamage, totalTime, totalDamage)
	labelControl:SetText(labelText)
end

local function UpdateHealingDone(panel)
	local panelControl = panel.control
	local labelControl = panelControl:GetNamedChild("Label")
	---@cast labelControl LabelControl

	local playerTime, playerHealing, totalTime, totalHealing = LC.GetLatestHealingDone(false)
	local labelText = FormatXPSLabel(playerTime, playerHealing, totalTime, totalHealing)
	labelControl:SetText(labelText)
end

local function UpdateAbsoluteHealingDone(panel)
	local panelControl = panel.control
	local labelControl = panelControl:GetNamedChild("Label")
	---@cast labelControl LabelControl

	local playerTime, playerHealing, _, _ = LC.GetLatestHealingDone(true)
	local playerHPS = zo_roundToZero(util.SafeDivide(playerHealing, playerTime), 0.01)

	labelControl:SetText(playerHPS)
end

---@param panel LiveReportPanel
local function UpdateDamageReceived(panel)
	local panelControl = panel.control
	local labelControl = panelControl:GetNamedChild("Label")
	---@cast labelControl LabelControl

	local playerTime, playerDamage, totalTime, totalDamage = LC.GetLatestTotalDamageReceived()
	local labelText = FormatXPSLabel(playerTime, playerDamage, totalTime, totalDamage)
	labelControl:SetText(labelText)
end

local function UpdateHealingReceived(panel)
	local panelControl = panel.control
	local labelControl = panelControl:GetNamedChild("Label")
	---@cast labelControl LabelControl

	local playerTime, playerHealing = LC.GetLatestPlayerHealingReceived()
	local playerHPS = zo_roundToZero(util.SafeDivide(playerHealing, playerTime), 0.01)

	labelControl:SetText(playerHPS)
end

local function UpdateCombatTime(panel)
	local panelControl = panel.control
	local labelControl = panelControl:GetNamedChild("Label")
	---@cast labelControl LabelControl

	local time = LC.GetLatestFightDuration()
	local timeString = string.format("%d:%04.1f", time / 60, time % 60)

	labelControl:SetText(timeString)
end

---@type LiveReportPanelData[]
local PANEL_DATA = {
	{
		name = "dpsSingle",
		tooltip = GetString(SI_COMBAT_METRICS_LIVEREPORT_DPSSINGLE_TOOLTIP),
		iconTexture = "/esoui/art/icons/mapkey/mapkey_fightersguild.dds",
		blockSize = 1,
		panelSize = 150,
		iconSize = 24,
		labelSize = 120,
		iconTextureBoss = "esoui/art/tutorial/poi_groupboss_complete.dds",
		tooltipBoss = GetString(SI_COMBAT_METRICS_LIVEREPORT_DPSBOSS_TOOLTIP),
		updateFunc = UpdateSingleTargetDamage,
	},
	{
		name = "dpsMulti",
		tooltip = GetString(SI_COMBAT_METRICS_LIVEREPORT_DPSMULTI_TOOLTIP),
		iconTexture = "/EsoUI/Art/LFG/Gamepad/LFG_roleIcon_dps.dds",
		blockSize = 1,
		panelSize = 150,
		iconSize = 24,
		labelSize = 120,
		updateFunc = UpdateMultiTargetDamage,
	},
	{
		name = "hpsOut",
		tooltip = GetString(SI_COMBAT_METRICS_LIVEREPORT_HPSOUT_TOOLTIP),
		iconTexture = "/EsoUI/Art/LFG/Gamepad/LFG_roleIcon_healer.dds",
		blockSize = 1,
		panelSize = 150,
		iconSize = 24,
		labelSize = 120,
		updateFunc = UpdateHealingDone,
	},
	{
		name = "dpsIn",
		tooltip = GetString(SI_COMBAT_METRICS_LIVEREPORT_DPSINC_TOOLTIP),
		iconTexture = "/EsoUI/Art/LFG/Gamepad/LFG_roleIcon_tank.dds",
		blockSize = 1,
		panelSize = 150,
		iconSize = 24,
		labelSize = 120,
		updateFunc = UpdateDamageReceived,
	},
	{
		name = "hpsOutRaw",
		tooltip = GetString(SI_COMBAT_METRICS_LIVEREPORT_HPSRAW_TOOLTIP),
		iconTexture = "/esoui/art/buttons/gamepad/pointsplus_up.dds",
		blockSize = 0.57,
		panelSize = 85,
		iconSize = 24,
		labelSize = 55,
		updateFunc = UpdateAbsoluteHealingDone,
	},
	{
		name = "hpsIn",
		tooltip = GetString(SI_COMBAT_METRICS_LIVEREPORT_HPSINC_TOOLTIP),
		iconTexture = "/esoui/art/hud/gamepad/gp_radialicon_invitegroup_down.dds",
		blockSize = 0.57,
		panelSize = 85,
		iconSize = 24,
		labelSize = 55,
		updateFunc = UpdateHealingReceived,
	},
	{
		name = "time",
		tooltip = GetString(SI_COMBAT_METRICS_LIVEREPORT_TIME_TOOLTIP),
		iconTexture = "/esoui/art/tutorial/timer_icon.dds",
		blockSize = 0.43,
		panelSize = 65,
		iconSize = 20,
		labelSize = 38,
		updateFunc = UpdateCombatTime,
	},
}

---@type table<string, LiveReportPanelData>
local PANEL_DATA_BY_NAME = {}
ui.PANEL_DATA_BY_NAME = PANEL_DATA_BY_NAME

for i, layout in ipairs(PANEL_DATA) do
	PANEL_DATA_BY_NAME[layout.name] = layout
end

local function resize(control, scale)
	if control:GetType() == CT_BACKDROP or control.sizes == nil and control.anchors == nil then
		return
	end
	local width, height = unpack(control.sizes)
	local maxwidth, maxheight = GuiRoot:GetDimensions()

	scale = zo_min(zo_max(scale or 1, 0.5), 3, maxwidth / width, maxheight / height)
	CMXint.settings.liveReport.scale = scale

	if width then
		control:SetWidth(width * scale)
	end
	if height then
		control:SetHeight(height * scale)
	end
	local fontcontrol = control:GetNamedChild("Font")

	if fontcontrol ~= nil then
		local font, size, style = unpack(fontcontrol.font)
		if size then
			size = tonumber(size) * (scale + 0.1) / 1.2
		end -- Don't Scale fonts as much
		control:SetFont(string.format("%s|%s|%s", font, size, style))
	end

	for i = 1, control:GetNumChildren() do
		local child = control:GetChild(i)
		if child then
			resize(child, scale)
		end
	end
end

---@class LiveReportPanel
---@field New fun(self: LiveReportPanel, name: string, parent: LiveReport): LiveReportPanel
local LiveReportPanel = ZO_InitializingObject:Subclass() -- holds all recent events + info to send on death

---@param name string
---@param parent LiveReport
function LiveReportPanel:Initialize(name, parent)
	assert(PANEL_DATA_BY_NAME[name], string.format("Missing layout data for live report panel: %s", name))

	local templateName = "CombatMetrics_LiveReport_" .. name
	local control = CreateControlFromVirtual(templateName, parent.control, "CombatMetrics_LiveReport_Panel")
	self.name = name
	self.control = control
	self:InitLayout(control)

	self.active = true
	self.parent = parent
	parent.panels[name] = self
end

function LiveReportPanel:InitLayout(control)
	local layout = PANEL_DATA_BY_NAME[self.name]

	self.layout = layout
	self.size = layout.blockSize
	control:SetWidth(layout.panelSize)

	local iconControl = control:GetNamedChild("Icon")
	iconControl:SetWidth(layout.iconSize)
	iconControl:SetHeight(layout.iconSize)
	iconControl:SetTexture(layout.iconTexture)

	local labelControl = control:GetNamedChild("Label")
	labelControl:SetWidth(layout.labelSize)
	util.storeOrigLayout(self.control)

	local tooltipControl = control:GetNamedChild("Tooltip")
	tooltipControl.tooltip = { layout.tooltip }

	self.Update = layout.updateFunc
end

function LiveReportPanel:Refresh()
	---@type Control
	local control = self.control
	local parent = self.parent
	local settings = parent.settings
	local scale = settings.scale

	resize(control, scale)

	-- local width, height = unpack(control.sizes)
	-- control:SetDimensions(width * scale, height * scale)

	logger:Info("Refresh LR Panel %s: WxH = %d x %d", self.name, control:GetDimensions())

	local label = control:GetNamedChild("Label")
	---@cast label LabelControl
	local alignment = settings.alignmentleft and TEXT_ALIGN_LEFT or TEXT_ALIGN_RIGHT
	label:SetHorizontalAlignment(alignment)

	local showGroupTooltip = CMXint.settings.group.enableGroupData == true
	---@diagnostic disable-next-line: undefined-field
	control:GetNamedChild("Tooltip").tooltip[2] = showGroupTooltip and SI_COMBAT_METRICS_LIVEREPORT_GROUP_TOOLTIP or nil
end

function LiveReportPanel:RefreshAnchor(anchorData)
	---@type Control
	local control = self.control
	local scale = self.parent.settings.scale

	control:ClearAnchors()
	control:SetAnchor(anchorData[1], anchorData[2], anchorData[3], anchorData[4] * scale, anchorData[5] * scale)
end

function LiveReportPanel:Update()
	-- placeholder
end

local anchorSchemes = {
	["First"] = { TOPLEFT, nil, TOPLEFT, 0, 0 },
	["Horizontal"] = { LEFT, nil, RIGHT, 0, 0 },
	["Vertical"] = { TOPLEFT, nil, BOTTOMLEFT, 0, 0 },
	["Compact"] = { LEFT, nil, RIGHT, 0, 0 },
	["CompactRow2"] = { TOPLEFT, nil, BOTTOMLEFT, 0, 0 },
}

---@class LiveReport
---@field New fun(self: LiveReport, control: Control): LiveReport
local LiveReport = ZO_InitializingObject:Subclass()

function LiveReport:Initialize(control)
	local settings = CMXint.settings.liveReport

	self.control = control
	self.control.object = self

	control:ClearAnchors()
	control:SetAnchor(CENTER, nil, TOPLEFT, settings.pos_x, settings.pos_y)

	function self.control:Resize(scale)
		self.object:Resize(scale)
	end

	local function OnMoveStop()
		self:SavePosition()
	end

	control:SetHandler("OnMoveStop", OnMoveStop)
	control:GetNamedChild("ResizeFrame"):SetMouseEnabled(not settings.locked)
	control:SetMovable(not settings.locked)
	control:GetNamedChild("BG"):SetAlpha(settings.bgalpha / 100)

	util.storeOrigLayout(self.control)

	self.settings = settings
	self.initialized = true
	self.fragment = ZO_HUDFadeSceneFragment:New(control)

	---@type table<string, LiveReportPanel>
	self.panels = {}

	self:Toggle(settings.enabled)
	self:Refresh()
end

---@return boolean
function LiveReport:IsEnabled()
	return self.settings.enabled
end

function LiveReport:SavePosition()
	local x, y = self.control:GetCenter()
	self.settings.pos_x = x
	self.settings.pos_y = y
end

function LiveReport:Toggle(value)
	local control = self.control
	if value == nil then
		value = control:IsHidden()
	end

	local fragment = self.fragment
	if value == true and SCENE_MANAGER and self.settings.enabled then
		SCENE_MANAGER:GetScene("hud"):AddFragment(fragment)
		SCENE_MANAGER:GetScene("hudui"):AddFragment(fragment)
		SCENE_MANAGER:GetScene("siegeBar"):AddFragment(fragment)

		local currentScene = SCENE_MANAGER.currentScene and SCENE_MANAGER.currentScene.name or ""
		local isShownForCurrentScene = currentScene == "hud" or currentScene == "hudui" or currentScene == "siegeBar"
		control:SetHidden(not isShownForCurrentScene)
	else
		SCENE_MANAGER:GetScene("hud"):RemoveFragment(fragment)
		SCENE_MANAGER:GetScene("hudui"):RemoveFragment(fragment)
		SCENE_MANAGER:GetScene("siegeBar"):RemoveFragment(fragment)

		control:SetHidden(true)
	end
end

function LiveReport:RefreshBg()
	local control = self.control
	local settings = self.settings

	local newwidth, newheight = control:GetDimensions()

	local bg = control:GetNamedChild("BG")
	local resizeFrame = control:GetNamedChild("ResizeFrame")

	bg:SetDimensions(newwidth, newheight)
	resizeFrame:SetDimensions(newwidth, newheight)
	resizeFrame:SetAnchorFill(control)

	control.sizes = { newwidth / settings.scale, newheight / settings.scale }
	bg.sizes = { newwidth / settings.scale, newheight / settings.scale }
	resizeFrame.sizes = { newwidth / settings.scale, newheight / settings.scale }
	resizeFrame:SetDimensionConstraints(
		newwidth / settings.scale * 0.5,
		newheight / settings.scale * 0.5,
		newwidth / settings.scale * 3,
		newheight / settings.scale * 3
	)
end

function LiveReport:GetTotalSize()
	local totalBlocks = 0
	for panelName, data in pairs(PANEL_DATA_BY_NAME) do
		if self.settings[panelName] then
			totalBlocks = totalBlocks + data.blockSize
		end
	end
	return totalBlocks
end

function LiveReport:Refresh()
	local settings = self.settings
	local layout = settings.layout or "Compact"
	local isSecondRow = false
	local totalWidth = self:GetTotalSize()
	local compactWidth

	local control = self.control
	control:GetNamedChild("ResizeFrame"):SetMouseEnabled(not settings.locked)
	control:SetMovable(not settings.locked)
	control:GetNamedChild("BG"):SetAlpha(settings.bgalpha / 100)

	if layout == "Compact" then
		compactWidth = zo_min(zo_round(zo_ceil(totalWidth) / 2), totalWidth - zo_floor(totalWidth / 2))
	end

	local currentSize = 0
	local anchorControl = self.control
	local panels = self.panels

	for i, panelLayout in ipairs(PANEL_DATA) do
		local name = panelLayout.name
		local panel = panels[name]

		if settings[name] then
			if panel == nil then
				panel = LiveReportPanel:New(name, self)
			end

			panel.active = true
			panel.control:SetHidden(false)

			local newSize = currentSize + panel.size
			local anchor

			if currentSize == 0 then
				anchor = anchorSchemes.First
				anchor[2] = anchorControl
				if layout == "Compact" then
					anchorSchemes.CompactRow2[2] = panel.control
				end
			elseif layout == "Compact" then
				if newSize <= compactWidth or isSecondRow then
					anchor = anchorSchemes[layout]
					anchor[2] = anchorControl
				else
					anchor = anchorSchemes.CompactRow2
					isSecondRow = true
				end
			elseif newSize <= totalWidth then
				anchor = anchorSchemes[layout]
				anchor[2] = anchorControl
			end

			panel:Refresh()
			panel:RefreshAnchor(anchor)

			currentSize = newSize
			anchorControl = panel.control
		elseif panel then
			panel.active = false
			panel.control:SetHidden(true)
		end
	end

	local function refreshBgDelayed()
		self:RefreshBg()
	end

	zo_callLater(refreshBgDelayed, 1)
end

function LiveReport:Resize(newScale)
	self.settings.scale = newScale
	self:Refresh()
	self:SavePosition()
end

function LiveReport:Update()
	if not self:IsEnabled() then -- TODO: bail when not in combat
		LiveReport:Toggle(false)
		return
	end

	for _, panel in pairs(self.panels) do
		if panel.active then
			panel:Update()
		end
	end
end

local isFileInitialized = false
function CMXint.InitializeLiveReport()
	if isFileInitialized == true then
		return true
	end
	logger = util.initSublogger("LiveReport")

	ui.LiveReport = LiveReport:New(CombatMetrics_LiveReport)
	ui.LiveReport:Refresh()

	local function LiveReportUpdate()
		ui.LiveReport:Update()
	end

	GetEventManager():RegisterForUpdate("CombatMetrics_LiveReport_Update", 500, LiveReportUpdate)

	isFileInitialized = true
	return true
end
