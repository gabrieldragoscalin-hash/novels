extends RefCounted
## Room and enemy state survives travel; floor progression comes later.
const SIZE := Vector2i(5, 5)
var current := Vector2i.ZERO
var rooms: Dictionary = {}

func _init() -> void:
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			var enemies: Array = []
			# Deterministic test encounters; final room generation comes later.
			if (x + 2 * y) % 4 != 0:
				var spawns := [Vector2(240, 270), Vector2(192, 385), Vector2(288, 385)]
				for i in range(1 + (x + y) % 3):
					enemies.append({"pos": spawns[i], "hp": 3, "flash": 0.0, "repath": 0.0, "path": PackedVector2Array()})
			rooms[Vector2i(x, y)] = {"visits": 0, "enemies": enemies}
	enter(current)

func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < SIZE.x and cell.y < SIZE.y

func enter(cell: Vector2i) -> bool:
	if not contains(cell): return false
	current = cell
	rooms[cell]["visits"] += 1
	return true

func room_name() -> String:
	return String.chr(65 + current.x) + str(current.y + 1)
