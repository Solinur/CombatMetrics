local strings = {

-- Colors

	SI_COMBAT_METRICS_SEP_COLOR = "FFAAAAAA",
	SI_COMBAT_METRICS_HEALTH_COLOR = "FFDE6531",
	SI_COMBAT_METRICS_MAGICKA_COLOR = "FF5EBDE7",
	SI_COMBAT_METRICS_STAMINA_COLOR = "FFA6D852",
	SI_COMBAT_METRICS_ULTIMATE_COLOR = "FFffe785",

-- Ingame (Use ZOS Tranlations, change only for languages which are not supported)

	SI_COMBAT_METRICS_HEALTH = GetString(SI_ATTRIBUTES1),  -- Health
	SI_COMBAT_METRICS_MAGICKA = GetString(SI_ATTRIBUTES2),  -- Magicka
	SI_COMBAT_METRICS_STAMINA = GetString(SI_ATTRIBUTES3),  -- Stamina
	SI_COMBAT_METRICS_ULTIMATE = GetString(SI_COMBATMECHANICTYPE10),  -- Ultimate

-- Localization Start

-- Functionality

	SI_COMBAT_METRICS_LANG = "en",
	SI_COMBAT_METRICS_ENCHANTMENT_TRIM = " Enchantment", -- this will be removed from the items enchantment string to show the rest in the info panel, e.g. "Spell Damage Enchantment" is reduced to "Spell Damage".

-- Fonts

	SI_COMBAT_METRICS_STD_FONT = "$(MEDIUM_FONT)",
	SI_COMBAT_METRICS_BOLD_FONT = "$(BOLD_FONT)",

	SI_COMBAT_METRICS_FONT_SIZE_SMALL = "14",
	SI_COMBAT_METRICS_FONT_SIZE = "15",
	SI_COMBAT_METRICS_FONT_SIZE_TITLE = "20",

-- Main UI

	SI_COMBAT_METRICS_CALC = "Calculating...",
	SI_COMBAT_METRICS_FINALISING = "Finalising...",
	SI_COMBAT_METRICS_GROUP = "Group",
	SI_COMBAT_METRICS_SELECTION = "Selection",

	SI_COMBAT_METRICS_BASE_REG = "Base Regeneration",
	SI_COMBAT_METRICS_DRAIN = "Drain",
	SI_COMBAT_METRICS_UNKNOWN = "Unknown",

	SI_COMBAT_METRICS_BLOCKS = "Blocks",
	SI_COMBAT_METRICS_CRITS = "Crits",

	SI_COMBAT_METRICS_DAMAGE = "Damage",
	SI_COMBAT_METRICS_DAMAGEC = "Damage: ",
	SI_COMBAT_METRICS_HIT = "Hit",
	SI_COMBAT_METRICS_DPS = "DPS",
	SI_COMBAT_METRICS_INCOMING_DPS = "Incoming DPS",

	SI_COMBAT_METRICS_HEALING = "Healing",
	SI_COMBAT_METRICS_HEALS = "Heals",
	SI_COMBAT_METRICS_HPS = "HPS",
	SI_COMBAT_METRICS_HPSA = "HPS + Overheal",
	SI_COMBAT_METRICS_INCOMING_HPS = "Incoming HPS",

	SI_COMBAT_METRICS_EDIT_TITLE = "Double click to edit fight name",

	SI_COMBAT_METRICS_DAMAGE_CAUSED = "Damage Caused",
	SI_COMBAT_METRICS_DAMAGE_RECEIVED = "Damage Received",
	SI_COMBAT_METRICS_HEALING_DONE = "Healing Done",
	SI_COMBAT_METRICS_HEALING_RECEIVED = "Healing Recieved",

	SI_COMBAT_METRICS_TOGGLE_FIGHTSTATS = "Fight Stats",
	SI_COMBAT_METRICS_TOGGLE_COMBAT_LOG = "Combat Log",
	SI_COMBAT_METRICS_TOGGLE_GRAPH = "Graph",
	SI_COMBAT_METRICS_TOGGLE_INFO = "Info",
	SI_COMBAT_METRICS_TOGGLE_SETTINGS = "Options",

	SI_COMBAT_METRICS_NOTIFICATION = "Mein Raid |cffff00Beyond Infinity|r sucht einen MagDK/Necro für vCR+3 (Greifenherz).",
	SI_COMBAT_METRICS_NOTIFICATION_GUILD = "Info: |cffff00Beyond Infinity|r",
	SI_COMBAT_METRICS_NOTIFICATION_ACCEPT = "Message Read",
	SI_COMBAT_METRICS_NOTIFICATION_DISCARD = "Turn off notifications",

	-- Options Menu Strings

	SI_COMBAT_METRICS_SHOWIDS = "Show IDs", -- (for units, buffs and abilities)
	SI_COMBAT_METRICS_HIDEIDS = "Hide IDs", -- (for units, buffs and abilities)

	SI_COMBAT_METRICS_SHOWOVERHEAL = "Show overheal", -- (for units, buffs and abilities)
	SI_COMBAT_METRICS_HIDEOVERHEAL = "Hide overheal", -- (for units, buffs and abilities)

	SI_COMBAT_METRICS_POSTDPS = "Post DPS/HPS",
	SI_COMBAT_METRICS_POSTSINGLEDPS = "Post single target DPS",
	SI_COMBAT_METRICS_POSTSMARTDPS = "Post boss target DPS",
	SI_COMBAT_METRICS_POSTMULTIDPS = "Post total DPS",
	SI_COMBAT_METRICS_POSTALLDPS = "Post single and total DPS",
	SI_COMBAT_METRICS_POSTHPS = "Post HPS",
	SI_COMBAT_METRICS_POSTUNITDPS = "Post DPS to this unit",
	SI_COMBAT_METRICS_POSTUNITNAMEDPS = "Post DPS to '<<tm:1>>' units", -- <<tm:1>> is unitname
	SI_COMBAT_METRICS_POSTSELECTIONDPS = "Post DPS to selected units",
	SI_COMBAT_METRICS_POSTSELECTIONHPS = "Post HPS to selected units",

	-- Format Strings for DPS posting

	SI_COMBAT_METRICS_BOSS_DPS = "Boss DPS",

	SI_COMBAT_METRICS_POSTDPS_FORMAT = "<<1>> - DPS: <<2>> (<<3>> in <<4>>)", -- for single target DPS (<<1>> = fightname, <<2>> = DPS, <<3>> = damage, <<4>> =  ) e.g. Z'Maja - DPS: 10000 (1000000 in 1:40.0)
	SI_COMBAT_METRICS_POSTSMARTDPS_FORMAT = "<<1>><<2>> - Boss DPS: <<3>> (<<4>> in <<5>>)", -- (<<1>> = fightname, <<2>> = extraunits (can be ""), <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Valariel (+5) - Boss DPS: 10000 (1000000 in 1:40.0)
	SI_COMBAT_METRICS_POSTMULTIDPS_FORMAT = "<<1>> (+<<2>>) - DPS: <<3>> (<<4>> in <<5>>)", -- (<<1>> = fightname, <<2>> = extraunits, <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Some random Mob (+5) - DPS: 10000 (1000000 in 1:40.0)
	SI_COMBAT_METRICS_POSTALLDPS_FORMAT_A = "<<1>> - Total DPS (+<<2>>): <<3>> (<<4>> in <<5>>)", -- multi target part (<<1>> = fightname, <<2>> = extraunits, <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Valariel - Total DPS (+5): 10000 (1000000 in 1:40.0)
	SI_COMBAT_METRICS_POSTALLDPS_FORMAT_B = "<<1>>: <<2>> (<<3>> in <<4>>)", --  single target part (<<1>> = Label, <<2>> = DPS, <<3>> = damage) e.g. Boss DPS (+2): 10000 (1000000 in 1:40.0)
	SI_COMBAT_METRICS_POSTSELECTIONDPS_FORMAT = "<<1>><<2>> - Selection DPS: <<3>> (<<4>> in <<5>>)", -- (<<1>> = fightname, <<2>> = extraunits (can be ""), <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Valariel (+5) - Boss DPS: 10000 (1000000 in 1:40.0)
	SI_COMBAT_METRICS_POSTHPS_FORMAT = "<<1>> - HPS: <<2>> (<<3>> in <<4>>)", -- (<<1>> = fightname, <<2>> = HPS, <<3>> = damage, <<4>> = time)  e.g. Z'Maja - HPS: 10000 (1000000 in 1:40.0)
	SI_COMBAT_METRICS_POSTSELECTIONHPS_FORMAT = "<<1>> - Selection HPS (x<<2>>): <<3>> (<<4>> in <<5>>)", -- (<<1>> = fightname, <<2>> = units, <<3>> = HPS, <<4>> = damage, <<5>> = time) e.g. Z'Maja - HPS (12): 10000 (1000000 in 1:40.0)

	SI_COMBAT_METRICS_POSTBUFF = "Post buff uptime",
	SI_COMBAT_METRICS_POSTBUFF_BOSS = "Post buff uptime on bosses",
	SI_COMBAT_METRICS_POSTBUFF_GROUP = "Post buff uptime on group members",
	SI_COMBAT_METRICS_POSTBUFF_FORMAT = "<<1>> - HPS: <<2>> (<<3>><<4[/ on $d/ on $d units]>>)", -- (<<1>> = buff name, <<2>> = relative uptime, <<3>> = uptime, <<4>> = time) e.g. Major Intellect - Uptime: 93.2% (9:26 in 10:07)
	SI_COMBAT_METRICS_POSTBUFF_FORMAT_GROUP = "<<1>> - Uptime: <<2>>/<<5>> (<<3>>/<<6>><<4[/ on $d/ on $d units]>>)", -- (<<1>> = buff name, <<2>> = relative uptime, <<3>> = uptime, <<4>> = units, <<5>> = relative group uptime, <<6>> = group uptime) e.g. Minor Sorcery - Uptime: 55.4%/100.6% (5:36/10:11 in 10:07)

	SI_COMBAT_METRICS_SETTINGS = "Addon Settings",
	SI_COMBAT_METRICS_FEEDBACK = "Send Feedback / Donate",

	-- Graph

	SI_COMBAT_METRICS_TOGGLE_CURSOR = "Toggle to show cursor and value tooltip",
	SI_COMBAT_METRICS_GRAPH_BUFF_GROUP_SELECTOR = "Toggle to show group uptime",

	SI_COMBAT_METRICS_RECALCULATE = "Recalculate Fight",
	SI_COMBAT_METRICS_SMOOTHED = "Smoothed",
	SI_COMBAT_METRICS_TOTAL = "Total",
	SI_COMBAT_METRICS_ABSOLUTE = "Absolute %",
	SI_COMBAT_METRICS_SMOOTH_LABEL = "Smooth: %d s",
	SI_COMBAT_METRICS_NONE = "None",
	SI_COMBAT_METRICS_BOSS_HP = "Boss HP",
	SI_COMBAT_METRICS_ENLARGE = "Enlarge",
	SI_COMBAT_METRICS_SHRINK = "Shrink",

	-- Feedback

	SI_COMBAT_METRICS_FEEDBACK_MAIL = "Send Mail",
	SI_COMBAT_METRICS_FEEDBACK_GOLD = "Donate 5000g",
	SI_COMBAT_METRICS_FEEDBACK_GOLD2 = "Donate 25000g",
	SI_COMBAT_METRICS_FEEDBACK_ESOUI = "Site (ESOUI)",
	SI_COMBAT_METRICS_FEEDBACK_GITHUB = "GitHub",
	SI_COMBAT_METRICS_FEEDBACK_TEXT = "\nIf you found a bug, have a request or a suggestion, send an ingame mail, create an issue on GitHub or post it in the comments on EsoUI. \n\nDonations are gladly accepted, but are not urgently needed. \nIf you want to buy me a coffee or a beer you can donate via Paypal on the ESOUI page.",

	SI_COMBAT_METRICS_STORAGE_FULL = "The storage file is full. The fight you want to save needs <<1>> MB. Delete a fight to free some space or increase the allowed space in the settings!",

	-- Fight Control Button Tooltips

	SI_COMBAT_METRICS_PREVIOUS_FIGHT = "Previous Fight",
	SI_COMBAT_METRICS_NEXT_FIGHT = "Next Fight",
	SI_COMBAT_METRICS_MOST_RECENT_FIGHT = "Most Recent Fight",
	SI_COMBAT_METRICS_LOAD_FIGHT = "Load Fight",
	SI_COMBAT_METRICS_SAVE_FIGHT = "Click: Save fight",
	SI_COMBAT_METRICS_SAVE_FIGHT2 = "Shift+Click: Save fight with combat log",
	SI_COMBAT_METRICS_DELETE_COMBAT_LOG = "Delete Combat Log",
	SI_COMBAT_METRICS_DELETE_FIGHT = "Delete Fight",

	-- Fight List

	SI_COMBAT_METRICS_RECENT_FIGHT = "Recent Fights",
	SI_COMBAT_METRICS_DURATION = "Duration",
	SI_COMBAT_METRICS_CHARACTER = "Character",
	SI_COMBAT_METRICS_ZONE = "Zone",
	SI_COMBAT_METRICS_TIME = "Time",
	SI_COMBAT_METRICS_TIME2 = "Time",
	SI_COMBAT_METRICS_TIMEC = "Time: ",

	SI_COMBAT_METRICS_SHOW = "Show",
	SI_COMBAT_METRICS_DELETE = "Delete",

	SI_COMBAT_METRICS_SAVED_FIGHTS = "Saved Fights",

	-- More UI Strings

	SI_COMBAT_METRICS_ACTIVE_TIME = "Active Time: ",
	SI_COMBAT_METRICS_ZERO_SEC = "0 s",
	SI_COMBAT_METRICS_IN_COMBAT = "In Combat: ",

	SI_COMBAT_METRICS_PLAYER = "Player",

	SI_COMBAT_METRICS_TOTALC = " Total: ",
	SI_COMBAT_METRICS_NORMAL = "Normal: ",
	SI_COMBAT_METRICS_CRITICAL = "Critical: ",
	SI_COMBAT_METRICS_BLOCKED = "Blocked: ",
	SI_COMBAT_METRICS_SHIELDED = "Shielded: ",
	SI_COMBAT_METRICS_ABSOLUTEC = "Absolute: ",
	SI_COMBAT_METRICS_OVERHEAL = "Overheal: ", -- as in overheal

	SI_COMBAT_METRICS_HITS = "Hits",
	SI_COMBAT_METRICS_NORM = "Norm",  -- Normal, short
	SI_COMBAT_METRICS_OH = "OH",  -- Overheal, short

	SI_COMBAT_METRICS_RESOURCES = "Resources",

	SI_COMBAT_METRICS_STATS = "Stats",
	SI_COMBAT_METRICS_AVE = "Avg",  -- Average, short
	SI_COMBAT_METRICS_AVE_N = "Avg N",  -- Average Normal, short
	SI_COMBAT_METRICS_AVE_C = "Avg C",  -- Average Crit, short
	SI_COMBAT_METRICS_AVE_B = "Avg B",  -- Average Blocked, short
	SI_COMBAT_METRICS_AVERAGE = "Average",
	SI_COMBAT_METRICS_NORMAL_HITS = "Normal Hits",
	SI_COMBAT_METRICS_MAX = "Max",  -- Maximum
	SI_COMBAT_METRICS_MIN = "Min",  -- Minimum

	SI_COMBAT_METRICS_STATS_MAGICKA1 = "Max Magicka",
	SI_COMBAT_METRICS_STATS_MAGICKA2 = "Spell Damage",
	SI_COMBAT_METRICS_STATS_MAGICKA3 = "Spell Critical",
	SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT3 = "%.1f %%", -- e.g. 12.3%
	SI_COMBAT_METRICS_STATS_MAGICKA4 = "Critical Damage",
	SI_COMBAT_METRICS_STATS_MAGICKA5 = "Spell Penetration",
	SI_COMBAT_METRICS_STATS_MAGICKA6 = "Overpenetration",
	SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT6 = "%.1f %%",-- e.g. 12.3%

	SI_COMBAT_METRICS_STATS_STAMINA1 = "Max Stamina",
	SI_COMBAT_METRICS_STATS_STAMINA2 = "Weapon Damage",
	SI_COMBAT_METRICS_STATS_STAMINA3 = "Weapon Critical",
	SI_COMBAT_METRICS_STATS_STAMINA_FORMAT3 = "%.1f %%",-- e.g. 12.3%
	SI_COMBAT_METRICS_STATS_STAMINA4 = "Critical Damage",
	SI_COMBAT_METRICS_STATS_STAMINA5 = "Phys. Penetration",
	SI_COMBAT_METRICS_STATS_STAMINA6 = "Overpenetration",
	SI_COMBAT_METRICS_STATS_STAMINA_FORMAT6 = "%.1f %%",-- e.g. 12.3%

	SI_COMBAT_METRICS_STATS_HEALTH1 = "Max Health",
	SI_COMBAT_METRICS_STATS_HEALTH2 = "Physical Resist.",
	SI_COMBAT_METRICS_STATS_HEALTH3 = "Spell Resistance",
	SI_COMBAT_METRICS_STATS_HEALTH4 = "Critical Resist.",
	SI_COMBAT_METRICS_STATS_HEALTH_FORMAT4 = "%.1f %%",-- e.g. 12.3%

	SI_COMBAT_METRICS_PERFORMANCE = "Performance",
	SI_COMBAT_METRICS_PERFORMANCE_FPSAVG = "Average FPS",
	SI_COMBAT_METRICS_PERFORMANCE_FPSMIN = "Minimum FPS",
	SI_COMBAT_METRICS_PERFORMANCE_FPSMAX = "Maximum FPS",
	SI_COMBAT_METRICS_PERFORMANCE_FPSPING = "Ping",
	SI_COMBAT_METRICS_PERFORMANCE_DESYNC = "Skill Desync",

	SI_COMBAT_METRICS_PENETRATION_TT = "Penetration vs. Damage",

	SI_COMBAT_METRICS_COMBAT_LOG = "Combat Log",

	SI_COMBAT_METRICS_GOTO_PREVIOUS = "Go to previous page",
	SI_COMBAT_METRICS_PAGE = "Go to page <<1>>", -- <<1>> = page number
	SI_COMBAT_METRICS_GOTO_NEXT = "Go to next page",

	SI_COMBAT_METRICS_TOGGLE_HEAL = "Toggle received healing events",
	SI_COMBAT_METRICS_TOGGLE_DAMAGE = "Toggle received damage events",

	SI_COMBAT_METRICS_TOGGLE_YOUR_HEAL = "Toggle your healing events",
	SI_COMBAT_METRICS_TOGGLE_YOUR_DAMAGE = "Toggle your damage events",

	SI_COMBAT_METRICS_TOGGLE_BUFFIN_EVENTS = "Toggle incoming buff events",
	SI_COMBAT_METRICS_TOGGLE_BUFFOUT_EVENTS = "Toggle outbound buff events",
	SI_COMBAT_METRICS_TOGGLE_GROUPBUFFIN_EVENTS = "Toggle incoming groupbuff events",
	SI_COMBAT_METRICS_TOGGLE_GROUPBUFFOUT_EVENTS = "Toggle outbound groupbuff events",
	SI_COMBAT_METRICS_TOGGLE_RESOURCE_EVENTS = "Toggle resource events",
	SI_COMBAT_METRICS_TOGGLE_STATS_CHANGE_EVENTS = "Toggle stats change events",
	SI_COMBAT_METRICS_TOGGLE_MESSAGE_CHANGE_EVENTS = "Toggle info events (e.g. weapon swap)",
	SI_COMBAT_METRICS_TOGGLE_SKILL_USE_EVENTS = "Toggle used skills events",
	SI_COMBAT_METRICS_TOGGLE_PERFORMANCE_EVENTS = "Toggle performance info",

	-- \n = new line

	SI_COMBAT_METRICS_DEBUFF_IN = "(De-)Buffs\nIn",
	SI_COMBAT_METRICS_DEBUFF_OUT = "(De-)Buffs\nOut",
	SI_COMBAT_METRICS_MAGICKA_PM = "Magicka\n +/-",
	SI_COMBAT_METRICS_STAMINA_PM = "Stamina\n +/-",
	SI_COMBAT_METRICS_RESOURCES_PM = "Resources\n +/-",

	SI_COMBAT_METRICS_BUFF = "Buff",
	SI_COMBAT_METRICS_BUFFS = "Buffs",
	SI_COMBAT_METRICS_DEBUFFS = "Debuffs",
	SI_COMBAT_METRICS_SHARP = "#",
	SI_COMBAT_METRICS_BUFFCOUNT_TT = "Player / Overall",
	SI_COMBAT_METRICS_UPTIME = "Uptime %",
	SI_COMBAT_METRICS_UPTIME_TT = "Player % / Overall %",

	SI_COMBAT_METRICS_REGENERATION = "Regeneration",
	SI_COMBAT_METRICS_CONSUMPTION = "Consumption",
	SI_COMBAT_METRICS_PM_SEC = "±/s",
	SI_COMBAT_METRICS_TARGET = "Target",
	SI_COMBAT_METRICS_PERCENT = "%",
	SI_COMBAT_METRICS_UNITDPS_TT = "Real DPS, e.g. the damage per second between your first and your last hit to that target",

	SI_COMBAT_METRICS_ABILITY = "Ability",
	SI_COMBAT_METRICS_PER_HITS = "/Hits",
	SI_COMBAT_METRICS_CRITS_PER = "Crit %",

	SI_COMBAT_METRICS_FAVOURITE_ADD = "Add to Favourites",
	SI_COMBAT_METRICS_FAVOURITE_REMOVE = "Remove from Favourites",

	SI_COMBAT_METRICS_UNCOLLAPSE = "Show Details",
	SI_COMBAT_METRICS_COLLAPSE = "Collapse",

	SI_COMBAT_METRICS_SKILL = "Skill",

	SI_COMBAT_METRICS_BAR = "Bar ",
	SI_COMBAT_METRICS_AVERAGEC = "Average: ",

	SI_COMBAT_METRICS_SKILLTIME_LABEL2 = "< W / S", -- as in "Weapon / Skill"
	SI_COMBAT_METRICS_SKILLTIME_LABEL3 = "W / S >",

	SI_COMBAT_METRICS_SKILLTIME_TT1 = "Number of casts of this skill",
	SI_COMBAT_METRICS_SKILLTIME_TT2 = "Time since the last weapon/skill activation and the ability activation.",
	SI_COMBAT_METRICS_SKILLTIME_TT3 = "Time between the ability activation and the next weapon/skill activation.",
	SI_COMBAT_METRICS_SKILLTIME_TT4 = "Average time between subsequent activations of this skill",

	SI_COMBAT_METRICS_SKILLAVG_TT = "Average time lost between two skill casts",
	SI_COMBAT_METRICS_SKILLTOTAL_TT = "Total time lost between two skill casts",

	SI_COMBAT_METRICS_TOTALWA = "Weapon attacks: ",
	SI_COMBAT_METRICS_TOTALWA_TT = "Total weapon attacks",
	SI_COMBAT_METRICS_TOTALSKILLS = "Skills: ",
	SI_COMBAT_METRICS_TOTALSKILLS_TT = "Total skills fired",

	SI_COMBAT_METRICS_SAVED_DATA = "Saved Data",

-- Live report window

	SI_COMBAT_METRICS_SHOW_XPS = "<<1>> / <<2>> (<<3>>%)", -- Format to show DPS/HPS. <<1>> = own value, <<2>> = group value, <<3>> = percentage

-- Settings Menu

	SI_COMBAT_METRICS_MENU_PROFILES = "Profiles",

	SI_COMBAT_METRICS_MENU_AC_NAME = "Use accountwide settings",
	SI_COMBAT_METRICS_MENU_AC_TOOLTIP = "If enabled all chars of an account will share their settings",

	SI_COMBAT_METRICS_MENU_GS_NAME = "General Settings",

	SI_COMBAT_METRICS_MENU_FH_NAME = "Fight History",
	SI_COMBAT_METRICS_MENU_FH_TOOLTIP = "Number of recent fights to save",

	SI_COMBAT_METRICS_MENU_SVSIZE_NAME = "Saved Fight Memory",
	SI_COMBAT_METRICS_MENU_SVSIZE_TOOLTIP = "Maximum memory size for saved fights in MB",
	SI_COMBAT_METRICS_MENU_SVSIZE_WARNING = "Use with caution! Lots of saved data significantly increase loading times. If the file gets too large, the client might crash when attempting to load it.",

	SI_COMBAT_METRICS_MENU_BOSSFIGHTS_NAME = "Keep Boss Fights",
	SI_COMBAT_METRICS_MENU_BOSSFIGHTS_TOOLTIP = "Delete trash fights first before deleting boss fights when limit of fights is reached",

	SI_COMBAT_METRICS_MENU_MG_NAME = "Monitor Group Damage",
	SI_COMBAT_METRICS_MENU_MG_TOOLTIP = "Monitor the events of the whole group",

	SI_COMBAT_METRICS_MENU_STACKS_NAME = "Show stacks of buffs",
	SI_COMBAT_METRICS_MENU_STACKS_TOOLTIP = "Show individual stacks in the buff panel",

	SI_COMBAT_METRICS_MENU_GL_NAME = "Monitor Damage in large groups",
	SI_COMBAT_METRICS_MENU_GL_TOOLTIP = "Monitor group damage in large groups (more than 4 group members)",

	SI_COMBAT_METRICS_MENU_LM_NAME = "Light Mode",
	SI_COMBAT_METRICS_MENU_LM_TOOLTIP = "When in light mode, combat metrics will only calculate the DPS/HPS in the live report window. No statistics will be calculated and the fight report window will be disabled",

	SI_COMBAT_METRICS_MENU_NOPVP_NAME = "Turn off in PvP",
	SI_COMBAT_METRICS_MENU_NOPVP_TOOLTIP = "Turns all fight logging off in Cyrodil and Battlegrounds",

	SI_COMBAT_METRICS_MENU_LMPVP_NAME = "Light Mode in PvP",
	SI_COMBAT_METRICS_MENU_LMPVP_TOOLTIP = "Swiches to light mode in Cyrodil and Battlegrounds. When in light mode, Combat Metrics will only calculate the DPS/HPS in the live report window. No statistics will be calculated and the fight report window will be disabled",

	SI_COMBAT_METRICS_MENU_ASCC_NAME = "Auto Select Channel",
	SI_COMBAT_METRICS_MENU_ASCC_TOOLTIP = "Automatically select the channel when posting DPS/HPS to chat. When in group the /group chat is used otherwise the /say chat.",
	SI_COMBAT_METRICS_MENU_AS_NAME = "Auto Screenshot",
	SI_COMBAT_METRICS_MENU_AS_TOOLTIP = "Automatically take a Screenshot when opening the fight report window",
	SI_COMBAT_METRICS_MENU_ML_NAME = "Minimum fight length for screenshot",
	SI_COMBAT_METRICS_MENU_ML_TOOLTIP = "Minimum fight length in s for auto screenshot",
	SI_COMBAT_METRICS_MENU_SF_NAME = "Scale of fight report window",
	SI_COMBAT_METRICS_MENU_SF_TOOLTIP = "Adjusts the size of all elements of the fight report window",

	SI_COMBAT_METRICS_MENU_DISPLAYNAMES_NAME = "Show account names",
	SI_COMBAT_METRICS_MENU_DISPLAYNAMES_TOOLTIP = "Shows account names (@Name) instead of character names for group members",

	SI_COMBAT_METRICS_MENU_SHOWPETS_NAME = "Show Pets",
	SI_COMBAT_METRICS_MENU_HIDEPETS = "Hide Pets",
	SI_COMBAT_METRICS_MENU_SHOWPETS_TOOLTIP = "Shows pets in the fight report window",

	SI_COMBAT_METRICS_MENU_NOTIFICATIONS = "Allow Notifications",
	SI_COMBAT_METRICS_MENU_NOTIFICATIONS_TOOLTIP = "From time to time, I may add a notification to the report window, for example to gather data or to recruit people to my raid (to save time that I'd rather use on addons). Turn this off, if you don't want this.",

	SI_COMBAT_METRICS_MENU_RESPEN_NAME = "Resistance and Penetration",
	SI_COMBAT_METRICS_MENU_CRUSHER = "Crusher",
	SI_COMBAT_METRICS_MENU_CRUSHER_TOOLTIP = "Resistance reduction due to debuff from Crusher glyph. For maxlevel gold glyph: standard: 1622, infused: 2108, infused + Torug's: 2740",
	SI_COMBAT_METRICS_MENU_MOBRESISTANCE = "Target resistance",
	SI_COMBAT_METRICS_MENU_MOBRESISTANCE_TOOLTIP = "Target resistance that is assumed for overpenetration calculation",

	SI_COMBAT_METRICS_MENU_LR_NAME = "Live report window",
	SI_COMBAT_METRICS_MENU_ENABLE_NAME = "Enable",
	SI_COMBAT_METRICS_MENU_ENABLE_TOOLTIP = "Enable Live report window which shows DPS & HPS during combat",

	SI_COMBAT_METRICS_MENU_LR_LOCK = "Lock",
	SI_COMBAT_METRICS_MENU_LR_LOCK_TOOLTIP = "Lock the Live report window, so it can't be moved",

	SI_COMBAT_METRICS_MENU_LR_ALIGNMENT = "Use left-aligned numbers",
	SI_COMBAT_METRICS_MENU_LR_ALIGNMENT_TOOLTIP = "Sets positioning of Damage/Heal/etc. numbers for the Live report window to left-aligned",

	SI_COMBAT_METRICS_MENU_LAYOUT_NAME = "Layout",
	SI_COMBAT_METRICS_MENU_LAYOUT_TOOLTIP = "Select the Layout of the Live report window",
	SI_COMBAT_METRICS_MENU_SCALE_NAME = "Scale",
	SI_COMBAT_METRICS_MENU_SCALE_TOOLTIP = "Scale of the Live report window.",

	SI_COMBAT_METRICS_MENU_BGALPHA_NAME = "Background Opacity",
	SI_COMBAT_METRICS_MENU_BGALPHA_TOOLTIP = "Set the Opacity of the Background",

	SI_COMBAT_METRICS_MENU_SHOW_DPS_NAME = "Show DPS",
	SI_COMBAT_METRICS_MENU_SHOW_DPS_TOOLTIP = "Show DPS you deal in Live report window",
	SI_COMBAT_METRICS_MENU_SHOW_SDPS_NAME = "Show single target DPS",
	SI_COMBAT_METRICS_MENU_SHOW_SDPS_TOOLTIP = "Show single target DPS you deal in Live report window",
	SI_COMBAT_METRICS_MENU_SHOW_HPS_NAME = "Show HPS",
	SI_COMBAT_METRICS_MENU_SHOW_HPS_TOOLTIP = "Show HPS you cast in Live report window",
	SI_COMBAT_METRICS_MENU_SHOW_HPSA_NAME = "Show HPS + overheal",
	SI_COMBAT_METRICS_MENU_SHOW_HPSA_TOOLTIP = "Show HPS including overheal that you cast in Live report window",
	SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_NAME = "Show Incoming DPS",
	SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_TOOLTIP = "Show DPS you receive in Live report window",
	SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_NAME = "Show Incoming HPS",
	SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_TOOLTIP = "Show HPS you receive in Live report window",
	SI_COMBAT_METRICS_MENU_SHOW_TIME_NAME = "Show Time",
	SI_COMBAT_METRICS_MENU_SHOW_TIME_TOOLTIP = "Show Time you have been dealing damage in Live report window",

	SI_COMBAT_METRICS_MENU_CHAT_TITLE = "Stream Combat Log to chat",
	SI_COMBAT_METRICS_MENU_CHAT_WARNING = "Use with caution! Creating text lines requires a lot of work from the CPU. It is better to disable this if you expect heavy fights (trials, cyrodil)",

	SI_COMBAT_METRICS_MENU_CHAT_DH_TOOLTIP = "Streams Damage and Heal Events to chat window",
	SI_COMBAT_METRICS_MENU_CHAT_TITLE_NAME = "Chat Log Title",
	SI_COMBAT_METRICS_MENU_CHAT_TITLE_TOOLTIP = "Show damage you deal in chat stream",
	SI_COMBAT_METRICS_MENU_CHAT_SD_NAME = "Show damage",
	SI_COMBAT_METRICS_MENU_CHAT_SD_TOOLTIP = "Show damage you deal in chat stream",
	SI_COMBAT_METRICS_MENU_CHAT_SH_NAME = "Show heals",
	SI_COMBAT_METRICS_MENU_CHAT_SH_TOOLTIP = "Show heals you cast in chat stream",
	SI_COMBAT_METRICS_MENU_CHAT_SID_NAME = "Show Incoming damage",
	SI_COMBAT_METRICS_MENU_CHAT_SID_TOOLTIP = "Show damage you receive in chat stream",
	SI_COMBAT_METRICS_MENU_CHAT_SIH_NAME = "Show Incoming heal",
	SI_COMBAT_METRICS_MENU_CHAT_SIH_TOOLTIP = "Show heals you receive in chat stream",

-- make a label for keybinding

	SI_BINDING_NAME_CMX_REPORT_TOGGLE = "Toggle Fight Report",
	SI_BINDING_NAME_CMX_LIVEREPORT_TOGGLE = "Toggle Live Report",
	SI_BINDING_NAME_CMX_POST_DPS_SMART = "Post Boss or Total DPS",
	SI_BINDING_NAME_CMX_POST_DPS_SINGLE = "Post Single Target DPS",
	SI_BINDING_NAME_CMX_POST_DPS_MULTI = "Post Multi Target DPS",
	SI_BINDING_NAME_CMX_POST_DPS = "Post Single + Multi Target DPS",
	SI_BINDING_NAME_CMX_POST_HPS = "Post Heal to Chat",
	SI_BINDING_NAME_CMX_RESET_FIGHT = "Manually Reset the Fight",

-- Localization End

}

for stringId, stringValue in pairs(strings) do
	ZO_CreateStringId(stringId, stringValue)
	SafeAddVersion(stringId, 1)
end
