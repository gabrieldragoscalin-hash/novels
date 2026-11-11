extends RefCounted
## Item templates. Hub stores individually identified copies, levels and rarities.
const MAX_LEVEL := 5
const ITEMS := {
	"bow": {"name": "Ranger bow", "slot": "weapon", "description": "Normal arrows with balanced damage and speed."},
	"crossbow": {"name": "Iron crossbow", "slot": "weapon", "description": "Bigger arrows, slower attacks and higher damage."},
	"wand": {"name": "Ember wand", "slot": "weapon", "description": "Magic beams that pass through obstacles."},
	"sword": {"name":"Vanguard sword","slot":"weapon","description":"Slashes a forward arc at close range."},
	"hammer": {"name":"Earthshaker hammer","slot":"weapon","description":"Forward cone shockwaves hit an area."},
	"chakram": {"name":"Gale chakram","slot":"weapon","description":"Thrown disc chains to three more enemies with reduced damage."},
	"vest": {"name": "Warden vest", "slot": "armor", "description": "Adds maximum health."},
	"boots": {"name": "Scout boots", "slot": "boots", "description": "Adds movement speed."},
	"hood": {"name": "Pathfinder hood", "slot": "headgear", "description": "Adds maximum health."},
	"pants": {"name": "Trailguard pants", "slot": "pants", "description": "Adds movement speed."},
	"ring": {"name": "Ember ring", "slot": "ring", "description": "Adds critical chance."},
	"bracelet": {"name": "Archer bracelet", "slot": "bracelet", "description": "Adds firing speed."},
	"charm": {"name": "Scholar necklace", "slot": "necklace", "description": "Increases experience gained."}
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

static func instance_stats(item: Dictionary) -> Dictionary:
	var result := stats(item["type"], item["level"])
	var multiplier: float = [1.0,1.15,1.35,1.7,2.3,3.6][item["rarity"]] + item["plus"] * 0.25
	if ITEMS[item["type"]]["slot"] == "weapon":
		result["damage"] = maxi(1, int(ceil(result["damage"] * multiplier)) + int(item["plus"]))
	else:
		result["health"] = int(ceil(result["health"] * multiplier)) + (int(item["plus"]) if result["health"] > 0 else 0)
		for stat in ["movement","xp","critical","haste"]: result[stat] *= multiplier
	return result

static func instance_summary(item: Dictionary) -> String:
	var s := instance_stats(item)
	match ITEMS[item["type"]]["slot"]:
		"weapon": return "%d DMG • %.1f/s • %d pierce • %d%% crit" % [s["damage"],1.0/s["interval"],s["pierce"],roundi(s["critical"]*100)]
		"armor","headgear": return "+%d maximum HP" % s["health"]
		"boots","pants": return "+%d%% movement" % roundi(s["movement"]*100)
		"ring": return "+%d%% critical chance" % roundi(s["critical"]*100)
		"bracelet": return "+%d%% firing speed" % roundi(s["haste"]*100)
		_: return "+%d%% XP" % roundi(s["xp"]*100)
