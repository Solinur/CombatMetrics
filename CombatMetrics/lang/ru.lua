-- Russian localization for CombatMetrics
-- Author: @KiriX

-- Functionality

SafeAddString(SI_COMBAT_METRICS_LANG, "ru", 1) 
--SafeAddString(SI_COMBAT_METRICS_ENCHANTMENT_TRIM, " Enchantment", 1) -- this will be removed from the items enchantment string to show the rest in the info panel, e.g. "Spell Damage Enchantment" is reduced to "Spell Damage".

-- Fonts

SafeAddString(SI_COMBAT_METRICS_STD_FONT, "RuESO/fonts/univers57.otf", 1) 
SafeAddString(SI_COMBAT_METRICS_BOLD_FONT, "RuESO/fonts/univers67.otf", 1) 

--SafeAddString(SI_COMBAT_METRICS_FONT_SIZE_SMALL, "14", 1) 
--SafeAddString(SI_COMBAT_METRICS_FONT_SIZE, "15", 1) 
--SafeAddString(SI_COMBAT_METRICS_FONT_SIZE_TITLE, "20", 1) 

-- Main UI

SafeAddString(SI_COMBAT_METRICS_CALC, "Подсчёт...", 1) 
--SafeAddString(SI_COMBAT_METRICS_FINALISING, "Finalising...", 1) 
SafeAddString(SI_COMBAT_METRICS_GROUP, "Группа", 1) 
SafeAddString(SI_COMBAT_METRICS_SELECTION, "Выбор", 1) 

SafeAddString(SI_COMBAT_METRICS_BASE_REG, "Базовое восстановление", 1) 
SafeAddString(SI_COMBAT_METRICS_DRAIN, "Расход", 1) 
SafeAddString(SI_COMBAT_METRICS_UNKNOWN, "Неизвестно", 1) 

SafeAddString(SI_COMBAT_METRICS_BLOCKS, "Блоки", 1) 
SafeAddString(SI_COMBAT_METRICS_CRITS, "Крит", 1) 

SafeAddString(SI_COMBAT_METRICS_DAMAGE, "Урон", 1) 
--SafeAddString(SI_COMBAT_METRICS_DAMAGEC, "Damage: ", 1) 
SafeAddString(SI_COMBAT_METRICS_HIT, "Удары", 1) 
SafeAddString(SI_COMBAT_METRICS_DPS, "DPS", 1) 
--SafeAddString(SI_COMBAT_METRICS_INCOMING_DPS, "Incoming DPS", 1) 

SafeAddString(SI_COMBAT_METRICS_HEALING, "Исцеление", 1) 
SafeAddString(SI_COMBAT_METRICS_HEALS, "Исцеления", 1) 
SafeAddString(SI_COMBAT_METRICS_HPS, "HPS", 1) 
--SafeAddString(SI_COMBAT_METRICS_INCOMING_HPS, "Incoming HPS", 1) 

SafeAddString(SI_COMBAT_METRICS_EDIT_TITLE, "Двойной щелчок, чтобы отредактировать название битвы", 1) 

SafeAddString(SI_COMBAT_METRICS_DAMAGE_CAUSED, "Урон Нанесённый", 1) 
SafeAddString(SI_COMBAT_METRICS_DAMAGE_RECEIVED, "Урон Полученный", 1) 
SafeAddString(SI_COMBAT_METRICS_HEALING_DONE, "Исцеление Нанесённое", 1) 
SafeAddString(SI_COMBAT_METRICS_HEALING_RECEIVED, "Исцеление Полученное", 1) 

SafeAddString(SI_COMBAT_METRICS_TOGGLE_FIGHTSTATS, "Статистика боя", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_COMBAT_LOG, "Лог боя", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_GRAPH, "Графы", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_INFO, "Информация", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_SETTINGS, "Настройки", 1) 

-- Options Menu Strings

SafeAddString(SI_COMBAT_METRICS_SHOWIDS, "Показать ID", 1) -- (for units, buffs and abilities)
SafeAddString(SI_COMBAT_METRICS_HIDEIDS, "Скрыть ID", 1) -- (for units, buffs and abilities)

--SafeAddString(SI_COMBAT_METRICS_POSTDPS, "Post DPS/HPS", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTSINGLEDPS, "Вывести в чат DPS по одиночной цели", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTSMARTDPS, "Вывести в чат DPS по боссу", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTMULTIDPS, "Вывести общий DPS", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTALLDPS, "Вывести в чат общий DPS и по одиночной цели", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTHPS, "Вывести в чат HPS", 1) 
--SafeAddString(SI_COMBAT_METRICS_POSTUNITDPS, "Post DPS to this unit", 1) 
--SafeAddString(SI_COMBAT_METRICS_POSTUNITNAMEDPS, "Post DPS to '<<1>>' units", 1) -- <<1>> is unitname
--SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONDPS, "Post DPS to selected units", 1) 
--SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONHPS, "Post HPS to selected units", 1) 

-- Format Strings for DPS posting

--SafeAddString(SI_COMBAT_METRICS_BOSS_DPS, "Boss DPS", 1) 

--SafeAddString(SI_COMBAT_METRICS_POSTDPS_FORMAT, "<<1>> - DPS: <<2>> (<<3>> in <<4>>)", 1) -- for single target DPS (<<1>> = fightname, <<2>> = DPS, <<3>> = damage, <<4>> =  ) e.g. Z'Maja - DPS: 10000 (1000000 in 1:40.0)
--SafeAddString(SI_COMBAT_METRICS_POSTSMARTDPS_FORMAT, "<<1>><<2>> - Boss DPS: <<3>> (<<4>> in <<5>>)", 1) -- (<<1>> = fightname, <<2>> = extraunits (can be ""), <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Valariel (+5) - Boss DPS: 10000 (1000000 in 1:40.0)
--SafeAddString(SI_COMBAT_METRICS_POSTMULTIDPS_FORMAT, "<<1>> (+<<2>>) - DPS: <<3>> (<<4>> in <<5>>)", 1) -- (<<1>> = fightname, <<2>> = extraunits, <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Some random Mob (+5) - DPS: 10000 (1000000 in 1:40.0)
--SafeAddString(SI_COMBAT_METRICS_POSTALLDPS_FORMAT_A, "<<1>> - Total DPS (+<<2>>): <<3>> (<<4>> in <<5>>)", 1) -- multi target part (<<1>> = fightname, <<2>> = extraunits, <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Valariel - Total DPS (+5): 10000 (1000000 in 1:40.0)
--SafeAddString(SI_COMBAT_METRICS_POSTALLDPS_FORMAT_B, "<<1>>: <<2>> (<<3>> in <<4>>)", 1) --  single target part (<<1>> = Label, <<2>> = DPS, <<3>> = damage) e.g. Boss DPS (+2): 10000 (1000000 in 1:40.0)
--SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONDPS_FORMAT, "<<1>><<2>> - Selection DPS: <<3>> (<<4>> in <<5>>)", 1) -- (<<1>> = fightname, <<2>> = extraunits (can be ""), <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Valariel (+5) - Boss DPS: 10000 (1000000 in 1:40.0)
--SafeAddString(SI_COMBAT_METRICS_POSTHPS_FORMAT, "<<1>> - HPS: <<2>> (<<3>> in <<4>>)", 1) -- (<<1>> = fightname, <<2>> = HPS, <<3>> = damage, <<4>> = time)  e.g. Z'Maja - HPS: 10000 (1000000 in 1:40.0)
--SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONHPS_FORMAT, "<<1>> - Selection HPS (x<<2>>): <<3>> (<<4>> in <<5>>)", 1) -- (<<1>> = fightname, <<2>> = units, <<3>> = HPS, <<4>> = damage, <<5>> = time) e.g. Z'Maja - HPS (12): 10000 (1000000 in 1:40.0)

--SafeAddString(SI_COMBAT_METRICS_POSTBUFF, "Post buff uptime", 1) 
--SafeAddString(SI_COMBAT_METRICS_POSTBUFF_BOSS, "Post buff uptime on bosses", 1) 
--SafeAddString(SI_COMBAT_METRICS_POSTBUFF_GROUP, "Post buff uptime on group members", 1) 
--SafeAddString(SI_COMBAT_METRICS_POSTBUFF_FORMAT, "<<1>> - HPS: <<2>> (<<3>><<4[/ on $d/ on $d units]>>)", 1) -- (<<1>> = buff name, <<2>> = relative uptime, <<3>> = uptime, <<4>> = time) e.g. Major Intellect - Uptime: 93.2% (9:26 in 10:07)
--SafeAddString(SI_COMBAT_METRICS_POSTBUFF_FORMAT_GROUP, "<<1>> - Uptime: <<2>>/<<5>> (<<3>>/<<6>><<4[/ on $d/ on $d units]>>)", 1) -- (<<1>> = buff name, <<2>> = relative uptime, <<3>> = uptime, <<4>> = units, <<5>> = relative group uptime, <<6>> = group uptime) e.g. Minor Sorcery - Uptime: 55.4%/100.6% (5:36/10:11 in 10:07)

--SafeAddString(SI_COMBAT_METRICS_SETTINGS, "Addon Settings", 1) 
--SafeAddString(SI_COMBAT_METRICS_FEEDBACK, "Send Feedback / Donate", 1) 

-- Graph

--SafeAddString(SI_COMBAT_METRICS_TOGGLE_CURSOR, "Toggle to show cursor and value tooltip", 1) 
--SafeAddString(SI_COMBAT_METRICS_GRAPH_BUFF_GROUP_SELECTOR, "Toggle to show group uptime", 1) 

--SafeAddString(SI_COMBAT_METRICS_RECALCULATE, "Recalculate Fight", 1) 
--SafeAddString(SI_COMBAT_METRICS_SMOOTHED, "Smoothed", 1) 
SafeAddString(SI_COMBAT_METRICS_TOTAL, "Всего:", 1) 
--SafeAddString(SI_COMBAT_METRICS_ABSOLUTE, "Absolute %", 1) 
--SafeAddString(SI_COMBAT_METRICS_SMOOTH_LABEL, "Smooth: %d s", 1) 
--SafeAddString(SI_COMBAT_METRICS_NONE, "None", 1) 
--SafeAddString(SI_COMBAT_METRICS_BOSS_HP, "Boss HP", 1) 
--SafeAddString(SI_COMBAT_METRICS_ENLARGE, "Enlarge", 1) 
--SafeAddString(SI_COMBAT_METRICS_SHRINK, "Shrink", 1) 

-- Feedback

--SafeAddString(SI_COMBAT_METRICS_FEEDBACK_MAIL, "Send Mail", 1) 
--SafeAddString(SI_COMBAT_METRICS_FEEDBACK_GOLD, "Donate 5000g", 1) 
--SafeAddString(SI_COMBAT_METRICS_FEEDBACK_GOLD2, "Donate 25000g", 1) 
--SafeAddString(SI_COMBAT_METRICS_FEEDBACK_ESOUI, "Site (ESOUI)", 1) 
--SafeAddString(SI_COMBAT_METRICS_FEEDBACK_GITHUB, "GitHub", 1) 
--SafeAddString(SI_COMBAT_METRICS_FEEDBACK_TEXT, "\nIf you found a bug, have a request or a suggestion, send an ingame mail, create an issue on GitHub or post it in the comments on EsoUI. \n\nDonations are appreciated but not required or necessary. \nIf you want to donate real money please visit the addon site on EsoUI", 1) 

SafeAddString(SI_COMBAT_METRICS_STORAGE_FULL, "Файл сохранений переполнен. Удалите битву, чтобы освободить немного места!", 1) 

-- Fight Control Button Tooltips

SafeAddString(SI_COMBAT_METRICS_PREVIOUS_FIGHT, "Предыдущая битва", 1) 
SafeAddString(SI_COMBAT_METRICS_NEXT_FIGHT, "Следующая битва", 1) 
SafeAddString(SI_COMBAT_METRICS_MOST_RECENT_FIGHT, "Самая последняя битва", 1) 
SafeAddString(SI_COMBAT_METRICS_LOAD_FIGHT, "Загрузить битву", 1) 
SafeAddString(SI_COMBAT_METRICS_SAVE_FIGHT, "Сохранить битву", 1) 
SafeAddString(SI_COMBAT_METRICS_SAVE_FIGHT2, "Shift+Щелчок: Сохранить битву с логом боя", 1) 
SafeAddString(SI_COMBAT_METRICS_DELETE_COMBAT_LOG, "Удалить лог боя", 1) 
SafeAddString(SI_COMBAT_METRICS_DELETE_FIGHT, "Удалить битву", 1) 

-- Fight List

SafeAddString(SI_COMBAT_METRICS_RECENT_FIGHT, "Последние битвы", 1) 
SafeAddString(SI_COMBAT_METRICS_DURATION, "Время", 1) 
SafeAddString(SI_COMBAT_METRICS_CHARACTER, "Персонаж", 1) 
SafeAddString(SI_COMBAT_METRICS_ZONE, "Зона", 1) 
SafeAddString(SI_COMBAT_METRICS_TIME, "Время", 1) 
--SafeAddString(SI_COMBAT_METRICS_TIMEC, "Time: ", 1) 

SafeAddString(SI_COMBAT_METRICS_SHOW, "Показать", 1) 
SafeAddString(SI_COMBAT_METRICS_DELETE, "Удалить", 1) 

SafeAddString(SI_COMBAT_METRICS_SAVED_FIGHTS, "Сохранённые битвы", 1) 

-- More UI Strings

SafeAddString(SI_COMBAT_METRICS_ACTIVE_TIME, "Время:", 1) 
SafeAddString(SI_COMBAT_METRICS_ZERO_SEC, "0 с", 1) 
SafeAddString(SI_COMBAT_METRICS_IN_COMBAT, "В бою:", 1) 

SafeAddString(SI_COMBAT_METRICS_PLAYER, "Игрок", 1) 

--SafeAddString(SI_COMBAT_METRICS_TOTALC, " Total: ", 1) 
SafeAddString(SI_COMBAT_METRICS_NORMAL, "Обычн.:", 1) 
SafeAddString(SI_COMBAT_METRICS_CRITICAL, "Крит.:", 1) 
SafeAddString(SI_COMBAT_METRICS_BLOCKED, "Блок.:", 1) 
SafeAddString(SI_COMBAT_METRICS_SHIELDED, "Поглощено:", 1) 
--SafeAddString(SI_COMBAT_METRICS_ABSOLUTEC, "Absolute: ", 1) 
--SafeAddString(SI_COMBAT_METRICS_OVERHEAL, "Overheal: ", 1) -- as in overheal

SafeAddString(SI_COMBAT_METRICS_HITS, "Удары", 1) 
--SafeAddString(SI_COMBAT_METRICS_NORM, "Norm", 1) -- Normal, short

SafeAddString(SI_COMBAT_METRICS_RESOURCES, "Ресурсы", 1) 

SafeAddString(SI_COMBAT_METRICS_STATS, "Характеристики", 1) 
SafeAddString(SI_COMBAT_METRICS_AVE, "Сред.", 1) -- Average, short
--SafeAddString(SI_COMBAT_METRICS_AVE_N, "Avg N", 1) -- Average Normal, short
--SafeAddString(SI_COMBAT_METRICS_AVE_C, "Avg C", 1) -- Average Crit, short
--SafeAddString(SI_COMBAT_METRICS_AVERAGE, "Average", 1) 
--SafeAddString(SI_COMBAT_METRICS_NORMAL_HITS, "Normal Hits", 1) 
SafeAddString(SI_COMBAT_METRICS_MAX, "Макс.", 1) -- Maximum
--SafeAddString(SI_COMBAT_METRICS_MIN, "Min", 1) -- Minimum

SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA1, "Макс. Магии:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA2, "Маг.урон:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA3, "Крит. закл.:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT3, "%.1f %%", 1) -- e.g. 12.3%
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA4, "Крит. урон:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA5, "Маг. пробив.:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA6, "Сверхпробив.:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT6, "%.1f %%", 1) -- e.g. 12.3%

SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA1, "Макс. Запаса Сил:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA2, "Урон оружия:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA3, "Крит. оружия:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA_FORMAT3, "%.1f %%", 1) -- e.g. 12.3%
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA4, "Крит. урон:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA5, "Физ. пробив.:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA6, "Сверхпробив.:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA_FORMAT6, "%.1f %%", 1) -- e.g. 12.3%

SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH1, "Макс. Здоровья:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH2, "Физ. сопрот.:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH3, "Маг. сопрот.:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH4, "Крит. сопрот.:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH_FORMAT4, "%.1f %%", 1) -- e.g. 12.3%

--SafeAddString(SI_COMBAT_METRICS_PENETRATION_TT, "Penetration: Damage", 1) 

SafeAddString(SI_COMBAT_METRICS_COMBAT_LOG, "Лог боя", 1) 

SafeAddString(SI_COMBAT_METRICS_GOTO_PREVIOUS, "Предыдущая страница", 1) 
SafeAddString(SI_COMBAT_METRICS_PAGE, "Страница <<1>>", 1) -- <<1>> = page number
SafeAddString(SI_COMBAT_METRICS_GOTO_NEXT, "Следующая страница", 1) 

SafeAddString(SI_COMBAT_METRICS_TOGGLE_HEAL, "События входящего исцеления", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_DAMAGE, "События входящего урона", 1) 

SafeAddString(SI_COMBAT_METRICS_TOGGLE_YOUR_HEAL, "События вашего исцеления", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_YOUR_DAMAGE, "События вашего урона", 1) 

SafeAddString(SI_COMBAT_METRICS_TOGGLE_BUFFIN_EVENTS, "Входящие события баффов", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_BUFFOUT_EVENTS, "Исходящие события баффов", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_GROUPBUFFIN_EVENTS, "Входящие события групповых баффов", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_GROUPBUFFOUT_EVENTS, "Исходящие события групповых баффов", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_RESOURCE_EVENTS, "События ресурсов", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_STATS_CHANGE_EVENTS, "События изменения характеристик", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_MESSAGE_CHANGE_EVENTS, "Информационные события, например, переключение оружия", 1) 
--SafeAddString(SI_COMBAT_METRICS_TOGGLE_SKILL_USE_EVENTS, "Toggle used skills events", 1) 

-- \n = new line

SafeAddString(SI_COMBAT_METRICS_DEBUFF_IN, "(Де-)Баффы\nВх.", 1) 
SafeAddString(SI_COMBAT_METRICS_DEBUFF_OUT, "(Де-)Баффы\nИсх.", 1) 
SafeAddString(SI_COMBAT_METRICS_MAGICKA_PM, "Магия\n +/-", 1) 
SafeAddString(SI_COMBAT_METRICS_STAMINA_PM, "Запас сил\n +/-", 1) 
SafeAddString(SI_COMBAT_METRICS_RESOURCES_PM, "Ресурсы\n +/-", 1) 

SafeAddString(SI_COMBAT_METRICS_BUFF, "Бафф", 1) 
--SafeAddString(SI_COMBAT_METRICS_BUFFS, "Buffs", 1) 
--SafeAddString(SI_COMBAT_METRICS_DEBUFFS, "Debuffs", 1) 
SafeAddString(SI_COMBAT_METRICS_SHARP, "#", 1) 
SafeAddString(SI_COMBAT_METRICS_BUFFCOUNT_TT, "Игрок / Всего", 1) 
SafeAddString(SI_COMBAT_METRICS_UPTIME, "Время", 1) 
SafeAddString(SI_COMBAT_METRICS_UPTIME_TT, "Игрок % / Всего %", 1) 

SafeAddString(SI_COMBAT_METRICS_REGENERATION, "Восстановление", 1) 
SafeAddString(SI_COMBAT_METRICS_CONSUMPTION, "Расход", 1) 
SafeAddString(SI_COMBAT_METRICS_PM_SEC, "±/с", 1) 
SafeAddString(SI_COMBAT_METRICS_TARGET, "Цель", 1) 
SafeAddString(SI_COMBAT_METRICS_PERCENT, "%", 1) 
SafeAddString(SI_COMBAT_METRICS_UNITDPS_TT, "Настоящий DPS, т.е. урон в секунду между вашим первым и последним ударом по этой цели", 1) 

SafeAddString(SI_COMBAT_METRICS_ABILITY, "Способность", 1) 
SafeAddString(SI_COMBAT_METRICS_PER_HITS, "/Удары", 1) 
SafeAddString(SI_COMBAT_METRICS_CRITS_PER, "Крит %", 1) 

SafeAddString(SI_COMBAT_METRICS_FAVOURITE_ADD, "Добавить в избранное", 1) 
SafeAddString(SI_COMBAT_METRICS_FAVOURITE_REMOVE, "Убрать из избранного", 1) 

--SafeAddString(SI_COMBAT_METRICS_SKILL, "Skill", 1) 

--SafeAddString(SI_COMBAT_METRICS_BAR, "Bar ", 1) 
--SafeAddString(SI_COMBAT_METRICS_AVERAGEC, "Average: ", 1) 

--SafeAddString(SI_COMBAT_METRICS_SKILLTIME_LABEL2, "< W / S", 1) -- as in "Weapon / Skill"
--SafeAddString(SI_COMBAT_METRICS_SKILLTIME_LABEL3, "W / S >", 1) 

--SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT1, "Number of casts of this skill", 1) 
--SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT2, "Time since the last weapon/skill activation and the ability activation.", 1) 
--SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT3, "Time between the ability activation and the next weapon/skill activation.", 1) 
--SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT4, "Average time between subsequent activations of this skill", 1) 

--SafeAddString(SI_COMBAT_METRICS_SAVED_DATA, "Saved Data", 1) 

-- Live Report Window

SafeAddString(SI_COMBAT_METRICS_SHOW_XPS, "<<1>> / <<2>> (<<3>>%)", 1) -- Format to show DPS/HPS. <<1>> = own value, <<2>> = group value, <<3>> = percentage

-- Settings Menu

SafeAddString(SI_COMBAT_METRICS_MENU_PROFILES, "Профили", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_AC_NAME, "Настройки на аккаунт", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_AC_TOOLTIP, "Если включено, текущие настройки будут применены ко всем персонажам на аккаунте", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_GS_NAME, "Общие настройки", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_FH_NAME, "История битв", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_FH_TOOLTIP, "Число сохраняемых последних битв", 1) 

--SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_NAME, "Saved Fight Memory", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_TOOLTIP, "Maximum memory size for saved fights in MB", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_WARNING, "Используйте с осторожностью! Большое количество сохранённых данных значительно увеличивает время загрузки. Если файл станет слишком большим, клиент может упасть при попытке открыть его.", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_BOSSFIGHTS_NAME, "Сохранять битвы с боссами", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_BOSSFIGHTS_TOOLTIP, "Сначала удаляются битвы с трэшем, а затем уже битвы с боссами, при достижении лимита сохраняемых битв", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_MG_NAME, "Урон группы", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_MG_TOOLTIP, "Отслеживать события всей группы", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_STACKS_NAME, "Стаки баффов", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_STACKS_TOOLTIP, "Показывает обособленные стаки на панели баффов", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_GL_NAME, "Урон в большой группе", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_GL_TOOLTIP, "Отслеживать урон всей группы в больших группах (более 4 человек в группе)", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LM_NAME, "Облегчённый режим", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_LM_TOOLTIP, "В облегчённом режиме Combat Metrics считает только текущий DPS/HPS в режиме реального времени. Статистика не подсчитывается и не записывается, большое окно отчёта отключено", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_NOPVP_NAME, "Выключить в Сиродиле", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_NOPVP_TOOLTIP, "Выключает логирование битвы в Сиродиле", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LMPVP_NAME, "Облегчённый режим в Сиродиле", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_LMPVP_TOOLTIP, "Переключение на облегчённый режим в Сиродиле. В облегчённом режиме Combat Metrics считает только текущий DPS/HPS в режиме реального времени. Статистика не подсчитывается и не записывается, большое окно отчёта отключено", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_ASCC_NAME, "Автовыбор канала", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_ASCC_TOOLTIP, "Автоматический выбор канала чата при выводе отчёта о DPS/HPS. В группе канал чата /group имеет приоритет перед каналом чата /say.", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_AS_NAME, "Автоскриншот", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_AS_TOOLTIP, "Автоматическое создание скриншота при открытии окна отчёта", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_ML_NAME, "Длительность битвы для скриншота", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_ML_TOOLTIP, "Минимальная длительность битвы в секундах для создания автоматического скриншота", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SF_NAME, "Размер окна отчёта о битве", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SF_TOOLTIP, "Задаёт масштаб всех элементов окна отчёта о битве", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_RESPEN_NAME, "Сопротивляемость и пробивание", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CRUSHER, "Crusher", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CRUSHER_TOOLTIP, "Снижение сопротивляемости от баффа с глифа Crusher. Для золотого глифа максимального уровня: обычный: 1622, infused: 2108", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_MOBRESISTANCE, "Сопротивляемость цели", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_MOBRESISTANCE_TOOLTIP, "Сопротивляемость цели, используемая для расчёта сверхпробивания", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LR_NAME, "Окно текущей статистики", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_ENABLE_NAME, "Включено", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_ENABLE_TOOLTIP, "Включает окно текущей статистики, которое показывает DPS & HPS во время боя", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LR_LOCK, "Заблокировать", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_LR_LOCK_TOOLTIP, "Блокирует окно текущей статистики, его будет нельзя переместить", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LR_ALIGNMENT, "Выравнивать по левому краю", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_LR_ALIGNMENT_TOOLTIP, "Выравнивает цифры урона/исцеления и т.п. в окне текущей статистики по левому краю", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LAYOUT_NAME, "Формат", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_LAYOUT_TOOLTIP, "Выберите формат окна текущей статистики", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SCALE_NAME, "Размер", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SCALE_TOOLTIP, "Размер окна текущей статистики.", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_BGALPHA_NAME, "Прозрачность фона", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_BGALPHA_TOOLTIP, "Задаёт прозрачность для фона", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_DPS_NAME, "DPS", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_DPS_TOOLTIP, "Показывать ваш DPS в окне текущей статистики", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_SDPS_NAME, "DPS по одиночной цели", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_SDPS_TOOLTIP, "Показывает ваш DPS по одиночной цели, по урону, который вы нанесли в окне текущей статистики", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_HPS_NAME, "HPS", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_HPS_TOOLTIP, "Показывать ваш HPS в окне текущей статистики", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_NAME, "Вх. DPS", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_TOOLTIP, "Показывать ваш Входящий DPS в окне текущей статистики", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_NAME, "Вх. HPS", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_TOOLTIP, "Показывать ваш Входящий HPS в окне текущей статистики", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_TIME_NAME, "Время", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_TIME_TOOLTIP, "Показывать время, в течение которого вы наносили урон, в окне текущей статистики", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE, "Лог боя в чат", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_DH_TOOLTIP, "Транслировать события Урона и Исцеления в окно чата", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE_NAME, "Лог в чат", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE_TOOLTIP, "Показывает в чате в режиме реального времени наносимый вами урон", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SD_NAME, "Урон", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SD_TOOLTIP, "Показывает наносимый вами Урон в окно чата", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SH_NAME, "Исцеление", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SH_TOOLTIP, "Показывает наносимое вами Исцеление в окно чата", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SID_NAME, "Входящий Урон", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SID_TOOLTIP, "Показывает Входящий Урон в окно чата", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SIH_NAME, "Входящее Исцеление", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SIH_TOOLTIP, "Показывает Входящее Исцеление в окно чата", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_TITLE, "Настройки отладки", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SF_NAME, "Сводка боя", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SF_TOOLTIP, "Выводит результаты боя в системное окно чата", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SA_NAME, "ID способностей", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SA_TOOLTIP, "Показывает ID способностей в окне отчёта", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SFC_NAME, "Инфо подсчёта битвы", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SFC_TOOLTIP, "Выводит информацию о подсчёте таймингов в системное окно чата", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_BI_NAME, "Инфо Баффов", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_BI_TOOLTIP, "Выводит события Баффов в системное окно чата (Заспамливание)", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_US_NAME, "Использованные способности", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_US_TOOLTIP, "Выводит события использованных способностей в системное окно чата", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SG_NAME, "Инфо о группе", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SG_TOOLTIP, "Выводит информацию о присоединении и покидании группы в системное окно чата", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_MD_NAME, "Прочая отладочная инфа", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_MD_TOOLTIP, "Выводит информацию о прочих событиях боя в системное окно чата", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SPECIAL_NAME, "Особая отладочная инфа", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SPECIAL_TOOLTIP, "Выводит информацию об особых событиях боя в системное окно чата", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SAVE_NAME, "Инфо о сохр. данных", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SAVE_TOOLTIP, "Выводит отладочную информацию о сохранённых и загруженных битвах в системное окно чата", 1) 

-- make a label for keybinding

SafeAddString(SI_BINDING_NAME_CMX_REPORT_TOGGLE, "Вкл. отчёт о битве", 1) 
SafeAddString(SI_BINDING_NAME_CMX_LIVEREPORT_TOGGLE, "Вкл. окно текущей статистики", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_SMART, "Отправить DPS по Боссу или общий", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_SINGLE, "Отправить DPS по одиночной цели", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_MULTI, "Отправить DPS по всем целям", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS, "Отправить DPS по одиночной + всем целям", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_HPS, "Отправить HPS в чат", 1) 
SafeAddString(SI_BINDING_NAME_CMX_RESET_FIGHT, "Сбросить статистику битвы", 1) 

