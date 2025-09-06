---@module 'CombatMetrics.CombatMetricsUI'

local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger
local db

-- Update the mini DPS meter

local function updateLiveReport(self, data)
	if data == nil then return end

	local livereport = self
	local DPSOut = data.DPSOut
	local DPSIn = data.DPSIn
	local HPSOut = data.HPSOut
	local HPSAOut = data.OHPSOut
	local HPSIn = data.HPSIn
	local dpstime = data.dpstime
	local hpstime = data.hpstime
	local groupDPSOut = data.groupDPSOut
	local groupDPSIn = data.groupDPSIn
	local groupHPSOut = data.groupHPSOut

	-- Bail out if there is no damage to report
	if (DPSOut == 0 and HPSOut == 0 and DPSIn == 0) or livereport:IsHidden() then return end

	local SDPS = 0
	local groupSDPS = 0

	if db.liveReport.damageOutSingle then
		local iconControl = livereport:GetNamedChild("DamageOutSingle"):GetNamedChild("Icon")
		local tooltipControl = livereport:GetNamedChild("DamageOutSingle"):GetNamedChild("Tooltip")
		local texture = "/esoui/art/icons/mapkey/mapkey_fightersguild.dds"
		local tooltip = SI_COMBAT_METRICS_LIVEREPORT_DPSSINGLE_TOOLTIP
		
		if data.bossfight then
			iconControl:SetTexture("esoui/art/tutorial/poi_groupboss_complete.dds")
			tooltip = SI_COMBAT_METRICS_LIVEREPORT_DPSBOSS_TOOLTIP
		end
		
		iconControl:SetTexture(texture)
		tooltipControl.tooltip[1] = tooltip
		SDPS = data.bossDPSOut
		groupSDPS = data.bossDPSOutGroup
	end

	local DPSString
	local HPSString
	local DPSInString
	local SDPSString
	local maxtime = zo_roundToNearest(zo_max(dpstime, hpstime), 0.1)
	local timeString = string.format("%d:%04.1f", maxtime/60, maxtime%60)

	-- maybe add data from group
	if db.recordgrp == true and (groupDPSOut > 0 or groupDPSIn > 0 or groupHPSOut > 0) then
		local dpsratio, hpsratio, idpsratio, sdpsratio = 0, 0, 0, 0
		if groupDPSOut > 0  then dpsratio  = (zo_floor(DPSOut / groupDPSOut * 1000) / 10) end
		if groupDPSIn > 0 then idpsratio = (zo_floor(DPSIn / groupDPSIn * 1000) / 10) end
		if groupSDPS > 0  then sdpsratio  = (zo_floor(SDPS / groupSDPS * 1000) / 10) end
		if groupHPSOut > 0 then hpsratio  = (zo_floor(HPSOut / groupHPSOut * 1000) / 10) end

		DPSString = zo_strformat(GetString(SI_COMBAT_METRICS_SHOW_XPS), DPSOut, groupDPSOut, dpsratio)
		DPSInString = zo_strformat(GetString(SI_COMBAT_METRICS_SHOW_XPS), DPSIn, groupDPSIn, idpsratio)
		HPSString = zo_strformat(GetString(SI_COMBAT_METRICS_SHOW_XPS), HPSOut, groupHPSOut, hpsratio)
		SDPSString = zo_strformat(GetString(SI_COMBAT_METRICS_SHOW_XPS), SDPS, groupSDPS, sdpsratio)
	else
		DPSString  = DPSOut
		DPSInString = DPSIn
		HPSString  = HPSOut
		SDPSString = SDPS
	end

	-- Update the values
	livereport:GetNamedChild("DamageOutSingle"):GetNamedChild("Label"):SetText( SDPSString )
	livereport:GetNamedChild("DamageOut"):GetNamedChild("Label"):SetText( DPSString )
	livereport:GetNamedChild("HealOut"):GetNamedChild("Label"):SetText( HPSString )
	livereport:GetNamedChild("HealOutAbsolute"):GetNamedChild("Label"):SetText( HPSAOut )
	livereport:GetNamedChild("DamageIn"):GetNamedChild("Label"):SetText( DPSInString )
	livereport:GetNamedChild("HealIn"):GetNamedChild("Label"):SetText( HPSIn )
	livereport:GetNamedChild("Time"):GetNamedChild("Label"):SetText( timeString )
end


local function resize(control, scale)
	if control:GetType() == CT_BACKDROP or control.sizes == nil and control.anchors == nil then return end
	local width, height = unpack(control.sizes)
	local maxwidth, maxheight = GuiRoot:GetDimensions()

	scale = zo_min(zo_max(scale or 1, 0.5), 3, maxwidth/width, maxheight/height)
	db.liveReport.scale = scale

	if width then control:SetWidth(width*scale) end
	if height then control:SetHeight(height*scale) end
	local fontcontrol = control:GetNamedChild("Font")

	if fontcontrol ~= nil then
		local font, size, style = unpack(fontcontrol.font)
		if size then size = tonumber(size) * (scale + 0.1)/1.2 end			-- Don't Scale fonts as much
		control:SetFont(string.format("%s|%s|%s", font, size, style))
	end

	for i = 1, control:GetNumChildren() do
		local child = control:GetChild(i)
		if child then resize(child, scale) end
	end
end

---@class LiveReportControl
local LiveReportControl = ZO_Object:Subclass()	-- holds all recent events + info to send on death

local LiveReportControlSizes = {
	["DamageOutSingle"] = 1,
	["DamageOut"] = 1,
	["HealOut"] = 1,
	["HealOutAbsolute"] = 0.57,
	["DamageIn"] = 1,
	["HealIn"] = 0.57,
	["Time"] = 0.43,
}

local LiveReportControls = {
	"DamageOutSingle",
	"DamageOut",
	"HealOut",
	"HealOutAbsolute",
	"DamageIn",
	"HealIn",
	"Time",
}

---@diagnostic disable-next-line: duplicate-set-field
function LiveReportControl:New(name)
	assert(LiveReportControlSizes[name], "Invalid module name for LiveReportControl!")
    local object = ZO_Object.New(self)
    object:Initialize(name)
    return object
end

function LiveReportControl:Initialize(name)
	local LiveReport = CombatMetrics_LiveReport
	local templateName = "CombatMetrics_LiveReport_" .. name

	local control = CreateControlFromVirtual(templateName, LiveReport, templateName)
	CMXf.storeOrigLayout(control)

	self.name = name
	self.control = control
	self.active = true
	self.size = LiveReportControlSizes[name]
	self.parent = LiveReport
	LiveReport.modules[name] = self
end

local anchorSchemes = {
	["First"] = {TOPLEFT, nil, TOPLEFT, 0, 0},
	["Horizontal"] = {LEFT, nil, RIGHT, 0, 0},
	["Vertical"] = {TOPLEFT, nil, BOTTOMLEFT, 0, 0},
	["Compact"] = {LEFT, nil, RIGHT, 0, 0},
	["CompactRow2"] = {TOPLEFT, nil, BOTTOMLEFT, 0, 0},
	
}

function LiveReportControl:Refresh(anchorControl)
	---@type Control
	local control = self.control
	local parent = self.parent
	local settings = parent.settings
	local scale = settings.scale

	control:ClearAnchors()

	local width, height = unpack(control.sizes)
	control:SetDimensions(width*scale, height*scale)
	control:SetAnchor(anchor[1], anchorControl, anchor[2], anchor[3]*scale, anchor[4]*scale)

	local label = self:GetNamedChild("Label")
	local alignment = settings.alignmentleft and TEXT_ALIGN_LEFT or TEXT_ALIGN_RIGHT
	label:SetHorizontalAlignment(alignment)

	local showGroupTooltip = db.recordgrp == true
	self:GetNamedChild("Tooltip").tooltip[2] = showGroupTooltip and SI_COMBAT_METRICS_LIVEREPORT_GROUP_TOOLTIP or nil

	self.last = self
end

---comment
---@param self TopLevelWindow
local function InitLiveReport(self)
	local settings = CMXint.settings.liveReport
	if settings.enabled == false then return end

	self.initilazed = true
	self.settings = settings
	self.modules = {}

	for _, name in ipairs(LiveReportControls) do
		if settings[name] == true then LiveReportControl:New(name) end
	end

	function self:SavePosition()
		local x, y = self:GetCenter()
		self.settings.pos_x = x
		self.settings.pos_y = y
	end

	self:ClearAnchors()
	self:SetAnchor(CENTER, nil , TOPLEFT, settings.pos_x, settings.pos_y)
    self:SetHandler("OnMoveStop", function () self:SavePosition() end)
	
	CMXf.storeOrigLayout(self)
	self.fragment = ZO_HUDFadeSceneFragment:New(self)

	function self:Toggle(value)
		if value == nil then value = self:IsHidden() end
		local fragment = self.fragment
		if value == true and SCENE_MANAGER then
			SCENE_MANAGER:GetScene("hud"):AddFragment( fragment )
			SCENE_MANAGER:GetScene("hudui"):AddFragment( fragment )
			SCENE_MANAGER:GetScene("siegeBar"):AddFragment( fragment )

			local currentScene = SCENE_MANAGER.currentScene and SCENE_MANAGER.currentScene.name or ""
			local isShownForCurrentScene = currentScene == "hud" or currentScene == "hudui" or currentScene == "siegeBar"
			self:SetHidden(not isShownForCurrentScene)
		else
			SCENE_MANAGER:GetScene("hud"):RemoveFragment( fragment )
			SCENE_MANAGER:GetScene("hudui"):RemoveFragment( fragment )
			SCENE_MANAGER:GetScene("siegeBar"):RemoveFragment( fragment )

			self:SetHidden(true)
		end
	end

	function self:RefreshBG()
		local newwidth, newheight = self:GetDimensions()

		local bg = self:GetNamedChild("BG")
		local resizeFrame = self:GetNamedChild("ResizeFrame")

		bg:SetDimensions(newwidth, newheight)
		resizeFrame:SetDimensions(newwidth, newheight)
		resizeFrame:SetAnchorFill(self)

		self.sizes = {newwidth/settings.scale, newheight/settings.scale}
		bg.sizes = {newwidth/settings.scale, newheight/settings.scale}
		resizeFrame.sizes = {newwidth/settings.scale, newheight/settings.scale}
		resizeFrame:SetDimensionConstraints(newwidth/settings.scale*0.5, newheight/settings.scale*0.5, newwidth/settings.scale*3, newheight/settings.scale*3)
	end

	function self:GetTotalSize()
		local totalBlocks = 0
		for _, module in pairs(self.modules) do
			if module.active then totalBlocks = totalBlocks + module.blocksize end
		end
		return totalBlocks
	end

	function self:Refresh()
		local totalWidth  = self:GetTotalSize()
		local layout = settings.layout or "Compact"

		if layout == "Compact" then 
			totalWidth = zo_min(zo_round(zo_ceil(totalWidth)  / 2), totalWidth-zo_floor(totalWidth/2))
		end

		local currentSize = 0
		local anchorControl = self
		local modules = self.modules

		for _, name in ipairs(LiveReportControls) do
			local module = modules[name]
			if module and module.active then
				local newSize = currentSize + module.size
				local anchor

				if currentSize == 0 then
					anchor = anchorSchemes.First
					anchor[2] = anchorControl
					if layout == "Compact" then anchorSchemes.CompactRow2[2] = module.control end
				elseif newSize < totalWidth then
					anchor = anchorSchemes[layout]
					anchor[2] = anchorControl
				else
					assert(layout == "Compact", "Unexpceted value during LiveReport refresh!")
					anchor = anchorSchemes.CompactRow2
				end

				LiveReportControl:Refresh(anchor)
				currentSize = newSize
				anchorControl = module.control
			end
		end
		zo_callLater(function() self:RefreshBG() end, 1)
	end

	function self:Resize(scale)
		for i = 1, self:GetNumChildren() do	-- dont resize liveReport!
			local child = self:GetChild(i)
			if child then resize(child, scale) end
		end
		self:Refresh()
	end

	self.Update = updateLiveReport
	self:Toggle(settings.enabled)
	self:Resize(settings.scale)
	self:GetNamedChild("ResizeFrame"):SetMouseEnabled(not settings.locked)
	self:SetMovable(not settings.locked)
	self:GetNamedChild("BG"):SetAlpha(settings.bgalpha/100)
end

local isFileInitialized = false
function CMXint.InitializeLiveReport()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("LiveReport")
	db = CMX.db

	InitLiveReport(CMX.internal.LiveReport) -- TODO: Directly pass init function.

    isFileInitialized = true
	return true
end