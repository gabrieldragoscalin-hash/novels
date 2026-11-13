extends SceneTree
const Backgrounds = preload("res://scripts/room_backgrounds.gd")
const Plans = preload("res://scripts/room_layouts.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(Backgrounds.TEXTURES.size()==10 and Plans.THEMES.size()==10)
	var seen := {}
	for i in range(10):
		var texture := Backgrounds.texture(i)
		assert(texture.get_width()>1000 and texture.get_height()>1000)
		assert(texture==Backgrounds.texture(i) and not seen.has(texture.resource_path))
		seen[texture.resource_path] = true
	for seed_value in [1,6,9,42,235]:
		var used := {}
		for y in range(5):
			for x in range(5): used[Plans.index(seed_value,Vector2i(x,y))] = true
		assert(used.size()==10,"A dungeon must use all ten painted room backgrounds")
	var game = load("res://scenes/room.tscn").instantiate(); root.add_child(game)
	game.hub = preload("res://scripts/hub.gd").new(false);game.seed_override = 6;game.start_game();game.set_physics_process(false)
	assert(game.room_backdrop.layout==game.layout_index and game.room_backdrop.z_index<game.z_index)
	var revision: int = game.room_backdrop.revision
	for i in range(60): game._physics_process(1.0/60)
	assert(game.room_backdrop.revision==revision,"Background must not be rebuilt every frame")
	assert(game.combat.shot_obstacles==game.PILLARS)
	var exits: Array[Vector2i] = [Vector2i.UP,Vector2i.LEFT]
	game.room_backdrop.configure(4,1,exits)
	assert(game.room_backdrop.material.get_shader_parameter("exits")==Vector4(1,0,0,1))
	game.queue_free()
	print("PASS: ten unique complete room paintings, all ten used per dungeon, cached backdrop, recessed-door lighting and matching collision")
	quit()
