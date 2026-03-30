extends Node

class_name GridMotor

signal entity_move_finished(entity: Node, origin: Vector2i, target: Vector2i)
## Emitted when an actor tries to move but is blocked.
signal move_denied(actor: Node, reason: String)

var occupiers: Dictionary = {}
var last_deny_reason := ""

## ── Move count (Item 5) ──────────────────────────────────────────────────────
var _move_count := 0

func get_move_count() -> int:
	return _move_count

func reset_move_count() -> void:
	_move_count = 0

func _ready() -> void:
	add_to_group("grid_motor")

func register_entity(entity: Node) -> void:
	var cell: Variant = entity.get("grid_position")
	if not (cell is Vector2i):
		return
	if not _blocks_grid_cell(entity):
		return

	if occupiers.has(cell):
		push_warning("GridMotor: '%s' overwriting existing '%s' at cell %s — may cause clipping." % [entity.name, occupiers.get(cell).name if occupiers.get(cell) else "?", cell])
	occupiers[cell] = entity

func unregister_entity(entity: Node) -> void:
	var cell: Variant = entity.get("grid_position")
	if cell is Vector2i and occupiers.get(cell) == entity:
		occupiers.erase(cell)
		return
	# Fallback: linear scan in case grid_position was already updated
	for key: Variant in occupiers.keys():
		if occupiers[key] == entity:
			occupiers.erase(key)
			return

func get_entity_at(cell: Vector2i) -> Node:
	return occupiers.get(cell)

func notify_entity_move_finished(entity: Node, origin: Vector2i, target: Vector2i) -> void:
	entity_move_finished.emit(entity, origin, target)

func try_move_actor(actor: Node, direction: Vector2i) -> bool:
	if direction == Vector2i.ZERO:
		return false
	if bool(actor.get("is_busy")):
		_set_denied(actor, "行动中...")
		return false

	var origin: Vector2i = actor.get("grid_position")
	var target := origin + direction
	var occupant := get_entity_at(target)

	if occupant == null:
		_commit_move(actor, target, direction)
		_move_count += 1
		return true

	if occupant.is_in_group("rolling_box") and bool(actor.get("can_push_boxes")):
		if try_push_box(occupant, direction):
			_commit_move(actor, target, direction)
			_move_count += 1
			return true
		## try_push_box already emitted move_denied(box, reason). Forward it
		## to the player so their _on_move_denied guard fires and they see
		## the feedback.
		_set_denied(actor, last_deny_reason)
		return false

	_set_denied(actor, "被阻挡")
	return false

func try_push_box(box: Node, direction: Vector2i) -> bool:
	if bool(box.get("is_busy")):
		_set_denied(box, "箱子行动中...")
		return false

	var origin: Vector2i = box.get("grid_position")
	var target := origin + direction

	var occupant := get_entity_at(target)
	if occupant == null:
		_commit_move(box, target, direction)
		return true

	if occupant.is_in_group("enemy"):
		var predicted_face_kind := ""
		if box.has_method("predict_face_kind"):
			predicted_face_kind = box.predict_face_kind(direction)

		if predicted_face_kind == "":
			_set_denied(box, "当前顶面无法攻击")
			return false

		if occupant.has_method("can_be_defeated_by") and occupant.can_be_defeated_by(predicted_face_kind):
			unregister_entity(occupant)
			if occupant.has_method("defeat"):
				occupant.defeat(direction, predicted_face_kind)
			_commit_move(box, target, direction)
			return true

		var face_display := _face_kind_display_name(predicted_face_kind)
		_set_denied(box, "%s 顶面打不过敌人" % face_display)
		return false

	if occupant.is_in_group("wall") or occupant.is_in_group("door"):
		_set_denied(box, "被墙或门阻挡")
		return false

	return false

func _commit_move(entity: Node, target: Vector2i, direction: Vector2i) -> void:
	unregister_entity(entity)
	entity.move_to_cell(target, direction)
	if _blocks_grid_cell(entity):
		occupiers[target] = entity

func _blocks_grid_cell(entity: Node) -> bool:
	var blocks: Variant = entity.get("blocks_grid_cell")
	if blocks is bool:
		return blocks
	return true

func _set_denied(entity: Node, reason: String) -> void:
	last_deny_reason = reason
	move_denied.emit(entity, reason)

func _face_kind_display_name(kind: String) -> String:
	match kind:
		"NORMAL": return "普通"
		"IMPACT": return "冲击"
		"HEAVY": return "重压"
		"ENERGY": return "能源"
		_: return kind
