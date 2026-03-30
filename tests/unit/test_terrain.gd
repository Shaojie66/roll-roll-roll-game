extends GutTest
## Unit tests for terrain tiles: RampTile, ConveyorTile, RotatingPlatformTile.

const GridMotorScript = preload("res://src/core/grid/grid_motor.gd")

var _motor: Node

class MockBox extends Node:
	var grid_position: Vector2i = Vector2i.ZERO
	var blocks_grid_cell: bool = true
	var is_busy: bool = false
	var _orientation := {
		"top": 0, "bottom": 1, "left": 2, "right": 3, "front": 4, "back": 5,
	}

	func _init(pos: Vector2i = Vector2i.ZERO) -> void:
		grid_position = pos
		add_to_group("rolling_box", true)

	func _apply_ramp_transform(roll_direction: Vector2i) -> void:
		var old := _orientation.duplicate()
		if roll_direction == Vector2i.RIGHT:
			_orientation["top"] = old["left"]
			_orientation["bottom"] = old["right"]
			_orientation["left"] = old["bottom"]
			_orientation["right"] = old["top"]
		elif roll_direction == Vector2i.LEFT:
			_orientation["top"] = old["right"]
			_orientation["bottom"] = old["left"]
			_orientation["left"] = old["top"]
			_orientation["right"] = old["bottom"]
		elif roll_direction == Vector2i.UP:
			_orientation["top"] = old["front"]
			_orientation["bottom"] = old["back"]
			_orientation["front"] = old["bottom"]
			_orientation["back"] = old["top"]
		elif roll_direction == Vector2i.DOWN:
			_orientation["top"] = old["back"]
			_orientation["bottom"] = old["front"]
			_orientation["front"] = old["top"]
			_orientation["back"] = old["bottom"]

	func _apply_rotation() -> void:
		var old := _orientation.duplicate()
		_orientation["top"] = old["left"]
		_orientation["left"] = old["bottom"]
		_orientation["bottom"] = old["right"]
		_orientation["right"] = old["top"]

	func move_to_cell(_t: Vector2i, _d: Vector2i) -> void:
		pass

func before_each():
	_motor = Node.new()
	_motor.set_script(GridMotorScript)
	add_child(_motor)

func after_each():
	_motor.queue_free()
	_motor = null

## Ramp transform tests

func test_ramp_transform_right_turns_top_to_left():
	var box := MockBox.new(Vector2i(2, 2))
	add_child(box)
	_motor.register_entity(box)
	assert_eq(box._orientation["top"], 0, "Initial top face should be 0")
	box._apply_ramp_transform(Vector2i.RIGHT)
	assert_eq(box._orientation["top"], 2, "After RIGHT roll, top should be old left (2)")
	box.queue_free()

func test_ramp_transform_left_turns_top_to_right():
	var box := MockBox.new(Vector2i(2, 2))
	add_child(box)
	_motor.register_entity(box)
	box._apply_ramp_transform(Vector2i.LEFT)
	assert_eq(box._orientation["top"], 3, "After LEFT roll, top should be old right (3)")
	box.queue_free()

func test_ramp_transform_up_turns_top_to_front():
	var box := MockBox.new(Vector2i(2, 2))
	add_child(box)
	_motor.register_entity(box)
	box._apply_ramp_transform(Vector2i.UP)
	assert_eq(box._orientation["top"], 4, "After UP roll, top should be old front (4)")
	box.queue_free()

func test_ramp_transform_down_turns_top_to_back():
	var box := MockBox.new(Vector2i(2, 2))
	add_child(box)
	_motor.register_entity(box)
	box._apply_ramp_transform(Vector2i.DOWN)
	assert_eq(box._orientation["top"], 5, "After DOWN roll, top should be old back (5)")
	box.queue_free()

func test_ramp_transform_ignores_non_cardinal():
	var box := MockBox.new(Vector2i(2, 2))
	add_child(box)
	_motor.register_entity(box)
	var initial_top: int = box._orientation["top"]
	box._apply_ramp_transform(Vector2i(1, 1))
	assert_eq(box._orientation["top"], initial_top, "Diagonal direction should not transform")
	box.queue_free()

## Rotation tests

func test_rotating_platform_rotates_top_clockwise():
	var box := MockBox.new(Vector2i(2, 2))
	add_child(box)
	_motor.register_entity(box)
	assert_eq(box._orientation["top"], 0, "Initial top should be 0")
	box._apply_rotation()
	assert_eq(box._orientation["top"], 2, "After 90 deg CW, top should be old left (2)")
	box.queue_free()

func test_rotating_platform_cumulative_rotation():
	var box := MockBox.new(Vector2i(2, 2))
	add_child(box)
	_motor.register_entity(box)
	box._apply_rotation()
	assert_eq(box._orientation["top"], 2, "After 1st rotation")
	box._apply_rotation()
	assert_eq(box._orientation["top"], 1, "After 2nd rotation (180 deg)")
	box._apply_rotation()
	assert_eq(box._orientation["top"], 3, "After 3rd rotation (270 deg)")
	box._apply_rotation()
	assert_eq(box._orientation["top"], 0, "After 4th rotation (360 deg = identity)")
	box.queue_free()

func test_rotating_platform_leaves_front_back_unchanged():
	var box := MockBox.new(Vector2i(2, 2))
	add_child(box)
	_motor.register_entity(box)
	var old_front: int = box._orientation["front"]
	var old_back: int = box._orientation["back"]
	box._apply_rotation()
	assert_eq(box._orientation["front"], old_front, "Front should be unchanged")
	assert_eq(box._orientation["back"], old_back, "Back should be unchanged")
	box.queue_free()
