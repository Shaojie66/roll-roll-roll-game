extends RefCounted

class_name GridCoord

const CELL_SIZE := 2.0

static func grid_to_world(cell: Vector2i, y: float = 0.0) -> Vector3:
	return Vector3(cell.x * CELL_SIZE, y, cell.y * CELL_SIZE)

static func world_to_grid(position: Vector3) -> Vector2i:
	return Vector2i(
		roundi(position.x / CELL_SIZE),
		roundi(position.z / CELL_SIZE)
	)

static func facing_yaw(direction: Vector2i) -> float:
	return atan2(-direction.x, -direction.y)
