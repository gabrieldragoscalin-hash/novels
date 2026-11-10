extends SceneTree
const Dungeon = preload("res://scripts/dungeon.gd")
const Combat = preload("res://scripts/combat.gd")
const Hub = preload("res://scripts/hub.gd")
const Services = preload("res://scripts/services.gd")
const BOUNDS := Rect2(32, 174, 416, 422)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for seed_value in range(80):
		var d = Dungeon.new(seed_value)
		var same = Dungeon.new(seed_value)
		assert(d.start == same.start and d.exit == same.exit)
		var base := {}
		var previous_traps := {}
		var previous_services := {}
		var previous_start: Vector2i = d.start
		var previous_exit: Vector2i = d.exit
		for f in range(1, 4):
			var counts := {}
			var services_seen := {}
			assert(d.rooms[d.start]["base"] != "bonus" and d.rooms[d.exit]["base"] != "bonus")
			assert(d.current == d.start)
			assert((d.start_edge == 0 and d.start.y == 0 and d.exit.y >= 3) or (d.start_edge == 1 and d.start.y == 4 and d.exit.y <= 1) or (d.start_edge == 2 and d.start.x == 0 and d.exit.x >= 3) or (d.start_edge == 3 and d.start.x == 4 and d.exit.x <= 1))
			for cell in d.rooms:
				var state: Dictionary = d.rooms[cell]
				counts[state["role"]] = counts.get(state["role"], 0) + 1
				if f == 1: base[cell] = state["base"]
				else: assert(base[cell] == state["base"], "Base identities must persist")
				if state["base"] == "bonus":
					services_seen[state["service"]] = true
					if f > 1: assert(previous_services[cell] != state["service"])
					previous_services[cell] = state["service"]
				if state["base"] == "trap":
					if f > 1: assert(previous_traps[cell] != state["trap"])
					previous_traps[cell] = state["trap"]
				if state["role"] == "empty":
					assert(state["enemies"].is_empty() if f < 3 else state["enemies"].size() == 2)
					if f == 3:
						for enemy in state["enemies"]: assert(enemy["tier"] == 2)
				if state["role"] == "loot": assert(state["enemies"].is_empty() if f == 1 else not state["enemies"].is_empty())
			assert(services_seen.size() == 5)
			assert(d.rooms[d.exit]["enemies"].size() == 1 and d.rooms[d.exit]["enemies"][0]["kind"] == "boss")
			if f == 1:
				for spec in [["start",1],["boss",1],["bonus",5],["combat",7],["empty",3],["loot",4],["trap",4]]: assert(counts[spec[0]] == spec[1])
			if f < 3:
				for cell in d.rooms:
					d.rooms[cell]["summoned_shop"] = true
					d.rooms[cell]["trade_used"] = true
				assert(d.advance())
				for state in d.rooms.values(): assert(not state.has("summoned_shop") and not state.has("trade_used"), "Temporary service state must reset each floor")
				assert(d.start != previous_start and d.exit != previous_exit)
				previous_start = d.start
				previous_exit = d.exit
		assert(not d.advance() and d.completed and d.floor_number == 3)
		assert(not d.advance() and d.floor_number == 3)

	var d = Dungeon.new(9)
	var c = Combat.new(BOUNDS, [])
	var h = Hub.new(false)
	var rules = Services.new(d, c, h)
	for cell in d.rooms:
		if d.rooms[cell]["role"] == "bonus":
			d.enter(cell)
			c.enter(d.rooms[cell], Vector2(240, 530))
			rules.enter()
			rules.enter()
	assert(c.progression.flares == 25, "Bonus entrance reward is once per floor")
	for cell in d.rooms:
		if d.rooms[cell]["role"] == "loot":
			d.enter(cell)
			c.enter(d.rooms[cell], Vector2(240, 530))
			assert(rules.loot())
			assert(not rules.loot())
	assert(c.progression.flares == 65 and c.progression.coins == 80)
	# Purchases consume funds once and permanent items belong to the hub immediately.
	for cell in d.rooms:
		if d.rooms[cell]["service"] == "shop": d.enter(cell); break
	assert(rules.buy("key") == "Purchased." and h.keys == 1 and c.progression.coins == 60)
	assert(rules.buy("key") != "Purchased." and h.keys == 1)
	assert(h.train() and h.training == 1 and h.keys == 0)
	assert(rules.buy("seal") == "Purchased." and h.seals == 1)
	assert(rules.buy("coins") == "Purchased.")
	var flares: int = c.progression.flares
	assert(rules.buy("upgrade") == "Purchased." and c.progression.pending == 1)
	assert(c.progression.flares == flares - 20)
	c.apply_choice(2)
	c.progression.ranks["damage"] = 1
	for cell in d.rooms:
		if d.rooms[cell]["service"] == "trader": d.enter(cell); break
	var offered: Array[String] = rules.trade_options("damage")
	assert(offered.size() == 3)
	assert(rules.trade("damage", offered[0], offered))
	assert(not rules.trade("damage", offered[1], offered))

	# Play actual boss combat on each floor; advance through the controller.
	var room = load("res://scenes/room.tscn").instantiate()
	root.add_child(room)
	room.hub.enabled = false
	room.hub.training = 0
	room.hub.seals = 0
	room.seed_override = 9
	room.start_game()
	room.set_physics_process(false)
	room.combat.progression.base_health = 100
	room.combat.health = 100
	room.combat.progression.ranks["damage"] = 7
	for f in range(1, 4):
		room.dungeon.enter(room.dungeon.exit)
		room.player = Vector2(240, 530)
		room._enter_current()
		room._advance_floor()
		assert(room.dungeon.floor_number == f, "A living boss must gate progression")
		var before: int = room.combat.progression.flares
		for frame in range(1800):
			room.combat.tick(1.0 / 60, room.player)
			while room.combat.progression.pending > 0: room.combat.apply_choice(2)
			if room.combat.alive_count() == 0: break
		assert(room.combat.alive_count() == 0, "Boss must be defeatable with real projectiles")
		assert(room.combat.progression.flares == before + 50 + (f - 1) * 10)
		room._advance_floor()
		if f < 3:
			await room.transition_finished
			assert(room.dungeon.floor_number == f + 1 and room.combat.progression.damage() == 8)
		else: assert(room.dungeon.completed and not room.active and room.death_panel.visible)
	# Floor-three empty rooms award tier-two enemy flares plus the one-time room reward.
	for cell in room.dungeon.rooms:
		if room.dungeon.rooms[cell]["role"] == "empty":
			room.dungeon.enter(cell)
			room._enter_current()
			room.combat.progression.pending = 0
			var before: int = room.combat.progression.flares
			for enemy in room.combat.enemies: enemy["hp"] = 0
			room.combat.tick(0.01, room.player)
			room.combat.tick(0.01, room.player)
			assert(room.combat.progression.flares == before + 5)
			break
	print("PASS: 80 seeded maps × 3 floors, identity, S/E, room counts, services, traps, rewards, purchases, hub, real boss combat, floor cap, awakened empty rooms")
	room.queue_free()
	quit(0)
