extends GutTest
## Unit tests for GridCoord — pure static functions, no scene required.

const GridCoordRef = preload("res://src/core/grid/grid_coord.gd")

func test_grid_to_world_origin():
	var result := GridCoordRef.grid_to_world(Vector2i.ZERO, 0.0)
	assert_eq(result, Vector3.ZERO, "Origin cell should map to world origin")

func test_grid_to_world_positive_cell():
	var result := GridCoordRef.grid_to_world(Vector2i(3, 2), 0.5)
	assert_eq(result, Vector3(6.0, 0.5, 4.0), "Cell (3,2) at y=0.5 with CELL_SIZE=2")

func test_grid_to_world_negative_cell():
	var result := GridCoordRef.grid_to_world(Vector2i(-1, -2), 1.0)
	assert_eq(result, Vector3(-2.0, 1.0, -4.0), "Negative cells should produce negative world coords")

func test_world_to_grid_exact():
	var result := GridCoordRef.world_to_grid(Vector3(6.0, 999.0, 4.0))
	assert_eq(result, Vector2i(3, 2), "Exact world position should round to correct cell")

func test_world_to_grid_rounding():
	var result := GridCoordRef.world_to_grid(Vector3(6.3, 0.0, 3.7))
	assert_eq(result, Vector2i(3, 2), "Slightly off-center should still round to nearest cell")

func test_world_to_grid_midpoint():
	var result := GridCoordRef.world_to_grid(Vector3(1.0, 0.0, 1.0))
	assert_eq(result, Vector2i(1, 1), "Midpoint between cells should round up (roundi)")

func test_roundtrip_grid_world_grid():
	var original := Vector2i(5, 7)
	var world := GridCoordRef.grid_to_world(original, 0.0)
	var back := GridCoordRef.world_to_grid(world)
	assert_eq(back, original, "Grid → World → Grid roundtrip should be lossless")

func test_facing_yaw_up():
	var yaw := GridCoordRef.facing_yaw(Vector2i.UP)
	assert_almost_eq(yaw, atan2(0.0, 1.0), 0.001, "UP should face +Z (yaw ≈ 0)")

func test_facing_yaw_down():
	var yaw := GridCoordRef.facing_yaw(Vector2i.DOWN)
	assert_almost_eq(yaw, atan2(0.0, -1.0), 0.001, "DOWN should face -Z (yaw ≈ PI)")

func test_facing_yaw_left():
	var yaw := GridCoordRef.facing_yaw(Vector2i.LEFT)
	assert_almost_eq(yaw, atan2(1.0, 0.0), 0.001, "LEFT should face +X (yaw ≈ PI/2)")

func test_facing_yaw_right():
	var yaw := GridCoordRef.facing_yaw(Vector2i.RIGHT)
	assert_almost_eq(yaw, atan2(-1.0, 0.0), 0.001, "RIGHT should face -X (yaw ≈ -PI/2)")

func test_cell_size_is_two():
	assert_eq(GridCoordRef.CELL_SIZE, 2.0, "CELL_SIZE must be 2.0 for all grid math to work")
