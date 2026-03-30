# Unit Tests

## Framework

Tests are written for [GUT](https://github.com/bitwes/Gut) (Godot Unit Testing).

## Setup

1. Install GUT via the Godot Asset Library or clone it into `addons/gut/`
2. Enable the GUT plugin in Project Settings → Plugins
3. Configure the test runner to scan `tests/unit/`

## Running Tests

**From the editor**: GUT panel → Run All

**Headless CLI** (CI-friendly):
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit/ -gexit
```

## Test Files

| File | System Under Test | Scene Required |
|------|------------------|----------------|
| `test_grid_coord.gd` | `GridCoord` static functions | No |
| `test_grid_motor.gd` | `GridMotor` registration, occupancy, move count | No (uses mock) |
| `test_rolling_box_orientation.gd` | `RollingBox` face prediction | Yes (instantiates scene) |
