extends SceneTree
const Progression = preload("res://scripts/progression.gd")
const Combat = preload("res://scripts/combat.gd")
const Dungeon = preload("res://scripts/dungeon.gd")
const BOUNDS := Rect2(32, 174, 416, 422)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var p = Progression.new()
	p.add_xp(3)
	assert(p.level == 1 and p.xp == 3 and p.pending == 0)
	p.add_xp(3)
	assert(p.level == 2 and p.xp == 2 and p.pending == 1)
	assert(p.offers.size() == 3 and p.offers[0] != p.offers[1] and p.offers[2] == "coins")
	var rolled = p.offers.duplicate()
	p.add_xp(0)
	assert(p.offers == rolled, "Offers must not reroll before selection")
	assert(p.choose(-1) == "" and p.pending == 1)
	assert(p.choose(2) == "coins" and p.coins == 20 and p.pending == 0)
	assert(p.choose(2) == "", "Reward cannot be claimed twice")
	p.add_xp(12)
	assert(p.level == 4 and p.pending == 2 and p.xp == 0, "Overflow XP queues every earned choice")
	p.choose(0)
	assert(p.pending == 1 and p.offers.size() == 3)
	p.choose(0)
	assert(p.pending == 0)

	var combat = Combat.new(BOUNDS, [])
	var state := {"enemies": [], "pickups": [{"pos": Vector2(240, 530), "amount": 4}]}
	combat.enter(state, Vector2(240, 530))
	combat.tick(1.0 / 60, Vector2(240, 530))
	assert(state["pickups"].is_empty() and combat.progression.pending == 1)
	combat.enemies.append({"pos": Vector2(240, 530), "hp": 3, "flash": 0.0, "repath": 0.0, "path": PackedVector2Array()})
	combat.hurt_time = 0
	combat.grace_time = 0
	combat.tick(10, Vector2(240, 530))
	assert(combat.health == 6 and combat.enemies[0]["hp"] == 3, "Combat must freeze while choosing")
	combat.progression.offers.assign(["damage", "health", "coins"])
	assert(combat.apply_choice(0) and combat.progression.damage() == 2)
	combat.progression.add_xp(combat.progression.required_xp())
	combat.progression.offers.assign(["health", "damage", "coins"])
	combat.health = 3
	combat.apply_choice(0)
	assert(combat.health == 5 and combat.progression.max_health() == 8)

	var dungeon = Dungeon.new()
	combat.enter(dungeon.rooms[Vector2i.ZERO], Vector2(240, 530))
	combat.pickups.append({"pos": Vector2(240, 270), "amount": 2})
	combat.enter(dungeon.rooms[Vector2i(1, 0)], Vector2(72, 385))
	assert(combat.progression.damage() == 2, "Upgrades must survive room travel")
	combat.enter(dungeon.rooms[Vector2i.ZERO], Vector2(240, 530))
	assert(combat.pickups.size() == 1, "Uncollected XP must survive revisits")

	# A piercing shot can hit two targets, but never the same target twice.
	combat = Combat.new(BOUNDS, [])
	combat.progression.ranks["piercing"] = 1
	state = {"enemies": [], "pickups": []}
	for y in [400, 360]:
		state["enemies"].append({"pos": Vector2(240, y), "hp": 3, "flash": 0.0, "repath": 999.0, "path": PackedVector2Array()})
	combat.enter(state, Vector2(240, 530))
	combat.fire_time = 0
	combat.tick(0.5, Vector2(240, 530))
	assert(state["enemies"][0]["hp"] == 2 and state["enemies"][1]["hp"] == 2)

	var room = load("res://scenes/room.tscn").instantiate()
	root.add_child(room)
	room.hub.enabled = false
	room.hub.training = 0
	room.hub.seals = 0
	room.start_game()
	room.combat.progression.add_xp(4)
	room._show_level_up()
	var pos: Vector2 = room.player
	room.move_player(Vector2(0, -50))
	assert(room.player == pos and room.level_panel.visible, "Choice overlay must freeze movement")
	room._choose_upgrade(2)
	assert(not room.level_panel.visible and room.combat.progression.coins == 20)
	room.restart_run()
	assert(room.combat.progression.level == 1 and room.combat.progression.coins == 0 and room.combat.progression.damage() == 1)
	assert(not room.level_panel.visible)
	print("PASS: XP thresholds, overflow, distinct stable offers, coins, upgrades, pause, piercing, persistence, restart")
	room.queue_free()
	quit(0)
