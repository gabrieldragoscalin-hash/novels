extends SceneTree
const Combat = preload("res://scripts/combat.gd")
const Dungeon = preload("res://scripts/dungeon.gd")
const BOUNDS := Rect2(32, 174, 416, 422)
const PILLARS: Array[Rect2] = [Rect2(108, 290, 38, 40), Rect2(334, 290, 38, 40), Rect2(108, 456, 38, 40), Rect2(334, 456, 38, 40)]

func enemy_at(pos: Vector2) -> Dictionary:
	return {"pos": pos, "hp": 3, "flash": 0.0, "repath": 0.0, "path": PackedVector2Array()}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var combat = Combat.new(BOUNDS, PILLARS)
	var state := {"enemies": [enemy_at(Vector2(240, 270))]}
	combat.enter(state, Vector2(240, 530))
	for frame in range(180):
		combat.tick(1.0 / 60, Vector2(220 + frame * 0.15, 530))
	assert(combat.kills == 1 and combat.alive_count() == 0, "Auto-fire must defeat enemies while player moves")
	assert(combat.health == combat.MAX_HEALTH)

	combat = Combat.new(BOUNDS, PILLARS)
	state = {"enemies": [enemy_at(Vector2(180, 310))]}
	combat.enter(state, Vector2(90, 310))
	combat.fire_time = 999
	combat.bullets.append({"pos": Vector2(90, 310), "velocity": Vector2(390, 0), "life": 1.6})
	combat.tick(0.5, Vector2(90, 310))
	assert(state["enemies"][0]["hp"] == 3 and combat.bullets.is_empty(), "Pillars must stop bullets, even on slow frames")
	combat.hurt_time = 999
	for frame in range(300):
		combat.tick(1.0 / 60, Vector2(90, 310))
		assert(not combat.blocked(state["enemies"][0]["pos"], 13), "Enemies must not walk through pillars")
	assert(state["enemies"][0]["pos"].distance_to(Vector2(90, 310)) < 30, "Enemy must navigate around the pillar")

	combat = Combat.new(BOUNDS, PILLARS)
	state = {"enemies": [enemy_at(Vector2(240, 530))]}
	combat.enemies = state["enemies"]
	combat.fire_time = 999
	combat.tick(1.0 / 60, Vector2(240, 530))
	assert(combat.health == 5)
	combat.tick(0.1, Vector2(240, 530))
	assert(combat.health == 5, "Contact must respect invulnerability")
	for hit in range(5):
		combat.hurt_time = 0
		combat.tick(1.0 / 60, Vector2(240, 530))
	assert(combat.health == 0)
	combat.tick(1, Vector2(240, 530))
	assert(combat.health == 0, "Death must stop further damage")

	var dungeon = Dungeon.new()
	combat = Combat.new(BOUNDS, PILLARS)
	var room_state: Dictionary = {"enemies": [enemy_at(Vector2(240, 270)), enemy_at(Vector2(192, 385))], "pickups": []}
	combat.enter(room_state, Vector2(72, 385))
	combat.enemies[0]["hp"] = 0
	combat.enemies[1]["hp"] = 1
	combat.bullets.append({"pos": Vector2.ZERO, "velocity": Vector2.ZERO, "life": 1})
	combat.enter(dungeon.rooms[Vector2i.ZERO], Vector2(408, 385))
	assert(combat.bullets.is_empty(), "Bullets cannot travel between rooms")
	combat.enter(room_state, Vector2(72, 385))
	assert(combat.enemies[0]["hp"] == 0 and combat.enemies[1]["hp"] == 1, "Dead and damaged enemies must retain state on revisit")

	var room = load("res://scenes/room.tscn").instantiate()
	root.add_child(room)
	room.hub = load("res://scripts/hub.gd").new(false)
	room.start_game()
	room.combat.health = 0
	room._physics_process(1.0 / 60)
	assert(not room.active and room.death_panel.visible, "Death must show restart interface")
	room.restart_run()
	assert(room.active and not room.death_panel.visible and room.combat.health == 6)
	assert(room.dungeon.current == room.dungeon.start and room.combat.kills == 0)
	print("PASS: moving auto-fire, kills, projectile walls, enemy navigation, contact damage, invulnerability, room persistence, death/restart")
	room.queue_free()
	quit(0)
