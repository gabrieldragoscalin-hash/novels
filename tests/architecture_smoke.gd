extends SceneTree
const Plans = preload("res://scripts/room_layouts.gd")
const Combat = preload("res://scripts/combat.gd")
const Dungeon = preload("res://scripts/dungeon.gd")
const BOUNDS := Rect2(8,166,464,438)
const ANCHORS := [Vector2(72,385),Vector2(408,385),Vector2(240,214),Vector2(240,556),Vector2(240,385),Vector2(240,530)]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for layout in range(Plans.THEMES.size()):
		var c = Combat.new(BOUNDS,Plans.obstacles(layout))
		c.set_obstacles(Plans.obstacles(layout),Plans.terrain(layout))
		for a in ANCHORS:
			assert(not c.blocked(a,18),"Blocked entrance/service in "+Plans.THEMES[layout])
			for b in ANCHORS: assert(not c.nav.get_point_path(c._cell(a),c._cell(b)).is_empty(),"Disconnected anchors")
		# Every walkable navigation cell must belong to the entrance component.
		var reached := {}; var queue: Array[Vector2i] = [c._cell(ANCHORS[0])]
		reached[queue[0]] = true
		var cursor := 0
		while cursor<queue.size():
			var cell := queue[cursor]; cursor += 1
			for step in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var next: Vector2i = cell+step
				if not c.nav.region.has_point(next) or c.nav.is_point_solid(next) or reached.has(next): continue
				reached[next] = true; queue.append(next)
		for y in range(c.nav.region.size.y):
			for x in range(c.nav.region.size.x):
				var cell := Vector2i(x,y)
				assert(c.nav.is_point_solid(cell) or reached.has(cell),"Isolated floor in "+Plans.THEMES[layout])
		for gap in Plans.terrain(layout): assert(c.blocked(gap.get_center(),12))
		for bridge in Plans.bridges(layout): assert(not c.blocked(bridge.get_center(),18))
		# Every default spawn is projected safely when an encounter enters a layout.
		var enemies: Array = []
		for pos in Dungeon._spawn_points(): enemies.append(Dungeon.make_enemy(pos,"normal",1))
		for gap in Plans.terrain(layout): enemies.append(Dungeon.make_enemy(gap.get_center(),"normal",1))
		c.enter({"role":"combat","enemies":enemies},Vector2(240,556))
		for enemy in enemies: assert(not c.blocked(enemy["pos"],13),"Enemy inside terrain")
	# Filling the crossing must disconnect the two banks: the bridge is necessary.
	for layout in [1,2,4]:
		var gaps := Plans.terrain(layout)
		gaps.append_array(Plans.bridges(layout))
		var sealed = Combat.new(BOUNDS,Plans.obstacles(layout))
		sealed.set_obstacles(Plans.obstacles(layout),gaps)
		var a := Vector2(240,214) if layout!=4 else Vector2(72,385)
		var b := Vector2(240,556) if layout!=4 else Vector2(408,385)
		assert(sealed.nav.get_point_path(sealed._cell(a),sealed._cell(b)).is_empty(),"Crossing must require bridge")
	var c = Combat.new(BOUNDS,Plans.obstacles(1))
	c.set_obstacles(Plans.obstacles(1),Plans.terrain(1))
	assert(c.blocked(Vector2(120,326),12))
	assert(not c.wall_between(Vector2(120,280),Vector2(120,390)),"Shots must cross the channel")
	assert(c.wall_between(Vector2(169,245),Vector2(169,310)),"Solid props must still stop shots")
	var enemy := Dungeon.make_enemy(Vector2(120,250),"normal",1)
	var crossed_bridge := false
	for tick in range(700):
		c.enemy_ai._walk(enemy,1.0/60,Vector2(120,390))
		assert(not c.blocked(enemy["pos"],13),"Enemy walked into canal")
		if enemy["pos"].y>300 and enemy["pos"].y<352: crossed_bridge = true; assert(enemy["pos"].x>213 and enemy["pos"].x<267)
	assert(crossed_bridge and enemy["pos"].distance_to(Vector2(120,390))<20,"Enemy must find and cross bridge")
	# A charge cannot tunnel across the channel instead of using the bridge.
	enemy["pos"] = Vector2(120,275)
	c.enemy_ai._move(enemy,Vector2(0,180)); assert(enemy["pos"].y<287)
	print("PASS: six architectural plans; all walkable floor connected; doors/services/spawns safe; bridge navigation, movement-only gaps and solid cover")
	quit()
