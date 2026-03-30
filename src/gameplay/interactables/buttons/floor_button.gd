extends Node3D

class_name FloorButton

const GridCoordRef = preload("res://src/core/grid/grid_coord.gd")

const BUTTON_HEIGHT := 0.03
@export var press_offset := Vector3(0.0, DesignTokens.BUTTON_PRESS_OFFSET_Y, 0.0)
@export var press_animation_duration := DesignTokens.BUTTON_PRESS_DURATION

@export var accepted_face_kinds := PackedStringArray(["NORMAL", "IMPACT", "HEAVY", "ENERGY"])
@export var linked_doors: Array[NodePath] = []

var grid_position: Vector2i = Vector2i.ZERO
var is_pressed := false
var _was_pressed := false  ## tracks previous state to detect press/release transitions

var _grid_motor: Node
var _released_plate_position := Vector3.ZERO
var _plate_tween: Tween

@onready var plate: Node3D = $Visual/Plate
@onready var status_light: OmniLight3D = $Visual/StatusLight

func _ready() -> void:
	add_to_group("floor_button")

	grid_position = GridCoordRef.world_to_grid(global_position)
	global_position = GridCoordRef.grid_to_world(grid_position, BUTTON_HEIGHT)
	_released_plate_position = plate.position
	_apply_visual_state(true)

	## Register synchronously — deferred registration causes a race where the
	## entity is not yet in the grid motor's occupiers map when collision
	## checks run.
	_bind_grid_motor()
	## Sync door states after all @onready vars in linked doors are initialized.
	## This deferred call runs at the end of the frame, after every entity's
	## _ready() completes.
	call_deferred("_sync_linked_doors")

func _bind_grid_motor() -> void:
	_grid_motor = get_tree().get_first_node_in_group("grid_motor")
	if _grid_motor != null and _grid_motor.has_signal("entity_move_finished"):
		var callback := Callable(self, "_on_entity_move_finished")
		if not _grid_motor.is_connected("entity_move_finished", callback):
			_grid_motor.connect("entity_move_finished", callback)

	_refresh_state(true)

func _on_entity_move_finished(entity: Node, origin: Vector2i, target: Vector2i) -> void:
	if not entity.is_in_group("rolling_box"):
		return
	if origin == grid_position or target == grid_position:
		_refresh_state()
		_sync_linked_doors()

func _refresh_state(force_visual_refresh := false) -> void:
	var occupant: Node = null
	if _grid_motor != null:
		occupant = _grid_motor.get_entity_at(grid_position)

	var next_pressed := _can_press(occupant)
	if next_pressed == is_pressed and not force_visual_refresh:
		return

	## Detect press/release transitions for audio feedback.
	var was_pressed := is_pressed
	is_pressed = next_pressed

	if was_pressed and not is_pressed:
		## Box left the button.
		if AudioManager and AudioManager.has_method('play_button_release'):
			AudioManager.play_button_release()
		if AudioManager and AudioManager.has_method('stop_button_hum'):
			AudioManager.stop_button_hum()
	elif is_pressed and not was_pressed:
		## Box landed on the button.
		if AudioManager and AudioManager.has_method('play_button_press'):
			AudioManager.play_button_press()
		if AudioManager and AudioManager.has_method('start_button_hum'):
			AudioManager.start_button_hum()

	_apply_visual_state(force_visual_refresh)

func _can_press(occupant: Node) -> bool:
	if occupant == null or not occupant.is_in_group("rolling_box"):
		return false
	if not occupant.has_method("current_face_kind"):
		return false

	var face_kind: String = occupant.current_face_kind()
	return accepted_face_kinds.is_empty() or accepted_face_kinds.has(face_kind)

func _sync_linked_doors() -> void:
	for door_path in linked_doors:
		var door := get_node_or_null(door_path)
		if door != null and door.has_method("set_open"):
			door.set_open(is_pressed)

func _apply_visual_state(instant := false) -> void:
	var target_position := _released_plate_position
	if is_pressed:
		target_position += press_offset

	if _plate_tween != null:
		_plate_tween.kill()

	if instant:
		plate.position = target_position
	else:
		_plate_tween = create_tween()
		_plate_tween.tween_property(
			plate,
			"position",
			target_position,
			press_animation_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	status_light.light_color = DesignTokens.LIGHT_BUTTON_ON if is_pressed else DesignTokens.LIGHT_BUTTON_OFF
	status_light.light_energy = 1.15 if is_pressed else 0.4
