extends SceneTree
const Art = preload("res://scripts/game_art.gd")
const Surfaces = preload("res://scripts/room_surfaces.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(Art.ARENA_FLOOR.get_width()>1000)
	for key in Art.MASONRY_KEYS:
		var texture := Art.frame(key)
		assert(texture.atlas==Art.MASONRY and texture.filter_clip)
		assert(Rect2(Vector2.ZERO,Art.MASONRY.get_size()).encloses(texture.region))
	for key in Surfaces.KEYS:
		var texture := Surfaces.frame(key)
		assert(texture.get_width()>300 and texture.get_height()>300)
		assert(texture.filter_clip and texture==Surfaces.frame(key))
	var game = load("res://scenes/room.tscn").instantiate(); root.add_child(game)
	game.hub = preload("res://scripts/hub.gd").new(false);game.seed_override = 6;game.start_game();game.set_physics_process(false)
	assert(game.room_backdrop.layout==game.layout_index and game.room_backdrop.z_index<game.z_index)
	var revision: int = game.room_backdrop.revision
	for i in range(60): game._physics_process(1.0/60)
	assert(game.room_backdrop.revision==revision,"Static architecture must not be rebuilt every frame")
	assert(game.combat.shot_obstacles==game.PILLARS)
	game.queue_free()
	print("PASS: eight original masonry modules, eight clipped material tiles, cached static backdrop, and matching cover collision")
	quit()
