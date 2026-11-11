extends Node2D
## Static architecture keeps its canvas draw list until the room/floor changes.
const Architecture = preload("res://scripts/room_architecture.gd")
var layout := 0
var floor_number := 1
var neighbors: Array[Vector2i] = []
var revision := 0
func configure(next_layout: int, next_floor: int, exits: Array[Vector2i]) -> void:
	layout = next_layout; floor_number = next_floor; neighbors = exits.duplicate(); revision += 1
	queue_redraw()
func _draw() -> void:
	Architecture.draw_static(self,layout,floor_number,neighbors)
