extends Node3D

class_name Player

const GridCoordRef = preload("res://src/core/grid/grid_coord.gd")

@export var move_duration := DesignTokens.PLAYER_MOVE_DURATION
const PLAYER_HEIGHT := 0.75

var grid_position: Vector2i = Vector2i.ZERO
var is_busy := false
var input_enabled := true
var can_push_boxes := true
var blocks_grid_cell := true

var _grid_motor: Node
var _previous_grid_position: Vector2i = Vector2i.ZERO
var _deny_tween: Tween
var _grid_motor_connected := false
var _marker_ring_mat: StandardMaterial3D
var _bob_time := 0.0

## Original body material colors for restore after deny flash.
var _body_mat: StandardMaterial3D
var _original_body_albedo: Color
var _original_body_emission: Color

signal deny_feedback_requested(reason: String)

@onready var visual: Node3D = $Visual
@onready var body: MeshInstance3D = $Visual/Body
@onready var marker_ring: MeshInstance3D = $Visual/MarkerRing

func _ready() -> void:
	add_to_group("grid_entity")
	add_to_group("player")

	grid_position = GridCoordRef.world_to_grid(global_position)
	global_position = GridCoordRef.grid_to_world(grid_position, PLAYER_HEIGHT)
	_previous_grid_position = grid_position

	## Duplicate body material so the deny-flash tween can modify it without
	## affecting other players or the scene's shared resource.
	var raw_mat := body.get_active_material(0)
	if raw_mat is StandardMaterial3D:
		_body_mat = raw_mat.duplicate()
		body.set_surface_override_material(0, _body_mat)
		_original_body_albedo = _body_mat.albedo_color
		_original_body_emission = _body_mat.emission

	## Duplicate marker ring material for pulse animation.
	var ring_raw_mat := marker_ring.get_active_material(0)
	if ring_raw_mat is StandardMaterial3D:
		_marker_ring_mat = ring_raw_mat.duplicate()
		marker_ring.set_surface_override_material(0, _marker_ring_mat)
		_start_marker_ring_pulse()

	## Bind synchronously so the main scene's input router always sees the
	## player registered in the grid before the first movement input lands.
	_bind_grid_motor()

func move_to_cell(target: Vector2i, direction: Vector2i) -> void:
	is_busy = true
	_previous_grid_position = grid_position
	grid_position = target
	rotation.y = GridCoordRef.facing_yaw(direction)

	var tween := create_tween()
	tween.tween_property(
		self,
		"global_position",
		GridCoordRef.grid_to_world(grid_position, PLAYER_HEIGHT),
		move_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_on_move_finished)

func _on_move_finished() -> void:
	is_busy = false
	if _grid_motor != null and _grid_motor.has_method("notify_entity_move_finished"):
		_grid_motor.notify_entity_move_finished(self, _previous_grid_position, grid_position)
	if AudioManager and AudioManager.has_method('play_player_step'):
		AudioManager.play_player_step()

func _on_move_denied(actor: Node, reason: String) -> void:
	if actor != self:
		return
	_show_deny_feedback(reason)

func _show_deny_feedback(reason: String) -> void:
	emit_signal("deny_feedback_requested", reason)
	## Brief red flash on the body material to reinforce the denial.
	if _deny_tween != null:
		_deny_tween.kill()
	if _body_mat == null:
		return
	_deny_tween = create_tween()
	_body_mat.albedo_color = DesignTokens.DENY_FLASH_ALBEDO
	_body_mat.emission = DesignTokens.DENY_FLASH_EMISSION
	_body_mat.emission_energy_multiplier = 1.2
	_deny_tween.tween_method(
		_restore_body_material.bind(_original_body_albedo, _original_body_emission),
		0.0, 1.0, 0.25
	)

func _restore_body_material(_t: float, albedo: Color, emission: Color) -> void:
	if _body_mat == null:
		return
	_body_mat.albedo_color = albedo
	_body_mat.emission = emission
	_body_mat.emission_energy_multiplier = 0.28

func _bind_grid_motor() -> void:
	_grid_motor = get_tree().get_first_node_in_group("grid_motor")
	if _grid_motor != null:
		_grid_motor.register_entity(self)
		if not _grid_motor_connected:
			_grid_motor.connect("move_denied", _on_move_denied)
			_grid_motor_connected = true

func _process(delta: float) -> void:
	## Idle bobbing: sine wave on the Visual node, ±0.04 units, 1.5s period.
	## The Visual node is parented to the Player, so this bobs the entire
	## character mesh without affecting global_position (movement tweens use
	## global_position directly, so the bob is purely visual).
	_bob_time += delta
	visual.position.y = sin(_bob_time * TAU / 1.5) * 0.04


func _exit_tree() -> void:
	## Clean up duplicated material to prevent memory leaks
	if _body_mat != null:
		_body_mat = null

func _start_marker_ring_pulse() -> void:
	if _marker_ring_mat == null:
		return
	## Pulse emission energy between 1.0 and 1.6 over 1.2s, looping forever.
	_marker_ring_mat.emission_energy_multiplier = 1.0
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(_marker_ring_mat, "emission_energy_multiplier", 1.6, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_marker_ring_mat, "emission_energy_multiplier", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
