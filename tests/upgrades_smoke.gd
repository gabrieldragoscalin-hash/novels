extends SceneTree
const Combat = preload("res://scripts/combat.gd")
const Progression = preload("res://scripts/progression.gd")
const Dungeon = preload("res://scripts/dungeon.gd")
const BOUNDS := Rect2(32, 174, 416, 422)

func _initialize() -> void:
	call_deferred("run")

func encounter(pos: Vector2 = Vector2(240, 270), hp: int = 100):
	var c = Combat.new(BOUNDS, [])
	var enemy: Dictionary = Dungeon.make_enemy(pos, "normal", 1)
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	c.enter({"enemies": [enemy], "pickups": [], "role": "combat"}, Vector2(240, 530))
	c.fire_time = 0
	return c

func run() -> void:
	var c = encounter()
	c.progression.ranks["multishot"] = 2
	c.tick(0.01, Vector2(240, 530))
	assert(c.bullets.size() == 3 and c.bullets[0]["velocity"] != c.bullets[1]["velocity"])
	c = encounter(Vector2(240, 430), 10)
	c.progression.ranks["critical"] = 5
	for seed_value in range(100):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		if rng.randf() < 0.5:
			c.progression.rng.seed = seed_value
			break
	c.tick(0.25, Vector2(240, 530))
	assert(c.enemies[0]["hp"] == 8, "Critical bolts must deal double damage")
	c = Combat.new(BOUNDS, [])
	c.enter({"enemies": [], "pickups": []}, Vector2(240, 530))
	c.bullets.append({"pos": Vector2(430,385), "velocity": Vector2(390,0), "life": 1.6, "bounces": 1})
	c.tick(0.1, Vector2(240, 530))
	assert(c.bullets.size() == 1 and c.bullets[0]["velocity"].x < 0 and c.bullets[0]["bounces"] == 0)
	c = encounter(Vector2(240,430), 10)
	c.progression.ranks["frost"] = 2
	c.progression.ranks["burn"] = 2
	c.tick(0.25, Vector2(240,530))
	assert(c.enemies[0]["hp"] == 9 and c.enemies[0]["frost_time"] > 0)
	assert(is_equal_approx(c.enemies[0]["frost_strength"], 0.3))
	c.fire_time = 999
	c.tick(1, Vector2(240,530))
	assert(c.enemies[0]["hp"] == 7, "Burn must damage over time")
	c.tick(2, Vector2(240,530))
	assert(c.enemies[0]["hp"] == 3)
	c = encounter(Vector2(240,430), 2)
	c.progression.ranks["burn"] = 2
	c.tick(0.25, Vector2(240,530))
	c.fire_time = 999
	c.tick(1, Vector2(240,530))
	c.tick(1, Vector2(240,530))
	assert(c.kills == 1 and c.progression.flares == 1, "Burn kills award rewards exactly once")
	c = Combat.new(BOUNDS, [])
	var state := {"enemies": [], "pickups": [{"pos": Vector2(240,330), "amount": 2}]}
	c.enter(state, Vector2(240,530))
	c.tick(1, Vector2(240,530))
	assert(c.pickups.size() == 1)
	c.progression.ranks["magnet"] = 3
	c.tick(1, Vector2(240,530))
	assert(c.pickups.is_empty() and c.progression.xp == 2)
	c = Combat.new(BOUNDS, [])
	state = {"enemies": [], "pickups": []}
	for i in range(5): state["pickups"].append({"pos": Vector2(240,530), "amount": 2})
	c.enter(state, Vector2(240,530))
	c.progression.ranks["experience"] = 1
	c.progression.gear_xp = 0.1
	for i in range(10):
		while c.progression.pending > 0: c.apply_choice(2)
		c.tick(0.01, Vector2(240,530))
	assert(c.progression.level == 3 and c.progression.xp == 3, "XP bonuses must preserve fractional gains across pickups")
	c = Combat.new(BOUNDS, [])
	c.enter({"enemies": [], "pickups": []}, Vector2(240,530))
	c.health = 3
	c.progression.ranks["regeneration"] = 1
	c.tick(12.1, Vector2(240,530))
	assert(c.health == 4)
	c.health = 0
	c.tick(12.1, Vector2(240,530))
	assert(c.health == 0, "Regeneration cannot revive a dead character")
	var p = Progression.new()
	assert(p.UPGRADES.size() == 13)
	for id in p.CAPS: p.ranks[id] = p.CAPS[id]
	var pool: Array[String] = p.available_upgrades()
	assert(pool.size() == 2 and pool.has("damage") and pool.has("health"))
	assert(Dungeon.make_enemy(Vector2.ZERO,"normal",2)["hp"] == 9)
	assert(Dungeon.make_enemy(Vector2.ZERO,"normal",3)["hp"] == 18)
	print("PASS: multishot, critical damage, ricochet, frost, burn/rewards, magnet, fractional XP bonus, regeneration, caps, increased floor HP")
	quit(0)
