extends Node3D

class_name GoalPad

const GridCoordRef = preload("res://src/core/grid/grid_coord.gd")

const GOAL_HEIGHT := 0.03
const ANIMATION_DURATION := 0.16

@export var requires_external_power := false

var grid_position: Vector2i = Vector2i.ZERO
var is_active := false
var is_powered := true

var _grid_motor: Node
var _ring_tween: Tween

@onready var ring: Node3D = $Visual/Ring
@onready var status_light: OmniLight3D = $Visual/StatusLight

func _ready() -> void:
	add_to_group("goal_pad")

	grid_position = GridCoordRef.world_to_grid(global_position)
	global_position = GridCoordRef.grid_to_world(grid_position, GOAL_HEIGHT)
	is_powered = not requires_external_power
	_apply_visual_state(true)

	## Register synchronously — deferred registration causes a race where the
	## entity is not yet in the grid motor's occupiers map when collision
	## checks run.
	_bind_grid_motor()

func _bind_grid_motor() -> void:
	_grid_motor = get_tree().get_first_node_in_group("grid_motor")
	if _grid_motor != null and _grid_motor.has_signal("entity_move_finished"):
		var callback := Callable(self, "_on_entity_move_finished")
		if not _grid_motor.is_connected("entity_move_finished", callback):
			_grid_motor.connect("entity_move_finished", callback)

func _on_entity_move_finished(entity: Node, _origin: Vector2i, target: Vector2i) -> void:
	if target != grid_position:
		return
	if not entity.is_in_group("player"):
		return
	if requires_external_power and not is_powered:
		return

	_activate_goal()

func set_powered(powered: bool) -> void:
	if is_powered == powered:
		return

	is_powered = powered
	if not is_active:
		_apply_visual_state()

func _activate_goal() -> void:
	if is_active:
		return

	is_active = true
	_apply_visual_state()

	var level_root := get_tree().get_first_node_in_group("level_root")
	if level_root != null and level_root.has_method("complete_level"):
		level_root.complete_level()

func _apply_visual_state(instant := false) -> void:
	var target_scale := Vector3.ONE
	var light_color := Color(0.62, 0.78, 1.0, 1.0)
	var light_energy := 0.8

	if is_active:
		target_scale = Vector3(1.25, 1.0, 1.25)
		light_color = Color(0.58, 0.96, 1.0, 1.0)
		light_energy = 1.5
	elif requires_external_power and not is_powered:
		target_scale = Vector3(0.82, 1.0, 0.82)
		light_color = Color(0.36, 0.42, 0.54, 1.0)
		light_energy = 0.18

	if _ring_tween != null:
		_ring_tween.kill()

	if instant:
		ring.scale = target_scale
	else:
		_ring_tween = create_tween()
		_ring_tween.tween_property(
			ring,
			"scale",
			target_scale,
			ANIMATION_DURATION
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	status_light.light_color = light_color
	status_light.light_energy = light_energy
