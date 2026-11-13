extends SceneTree
const Hub = preload("res://scripts/hub.gd")
const Gear = preload("res://scripts/equipment.gd")
const Dungeon = preload("res://scripts/dungeon.gd")
const Services = preload("res://scripts/services.gd")
const Combat = preload("res://scripts/combat.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var h = Hub.new(false)
	for kind in ["vest","hood","pants","boots","charm"]: assert(Gear.stats(kind,1)["health"]>0)
	for kind in ["vest","ring","bracelet","charm","boots","pants"]: h.equip_item(h.find_equipment(kind))
	var stats: Dictionary = h.loadout_stats()
	assert(stats["damage"]==2 and stats["critical_damage"]==0.25 and stats["critical"]==0.05)
	assert(stats["movement"]==0 and stats["xp"]==0)
	var c = Combat.new(Rect2(8,166,464,438),[])
	c.progression.apply_loadout(stats); c.health = 6
	c.hurt(1); assert(is_equal_approx(c.health,5.05))
	c.progression.base_critical = 1; c.progression.rng.seed = 1
	assert(c.progression.critical_multiplier()==2.25)
	# A ring increases actual projectile critical damage without adding crit chance.
	c.enemies = [{"pos":Vector2(240,300),"hp":100.0}]
	for seed_value in range(100):
		var rng := RandomNumberGenerator.new(); rng.seed = seed_value
		if rng.randf()<c.progression.critical_chance(): c.progression.rng.seed = seed_value; break
	c.arsenal._fire(Vector2(240,530),0,false,0)
	assert(is_equal_approx(c.bullets[0]["damage"],4.5))
	# Loot can yield no item while retaining normal coins and finite chest use.
	var d = Dungeon.new(9)
	for cell in d.rooms:
		if d.rooms[cell]["role"]=="loot": d.enter(cell); break
	var loot_combat = Combat.new(Rect2(8,166,464,438),[])
	loot_combat.enter(d.rooms[d.current],Vector2(240,530))
	var loot_hub = Hub.new(false); var service = Services.new(d,loot_combat,loot_hub)
	var drops := 0; d.rng.seed = 2025
	for i in range(50):
		d.rooms[d.current]["used"] = false
		var count: int = loot_hub.inventory.size()
		assert(service.loot() and not service.loot())
		if loot_hub.inventory.size()>count: drops += 1
	assert(drops>0 and drops<50 and loot_hub.coins==1000)
	# Confirmed reset replaces all saved data and active run, preserving save location.
	var path := "user://reset-test-%d.json" % Time.get_ticks_usec()
	var game = load("res://scenes/room.tscn").instantiate(); root.add_child(game)
	game.hub = Hub.new(true,path)
	game.hub.coins = 999; game.hub.gems = 999; game.hub.keys["gold"] = 12
	game.hub.perks["starting_hp"] = 25; game.hub.pity["gold"] = 34
	game.hub.find_equipment("wand",4,1); game.hub.save()
	game.start_game(); game.combat.invincible = true
	game.cheat_menu.reset_everything()
	assert(game.in_hub and not game.active and not game.combat.invincible)
	assert(game.hub.inventory.size()==1 and game.hub.coins==0 and game.hub.gems==0 and game.hub.highest_floor==0)
	var reloaded = Hub.new(true,path)
	assert(reloaded.inventory.size()==1 and reloaded.keys["gold"]==0 and reloaded.perks["starting_hp"]==0 and reloaded.pity["gold"]==0)
	assert(game.FLOOR.size.x*game.FLOOR.size.y>416*422)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("PASS: item roles, flat bracelet damage, critical damage, fractional armor reduction, larger geometry, full reset and saved fresh profile")
	game.queue_free(); quit(0)
