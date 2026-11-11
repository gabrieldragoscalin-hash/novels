extends SceneTree
const Hub = preload("res://scripts/hub.gd")
const Rules = preload("res://scripts/economy.gd")
const DAY := 2000000000

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var h = Hub.new(false)
	assert(h.inventory.size() == 1 and h.coins == 0)
	var bow: String = h.equipped["weapon"]
	var duplicate: String = h.find_equipment("bow")
	assert(bow != duplicate and h.inventory.size() == 2)
	h.coins = 10000
	h.refresh_day(DAY)
	assert(h.offers.size() == 6)
	for index in range(3): assert(h.offers[index]["kind"] == "parts")
	for index in range(3,6): assert(h.offers[index]["kind"] == "item")
	var offers: Array = h.offers.duplicate(true)
	var before: int = h.coins
	assert(h.buy_offer(0,DAY) == "Purchased." and h.parts["armor"] == 5 and h.coins == before-50)
	assert(h.buy_offer(0,DAY) != "Purchased.")
	h.refresh_day(DAY+100)
	assert(h.offers[0]["sold"])
	h.refresh_day(DAY+86400)
	assert(not h.offers[0]["sold"])
	var rewards := [["copper",1],["silver",1],["copper",2],["silver",2],["gold",1],["copper",3],["silver",3],["copper",3],["silver",3],["gold",2],["copper",4],["silver",4],["copper",4],["silver",4],["gold",3]]
	for floor_number in range(1,16):
		var reward := Rules.floor_reward(floor_number)
		assert(reward["kind"] == rewards[floor_number-1][0] and reward["amount"] == rewards[floor_number-1][1])
		var old: int = h.keys[reward["kind"]]
		for clear in range(4):
			var paid: Dictionary = h.claim_floor(floor_number,"run%d-floor%d" % [clear,floor_number],DAY)
			assert(paid.is_empty() if clear == 3 else not paid.is_empty())
		assert(h.keys[reward["kind"]] == old+reward["amount"]*3)
		assert(h.claim_floor(floor_number,"run0-floor%d" % floor_number,DAY).is_empty())
	assert(not h.claim_floor(1,"tomorrow",DAY+86400).is_empty())
	# Separate pity counters, insufficient funds, exact guarantees, shared gem/key progress.
	for kind in ["copper","silver","gold"]:
		h.keys[kind] = 1
		h.pity[kind] = 34
		var result: Dictionary = h.open_chest(kind)
		assert(result["guaranteed"] and result["rarity"] == (3 if kind == "copper" else 4))
		if kind == "gold": assert(result["plus"] == 1)
		assert(h.pity[kind] == 0 and h.keys[kind] == 0)
		before = h.inventory.size()
		assert(h.open_chest(kind).is_empty() and h.inventory.size() == before)
		h.gems = 1000; h.pity[kind] = 34
		assert(h.open_chest(kind,"gems")["guaranteed"] and h.gems == 1000-Rules.GEM_COST[kind])
	# Force a normal legendary on gold by choosing a seed, proving it resets pity too.
	for seed_value in range(10000):
		var rng := RandomNumberGenerator.new(); rng.seed = seed_value
		if rng.randf() >= 0.96 and rng.randf() >= 0.1:
			h.rng.seed = seed_value; break
	h.keys["gold"] = 1; h.pity["gold"] = 17
	var normal: Dictionary = h.open_chest("gold")
	assert(normal["rarity"] == 4 and normal["plus"] == 0 and h.pity["gold"] == 0)
	# The first perk is fixed; all other unlocks happen before any levels.
	h = Hub.new(false); h.coins = 100000
	assert(h.perk_price() == 250 and h.buy_perk() == "starting_upgrade")
	assert(h.perks["starting_upgrade"] == 1 and h.perk_price() == 300)
	for i in range(3): assert(not h.buy_perk().is_empty())
	for value in h.perks.values(): assert(value == 1)
	if Rules.REQUIRE_RESERVED_PERKS: assert(not h.can_buy_perk())
	else:
		h.coins = 10000000
		for i in range(72): assert(not h.buy_perk().is_empty())
		assert(not h.can_buy_perk())
		assert(h.perks["starting_upgrade"] == 1 and h.perks["starting_hp"] == 25)
	# Undefined tasks cannot grant gems.
	h.record_progress("kills",10)
	before = h.gems
	assert(not h.claim_task("kills") and h.gems == before, "Tasks and gem earning are reserved")
	# Saving daily counts/pity/instances/perks and migrating v3 without invented currency conversion.
	var path := "user://economy-test-%d.json" % Time.get_ticks_usec()
	h.enabled = true; h.storage_path = path; h.save()
	var loaded = Hub.new(true,path)
	assert(loaded.inventory == h.inventory and loaded.perks == h.perks and loaded.coins == h.coins)
	h.claim_floor(3,"persisted-clear")
	h.pity["silver"] = 34; h.keys["silver"] = 1; h.save()
	loaded = Hub.new(true,path)
	assert(loaded.claim_floor(3,"persisted-clear").is_empty())
	assert(not loaded.claim_floor(3,"persisted-clear-2").is_empty())
	assert(not loaded.claim_floor(3,"persisted-clear-3").is_empty())
	assert(loaded.claim_floor(3,"persisted-clear-4").is_empty())
	assert(loaded.open_chest("silver")["guaranteed"],"Pity must survive reload")
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":3,"materials":123,"keys":7,"training":2,"inventory":{"bow":3,"charm":2},"equipped":{"weapon":"bow","necklace":"charm"}})); file.close()
	loaded = Hub.new(true,path)
	assert(loaded.inventory.size() == 2 and loaded.inventory[loaded.equipped["weapon"]]["level"] == 3)
	assert(loaded.legacy_data["materials"] == 123 and loaded.coins == 0)
	assert(loaded.item_type(loaded.equipped["necklace"]) == "charm")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("PASS: duplicate copies, daily offers, all floor-key tiers, daily limits, chest odds/pity/payments, normal-gold reset, perk unlock order, reserved tasks, save migration")
	quit(0)
