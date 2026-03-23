extends Node3D

class_name EnergySocket

const GridCoordRef = preload("res://src/core/grid/grid_coord.gd")

const SOCKET_HEIGHT := 0.03
const ANIMATION_DURATION := 0.14

@export var accepted_face_kinds := PackedStringArray(["ENERGY"])
@export var linked_doors: Array[NodePath] = []
@export var linked_goals: Array[NodePath] = []

var grid_position: Vector2i = Vector2i.ZERO
var is_powered := false

var _grid_motor: Node
var _core_tween: Tween

@onready var core: Node3D = $Visual/Core
@onready var status_light: OmniLight3D = $Visual/StatusLight

func _ready() -> void:
	add_to_group("energy_socket")

	grid_position = GridCoordRef.world_to_grid(global_position)
	global_position = GridCoordRef.grid_to_world(grid_position, SOCKET_HEIGHT)
	_apply_visual_state(true)

	call_deferred("_bind_grid_motor")

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

func _refresh_state(force_visual_refresh := false) -> void:
	var occupant: Node = null
	if _grid_motor != null:
		occupant = _grid_motor.get_entity_at(grid_position)

	var next_powered := _can_power(occupant)
	if next_powered == is_powered and not force_visual_refresh:
		_sync_links()
		return

	is_powered = next_powered
	_apply_visual_state(force_visual_refresh)
	_sync_links()

func _can_power(occupant: Node) -> bool:
	if occupant == null or not occupant.is_in_group("rolling_box"):
		return false
	if not occupant.has_method("current_face_kind"):
		return false

	var face_kind: String = occupant.current_face_kind()
	return accepted_face_kinds.is_empty() or accepted_face_kinds.has(face_kind)

func _sync_links() -> void:
	for door_path in linked_doors:
		var door := get_node_or_null(door_path)
		if door != null and door.has_method("set_open"):
			door.set_open(is_powered)

	for goal_path in linked_goals:
		var goal := get_node_or_null(goal_path)
		if goal != null and goal.has_method("set_powered"):
			goal.set_powered(is_powered)

func _apply_visual_state(instant := false) -> void:
	var target_scale := Vector3(1.18, 1.18, 1.18) if is_powered else Vector3.ONE

	if _core_tween != null:
		_core_tween.kill()

	if instant:
		core.scale = target_scale
	else:
		_core_tween = create_tween()
		_core_tween.tween_property(
			core,
			"scale",
			target_scale,
			ANIMATION_DURATION
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	status_light.light_color = Color(0.48, 0.98, 1.0, 1.0) if is_powered else Color(0.32, 0.44, 0.54, 1.0)
	status_light.light_energy = 1.2 if is_powered else 0.18
