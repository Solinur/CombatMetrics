
-- Functionality

SafeAddString(SI_COMBAT_METRICS_LANG, "jp", 1) 
--SafeAddString(SI_COMBAT_METRICS_ENCHANTMENT_TRIM, " Enchantment", 1) -- this will be removed from the items enchantment string to show the rest in the info panel, e.g. "Spell Damage Enchantment" is reduced to "Spell Damage".

-- Fonts

SafeAddString(SI_COMBAT_METRICS_STD_FONT, "EsoUI/Common/Fonts/ESO_FWNTLGUDC70-DB.ttf", 1) 
SafeAddString(SI_COMBAT_METRICS_BOLD_FONT, "EsoUI/Common/Fonts/ESO_FWNTLGUDC70-DB.ttf", 1) 

--SafeAddString(SI_COMBAT_METRICS_FONT_SIZE_SMALL, "14", 1) 
SafeAddString(SI_COMBAT_METRICS_FONT_SIZE, "11", 1) 
--SafeAddString(SI_COMBAT_METRICS_FONT_SIZE_TITLE, "20", 1) 

-- Main UI

SafeAddString(SI_COMBAT_METRICS_CALC, "計算中...", 1) 
--SafeAddString(SI_COMBAT_METRICS_FINALISING, "Finalising...", 1) 
SafeAddString(SI_COMBAT_METRICS_GROUP, "グループ", 1) 
SafeAddString(SI_COMBAT_METRICS_SELECTION, "選択中", 1) 

SafeAddString(SI_COMBAT_METRICS_BASE_REG, "基本再生", 1) 
SafeAddString(SI_COMBAT_METRICS_DRAIN, "吸収", 1) 
SafeAddString(SI_COMBAT_METRICS_UNKNOWN, "不明", 1) 

SafeAddString(SI_COMBAT_METRICS_BLOCKS, "Blocks", 1) 
SafeAddString(SI_COMBAT_METRICS_CRITS, "クリ", 1) 

SafeAddString(SI_COMBAT_METRICS_DAMAGE, "ダメージ", 1) 
--SafeAddString(SI_COMBAT_METRICS_DAMAGEC, "Damage: ", 1) 
SafeAddString(SI_COMBAT_METRICS_HIT, "ヒット", 1) 
SafeAddString(SI_COMBAT_METRICS_DPS, "DPS", 1) 
--SafeAddString(SI_COMBAT_METRICS_INCOMING_DPS, "Incoming DPS", 1) 

SafeAddString(SI_COMBAT_METRICS_HEALING, "回復", 1) 
SafeAddString(SI_COMBAT_METRICS_HEALS, "回復数", 1) 
SafeAddString(SI_COMBAT_METRICS_HPS, "HPS", 1) 
--SafeAddString(SI_COMBAT_METRICS_INCOMING_HPS, "Incoming HPS", 1) 

--SafeAddString(SI_COMBAT_METRICS_EDIT_TITLE, "Double click to edit fight name", 1) 

SafeAddString(SI_COMBAT_METRICS_DAMAGE_CAUSED, "与えたダメージ", 1) 
SafeAddString(SI_COMBAT_METRICS_DAMAGE_RECEIVED, "受けたダメージ", 1) 
SafeAddString(SI_COMBAT_METRICS_HEALING_DONE, "行った回復", 1) 
--SafeAddString(SI_COMBAT_METRICS_HEALING_RECEIVED, "Healing Recieved", 1) 

--SafeAddString(SI_COMBAT_METRICS_TOGGLE_FIGHTSTATS, "Fight Stats", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_COMBAT_LOG, "戦闘ログの切り替え", 1) 
--SafeAddString(SI_COMBAT_METRICS_TOGGLE_GRAPH, "Graph", 1) 
--SafeAddString(SI_COMBAT_METRICS_TOGGLE_INFO, "Info", 1) 
--SafeAddString(SI_COMBAT_METRICS_TOGGLE_SETTINGS, "Options", 1) 

-- Options Menu Strings

--SafeAddString(SI_COMBAT_METRICS_SHOWIDS, "Show IDs", 1) -- (for units, buffs and abilities)
--SafeAddString(SI_COMBAT_METRICS_HIDEIDS, "Hide IDs", 1) -- (for units, buffs and abilities)

--SafeAddString(SI_COMBAT_METRICS_POSTDPS, "Post DPS/HPS", 1) 
--SafeAddString(SI_COMBAT_METRICS_POSTSINGLEDPS, "Post single target DPS", 1) 
--SafeAddString(SI_COMBAT_METRICS_POSTSMARTDPS, "Post boss target DPS", 1) 
--SafeAddString(SI_COMBAT_METRICS_POSTMULTIDPS, "Post total DPS", 1) 
--SafeAddString(SI_COMBAT_METRICS_POSTALLDPS, "Post single and total DPS", 1) 
--SafeAddString(SI_COMBAT_METRICS_POSTHPS, "Post HPS", 1) 
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
--SafeAddString(SI_COMBAT_METRICS_TOTAL, "Total", 1) 
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

SafeAddString(SI_COMBAT_METRICS_STORAGE_FULL, "ストレージファイルが一杯です。容量確保のため戦闘を削除してください！", 1) 

-- Fight Control Button Tooltips

SafeAddString(SI_COMBAT_METRICS_PREVIOUS_FIGHT, "前回の戦闘", 1) 
SafeAddString(SI_COMBAT_METRICS_NEXT_FIGHT, "次の戦闘", 1) 
SafeAddString(SI_COMBAT_METRICS_MOST_RECENT_FIGHT, "最近の戦闘", 1) 
SafeAddString(SI_COMBAT_METRICS_LOAD_FIGHT, "戦闘のロード", 1) 
SafeAddString(SI_COMBAT_METRICS_SAVE_FIGHT, "戦闘の保存", 1) 
--SafeAddString(SI_COMBAT_METRICS_SAVE_FIGHT2, "Shift+Click: Save fight with combat log", 1) 
SafeAddString(SI_COMBAT_METRICS_DELETE_COMBAT_LOG, "戦闘ログの削除", 1) 
SafeAddString(SI_COMBAT_METRICS_DELETE_FIGHT, "戦闘の削除", 1) 

-- Fight List

SafeAddString(SI_COMBAT_METRICS_RECENT_FIGHT, "最近の戦闘", 1) 
SafeAddString(SI_COMBAT_METRICS_DURATION, "期間", 1) 
--SafeAddString(SI_COMBAT_METRICS_CHARACTER, "Character", 1) 
--SafeAddString(SI_COMBAT_METRICS_ZONE, "Zone", 1) 
--SafeAddString(SI_COMBAT_METRICS_TIME, "Time", 1) 
--SafeAddString(SI_COMBAT_METRICS_TIMEC, "Time: ", 1) 

SafeAddString(SI_COMBAT_METRICS_SHOW, "表示", 1) 
SafeAddString(SI_COMBAT_METRICS_DELETE, "削除", 1) 

SafeAddString(SI_COMBAT_METRICS_SAVED_FIGHTS, "保存された戦闘", 1) 

-- More UI Strings

SafeAddString(SI_COMBAT_METRICS_ACTIVE_TIME, "有効時間:", 1) 
SafeAddString(SI_COMBAT_METRICS_ZERO_SEC, "0 秒", 1) 
SafeAddString(SI_COMBAT_METRICS_IN_COMBAT, "戦闘中:", 1) 

SafeAddString(SI_COMBAT_METRICS_PLAYER, "プレイヤー", 1) 

SafeAddString(SI_COMBAT_METRICS_TOTALC, "合計:", 1) 
SafeAddString(SI_COMBAT_METRICS_NORMAL, "通常:", 1) 
SafeAddString(SI_COMBAT_METRICS_CRITICAL, "クリティカル:", 1) 
SafeAddString(SI_COMBAT_METRICS_BLOCKED, "ブロック:", 1) 
SafeAddString(SI_COMBAT_METRICS_SHIELDED, "シールド:", 1) 
--SafeAddString(SI_COMBAT_METRICS_ABSOLUTEC, "Absolute: ", 1) 
--SafeAddString(SI_COMBAT_METRICS_OVERHEAL, "Overheal: ", 1) -- as in overheal

SafeAddString(SI_COMBAT_METRICS_HITS, "ヒット", 1) 
--SafeAddString(SI_COMBAT_METRICS_NORM, "Norm", 1) -- Normal, short

SafeAddString(SI_COMBAT_METRICS_RESOURCES, "リソース", 1) 

SafeAddString(SI_COMBAT_METRICS_STATS, "統計", 1) 
SafeAddString(SI_COMBAT_METRICS_AVE, "平均", 1) -- Average, short
--SafeAddString(SI_COMBAT_METRICS_AVE_N, "Avg N", 1) -- Average Normal, short
--SafeAddString(SI_COMBAT_METRICS_AVE_C, "Avg C", 1) -- Average Crit, short
--SafeAddString(SI_COMBAT_METRICS_AVERAGE, "Average", 1) 
--SafeAddString(SI_COMBAT_METRICS_NORMAL_HITS, "Normal Hits", 1) 
SafeAddString(SI_COMBAT_METRICS_MAX, "最大", 1) -- Maximum
--SafeAddString(SI_COMBAT_METRICS_MIN, "Min", 1) -- Minimum

--SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA1, "Max Magicka", 1) 
--SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA2, "Spell Damage", 1) 
--SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA3, "Spell Critical", 1) 
--SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT3, "%.1f %%", 1) -- e.g. 12.3%
--SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA4, "Critical Damage", 1) 
--SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA5, "Spell Penetration", 1) 
--SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA6, "Overpenetration", 1) 
--SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT6, "%.1f %%", 1) -- e.g. 12.3%

--SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA1, "Max Stamina", 1) 
--SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA2, "Weapon Damage", 1) 
--SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA3, "Weapon Critical", 1) 
--SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA_FORMAT3, "%.1f %%", 1) -- e.g. 12.3%
--SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA4, "Critical Damage", 1) 
--SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA5, "Phys. Penetration", 1) 
--SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA6, "Overpenetration", 1) 
--SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA_FORMAT6, "%.1f %%", 1) -- e.g. 12.3%

--SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH1, "Max Health", 1) 
--SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH2, "Physical Resist.", 1) 
--SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH3, "Spell Resistance", 1) 
--SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH4, "Critical Resist.", 1) 
--SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH_FORMAT4, "%.1f %%", 1) -- e.g. 12.3%

--SafeAddString(SI_COMBAT_METRICS_PENETRATION_TT, "Penetration: Damage", 1) 

SafeAddString(SI_COMBAT_METRICS_COMBAT_LOG, "戦闘ログ", 1) 

SafeAddString(SI_COMBAT_METRICS_GOTO_PREVIOUS, "前のページへ", 1) 
SafeAddString(SI_COMBAT_METRICS_PAGE, "ページ <<1>>", 1) -- <<1>> = page number
SafeAddString(SI_COMBAT_METRICS_GOTO_NEXT, "次のページへ", 1) 

SafeAddString(SI_COMBAT_METRICS_TOGGLE_HEAL, "受けた回復のイベントを切り替える", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_DAMAGE, "受けたダメージのイベントを切り替える", 1) 

SafeAddString(SI_COMBAT_METRICS_TOGGLE_YOUR_HEAL, "あなたが回復したイベントを切り替える", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_YOUR_DAMAGE, "あなたのダメージイベントを切り替える", 1) 

--SafeAddString(SI_COMBAT_METRICS_TOGGLE_BUFFIN_EVENTS, "Toggle incoming buff events", 1) 
--SafeAddString(SI_COMBAT_METRICS_TOGGLE_BUFFOUT_EVENTS, "Toggle outbound buff events", 1) 
--SafeAddString(SI_COMBAT_METRICS_TOGGLE_GROUPBUFFIN_EVENTS, "Toggle incoming groupbuff events", 1) 
--SafeAddString(SI_COMBAT_METRICS_TOGGLE_GROUPBUFFOUT_EVENTS, "Toggle outbound groupbuff events", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_RESOURCE_EVENTS, "リソースのイベントを切り替える", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_STATS_CHANGE_EVENTS, "統計の変化イベントを切り替える", 1) 
--SafeAddString(SI_COMBAT_METRICS_TOGGLE_MESSAGE_CHANGE_EVENTS, "Toggle info events (e.g. weapon swap)", 1) 
--SafeAddString(SI_COMBAT_METRICS_TOGGLE_SKILL_USE_EVENTS, "Toggle used skills events", 1) 

-- \n = new line

--SafeAddString(SI_COMBAT_METRICS_DEBUFF_IN, "(De-)Buffs\nIn", 1) 
SafeAddString(SI_COMBAT_METRICS_DEBUFF_OUT, "（デ）バフ\nアウト", 1) 
SafeAddString(SI_COMBAT_METRICS_MAGICKA_PM, "マジカ\n +/-", 1) 
SafeAddString(SI_COMBAT_METRICS_STAMINA_PM, "スタミナ\n +/-", 1) 
--SafeAddString(SI_COMBAT_METRICS_RESOURCES_PM, "Resources\n +/-", 1) 

SafeAddString(SI_COMBAT_METRICS_BUFF, "バフ", 1) 
--SafeAddString(SI_COMBAT_METRICS_BUFFS, "Buffs", 1) 
--SafeAddString(SI_COMBAT_METRICS_DEBUFFS, "Debuffs", 1) 
SafeAddString(SI_COMBAT_METRICS_SHARP, "回数", 1) 
--SafeAddString(SI_COMBAT_METRICS_BUFFCOUNT_TT, "Player / Overall", 1) 
SafeAddString(SI_COMBAT_METRICS_UPTIME, "時間", 1) 
--SafeAddString(SI_COMBAT_METRICS_UPTIME_TT, "Player % / Overall %", 1) 

--SafeAddString(SI_COMBAT_METRICS_REGENERATION, "Regeneration", 1) 
--SafeAddString(SI_COMBAT_METRICS_CONSUMPTION, "Consumption", 1) 
SafeAddString(SI_COMBAT_METRICS_PM_SEC, "±/秒", 1) 
SafeAddString(SI_COMBAT_METRICS_TARGET, "ターゲット", 1) 
SafeAddString(SI_COMBAT_METRICS_PERCENT, "%", 1) 
--SafeAddString(SI_COMBAT_METRICS_UNITDPS_TT, "Real DPS, e.g. the damage per second between your first and your last hit to that target", 1) 

--SafeAddString(SI_COMBAT_METRICS_ABILITY, "Ability", 1) 
SafeAddString(SI_COMBAT_METRICS_PER_HITS, "/ヒット", 1) 
SafeAddString(SI_COMBAT_METRICS_CRITS_PER, "クリ %", 1) 

--SafeAddString(SI_COMBAT_METRICS_FAVOURITE_ADD, "Add to Favourites", 1) 
--SafeAddString(SI_COMBAT_METRICS_FAVOURITE_REMOVE, "Remove from Favourites", 1) 

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

SafeAddString(SI_COMBAT_METRICS_MENU_PROFILES, "プロファイル", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_AC_NAME, "アカウント全体設定を使用", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_AC_TOOLTIP, "有効な場合アカウントの全てのキャラクターで設定を共有する", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_GS_NAME, "一般設定", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_FH_NAME, "戦闘履歴", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_FH_TOOLTIP, "保存する最近の戦闘の数", 1) 

--SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_NAME, "Saved Fight Memory", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_TOOLTIP, "Maximum memory size for saved fights in MB", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_WARNING, "Use with caution! Lots of saved data significantly increase loading times. If the file gets too large, the client might crash when attempting to load it.", 1) 

--SafeAddString(SI_COMBAT_METRICS_MENU_BOSSFIGHTS_NAME, "Keep Boss Fights", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_BOSSFIGHTS_TOOLTIP, "Delete trash fights first before deleting boss fights when limit of fights is reached", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_MG_NAME, "グループダメージを監視", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_MG_TOOLTIP, "グループ全体のイベントを監視する", 1) 

--SafeAddString(SI_COMBAT_METRICS_MENU_STACKS_NAME, "Show stacks of buffs", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_STACKS_TOOLTIP, "Show individual stacks in the buff panel", 1) 

--SafeAddString(SI_COMBAT_METRICS_MENU_GL_NAME, "Monitor Damage in large groups", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_GL_TOOLTIP, "Monitor group damage in large groups (more than 4 group members)", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LM_NAME, "軽量モード", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_LM_TOOLTIP, "軽量モード時は、combat metricsはライブレポートウィンドウでDPSとHPSのみ計測します。統計は出力されず大きなレポートウィンドウは無効になります。", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_NOPVP_NAME, "シロディールでオフにする", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_NOPVP_TOOLTIP, "シロディールで全ての戦闘ログをオフにします。", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LMPVP_NAME, "シロディールで軽量モード", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_LMPVP_TOOLTIP, "シロディールで軽量モードに切り替えます。軽量モード時は、combat metricsはライブレポートウィンドウでDPSとHPSのみ計測します。統計は出力されず大きなレポートウィンドウは無効になります。", 1) 

--SafeAddString(SI_COMBAT_METRICS_MENU_ASCC_NAME, "Auto Select Channel", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_ASCC_TOOLTIP, "Automatically select the channel when posting DPS/HPS to chat. When in group the /group chat is used otherwise the /say chat.", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_AS_NAME, "自動スクリーンショット", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_AS_TOOLTIP, "レポートを開いた時に自動的にスクリーンショットを撮る", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_ML_NAME, "スクリーンショットの最小戦闘期間", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_ML_TOOLTIP, ", 1)  --", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SF_NAME, "戦闘レポートの大きさ", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SF_TOOLTIP, ", 1)  --", 1) 

--SafeAddString(SI_COMBAT_METRICS_MENU_RESPEN_NAME, "Resistance and Penetration", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_CRUSHER, "Crusher", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_CRUSHER_TOOLTIP, "Resistance reduction due to debuff from Crusher glyph. For maxlevel gold glyph: standard: 1622, infused: 2108, infused + Torug's: 2740", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_MOBRESISTANCE, "Target resistance", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_MOBRESISTANCE_TOOLTIP, "Target resistance that is assumed for overpenetration calculation", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LR_NAME, "ライブレポート", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_ENABLE_NAME, "有効", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_ENABLE_TOOLTIP, "ライブレポートへの戦闘中のDPSとHPSの表示を有効にする", 1) 

--SafeAddString(SI_COMBAT_METRICS_MENU_LR_LOCK, "Lock", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_LR_LOCK_TOOLTIP, "Lock the Live Report Window, so it can't be moved", 1) 

--SafeAddString(SI_COMBAT_METRICS_MENU_LR_ALIGNMENT, "Use left-aligned numbers", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_LR_ALIGNMENT_TOOLTIP, "Sets positioning of Damage/Heal/etc. numbers for the Live Report Window to left-aligned", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LAYOUT_NAME, "レイアウト", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_LAYOUT_TOOLTIP, "ライブレポートのレイアウトを選択する", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SCALE_NAME, "大きさ", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SCALE_TOOLTIP, "ライブレポートの大きさ", 1) 

--SafeAddString(SI_COMBAT_METRICS_MENU_BGALPHA_NAME, "Background Opacity", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_BGALPHA_TOOLTIP, "Set the Opacity of the Background", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_DPS_NAME, "DPSの表示", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_DPS_TOOLTIP, "ライブレポートに与えたDPSを表示する", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_SDPS_NAME, "Show single target DPS", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_SDPS_TOOLTIP, "Show single target DPS you deal in Live Report Window", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_HPS_NAME, "HPSの表示", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_HPS_TOOLTIP, "ライブレポートに唱えたHPSを表示する", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_NAME, "被DPSの表示", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_TOOLTIP, "ライブレポートに受けたDPSを表示する", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_NAME, "被HPSの表示", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_TOOLTIP, "ライブレポートに受けたHPSを表示する", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_TIME_NAME, "時間の表示", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_TIME_TOOLTIP, "ライブレポートに与えたダメージの時間を表示する", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE, "チャットに戦闘ログを流す", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_DH_TOOLTIP, "チャット欄にダメージと回復イベントを流す", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE_NAME, "Chat Log Title", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE_TOOLTIP, "Show damage you deal in chat stream", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SD_NAME, "ダメージの表示", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SD_TOOLTIP, "チャット欄に与えたダメージを表示する", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SH_NAME, "回復の表示", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SH_TOOLTIP, "チャット欄に唱えたヒーを表示する", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SID_NAME, "被ダメージの表示", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SID_TOOLTIP, "チャット欄に受けたダメージを表示する", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SIH_NAME, "被回復の表示", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SIH_TOOLTIP, "チャット欄に受けた回復を表示する", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_TITLE, "デバッグオプション", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SF_NAME, "戦闘結果の表示", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SF_TOOLTIP, "システムチャット欄に戦闘結果を出力する", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SA_NAME, "アビリティIDの表示", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SA_TOOLTIP, "戦闘レポートにアビリティのIDを表示する", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SFC_NAME, "戦闘計算情報の表示", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SFC_TOOLTIP, "システムチャット欄に計算タイミングに関する情報を出力する", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_BI_NAME, "バフ情報の表示", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_BI_TOOLTIP, "システムチャット欄にバフイベントを出力する（スパム）", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_US_NAME, "使用スキルの情報の表示", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_US_TOOLTIP, "システムチャット欄に使用したスキルイベントを出力する", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SG_NAME, "グループ情報の表示", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SG_TOOLTIP, "システムチャット欄にグループへの加入・脱退を出力する", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_MD_NAME, "その他のデバッグ情報の表示", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_MD_TOOLTIP, "システムチャット欄にその他のイベントを出力する", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SPECIAL_NAME, "Show special debug Info", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SPECIAL_TOOLTIP, "Print certain special events to the system chat window", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SAVE_NAME, "Show save data Info", 1) 
--SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SAVE_TOOLTIP, "Print debug info about saved and loaded fights to the system chat window", 1) 

-- make a label for keybinding

SafeAddString(SI_BINDING_NAME_CMX_REPORT_TOGGLE, "戦闘レポートの切り替え", 1) 
--SafeAddString(SI_BINDING_NAME_CMX_LIVEREPORT_TOGGLE, "Toggle Live Report", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_SMART, "チャットにボスまたはダメージ合計を投稿する", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_SINGLE, "チャットに単一ターゲットのダメージを投稿する", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_MULTI, "チャットに複数のターゲットのダメージを投稿する", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS, "チャットに単一＋複数のターゲットのダメージを投稿する", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_HPS, "チャットに回復を投稿する", 1) 
--SafeAddString(SI_BINDING_NAME_CMX_RESET_FIGHT, "Manually Reset the Fight", 1) 

