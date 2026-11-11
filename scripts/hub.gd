extends RefCounted
const Equipment = preload("res://scripts/equipment.gd")
const Economy = preload("res://scripts/economy.gd")
const PERK_EFFECTS := {"starting_upgrade":"Start each run with an upgrade choice.","starting_hp":"+1 starting HP per level.","dodge":"+1% dodge chance per level.","boss_damage":"+2% boss damage per level.","recovery":"Healing restores 1% more HP per level.","resourceful":"Dungeon shop prices -0.5% per level.","scavenger":"Dungeon-earned coins +1% per level. Excludes coin cards and purchases.","collector":"XP pickup radius +2% per level.","trap_resist":"Trap damage -1% per level.","elite_hunter":"Brute/guardian damage +0.5% per level.","treasure_sense":"Equipment chance in loot rooms +0.2pp per level.","loot_gold":"Loot-room coins +1% per level."}
const PATH := "user://hub.json"
const PERK_NAMES := {"starting_upgrade":"Starting upgrade", "starting_hp":"Starting HP", "dodge":"Dodge chance", "boss_damage":"Damage to bosses","recovery":"Recovery","resourceful":"Resourcefulness","scavenger":"Scavenger","collector":"Collector","trap_resist":"Trap resistance","elite_hunter":"Elite hunter","treasure_sense":"Treasure sense","loot_gold":"Loot gold"}
const PERK_CAPS := {"starting_upgrade":1,"starting_hp":25,"dodge":25,"boss_damage":25,"recovery":25,"resourceful":20,"scavenger":25,"collector":25,"trap_resist":20,"elite_hunter":20,"treasure_sense":25,"loot_gold":25}
var storage_path := PATH
var coins := 0
var gems := 0
var keys: Dictionary = {"copper":0,"silver":0,"gold":0}
var parts: Dictionary = {"armor":0,"accessory":0,"weapon":0}
var inventory: Dictionary = {}
var equipped: Dictionary = {"weapon":"","armor":"","headgear":"","pants":"","boots":"","necklace":"","ring":"","bracelet":""}
var next_item := 1
var highest_floor := 0
var pity: Dictionary = {"copper":0,"silver":0,"gold":0}
var perks: Dictionary = {"starting_upgrade":0,"starting_hp":0,"dodge":0,"boss_damage":0}
var perk_purchases := 0
var day := -1
var daily_clears: Dictionary = {}
var claimed_clears: Array = []
var task_progress: Dictionary = {}
var task_claimed: Dictionary = {}
var offers: Array = []
var legacy_data: Dictionary = {}
var last_find := ""
var persistence_ok := true
var enabled := true
var rng := RandomNumberGenerator.new()

func _init(persist: bool = true, save_path: String = PATH) -> void:
	enabled = persist
	storage_path = save_path
	rng.randomize()
	for id in PERK_NAMES: perks[id] = 0
	if enabled and FileAccess.file_exists(storage_path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(storage_path))
		if data is Dictionary: _load(data)
	if inventory.is_empty(): _add_item("bow",0,0,1)
	if equipped["weapon"].is_empty():
		for uid in inventory:
			if Equipment.ITEMS[inventory[uid]["type"]]["slot"] == "weapon": equipped["weapon"] = uid; break
		if equipped["weapon"].is_empty(): equipped["weapon"] = _add_item("bow",0,0,1)
	refresh_day()

func _number(value, maximum: int = 100000000) -> int:
	return clampi(int(value),0,maximum) if value is int or value is float else 0

func _load(data: Dictionary) -> void:
	highest_floor = _number(data.get("highest_floor",0))
	var version: int = _number(data.get("version",0))
	var aliases := {}
	var stored = data.get("inventory",{})
	if stored is Dictionary:
		for uid in stored:
			var value = stored[uid]
			if value is Dictionary:
				var kind = value.get("type","")
				if not kind is String or not Equipment.ITEMS.has(kind): continue
				var rarity := _number(value.get("rarity",0),5)
				var plus := _number(value.get("plus",0),2)
				if rarity < 3 or rarity == 5: plus = 0
				if rarity == 3: plus = mini(plus,1)
				inventory[str(uid)] = {"type":kind,"level":clampi(_number(value.get("level",1)),1,Equipment.MAX_LEVEL),"rarity":rarity,"plus":plus}
			elif Equipment.ITEMS.has(uid) and _number(value) > 0:
				aliases[uid] = _add_item(uid,0,0,clampi(int(value),1,Equipment.MAX_LEVEL))
	var loadout = data.get("equipped",{})
	if loadout is Dictionary:
		for slot in Equipment.SLOTS:
			var old = loadout.get(slot,loadout.get("charm","") if slot == "necklace" else "")
			if not old is String: continue
			var uid: String = aliases.get(old,old)
			if inventory.has(uid) and Equipment.ITEMS[inventory[uid]["type"]]["slot"] == slot: equipped[slot] = uid
	next_item = maxi(next_item,_number(data.get("next_item",1)))
	if version < 4:
		legacy_data = data.duplicate(true)
		return
	coins = _number(data.get("coins",0)); gems = _number(data.get("gems",0))
	for field in ["keys","parts","pity","perks"]:
		var values = data.get(field,{})
		if not values is Dictionary: continue
		var destination: Dictionary = get(field)
		for key in destination:
			var cap: int = 34 if field == "pity" else (PERK_CAPS[key] if field == "perks" else 100000000)
			destination[key] = _number(values.get(key,0),cap)
	perk_purchases = maxi(_number(data.get("perk_purchases",0)),_perk_total())
	day = int(data.get("day",-1)) if data.get("day",-1) is float or data.get("day",-1) is int else -1
	for field in ["daily_clears","task_progress","task_claimed","legacy_data"]:
		var value = data.get(field,{})
		if value is Dictionary: set(field,value.duplicate(true))
	if data.get("claimed_clears",[]) is Array: claimed_clears = data.get("claimed_clears",[]).slice(0,200)
	if data.get("offers",[]) is Array: offers = data.get("offers",[]).duplicate(true)

func save() -> bool:
	if not enabled: return true
	var data := {"version":4,"coins":coins,"gems":gems,"keys":keys,"parts":parts,"inventory":inventory,"equipped":equipped,"next_item":next_item,"highest_floor":highest_floor,"pity":pity,"perks":perks,"perk_purchases":perk_purchases,"day":day,"daily_clears":daily_clears,"claimed_clears":claimed_clears,"task_progress":task_progress,"task_claimed":task_claimed,"offers":offers,"legacy_data":legacy_data}
	var temporary := storage_path + ".tmp"
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file == null: persistence_ok = false; return false
	file.store_string(JSON.stringify(data)); file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(storage_path)) != OK:
		persistence_ok = false
		return false
	persistence_ok = true
	return true

func refresh_day(now: int = -1) -> void:
	var today := Economy.day_id(now)
	if day == today and _valid_offers(): return
	if day != today:
		daily_clears.clear(); claimed_clears.clear(); task_progress.clear(); task_claimed.clear()
	day = today
	offers.clear()
	var daily_rng := RandomNumberGenerator.new()
	daily_rng.seed = today + 37219
	for kind in ["armor","accessory","weapon"]: offers.append({"kind":"parts","type":kind,"quantity":Economy.PART_QUANTITY,"price":Economy.PART_COST,"sold":false})
	var catalog: Array = Equipment.ITEMS.keys()
	for i in range(3): offers.append({"kind":"item","type":catalog[daily_rng.randi_range(0,catalog.size()-1)],"quantity":1,"price":Economy.ITEM_COST,"sold":false})
	save()

func _valid_offers() -> bool:
	if offers.size() != 6: return false
	for index in range(6):
		var offer = offers[index]
		if not offer is Dictionary or not offer.get("sold",null) is bool: return false
		if _number(offer.get("price",0)) != (Economy.PART_COST if index < 3 else Economy.ITEM_COST): return false
		if _number(offer.get("quantity",0)) != (Economy.PART_QUANTITY if index < 3 else 1): return false
		if index < 3:
			if offer.get("kind","") != "parts" or offer.get("type","") != ["armor","accessory","weapon"][index]: return false
		elif offer.get("kind","") != "item" or not Equipment.ITEMS.has(offer.get("type","")): return false
	return true

func _add_item(kind: String, rarity: int, plus: int, level: int = 1) -> String:
	var uid := "item_%d" % next_item
	while inventory.has(uid): next_item += 1; uid = "item_%d" % next_item
	next_item += 1
	inventory[uid] = {"type":kind,"rarity":rarity,"plus":plus,"level":level}
	return uid

func find_equipment(kind: String, rarity: int = 0, plus: int = 0) -> String:
	if not Equipment.ITEMS.has(kind): return ""
	var uid := _add_item(kind,rarity,plus)
	last_find = "Found " + item_name(uid)
	save()
	return uid

func item_type(uid: String) -> String:
	return str(inventory[uid]["type"]) if inventory.has(uid) else ""

func item_name(uid: String) -> String:
	if not inventory.has(uid): return "Empty"
	var item: Dictionary = inventory[uid]
	return "%s %s%s" % [Economy.RARITIES[item["rarity"]],Equipment.ITEMS[item["type"]]["name"]," +%d" % item["plus"] if item["plus"] > 0 else ""]

func equip_item(uid: String) -> bool:
	if not inventory.has(uid): return false
	equipped[Equipment.ITEMS[item_type(uid)]["slot"]] = uid
	save(); return true

func unequip(slot: String) -> bool:
	if slot == "weapon" or not equipped.has(slot): return false
	equipped[slot] = ""; save(); return true

func upgrade_cost(uid: String) -> int:
	return int(inventory[uid]["level"]) * 5 if inventory.has(uid) else 0

func upgrade(uid: String) -> bool:
	if not inventory.has(uid) or inventory[uid]["level"] >= Equipment.MAX_LEVEL: return false
	var category := Economy.part_for(Equipment.ITEMS[item_type(uid)]["slot"])
	var cost := upgrade_cost(uid)
	if parts[category] < cost: return false
	parts[category] -= cost; inventory[uid]["level"] += 1
	save(); return true

func synthesis_candidates(base_uid: String) -> Array[String]:
	var result: Array[String] = []
	if not inventory.has(base_uid): return result
	var base: Dictionary = inventory[base_uid]
	var recipe := Economy.recipe(base)
	if recipe.is_empty(): return result
	for uid in inventory:
		if uid == base_uid or equipped.values().has(uid): continue
		var item: Dictionary = inventory[uid]
		if item["rarity"] != base["rarity"] or item["plus"] != recipe["fodder_plus"]: continue
		if recipe["exact"] and item["type"] != base["type"]: continue
		if not recipe["exact"] and Equipment.ITEMS[item["type"]]["slot"] != Equipment.ITEMS[base["type"]]["slot"]: continue
		result.append(uid)
	return result

func synthesize(base_uid: String, fodder: Array[String]) -> bool:
	if not inventory.has(base_uid): return false
	var recipe := Economy.recipe(inventory[base_uid])
	if recipe.is_empty() or fodder.size() != recipe["count"]: return false
	var allowed := synthesis_candidates(base_uid)
	var unique := {}
	for uid in fodder:
		if not allowed.has(uid) or unique.has(uid): return false
		unique[uid] = true
	for uid in fodder: inventory.erase(uid)
	inventory[base_uid]["rarity"] = recipe["rarity"]; inventory[base_uid]["plus"] = recipe["plus"]
	save(); return true

func sorted_items(synthesis: bool = false) -> Array[String]:
	var values: Array[String] = []
	var counts := {}
	for uid in inventory:
		values.append(uid)
		var item: Dictionary = inventory[uid]
		var group := "%s_%d_%d" % [item["type"],item["rarity"],item["plus"]]
		counts[group] = counts.get(group,0) + 1
	values.sort_custom(func(a,b):
		var x: Dictionary = inventory[a]; var y: Dictionary = inventory[b]
		if x["rarity"] != y["rarity"]: return x["rarity"] > y["rarity"]
		if x["plus"] != y["plus"]: return x["plus"] > y["plus"]
		if synthesis:
			var xc: int = counts["%s_%d_%d" % [x["type"],x["rarity"],x["plus"]]]
			var yc: int = counts["%s_%d_%d" % [y["type"],y["rarity"],y["plus"]]]
			if xc != yc: return xc > yc
		if x["type"] != y["type"]: return x["type"] < y["type"]
		return a < b
	)
	return values

func buy_offer(index: int, now: int = -1) -> String:
	refresh_day(now)
	if index < 0 or index >= offers.size(): return "Invalid offer."
	var offer: Dictionary = offers[index]
	if offer["sold"]: return "Sold out until the next daily refresh."
	if coins < offer["price"]: return "Not enough coins."
	coins -= int(offer["price"]); offer["sold"] = true
	if offer["kind"] == "parts": parts[offer["type"]] += int(offer["quantity"])
	else: _add_item(offer["type"],0,0)
	save(); return "Purchased."

func open_chest(kind: String, payment: String = "key") -> Dictionary:
	if not Economy.ODDS.has(kind) or payment not in ["key","gems"]: return {}
	if payment == "key":
		if keys[kind] <= 0: return {}
	else:
		if gems < Economy.GEM_COST[kind]: return {}
	if payment == "key": keys[kind] -= 1
	else: gems -= Economy.GEM_COST[kind]
	var guaranteed: bool = pity[kind] >= 34
	var rarity := 0
	var plus := 0
	if guaranteed:
		rarity = 3 if kind == "copper" else 4
		if kind == "gold": plus = 1
	else:
		var roll := minf(99.999999,rng.randf() * 100)
		var sum := 0.0
		for index in range(5):
			sum += Economy.ODDS[kind][index]
			if roll < sum: rarity = index; break
		if kind == "gold" and rarity == 4 and rng.randf() < 0.1: plus = 1
	var highest: bool = rarity >= (3 if kind == "copper" else 4)
	pity[kind] = 0 if highest else pity[kind] + 1
	var catalog: Array = Equipment.ITEMS.keys()
	var uid := _add_item(catalog[rng.randi_range(0,catalog.size()-1)],rarity,plus)
	save(); return {"uid":uid,"guaranteed":guaranteed,"rarity":rarity,"plus":plus}

func claim_floor(floor_number: int, token: String, now: int = -1) -> Dictionary:
	refresh_day(now)
	if floor_number <= 0 or token.is_empty() or claimed_clears.has(token): return {}
	claimed_clears.append(token)
	if claimed_clears.size() > 200: claimed_clears.pop_front()
	highest_floor = maxi(highest_floor,floor_number)
	if Economy.TASKS_ENABLED: task_progress["floors"] = int(task_progress.get("floors",0)) + 1
	var count := _number(daily_clears.get(str(floor_number),0),3)
	var reward := Economy.floor_reward(floor_number)
	if count < 3:
		daily_clears[str(floor_number)] = count + 1
		keys[reward["kind"]] += reward["amount"]
	else: reward = {}
	save(); return reward

func record_progress(kind: String, amount: int = 1) -> void:
	refresh_day()
	if not Economy.TASKS_ENABLED or not Economy.TASKS.has(kind) or amount <= 0: return
	task_progress[kind] = mini(100000,int(task_progress.get(kind,0)) + amount)
	save()

func claim_task(kind: String) -> bool:
	refresh_day()
	if not Economy.TASKS_ENABLED or not Economy.TASKS.has(kind) or task_claimed.get(kind,false) or int(task_progress.get(kind,0)) < Economy.TASKS[kind][0]: return false
	task_claimed[kind] = true; gems += int(Economy.TASKS[kind][1])
	save(); return true

func _perk_total() -> int:
	var total := 0
	for value in perks.values(): total += int(value)
	return total

func perk_price() -> int:
	return 250 + perk_purchases * Economy.PERK_INCREMENT

func can_buy_perk() -> bool:
	if coins < perk_price(): return false
	for value in perks.values():
		if value == 0: return true
	if Economy.REQUIRE_RESERVED_PERKS: return false
	for id in perks:
		if perks[id] < PERK_CAPS[id]: return true
	return false

func buy_perk() -> String:
	if not can_buy_perk(): return ""
	var candidates: Array[String] = []
	if perk_purchases == 0 or perks["starting_upgrade"] == 0: candidates.append("starting_upgrade")
	else:
		for id in perks:
			if perks[id] == 0: candidates.append(id)
		if candidates.is_empty() and not Economy.REQUIRE_RESERVED_PERKS:
			for id in perks:
				if perks[id] < PERK_CAPS[id]: candidates.append(id)
	if candidates.is_empty(): return ""
	var chosen := candidates[rng.randi_range(0,candidates.size()-1)]
	coins -= perk_price(); perk_purchases += 1; perks[chosen] += 1
	save(); return chosen

func loadout_stats() -> Dictionary:
	var uid: String = equipped["weapon"]
	var item: Dictionary = inventory[uid]
	var result := Equipment.instance_stats(item)
	result["weapon"] = item["type"]; result["level"] = item["level"]
	for slot in Equipment.SLOTS:
		if slot == "weapon" or equipped[slot].is_empty(): continue
		var extra := Equipment.instance_stats(inventory[equipped[slot]])
		for stat in ["health","movement","xp","critical","damage","critical_damage","reduction"]: result[stat] += extra[stat]
		result["interval"] /= 1.0 + extra["haste"]
	return result

func record_floor(value: int) -> void:
	if value > highest_floor: highest_floor = value; save()

func pet_slot_unlocked() -> bool:
	return highest_floor >= 10

# Ascending passes cascade common -> uncommon -> rare -> epic, never consume epic.
func quick_synthesis() -> int:
	var merged := 0
	for rarity in range(3):
		var changed := true
		while changed:
			changed = false
			var order: Array[String] = sorted_items(true)
			# Prefer equipped bases, then the highest level, retaining invested levels.
			order.sort_custom(func(a,b):
				if equipped.values().has(a) != equipped.values().has(b): return equipped.values().has(a)
				return inventory[a]["level"] > inventory[b]["level"] if inventory[a]["level"] != inventory[b]["level"] else a < b)
			for uid in order:
				if inventory[uid]["rarity"] != rarity: continue
				var ingredients := synthesis_candidates(uid)
				# Spend the lowest-level copies first.
				ingredients.sort_custom(func(a,b): return inventory[a]["level"] < inventory[b]["level"] if inventory[a]["level"] != inventory[b]["level"] else a < b)
				if ingredients.size() < 3: continue
				var selected: Array[String] = [ingredients[0],ingredients[1],ingredients[2]]
				if synthesize(uid,selected): merged += 1; changed = true; break
	return merged
