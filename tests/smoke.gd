extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room = load("res://scenes/room.tscn").instantiate()
	root.add_child(room)
	assert(not room.active, "Start screen must pause movement")
	room.hub = load("res://scripts/hub.gd").new(false)
	room.seed_override = 6 # Open processional floor for the baseline movement fixture.
	room.start_game()
	assert(room.active and not room.start_panel.visible)
	room.move_player(Vector2(0, -30))
	assert(room.player == Vector2(240, 500), "Player should move on empty floor")
	var prop: Rect2 = room.PILLARS[0]
	room.player = Vector2(prop.position.x-20,prop.get_center().y)
	room.move_player(Vector2(100, 0))
	assert(room.player.x <= prop.position.x-room.RADIUS, "Solid props must block the player")
	room.player = Vector2(65, 530)
	room.move_player(Vector2(0, 1000))
	assert(room.player.y <= room.FLOOR.end.y-room.RADIUS, "Player must stay within room walls")
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(220, 380)
	touch.pressed = true
	room._input(touch)
	assert(room.pointer == 0, "Touch should activate the joystick")
	var second := InputEventScreenTouch.new()
	second.index = 1
	second.position = Vector2(280, 680)
	second.pressed = true
	room._input(second)
	assert(room.pointer == 0, "Second finger must not steal joystick")
	touch.pressed = false
	room._input(touch)
	assert(room.pointer == -1, "Releasing touch must stop the joystick")
	for pos in [Vector2(30, 80), Vector2(220, 380), Vector2(50, 900)]:
		touch.position = pos
		touch.pressed = true
		room._input(touch)
		assert(room.pointer == 0 and room.stick_origin == pos, "Joystick must start at any non-button touch")
		touch.pressed = false
		room._input(touch)
	touch.position = Vector2(200, 750)
	touch.pressed = true
	room._input(touch)
	assert(room.pointer == -1, "Buttons must not activate movement")
	room.pointer = 0
	room._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(room.pointer == -1, "Losing focus must release movement")
	room.reset_player()
	assert(room.player == Vector2(240, 530))
	for state in room.dungeon.rooms.values(): state["visits"] = 0
	room.dungeon.enter(Vector2i.ZERO)
	# Traverse every room in a snake, then return through the same doors.
	var route: Array[Vector2i] = []
	for y in range(5):
		for x in range(4): route.append(Vector2i.RIGHT if y % 2 == 0 else Vector2i.LEFT)
		if y < 4: route.append(Vector2i.DOWN)
	for direction in route:
		await cross_door(room, direction)
	assert(room.dungeon.current == Vector2i(4, 4))
	for state in room.dungeon.rooms.values(): assert(state["visits"] > 0, "All 25 rooms must be reachable")
	route.reverse()
	for direction in route:
		await cross_door(room, -direction)
	assert(room.dungeon.current == Vector2i.ZERO)
	assert(room.dungeon.rooms[Vector2i.ZERO]["visits"] == 2, "Visits must survive room changes")
	room.player = Vector2(240,room.FLOOR.position.y+room.RADIUS)
	room.move_player(Vector2(0, -10))
	assert(not room.transitioning and room.dungeon.current == Vector2i.ZERO, "Outer wall cannot leave grid")
	print("PASS: 25 rooms, bidirectional doors, transitions, outer boundaries, persistent visits")
	print("PASS: start gate, movement, pillar collision, bounds, touch ownership, release, focus loss, reset")
	room.queue_free()
	quit(0)

func cross_door(room: Node, direction: Vector2i) -> void:
	var previous: Vector2i = room.dungeon.current
	if direction == Vector2i.RIGHT: room.player = Vector2(room.FLOOR.end.x-room.RADIUS,385)
	elif direction == Vector2i.LEFT: room.player = Vector2(room.FLOOR.position.x+room.RADIUS,385)
	elif direction == Vector2i.DOWN: room.player = Vector2(240,room.FLOOR.end.y-room.RADIUS)
	else: room.player = Vector2(240,room.FLOOR.position.y+room.RADIUS)
	room.move_player(Vector2(direction) * 2)
	assert(room.transitioning, "Walking into an open door starts a transition")
	room.move_player(Vector2(direction) * 1000)
	assert(room.dungeon.current == previous, "Movement must pause during fade-out")
	await room.transition_finished
	assert(room.dungeon.current == previous + direction)
	assert(not room._blocked(room.player), "Entrance must not intersect a pillar")
	assert(room.FLOOR.grow(-room.RADIUS).has_point(room.player))
