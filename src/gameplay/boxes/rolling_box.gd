extends Node3D

class_name RollingBox

const GridCoordRef = preload("res://src/core/grid/grid_coord.gd")

enum FaceId {
	NORMAL_A,
	NORMAL_B,
	IMPACT_A,
	IMPACT_B,
	HEAVY,
	ENERGY,
}

const ROLL_DURATION := 0.22
const BOX_HEIGHT := 0.5
const FACE_VISUALS := {
	"NORMAL": {
		"label_color": Color(1.0, 0.96, 0.84, 1.0),
		"body_color": Color(0.956863, 0.701961, 0.247059, 1.0),
		"label_text": "● 普通",
	},
	"IMPACT": {
		"label_color": Color(1.0, 0.86, 0.78, 1.0),
		"body_color": Color(0.968627, 0.486275, 0.345098, 1.0),
		"label_text": "◆ 冲击",
	},
	"HEAVY": {
		"label_color": Color(1.0, 0.96, 0.82, 1.0),
		"body_color": Color(0.886275, 0.372549, 0.223529, 1.0),
		"label_text": "■ 重压",
	},
	"ENERGY": {
		"label_color": Color(0.88, 0.988, 1.0, 1.0),
		"body_color": Color(0.290196, 0.780392, 0.94902, 1.0),
		"label_text": "★ 能源",
	},
}

var grid_position: Vector2i = Vector2i.ZERO
var is_busy := false
var blocks_grid_cell := true

signal roll_finished
## Emitted after a roll animation completes and the box has settled.
## AudioManager subscribes to this to play the face-kind-dependent roll sound.

var _grid_motor: Node
var _previous_grid_position: Vector2i = Vector2i.ZERO
var _orientation := {
	"top": FaceId.NORMAL_A,
	"bottom": FaceId.NORMAL_B,
	"left": FaceId.IMPACT_A,
	"right": FaceId.IMPACT_B,
	"front": FaceId.HEAVY,
	"back": FaceId.ENERGY,
}

@onready var visual: Node3D = $Visual
@onready var body: MeshInstance3D = $Visual/Body
@onready var face_label: Label3D = $Visual/FaceLabel
@onready var face_panel: CSGBox3D = $Visual/FacePanel

var _body_material: StandardMaterial3D

func _ready() -> void:
	add_to_group("grid_entity")
	add_to_group("rolling_box")

	grid_position = GridCoordRef.world_to_grid(global_position)
	global_position = GridCoordRef.grid_to_world(grid_position, BOX_HEIGHT)
	_previous_grid_position = grid_position

	## Register synchronously — deferred registration causes a race where the
	## entity is not yet in the grid motor's occupiers map when collision
	## checks run, letting the player walk through boxes or walls.
	_bind_grid_motor()
	_prepare_visual_material()

	_refresh_display()

func move_to_cell(target: Vector2i, direction: Vector2i) -> void:
	is_busy = true
	_previous_grid_position = grid_position
	grid_position = target
	_roll_orientation(direction)

	var rotation_delta := Vector3.ZERO
	if direction.x != 0:
		rotation_delta.z = deg_to_rad(-90.0 * direction.x)
	elif direction.y != 0:
		rotation_delta.x = deg_to_rad(90.0 * direction.y)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		self,
		"global_position",
		GridCoordRef.grid_to_world(grid_position, BOX_HEIGHT),
		ROLL_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		visual,
		"rotation",
		visual.rotation + rotation_delta,
		ROLL_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_on_roll_finished)

func current_face_kind() -> String:
	return _face_kind_name(_orientation["top"])

func predict_face_kind(direction: Vector2i) -> String:
	var predicted_orientation := _predict_orientation_after_roll(direction)
	return _face_kind_name(predicted_orientation["top"])

func _on_roll_finished() -> void:
	is_busy = false
	_refresh_display()
	roll_finished.emit()
	if _grid_motor != null and _grid_motor.has_method("notify_entity_move_finished"):
		_grid_motor.notify_entity_move_finished(self, _previous_grid_position, grid_position)

func _refresh_display() -> void:
	var face_kind := current_face_kind()
	var face_visual: Dictionary = FACE_VISUALS.get(face_kind, FACE_VISUALS["NORMAL"])
	face_label.text = face_visual.get("label_text", face_kind)
	face_label.modulate = face_visual.get("label_color", Color.WHITE)

	var body_color: Color = face_visual.get("body_color", Color.WHITE)

	if _body_material != null:
		_body_material.albedo_color = body_color
		_body_material.emission = body_color
		_body_material.emission_energy_multiplier = 0.18

	## Paint the face panel to match the current face type.
	if face_panel != null:
		var panel_mat: StandardMaterial3D = face_panel.material as StandardMaterial3D
		if panel_mat == null:
			panel_mat = StandardMaterial3D.new()
			face_panel.material = panel_mat
		panel_mat.emission_enabled = true
		panel_mat.albedo_color = body_color
		panel_mat.emission = body_color
		panel_mat.emission_energy_multiplier = 0.30

func _face_kind_name(face_id: int) -> String:
	match face_id:
		FaceId.NORMAL_A, FaceId.NORMAL_B:
			return "NORMAL"
		FaceId.IMPACT_A, FaceId.IMPACT_B:
			return "IMPACT"
		FaceId.HEAVY:
			return "HEAVY"
		FaceId.ENERGY:
			return "ENERGY"
		_:
			return "UNKNOWN"

func _roll_orientation(direction: Vector2i) -> void:
	_orientation = _predict_orientation_after_roll(direction)

func _predict_orientation_after_roll(direction: Vector2i) -> Dictionary:
	var old := _orientation.duplicate()
	var predicted := old.duplicate()

	if direction == Vector2i.RIGHT:
		predicted["top"] = old["left"]
		predicted["bottom"] = old["right"]
		predicted["left"] = old["bottom"]
		predicted["right"] = old["top"]
	elif direction == Vector2i.LEFT:
		predicted["top"] = old["right"]
		predicted["bottom"] = old["left"]
		predicted["left"] = old["top"]
		predicted["right"] = old["bottom"]
	elif direction == Vector2i.DOWN:
		predicted["top"] = old["back"]
		predicted["bottom"] = old["front"]
		predicted["front"] = old["top"]
		predicted["back"] = old["bottom"]
	elif direction == Vector2i.UP:
		predicted["top"] = old["front"]
		predicted["bottom"] = old["back"]
		predicted["front"] = old["bottom"]
		predicted["back"] = old["top"]

	return predicted

func _bind_grid_motor() -> void:
	_grid_motor = get_tree().get_first_node_in_group("grid_motor")
	if _grid_motor != null:
		_grid_motor.register_entity(self)

func _prepare_visual_material() -> void:
	var current_material := body.get_active_material(0)
	if current_material is StandardMaterial3D:
		_body_material = current_material.duplicate() as StandardMaterial3D
		body.set_surface_override_material(0, _body_material)
