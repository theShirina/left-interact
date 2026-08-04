LEFT INTERACT 1.6.0
===================

A lightweight accessibility addon for WotLK 3.3.5a clients.

INSTALLATION
------------
Extract the release so this file exists:
<WoW folder>\Interface\AddOns\LeftInteract\LeftInteract.toc

Enable Left Interact at character selection, then log in or run /reload.

CONTROLS
--------
Left click          Interact with NPCs and world objects
Hold left click     Steer while moving with right click
Hold right click    Move forward
Shift + left click  Native selection/camera action
Shift + right click Original right-click action
Minimap left click  Open settings
Minimap right click Enable or disable the addon
Minimap drag        Reposition the button

SETTINGS
--------
Open the minimap panel or run /leftinteract gui.

Seamless left hold keeps steering active after right click is released, but W
shares the old client's forward state. W-compatible keeps keyboard movement
separate, but releasing right click can reset held-left steering.

Inventory items automatically restore native left click for dropping and delete
confirmation. Optional empty-world deselection only runs outside combat and may
be blocked by some clients. Shift + left click remains the native fallback.

COMMANDS
--------
/leftinteract gui
/leftinteract on
/leftinteract off
/leftinteract toggle
/leftinteract status
/leftinteract rightmove on|off
/leftinteract movement independent|combined
/leftinteract mode action|mouseover

SOURCE AND LICENSE
------------------
https://github.com/theShirina/left-interact
MIT License
