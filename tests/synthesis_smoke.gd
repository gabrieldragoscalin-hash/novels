extends SceneTree
const Hub = preload("res://scripts/hub.gd")
const Rules = preload("res://scripts/economy.gd")
const Gear = preload("res://scripts/equipment.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for spec in [[0,0],[1,0],[2,0],[3,0],[3,1],[4,0],[4,1],[4,2]]:
		var h = Hub.new(false)
		var base: String = h._add_item("bow",spec[0],spec[1],4)
		h.equip_item(base)
		var recipe := Rules.recipe(h.inventory[base])
		var selected: Array[String] = []
		for index in range(recipe["count"]):
			var kind: String = "bow" if recipe["exact"] else ["crossbow","wand","bow"][index]
			selected.append(h._add_item(kind,spec[0],recipe["fodder_plus"],1))
		var before: Dictionary = h.inventory.duplicate(true)
		var bad: Array[String] = selected.duplicate()
		bad.append(selected[0])
		assert(not h.synthesize(base,bad) and h.inventory == before)
		var duplicates: Array[String] = []
		for index in range(recipe["count"]): duplicates.append(base)
		assert(not h.synthesize(base,duplicates) and h.inventory == before)
		# Protect equipped ingredient copies; base identity remains equipped after success.
		h.equip_item(selected[0])
		assert(not h.synthesize(base,selected) and h.inventory == before)
		h.equip_item(base)
		assert(h.synthesize(base,selected))
		assert(h.inventory[base]["rarity"] == recipe["rarity"] and h.inventory[base]["plus"] == recipe["plus"])
		assert(h.inventory[base]["level"] == 4 and h.equipped["weapon"] == base)
		for uid in selected: assert(not h.inventory.has(uid))
		assert(not h.synthesize(base,selected),"An ingredient cannot be consumed twice")
	var h = Hub.new(false)
	var base: String = h._add_item("bow",1,0)
	var wrong: String = h._add_item("wand",1,0)
	assert(not h.synthesis_candidates(base).has(wrong),"Green requires exact identity")
	base = h._add_item("bow",4,1)
	wrong = h._add_item("bow",4,1)
	assert(not h.synthesis_candidates(base).has(wrong),"Yellow +1 requires unenhanced yellow ingredients")
	var mythic: String = h._add_item("bow",5,0)
	var none: Array[String] = []
	assert(not h.synthesize(mythic,none))
	# Parts, not scrap or duplicates, level an individual item.
	base = h.equipped["weapon"]
	h.parts["armor"] = 100
	assert(not h.upgrade(base))
	h.parts["weapon"] = 100
	assert(h.upgrade(base) and h.inventory[base]["level"] == 2 and h.parts["weapon"] == 95)
	assert(Gear.instance_stats({"type":"bow","rarity":4,"plus":1,"level":1})["damage"] > Gear.instance_stats({"type":"bow","rarity":4,"plus":0,"level":1})["damage"])
	var sorted: Array[String] = h.sorted_items(true)
	assert(h.inventory[sorted[0]]["rarity"] == 5)
	print("PASS: all eight synthesis recipes, exact/category/stage matching, equipped protection, atomic rejection, base levels/identity, no double consume, Mythic limit, parts leveling")
	quit(0)
