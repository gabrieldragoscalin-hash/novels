extends SceneTree
const Art = preload("res://scripts/game_art.gd")
const Layouts = preload("res://scripts/room_layouts.gd")
const Combat = preload("res://scripts/combat.gd")
const Dungeon = preload("res://scripts/dungeon.gd")
const Bosses = preload("res://scripts/boss_roster.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for key in Art.Layout.FRAMES:
		var frame := Art.frame(key)
		assert(frame.get_width()>20 and frame.get_height()>20,key)
		assert(Rect2(Vector2.ZERO,frame.atlas.get_size()).encloses(frame.region),key)
	assert(Art.BOSSES.get_image().get_pixel(0,0).a<0.1)
	for weapon in ["bow","crossbow","wand","sword","hammer","chakram"]: assert(Art.frame("weapon_"+weapon).atlas==Art.OBJECTS)
	for key in Art.Extensions.FRAMES:
		var frame = Art.frame(key)
		assert(Rect2(Vector2.ZERO,frame.atlas.get_size()).encloses(frame.region))
		assert(frame.get_width()>20 and frame.get_height()>20)
	assert(Art.Extensions.SHEET.get_image().get_pixel(0,0).a<0.1)
	assert(Art.frame("normal_0").atlas==Art.ENEMIES)
	assert(Art.frame("portrait")!=Art.frame("idle_front"))
	assert(Art.frame("walk_front_0").region!=Art.frame("walk_front_1").region)
	var entrances := [Vector2(72,385),Vector2(408,385),Vector2(240,214),Vector2(240,556),Vector2(240,385)]
	for layout in range(Layouts.THEMES.size()):
		var c = Combat.new(Rect2(8,166,464,438),Layouts.obstacles(layout))
		c.set_obstacles(Layouts.obstacles(layout),Layouts.terrain(layout))
		for a in entrances:
			assert(not c.blocked(a,18))
			for b in entrances: assert(not c.nav.get_point_path(c._cell(a),c._cell(b)).is_empty())
	var identities := {}
	var rotations := {}
	for floor_number in range(1,11):
		identities[Bosses.name_for(floor_number)] = true
		rotations[str(Bosses.sequence(floor_number))] = true
		var c = Combat.new(Rect2(8,166,464,438),[])
		var boss := Dungeon.make_enemy(Vector2(240,300),"boss",floor_number)
		c.enemies = [boss]
		for action in Bosses.sequence(floor_number):
			boss["phase"] = "idle"; boss["action"] = action; boss["aim"] = Vector2.DOWN
			c.enemy_ai._release(boss,floor_number-1,Vector2(240,500))
			if action in ["ring","cross","spiral","spread","combo"]: assert(not c.hostile_bullets.is_empty())
	var c = Combat.new(Rect2(8,166,464,438),[])
	c.enemies = [Dungeon.make_enemy(Vector2(240,280),"boss",1)]
	c.arsenal._fire(Vector2(240,500),0,false,0)
	assert(c.arsenal.pose_time==0.24 and c.arsenal.pose_direction.y<0)
	c.arsenal.reset(Vector2.ZERO); assert(c.arsenal.pose_time==0)
	assert(identities.size()==10 and rotations.size()==10)
	print("PASS: animated atlas, ten connected room layouts, nine held weapons, ten distinct boss identities/rotations and attack-synchronized poses")
	quit()
