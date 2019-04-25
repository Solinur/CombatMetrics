
local LIB_NAME = "LibVotansAddonList"
local addon = LibStub and LibStub:NewLibrary(LIB_NAME, 1.4) or { }

if not addon then
	return
	-- already loaded and no upgrade necessary
end

local em = GetEventManager()
local AddOnManager = GetAddOnManager()

function addon:Initialize()
	local list = ADD_ON_MANAGER.list
	if list.dataTypes[1] then
		list.dataTypes[1].setupCallback = ADD_ON_MANAGER:GetRowSetupFunction()
	else
		ZO_ScrollList_AddDataType(list, 1, "ZO_AddOnRow", 30, ADD_ON_MANAGER:GetRowSetupFunction())
	end

	ADD_ON_MANAGER.isDirty = true
end

addon.libKeepEnabledList = {
	["LibStub"] = true,
	["LibVotansAddonList"] = true
}

function addon:DisableAllLibraries()
	local masterList, libKeepEnabledList = ADD_ON_MANAGER.masterList, addon.libKeepEnabledList
	local data
	for i = 1, #masterList do
		data = masterList[i]
		if data.isLibrary then
			AddOnManager:SetAddOnEnabled(data.index, libKeepEnabledList[data.addOnFileName] == true)
		end
	end
end

local function createToolbar(self)
	self.toolBar = CreateControlFromVirtual("$(parent)ToolBar", self, "ZO_MenuBarTemplate")
	self.toolBar:ClearAnchors()
	self.toolBar:SetAnchor(RIGHT, self, RIGHT, -5, 0)

	ZO_MenuBar_OnInitialized(self.toolBar)
	local barData =
	{
		buttonPadding = - 4,
		normalSize = 28,
		downSize = 28,
		animationDuration = DEFAULT_SCENE_TRANSITION_TIME,
		buttonTemplate = "ZO_MenuBarButtonTemplateWithTooltip",
	}
	ZO_MenuBar_SetData(self.toolBar, barData)
	ZO_MenuBar_SetClickSound(self.toolBar, "DEFAULT_CLICK")

	local function CreateButtonData(name, mode, normal, highlight, disabled)
		return {
			activeTabText = name,
			categoryName = name,
			tooltip = name,

			descriptor = mode,
			normal = normal,
			pressed = normal,
			highlight = highlight,
			disabled = disabled,
			callback = function(tabData)
				addon:DisableAllLibraries()
				ADD_ON_MANAGER:RefreshData()
				ZO_MenuBar_ClearSelection(self.toolBar)
			end,
		}
	end

	local mainAddonsTab = CreateButtonData(
	SI_VOTANS_ADDONLIST_DISABLE_ALL_LIBS,
	1,
	"esoui/art/buttons/edit_cancel_up.dds",
	"esoui/art/buttons/edit_cancel_over.dds",
	"esoui/art/buttons/edit_cancel_disabled.dds"
	)
	ZO_MenuBar_AddButton(self.toolBar, mainAddonsTab)

	ZO_MenuBar_ClearSelection(self.toolBar)
end

local function setupHeaderFunction(control, data)
	control:SetText(data.text)
	control:SetMouseEnabled(false)

	if not control.toolBar then createToolbar(control) end
end

local function setupDividerFunction(control, data)
	control:SetHeight(30)
end

do
	local LIB_ROW_ID = 10
	local orgSort
	local orgSortScrollList = ZO_AddOnManager.SortScrollList
	local scrollData
	local function newSort(...)
		scrollData = ...
		table.sort = orgSort
	end
	local function sortBySortable(a, b)
		return a.data.sortableName < b.data.sortableName
	end
	local function sortByLib(a, b)
		return a.data.isLibrary == b.data.isLibrary and sortBySortable(a, b) or(not a.data.isLibrary and b.data.isLibrary)
	end
	function ZO_AddOnManager:SortScrollList()
		ZO_ScrollList_AddDataType(self.list, LIB_ROW_ID, "ZO_GameMenu_LabelHeader", 30, setupHeaderFunction)
		ZO_ScrollList_AddDataType(self.list, LIB_ROW_ID + 1, "ZO_DynamicHorizontalDivider", 30, setupDividerFunction)
		orgSort, table.sort = table.sort, newSort
		orgSortScrollList(self)
		table.sort(scrollData, sortByLib)
		local hasLibs = false
		for i = #scrollData, 1, -1 do
			if scrollData[i].data.isLibrary then
				hasLibs = true
			else
				if hasLibs then
					local dataIndex = i + 1
					addon.libSectionDataIndex = dataIndex

					table.insert(scrollData, dataIndex, ZO_ScrollList_CreateDataEntry(LIB_ROW_ID, { text = GetString(SI_VOTANS_ADDONLIST_LIBS) }))
					table.insert(scrollData, dataIndex, ZO_ScrollList_CreateDataEntry(LIB_ROW_ID + 1, { }))
				else
					addon.libSectionDataIndex = 0
				end
				break
			end
		end
	end
end

do
	local orgBuildMasterList = ZO_AddOnManager.BuildMasterList
	-- ZOS could know/call this "nested manifest". All nested manifests are libs. Never seen a main addon nesting a main addon.
	-- In case of having the "nested" information: isPatch = depends on one non-nested addon. Else: isLibrary = isNested and not depends on non-nested.
	local isLibrary
	if LibStub then
		function isLibrary(item)
			local data = item.data
			if data.isLibrary == nil then
				data.isLibrary =(LibStub(data.addOnFileName, LibStub.SILENT) or data.addOnFileName:match("^[Ll]ib[%u%d]%a")) ~= nil
			end
		end
	else
		function isLibrary(item)
			local data = item.data
			if data.isLibrary == nil then
				data.isLibrary = data.addOnFileName:match("^[Ll]ib[%u%d]%a") ~= nil
			end
		end
	end
	function ZO_AddOnManager:BuildMasterList()
		orgBuildMasterList(self)
		local scrollData = ZO_ScrollList_GetDataList(self.list)
		self.masterList = self.masterList or { }
		local masterList = self.masterList
		ZO_ClearNumericallyIndexedTable(masterList)

		local nameToLib = { }
		local data
		for i = 1, #scrollData do
			isLibrary(scrollData[i])
			data = scrollData[i].data
			masterList[i] = data
			nameToLib[data.addOnFileName] = data
			data.sortableName = data.strippedAddOnName:upper()
			data.expandable = false
		end
		local name, i, dependency, depCount, isPatchFor, dependsOn
		for index = 1, #masterList do
			data = masterList[index]
			i = data.index
			name, depCount = nil, 0
			dependsOn = { }
			data.dependsOn = dependsOn
			for j = 1, AddOnManager:GetAddOnNumDependencies(i) do
				dependency = AddOnManager:GetAddOnDependencyInfo(i, j)
				dependency = nameToLib[dependency]
				if dependency and not dependency.isLibrary then
					if not name then
						name = dependency.sortableName
						isPatchFor = dependency
					end
					depCount = depCount + 1
				end
				if dependency then dependsOn[#dependsOn + 1] = dependency end
			end

			data.isPatch = depCount >= 1
			if data.isPatch then
				data.isLibrary = false
				data.isPatchFor = isPatchFor
				data.sortableName = string.format("%s-%s", name, data.sortableName)
			end
		end
	end
end

do
	local orgGetRowSetupFunction = ZO_AddOnManager.GetRowSetupFunction
	local WARNING_COLOR = ZO_ColorDef:New("C5C23E")
	local attentionIcon = zo_iconFormatInheritColor(ZO_KEYBOARD_NEW_ICON, 28, 28)

	local function AddLine(tooltip, text, color, alignment)
		local r, g, b = color:UnpackRGB()
		tooltip:AddLine(text, "", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, alignment, alignment ~= TEXT_ALIGN_LEFT)
	end

	local function AddLineCenter(tooltip, text, color)
		if not color then color = ZO_TOOLTIP_DEFAULT_COLOR end
		AddLine(tooltip, text, color, TEXT_ALIGN_CENTER)
	end

	local function AddLineTitle(tooltip, text, color)
		if not color then color = ZO_SELECTED_TEXT end
		local r, g, b = color:UnpackRGB()
		tooltip:AddLine(text, "ZoFontHeader3", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
	end

	local function AddLineSubTitle(tooltip, text, color)
		if not color then color = ZO_SELECTED_TEXT end
		local r, g, b = color:UnpackRGB()
		tooltip:AddLine(text, "ZoFontWinH5", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
	end

	local function AddLinePath(tooltip, text, color)
		if not color then color = ZO_HINT_TEXT end
		local r, g, b = color:UnpackRGB()
		tooltip:AddLine(text, "ZoFontWinH4", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
	end

	-- zo_strformat converts the dot in version numbers into comma (localization of decimal numbers, but wrong here)
	local formatDep = GetString(SI_ADDON_MANAGER_DEPENDENCIES):gsub("<<1>>", "%%s")
	local formatLocation = "|t32:32:esoui/art/treeicons/gamepad/gp_store_indexicon_dlc.dds:inheritColor|t"
	local function onMouseEnter(control)
		local data = ZO_ScrollList_GetData(control)
		if not data then return end
		InitializeTooltip(ItemTooltip, control, LEFT, -7, -30, BOTTOMRIGHT)
		ItemTooltip:SetMinHeaderRowHeight(0)
		ItemTooltip:SetMinHeaderRows(1)

		ZO_ItemIconTooltip_OnAddGameData(ItemTooltip, TOOLTIP_GAME_DATA_ITEM_ICON, data.isLibrary and "esoui/art/journal/journal_tabicon_cadwell_up.dds" or "esoui/art/inventory/inventory_tabicon_misc_up.dds")

		if data.isLibrary then
			ItemTooltip:AddHeaderLine(zo_strformat(SI_ITEM_FORMAT_STR_TEXT1, GetString(SI_VOTANS_ADDONLIST_LIB)), "ZoFontWinH5", 1, TOOLTIP_HEADER_SIDE_LEFT, ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
		end
		AddLineTitle(ItemTooltip, data.addOnName)
		ItemTooltip:AddVerticalPadding(-9)

		local version = AddOnManager.GetAddOnVersion and AddOnManager:GetAddOnVersion(data.index) or 0
		if version > 0 then
			ItemTooltip:AddVerticalPadding(-3)
			AddLineSubTitle(ItemTooltip, string.format("Version %i", version), ZO_TOOLTIP_DEFAULT_COLOR)
			ItemTooltip:AddVerticalPadding(-6)
		end

		ZO_Tooltip_AddDivider(ItemTooltip)

		if data.addOnAuthorByLine ~= "" then
			AddLineSubTitle(ItemTooltip, data.addOnAuthorByLine)
		end

		if data.addOnDescription ~= "" then
			AddLineCenter(ItemTooltip, data.addOnDescription)
		end

		if AddOnManager.GetAddOnRootDirectoryPath then
			local path = AddOnManager:GetAddOnRootDirectoryPath(data.index):gsub("^user:/", formatLocation):gsub("/$", "")
			AddLinePath(ItemTooltip, path)
		end

		if data.isOutOfDate then
			AddLineCenter(ItemTooltip, GetString(SI_VOTANS_ADDONLIST_OUTDATED), WARNING_COLOR)
		end

		if data.hasDependencyError then
			local dependencyText = { }
			local i = data.index
			local dependencyName, dependencyActive
			for j = 1, AddOnManager:GetAddOnNumDependencies(i) do
				dependencyName, dependencyActive = AddOnManager:GetAddOnDependencyInfo(i, j)

				if not dependencyActive then
					if #dependencyName == 0 then dependencyName = "not installed" end
					dependencyName = ZO_ERROR_COLOR:Colorize(dependencyName)
				end
				dependencyText[#dependencyText + 1] = dependencyName
			end
			table.sort(dependencyText)
			AddLineCenter(ItemTooltip, formatDep:format(table.concat(dependencyText, ", ")))
		end

		ZO_ItemIconTooltip_OnAddGameData(ItemTooltip, TOOLTIP_GAME_DATA_STOLEN, false)
	end
	local function onMouseChildEnter(control)
		return onMouseEnter(control:GetParent())
	end
	local function onMouseExit(control)
		ClearTooltip(ItemTooltip)
	end

	function ZO_AddOnManager:GetRowSetupFunction()
		local orgSetup = orgGetRowSetupFunction(self)
		local function modify(control, data)
			local indent = data.isPatch and 12 or 0
			local expandButton = control:GetNamedChild("ExpandButton")
			expandButton:SetHidden(true)
			local enableButton = control:GetNamedChild("Enabled")
			enableButton:SetAnchor(TOPLEFT, nil, TOPLEFT, 7 + indent, 7)
			enableButton:SetHidden(data.isOutOfDate and not AddOnManager:GetLoadOutOfDateAddOns())
			if data.hasDependencyError then
				ZO_TriStateCheckButton_SetState(enableButton, TRISTATE_CHECK_BUTTON_UNCHECKED)
			end

			local state = control:GetNamedChild("State")
			state:SetDimensions(28, 28)
			state:ClearAnchors()
			state:SetAnchor(TOPRIGHT, nil, TOPRIGHT, -7, 1)
			local stateText
			-- out-dated libs coming from out-dated main-addons. If an out-dated lib is used by an up-to-date addon, it is still working.
			-- if it is a patch, but its parent is not enabled, show out-of-date warning only.
			if (data.isOutOfDate and not data.isLibrary) or(data.hasDependencyError and(not data.isPatch or(data.isPatch and data.isPatchFor.addOnEnabled))) then
				stateText = attentionIcon
				if not data.hasDependencyError and AddOnManager:GetLoadOutOfDateAddOns() or(data.isPatch and not data.isPatchFor.addOnEnabled) then
					stateText = WARNING_COLOR:Colorize(stateText)
				else
					stateText = ZO_ERROR_COLOR:Colorize(stateText)
				end
			else
				stateText = ""
			end
			state:SetText(stateText)

			local name = control:GetNamedChild("Name")
			name:SetWidth(385 - indent)
			local author = control:GetNamedChild("Author")
			author:SetWidth(372)

			if data.isPatch and not data.isPatchFor.addOnEnabled then
				local color = ZO_DEFAULT_DISABLED_COLOR
				name:SetColor(color:UnpackRGBA())
				author:SetColor(color:UnpackRGBA())
			end

			if not control.votanAddonLib then
				control.votanAddonLib = true
				ZO_PreHookHandler(control, "OnMouseEnter", onMouseEnter)
				ZO_PreHookHandler(control, "OnMouseExit", onMouseExit)
				control:SetMouseEnabled(true)

				local name = control:GetNamedChild("Name")
				ZO_PreHookHandler(name, "OnMouseEnter", onMouseChildEnter)
				ZO_PreHookHandler(name, "OnMouseExit", onMouseExit)
			end
		end
		local function setupAddonRow(...)
			orgSetup(...)
			return modify(...)
		end
		return setupAddonRow
	end
end

do
	local function checkDependsOn(data)
		-- assume success to break recursion
		data.addOnEnabled = true

		local success = true
		local other
		for i = 1, #data.dependsOn do
			other = data.dependsOn[i]

			if not other.addOnEnabled then
				checkDependsOn(other)
			end
		end
		AddOnManager:SetAddOnEnabled(data.index, true)
		-- Verify success
		local state
		data.addOnEnabled, state = select(5, AddOnManager:GetAddOnInfo(data.index))
		success = success and state == ADDON_STATE_ENABLED
		return success
	end
	local function CheckPreRequirements(self, control, checkState)
		local row = control:GetParent()

		if checkState ~= TRISTATE_CHECK_BUTTON_CHECKED then return true end
		return checkDependsOn(row.data)
	end
	local function refresh(self)
		return self:RefreshData()
	end
	local orgOnEnabledButtonClicked = ZO_AddOnManager.OnEnabledButtonClicked
	function ZO_AddOnManager.OnEnabledButtonClicked(...)
		if CheckPreRequirements(...) then
			return orgOnEnabledButtonClicked(...)
		else
			refresh(...)
			PlaySound(SOUNDS.GENERAL_ALERT_ERROR)
		end
	end
end

function ZO_AddOnManager:OnExpandButtonClicked(row)
	-- Disabled.
end

ZO_AddOnsLoadOutOfDateAddOnsText:SetText(GetString(SI_ADDON_MANAGER_LOAD_OUT_OF_DATE_ADDONS))


function addon:SetSection(mode)
	local function endAnim()
		ZO_MenuBar_ClearSelection(self.sectionBar)
	end
	if mode == 1 then
		local value = ADD_ON_MANAGER.list.scrollbar:GetValue()
		if value > 0 then
			ZO_ScrollList_ScrollRelative(ADD_ON_MANAGER.list, - value, endAnim)
		else
			endAnim()
		end
	else
		ZO_ScrollList_ScrollDataToCenter(ADD_ON_MANAGER.list, self.libSectionDataIndex, endAnim)
	end
end

do
	local function InitializeModeBar(self)
		self.sectionBar = CreateControlFromVirtual("$(parent)SectionBar", ZO_AddOns, "ZO_MenuBarTemplate")
		self.sectionBar:ClearAnchors()
		self.sectionBar:SetAnchor(BOTTOMRIGHT, ZO_AddOnsDivider, TOPRIGHT, -6, -5)

		ZO_MenuBar_OnInitialized(self.sectionBar)
		local barData =
		{
			buttonPadding = 6,
			normalSize = 42,
			downSize = 51,
			animationDuration = DEFAULT_SCENE_TRANSITION_TIME,
			buttonTemplate = "ZO_MenuBarButtonTemplateWithTooltip",
		}
		ZO_MenuBar_SetData(self.sectionBar, barData)
		ZO_MenuBar_SetClickSound(self.sectionBar, "DEFAULT_CLICK")

		local function CreateButtonData(name, mode, normal, highlight, disabled)
			return {
				activeTabText = name,
				categoryName = name,
				tooltip = name,

				descriptor = mode,
				normal = normal,
				pressed = normal,
				highlight = highlight,
				disabled = disabled,
				callback = function(tabData)
					self:SetSection(mode)
				end,
			}
		end

		local mainAddonsTab = CreateButtonData(
		SI_WINDOW_TITLE_ADDON_MANAGER,
		1,
		"esoui/art/inventory/inventory_tabicon_misc_up.dds",
		"esoui/art/inventory/inventory_tabicon_misc_over.dds",
		"esoui/art/inventory/inventory_tabicon_misc_disabled.dds"
		)
		ZO_MenuBar_AddButton(self.sectionBar, mainAddonsTab)

		local libAddonsTab = CreateButtonData(
		SI_VOTANS_ADDONLIST_LIBS,
		2,
		"esoui/art/journal/journal_tabicon_cadwell_up.dds",
		"esoui/art/journal/journal_tabicon_cadwell_over.dds",
		"esoui/art/journal/journal_tabicon_cadwell_disabled.dds"
		)
		ZO_MenuBar_AddButton(self.sectionBar, libAddonsTab)
		ZO_MenuBar_SetDescriptorEnabled(self.sectionBar, 2, self.libSectionDataIndex ~= 0)

		ZO_MenuBar_ClearSelection(self.sectionBar)
	end

	ZO_AddOnsLoadOutOfDateAddOnsText:SetMouseEnabled(true)

	local function showOutOfDateAddonsTooltip()
		ZO_Tooltips_ShowTextTooltip(ZO_AddOnsLoadOutOfDateAddOns, BOTTOM, GetString(SI_VOTANS_ADDONLIST_LOAD_OUT_OF_DATE_ADDONS_DESC))
	end
	ZO_AddOnsLoadOutOfDateAddOns:SetHandler("OnMouseEnter", showOutOfDateAddonsTooltip)
	ZO_AddOnsLoadOutOfDateAddOnsText:SetHandler("OnMouseEnter", showOutOfDateAddonsTooltip)
	ZO_AddOnsLoadOutOfDateAddOns:SetHandler("OnMouseExit", ZO_Tooltips_HideTextTooltip)
	ZO_AddOnsLoadOutOfDateAddOnsText:SetHandler("OnMouseExit", ZO_Tooltips_HideTextTooltip)

	local function initTabs(oldState, newState)
		if (newState == SCENE_FRAGMENT_SHOWN) then
			ADDONS_FRAGMENT:UnregisterCallback("StateChange", initTabs)
			if ZO_ScrollList_EnoughEntriesToScroll(ADD_ON_MANAGER.list) then
				InitializeModeBar(addon)
			end
		end
	end
	ADDONS_FRAGMENT:RegisterCallback("StateChange", initTabs)
end

local function OnAddonLoaded(event, name)
	if name ~= LIB_NAME and name ~= "AddonSelector" then return end
	em:UnregisterForEvent(LIB_NAME, EVENT_ADD_ON_LOADED)
	if name == LIB_NAME then addon:Initialize() end
end

em:RegisterForEvent(LIB_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)
