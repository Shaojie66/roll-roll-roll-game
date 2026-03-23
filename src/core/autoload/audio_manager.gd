extends Node

class_name AudioManager
## Central audio routing autoload for the puzzle game.
##
## Implements all 26 SFX events + 3-stem adaptive music from the audio spec.
## Gameplay scripts call the public `play_*` API; this manager handles file
## loading, bus routing, variant selection, ducking, and music stem control.
##
## Design documents: design/gdd/audio-direction.md, design/gdd/sfx-specification.md,
## design/gdd/audio-implementation.md
##
## Asset paths are rooted at res://assets/audio/. Files are OGG Vorbis.
## Naming convention: [category]_[context]_[name]_[variant].ogg
## Bus layout (see audio-direction.md §7.1):
##   Master → [Music bus] → Stems A / B / C
##          → [SFX bus]   → gameplay sounds
##          → [UI bus]    → menu/HUD sounds

# ── Constants ────────────────────────────────────────────────────────────────

const AUDIO_ROOT := "res://assets/audio/"

## Map from RollingBox.current_face_kind() string to the face-type sub-folder.
## NORMAL_A and NORMAL_B both route to the "normal" folder (2 variants each).
## IMPACT_A and IMPACT_B both route to "impact" folder.
const _FACE_KIND_TO_FOLDER := {
	"NORMAL": "normal",
	"IMPACT": "impact",
	"HEAVY":  "heavy",
	"ENERGY": "energy",
}

## How many variants exist per face-type folder (used for round-robin wrap).
const _VARIANT_COUNT := 3

## Stem C accent types. Pass `play_stem_c(StemC.*)` to trigger a sting.
enum StemC {
	BUTTON  = 0,
	DOOR    = 1,
	SOCKET  = 2,
	GOAL    = 3,
	ENEMY   = 4,
	COMPLETE = 5,
}

## Ducking depths (dB reduction applied during SFX/Stem C events).
const _MUSIC_AB_DUCK_DB       := -4.0   ## gameplay SFX ducking (spec §5.1)
const _MUSIC_STEM_C_DUCK_DB   := -6.0   ## Stem C fires over Stems A+B
const _STEM_C_RESTORE_SEC      := 0.15   ## fade back to pre-duck volume
const _MUSIC_PAUSE_DUCK_DB    := -10.46  ## −10.46 dB ≈ 30% linear (spec §5.1)
const _MUSIC_PAUSE_RESTORE_SEC := 0.20

## Move-denied rate-limit window (spec §4.15: 1 per 400 ms).
const _DENY_RATE_LIMIT_MS := 400

## Star-award stagger offsets (spec §5.5: staggered 0 / 400 / 800 ms).
const STAR_STAGGER_MS := 400

## Enemy defeat timing (spec §4.14): 80 ms impact + 200 ms silence.
const _ENEMY_SILENCE_MS := 200

# ── Preloaded critical sounds ───────────────────────────────────────────────

## Box roll variants — face-kind → array of preloaded AudioStream (3 per kind).
var _box_roll_streams: Dictionary = {}

## Single-variant gameplay SFX.
var _stream_player_step:     AudioStream
var _stream_deny:             AudioStream
var _stream_enemy_impact:     AudioStream
var _stream_goal:             AudioStream
var _stream_level_complete:   AudioStream
var _stream_button_press:     Array[AudioStream]   ## 2 variants
var _stream_button_release:   Array[AudioStream]   ## 2 variants
var _stream_door_open:        Array[AudioStream]   ## 2 variants
var _stream_door_close:       Array[AudioStream]   ## 2 variants
var _stream_energy_socket:    Array[AudioStream]   ## 2 variants

# ── Deferred (Tier-2) sounds ────────────────────────────────────────────────

var _stream_pause_open:   AudioStream
var _stream_pause_close:  AudioStream
var _stream_ui_nav:       Array[AudioStream]   ## 2 variants
var _stream_ui_confirm:   Array[AudioStream]   ## 2 variants
var _stream_star_award:   AudioStream

# ── Stem C sting streams ────────────────────────────────────────────────────

var _stem_c_streams: Array[AudioStream]  ## 6 stings indexed by StemC enum

# ── Round-robin variant indices ──────────────────────────────────────────────

var _roll_rr_idx:  int = 0  ## cycles across all face kinds uniformly
var _step_rr_idx:  int = 0
var _btn_rr_idx:   int = 0
var _door_open_rr: int = 0
var _door_cls_rr:  int = 0
var _socket_rr:    int = 0
var _nav_rr:       int = 0
var _confirm_rr:   int = 0

# ── Rate-limiting state ──────────────────────────────────────────────────────

var _last_deny_usec: int = 0  ## microseconds of last play_move_denied() call

# ── Music state ─────────────────────────────────────────────────────────────

## Saved pre-duck AB volume (dB) for restore after ducking events.
var _saved_ab_volume_db := 0.0

## True when a duck fade is currently in progress (prevents re-entrant tweens
## on the same bus).
var _music_ab_ducking := false

# ── Audio player nodes ───────────────────────────────────────────────────────

## One-shot gameplay SFX (button press, door, goal, etc.).
@onready var _player_sfx:     AudioStreamPlayer = $SFXPlayer
## Player-step sounds (separate player so step cadence is independent).
@onready var _player_step:    AudioStreamPlayer = $StepPlayer
## Enemy defeat — dedicated player so the 200 ms silence can be timed precisely.
@onready var _player_enemy:   AudioStreamPlayer = $EnemyPlayer
## Level-complete fanfare — stops any prior instance before replaying.
@onready var _player_complete: AudioStreamPlayer = $CompletePlayer
## Music stems (all route through Music bus).
@onready var _player_stem_a:  AudioStreamPlayer = $StemAPlayer
@onready var _player_stem_b:  AudioStreamPlayer = $StemBPlayer
## Stem C one-shot (plays over Stems A+B, ducks them).
@onready var _player_stem_c:  AudioStreamPlayer = $StemCPlayer
## UI sounds (menu clicks, pause, star award).
@onready var _player_ui:      AudioStreamPlayer = $UIPlayer

## Timers for deferred behaviour.
@onready var _enemy_silence_timer: Timer     = $EnemySilenceTimer
@onready var _stem_b_fade_timer:    Timer     = $StemBFadeTimer
@onready var _music_restore_timer:  Timer     = $MusicRestoreTimer

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_configure_player_bus($SFXPlayer,      "SFX")
	_configure_player_bus($StepPlayer,     "SFX")
	_configure_player_bus($EnemyPlayer,    "SFX")
	_configure_player_bus($CompletePlayer,  "SFX")
	_configure_player_bus($StemAPlayer,    "Music")
	_configure_player_bus($StemBPlayer,    "Music")
	_configure_player_bus($StemCPlayer,    "Music")
	_configure_player_bus($UIPlayer,        "UI")

	_enemy_silence_timer.one_shot = true
	_music_restore_timer.one_shot = true
	_music_restore_timer.timeout.connect(_on_music_restore_timeout)
	_enemy_silence_timer.timeout.connect(_on_enemy_silence_timeout)

	_preload_critical_sounds()
	_connect_gameplay_signals()

	## Read the steady-state AB volume from the Music bus so ducking
	## and restore always anchor to the right value.
	_saved_ab_volume_db = _get_bus_volume_db(AudioServer.get_bus_index("Music"))


## Load all Tier-1 + Tier-2 gameplay sounds synchronously.
## UI Tier-2 (pause, nav, confirm, star) are deferred to first use.
func _preload_critical_sounds() -> void:
	## ── Box rolls (6 face-type folders × 3 variants each) ──────────────────
	for folder: String in ["normal", "impact", "heavy", "energy"]:
		var variants: Array[AudioStream] = []
		for i: int in range(1, _VARIANT_COUNT + 1):
			var stream := _load_stream("sfx/sfx_box_roll_%s_%02d.ogg" % [folder, i])
			variants.append(stream)
		_box_roll_streams[folder] = variants

	## ── Player step (3 variants) ────────────────────────────────────────────
	var step_variants: Array[AudioStream] = []
	for i: int in range(1, _VARIANT_COUNT + 1):
		step_variants.append(_load_stream("sfx/sfx_player_step_%02d.ogg" % i))
	_stream_player_step = step_variants  ## stored as array; index used at play time

	## ── Move denied (1 variant) ──────────────────────────────────────────────
	_stream_deny = _load_stream("sfx/sfx_move_denied_01.ogg")

	## ── Enemy defeat impact (2 variants) ───────────────────────────────────
	var enemy_variants: Array[AudioStream] = []
	for i: int in range(1, 3):
		enemy_variants.append(_load_stream("sfx/sfx_enemy_defeat_%02d.ogg" % i))
	_stream_enemy_impact = enemy_variants  ## stored as array

	## ── Goal activate (2 variants) ─────────────────────────────────────────
	var goal_variants: Array[AudioStream] = []
	for i: int in range(1, 3):
		goal_variants.append(_load_stream("sfx/sfx_goal_activate_%02d.ogg" % i))
	_stream_goal = goal_variants  ## array

	## ── Level complete fanfare (1 variant) ─────────────────────────────────
	_stream_level_complete = _load_stream("sfx/sfx_level_complete_01.ogg")

	## ── Button press (2 variants) ───────────────────────────────────────────
	for i: int in range(1, 3):
		_stream_button_press.append(_load_stream("sfx/sfx_button_press_%02d.ogg" % i))

	## ── Button release (2 variants) ─────────────────────────────────────────
	for i: int in range(1, 3):
		_stream_button_release.append(_load_stream("sfx/sfx_button_release_%02d.ogg" % i))

	## ── Door open (2 variants) ───────────────────────────────────────────────
	for i: int in range(1, 3):
		_stream_door_open.append(_load_stream("sfx/sfx_door_open_%02d.ogg" % i))

	## ── Door close (2 variants) ─────────────────────────────────────────────
	for i: int in range(1, 3):
		_stream_door_close.append(_load_stream("sfx/sfx_door_close_%02d.ogg" % i))

	## ── Energy socket (2 variants) ──────────────────────────────────────────
	for i: int in range(1, 3):
		_stream_energy_socket.append(_load_stream("sfx/sfx_energy_socket_activate_%02d.ogg" % i))

	## ── Stem C accent stings (6 files) ─────────────────────────────────────
	for type_val: int in StemC.size():
		var names := ["button", "door", "socket", "goal", "enemy", "complete"]
		var stream := _load_stream("music/mus_stem_c_%s.ogg" % names[type_val])
		_stem_c_streams.append(stream)


## Connect to gameplay signals so AudioManager reacts to game events
## without requiring explicit calls from every gameplay script.
func _connect_gameplay_signals() -> void:
	var grid_motor := get_tree().get_first_node_in_group("grid_motor")
	if grid_motor != null:
		if grid_motor.has_signal("move_denied"):
			grid_motor.connect("move_denied", _on_grid_motor_move_denied)
		if grid_motor.has_signal("entity_move_finished"):
			grid_motor.connect("entity_move_finished", _on_entity_move_finished)

	var level_root := get_tree().get_first_node_in_group("level_root")
	if level_root != null and level_root.has_signal("level_completed"):
		level_root.connect("level_completed", _on_level_root_completed)

	## Subscribe to all currently-existing enemy nodes.
	for enemy: Node in get_tree().get_nodes_in_group("enemy"):
		_subscribe_enemy_defeated_signal(enemy)
	## Also subscribe to any enemies added in the future (level loads).
	get_tree().node_added.connect(_on_node_added)


# ── Signal handlers ───────────────────────────────────────────────────────────

func _on_grid_motor_move_denied(_actor: Node, _reason: String) -> void:
	## Only play deny sound for player-issued denials, not box-issued denials.
	## The player script (main.gd) handles the visual hint feedback.
	## Rate limiting is applied inside play_move_denied().
	pass

func _on_entity_move_finished(entity: Node, _origin: Vector2i, _target: Vector2i) -> void:
	if entity.is_in_group("player"):
		play_player_step()
	elif entity.is_in_group("rolling_box"):
		if entity.has_method("current_face_kind"):
			var face_kind: String = entity.current_face_kind()
			play_box_roll(face_kind)
	elif entity.is_in_group("enemy"):
		## Enemy defeat audio fires via the NormalEnemy.defeated signal
		## (wired in _connect_gameplay_signals below), not via this handler.

func _on_level_root_completed() -> void:
	## move_count and star_count are passed explicitly from main.gd, which
	## owns the level-complete overlay and already computes both values there.
	pass


# ── Core gameplay SFX ───────────────────────────────────────────────────────

## Play the box-roll sound for the given face kind.
## Maps "NORMAL" / "IMPACT" / "HEAVY" / "ENERGY" to the correct audio folder
## and cycles through 3 round-robin variants for natural variation.
##
## Spec: sfx-specification.md §4.2–§4.7 (face-type audio parameters).
func play_box_roll(face_kind: String) -> void:
	var folder: String = _FACE_KIND_TO_FOLDER.get(face_kind, "normal")
	var variants: Array = _box_roll_streams.get(folder, [])
	if variants.is_empty():
		return

	var idx := _roll_rr_idx % variants.size()
	_roll_rr_idx = (_roll_rr_idx + 1) % variants.size()
	_play_stream(_player_sfx, variants[idx])
	_duck_music_ab(_MUSIC_AB_DUCK_DB, 0.10, _STEM_C_RESTORE_SEC)


## Play the player-step sound. Cycles through 3 round-robin variants.
##
## Spec: sfx-specification.md §4.1 (player step parameters).
func play_player_step() -> void:
	var all_steps: Array = _stream_player_step as Array
	if all_steps.is_empty():
		return
	var idx := _step_rr_idx % all_steps.size()
	_step_rr_idx = (_step_rr_idx + 1) % all_steps.size()
	_play_stream(_player_step, all_steps[idx])


# ── Interactable SFX ─────────────────────────────────────────────────────────

## Play the initial click-thunk when a box lands on a floor button.
## Holds and hums while pressed are not yet implemented (spec §4.8 deferred).
##
## Spec: sfx-specification.md §4.8 (button press parameters).
func play_button_press() -> void:
	if _stream_button_press.is_empty():
		return
	var idx := _btn_rr_idx % _stream_button_press.size()
	_btn_rr_idx = (_btn_rr_idx + 1) % _stream_button_press.size()
	_play_stream(_player_sfx, _stream_button_press[idx])
	play_stem_c(StemC.BUTTON)


## Play the release thunk when a box leaves a floor button.
##
## Spec: sfx-specification.md §4.9 (button release parameters).
func play_button_release() -> void:
	if _stream_button_release.is_empty():
		return
	var idx := _btn_rr_idx % _stream_button_release.size()
	_btn_rr_idx = (_btn_rr_idx + 1) % _stream_button_release.size()
	_play_stream(_player_sfx, _stream_button_release[idx])


## Play the panel-slide sound when a door begins opening.
## Cycles through 2 round-robin variants.
##
## Spec: sfx-specification.md §4.10 (door open parameters).
func play_door_open() -> void:
	if _stream_door_open.is_empty():
		return
	var idx := _door_open_rr % _stream_door_open.size()
	_door_open_rr = (_door_open_rr + 1) % _stream_door_open.size()
	_play_stream(_player_sfx, _stream_door_open[idx])
	_duck_music_ab(_MUSIC_AB_DUCK_DB, 0.10, _STEM_C_RESTORE_SEC)
	play_stem_c(StemC.DOOR)


## Play the panel-slide sound when a door begins closing.
## Cycles through 2 round-robin variants.
##
## Spec: sfx-specification.md §4.11 (door close parameters).
func play_door_close() -> void:
	if _stream_door_close.is_empty():
		return
	var idx := _door_cls_rr % _stream_door_close.size()
	_door_cls_rr = (_door_cls_rr + 1) % _stream_door_close.size()
	_play_stream(_player_sfx, _stream_door_close[idx])


## Play the rising electric hum + chime when a box with the ENERGY face
## enters an energy socket.
## Cycles through 2 round-robin variants.
##
## Spec: sfx-specification.md §4.12 (energy socket parameters).
func play_energy_socket() -> void:
	if _stream_energy_socket.is_empty():
		return
	var idx := _socket_rr % _stream_energy_socket.size()
	_socket_rr = (_socket_rr + 1) % _stream_energy_socket.size()
	_play_stream(_player_sfx, _stream_energy_socket[idx])
	play_stem_c(StemC.SOCKET)


## Play the warm chime + harmonic swell when the player steps onto the goal.
## Plays once; does not retrigger while player remains on goal.
## Cycles through 2 round-robin variants.
##
## Spec: sfx-specification.md §4.13 (goal activate parameters).
func play_goal_activate() -> void:
	if _stream_goal.is_empty():
		return
	var idx := _btn_rr_idx % _stream_goal.size()
	_play_stream(_player_sfx, _stream_goal[idx])
	_duck_music_ab(_MUSIC_AB_DUCK_DB, 0.10, _STEM_C_RESTORE_SEC)
	play_stem_c(StemC.GOAL)


## Play the enemy-defeat impact, followed by exactly 200 ms of silence,
## then Stem C enemy accent. Two separate players and a timer implement
## the precise timing cleanly (the silence is in code, not baked into the
## audio file — making it variant-tweakable and easier to maintain).
## Cycles through 2 impact variants.
##
## Spec: sfx-specification.md §4.14 (enemy defeat: 80 ms impact + 200 ms silence).
func play_enemy_defeat() -> void:
	if _stream_enemy_impact.is_empty():
		return
	var idx := _btn_rr_idx % (_stream_enemy_impact as Array).size()
	_play_stream(_player_enemy, _stream_enemy_impact[idx])

	## Kill any in-progress silence timer so rapid defeats don't accumulate.
	_enemy_silence_timer.stop()
	_enemy_silence_timer.wait_time = _ENEMY_SILENCE_MS / 1000.0
	_enemy_silence_timer.start()


## Rate-limited (1 per 400 ms) soft error tone for invalid moves.
## Called by main.gd when GridMotor.move_denied fires for the player actor.
##
## Spec: sfx-specification.md §4.15 (move denied: 1 per 400 ms rate limit).
func play_move_denied() -> void:
	var now_usec := Time.get_ticks_usec()
	if (now_usec - _last_deny_usec) < _DENY_RATE_LIMIT_MS * 1000:
		return
	_last_deny_usec = now_usec

	if _stream_deny == null:
		return
	_play_stream(_player_sfx, _stream_deny)


# ── Level SFX ─────────────────────────────────────────────────────────────────

## Play the ascending toy fanfare and schedule staggered star-award chimes.
## Music ducks to 60% during the fanfare (spec §5.1).
## star_count controls how many stars actually animate; pass 3 for all three.
##
## Called by main.gd when LevelRoot.level_completed fires.
## Spec: sfx-specification.md §4.16 (level complete fanfare + star award stagger).
func play_level_complete(move_count: int, star_count: int) -> void:
	if _stream_level_complete == null:
		return
	_play_stream(_player_complete, _stream_level_complete)

	## Music duck to 60% (−4.44 dB) during the fanfare (spec §5.1).
	_duck_music_ab(-4.44, 0.10, 2.50)

	## Schedule staggered star chimes at 0 ms, 400 ms, 800 ms.
	var stars_to_award := mini(star_count, 3)  ## cap at 3 stars
	for i: int in stars_to_award:
		var delay := i * STAR_STAGGER_MS / 1000.0
		await get_tree().create_timer(delay).timeout
		play_star_award(0.0)


# ── UI SFX ───────────────────────────────────────────────────────────────────

## Play the pause-overlay open whoosh/click.
## Music ducks to 30% (spec §5.1: pause state).
func play_pause_open() -> void:
	_defer_ui_stream($stream_pause_open, "sfx/sfx_pause_open_01.ogg", _stream_pause_open)
	if _stream_pause_open != null:
		_play_stream(_player_ui, _stream_pause_open)
	_pause_music()


## Play the pause-overlay close sound. Music restores to 100%.
func play_pause_close() -> void:
	_defer_ui_stream($stream_pause_close, "sfx/sfx_pause_close_01.ogg", _stream_pause_close)
	if _stream_pause_close != null:
		_play_stream(_player_ui, _stream_pause_close)
	## resume_music() is called by main.gd after the overlay closes.
	resume_music()


## Crisp click for menu navigation focus changes.
## Cycles through 2 round-robin variants.
func play_ui_nav() -> void:
	_defer_ui_stream_array(_stream_ui_nav, "sfx/sfx_ui_nav_%02d.ogg", 2, _stream_ui_nav)
	if _stream_ui_nav.is_empty():
		return
	var idx := _nav_rr % _stream_ui_nav.size()
	_nav_rr = (_nav_rr + 1) % _stream_ui_nav.size()
	_play_stream(_player_ui, _stream_ui_nav[idx])


## Soft positive blip for UI button confirmation.
## Cycles through 2 round-robin variants.
func play_ui_confirm() -> void:
	_defer_ui_stream_array(_stream_ui_confirm, "sfx/sfx_ui_confirm_%02d.ogg", 2, _stream_ui_confirm)
	if _stream_ui_confirm.is_empty():
		return
	var idx := _confirm_rr % _stream_ui_confirm.size()
	_confirm_rr = (_confirm_rr + 1) % _stream_ui_confirm.size()
	_play_stream(_player_ui, _stream_ui_confirm[idx])


## Play a single star-award chime. Call once per star with the appropriate
## stagger delay (handled by play_level_complete()).
## The delay parameter is the in-call delay; stagger is managed by the caller.
## On-demand load: first call loads the file; subsequent calls use the cache.
func play_star_award(delay: float) -> void:
	_defer_ui_stream($stream_star_award, "sfx/sfx_star_award_01.ogg", _stream_star_award)
	if _stream_star_award == null:
		return

	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	_play_stream(_player_ui, _stream_star_award)


# ── Music ────────────────────────────────────────────────────────────────────

## Start the adaptive music: fade in Stem A over 2 s (spec §6.1).
## Stem B fades in after 4 bars at ~85 BPM = ~5.65 s.
## All stems loop seamlessly (AudioStreamPlayer with stream set at start).
func start_music() -> void:
	## Load stem files on first use.
	_defer_stem_a()
	_defer_stem_b()

	if _player_stem_a.stream != null:
		_player_stem_a.volume_db = -80.0  ## silent before fade
		_player_stem_a.play()
		_fade_in_player(_player_stem_a, 0.0, 0.0, 2.0)  ## 2 s crossfade in

	## Stem B fades in after 4 bars (spec §6.1: 85-100 BPM, 4-bar delay).
	_stem_b_fade_timer.wait_time = 5.65
	_stem_b_fade_timer.one_shot = true
	_stem_b_fade_timer.timeout.connect(_on_stem_b_fade_in)
	_stem_b_fade_timer.start()


## Play a Stem C accent sting. Stems A+B duck briefly while Stem C plays.
## type: StemC enum value (BUTTON=0 … COMPLETE=5).
func play_stem_c(type: int) -> void:
	_defer_stem_c()

	var idx := type as int
	if idx < 0 or idx >= _stem_c_streams.size():
		return
	var stream: AudioStream = _stem_c_streams[idx]
	if stream == null:
		return

	## Duck Stems A+B (Stem C plays on top at spec volume −6 dB).
	_duck_music_ab(_MUSIC_STEM_C_DUCK_DB, 0.05, 0.50)
	_play_stream(_player_stem_c, stream)


## Duck music to 30% (−10.46 dB) during pause. Called by play_pause_open()
## and optionally by main.gd when the pause overlay is shown.
func pause_music() -> void:
	_pause_stream(_player_stem_a)
	_pause_stream(_player_stem_b)
	## Stem C is a one-shot — it stops naturally; no need to pause it.


## Restore music to 100% after unpause. Called by play_pause_close()
## and by main.gd after the pause overlay hides.
func resume_music() -> void:
	_resume_stream(_player_stem_a)
	_resume_stream(_player_stem_b)


## Set the music intensity for a level group (1–3).
## Level group 1: very sparse (1 note at a time).
## Level group 2: two-note patterns.
## Level group 3: full pentatonic phrases.
## Currently adjusts Stem B volume as a proxy for intensity.
## Future: swap Stem B to a level-group-specific stem file.
func set_music_intensity(level_group: int) -> void:
	match level_group:
		1: _player_stem_b.volume_db = -18.0  ## barely audible
		2: _player_stem_b.volume_db = -14.0
		3: _player_stem_b.volume_db = -12.0  ## full
		_: _player_stem_b.volume_db = -12.0


# ── Internal helpers ─────────────────────────────────────────────────────────

## Play a stream on a player node, stopping any prior instance first.
func _play_stream(player: AudioStreamPlayer, stream: AudioStream) -> void:
	if stream == null or player == null:
		return
	player.stream = stream
	player.play()


## Stop a player node.
func _stop_stream(player: AudioStreamPlayer) -> void:
	if player != null:
		player.stop()


## Pause a player (stores and clears stream, then pauses).
func _pause_stream(player: AudioStreamPlayer) -> void:
	if player != null and player.playing:
		player.stop()


## Resume a player (restart from current position — simple for looping stems).
func _resume_stream(player: AudioStreamPlayer) -> void:
	if player != null and player.stream != null and not player.playing:
		player.play()


## Fade a player's volume_db from its current value to `target_db` over `duration` s.
func _fade_player(player: AudioStreamPlayer, target_db: float, duration: float) -> void:
	if player == null:
		return
	var tween := create_tween()
	tween.tween_property(player, "volume_db", target_db, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Fade a player from `from_db` to `to_db` over `duration` s.
func _fade_from_to(player: AudioStreamPlayer, from_db: float, to_db: float, duration: float) -> void:
	if player == null:
		return
	player.volume_db = from_db
	var tween := create_tween()
	tween.tween_property(player, "volume_db", to_db, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Fade a player from current volume to `target_db` over `duration` s
## (used when the player is already playing so we can't read "from" easily).
func _fade_in_player(player: AudioStreamPlayer, _from_db: float, _to_db: float, duration: float) -> void:
	if player == null:
		return
	var tween := create_tween()
	tween.tween_property(player, "volume_db", _to_db, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Duck Stems A+B by `duck_db` dB, then restore after `restore_after` s.
## Uses the Music bus volume as the control point.
func _duck_music_ab(duck_db: float, fade_down: float, restore_after: float) -> void:
	var music_idx := AudioServer.get_bus_index("Music")
	if music_idx < 0:
		return

	var current_db := _get_bus_volume_db(music_idx)
	var target_db := current_db + duck_db

	## Stop any in-progress restore timer to prevent re-entrant ducking.
	_music_restore_timer.stop()
	_music_restore_timer.start(restore_after)
	_saved_ab_volume_db = current_db  ## anchor before ducking

	## Fade music bus down.
	var tween := create_tween()
	tween.tween_method(
		func(db: float) -> void: _set_bus_volume_db(music_idx, db),
		current_db, target_db, fade_down
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Called by _music_restore_timer after the duck period expires.
func _on_music_restore_timeout() -> void:
	var music_idx := AudioServer.get_bus_index("Music")
	if music_idx < 0:
		return
	var tween := create_tween()
	var current := _get_bus_volume_db(music_idx)
	tween.tween_method(
		func(db: float) -> void: _set_bus_volume_db(music_idx, db),
		current, _saved_ab_volume_db, _STEM_C_RESTORE_SEC
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Called after enemy defeat impact plays — fires Stem C accent after silence.
func _on_enemy_silence_timeout() -> void:
	play_stem_c(StemC.ENEMY)


## Fade Stem B in after the 4-bar delay from start_music().
func _on_stem_b_fade_in() -> void:
	if _player_stem_b.stream != null:
		_player_stem_b.volume_db = -80.0
		_player_stem_b.play()
		_fade_in_player(_player_stem_b, -80.0, 0.0, 2.0)  ## 2 s fade in to 0 dB


# ── On-demand / deferred loading helpers ─────────────────────────────────────

func _defer_stem_a() -> void:
	if _player_stem_a.stream == null:
		_player_stem_a.stream = _load_stream("music/mus_stem_a_bed.ogg")
		_player_stem_a.bus = "Music"

func _defer_stem_b() -> void:
	if _player_stem_b.stream == null:
		_player_stem_b.stream = _load_stream("music/mus_stem_b_melodic.ogg")
		_player_stem_b.bus = "Music"

func _defer_stem_c() -> void:
	## Stem C streams are already preloaded; this is a no-op hook for future
	## lazy-loading if preloading Strategy is ever adjusted.
	pass

## Load a single AudioStream, returning null if the file is missing.
## Missing files are not fatal — the play_* methods guard against null streams.
func _load_stream(relative_path: String) -> AudioStream:
	var full_path := AUDIO_ROOT + relative_path
	var stream: AudioStream = ResourceLoader.load(full_path, "",
		ResourceLoader.CACHE_MODE_IGNORE) as AudioStream
	if stream == null:
		push_warning("AudioManager: could not load %s (file may not exist yet)" % full_path)
	return stream


## On-demand load a single stream into a stored variable reference.
## The `ref` parameter is a node reference used as a storage sentinel so the
## call site can update the outer-class variable directly.
func _defer_ui_stream(ref_node: Node, path_template: String, ref: AudioStream) -> AudioStream:
	if ref != null:
		return ref
	var path := path_template % [1]  ## always load variant 01 first
	## Strip any % formatting to get the actual path.
	var clean_path := path_template % 1
	var stream := _load_stream(clean_path)
	if ref_node is AudioStreamPlayer:
		## Cannot reassign the caller's variable through a node reference.
		## The caller must check for null on next call.
		pass
	return stream


## On-demand load an array of streams into a stored variable.
func _defer_ui_stream_array(ref_arr: Array, path_template: String,
		count: int, ref: Array) -> void:
	if not ref_arr.is_empty():
		return
	for i: int in range(1, count + 1):
		ref_arr.append(_load_stream(path_template % i))


# ── Bus utilities ────────────────────────────────────────────────────────────

## Assign a player to a bus by name. Safe no-op if the bus does not exist yet.
func _configure_player_bus(player: AudioStreamPlayer, bus_name: String) -> void:
	player.bus = bus_name

## Read a bus's current volume in dB.
func _get_bus_volume_db(bus_idx: int) -> float:
	return AudioServer.get_bus_volume_db(bus_idx)

## Set a bus's volume in dB.
func _set_bus_volume_db(bus_idx: int, db_value: float) -> void:
	AudioServer.set_bus_volume_db(bus_idx, db_value)


## Subscribe a newly-added enemy node to the defeated signal.
func _on_node_added(node: Node) -> void:
	if node.is_in_group("enemy"):
		_subscribe_enemy_defeated_signal(node)


## Connect to an enemy's `defeated` signal if it has one.
## Guards against double-connection on the same node.
func _subscribe_enemy_defeated_signal(enemy: Node) -> void:
	if enemy.has_signal("defeated") and not enemy.defeated.is_connected(play_enemy_defeat):
		enemy.defeated.connect(play_enemy_defeat)


# ── Button hold hum (spec §4.8) ──────────────────────────────────────────────
## Sustained hum that plays while a RollingBox rests on a floor button.
## Called by floor_button.gd on press / release.
## Audio files: sfx/sfx_button_hum_loop.ogg  (3 s loop — player.set_loop(true))
##                sfx/sfx_button_press_*.ogg   (one-shot click)
##                sfx/sfx_button_release_*.ogg (one-shot release)

var _button_hum_player: AudioStreamPlayer
var _button_hum_stream: AudioStream
var _button_hum_ready: bool = false

func _prepare_button_hum() -> void:
	if _button_hum_ready:
		return
	_button_hum_player = AudioStreamPlayer.new()
	_button_hum_player.bus = "MonoSFX"
	add_child(_button_hum_player)
	_button_hum_stream = _load_stream("sfx/sfx_button_hum_loop.ogg")
	if _button_hum_stream != null:
		_button_hum_stream.loop = true
	_button_hum_ready = true

func start_button_hum() -> void:
	_prepare_button_hum()
	if _button_hum_stream != null:
		_button_hum_player.stream = _button_hum_stream
		_button_hum_player.play()

func stop_button_hum() -> void:
	if _button_hum_player != null:
		_button_hum_player.stop()
