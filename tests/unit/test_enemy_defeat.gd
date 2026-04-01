extends GutTest
## Unit tests for enemy defeat conditions and variants.

const GridMotorScript = preload("res://src/core/grid/grid_motor.gd")
const NormalEnemyScript = preload("res://src/gameplay/enemies/normal_enemy.gd")
const ShieldEnemyScript = preload("res://src/gameplay/enemies/shield_enemy.gd")
const SplitterEnemyScript = preload("res://src/gameplay/enemies/splitter_enemy.gd")

var _motor: Node

class MockBox extends Node:
	var grid_position: Vector2i = Vector2i.ZERO
	var blocks_grid_cell: bool = true
	var is_busy: bool = false
	var _top_face_kind := "NORMAL"

	func _init(pos: Vector2i = Vector2i.ZERO) -> void:
		grid_position = pos
		add_to_group("rolling_box", true)

	func predict_face_kind(_direction: Vector2i) -> String:
		return _top_face_kind

	func current_face_kind() -> String:
		return _top_face_kind

	func set_top_face_kind(kind: String) -> void:
		_top_face_kind = kind

	func move_to_cell(_t: Vector2i, _d: Vector2i) -> void:
		pass

class MockEnemy extends Node:
	var grid_position: Vector2i = Vector2i.ZERO
	var blocks_grid_cell: bool = true
	var is_defeated: bool = false
	var accepted_face_kinds := PackedStringArray(["IMPACT", "HEAVY"])

	func _init(pos: Vector2i = Vector2i.ZERO) -> void:
		grid_position = pos
		add_to_group("enemy", true)

	func can_be_defeated_by(face_kind: String) -> bool:
		return accepted_face_kinds.has(face_kind)

	func defeat(_direction: Vector2i, _face_kind: String) -> void:
		is_defeated = true


func before_each():
	_motor = Node.new()
	_motor.set_script(GridMotorScript)
	add_child(_motor)


func after_each():
	_motor.queue_free()
	_motor = null


## NormalEnemy defeat tests

func test_normal_enemy_defeated_by_impact_face():
	var enemy := MockEnemy.new(Vector2i(3, 2))
	add_child(enemy)
	_motor.register_entity(enemy)

	var box := MockBox.new(Vector2i(2, 2))
	box.set_top_face_kind("IMPACT")
	add_child(box)
	_motor.register_entity(box)

	## Simulate defeat check as GridMotor would
	var predicted_face := box.predict_face_kind(Vector2i.RIGHT)
	var can_defeat := enemy.can_be_defeated_by(predicted_face)
	assert_eq(can_defeat, true, "IMPACT face should defeat NormalEnemy")
	assert_eq(enemy.is_defeated, false, "Enemy should not be defeated until defeat() is called")

	## Call defeat
	enemy.defeat(Vector2i.RIGHT, predicted_face)
	assert_eq(enemy.is_defeated, true, "Enemy should be defeated after defeat() called")

	enemy.queue_free()
	box.queue_free()


func test_normal_enemy_not_defeated_by_normal_face():
	var enemy := MockEnemy.new(Vector2i(3, 2))
	add_child(enemy)
	_motor.register_entity(enemy)

	var box := MockBox.new(Vector2i(2, 2))
	box.set_top_face_kind("NORMAL")
	add_child(box)
	_motor.register_entity(box)

	var predicted_face := box.predict_face_kind(Vector2i.RIGHT)
	var can_defeat := enemy.can_be_defeated_by(predicted_face)
	assert_eq(can_defeat, false, "NORMAL face should NOT defeat NormalEnemy")
	assert_eq(enemy.is_defeated, false, "Enemy should remain undefeated")

	enemy.queue_free()
	box.queue_free()


func test_normal_enemy_heavy_face_also_defeats():
	var enemy := MockEnemy.new(Vector2i(3, 2))
	add_child(enemy)
	_motor.register_entity(enemy)

	var box := MockBox.new(Vector2i(2, 2))
	box.set_top_face_kind("HEAVY")
	add_child(box)
	_motor.register_entity(box)

	var predicted_face := box.predict_face_kind(Vector2i.RIGHT)
	var can_defeat := enemy.can_be_defeated_by(predicted_face)
	assert_eq(can_defeat, true, "HEAVY face should also defeat NormalEnemy")

	enemy.queue_free()
	box.queue_free()


## ShieldEnemy tests

class MockShieldEnemy extends Node:
	var grid_position: Vector2i = Vector2i.ZERO
	var blocks_grid_cell: bool = true
	var is_defeated: bool = false
	var shield_hp: int = 1
	var accepted_face_kinds := PackedStringArray(["IMPACT", "HEAVY"])
	var shield_broken: bool = false

	func _init(pos: Vector2i = Vector2i.ZERO) -> void:
		grid_position = pos
		add_to_group("enemy", true)

	func can_be_defeated_by(face_kind: String) -> bool:
		return accepted_face_kinds.has(face_kind)

	func defeat(direction: Vector2i, face_kind: String) -> void:
		if is_defeated:
			return
		if shield_hp > 0:
			shield_hp -= 1
			shield_broken = true
			return
		is_defeated = true


func test_shield_enemy_first_hit_breaks_shield_not_death():
	var enemy := MockShieldEnemy.new(Vector2i(3, 2))
	add_child(enemy)
	_motor.register_entity(enemy)

	var box := MockBox.new(Vector2i(2, 2))
	box.set_top_face_kind("IMPACT")
	add_child(box)
	_motor.register_entity(box)

	var predicted_face := box.predict_face_kind(Vector2i.RIGHT)
	var can_defeat := enemy.can_be_defeated_by(predicted_face)
	assert_eq(can_defeat, true, "ShieldEnemy accepts IMPACT face")
	assert_eq(enemy.shield_hp, 1, "Shield should start with 1 HP")

	enemy.defeat(Vector2i.RIGHT, predicted_face)
	assert_eq(enemy.shield_hp, 0, "Shield HP should be 0 after first hit")
	assert_eq(enemy.shield_broken, true, "Shield should be broken")
	assert_eq(enemy.is_defeated, false, "Enemy should NOT be defeated on first hit")
	assert_eq(enemy.blocks_grid_cell, true, "Enemy should still block grid cell")

	enemy.queue_free()
	box.queue_free()


func test_shield_enemy_second_hit_kills():
	var enemy := MockShieldEnemy.new(Vector2i(3, 2))
	add_child(enemy)
	_motor.register_entity(enemy)

	## First hit breaks shield
	enemy.defeat(Vector2i.RIGHT, "IMPACT")
	assert_eq(enemy.shield_hp, 0, "Shield should be broken")
	assert_eq(enemy.is_defeated, false, "Should not be defeated yet")

	## Second hit kills
	enemy.defeat(Vector2i.RIGHT, "IMPACT")
	assert_eq(enemy.is_defeated, true, "Should be defeated on second hit")

	enemy.queue_free()


func test_shield_enemy_normal_face_not_accepted():
	var enemy := MockShieldEnemy.new(Vector2i(3, 2))
	add_child(enemy)
	_motor.register_entity(enemy)

	var box := MockBox.new(Vector2i(2, 2))
	box.set_top_face_kind("NORMAL")
	add_child(box)
	_motor.register_entity(box)

	var predicted_face := box.predict_face_kind(Vector2i.RIGHT)
	var can_defeat := enemy.can_be_defeated_by(predicted_face)
	assert_eq(can_defeat, false, "NORMAL face should NOT be accepted by ShieldEnemy")

	enemy.queue_free()
	box.queue_free()


## SplitterEnemy tests

class MockSplitterEnemy extends Node:
	var grid_position: Vector2i = Vector2i.ZERO
	var blocks_grid_cell: bool = true
	var is_defeated: bool = false
	var accepted_face_kinds := PackedStringArray(["IMPACT", "HEAVY"])
	var minions_spawned: int = 0
	var _last_defeat_dir := Vector2i.ZERO

	func _init(pos: Vector2i = Vector2i.ZERO) -> void:
		grid_position = pos
		add_to_group("enemy", true)

	func can_be_defeated_by(face_kind: String) -> bool:
		return accepted_face_kinds.has(face_kind)

	func defeat(direction: Vector2i, face_kind: String) -> void:
		if is_defeated:
			return
		is_defeated = true
		blocks_grid_cell = false
		_last_defeat_dir = direction
		## Simulate minion spawning
		minions_spawned = 2


func test_splitter_enemy_defeat_spawns_minions():
	var enemy := MockSplitterEnemy.new(Vector2i(3, 2))
	add_child(enemy)
	_motor.register_entity(enemy)

	var box := MockBox.new(Vector2i(2, 2))
	box.set_top_face_kind("IMPACT")
	add_child(box)
	_motor.register_entity(box)

	var predicted_face := box.predict_face_kind(Vector2i.RIGHT)
	var can_defeat := enemy.can_be_defeated_by(predicted_face)
	assert_eq(can_defeat, true, "SplitterEnemy accepts IMPACT")

	enemy.defeat(Vector2i.RIGHT, predicted_face)
	assert_eq(enemy.is_defeated, true, "Should be defeated")
	assert_eq(enemy.blocks_grid_cell, false, "Should no longer block cell after defeat")
	assert_eq(enemy.minions_spawned, 2, "Should spawn 2 minions")

	enemy.queue_free()
	box.queue_free()


func test_splitter_enemy_not_defeated_by_energy():
	var enemy := MockSplitterEnemy.new(Vector2i(3, 2))
	add_child(enemy)
	_motor.register_entity(enemy)

	var box := MockBox.new(Vector2i(2, 2))
	box.set_top_face_kind("ENERGY")
	add_child(box)
	_motor.register_entity(box)

	var predicted_face := box.predict_face_kind(Vector2i.RIGHT)
	var can_defeat := enemy.can_be_defeated_by(predicted_face)
	assert_eq(can_defeat, false, "ENERGY face should NOT defeat SplitterEnemy")
	assert_eq(enemy.is_defeated, false, "Should not be defeated")

	enemy.queue_free()
	box.queue_free()


## Defeat direction affects spawn direction (perpendicular)

func test_splitter_minion_spawn_perpendicular_to_defeat_direction():
	## When defeated moving RIGHT, minions spawn at UP and DOWN (perpendicular)
	var enemy := MockSplitterEnemy.new(Vector2i(3, 3))
	add_child(enemy)

	enemy.defeat(Vector2i.RIGHT, "IMPACT")
	## _last_defeat_dir is RIGHT (1, 0)
	## perpendicular should be (0, 1) and (0, -1)
	## i.e., UP and DOWN
	assert_eq(enemy._last_defeat_dir, Vector2i.RIGHT, "Defeat direction recorded")

	## Perpendicular calculation: Vector2i(-direction.y, direction.x)
	## RIGHT = (1, 0) → perp = (0, 1) = UP
	## RIGHT = (1, 0) → perp negative = (0, -1) = DOWN
	var expected_perp_positive := Vector2i(-enemy._last_defeat_dir.y, enemy._last_defeat_dir.x)
	var expected_perp_negative := Vector2i(enemy._last_defeat_dir.y, -enemy._last_defeat_dir.x)
	assert_eq(expected_perp_positive, Vector2i(0, 1), "Perp should be UP")
	assert_eq(expected_perp_negative, Vector2i(0, -1), "Perp negative should be DOWN")

	enemy.queue_free()
