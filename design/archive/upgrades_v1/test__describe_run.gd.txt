extends SceneTree
func _initialize() -> void:
	var dungeon = load("res://scripts/dungeon.gd").new(9)
	var cells := []
	for cell in dungeon.rooms:
		var state: Dictionary = dungeon.rooms[cell]
		cells.append({"x": cell.x, "y": cell.y, "role": state["role"], "service": state["service"]})
	print(JSON.stringify({"seed": 9, "start": [dungeon.start.x, dungeon.start.y], "exit": [dungeon.exit.x, dungeon.exit.y], "rooms": cells}))
	quit()
