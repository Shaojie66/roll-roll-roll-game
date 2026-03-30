extends Node3D

class_name SlidingDoor

const GridCoordRef = preload("res://src/core/grid/grid_coord.gd")

@export var slide_animation_duration := DesignTokens.DOOR_SLIDE_DURATION

@export var starts_open := false
@export var open_offset := Vector3(0.0, DesignTokens.DOOR_OPEN_OFFSET_Y, 0.0)

var grid_position: Vector2i = Vector2i.ZERO
var blocks_grid_cell := true
var is_open := false

var _grid_motor: Node
var _desired_open := false
var _closed_panel_position := Vector3.ZERO
var _panel_tween: Tween

@onready var door_panel: Node3D = $Visual/DoorPanel
@onready var status_light: OmniLight3D = $Visual/StatusLight

func _ready() -> void:
	add_to_group("grid_entity")
	add_to_group("door")

	grid_position = GridCoordRef.world_to_grid(global_position)
	global_position = GridCoordRef.grid_to_world(grid_position, 0.0)
	_closed_panel_position = door_panel.position
	_desired_open = starts_open

	if starts_open:
		is_open = true
		blocks_grid_cell = false
		_apply_visual_state(true, true)
	else:
		is_open = false
		blocks_grid_cell = true
		_apply_visual_state(false, true)

	## Register synchronously — all entities must be registered before any
	## collision checks fire, otherwise the player can walk through walls/boxes.
	_register_with_grid_motor()
	## Sync door state after all entities in the level have registered.
	## This deferred call runs at the end of the frame, after every entity's
	## _ready() is complete, so the grid motor's occupancy map is stable.
	call_deferred("_sync_door_state")

func _register_with_grid_motor() -> void:
	_grid_motor = get_tree().get_first_node_in_group("grid_motor")
	if _grid_motor != null:
		if _grid_motor.has_signal("entity_move_finished"):
			var callback := Callable(self, "_on_entity_move_finished")
			if not _grid_motor.is_connected("entity_move_finished", callback):
				_grid_motor.connect("entity_move_finished", callback)
		if not _desired_open:
			_grid_motor.register_entity(self)

func _sync_door_state() -> void:
	if _grid_motor == null:
		return
	if _desired_open:
		_open_door(true)
	else:
		_close_door(true)

func set_open(should_open: bool, instant := false) -> void:
	_desired_open = should_open

	if should_open:
		_open_door(instant)
	else:
		_close_door(instant)

func _on_entity_move_finished(_entity: Node, origin: Vector2i, target: Vector2i) -> void:
	if _desired_open:
		return
	if origin == grid_position or target == grid_position:
		_close_door()

func _open_door(instant := false) -> void:
	is_open = true
	blocks_grid_cell = false

	if _grid_motor != null:
		_grid_motor.unregister_entity(self)

	if not instant:
		if AudioManager and AudioManager.has_method('play_door_open'):
		    AudioManager.play_door_open()
	_apply_visual_state(true, instant)

func _close_door(instant := false) -> void:
	if _grid_motor != null:
		var occupant: Node = _grid_motor.get_entity_at(grid_position)
		if occupant != null and occupant != self:
			return

	is_open = false
	blocks_grid_cell = true

	if _grid_motor != null and _grid_motor.get_entity_at(grid_position) != self:
		_grid_motor.register_entity(self)

	if not instant:
		if AudioManager and AudioManager.has_method('play_door_close'):
		    AudioManager.play_door_close()
	_apply_visual_state(false, instant)

func _apply_visual_state(open_state: bool, instant := false) -> void:
	var target_position := _closed_panel_position + (open_offset if open_state else Vector3.ZERO)

	if _panel_tween != null:
		_panel_tween.kill()

	if instant:
		door_panel.position = target_position
	else:
		_panel_tween = create_tween()
		_panel_tween.tween_property(
			door_panel,
			"position",
			target_position,
			slide_animation_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	status_light.light_color = DesignTokens.LIGHT_DOOR_OPEN if open_state else DesignTokens.LIGHT_DOOR_CLOSED
	status_light.light_energy = DesignTokens.LIGHT_DOOR_OPEN_ENERGY if open_state else DesignTokens.LIGHT_DOOR_CLOSED_ENERGY
