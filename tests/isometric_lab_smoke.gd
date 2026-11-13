extends SceneTree
const Plans = preload("res://prototypes/isometric_lab/stage.gd")
const Models = preload("res://prototypes/isometric_lab/models.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(480,800)
	var lab=load("res://prototypes/isometric_lab/lab.tscn").instantiate(); root.add_child(lab); lab.set_physics_process(false)
	assert(lab.camera.projection==Camera3D.PROJECTION_ORTHOGONAL and lab.viewport.own_world_3d)
	assert(lab.world.get_child_count()>20 and lab.alive()==3)
	assert(not Plans.blocked(lab.player,lab.obstacles) and Plans.blocked(Vector2(30,30),lab.obstacles))
	assert(Plans.blocked(Vector2(0,0),lab.obstacles),"The central pit must be a real movement gap")
	assert(not Plans.floor_contains(Vector2(0,0)) and Plans.floor_contains(Vector2(0,4)))
	assert(Plans.blocked(Vector2(-6,-9),lab.obstacles),"Monumental walls must block movement")
	# Architectural collision must leave both routes around the pit connected.
	var reached: Dictionary={}; var pending: Array[Vector2i]=[Vector2i(0,-12)]; reached[pending[0]]=true; var cursor:=0
	while cursor<pending.size():
		var cell: Vector2i=pending[cursor]; cursor+=1
		for d in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var next: Vector2i=cell+d
			if next.x< -44 or next.x>27 or next.y< -37 or next.y>22 or reached.has(next): continue
			if not Plans.blocked(Vector2(next)*0.4,lab.obstacles): reached[next]=true; pending.append(next)
	for point in [Vector2i(0,-30),Vector2i(-33,-5),Vector2i(-11,9),Vector2i(12,12)]: assert(reached.has(point),"Crypt architecture must keep the side shrine, terrace and both aisles accessible")
	var a: Vector2=lab.camera.unproject_position(Plans.point(lab.player))
	var b: Vector2=lab.camera.unproject_position(Plans.point(lab.player+lab.screen_direction(Vector2.RIGHT)))
	assert(b.x>a.x and absf(b.y-a.y)<1,"Movement must be relative to the fixed camera")
	var c: Vector2=lab.camera.unproject_position(Plans.point(lab.player+lab.screen_direction(Vector2.UP)))
	assert(c.y<a.y and absf(c.x-a.x)<1)
	lab.player=Vector2(-6,2); lab.move_player(Vector2(8,0)); assert(lab.player.x< -5 and not Plans.blocked(lab.player,lab.obstacles))
	lab.player=Vector2(0,5); lab.move_player(Vector2(100,0)); assert(lab.player.x<10 and not Plans.blocked(lab.player,lab.obstacles))
	# Connected main platform, side bridge and climbable terrace; no teleporting to higher floors.
	for pos in [Vector2(-10.5,-1.5),Vector2(-13,-2),Vector2(0,-8.5),Vector2(0,-12)]: assert(not Plans.blocked(pos,lab.obstacles))
	assert(is_equal_approx(Plans.height_at(Vector2(0,-8.5)),0.625) and Plans.height_at(Vector2(0,-12))==1.25)
	lab.player=Vector2(0,4.7); lab.enemies[0]["pos"]=Vector2(0,3.8); lab.enemies[0]["node"].position=Plans.point(lab.enemies[0]["pos"])
	lab.attack(); assert(lab.enemies[0]["hp"]==2 and lab.attack_cycle==1)
	lab.attack(); assert(lab.attack_cycle==1,"Attack cooldown must prevent duplicate taps")
	lab.weapon="spear"; Models.equip(lab.rig,"spear")
	assert(lab.rig["mount"].get_node("Weapon").get_child_count()>1)
	assert(lab.rig["mount"].get_node("Weapon").get_parent()==lab.rig["arms"][1].get_meta("hand"))
	lab.facing=Vector2.RIGHT; lab.dash(); var cd: float=lab.dash_cooldown; lab.dash(); assert(cd==lab.dash_cooldown and lab.dash_left>0)
	lab.player=Vector2(0,-8.5); lab._physics_process(0.01); assert(is_equal_approx(lab.rig["root"].position.y,Plans.height_at(lab.player)))
	lab.overview=true; var before: Vector2=lab.player; lab._physics_process(0.1); assert(lab.player==before)
	lab.reset(); assert(lab.health==6 and lab.alive()==3)
	assert(lab.get_script().source_code.find("HubState.new")==-1)
	lab.queue_free()
	print("PASS: isolated real 3D stage, orthographic camera, screen-relative movement, void/cover collision, bridge/stair access, height alignment, physical weapon grip, melee damage, cooldowns, dash and reset")
	quit()
