-- Fonts

SafeAddString(SI_COMBAT_METRICS_LANG, "br", 1)
SafeAddString(SI_COMBAT_METRICS_STD_FONT, "EsoUI/Common/Fonts/Univers57.otf", 1)  -- EsoUi/Common/Fonts/Univers57.otf
SafeAddString(SI_COMBAT_METRICS_BOLD_FONT, "EsoUI/Common/Fonts/Univers67.otf", 1)  -- EsoUi/Common/Fonts/Univers67.otf

SafeAddString(SI_COMBAT_METRICS_FONT_SIZE_SMALL, "14", 1)  -- 14
SafeAddString(SI_COMBAT_METRICS_FONT_SIZE, "15", 1)  -- 15
SafeAddString(SI_COMBAT_METRICS_FONT_SIZE_TITLE, "20", 1)  -- 20

-- Colors

SafeAddString(SI_COMBAT_METRICS_SEP_COLOR, "FFAAAAAA", 1)
SafeAddString(SI_COMBAT_METRICS_HEALTH_COLOR, "FFDE6531", 1)
SafeAddString(SI_COMBAT_METRICS_MAGICKA_COLOR, "FF5EBDE7", 1)
SafeAddString(SI_COMBAT_METRICS_STAMINA_COLOR, "FFA6D852", 1)
SafeAddString(SI_COMBAT_METRICS_ULTIMATE_COLOR, "FFffe785", 1)
	
-- Ingame (Use ZOS Tranlations, change only for languages which are not supported)

SafeAddString(SI_COMBAT_METRICS_MAGICKA, GetString(SI_COMBATMECHANICTYPE0), 1)  --Magicka 
SafeAddString(SI_COMBAT_METRICS_STAMINA, GetString(SI_ATTRIBUTES3), 1)  --Stamina 
SafeAddString(SI_COMBAT_METRICS_ULTIMATE, GetString(SI_COMBATMECHANICTYPE10), 1)  --Ultimate 

-- UI&Control

SafeAddString(SI_COMBAT_METRICS_SHOW_XPS, "<<1>> / <<2>> (<<3>>%)", 1)
SafeAddString(SI_COMBAT_METRICS_CALC, "Calculando...", 1)  -- Calculating...
SafeAddString(SI_COMBAT_METRICS_GROUP, "Grupo", 1)  -- Group
SafeAddString(SI_COMBAT_METRICS_SELECTION, "Seleção", 1)  -- Selection

SafeAddString(SI_COMBAT_METRICS_BASE_REG, "Regeneração Base", 1)  -- Base Regeneration
SafeAddString(SI_COMBAT_METRICS_DRAIN, "Dreno", 1)  -- Drain
SafeAddString(SI_COMBAT_METRICS_UNKNOWN, "Desconhecido", 1)  -- Unknown

SafeAddString(SI_COMBAT_METRICS_BLOCKS, "Bloqueios", 1)  -- Blocks
SafeAddString(SI_COMBAT_METRICS_CRITS, "Criticos", 1)  -- Crits

SafeAddString(SI_COMBAT_METRICS_DAMAGE, "Dano", 1)  -- Damage
SafeAddString(SI_COMBAT_METRICS_HIT, "Golpe", 1)
SafeAddString(SI_COMBAT_METRICS_DPS, "DPS", 1)

SafeAddString(SI_COMBAT_METRICS_HEALING, "Curando", 1)  -- Healing
SafeAddString(SI_COMBAT_METRICS_HEALS, "Curas", 1)
SafeAddString(SI_COMBAT_METRICS_HPS, "CPS", 1)
	
SafeAddString(SI_COMBAT_METRICS_EDIT_TITLE, "Duplo clique para editar o nome da luta", 1)

SafeAddString(SI_COMBAT_METRICS_DAMAGE_CAUSED, "Dano Causado", 1)  -- Damage Caused
SafeAddString(SI_COMBAT_METRICS_DAMAGE_RECEIVED, "Dano Recebido", 1)  -- Damage Received
SafeAddString(SI_COMBAT_METRICS_HEALING_DONE, "Cura Feita", 1)  -- Healing Done
SafeAddString(SI_COMBAT_METRICS_HEALING_RECEIVED, "Cura Recebida", 1)  -- Healing Recieved

SafeAddString(SI_COMBAT_METRICS_TOGGLE_FIGHTSTATS, "Estatísticas da Luta", 1)  -- Fight Stats
SafeAddString(SI_COMBAT_METRICS_TOGGLE_COMBAT_LOG, "Log do Combate", 1)  -- Combat Log
SafeAddString(SI_COMBAT_METRICS_TOGGLE_GRAPH, "Gráfico", 1)  -- Graph
SafeAddString(SI_COMBAT_METRICS_TOGGLE_INFO, "Infor.", 1)  -- Info
SafeAddString(SI_COMBAT_METRICS_TOGGLE_SETTINGS, "Opções", 1)  -- Settings
	
SafeAddString(SI_COMBAT_METRICS_SHOWIDS, "Mostra IDs", 1)  -- Show IDs for units, buffs and abilities
SafeAddString(SI_COMBAT_METRICS_HIDEIDS, "Esconde IDs", 1)  -- Hide IDs for units, buffs and abilities
	
SafeAddString(SI_COMBAT_METRICS_POSTSINGLEDPS, "Posta DPS de unico alvo", 1)
SafeAddString(SI_COMBAT_METRICS_POSTSMARTDPS, "Posta DPS do Chefe alvo", 1)
SafeAddString(SI_COMBAT_METRICS_POSTMULTIDPS, "Posta DPS total", 1)
SafeAddString(SI_COMBAT_METRICS_POSTALLDPS, "Posta DPS único e total", 1)
SafeAddString(SI_COMBAT_METRICS_POSTHPS, "Posta CPS", 1)

SafeAddString(SI_COMBAT_METRICS_STORAGE_FULL, "O arquivo de armazenamento está cheio. A luta que você quer salvar precisa de <<1>> MB e <<2>> indices. Apque uma luta para liberar algum espaço ou aumente o espaço permitido nas configurações!", 1)  -- The storage file is full. Delete a fight to free some space!

SafeAddString(SI_COMBAT_METRICS_PREVIOUS_FIGHT, "Luta Anterior", 1)  -- Previous Fight
SafeAddString(SI_COMBAT_METRICS_NEXT_FIGHT, "Próxima Luta", 1)  -- Next Fight
SafeAddString(SI_COMBAT_METRICS_MOST_RECENT_FIGHT, "Luta Mais Recente", 1)  -- Most Recent Fight
SafeAddString(SI_COMBAT_METRICS_LOAD_FIGHT, "Lê Luta", 1)  -- Load Fight
SafeAddString(SI_COMBAT_METRICS_SAVE_FIGHT, "Clique: Salva luta", 1)  -- Click: Save fight
SafeAddString(SI_COMBAT_METRICS_SAVE_FIGHT2, "Shift+Clique: Salva a luta com o log de combate", 1)  -- Shift+Click: Save fight with combat log
SafeAddString(SI_COMBAT_METRICS_DELETE_COMBAT_LOG, "Apaga o Log de Combate", 1)  -- Delete Combat Log
SafeAddString(SI_COMBAT_METRICS_DELETE_FIGHT, "Apaga Luta", 1)  -- Delete Fight

SafeAddString(SI_COMBAT_METRICS_RECENT_FIGHT, "Lutas Recentes", 1)  -- Recent Fights
SafeAddString(SI_COMBAT_METRICS_DURATION, "Duração", 1)  -- Duration
SafeAddString(SI_COMBAT_METRICS_CHARACTER, "Personagem", 1)  -- Character
SafeAddString(SI_COMBAT_METRICS_ZONE, "Zona", 1)  -- Zone
SafeAddString(SI_COMBAT_METRICS_TIME, "Hora", 1)  -- Time

SafeAddString(SI_COMBAT_METRICS_SHOW, "Mostra", 1)  -- Show
SafeAddString(SI_COMBAT_METRICS_DELETE, "Apaga", 1)  -- Delete

SafeAddString(SI_COMBAT_METRICS_SAVED_FIGHTS, "Lutas Salvas", 1)  -- Saved Fights

SafeAddString(SI_COMBAT_METRICS_ACTIVE_TIME, "Tempo Ativo: ", 1)  -- Active Time: 
SafeAddString(SI_COMBAT_METRICS_ZERO_SEC, "0 s", 1)  -- 0 s
SafeAddString(SI_COMBAT_METRICS_IN_COMBAT, "Em Combate: ", 1)  -- In Combat: 

SafeAddString(SI_COMBAT_METRICS_PLAYER, "Jogador", 1)  -- Player

SafeAddString(SI_COMBAT_METRICS_TOTAL, " Total: ", 1)  -- Total: 
SafeAddString(SI_COMBAT_METRICS_NORMAL, "Normal: ", 1)  -- Normal: 
SafeAddString(SI_COMBAT_METRICS_CRITICAL, "Critico: ", 1)  -- Critical: 
SafeAddString(SI_COMBAT_METRICS_BLOCKED, "Bloqueado: ", 1)  -- Blocked: 
SafeAddString(SI_COMBAT_METRICS_SHIELDED, "Escudo: ", 1)  -- Shielded: 

SafeAddString(SI_COMBAT_METRICS_HITS, "Golpes", 1)  -- Hits

SafeAddString(SI_COMBAT_METRICS_RESOURCES, "Recursos", 1)  --Resources

SafeAddString(SI_COMBAT_METRICS_STATS, "Estatisticas", 1)  --Stats
SafeAddString(SI_COMBAT_METRICS_AVE, "Med", 1)  --Average
SafeAddString(SI_COMBAT_METRICS_MAX, "Max", 1)  --Maximum

SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA1, "Mágicka Máxima:", 1)  --Max Magicka:
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA2, "Dano de Feitiço:", 1)  --Spell Damage:
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA3, "Feitiço Crítico:", 1)  --Spell Critical:
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT3, "%.1f %%", 1)  --%.1f %%
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA4, "Dano Crítico:", 1)  --Critical Damage:
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA5, "Penet. Feitiço:", 1)  --Spell Penetration:
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA6, "Overpenetração:", 1)  --Overpenetration:
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT6, "%.1f %%", 1)  --%.1f %%

SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA1, "Vigor Máximo:", 1)  --Max Stamina:
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA2, "Dano de Arma:", 1)  --Weapon Damage:
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA3, "Crítico de Arma:", 1)  --Weapon Critical:
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA_FORMAT3, "%.1f %%", 1)  --Spell Critical:
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA4, "Dano Crítico:", 1)  --Critical Damage:
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA5, "Penetração Fisica:", 1)  --Physical Penetration:
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA6, "Overpenetração:", 1)  --Overpenetration:
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA_FORMAT6, "%.1f %%", 1)  --%.1f %%

SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH1, "Saúde Máxima:", 1)  --Max Magicka:
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH2, "Resist. Fisica:", 1)  --Physical Resist.:
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH3, "Resist. Feitiço:", 1)  --Spell Resistance:
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH4, "Resist. Crítico:", 1)  --Critical Resist.:
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH_FORMAT4, "%.1f %%", 1)  --Critical Resist.:

SafeAddString(SI_COMBAT_METRICS_COMBAT_LOG, "Log de Combate", 1)  --Combat Log

SafeAddString(SI_COMBAT_METRICS_GOTO_PREVIOUS, "Vai para págs. anteriores", 1)  --Go to previous pages
SafeAddString(SI_COMBAT_METRICS_PAGE, "Pág. <<1>>", 1)  --Page 
SafeAddString(SI_COMBAT_METRICS_GOTO_NEXT, "Vai para págs. seguintes", 1)  --Go to next pages

SafeAddString(SI_COMBAT_METRICS_TOGGLE_HEAL, "Alterna entre eventos de cura recebida", 1)  --Toggle received heal events
SafeAddString(SI_COMBAT_METRICS_TOGGLE_DAMAGE, "Alterna entre eventos de dano recebido", 1)  --Toggle received damage events

SafeAddString(SI_COMBAT_METRICS_TOGGLE_YOUR_HEAL, "Alterna entre os seus eventos de cura", 1)  --Toggle your healing events
SafeAddString(SI_COMBAT_METRICS_TOGGLE_YOUR_DAMAGE, "Alterna entre os seus eventos de dano", 1)  --Toggle your damage events

SafeAddString(SI_COMBAT_METRICS_TOGGLE_BUFFIN_EVENTS, "Alterna entre eventos de bônus recebidos", 1)  --Toggle buff events
SafeAddString(SI_COMBAT_METRICS_TOGGLE_BUFFOUT_EVENTS, "Alterna entre eventos de bônus enviados", 1)  --Toggle buff events
SafeAddString(SI_COMBAT_METRICS_TOGGLE_GROUPBUFFIN_EVENTS, "Alterna entre eventos de bônus de grupo recebidos", 1)  --Toggle buff events
SafeAddString(SI_COMBAT_METRICS_TOGGLE_GROUPBUFFOUT_EVENTS, "Alterna entre eventos de bônus de grupo enviados", 1)  --Toggle buff events
SafeAddString(SI_COMBAT_METRICS_TOGGLE_RESOURCE_EVENTS, "Alterna entre eventos de recursos", 1)  --Toggle resource events
SafeAddString(SI_COMBAT_METRICS_TOGGLE_STATS_CHANGE_EVENTS, "Alterna entre eventos de alteração de status", 1)  --Toggle stats change events
SafeAddString(SI_COMBAT_METRICS_TOGGLE_MESSAGE_CHANGE_EVENTS, "Alterna eventos de alternancia ex. troca de arma", 1)  --Toggle stats change events

SafeAddString(SI_COMBAT_METRICS_DEBUFF_IN, "(De-)Bônus\nVindo", 1)  --(De-)Buffs\nIn (\n is newline,
SafeAddString(SI_COMBAT_METRICS_DEBUFF_OUT, "(De-)Bônus\nIndo", 1)  --(De-,Buffs\nOut
SafeAddString(SI_COMBAT_METRICS_MAGICKA_PM, "Mágicka\n +/-", 1)  --Magicka\n +/-
SafeAddString(SI_COMBAT_METRICS_STAMINA_PM, "Vigor\n +/-", 1)  --Stamina\n +/-
SafeAddString(SI_COMBAT_METRICS_RESOURCES_PM, "Recursos\n +/-", 1)  --Resources\n +/-

SafeAddString(SI_COMBAT_METRICS_BUFF, "Bônus", 1)  --Buff
SafeAddString(SI_COMBAT_METRICS_SHARP, "#", 1)  --#
SafeAddString(SI_COMBAT_METRICS_BUFFCOUNT_TT, "Jogador / Geral", 1)  --Player / Overall
SafeAddString(SI_COMBAT_METRICS_UPTIME, "Atividade", 1)  --Uptime
SafeAddString(SI_COMBAT_METRICS_UPTIME_TT, "Jogador % / Geral %", 1)  --Player % / Overall %

SafeAddString(SI_COMBAT_METRICS_REGENERATION, "Regeneração", 1)  -- Source
SafeAddString(SI_COMBAT_METRICS_CONSUMPTION, "Consumo", 1)  -- Consumption
SafeAddString(SI_COMBAT_METRICS_PM_SEC, "±/s", 1)  --±/s
SafeAddString(SI_COMBAT_METRICS_TARGET, "Alvo", 1)  --Target
SafeAddString(SI_COMBAT_METRICS_PERCENT, "%", 1)  --%
SafeAddString(SI_COMBAT_METRICS_UNITDPS_TT, "DPS Real, ex. o dano por segundo entre seu primeiro e seu ultimo golpe no alvo", 1)  --%

SafeAddString(SI_COMBAT_METRICS_ABILITY, "Habilidade", 1)  --Ability
SafeAddString(SI_COMBAT_METRICS_PER_HITS, "/Golpes", 1)  --/Hits
SafeAddString(SI_COMBAT_METRICS_CRITS_PER, "Crit %", 1)  --Crit %
	
SafeAddString(SI_COMBAT_METRICS_FAVOURITE_ADD, "Inclui nos Favoritos", 1)  -- Add to Favourites NEW
SafeAddString(SI_COMBAT_METRICS_FAVOURITE_REMOVE, "Remove dos Favoritos", 1)  -- Remove from Favourites NEW

-- Menus

SafeAddString(SI_COMBAT_METRICS_MENU_PROFILES, "Perfis", 1)  --Profiles

SafeAddString(SI_COMBAT_METRICS_MENU_AC_NAME, "Usa configurações p/ toda conta", 1)  --Use accountwide settings
SafeAddString(SI_COMBAT_METRICS_MENU_AC_TOOLTIP, "Se habilitado todos os personagens de uma conta vão compartilhar suas configurações", 1)  --If enabled all chars of an account will share their settings

SafeAddString(SI_COMBAT_METRICS_MENU_GS_NAME, "Configurações Gerais", 1)  --General Settings
	
SafeAddString(SI_COMBAT_METRICS_MENU_FH_NAME, "Histórico de Luta", 1)  --Fight History
SafeAddString(SI_COMBAT_METRICS_MENU_FH_TOOLTIP, "Numero de lutas recentes a salvar", 1)  --Number of recent fights to save	
	
SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_NAME, "Memória para Lutas Salvas ", 1)  --Saved Fight Memory
SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_TOOLTIP, "Tamanho Máximo de memória para lutas salvas em MB", 1)  --Maximum memory size for saved fights in MB
SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_WARNING, "Use com cuidado! Muitos dados salvos aumentam significativamente o tempo de carregamento. Se o arquivo ficar muito grande, o cliente pode dar erro quando tentar ler.", 1)  -- Use with caution! Lots of saved data significantly increase loading times. If the file gets too large, the client might crash when attempting to load it.
	
SafeAddString(SI_COMBAT_METRICS_MENU_BOSSFIGHTS_NAME, "Guarda Lutas com Chefes", 1)  --Keep Boss Fights
SafeAddString(SI_COMBAT_METRICS_MENU_BOSSFIGHTS_TOOLTIP, "Apaga as lutas lixo primeiro, antes de apagar as lutas com os chefes quando o limite de lutas for alcançado", 1)  --Delete trash fights first before deleting boss fights when limit of fights is reached
	
SafeAddString(SI_COMBAT_METRICS_MENU_MG_NAME, "Monitora Dano do Grupo", 1)  --Monitor Group Damage
SafeAddString(SI_COMBAT_METRICS_MENU_MG_TOOLTIP, "Monitora os eventos de todo o grupo", 1)  --Monitor the events of the whole group
	
SafeAddString(SI_COMBAT_METRICS_MENU_STACKS_NAME, "Mostra pilhas de bônus", 1)  --Monitor the events of the whole group
SafeAddString(SI_COMBAT_METRICS_MENU_STACKS_TOOLTIP, "Mostra pilhas individuais no painel de bônus", 1)  --Monitor the events of the whole group

SafeAddString(SI_COMBAT_METRICS_MENU_GL_NAME, "Monitora Dano em grupos grandes", 1)  --Monitor Damage in large groups
SafeAddString(SI_COMBAT_METRICS_MENU_GL_TOOLTIP, "Monitora o dano de grupos grandes (mais de 4 membros)", 1)  --Don't Monitor Group Damage in Large Groups

SafeAddString(SI_COMBAT_METRICS_MENU_LM_NAME, "Modo Leve", 1)  -- Light Mode
SafeAddString(SI_COMBAT_METRICS_MENU_LM_TOOLTIP, "Quando no modo leve, o combat metrics só vai calcular o DPS/CPS na janela de relatório ativa. Nenhuma estatística será calculada e a janela grande de relatório será desativada", 1)  --When in light mode, combat metrics will only calculate the DPS/HPS in the live report window. No statistics will be calculated and the big report window will be disabled

SafeAddString(SI_COMBAT_METRICS_MENU_NOPVP_NAME, "Desliga em Cyrodil", 1)  -- Turn off in PVP
SafeAddString(SI_COMBAT_METRICS_MENU_NOPVP_TOOLTIP, "Desliga todos os logs de lutas em Cyrodil", 1)  --Turns all fight logging off in Cyrodil

SafeAddString(SI_COMBAT_METRICS_MENU_LMPVP_NAME, "Modo Leve em Cyrodil", 1)  --Light Mode in PVP
SafeAddString(SI_COMBAT_METRICS_MENU_LMPVP_TOOLTIP, "Alterna para o modo leve em Cyrodil. Quando no modo leve, o Combat Metrics só calcula o DPS/CPS na janela de relatório ativa. Nenhuma estatística será calculada e a janela grande de relatório será desativada", 1)  -- Swiches to light mode in PVP areas. When in light mode, combat metrics will only calculate the DPS/HPS in the live report window. No statistics will be calculated and the big report window will be disabled

SafeAddString(SI_COMBAT_METRICS_MENU_ASCC_NAME, "Auto Escolhe Canal", 1)  --Auto Screenshot
SafeAddString(SI_COMBAT_METRICS_MENU_ASCC_TOOLTIP, "Automaticamente escolhe o canal quando postar o DPS/CPS no chat. Quando em grupo o chat /group é usado senão usa o chat /say.", 1)  --Automatically take a Screenshot when opening the Report window
SafeAddString(SI_COMBAT_METRICS_MENU_AS_NAME, "Auto Screenshot", 1)  --Auto Screenshot
SafeAddString(SI_COMBAT_METRICS_MENU_AS_TOOLTIP, "Automaticamente tira uma Screenshot quando abrir a janela de Relatório", 1)  --Automatically take a Screenshot when opening the Report window
SafeAddString(SI_COMBAT_METRICS_MENU_ML_NAME, "Tamanho minimo da luta para screenshot", 1)  --Minimum fight length for screenshot
SafeAddString(SI_COMBAT_METRICS_MENU_ML_TOOLTIP, "Menor tamanho de luta em s para o auto screenshot", 1)  --Minimum fight length in s for auto screenshot
SafeAddString(SI_COMBAT_METRICS_MENU_SF_NAME, "Escala da Janela de Relatório de Luta", 1)  --Scale of Fight Report Window
SafeAddString(SI_COMBAT_METRICS_MENU_SF_TOOLTIP, "Ajusta o tamanho de todos os elementos da janela de Relatório de Luta", 1)  --Adjusts the size of all elements of the Fightreport Window

SafeAddString(SI_COMBAT_METRICS_MENU_RESPEN_NAME, "Resistência e Penetração", 1)  --Live Report Window NEW
SafeAddString(SI_COMBAT_METRICS_MENU_CRUSHER, "Esmagador", 1)  --Crusher NEW
SafeAddString(SI_COMBAT_METRICS_MENU_CRUSHER_TOOLTIP, "Redução de resistência devido à penalidade do glifo Esmagador. Para o glifo dourado nível máximo: padrão: 1622, infundido: 2108", 1)  --Resistance reduction due to debuff from Crusher glyph. For maxlevel gold glyph: standard: 1622, infused: 1946 NEW
SafeAddString(SI_COMBAT_METRICS_MENU_MOBRESISTANCE, "Resistência do Alvo", 1)  --Target Resistance NEW
SafeAddString(SI_COMBAT_METRICS_MENU_MOBRESISTANCE_TOOLTIP, "Resistência do Alvo que é assumida para o cálculo de overpenetração", 1)  --Target resistance that is assumed for overpenetration calculation NEW
	
SafeAddString(SI_COMBAT_METRICS_MENU_LR_NAME, "Janela de Relatório Ativa", 1)  --Live Report Window
SafeAddString(SI_COMBAT_METRICS_MENU_ENABLE_NAME, "Habilitada", 1)  --Enable
SafeAddString(SI_COMBAT_METRICS_MENU_ENABLE_TOOLTIP, "Habilita a Janela de Relatório Ativa que mostra DPS & CPS durante o combate", 1)  --Enable Live Report Window which shows DPS & HPS during combat
	
SafeAddString(SI_COMBAT_METRICS_MENU_LOCK, "Trava", 1)  --Lock NEW
SafeAddString(SI_COMBAT_METRICS_MENU_LOCK_LR_TOOLTIP, "Trava a Janela de Relatório Ativa, para que não possa ser movida", 1)  -- Lock the Live Report Window, so it can't be moved NEW
	
SafeAddString(SI_COMBAT_METRICS_MENU_LAYOUT_NAME, "Layout", 1)  --Layout
SafeAddString(SI_COMBAT_METRICS_MENU_LAYOUT_TOOLTIP, "Escolhe o Layout da Janela de Relatório Ativa", 1)  --Select the Layout of the Live Report Window
SafeAddString(SI_COMBAT_METRICS_MENU_SCALE_NAME, "Escala", 1)  --Scale
SafeAddString(SI_COMBAT_METRICS_MENU_SCALE_TOOLTIP, "Escala da Janela de Relatório Ativa.", 1)  --Scale of the Live report window.
	
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_BG_NAME, "Mostra Fundo", 1)  --Show Background OLD
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_BG_TOOLTIP, "Mostra o fundo na Janela de Relatório Ativa", 1)  --Show the Background og the Live Report Window OLD
	
SafeAddString(SI_COMBAT_METRICS_MENU_BGALPHA_NAME, "Opacidade do Fundo", 1)  --Show Background NEW
SafeAddString(SI_COMBAT_METRICS_MENU_BGALPHA_TOOLTIP, "Define a Opacidade do Fundo", 1)  --Set the Opacity of the Background NEW
	
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_DPS_NAME, "Mostra DPS", 1)  --Show DPS
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_DPS_TOOLTIP, "Mostra o DPS que você causou na Janela de Relatório Ativa", 1)  --Show DPS you deal in Live Report Window
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_SDPS_NAME, "Mostra DPS em único alvo", 1)  --Show DPS
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_SDPS_TOOLTIP, "Mostra o DPS que você causou em um único alvo na Janela de Relatório Ativa", 1)  --Show DPS you deal in Live Report Window
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_HPS_NAME, "Mostra CPS", 1)  --Show HPS
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_HPS_TOOLTIP, "Mostra a CPS que você lançou na Janela de Relatório Ativa", 1)  --Show HPS you cast in Live Report Window
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_NAME, "Mostra DPS vindo", 1)  --Show Incoming DPS
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_TOOLTIP, "Mostra o DPS que você recebeu na Janela de Relatório Ativa", 1)  --Show DPS you receive in Live Report Window
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_NAME, "Mostra CPS vinda", 1)  --Show Incoming HPS
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_TOOLTIP, "Mostra a CPS que você recebeu na Janela de Relatório Ativa", 1)  --Show HPS you receive in Live Report Window
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_TIME_NAME, "Mostra Tempo", 1)  --Show Time
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_TIME_TOOLTIP, "Mostra o Tempo que você ficou causando dano na Janela de Relatório Ativa", 1)  --Show Time you have been dealing damage in Live Report Window

SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE, "Dados de Combate no chat", 1)  --Stream Combat Log to chat
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_DH_TOOLTIP, "Envia os dados dos Eventos de Dano e Cura para a janela de chat", 1)  --Streams Damage and Heal Events to chat window
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE_NAME, "Titulo do Chat Log", 1)  --Show damage
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE_TOOLTIP, "Mostra o dano que você causou no envio para o chat", 1)  --Show damage you deal in chat stream
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SD_NAME, "Mostra dano", 1)  --Show damage
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SD_TOOLTIP, "Mostra o dano que você causou no envio para o chat", 1)  --Show damage you deal in chat stream
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SH_NAME, "Mostra curas", 1)  --Show heals
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SH_TOOLTIP, "Mostra as curas que você lançou no envio para o chat", 1)  --Show heals you cast in chat stream
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SID_NAME, "Mostra Dano Vindo", 1)  --Show Incoming damage
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SID_TOOLTIP, "Mostra o dano que você recebeu no envio para o chat", 1)  --Show damage you receive in chat stream
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SIH_NAME, "Mostra Cura Vinda", 1)  --Show Incoming heal
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SIH_TOOLTIP, "Mostra as curas que você recebeu no envio para o chat", 1)  --Show heals you receive in chat stream

SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_TITLE, "Opções de Debug", 1)  --Debug options
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SF_NAME, "Mostra Recap de Luta", 1)  --Show Fight Recap
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SF_TOOLTIP, "Imprime Resultados do Combate na janela de chat do sistema", 1)  --Print Combat Results to the system chat window
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SA_NAME, "Mostra IDs das Habilidades", 1)  --Show ability IDs
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SA_TOOLTIP, "Mostra os ids das habilidades na janela de relatório de luta", 1)  --Show ability ids in the fight report window
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SFC_NAME, "Mostra Informação de Cálculo de Luta", 1)  --Show Fight Calculation Info
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SFC_TOOLTIP, "Imprime as Informações sobre o cálculo dos tempos na janela de chat do sistema", 1)  --Print Info about the calculation timings to the system chat window
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_BI_NAME, "Mostra Info de Bônus", 1)  --Show Buff Info
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_BI_TOOLTIP, " Imprime os events de Bônus na janela de chat do sistema (Spammy)", 1)  --Print Buff events to the system chat window (Spammy,
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_US_NAME, "Mostra Info de habilidade Usada", 1)  --Show used Skill Info
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_US_TOOLTIP, "Imprime os eventos de habilidades usadas na janela de chat do sistema", 1)  --Print used skill events to the system chat window
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SG_NAME, "Mostra Info do Grupo", 1)  --Show group Info
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SG_TOOLTIP, "Imprime eventos de entrar e sair do grupo na janela de chat do sistema", 1)  --Print group joining and leave events to the system chat window
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_MD_NAME, "Mostra Informações diversas de Debug", 1)  --Show miscellaneous debug Info
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_MD_TOOLTIP, "imprime algumas outros eventos na janela de chat do sistema", 1)  --Print some other events to the system chat window
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SPECIAL_NAME, "Show Informação especial de debug", 1)  --Show miscellaneous debug Info
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SPECIAL_TOOLTIP, "Imprime certos eventos especiais na janela de chat do sistema", 1)  --Print some other events to the system chat window
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SAVE_NAME, "Mostra Informação de dados salvos", 1)  --Show group Info
SafeAddString(SI_COMBAT_METRICS_MENU_DEBUG_SAVE_TOOLTIP, "Imprime informações de debug sobre lutas salvas e lidas na janela de chat do sistema", 1)  --Print group joining and leave events to the system chat window
	
-- make a label for keybinding

SafeAddString(SI_BINDING_NAME_CMX_REPORT_TOGGLE, "Alterna Relatório de Luta", 1)
SafeAddString(SI_BINDING_NAME_CMX_LIVEREPORT_TOGGLE, "Alterna Relatório Ativo", 1)
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_SMART, "Posta Chefe ou DPS Total", 1)
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_SINGLE, "Posta DPS de Único Alvo", 1)
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_MULTI, "Posta DPS Multi Alvo", 1)
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS, "Posta DPS de Único + Multi Alvo", 1)
SafeAddString(SI_BINDING_NAME_CMX_POST_HPS, "Posta Cura no Chat", 1)
SafeAddString(SI_BINDING_NAME_CMX_RESET_FIGHT, "Reinicia a Luta Manualmente", 1)
	


--for stringId, stringValue in pairs(strings) do
--	ZO_CreateStringId(stringId, stringValue)
--	SafeAddVersion(stringId, 1)
--end
