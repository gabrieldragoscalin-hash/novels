extends RefCounted
## All values belong to one run. Upgrade offers are generated once per level.
const Balance = preload("res://scripts/combat_balance.gd")
const Catalog = preload("res://scripts/upgrade_catalog.gd")
const UPGRADES = Catalog.UPGRADES
const ACTIVE = Catalog.ACTIVE
const CAPS = Catalog.CAPS
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
	# Retired counters remain zero for compatibility with existing effect readers.
	for id in ["gatherer","last_enemy","momentum","stop_aim"]: ranks[id] = 0

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
	_make_choices(3)

func choose(index: int) -> String:
	if pending <= 0 or index < 0 or index >= offers.size(): return ""
	var id := offers[index]
	for other in offers:
		if other!=id and other in ["explosive","arrow_split","perpetuum","meteor"]: declined[other] = true
	grant_upgrade(id)
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
		if Catalog.OWNERS.has(id) and Catalog.OWNERS[id]!=weapon: continue
		if id in Catalog.RANGED_ONLY and not is_ranged(): continue
		if id in Catalog.MELEE_ONLY and not is_melee(): continue
		if id=="piercing" and not (weapon=="wand" and ranks["meteor"]>0): continue
		if id=="medicine" and current_health>=max_health(): continue
		if id=="second_chance" and seen_once.has(id): continue
		if id=="see_all" and (weapon=="wand" or seen_once.has(id)): continue
		if CAPS.has(id) and ranks[id]>=CAPS[id]: continue
		pool.append(id)
	return pool

func reward_choices(count: int = 3) -> void:
	pending += 1
	_make_choices(count)

func _make_choices(count: int) -> void:
	offers.clear()
	var pool := available_upgrades()
	if count>=2:
		var offense: Array[String] = []; var utility: Array[String] = []
		for id in pool:
			if id in ["movement","experience","vitality","medicine","lifesteal","barrier","salvage","second_chance"]: utility.append(id)
			else: offense.append(id)
		for group in [offense,utility]:
			if not group.is_empty():
				var id := weighted_pick(group); offers.append(id); pool.erase(id)
	while offers.size()<count and not pool.is_empty():
		var id := weighted_pick(pool); offers.append(id); pool.erase(id)
	if offers.is_empty(): pending = 0 # Exhausted catalog: never trap the player in an empty reveal.

func weight(id: String) -> float:
	var value := 0.08 if id=="second_chance" else (0.35 if Catalog.signature(id) else 1.0)
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
	if id not in available_upgrades(): return
	var opposite := Catalog.opposite(id)
	if not opposite.is_empty(): ranks[opposite] = 0
	ranks[id] += 1
	if id in ["see_all","second_chance"] and not seen_once.has(id): seen_once.append(id)

func upgrade_info(id: String) -> Array:
	if id=="reach":
		if is_melee(): return ["Melee reach","+5% melee reach"]
		if weapon=="wand" and ranks["meteor"]>0: return ["Faster Descent","Faster falling and rolling meteors"]
		return ["Projectile speed","+10% projectile speed"]
	if weapon=="wand" and ranks["meteor"]>0:
		if id=="ricochet": return ["Meteor Rain","Cast on one more enemy per attack"]
		if id=="follow": return ["Telekinesis","Roll after impact for 25% damage"]
	return UPGRADES[id]

func is_ranged() -> bool: return weapon in Catalog.RANGED
func is_melee() -> bool: return weapon in Catalog.MELEE
func pierce_count() -> int: return base_pierce+ranks["skewer"]+(3 if ranks["ballista"]>0 else 0)

func through_obstacles() -> bool:
	return weapon == "wand" or ranks["see_all"] > 0

func critical_multiplier() -> float: return 2.0+critical_damage
func roll_damage() -> float: return damage()*(critical_multiplier() if rng.randf()<critical_chance() else 1.0)

func cycle_output() -> float:
	var extra: int = ranks["multishot"] if is_ranged() else 0
	return (1.0+extra*Balance.EXTRA_OUTPUT)*(1.0+ranks["multiple_shots"]*Balance.BURST_OUTPUT)

func delivery_factor() -> float:
	var extra: int = ranks["multishot"] if is_ranged() else 0
	return cycle_output()/((1+extra)*(1+ranks["multiple_shots"]))
