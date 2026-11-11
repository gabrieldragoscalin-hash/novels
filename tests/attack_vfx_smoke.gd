extends SceneTree
const Vfx = preload("res://scripts/attack_vfx.gd")
const Renderer = preload("res://scripts/attack_renderer.gd")
const Combat = preload("res://scripts/combat.gd")
const Dungeon = preload("res://scripts/dungeon.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	Vfx.prepare(); assert(Vfx.frames.size()==48)
	for kind in Vfx.CLIPS:
		var first := Vfx.frame(kind,0)
		for index in range(Vfx.CLIPS[kind][2]):
			var frame := Vfx.frame(kind,index)
			assert(Rect2(Vector2.ZERO,frame.atlas.get_size()).encloses(frame.region))
			assert(absf(first.get_width()-frame.get_width())<=1 and absf(first.get_height()-frame.get_height())<=1)
		assert(Vfx.at(kind,0).region!=Vfx.at(kind,0.7).region)
	var many: Array = []; var meteors: Array = []
	for i in range(2000):
		many.append({"kind":"rolling_meteor" if i%2==0 else "bow","pos":Vector2(i%400,200+int(i/400)*50)})
		meteors.append({"pos":Vector2(i%400,200+int(i/400)*50)})
	assert(Renderer.projectile_samples(many).size()<=Renderer.MAX_PROJECTILES+Renderer.MAX_ROCKS)
	assert(Renderer.meteor_samples(meteors).size()<=Renderer.MAX_METEORS)
	assert(Renderer.meteor_samples(meteors.slice(0,3)).size()==3,"Ordinary multishot must show every meteor")
	assert(many.size()==2000 and meteors.size()==2000,"Visual sampling must not remove damage entities")
	var c = Combat.new(Rect2(8,166,464,438),[])
	var a := Dungeon.make_enemy(Vector2(120,300),"normal",1)
	var b := Dungeon.make_enemy(Vector2(180,300),"normal",1)
	c.enemies = [a,b]
	# These blasts share a visual cell but hit different enemies: both still resolve.
	c.arsenal._explode(Vector2(140,300),17,1,100)
	c.arsenal._explode(Vector2(159,300),17,1,100)
	assert(c.arsenal.effects.size()==1 and a["hp"]==4 and b["hp"]==4)
	for i in range(1000): c.arsenal._explode(Vector2(i%450,200),4,0,i+101)
	assert(c.arsenal.effects.size()<=c.arsenal.MAX_EFFECTS)
	c = Combat.new(Rect2(8,166,464,438),[])
	var sleeper := Dungeon.make_enemy(Vector2(230,300),"normal",1); sleeper["dormant"] = true
	c.enemies = [Dungeon.make_enemy(Vector2(120,300),"normal",1),Dungeon.make_enemy(Vector2(180,300),"normal",1),sleeper]
	for i in range(10): c.bullets.append({"pos":Vector2(90,300),"velocity":Vector2(1000,0),"kind":"rolling_meteor","radius":17.0,"damage":1.0,"hits":[],"remaining":999,"life":6.0,"cycle":1,"through":true})
	c.arsenal._tick_bullets(0.1)
	assert(c.enemies[0]["hp"]==4 and c.enemies[1]["hp"]==4 and sleeper["hp"]==5)
	sleeper["dormant"] = false; c.arsenal._tick_bullets(0.1)
	assert(sleeper["hp"]==4,"Newly active enemies must remain eligible for rolling damage")
	print("PASS: 48 fixed-cell animated VFX frames; bounded visual work with intact damage arrays; merged blasts preserve damage; swept rolling hits and dormant activation")
	quit()
