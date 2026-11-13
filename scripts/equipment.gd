extends RefCounted
## Item templates. Hub stores individually identified copies, levels and rarities.
const MAX_LEVEL := 5
const ITEMS := {
	"bow": {"name": "Ranger bow", "slot": "weapon", "description": "Normal arrows with balanced damage and speed."},
	"crossbow": {"name": "Iron crossbow", "slot": "weapon", "description": "Bigger arrows, slower attacks and higher damage."},
	"wand": {"name": "Ember wand", "slot": "weapon", "description": "Magic beams that pass through obstacles."},
	"sword": {"name":"Vanguard sword","slot":"weapon","description":"Slashes a forward arc at close range."},
	"hammer": {"name":"Earthshaker hammer","slot":"weapon","description":"Forward cone shockwaves hit an area."},
	"chakram": {"name":"Gale chakram","slot":"weapon","description":"Curved throws hit outward and again on their return."},
	"spear": {"name":"Dawnpiercer spear","slot":"weapon","description":"Thrown spears lodge, then return along a path you control."},
	"dual_axe": {"name":"Eclipse axes","slot":"weapon","description":"Alternating axe combos build close-range pressure."},
	"club": {"name":"Titanwood club","slot":"weapon","description":"Heavy swings knock enemies into each other."},
	"vest": {"name": "Warden vest", "slot": "armor", "description": "Adds HP and damage reduction."},
	"boots": {"name": "Scout boots", "slot": "boots", "description": "Adds maximum health."},
	"hood": {"name": "Pathfinder hood", "slot": "headgear", "description": "Adds maximum health."},
	"pants": {"name": "Trailguard pants", "slot": "pants", "description": "Adds maximum health."},
	"ring": {"name": "Ember ring", "slot": "ring", "description": "Increases critical damage, not chance."},
	"bracelet": {"name": "Archer bracelet", "slot": "bracelet", "description": "Adds attack damage and firing speed."},
	"charm": {"name": "Scholar necklace", "slot": "necklace", "description": "Adds maximum health."}
}
const SLOTS := ["weapon", "armor", "headgear", "pants", "boots", "necklace", "ring", "bracelet"]

static func stats(id: String, level: int) -> Dictionary:
	level = clampi(level, 1, MAX_LEVEL)
	var result := {"damage": 0, "interval": 0.45, "projectile_speed": 390.0, "pierce": 0, "critical": 0.05 if ITEMS[id]["slot"]=="weapon" else 0.0, "critical_damage":0.0,"reduction":0.0, "health": 0, "movement": 0.0, "xp": 0.0, "haste": 0.0}
	match id:
		"bow": result["damage"] = 1 + int((level - 1) / 2)
		"crossbow":
			result["damage"] = 2 + level - 1
			result["interval"] = 0.72
			result["projectile_speed"] = 470.0
			result["pierce"] = 0
		"wand":
			result["damage"] = 1 + int((level - 1) / 2)
			result["interval"] = 0.34
			result["projectile_speed"] = 320.0
			result["critical"] = 0.1
		"sword":
			result["damage"] = 3 + level - 1
			result["interval"] = 0.65
		"hammer":
			result["damage"] = 4 + level - 1
			result["interval"] = 1.0
		"chakram":
			result["damage"] = 2 + level - 1
			result["interval"] = 0.7
		"spear":
			result["damage"] = 3+level-1; result["interval"] = 0.95; result["projectile_speed"] = 330.0
		"dual_axe":
			result["damage"] = 2+level-1; result["interval"] = 0.48
		"club":
			result["damage"] = 5+level-1; result["interval"] = 1.15
		"vest":
			result["health"] = 1+level
			result["reduction"] = 0.05+(level-1)*0.01
		"hood", "pants", "boots", "charm": result["health"] = level
		"ring": result["critical_damage"] = 0.25+(level-1)*0.05
		"bracelet":
			result["damage"] = 1+int((level-1)/2)
			result["haste"] = 0.05+(level-1)*0.025
	if ITEMS.has(id) and ITEMS[id]["slot"] == "weapon": result["interval"] /= 1.0 + (level - 1) * 0.05
	return result

static func summary(id: String, level: int) -> String:
	return _summary(id,stats(id,level))

static func _summary(id: String,s: Dictionary) -> String:
	if ITEMS[id]["slot"]=="weapon": return "%d DMG • %.1f/s • %d%% crit" % [s["damage"],1.0/s["interval"],roundi(s["critical"]*100)]
	if id=="vest": return "+%d HP • %.1f%% damage reduction" % [s["health"],s["reduction"]*100]
	if id=="ring": return "+%.0f%% critical damage" % (s["critical_damage"]*100)
	if id=="bracelet": return "+%d damage • +%.1f%% attack speed" % [s["damage"],s["haste"]*100]
	return "+%d maximum HP" % s["health"]

static func instance_stats(item: Dictionary) -> Dictionary:
	var result := stats(item["type"], item["level"])
	var multiplier: float = [1.0,1.15,1.35,1.7,2.3,3.6][item["rarity"]] + item["plus"] * 0.25
	if ITEMS[item["type"]]["slot"] == "weapon":
		result["damage"] = maxi(1, int(ceil(result["damage"] * multiplier)) + int(item["plus"]))
	else:
		result["health"] = int(ceil(result["health"] * multiplier)) + (int(item["plus"]) if result["health"] > 0 else 0)
		result["damage"] = int(ceil(result["damage"]*multiplier))
		for stat in ["movement","xp","critical","haste","critical_damage","reduction"]: result[stat] *= multiplier
	return result

static func instance_summary(item: Dictionary) -> String:
	return _summary(item["type"],instance_stats(item))
