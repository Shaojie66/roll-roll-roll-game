extends Node3D

class_name ConveyorTile

## Terrain tile that auto-pushes a RollingBox every DesignTokens.CONVEYOR_INTERVAL seconds.
## The conveyor does not move the player — only boxes.
## Design rule: conveyor tiles are never placed on player-walkable cells.

const GridCoordRef = preload("res://src/core/grid/grid_coord.gd")

const TERRAIN_HEIGHT := 0.0
const DesignTokens.CONVEYOR_INTERVAL := DesignTokens.DesignTokens.CONVEYOR_INTERVAL  ## seconds between auto-pushes

@export var conveyor_direction: Vector2i = Vector2i.RIGHT

var grid_position: Vector2i = Vector2i.ZERO
var _grid_motor: Node
var _box: Node = null
var _is_active := false

signal terrain_activated(box: Node, terrain_type: StringName)

@onready var push_timer: Timer = $PushTimer
@onready var glow_light: OmniLight3D = $GlowLight

func _ready() -> void:
	add_to_group("conveyor_tile")
	add_to_group("terrain_tile")

	grid_position = GridCoordRef.world_to_grid(global_position)
	global_position = GridCoordRef.grid_to_world(grid_position, TERRAIN_HEIGHT)

	push_timer.wait_time = DesignTokens.DesignTokens.CONVEYOR_INTERVAL
	push_timer.timeout.connect(_on_push_timer)

	_bind_grid_motor()
	_apply_visual_state(false)
	_update_arrow_rotation()

func _update_arrow_rotation() -> void:
	## Rotate arrow meshes to point in conveyor direction
	var arrow1 = get_node_or_null("Visual/Arrow1")
	var arrow2 = get_node_or_null("Visual/Arrow2")
	if arrow1 == null or arrow2 == null:
		return
	var yaw := atan2(-conveyor_direction.x, -conveyor_direction.y)
	arrow1.rotation.y = yaw
	arrow2.rotation.y = yaw

func _bind_grid_motor() -> void:
	_grid_motor = get_tree().get_first_node_in_group("grid_motor")
	if _grid_motor != null:
		var callback := Callable(self, "_on_entity_move_finished")
		if not _grid_motor.is_connected("entity_move_finished", callback):
			_grid_motor.connect("entity_move_finished", callback)

func _on_entity_move_finished(entity: Node, origin: Vector2i, target: Vector2i) -> void:
	if not entity.is_in_group("rolling_box"):
		return

	if target == grid_position and origin != grid_position:
		## Box entered this conveyor cell
		_box = entity
		_start_conveyor()
	elif origin == grid_position:
		## Box left this cell — could be moving to adjacent cell
		if _box == entity:
			_box = null
			_stop_conveyor()

func _start_conveyor() -> void:
	if _is_active:
		return
	_is_active = true
	_apply_visual_state(false)
	push_timer.start()

func _stop_conveyor() -> void:
	_is_active = false
	_apply_visual_state(false)
	if push_timer.time_left > 0.0:
		push_timer.stop()

func _on_push_timer() -> void:
	## Check if box is still on this conveyor
	if _box == null:
		_stop_conveyor()
		return

	## Skip if box is mid-roll animation
	if _box.get("is_busy"):
		return

	## Verify box is still at our grid position
	var occupant: Node = null
	if _grid_motor != null:
		occupant = _grid_motor.get_entity_at(grid_position)

	if occupant != _box:
		## Box is gone
		_box = null
		_stop_conveyor()
		return

	## Attempt to push
	if _grid_motor == null:
		return

	var result: bool = _grid_motor.try_push_box(_box, conveyor_direction)
	if result:
		if AudioManager and AudioManager.has_method('play_terrain_sfx'):
			AudioManager.play_terrain_sfx("conveyor")
		terrain_activated.emit(_box, "conveyor")
		## After a successful push, box has moved off this cell.
		## _on_entity_move_finished will fire for origin==grid_position,
		## cleaning up _box and stopping the conveyor.
		## No extra work needed here.
	else:
		## Blocked — try again next tick

func _apply_visual_state(instant: bool = false) -> void:
	if glow_light == null:
		return

	var target_energy := DesignTokens.CONVEYOR_ACTIVE_ENERGY if _is_active else DesignTokens.CONVEYOR_GLOW_ENERGY
	glow_light.light_color = DesignTokens.CONVEYOR_COLOR

	if instant:
		glow_light.light_energy = target_energy
	else:
		var tween := create_tween()
		tween.tween_property(glow_light, "light_energy", target_energy, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
