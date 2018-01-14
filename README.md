# CombatMetrics
Creates and analyzes combat logs in ESO

Pasted from EsoUI description:

Description

[COLOR=DarkOrange][B]Please note that the addon is still in beta so don't expect everything to be perfect.[/B][/COLOR]

I made Combat Metrics basically for two reasons. First to have a tool to analyse my fights in a useful and comfortable manner. The second was to provide more insightful and meaningful damage parses. 

Combat Metrics is an addon to track your fights. You can use it to measure your DPS, you can analyse which skills make your DPS or who caused your incoming damage. You can also analyse the heals you received or cast. You can check which buffs and debuffs were running, how much magicka or stamina per second you used and regenerated. You can Analyse the Combat log, filter it to analyse specific issues. 

Combat Metrics basically just records your fight during combat and analyses it when you attempt to view the statistics. That way I hope to keep the impact on the fps as low as possible. Since it saves the data of the whole fight, you might hit the lua memory limit especially when a lot of heavy fights are happening in a row (I suspect Cyrodil is a candidate). If you want to keep the impact on memory small you can select to only keep a few fights in storage. For minimal performance impact there is a light mode that only uses a minimum of resources to show you DPS and HPS of your current fight.

The main report window can be toggled by assigning a key to it or by typing [COLOR="Yellow"]/cmx[/COLOR] into the chatbox. 
You can also assign keys to post the damage per second (DPS) or healing per second (HPS) of your most recent fight to the chat. Alternatively you can use [COLOR="Yellow"]/cmx dps[/COLOR], [COLOR="Yellow"]/cmx sdps[/COLOR], [COLOR="Yellow"]/cmx mdps[/COLOR], [COLOR="Yellow"]/cmx alldps[/COLOR] for automatic, single-target, multi-target or single + multitarget DPS respectively. You can use [COLOR="Yellow"]/cmx hps[/COLOR] to post you healing per second.

 I want to thank Atropos for letting me use his functions to build the user interface. Coolmodi's addons were also quite insightful especially for handling the event registrations. I also learned from the addons of Circonian and Spellbuilder. Finally I want to mention @EgoRush and [URL="http://tamrielfoundry.com/topic/aedrics-warrior-magicka-build-templar-dd/"] all participants in his thread at Tamrielfoundry[/URL]. The discussions there lead to my motivation for creating this addon.

[FONT=Georgia][U][B][COLOR=Yellow]Known Issues[/COLOR][/B][/U][/FONT][LIST]
[*]Sometimes a buff event is missed (probably). The addon dismisses these cases which might lead to (slightly) reduced uptimes shown in the report.
[*]If you want to see Statistics in AvA areas, disable "Light Mode in Cyrodil"
[/LIST][COLOR=Yellow]Decay2 aka Solinur (Pact EU)[/COLOR]