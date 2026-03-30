extends Node3D

class_name ShieldEnemy

## Enemy with 1 shield HP. First IMPACT/HEAVY hit breaks the shield.
## Second IMPACT/HEAVY hit kills the enemy.
## While shielded, the box rolls through normally.

const GridCoordRef = preload("res://src/core/grid/grid_coord.gd")

const ENEMY_HEIGHT := 0.45
@export var defeat_duration := DesignTokens.ENEMY_DEFEAT_DURATION
@export var shield_break_duration := 0.25

@export var accepted_face_kinds := PackedStringArray(["IMPACT", "HEAVY"])
@export var enemy_group_name := "shield_enemy"

var grid_position: Vector2i = Vector2i.ZERO
var blocks_grid_cell := true
var is_defeated := false
var shield_hp: int = 1

signal defeated

var _grid_motor: Node

@onready var visual: Node3D = $Visual
@onready var status_light: OmniLight3D = $Visual/StatusLight
@onready var shield_arc: Node3D = $Visual/ShieldArc

func _ready() -> void:
	add_to_group("grid_entity")
	add_to_group("enemy")
	if enemy_group_name != "":
		add_to_group(enemy_group_name)

	grid_position = GridCoordRef.world_to_grid(global_position)
	global_position = GridCoordRef.grid_to_world(grid_position, ENEMY_HEIGHT)

	_bind_grid_motor()

	## Shield starts active
	shield_arc.visible = true
	status_light.light_color = Color(0.494, 0.784, 0.890)  # ice blue

func _bind_grid_motor() -> void:
	_grid_motor = get_tree().get_first_node_in_group("grid_motor")
	if _grid_motor != null:
		_grid_motor.register_entity(self)

func can_be_defeated_by(face_kind: String) -> bool:
	## Shield accepts IMPACT/HEAVY even when intact — it just doesn't die
	return accepted_face_kinds.has(face_kind)

func defeat(direction: Vector2i, face_kind: String) -> void:
	if is_defeated:
		return

	if shield_hp > 0:
		## First hit — break the shield
		shield_hp -= 1
		_break_shield(direction, face_kind)
		return

	## shield_hp == 0 — actual death
	_do_death(direction, face_kind)

func _break_shield(direction: Vector2i, face_kind: String) -> void:
	## Shield flies off
	status_light.light_color = Color(0.3, 0.3, 0.4)  # dimmed

	var shield_fly_offset := Vector3(direction.x * 0.4, 0.8, direction.y * 0.4)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		shield_arc,
		"global_position",
		shield_arc.global_position + shield_fly_offset,
		shield_break_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		shield_arc,
		"rotation",
		shield_arc.rotation + Vector3(0.0, deg_to_rad(180.0), 0.0),
		shield_break_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		shield_arc,
		"scale",
		Vector3(0.1, 0.1, 0.1),
		shield_break_duration
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.finished.connect(_on_shield_broken)

	if AudioManager and AudioManager.has_method('play_enemy_defeat'):
		AudioManager.play_enemy_defeat()

func _on_shield_broken() -> void:
	shield_arc.visible = false

func _do_death(direction: Vector2i, face_kind: String) -> void:
	is_defeated = true
	blocks_grid_cell = false

	var launch_offset := Vector3(direction.x * 0.65, 0.5, direction.y * 0.65)
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
