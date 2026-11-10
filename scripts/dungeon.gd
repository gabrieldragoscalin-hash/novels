extends RefCounted
## Generate once per run; base identities persist through three floors.
const SIZE := Vector2i(5, 5)
const SERVICES := ["shop", "trader", "upgrade", "wheel", "healer"]
const MAX_FLOOR := 3
var current := Vector2i.ZERO
var start := Vector2i.ZERO
var exit := Vector2i.ZERO
var start_edge := 0
var floor_number := 1
var completed := false
var seed_value: int
var rooms: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _init(run_seed: int = -1) -> void:
	if run_seed < 0:
		rng.randomize()
		rng.seed = rng.randi_range(0, 2147483647)
	else: rng.seed = run_seed
	seed_value = rng.seed
	for y in range(5):
		for x in range(5): rooms[Vector2i(x, y)] = {"base": "empty", "service_index": -1, "trap": -1}
	_choose_endpoints(true)
	var cells: Array = []
	for cell in rooms:
		if cell != start and cell != exit: cells.append(cell)
	_shuffle(cells)
	var types: Array = ["bonus", "bonus", "bonus", "bonus", "bonus"]
	for spec in [["combat", 7], ["empty", 3], ["loot", 4], ["trap", 4]]:
		for i in range(spec[1]): types.append(spec[0])
	for i in range(cells.size()):
		rooms[cells[i]]["base"] = types[i]
		if types[i] == "bonus": rooms[cells[i]]["service_index"] = i
	_prepare_floor()

func _shuffle(values: Array) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp = values[i]
		values[i] = values[j]
		values[j] = temp

func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < 5 and cell.y < 5

func _choose_endpoints(initial: bool = false) -> void:
	var options: Array = []
	for edge in range(4):
		for cell in rooms:
			var on_edge: bool = (edge == 0 and cell.y == 0) or (edge == 1 and cell.y == 4) or (edge == 2 and cell.x == 0) or (edge == 3 and cell.x == 4)
			if not on_edge or rooms[cell]["base"] == "bonus" or (not initial and cell == start): continue
			for destination in rooms:
				var opposite: bool = (edge == 0 and destination.y >= 3) or (edge == 1 and destination.y <= 1) or (edge == 2 and destination.x >= 3) or (edge == 3 and destination.x <= 1)
				if opposite and rooms[destination]["base"] != "bonus" and (initial or destination != exit):
					options.append([cell, destination, edge])
	var choice: Array = options[rng.randi_range(0, options.size() - 1)]
	start = choice[0]
	exit = choice[1]
	start_edge = choice[2]

func _prepare_floor() -> void:
	for cell in rooms:
		var state: Dictionary = rooms[cell]
		var previous_trap: int = state["trap"]
		var base: String = state["base"]
		var service_index: int = state["service_index"]
		state.clear()
		state.merge({"base": base, "service_index": service_index, "trap": previous_trap})
		state.merge({"visits": 0, "enemies": [], "pickups": [], "room_paid": false, "used": false, "boss_paid": false, "stock": {}, "reward": "", "trap_time": 1.0}, true)
		state["role"] = "start" if cell == start else ("boss" if cell == exit else state["base"])
		state["service"] = SERVICES[(state["service_index"] + floor_number - 1) % 5] if state["base"] == "bonus" else ""
		if state["base"] == "trap":
			var traps := [0, 1, 2]
			traps.erase(previous_trap)
			state["trap"] = traps[rng.randi_range(0, traps.size() - 1)]
		var role: String = state["role"]
		if role == "boss":
			state["enemies"].append(make_enemy(Vector2(240, 270), "boss", floor_number))
		elif role == "combat" or (role == "loot" and floor_number >= 2) or (role == "empty" and floor_number >= 3):
			var count := 2 + floor_number if role == "combat" else (floor_number if role == "loot" else 2)
			var tier := 2 if role == "empty" else floor_number
			var spawns := [Vector2(240, 270), Vector2(192, 385), Vector2(288, 385), Vector2(240, 510), Vector2(72, 250)]
			for i in range(count):
				var kind := "normal"
				if role != "empty" and i == 1: kind = "shooter"
				if role != "empty" and i == 2: kind = "brute"
				state["enemies"].append(make_enemy(spawns[i], kind, tier))
	current = start
	enter(current)

static func make_enemy(pos: Vector2, kind: String, tier: int) -> Dictionary:
	var hp := 3 + (tier - 1) * 2
	if kind == "brute": hp *= 2
	if kind == "boss": hp = 22 + (tier - 1) * 16
	return {"pos": pos, "hp": hp, "max_hp": hp, "kind": kind, "tier": tier, "flash": 0.0, "repath": 0.0, "path": PackedVector2Array(), "attack": 1.5, "telegraph": 0.0, "aim": Vector2.DOWN}

func enter(cell: Vector2i) -> bool:
	if not contains(cell): return false
	current = cell
	rooms[cell]["visits"] += 1
	return true

func advance() -> bool:
	if completed: return false
	if floor_number >= MAX_FLOOR:
		completed = true
		return false
	floor_number += 1
	_choose_endpoints()
	_prepare_floor()
	return true

func room_name() -> String:
	return String.chr(65 + current.x) + str(current.y + 1)

func bonus_flares() -> int:
	return 5 * (1 + int((floor_number - 1) / 5))

func boss_flares() -> int:
	return 50 + 10 * (floor_number - 1)

func empty_flares() -> int:
	return floor_number + 2 if floor_number >= 3 else 0
