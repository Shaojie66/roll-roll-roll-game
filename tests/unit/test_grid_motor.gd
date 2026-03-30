extends GutTest
## Unit tests for GridMotor — entity registration, occupancy queries, and move logic.

const GridMotorScript = preload("res://src/core/grid/grid_motor.gd")

var _motor: Node

## Minimal mock entity for testing without full scene hierarchy.
class MockEntity extends Node:
	var grid_position: Vector2i = Vector2i.ZERO
	var blocks_grid_cell: bool = true
	var is_busy: bool = false
	var can_push_boxes: bool = false
	var _groups: PackedStringArray = []

	func _init(pos: Vector2i = Vector2i.ZERO, groups: PackedStringArray = []) -> void:
		grid_position = pos
		_groups = groups

	func is_in_group(group_name: String) -> bool:
		return group_name in _groups

func before_each():
	_motor = Node.new()
	_motor.set_script(GridMotorScript)
	add_child(_motor)

func after_each():
	_motor.queue_free()
	_motor = null

## ── Registration ─────────────────────────────────────────────────────────────

func test_register_entity_adds_to_occupiers():
	var entity := MockEntity.new(Vector2i(3, 4))
	add_child(entity)
	_motor.register_entity(entity)
	assert_eq(_motor.get_entity_at(Vector2i(3, 4)), entity, "Registered entity should be at its cell")
	entity.queue_free()

func test_unregister_entity_removes_from_occupiers():
	var entity := MockEntity.new(Vector2i(2, 2))
	add_child(entity)
	_motor.register_entity(entity)
	_motor.unregister_entity(entity)
	assert_null(_motor.get_entity_at(Vector2i(2, 2)), "Unregistered entity should leave cell empty")
	entity.queue_free()

func test_get_entity_at_empty_cell_returns_null():
	assert_null(_motor.get_entity_at(Vector2i(99, 99)), "Empty cell should return null")

func test_non_blocking_entity_not_registered():
	var entity := MockEntity.new(Vector2i(1, 1))
	entity.blocks_grid_cell = false
	add_child(entity)
	_motor.register_entity(entity)
	assert_null(_motor.get_entity_at(Vector2i(1, 1)), "Non-blocking entity should not occupy cell")
	entity.queue_free()

## ── Move count ───────────────────────────────────────────────────────────────

func test_move_count_starts_at_zero():
	assert_eq(_motor.get_move_count(), 0, "Move count should start at 0")

func test_reset_move_count():
	_motor._move_count = 5
	_motor.reset_move_count()
	assert_eq(_motor.get_move_count(), 0, "Reset should bring count to 0")

## ── Deny reasons ─────────────────────────────────────────────────────────────

func test_face_kind_display_name_normal():
	assert_eq(_motor._face_kind_display_name("NORMAL"), "普通")

func test_face_kind_display_name_impact():
	assert_eq(_motor._face_kind_display_name("IMPACT"), "冲击")

func test_face_kind_display_name_heavy():
	assert_eq(_motor._face_kind_display_name("HEAVY"), "重压")

func test_face_kind_display_name_energy():
	assert_eq(_motor._face_kind_display_name("ENERGY"), "能源")

func test_face_kind_display_name_unknown():
	assert_eq(_motor._face_kind_display_name("FOOBAR"), "FOOBAR",
		"Unknown kind should pass through unchanged")
