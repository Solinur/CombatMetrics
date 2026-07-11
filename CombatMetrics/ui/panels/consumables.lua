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

local GetFormattedAbilityIcon = util.GetFormattedAbilityIcon
local GetFormattedAbilityName = util.GetFormattedAbilityName
local GetFoodDrinkItemLinkFromAbilityId = CMXint.LibCombat2.GetFoodDrinkItemLinkFromAbilityId

local function valueOrder(t, a, b)
	return t[a] < t[b]
end

function CMXint.InitializeConsumablesPanel(control)
	---@class ConsumablesPanel: Panel
	local ConsumablesPanel = CMX.internal.PanelObject:New(control, "consumables")

	function ConsumablesPanel:Update(fightData)
		local control = self.control
		local mundusControl = control:GetNamedChild("Mundus")
		local drinksFoodsControl = control:GetNamedChild("DrinkFood")
		local potionsControl = control:GetNamedChild("Potions")

		if fightData == nil or fightData.calculated == nil or fightData.calculated.buildInfo == nil then
			mundusControl:SetHidden(true)
			drinksFoodsControl:SetHidden(true)
			potionsControl:SetHidden(true)
			return
		end

		local buildInfo = fightData.calculated.buildInfo
		self:UpdateItem("Mundus", buildInfo.mundus)
		self:UpdateItem("DrinkFood", buildInfo.drinkFood)
		self:UpdateItem("Potions", buildInfo.potions)
	end

	function ConsumablesPanel:UpdateItem(name, data)
		local numItems = NonContiguousCount(data)
		local control = self.control:GetNamedChild(name)

		if numItems == 0 then
			control:SetHidden(true)
		else
			local num = 0
			for key, _ in util.spairs(data, valueOrder) do
				num = num + 1
				local label, texture
				if name == "Mundus" then
					label = GetFormattedAbilityName(key)
					texture = GetFormattedAbilityIcon(key)
				elseif name == "DrinkFood" then
					label = GetFoodDrinkItemLinkFromAbilityId(key)
					texture = GetItemLinkIcon(label)
				else
					label = key
					texture = GetItemLinkIcon(key)
				end

				local nameControl = control:GetNamedChild("Name" .. num) --[[@as LabelControl]]
				nameControl:SetText(label)

				local iconControl = control:GetNamedChild("Icon" .. num) --[[@as TextureControl]]
				iconControl:SetTexture(texture)

				if num >= 2 then
					break
				end
			end

			local icon1 = control:GetNamedChild("Icon1")
			local iconSize = control:GetNamedChild("Icon2"):GetWidth()
			icon1:ClearAnchors()
			if numItems == 1 then
				icon1:SetDimensions(1.3 * iconSize, 1.3 * iconSize)
				---@diagnostic disable-next-line: missing-parameter
				icon1:SetAnchor(LEFT)
				control:GetNamedChild("Name2"):SetHidden(true)
				control:GetNamedChild("Icon2"):SetHidden(true)
			else
				icon1:SetDimensions(iconSize, iconSize)
				---@diagnostic disable-next-line: missing-parameter
				icon1:SetAnchor(TOPLEFT)
				control:GetNamedChild("Name2"):SetHidden(false)
				control:GetNamedChild("Icon2"):SetHidden(false)
			end
			control:SetHidden(false)
		end
	end
end

local isFileInitialized = false
function CMXint.InitializeConsumables()
	if isFileInitialized == true then
		return false
	end
	logger = util.initSublogger("Consumables")

	isFileInitialized = true
	return true
end
