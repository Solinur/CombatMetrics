-- Translated by: Cisneros

local strings = {

-- Colors

	SI_COMBAT_METRICS_SEP_COLOR = "FFAAAAAA",
	SI_COMBAT_METRICS_HEALTH_COLOR = "FFDE6531",
	SI_COMBAT_METRICS_MAGICKA_COLOR = "FF5EBDE7",
	SI_COMBAT_METRICS_STAMINA_COLOR = "FFA6D852",
	SI_COMBAT_METRICS_ULTIMATE_COLOR = "FFffe785",

-- URLs (Feedback Menu)

	SI_COMBAT_METRICS_FEEDBACK_ESOUIURL = "https://www.esoui.com/downloads/info1360-CombatMetrics.html",
	SI_COMBAT_METRICS_FEEDBACK_GITHUBURL = "https://github.com/Solinur/CombatMetrics",
	SI_COMBAT_METRICS_FEEDBACK_DISCORDURL = "https://discord.gg/2eqYt2n5M5",
	SI_COMBAT_METRICS_DONATE_ESOUIURL = "https://www.esoui.com/downloads/info1360-CombatMetrics.html#donate",

-- Localization Start

-- Functionality

	SI_COMBAT_METRICS_LANG = "es",
	SI_COMBAT_METRICS_ENCHANTMENT_TRIM = " Encantamiento", -- esto se eliminará de la cadena del encantamiento del objeto para mostrar el resto en el panel de información, por ejemplo, "Encantamiento de Daño de Hechizo" se reduce a "Daño de Hechizo".

-- Fonts

	SI_COMBAT_METRICS_STD_FONT = "$(MEDIUM_FONT)",
	SI_COMBAT_METRICS_BOLD_FONT = "$(BOLD_FONT)",

	SI_COMBAT_METRICS_FONT_SIZE_SMALL = "14",
	SI_COMBAT_METRICS_FONT_SIZE = "15",
	SI_COMBAT_METRICS_FONT_SIZE_TITLE = "20",

-- Main UI

	SI_COMBAT_METRICS_CALC = "Calculando...",
	SI_COMBAT_METRICS_LOADING = "Cargando...",
	SI_COMBAT_METRICS_FINALIZING = "Finalizando...",
	SI_COMBAT_METRICS_GROUP = "Grupo",
	SI_COMBAT_METRICS_SELECTION = "Selección",

	SI_COMBAT_METRICS_BASE_REG = "Regeneración Base",
	SI_COMBAT_METRICS_DRAIN = "Drenaje",
	SI_COMBAT_METRICS_UNKNOWN = "Desconocido",

	SI_COMBAT_METRICS_BLOCKS = "Bloqueos",
	SI_COMBAT_METRICS_CRITS = "Críticos",

	SI_COMBAT_METRICS_DAMAGE = "Daño",
	SI_COMBAT_METRICS_DAMAGEC = "Daño: ",
	SI_COMBAT_METRICS_HIT = "Golpe",
	SI_COMBAT_METRICS_DPS = "DPS",
	SI_COMBAT_METRICS_INCOMING_DPS = "DPS Entrante",

	SI_COMBAT_METRICS_HEALING = "Curación",
	SI_COMBAT_METRICS_HEALS = "Curas",
	SI_COMBAT_METRICS_HPS = "HPS",
	SI_COMBAT_METRICS_HPSA = "HPS + Sobrecuración",
	SI_COMBAT_METRICS_INCOMING_HPS = "HPS Entrante",

	SI_COMBAT_METRICS_EDIT_TITLE = "Haz doble clic para editar el nombre de la pelea",

	SI_COMBAT_METRICS_DAMAGE_CAUSED = "Daño Causado",
	SI_COMBAT_METRICS_DAMAGE_RECEIVED = "Daño Recibido",
	SI_COMBAT_METRICS_HEALING_DONE = "Curación Realizada",
	SI_COMBAT_METRICS_HEALING_RECEIVED = "Curación Recibida",

	SI_COMBAT_METRICS_TOGGLE_FIGHTSTATS = "Estadísticas de Pelea",
	SI_COMBAT_METRICS_TOGGLE_COMBAT_LOG = "Registro de Combate",
	SI_COMBAT_METRICS_TOGGLE_GRAPH = "Gráfico",
	SI_COMBAT_METRICS_TOGGLE_INFO = "Información",
	SI_COMBAT_METRICS_TOGGLE_SETTINGS = "Opciones",

	SI_COMBAT_METRICS_NOTIFICATION = "Mi Raid |cffff00Beyond Infinity|r busca un MagDK/Necro para vCR+3 (Greifenherz).",
	SI_COMBAT_METRICS_NOTIFICATION_GUILD = "Info: |cffff00Beyond Infinity|r",
	SI_COMBAT_METRICS_NOTIFICATION_ACCEPT = "Mensaje Leído",
	SI_COMBAT_METRICS_NOTIFICATION_DISCARD = "Desactivar notificaciones",

	-- Options Menu Strings

	SI_COMBAT_METRICS_SHOWIDS = "Mostrar IDs", -- (para unidades, buffs y habilidades)
	SI_COMBAT_METRICS_HIDEIDS = "Ocultar IDs", -- (para unidades, buffs y habilidades)

	SI_COMBAT_METRICS_SHOWOVERHEAL = "Mostrar sobrecuración", -- (para unidades, buffs y habilidades)
	SI_COMBAT_METRICS_HIDEOVERHEAL = "Ocultar sobrecuración", -- (para unidades, buffs y habilidades)

	SI_COMBAT_METRICS_POSTDPS = "Publicar DPS/HPS",
	SI_COMBAT_METRICS_POSTSINGLEDPS = "Publicar DPS de un solo objetivo",
	SI_COMBAT_METRICS_POSTSMARTDPS = "Publicar DPS de objetivo jefe",
	SI_COMBAT_METRICS_POSTMULTIDPS = "Publicar DPS total",
	SI_COMBAT_METRICS_POSTALLDPS = "Publicar DPS único y total",
	SI_COMBAT_METRICS_POSTHPS = "Publicar HPS",
	SI_COMBAT_METRICS_POSTUNITDPS = "Publicar DPS a esta unidad",
	SI_COMBAT_METRICS_POSTUNITNAMEDPS = "Publicar DPS a unidades '<<tm:1>>'", -- <<tm:1>> es el nombre de la unidad
	SI_COMBAT_METRICS_POSTSELECTIONDPS = "Publicar DPS a unidades seleccionadas",
	SI_COMBAT_METRICS_POSTSELECTIONHPS = "Publicar HPS a unidades seleccionadas",

	-- Format Strings for DPS posting

	SI_COMBAT_METRICS_BOSS_DPS = "DPS de Jefe",

	SI_COMBAT_METRICS_POSTDPS_FORMAT = "<<1>> - DPS: <<2>> (<<3>> en <<4>>)", -- para DPS de un solo objetivo (<<1>> = nombre de la pelea, <<2>> = DPS, <<3>> = daño, <<4>> = tiempo) ej. Z'Maja - DPS: 10000 (1000000 en 1:40.0)
	SI_COMBAT_METRICS_POSTSMARTDPS_FORMAT = "<<1>><<2>> - DPS de Jefe: <<3>> (<<4>> en <<5>>)", -- (<<1>> = nombre de la pelea, <<2>> = unidades adicionales (puede ser ""), <<3>> = DPS, <<4>> = daño, <<5>> = tiempo) ej. Valariel (+5) - DPS de Jefe: 10000 (1000000 en 1:40.0)
	SI_COMBAT_METRICS_POSTMULTIDPS_FORMAT = "<<1>> (+<<2>>) - DPS: <<3>> (<<4>> en <<5>>)", -- (<<1>> = nombre de la pelea, <<2>> = unidades adicionales, <<3>> = DPS, <<4>> = daño, <<5>> = tiempo) ej. Some random Mob (+5) - DPS: 10000 (1000000 en 1:40.0)
	SI_COMBAT_METRICS_POSTALLDPS_FORMAT_A = "<<1>> - DPS Total (+<<2>>): <<3>> (<<4>> en <<5>>)", -- parte de múltiples objetivos (<<1>> = nombre de la pelea, <<2>> = unidades adicionales, <<3>> = DPS, <<4>> = daño, <<5>> = tiempo) ej. Valariel - DPS Total (+5): 10000 (1000000 en 1:40.0)
	SI_COMBAT_METRICS_POSTALLDPS_FORMAT_B = "<<1>>: <<2>> (<<3>> en <<4>>)", -- parte de un solo objetivo (<<1>> = Etiqueta, <<2>> = DPS, <<3>> = daño) ej. DPS de Jefe (+2): 10000 (1000000 en 1:40.0)
	SI_COMBAT_METRICS_POSTSELECTIONDPS_FORMAT = "<<1>><<2>> - DPS de Selección: <<3>> (<<4>> en <<5>>)", -- (<<1>> = nombre de la pelea, <<2>> = unidades adicionales (puede ser ""), <<3>> = DPS, <<4>> = daño, <<5>> = tiempo) ej. Valariel (+5) - DPS de Jefe: 10000 (1000000 en 1:40.0)
	SI_COMBAT_METRICS_POSTHPS_FORMAT = "<<1>> - HPS: <<2>> (<<3>> en <<4>>)", -- (<<1>> = nombre de la pelea, <<2>> = HPS, <<3>> = daño, <<4>> = tiempo) ej. Z'Maja - HPS: 10000 (1000000 en 1:40.0)
	SI_COMBAT_METRICS_POSTSELECTIONHPS_FORMAT = "<<1>> - HPS de Selección (x<<2>>): <<3>> (<<4>> en <<5>>)", -- (<<1>> = nombre de la pelea, <<2>> = unidades, <<3>> = HPS, <<4>> = daño, <<5>> = tiempo) ej. Z'Maja - HPS (12): 10000 (1000000 en 1:40.0)

	SI_COMBAT_METRICS_POSTBUFF = "Publicar tiempo activo de buff",
	SI_COMBAT_METRICS_POSTBUFF_BOSS = "Publicar tiempo activo de buff en jefes",
	SI_COMBAT_METRICS_POSTBUFF_GROUP = "Publicar tiempo activo de buff en miembros del grupo",
	SI_COMBAT_METRICS_POSTBUFF_FORMAT = "<<1>> - Tiempo activo: <<2>> (<<3>><<4[/ en $d/ en $d unidades]>>)", -- (<<1>> = nombre del buff, <<2>> = tiempo activo relativo, <<3>> = tiempo activo, <<4>> = tiempo) ej. Major Intellect - Tiempo activo: 93.2% (9:26 en 10:07)
	SI_COMBAT_METRICS_POSTBUFF_FORMAT_GROUP = "<<1>> - Tiempo activo: <<2>>/<<5>> (<<3>>/<<6>><<4[/ en $d/ en $d unidades]>>)", -- (<<1>> = nombre del buff, <<2>> = tiempo activo relativo, <<3>> = tiempo activo, <<4>> = unidades, <<5>> = tiempo activo relativo del grupo, <<6>> = tiempo activo del grupo) ej. Minor Sorcery - Tiempo activo: 55.4%/100.6% (5:36/10:11 en 10:07)

	SI_COMBAT_METRICS_SETTINGS = "Configuración del Addon",

	-- Graph

	SI_COMBAT_METRICS_TOGGLE_CURSOR = "Alternar para mostrar el cursor y la herramienta de valor",
	SI_COMBAT_METRICS_GRAPH_BUFF_GROUP_SELECTOR = "Alternar para mostrar el tiempo activo del grupo",

	SI_COMBAT_METRICS_RECALCULATE = "Recalcular Pelea",
	SI_COMBAT_METRICS_SMOOTHED = "Suavizado",
	SI_COMBAT_METRICS_TOTAL = "Total",
	SI_COMBAT_METRICS_ABSOLUTE = "Absoluto %",
	SI_COMBAT_METRICS_SMOOTH_LABEL = "Suavizado: %d s",
	SI_COMBAT_METRICS_NONE = "Ninguno",
	SI_COMBAT_METRICS_BOSS_HP = "Vida del Jefe",
	SI_COMBAT_METRICS_ENLARGE = "Ampliar",
	SI_COMBAT_METRICS_SHRINK = "Reducir",

	-- Feedback

	SI_COMBAT_METRICS_FEEDBACK = "Comentarios",

	SI_COMBAT_METRICS_FEEDBACK_SEND = "Enviar comentarios",

	SI_COMBAT_METRICS_FEEDBACK_EUONLY_FORMAT = "<<1>> (solo UE)",
	SI_COMBAT_METRICS_FEEDBACK_MAIL = "Correo en el juego",
	SI_COMBAT_METRICS_FEEDBACK_MAIL_HEADER = "Comentarios: Combat Metrics %s",

	SI_COMBAT_METRICS_FEEDBACK_ESOUI = "Página de ESOUI",
	SI_COMBAT_METRICS_FEEDBACK_GITHUB = "Repositorio de GitHub",
	SI_COMBAT_METRICS_FEEDBACK_DISCORD = "Discord",

	SI_COMBAT_METRICS_DONATE = "Donar",
	SI_COMBAT_METRICS_DONATE_GOLD = "Oro",
	SI_COMBAT_METRICS_DONATE_GOLD_HEADER = "Donación: Combat Metrics %s",
	SI_COMBAT_METRICS_DONATE_CROWNS = "Coronas",
	SI_COMBAT_METRICS_DONATE_CROWNS_TEXT = "Si deseas regalar algo de la tienda de coronas, estaría feliz de recibir algunas cajas de coronas o artículos consumibles. \nTambién puedes contactarme si deseas regalar algo más.",
	SI_COMBAT_METRICS_DONATE_CROWNS_ACCOUNT = "Mi cuenta:",
	SI_COMBAT_METRICS_DONATE_ESOUI = "Página de Donación",
	
	SI_COMBAT_METRICS_OK = "OK",
	
	SI_COMBAT_METRICS_SAVEDFIGHTS_FULL = "Estás excediendo el número máximo de peleas guardadas. ¡Elimina <<1[una pelea/una pelea/$d peleas]>> o aumenta el número permitido en la configuración!",
	SI_COMBAT_METRICS_CONVERT_DB_TITLE = "COMBAT METRICS",
	SI_COMBAT_METRICS_CONVERT_DB_TEXT = "Esta versión presenta una nueva forma de almacenar peleas. Ocupa menos espacio y reduce los tiempos de carga de la interfaz, incluso con muchas más peleas guardadas. \n\nPara beneficiarte de esto y permitir que se guarden nuevas peleas, todas las peleas almacenadas deben convertirse. \n\nEste proceso puede tardar hasta unos minutos.",
	SI_COMBAT_METRICS_CONVERT_DB_BUTTON1_TEXT = "Convertir",
	SI_COMBAT_METRICS_CONVERT_DB_BUTTON2_TEXT = "Cancelar",
	SI_COMBAT_METRICS_CONVERSION_TITLE_TEXT = "Convirtiendo Pelea <<1>>/<<2>> ...",
	SI_COMBAT_METRICS_CONVERSION_FINISHED_TEXT = "¡Conversión Finalizada!",

	-- Fight Control Button Tooltips

	SI_COMBAT_METRICS_PREVIOUS_FIGHT = "Pelea Anterior",
	SI_COMBAT_METRICS_NEXT_FIGHT = "Pelea Siguiente",
	SI_COMBAT_METRICS_MOST_RECENT_FIGHT = "Pelea Más Reciente",
	SI_COMBAT_METRICS_LOAD_FIGHT = "Cargar Pelea",
	SI_COMBAT_METRICS_SAVE_FIGHT = "Clic: Guardar pelea",
	SI_COMBAT_METRICS_SAVE_FIGHT2 = "Shift+Clic: Guardar pelea con registro de combate",
	SI_COMBAT_METRICS_DELETE_COMBAT_LOG = "Eliminar Registro de Combate",
	SI_COMBAT_METRICS_DELETE_FIGHT = "Eliminar Pelea",

	-- Fight List

	SI_COMBAT_METRICS_RECENT_FIGHT = "Peleas Recientes",
	SI_COMBAT_METRICS_DURATION = "Duración",
	SI_COMBAT_METRICS_CHARACTER = "Personaje",
	SI_COMBAT_METRICS_ZONE = "Zona",
	SI_COMBAT_METRICS_TIME = "Tiempo",
	SI_COMBAT_METRICS_TIME2 = "Tiempo",
	SI_COMBAT_METRICS_TIMEC = "Tiempo: ",

	SI_COMBAT_METRICS_SHOW = "Mostrar",
	SI_COMBAT_METRICS_DELETE = "Eliminar",

	SI_COMBAT_METRICS_SAVED_FIGHTS = "Peleas Guardadas",

	-- More UI Strings

	SI_COMBAT_METRICS_ACTIVE_TIME = "Tiempo Activo: ",
	SI_COMBAT_METRICS_ZERO_SEC = "0 s",
	SI_COMBAT_METRICS_IN_COMBAT = "En Combate: ",

	SI_COMBAT_METRICS_PLAYER = "Jugador",

	SI_COMBAT_METRICS_TOTALC = " Total: ",
	SI_COMBAT_METRICS_NORMAL = "Normal: ",
	SI_COMBAT_METRICS_CRITICAL = "Crítico: ",
	SI_COMBAT_METRICS_BLOCKED = "Bloqueado: ",
	SI_COMBAT_METRICS_SHIELDED = "Escudado: ",
	SI_COMBAT_METRICS_ABSOLUTEC = "Absoluto: ",
	SI_COMBAT_METRICS_OVERHEAL = "Sobrecuración: ", -- como en sobrecuración

	SI_COMBAT_METRICS_HITS = "Golpes",
	SI_COMBAT_METRICS_NORM = "Norm",  -- Normal, corto
	SI_COMBAT_METRICS_OH = "OH",  -- Sobrecuración, corto

	SI_COMBAT_METRICS_RESOURCES = "Recursos",

	SI_COMBAT_METRICS_STATS = "Estadísticas",
	SI_COMBAT_METRICS_AVE = "Prom",  -- Promedio, corto
	SI_COMBAT_METRICS_AVE_N = "Prom N",  -- Promedio Normal, corto
	SI_COMBAT_METRICS_AVE_C = "Prom C",  -- Promedio Crítico, corto
	SI_COMBAT_METRICS_AVE_B = "Prom B",  -- Promedio Bloqueado, corto
	SI_COMBAT_METRICS_AVERAGE = "Promedio",
	SI_COMBAT_METRICS_NORMAL_HITS = "Golpes Normales",
	SI_COMBAT_METRICS_MAX = "Máx",  -- Máximo
	SI_COMBAT_METRICS_MIN = "Mín",  -- Mínimo
	SI_COMBAT_METRICS_EFFECTIVE = "Efectivo",  -- Efectivo

	SI_COMBAT_METRICS_STATS_MAGICKA1 = "Magia Máxima",
	SI_COMBAT_METRICS_STATS_MAGICKA2 = "Daño de Hechizo",
	SI_COMBAT_METRICS_STATS_MAGICKA3 = "Crítico de Hechizo",
	SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT3 = "%.1f %%", -- ej. 12.3%
	SI_COMBAT_METRICS_STATS_MAGICKA4 = "Daño Crítico",
	SI_COMBAT_METRICS_STATS_MAGICKA5 = "Pen. de Hechizo",
	SI_COMBAT_METRICS_STATS_MAGICKA6 = "Sobrepenetración",
	SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT6 = "%.1f %%",-- ej. 12.3%

	SI_COMBAT_METRICS_STATS_STAMINA1 = "Aguante Máximo",
	SI_COMBAT_METRICS_STATS_STAMINA2 = "Daño de Arma",
	SI_COMBAT_METRICS_STATS_STAMINA3 = "Crítico de Arma",
	SI_COMBAT_METRICS_STATS_STAMINA_FORMAT3 = "%.1f %%",-- ej. 12.3%
	SI_COMBAT_METRICS_STATS_STAMINA4 = "Daño Crítico",
	SI_COMBAT_METRICS_STATS_STAMINA5 = "Penetración Física",
	SI_COMBAT_METRICS_STATS_STAMINA6 = "Sobrepenetración",
	SI_COMBAT_METRICS_STATS_STAMINA_FORMAT6 = "%.1f %%",-- ej. 12.3%

	SI_COMBAT_METRICS_STATS_HEALTH1 = "Salud Máxima",
	SI_COMBAT_METRICS_STATS_HEALTH2 = "Res. Física",
	SI_COMBAT_METRICS_STATS_HEALTH3 = "Res. a Hechizos",
	SI_COMBAT_METRICS_STATS_HEALTH4 = "Res. a Críticos",
	SI_COMBAT_METRICS_STATS_HEALTH_FORMAT4 = "%.1f %%",-- ej. 12.3%

	SI_COMBAT_METRICS_PERFORMANCE = "Rendimiento",
	SI_COMBAT_METRICS_PERFORMANCE_FPSAVG = "FPS Promedio",
	SI_COMBAT_METRICS_PERFORMANCE_FPSMIN = "FPS Mínimo",
	SI_COMBAT_METRICS_PERFORMANCE_FPSMAX = "FPS Máximo",
	SI_COMBAT_METRICS_PERFORMANCE_FPSPING = "Ping",
	SI_COMBAT_METRICS_PERFORMANCE_DESYNC = "Desincronización de Habilidad",

	SI_COMBAT_METRICS_PENETRATION_TT = "Penetración vs. Daño",
	SI_COMBAT_METRICS_CRITBONUS_TT = "Crítico vs. Daño",
	SI_COMBAT_METRICS_BACKSTABBER_TT = "*Puñalada trapera se incluye como si todos los objetivos estuvieran siempre flanqueados",

	SI_COMBAT_METRICS_COMBAT_LOG = "Registro de Combate",

	SI_COMBAT_METRICS_GOTO_PREVIOUS = "Ir a la página anterior",
	SI_COMBAT_METRICS_PAGE = "Ir a la página <<1>>", -- <<1>> = número de página
	SI_COMBAT_METRICS_GOTO_NEXT = "Ir a la página siguiente",

	SI_COMBAT_METRICS_TOGGLE_HEAL = "Alternar eventos de curación recibida",
	SI_COMBAT_METRICS_TOGGLE_DAMAGE = "Alternar eventos de daño recibido",

	SI_COMBAT_METRICS_TOGGLE_YOUR_HEAL = "Alternar tus eventos de curación",
	SI_COMBAT_METRICS_TOGGLE_YOUR_DAMAGE = "Alternar tus eventos de daño",

	SI_COMBAT_METRICS_TOGGLE_BUFFIN_EVENTS = "Alternar eventos de buff entrantes",
	SI_COMBAT_METRICS_TOGGLE_BUFFOUT_EVENTS = "Alternar eventos de buff salientes",
	SI_COMBAT_METRICS_TOGGLE_GROUPBUFFIN_EVENTS = "Alternar eventos de buff de grupo entrantes",
	SI_COMBAT_METRICS_TOGGLE_GROUPBUFFOUT_EVENTS = "Alternar eventos de buff de grupo salientes",
	SI_COMBAT_METRICS_TOGGLE_RESOURCE_EVENTS = "Alternar eventos de recursos",
	SI_COMBAT_METRICS_TOGGLE_STATS_CHANGE_EVENTS = "Alternar eventos de cambio de estadísticas",
	SI_COMBAT_METRICS_TOGGLE_MESSAGE_CHANGE_EVENTS = "Alternar eventos de información (ej. cambio de arma)",
	SI_COMBAT_METRICS_TOGGLE_SKILL_USE_EVENTS = "Alternar eventos de habilidades usadas",
	SI_COMBAT_METRICS_TOGGLE_PERFORMANCE_EVENTS = "Alternar información de rendimiento",

	-- \n = nueva línea

	SI_COMBAT_METRICS_DEBUFF_IN = "(De-)Buffs\nEntrantes",
	SI_COMBAT_METRICS_DEBUFF_OUT = "(De-)Buffs\nSalientes",
	SI_COMBAT_METRICS_MAGICKA_PM = "Magia\n +/-",
	SI_COMBAT_METRICS_STAMINA_PM = "Aguante\n +/-",
	SI_COMBAT_METRICS_RESOURCES_PM = "Recursos\n +/-",

	SI_COMBAT_METRICS_BUFF = "Buff",
	SI_COMBAT_METRICS_BUFFS = "Buffs",
	SI_COMBAT_METRICS_DEBUFFS = "Debuffs",
	SI_COMBAT_METRICS_SHARP = "#",
	SI_COMBAT_METRICS_BUFFCOUNT_TT = "Jugador / General",
	SI_COMBAT_METRICS_UPTIME = "Tiempo Activo %",
	SI_COMBAT_METRICS_UPTIME_TT = "Jugador % / General %",

	SI_COMBAT_METRICS_REGENERATION = "Regeneración",
	SI_COMBAT_METRICS_CONSUMPTION = "Consumo",
	SI_COMBAT_METRICS_PM_SEC = "±/s",
	SI_COMBAT_METRICS_TARGET = "Objetivo",
	SI_COMBAT_METRICS_PERCENT = "%",
	SI_COMBAT_METRICS_UNITDPS_TT = "DPS real, por ejemplo, el daño por segundo entre tu primer y último golpe a ese objetivo",

	SI_COMBAT_METRICS_ABILITY = "Habilidad",
	SI_COMBAT_METRICS_PER_HITS = "/Golpes",
	SI_COMBAT_METRICS_CRITS_PER = "Crítico %",

	SI_COMBAT_METRICS_FAVOURITE_ADD = "Añadir a Favoritos",
	SI_COMBAT_METRICS_FAVOURITE_REMOVE = "Eliminar de Favoritos",

	SI_COMBAT_METRICS_UNCOLLAPSE = "Mostrar Detalles",
	SI_COMBAT_METRICS_COLLAPSE = "Colapsar",

	SI_COMBAT_METRICS_SKILL = "Habilidad",

	SI_COMBAT_METRICS_BAR = "Barra ",
	SI_COMBAT_METRICS_AVERAGEC = "Promedio: ",

	SI_COMBAT_METRICS_SKILLTIME_LABEL2 = "weaving", -- tiempo de weaving
	SI_COMBAT_METRICS_SKILLTIME_LABEL3 = "fallo", -- errores

	SI_COMBAT_METRICS_SKILLTIME_TT1 = "Número de lanzamientos de esta habilidad",
	SI_COMBAT_METRICS_SKILLTIME_TT2 = "Tiempo de weaving\n\nTiempo promedio perdido hasta que se lanza la siguiente habilidad.",
	SI_COMBAT_METRICS_SKILLTIME_TT3 = "Errores de weaving\n\nNúmero de veces que el lanzamiento de la habilidad no es seguida por un ataque de arma o viceversa",
	SI_COMBAT_METRICS_SKILLTIME_TT4 = "Tiempo promedio entre activaciones posteriores de esta habilidad",

	SI_COMBAT_METRICS_SKILLTIME_WEAVING = "Weaving Promedio: ",

	SI_COMBAT_METRICS_SKILLAVG_TT = "Tiempo promedio perdido entre dos lanzamientos de habilidades",
	SI_COMBAT_METRICS_SKILLTOTAL_TT = "Tiempo total perdido entre lanzamientos de habilidades",

	SI_COMBAT_METRICS_TOTALWA = "Ataques de Arma: ",
	SI_COMBAT_METRICS_TOTALWA_TT = "Total de ataques ligeros y pesados",
	SI_COMBAT_METRICS_TOTALSKILLS = "Habilidades: ",
	SI_COMBAT_METRICS_TOTALSKILLS_TT = "Total de habilidades lanzadas",

	SI_COMBAT_METRICS_SAVED_DATA = "Datos guardados",

-- Live report window

	SI_COMBAT_METRICS_SHOW_XPS = "<<1>> / <<2>> (<<3>>%)", -- Formato para mostrar DPS/HPS. <<1>> = valor propio, <<2>> = valor del grupo, <<3>> = porcentaje

-- Settings Menu

	SI_COMBAT_METRICS_MENU_PROFILES = "Perfiles",

	SI_COMBAT_METRICS_MENU_AC_NAME = "Usar configuración de cuenta",
	SI_COMBAT_METRICS_MENU_AC_TOOLTIP = "Si está habilitado, todos los personajes de una cuenta compartirán su configuración",

	SI_COMBAT_METRICS_MENU_GS_NAME = "Configuración general",

	SI_COMBAT_METRICS_MENU_FH_NAME = "Historial de peleas",
	SI_COMBAT_METRICS_MENU_FH_TOOLTIP = "Número de peleas recientes para guardar",

	SI_COMBAT_METRICS_MENU_MAXSAVEDFIGHTS_NAME = "Peleas guardadas",
	SI_COMBAT_METRICS_MENU_MAXSAVEDFIGHTS_TOOLTIP = "Número máximo de peleas que se pueden guardar",
	SI_COMBAT_METRICS_MENU_MAXSAVEDFIGHTS_WARNING = "Guardar demasiadas peleas puede aumentar los tiempos de carga.",

	SI_COMBAT_METRICS_MENU_BOSSFIGHTS_NAME = "Mantener peleas de jefe",
	SI_COMBAT_METRICS_MENU_BOSSFIGHTS_TOOLTIP = "Elimina peleas de basura primero antes de eliminar peleas de jefe cuando se alcance el límite de peleas",

	SI_COMBAT_METRICS_MENU_MG_NAME = "Monitorear daño del grupo",
	SI_COMBAT_METRICS_MENU_MG_TOOLTIP = "Monitorea los eventos de todo el grupo",

	SI_COMBAT_METRICS_MENU_STACKS_NAME = "Mostrar acumulaciones de buffs",
	SI_COMBAT_METRICS_MENU_STACKS_TOOLTIP = "Mostrar acumulaciones individuales en el panel de buffs",

	SI_COMBAT_METRICS_MENU_GL_NAME = "Monitorear daño en grupos grandes",
	SI_COMBAT_METRICS_MENU_GL_TOOLTIP = "Monitorea el daño del grupo en grupos grandes (más de 4 miembros del grupo)",

	SI_COMBAT_METRICS_MENU_LM_NAME = "Modo ligero",
	SI_COMBAT_METRICS_MENU_LM_TOOLTIP = "Cuando está en modo ligero, Combat Metrics solo calculará el DPS/HPS en la ventana de informe en vivo. No se calcularán estadísticas y la ventana de informe de peleas estará deshabilitada",

	SI_COMBAT_METRICS_MENU_NOPVP_NAME = "Desactivar en PvP",
	SI_COMBAT_METRICS_MENU_NOPVP_TOOLTIP = "Desactiva todo el registro de peleas en Cyrodiil y Campos de Batalla",

	SI_COMBAT_METRICS_MENU_LMPVP_NAME = "Modo ligero en PvP",
	SI_COMBAT_METRICS_MENU_LMPVP_TOOLTIP = "Cambia al modo ligero en Cyrodiil y Campos de Batalla. Cuando está en modo ligero, Combat Metrics solo calculará el DPS/HPS en la ventana de informe en vivo. No se calcularán estadísticas y la ventana de informe de peleas estará deshabilitada",

	SI_COMBAT_METRICS_MENU_ASCC_NAME = "Selección automática de canal",
	SI_COMBAT_METRICS_MENU_ASCC_TOOLTIP = "Selecciona automáticamente el canal al publicar DPS/HPS en el chat. Cuando estás en grupo, se usa el chat /group, de lo contrario, se usa el chat /say.",
	SI_COMBAT_METRICS_MENU_AS_NAME = "Captura de pantalla automática",
	SI_COMBAT_METRICS_MENU_AS_TOOLTIP = "Toma automáticamente una captura de pantalla al abrir la ventana de informe de peleas",
	SI_COMBAT_METRICS_MENU_ML_NAME = "Duración mínima de la pelea para captura de pantalla",
	SI_COMBAT_METRICS_MENU_ML_TOOLTIP = "Duración mínima de la pelea en s para la captura de pantalla automática",
	SI_COMBAT_METRICS_MENU_SF_NAME = "Escala de la ventana de informe de peleas",
	SI_COMBAT_METRICS_MENU_SF_TOOLTIP = "Ajusta el tamaño de todos los elementos de la ventana de informe de peleas",

	SI_COMBAT_METRICS_MENU_DISPLAYNAMES_NAME = "Mostrar nombres de cuenta",
	SI_COMBAT_METRICS_MENU_DISPLAYNAMES_TOOLTIP = "Muestra nombres de cuenta (@Nombre) en lugar de nombres de personajes para los miembros del grupo",

	SI_COMBAT_METRICS_MENU_SHOWPETS_NAME = "Mostrar mascotas",
	SI_COMBAT_METRICS_MENU_HIDEPETS = "Ocultar mascotas",
	SI_COMBAT_METRICS_MENU_SHOWPETS_TOOLTIP = "Muestra mascotas en la ventana de informe de peleas",

	SI_COMBAT_METRICS_MENU_NOTIFICATIONS = "Permitir notificaciones",
	SI_COMBAT_METRICS_MENU_NOTIFICATIONS_TOOLTIP = "De vez en cuando, puedo agregar una notificación a la ventana de informe, por ejemplo, para recopilar datos o para reclutar personas para mi raid (para ahorrar tiempo que preferiría usar en addons). Desactiva esto si no lo deseas.",

	SI_COMBAT_METRICS_MENU_RESPEN_NAME = "Resistencia y penetración",
	SI_COMBAT_METRICS_MENU_CRUSHER = "Aplastamiento",
	SI_COMBAT_METRICS_MENU_CRUSHER_TOOLTIP = "Reducción de resistencia del debuff del glifo Aplastamiento. \nPara glifo dorado CP160: \nestándar: 1622 \nimbuido: 2108 \nimbuido + Torug's: 2740",
	SI_COMBAT_METRICS_MENU_ALKOSH = "Alkosh",
	SI_COMBAT_METRICS_MENU_ALKOSH_TOOLTIP = "Reducción de resistencia del debuff Rugido de Alkosh. \nEstá dado por el mayor daño de arma o hechizo del lanzador, hasta un máximo de 6000.",
	SI_COMBAT_METRICS_MENU_TREMORSCALE = "Escama Trémula",
	SI_COMBAT_METRICS_MENU_TREMORSCALE_TOOLTIP = "Reducción de resistencia del debuff Escama Trémula. \nEstá dado por la mayor resistencia física o a hechizos del lanzador, multiplicada por 0.08.",
	SI_COMBAT_METRICS_MENU_MOBRESISTANCE = "Resistencia del objetivo",
	SI_COMBAT_METRICS_MENU_MOBRESISTANCE_TOOLTIP = "Resistencia del objetivo que se asume para el cálculo de sobrepenetración",

	SI_COMBAT_METRICS_MENU_LR_NAME = "Ventana de informe en vivo",
	SI_COMBAT_METRICS_MENU_ENABLE_NAME = "Habilitar",
	SI_COMBAT_METRICS_MENU_ENABLE_TOOLTIP = "Habilita la ventana de informe en vivo que muestra DPS y HPS durante el combate",

	SI_COMBAT_METRICS_MENU_LR_LOCK = "Bloquear",
	SI_COMBAT_METRICS_MENU_LR_LOCK_TOOLTIP = "Bloquea la ventana de informe en vivo para que no se pueda mover",

	SI_COMBAT_METRICS_MENU_LR_ALIGNMENT = "Usar números alineados a la izquierda",
	SI_COMBAT_METRICS_MENU_LR_ALIGNMENT_TOOLTIP = "Establece la posición de los números de Daño/Cura/etc. para la ventana de informe en vivo alineados a la izquierda",

	SI_COMBAT_METRICS_MENU_LAYOUT_NAME = "Diseño",
	SI_COMBAT_METRICS_MENU_LAYOUT_TOOLTIP = "Selecciona el diseño de la ventana de informe en vivo",
	SI_COMBAT_METRICS_MENU_SCALE_NAME = "Escala",
	SI_COMBAT_METRICS_MENU_SCALE_TOOLTIP = "Escala de la ventana de informe en vivo.",

	SI_COMBAT_METRICS_MENU_BGALPHA_NAME = "Opacidad del Fondo",
	SI_COMBAT_METRICS_MENU_BGALPHA_TOOLTIP = "Establece la opacidad del fondo",

	SI_COMBAT_METRICS_MENU_SHOW_DPS_NAME = "Mostrar DPS",
	SI_COMBAT_METRICS_MENU_SHOW_DPS_TOOLTIP = "Muestra el DPS que infliges en la ventana de informe en vivo",
	SI_COMBAT_METRICS_MENU_SHOW_SDPS_NAME = "Mostrar DPS de un solo objetivo",
	SI_COMBAT_METRICS_MENU_SHOW_SDPS_TOOLTIP = "Muestra el DPS de un solo objetivo que infliges en la ventana de informe en vivo",
	SI_COMBAT_METRICS_MENU_SHOW_HPS_NAME = "Mostrar HPS",
	SI_COMBAT_METRICS_MENU_SHOW_HPS_TOOLTIP = "Muestra el HPS que lanzas en la ventana de informe en vivo",
	SI_COMBAT_METRICS_MENU_SHOW_HPSA_NAME = "Mostrar HPS + sobrecuración",
	SI_COMBAT_METRICS_MENU_SHOW_HPSA_TOOLTIP = "Muestra el HPS incluyendo la sobrecuración que lanzas en la ventana de informe en vivo",
	SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_NAME = "Mostrar DPS Entrante",
	SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_TOOLTIP = "Muestra el DPS que recibes en la ventana de informe en vivo",
	SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_NAME = "Mostrar HPS Entrante",
	SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_TOOLTIP = "Muestra el HPS que recibes en la ventana de informe en vivo",
	SI_COMBAT_METRICS_MENU_SHOW_TIME_NAME = "Mostrar Tiempo",
	SI_COMBAT_METRICS_MENU_SHOW_TIME_TOOLTIP = "Muestra el tiempo que has estado infligiendo daño en la ventana de informe en vivo",

	SI_COMBAT_METRICS_MENU_CHAT_TITLE = "Transmitir Registro de Combate al chat",
	SI_COMBAT_METRICS_MENU_CHAT_WARNING = "¡Usar con precaución! Crear líneas de texto requiere mucho trabajo de la CPU. Es mejor desactivar esto si esperas peleas intensas (pruebas, Cyrodiil)",

	SI_COMBAT_METRICS_MENU_CHAT_DH_TOOLTIP = "Transmite eventos de Daño y Cura a la ventana de chat",
	SI_COMBAT_METRICS_MENU_CHAT_TITLE_NAME = "Título del Registro de Chat",
	SI_COMBAT_METRICS_MENU_CHAT_TITLE_TOOLTIP = "Muestra el daño que infliges en la transmisión de chat",
	SI_COMBAT_METRICS_MENU_CHAT_SD_NAME = "Mostrar daño",
	SI_COMBAT_METRICS_MENU_CHAT_SD_TOOLTIP = "Muestra el daño que infliges en la transmisión de chat",
	SI_COMBAT_METRICS_MENU_CHAT_SH_NAME = "Mostrar curas",
	SI_COMBAT_METRICS_MENU_CHAT_SH_TOOLTIP = "Muestra las curas que lanzas en la transmisión de chat",
	SI_COMBAT_METRICS_MENU_CHAT_SID_NAME = "Mostrar Daño Entrante",
	SI_COMBAT_METRICS_MENU_CHAT_SID_TOOLTIP = "Muestra el daño que recibes en la transmisión de chat",
	SI_COMBAT_METRICS_MENU_CHAT_SIH_NAME = "Mostrar Cura Entrante",
	SI_COMBAT_METRICS_MENU_CHAT_SIH_TOOLTIP = "Muestra las curas que recibes en la transmisión de chat",

-- Live Report Tooltips

	SI_COMBAT_METRICS_LIVEREPORT_GROUP_TOOLTIP = "Jugador / Grupo",
	SI_COMBAT_METRICS_LIVEREPORT_DPSSINGLE_TOOLTIP = "DPS de un solo objetivo",
	SI_COMBAT_METRICS_LIVEREPORT_DPSBOSS_TOOLTIP = "DPS de Jefe",
	SI_COMBAT_METRICS_LIVEREPORT_DPSMULTI_TOOLTIP = "DPS de múltiples objetivos",
	SI_COMBAT_METRICS_LIVEREPORT_HPSOUT_TOOLTIP = "HPS",
	SI_COMBAT_METRICS_LIVEREPORT_HPSRAW_TOOLTIP = "HPS Bruto (incl. sobrecuración)",
	SI_COMBAT_METRICS_LIVEREPORT_DPSINC_TOOLTIP = "DPS Entrante",
	SI_COMBAT_METRICS_LIVEREPORT_HPSINC_TOOLTIP = "HPS Entrante",
	SI_COMBAT_METRICS_LIVEREPORT_TIME_TOOLTIP = "Duración del combate",

-- make a label for keybinding

	SI_BINDING_NAME_CMX_REPORT_TOGGLE = "Alternar Informe de Pelea",
	SI_BINDING_NAME_CMX_LIVEREPORT_TOGGLE = "Alternar Informe en Vivo",
	SI_BINDING_NAME_CMX_POST_DPS_SMART = "Publicar DPS de Jefe o Total",
	SI_BINDING_NAME_CMX_POST_DPS_SINGLE = "Publicar DPS de un solo objetivo",
	SI_BINDING_NAME_CMX_POST_DPS_MULTI = "Publicar DPS de múltiples objetivos",
	SI_BINDING_NAME_CMX_POST_DPS = "Publicar DPS único y múltiple",
	SI_BINDING_NAME_CMX_POST_HPS = "Publicar Cura en el Chat",
	SI_BINDING_NAME_CMX_RESET_FIGHT = "Reiniciar la Pelea Manualmente",

}

-- Ingame (Use ZOS Tranlations, change only for languages which are not supported)

strings["SI_COMBAT_METRICS_HEALTH"] = GetString(SI_COMBATMECHANICFLAGS32)  -- Salud
strings["SI_COMBAT_METRICS_MAGICKA"] = GetString(SI_COMBATMECHANICFLAGS1)  -- Magia
strings["SI_COMBAT_METRICS_STAMINA"] = GetString(SI_COMBATMECHANICFLAGS4)  -- Aguante
strings["SI_COMBAT_METRICS_ULTIMATE"] = GetString(SI_COMBATMECHANICFLAGS8)  -- Ultimate

-- Localization End

for stringId, stringValue in pairs(strings) do
	ZO_CreateStringId(stringId, stringValue)
	SafeAddVersion(stringId, 1)
end