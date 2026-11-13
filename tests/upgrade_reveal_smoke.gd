extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(480,800)
	var room = load("res://scenes/room.tscn").instantiate(); root.add_child(room)
	room.hub = load("res://scripts/hub.gd").new(false); room.start_game()
	room.combat.progression.add_xp(10)
	var offers: Array = room.combat.progression.offers.duplicate()
	var rng_state: int = room.combat.progression.rng.state
	room._show_level_up(); var reveal = room.level_panel; reveal.set_process(false)
	assert(reveal.slowing() and is_equal_approx(reveal.world_speed(),0.65))
	room._choose_upgrade(2)
	assert(room.combat.progression.pending==2 and room.hub.coins==0,"Early touches must not choose")
	var before: float = room.run_time
	room._physics_process(0.1)
	assert(is_equal_approx(room.run_time-before,0.065),"Combat must actually slow before cards appear")
	assert(room.combat.health>0 and room.combat.grace_time>0)
	reveal._process(0.46); assert(reveal.phase=="rolling")
	before = room.run_time; room._physics_process(0.1)
	assert(room.run_time==before,"Combat must pause while cards roll and await selection")
	reveal._process(2)
	assert(reveal.ready_for_choice() and room.combat.progression.offers==offers)
	for i in range(offers.size()):
		assert(reveal.cards[i].clip.size==Vector2(116,248),"Rolling content must have a nonzero clip viewport")
		assert(reveal.cards[i].landed and not reveal.cards[i].disabled and reveal.cards[i].names[0].text==reveal.cards[i].final_entry["title"])
	assert(room.combat.progression.rng.state==rng_state,"Cosmetic rolling must not consume reward RNG")
	room._choose_upgrade(2)
	assert(room.combat.progression.pending==1 and room.hub.coins==20 and reveal.phase=="rolling", "Queued rewards must remain paused")
	room._choose_upgrade(2); assert(room.hub.coins==20,"Queued cards must settle before another choice")
	reveal._process(2); room._choose_upgrade(2)
	assert(room.combat.progression.pending==0 and room.hub.coins==40 and not reveal.visible)
	assert(room.combat.grace_time>=0.5 and Engine.time_scale==1)
	room.combat.progression.reward_choices(2,false); room._show_level_up("FREE UPGRADE")
	assert(not reveal.slowing() and reveal.offer_ids.size()==2)
	room.restart_run(); assert(not reveal.visible and reveal.phase=="idle")
	room.combat.progression.weapon = "wand"; room.combat.progression.ranks["meteor"] = 1
	assert(reveal.entry(room.combat.progression,"piercing")["title"]=="Meteor Size")
	assert(reveal.entry(room.combat.progression,"second_chance")["badge"]=="RARE")
	# New weapon cards must fit inside the existing mobile reel layout.
	for kind in room.combat.progression.Catalog.RANGED+room.combat.progression.Catalog.MELEE:
		room.combat.progression.weapon = kind
		for id in room.combat.progression.Catalog.ACTIVE:
			var entry = reveal.entry(room.combat.progression,id)
			reveal.cards[0]._fill(0,entry)
			assert(reveal.cards[0].names[0].get_minimum_size().y<=53,id+" title clips")
			assert(reveal.cards[0].descriptions[0].get_minimum_size().y<=99,id+" description clips")
	room.queue_free()
	print("PASS: real slowdown, invulnerability, rolling/input gate, stable offers/RNG, paused queued choices, coins once, safe resume/reset, two choices and dynamic meteor glyphs")
	quit()
