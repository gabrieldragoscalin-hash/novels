extends RefCounted
## Unique stored items; level and equipped slots persist, run ranks do not.
const MAX_LEVEL := 5
const ITEMS := {
	"bow": {"name": "Ranger bow", "slot": "weapon", "cost": 0, "description": "Balanced bolts. Reliable attack speed."},
	"crossbow": {"name": "Iron crossbow", "slot": "weapon", "cost": 8, "description": "Heavy, slower bolts; pierces one enemy."},
	"wand": {"name": "Ember wand", "slot": "weapon", "cost": 10, "description": "Fast magic orbs with 10% base critical chance."},
	"vest": {"name": "Warden vest", "slot": "armor", "cost": 6, "description": "Adds maximum health."},
	"boots": {"name": "Scout boots", "slot": "boots", "cost": 6, "description": "Adds movement speed."},
	"hood": {"name": "Pathfinder hood", "slot": "headgear", "cost": 6, "description": "Adds maximum health."},
	"pants": {"name": "Trailguard pants", "slot": "pants", "cost": 6, "description": "Adds movement speed."},
	"ring": {"name": "Ember ring", "slot": "ring", "cost": 8, "description": "Adds critical chance."},
	"bracelet": {"name": "Archer bracelet", "slot": "bracelet", "cost": 8, "description": "Adds firing speed."},
	"charm": {"name": "Scholar necklace", "slot": "necklace", "cost": 8, "description": "Increases experience gained."}
}
const SLOTS := ["weapon", "armor", "headgear", "pants", "boots", "necklace", "ring", "bracelet"]

static func stats(id: String, level: int) -> Dictionary:
	level = clampi(level, 1, MAX_LEVEL)
	var result := {"damage": 1, "interval": 0.45, "projectile_speed": 390.0, "pierce": 0, "critical": 0.0, "health": 0, "movement": 0.0, "xp": 0.0, "haste": 0.0}
	match id:
		"bow": result["damage"] = 1 + int((level - 1) / 2)
		"crossbow":
			result["damage"] = 2 + level - 1
			result["interval"] = 0.72
			result["projectile_speed"] = 470.0
			result["pierce"] = 1
		"wand":
			result["damage"] = 1 + int((level - 1) / 2)
			result["interval"] = 0.34
			result["projectile_speed"] = 320.0
			result["critical"] = 0.1
		"vest": result["health"] = 1 + level
		"hood": result["health"] = level
		"pants": result["movement"] = 0.05 + (level - 1) * 0.02
		"ring": result["critical"] = 0.05 + (level - 1) * 0.025
		"bracelet": result["haste"] = 0.05 + (level - 1) * 0.025
		"boots": result["movement"] = 0.08 + (level - 1) * 0.03
		"charm": result["xp"] = 0.1 + (level - 1) * 0.05
	if ITEMS.has(id) and ITEMS[id]["slot"] == "weapon": result["interval"] /= 1.0 + (level - 1) * 0.05
	return result

static func summary(id: String, level: int) -> String:
	var s := stats(id, level)
	match ITEMS[id]["slot"]:
		"weapon": return "%d DMG • %.1f/s • %d pierce • %d%% crit" % [s["damage"], 1.0 / s["interval"], s["pierce"], roundi(s["critical"] * 100)]
		"armor", "headgear": return "+%d maximum HP" % s["health"]
		"boots", "pants": return "+%d%% movement speed" % roundi(s["movement"] * 100)
		"ring": return "+%d%% critical chance" % roundi(s["critical"] * 100)
		"bracelet": return "+%d%% firing speed" % roundi(s["haste"] * 100)
		_: return "+%d%% XP gained" % roundi(s["xp"] * 100)
