extends RefCounted
## Device-local persistence, not a cloud account. Only validated small integers load.
const Equipment = preload("res://scripts/equipment.gd")
const PATH := "user://hub.json"
var storage_path := PATH
var materials := 0
var inventory: Dictionary = {"bow": 1}
var equipped: Dictionary = {"weapon": "bow", "armor": "", "boots": "", "charm": ""}
var last_find := ""
var keys := 0
var seals := 0
var training := 0
var persistence_ok := true
var enabled := true

func _init(persist: bool = true, save_path: String = PATH) -> void:
	storage_path = save_path
	enabled = persist
	if not enabled or not FileAccess.file_exists(storage_path): return
	var data = JSON.parse_string(FileAccess.get_file_as_string(storage_path))
	if not data is Dictionary: return
	for name in ["keys", "seals", "training", "materials"]:
		var value = data.get(name, 0)
		if value is float or value is int:
			set(name, clampi(int(value), 0, 3 if name == "training" else 100000))
	var stored = data.get("inventory", {})
	if stored is Dictionary:
		for id in Equipment.ITEMS:
			var value = stored.get(id, 0)
			if (value is int or value is float) and int(value) >= 1:
				inventory[id] = clampi(int(value), 1, Equipment.MAX_LEVEL)
	var loadout = data.get("equipped", {})
	if loadout is Dictionary:
		for slot in Equipment.SLOTS:
			var id = loadout.get(slot, "")
			if id is String and inventory.has(id) and Equipment.ITEMS[id]["slot"] == slot: equipped[slot] = id


func save() -> bool:
	if not enabled: return true
	var temporary := storage_path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		persistence_ok = false
		return false
	file.store_string(JSON.stringify({"version": 2, "keys": keys, "seals": seals, "training": training, "materials": materials, "inventory": inventory, "equipped": equipped}))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		persistence_ok = false
		return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(storage_path)) != OK:
		persistence_ok = false
		return false
	persistence_ok = true
	return true

func train() -> bool:
	if keys <= 0 or training >= 3: return false
	keys -= 1
	training += 1
	save()
	return true

func craft(id: String) -> bool:
	if not Equipment.ITEMS.has(id) or inventory.has(id): return false
	var cost: int = Equipment.ITEMS[id]["cost"]
	if materials < cost: return false
	materials -= cost
	inventory[id] = 1
	save()
	return true

func upgrade_cost(id: String) -> int:
	return 3 * int(inventory.get(id, 0))

func upgrade(id: String) -> bool:
	if not inventory.has(id) or inventory[id] >= Equipment.MAX_LEVEL: return false
	var cost := upgrade_cost(id)
	if materials < cost: return false
	materials -= cost
	inventory[id] += 1
	save()
	return true

func equip_item(id: String) -> bool:
	if not inventory.has(id) or not Equipment.ITEMS.has(id): return false
	equipped[Equipment.ITEMS[id]["slot"]] = id
	save()
	return true

func unequip(slot: String) -> bool:
	if slot == "weapon" or not Equipment.SLOTS.has(slot): return false
	equipped[slot] = ""
	save()
	return true

func grant_materials(amount: int) -> void:
	materials = mini(100000, materials + maxi(0, amount))
	save()

func find_equipment(id: String) -> String:
	if not Equipment.ITEMS.has(id): return ""
	if inventory.has(id):
		materials = mini(100000, materials + 2)
		last_find = "%s duplicate → 2 scrap" % Equipment.ITEMS[id]["name"]
	else:
		inventory[id] = 1
		last_find = "Stored %s in the armory" % Equipment.ITEMS[id]["name"]
	save()
	return last_find

func loadout_stats() -> Dictionary:
	var id: String = equipped["weapon"]
	var result := Equipment.stats(id, inventory[id])
	result["weapon"] = id
	result["level"] = inventory[id]
	for slot in ["armor", "boots", "charm"]:
		var item: String = equipped[slot]
		if item.is_empty(): continue
		var extra := Equipment.stats(item, inventory[item])
		result["health"] += extra["health"]
		result["movement"] += extra["movement"]
		result["xp"] += extra["xp"]
	return result
