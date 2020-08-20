# Combat Metrics

## Dependencies

This addon requires the following libraries:

* [LibAddonMenu](https://www.esoui.com/downloads/info7-LibAddonMenu.html)
* [LibCustomMenu](https://www.esoui.com/downloads/info1146-LibCustomMenu.html)
* [LibFeedback](https://www.esoui.com/downloads/info2079-LibFeedback.html)
* [LibCombat](https://www.esoui.com/downloads/info2528-LibCombat.html)

They are not included in the release and have to be downloaded manually.

Additionally a module is included handling the fights you save. It is called **CombatMetricsFightData** and is required to be enabled in the "AddOns" panel in the game.

## Description

**Please note that the addon is still in beta so don't expect everything to be perfect.**

Combat Metrics was created for two reasons. First to have a tool to analyse my fights in a useful and comfortable manner. The second was to provide more insightful and meaningful damage parses. To achieve this, Combat Metrics records your fight during combat and analyses it when you attempt to view the statistics. That way I hope to keep the impact on the fps as low as possible. For minimal performance impact there is a light mode that only uses a minimum of resources to show you the DPS and HPS of your current fight.

The main report window can be toggled by assigning a key to it or by typing `/cmx` into the chatbox. 
You can also assign keys to post the damage per second (DPS) or healing per second (HPS) of your most recent fight to the chat. Alternatively you can use `/cmx dps`, `/cmx sdps`, `/cmx mdps`, `/cmx alldps` for automatic, single-target, multi-target or single + multitarget DPS respectively. You can use `/cmx hps` to post you healing per second.

## Known Issues
* If you want to see Statistics in AvA areas, disable "Light Mode in Cyrodil"
* Minor Savagery is ignored since it is too spammy.

*Solinur (EU)*
