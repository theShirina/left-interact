# Left Interact

[![Validation](https://github.com/theShirina/left-interact/actions/workflows/validate.yml/badge.svg)](https://github.com/theShirina/left-interact/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A lightweight accessibility addon for World of Warcraft 3.3.5a clients. It moves the native world-interaction action to left click and adds optional right-click movement without rewriting saved keybindings.

Left Interact has no dependencies, telemetry, network requests, or bundled libraries.

## Features

- Left-click interaction with NPCs, loot, gathering nodes, and quest objects.
- Two native right-click movement modes:
  - **Seamless left hold** keeps steering active after right click is released.
  - **W-compatible** keeps keyboard movement separate from mouse movement.
- Native left-click fallback with **Shift + left click**.
- Original right-click fallback with **Shift + right click**.
- Native inventory-item dragging and delete confirmation.
- Optional short empty-world click deselection outside combat.
- Draggable minimap button and a dependency-free settings panel.
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
| Shift + left click | Native selection and camera action |
| Shift + right click | Original right-click action while **Right-click movement** is enabled |
| Minimap button, left click | Open settings |
| Minimap button, right click | Enable or disable the addon |
| Minimap button, drag | Move the button around the minimap |

## Settings

Open the settings panel from the minimap button or run:

```text
/leftinteract gui
```

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

**Seamless left hold** uses the client's `MOVEFORWARD` action for right click. It keeps a held left-click steering action active when right click is released. Old 3.3.5 clients do not reference-count duplicate forward inputs, so pressing W while right click is held can interrupt movement.

**W-compatible** uses `MOVEANDSTEER`. W remains independent, but releasing right click can reset an already-held left-click steering action.

This is a client limitation; the addon exposes both native choices rather than hiding the tradeoff.

## Known limitations

- Empty-world deselection is experimental and only runs outside combat. `ClearTarget` is protected, and some client forks can reject it. Shift + left click remains the safe native fallback.
- A world object has no `mouseover` unit token. Empty-world deselection can also clear an existing target when interacting with a game object.
- Full world interaction and native deselection cannot share one protected binding in a normal 3.3.5 addon.
- No movement mode can provide both W compatibility and seamless held-left state on every client fork.

## Building and validation

Requirements:

- Python 3.11+
- [`luaparser`](https://pypi.org/project/luaparser/)

```bash
python -m pip install --require-hashes -r requirements-dev.txt
python scripts/validate.py
python scripts/build_release.py
```

The release ZIP is written to `dist/` with a SHA-256 checksum.

## Contributing

Bug reports and focused pull requests are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting changes.

## License

[MIT](LICENSE) © 2026 Stefán / [theShirina](https://github.com/theShirina)
