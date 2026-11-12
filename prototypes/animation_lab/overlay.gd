@tool
extends Node2D
@export var contacts := false
func _draw() -> void:
	if get_parent().has_method("draw_overlay"): get_parent().draw_overlay(self,contacts)
