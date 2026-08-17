# Left Interact change log


## [1.6.2] - 2026-08-04

### Changed

- Make W-compatible movement the fresh-install default.
- Preserve existing users' selected movement mode during upgrades.
- Clarify the unavoidable legacy-client tradeoff in the GUI and documentation.
- Document Shift + left click for ground-spell placement in combat.
- Document an `@cursor` macro option for one-key ground placement.
- Add a distinct settings-panel notice with an example `@cursor` macro.
- Add a one-click macro selector for copying with Ctrl+C.
- Add an in-game What's New changelog page with back navigation.
- Keep the macro-copy help text inside the settings panel.
- Keep the displayed version correct when the legacy client caches addon metadata.
- Restore native unit-frame equip prompts while dragging an inventory item.

## [1.6.1] - 2026-08-04

### Fixed

- Show the last applied bindings separately from settings queued during combat.
- Label slash-command setting changes as queued until combat ends.
- Cancel a pending enable cleanly when the addon is already inactive.

## [1.6.0] - 2026-08-04

### Added

- Polished dependency-free settings panel with clearer sections, selected states, and mode descriptions.
- Dynamic GUI version read from the addon metadata.
- Public documentation, validation scripts, reproducible packaging, and CI.

### Changed

- Restored Seamless left hold as the default movement mode.
- Improved minimap-button help and settings layout.

### Removed

- Failed experimental W Priority mode.

## [1.5.0] - 2026-08-04

### Added

- Optional short empty-world click deselection outside combat.
- GUI control for experimental deselection.

## [1.3.0] - 2026-08-04

### Added

- Draggable minimap button.
- In-game settings panel.
- Selectable movement and interaction modes.

## [1.2.0] - 2026-08-04

### Added

- Native inventory-item dragging and delete confirmation support.
- Selectable Independent and Combined movement modes.

## [1.0.0] - 2026-08-04

### Added

- Initial left-click world interaction addon for WotLK 3.3.5a.
