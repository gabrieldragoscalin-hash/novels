extends RefCounted
## Explicit prototype prices/odds; structural rules live in ECONOMY_SPEC.md.
const RARITIES := ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"]
const COLORS := [Color("aab1ba"),Color("72c586"),Color("76aeeb"),Color("ba87df"),Color("efcf69"),Color("ff8b3d")]
const ODDS := {"copper":[55.0,35.0,9.0,1.0,0.0], "silver":[38.0,32.0,26.0,3.5,0.5], "gold":[15.0,20.0,45.0,16.0,4.0]}
const GEM_COST := {"copper":60,"silver":200,"gold":500}
const PART_COST := 50
const PART_QUANTITY := 5
const ITEM_COST := 150
const PERK_INCREMENT := 50
const REQUIRE_RESERVED_PERKS := false
const TASKS_ENABLED := false
const TASKS: Dictionary = {}

static func day_id(now: int = -1) -> int:
	return int((int(Time.get_unix_time_from_system()) if now < 0 else now) / 86400)

static func floor_reward(floor_number: int) -> Dictionary:
	if floor_number <= 0: return {}
	if floor_number % 5 == 0: return {"kind":"gold", "amount":int(floor_number / 5)}
	if floor_number < 5: return {"kind":"copper" if floor_number % 2 == 1 else "silver", "amount":1 if floor_number <= 2 else 2}
	return {"kind":"copper" if (floor_number - 1) % 5 % 2 == 0 else "silver", "amount":int(floor_number / 5) + 2}

static func part_for(slot: String) -> String:
	if slot == "weapon": return "weapon"
	if slot in ["armor","headgear","pants","boots"]: return "armor"
	return "accessory"

static func recipe(item: Dictionary) -> Dictionary:
	var rarity: int = item["rarity"]
	var plus: int = item["plus"]
	if rarity == 0: return {"count":3,"exact":false,"fodder_plus":0,"rarity":1,"plus":0}
	if rarity in [1,2]: return {"count":3,"exact":true,"fodder_plus":0,"rarity":rarity+1,"plus":0}
	if rarity == 3 and plus == 0: return {"count":2,"exact":false,"fodder_plus":0,"rarity":3,"plus":1}
	if rarity == 3 and plus == 1: return {"count":1,"exact":true,"fodder_plus":1,"rarity":4,"plus":0}
	if rarity == 4 and plus == 0: return {"count":2,"exact":false,"fodder_plus":0,"rarity":4,"plus":1}
	if rarity == 4 and plus == 1: return {"count":2,"exact":false,"fodder_plus":0,"rarity":4,"plus":2}
	if rarity == 4 and plus == 2: return {"count":1,"exact":true,"fodder_plus":2,"rarity":5,"plus":0}
	return {}
