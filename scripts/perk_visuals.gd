extends RefCounted
const ICONS := {
	"starting_upgrade":preload("res://art/perks/starting_upgrade.svg"),"starting_hp":preload("res://art/perks/starting_hp.svg"),
	"dodge":preload("res://art/perks/dodge.svg"),"boss_damage":preload("res://art/perks/boss_damage.svg"),
	"recovery":preload("res://art/perks/recovery.svg"),"resourceful":preload("res://art/perks/resourceful.svg"),
	"scavenger":preload("res://art/perks/scavenger.svg"),"collector":preload("res://art/perks/collector.svg"),
	"trap_resist":preload("res://art/perks/trap_resist.svg"),"elite_hunter":preload("res://art/perks/elite_hunter.svg"),
	"treasure_sense":preload("res://art/perks/treasure_sense.svg"),"loot_gold":preload("res://art/perks/loot_gold.svg")}
const LOCK = preload("res://art/perks/lock.svg")
static func effect(id: String, rank: int) -> String:
	match id:
		"starting_upgrade": return "Start each run with an upgrade choice"
		"starting_hp": return "Starting HP +%d" % rank
		"dodge": return "Dodge chance +%d%%" % rank
		"boss_damage": return "Boss damage +%d%%" % (rank*2)
		"recovery": return "Healing received +%d%%" % rank
		"resourceful": return "Dungeon shop prices −%.1f%%" % (rank*0.5)
		"scavenger": return "Dungeon coins +%d%%" % rank
		"collector": return "XP pickup radius +%d%%" % (rank*2)
		"trap_resist": return "Trap damage −%d%%" % rank
		"elite_hunter": return "Brute & miniboss damage +%.1f%%" % (rank*0.5)
		"treasure_sense": return "Loot equipment chance +%.1f%%" % (rank*0.2)
		"loot_gold": return "Loot-room coins +%d%%" % rank
	return ""
