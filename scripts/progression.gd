extends RefCounted
## All values belong to one run. Upgrade offers are generated once per level.
const Balance = preload("res://scripts/combat_balance.gd")
const UPGRADES := {
	"damage":["Increased damage","+15% equipment damage (additive)"],
	"attack_speed":["Increased attack speed","+12% attack speed (additive)"],
	"movement":["Increased move speed","+10% movement speed"],
	"experience":["Increased EXP gain","+20% experience gained"],
	"piercing":["Punchthrough","Pass through one more enemy"],
	"multishot":["Extra projectile","+1 projectile; +35% total output"],
	"multiple_shots":["Multiple Shots","+1 attack; +30% total output"],
	"ricochet":["Ricochet","Bounce to one more enemy; never off walls"],
	"follow":["Follow","Projectiles home toward unhit enemies"],
	"see_all":["See All","Attacks pass through obstacles"],
	"arrow_split":["Arrow split","Split in 3 after the final hit.\nReplaces Explosive arrows."],
	"stop_aim":["Stop and Aim","Stop to charge; move/3s to fire.\nDouble damage; always penetrates."],
	"explosive":["Explosive arrows","Impact +45% splash, once per cycle.\nReplaces Arrow split."],
	"perpetuum":["Perpetuum","Continuous laser.\nReplaces Magic Meteor."],
	"meteor":["Magic Meteor","Falling area damage.\nReplaces Perpetuum."],
	"vitality":["Vitality","+10% starting max HP; heal HP gained"],
	"medicine":["Field medicine","Restore 15% max HP now"],
	"gatherer":["Gatherer","+25% XP pickup radius"],
	"reach":["Long reach","+10% shot speed / +5% melee reach"],
	"last_enemy":["Last enemy","+15% damage against the final enemy"],
	"momentum":["Momentum","Clear combat: +10% speed next room"],
	"barrier":["Emergency barrier","Block one hit for 4s on room entry"],
	"salvage":["Salvage","+3 coins per combat room cleared"],
	"second_chance":["Second Chance • RARE","Revive once at 25% HP this run"]
}
const ACTIVE := ["damage","attack_speed","movement","experience","piercing","multishot","multiple_shots","ricochet","follow","see_all","arrow_split","stop_aim","explosive","perpetuum","meteor","vitality","medicine","gatherer","reach","last_enemy","momentum","barrier","salvage","second_chance"]
const CAPS := {"vitality":5,"gatherer":3,"reach":3,"last_enemy":2,"momentum":1,"barrier":1,"salvage":3,"second_chance":1,"damage":12,"attack_speed":8,"movement":5,"experience":3,"piercing":5,"multishot":5,"multiple_shots":5,"ricochet":5,"follow":1,"see_all":1,"arrow_split":1,"stop_aim":1,"explosive":1,"perpetuum":1,"meteor":1}
var perk_ranks: Dictionary = {}
var current_health := 6.0
var last_enemy_active := false
var momentum_pending := false
var momentum_active := false
var revive_used := false
var coin_fraction := 0.0
var declined: Dictionary = {}
var weapon := "bow"
var weapon_level := 1
var base_damage := 1.0
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
	_make_choices(2,true)

func coin_reward() -> int:
	return 20

func choose(index: int) -> String:
	if pending <= 0 or index < 0 or index >= offers.size(): return ""
	var id := offers[index]
	for other in offers:
		if other!=id and other in ["explosive","arrow_split","perpetuum","meteor"]: declined[other] = true
	if id == "coins": coins += coin_reward()
	else: grant_upgrade(id)
	pending -= 1
	offers.clear()
	if pending > 0: _roll_offers()
	return id

func damage() -> float:
	return base_damage*(1.0+Balance.DAMAGE_PER_RANK*ranks["damage"])*(1.0+0.15*ranks["last_enemy"] if last_enemy_active else 1.0)

func fire_interval() -> float:
	return maxf(Balance.MIN_INTERVAL,base_interval/(1.0+Balance.HASTE_PER_RANK*ranks["attack_speed"]))

func movement_multiplier() -> float:
	return (1.0 + gear_movement + ranks["movement"] * 0.1+(0.1 if momentum_active and ranks["momentum"]>0 else 0.0)) * (0.65 if slow_time > 0 else 1.0)

func max_health() -> float:
	return base_health*(1.0+0.1*ranks["vitality"])

func available_upgrades() -> Array[String]:
	var pool: Array[String] = []
	for id in ACTIVE:
		if id in ["arrow_split","stop_aim","explosive"] and weapon not in ["bow","crossbow"]: continue
		if id in ["perpetuum","meteor"] and weapon != "wand": continue
		if id=="medicine" and current_health>=max_health(): continue
		if id=="second_chance" and seen_once.has(id): continue
		if id == "see_all" and (weapon == "wand" or seen_once.has(id)): continue
		if id in ["piercing","ricochet","follow"] and weapon in ["sword","hammer"]: continue
		if CAPS.has(id) and ranks[id] >= CAPS[id]: continue
		pool.append(id)
	return pool

func reward_choices(count: int = 2, with_coins: bool = true) -> void:
	pending += 1
	_make_choices(count,with_coins)

func _make_choices(count: int,with_coins: bool) -> void:
	offers.clear()
	var pool := available_upgrades()
	if count>=2:
		var offense: Array[String] = []; var utility: Array[String] = []
		for id in pool:
			if id in ["movement","experience","vitality","medicine","gatherer","momentum","barrier","salvage","second_chance"]: utility.append(id)
			else: offense.append(id)
		for group in [offense,utility]:
			if not group.is_empty():
				var id := weighted_pick(group); offers.append(id); pool.erase(id)
	while offers.size()<count and not pool.is_empty():
		var id := weighted_pick(pool); offers.append(id); pool.erase(id)
	if with_coins: offers.append("coins")

func weight(id: String) -> float:
	var value := 0.08 if id=="second_chance" else (0.35 if id in ["explosive","arrow_split","perpetuum","meteor","stop_aim"] else 1.0)
	if declined.has(id): value *= 0.35
	return value

func weighted_pick(pool: Array[String]) -> String:
	var total := 0.0
	for id in pool: total += weight(id)
	var roll := rng.randf()*total
	for id in pool:
		roll -= weight(id)
		if roll<=0: return id
	return pool.back()

func perk(id: String) -> int: return int(perk_ranks.get(id,0))
func award_coins(amount: float,loot: bool = false) -> void:
	var value := amount*(1.0+0.01*perk("scavenger")+(0.01*perk("loot_gold") if loot else 0.0))+coin_fraction
	var whole := int(floor(value+0.000001)); coin_fraction = value-whole; coins += whole
func healing_multiplier() -> float: return 1.0+perk("recovery")*0.01
func shot_speed() -> float: return projectile_speed*(1.0+0.1*ranks["reach"])
func pickup_radius() -> float: return 110*(1.0+0.02*perk("collector")+0.25*ranks["gatherer"])

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
	if not ranks.has(id) or (CAPS.has(id) and ranks[id]>=CAPS[id]): return
	var opposite: String = {"arrow_split":"explosive","explosive":"arrow_split","perpetuum":"meteor","meteor":"perpetuum"}.get(id,"")
	if not opposite.is_empty(): ranks[opposite] = 0
	ranks[id] += 1
	if id in ["see_all","second_chance"] and not seen_once.has(id): seen_once.append(id)

func upgrade_info(id: String) -> Array:
	if id=="reach" and weapon=="wand" and ranks["perpetuum"]>0: return ["Long reach","+5% beam width per rank"]
	if id=="reach" and weapon=="wand" and ranks["meteor"]>0: return ["Long reach","Faster falling and rolling meteors"]
	if id == "multishot" and weapon == "sword": return ["Extra projectile","+1 slash; +35% total output"]
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

func cycle_output() -> float:
	var extra: int = 0 if weapon=="hammer" else ranks["multishot"]
	return (1.0+extra*Balance.EXTRA_OUTPUT)*(1.0+ranks["multiple_shots"]*Balance.BURST_OUTPUT)

func delivery_factor() -> float:
	var extra: int = 0 if weapon=="hammer" else ranks["multishot"]
	return cycle_output()/((1+extra)*(1+ranks["multiple_shots"]))
