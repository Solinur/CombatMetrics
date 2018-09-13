local strings = {

-- Fonts

	SI_COMBAT_METRICS_LANG = "en",
	SI_COMBAT_METRICS_STD_FONT = "EsoUI/Common/Fonts/Univers57.otf", -- EsoUi/Common/Fonts/Univers57.otf
	SI_COMBAT_METRICS_BOLD_FONT = "EsoUI/Common/Fonts/Univers67.otf", -- EsoUi/Common/Fonts/Univers67.otf

	SI_COMBAT_METRICS_FONT_SIZE_SMALL = "14", -- 14
	SI_COMBAT_METRICS_FONT_SIZE = "15", -- 15
	SI_COMBAT_METRICS_FONT_SIZE_TITLE = "20", -- 20

-- Colors

	SI_COMBAT_METRICS_SEP_COLOR = "FFAAAAAA",
	SI_COMBAT_METRICS_HEALTH_COLOR = "FFDE6531",
	SI_COMBAT_METRICS_MAGICKA_COLOR = "FF5EBDE7",
	SI_COMBAT_METRICS_STAMINA_COLOR = "FFA6D852",
	SI_COMBAT_METRICS_ULTIMATE_COLOR = "FFffe785",
	
-- Functionality

	SI_COMBAT_METRICS_ENCHANTMENT_TRIM = " Enchantment", -- this will be frmoved for the enchantments shown in infopanel
	
-- Ingame (Use ZOS Tranlations, change only for languages which are not supported)

	SI_COMBAT_METRICS_MAGICKA = GetString(SI_COMBATMECHANICTYPE0),  -- Magicka 
	SI_COMBAT_METRICS_STAMINA = GetString(SI_ATTRIBUTES3),  -- Stamina 
	SI_COMBAT_METRICS_ULTIMATE = GetString(SI_COMBATMECHANICTYPE10),  -- Ultimate 

-- UI&Control

	SI_COMBAT_METRICS_SHOW_XPS = "<<1>> / <<2>> (<<3>>%)",
	SI_COMBAT_METRICS_CALC = "Calculating...", -- Calculating...
	SI_COMBAT_METRICS_FINALISING = "Finalising...", -- Finalizing...
	SI_COMBAT_METRICS_GROUP = "Group", -- Group
	SI_COMBAT_METRICS_SELECTION = "Selection", -- Selection

	SI_COMBAT_METRICS_BASE_REG = "Base Regeneration", -- Base Regeneration
	SI_COMBAT_METRICS_DRAIN = "Drain", -- Drain
	SI_COMBAT_METRICS_UNKNOWN = "Unknown", -- Unknown

	SI_COMBAT_METRICS_BLOCKS = "Blocks", -- Blocks
	SI_COMBAT_METRICS_CRITS = "Crits", -- Crits

	SI_COMBAT_METRICS_DAMAGE = "Damage", -- Damage
	SI_COMBAT_METRICS_DAMAGEC = "Damage: ", -- Damage
	SI_COMBAT_METRICS_HIT = "Hit",
	SI_COMBAT_METRICS_DPS = "DPS",

	SI_COMBAT_METRICS_HEALING = "Healing", -- Healing
	SI_COMBAT_METRICS_HEALS = "Heals",
	SI_COMBAT_METRICS_HPS = "HPS",
	
	SI_COMBAT_METRICS_EDIT_TITLE = "Double click to edit fight name",

	SI_COMBAT_METRICS_DAMAGE_CAUSED = "Damage Caused", -- Damage Caused
	SI_COMBAT_METRICS_DAMAGE_RECEIVED = "Damage Received", -- Damage Received
	SI_COMBAT_METRICS_HEALING_DONE = "Healing Done", -- Healing Done
	SI_COMBAT_METRICS_HEALING_RECEIVED = "Healing Recieved", -- Healing Recieved

	SI_COMBAT_METRICS_TOGGLE_FIGHTSTATS = "Fight Stats", -- Fight Stats
	SI_COMBAT_METRICS_TOGGLE_COMBAT_LOG = "Combat Log", -- Combat Log
	SI_COMBAT_METRICS_TOGGLE_GRAPH = "Graph", -- Graph
	SI_COMBAT_METRICS_TOGGLE_INFO = "Info", -- Info
	SI_COMBAT_METRICS_TOGGLE_SETTINGS = "Options", -- Settings
	
	SI_COMBAT_METRICS_SHOWIDS = "Show IDs", -- Show IDs for units, buffs and abilities
	SI_COMBAT_METRICS_HIDEIDS = "Hide IDs", -- Hide IDs for units, buffs and abilities
	
	SI_COMBAT_METRICS_POSTDPS = "Post DPS/HPS",
	SI_COMBAT_METRICS_POSTSINGLEDPS = "Post single target DPS",
	SI_COMBAT_METRICS_POSTSMARTDPS = "Post boss target DPS",
	SI_COMBAT_METRICS_POSTMULTIDPS = "Post total DPS",
	SI_COMBAT_METRICS_POSTALLDPS = "Post single and total DPS",
	SI_COMBAT_METRICS_POSTHPS = "Post HPS",
	
	SI_COMBAT_METRICS_SETTINGS = "Addon Settings",
	SI_COMBAT_METRICS_FEEDBACK = "Send Feedback / Donate",
	
	SI_COMBAT_METRICS_RECALCULATE = "Recalculate Fight",
	SI_COMBAT_METRICS_SMOOTH = "Smooth: %d s",
	
	SI_COMBAT_METRICS_FEEDBACK_MAIL = "Send Note",
	SI_COMBAT_METRICS_FEEDBACK_GOLD = "Donate 5000g",
	SI_COMBAT_METRICS_FEEDBACK_GOLD2 = "Donate 50000g",
	SI_COMBAT_METRICS_FEEDBACK_ESOUI = "Site (ESOUI)",
	SI_COMBAT_METRICS_FEEDBACK_PP = "PayPal",
	SI_COMBAT_METRICS_FEEDBACK_TEXT = "If you found a bug, have a request or a suggestion, or simply wish to donate, send a mail.",

	SI_COMBAT_METRICS_STORAGE_FULL = "The storage file is full. The fight you want to save needs <<1>> MB. Delete a fight to free some space or increase the allowed space in the settings!", -- The storage file is full. Delete a fight to free some space!

	SI_COMBAT_METRICS_PREVIOUS_FIGHT = "Previous Fight", -- Previous Fight
	SI_COMBAT_METRICS_NEXT_FIGHT = "Next Fight", -- Next Fight
	SI_COMBAT_METRICS_MOST_RECENT_FIGHT = "Most Recent Fight", -- Most Recent Fight
	SI_COMBAT_METRICS_LOAD_FIGHT = "Load Fight", -- Load Fight
	SI_COMBAT_METRICS_SAVE_FIGHT = "Click: Save fight", -- Click: Save fight
	SI_COMBAT_METRICS_SAVE_FIGHT2 = "Shift+Click: Save fight with combat log", -- Shift+Click: Save fight with combat log
	SI_COMBAT_METRICS_DELETE_COMBAT_LOG = "Delete Combat Log", -- Delete Combat Log
	SI_COMBAT_METRICS_DELETE_FIGHT = "Delete Fight", -- Delete Fight

	SI_COMBAT_METRICS_RECENT_FIGHT = "Recent Fights", -- Recent Fights
	SI_COMBAT_METRICS_DURATION = "Duration", -- Duration
	SI_COMBAT_METRICS_CHARACTER = "Character", -- Character
	SI_COMBAT_METRICS_ZONE = "Zone", -- Zone
	SI_COMBAT_METRICS_TIME = "Time", -- Time
	SI_COMBAT_METRICS_TIMEC = "Time: ", -- Time: 

	SI_COMBAT_METRICS_SHOW = "Show", -- Show
	SI_COMBAT_METRICS_DELETE = "Delete", -- Delete

	SI_COMBAT_METRICS_SAVED_FIGHTS = "Saved Fights", -- Saved Fights

	SI_COMBAT_METRICS_ACTIVE_TIME = "Active Time: ", -- Active Time: 
	SI_COMBAT_METRICS_ZERO_SEC = "0 s", -- 0 s
	SI_COMBAT_METRICS_IN_COMBAT = "In Combat: ", -- In Combat: 

	SI_COMBAT_METRICS_PLAYER = "Player", -- Player

	SI_COMBAT_METRICS_TOTAL = " Total: ", -- Total: 
	SI_COMBAT_METRICS_NORMAL = "Normal: ", -- Normal: 
	SI_COMBAT_METRICS_CRITICAL = "Critical: ", -- Critical: 
	SI_COMBAT_METRICS_BLOCKED = "Blocked: ", -- Blocked: 
	SI_COMBAT_METRICS_SHIELDED = "Shielded: ", -- Shielded: 

	SI_COMBAT_METRICS_HITS = "Hits", -- Hits
	SI_COMBAT_METRICS_NORM = "Norm", -- Norm

	SI_COMBAT_METRICS_RESOURCES = "Resources",  -- Resources

	SI_COMBAT_METRICS_STATS = "Stats",  -- Stats
	SI_COMBAT_METRICS_AVE = "Avg",  -- Average
	SI_COMBAT_METRICS_AVERAGE = "Average",  -- Average
	SI_COMBAT_METRICS_NORMAL_HITS = "Normal Hits",  -- Average
	SI_COMBAT_METRICS_MAX = "Max",  -- Maximum
	SI_COMBAT_METRICS_MIN = "Min",  -- Maximum

	SI_COMBAT_METRICS_STATS_MAGICKA1 = "Max Magicka:",  -- Max Magicka:
	SI_COMBAT_METRICS_STATS_MAGICKA2 = "Spell Damage:",  -- Spell Damage:
	SI_COMBAT_METRICS_STATS_MAGICKA3 = "Spell Critical:",  -- Spell Critical:
	SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT3 = "%.1f %%",  -- %.1f %%
	SI_COMBAT_METRICS_STATS_MAGICKA4 = "Critical Damage:",  -- Critical Damage:
	SI_COMBAT_METRICS_STATS_MAGICKA5 = "Spell Penetration:",  -- Spell Penetration:
	SI_COMBAT_METRICS_STATS_MAGICKA6 = "Overpenetration:",  -- Overpenetration:
	SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT6 = "%.1f %%",  -- %.1f %%

	SI_COMBAT_METRICS_STATS_STAMINA1 = "Max Stamina:",  -- Max Stamina:
	SI_COMBAT_METRICS_STATS_STAMINA2 = "Weapon Damage:",  -- Weapon Damage:
	SI_COMBAT_METRICS_STATS_STAMINA3 = "Weapon Critical:",  -- Weapon Critical:
	SI_COMBAT_METRICS_STATS_STAMINA_FORMAT3 = "%.1f %%",  -- Spell Critical:
	SI_COMBAT_METRICS_STATS_STAMINA4 = "Critical Damage:",  -- Critical Damage:
	SI_COMBAT_METRICS_STATS_STAMINA5 = "Phys. Penetration:",  -- Physical Penetration:
	SI_COMBAT_METRICS_STATS_STAMINA6 = "Overpenetration:",  -- Overpenetration:
	SI_COMBAT_METRICS_STATS_STAMINA_FORMAT6 = "%.1f %%",  -- %.1f %%

	SI_COMBAT_METRICS_STATS_HEALTH1 = "Max Health:",  -- Max Magicka:
	SI_COMBAT_METRICS_STATS_HEALTH2 = "Physical Resist.:",  -- Physical Resist.:
	SI_COMBAT_METRICS_STATS_HEALTH3 = "Spell Resistance:",  -- Spell Resistance:
	SI_COMBAT_METRICS_STATS_HEALTH4 = "Critical Resist.:",  -- Critical Resist.:
	SI_COMBAT_METRICS_STATS_HEALTH_FORMAT4 = "%.1f %%",  -- Critical Resist.:

	SI_COMBAT_METRICS_COMBAT_LOG = "Combat Log",  -- Combat Log

	SI_COMBAT_METRICS_GOTO_PREVIOUS = "Go to previous pages",  -- Go to previous pages
	SI_COMBAT_METRICS_PAGE = "Page <<1>>",  -- Page 
	SI_COMBAT_METRICS_GOTO_NEXT = "Go to next pages",  -- Go to next pages

	SI_COMBAT_METRICS_TOGGLE_HEAL = "Toggle received heal events",  -- Toggle received heal events
	SI_COMBAT_METRICS_TOGGLE_DAMAGE = "Toggle received damage events",  -- Toggle received damage events

	SI_COMBAT_METRICS_TOGGLE_YOUR_HEAL = "Toggle your healing events",  -- Toggle your healing events
	SI_COMBAT_METRICS_TOGGLE_YOUR_DAMAGE = "Toggle your damage events",  -- Toggle your damage events

	SI_COMBAT_METRICS_TOGGLE_BUFFIN_EVENTS = "Toggle incoming buff events",  -- Toggle buff events
	SI_COMBAT_METRICS_TOGGLE_BUFFOUT_EVENTS = "Toggle outbound buff events",  -- Toggle buff events
	SI_COMBAT_METRICS_TOGGLE_GROUPBUFFIN_EVENTS = "Toggle incoming groupbuff events",  -- Toggle buff events
	SI_COMBAT_METRICS_TOGGLE_GROUPBUFFOUT_EVENTS = "Toggle outbound groupbuff events",  -- Toggle buff events
	SI_COMBAT_METRICS_TOGGLE_RESOURCE_EVENTS = "Toggle resource events",  -- Toggle resource events
	SI_COMBAT_METRICS_TOGGLE_STATS_CHANGE_EVENTS = "Toggle stats change events",  -- Toggle stats change events
	SI_COMBAT_METRICS_TOGGLE_MESSAGE_CHANGE_EVENTS = "Toggle info events i.e. weapon swap",  -- Toggle info events i.e. weapon swap
	SI_COMBAT_METRICS_TOGGLE_SKILL_USE_EVENTS = "Toggle info about used skills",  -- Toggle info about used skills

	SI_COMBAT_METRICS_DEBUFF_IN = "(De-)Buffs\nIn",  -- (De-)Buffs\nIn (\n is newline,
	SI_COMBAT_METRICS_DEBUFF_OUT = "(De-)Buffs\nOut",  -- (De-,Buffs\nOut
	SI_COMBAT_METRICS_MAGICKA_PM = "Magicka\n +/-",  -- Magicka\n +/-
	SI_COMBAT_METRICS_STAMINA_PM = "Stamina\n +/-",  -- Stamina\n +/-
	SI_COMBAT_METRICS_RESOURCES_PM = "Resources\n +/-",  -- Resources\n +/-

	SI_COMBAT_METRICS_BUFF = "Buff",  -- Buff
	SI_COMBAT_METRICS_SHARP = "#",  -- #
	SI_COMBAT_METRICS_BUFFCOUNT_TT = "Player / Overall",  -- Player / Overall
	SI_COMBAT_METRICS_UPTIME = "Uptime",  -- Uptime
	SI_COMBAT_METRICS_UPTIME_TT = "Player % / Overall %",  -- Player % / Overall %

	SI_COMBAT_METRICS_REGENERATION = "Regeneration",  --  Source
	SI_COMBAT_METRICS_CONSUMPTION = "Consumption",  --  Consumption
	SI_COMBAT_METRICS_PM_SEC = "±/s",  -- ±/s
	SI_COMBAT_METRICS_TARGET = "Target",  -- Target
	SI_COMBAT_METRICS_PERCENT = "%",  -- %
	SI_COMBAT_METRICS_UNITDPS_TT = "Real DPS, e.g. the damage per second between your first and your last hit to that target",  -- %

	SI_COMBAT_METRICS_ABILITY = "Ability",  -- Ability
	SI_COMBAT_METRICS_PER_HITS = "/Hits",  -- /Hits
	SI_COMBAT_METRICS_CRITS_PER = "Crit %",  -- Crit %
	
	SI_COMBAT_METRICS_FAVOURITE_ADD = "Add to Favourites", -- Add to Favourites NEW
	SI_COMBAT_METRICS_FAVOURITE_REMOVE = "Remove from Favourites", -- Remove from Favourites NEW
	
	SI_COMBAT_METRICS_SKILL = "Skill", -- "Skill"
	
	SI_COMBAT_METRICS_BAR = "Bar ", -- Total Time Between Skills: NEW
	SI_COMBAT_METRICS_AVERAGEC = "Average: ", -- Total Time Between Skills: NEW
	
	SI_COMBAT_METRICS_SKILLTIME_LABEL2 = "< W / S", -- as in Weapon / Skill
	SI_COMBAT_METRICS_SKILLTIME_LABEL3 = "W / S >", -- as in Weapon / Skill
	
	SI_COMBAT_METRICS_SKILLTIME_TT1 = "Number of casts", -- "Number of uses of this skill"
	SI_COMBAT_METRICS_SKILLTIME_TT2 = "Time between the last weapon / skill use and the useage of the ability.", -- "Time between the last weapon / skill use and the useage of the ability."
	SI_COMBAT_METRICS_SKILLTIME_TT3 = "Time between the ability and the next useage of the weapon / skill .", -- "Time between the ability and the next useage of the weapon / skill ."
	SI_COMBAT_METRICS_SKILLTIME_TT4 = "Average time between subsequent uses of this skill", -- "Average time between the uses of this skill"

	SI_COMBAT_METRICS_SAVED_DATA = "Saved Data", -- "Saved Data"
	
-- Menus

	SI_COMBAT_METRICS_MENU_PROFILES = "Profiles",  -- Profiles

	SI_COMBAT_METRICS_MENU_AC_NAME = "Use accountwide settings",  -- Use accountwide settings
	SI_COMBAT_METRICS_MENU_AC_TOOLTIP = "If enabled all chars of an account will share their settings",  -- If enabled all chars of an account will share their settings

	SI_COMBAT_METRICS_MENU_GS_NAME = "General Settings",  -- General Settings
	
	SI_COMBAT_METRICS_MENU_FH_NAME = "Fight History",  -- Fight History
	SI_COMBAT_METRICS_MENU_FH_TOOLTIP = "Number of recent fights to save",  -- Number of recent fights to save	
	
	SI_COMBAT_METRICS_MENU_SVSIZE_NAME = "Saved Fight Memory",  -- Saved Fight Memory
	SI_COMBAT_METRICS_MENU_SVSIZE_TOOLTIP = "Maximum memory size for saved fights in MB",  -- Maximum memory size for saved fights in MB
	SI_COMBAT_METRICS_MENU_SVSIZE_WARNING = "Use with caution! Lots of saved data significantly increase loading times. If the file gets too large, the client might crash when attempting to load it.", -- Use with caution! Lots of saved data significantly increase loading times. If the file gets too large, the client might crash when attempting to load it.
	
	SI_COMBAT_METRICS_MENU_BOSSFIGHTS_NAME = "Keep Boss Fights",  -- Keep Boss Fights
	SI_COMBAT_METRICS_MENU_BOSSFIGHTS_TOOLTIP = "Delete trash fights first before deleting boss fights when limit of fights is reached",  -- Delete trash fights first before deleting boss fights when limit of fights is reached
	
	SI_COMBAT_METRICS_MENU_MG_NAME = "Monitor Group Damage",  -- Monitor Group Damage
	SI_COMBAT_METRICS_MENU_MG_TOOLTIP = "Monitor the events of the whole group",  -- Monitor the events of the whole group
	
	SI_COMBAT_METRICS_MENU_STACKS_NAME = "Show stacks of buffs",  -- Monitor the events of the whole group
	SI_COMBAT_METRICS_MENU_STACKS_TOOLTIP = "Show individual stacks in the buff panel",  -- Monitor the events of the whole group

	SI_COMBAT_METRICS_MENU_GL_NAME = "Monitor Damage in large groups",  -- Monitor Damage in large groups
	SI_COMBAT_METRICS_MENU_GL_TOOLTIP = "Monitor group damage in large groups (more than 4 group members)",  -- Don't Monitor Group Damage in Large Groups

	SI_COMBAT_METRICS_MENU_LM_NAME = "Light Mode", -- Light Mode
	SI_COMBAT_METRICS_MENU_LM_TOOLTIP = "When in light mode, combat metrics will only calculate the DPS/HPS in the live report window. No statistics will be calculated and the big report window will be disabled",  -- When in light mode, combat metrics will only calculate the DPS/HPS in the live report window. No statistics will be calculated and the big report window will be disabled

	SI_COMBAT_METRICS_MENU_NOPVP_NAME = "Turn off in Cyrodil", -- Turn off in PVP
	SI_COMBAT_METRICS_MENU_NOPVP_TOOLTIP = "Turns all fight logging off in Cyrodil",  -- Turns all fight logging off in Cyrodil

	SI_COMBAT_METRICS_MENU_LMPVP_NAME = "Light Mode in Cyrodil",  -- Light Mode in PVP
	SI_COMBAT_METRICS_MENU_LMPVP_TOOLTIP = "Swiches to light mode in Cyrodil. When in light mode, Combat Metrics will only calculate the DPS/HPS in the live report window. No statistics will be calculated and the big report window will be disabled", -- Swiches to light mode in PVP areas. When in light mode, combat metrics will only calculate the DPS/HPS in the live report window. No statistics will be calculated and the big report window will be disabled

	SI_COMBAT_METRICS_MENU_ASCC_NAME = "Auto Select Channel",  -- Auto Screenshot
	SI_COMBAT_METRICS_MENU_ASCC_TOOLTIP = "Automatically select the channel when posting DPS/HPS to chat. When in group the /group chat is used otherwise the /say chat.",  -- Automatically take a Screenshot when opening the Report window
	SI_COMBAT_METRICS_MENU_AS_NAME = "Auto Screenshot",  -- Auto Screenshot
	SI_COMBAT_METRICS_MENU_AS_TOOLTIP = "Automatically take a Screenshot when opening the Report window",  -- Automatically take a Screenshot when opening the Report window
	SI_COMBAT_METRICS_MENU_ML_NAME = "Minimum fight length for screenshot",  -- Minimum fight length for screenshot
	SI_COMBAT_METRICS_MENU_ML_TOOLTIP = "Minimum fight length in s for auto screenshot",  -- Minimum fight length in s for auto screenshot
	SI_COMBAT_METRICS_MENU_SF_NAME = "Scale of Fight Report Window",  -- Scale of Fight Report Window
	SI_COMBAT_METRICS_MENU_SF_TOOLTIP = "Adjusts the size of all elements of the Fightreport Window",  -- Adjusts the size of all elements of the Fightreport Window

	SI_COMBAT_METRICS_MENU_RESPEN_NAME = "Resistance and Penetration",  -- Live Report Window NEW
	SI_COMBAT_METRICS_MENU_CRUSHER = "Crusher",  -- Crusher NEW
	SI_COMBAT_METRICS_MENU_CRUSHER_TOOLTIP = "Resistance reduction due to debuff from Crusher glyph. For maxlevel gold glyph: standard: 1622, infused: 2108",  -- Resistance reduction due to debuff from Crusher glyph. For maxlevel gold glyph: standard: 1622, infused: 1946 NEW
	SI_COMBAT_METRICS_MENU_MOBRESISTANCE = "Target resistance",  -- Target Resistance NEW
	SI_COMBAT_METRICS_MENU_MOBRESISTANCE_TOOLTIP = "Target resistance that is assumed for overpenetration calculation",  -- Target resistance that is assumed for overpenetration calculation NEW
	
	SI_COMBAT_METRICS_MENU_LR_NAME = "Live Report Window",  -- Live Report Window
	SI_COMBAT_METRICS_MENU_ENABLE_NAME = "Enable",  -- Enable
	SI_COMBAT_METRICS_MENU_ENABLE_TOOLTIP = "Enable Live Report Window which shows DPS & HPS during combat",  -- Enable Live Report Window which shows DPS & HPS during combat
	
	SI_COMBAT_METRICS_MENU_LR_LOCK = "Lock",  -- Lock NEW
	SI_COMBAT_METRICS_MENU_LR_LOCK_TOOLTIP = "Lock the Live Report Window, so it can't be moved",  --  Lock the Live Report Window, so it can't be moved NEW
	
	SI_COMBAT_METRICS_MENU_LR_ALIGNMENT = "Use left-aligned numbers",
	SI_COMBAT_METRICS_MENU_LR_ALIGNMENT_TOOLTIP = "Sets positioning of Damage/Heal/etc. numbers for the Live Report Window to left-aligned",
	
	SI_COMBAT_METRICS_MENU_LAYOUT_NAME = "Layout",  -- Layout
	SI_COMBAT_METRICS_MENU_LAYOUT_TOOLTIP = "Select the Layout of the Live Report Window",  -- Select the Layout of the Live Report Window
	SI_COMBAT_METRICS_MENU_SCALE_NAME = "Scale",  -- Scale
	SI_COMBAT_METRICS_MENU_SCALE_TOOLTIP = "Scale of the Live report window.",  -- Scale of the Live report window.
	
	SI_COMBAT_METRICS_MENU_SHOW_BG_NAME = "Show Background",  -- Show Background OLD
	SI_COMBAT_METRICS_MENU_SHOW_BG_TOOLTIP = "Show the Background og the Live Report Window",  -- Show the Background og the Live Report Window OLD
	
	SI_COMBAT_METRICS_MENU_BGALPHA_NAME = "Background Opacity",  -- Show Background NEW
	SI_COMBAT_METRICS_MENU_BGALPHA_TOOLTIP = "Set the Opacity of the Background",  -- Set the Opacity of the Background NEW
	
	SI_COMBAT_METRICS_MENU_SHOW_DPS_NAME = "Show DPS",  -- Show DPS
	SI_COMBAT_METRICS_MENU_SHOW_DPS_TOOLTIP = "Show DPS you deal in Live Report Window",  -- Show DPS you deal in Live Report Window
	SI_COMBAT_METRICS_MENU_SHOW_SDPS_NAME = "Show single target DPS",  -- Show DPS
	SI_COMBAT_METRICS_MENU_SHOW_SDPS_TOOLTIP = "Show single target DPS you deal in Live Report Window",  -- Show DPS you deal in Live Report Window
	SI_COMBAT_METRICS_MENU_SHOW_HPS_NAME = "Show HPS",  -- Show HPS
	SI_COMBAT_METRICS_MENU_SHOW_HPS_TOOLTIP = "Show HPS you cast in Live Report Window",  -- Show HPS you cast in Live Report Window
	SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_NAME = "Show Incoming DPS",  -- Show Incoming DPS
	SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_TOOLTIP = "Show DPS you receive in Live Report Window",  -- Show DPS you receive in Live Report Window
	SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_NAME = "Show Incoming HPS",  -- Show Incoming HPS
	SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_TOOLTIP = "Show HPS you receive in Live Report Window",  -- Show HPS you receive in Live Report Window
	SI_COMBAT_METRICS_MENU_SHOW_TIME_NAME = "Show Time",  -- Show Time
	SI_COMBAT_METRICS_MENU_SHOW_TIME_TOOLTIP = "Show Time you have been dealing damage in Live Report Window",  -- Show Time you have been dealing damage in Live Report Window

	SI_COMBAT_METRICS_MENU_CHAT_TITLE = "Stream Combat Log to chat",  -- Stream Combat Log to chat
	SI_COMBAT_METRICS_MENU_CHAT_DH_TOOLTIP = "Streams Damage and Heal Events to chat window",  -- Streams Damage and Heal Events to chat window
	SI_COMBAT_METRICS_MENU_CHAT_TITLE_NAME = "Chat Log Title",  -- Show damage
	SI_COMBAT_METRICS_MENU_CHAT_TITLE_TOOLTIP = "Show damage you deal in chat stream",  -- Show damage you deal in chat stream
	SI_COMBAT_METRICS_MENU_CHAT_SD_NAME = "Show damage",  -- Show damage
	SI_COMBAT_METRICS_MENU_CHAT_SD_TOOLTIP = "Show damage you deal in chat stream",  -- Show damage you deal in chat stream
	SI_COMBAT_METRICS_MENU_CHAT_SH_NAME = "Show heals",  -- Show heals
	SI_COMBAT_METRICS_MENU_CHAT_SH_TOOLTIP = "Show heals you cast in chat stream",  -- Show heals you cast in chat stream
	SI_COMBAT_METRICS_MENU_CHAT_SID_NAME = "Show Incoming damage",  -- Show Incoming damage
	SI_COMBAT_METRICS_MENU_CHAT_SID_TOOLTIP = "Show damage you receive in chat stream",  -- Show damage you receive in chat stream
	SI_COMBAT_METRICS_MENU_CHAT_SIH_NAME = "Show Incoming heal",  -- Show Incoming heal
	SI_COMBAT_METRICS_MENU_CHAT_SIH_TOOLTIP = "Show heals you receive in chat stream",  -- Show heals you receive in chat stream

	SI_COMBAT_METRICS_MENU_DEBUG_TITLE = "Debug options",  -- Debug options
	SI_COMBAT_METRICS_MENU_DEBUG_SF_NAME = "Show Fight Recap",  -- Show Fight Recap
	SI_COMBAT_METRICS_MENU_DEBUG_SF_TOOLTIP = "Print Combat Results to the system chat window",  -- Print Combat Results to the system chat window
	SI_COMBAT_METRICS_MENU_DEBUG_SA_NAME = "Show ability IDs",  -- Show ability IDs
	SI_COMBAT_METRICS_MENU_DEBUG_SA_TOOLTIP = "Show ability ids in the fight report window",  -- Show ability ids in the fight report window
	SI_COMBAT_METRICS_MENU_DEBUG_SFC_NAME = "Show Fight Calculation Info",  -- Show Fight Calculation Info
	SI_COMBAT_METRICS_MENU_DEBUG_SFC_TOOLTIP = "Print Info about the calculation timings to the system chat window",  -- Print Info about the calculation timings to the system chat window
	SI_COMBAT_METRICS_MENU_DEBUG_BI_NAME = "Show Buff Info",  -- Show Buff Info
	SI_COMBAT_METRICS_MENU_DEBUG_BI_TOOLTIP = " Print Buff events to the system chat window (Spammy)",  -- Print Buff events to the system chat window (Spammy,
	SI_COMBAT_METRICS_MENU_DEBUG_US_NAME = "Show used Skill Info",  -- Show used Skill Info
	SI_COMBAT_METRICS_MENU_DEBUG_US_TOOLTIP = "Print used skill events to the system chat window",  -- Print used skill events to the system chat window
	SI_COMBAT_METRICS_MENU_DEBUG_SG_NAME = "Show group Info",  -- Show group Info
	SI_COMBAT_METRICS_MENU_DEBUG_SG_TOOLTIP = "Print group joining and leave events to the system chat window",  -- Print group joining and leave events to the system chat window
	SI_COMBAT_METRICS_MENU_DEBUG_MD_NAME = "Show miscellaneous debug Info",  -- Show miscellaneous debug Info
	SI_COMBAT_METRICS_MENU_DEBUG_MD_TOOLTIP = "Print some other events to the system chat window",  -- Print some other events to the system chat window
	SI_COMBAT_METRICS_MENU_DEBUG_SPECIAL_NAME = "Show special debug Info",  -- Show miscellaneous debug Info
	SI_COMBAT_METRICS_MENU_DEBUG_SPECIAL_TOOLTIP = "Print certain special events to the system chat window",  -- Print some other events to the system chat window
	SI_COMBAT_METRICS_MENU_DEBUG_SAVE_NAME = "Show save data Info",  -- Show group Info
	SI_COMBAT_METRICS_MENU_DEBUG_SAVE_TOOLTIP = "Print debug info about saved and loaded fights to the system chat window",  -- Print group joining and leave events to the system chat window
	
-- make a label for keybinding

	SI_BINDING_NAME_CMX_REPORT_TOGGLE = "Toggle Fight Report",
	SI_BINDING_NAME_CMX_LIVEREPORT_TOGGLE = "Toggle Live Report",
	SI_BINDING_NAME_CMX_POST_DPS_SMART = "Post Boss or Total DPS",
	SI_BINDING_NAME_CMX_POST_DPS_SINGLE = "Post Single Target DPS",
	SI_BINDING_NAME_CMX_POST_DPS_MULTI = "Post Multi Target DPS",
	SI_BINDING_NAME_CMX_POST_DPS = "Post Single + Multi Target DPS",
	SI_BINDING_NAME_CMX_POST_HPS = "Post Heal to Chat",
	SI_BINDING_NAME_CMX_RESET_FIGHT = "Manually Reset the Fight",
	
}

for stringId, stringValue in pairs(strings) do
	ZO_CreateStringId(stringId, stringValue)
	SafeAddVersion(stringId, 1)
end
