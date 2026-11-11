extends Node2D
## One complete room painting. Canvas geometry is cached until entry changes it.
const Backgrounds = preload("res://scripts/room_backgrounds.gd")
const DoorShader = preload("res://scripts/room_doors.gdshader")
var layout := 0
var floor_number := 1
var neighbors: Array[Vector2i] = []
var revision := 0
func configure(next_layout: int, next_floor: int, exits: Array[Vector2i]) -> void:
	layout = next_layout; floor_number = next_floor; neighbors = exits.duplicate(); revision += 1
	if material==null:
		material = ShaderMaterial.new(); material.shader = DoorShader
	material.set_shader_parameter("exits",Vector4(1 if Vector2i.UP in exits else 0,1 if Vector2i.RIGHT in exits else 0,1 if Vector2i.DOWN in exits else 0,1 if Vector2i.LEFT in exits else 0))
	queue_redraw()
func _draw() -> void:
	draw_texture_rect(Backgrounds.texture(layout),Backgrounds.RECT,false)
