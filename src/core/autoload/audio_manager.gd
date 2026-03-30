extends Node
class_name AudioManager
## Central audio routing autoload for the puzzle game.
##
## Implements all 26 SFX events + 3-stem adaptive music from the audio spec.
## Gameplay scripts call the public `play_*` API; this manager handles file
## loading, bus routing, variant selection, ducking, and music stem control.
##
## All AudioStreamPlayer nodes are created programmatically in _ready().
## No .tscn file is required.
##
## Design documents: design/gdd/audio-tutorial-levels.md,
## design/gdd/audio-implementation.md
##
## Asset paths are rooted at res://assets/audio/. Files are OGG Vorbis.
## Naming convention: sfx_[name]_[variant].ogg  /  mus_stem_[name].ogg

# ── Enums ─────────────────────────────────────────────────────────────────────

## Box face types. Maps to the face-kind string returned by RollingBox.
## Used for pitch/volume/reverb variation per face.
enum FaceType {
	NORMAL_A,
	NORMAL_B,
	IMPACT_A,
	IMPACT_B,
	HEAVY,
	ENERGY,
}

## Stem C accent sting types. One AudioStreamPlayer per type.
enum StemCType {
	BUTTON  = 0,
	DOOR    = 1,
	SOCKET  = 2,
	GOAL    = 3,
	ENEMY   = 4,
	COMPLETE = 5,
}

# ── Asset root ────────────────────────────────────────────────────────────────

const AUDIO_ROOT := "res://assets/audio/"

# ── Face-type audio parameters ────────────────────────────────────────────────
## From design/gdd/audio-implementation.md §9.2 / sfx-ffmpeg-lavfi-spec.md

const _FACE_PITCH := {
	FaceType.NORMAL_A: 1.0,
	FaceType.NORMAL_B: 0.85,
	FaceType.IMPACT_A: 1.1,
	FaceType.IMPACT_B: 0.9,
	FaceType.HEAVY:    0.5,
	FaceType.ENERGY:   1.3,
}

const _FACE_VOLUME_DB := {
	FaceType.NORMAL_A: -4.0,
	FaceType.NORMAL_B: -4.0,
	FaceType.IMPACT_A: -1.0,
	FaceType.IMPACT_B: -1.0,
	FaceType.HEAVY:     1.0,
	FaceType.ENERGY:   -4.0,
}

const _FACE_REVERB_AMOUNT := {
	FaceType.NORMAL_A: 0.10,
	FaceType.NORMAL_B: 0.12,
	FaceType.IMPACT_A: 0.15,
	FaceType.IMPACT_B: 0.20,
	FaceType.HEAVY:    0.25,
	FaceType.ENERGY:   0.15,
}

# ── Ducking constants ─────────────────────────────────────────────────────────
## From audio-implementation.md §5.1 and audio-direction.md §6.4

const _MUSIC_AB_DUCK_DB     := -4.0  ## gameplay SFX ducking
const _MUSIC_STEM_C_DUCK_DB := -6.0  ## Stem C fires over Stems A+B
const _STEM_C_RESTORE_SEC    := 0.15  ## fade back after Stem C
const _MUSIC_PAUSE_DUCK_DB   := -10.46  ## −10.46 dB ≈ 30% linear
const _MUSIC_PAUSE_RESTORE_SEC := 0.20

# ── Timing constants ───────────────────────────────────────────────────────────

const _DENY_RATE_LIMIT_MS := 400   ## move_denied: 1 per 400ms (spec §4.15)
const _ENEMY_SILENCE_MS     := 200   ## enemy defeat: 80ms impact + 200ms silence
const _STEM_B_DELAY_SEC    := 10.6  ## Stem B fades in after 4 bars at 90 BPM
const _STAR_STAGGER_MS      := 400   ## star award stagger: 0 / 400 / 800 ms

# ── Stream cache ─────────────────────────────────────────────────────────────

## Box roll variants — keyed by face-type name string, each with 3 round-robin variants
var _box_roll_streams: Dictionary = {}

## Single-variant gameplay SFX
var _stream_player_step:       Array[AudioStream]   ## 3 variants
var _stream_deny:             AudioStream          ## 1 variant
var _stream_enemy_defeat:     Array[AudioStream]   ## 1 variant (280ms total)
var _stream_goal:             Array[AudioStream]   ## 1 variant
var _stream_level_complete:   AudioStream          ## 1 variant (fanfare)
var _stream_button_press:     Array[AudioStream]   ## 1 variant
var _stream_button_release:   AudioStream          ## 1 variant
var _stream_door_open:        Array[AudioStream]   ## 1 variant
var _stream_door_close:       Array[AudioStream]   ## 1 variant
var _stream_energy_socket:     Array[AudioStream]   ## 1 variant

## Tier-2 UI SFX (deferred load)
var _stream_pause_open:   AudioStream
var _stream_pause_close:  AudioStream
var _stream_ui_nav:       Array[AudioStream]   ## 1 variant
var _stream_ui_confirm:   Array[AudioStream]   ## 1 variant
var _stream_star_award:   AudioStream

## Music stem streams
var _stream_stem_a: AudioStream
var _stream_stem_b: AudioStream

## Stem C sting streams — indexed by StemCType enum
var _stem_c_streams: Array[AudioStream]  ## 6 stings

# ── Round-robin indices ───────────────────────────────────────────────────────

var _roll_rr_idx:  int = 0
var _step_rr_idx:  int = 0
var _door_open_rr: int = 0
var _door_cls_rr:  int = 0
var _nav_rr:       int = 0
var _confirm_rr:   int = 0

# ── Rate-limiting state ───────────────────────────────────────────────────────

var _last_deny_usec: int = 0

# ── Music state ───────────────────────────────────────────────────────────────

var _saved_ab_volume_db := 0.0
var _music_bus_idx := -1
var _music_stem_b_started := false
var _is_ducked := false

# ── Button hum state ─────────────────────────────────────────────────────────

var _button_hum_player: AudioStreamPlayer
var _button_hum_stream: AudioStream
var _button_hum_ready := false

# ── Pool counters ────────────────────────────────────────────────────────────

var _box_pool_idx := 0
var _ui_pool_idx  := 0

# ── Audio player nodes ────────────────────────────────────────────────────────
## All created programmatically in _ready(). No .tscn file required.

## Box roll pool — 6 nodes, round-robin
var _box_pool: Array[AudioStreamPlayer] = []
const BOX_POOL_SIZE := 6

## Player step pool — 2 nodes
var _step_pool: Array[AudioStreamPlayer] = []
const STEP_POOL_SIZE := 2

## UI pool — 4 nodes (shared for nav, confirm, star award)
var _ui_pool: Array[AudioStreamPlayer] = []
const UI_POOL_SIZE := 4

## Door pool — 2 nodes
var _door_pool: Array[AudioStreamPlayer] = []

## Stem C pool — 6 nodes (one per sting type)
var _stem_c_pool: Array[AudioStreamPlayer] = []

## Dedicated one-shot players
var _player_enemy:     AudioStreamPlayer
var _player_complete:  AudioStreamPlayer
var _player_goal:      AudioStreamPlayer
var _player_deny:      AudioStreamPlayer
var _player_energy:    AudioStreamPlayer
var _player_btn_press: AudioStreamPlayer
var _player_btn_release: AudioStreamPlayer

## Music players
var _player_stem_a: AudioStreamPlayer
var _player_stem_b: AudioStreamPlayer

## Timers
var _enemy_silence_timer: Timer
var _music_restore_timer: Timer

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  ## not paused when tree is paused
	_create_player_nodes()
	_configure_buses()
	_preload_streams()

func _create_player_nodes() -> void:
	## ── Box roll pool (6 nodes on SpatialSFX) ────────────────────────────
	for i: int in BOX_POOL_SIZE:
		var p := _make_player("BoxPool_%d" % i, "SpatialSFX")
		_box_pool.append(p)
		add_child(p)

	## ── Step pool (2 nodes on SpatialSFX) ──────────────────────────────────
	for i: int in STEP_POOL_SIZE:
		var p := _make_player("StepPool_%d" % i, "SpatialSFX")
		_step_pool.append(p)
		add_child(p)

	## ── UI pool (4 nodes on UI bus) ────────────────────────────────────────
	for i: int in UI_POOL_SIZE:
		var p := _make_player("UIPool_%d" % i, "UI")
		_ui_pool.append(p)
		add_child(p)

	## ── Door pool (2 nodes on SpatialSFX) ──────────────────────────────────
	for i: int in 2:
		var p := _make_player("DoorPool_%d" % i, "SpatialSFX")
		_door_pool.append(p)
		add_child(p)

	## ── Stem C pool (6 nodes on Music bus) ────────────────────────────────
	for i: int in 6:
		var p := _make_player("StemC_%d" % i, "Music")
		_stem_c_pool.append(p)
		add_child(p)

	## ── Dedicated one-shot players ─────────────────────────────────────────
	_player_enemy     = _make_player("Enemy",     "SpatialSFX"); add_child(_player_enemy)
	_player_complete  = _make_player("Complete",  "MonoSFX");    add_child(_player_complete)
	_player_goal      = _make_player("Goal",      "MonoSFX");    add_child(_player_goal)
	_player_deny     = _make_player("Deny",      "MonoSFX");    add_child(_player_deny)
	_player_energy    = _make_player("Energy",    "MonoSFX");    add_child(_player_energy)
	_player_btn_press   = _make_player("BtnPress",   "MonoSFX"); add_child(_player_btn_press)
	_player_btn_release = _make_player("BtnRelease", "MonoSFX"); add_child(_player_btn_release)

	## ── Music players ─────────────────────────────────────────────────────
	_player_stem_a = _make_player("StemA", "Music"); add_child(_player_stem_a)
	_player_stem_b = _make_player("StemB", "Music"); add_child(_player_stem_b)
	_player_stem_b.volume_db = -80.0  ## silent until start_music() fades it in

	## ── Timers ─────────────────────────────────────────────────────────────
	_enemy_silence_timer = Timer.new()
	_enemy_silence_timer.one_shot = true
	_enemy_silence_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_enemy_silence_timer)
	_enemy_silence_timer.timeout.connect(_on_enemy_silence_timeout)

	_music_restore_timer = Timer.new()
	_music_restore_timer.one_shot = true
	_music_restore_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_restore_timer)
	_music_restore_timer.timeout.connect(_on_music_restore_timeout)


func _make_player(name: String, bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = name
	p.bus = bus
	return p


func _configure_buses() -> void:
	## Read the steady-state Music bus volume so ducking anchors correctly.
	_music_bus_idx = AudioServer.get_bus_index("Music")
	if _music_bus_idx >= 0:
		_saved_ab_volume_db = AudioServer.get_bus_volume_db(_music_bus_idx)


# ── Stream loading ───────────────────────────────────────────────────────────

func _preload_streams() -> void:
	## ── Box rolls: 6 face types × 3 variants ─────────────────────────────
	var face_type_map := {
		"normal_a": "normal",
		"normal_b": "normal",
		"impact_a": "impact",
		"impact_b": "impact",
		"heavy":    "heavy",
		"energy":   "energy",
	}
	var folders := ["normal", "impact", "heavy", "energy"]
	for folder: String in folders:
		var variants: Array[AudioStream] = []
		for i: int in [1, 2, 3]:
			var s := _load("sfx/sfx_box_roll_%s_%02d.ogg" % [folder, i])
			variants.append(s)
		_box_roll_streams[folder] = variants

	## ── Player step (3 variants) ───────────────────────────────────────────
	for i: int in [1, 2, 3]:
		_stream_player_step.append(_load("sfx/sfx_player_step_%02d.ogg" % i))

	## ── Move denied ────────────────────────────────────────────────────────
	_stream_deny = _load("sfx/sfx_move_denied_01.ogg")

	## ── Enemy defeat ─────────────────────────────────────────────────────────
	_stream_enemy_defeat.append(_load("sfx/sfx_enemy_defeat_01.ogg"))

	## ── Goal activate ───────────────────────────────────────────────────────
	_stream_goal.append(_load("sfx/sfx_goal_activate_01.ogg"))

	## ── Level complete fanfare ───────────────────────────────────────────────
	_stream_level_complete = _load("sfx/sfx_level_complete_01.ogg")

	## ── Button press ─────────────────────────────────────────────────────────
	_stream_button_press.append(_load("sfx/sfx_button_press_01.ogg"))

	## ── Button release ────────────────────────────────────────────────────────
	_stream_button_release.append(_load("sfx/sfx_button_release_01.ogg"))

	## ── Door open / close ───────────────────────────────────────────────────
	_stream_door_open.append(_load("sfx/sfx_door_open_01.ogg"))
	_stream_door_close.append(_load("sfx/sfx_door_close_01.ogg"))

	## ── Energy socket ────────────────────────────────────────────────────────
	_stream_energy_socket.append(_load("sfx/sfx_energy_socket_activate_01.ogg"))

	## ── Stem C accent stings (6 files) ─────────────────────────────────────
	var stem_c_names := ["button", "door", "socket", "goal", "enemy", "complete"]
	for type_val: int in StemCType.size():
		_stem_c_streams.append(_load("music/mus_stem_c_%s.ogg" % stem_c_names[type_val]))

	## ── Music stems ─────────────────────────────────────────────────────────
	_stream_stem_a = _load("music/mus_stem_a_pulse.ogg")
	_stream_stem_b = _load("music/mus_stem_b_melodic.ogg")


func _load(relative: String) -> AudioStream:
	var stream: AudioStream = ResourceLoader.load(
		AUDIO_ROOT + relative, "", ResourceLoader.CACHE_MODE_REUSE)
	if stream == null:
		push_warning("AudioManager: could not load %s (file may not exist yet)" % relative)
	return stream


## Deferred load for Tier-2 UI sounds.
func _defer_ui_stream(ref: AudioStream, path: String) -> AudioStream:
	if ref != null:
		return ref
	return _load(path)


# ── Core gameplay SFX ────────────────────────────────────────────────────────

## Play the box-roll sound for the given face type.
## Cycles through 3 round-robin variants for natural variation.
## Ducks Stems A+B by 4dB briefly.
func play_box_roll(face_type: FaceType) -> void:
	var folder: String
	match face_type:
		FaceType.NORMAL_A, FaceType.NORMAL_B: folder = "normal"
		FaceType.IMPACT_A,  FaceType.IMPACT_B:  folder = "impact"
		FaceType.HEAVY:                           folder = "heavy"
		FaceType.ENERGY:                          folder = "energy"
		_: return

	var variants: Array = _box_roll_streams.get(folder, [])
	if variants.is_empty():
		return

	var idx := _box_pool_idx % _box_pool.size()
	_box_pool_idx = (_box_pool_idx + 1) % _box_pool.size()
	var player: AudioStreamPlayer = _box_pool[idx]
	player.stream = variants[_roll_rr_idx % variants.size()]
	_roll_rr_idx += 1
	player.volume_db = _FACE_VOLUME_DB.get(face_type, 0.0)
	player.reverb_amount = _FACE_REVERB_AMOUNT.get(face_type, 0.1)
	player.play()
	_duck_music_ab(_MUSIC_AB_DUCK_DB, 0.05, _STEM_C_RESTORE_SEC)


## Play the player-step sound. Cycles through 3 round-robin variants.
func play_player_step() -> void:
	if _stream_player_step.is_empty():
		return
	var idx := _step_rr_idx % _stream_player_step.size()
	_step_rr_idx = (_step_rr_idx + 1) % _stream_player_step.size()
	var pool_idx := 0  ## step pool always uses node 0 (only one step at a time)
	_step_pool[pool_idx].stream = _stream_player_step[idx]
	_step_pool[pool_idx].play()


# ── Interactable SFX ──────────────────────────────────────────────────────────

## Play the click-thunk when a box lands on a floor button.
## Also triggers Stem C button accent.
func play_button_press() -> void:
	if _stream_button_press.is_empty():
		return
	_player_btn_press.stream = _stream_button_press[0]
	_player_btn_press.play()
	play_stem_c(StemCType.BUTTON)


## Fade out and stop the sustained button hum loop.
func stop_button_hum() -> void:
	if _button_hum_player == null or not _button_hum_player.playing:
		return
	var tween := create_tween()
	tween.tween_property(_button_hum_player, "volume_db", -80.0, 0.1)
	await tween.finished
	_button_hum_player.stop()


## Start the sustained hum loop when a box rests on a floor button.
func start_button_hum() -> void:
	if not _button_hum_ready:
		_button_hum_player = _make_player("ButtonHum", "MonoSFX")
		_button_hum_player.bus = "MonoSFX"
		add_child(_button_hum_player)
		_button_hum_stream = _load("sfx/sfx_button_hum_loop.ogg")
		if _button_hum_stream != null:
			_button_hum_stream.loop = true
		_button_hum_ready = true

	if _button_hum_stream != null:
		_button_hum_player.stream = _button_hum_stream
		_button_hum_player.volume_db = 0.0
		_button_hum_player.play()


## Play the release thunk when a box leaves a floor button.
func play_button_release() -> void:
	if _stream_button_release.is_empty():
		return
	_player_btn_release.stream = _stream_button_release[0]
	_player_btn_release.play()


## Play the panel-slide sound when a door opens.
## Triggers Stem C door accent.
func play_door_open() -> void:
	if _stream_door_open.is_empty():
		return
	var idx := _door_open_rr % _door_pool.size()
	_door_open_rr = (_door_open_rr + 1) % _door_pool.size()
	_door_pool[idx].stream = _stream_door_open[idx % _stream_door_open.size()]
	_door_pool[idx].play()
	_duck_music_ab(_MUSIC_AB_DUCK_DB, 0.05, _STEM_C_RESTORE_SEC)
	play_stem_c(StemCType.DOOR)


## Play the panel-slide sound when a door closes.
func play_door_close() -> void:
	if _stream_door_close.is_empty():
		return
	var idx := _door_cls_rr % _door_pool.size()
	_door_cls_rr = (_door_cls_rr + 1) % _door_pool.size()
	# Use a box pool node for close sound (door pool may still be playing open)
	var pool_idx := _box_pool_idx % _box_pool.size()
	_box_pool[pool_idx].stream = _stream_door_close[idx]
	_box_pool[pool_idx].play()


## Play the rising electric hum when a box enters an energy socket.
## Triggers Stem C socket accent.
func play_energy_socket_activate() -> void:
	if _stream_energy_socket.is_empty():
		return
	_player_energy.stream = _stream_energy_socket[0]
	_player_energy.play()
	play_stem_c(StemCType.SOCKET)


## Play the warm chime when the player steps onto the goal.
## Triggers Stem C goal accent.
func play_goal_activate() -> void:
	if _stream_goal.is_empty():
		return
	_player_goal.stream = _stream_goal[0]
	_player_goal.play()
	_duck_music_ab(_MUSIC_AB_DUCK_DB, 0.05, _STEM_C_RESTORE_SEC)
	play_stem_c(StemCType.GOAL)


## Play the enemy-defeat impact. After 200ms silence, fires Stem C enemy accent.
func play_enemy_defeat() -> void:
	if _stream_enemy_defeat.is_empty():
		return
	_player_enemy.stream = _stream_enemy_defeat[0]
	_player_enemy.play()

	## Stop any in-progress silence timer so rapid defeats don't accumulate.
	_enemy_silence_timer.stop()
	_enemy_silence_timer.wait_time = _ENEMY_SILENCE_MS / 1000.0
	_enemy_silence_timer.start()


## Rate-limited (1 per 400ms) soft error tone for invalid moves.
func play_move_denied() -> void:
	var now_usec := Time.get_ticks_usec()
	if (now_usec - _last_deny_usec) < _DENY_RATE_LIMIT_MS * 1000:
		return
	_last_deny_usec = now_usec

	if _stream_deny == null:
		return
	_player_deny.stream = _stream_deny
	_player_deny.play()


# ── Level SFX ─────────────────────────────────────────────────────────────────

## Play the ascending fanfare and schedule staggered star-award chimes.
## Ducks music during the fanfare.
func play_level_complete(_move_count: int, star_count: int) -> void:
	if _stream_level_complete == null:
		return
	_player_complete.stream = _stream_level_complete
	_player_complete.play()

	## Duck music to 60% (−4.44 dB) during fanfare.
	_duck_music_ab(-4.44, 0.10, 2.50)

	## Schedule staggered star chimes at 0 / 400 / 800 ms.
	var stars_to_award := mini(star_count, 3)
	for i: int in stars_to_award:
		var delay := i * _STAR_STAGGER_MS / 1000.0
		await get_tree().create_timer(delay).timeout
		play_star_award()


# ── UI SFX ────────────────────────────────────────────────────────────────────

## Crisp click for menu navigation.
func play_ui_nav() -> void:
	if _stream_ui_nav.is_empty():
		_stream_ui_nav.append(null)
	_stream_ui_nav[0] = _defer_ui_stream(_stream_ui_nav[0], "sfx/sfx_ui_nav_01.ogg")
	if _stream_ui_nav[0] == null:
		return
	var idx := _ui_pool_idx % _ui_pool.size()
	_ui_pool_idx = (_ui_pool_idx + 1) % _ui_pool.size()
	_ui_pool[idx].stream = _stream_ui_nav[0]
	_ui_pool[idx].play()


## Soft positive blip for UI button confirmation.
func play_ui_confirm() -> void:
	if _stream_ui_confirm.is_empty():
		_stream_ui_confirm.append(null)
	_stream_ui_confirm[0] = _defer_ui_stream(_stream_ui_confirm[0], "sfx/sfx_ui_confirm_01.ogg")
	if _stream_ui_confirm[0] == null:
		return
	var idx := _ui_pool_idx % _ui_pool.size()
	_ui_pool_idx = (_ui_pool_idx + 1) % _ui_pool.size()
	_ui_pool[idx].stream = _stream_ui_confirm[0]
	_ui_pool[idx].play()


## Play a single star-award chime.
func play_star_award() -> void:
	if _stream_star_award == null:
		_stream_star_award = _defer_ui_stream(_stream_star_award, "sfx/sfx_star_award_01.ogg")
	if _stream_star_award == null:
		return
	var idx := _ui_pool_idx % _ui_pool.size()
	_ui_pool_idx = (_ui_pool_idx + 1) % _ui_pool.size()
	_ui_pool[idx].stream = _stream_star_award
	_ui_pool[idx].play()


## Play the pause-overlay open whoosh.
## Pauses music during pause state.
func play_pause_open() -> void:
	_stream_pause_open = _defer_ui_stream(_stream_pause_open, "sfx/sfx_pause_open_01.ogg")
	if _stream_pause_open != null:
		var idx := _ui_pool_idx % _ui_pool.size()
		_ui_pool_idx = (_ui_pool_idx + 1) % _ui_pool.size()
		_ui_pool[idx].stream = _stream_pause_open
		_ui_pool[idx].play()
	pause_music()


## Play the pause-overlay close sound.
func play_pause_close() -> void:
	_stream_pause_close = _defer_ui_stream(_stream_pause_close, "sfx/sfx_pause_close_01.ogg")
	if _stream_pause_close != null:
		var idx := _ui_pool_idx % _ui_pool.size()
		_ui_pool_idx = (_ui_pool_idx + 1) % _ui_pool.size()
		_ui_pool[idx].stream = _stream_pause_close
		_ui_pool[idx].play()
	resume_music()


# ── Menu SFX ───────────────────────────────────────────────────────────────────

## Hover blip for menu items.
func play_menu_hover() -> void:
	## Reuse the UI nav sound for menu hover.
	play_ui_nav()


## Select click for menu items.
func play_menu_select() -> void:
	## Reuse the UI confirm sound.
	play_ui_confirm()


# ── Music ─────────────────────────────────────────────────────────────────────

## Start the adaptive 3-stem music:
##   Stem A fades in immediately at -18dB.
##   Stem B fades in after 4 bars (~10.6s at 90 BPM).
func start_music() -> void:
	if _stream_stem_a != null:
		_player_stem_a.stream = _stream_stem_a
		_player_stem_a.volume_db = -80.0
		_player_stem_a.play()
		var tw := create_tween()
		tw.tween_property(_player_stem_a, "volume_db", -18.0, 2.0) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if _stream_stem_b != null:
		_player_stem_b.volume_db = -80.0
		await get_tree().create_timer(_STEM_B_DELAY_SEC).timeout
		_player_stem_b.stream = _stream_stem_b
		_player_stem_b.play()
		var tw := create_tween()
		tw.tween_property(_player_stem_b, "volume_db", -12.0, 2.0) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_music_stem_b_started = true


## Fade out both stems and stop.
func stop_music(fade_time: float = 1.5) -> void:
	var tw := create_tween().set_parallel(true)
	if _player_stem_a.playing:
		tw.tween_property(_player_stem_a, "volume_db", -80.0, fade_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if _player_stem_b.playing:
		tw.tween_property(_player_stem_b, "volume_db", -80.0, fade_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	_player_stem_a.stop()
	_player_stem_b.stop()


## Play a Stem C accent sting on a dedicated player.
## Does NOT duck Stems A+B — caller is responsible for ducking.
func play_stem_c(type: StemCType) -> void:
	var idx := type as int
	if idx < 0 or idx >= _stem_c_streams.size():
		return
	var stream: AudioStream = _stem_c_streams[idx]
	if stream == null:
		return
	_stem_c_pool[idx].stream = stream
	_stem_c_pool[idx].play()


## Duck the Music bus by `amount_db` for `duration_s`.
func duck_music(amount_db: float, duration_s: float) -> void:
	_duck_music_ab(amount_db, 0.05, duration_s)


## Restore the Music bus to pre-duck volume.
func restore_music(duration_s: float = 0.2) -> void:
	_restore_music_ab(duration_s)


## Pause Stems A+B (call when entering pause state).
func pause_music() -> void:
	if _player_stem_a.playing:
		_player_stem_a.stop()
	if _player_stem_b.playing:
		_player_stem_b.stop()


## Resume Stems A+B (call when exiting pause state).
func resume_music() -> void:
	if _player_stem_a.stream != null and not _player_stem_a.playing:
		_player_stem_a.play()
	if _player_stem_b.stream != null and not _player_stem_b.playing:
		_player_stem_b.play()


## Stub for music intensity control (post-MVP).
## Adjusts Stem B volume as a proxy for intensity.
func set_music_intensity(level_group: int) -> void:
	match level_group:
		1: _player_stem_b.volume_db = -18.0
		2: _player_stem_b.volume_db = -14.0
		3: _player_stem_b.volume_db = -12.0
		_: pass


# ── Internal ducking ──────────────────────────────────────────────────────────

func _duck_music_ab(duck_db: float, fade_down: float, restore_after: float) -> void:
	if _music_bus_idx < 0:
		return

	_music_restore_timer.stop()
	_music_restore_timer.start(restore_after)

	var current_db := AudioServer.get_bus_volume_db(_music_bus_idx)
	if not _is_ducked:
		_saved_ab_volume_db = current_db
		_is_ducked = true

	var target_db := _saved_ab_volume_db + duck_db
	var tween := create_tween()
	tween.tween_method(
		func(db: float) -> void: AudioServer.set_bus_volume_db(_music_bus_idx, db),
		current_db, target_db, fade_down
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _restore_music_ab(restore_duration: float) -> void:
	if _music_bus_idx < 0:
		return
	_music_restore_timer.stop()
	var current := AudioServer.get_bus_volume_db(_music_bus_idx)
	var tween := create_tween()
	tween.tween_method(
		func(db: float) -> void: AudioServer.set_bus_volume_db(_music_bus_idx, db),
		current, _saved_ab_volume_db, restore_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# ── Timer callbacks ───────────────────────────────────────────────────────────

func _on_enemy_silence_timeout() -> void:
	## After 200ms silence following the enemy impact, play Stem C enemy accent.
	play_stem_c(StemCType.ENEMY)


func _on_music_restore_timeout() -> void:
	## Restore Music bus to saved volume after duck period expires.
	_is_ducked = false
	if _music_bus_idx >= 0:
		var current := AudioServer.get_bus_volume_db(_music_bus_idx)
		var tween := create_tween()
		tween.tween_method(
			func(db: float) -> void: AudioServer.set_bus_volume_db(_music_bus_idx, db),
			current, _saved_ab_volume_db, _STEM_C_RESTORE_SEC
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
