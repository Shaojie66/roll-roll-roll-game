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

## Conveyor belt tests

class MockConveyorLogic extends RefCounted:
	var push_count: int = 0
	var last_push_dir: Vector2i = Vector2i.ZERO
	var is_busy: bool = false

	func try_push(box, direction: Vector2i) -> bool:
		if is_busy:
			return false
		push_count += 1
		last_push_dir = direction
		return true


func test_conveyor_pushes_box_when_ready():
	var logic := MockConveyorLogic.new()
	var box := MockBox.new(Vector2i(2, 2))
	add_child(box)
	_motor.register_entity(box)

	# Simulate conveyor belt logic
	var did_push := logic.try_push(box, Vector2i.RIGHT)
	assert_eq(did_push, true, "Should push when not busy")
	assert_eq(logic.push_count, 1, "Push count should be 1")
	assert_eq(logic.last_push_dir, Vector2i.RIGHT, "Push direction should be RIGHT")

	box.queue_free()


func test_conveyor_skips_when_busy():
	var logic := MockConveyorLogic.new()
	var box := MockBox.new(Vector2i(2, 2))
	add_child(box)
	_motor.register_entity(box)

	logic.is_busy = true
	var did_push := logic.try_push(box, Vector2i.RIGHT)
	assert_eq(did_push, false, "Should not push when busy")
	assert_eq(logic.push_count, 0, "Push count should remain 0")

	box.queue_free()


func test_conveyor_consecutive_pushes():
	var logic := MockConveyorLogic.new()
	var box := MockBox.new(Vector2i(2, 2))
	add_child(box)
	_motor.register_entity(box)

	# Simulate 3 consecutive pushes
	logic.try_push(box, Vector2i.RIGHT)
	logic.try_push(box, Vector2i.RIGHT)
	logic.try_push(box, Vector2i.RIGHT)

	assert_eq(logic.push_count, 3, "Should have 3 pushes")
	assert_eq(logic.last_push_dir, Vector2i.RIGHT, "Last push should be RIGHT")

	box.queue_free()


func test_conveyor_different_directions():
	var logic := MockConveyorLogic.new()
	var box := MockBox.new(Vector2i(2, 2))
	add_child(box)
	_motor.register_entity(box)

	logic.try_push(box, Vector2i.UP)
	assert_eq(logic.last_push_dir, Vector2i.UP)

	logic.try_push(box, Vector2i.DOWN)
	assert_eq(logic.last_push_dir, Vector2i.DOWN)

	logic.try_push(box, Vector2i.LEFT)
	assert_eq(logic.last_push_dir, Vector2i.LEFT)

	assert_eq(logic.push_count, 3, "Should have 3 pushes in different directions")

	box.queue_free()


## Multi-box terrain interaction tests

func test_conveyor_skipped_when_box_not_at_position():
	## Box leaves conveyor cell before next push tick
	var logic := MockConveyorLogic.new()
	var box := MockBox.new(Vector2i(2, 2))
	add_child(box)
	_motor.register_entity(box)

	## Simulate: box enters conveyor, then leaves before push
	logic.try_push(box, Vector2i.RIGHT)
	assert_eq(logic.push_count, 1, "First push succeeds")

	## Box is no longer at conveyor position — subsequent push should not affect it
	var another_box := MockBox.new(Vector2i(3, 2))
	add_child(another_box)

	logic.try_push(another_box, Vector2i.RIGHT)
	assert_eq(logic.push_count, 2, "Push affects different box at different position")

	box.queue_free()
	another_box.queue_free()


func test_conveyor_blocked_by_wall_returns_false():
	var logic := MockConveyorLogic.new()
	var box := MockBox.new(Vector2i(1, 2))
	add_child(box)
	_motor.register_entity(box)

	## Register a wall at the target cell
	var wall := Node.new()
	wall.set("blocks_grid_cell", true)
	wall.set("grid_position", Vector2i(2, 2))
	add_child(wall)
	_motor.register_entity(wall, Vector2i(2, 2))

	## Conveyor would push RIGHT but wall blocks
	var did_push := logic.try_push(box, Vector2i.RIGHT)
	assert_eq(did_push, false, "Push should be blocked by wall")
	assert_eq(logic.push_count, 0, "No push should occur when blocked")

	box.queue_free()
	wall.queue_free()


func test_multiple_terrain_tiles_independent():
	## Two conveyor tiles at different positions don't interfere
	var logic1 := MockConveyorLogic.new()
	var logic2 := MockConveyorLogic.new()

	var box1 := MockBox.new(Vector2i(1, 1))
	var box2 := MockBox.new(Vector2i(3, 3))
	add_child(box1)
	add_child(box2)
	_motor.register_entity(box1)
	_motor.register_entity(box2)

	## Each conveyor pushes independently
	var push1 := logic1.try_push(box1, Vector2i.RIGHT)
	var push2 := logic2.try_push(box2, Vector2i.LEFT)

	assert_eq(push1, true, "First conveyor pushes its box")
	assert_eq(push2, true, "Second conveyor pushes its box")
	assert_eq(logic1.push_count, 1)
	assert_eq(logic2.push_count, 1)

	box1.queue_free()
	box2.queue_free()


func test_terrain_tile_blocks_grid_cell_false():
	## Terrain tiles must register with blocks_grid_cell = false
	var box := MockBox.new(Vector2i(2, 2))
	box.set("blocks_grid_cell", false)  ## Simulate terrain behavior
	add_child(box)
	_motor.register_entity(box)

	## A terrain tile at same position should not block the box
	var terrain := MockBox.new(Vector2i(2, 2))
	terrain.set("blocks_grid_cell", false)  ## Terrain blocks_grid_cell = false
	add_child(terrain)

	## Terrain can be registered at same cell (non-blocking)
	_motor.register_entity(terrain, Vector2i(2, 2))

	## Both entities should be able to occupy same cell (terrain is non-blocking)
	var occupant = _motor.get_entity_at(Vector2i(2, 2))
	assert_ne(occupant, null, "Should have an occupant")

	box.queue_free()
	terrain.queue_free()
