extends Node3D

class_name RampTile

## Terrain tile that rotates a RollingBox's face orientation when the box
## rolls onto it. The ramp does not move the box — only transforms its face.

const GridCoordRef = preload("res://src/core/grid/grid_coord.gd")

const TERRAIN_HEIGHT := 0.0
@export var direction: Vector2i = Vector2i.RIGHT  ## Cardinal direction of the ramp

var grid_position: Vector2i = Vector2i.ZERO
var _grid_motor: Node
var _is_active := false

signal terrain_activated(box: Node, terrain_type: StringName)

@onready var glow_light: OmniLight3D = $GlowLight

func _ready() -> void:
	add_to_group("ramp_tile")
	add_to_group("terrain_tile")

	grid_position = GridCoordRef.world_to_grid(global_position)
	global_position = GridCoordRef.grid_to_world(grid_position, TERRAIN_HEIGHT)

	_bind_grid_motor()
	_apply_visual_state(false)
	_update_dir_pillar()

func _update_dir_pillar() -> void:
	## Rotate direction pillar to point in ramp direction
	var pillar = get_node_or_null("Visual/DirPillar")
	if pillar == null:
		return
	var yaw := atan2(-direction.x, -direction.y)
	pillar.rotation.y = yaw

func _bind_grid_motor() -> void:
	_grid_motor = get_tree().get_first_node_in_group("grid_motor")
	if _grid_motor != null:
		var callback := Callable(self, "_on_entity_move_finished")
		if not _grid_motor.is_connected("entity_move_finished", callback):
			_grid_motor.connect("entity_move_finished", callback)

func _on_entity_move_finished(entity: Node, origin: Vector2i, target: Vector2i) -> void:
	if not entity.is_in_group("rolling_box"):
		return

	## Box entering this ramp cell
	if target == grid_position and origin != grid_position:
		_apply_ramp_transform(entity, target - origin)

	## Update active state on enter or leave
	_update_active_state()

func _apply_ramp_transform(box: Node, roll_direction: Vector2i) -> void:
	if not box.has_method("apply_ramp_transform"):
		push_warning("RampTile: box has no apply_ramp_transform — skipping")
		return

	box.apply_ramp_transform(roll_direction)
	terrain_activated.emit(box, "ramp")
	if AudioManager and AudioManager.has_method('play_terrain_sfx'):
	    AudioManager.play_terrain_sfx("ramp_activate")

func _update_active_state() -> void:
	var occupant: Node = null
	if _grid_motor != null:
		occupant = _grid_motor.get_entity_at(grid_position)

	var next_active := occupant != null and occupant.is_in_group("rolling_box")
	if next_active == _is_active:
		return

	_is_active = next_active
	_apply_visual_state(false)

func _apply_visual_state(instant: bool = false) -> void:
	if glow_light == null:
		return

	var target_energy := DesignTokens.RAMP_ACTIVE_ENERGY if _is_active else DesignTokens.RAMP_GLOW_ENERGY
	glow_light.light_color = DesignTokens.RAMP_COLOR

	if instant:
		glow_light.light_energy = target_energy
	else:
		var tween := create_tween()
		tween.tween_property(glow_light, "light_energy", target_energy, DesignTokens.TERRAIN_GLOW_TWEEN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
