
-- Functionality

SafeAddString(SI_COMBAT_METRICS_LANG, "de", 1)
-- this will be removed from the items enchantment string to show the rest in the info panel, e.g. "Spell Damage Enchantment" is reduced to "Spell Damage".
SafeAddString(SI_COMBAT_METRICS_ENCHANTMENT_TRIM, "Verzauberung:Â ", 1) -- ZOS uses a two byte char here !!!

-- Fonts

--SafeAddString(SI_COMBAT_METRICS_STD_FONT, "EsoUI/Common/Fonts/Univers57.otf", 1)
--SafeAddString(SI_COMBAT_METRICS_BOLD_FONT, "EsoUI/Common/Fonts/Univers67.otf", 1)

--SafeAddString(SI_COMBAT_METRICS_FONT_SIZE_SMALL, "14", 1)
--SafeAddString(SI_COMBAT_METRICS_FONT_SIZE, "15", 1)
--SafeAddString(SI_COMBAT_METRICS_FONT_SIZE_TITLE, "20", 1)

-- Main UI

SafeAddString(SI_COMBAT_METRICS_CALC, "Berechnung...", 1)
SafeAddString(SI_COMBAT_METRICS_FINALIZING, "Berechnung...", 1)
SafeAddString(SI_COMBAT_METRICS_GROUP, "Gruppe", 1)
SafeAddString(SI_COMBAT_METRICS_SELECTION, "Auswahl", 1)

SafeAddString(SI_COMBAT_METRICS_BASE_REG, "Basis Regeneration", 1)
SafeAddString(SI_COMBAT_METRICS_DRAIN, "Verbrauch", 1)
SafeAddString(SI_COMBAT_METRICS_UNKNOWN, "Unbekannt", 1)

SafeAddString(SI_COMBAT_METRICS_BLOCKS, "Blocks", 1)
SafeAddString(SI_COMBAT_METRICS_CRITS, "Crits", 1)

SafeAddString(SI_COMBAT_METRICS_DAMAGE, "Schaden", 1)
SafeAddString(SI_COMBAT_METRICS_DAMAGEC, "Schaden: ", 1)
SafeAddString(SI_COMBAT_METRICS_HIT, "Treffer", 1)
SafeAddString(SI_COMBAT_METRICS_DPS, "DPS", 1)
SafeAddString(SI_COMBAT_METRICS_INCOMING_DPS, "Erhaltene DPS", 1)

SafeAddString(SI_COMBAT_METRICS_HEALING, "Heilung", 1)
SafeAddString(SI_COMBAT_METRICS_HEALS, "Heilungen", 1)
SafeAddString(SI_COMBAT_METRICS_HPS, "HPS", 1)
SafeAddString(SI_COMBAT_METRICS_INCOMING_HPS, "Erhaltene HPS", 1)

SafeAddString(SI_COMBAT_METRICS_EDIT_TITLE, "Doppelklick um zu editieren", 1)

SafeAddString(SI_COMBAT_METRICS_DAMAGE_CAUSED, "Verursachter Schaden", 1)
SafeAddString(SI_COMBAT_METRICS_DAMAGE_RECEIVED, "Erhaltener Schaden", 1)
SafeAddString(SI_COMBAT_METRICS_HEALING_DONE, "Gewirkte Heilung", 1)
SafeAddString(SI_COMBAT_METRICS_HEALING_RECEIVED, "Erhaltene Heilung", 1)

SafeAddString(SI_COMBAT_METRICS_TOGGLE_FIGHTSTATS, "Kampfstatistik", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_COMBAT_LOG, "Kampflog", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_GRAPH, "Graph", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_INFO, "Info", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_SETTINGS, "Optionen", 1)

SafeAddString(SI_COMBAT_METRICS_NOTIFICATION, "PLACEHOLDER", 1)

SafeAddString(SI_COMBAT_METRICS_NOTIFICATION_GUILD, "Info: |cffff00Beyond Infinity|r", 1)
SafeAddString(SI_COMBAT_METRICS_NOTIFICATION_ACCEPT, "Gelesen", 1)
SafeAddString(SI_COMBAT_METRICS_NOTIFICATION_DISCARD, "Meldungen abschalten", 1)

-- Options Menu Strings

SafeAddString(SI_COMBAT_METRICS_SHOWIDS, "IDs zeigen", 1) -- (for units, buffs and abilities)
SafeAddString(SI_COMBAT_METRICS_HIDEIDS, "IDs verstecken", 1) -- (for units, buffs and abilities)

SafeAddString(SI_COMBAT_METRICS_POSTDPS, "DPS/HPS posten", 1)
SafeAddString(SI_COMBAT_METRICS_POSTSINGLEDPS, "Einzel DPS posten", 1)
SafeAddString(SI_COMBAT_METRICS_POSTSMARTDPS, "Boss DPS posten", 1)
SafeAddString(SI_COMBAT_METRICS_POSTMULTIDPS, "Gesamt DPS posten", 1)
SafeAddString(SI_COMBAT_METRICS_POSTALLDPS, "Einzel und Gesamt DPS posten", 1)
SafeAddString(SI_COMBAT_METRICS_POSTHPS, "HPS posten", 1)
SafeAddString(SI_COMBAT_METRICS_POSTUNITDPS, "DPS an dieser Einheit posten", 1)
SafeAddString(SI_COMBAT_METRICS_POSTUNITNAMEDPS, "DPS an allen '<<tm:1>>' posten", 1) -- <<1>> is unitname
SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONDPS, "DPS an ausgewählten Einheiten posten", 1)
SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONHPS, "HPS an ausgewählten Einheiten posten", 1)

-- Format Strings for DPS posting

--SafeAddString(SI_COMBAT_METRICS_BOSS_DPS, "Boss DPS", 1)

SafeAddString(SI_COMBAT_METRICS_POSTDPS_FORMAT, "<<1>> - DPS: <<2>> (<<3>> in <<4>>)", 1) -- for single target DPS (<<1>> = fightname, <<2>> = DPS, <<3>> = damage, <<4>> =  ) e.g. Z'Maja - DPS: 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTSMARTDPS_FORMAT, "<<1>><<2>> - Boss DPS: <<3>> (<<4>> in <<5>>)", 1) -- (<<1>> = fightname, <<2>> = extraunits (can be ""), <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Valariel (+5) - Boss DPS: 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTMULTIDPS_FORMAT, "<<1>> (+<<2>>) - DPS: <<3>> (<<4>> in <<5>>)", 1) -- (<<1>> = fightname, <<2>> = extraunits, <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Some random Mob (+5) - DPS: 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTALLDPS_FORMAT_A, "<<1>> - Gesamt DPS (+<<2>>): <<3>> (<<4>> in <<5>>)", 1) -- multi target part (<<1>> = fightname, <<2>> = extraunits, <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Valariel - Total DPS (+5): 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTALLDPS_FORMAT_B, "<<1>>: <<2>> (<<3>> in <<4>>)", 1) --  single target part (<<1>> = Label, <<2>> = DPS, <<3>> = damage) e.g. Boss DPS (+2): 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONDPS_FORMAT, "<<1>><<2>> - Auswahl DPS: <<3>> (<<4>> in <<5>>)", 1) -- (<<1>> = fightname, <<2>> = extraunits (can be ""), <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Valariel (+5) - Boss DPS: 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTHPS_FORMAT, "<<1>> - HPS: <<2>> (<<3>> in <<4>>)", 1) -- (<<1>> = fightname, <<2>> = HPS, <<3>> = damage, <<4>> = time)  e.g. Z'Maja - HPS: 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONHPS_FORMAT, "<<1>> - Auswahl HPS (x<<2>>): <<3>> (<<4>> in <<5>>)", 1) -- (<<1>> = fightname, <<2>> = units, <<3>> = HPS, <<4>> = damage, <<5>> = time) e.g. Z'Maja - HPS (12): 10000 (1000000 in 1:40.0)

SafeAddString(SI_COMBAT_METRICS_POSTBUFF, "Buff Uptime posten", 1)
SafeAddString(SI_COMBAT_METRICS_POSTBUFF_BOSS, "Buff Uptime an Bossen posten", 1)
SafeAddString(SI_COMBAT_METRICS_POSTBUFF_GROUP, "Buff Uptime an Gruppenmitgliedern posten", 1)
SafeAddString(SI_COMBAT_METRICS_POSTBUFF_FORMAT, "<<1>> - HPS: <<2>> (<<3>><<4[/ auf $d/ auf $d Einheiten]>>)", 1) -- (<<1>> = buff name, <<2>> = relative uptime, <<3>> = uptime, <<4>> = time) e.g. Major Intellect - Uptime: 93.2% (9:26 in 10:07)
SafeAddString(SI_COMBAT_METRICS_POSTBUFF_FORMAT_GROUP, "<<1>> - Uptime: <<2>>/<<5>> (<<3>>/<<6>><<4[/ auf $d/ auf $d Einheiten]>>)", 1) -- (<<1>> = buff name, <<2>> = relative uptime, <<3>> = uptime, <<4>> = units, <<5>> = relative group uptime, <<6>> = group uptime) e.g. Minor Sorcery - Uptime: 55.4%/100.6% (5:36/10:11 in 10:07)

SafeAddString(SI_COMBAT_METRICS_SETTINGS, "Einstellungen", 1)
SafeAddString(SI_COMBAT_METRICS_FEEDBACK, "Feedback / Spenden senden", 1)

-- Graph

SafeAddString(SI_COMBAT_METRICS_TOGGLE_CURSOR, "Cursor und Tooltip ein-/ausschalten", 1)
SafeAddString(SI_COMBAT_METRICS_GRAPH_BUFF_GROUP_SELECTOR, "Gruppen/Solo Modus für Buffs", 1)

SafeAddString(SI_COMBAT_METRICS_RECALCULATE, "Kampf neu berechnen", 1)
SafeAddString(SI_COMBAT_METRICS_SMOOTHED, "Geglättet", 1)
SafeAddString(SI_COMBAT_METRICS_TOTAL, "Gesamt", 1)
SafeAddString(SI_COMBAT_METRICS_ABSOLUTE, "Absolut %", 1)
SafeAddString(SI_COMBAT_METRICS_SMOOTH_LABEL, "Glätten: %d s", 1)
SafeAddString(SI_COMBAT_METRICS_NONE, "Aus", 1)
SafeAddString(SI_COMBAT_METRICS_BOSS_HP, "Boss HP", 1)
SafeAddString(SI_COMBAT_METRICS_ENLARGE, "Maximieren", 1)
SafeAddString(SI_COMBAT_METRICS_SHRINK, "Minimieren", 1)

-- Feedback

SafeAddString(SI_COMBAT_METRICS_FEEDBACK_MAIL, "Nachricht senden", 1)
SafeAddString(SI_COMBAT_METRICS_FEEDBACK_GOLD, "5000g spenden", 1)
SafeAddString(SI_COMBAT_METRICS_FEEDBACK_GOLD2, "25000g spenden", 1)
SafeAddString(SI_COMBAT_METRICS_FEEDBACK_ESOUI, "Webseite (ESOUI)", 1)
SafeAddString(SI_COMBAT_METRICS_FEEDBACK_GITHUB, "GitHub", 1)
SafeAddString(SI_COMBAT_METRICS_FEEDBACK_TEXT, "\nFalls du einen Bug melden willst, einen Vorschlag oder eine Frage hast, sende eine Nachricht, erstelle eine Meldung auf Github oder schreibe in die Kommentare auf ESOUI. \n\nSpenden werden gern entgegen genommen, werden aber nicht dringend gebraucht. \nFalls du mir nen Kaffee oder ein Bier ausgeben möchtest kannst du auf der ESOUI-Seite über Paypal spenden.", 1)

SafeAddString(SI_COMBAT_METRICS_STORAGE_FULL, "Der Datenspeicher ist voll. Der Kampf, den du speichern möchtest benötigt <<1>> MB. Lösche einen Kampf oder Kampflog, um Platz zu schaffen oder erhöhe die erlaubte Größe des Speichers in den Einstellungen.", 1)

-- Fight Control Button Tooltips

SafeAddString(SI_COMBAT_METRICS_PREVIOUS_FIGHT, "Vorheriger Kampf", 1)
SafeAddString(SI_COMBAT_METRICS_NEXT_FIGHT, "Nächster Kampf", 1)
SafeAddString(SI_COMBAT_METRICS_MOST_RECENT_FIGHT, "Letzter Kampf", 1)
SafeAddString(SI_COMBAT_METRICS_LOAD_FIGHT, "Kampf laden", 1)
SafeAddString(SI_COMBAT_METRICS_SAVE_FIGHT, "Klick: Kampf speichern", 1)
SafeAddString(SI_COMBAT_METRICS_SAVE_FIGHT2, "Shift+Klick: Kampf inklusive Log speichern", 1)
SafeAddString(SI_COMBAT_METRICS_DELETE_COMBAT_LOG, "Kampf Log löschen", 1)
SafeAddString(SI_COMBAT_METRICS_DELETE_FIGHT, "Kampf löschen", 1)

-- Fight List

SafeAddString(SI_COMBAT_METRICS_RECENT_FIGHT, "Letzte Kämpfe", 1)
SafeAddString(SI_COMBAT_METRICS_DURATION, "Dauer", 1)
SafeAddString(SI_COMBAT_METRICS_CHARACTER, "Charakter", 1)
SafeAddString(SI_COMBAT_METRICS_ZONE, "Zone", 1)
SafeAddString(SI_COMBAT_METRICS_TIME, "Zeit", 1)
SafeAddString(SI_COMBAT_METRICS_TIMEC, "Zeit: ", 1)

SafeAddString(SI_COMBAT_METRICS_SHOW, "Zeigen", 1)
SafeAddString(SI_COMBAT_METRICS_DELETE, "Löschen", 1)

SafeAddString(SI_COMBAT_METRICS_SAVED_FIGHTS, "Gespeicherte Kämpfe", 1)

-- More UI Strings

SafeAddString(SI_COMBAT_METRICS_ACTIVE_TIME, "Aktive Zeit: ", 1)
SafeAddString(SI_COMBAT_METRICS_ZERO_SEC, "0 s", 1)
SafeAddString(SI_COMBAT_METRICS_IN_COMBAT, "Im Kampf: ", 1)

SafeAddString(SI_COMBAT_METRICS_PLAYER, "Spieler", 1)

SafeAddString(SI_COMBAT_METRICS_TOTALC, "Gesamt: ", 1)
SafeAddString(SI_COMBAT_METRICS_NORMAL, "Normal: ", 1)
SafeAddString(SI_COMBAT_METRICS_CRITICAL, "Kritisch: ", 1)
SafeAddString(SI_COMBAT_METRICS_BLOCKED, "Geblockt: ", 1)
SafeAddString(SI_COMBAT_METRICS_SHIELDED, "Absorbiert: ", 1)
SafeAddString(SI_COMBAT_METRICS_ABSOLUTEC, "Absolut: ", 1)
SafeAddString(SI_COMBAT_METRICS_OVERHEAL, "Overheal: ", 1) -- as in overheal

SafeAddString(SI_COMBAT_METRICS_HITS, "Treffer", 1)
SafeAddString(SI_COMBAT_METRICS_NORM, "Norm", 1) -- Normal, short

SafeAddString(SI_COMBAT_METRICS_RESOURCES, "Ressourcen", 1)

SafeAddString(SI_COMBAT_METRICS_STATS, "Stats", 1)
SafeAddString(SI_COMBAT_METRICS_AVE, "MW", 1) -- Average, short
SafeAddString(SI_COMBAT_METRICS_AVE_N, "MW N", 1) -- Average Normal, short
SafeAddString(SI_COMBAT_METRICS_AVE_C, "MW C", 1) -- Average Crit, short
SafeAddString(SI_COMBAT_METRICS_AVERAGE, "Mittelwert", 1)
SafeAddString(SI_COMBAT_METRICS_NORMAL_HITS, "Normale Treffer", 1)
SafeAddString(SI_COMBAT_METRICS_MAX, "Max", 1) -- Maximum
SafeAddString(SI_COMBAT_METRICS_MIN, "Min", 1) -- Minimum

SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA1, "Max Magicka", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA2, "Zauberschaden", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA3, "Krit. Trefferrate", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT3, "%.1f %%", 1) -- e.g. 12.3%
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA4, "Kritischer Schaden", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA5, "Zauberdurchdringung", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA6, "Overpenetration", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT6, "%.1f %%", 1) -- e.g. 12.3%

SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA1, "Max Stamina", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA2, "Waffenschaden", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA3, "Krit. Trefferrate", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA_FORMAT3, "%.1f %%", 1) -- e.g. 12.3%
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA4, "Kritischer Schaden", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA5, "Waffendurchdringung", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA6, "Overpenetration", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA_FORMAT6, "%.1f %%", 1) -- e.g. 12.3%

SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH1, "Max Leben", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH2, "Waffenresistenz", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH3, "Zauberresistenz", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH4, "Kritische Resistenz", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH_FORMAT4, "%.1f %%", 1) -- e.g. 12.3%

SafeAddString(SI_COMBAT_METRICS_PENETRATION_TT, "Durchdringung: Schaden", 1)

SafeAddString(SI_COMBAT_METRICS_COMBAT_LOG, "Kampf Log", 1)

SafeAddString(SI_COMBAT_METRICS_GOTO_PREVIOUS, "Vorherige Seite", 1)
SafeAddString(SI_COMBAT_METRICS_PAGE, "Seite <<1>>", 1) -- <<1>> = page number
SafeAddString(SI_COMBAT_METRICS_GOTO_NEXT, "Nächste Seite", 1)

SafeAddString(SI_COMBAT_METRICS_TOGGLE_HEAL, "Erhaltene Heilung: ein/aus", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_DAMAGE, "Erhaltener Schaden: ein/aus", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_YOUR_HEAL, "Gewirkte Heilung: ein/aus", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_YOUR_DAMAGE, "Erzielter Schaden: ein/aus", 1)

SafeAddString(SI_COMBAT_METRICS_TOGGLE_BUFFIN_EVENTS, "Erhaltene Buffs: ein/aus", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_BUFFOUT_EVENTS, "Gewirkte Buffs: ein/aus", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_GROUPBUFFIN_EVENTS, "Erhaltene Buffs der Gruppe: ein/aus", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_GROUPBUFFOUT_EVENTS, "Gewirkte Buffs der Gruppe: ein/aus", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_RESOURCE_EVENTS, "Ressourcen: ein/aus", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_STATS_CHANGE_EVENTS, "Änderungen der Charakterwerte: ein/aus", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_MESSAGE_CHANGE_EVENTS, "Infor Events (z.B. Waffenwechsel): ein/aus", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_SKILL_USE_EVENTS, "Benutzte Fertigkeiten: ein/aus", 1)

-- \n = new line

SafeAddString(SI_COMBAT_METRICS_DEBUFF_IN, "(De-)Buffs\n erhalten", 1)
SafeAddString(SI_COMBAT_METRICS_DEBUFF_OUT, "(De-)Buffs\n gewirkt", 1)
SafeAddString(SI_COMBAT_METRICS_MAGICKA_PM, "Magicka\n +/-", 1)
SafeAddString(SI_COMBAT_METRICS_STAMINA_PM, "Stamina\n +/-", 1)
SafeAddString(SI_COMBAT_METRICS_RESOURCES_PM, "Ressourcen\n +/-", 1)

SafeAddString(SI_COMBAT_METRICS_BUFF, "Buff", 1)
SafeAddString(SI_COMBAT_METRICS_BUFFS, "Buffs", 1)
SafeAddString(SI_COMBAT_METRICS_DEBUFFS, "Debuffs", 1)
SafeAddString(SI_COMBAT_METRICS_SHARP, "#", 1)
SafeAddString(SI_COMBAT_METRICS_BUFFCOUNT_TT, "Spieler / Gesamt", 1)
SafeAddString(SI_COMBAT_METRICS_UPTIME, "Uptime", 1)
SafeAddString(SI_COMBAT_METRICS_UPTIME_TT, "Spieler % / Gesamt %", 1)

SafeAddString(SI_COMBAT_METRICS_REGENERATION, "Regeneration", 1)
SafeAddString(SI_COMBAT_METRICS_CONSUMPTION, "Verbrauch", 1)
SafeAddString(SI_COMBAT_METRICS_PM_SEC, "±/s", 1)
SafeAddString(SI_COMBAT_METRICS_TARGET, "Ziel", 1)
SafeAddString(SI_COMBAT_METRICS_PERCENT, "%", 1)
SafeAddString(SI_COMBAT_METRICS_UNITDPS_TT, "Reale DPS, also der Schaden pro Sekunde zwischen dem ersten und letzten Treffer auf das Ziel", 1)

SafeAddString(SI_COMBAT_METRICS_ABILITY, "Fähigkeit", 1)
SafeAddString(SI_COMBAT_METRICS_PER_HITS, "/Treffer", 1)
SafeAddString(SI_COMBAT_METRICS_CRITS_PER, "Krit. %", 1)

SafeAddString(SI_COMBAT_METRICS_FAVOURITE_ADD, "Zu Favouriten hinzufügen", 1)
SafeAddString(SI_COMBAT_METRICS_FAVOURITE_REMOVE, "Aus Favouriten entfernen", 1)

SafeAddString(SI_COMBAT_METRICS_SKILL, "Fertigkeit", 1)

SafeAddString(SI_COMBAT_METRICS_BAR, "Leiste ", 1)
SafeAddString(SI_COMBAT_METRICS_AVERAGEC, "Mittelwert: ", 1)

SafeAddString(SI_COMBAT_METRICS_SKILLTIME_LABEL2, "< W / F", 1) -- as in "Weapon / Skill"
SafeAddString(SI_COMBAT_METRICS_SKILLTIME_LABEL3, "W / F >", 1)

SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT1, "Anzahl der Nutzungen", 1)
SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT2, "Zeit zwischen der letzten Aktivierung von Waffe/Fertigkeit und dieser Fertigkeit.", 1)
SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT3, "Zeit zwischen der letzten Aktivierung dieser Fertigkeit und dem folgenden Einsatz von einer Waffe/Fertigkeit.", 1)
SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT4, "Durchschnittliche Zeit zwischen zwei Aktivierungen dieser Fertigkeit", 1)

SafeAddString(SI_COMBAT_METRICS_SAVED_DATA, "Gespeicherte Daten", 1)

-- Live Report Window

SafeAddString(SI_COMBAT_METRICS_SHOW_XPS, "<<1>> / <<2>> (<<3>>%)", 1) -- Format to show DPS/HPS. <<1>> = own value, <<2>> = group value, <<3>> = percentage

-- Settings Menu

SafeAddString(SI_COMBAT_METRICS_MENU_PROFILES, "Profile", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_AC_NAME, "Konto-weite Einstellungen", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_AC_TOOLTIP, "Wenn aktiviert, teilen alle Charaktere eines Kontos die Einstellungen", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_GS_NAME, "Allgemeine Einstellungen", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_FH_NAME, "Kampfverlauf", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_FH_TOOLTIP, "Anzahl der letzen Kämpfe, die angezeigt werden", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_NAME, "Datenspeicher für Kämpfe", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_TOOLTIP, "Maximale Größe des Datenspeichers für Kämpfe in MB", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_WARNING, "Mit Vorsicht benutzen! Viele gespeicherte Daten führen zu deutlich längeren Ladezeiten beim einloggen. In Extremfällen kann das Spiel dabei sogar abstürzen.", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_BOSSFIGHTS_NAME, "Bosskämpfe erhalten", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_BOSSFIGHTS_TOOLTIP, "Bosskämpfe im Verlauf bevorzugt behalten wenn die maximale Zahl an Kämpfen im Verlauf erreicht ist.", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_MG_NAME, "Schaden der Gruppe ermitteln", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_MG_TOOLTIP, "Monitor the events of the whole group", 1)

--SafeAddString(SI_COMBAT_METRICS_MENU_STACKS_NAME, "Show stacks of buffs", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_STACKS_TOOLTIP, "Show individual stacks in the buff panel", 1)

--SafeAddString(SI_COMBAT_METRICS_MENU_GL_NAME, "Monitor Damage in large groups", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_GL_TOOLTIP, "Monitor group damage in large groups (more than 4 group members)", 1)

--SafeAddString(SI_COMBAT_METRICS_MENU_LM_NAME, "Light Mode", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_LM_TOOLTIP, "When in light mode, combat metrics will only calculate the DPS/HPS in the live report window. No statistics will be calculated and the big report window will be disabled", 1)

--SafeAddString(SI_COMBAT_METRICS_MENU_NOPVP_NAME, "Turn off in Cyrodil", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_NOPVP_TOOLTIP, "Turns all fight logging off in Cyrodil", 1)

--SafeAddString(SI_COMBAT_METRICS_MENU_LMPVP_NAME, "Light Mode in Cyrodil", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_LMPVP_TOOLTIP, "Swiches to light mode in Cyrodil. When in light mode, Combat Metrics will only calculate the DPS/HPS in the live report window. No statistics will be calculated and the big report window will be disabled", 1)

--SafeAddString(SI_COMBAT_METRICS_MENU_ASCC_NAME, "Auto Select Channel", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_ASCC_TOOLTIP, "Automatically select the channel when posting DPS/HPS to chat. When in group the /group chat is used otherwise the /say chat.", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_AS_NAME, "Auto Screenshot", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_AS_TOOLTIP, "Automatically take a Screenshot when opening the Report window", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_ML_NAME, "Minimum fight length for screenshot", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_ML_TOOLTIP, "Minimum fight length in s for auto screenshot", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_SF_NAME, "Scale of Fight Report Window", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_SF_TOOLTIP, "Adjusts the size of all elements of the Fightreport Window", 1)

--SafeAddString(SI_COMBAT_METRICS_MENU_RESPEN_NAME, "Resistance and Penetration", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_CRUSHER, "Crusher", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_CRUSHER_TOOLTIP, "Resistance reduction due to debuff from Crusher glyph. For maxlevel gold glyph: standard: 1622, infused: 2108, infused + Torug's: 2740", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_MOBRESISTANCE, "Target resistance", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_MOBRESISTANCE_TOOLTIP, "Target resistance that is assumed for overpenetration calculation", 1)

--SafeAddString(SI_COMBAT_METRICS_MENU_LR_NAME, "Live Report Window", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_ENABLE_NAME, "Enable", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_ENABLE_TOOLTIP, "Enable Live Report Window which shows DPS & HPS during combat", 1)

--SafeAddString(SI_COMBAT_METRICS_MENU_LR_LOCK, "Lock", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_LR_LOCK_TOOLTIP, "Lock the Live Report Window, so it can't be moved", 1)

--SafeAddString(SI_COMBAT_METRICS_MENU_LR_ALIGNMENT, "Use left-aligned numbers", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_LR_ALIGNMENT_TOOLTIP, "Sets positioning of Damage/Heal/etc. numbers for the Live Report Window to left-aligned", 1)

--SafeAddString(SI_COMBAT_METRICS_MENU_LAYOUT_NAME, "Layout", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_LAYOUT_TOOLTIP, "Select the Layout of the Live Report Window", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_SCALE_NAME, "Scale", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_SCALE_TOOLTIP, "Scale of the Live report window.", 1)

--SafeAddString(SI_COMBAT_METRICS_MENU_BGALPHA_NAME, "Background Opacity", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_BGALPHA_TOOLTIP, "Set the Opacity of the Background", 1)

--SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_DPS_NAME, "Show DPS", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_DPS_TOOLTIP, "Show DPS you deal in Live Report Window", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_SDPS_NAME, "Show single target DPS", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_SDPS_TOOLTIP, "Show single target DPS you deal in Live Report Window", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_HPS_NAME, "Show HPS", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_HPS_TOOLTIP, "Show HPS you cast in Live Report Window", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_NAME, "Show Incoming DPS", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_TOOLTIP, "Show DPS you receive in Live Report Window", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_NAME, "Show Incoming HPS", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_TOOLTIP, "Show HPS you receive in Live Report Window", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_TIME_NAME, "Show Time", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_TIME_TOOLTIP, "Show Time you have been dealing damage in Live Report Window", 1)

--SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE, "Stream Combat Log to chat", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_DH_TOOLTIP, "Streams Damage and Heal Events to chat window", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE_NAME, "Chat Log Title", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE_TOOLTIP, "Show damage you deal in chat stream", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SD_NAME, "Show damage", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SD_TOOLTIP, "Show damage you deal in chat stream", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SH_NAME, "Show heals", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SH_TOOLTIP, "Show heals you cast in chat stream", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SID_NAME, "Show Incoming damage", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SID_TOOLTIP, "Show damage you receive in chat stream", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SIH_NAME, "Show Incoming heal", 1)
--SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SIH_TOOLTIP, "Show heals you receive in chat stream", 1)

-- make a label for keybinding

--SafeAddString(SI_BINDING_NAME_CMX_REPORT_TOGGLE, "Toggle Fight Report", 1)
--SafeAddString(SI_BINDING_NAME_CMX_LIVEREPORT_TOGGLE, "Toggle Live Report", 1)
--SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_SMART, "Post Boss or Total DPS", 1)
--SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_SINGLE, "Post Single Target DPS", 1)
--SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_MULTI, "Post Multi Target DPS", 1)
--SafeAddString(SI_BINDING_NAME_CMX_POST_DPS, "Post Single + Multi Target DPS", 1)
--SafeAddString(SI_BINDING_NAME_CMX_POST_HPS, "Post Heal to Chat", 1)
--SafeAddString(SI_BINDING_NAME_CMX_RESET_FIGHT, "Manually Reset the Fight", 1)

