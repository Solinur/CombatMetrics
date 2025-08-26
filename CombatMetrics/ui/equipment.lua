local CMX = CombatMetrics
local CMXint = CMX.internal
local CMXf = CMXint.functions
local CMXd = CMXint.data
local logger

local equipslots = {

	{EQUIP_SLOT_MAIN_HAND, "EsoUI/Art/CharacterWindow/gearslot_mainhand.dds"},
	{EQUIP_SLOT_OFF_HAND, "EsoUI/Art/CharacterWindow/gearslot_offhand.dds"},
	{EQUIP_SLOT_BACKUP_MAIN, "EsoUI/Art/CharacterWindow/gearslot_mainhand.dds"},
	{EQUIP_SLOT_BACKUP_OFF, "EsoUI/Art/CharacterWindow/gearslot_offhand.dds"},
	{EQUIP_SLOT_HEAD, "EsoUI/Art/CharacterWindow/gearslot_head.dds"},
	{EQUIP_SLOT_SHOULDERS, "EsoUI/Art/CharacterWindow/gearslot_shoulders.dds"},
	{EQUIP_SLOT_CHEST, "EsoUI/Art/CharacterWindow/gearslot_chest.dds"},
	{EQUIP_SLOT_HAND, "EsoUI/Art/CharacterWindow/gearslot_hands.dds"},
	{EQUIP_SLOT_WAIST, "EsoUI/Art/CharacterWindow/gearslot_belt.dds"},
	{EQUIP_SLOT_LEGS, "EsoUI/Art/CharacterWindow/gearslot_legs.dds"},
	{EQUIP_SLOT_FEET, "EsoUI/Art/CharacterWindow/gearslot_feet.dds"},
	{EQUIP_SLOT_NECK, "EsoUI/Art/CharacterWindow/gearslot_neck.dds"},
	{EQUIP_SLOT_RING1, "EsoUI/Art/CharacterWindow/gearslot_ring.dds"},
	{EQUIP_SLOT_RING2, "EsoUI/Art/CharacterWindow/gearslot_ring.dds"},
}

local armorcolors = {

	[ARMORTYPE_NONE] = {1, 1, 1, 1},
	[ARMORTYPE_HEAVY] = {1, 0.3, 0.3, 1},
	[ARMORTYPE_MEDIUM] = {0.3, 1, 0.3, 1},
	[ARMORTYPE_LIGHT] = {0.3, 0.3, 1, 1},
}
local subIdToQuality = {}

local function GetEnchantQuality(itemLink)	-- From Enchanted Quality (Rhyono, votan)
	local itemId, itemIdSub, enchantSub = itemLink:match("|H[^:]+:item:([^:]+):([^:]+):[^:]+:[^:]+:([^:]+):")
	if not itemId then return 0 end

	enchantSub = tonumber(enchantSub)
	if enchantSub == 0 and not IsItemLinkCrafted(itemLink) then
		local hasSet = GetItemLinkSetInfo(itemLink, false)
		if hasSet then enchantSub = tonumber(itemIdSub) end -- For non-crafted sets, the "built-in" enchantment has the same quality as the item itself
	end

	if enchantSub > 0 then
		local quality = subIdToQuality[enchantSub]
		if not quality then
			-- Create a fake itemLink to get the quality from built-in function
			local itemLink = string.format("|H1:item:%i:%i:50:0:0:0:0:0:0:0:0:0:0:0:0:1:1:0:0:10000:0|h|h", itemId, enchantSub)
			quality = GetItemLinkQuality(itemLink)
			subIdToQuality[enchantSub] = quality
		end

		return quality
	end

	return 0
end

local EquipmentPanel = CMXint.PanelObject:New("Equipment", CombatMetrics_Report_SetupPanelEquipmentPanel)

function EquipmentPanel:Update(fightData)
	if fightData == nil then return end
	local charData = fightData.charData
	if charData == nil then return end

	local control = self.control
	local equipdata = charData and charData.equip or {}

	local poison1 = equipdata[EQUIP_SLOT_POISON]
	local poison2 = equipdata[EQUIP_SLOT_BACKUP_POISON]

	for i, slotData in ipairs(equipslots) do

		local slot = slotData[1]
		local texture = slotData[2]

		local equipline = control:GetNamedChild("EquipLine" .. i)
		local label = equipline:GetNamedChild("ItemLink")
		local icon = equipline:GetNamedChild("Icon")
		local icon2 = equipline:GetNamedChild("Icon2")	-- textures are added twice since icons are so low in contrast
		local trait = equipline:GetNamedChild("Trait")
		local enchant = equipline:GetNamedChild("Enchant")

		local item = equipdata[slot] or ""

		local armortype = GetItemLinkArmorType(item)
		local color = item:len() > 0 and armorcolors[armortype] or {0, 0, 0, 1}
		local color2 = item:len() > 0 and {1, 1, 1, 1} or {0.5, 0.5, 0.5, 1}

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
		local enchantColor = {1, 1, 1, 1}

		if (slot == EQUIP_SLOT_MAIN_HAND or slot == EQUIP_SLOT_OFF_HAND) and poison1:len() > 0 then
			enchantString = poison1
			enchant.itemLink = poison1
		elseif (slot == EQUIP_SLOT_BACKUP_MAIN or slot == EQUIP_SLOT_BACKUP_OFF) and poison2:len() > 0 then
			enchantString = poison2
			enchant.itemLink = poison2
		else
			_, enchantString, enchantDescription = GetItemLinkEnchantInfo(item)
			enchantString = enchantString:gsub(GetString(SI_COMBAT_METRICS_ENCHANTMENT_TRIM), "")
			local enchantId = GetItemLinkAppliedEnchantId(item)
			enchant.enchantDescription = enchantDescription
			enchant.itemLink = ""
			local quality = GetEnchantQuality(item)
			enchantColor = {GetItemQualityColor(quality):UnpackRGBA()}
		end

		enchant:SetText(enchantString)
		enchant:SetColor(unpack(enchantColor))
		-- GetEnchantProcAbilityId(GetItemLinkAppliedEnchantId())
		-- GetItemLinkAppliedEnchantId
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
function CMXint.InitializeEquipmentPanel()
	if isFileInitialized == true then return false end
	logger = CMXf.initSublogger("Equipment")

    isFileInitialized = true
	return true
end