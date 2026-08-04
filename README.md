# Left Interact

[![Validation](https://github.com/theShirina/left-interact/actions/workflows/validate.yml/badge.svg)](https://github.com/theShirina/left-interact/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A lightweight accessibility addon for World of Warcraft 3.3.5a clients. It moves the native world-interaction action to left click and adds optional right-click movement without rewriting saved keybindings.

Left Interact has no dependencies, telemetry, network requests, or bundled libraries.

## Features

- Left-click interaction with NPCs, loot, gathering nodes, and quest objects.
- Two native right-click movement modes:
  - **W-compatible** is the fresh-install default and keeps keyboard movement separate from mouse movement.
  - **Seamless left hold** keeps steering active after right click is released.
- Native selection, camera, and ground-spell placement with **Shift + left click**.
- Original right-click fallback with **Shift + right click**.
- Native inventory-item dragging, unit-frame equip prompts, and delete confirmation.
- Optional short empty-world click deselection outside combat.
- Draggable minimap button and a dependency-free settings panel.
- Scrollable in-game changelog page available from **WHAT'S NEW** in settings.
- Combat-safe binding changes that defer until combat ends.

## Compatibility

- Interface: `30300`
- Lua: 5.1
- Designed for WotLK 3.3.5a-derived clients that expose the standard binding API.
- Tested against local Project Ebonhold and Project Ascension client files.

Client forks can change protected input behavior. See [Known limitations](#known-limitations).

## Installation

1. Download the ZIP from [Releases](https://github.com/theShirina/left-interact/releases).
2. Extract it into your client's `Interface/AddOns` folder.
3. Confirm this path exists:

   ```text
   <WoW folder>/Interface/AddOns/LeftInteract/LeftInteract.toc
   ```

4. Enable **Left Interact** at character selection.
5. Log in or run `/reload`.

## Controls

| Input | Action |
|---|---|
| Left click | Interact with the NPC or world object under the pointer |
| Hold left click | Steer while moving with right click |
| Hold right click | Move forward when **Right-click movement** is enabled |
| Shift + left click | Native selection, camera, and ground-spell placement |
| Shift + right click | Original right-click action while **Right-click movement** is enabled |
| Minimap button, left click | Open settings |
| Minimap button, right click | Enable or disable the addon |
| Minimap button, drag | Move the button around the minimap |

## Settings

Open the settings panel from the minimap button or run:

```text
/leftinteract gui
```

Click **WHAT'S NEW** to switch to the in-game release history. Use **BACK TO SETTINGS** to return without opening another window.

Other commands:

```text
/leftinteract on
/leftinteract off
/leftinteract toggle
/leftinteract status
/leftinteract rightmove on
/leftinteract rightmove off
/leftinteract movement independent
/leftinteract movement combined
/leftinteract mode action
/leftinteract mode mouseover
```

### Movement modes

**W-compatible** is the fresh-install default and uses `MOVEANDSTEER`. W remains independent. After releasing right click while left remains held, release and press left again before steering.

**Seamless left hold** uses the client's `MOVEFORWARD` action for right click. It keeps a held left-click steering action active when right click is released. Old 3.3.5 clients do not reference-count duplicate forward inputs, so W and right click can stop each other.

This is a client limitation; the addon exposes both native choices rather than hiding the tradeoff.

## Ground-target spells on Ascension

Left Interact uses unmodified left click for world interaction. WoW does not allow the addon to switch that protected binding after a targeting circle opens during combat.

For ground-targeted abilities on Ascension, use an `@cursor` macro. `@cursor` casts at the ground beneath your pointer; `@mouseover` targets a unit and does not mean a ground position.

Example:

```text
#showtooltip Death and Decay
/cast [@cursor] Death and Decay
```

Place the macro on your action bar in place of the normal spell. Its existing action-bar key then casts directly at the pointer without a second click. **Shift + left click** remains the native fallback for spells that still open a targeting circle.

The addon settings panel includes the same macro in a text field. Click **SELECT TO COPY**, press **Ctrl+C**, then paste it into a WoW macro.

## Known limitations

- Clients without Ascension-style `@cursor` support require **Shift + left click** to place a ground-target spell while Left Interact is enabled.
- Empty-world deselection is experimental and only runs outside combat. `ClearTarget` is protected, and some client forks can reject it. Shift + left click remains the safe native fallback.
- A world object has no `mouseover` unit token. Empty-world deselection can also clear an existing target when interacting with a game object.
- Full world interaction and native deselection cannot share one protected binding in a normal 3.3.5 addon.
- No movement mode can provide both W compatibility and seamless held-left state on every client fork.

## Building and validation

Requirements:

- Python 3.11+
- [`luaparser`](https://pypi.org/project/luaparser/)
- Lua 5.1

```bash
python -m pip install --require-hashes -r requirements-dev.txt
python scripts/validate.py
lua5.1 tests/test_defaults.lua new
lua5.1 tests/test_defaults.lua existing-independent
lua5.1 tests/test_defaults.lua existing-independent-without-enabled
lua5.1 tests/test_defaults.lua existing-combined
lua5.1 tests/test_defaults.lua item-native-dispatch
lua5.1 tests/test_defaults.lua changelog-page
python scripts/build_release.py
```

The release ZIP is written to `dist/` with a SHA-256 checksum.

## Contributing

Bug reports and focused pull requests are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting changes.

## License

[MIT](LICENSE) © 2026 Stefán / [theShirina](https://github.com/theShirina)
