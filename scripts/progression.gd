extends RefCounted
## All values belong to one run. Upgrade offers are generated once per level.
const UPGRADES := {
	"damage": ["Heavy bolts", "+1 damage per shot"],
	"attack_speed": ["Quick draw", "Fire 15% faster"],
	"movement": ["Light feet", "+10% movement speed"],
	"piercing": ["Piercing bolts", "Pass through 1 additional enemy"],
	"health": ["Vitality", "+2 max HP and heal 2 HP"],
	"critical": ["Deadeye", "+10% chance for double damage"],
	"multishot": ["Split volley", "+1 side bolt per attack"],
	"ricochet": ["Ricochet", "Bolts bounce off 1 additional wall"],
	"frost": ["Frostbite", "Hits slow enemies for 2 seconds"],
	"burn": ["Ember touch", "Hits burn for +1 damage/s for 3s"],
	"magnet": ["Gatherer", "+40 XP pickup attraction range"],
	"experience": ["Fast learner", "+20% experience gained"],
	"regeneration": ["Second wind", "Recover 1 HP every 12s (faster per rank)"]
}
const CAPS := {"attack_speed": 8, "movement": 5, "piercing": 5, "critical": 5, "multishot": 2, "ricochet": 2, "frost": 3, "burn": 3, "magnet": 4, "experience": 3, "regeneration": 3}
var weapon := "bow"
var weapon_level := 1
var base_damage := 1
var base_interval := 0.45
var projectile_speed := 390.0
var base_pierce := 0
var base_critical := 0.0
var gear_movement := 0.0
var gear_xp := 0.0
var base_health := 6
var level := 1
var xp := 0
var wallet
var local_coins := 0
var coins: int:
	get: return int(wallet.coins) if wallet != null else local_coins
	set(value):
		if wallet != null:
			wallet.coins = maxi(0,value)
			wallet.save()
		else: local_coins = maxi(0,value)
var dodge_chance := 0.0
var boss_damage_bonus := 0.0
var flares := 0
var slow_time := 0.0
var pending := 0
var ranks: Dictionary = {}
var offers: Array[String] = []
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()
	for id in UPGRADES: ranks[id] = 0

func required_xp() -> int:
	return 4 + (level - 1) * 2

func add_xp(amount: int) -> void:
	if amount <= 0: return
	xp += amount
	while xp >= required_xp():
		xp -= required_xp()
		level += 1
		pending += 1
	if pending > 0 and offers.is_empty(): _roll_offers()

func _roll_offers() -> void:
	var pool := available_upgrades()
	offers.clear()
	for i in range(2):
		var index := rng.randi_range(0, pool.size() - 1)
		offers.append(pool[index])
		pool.remove_at(index)
	offers.append("coins")

func coin_reward() -> int:
	return 20

func choose(index: int) -> String:
	if pending <= 0 or index < 0 or index >= offers.size(): return ""
	var id := offers[index]
	if id == "coins": coins += coin_reward()
	else: ranks[id] += 1
	pending -= 1
	offers.clear()
	if pending > 0: _roll_offers()
	return id

func damage() -> int:
	return base_damage + ranks["damage"]

func fire_interval() -> float:
	return base_interval / pow(1.15, ranks["attack_speed"])

func movement_multiplier() -> float:
	return (1.0 + gear_movement + ranks["movement"] * 0.1) * (0.65 if slow_time > 0 else 1.0)

func max_health() -> int:
	return base_health + ranks["health"] * 2

func available_upgrades() -> Array[String]:
	var pool: Array[String] = []
	for id in UPGRADES:
		if CAPS.has(id) and ranks[id] >= CAPS[id]: continue
		pool.append(id)
	return pool

func reward_choices(count: int = 2, with_coins: bool = true) -> void:
	pending += 1
	offers.clear()
	var pool := available_upgrades()
	for i in range(mini(count, pool.size())):
		var index := rng.randi_range(0, pool.size() - 1)
		offers.append(pool[index])
		pool.remove_at(index)
	if with_coins: offers.append("coins")

func xp_multiplier() -> float:
	return 1.0 + gear_xp + ranks["experience"] * 0.2

func critical_chance() -> float:
	return minf(0.75, base_critical + ranks["critical"] * 0.1)

func apply_loadout(stats: Dictionary) -> void:
	weapon = stats["weapon"]
	weapon_level = stats["level"]
	base_damage = stats["damage"]
	base_interval = stats["interval"]
	projectile_speed = stats["projectile_speed"]
	base_pierce = stats["pierce"]
	base_critical = stats["critical"]
	gear_movement = stats["movement"]
	gear_xp = stats["xp"]
	base_health += stats["health"]
