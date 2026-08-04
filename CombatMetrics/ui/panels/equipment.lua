---@diagnostic disable: inject-field
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

-- { slot, iconPath, gapBefore }  gapBefore=0 for the first row; larger values mark group breaks
local equipRows = {

	{ EQUIP_SLOT_MAIN_HAND, "EsoUI/Art/CharacterWindow/gearslot_mainhand.dds", 0 },
	{ EQUIP_SLOT_OFF_HAND, "EsoUI/Art/CharacterWindow/gearslot_offhand.dds", 2 },
	{ EQUIP_SLOT_BACKUP_MAIN, "EsoUI/Art/CharacterWindow/gearslot_mainhand.dds", 8 },
	{ EQUIP_SLOT_BACKUP_OFF, "EsoUI/Art/CharacterWindow/gearslot_offhand.dds", 2 },
	{ EQUIP_SLOT_HEAD, "EsoUI/Art/CharacterWindow/gearslot_head.dds", 10 },
	{ EQUIP_SLOT_SHOULDERS, "EsoUI/Art/CharacterWindow/gearslot_shoulders.dds", 2 },
	{ EQUIP_SLOT_CHEST, "EsoUI/Art/CharacterWindow/gearslot_chest.dds", 2 },
	{ EQUIP_SLOT_HAND, "EsoUI/Art/CharacterWindow/gearslot_hands.dds", 2 },
	{ EQUIP_SLOT_WAIST, "EsoUI/Art/CharacterWindow/gearslot_belt.dds", 2 },
	{ EQUIP_SLOT_LEGS, "EsoUI/Art/CharacterWindow/gearslot_legs.dds", 2 },
	{ EQUIP_SLOT_FEET, "EsoUI/Art/CharacterWindow/gearslot_feet.dds", 2 },
	{ EQUIP_SLOT_NECK, "EsoUI/Art/CharacterWindow/gearslot_neck.dds", 10 },
	{ EQUIP_SLOT_RING1, "EsoUI/Art/CharacterWindow/gearslot_ring.dds", 2 },
	{ EQUIP_SLOT_RING2, "EsoUI/Art/CharacterWindow/gearslot_ring.dds", 2 },
}

local armorcolors = {

	[ARMORTYPE_NONE] = { 1, 1, 1, 1 },
	[ARMORTYPE_HEAVY] = { 1, 0.3, 0.3, 1 },
	[ARMORTYPE_MEDIUM] = { 0.3, 1, 0.3, 1 },
	[ARMORTYPE_LIGHT] = { 0.3, 0.3, 1, 1 },
}

local EQUIP_ROW_HEIGHT = 22
local EQUIP_LEFT_MARGIN = 5
local LABEL_WIDTH = 280
local TRAIT_WIDTH = 100

local subIdToQuality = {}

local function GetEnchantQuality(itemLink) -- From Enchanted Quality (Rhyono, votan)
	local itemId, itemIdSub, enchantSub = itemLink:match("|H[^:]+:item:([^:]+):([^:]+):[^:]+:[^:]+:([^:]+):")
	if not itemId then
		return 0
	end

	enchantSub = tonumber(enchantSub)
	if enchantSub == 0 and not IsItemLinkCrafted(itemLink) then
		local hasSet = GetItemLinkSetInfo(itemLink, false)
		if hasSet then
			enchantSub = tonumber(itemIdSub)
		end -- For non-crafted sets, the "built-in" enchantment has the same quality as the item itself
	end

	if enchantSub and enchantSub > 0 then
		local quality = subIdToQuality[enchantSub]
		if not quality then
			-- Create a fake itemLink to get the quality from built-in function
			local itemLink =
				string.format("|H1:item:%i:%i:50:0:0:0:0:0:0:0:0:0:0:0:0:1:1:0:0:10000:0|h|h", itemId, enchantSub)
			quality = GetItemLinkFunctionalQuality(itemLink)
			subIdToQuality[enchantSub] = quality
		end

		return quality
	end

	return 0
end

local function OnLinkClicked(_, linkText, button)
	ClearTooltip(ItemTooltip)
	ZO_LinkHandler_OnLinkClicked(linkText, button)
end

function CMXint.InitializeEquipmentPanel(control)
	local EquipmentPanel = CMX.internal.PanelObject:New(control, "equipment")
	EquipmentPanel.scenes = { "info" }

	-- Unlike the other row panels, the container here is only an ownership and positioning parent: an
	-- equipment row has two independent tooltip targets (the item and its enchantment or poison), so
	-- the mouse handlers stay on those two labels rather than moving up to the row.
	function EquipmentPanel:RecoverEquipLine(line)
		local container = line.container

		line.icon = container:AcquireSharedControl(CT_TEXTURE)
		line.icon:ApplyPosition(container, 0, 0, EQUIP_ROW_HEIGHT, EQUIP_ROW_HEIGHT)

		line.icon2 = container:AcquireSharedControl(CT_TEXTURE)
		line.icon2:ApplyPosition(container, 0, 0, EQUIP_ROW_HEIGHT, EQUIP_ROW_HEIGHT)

		local labelX = EQUIP_ROW_HEIGHT + 4
		local label = container:AcquireSharedControl(CT_LABEL)
		label:ApplyPosition(container, labelX, 0, LABEL_WIDTH, nil)
		label:ApplyFont(ui.fontSize)
		label:SetMouseEnabled(true)
		label:SetLinkEnabled(true)
		label:SetHandler("OnMouseEnter", CMXint.ItemTooltip_OnMouseEnter)
		label:SetHandler("OnMouseExit", CMXint.ItemTooltip_OnMouseExit)
		label:SetHandler("OnLinkClicked", OnLinkClicked)
		line.label = label

		local traitX = labelX + LABEL_WIDTH + 4
		line.trait = container:AcquireSharedControl(CT_LABEL)
		line.trait:ApplyPosition(container, traitX, 0, TRAIT_WIDTH, nil)
		line.trait:ApplyFont(ui.fontSize)

		local enchant = container:AcquireSharedControl(CT_LABEL)
		enchant:ApplyStretch(container, traitX + TRAIT_WIDTH + 10, 0, 4)
		enchant:ApplyFont(ui.fontSize)
		enchant:SetMouseEnabled(true)
		enchant:SetLinkEnabled(true)
		enchant:SetHandler("OnMouseEnter", CMXint.ItemTooltip_OnMouseEnter)
		enchant:SetHandler("OnMouseExit", CMXint.ItemTooltip_OnMouseExit)
		enchant:SetHandler("OnLinkClicked", OnLinkClicked)
		line.enchant = enchant
	end

	function EquipmentPanel:Recover()
		local lines = self.equipLines

		if lines == nil then
			lines = {}
			self.equipLines = lines

			for i in ipairs(equipRows) do
				local name = string.format("%sRow%d", control:GetName(), i)
				lines[i] = { container = self:CreateRowContainer(name) }
			end
		end

		local scale = CMXint.settings.fightReport.scale
		local rowWidth = control:GetWidth() / scale - EQUIP_LEFT_MARGIN
		local yOffset = 4

		for i, rowData in ipairs(equipRows) do
			if i > 1 then
				yOffset = yOffset + EQUIP_ROW_HEIGHT + rowData[3]
			end

			local line = lines[i]
			self:RecoverEquipLine(line)
			line.container:ApplyPosition(control, EQUIP_LEFT_MARGIN, yOffset, rowWidth, EQUIP_ROW_HEIGHT)
		end
	end

	function EquipmentPanel:Clear()
		if not self.equipLines then
			return
		end
		for i = 1, #self.equipLines do
			local line = self.equipLines[i]
			line.label:SetText("")
			line.trait:SetText("")
			line.enchant:SetText("")
		end
	end

	function EquipmentPanel:Update()
		local fightData = self:GetCurrentFightData()
		if fightData == nil then
			return
		end
		local charData = fightData.charData
		if charData == nil then
			return
		end

		local equipdata = charData and charData.equip or {}

		local poison1 = equipdata[EQUIP_SLOT_POISON]
		local poison2 = equipdata[EQUIP_SLOT_BACKUP_POISON]

		for i, slotData in ipairs(equipRows) do
			local slot = slotData[1]
			local texture = slotData[2]

			local line = self.equipLines[i]
			local label = line.label
			local icon = line.icon
			local icon2 = line.icon2
			local trait = line.trait
			local enchant = line.enchant

			local item = equipdata[slot] or ""

			local armortype = GetItemLinkArmorType(item)
			local color = item:len() > 0 and armorcolors[armortype] or { 0, 0, 0, 1 }
			local color2 = item:len() > 0 and { 1, 1, 1, 1 } or { 0.5, 0.5, 0.5, 1 }

			label:SetText(item)
			label.data.itemLink = item == "" and nil or item

			icon:SetTexture(texture)
			icon:SetColor(unpack(color))
			icon:SetBlendMode(TEX_BLEND_MODE_ADD)

			icon2:SetTexture(texture)
			icon2:SetColor(unpack(color2))
			icon2:SetBlendMode(TEX_BLEND_MODE_ADD)

			local traitType, _ = GetItemLinkTraitInfo(item)
			local traitName = traitType > 0 and GetString("SI_ITEMTRAITTYPE", traitType) or ""

			trait:SetText(traitName)

			local enchantString, enchantDescription
			local enchantColor = { 1, 1, 1, 1 }

			if (slot == EQUIP_SLOT_MAIN_HAND or slot == EQUIP_SLOT_OFF_HAND) and poison1:len() > 0 then
				enchantString = poison1
				enchant.data.itemLink = poison1
			elseif (slot == EQUIP_SLOT_BACKUP_MAIN or slot == EQUIP_SLOT_BACKUP_OFF) and poison2:len() > 0 then
				enchantString = poison2
				enchant.data.itemLink = poison2
			else
				_, enchantString, enchantDescription = GetItemLinkEnchantInfo(item)
				enchantString = enchantString:gsub(GetString(SI_COMBAT_METRICS_ENCHANTMENT_TRIM), "")
				enchant.data.enchantDescription = enchantDescription
				enchant.data.itemLink = ""
				local quality = GetEnchantQuality(item)
				enchantColor = { GetItemQualityColor(quality):UnpackRGBA() }
			end

			enchant:SetText(enchantString)
			enchant:SetColor(unpack(enchantColor))
		end
	end
end

function CMXint.ItemTooltip_OnMouseEnter(control)
	local itemLink = control.data.itemLink
	local enchantDescription = control.data.enchantDescription

	if itemLink ~= "" and itemLink ~= nil then
		InitializeTooltip(ItemTooltip, control:GetParent(), TOPLEFT, 5, 0, TOPRIGHT)
		ItemTooltip:SetLink(itemLink)
	elseif enchantDescription ~= "" and enchantDescription ~= nil then
		InitializeTooltip(SkillTooltip, control:GetParent(), TOPLEFT, 5, 0, TOPRIGHT)
		SkillTooltip:AddVerticalPadding(5)
		SkillTooltip:AddLine(enchantDescription)
	end
end

function CMXint.ItemTooltip_OnMouseExit(control)
	ClearTooltip(ItemTooltip)
	ClearTooltip(SkillTooltip)
end

local isFileInitialized = false
function CMXint.InitializeEquipment()
	if isFileInitialized == true then
		return false
	end
	logger = util.initSublogger("Equipment")

	isFileInitialized = true
	return true
end
