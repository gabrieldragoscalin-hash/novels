extends RefCounted
## Finite room rewards and prototype service prices, independent of the interface.
var dungeon
var combat
var hub

func _init(d, c, h) -> void:
	dungeon = d
	combat = c
	hub = h
	if combat.progression.wallet == null: combat.progression.wallet = hub

func state() -> Dictionary:
	return dungeon.rooms[dungeon.current]

func enter() -> void:
	var room := state()
	combat.floor_number = dungeon.floor_number
	if room["role"] == "bonus" and not room["room_paid"]:
		room["room_paid"] = true
		combat.progression.flares += dungeon.bonus_flares()

func loot() -> bool:
	var room := state()
	if combat.progression.pending > 0 or room["role"] != "loot" or room["used"] or combat.alive_count() > 0: return false
	room["used"] = true
	room["room_paid"] = true
	combat.progression.flares += 20 if dungeon.floor_number % 5 == 0 else 10
	var coins_before: int = combat.progression.coins
	combat.progression.award_coins(15+dungeon.floor_number*5,true)
	room["coin_reward"] = combat.progression.coins-coins_before
	var catalog: Array = hub.Equipment.ITEMS.keys()
	var kind: String = catalog[dungeon.rng.randi_range(0,catalog.size()-1)]
	var roll_rarity: float = dungeon.rng.randf()*100
	var odds: Array = [[80,20,0,0],[70,28,2,0],[55,40,5,0],[40,50,10,0],[0,70,28,2]][clampi(dungeon.floor_number-1,0,4)]
	var rarity := 0
	var total := 0.0
	for i in range(odds.size()):
		total += odds[i]
		if roll_rarity<total: rarity = i; break
	room["reward"] = "No equipment this time."
	if dungeon.rng.randf() < minf(0.9,[0.35,0.40,0.45,0.50,0.65][clampi(dungeon.floor_number-1,0,4)]+0.002*combat.progression.perk("treasure_sense")):
		var uid: String = hub.find_equipment(kind,rarity)
		room["reward"] = "Stored " + hub.item_name(uid)
	if dungeon.rng.randf() < 0.05:
		var roll: float = dungeon.rng.randf()
		var key_kind := "copper" if roll < 0.7 else ("silver" if roll < 0.95 else "gold")
		hub.keys[key_kind] += 1
		hub.save()
		room["reward"] += "\nFound a %s key" % key_kind
	hub.record_progress("loot")
	# Better loot across the ten floors without consuming an XP level.
	if dungeon.floor_number >= 2: combat.progression.reward_choices()
	return true

func heal() -> bool:
	var room := state()
	if room["role"] != "bonus" or room["service"] != "healer" or room["used"] or combat.health >= combat.progression.max_health(): return false
	room["used"] = true
	combat.heal(combat.progression.max_health())
	return true

func free_upgrade() -> bool:
	var room := state()
	if combat.progression.pending > 0 or room["role"] != "bonus" or room["service"] != "upgrade" or room["used"]: return false
	room["used"] = true
	combat.progression.reward_choices()
	return true

func buy(id: String) -> String:
	var room := state()
	if combat.progression.pending > 0: return "Finish your reward choice first."
	if room["role"] != "bonus" or (room["service"] != "shop" and not room.get("summoned_shop", false)): return "There is no shop here."
	if room["stock"].get(id, false): return "Already purchased on this floor."
	var p = combat.progression
	var cost := 0
	var permanent := id in ["weapon_item", "armor_item"]
	match id:
		"weapon_item": cost = 150
		"armor_item": cost = 150
		"upgrade": cost = 20
		"heal":
			cost = 10
			if combat.health >= p.max_health(): return "You already have full health."
		"coins": cost = 10
		_: return "Unknown item."
	cost = price(id)
	if (p.coins if permanent else p.flares) < cost: return "Not enough coins." if permanent else "Not enough flares."
	if permanent: p.coins -= cost
	else: p.flares -= cost
	room["stock"][id] = true
	match id:
		"weapon_item": hub.find_equipment("bow")
		"armor_item": hub.find_equipment("vest")
		"upgrade": p.reward_choices()
		"heal": combat.heal(3)
		"coins": p.coins += 20
	return "Purchased."

func owned() -> Array[String]:
	var result: Array[String] = []
	for id in combat.progression.ranks:
		if id not in ["second_chance","medicine"] and combat.progression.ranks[id] > 0: result.append(id)
	return result

func trade_options(old: String) -> Array[String]:
	var pool: Array[String] = combat.progression.available_upgrades()
	pool.erase(old)
	var result: Array[String] = []
	while not pool.is_empty() and result.size() < 3:
		var id: String = combat.progression.weighted_pick(pool)
		result.append(id)
		pool.erase(id)
	return result

func trade(old: String, replacement: String, offered: Array[String]) -> bool:
	if state()["role"] != "bonus" or (state()["service"] != "trader" and not state().get("wheel_trade", false)): return false
	if state().get("trade_used", false) or not combat.progression.available_upgrades().has(replacement) or not offered.has(replacement) or not owned().has(old) or old == replacement: return false
	var previous_max: float = combat.progression.max_health()
	combat.progression.ranks[old] -= 1
	combat.progression.grant_upgrade(replacement)
	combat.apply_upgrade_effect(replacement,previous_max)
	combat.health = minf(combat.health, combat.progression.max_health())
	state()["used"] = true
	state()["trade_used"] = true
	return true

func tradable_owned() -> Array[String]:
	var result: Array[String] = []
	for old in owned():
		var pool: Array[String] = combat.progression.available_upgrades()
		pool.erase(old)
		if pool.size() >= 3: result.append(old)
	return result

func price(id: String) -> int:
	var base: int = {"weapon_item":150,"armor_item":150,"upgrade":20,"heal":10,"coins":10}.get(id,0)
	return maxi(1,int(ceil(base*(1.0-0.005*combat.progression.perk("resourceful")))))
