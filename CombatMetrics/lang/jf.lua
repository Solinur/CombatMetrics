
-- Functionality

SafeAddString(SI_COMBAT_METRICS_LANG, "zh", 1) 
SafeAddString(SI_COMBAT_METRICS_ENCHANTMENT_TRIM, " 附魔", 1) -- this will be removed from the items enchantment string to show the rest in the info panel, e.g. "Spell Damage Enchantment" is reduced to "Spell Damage".

-- Fonts

SafeAddString(SI_COMBAT_METRICS_STD_FONT, "EsoZH/fonts/Univers57.otf", 1) 
SafeAddString(SI_COMBAT_METRICS_BOLD_FONT, "EsoZH/fonts/Univers67.otf", 1) 

SafeAddString(SI_COMBAT_METRICS_FONT_SIZE_SMALL, "14", 1) 
SafeAddString(SI_COMBAT_METRICS_FONT_SIZE, "13", 1) 
SafeAddString(SI_COMBAT_METRICS_FONT_SIZE_TITLE, "20", 1) 

-- Main UI

SafeAddString(SI_COMBAT_METRICS_CALC, "计算中...", 1) 
SafeAddString(SI_COMBAT_METRICS_FINALISING, "结束中...", 1) 
SafeAddString(SI_COMBAT_METRICS_GROUP, "队伍", 1) 
SafeAddString(SI_COMBAT_METRICS_SELECTION, "选定", 1) 

SafeAddString(SI_COMBAT_METRICS_BASE_REG, "基本再生", 1) 
SafeAddString(SI_COMBAT_METRICS_DRAIN, "吸收", 1) 
SafeAddString(SI_COMBAT_METRICS_UNKNOWN, "不明", 1) 

SafeAddString(SI_COMBAT_METRICS_BLOCKS, "格挡", 1) 
SafeAddString(SI_COMBAT_METRICS_CRITS, "暴击", 1) 

SafeAddString(SI_COMBAT_METRICS_DAMAGE, "伤害", 1) 
SafeAddString(SI_COMBAT_METRICS_DAMAGEC, "伤害: ", 1) 
SafeAddString(SI_COMBAT_METRICS_HIT, "击", 1) 
SafeAddString(SI_COMBAT_METRICS_DPS, "DPS", 1) 
SafeAddString(SI_COMBAT_METRICS_INCOMING_DPS, "承受 DPS", 1) 

SafeAddString(SI_COMBAT_METRICS_HEALING, "治疗", 1) 
SafeAddString(SI_COMBAT_METRICS_HEALS, "恢复", 1) 
SafeAddString(SI_COMBAT_METRICS_HPS, "HPS", 1) 
SafeAddString(SI_COMBAT_METRICS_HPSA, "HPS + 治疗溢出", 1) 
SafeAddString(SI_COMBAT_METRICS_INCOMING_HPS, "承受 HPS", 1) 

SafeAddString(SI_COMBAT_METRICS_EDIT_TITLE, "双击以编辑战斗名", 1) 

SafeAddString(SI_COMBAT_METRICS_DAMAGE_CAUSED, "造成伤害", 1) 
SafeAddString(SI_COMBAT_METRICS_DAMAGE_RECEIVED, "受到伤害", 1) 
SafeAddString(SI_COMBAT_METRICS_HEALING_DONE, "造成治疗", 1) 
SafeAddString(SI_COMBAT_METRICS_HEALING_RECEIVED, "受到治疗", 1) 

SafeAddString(SI_COMBAT_METRICS_TOGGLE_FIGHTSTATS, "战斗统计", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_COMBAT_LOG, "战斗日志", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_GRAPH, "附魔", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_INFO, "信息", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_SETTINGS, "选项", 1) 

SafeAddString(SI_COMBAT_METRICS_NOTIFICATION, "Mein Raid |cffff00Beyond Infinity|r sucht einen MagDK/Necro für vCR+3 (Greifenherz).", 1) 
SafeAddString(SI_COMBAT_METRICS_NOTIFICATION_GUILD, "消息: |cffff00超过无限|r", 1) 
SafeAddString(SI_COMBAT_METRICS_NOTIFICATION_ACCEPT, "消息读取", 1) 
SafeAddString(SI_COMBAT_METRICS_NOTIFICATION_DISCARD, "关闭通知", 1) 

	-- Options Menu Strings

SafeAddString(SI_COMBAT_METRICS_SHOWIDS, "显示 ID", 1) -- (for units, buffs and abilities)
SafeAddString(SI_COMBAT_METRICS_HIDEIDS, "隐藏 ID", 1) -- (for units, buffs and abilities)

SafeAddString(SI_COMBAT_METRICS_SHOWOVERHEAL, "显示治疗溢出", 1)
SafeAddString(SI_COMBAT_METRICS_HIDEOVERHEAL, "隐藏治疗溢出", 1)

SafeAddString(SI_COMBAT_METRICS_POSTDPS, "贴出 DPS/HPS", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTSINGLEDPS, "贴出单目标 DPS", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTSMARTDPS, "贴出boss目标 DPS", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTMULTIDPS, "贴出总 DPS", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTALLDPS, "贴出单人和总计 DPS", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTHPS, "贴出 HPS", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTUNITDPS, "贴出 DPS 给此单位", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTUNITNAMEDPS, "贴出 DPS 给 '<<1>>' 单位", 1) -- <<1>> is unitname
SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONDPS, "贴出 DPS 给选定的单位", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONHPS, "贴出 HPS 给选定的单位", 1) 

	-- Format Strings for DPS posting

SafeAddString(SI_COMBAT_METRICS_BOSS_DPS, "Boss DPS", 1) 

SafeAddString(SI_COMBAT_METRICS_POSTDPS_FORMAT, "<<1>> - DPS: <<2>> (<<3>> 在 <<4>> 内)", 1) -- for single target DPS (<<1>> = fightname, <<2>> = DPS, <<3>> = damage, <<4>> =  ) e.g. Z'Maja - DPS: 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTSMARTDPS_FORMAT, "<<1>><<2>> - Boss DPS: <<3>> (<<4>> 在 <<5>> 内)", 1) -- (<<1>> = fightname, <<2>> = extraunits (can be ""), <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Valariel (+5) - Boss DPS: 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTMULTIDPS_FORMAT, "<<1>> (+<<2>>) - DPS: <<3>> (<<4>> 在 <<5>> 内)", 1) -- (<<1>> = fightname, <<2>> = extraunits, <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Some random Mob (+5) - DPS: 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTALLDPS_FORMAT_A, "<<1>> - 总 DPS (+<<2>>): <<3>> (<<4>> 在 <<5>> 内)", 1) -- multi target part (<<1>> = fightname, <<2>> = extraunits, <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Valariel - Total DPS (+5): 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTALLDPS_FORMAT_B, "<<1>>: <<2>> (<<3>> 在 <<4>> 内)", 1) --  single target part (<<1>> = Label, <<2>> = DPS, <<3>> = damage) e.g. Boss DPS (+2): 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONDPS_FORMAT, "<<1>><<2>> - 选定 DPS: <<3>> (<<4>> 在 <<5>> 内)", 1) -- (<<1>> = fightname, <<2>> = extraunits (can be ""), <<3>> = DPS, <<4>> = damage, <<5>> = time) e.g. Valariel (+5) - Boss DPS: 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTHPS_FORMAT, "<<1>> - HPS: <<2>> (<<3>> 在 <<4>> 内)", 1) -- (<<1>> = fightname, <<2>> = HPS, <<3>> = damage, <<4>> = time)  e.g. Z'Maja - HPS: 10000 (1000000 in 1:40.0)
SafeAddString(SI_COMBAT_METRICS_POSTSELECTIONHPS_FORMAT, "<<1>> - 选定 HPS (x<<2>>): <<3>> (<<4>> 在 <<5>> 内)", 1) -- (<<1>> = fightname, <<2>> = units, <<3>> = HPS, <<4>> = damage, <<5>> = time) e.g. Z'Maja - HPS (12): 10000 (1000000 in 1:40.0)

SafeAddString(SI_COMBAT_METRICS_POSTBUFF, "贴出buff持续时间", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTBUFF_BOSS, "贴出boss的buff持续时间", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTBUFF_GROUP, "贴出队伍成员的buff持续时间", 1) 
SafeAddString(SI_COMBAT_METRICS_POSTBUFF_FORMAT, "<<1>> - 持续时间: <<2>> (<<3>><<4[/ 于 $d/ 于 $d 持续时间]>>)", 1) -- (<<1>> = buff name, <<2>> = relative uptime, <<3>> = uptime, <<4>> = time) e.g. Major Intellect - Uptime: 93.2% (9:26 in 10:07)
SafeAddString(SI_COMBAT_METRICS_POSTBUFF_FORMAT_GROUP, "<<1>> - 持续时间: <<2>>/<<5>> (<<3>>/<<6>><<4[/ 于 $d/ 于 $d 持续时间]>>)", 1) -- (<<1>> = buff name, <<2>> = relative uptime, <<3>> = uptime, <<4>> = units, <<5>> = relative group uptime, <<6>> = group uptime) e.g. Minor Sorcery - Uptime: 55.4%/100.6% (5:36/10:11 in 10:07)

SafeAddString(SI_COMBAT_METRICS_SETTINGS, "插件设置", 1) 

	-- Graph

SafeAddString(SI_COMBAT_METRICS_TOGGLE_CURSOR, "切换以显示光标和值提示框", 1) 
SafeAddString(SI_COMBAT_METRICS_GRAPH_BUFF_GROUP_SELECTOR, "切换以显示队伍持续时间", 1) 

SafeAddString(SI_COMBAT_METRICS_RECALCULATE, "重新计算战斗", 1) 
SafeAddString(SI_COMBAT_METRICS_SMOOTHED, "已平滑", 1) 
SafeAddString(SI_COMBAT_METRICS_TOTAL, "总", 1) 
SafeAddString(SI_COMBAT_METRICS_ABSOLUTE, "绝对 %", 1) 
SafeAddString(SI_COMBAT_METRICS_SMOOTH_LABEL, "平滑: %d 秒", 1) 
SafeAddString(SI_COMBAT_METRICS_NONE, "无", 1) 
SafeAddString(SI_COMBAT_METRICS_BOSS_HP, "Boss生命", 1) 
SafeAddString(SI_COMBAT_METRICS_ENLARGE, "放大", 1) 
SafeAddString(SI_COMBAT_METRICS_SHRINK, "缩小", 1) 

	-- Feedback

SafeAddString(SI_COMBAT_METRICS_FEEDBACK, "反馈", 1) 

SafeAddString(SI_COMBAT_METRICS_FEEDBACK_SEND, "发送反馈", 1) 

SafeAddString(SI_COMBAT_METRICS_FEEDBACK_EUONLY_FORMAT, "<<1>> (仅欧服)", 1) 
SafeAddString(SI_COMBAT_METRICS_FEEDBACK_MAIL, "游戏内邮箱", 1) 
SafeAddString(SI_COMBAT_METRICS_FEEDBACK_MAIL_HEADER, "Feedback: Combat Metrics %s", 1) 

SafeAddString(SI_COMBAT_METRICS_FEEDBACK_ESOUI, "ESOUI页面", 1) 
SafeAddString(SI_COMBAT_METRICS_FEEDBACK_GITHUB, "GitHub知识库", 1) 
SafeAddString(SI_COMBAT_METRICS_FEEDBACK_DISCORD, "Discord", 1) 

SafeAddString(SI_COMBAT_METRICS_DONATE, "捐赠", 1) 
SafeAddString(SI_COMBAT_METRICS_DONATE_GOLD, "金币", 1) 
SafeAddString(SI_COMBAT_METRICS_DONATE_GOLD_HEADER, "Donation: Combat Metrics %s", 1) 
SafeAddString(SI_COMBAT_METRICS_DONATE_CROWNS, "皇冠", 1) 
SafeAddString(SI_COMBAT_METRICS_DONATE_CROWNS_TEXT, "如果你想从皇冠商城送礼，我很乐意收到一些皇冠宝箱或消耗品。\n如果你想送什么其他的东西，你也可以联系我。", 1) 
SafeAddString(SI_COMBAT_METRICS_DONATE_CROWNS_ACCOUNT, "我的账户:", 1) 
SafeAddString(SI_COMBAT_METRICS_DONATE_ESOUI, "捐赠页面", 1) 
	
SafeAddString(SI_COMBAT_METRICS_OK, "OK", 1) 
	
SafeAddString(SI_COMBAT_METRICS_STORAGE_FULL, "存储文件已满。此战斗储存需要 <<1>> MB 空间。删除一个战斗以释放一些空间，或者在设置中增加允许使用的容量空间!", 1) 

	-- Fight Control Button Tooltips

SafeAddString(SI_COMBAT_METRICS_PREVIOUS_FIGHT, "上一个战斗", 1) 
SafeAddString(SI_COMBAT_METRICS_NEXT_FIGHT, "下一个战斗", 1) 
SafeAddString(SI_COMBAT_METRICS_MOST_RECENT_FIGHT, "最近的战斗", 1) 
SafeAddString(SI_COMBAT_METRICS_LOAD_FIGHT, "载入战斗", 1) 
SafeAddString(SI_COMBAT_METRICS_SAVE_FIGHT, "点击: 储存战斗", 1) 
SafeAddString(SI_COMBAT_METRICS_SAVE_FIGHT2, "Shift+点击: 储存带有战斗日志的战斗", 1) 
SafeAddString(SI_COMBAT_METRICS_DELETE_COMBAT_LOG, "删除战斗日志", 1) 
SafeAddString(SI_COMBAT_METRICS_DELETE_FIGHT, "删除战斗", 1) 

	-- Fight List

SafeAddString(SI_COMBAT_METRICS_RECENT_FIGHT, "最近的战斗", 1) 
SafeAddString(SI_COMBAT_METRICS_DURATION, "持续时间", 1) 
SafeAddString(SI_COMBAT_METRICS_CHARACTER, "角色", 1) 
SafeAddString(SI_COMBAT_METRICS_ZONE, "区域", 1) 
SafeAddString(SI_COMBAT_METRICS_TIME, "时间", 1) 
SafeAddString(SI_COMBAT_METRICS_TIME2, "时间", 1) 
SafeAddString(SI_COMBAT_METRICS_TIMEC, "时间: ", 1) 

SafeAddString(SI_COMBAT_METRICS_SHOW, "显示", 1) 
SafeAddString(SI_COMBAT_METRICS_DELETE, "删除", 1) 

SafeAddString(SI_COMBAT_METRICS_SAVED_FIGHTS, "保存的战斗", 1) 

	-- More UI Strings

SafeAddString(SI_COMBAT_METRICS_ACTIVE_TIME, "有效时间: ", 1) 
SafeAddString(SI_COMBAT_METRICS_ZERO_SEC, "0 秒", 1) 
SafeAddString(SI_COMBAT_METRICS_IN_COMBAT, "战斗中: ", 1) 

SafeAddString(SI_COMBAT_METRICS_PLAYER, "玩家", 1) 

SafeAddString(SI_COMBAT_METRICS_TOTALC, " 总共: ", 1) 
SafeAddString(SI_COMBAT_METRICS_NORMAL, "普通: ", 1) 
SafeAddString(SI_COMBAT_METRICS_CRITICAL, "暴击: ", 1) 
SafeAddString(SI_COMBAT_METRICS_BLOCKED, "格挡: ", 1) 
SafeAddString(SI_COMBAT_METRICS_SHIELDED, "护盾: ", 1) 
SafeAddString(SI_COMBAT_METRICS_ABSOLUTEC, "绝对: ", 1) 
SafeAddString(SI_COMBAT_METRICS_OVERHEAL, "治疗溢出: ", 1) -- as in overheal

SafeAddString(SI_COMBAT_METRICS_HITS, "击", 1) 
SafeAddString(SI_COMBAT_METRICS_NORM, "普通", 1) -- Normal, short
SafeAddString(SI_COMBAT_METRICS_OH, "OH", 1) -- Normal, short

SafeAddString(SI_COMBAT_METRICS_RESOURCES, "资源", 1) 

SafeAddString(SI_COMBAT_METRICS_STATS, "统计", 1) 
SafeAddString(SI_COMBAT_METRICS_AVE, "平均", 1) -- Average, short
SafeAddString(SI_COMBAT_METRICS_AVE_N, "平均普通", 1) -- Average Normal, short
SafeAddString(SI_COMBAT_METRICS_AVE_C, "平均暴击", 1) -- Average Crit, short
SafeAddString(SI_COMBAT_METRICS_AVE_B, "平均格挡", 1)  -- Average Blocked, short
SafeAddString(SI_COMBAT_METRICS_AVERAGE, "平均", 1) 
SafeAddString(SI_COMBAT_METRICS_NORMAL_HITS, "普通攻击", 1) 
SafeAddString(SI_COMBAT_METRICS_MAX, "最大", 1) -- Maximum
SafeAddString(SI_COMBAT_METRICS_MIN, "最小", 1) -- Minimum
SafeAddString(SI_COMBAT_METRICS_EFFECTIVE, "有效", 1) -- Effective

SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA1, "最大魔法", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA2, "法术伤害", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA3, "法术暴击", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT3, "%.1f %%", 1) -- e.g. 12.3%
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA4, "暴击伤害", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA5, "法术穿透", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA6, "穿透溢出", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_MAGICKA_FORMAT6, "%.1f %%", 1) -- e.g. 12.3%

SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA1, "最大耐力", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA2, "武器伤害", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA3, "武器暴击", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA_FORMAT3, "%.1f %%", 1) -- e.g. 12.3%
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA4, "暴击伤害", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA5, "物理穿透", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA6, "穿透溢出", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_STAMINA_FORMAT6, "%.1f %%", 1) -- e.g. 12.3%

SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH1, "最大生命", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH2, "物理抗性", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH3, "法术抗性", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH4, "暴击抗性", 1) 
SafeAddString(SI_COMBAT_METRICS_STATS_HEALTH_FORMAT4, "%.1f %%", 1) -- e.g. 12.3%

SafeAddString(SI_COMBAT_METRICS_PERFORMANCE, "性能", 1)
SafeAddString(SI_COMBAT_METRICS_PERFORMANCE_FPSAVG, "平均FPS", 1)
SafeAddString(SI_COMBAT_METRICS_PERFORMANCE_FPSMIN, "最小FPS", 1)
SafeAddString(SI_COMBAT_METRICS_PERFORMANCE_FPSMAX, "最大FPS", 1)
SafeAddString(SI_COMBAT_METRICS_PERFORMANCE_FPSPING, "Ping", 1)
SafeAddString(SI_COMBAT_METRICS_PERFORMANCE_DESYNC, "技能失调", 1)

SafeAddString(SI_COMBAT_METRICS_PENETRATION_TT, "穿透 vs 伤害", 1) 
SafeAddString(SI_COMBAT_METRICS_BACKSTABBER_TT, "背刺者也包括，似乎所有的目标都在侧边", 1) 

SafeAddString(SI_COMBAT_METRICS_COMBAT_LOG, "战斗日志", 1) 

SafeAddString(SI_COMBAT_METRICS_GOTO_PREVIOUS, "前往上一页", 1) 
SafeAddString(SI_COMBAT_METRICS_PAGE, "跳转到第 <<1>> 页", 1) -- <<1>> = page number
SafeAddString(SI_COMBAT_METRICS_GOTO_NEXT, "前往下一页", 1) 

SafeAddString(SI_COMBAT_METRICS_TOGGLE_HEAL, "切换受到治疗事件", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_DAMAGE, "切换受到伤害时间", 1) 

SafeAddString(SI_COMBAT_METRICS_TOGGLE_YOUR_HEAL, "切换你的治疗事件", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_YOUR_DAMAGE, "切换你的伤害事件", 1) 

SafeAddString(SI_COMBAT_METRICS_TOGGLE_BUFFIN_EVENTS, "切换受到buff事件", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_BUFFOUT_EVENTS, "切换造成buff事件", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_GROUPBUFFIN_EVENTS, "切换受到队伍buff事件", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_GROUPBUFFOUT_EVENTS, "切换造成队伍buff事件", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_RESOURCE_EVENTS, "切换资源事件", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_STATS_CHANGE_EVENTS, "切换统计改变事件", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_MESSAGE_CHANGE_EVENTS, "切换信息事件 (例如武器切换)", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_SKILL_USE_EVENTS, "切换使用技能事件", 1) 
SafeAddString(SI_COMBAT_METRICS_TOGGLE_PERFORMANCE_EVENTS, "切出性能信息", 1) 

	-- \n = new line

SafeAddString(SI_COMBAT_METRICS_DEBUFF_IN, "(De-)Buff\n受到", 1) 
SafeAddString(SI_COMBAT_METRICS_DEBUFF_OUT, "(De-)Buff\n造成", 1) 
SafeAddString(SI_COMBAT_METRICS_MAGICKA_PM, "魔法\n +/-", 1) 
SafeAddString(SI_COMBAT_METRICS_STAMINA_PM, "耐力\n +/-", 1) 
SafeAddString(SI_COMBAT_METRICS_RESOURCES_PM, "资源\n +/-", 1) 

SafeAddString(SI_COMBAT_METRICS_BUFF, "Buff", 1) 
SafeAddString(SI_COMBAT_METRICS_BUFFS, "Buff", 1) 
SafeAddString(SI_COMBAT_METRICS_DEBUFFS, "Debuff", 1) 
SafeAddString(SI_COMBAT_METRICS_SHARP, "#", 1) 
SafeAddString(SI_COMBAT_METRICS_BUFFCOUNT_TT, "玩家 / 全体", 1) 
SafeAddString(SI_COMBAT_METRICS_UPTIME, "持续时间 %", 1) 
SafeAddString(SI_COMBAT_METRICS_UPTIME_TT, "玩家 % / 全体 %", 1) 

SafeAddString(SI_COMBAT_METRICS_REGENERATION, "再生", 1) 
SafeAddString(SI_COMBAT_METRICS_CONSUMPTION, "消耗", 1) 
SafeAddString(SI_COMBAT_METRICS_PM_SEC, "±/秒", 1) 
SafeAddString(SI_COMBAT_METRICS_TARGET, "目标", 1) 
SafeAddString(SI_COMBAT_METRICS_PERCENT, "%", 1) 
SafeAddString(SI_COMBAT_METRICS_UNITDPS_TT, "真实DPS, 例如对该目标造成的第一击和最后一击之间的每秒伤害值", 1) 

SafeAddString(SI_COMBAT_METRICS_ABILITY, "技能", 1) 
SafeAddString(SI_COMBAT_METRICS_PER_HITS, "/击", 1) 
SafeAddString(SI_COMBAT_METRICS_CRITS_PER, "暴击 %", 1) 

SafeAddString(SI_COMBAT_METRICS_FAVOURITE_ADD, "加入收藏", 1) 
SafeAddString(SI_COMBAT_METRICS_FAVOURITE_REMOVE, "从收藏删除", 1) 

SafeAddString(SI_COMBAT_METRICS_UNCOLLAPSE, "显示细节", 1) 
SafeAddString(SI_COMBAT_METRICS_COLLAPSE, "崩溃", 1) 

SafeAddString(SI_COMBAT_METRICS_SKILL, "法术", 1) 

SafeAddString(SI_COMBAT_METRICS_BAR, "条 ", 1) 
SafeAddString(SI_COMBAT_METRICS_AVERAGEC, "平均: ", 1) 

SafeAddString(SI_COMBAT_METRICS_SKILLTIME_LABEL2, "挥舞", 1) -- weaving time
SafeAddString(SI_COMBAT_METRICS_SKILLTIME_LABEL3, "闪避", 1) -- errors

SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT1, "此技能的施放数量", 1) 
SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT2, "挥舞时间\n\n从本次到下一次技能释放中间浪费的平均时间。", 1) 
SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT3, "挥舞错误\n\n技能激活后没有立即进行武器攻击的次数，反之亦然。", 1) 
SafeAddString(SI_COMBAT_METRICS_SKILLTIME_TT4, "此技能后续的激活之间的平均时间", 1) 

SafeAddString(SI_COMBAT_METRICS_SKILLTIME_WEAVING, "挥舞平均：", 1) 

SafeAddString(SI_COMBAT_METRICS_SKILLAVG_TT, "两次技能释放之间浪费的平均时间", 1) 
SafeAddString(SI_COMBAT_METRICS_SKILLTOTAL_TT, "两次技能释放之间浪费的总时间", 1) 

SafeAddString(SI_COMBAT_METRICS_TOTALWA, "武器攻击: ", 1) 
SafeAddString(SI_COMBAT_METRICS_TOTALWA_TT, "总轻重击", 1) 
SafeAddString(SI_COMBAT_METRICS_TOTALSKILLS, "技能: ", 1) 
SafeAddString(SI_COMBAT_METRICS_TOTALSKILLS_TT, "总技能施放", 1) 

SafeAddString(SI_COMBAT_METRICS_SAVED_DATA, "保存的数据", 1) 

-- Live report window

SafeAddString(SI_COMBAT_METRICS_SHOW_XPS, "<<1>> / <<2>> (<<3>>%)", 1) -- Format to show DPS/HPS. <<1>> = own value, <<2>> = group value, <<3>> = percentage

-- Settings Menu

SafeAddString(SI_COMBAT_METRICS_MENU_PROFILES, "配置", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_AC_NAME, "使用账户全局设置", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_AC_TOOLTIP, "如果开启，账号下的所有角色将使用相同设置", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_GS_NAME, "通用设置", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_FH_NAME, "战斗历史", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_FH_TOOLTIP, "可保存的最近战斗数量", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_NAME, "保存的战斗容量", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_TOOLTIP, "已保存战斗的最大内存容量，以MB记", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SVSIZE_WARNING, "使用注意! 大量的保存数据会大大增加读取时间。如果文件变得过大, 客户端可能会在试图读取数据时崩溃。", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_BOSSFIGHTS_NAME, "保留Boss战斗", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_BOSSFIGHTS_TOOLTIP, "当战斗总数限制达到时，先删除垃圾战斗数据，之后才删除boss战斗数据", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_MG_NAME, "监视组队伤害", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_MG_TOOLTIP, "监视全组的事件", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_STACKS_NAME, "显示buff堆叠", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_STACKS_TOOLTIP, "在buff面板中单独显示堆叠", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_GL_NAME, "在大团队中监视伤害", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_GL_TOOLTIP, "在大团队中监视队伍伤害 (超过四个队伍成员)", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LM_NAME, "轻量模式", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_LM_TOOLTIP, "在轻量模式中, 实时报告窗口中战斗度量将仅计算 DPS/HPS 。将不会计算统计数据并且战斗报告窗口将被禁用", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_NOPVP_NAME, "在PVP中关闭", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_NOPVP_TOOLTIP, "在悉罗帝尔地图和角斗场关闭所有战斗日志", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LMPVP_NAME, "在PVP中使用轻量模式", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_LMPVP_TOOLTIP, "在悉罗帝尔地图和角斗场切换为轻量模式。在轻量模式中, 实时报告窗口中战斗度量将仅计算 DPS/HPS 。将不会计算统计数据并且战斗报告窗口将被禁用", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_ASCC_NAME, "自动选择频道", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_ASCC_TOOLTIP, "在聊天窗口中贴出 DPS/HPS 时自动选择频道。在队伍中时使用 /group 聊天频道，否则使用 /say 聊天频道。", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_AS_NAME, "自动截屏", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_AS_TOOLTIP, "打开战斗报告窗口时自动截屏", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_ML_NAME, "截屏的最小战斗时长", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_ML_TOOLTIP, "进行自动截屏的最小战斗时长，单位为秒", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SF_NAME, "缩放战斗报告窗口", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SF_TOOLTIP, "调整战斗报告窗口中所有元素的尺寸", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_DISPLAYNAMES_NAME, "显示账户名", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_DISPLAYNAMES_TOOLTIP, "队员显示账户名 (@Name) 而不显示角色名", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_SHOWPETS_NAME, "显示宠物", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_HIDEPETS, "隐藏宠物", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_SHOWPETS_TOOLTIP, "在战斗报告窗口中显示宠物", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_NOTIFICATIONS, "允许通知", 1)
SafeAddString(SI_COMBAT_METRICS_MENU_NOTIFICATIONS_TOOLTIP, "有时，我可能会在报告窗口添加一个通知，例如收集数据或招募人员到我的队伍里(为了节省时间，我宁愿使用插件)。如果你不想要这个，就把它关掉。", 1)

SafeAddString(SI_COMBAT_METRICS_MENU_RESPEN_NAME, "抗性和穿透", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CRUSHER, "粉碎者", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CRUSHER_TOOLTIP, "由粉碎者附魔debuff造成的抗性降低。以最大等级金附魔: 标准: 1622, 魔甲强化: 2108, 魔甲强化 + 塔鲁格契约: 2740", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_MOBRESISTANCE, "目标抗性", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_MOBRESISTANCE_TOOLTIP, "为计算穿透溢出而假定的目标抗性", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LR_NAME, "实时报告窗口", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_ENABLE_NAME, "开启", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_ENABLE_TOOLTIP, "开启实时报告窗口以在战斗中显示 DPS & HPS", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LR_LOCK, "锁定", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_LR_LOCK_TOOLTIP, "锁定实时报告窗口, 使其不能被移动", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LR_ALIGNMENT, "使用左对齐数字", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_LR_ALIGNMENT_TOOLTIP, "将实时报告窗口中的 伤害/治疗/其他 数字位置设置为左对齐", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_LAYOUT_NAME, "布局", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_LAYOUT_TOOLTIP, "为实时报告窗口选择布局", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SCALE_NAME, "缩放比例", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SCALE_TOOLTIP, "实时报告窗口的缩放比例", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_BGALPHA_NAME, "背景不透明度", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_BGALPHA_TOOLTIP, "为背景设置不透明度", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_DPS_NAME, "显示 DPS", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_DPS_TOOLTIP, "在实时报告窗口显示你造成的 DPS", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_SDPS_NAME, "显示单目标 DPS", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_SDPS_TOOLTIP, "在实时报告窗口显示你造成的单目标 DPS", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_HPS_NAME, "显示 HPS", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_HPS_TOOLTIP, "在实时报告窗口显示你施放的 HPS", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_HPSA_NAME, "在实时报告窗口显示你施放的 HPS", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_HPSA_TOOLTIP, "在实时报告窗口显示你施放的 HPS 包括治疗溢出", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_NAME, "显示承受 DPS", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_DPS_TOOLTIP, "在实时报告窗口显示你受到的 DPS", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_NAME, "显示承受 HPS", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_INC_HPS_TOOLTIP, "在实时报告窗口显示你受到的 HPS", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_TIME_NAME, "显示时间", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_SHOW_TIME_TOOLTIP, "在实时报告窗口显示你造成伤害的时间", 1) 

SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE, "聊天窗口战斗日志流", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_WARNING, "使用请注意! 创建文本杭需要占用大量CPU。当你需要大量的战斗时最好禁用此选项 (试炼, 悉罗帝尔)", 1) 
	
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_DH_TOOLTIP, "在聊天窗口显示伤害和治疗事件流", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE_NAME, "聊天日志标题", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_TITLE_TOOLTIP, "聊天日志标题", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SD_NAME, "显示伤害", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SD_TOOLTIP, "在聊天流中显示你造成的伤害", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SH_NAME, "显示治疗", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SH_TOOLTIP, "在聊天流中显示你施放的治疗", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SID_NAME, "显示承受伤害", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SID_TOOLTIP, "在聊天流中显示你受到的伤害", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SIH_NAME, "显示承受治疗", 1) 
SafeAddString(SI_COMBAT_METRICS_MENU_CHAT_SIH_TOOLTIP, "在聊天流中显示你受到的治疗", 1) 

-- make a label for keybinding

SafeAddString(SI_BINDING_NAME_CMX_REPORT_TOGGLE, "切出战斗报告", 1) 
SafeAddString(SI_BINDING_NAME_CMX_LIVEREPORT_TOGGLE, "切出实时报告", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_SMART, "贴出Boss或总 DPS", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_SINGLE, "贴出单目标 DPS", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS_MULTI, "贴出多目标 DPS", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_DPS, "贴出单+多目标 DPS", 1) 
SafeAddString(SI_BINDING_NAME_CMX_POST_HPS, "贴出治疗到聊天窗", 1) 
SafeAddString(SI_BINDING_NAME_CMX_RESET_FIGHT, "手动重置战斗", 1) 

