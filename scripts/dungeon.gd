extends RefCounted
## Generate once per run; base identities persist through five floors.
const SIZE := Vector2i(5, 5)
const SERVICES := ["shop", "trader", "upgrade", "wheel", "healer"]
const MAX_FLOOR := 5
const Balance = preload("res://scripts/combat_balance.gd")
const NORMAL_HP = Balance.NORMAL_HP
const SHOOTER_HP = Balance.SHOOTER_HP
const BRUTE_HP = Balance.BRUTE_HP
const BOSS_HP = Balance.BOSS_HP
const ENEMY_SPEEDS := [75.0,90.0,105.0,112.0,120.0]
const SHOT_SPEEDS := [160.0,190.0,220.0,240.0,260.0]
const SHOT_INTERVALS := [2.4,2.1,1.8,1.65,1.5]
const CHARGE_WARNINGS := [0.9,0.8,0.7,0.65,0.6]
const ENCOUNTERS := ["mixed","swarm","crossfire","heavy","ambush"]
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
	var encounter_index := 0
	for i in range(cells.size()):
		rooms[cells[i]]["base"] = types[i]
		if types[i]=="combat":
			rooms[cells[i]]["encounter_index"] = encounter_index%ENCOUNTERS.size()
			encounter_index += 1
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
		var encounter_index: int = state.get("encounter_index",-1)
		state.clear()
		state.merge({"base": base, "service_index": service_index, "trap": previous_trap,"encounter_index":encounter_index})
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
		elif role == "combat":
			_spawn_encounter(state,cell)
		elif role == "loot" and floor_number >= 2:
			if floor_number == 5:
				state["encounter"] = "treasure guardian"
				state["enemies"].append(make_enemy(Vector2(240,270),"miniboss",5))
			else:
				for i in range(floor_number): state["enemies"].append(make_enemy(_spawn_points()[i],"shooter" if i==1 else "normal",floor_number))
		elif role == "empty" and floor_number >= 3:
			for i in range(2): state["enemies"].append(make_enemy(_spawn_points()[i],"normal",2 if floor_number<=4 else 3))
	current = start
	enter(current)

static func _spawn_points() -> Array[Vector2]:
	return [Vector2(240,270),Vector2(192,385),Vector2(288,385),Vector2(240,510),Vector2(72,250),Vector2(408,250),Vector2(72,540),Vector2(408,540)]

func _spawn_encounter(state: Dictionary, _cell: Vector2i) -> void:
	# Deterministic per location: room identity and encounter style persist each floor.
	var style: String = ENCOUNTERS[state["encounter_index"]]
	state["encounter"] = style
	var count := floor_number+3
	var spawns := _spawn_points()
	for i in range(count):
		var kind := "normal"
		match style:
			"mixed", "ambush": kind = "brute" if i==2 else ("shooter" if i%3==1 else "normal")
			"swarm": kind = "shooter" if i==count-1 else "normal"
			"crossfire": kind = "shooter" if i%2==0 else "normal"
			"heavy": kind = "brute" if i%4==0 else ("shooter" if i%4==1 else "normal")
		var enemy := make_enemy(spawns[i],kind,floor_number)
		if style == "swarm" and kind == "normal":
			enemy["hp"] = maxi(2,int(ceil(enemy["hp"]*0.65))); enemy["max_hp"] = enemy["hp"]
			enemy["speed_multiplier"] = 1.1
		if style == "ambush" and i>=int(ceil(count/2.0)): enemy["dormant"] = true
		# Initial firing times are staggered, avoiding simultaneous room-entry volleys.
		enemy["attack"] = 0.9+i*0.18
		state["enemies"].append(enemy)

static func make_enemy(pos: Vector2, kind: String, tier: int) -> Dictionary:
	var index := clampi(tier-1,0,MAX_FLOOR-1)
	var hp: int = NORMAL_HP[index]
	if kind == "shooter": hp = SHOOTER_HP[index]
	if kind == "brute": hp = BRUTE_HP[index]
	if kind == "boss": hp = BOSS_HP[index]
	if kind == "miniboss": hp = Balance.GUARDIAN_HP
	return {"pos":pos,"hp":hp,"max_hp":hp,"kind":kind,"tier":tier,"flash":0.0,"repath":0.0,"path":PackedVector2Array(),"attack":1.5,"telegraph":0.0,"aim":Vector2.DOWN,"action":"","phase":"idle","phase_time":0.0,"sequence":0,"burst_left":0,"burst_time":0.0,"dormant":false}

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
