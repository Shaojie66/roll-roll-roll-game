extends Node3D

class_name RotatingPlatformTile

## Terrain tile that rotates a RollingBox 90° clockwise each time the box
## enters the tile. Does not move the box — only rotates its face orientation.

const GridCoordRef = preload("res://src/core/grid/grid_coord.gd")

const TERRAIN_HEIGHT := 0.0

var grid_position: Vector2i = Vector2i.ZERO
var _grid_motor: Node
var _is_active := false

signal terrain_activated(box: Node, terrain_type: StringName)

@onready var glow_light: OmniLight3D = $GlowLight

func _ready() -> void:
	add_to_group("rotating_platform_tile")
	add_to_group("terrain_tile")

	grid_position = GridCoordRef.world_to_grid(global_position)
	global_position = GridCoordRef.grid_to_world(grid_position, TERRAIN_HEIGHT)

	_bind_grid_motor()
	_apply_visual_state(false)

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
		_apply_rotation(entity)

	_update_active_state()

func _apply_rotation(box: Node) -> void:
	if not box.has_method("apply_rotation"):
		push_warning("RotatingPlatformTile: box has no apply_rotation — skipping")
		return

	box.apply_rotation()
	if AudioManager and AudioManager.has_method('play_terrain_sfx'):
		AudioManager.play_terrain_sfx("rotating_platform")
	terrain_activated.emit(box, "rotating_platform")
	_do_rotation_animation()

func _update_active_state() -> void:
	var occupant: Node = null
	if _grid_motor != null:
		occupant = _grid_motor.get_entity_at(grid_position)

	var next_active := occupant != null and occupant.is_in_group("rolling_box")
	if next_active == _is_active:
		return

	_is_active = next_active
	_apply_visual_state(false)

func _do_rotation_animation() -> void:
	## Animate the visual body rotating 90° clockwise when box enters
	var visual = get_node_or_null("Visual")
	if visual == null:
		return
	var tween := create_tween()
	tween.tween_property(visual, "rotation:y", visual.rotation.y + deg_to_rad(90.0), DesignTokens.ROTATION_ANIM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _apply_visual_state(instant: bool = false) -> void:
	if glow_light == null:
		return

	var target_energy := DesignTokens.ROTATING_ACTIVE_ENERGY if _is_active else DesignTokens.ROTATING_GLOW_ENERGY
	glow_light.light_color = DesignTokens.ROTATING_COLOR

	if instant:
		glow_light.light_energy = target_energy
	else:
		var tween := create_tween()
		tween.tween_property(glow_light, "light_energy", target_energy, DesignTokens.TERRAIN_GLOW_TWEEN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
