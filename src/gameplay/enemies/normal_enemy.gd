extends Node3D

class_name NormalEnemy

const GridCoordRef = preload("res://src/core/grid/grid_coord.gd")

const ENEMY_HEIGHT := 0.45
@export var defeat_duration := DesignTokens.ENEMY_DEFEAT_DURATION

@export var accepted_face_kinds := PackedStringArray(["IMPACT", "HEAVY"])
@export var enemy_group_name := "normal_enemy"

var grid_position: Vector2i = Vector2i.ZERO
var blocks_grid_cell := true
var is_defeated := false

signal defeated

var _grid_motor: Node

@onready var visual: Node3D = $Visual
@onready var status_light: OmniLight3D = $Visual/StatusLight

func _ready() -> void:
	add_to_group("grid_entity")
	add_to_group("enemy")
	if enemy_group_name != "":
		add_to_group(enemy_group_name)

	grid_position = GridCoordRef.world_to_grid(global_position)
	global_position = GridCoordRef.grid_to_world(grid_position, ENEMY_HEIGHT)

	## Register synchronously — deferred registration causes a race where the
	## entity is not yet in the grid motor's occupiers map when collision
	## checks run.
	_bind_grid_motor()

	## Self-register defeat sound with AudioManager (replaces global node_added listener).
	if AudioManager and AudioManager.has_method('play_enemy_defeat'):
		if not defeated.is_connected(AudioManager.play_enemy_defeat):
			defeated.connect(AudioManager.play_enemy_defeat)

func can_be_defeated_by(face_kind: String) -> bool:
	return accepted_face_kinds.has(face_kind)

func defeat(direction: Vector2i, face_kind: String) -> void:
	if is_defeated:
		return

	is_defeated = true
	blocks_grid_cell = false

	if _grid_motor != null and _grid_motor.has_method("unregister_entity"):
		_grid_motor.unregister_entity(self)

	var launch_offset := Vector3(direction.x * 0.65, 0.55, direction.y * 0.65)
	var spin_direction := 1.0
	if direction.x < 0 or direction.y < 0:
		spin_direction = -1.0

	status_light.light_color = DesignTokens.LIGHT_ENEMY_DEFEAT_HEAVY if face_kind == "HEAVY" else DesignTokens.LIGHT_ENEMY_DEFEAT_NORMAL
	status_light.light_energy = DesignTokens.LIGHT_ENEMY_DEFEAT_ENERGY

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		self,
		"global_position",
		global_position + launch_offset,
		defeat_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		visual,
		"rotation",
		visual.rotation + Vector3(deg_to_rad(65.0), deg_to_rad(110.0 * spin_direction), 0.0),
		defeat_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		visual,
		"scale",
		Vector3(0.25, 0.25, 0.25),
		defeat_duration
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.finished.connect(queue_free)
	defeated.emit()

func _bind_grid_motor() -> void:
	_grid_motor = get_tree().get_first_node_in_group("grid_motor")
	if _grid_motor != null:
		_grid_motor.register_entity(self)
