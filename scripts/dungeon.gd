extends RefCounted
## Room state survives travel; encounters and floor progression come later.
const SIZE := Vector2i(5, 5)
var current := Vector2i.ZERO
var rooms: Dictionary = {}

func _init() -> void:
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			rooms[Vector2i(x, y)] = {"visits": 0}
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
