extends Node3D

class_name WallBlock

const GridCoordRef = preload("res://src/core/grid/grid_coord.gd")

const WALL_HEIGHT := 1.0

var grid_position: Vector2i = Vector2i.ZERO
var blocks_grid_cell := true

var _grid_motor: Node

func _ready() -> void:
	add_to_group("grid_entity")
	add_to_group("wall_block")
	add_to_group("wall")  # grid_motor.gd checks is_in_group("wall")

	grid_position = GridCoordRef.world_to_grid(global_position)
	global_position = GridCoordRef.grid_to_world(grid_position, WALL_HEIGHT)

	## Register synchronously — deferred registration causes a race where the
	## entity is not yet in the grid motor's occupiers map when collision
	## checks run, letting the player walk through walls.
	_bind_grid_motor()

func _bind_grid_motor() -> void:
	_grid_motor = get_tree().get_first_node_in_group("grid_motor")
	if _grid_motor != null:
		_grid_motor.register_entity(self)
