-- Localization Start

-- Functionality

SafeAddString(SI_COMBAT_METRICS_LANG, "it", 1)
SafeAddString(SI_COMBAT_METRICS_ENCHANTMENT_TRIM, " Incantamento", 1) -- this will be removed from the items enchantment string to show the rest in the info panel, e.g. "Spell Damage Enchantment" is reduced to "Spell Damage".

-- Main UI

SafeAddString(SI_COMBAT_METRICS_CALC, "Calcolo...", 1)
SafeAddString(SI_COMBAT_METRICS_FINALISING, "Completamento...", 1)
SafeAddString(SI_COMBAT_METRICS_GROUP, "Gruppo", 1)
SafeAddString(SI_COMBAT_METRICS_SELECTION, "Selezione", 1)

SafeAddString(SI_COMBAT_METRICS_BASE_REG, "Rigenerazione di base", 1)
SafeAddString(SI_COMBAT_METRICS_DRAIN, "Prosciugamento", 1)
SafeAddString(SI_COMBAT_METRICS_UNKNOWN, "Sconosciuto", 1)

SafeAddString(SI_COMBAT_METRICS_BLOCKS, "Blocchi", 1)
SafeAddString(SI_COMBAT_METRICS_CRITS, "Critici", 1)

SafeAddString(SI_COMBAT_METRICS_DAMAGE, "Danno", 1)
SafeAddString(SI_COMBAT_METRICS_DAMAGEC, "Danno: ", 1)
SafeAddString(SI_COMBAT_METRICS_HIT, "Colpo", 1)
SafeAddString(SI_COMBAT_METRICS_DPS, "DPS", 1)
SafeAddString(SI_COMBAT_METRICS_INCOMING_DPS, "DPS In arrivo", 1)

SafeAddString(SI_COMBAT_METRICS_HEALING, "Guarigione", 1)
SafeAddString(SI_COMBAT_METRICS_HEALS, "Cure", 1)
SafeAddString(SI_COMBAT_METRICS_HPS, "HPS", 1)
SafeAddString(SI_COMBAT_METRICS_HPSA, "HPS + Cure Eccessive", 1)
SafeAddString(SI_COMBAT_METRICS_INCOMING_HPS, "HPS in arrivo", 1)

SafeAddString(SI_COMBAT_METRICS_EDIT_TITLE, "Clicca due volte per modificare il nome dello scontro", 1)

SafeAddString(SI_COMBAT_METRICS_DAMAGE_CAUSED, "Danno Inflitto", 1)
SafeAddString(SI_COMBAT_METRICS_DAMAGE_RECEIVED, "Danno Ricevuto", 1)
SafeAddString(SI_COMBAT_METRICS_HEALING_DONE, "Cure Fatte", 1)
SafeAddString(SI_COMBAT_METRICS_HEALING_RECEIVED, "Cure Ricevute", 1)

SafeAddString(SI_COMBAT_METRICS_TOGGLE_FIGHTSTATS, "Statistiche dello Scontro", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_COMBAT_LOG, "Registro del Combattimento", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_GRAPH, "Grafico", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_INFO, "Informazioni", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_SETTINGS, "Opzioni", 1)

SafeAddString(SI_COMBAT_METRICS_NOTIFICATION, "Il mio Raid |cffff00Beyond Infinity|r sta cercando MagDK/Necro für vCR+3 (Greifenherz).", 1)
SafeAddString(SI_COMBAT_METRICS_NOTIFICATION_GUILD, "Info: |cffff00Beyond Infinity|r", 1)
SafeAddString(SI_COMBAT_METRICS_NOTIFICATION_ACCEPT, "Messaggio letto", 1)
SafeAddString(SI_COMBAT_METRICS_NOTIFICATION_DISCARD, "Disattiva le notifiche", 1)

	-- Options Menu Strings

SafeAddString(SI_COMBAT_METRICS_SHOWIDS, "Mostra ID", 1) -- (for units, buffs and abilities)
SafeAddString(SI_COMBAT_METRICS_HIDEIDS, "Nascondi ID", 1) -- (for units, buffs and abilities)

SafeAddString(SI_COMBAT_METRICS_SHOWOVERHEAL, "Mostra cure eccessive", 1) -- (for units, buffs and abilities)
SafeAddString(SI_COMBAT_METRICS_HIDEOVERHEAL, "Nascondi cure eccessive", 1) -- (for units, buffs and abilities)

SafeAddString(SI_COMBAT_METRICS_POSTDPS, "Invia DPS/HPS", 1)
SafeAddString(SI_COMBAT_METRICS_POSTSINGLEDPS, "Invia DPS Bersaglio Singolo", 1)
SafeAddString(SI_COMBAT_METRICS_POSTSMARTDPS, "Invia DPS Boss", 1)
SafeAddString(SI_COMBAT_METRICS_POSTMULTIDPS, "Invia DPS Totale", 1)
SafeAddString(SI_COMBAT_METRICS_POSTALLDPS, "Invia DPS Singolo e Totale", 1)
SafeAddString(SI_COMBAT_METRICS_POSTHPS, "Invia HPS", 1)
SafeAddString(SI_COMBAT_METRICS_POSTUNITDPS, "Invia DPS a questo gruppo", 1)
SafeAddString(SI_COMBAT_METRICS_POSTUNITNAMEDPS, "Invia DPS a '<<tm:1>>' gruppi", 1) -- <<tm:1>> is unitname
SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONDPS, "Invia DPS ai gruppi selezionati", 1)
SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONHPS, "Invia HPS ai gruppi selezionati", 1)

	-- Format Strings for DPS posting

SafeAddString(SI_COMBAT_METRICS_BOSS_DPS, "Boss DPS", 1)

SafeAddString(SI_COMBAT_METRICS_POSTDPS_FORMAT, "<<1>> - DPS: <<2>> (<<3>> in <<4>>)", 1) -- for single target DPS (<<1>> = fightname, <<2>> = DPS, <<3>> = damage, <<4>> =  ) e.g. Z'Maja - DPS: 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTSMARTDPS_FORMAT, "<<1>><<2>> - Boss DPS: <<3>> (<<4>> in <<5>>)", 1) -- (<<1>> = fightname, <<2>> = extraunits (can be ""), <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Valariel (+5) - Boss DPS: 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTMULTIDPS_FORMAT, "<<1>> (+<<2>>) - DPS: <<3>> (<<4>> in <<5>>)", 1) -- (<<1>> = fightname, <<2>> = extraunits, <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Some random Mob (+5) - DPS: 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTALLDPS_FORMAT_A, "<<1>> - DPS Totale (+<<2>>): <<3>> (<<4>> in <<5>>)", 1) -- multi target part (<<1>> = fightname, <<2>> = extraunits, <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Valariel - Total DPS (+5): 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTALLDPS_FORMAT_B, "<<1>>: <<2>> (<<3>> in <<4>>)", 1) --  single target part (<<1>> = Label, <<2>> = DPS, <<3>> = damage) e.g. Boss DPS (+2): 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONDPS_FORMAT, "<<1>><<2>> -  Selezione DPS: <<3>> (<<4>> in <<5>>)", 1) -- (<<1>> = fightname, <<2>> = extraunits (can be ""), <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Valariel (+5) - Boss DPS: 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTHPS_FORMAT, "<<1>> - HPS: <<2>> (<<3>> in <<4>>)", 1) -- (<<1>> = fightname, <<2>> = HPS, <<3>> = damage, <<4>> = time)  e.g. Z'Maja - HPS: 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONHPS_FORMAT, "<<1>> - Selezione HPS (x<<2>>): <<3>> (<<4>> in <<5>>)", 1) -- (<<1>> = fightname, <<2>> = units, <<3>> = HPS, <<4>> = damage, <<5>> = time) e.g. Z'Maja - HPS (12): 10000 (1000000 in 1:40.0)

SafeAddString(SI_COMBAT_METRICS_POSTBUFF, "Invia Durata del Bonus", 1)
SafeAddString(SI_COMBAT_METRICS_POSTBUFF_BOSS, "Invia Durata del Bonus sui Boss", 1)
SafeAddString(SI_COMBAT_METRICS_POSTBUFF_GROUP, "Invia Durata del Bonus sui membri del gruppo", 1)
SafeAddString(SI_COMBAT_METRICS_POSTBUFF_FORMAT, "<<1>> - Durata: <<2>> (<<3>><<4[/ su $d/ su $d gruppi]>>)", 1) -- (<<1>> = buff name, <<2>> = relative uptime, <<3>> = uptime, <<4>> = time) e.g. Major Intellect - Uptime: 93.2% (9:26 in 10:07)
SafeAddString(SI_COMBAT_METRICS_POSTBUFF_FORMAT_GROUP, "<<1>> - Durata: <<2>>/<<5>> (<<3>>/<<6>><<4[/ su $d/ su $d gruppi]>>)", 1) -- (<<1>> = buff name, <<2>> = relative uptime, <<3>> = uptime, <<4>> = units, <<5>> = relative group uptime, <<6>> = group uptime) e.g. Minor Sorcery - Uptime: 55.4%/100.6% (5:36/10:11 in 10:07)

SafeAddString(SI_COMBAT_METRICS_SETTINGS, "Impostazioni Addon", 1)

	-- Graph

SafeAddString(SI_COMBAT_METRICS_TOGGLE_CURSOR, "Attiva/Disattiva per mostrare il cursore e i suggerimenti", 1)
SafeAddString(SI_COMBAT_METRICS_GRAPH_BUFF_GROUP_SELECTOR, "Attiva/Disattiva per mostrare il tempo di attività del gruppo", 1)

SafeAddString(SI_COMBAT_METRICS_RECALCULATE, "Rielabora lo Scontro ", 1)
SafeAddString(SI_COMBAT_METRICS_SMOOTHED, "Smoothed", 1)
SafeAddString(SI_COMBAT_METRICS_TOTAL, "Totale", 1)
SafeAddString(SI_COMBAT_METRICS_ABSOLUTE, "Assoluto %", 1)
SafeAddString(SI_COMBAT_METRICS_SMOOTH_LABEL, "Smooth: %d s", 1)
SafeAddString(SI_COMBAT_METRICS_NONE, "Nessuno", 1)
SafeAddString(SI_COMBAT_METRICS_BOSS_HP, "HP Boss", 1)
SafeAddString(SI_COMBAT_METRICS_ENLARGE, "Ingrandito", 1)
SafeAddString(SI_COMBAT_METRICS_SHRINK, "Ristretto", 1)

	-- Feedback

SafeAddString(SI_COMBAT_METRICS_FEEDBACK, "Riscontro", 1)

SafeAddString(SI_COMBAT_METRICS_FEEDBACK_SEND, "Invia riscontro", 1)

SafeAddString(SI_COMBAT_METRICS_FEEDBACK_EUONLY_FORMAT, "<<1>> (solo EU)", 1)
SafeAddString(SI_COMBAT_METRICS_FEEDBACK_MAIL, "Ingame mail", 1)
SafeAddString(SI_COMBAT_METRICS_FEEDBACK_MAIL_HEADER, "Riscontro: Combat Metrics %s", 1)

SafeAddString(SI_COMBAT_METRICS_FEEDBACK_ESOUI, "Pagina ESOUI", 1)
SafeAddString(SI_COMBAT_METRICS_FEEDBACK_GITHUB, "GitHub repository", 1)
SafeAddString(SI_COMBAT_METRICS_FEEDBACK_DISCORD, "Discord", 1)

SafeAddString(SI_COMBAT_METRICS_DONATE, "Dona", 1)
SafeAddString(SI_COMBAT_METRICS_DONATE_GOLD, "Oro", 1)
SafeAddString(SI_COMBAT_METRICS_DONATE_GOLD_HEADER, "Donazione: Combat Metrics %s", 1)
SafeAddString(SI_COMBAT_METRICS_DONATE_CROWNS, "Crown", 1)
SafeAddString(SI_COMBAT_METRICS_DONATE_CROWNS_TEXT, "Se vuoi regalare qualcosa dal negozio delle corone, sarei felice di ricevere qualche cassa della corona o oggetti consumabili.\nPuoi anche contattarmi se desideri regalare qualcos'altro.", 1)
SafeAddString(SI_COMBAT_METRICS_DONATE_CROWNS_ACCOUNT, "Il Mio Account:", 1)
SafeAddString(SI_COMBAT_METRICS_DONATE_ESOUI, "Pagina della Donazione", 1)

SafeAddString(SI_COMBAT_METRICS_OK, "OK", 1)

SafeAddString(SI_COMBAT_METRICS_STORAGE_FULL, "Il file di archiviazione è pieno. Lo scontro che vuoi salvare ha bisogno di <<1>> MB. Elimina uno scontro per liberare un po' di spazio o aumenta lo spazio consentito nelle impostazioni!", 1)

	-- Fight Control Button Tooltips

SafeAddString(SI_COMBAT_METRICS_PREVIOUS_FIGHT, "Scontro Precedente", 1)
SafeAddString(SI_COMBAT_METRICS_NEXT_FIGHT, "Scontro Successivo", 1)
SafeAddString(SI_COMBAT_METRICS_MOST_RECENT_FIGHT, "Scontro più Recente", 1)
SafeAddString(SI_COMBAT_METRICS_LOAD_FIGHT, "Carica Scontro", 1)
SafeAddString(SI_COMBAT_METRICS_SAVE_FIGHT, "Clicca: Salva Scontro", 1)
SafeAddString(SI_COMBAT_METRICS_SAVE_FIGHT2, "Shift+Click: Salva lo scontro e il registro del combattimento", 1)
SafeAddString(SI_COMBAT_METRICS_DELETE_COMBAT_LOG, "Cancella il registro del combattimento", 1)
SafeAddString(SI_COMBAT_METRICS_DELETE_FIGHT, "Cancella Scontro", 1)

	-- Fight List

SafeAddString(SI_COMBAT_METRICS_RECENT_FIGHT, "Scontri Recenti", 1)
SafeAddString(SI_COMBAT_METRICS_DURATION, "Durata", 1)
SafeAddString(SI_COMBAT_METRICS_CHARACTER, "Personaggio", 1)
SafeAddString(SI_COMBAT_METRICS_ZONE, "Zona", 1)
SafeAddString(SI_COMBAT_METRICS_TIME, "Tempo", 1)
SafeAddString(SI_COMBAT_METRICS_TIME2, "Tempo", 1)
SafeAddString(SI_COMBAT_METRICS_TIMEC, "Tempo: ", 1)

SafeAddString(SI_COMBAT_METRICS_SHOW, "Mostra", 1)
SafeAddString(SI_COMBAT_METRICS_DELETE, "Cancella", 1)

SafeAddString(SI_COMBAT_METRICS_SAVED_FIGHTS, "Scontri Salvati", 1)

	-- More UI Strings

SafeAddString(SI_COMBAT_METRICS_ACTIVE_TIME, "Tempo Attivo: ", 1)
SafeAddString(SI_COMBAT_METRICS_ZERO_SEC, "0 s", 1)
SafeAddString(SI_COMBAT_METRICS_IN_COMBAT, "In Combattimento: ", 1)

SafeAddString(SI_COMBAT_METRICS_PLAYER, "Giocatore", 1)

SafeAddString(SI_COMBAT_METRICS_TOTALC, " Totale: ", 1)
SafeAddString(SI_COMBAT_METRICS_NORMAL, "Normale: ", 1)
SafeAddString(SI_COMBAT_METRICS_CRITICAL, "Critico: ", 1)
SafeAddString(SI_COMBAT_METRICS_BLOCKED, "Bloccato: ", 1)
SafeAddString(SI_COMBAT_METRICS_SHIELDED, "Scudato: ", 1)
SafeAddString(SI_COMBAT_METRICS_ABSOLUTEC, "Assoluto: ", 1)
SafeAddString(SI_COMBAT_METRICS_OVERHEAL, "Cure eccessive: ", 1) -- as in overheal

SafeAddString(SI_COMBAT_METRICS_HITS, "Colpi", 1)
SafeAddString(SI_COMBAT_METRICS_NORM, "Norm", 1)  -- Normal, short
SafeAddString(SI_COMBAT_METRICS_OH, "CE", 1)  -- Overheal, short

SafeAddString(SI_COMBAT_METRICS_RESOURCES, "Risorse", 1)

SafeAddString(SI_COMBAT_METRICS_STATS, "Statistiche", 1)
SafeAddString(SI_COMBAT_METRICS_AVE, "Media", 1)  -- Average, short
SafeAddString(SI_COMBAT_METRICS_AVE_N, "Media N", 1)  -- Average Normal, short
SafeAddString(SI_COMBAT_METRICS_AVE_C, "Media C", 1)  -- Average Crit, short
SafeAddString(SI_COMBAT_METRICS_AVE_B, "Media B", 1)  -- Average Blocked, short
SafeAddString(SI_COMBAT_METRICS_AVERAGE, "Media", 1)
SafeAddString(SI_COMBAT_METRICS_NORMAL_HITS, "Colpi normali", 1)
SafeAddString(SI_COMBAT_METRICS_MAX, "Max", 1)  -- Maximum
SafeAddString(SI_COMBAT_METRICS_MIN, "Min", 1)  -- Minimum
SafeAddString(SI_COMBAT_METRICS_EFFECTIVE, "Effettivo", 1)  -- Effective

SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA1, "Magicka Massima", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA2, "Danno Incantesimo", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA3, "Incantesimo Critico", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT3, "%.1f %%", 1) -- e.g. 12.3%
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA4, "Danno Critico", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA5, "Penetr. Incantesimo", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA6, "Penetr. Eccessiva", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT6, "%.1f %%", 1)-- e.g. 12.3%

SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA1, "Stamina Massima", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA2, "Danno Arma", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA3, "Arma Critico", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA_FORMAT3, "%.1f %%", 1)-- e.g. 12.3%
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA4, "Danno Critico", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA5, "Penetr. Fisica", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA6, "Penetr. Eccessiva", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA_FORMAT6, "%.1f %%", 1)-- e.g. 12.3%

SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH1, "Salute Massima", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH2, "Resistenza Fisica", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH3, "Resistenza Incantesimi", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH4, "Resistenza Critico", 1)
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH_FORMAT4, "%.1f %%", 1)-- e.g. 12.3%

SafeAddString(SI_COMBAT_METRICS_PERFORMANCE, "Prestazioni", 1)
SafeAddString(SI_COMBAT_METRICS_PERFORMANCE_FPSAVG, "FPS Media", 1)
SafeAddString(SI_COMBAT_METRICS_PERFORMANCE_FPSMIN, "FPS Minimo", 1)
SafeAddString(SI_COMBAT_METRICS_PERFORMANCE_FPSMAX, "FPS Massimo", 1)
SafeAddString(SI_COMBAT_METRICS_PERFORMANCE_FPSPING, "Ping", 1)
SafeAddString(SI_COMBAT_METRICS_PERFORMANCE_DESYNC, "Abilità Desincr.", 1)

SafeAddString(SI_COMBAT_METRICS_PENETRATION_TT, "Penetrazione vs. Danno", 1)

SafeAddString(SI_COMBAT_METRICS_COMBAT_LOG, "Registro del Combattimento", 1)

SafeAddString(SI_COMBAT_METRICS_GOTO_PREVIOUS, "Vai alla pagina precedente", 1)
SafeAddString(SI_COMBAT_METRICS_PAGE, "Vai alla pagina <<1>>", 1) -- <<1>> = page number
SafeAddString(SI_COMBAT_METRICS_GOTO_NEXT, "Vai alla pagina successiva", 1)

SafeAddString(SI_COMBAT_METRICS_TOGGLE_HEAL, "Attiva/Disattiva eventi di guarigione ricevuti", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_DAMAGE, "Attiva/Disattiva eventi di danno ricevuti", 1)

SafeAddString(SI_COMBAT_METRICS_TOGGLE_YOUR_HEAL, "Attiva/Disattiva i tuoi eventi di guarigione", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_YOUR_DAMAGE, "Attiva/Disattiva i tuoi eventi di danno", 1)

SafeAddString(SI_COMBAT_METRICS_TOGGLE_BUFFIN_EVENTS, "Attiva/Disattiva eventi dei bonus ricevuti", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_BUFFOUT_EVENTS, "Attiva/Disattiva eventi dei bonus inviati", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_GROUPBUFFIN_EVENTS, "Attiva/Disattiva eventi dei bonus di gruppo ricevuti", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_GROUPBUFFOUT_EVENTS, "Attiva/Disattiva eventi dei bonus di gruppo inviati", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_RESOURCE_EVENTS, "Attiva/Disattiva eventi risorse", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_STATS_CHANGE_EVENTS, "Attiva/Disattiva statistiche cambio eventi", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_MESSAGE_CHANGE_EVENTS, "Attiva/Disattiva eventi di informazione (e.g. cambio arma)", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_SKILL_USE_EVENTS, "Attiva/Disattiva eventi delle abilità usate", 1)
SafeAddString(SI_COMBAT_METRICS_TOGGLE_PERFORMANCE_EVENTS, "Attiva/Disattiva informazioni sulle prestazioni", 1)

	-- \n = new line

SafeAddString(SI_COMBAT_METRICS_DEBUFF_IN, "(Malus)Bonus\nIn", 1)
SafeAddString(SI_COMBAT_METRICS_DEBUFF_OUT, "(Malus)Bonus\nOut", 1)
SafeAddString(SI_COMBAT_METRICS_MAGICKA_PM, "Magicka\n +/-", 1)
SafeAddString(SI_COMBAT_METRICS_STAMINA_PM, "Stamina\n +/-", 1)
SafeAddString(SI_COMBAT_METRICS_RESOURCES_PM, "Risorse\n +/-", 1)

SafeAddString(SI_COMBAT_METRICS_BUFF, "Bonus", 1)
SafeAddString(SI_COMBAT_METRICS_BUFFS, "Bonus", 1)
SafeAddString(SI_COMBAT_METRICS_DEBUFFS, "Malus", 1)
SafeAddString(SI_COMBAT_METRICS_SHARP, "#", 1)
SafeAddString(SI_COMBAT_METRICS_BUFFCOUNT_TT, "Giocatore / Complessivo", 1)
SafeAddString(SI_COMBAT_METRICS_UPTIME, "Durata %", 1)
SafeAddString(SI_COMBAT_METRICS_UPTIME_TT, "Giocatore % / Complessivo %", 1)

SafeAddString(SI_COMBAT_METRICS_REGENERATION, "Rigenerazione", 1)
SafeAddString(SI_COMBAT_METRICS_CONSUMPTION, "Consumo", 1)
SafeAddString(SI_COMBAT_METRICS_PM_SEC, "±/s", 1)
SafeAddString(SI_COMBAT_METRICS_TARGET, "Bersaglio", 1)
SafeAddString(SI_COMBAT_METRICS_PERCENT, "%", 1)
SafeAddString(SI_COMBAT_METRICS_UNITDPS_TT, "DPS Reale, e.g. il danno al secondo tra il tuo primo e il tuo ultimo colpo a quel bersaglio", 1)

SafeAddString(SI_COMBAT_METRICS_ABILITY, "Abilità", 1)
SafeAddString(SI_COMBAT_METRICS_PER_HITS, "/Colpi", 1)
SafeAddString(SI_COMBAT_METRICS_CRITS_PER, "Critico %", 1)

SafeAddString(SI_COMBAT_METRICS_FAVOURITE_ADD, "Aggiungi ai Preferiti", 1)
SafeAddString(SI_COMBAT_METRICS_FAVOURITE_REMOVE, "Rimuovi dai Preferiti", 1)

SafeAddString(SI_COMBAT_METRICS_UNCOLLAPSE, "Mostra Dettagli", 1)
SafeAddString(SI_COMBAT_METRICS_COLLAPSE, "Collapse", 1)

SafeAddString(SI_COMBAT_METRICS_SKILL, "Abilità", 1)

SafeAddString(SI_COMBAT_METRICS_BAR, "Barra ", 1)
SafeAddString(SI_COMBAT_METRICS_AVERAGEC, "Media: ", 1)

SafeAddString(SI_COMBAT_METRICS_SKILLTIME_LABEL2, "tess", 1) -- weaving time
SafeAddString(SI_COMBAT_METRICS_SKILLTIME_LABEL3, "persi", 1) -- errors

SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT1, "Numero di lanci di questa abilità", 1)
SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT2, "Tempo Combinazione\n\nIl tempo medio sprecato prima del lancio della abilità successiva.", 1)
SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT3, "Errori Combinazione\n\nNumero di volte in cui l'attivazione di abilità non è stata seguita dopo un attacco d'arma o viceversa", 1)
SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT4, "Tempo medio tra le successive attivazioni di questa abilità", 1)

SafeAddString(SI_COMBAT_METRICS_SKILLTIME_WEAVING, "Media Combinazione: ", 1)

SafeAddString(SI_COMBAT_METRICS_SKILLAVG_TT, "Tempo medio sprecato tra due lanci di abilità", 1)
SafeAddString(SI_COMBAT_METRICS_SKILLTOTAL_TT, "Tempo totale sprecato tra i lanci di abilità", 1)

SafeAddString(SI_COMBAT_METRICS_TOTALWA, "Attacchi con armi: ", 1)
SafeAddString(SI_COMBAT_METRICS_TOTALWA_TT, "Totale attacchi leggeri e pesanti", 1)
SafeAddString(SI_COMBAT_METRICS_TOTALSKILLS, "Abilità: ", 1)
SafeAddString(SI_COMBAT_METRICS_TOTALSKILLS_TT, "Totale delle abilità lanciate", 1)

SafeAddString(SI_COMBAT_METRICS_SAVED_DATA, "Dati salvati", 1)

-- Live report window

SafeAddString(SI_COMBAT_METRICS_SHOW_XPS, "<<1>> / <<2>> (<<3>>%)", 1) -- Format to show DPS/HPS. <<1>> = own value, <<2>> = group value, <<3>> = percentage

-- Settings Menu

SafeAddString(SI_COMBAT_METRICS_MENU_PROFILES, "Profili", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_AC_NAME, "Utilizzare Impostazioni Intero Account", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_AC_TOOLTIP, "Se abilitato, tutti i personaggi di un account condivideranno le impostazioni", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_GS_NAME, "Impostazioni Generali", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_FH_NAME, "Storico degli Scontri", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_FH_TOOLTIP, "Numero degli scontri recenti da salvare", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_NAME, "Memoria degli Scontri Salvati", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_TOOLTIP, "Dimensione massima della memoria per gli salvati in MB", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_WARNING, "Da usare con cautela! Molti dati salvati aumentano significativamente i tempi di caricamento. Se il file diventa troppo grande, il client potrebbe bloccarsi nel tentativo di caricarlo.", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_BOSSFIGHTS_NAME, "Mantieni gli Scontri dei Boss", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_BOSSFIGHTS_TOOLTIP, "Cancella gli altri scontri prima di cancellare gli scontri con i boss quando viene raggiunto il limite degli scontri.", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_MG_NAME, "Monitoraggio Danni di Gruppo", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_MG_TOOLTIP, "Controlla gli eventi di tutto il gruppo", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_STACKS_NAME, "Mostra carica dei bonus", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_STACKS_TOOLTIP, "Mostra le singole cariche nel pannello dei bonus", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_GL_NAME, "Monitoraggio Danni per Grandi Gruppi", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_GL_TOOLTIP, "Monitora i danni per grandi gruppi (più di 4 membri)", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_LM_NAME, "Modalità Leggera", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_LM_TOOLTIP, "Quando è in modalità leggera, la metrica degli scontri calcolerà solo i DPS/HPS nella finestra del registro in tempo reale. Non verrà calcolata alcuna statistica e la finestra del registro del combattimento sarà disabilitata", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_NOPVP_NAME, "Disattiva in PvP", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_NOPVP_TOOLTIP, "Disattiva la registrazione degli scontri a Cyrodil e nei Campi di Battaglia", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_LMPVP_NAME, "Modalità Leggera in PvP", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_LMPVP_TOOLTIP, "Passa alla modalità leggera a Cyrodil e nei Campi di Battaglia. Quando è in modalità leggera, Combat Metrics calcolerà solo i DPS/HPS nella finestra del registro in tempo reale. Non verrà calcolata alcuna statistica e la finestra del registro degli scontri sarà disabilitata", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_ASCC_NAME, "Selezione Automatica del Canale", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_ASCC_TOOLTIP, "Seleziona automaticamente il canale quando si inviano DPS/HPS nella chat. Quando si è in gruppo usa /group nella chat altrimenti usa /say.", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_AS_NAME, "Schermata Automatica", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_AS_TOOLTIP, "Scatta automaticamente un'immagine quando si apre la finestra del registro degli scontri", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_ML_NAME, "Lunghezza minima dello scontro per la schermata", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_ML_TOOLTIP, "Lunghezza minima dello scontro in s per lo schermata automatica", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SF_NAME, "Adatta la finestra del registro degli scontri", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SF_TOOLTIP, "Regola la dimensione di tutti gli elementi della finestra del registro degli scontri", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_DISPLAYNAMES_NAME, "Mostra Nomi Account", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_DISPLAYNAMES_TOOLTIP, "Mostra i nomi degli account (@Nome) invece dei nomi dei personaggi per i membri del gruppo", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_SHOWPETS_NAME, "Mostra Animali Domestici", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_HIDEPETS, "Nascondi Animali Domestici", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SHOWPETS_TOOLTIP, "Mostra gli animali domestici nella finestra del registro degli scontri", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_NOTIFICATIONS, "Consenti Notifiche", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_NOTIFICATIONS_TOOLTIP, "Ogni tanto, potrei aggiungere una notifica alla finestra dei registri, per raccogliere dati o per reclutare persone nei miei raid (per risparmiare tempo che preferirei dedicare agli addon). Disattivalo, se non lo vuoi.", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_RESPEN_NAME, "Resistenza e Penetrazione", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_CRUSHER, "Frantumatore", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_CRUSHER_TOOLTIP, "Riduzione della resistenza dovuta al malus del glifo Frantumatore. Per il glifo d'oro di livello massimo: standard: 1622, infuso: 2108, infuso + Torug: 2740", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_MOBRESISTANCE, "Resistenza del bersaglio", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_MOBRESISTANCE_TOOLTIP, "Resistenza del bersaglio,immaginata, per il calcolo della sovrappenetrazione", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_LR_NAME, "Finestra Registro in Tempo Reale", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_ENABLE_NAME, "Abilita", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_ENABLE_TOOLTIP, "Abilita la finestra del registro in tempo reale che mostra DPS e HPS durante il combattimento", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_LR_LOCK, "Blocca", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_LR_LOCK_TOOLTIP, "Bloccare la finestra del registro in tempo reale, in modo che non possa essere spostata", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_LR_ALIGNMENT, "Usa numeri allineati a sinistra", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_LR_ALIGNMENT_TOOLTIP, "Imposta il posizionamento dei numeri di Danni/Cure/ecc. per la finestra del registro in tempo reale con l'allineato a sinistra", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_LAYOUT_NAME, "Disposizione", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_LAYOUT_TOOLTIP, "Seleziona la disposizione della finestra del registro in tempo reale", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SCALE_NAME, "Adatta", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SCALE_TOOLTIP, "Adatta la finestra del registro in tempo reale.", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_BGALPHA_NAME, "Trasparenza Sfondo", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_BGALPHA_TOOLTIP, "Impostare la Trasparenza dello Sfondo", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_DPS_NAME, "Mostra DPS", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_DPS_TOOLTIP, "Mostra i DPS inflitti nella finestra del registro in tempo reale", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_SDPS_NAME, "Mostra DPS Bersaglio Singolo", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_SDPS_TOOLTIP, "Mostra i DPS inflitti su singolo bersaglio nella finestra del registro in tempo reale", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_HPS_NAME, "Mostra HPS", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_HPS_TOOLTIP, "Mostra HPS dei tuoi lanci nella finestra del registro in tempo reale", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_HPSA_NAME, "Mostra HPS + Cure Eccesso", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_HPSA_TOOLTIP, "Mostra HPS incluso l'eccesso di cure lanciate nella finestra del registro in tempo reale", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_NAME, "Mostra DPS Ricevuti", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_TOOLTIP, "Mostra i DPS ricevuti nella finestra del registro in tempo reale", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_NAME, "Mostra HPS Ricevuti", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_TOOLTIP, "Mostra gli HPS ricevuti nella finestra del registro in tempo reale", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_TIME_NAME, "Mostra il Tempo", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_TIME_TOOLTIP, "Mostra il tempo in cui hai inflitto danni nella finestra del registro in tempo reale", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE, "Trasmetti Registro del Combattimento nella chat", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_WARNING, "Usare con cautela! La creazione di linee di testo richiede molto lavoro da parte della CPU. È meglio disabilitarlo se si prevedono scontri pesanti (trial, cyrodil)", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_DH_TOOLTIP, "Trasmette gli eventi di danno e guarigione alla finestra della chat", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE_NAME, "Titolo Registro della chat", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE_TOOLTIP, "Mostra i danni inflitti nella chat", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SD_NAME, "Mostra Danni", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SD_TOOLTIP, "Mostra i danni inflitti nella chat", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SH_NAME, "Mostra Cure", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SH_TOOLTIP, "Mostra le cure lanciate nella chat", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SID_NAME, "Mostra Danno Ricevuto", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SID_TOOLTIP, "Mostra il danno ricevuto nella chat", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SIH_NAME, "Mostra Cure Ricevute", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SIH_TOOLTIP, "Mostra le cure ricevute nella chat", 1)

-- make a label for keybinding

SafeAddString(SI_BINDING_NAME_CMX_REPORT_TOGGLE, "Attiva/Disattiva Registro degli Scontri", 1)
SafeAddString(SI_BINDING_NAME_CMX_LIVEREPORT_TOGGLE, "Attiva/Disattiva Registro in Tempo Reale", 1)
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_SMART, "Invia DPS del Boss o DPS Tolale", 1)
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_SINGLE, "Invia DPS Bersaglio Singolo", 1)
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_MULTI, "Invia DPS Bersaglio Multiplo", 1)
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS, "Invia DPS Bersaglio Singolo + Multiplo", 1)
SafeAddString(SI_BINDING_NAME_CMX_POST_HPS, "Invia Cure nella Chat", 1)
SafeAddString(SI_BINDING_NAME_CMX_RESET_FIGHT, "Ripristina Manualmente lo Scontro", 1)

-- Localization End
