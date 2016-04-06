This is a WIP and slowly at that, so things may be a bit confusing at the moment.

The goal is to make as many of these elements work both together and as standalone scripts like they used to be. Still some way to go on that, so at the moment it's mostly just designed to be used together.


TeammatePanels.lua modifies the functionality of the information displayed about you and your team. This will replace the vanilla HUD, so it may not place nice with other mods that try to alter the same things. It's fairly customizable in terms of what to show, not so much in terms of appearance of the elements however. Take a look at the HUDTeammateCustom.SETTINGS table for options.
To use, the script should be post-required/hooked to:
"lib/managers/hud/hudteammate"
"lib/managers/hudmanagerpd2"

HUDChat.lua modifies the chat box with some additonal features like scrolling and custom number and size of lines (check the HUDChat.X values in the script). This should be usable both with my scripts as well as a standalone script with other HUDs provided they don't alter the HUDChat code too much. Post-require/hook to:
"lib/managers/hud/hudchat"
"lib/managers/hudmanagerpd2"

CustomHUD.lua is a legacy script and is not particularly important, but contains some code that I use mostly to make the HUDList look better and haven't as of yet done something more sensible with. It contains code to make objectives a single line, moves the heist timer and assault banner, and hides the default hostage counter. Can be used as standalone as well.
Post-require/hook to one or more of the following (depending on what you want it to do):
"lib/managers/hud/hudassaultcorner"
"lib/managers/hud/hudobjectives"
"lib/managers/hud/hudheisttimer"

The plugin folder contains various scripts that I haven't found a better place for yet.
* CivAlerts makes pacified change color to green instead of orange. Standalone. ("lib/managers/group_ai_states/groupaistatebase")
* VisualSwanSong should make the screen gray and give you the hearbeat sounds when you enter swan song for a bit of audio/visual cue. Standalone. ("lib/units/beings/player/playerdamage")
* StaminaCircle adds a circle inside the health display that shows the current stamina. May not place nice with the new Maniac perk deck that occupies the same space. Standalone, don't use it with the TeammatePanels script (has native support anyway). ("lib/managers/hudmanagerpd2" and "lib/managers/hud/hudteammate")
* Plugin_Accuracy calculates the total and per-weapon accuracy of the player (not teammates). Intended to be standalone at some point, but currently only works for the TeammatePanels script (or any HUD that defines the interface functions and handles it correctly). Required if you want to see your accuracy in the HUD. ("lib/managers/statisticsmanager" and, if not used with the TeammatePanels, "lib/managers/hudmanagerpd2")
* Plugin_KillCounter is intended to process any kills for all units (but mainly the player and bot/human team), but is currently a bit buggy in terms of DoT kills and such. Same deal as the accuracy plugin with compatibility. Can be enabled, but will not show accurate numbers in all scenarios. ("lib/units/enemies/cop/copdamage", "lib/units/equipment/sentry_gun/sentrygunbase" and as standalone, "lib/managers/hudmanagerpd2")
