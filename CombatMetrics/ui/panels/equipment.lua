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

	function EquipmentPanel:RecoverEquipLine(parent, x, y)
		local icon = self:AcquireSharedControl(CT_TEXTURE)
		icon:ApplyPosition(parent, x, y, EQUIP_ROW_HEIGHT, EQUIP_ROW_HEIGHT)

		local icon2 = self:AcquireSharedControl(CT_TEXTURE)
		icon2:ApplyPosition(parent, x, y, EQUIP_ROW_HEIGHT, EQUIP_ROW_HEIGHT)

		local labelX = x + EQUIP_ROW_HEIGHT + 4
		local label = self:AcquireSharedControl(CT_LABEL)
		label:ApplyPosition(parent, labelX, y, 280, nil)
		---@diagnostic disable-next-line: undefined-field
		label:SetFont(ui.GetFont(ui.fontSize))
		---@diagnostic disable-next-line: undefined-field
		label:SetMouseEnabled(true)
		---@diagnostic disable-next-line: undefined-field
		label:SetLinkEnabled(true)
		---@diagnostic disable-next-line: undefined-field, missing-parameter
		label:SetHandler("OnMouseEnter", CMXint.ItemTooltip_OnMouseEnter)
		---@diagnostic disable-next-line: undefined-field, missing-parameter
		label:SetHandler("OnMouseExit", CMXint.ItemTooltip_OnMouseExit)
		---@diagnostic disable-next-line: undefined-field, missing-parameter
		label:SetHandler("OnLinkClicked", OnLinkClicked)

		local traitX = labelX + 280 + 4
		local trait = self:AcquireSharedControl(CT_LABEL)
		trait:ApplyPosition(parent, traitX, y, 100, nil)
		---@diagnostic disable-next-line: undefined-field
		trait:SetFont(ui.GetFont(ui.fontSize))

		local scale = self.settings.scale > 0 and self.settings.scale or 1
		local enchantX = traitX + 100 + 10
		local enchant = self:AcquireSharedControl(CT_LABEL)
		---@diagnostic disable-next-line: undefined-field
		enchant:SetFont(ui.GetFont(ui.fontSize))
		---@diagnostic disable-next-line: undefined-field
		enchant:SetParent(parent)
		---@diagnostic disable-next-line: undefined-field
		enchant:ClearAnchors()
		---@diagnostic disable-next-line: undefined-field
		enchant:SetAnchor(TOPLEFT, parent, TOPLEFT, enchantX * scale, y * scale)
		---@diagnostic disable-next-line: undefined-field
		enchant:SetAnchor(TOPRIGHT, parent, TOPRIGHT, -4 * scale, y * scale)
		---@diagnostic disable-next-line: undefined-field
		enchant:SetMouseEnabled(true)
		---@diagnostic disable-next-line: undefined-field
		enchant:SetLinkEnabled(true)
		---@diagnostic disable-next-line: undefined-field, missing-parameter
		enchant:SetHandler("OnMouseEnter", CMXint.ItemTooltip_OnMouseEnter)
		---@diagnostic disable-next-line: undefined-field, missing-parameter
		enchant:SetHandler("OnMouseExit", CMXint.ItemTooltip_OnMouseExit)
		---@diagnostic disable-next-line: undefined-field, missing-parameter
		enchant:SetHandler("OnLinkClicked", OnLinkClicked)

		return { icon = icon, icon2 = icon2, label = label, trait = trait, enchant = enchant }
	end

	function EquipmentPanel:Recover()
		self.equipLines = {}
		local yOffset = 4

		for i, rowData in ipairs(equipRows) do
			if i > 1 then
				yOffset = yOffset + EQUIP_ROW_HEIGHT + rowData[3]
			end
			self.equipLines[i] = self:RecoverEquipLine(self.control, 5, yOffset)
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
			label.itemLink = item == "" and nil or item

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
				enchant.itemLink = poison1
			elseif (slot == EQUIP_SLOT_BACKUP_MAIN or slot == EQUIP_SLOT_BACKUP_OFF) and poison2:len() > 0 then
				enchantString = poison2
				enchant.itemLink = poison2
			else
				_, enchantString, enchantDescription = GetItemLinkEnchantInfo(item)
				enchantString = enchantString:gsub(GetString(SI_COMBAT_METRICS_ENCHANTMENT_TRIM), "")
				enchant.enchantDescription = enchantDescription
				enchant.itemLink = ""
				local quality = GetEnchantQuality(item)
				enchantColor = { GetItemQualityColor(quality):UnpackRGBA() }
			end

			enchant:SetText(enchantString)
			enchant:SetColor(unpack(enchantColor))
		end
	end
end

function CMXint.ItemTooltip_OnMouseEnter(control)
	local itemLink = control.itemLink
	local enchantDescription = control.enchantDescription

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
