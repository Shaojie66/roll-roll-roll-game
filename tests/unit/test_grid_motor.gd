extends GutTest
## Unit tests for GridMotor — entity registration, occupancy queries, and move logic.

const GridMotorScript = preload("res://src/core/grid/grid_motor.gd")

var _motor: Node

## Minimal mock entity for testing without full scene hierarchy.
class MockEntity extends Node:
	@export var grid_position: Vector2i = Vector2i.ZERO
	@export var blocks_grid_cell: bool = true
	@export var is_busy: bool = false
	@export var can_push_boxes: bool = false

	func _init(pos: Vector2i = Vector2i.ZERO, groups: PackedStringArray = []) -> void:
		grid_position = pos
		# Add to Godot groups so is_in_group() works natively
		for g in groups:
			add_to_group(g, true)

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

## ── Push chain: player pushes box ─────────────────────────────────────────

class MockBox extends Node:
	@export var grid_position: Vector2i = Vector2i.ZERO
	@export var blocks_grid_cell: bool = true
	@export var is_busy: bool = false
	var _groups: PackedStringArray = ["rolling_box"]
	var _predicted_face: String = "IMPACT"

	func _init(pos: Vector2i = Vector2i.ZERO) -> void:
		grid_position = pos
		add_to_group("rolling_box", true)

	func predict_face_kind(_dir: Vector2i) -> String:
		return _predicted_face

	func current_face_kind() -> String:
		return _predicted_face

	func move_to_cell(t: Vector2i, _d: Vector2i) -> void:
		grid_position = t

class MockPlayer extends Node:
	@export var grid_position: Vector2i = Vector2i.ZERO
	@export var blocks_grid_cell: bool = true
	@export var is_busy: bool = false
	@export var can_push_boxes: bool = true
	var _groups: PackedStringArray = ["player"]

	func _init(pos: Vector2i = Vector2i.ZERO) -> void:
		grid_position = pos
		add_to_group("player", true)

	func move_to_cell(t: Vector2i, _d: Vector2i) -> void:
		grid_position = t

class MockEnemy extends Node:
	@export var grid_position: Vector2i = Vector2i.ZERO
	@export var blocks_grid_cell: bool = true
	var _groups: PackedStringArray = ["enemy"]
	var _accepted: PackedStringArray = ["IMPACT", "HEAVY"]

	func _init(pos: Vector2i = Vector2i.ZERO) -> void:
		grid_position = pos
		add_to_group("enemy", true)

	func can_be_defeated_by(face: String) -> bool:
		return face in _accepted

	func defeat(_d: Vector2i, _f: String) -> void:
		grid_position = Vector2i(-100, -100)  # Move off grid when defeated

## Player pushes box into empty cell — both should move
func test_player_pushes_box_into_empty():
	var player := MockPlayer.new(Vector2i(1, 3))
	var box := MockBox.new(Vector2i(2, 3))
	add_child(player)
	add_child(box)
	_motor.register_entity(player)
	_motor.register_entity(box)

	var result: bool = _motor.try_move_actor(player, Vector2i.RIGHT)
	assert_eq(result, true, "Push should succeed into empty cell")
	assert_eq(player.grid_position, Vector2i(2, 3), "Player moves to box's old cell")
	assert_eq(box.grid_position, Vector2i(3, 3), "Box moves ahead of player")

	player.queue_free()
	box.queue_free()

## Player walks into empty cell — succeeds
func test_player_walks_into_empty():
	var player := MockPlayer.new(Vector2i(1, 1))
	add_child(player)
	_motor.register_entity(player)

	var result: bool = _motor.try_move_actor(player, Vector2i.RIGHT)
	assert_eq(result, true, "Move into empty cell should succeed")
	assert_eq(player.grid_position, Vector2i(2, 1))

	player.queue_free()

## Player walks into wall cell — denied
func test_player_walks_into_wall():
	var player := MockPlayer.new(Vector2i(1, 1))
	var wall := MockEntity.new(Vector2i(2, 1), ["wall"])
	add_child(player)
	add_child(wall)
	_motor.register_entity(player)
	_motor.register_entity(wall)

	var result: bool = _motor.try_move_actor(player, Vector2i.RIGHT)
	assert_eq(result, false, "Move into wall should be denied")
	assert_eq(player.grid_position, Vector2i(1, 1), "Player should not move")
	assert_eq(_motor.last_deny_reason, "被阻挡", "Deny reason should be '被阻挡'")

	player.queue_free()
	wall.queue_free()

## Player pushes box into wall — denied
func test_player_pushes_box_into_wall():
	var player := MockPlayer.new(Vector2i(1, 3))
	var box := MockBox.new(Vector2i(2, 3))
	var wall := MockEntity.new(Vector2i(3, 3), ["wall"])
	add_child(player)
	add_child(box)
	add_child(wall)
	_motor.register_entity(player)
	_motor.register_entity(box)
	_motor.register_entity(wall)

	var result: bool = _motor.try_move_actor(player, Vector2i.RIGHT)
	assert_eq(result, false, "Push into wall should be denied")
	assert_eq(player.grid_position, Vector2i(1, 3), "Player should not move")
	assert_eq(box.grid_position, Vector2i(2, 3), "Box should not move")

	player.queue_free()
	box.queue_free()
	wall.queue_free()

## Box pushes into enemy with correct face — enemy defeated, box moves
func test_box_defeats_enemy_with_correct_face():
	var box := MockBox.new(Vector2i(2, 3))
	box._predicted_face = "IMPACT"  # Correct face
	var enemy := MockEnemy.new(Vector2i(3, 3))
	add_child(box)
	add_child(enemy)
	_motor.register_entity(box)
	_motor.register_entity(enemy)

	# MockBox has predict_face_kind returning "IMPACT" → enemy.can_be_defeated_by("IMPACT") = true
	var result: bool = _motor.try_push_box(box, Vector2i.RIGHT)
	assert_eq(result, true, "Box with IMPACT face should defeat enemy")
	assert_eq(box.grid_position, Vector2i(3, 3), "Box moves into enemy's cell")
	assert_eq(_motor.get_entity_at(Vector2i(3, 3)), box, "Cell should now contain the box after defeating enemy")

	box.queue_free()
	enemy.queue_free()

## Box pushes into enemy with wrong face — denied
func test_box_denied_by_enemy_with_wrong_face():
	var box := MockBox.new(Vector2i(2, 3))
	box._predicted_face = "NORMAL"  # Wrong face
	var enemy := MockEnemy.new(Vector2i(3, 3))
	add_child(box)
	add_child(enemy)
	_motor.register_entity(box)
	_motor.register_entity(enemy)

	var result: bool = _motor.try_push_box(box, Vector2i.RIGHT)
	assert_eq(result, false, "Box with NORMAL face should be denied by enemy")
	assert_eq(box.grid_position, Vector2i(2, 3), "Box should not move")
	assert_eq(_motor.get_entity_at(Vector2i(3, 3)), enemy, "Enemy should still be registered")

	box.queue_free()
	enemy.queue_free()

## Player is denied when box push fails
func test_player_denied_when_box_push_fails():
	var player := MockPlayer.new(Vector2i(1, 3))
	var box := MockBox.new(Vector2i(2, 3))
	var wall := MockEntity.new(Vector2i(3, 3), ["wall"])
	add_child(player)
	add_child(box)
	add_child(wall)
	_motor.register_entity(player)
	_motor.register_entity(box)
	_motor.register_entity(wall)

	var result: bool = _motor.try_move_actor(player, Vector2i.RIGHT)
	assert_eq(result, false, "Player should be denied")
	assert_eq(_motor.last_deny_reason, "被墙或门阻挡", "Deny reason should mention blocking")

	player.queue_free()
	box.queue_free()
	wall.queue_free()
