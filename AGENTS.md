# Feira Livre Simulator — development conventions

This repository is a standalone Godot 4 / GDScript game. Keep the playable loop working: menu → 180-second market session → results → restart.

## Conventions

- All player-facing text is Brazilian Portuguese; currency is integer Brazilian reais.
- No external assets, plugins, network services, or runtime dependencies.
- Procedural art lives in `MarketArt` and `MarketManager`; do not mix accounting into visual code.
- `FruitCatalog` owns fruit definitions. `InventoryManager` and `EconomyManager` own their respective state. `GameSessionManager` coordinates transactions, timing and results.
- Sales are only possible during a session, with positive quantities and sufficient stock. Restocking must be affordable before inventory is added. Invalid transactions leave state unchanged.
- Customer state transitions must prevent duplicate payments and duplicate missed counts.
- Closing counts all pending arriving/waiting customers as missed, then snapshots results. Initial cash and free starting stock are excluded from session profit.
- Use explicit types when a Dictionary or Variant would make `:=` ambiguous. Use tabs in GDScript.
- Keep CLI tests deterministic with seeded RNG and bounded execution. The actual game uses randomized customers.
- Do not commit `.godot/`, `.tools/`, generated logs or raw recordings. Curated public screenshots and GIFs belong in `docs/media/` and are intentionally committed. Keep `.gd.uid` files tracked.

## Commands

The wrapper finds the project-local Godot, `/Applications/Godot.app`, or `godot`/`godot4` in PATH. `GODOT_BIN` overrides discovery.

```sh
sh tools/godot.sh --editor
sh tools/godot.sh
python3 tools/test.py
sh tools/godot.sh --headless --editor --quit
sh tools/godot.sh --headless --script res://tests/test_game.gd
sh tools/godot.sh --headless --quit-after 600 -- --smoke
sh tools/godot.sh --script res://tests/test_game.gd -- --visual
```

## Required validation

After gameplay changes run the full `tools/test.py` suite: editor import, tests, bounded menu smoke, bounded active game smoke. Check logs for script errors even when the engine exits with status zero. Add behavior-focused tests for changes to transactions, customer state or session results.

For visual changes run graphical validation where available, inspect the generated menu/gameplay/restock/results screenshots in `artifacts/`, and launch the normal game. Never claim human-input or visual checks that were not performed. Godot writes its normal user/editor directories under the macOS Library; sandboxed environments may need execution approval.
