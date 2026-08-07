-- Scene management for CMX view switching.
---@class CMX
local CMX = CombatMetrics
---@class CMXint
local CMXint = CMX.internal
---@class CMXui
local ui = CMXint.ui

local VIEW_SCENE_KEYS = { "fightStats", "info", "combatLog", "graph", "fightList" }

---@param panel Panel
---@param key string
---@return boolean
local function panelInScene(panel, key)
	if panel.scenes == nil then
		return false
	end
	for _, s in ipairs(panel.scenes) do
		if s == key then
			return true
		end
	end
	return false
end

local function applyLayout(key)
	for _, panel in pairs(ui.panels) do
		if panel.scenes then
			panel:SetHidden(not panelInScene(panel, key))
		end
	end
end

--- Whether any panel is registered for this view. `graph` and `fightList` have none yet, so their
--- scenes render nothing but the title, menu and info row -- the view cycle skips those.
---@param key string
---@return boolean
function ui.ViewHasPanels(key)
	for _, panel in pairs(ui.panels) do
		if panelInScene(panel, key) then
			return true
		end
	end
	return false
end

---@return boolean
function ui.IsAnyViewShowing()
	for _, scene in pairs(CMXint.scenes.views) do
		if scene:IsShowing() then
			return true
		end
	end
	return false
end

local function CreateViewScene(key, reportFragment)
	local sceneName = "CMX_VIEW_" .. key:upper() .. "_SCENE"
	local scene = ZO_Scene:New(sceneName, SCENE_MANAGER)
	scene:AddFragment(reportFragment)
	scene:RegisterCallback("StateChange", function(_, newState)
		if newState == SCENE_SHOWN then
			ui.sceneTransitioning = true
			applyLayout(key)
			ui.sceneTransitioning = false
			CMXint.fightReport:Update()
		end
	end)
	CMXint.scenes.views[key] = scene
	CMXint.viewSceneNames[key] = sceneName
	return scene
end

local isFileInitialized = false
function CMXint.InitializeViewScenes()
	if isFileInitialized then
		return true
	end

	CMXint.scenes.views = {}
	CMXint.viewSceneNames = {}

	local reportFragment = CMXint.scenes.reportFragment
	for _, key in ipairs(VIEW_SCENE_KEYS) do
		CreateViewScene(key, reportFragment)
	end

	isFileInitialized = true
	return true
end
