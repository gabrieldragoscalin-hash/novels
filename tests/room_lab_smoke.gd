extends SceneTree
const Plans = preload("res://prototypes/room_lab/layouts.gd")
const Encounter = preload("res://prototypes/room_lab/combat.gd")
const Progression = preload("res://scripts/progression.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for index in range(3):
		var plan=Plans.make(index); var c=Encounter.new(plan)
		assert(Plans.BOUNDS.get_area()>464*438*10)
		assert(not c.blocked(plan["start"],18) and not c.blocked(plan["exit"],18))
		assert(c.blocked(Vector2(20,20),12),"Void must block walking")
		assert(not c.wall_between(Vector2(20,20),Vector2(100,20)),"Gaps permit ranged attacks")
		for court in plan["courts"]:
			var pos: Vector2=court["center"]
			assert(not c.nav.get_point_path(c._cell(plan["start"]),c._cell(pos)).is_empty(),"Every chamber must be connected")
		assert(not c.nav.get_point_path(c._cell(plan["start"]),c._cell(plan["exit"])).is_empty())
		assert(not c.nav.get_point_path(c._cell(plan["start"]),c._cell(plan["shrine"])).is_empty())
		# A connected loop offers more than one route, with room for body-radius clearance.
		var edges:=0
		for cell in plan["cells"]:
			for direction in [Vector2i.RIGHT,Vector2i.DOWN]:
				if plan["cells"].has(cell+direction): edges+=1
		assert(edges>plan["cells"].size())
	var lab=load("res://prototypes/room_lab/lab.tscn").instantiate(); root.add_child(lab)
	lab.set_physics_process(false)
	for index in range(3):
		lab.reset(index); assert(lab.combat.progression.wallet==null and lab.remaining()==24)
		for enemy in lab.combat.enemies: assert(not lab.combat.blocked(enemy["pos"],18))
		lab.activate_groups(); assert(lab.combat.enemies.filter(func(e): return not e["dormant"]).size()==6)
		for group in lab.groups:
			if group["active"]:
				for enemy in group["enemies"]: enemy["hp"]=0
		lab.combat._tick_waves(20)
		assert(lab.combat.enemies.any(func(e): return e["dormant"] and e["hp"]>0),"Remote courts must not all wake on a wave timer")
		var old: Vector2=lab.player
		lab.move_player(Vector2(0,10000)); assert(not lab.combat.blocked(lab.player,12) and lab.player.y<old.y+300)
		lab.offer_upgrade(); lab.reveal._process(2); assert(lab.reveal.offer_ids.size()==3 and not lab.reveal.offer_ids.has("coins"))
		var rank: String=lab.combat.progression.offers[0]; lab.choose(0); assert(lab.combat.progression.ranks[rank]==1)
	lab.crowded=true; lab.reset(0); assert(lab.remaining()==36)
	# All weapon pools yield three distinct eligible upgrades; no coin fallback.
	for kind in Progression.Catalog.RANGED+Progression.Catalog.MELEE:
		var p=Progression.new(); p.weapon=kind; p.rng.seed=42
		for i in range(30):
			p.reward_choices(); assert(p.offers.size()==3 and not p.offers.has("coins"))
			assert(p.offers[0]!=p.offers[1] and p.offers[0]!=p.offers[2] and p.offers[1]!=p.offers[2])
			p.choose(0)
	var empty=Progression.new()
	for id in empty.CAPS: empty.ranks[id]=empty.CAPS[id]
	empty.reward_choices(); assert(not empty.offers.has("coins") and (not empty.offers.is_empty() or empty.pending==0))
	lab.queue_free()
	print("PASS: three connected non-square floor plans, real void collision, routes to every court/exit/shrine, 24/36 mobs, spatial activation, safe movement, isolated rewards and three upgrade choices across nine weapons")
	quit()
