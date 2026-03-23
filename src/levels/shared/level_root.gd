extends Node3D

class_name LevelRoot

signal hint_requested(text: String)
signal level_completed

@export_multiline var start_hint_text := "把箱子推到机关上，读懂状态变化，再走到发光终点。"
@export_multiline var completed_hint_text := "本关完成。按 R 可以重开。"

var is_level_completed := false

func _ready() -> void:
	add_to_group("level_root")
	hint_requested.emit(start_hint_text)

func complete_level() -> void:
	if is_level_completed:
		return

	is_level_completed = true

	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.set("input_enabled", false)

	hint_requested.emit(completed_hint_text)
	level_completed.emit()
