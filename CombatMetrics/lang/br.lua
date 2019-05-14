
-- Functionality

SafeAddString(SI_COMBAT_METRICS_LANG, "br", 1) 
SafeAddString(SI_COMBAT_METRICS_ENCHANTMENT_TRIM, "Spell Damage", 1) -- this will be removed from the items enchantment string to show the rest in the info panel, e.g. "Spell Damage Enchantment" is reduced to "Spell Damage".

-- Fonts

--SafeAddString(SI_COMBAT_METRICS_STD_FONT, "EsoUI/Common/Fonts/Univers57.otf", 1) 
--SafeAddString(SI_COMBAT_METRICS_BOLD_FONT, "EsoUI/Common/Fonts/Univers67.otf", 1) 

--SafeAddString(SI_COMBAT_METRICS_FONT_SIZE_SMALL, "14", 1) 
--SafeAddString(SI_COMBAT_METRICS_FONT_SIZE, "15", 1) 
--SafeAddString(SI_COMBAT_METRICS_FONT_SIZE_TITLE, "20", 1) 

-- Main UI

SafeAddString(SI_COMBAT_METRICS_CALC, "Calculando...", 1) 
SafeAddString(SI_COMBAT_METRICS_FINALISING, "Finalizando...", 1) 
SafeAddString(SI_COMBAT_METRICS_GROUP, "Grupo", 1) 
SafeAddString(SI_COMBAT_METRICS_SELECTION, "Seleção", 1) 

SafeAddString(SI_COMBAT_METRICS_BASE_REG, "Regeneração Base", 1) 
SafeAddString(SI_COMBAT_METRICS_DRAIN, "Dreno", 1) 
SafeAddString(SI_COMBAT_METRICS_UNKNOWN, "Desconhecido", 1) 

SafeAddString(SI_COMBAT_METRICS_BLOCKS, "Bloqueios", 1) 
SafeAddString(SI_COMBAT_METRICS_CRITS, "Criticos", 1) 

SafeAddString(SI_COMBAT_METRICS_DAMAGE, "Dano", 1) 
SafeAddString(SI_COMBAT_METRICS_DAMAGEC, "Dano:", 1) 
SafeAddString(SI_COMBAT_METRICS_HIT, "Golpe", 1) 
SafeAddString(SI_COMBAT_METRICS_DPS, "DPS", 1) 
SafeAddString(SI_COMBAT_METRICS_INCOMING_DPS, "DPS Recebido", 1) 

SafeAddString(SI_COMBAT_METRICS_HEALING, "Curando", 1) 
SafeAddString(SI_COMBAT_METRICS_HEALS, "Curas", 1) 
SafeAddString(SI_COMBAT_METRICS_HPS, "CPS", 1) 
SafeAddString(SI_COMBAT_METRICS_INCOMING_HPS, "CPS Recebida", 1) 

SafeAddString(SI_COMBAT_METRICS_EDIT_TITLE, "Duplo clique para editar o nome da luta", 1) 

SafeAddString(SI_COMBAT_METRICS_DAMAGE_CAUSED, "Dano Causado", 1) 
SafeAddString(SI_COMBAT_METRICS_DAMAGE_RECEIVED, "Dano Recebido", 1) 
SafeAddString(SI_COMBAT_METRICS_HEALING_DONE, "Cura Feita", 1) 
SafeAddString(SI_COMBAT_METRICS_HEALING_RECEIVED, "Cura Recebida", 1) 

SafeAddString(SI_COMBAT_METRICS_TOGGLE_FIGHTSTATS, "Estatísticas da Luta", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_COMBAT_LOG, "Log do Combate", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_GRAPH, "Gráfico", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_INFO, "Infor.", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_SETTINGS, "Opções", 1) 

-- Options Menu Strings

SafeAddString(SI_COMBAT_METRICS_SHOWIDS, "Mostra IDs", 1) -- (for units, buffs and abilities)
SafeAddString(SI_COMBAT_METRICS_HIDEIDS, "Esconde IDs", 1) -- (for units, buffs and abilities)

SafeAddString(SI_COMBAT_METRICS_POSTDPS, "Posta DPS/CPS", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTSINGLEDPS, "Posta DPS de unico alvo", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTSMARTDPS, "Posta DPS do Chefe alvo", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTMULTIDPS, "Posta DPS total", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTALLDPS, "Posta DPS único e total", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTHPS, "Posta CPS", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTUNITDPS, "Posta DPS para esta unidade", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTUNITNAMEDPS, "Posta DPS para unidade '<<1>>'", 1) -- <<1>> is unitname
SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONDPS, "Posta DPS para unidade selecionada", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONHPS, "Posta CPS para unidade selecionada", 1) 

-- Format Strings for DPS posting

SafeAddString(SI_COMBAT_METRICS_BOSS_DPS, "DPS do Chefe", 1) 

SafeAddString(SI_COMBAT_METRICS_POSTDPS_FORMAT, "<<1>> - DPS: <<2>> (<<3>> em <<4>>)", 1) -- for single target DPS (<<1>> = fightname, <<2>> = DPS, <<3>> = damage, <<4>> =  ) e.g. Z'Maja - DPS: 10000 (1000000 in 1:40.0)
--SafeAddString(SI_COMBAT_METRICS_POSTSMARTDPS_FORMAT, "<<1>><<2>> - Boss DPS: <<3>> (<<4>> in <<5>>)", 1) -- (<<1>> = fightname, <<2>> = extraunits (can be ""), <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Valariel (+5) - Boss DPS: 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTMULTIDPS_FORMAT, "<<1>> (+<<2>>) - DPS: <<3>> (<<4>> em <<5>>)", 1) -- (<<1>> = fightname, <<2>> = extraunits, <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Some random Mob (+5) - DPS: 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTALLDPS_FORMAT_A, "<<1>> - DPS Total (+<<2>>): <<3>> (<<4>> em <<5>>)", 1) -- multi target part (<<1>> = fightname, <<2>> = extraunits, <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Valariel - Total DPS (+5): 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTALLDPS_FORMAT_B, "<<1>>: <<2>> (<<3>> em <<4>>)", 1) --  single target part (<<1>> = Label, <<2>> = DPS, <<3>> = damage) e.g. Boss DPS (+2): 10000 (1000000 in 1:40.0)
--SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONDPS_FORMAT, "<<1>><<2>> - Selection DPS: <<3>> (<<4>> in <<5>>)", 1) -- (<<1>> = fightname, <<2>> = extraunits (can be ""), <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Valariel (+5) - Boss DPS: 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTHPS_FORMAT, "<<1>> - CPS: <<2>> (<<3>> em <<4>>)", 1) -- (<<1>> = fightname, <<2>> = HPS, <<3>> = damage, <<4>> = time)  e.g. Z'Maja - HPS: 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONHPS_FORMAT, "<<1>> - CPS Selecionada (x<<2>>): <<3>> (<<4>> in <<5>>)", 1) -- (<<1>> = fightname, <<2>> = units, <<3>> = HPS, <<4>> = damage, <<5>> = time) e.g. Z'Maja - HPS (12): 10000 (1000000 in 1:40.0)

SafeAddString(SI_COMBAT_METRICS_POSTBUFF, "Posta bônus de atividade", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTBUFF_BOSS, "Posta bônus de atividade em Chefes", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTBUFF_GROUP, "Posta bônus de atividade de membros do grupo", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTBUFF_FORMAT, "<<1>> - CPS: <<2>> (<<3>><<4[/ on $d/ on $d units]>>)", 1) -- (<<1>> = buff name, <<2>> = relative uptime, <<3>> = uptime, <<4>> = time) e.g. Major Intellect - Uptime: 93.2% (9:26 in 10:07)
SafeAddString(SI_COMBAT_METRICS_POSTBUFF_FORMAT_GROUP, "<<1>> - Atividade: <<2>>/<<5>> (<<3>>/<<6>><<4[/ on $d/ on $d units]>>)", 1) -- (<<1>> = buff name, <<2>> = relative uptime, <<3>> = uptime, <<4>> = units, <<5>> = relative group uptime, <<6>> = group uptime) e.g. Minor Sorcery - Uptime: 55.4%/100.6% (5:36/10:11 in 10:07)

SafeAddString(SI_COMBAT_METRICS_SETTINGS, "Opções do Addon", 1) 
SafeAddString(SI_COMBAT_METRICS_FEEDBACK, "Envie Feedback / Doe", 1) 
SafeAddString(SI_COMBAT_METRICS_SAVEHDD, "Salve Dados de Luta no HDD", 1) 

-- Graph

SafeAddString(SI_COMBAT_METRICS_TOGGLE_CURSOR, "Alterna para mostrar cursor e a dica do valor", 1) 
SafeAddString(SI_COMBAT_METRICS_GRAPH_BUFF_GROUP_SELECTOR, "Alterna para mostrar atividade do grupo", 1) 

SafeAddString(SI_COMBAT_METRICS_RECALCULATE, "Recalcula luta", 1) 
SafeAddString(SI_COMBAT_METRICS_SMOOTHED, "Suavizado", 1) 
SafeAddString(SI_COMBAT_METRICS_TOTAL, "Total", 1) 
SafeAddString(SI_COMBAT_METRICS_ABSOLUTE, "% Absoluto", 1) 
SafeAddString(SI_COMBAT_METRICS_SMOOTH_LABEL, "Suave: %d s", 1) 
SafeAddString(SI_COMBAT_METRICS_NONE, "Nenhum", 1) 
SafeAddString(SI_COMBAT_METRICS_BOSS_HP, "HP do Chefe", 1) 
SafeAddString(SI_COMBAT_METRICS_ENLARGE, "Alargar", 1) 
SafeAddString(SI_COMBAT_METRICS_SHRINK, "Encurtar", 1) 

-- Feedback

SafeAddString(SI_COMBAT_METRICS_FEEDBACK_MAIL, "Enviar Email", 1) 
SafeAddString(SI_COMBAT_METRICS_FEEDBACK_GOLD, "Doar 5000g", 1) 
SafeAddString(SI_COMBAT_METRICS_FEEDBACK_GOLD2, "Doar 25000g", 1) 
SafeAddString(SI_COMBAT_METRICS_FEEDBACK_ESOUI, "Site (ESOUI)", 1) 
SafeAddString(SI_COMBAT_METRICS_FEEDBACK_GITHUB, "GitHub", 1) 
SafeAddString(SI_COMBAT_METRICS_FEEDBACK_TEXT, "\nSe envontrar um bug, tem uma requisição ou uma sugestão, envie um email no jogo, crie uma pergunta no GitHub ou poste nos comentários no EsoUI. \n\nDoações são apreciadas mas não obrigatórias ou necessárias. \nSe você quer doar dinheiro real por favor visite o site do addon no EsoUI", 1) 

SafeAddString(SI_COMBAT_METRICS_STORAGE_FULL, "O arquivo de armazenamento está cheio. A luta que você quer salvar precisa de <<1>> MB e <<2>> indices. Apque uma luta para liberar algum espaço ou aumente o espaço permitido nas configurações!", 1) 

-- Fight Control Button Tooltips

SafeAddString(SI_COMBAT_METRICS_PREVIOUS_FIGHT, "Luta Anterior", 1) 
SafeAddString(SI_COMBAT_METRICS_NEXT_FIGHT, "Próxima Luta", 1) 
SafeAddString(SI_COMBAT_METRICS_MOST_RECENT_FIGHT, "Luta Mais Recente", 1) 
SafeAddString(SI_COMBAT_METRICS_LOAD_FIGHT, "Lê Luta", 1) 
SafeAddString(SI_COMBAT_METRICS_SAVE_FIGHT, "Clique: Salva luta", 1) 
SafeAddString(SI_COMBAT_METRICS_SAVE_FIGHT2, "Shift+Clique: Salva a luta com o log de combate", 1) 
SafeAddString(SI_COMBAT_METRICS_DELETE_COMBAT_LOG, "Apaga o Log de Combate", 1) 
SafeAddString(SI_COMBAT_METRICS_DELETE_FIGHT, "Apaga Luta", 1) 

-- Fight List

SafeAddString(SI_COMBAT_METRICS_RECENT_FIGHT, "Lutas Recentes", 1) 
SafeAddString(SI_COMBAT_METRICS_DURATION, "Duração", 1) 
SafeAddString(SI_COMBAT_METRICS_CHARACTER, "Personagem", 1) 
SafeAddString(SI_COMBAT_METRICS_ZONE, "Zona", 1) 
SafeAddString(SI_COMBAT_METRICS_TIME, "Hora", 1) 
SafeAddString(SI_COMBAT_METRICS_TIMEC, "Tempo:", 1) 

SafeAddString(SI_COMBAT_METRICS_SHOW, "Mostra", 1) 
SafeAddString(SI_COMBAT_METRICS_DELETE, "Apaga", 1) 

SafeAddString(SI_COMBAT_METRICS_SAVED_FIGHTS, "Lutas Salvas", 1) 

-- More UI Strings

SafeAddString(SI_COMBAT_METRICS_ACTIVE_TIME, "Tempo Ativo:", 1) 
SafeAddString(SI_COMBAT_METRICS_ZERO_SEC, "0 s", 1) 
SafeAddString(SI_COMBAT_METRICS_IN_COMBAT, "Em Combate:", 1) 

SafeAddString(SI_COMBAT_METRICS_PLAYER, "Jogador", 1) 

SafeAddString(SI_COMBAT_METRICS_TOTALC, "Total:", 1) 
SafeAddString(SI_COMBAT_METRICS_NORMAL, "Normal:", 1) 
SafeAddString(SI_COMBAT_METRICS_CRITICAL, "Critico:", 1) 
SafeAddString(SI_COMBAT_METRICS_BLOCKED, "Bloqueado:", 1) 
SafeAddString(SI_COMBAT_METRICS_SHIELDED, "Escudo:", 1) 
--SafeAddString(SI_COMBAT_METRICS_ABSOLUTEC, "Absolute: ", 1) 
--SafeAddString(SI_COMBAT_METRICS_OVERHEAL, "Overheal: ", 1) -- as in overheal

SafeAddString(SI_COMBAT_METRICS_HITS, "Golpes", 1) 
SafeAddString(SI_COMBAT_METRICS_NORM, "Norm", 1) -- Normal, short

SafeAddString(SI_COMBAT_METRICS_RESOURCES, "Recursos", 1) 

SafeAddString(SI_COMBAT_METRICS_STATS, "Estatisticas", 1) 
SafeAddString(SI_COMBAT_METRICS_AVE, "Med", 1) -- Average, short
SafeAddString(SI_COMBAT_METRICS_AVE_N, "Med N", 1) -- Average Normal, short
SafeAddString(SI_COMBAT_METRICS_AVE_C, "Med C", 1) -- Average Crit, short
SafeAddString(SI_COMBAT_METRICS_AVERAGE, "Média", 1) 
SafeAddString(SI_COMBAT_METRICS_NORMAL_HITS, "Golpes Normais", 1) 
SafeAddString(SI_COMBAT_METRICS_MAX, "Max", 1) -- Maximum
SafeAddString(SI_COMBAT_METRICS_MIN, "Min", 1) -- Minimum

SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA1, "Mágicka Máxima:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA2, "Dano de Feitiço:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA3, "Feitiço Crítico:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT3, "%.1f %%", 1) -- e.g. 12.3%
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA4, "Dano Crítico:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA5, "Penet. Feitiço:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA6, "Overpenetração:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT6, "%.1f %%", 1) -- e.g. 12.3%

SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA1, "Vigor Máximo:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA2, "Dano de Arma:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA3, "Crítico de Arma:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA_FORMAT3, "%.1f %%", 1) -- e.g. 12.3%
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA4, "Dano Crítico:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA5, "Penetração Fisica:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA6, "Overpenetração:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA_FORMAT6, "%.1f %%", 1) -- e.g. 12.3%

SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH1, "Saúde Máxima:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH2, "Resist. Fisica:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH3, "Resist. Feitiço:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH4, "Resist. Crítico:", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH_FORMAT4, "%.1f %%", 1) -- e.g. 12.3%

SafeAddString(SI_COMBAT_METRICS_PENETRATION_TT, "Penetração: Dano", 1) 

SafeAddString(SI_COMBAT_METRICS_COMBAT_LOG, "Log de Combate", 1) 

SafeAddString(SI_COMBAT_METRICS_GOTO_PREVIOUS, "Vai para págs. anteriores", 1) 
SafeAddString(SI_COMBAT_METRICS_PAGE, "Pág. <<1>>", 1) -- <<1>> = page number
SafeAddString(SI_COMBAT_METRICS_GOTO_NEXT, "Vai para págs. seguintes", 1) 

SafeAddString(SI_COMBAT_METRICS_TOGGLE_HEAL, "Alterna entre eventos de cura recebida", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_DAMAGE, "Alterna entre eventos de dano recebido", 1) 

SafeAddString(SI_COMBAT_METRICS_TOGGLE_YOUR_HEAL, "Alterna entre os seus eventos de cura", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_YOUR_DAMAGE, "Alterna entre os seus eventos de dano", 1) 

SafeAddString(SI_COMBAT_METRICS_TOGGLE_BUFFIN_EVENTS, "Alterna entre eventos de bônus recebidos", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_BUFFOUT_EVENTS, "Alterna entre eventos de bônus enviados", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_GROUPBUFFIN_EVENTS, "Alterna entre eventos de bônus de grupo recebidos", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_GROUPBUFFOUT_EVENTS, "Alterna entre eventos de bônus de grupo enviados", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_RESOURCE_EVENTS, "Alterna entre eventos de recursos", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_STATS_CHANGE_EVENTS, "Alterna entre eventos de alteração de status", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_MESSAGE_CHANGE_EVENTS, "Alterna eventos de alternancia ex. troca de arma", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_SKILL_USE_EVENTS, "Alterna eventos de habilidades usados", 1) 

-- \n = new line

SafeAddString(SI_COMBAT_METRICS_DEBUFF_IN, "(De-)Bônus\nVindo", 1) 
SafeAddString(SI_COMBAT_METRICS_DEBUFF_OUT, "(De-)Bônus\nIndo", 1) 
SafeAddString(SI_COMBAT_METRICS_MAGICKA_PM, "Mágicka\n +/-", 1) 
SafeAddString(SI_COMBAT_METRICS_STAMINA_PM, "Vigor\n +/-", 1) 
SafeAddString(SI_COMBAT_METRICS_RESOURCES_PM, "Recursos\n +/-", 1) 

SafeAddString(SI_COMBAT_METRICS_BUFF, "Bônus", 1) 
SafeAddString(SI_COMBAT_METRICS_BUFFS, "Bônus", 1) 
SafeAddString(SI_COMBAT_METRICS_DEBUFFS, "(De-)Bônus", 1) 
SafeAddString(SI_COMBAT_METRICS_SHARP, "#", 1) 
SafeAddString(SI_COMBAT_METRICS_BUFFCOUNT_TT, "Jogador / Geral", 1) 
SafeAddString(SI_COMBAT_METRICS_UPTIME, "Atividade", 1) 
SafeAddString(SI_COMBAT_METRICS_UPTIME_TT, "Jogador % / Geral %", 1) 

SafeAddString(SI_COMBAT_METRICS_REGENERATION, "Regeneração", 1) 
SafeAddString(SI_COMBAT_METRICS_CONSUMPTION, "Consumo", 1) 
SafeAddString(SI_COMBAT_METRICS_PM_SEC, "±/s", 1) 
SafeAddString(SI_COMBAT_METRICS_TARGET, "Alvo", 1) 
SafeAddString(SI_COMBAT_METRICS_PERCENT, "%", 1) 
SafeAddString(SI_COMBAT_METRICS_UNITDPS_TT, "DPS Real, ex. o dano por segundo entre seu primeiro e seu ultimo golpe no alvo", 1) 

SafeAddString(SI_COMBAT_METRICS_ABILITY, "Habilidade", 1) 
SafeAddString(SI_COMBAT_METRICS_PER_HITS, "/Golpes", 1) 
SafeAddString(SI_COMBAT_METRICS_CRITS_PER, "Crit %", 1) 

SafeAddString(SI_COMBAT_METRICS_FAVOURITE_ADD, "Inclui nos Favoritos", 1) 
SafeAddString(SI_COMBAT_METRICS_FAVOURITE_REMOVE, "Remove dos Favoritos", 1) 

SafeAddString(SI_COMBAT_METRICS_SKILL, "habilidade", 1) 

SafeAddString(SI_COMBAT_METRICS_BAR, "Barra", 1) 
SafeAddString(SI_COMBAT_METRICS_AVERAGEC, "Média:", 1) 

SafeAddString(SI_COMBAT_METRICS_SKILLTIME_LABEL2, "Weapon / Skill", 1) -- as in "Weapon / Skill"
SafeAddString(SI_COMBAT_METRICS_SKILLTIME_LABEL3, "A / H >", 1) 

SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT1, "Número de lançamentos desta habilidade", 1) 
SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT2, "Tempo desde a última arma/Habilidade ativada.", 1) 
SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT3, "Tempo entre ativação da habilidade e a próxima ativação de arma/Habilidade.", 1) 
SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT4, "Média de tempo entre ativações subsequentes desta habilidade", 1) 

SafeAddString(SI_COMBAT_METRICS_SAVED_DATA, "Dados salvos", 1) 

-- Live Report Window

SafeAddString(SI_COMBAT_METRICS_SHOW_XPS, "<<1>> / <<2>> (<<3>>%)", 1) -- Format to show DPS/HPS. <<1>> = own value, <<2>> = group value, <<3>> = percentage

-- Settings Menu

SafeAddString(SI_COMBAT_METRICS_MENU_PROFILES, "Perfis", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_AC_NAME, "Usa configurações p/ toda conta", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_AC_TOOLTIP, "Se habilitado todos os personagens de uma conta vão compartilhar suas configurações", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_GS_NAME, "Configurações Gerais", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_FH_NAME, "Histórico de Luta", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_FH_TOOLTIP, "Numero de lutas recentes a salvar", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_NAME, "Memória para Lutas Salvas", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_TOOLTIP, "Tamanho Máximo de memória para lutas salvas em MB", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_WARNING, "Use com cuidado! Muitos dados salvos aumentam significativamente o tempo de carregamento. Se o arquivo ficar muito grande, o cliente pode dar erro quando tentar ler.", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_BOSSFIGHTS_NAME, "Guarda Lutas com Chefes", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_BOSSFIGHTS_TOOLTIP, "Apaga as lutas lixo primeiro, antes de apagar as lutas com os chefes quando o limite de lutas for alcançado", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_MG_NAME, "Monitora Dano do Grupo", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_MG_TOOLTIP, "Monitora os eventos de todo o grupo", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_STACKS_NAME, "Mostra pilhas de bônus", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_STACKS_TOOLTIP, "Mostra pilhas individuais no painel de bônus", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_GL_NAME, "Monitora Dano em grupos grandes", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_GL_TOOLTIP, "Monitora o dano de grupos grandes (mais de 4 membros)", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LM_NAME, "Modo Leve", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_LM_TOOLTIP, "Quando no modo leve, o combat metrics só vai calcular o DPS/CPS na janela de relatório ativa. Nenhuma estatística será calculada e a janela grande de relatório será desativada", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_NOPVP_NAME, "Desliga em Cyrodil", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_NOPVP_TOOLTIP, "Desliga todos os logs de lutas em Cyrodil", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LMPVP_NAME, "Modo Leve em Cyrodil", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_LMPVP_TOOLTIP, "Alterna para o modo leve em Cyrodil. Quando no modo leve, o Combat Metrics só calcula o DPS/CPS na janela de relatório ativa. Nenhuma estatística será calculada e a janela grande de relatório será desativada", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_ASCC_NAME, "Auto Escolhe Canal", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_ASCC_TOOLTIP, "Automaticamente escolhe o canal quando postar o DPS/CPS no chat. Quando em grupo o chat /group é usado senão usa o chat /say.", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_AS_NAME, "Auto Screenshot", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_AS_TOOLTIP, "Automaticamente tira uma Screenshot quando abrir a janela de Relatório", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_ML_NAME, "Tamanho minimo da luta para screenshot", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_ML_TOOLTIP, "Menor tamanho de luta em s para o auto screenshot", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SF_NAME, "Escala da Janela de Relatório de Luta", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SF_TOOLTIP, "Ajusta o tamanho de todos os elementos da janela de Relatório de Luta", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_RESPEN_NAME, "Resistência e Penetração", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CRUSHER, "Esmagador", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CRUSHER_TOOLTIP, "Redução de resistência devido à penalidade do glifo Esmagador. Para o glifo dourado nível máximo: padrão: 1622, infundido: 2108", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_MOBRESISTANCE, "Resistência do Alvo", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_MOBRESISTANCE_TOOLTIP, "Resistência do Alvo que é assumida para o cálculo de overpenetração", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LR_NAME, "Janela de Relatório Ativa", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_ENABLE_NAME, "Habilitada", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_ENABLE_TOOLTIP, "Habilita a Janela de Relatório Ativa que mostra DPS & CPS durante o combate", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LR_LOCK, "Travar", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_LR_LOCK_TOOLTIP, "Travar a Janela de relatórios ao ativa, para ela não se mover", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LR_ALIGNMENT, "Use números alinhados a esquerda", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_LR_ALIGNMENT_TOOLTIP, "Alinhe a esquerda os conjuntos de números de Dano/Curas/etc. para a hanela de relatórios ao ativa", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LAYOUT_NAME, "Layout", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_LAYOUT_TOOLTIP, "Escolhe o Layout da Janela de Relatório Ativa", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SCALE_NAME, "Escala", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SCALE_TOOLTIP, "Escala da Janela de Relatório Ativa.", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_BGALPHA_NAME, "Opacidade do Fundo", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_BGALPHA_TOOLTIP, "Define a Opacidade do Fundo", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_DPS_NAME, "Mostra DPS", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_DPS_TOOLTIP, "Mostra o DPS que você causou na Janela de Relatório Ativa", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_SDPS_NAME, "Mostra DPS em único alvo", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_SDPS_TOOLTIP, "Mostra o DPS que você causou em um único alvo na Janela de Relatório Ativa", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_HPS_NAME, "Mostra CPS", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_HPS_TOOLTIP, "Mostra a CPS que você lançou na Janela de Relatório Ativa", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_NAME, "Mostra DPS vindo", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_TOOLTIP, "Mostra o DPS que você recebeu na Janela de Relatório Ativa", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_NAME, "Mostra CPS vinda", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_TOOLTIP, "Mostra a CPS que você recebeu na Janela de Relatório Ativa", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_TIME_NAME, "Mostra Tempo", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_TIME_TOOLTIP, "Mostra o Tempo que você ficou causando dano na Janela de Relatório Ativa", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE, "Dados de Combate no chat", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_DH_TOOLTIP, "Envia os dados dos Eventos de Dano e Cura para a janela de chat", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE_NAME, "Titulo do Chat Log", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE_TOOLTIP, "Mostra o dano que você causou no envio para o chat", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SD_NAME, "Mostra dano", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SD_TOOLTIP, "Mostra o dano que você causou no envio para o chat", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SH_NAME, "Mostra curas", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SH_TOOLTIP, "Mostra as curas que você lançou no envio para o chat", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SID_NAME, "Mostra Dano Vindo", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SID_TOOLTIP, "Mostra o dano que você recebeu no envio para o chat", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SIH_NAME, "Mostra Cura Vinda", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SIH_TOOLTIP, "Mostra as curas que você recebeu no envio para o chat", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_TITLE, "Opções de Debug", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SF_NAME, "Mostra Recap de Luta", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SF_TOOLTIP, "Imprime Resultados do Combate na janela de chat do sistema", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SA_NAME, "Mostra IDs das Habilidades", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SA_TOOLTIP, "Mostra os ids das habilidades na janela de relatório de luta", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SFC_NAME, "Mostra Informação de Cálculo de Luta", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SFC_TOOLTIP, "Imprime as Informações sobre o cálculo dos tempos na janela de chat do sistema", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_BI_NAME, "Mostra Info de Bônus", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_BI_TOOLTIP, "Imprime os events de Bônus na janela de chat do sistema (Spammy)", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_US_NAME, "Mostra Info de habilidade Usada", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_US_TOOLTIP, "Imprime os eventos de habilidades usadas na janela de chat do sistema", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SG_NAME, "Mostra Info do Grupo", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SG_TOOLTIP, "Imprime eventos de entrar e sair do grupo na janela de chat do sistema", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_MD_NAME, "Mostra Informações diversas de Debug", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_MD_TOOLTIP, "imprime algumas outros eventos na janela de chat do sistema", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SPECIAL_NAME, "Show Informação especial de debug", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SPECIAL_TOOLTIP, "Imprime certos eventos especiais na janela de chat do sistema", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SAVE_NAME, "Mostra Informação de dados salvos", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SAVE_TOOLTIP, "Imprime informações de debug sobre lutas salvas e lidas na janela de chat do sistema", 1) 

-- make a label for keybinding

SafeAddString(SI_BINDING_NAME_CMX_REPORT_TOGGLE, "Alterna Relatório de Luta", 1) 
SafeAddString(SI_BINDING_NAME_CMX_LIVEREPORT_TOGGLE, "Alterna Relatório Ativo", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_SMART, "Posta Chefe ou DPS Total", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_SINGLE, "Posta DPS de Único Alvo", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_MULTI, "Posta DPS Multi Alvo", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS, "Posta DPS de Único + Multi Alvo", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_HPS, "Posta Cura no Chat", 1) 
SafeAddString(SI_BINDING_NAME_CMX_RESET_FIGHT, "Reinicia a Luta Manualmente", 1) 

