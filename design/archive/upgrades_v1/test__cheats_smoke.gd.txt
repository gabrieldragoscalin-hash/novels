extends SceneTree
const Hub = preload("res://scripts/hub.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/room.tscn").instantiate()
	root.add_child(game)
	game.hub = Hub.new(false); game._refresh_hub()
	var menu = game.cheat_menu
	menu.open(); assert(menu.visible and game.in_hub)
	for button in menu.run_buttons: assert(button.disabled)
	menu.grant("coins"); menu.grant("gems"); menu.grant("keys"); menu.grant("parts"); menu.grant("pity")
	assert(game.hub.coins == 10000 and game.hub.gems == 1000)
	for key in game.hub.keys: assert(game.hub.keys[key] == 35 and game.hub.pity[key] == 34)
	assert(game.hub.parts["weapon"] == 100)
	game.hub.daily_clears["1"] = 3; game.hub.offers[0]["sold"] = true
	menu.grant("daily"); assert(game.hub.daily_clears.is_empty() and not game.hub.offers[0]["sold"])
	menu.rarity_picker.select(4); menu._enhancements(); menu.plus_picker.select(2); menu.copies.value = 4
	var before: int = game.hub.inventory.size(); menu.give_items()
	assert(game.hub.inventory.size() == before+4)
	var matched := 0
	for item in game.hub.inventory.values():
		if item["rarity"] == 4 and item["plus"] == 2: matched += 1
	assert(matched == 4)
	menu.rarity_picker.select(5); menu._enhancements(); assert(menu.plus_picker.item_count == 1)
	menu.grant("unlock_perks")
	for rank in game.hub.perks.values(): assert(rank == 1)
	menu.floor_picker.select(2); menu.start_floor()
	assert(game.active and not menu.visible and game.dungeon.floor_number == 3)
	assert(game.hub.keys["copper"] == 35, "Skipping floors must not pay floor keys")
	menu.open()
	menu.upgrade_picker.select(menu.upgrade_ids.find("ricochet")); menu.give_upgrade()
	assert(game.combat.progression.ranks["ricochet"] == 1)
	menu.toggle_god()
	game.combat.grace_time = 0; game.combat.hurt_time = 0
	var hp: int = game.combat.health; game.combat.hurt(99); assert(game.combat.health == hp)
	var clock: float = game.clock; game._physics_process(1.0); assert(game.clock == clock)
	menu.flares(); assert(game.combat.progression.flares == 100)
	menu.level_up(); assert(game.combat.progression.pending == 2)
	menu.teleport_boss(); assert(game.dungeon.rooms[game.dungeon.current]["role"] == "boss")
	menu.open(); menu.clear_room()
	assert(game.combat.alive_count() == 0 and game.dungeon.rooms[game.dungeon.current]["boss_paid"])
	assert(game.hub.keys["copper"] == 37)
	menu.clear_room(); assert(game.hub.keys["copper"] == 37, "Repeat clears must not repeat rewards")
	game.combat.health = 1; menu.heal(); assert(game.combat.health == game.combat.progression.max_health())
	menu.room_picker.select(24); menu.teleport(); assert(game.dungeon.current == Vector2i(4,4))
	menu.floor_picker.select(0); menu.start_floor(); assert(not game.combat.invincible and game.dungeon.floor_number == 1)
	print("PASS: cheat grants, copy rarity/stage, daily reset, perks, floor cap, pause, god mode, heal, XP, flares, teleport, normal boss rewards and no duplicate payouts")
	game.queue_free(); quit(0)
