extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room = load("res://scenes/room.tscn").instantiate()
	root.add_child(room)
	assert(not room.active, "Start screen must pause movement")
	room.start_game()
	assert(room.active and not room.start_panel.visible)
	room.move_player(Vector2(0, -30))
	assert(room.player == Vector2(240, 500), "Player should move on empty floor")
	room.player = Vector2(90, 310)
	room.move_player(Vector2(100, 0))
	assert(room.player.x <= 96, "Pillars must block the player")
	room.player = Vector2(240, 530)
	room.move_player(Vector2(0, 1000))
	assert(room.player.y <= 584, "Player must stay within room walls")
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(220, 680)
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
	room.pointer = 0
	room._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(room.pointer == -1, "Losing focus must release movement")
	room.reset_player()
	assert(room.player == Vector2(240, 530))
	print("PASS: start gate, movement, pillar collision, bounds, touch ownership, release, focus loss, reset")
	room.queue_free()
	quit(0)
