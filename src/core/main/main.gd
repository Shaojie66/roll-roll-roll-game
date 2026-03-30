extends Node

const LEVEL_SEQUENCE := [
	preload("res://src/levels/tutorial/level_01.tscn"),
	preload("res://src/levels/tutorial/level_02.tscn"),
	preload("res://src/levels/tutorial/level_03.tscn"),
	preload("res://src/levels/tutorial/level_04.tscn"),
	preload("res://src/levels/tutorial/level_05.tscn"),
]
const LEVEL_PRESENTATION := [
	{
		"kicker": "教程 01 / 05",
		"title": "滚动入门",
		"subtitle": "推动箱子，看它滚动后顶面会变化。",
		"star3_max": 6,
		"star2_max": 10,
	},
	{
		"kicker": "教程 02 / 05",
		"title": "按钮占位",
		"subtitle": "圆形按钮需要持续压住，门不会自动永久开启。",
		"star3_max": 8,
		"star2_max": 14,
	},
	{
		"kicker": "教程 03 / 05",
		"title": "冲击与重压",
		"subtitle": "不是所有顶面都能打穿敌人，先看状态再动手。",
		"star3_max": 10,
		"star2_max": 16,
	},
	{
		"kicker": "教程 04 / 05",
		"title": "门与按钮",
		"subtitle": "用箱子压住按钮开门，然后穿过门走到终点。",
		"star3_max": 12,
		"star2_max": 18,
	},
	{
		"kicker": "教程 05 / 05",
		"title": "一箱三用",
		"subtitle": "一个箱子，三份工作：先开门，再打掉机器人，最后把能源面送到发光的终端上。",
		"star3_max": 16,
		"star2_max": 24,
	},
]
const CONTROL_HINT_TEXT := "移动  W A S D / 方向键\n重开  R"
const INPUT_ACTIONS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"restart_level": [KEY_R],
	"toggle_pause": [KEY_ESCAPE],
}

@onready var world: Node3D = $World
@onready var level_kicker_label: Label = %LevelKickerLabel
@onready var level_title_label: Label = %LevelTitleLabel
@onready var level_subtitle_label: Label = %LevelSubtitleLabel
@onready var controls_label: Label = %ControlsLabel
@onready var hint_label: Label = %HintLabel

## Pause overlay nodes
@onready var pause_overlay: CanvasLayer = $PauseOverlay
@onready var pause_darken: ColorRect = $PauseOverlay/DarkenBg
@onready var pause_card: PanelContainer = %PauseCard
@onready var pause_resume_btn: Button = %ResumeButton
@onready var pause_restart_btn: Button = %RestartButton
@onready var pause_quit_btn: Button = %QuitButton

## Level-complete overlay nodes
@onready var complete_overlay: CanvasLayer = $LevelCompleteOverlay
@onready var complete_darken: ColorRect = $LevelCompleteOverlay/DarkenBg
@onready var complete_card: PanelContainer = %CompleteCard
@onready var complete_kicker: Label = %LevelKicker
@onready var complete_title: Label = %CompleteTitle
@onready var complete_moves: Label = %MoveCount
@onready var complete_star1: Label = %Star1
@onready var complete_star2: Label = %Star2
@onready var complete_star3: Label = %Star3
@onready var complete_button_row: HBoxContainer = %ButtonRow
@onready var complete_next_btn: Button = %NextButton
@onready var complete_replay_btn: Button = %ReplayButton
@onready var complete_select_btn: Button = %SelectButton

var _current_level_index := 0
var _active_level: Node
var _deny_restore_timer := 0.0
var _deny_restore_delay := 2.0
var _stored_hint := ""
var _player_deny_connected := false
var _deny_feedback_active := false
var _hint_tween: Tween

## Guards against double-fire on rapid input during animations
var _is_animating_out := false

func _ready() -> void:
	_ensure_input_actions()
	controls_label.text = CONTROL_HINT_TEXT

	# Connect pause overlay button signals
	pause_resume_btn.pressed.connect(_on_pause_resume_pressed)
	pause_restart_btn.pressed.connect(_on_pause_restart_pressed)
	pause_quit_btn.pressed.connect(_on_pause_quit_pressed)

	# Connect level-complete overlay button signals
	complete_next_btn.pressed.connect(_on_complete_next_pressed)
	complete_replay_btn.pressed.connect(_on_complete_replay_pressed)
	complete_select_btn.pressed.connect(_on_complete_select_pressed)

	# Hide post-MVP screens that aren't implemented yet so players
	# don't hit dead-end stub messages during playtesting.
	complete_select_btn.visible = false

	# Start with overlays hidden
	pause_overlay.visible = false
	complete_overlay.visible = false

	_load_level(_current_level_index)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("restart_level"):
			if not _is_animating_out and not get_tree().paused:
				_load_level(_current_level_index)
			get_viewport().set_input_as_handled()
			return

		if event.is_action_pressed("toggle_pause"):
			get_viewport().set_input_as_handled()
			# ESC closes level-complete overlay first, then toggles pause
			if complete_overlay.visible and not _is_animating_out:
				_hide_level_complete_overlay()
				return
			if get_tree().paused:
				_hide_pause_overlay()
			else:
				_show_pause_overlay()
			return

		## Route directional input to the player from here so the Camera3D
		## in the level scene can't intercept it.
		## Respect input_enabled so that level completion (which sets it to false)
		## actually prevents further movement through this path.
		if _active_level != null and not get_tree().paused:
			var player := _active_level.get_node_or_null("Player")
			if player != null and player.get("input_enabled") != false:
				var direction := _direction_from_key_event(event)
				if direction != Vector2i.ZERO:
					var grid_motor := _active_level.get_node_or_null("GridMotor")
					if grid_motor != null and grid_motor.has_method("try_move_actor"):
						grid_motor.try_move_actor(player, direction)

func _direction_from_key_event(event: InputEventKey) -> Vector2i:
	match event.physical_keycode:
		KEY_W, KEY_UP:
			return Vector2i.UP
		KEY_S, KEY_DOWN:
			return Vector2i.DOWN
		KEY_A, KEY_LEFT:
			return Vector2i.LEFT
		KEY_D, KEY_RIGHT:
			return Vector2i.RIGHT
	return Vector2i.ZERO

func _process(delta: float) -> void:
	if _deny_restore_timer > 0.0:
		_deny_restore_timer -= delta
		if _deny_restore_timer <= 0.0 and _stored_hint != "":
			hint_label.text = _stored_hint

func _load_level(level_index: int) -> void:
	if level_index < 0 or level_index >= LEVEL_SEQUENCE.size():
		return

	_current_level_index = level_index
	_deny_restore_timer = 0.0
	_player_deny_connected = false
	_update_level_hud()
	hint_label.text = "目标加载中..."

	if _active_level != null:
		_active_level.queue_free()
		_active_level = null

	var level: Node = LEVEL_SEQUENCE[_current_level_index].instantiate()
	if level.has_signal("hint_requested"):
		level.connect("hint_requested", Callable(self, "_set_hint_text"))
	if level.has_signal("level_completed"):
		level.connect("level_completed", Callable(self, "_on_level_completed"))

	_try_connect_player_deny_signal(level)

	# Reset move counter for the fresh level
	var grid_motor := level.get_node_or_null("GridMotor")
	if grid_motor != null and grid_motor.has_method("reset_move_count"):
		grid_motor.reset_move_count()

	world.add_child(level)
	_active_level = level

func _set_hint_text(text: String) -> void:
	_stored_hint = text
	if _deny_restore_timer <= 0.0:
		if _hint_tween != null and _hint_tween.is_valid():
			_hint_tween.kill()
		_hint_tween = create_tween()
		_hint_tween.tween_property(hint_label, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_hint_tween.tween_callback(func(): hint_label.text = text)
		_hint_tween.tween_property(hint_label, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _try_connect_player_deny_signal(level: Node) -> void:
	if _player_deny_connected:
		return
	var player := level.get_node_or_null("Player")
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if player != null and player.has_signal("deny_feedback_requested"):
		player.connect("deny_feedback_requested", _on_player_deny_feedback)
		_player_deny_connected = true

func _on_player_deny_feedback(reason: String) -> void:
	_deny_restore_timer = _deny_restore_delay
	hint_label.text = "[ %s ]" % reason
	AudioManager.play_move_denied()

	if _deny_feedback_active:
		return
	_deny_feedback_active = true

	## Layer 2: flash ObjectiveCard border red for 0.15s
	var obj_card := %ObjectiveCard
	var obj_style: StyleBoxFlat = obj_card.get_theme_stylebox("panel")
	var saved_border_color := obj_style.border_color
	obj_style.border_color = Color(1.0, 0.35, 0.35, 0.9)
	await get_tree().create_timer(0.15).timeout
	obj_style.border_color = saved_border_color

	## Layer 4: tint hint label red for 0.4s
	var saved_hint_modulate := hint_label.modulate
	hint_label.modulate = Color(1.0, 0.7, 0.7)
	await get_tree().create_timer(0.4).timeout
	hint_label.modulate = saved_hint_modulate
	_deny_feedback_active = false

func _on_level_completed() -> void:
	_set_hint_text("本关完成！")
	## Play level-complete fanfare. Star count is computed from move_count in the overlay.
	var move_count := 0
	var grid_motor := _active_level.get_node_or_null("GridMotor")
	if grid_motor != null and grid_motor.has_method("get_move_count"):
		move_count = grid_motor.get_move_count()
	AudioManager.play_level_complete(move_count, _star_count_for_moves(move_count))
	await get_tree().create_timer(0.6).timeout
	_show_level_complete_overlay()

## ─── Level-complete overlay ──────────────────────────────────────────────────

func _show_level_complete_overlay() -> void:
	if _active_level == null:
		return

	var is_last_level := _current_level_index == LEVEL_SEQUENCE.size() - 1
	var move_count := 0
	var grid_motor := _active_level.get_node_or_null("GridMotor")
	if grid_motor != null and grid_motor.has_method("get_move_count"):
		move_count = grid_motor.get_move_count()

	complete_moves.text = "步数: %d" % move_count

	if is_last_level:
		complete_kicker.text = "教程 05 / 05"
		complete_title.text = "教程已完成！"
		complete_replay_btn.text = "再玩一次"
		# Apply gold-filled button style using design token
		var gold_style := StyleBoxFlat.new()
		gold_style.bg_color = Color(DesignTokens.ACCENT_GOLD_STAR, 0.95)
		gold_style.border_color = DesignTokens.ACCENT_GOLD_STAR
		gold_style.border_width_left = 2
		gold_style.border_width_top = 2
		gold_style.border_width_right = 2
		gold_style.border_width_bottom = 2
		gold_style.corner_radius_top_left = 12
		gold_style.corner_radius_top_right = 12
		gold_style.corner_radius_bottom_right = 12
		gold_style.corner_radius_bottom_left = 12
		complete_replay_btn.remove_theme_stylebox_override("normal")
		complete_replay_btn.add_theme_stylebox_override("normal", gold_style)
	else:
		var pres: Dictionary = LEVEL_PRESENTATION[_current_level_index]
		complete_kicker.text = str(pres.get("kicker", ""))
		complete_title.text = "本关完成！"
		complete_replay_btn.text = "重玩本关"
		complete_replay_btn.remove_theme_stylebox_override("normal")

	complete_overlay.visible = true
	complete_card.modulate = Color(1, 1, 1, 0)
	complete_card.scale = Vector2(0.85, 0.85)
	complete_darken.modulate.a = 0.0
	complete_button_row.modulate.a = 0.0
	for star: Label in [complete_star1, complete_star2, complete_star3]:
		star.scale = Vector2.ZERO

	# Darken + card open: DarkenBg 0→0.60 over 250ms, card scale 0.85→1.0 + alpha 0→1 over 350ms ease-out-back
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(complete_darken, "modulate:a", 0.60, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(complete_card, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(complete_card, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Stars after card settles (~430ms total = 80ms delay + 350ms)
	await get_tree().create_timer(0.43).timeout
	_animate_star(complete_star1, 0.0)
	_animate_star(complete_star2, 0.08)
	_animate_star(complete_star3, 0.16)

	# Button row fades in at ~770ms (430ms + 340ms)
	await get_tree().create_timer(0.34).timeout
	var btn_tween := create_tween()
	btn_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	btn_tween.tween_property(complete_button_row, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	complete_next_btn.grab_focus()

func _animate_star(star: Label, delay: float) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(star, "scale", Vector2(1.15, 1.15), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(star, "scale", Vector2(1.0, 1.0), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _hide_level_complete_overlay() -> void:
	if _is_animating_out:
		return
	_is_animating_out = true

	# Close: card alpha 1→0 + scale 1→0.92 over 250ms ease-in; darken 0.60→0 over 250ms ease-in
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(complete_card, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(complete_card, "scale", Vector2(0.92, 0.92), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(complete_darken, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished

	complete_overlay.visible = false
	_is_animating_out = false

func _on_complete_next_pressed() -> void:
	if _is_animating_out:
		return
	# Loop to level 1 when on last level
	var next_idx := _current_level_index + 1
	if next_idx >= LEVEL_SEQUENCE.size():
		next_idx = 0
	_hide_level_complete_overlay()
	await get_tree().create_timer(0.30).timeout
	_load_level(next_idx)

func _on_complete_replay_pressed() -> void:
	if _is_animating_out:
		return
	_hide_level_complete_overlay()
	await get_tree().create_timer(0.30).timeout
	_load_level(_current_level_index)

func _on_complete_select_pressed() -> void:
	if _is_animating_out:
		return
	_hide_level_complete_overlay()
	await get_tree().create_timer(0.30).timeout
	_set_hint_text("选择关卡功能开发中")

## ─── Pause overlay ───────────────────────────────────────────────────────────

func _show_pause_overlay() -> void:
	pause_overlay.visible = true
	pause_card.modulate = Color(1, 1, 1, 0)
	pause_card.scale = Vector2(0.88, 0.88)
	pause_darken.modulate.a = 0.0
	get_tree().paused = true
	AudioManager.play_pause_open()

	# Open: DarkenBg alpha 0→0.55 over 200ms ease-out; Card scale 0.88→1.0 + alpha 0→1 over 300ms ease-out-back
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(pause_darken, "modulate:a", 0.55, 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(pause_card, "modulate:a", 1.0, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(pause_card, "scale", Vector2(1.0, 1.0), 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await tween.finished
	pause_resume_btn.grab_focus()

func _hide_pause_overlay() -> void:
	if _is_animating_out:
		return
	_is_animating_out = true

	# Close: card alpha 1→0 + scale 1→0.92 over 250ms ease-in; DarkenBg alpha 0.55→0 over 250ms ease-in
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(pause_card, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(pause_card, "scale", Vector2(0.92, 0.92), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(pause_darken, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished

	pause_overlay.visible = false
	get_tree().paused = false
	_is_animating_out = false

func _on_pause_resume_pressed() -> void:
	AudioManager.play_pause_close()
	_hide_pause_overlay()

func _on_pause_restart_pressed() -> void:
	var idx_to_restart := _current_level_index
	_hide_pause_overlay()
	await get_tree().create_timer(0.30).timeout
	_load_level(idx_to_restart)

func _on_pause_quit_pressed() -> void:
	_hide_pause_overlay()
	await get_tree().create_timer(0.30).timeout
	get_tree().quit()

## ─── HUD helpers ─────────────────────────────────────────────────────────────

func _update_level_hud() -> void:
	if _current_level_index < 0 or _current_level_index >= LEVEL_PRESENTATION.size():
		level_kicker_label.text = "原型"
		level_title_label.text = "未命名关卡"
		level_subtitle_label.text = ""
		return

	var presentation: Dictionary = LEVEL_PRESENTATION[_current_level_index]
	level_kicker_label.text = str(presentation.get("kicker", "原型"))
	level_title_label.text = str(presentation.get("title", "未命名关卡"))
	level_subtitle_label.text = str(presentation.get("subtitle", ""))
	_animate_level_card_in()

## Returns 1-3 stars based on move count. Thresholds are per-level in LEVEL_PRESENTATION.
func _star_count_for_moves(moves: int) -> int:
	var pres: Dictionary = {}
	if _current_level_index >= 0 and _current_level_index < LEVEL_PRESENTATION.size():
		pres = LEVEL_PRESENTATION[_current_level_index]
	var star3_max: int = pres.get("star3_max", 10)
	var star2_max: int = pres.get("star2_max", 15)
	if moves <= star3_max:
		return 3
	elif moves <= star2_max:
		return 2
	else:
		return 1


func _animate_level_card_in() -> void:
	var card: PanelContainer = %LevelCard
	card.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	## position.y animation omitted — LevelCard is a child of HBoxContainer which
	## overwrites position every frame, so the tween target would be clobbered.
	## Fade-only is safe and achieves the card-entry effect without layout conflict.

func _ensure_input_actions() -> void:
	for action_name in INPUT_ACTIONS.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)

		if not InputMap.action_get_events(action_name).is_empty():
			continue

		var keycodes: Array = INPUT_ACTIONS[action_name]
		for keycode_variant in keycodes:
			InputMap.action_add_event(action_name, _make_key_event(keycode_variant))

func _make_key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	return event
