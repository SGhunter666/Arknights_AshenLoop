# Project Architecture

This project is split into a few stable layers. Keep new work inside the smallest layer that owns the change, so future card, enemy, UI, and balance updates stay easy to review.

## Data Resources

- `data/cards`: card definitions and card effects.
- `data/enemies`: enemy stats, tags, portraits, and move profiles.
- `data/modules`: tactical modules.
- `data/charms`: charm definitions.
- `data/events`: event content and choice effects.

Prefer adding or tuning gameplay content here before changing code. If a card or enemy needs a new behavior that data cannot express, add the new effect or enemy move in the battle layer first, then reference it from data.

## Battle Layer

- `scripts/battle/BattleManager.gd`: owns battle flow, win/loss routing, and turn orchestration.
- `scripts/battle/EffectResolver.gd`: owns card and status effect execution.
- `scripts/battle/DeckController.gd`: owns draw, discard, exhaust, and shuffle behavior.
- `scripts/battle/EnemyAI.gd`: owns enemy intent selection.
- `scripts/battle/UnitState.gd`: owns runtime stats and statuses for player/enemies.
- `scripts/battle/ChannelManager.gd`: reserved for delayed channel effects.

Avoid putting UI layout in this layer. If code needs to show something to the player, emit state and let the UI layer render it.

## UI Layer

- `scripts/ui/battle_scene_v2.gd`: coordinates the battle scene and binds BattleManager state to views.
- `scripts/ui/combat_actor_view.gd`: renders one player/enemy actor card, health, block, statuses, and intent.
- `scripts/ui/battle_abandon_overlay.gd`: owns the abandon-run battle overlay and confirmation dialog.
- `scripts/ui/enemy_visual_resolver.gd`: owns enemy portrait, emblem, tint, and accent lookup.
- `scripts/ui/map_scene_v2.gd`: renders the map and node selection.
- `scripts/ui/encyclopedia_scene.gd`: renders encyclopedia pages.

When a UI feature becomes self-contained, prefer extracting it into a small view script instead of growing `battle_scene_v2.gd`.

## Run And Global Systems

- `scripts/autoload/RunManager.gd`: owns current run state.
- `scripts/autoload/SaveManager.gd`: owns profile and run save persistence.
- `scripts/autoload/SceneRouter.gd`: owns scene transitions.
- `scripts/autoload/SettingsManager.gd`: owns settings and persistence.
- `scripts/autoload/MusicManager.gd`: owns global BGM transitions.
- `scripts/autoload/LocalizationManager.gd`: owns text lookup.

Long term, localization text should move out of code into data files, because it is one of the largest remaining maintenance hotspots.

## Progression Systems

- `scripts/rewards`: card/module/charm reward generation.
- `scripts/events`: event choice execution.
- `scripts/shop`: shop inventory and services.
- `scripts/rest`: rest site services.
- `scripts/map`: map generation and node models.

These folders define the run structure around combat. Keep shop/rest/event behavior here instead of embedding it in scene scripts.

## Assets

- `assets/backgrounds`: scene backgrounds.
- `assets/card_art`: card images.
- `assets/enemy_portraits`: enemy portraits. File names should match enemy ids when possible.
- `assets/ui_icons`: reusable UI icons.

Do not rely on files in Desktop or Downloads during runtime. Copy assets into the project and let Godot import them.

## Tests

- `scripts/tools`: headless smoke test scripts.
- `scenes/*SmokeTest.tscn`: test scenes that can run with `./godot --headless --path . --log-file /tmp/test.log`.

Run relevant smoke tests after refactors. For battle UI changes, run at least `UISceneSmokeTest`, `RunFlowSmokeTest`, and the targeted test scene if one exists.
