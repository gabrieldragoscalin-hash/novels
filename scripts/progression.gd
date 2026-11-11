extends RefCounted
## All values belong to one run. Upgrade offers are generated once per level.
const UPGRADES := {
	"damage":["Increased damage","+1 damage"],
	"attack_speed":["Increased attack speed","Attack 15% faster"],
	"movement":["Increased move speed","+10% movement speed"],
	"experience":["Increased EXP gain","+20% experience gained"],
	"piercing":["Punchthrough","Pass through one more enemy"],
	"multishot":["Extra projectile","+1 parallel projectile"],
	"multiple_shots":["Multiple Shots","+1 sequential attack per cycle"],
	"ricochet":["Ricochet","Bounce to one more enemy; never off walls"],
	"follow":["Follow","Projectiles home toward unhit enemies"],
	"see_all":["See All","Attacks pass through obstacles"],
	"arrow_split":["Arrow split","Split in 3 after the final hit.\nReplaces Explosive arrows."],
	"stop_aim":["Stop and Aim","Stop to charge; move/3s to fire.\nDouble damage; always penetrates."],
	"explosive":["Explosive arrows","Impact +70% splash.\nReplaces Arrow split."],
	"perpetuum":["Perpetuum","Continuous laser.\nReplaces Magic Meteor."],
	"meteor":["Magic Meteor","Falling area damage.\nReplaces Perpetuum."],

}
const ACTIVE := ["damage","attack_speed","movement","experience","piercing","multishot","multiple_shots","ricochet","follow","see_all","arrow_split","stop_aim","explosive","perpetuum","meteor"]
const CAPS := {"attack_speed":8,"movement":5,"experience":3,"piercing":5,"multishot":5,"multiple_shots":5,"ricochet":5,"follow":1,"see_all":1,"arrow_split":1,"stop_aim":1,"explosive":1,"perpetuum":1,"meteor":1}
var weapon := "bow"
var weapon_level := 1
var base_damage := 1
var base_interval := 0.45
var projectile_speed := 390.0
var base_pierce := 0
var base_critical := 0.0
var critical_damage := 0.0
var damage_reduction := 0.0
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
var seen_once: Array[String] = []
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
	for i in range(mini(2,pool.size())):
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
	else: grant_upgrade(id)
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
	return base_health

func available_upgrades() -> Array[String]:
	var pool: Array[String] = []
	for id in ACTIVE:
		if id in ["arrow_split","stop_aim","explosive"] and weapon not in ["bow","crossbow"]: continue
		if id in ["perpetuum","meteor"] and weapon != "wand": continue
		if id == "see_all" and (weapon == "wand" or seen_once.has(id)): continue
		if id in ["piercing","ricochet","follow"] and weapon in ["sword","hammer"]: continue
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
	return minf(0.75,base_critical)

func apply_loadout(stats: Dictionary) -> void:
	weapon = stats["weapon"]
	weapon_level = stats["level"]
	base_damage = stats["damage"]
	base_interval = stats["interval"]
	projectile_speed = stats["projectile_speed"]
	base_pierce = stats["pierce"]
	base_critical = stats["critical"]
	critical_damage = stats.get("critical_damage",0.0)
	damage_reduction = clampf(stats.get("reduction",0.0),0.0,0.4)
	gear_movement = stats["movement"]
	gear_xp = stats["xp"]
	base_health += stats["health"]

func grant_upgrade(id: String) -> void:
	if not ranks.has(id): return
	var opposite: String = {"arrow_split":"explosive","explosive":"arrow_split","perpetuum":"meteor","meteor":"perpetuum"}.get(id,"")
	if not opposite.is_empty(): ranks[opposite] = 0
	ranks[id] += 1
	if id == "see_all" and not seen_once.has(id): seen_once.append(id)

func upgrade_info(id: String) -> Array:
	if id == "multishot" and weapon == "sword": return ["Extra projectile","+1 alternating slash per attack"]
	if id == "multishot" and weapon == "hammer": return ["Extra projectile","Wider cone; unchanged reach"]
	if weapon == "wand" and ranks["meteor"] > 0:
		if id == "piercing": return ["Meteor Size","+20% base meteor radius per rank"]
		if id == "ricochet": return ["Meteor Rain","Cast on one more enemy per attack"]
		if id == "follow": return ["Telekinesis","Roll after impact for 25% damage"]
	return UPGRADES[id]

func through_obstacles() -> bool:
	return weapon == "wand" or ranks["see_all"] > 0

func critical_multiplier() -> float: return 2.0+critical_damage
func roll_damage() -> float: return damage()*(critical_multiplier() if rng.randf()<critical_chance() else 1.0)
