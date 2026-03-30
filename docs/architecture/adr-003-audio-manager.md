# ADR-003: Centralized AudioManager Autoload

- **Status**: Accepted
- **Date**: 2026-03-23
- **Deciders**: Technical Director, Audio Director

## Context

The game has 26 SFX events and a 3-stem adaptive music system. Audio needs to be globally accessible (any gameplay script can trigger sound), survive scene transitions, and continue playing during pause. Multiple simultaneous sounds (box rolls, steps, button presses) require pooled players to avoid cut-offs.

## Decision

Implement `AudioManager` as a single autoload singleton with:

- **Pre-allocated player pools**: 6 box-roll, 2 step, 4 UI, 2 door, 6 stem-C players created in `_ready()`. No runtime allocation.
- **Round-robin variant selection**: Box rolls and steps cycle through 3 variants per sound to avoid repetition.
- **Face-type audio routing**: Each box face type maps to specific pitch, volume, and reverb parameters for distinct sonic identity.
- **Music ducking with race-condition guard**: `_is_ducked` flag prevents saving an already-ducked volume as the restore target.
- **`process_mode = ALWAYS`**: Audio continues during pause state.
- **Enemy self-registration**: Each enemy connects its `defeated` signal to `AudioManager.play_enemy_defeat` in its own `_ready()`, avoiding a global `node_added` listener.

## Alternatives Considered

1. **Per-entity AudioStreamPlayer3D nodes**: Each object owns its audio player. Rejected — spatial audio is not needed for this top-down camera, and it fragments audio management.
2. **Multiple smaller audio managers** (SFXManager, MusicManager): Rejected — ducking requires cross-bus coordination; splitting managers adds complexity for no benefit at this scale.
3. **Signal-based playback** (entities emit signals, manager listens): Partially adopted for enemies. Rejected for general SFX because direct API calls (`AudioManager.play_door_open()`) are simpler and the coupling is acceptable for a game this size.

## Consequences

- **Positive**: Centralized mix control. Pre-allocated pools prevent frame spikes. Rate limiting on deny sound prevents audio spam.
- **Negative**: Large file (~750 lines). All gameplay code has a direct dependency on the AudioManager class name. Adding new SFX requires editing this file.
- **Future**: If the file grows beyond ~1000 lines, extract inner managers (MusicStemController, SFXPoolManager) as composition children.

## References

- Implementation: `src/core/autoload/audio_manager.gd`
- Registered in: `project.godot` [autoload] section
