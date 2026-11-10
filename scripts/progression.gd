extends RefCounted
## All values belong to one run. Upgrade offers are generated once per level.
const UPGRADES := {
	"damage": ["Heavy bolts", "+1 damage per shot"],
	"attack_speed": ["Quick draw", "Fire 15% faster"],
	"movement": ["Light feet", "+10% movement speed"],
	"piercing": ["Piercing bolts", "Pass through 1 additional enemy"],
	"health": ["Vitality", "+2 max HP and heal 2 HP"]
}
var level := 1
var xp := 0
var coins := 0
var pending := 0
var ranks: Dictionary = {"damage": 0, "attack_speed": 0, "movement": 0, "piercing": 0, "health": 0}
var offers: Array[String] = []
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

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
	var pool: Array[String] = []
	for id in UPGRADES:
		if id == "piercing" and ranks[id] >= 5: continue
		if id == "movement" and ranks[id] >= 5: continue
		if id == "attack_speed" and ranks[id] >= 8: continue
		pool.append(id)
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
	return 1 + ranks["damage"]

func fire_interval() -> float:
	return 0.45 / pow(1.15, ranks["attack_speed"])

func movement_multiplier() -> float:
	return 1.0 + ranks["movement"] * 0.1

func max_health() -> int:
	return 6 + ranks["health"] * 2
