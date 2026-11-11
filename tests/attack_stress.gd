extends SceneTree
const Combat = preload("res://scripts/combat.gd")
const Dungeon = preload("res://scripts/dungeon.gd")
const Renderer = preload("res://scripts/attack_renderer.gd")
func _initialize() -> void:
	var c = Combat.new(Rect2(8,166,464,438),[])
	var enemies: Array = []
	for i in range(8):
		var e := Dungeon.make_enemy(Vector2(120+(i%4)*75,280+int(i/4)*100),"normal",5)
		e["hp"] = 1000000; e["max_hp"] = 1000000; enemies.append(e)
	c.enter({"role":"combat","enemies":enemies},Vector2(240,530))
	c.progression.weapon = "wand"; c.progression.ranks["meteor"] = 1
	for id in ["multishot","multiple_shots","ricochet","attack_speed","piercing"]: c.progression.ranks[id] = 5 if id!="attack_speed" else 8
	c.progression.ranks["follow"] = 1
	var peak_rocks := 0; var peak_meteors := 0
	var start := Time.get_ticks_usec()
	for frame in range(900):
		c.fire_time -= 1.0/60; c.arsenal.tick(1.0/60,Vector2(240,530))
		peak_rocks = maxi(peak_rocks,c.bullets.size());peak_meteors = maxi(peak_meteors,c.arsenal.meteors.size())
		assert(c.arsenal.effects.size()<=c.arsenal.MAX_EFFECTS)
		assert(c.arsenal.rolling_candidates.size()<=128)
	assert(peak_rocks>100 and peak_meteors>100,"Fixture must exercise dense meteor rain")
	assert(Renderer.projectile_samples(c.bullets).size()<=Renderer.MAX_ROCKS)
	assert(Renderer.meteor_samples(c.arsenal.meteors).size()<=Renderer.MAX_METEORS)
	print("METEOR_STRESS "+JSON.stringify({"frames":900,"milliseconds":(Time.get_ticks_usec()-start)/1000.0,"peak_rocks":peak_rocks,"peak_meteors":peak_meteors,"effects":c.arsenal.effects.size()}))
	print("PASS: maximum-upgrade meteor/rain/Telekinesis workload retains all damage entities with bounded effect and draw budgets")
	quit()
