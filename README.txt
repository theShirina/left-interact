LEFT INTERACT 1.6.2
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
Shift + left click  Native selection, camera, and ground-spell placement
Shift + right click Original right-click action
Minimap left click  Open settings
Minimap right click Enable or disable the addon
Minimap drag        Reposition the button

SETTINGS
--------
Open the minimap panel or run /leftinteract gui.
Click WHAT'S NEW to switch to the scrollable changelog page. Use BACK TO
SETTINGS to return without opening another window.

W-compatible is the fresh-install default and keeps keyboard movement separate.
After releasing right click, re-press left click before steering again. Seamless
left hold preserves held-left steering, but W and right click can stop each other.

Inventory items temporarily remove the addon's unmodified left-click override.
This preserves native unit-frame equip prompts, dropping, and delete confirmation.
Optional empty-world deselection only runs outside combat and may be blocked by
some clients. Shift + left click remains the native fallback.

GROUND-TARGET SPELLS (ASCENSION)
--------------------------------
Left Interact cannot safely switch its protected left-click binding after a
targeting circle opens during combat. Use an @cursor macro for ground-targeted
abilities. @cursor casts at the ground beneath your pointer; @mouseover targets
a unit and does not mean a ground position.

Example:
#showtooltip Death and Decay
/cast [@cursor] Death and Decay

Place the macro on your action bar in place of the normal spell. The existing
action-bar key then casts directly at the pointer without a second click.
Shift + left click remains the native fallback for targeting circles.
In the addon settings, click SELECT TO COPY, press Ctrl+C, then paste the macro
into a WoW macro.

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
