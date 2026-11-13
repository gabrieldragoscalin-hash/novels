extends SceneTree
const Combat = preload("res://scripts/combat.gd")
const Dungeon = preload("res://scripts/dungeon.gd")
const Hub = preload("res://scripts/hub.gd")
const BOUNDS := Rect2(32, 174, 416, 422)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:

	var combat = Combat.new(BOUNDS, [])
	var state := {"role": "trap", "enemies": [], "pickups": [], "trap": 0, "trap_time": 0.01}
	combat.enter(state, Vector2(240, 385))
	combat.grace_time = 0
	combat.tick(0.02, Vector2(240, 385))
	assert(combat.progression.slow_time > 0 and combat.progression.movement_multiplier() < 1)
	state["trap"] = 1
	state["trap_time"] = 0.01
	combat.tick(0.02, Vector2(240, 385))
	assert(combat.health == 5)
	state["trap"] = 2
	state["trap_time"] = 0.01
	combat.tick(0.02, Vector2(240, 385))
	assert(combat.hostile_bullets.size() == 3)
	combat.hurt_time = 0
	combat.tick(1.5, Vector2(240, 385))
	assert(combat.health == 4 and combat.progression.flares == 0)

	combat = Combat.new(BOUNDS, [])
	state = {"role": "boss", "enemies": [Dungeon.make_enemy(Vector2(240, 270), "boss", 1)], "pickups": [], "boss_paid": false}
	combat.enter(state, Vector2(240, 530))
	combat.fire_time = 999
	combat.tick(1.6, Vector2(240, 530))
	assert(combat.enemies[0]["telegraph"] > 0 and combat.hostile_bullets.is_empty())
	combat.tick(0.7, Vector2(240, 530))
	assert(combat.hostile_bullets.size() > 0)
	# Boss-room additions can award XP but never flares.
	combat = Combat.new(BOUNDS, [])
	state = {"role": "boss", "enemies": [Dungeon.make_enemy(Vector2(240, 400), "normal", 1)], "pickups": [], "boss_paid": false}
	combat.enter(state, Vector2(240, 530))
	combat.progression.base_damage = 6 # Reward-path fixture, independent of card tuning.
	combat.fire_time = 0
	combat.tick(0.5, Vector2(241, 530))
	assert(combat.kills == 1 and combat.progression.flares == 0)

	var room = load("res://scenes/room.tscn").instantiate()
	root.add_child(room)
	room.hub = load("res://scripts/hub.gd").new(false)
	room.seed_override = 9
	room.start_game()
	room.set_physics_process(false)
	for result in range(5):
		room.hub.coins = 0
		room.restart_run()
		enter_service(room, "wheel")
		room.combat.health = 3
		room.combat.progression.ranks["damage"] = 1
		var bonus_flares: int = room.combat.progression.flares
		for seed_value in range(1000):
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			if rng.randi_range(0, 4) == result:
				room.dungeon.rng.seed = seed_value
				break
		room._spin_wheel()
		await create_timer(1.1).timeout
		assert(not room.wheel_spinning and room.services.state()["used"])
		assert(int(fposmod(-PI / 2 - room.wheel_rotation, TAU) / (TAU / 5)) == result, "Wheel pointer must match its reward sector")
		room.services.enter()
		assert(room.combat.progression.flares == bonus_flares, "Wheel shop cannot repeat entrance reward")
		match result:
			0: assert(room.combat.health == 6)
			1: assert(room.combat.progression.coins == 20)
			2:
				assert(room.combat.progression.offers.size() == 3 and not room.combat.progression.offers.has("coins"))
				await create_timer(1.5).timeout
				room._choose_upgrade(0)
			3:
				room._trade_select_old("damage")
				var offered: Array[String] = room.services.state()["trade_offers"]["damage"]
				assert(offered.size() == 3)
				room._trade_finish("damage", offered[0], offered)
				assert(room.combat.progression.ranks["damage"] == 0 and room.combat.progression.ranks[offered[0]] == 1)
			4: assert(room.services.state()["summoned_shop"] and room.service_panel.visible)
		room._close_service()
	room.hub.coins = 0
	room.restart_run()
	enter_service(room, "upgrade")
	room._interact()
	assert(room.level_panel.visible and room.combat.progression.offers.size() == 3)
	await create_timer(1.5).timeout
	room._choose_upgrade(2)
	room._interact()
	assert(room.combat.progression.pending == 0 and room.combat.progression.coins == 0)
	room.restart_run()
	enter_service(room, "healer")
	room.combat.health = 2
	room._interact()
	assert(room.combat.health == 6)
	room.combat.health = 3
	room._interact()
	assert(room.combat.health == 3, "Healing can only be used once per floor")
	print("PASS: hub save/reload, all trap effects, boss telegraph/volley, summon rewards, all 5 wheel outcomes, free upgrade, healer, finite services")
	room.queue_free()
	quit(0)

func enter_service(room: Node, service: String) -> void:
	for cell in room.dungeon.rooms:
		if room.dungeon.rooms[cell]["service"] == service:
			room.dungeon.enter(cell)
			room._enter_current()
			return
	assert(false, "Required service missing")
