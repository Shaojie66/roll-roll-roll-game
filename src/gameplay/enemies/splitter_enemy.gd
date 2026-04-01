extends Node3D

class_name SplitterEnemy

## Enemy that splits into 2 SplitterMinion on defeat.
## Minions spawn in cells perpendicular to the defeat direction.

const GridCoordRef = preload("res://src/core/grid/grid_coord.gd")

const ENEMY_HEIGHT := 0.45
const MINION_SCENE := preload("res://src/gameplay/enemies/splitter_minion.tscn")
const MINION_SPAWN_DURATION := 0.3

@export var defeat_duration := DesignTokens.ENEMY_DEFEAT_DURATION
@export var minion_spawn_duration := MINION_SPAWN_DURATION

@export var accepted_face_kinds := PackedStringArray(["IMPACT", "HEAVY"])
@export var enemy_group_name := "splitter_enemy"

var grid_position: Vector2i = Vector2i.ZERO
var blocks_grid_cell := true
var is_defeated := false
var _last_defeat_dir := Vector2i.ZERO

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

	_bind_grid_motor()

func _bind_grid_motor() -> void:
	_grid_motor = get_tree().get_first_node_in_group("grid_motor")
	if _grid_motor != null:
		_grid_motor.register_entity(self)

func can_be_defeated_by(face_kind: String) -> bool:
	return accepted_face_kinds.has(face_kind)

func defeat(direction: Vector2i, face_kind: String) -> void:
	if is_defeated:
		return

	is_defeated = true
	blocks_grid_cell = false
	_last_defeat_dir = direction

	## Death animation
	var launch_offset := Vector3(direction.x * 0.65, 0.65, direction.y * 0.65)
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
		Vector3(deg_to_rad(90.0 * spin_direction), 0.0, 0.0),
		defeat_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		visual,
		"scale",
		Vector3(0.25, 0.25, 0.25),
		defeat_duration
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.finished.connect(_on_death_animation_done)

	if AudioManager and AudioManager.has_method('play_enemy_defeat'):
		AudioManager.play_enemy_defeat()

	defeated.emit()

func _on_death_animation_done() -> void:
	_spawn_minions()
	queue_free()

func _spawn_minions() -> void:
	if _grid_motor == null:
		return
	## Perpendicular to the defeat direction
	var perp := Vector2i(-_last_defeat_dir.y, _last_defeat_dir.x)
	var cell_a := grid_position + perp
	var cell_b := grid_position - perp
	_spawn_minion_at(cell_a)
	_spawn_minion_at(cell_b)

func _spawn_minion_at(target_cell: Vector2i) -> void:
	if _grid_motor == null:
		return

	## Check if cell is empty
	if not _grid_motor.has_method("is_cell_empty"):
		return

	var is_empty := _grid_motor.is_cell_empty(target_cell)
	if not is_empty:
		return

	## Spawn the minion
	var minion = MINION_SCENE.instantiate()
	minion.global_position = GridCoordRef.grid_to_world(target_cell, ENEMY_HEIGHT)
	get_tree().root.add_child(minion)
	minion.grid_position = target_cell
	_grid_motor.register_entity_at(minion, target_cell)
