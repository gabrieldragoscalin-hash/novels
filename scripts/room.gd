extends Node2D
## Connected-room prototype; combat and floor progression come later.
signal transition_finished
const DungeonState = preload("res://scripts/dungeon.gd")
const SPEED := 185.0
const RADIUS := 12.0
const FLOOR := Rect2(32, 174, 416, 422)
const PILLARS: Array[Rect2] = [Rect2(108, 290, 38, 40), Rect2(334, 290, 38, 40), Rect2(108, 456, 38, 40), Rect2(334, 456, 38, 40)]
var dungeon = DungeonState.new()
var transitioning := false
var fade: ColorRect
var player := Vector2(240, 530)
var active := false
var pointer := -1
var stick_origin := Vector2.ZERO
var stick_position := Vector2.ZERO
var pointer_mouse := false
var facing := 1.0
var clock := 0.0
var distance_walked := 0.0
var start_panel: PanelContainer
var status_label: Label
var movement_blockers: Array[Control] = []
var font := ThemeDB.fallback_font

func _ready() -> void:
	_build_ui()
	_update_room_label()
	get_viewport().focus_exited.connect(_release_stick)
	queue_redraw()

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)
	_label(root, "THE DUNGEON", Vector2(28, 25), 25, Color("eee5cc"))
	_label(root, "FIRST STEPS   /   EXPLORE 25 ROOMS", Vector2(29, 61), 11, Color("96a3b6"))
	status_label = _label(root, "ROOM A1     •     FLOOR 01", Vector2(29, 109), 13, Color("dfbd78"))
	_label(root, "Touch and drag anywhere to move", Vector2(99, 623), 16, Color("d2d7df"))
	_label(root, "WASD / arrow keys on a computer", Vector2(126, 648), 12, Color("8594aa"))
	_label(root, "Walk into a doorway to change rooms", Vector2(117, 676), 12, Color("dfbd78"))
	var reset := Button.new()
	reset.text = "Reset position"
	reset.position = Vector2(164, 737)
	reset.size = Vector2(152, 40)
	reset.pressed.connect(reset_player)
	root.add_child(reset)
	movement_blockers.append(reset)
	start_panel = PanelContainer.new()
	start_panel.position = Vector2(54, 250)
	start_panel.size = Vector2(372, 240)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("131e30")
	style.border_color = Color("a7864d")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 25
	style.content_margin_right = 25
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	start_panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	start_panel.add_child(box)
	var title := Label.new()
	title.text = "Explore the dungeon"
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)
	var text := Label.new()
	text.text = "25 connected rooms await.\nWalk through doors to explore.\nCombat and rewards come next."
	text.add_theme_font_size_override("font_size", 14)
	box.add_child(text)
	var start := Button.new()
	start.text = "Enter the dungeon"
	start.custom_minimum_size.y = 48
	start.pressed.connect(start_game)
	box.add_child(start)
	root.add_child(start_panel)
	var overlay := CanvasLayer.new()
	overlay.layer = 10
	add_child(overlay)
	fade = ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0.025, 0.035, 0.055, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(fade)

func _label(parent: Node, text: String, pos: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func start_game() -> void:
	active = true
	start_panel.hide()

func reset_player() -> void:
	if transitioning: return
	player = Vector2(240, 530)
	distance_walked = 0.0
	_release_stick()

func _release_stick() -> void:
	pointer = -1
	pointer_mouse = false
	stick_position = Vector2.ZERO
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release_stick()

func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventScreenTouch:
		if event.pressed and not transitioning and pointer == -1 and not pointer_mouse and _is_control_area(event.position):
			pointer = event.index
			stick_origin = event.position
			stick_position = event.position
		elif not event.pressed and event.index == pointer:
			_release_stick()
	elif event is InputEventScreenDrag and event.index == pointer:
		stick_position = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not transitioning and pointer == -1 and not pointer_mouse and _is_control_area(event.position):
			pointer_mouse = true
			stick_origin = event.position
			stick_position = event.position
		elif not event.pressed and pointer_mouse:
			_release_stick()
	elif event is InputEventMouseMotion and pointer_mouse:
		stick_position = event.position

func _is_control_area(pos: Vector2) -> bool:
	# UI buttons keep their normal behaviour, even with full-screen movement.
	for control in movement_blockers:
		if control.is_visible_in_tree() and control.get_global_rect().has_point(pos):
			return false
	return true

func _physics_process(delta: float) -> void:
	clock += delta
	if active and not transitioning:
		var direction := Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): direction.x -= 1
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): direction.x += 1
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): direction.y -= 1
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): direction.y += 1
		if pointer != -1 or pointer_mouse:
			direction += (stick_position - stick_origin).limit_length(45.0) / 45.0
		if direction.length() > 0.08:
			move_player(direction.limit_length(1.0) * SPEED * delta)
	queue_redraw()

func move_player(motion: Vector2) -> void:
	if transitioning: return
	var old := player
	# Substeps prevent tunnelling through pillars during frame stalls.
	var steps := maxi(1, int(ceil(motion.length() / 5.0)))
	var step := motion / steps
	for i in range(steps):
		var next := Vector2(clampf(player.x + step.x, FLOOR.position.x + RADIUS, FLOOR.end.x - RADIUS), player.y)
		if not _blocked(next): player.x = next.x
		next = Vector2(player.x, clampf(player.y + step.y, FLOOR.position.y + RADIUS, FLOOR.end.y - RADIUS))
		if not _blocked(next): player.y = next.y
	distance_walked += player.distance_to(old)
	if absf(motion.x) > 0.01: facing = signf(motion.x)
	_check_door(motion)

func _check_door(motion: Vector2) -> void:
	if not active: return
	var direction := Vector2i.ZERO
	if absf(player.x - 240) <= 28:
		if player.y <= 186.1 and motion.y < 0: direction = Vector2i.UP
		elif player.y >= 583.9 and motion.y > 0: direction = Vector2i.DOWN
	if absf(player.y - 385) <= 28:
		if player.x <= 44.1 and motion.x < 0: direction = Vector2i.LEFT
		elif player.x >= 435.9 and motion.x > 0: direction = Vector2i.RIGHT
	if direction != Vector2i.ZERO and dungeon.contains(dungeon.current + direction):
		_transition_to(direction)

func _transition_to(direction: Vector2i) -> void:
	if transitioning or not dungeon.contains(dungeon.current + direction): return
	transitioning = true
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.12)
	tween.tween_callback(func():
		dungeon.enter(dungeon.current + direction)
		if direction == Vector2i.RIGHT: player = Vector2(72, 385)
		elif direction == Vector2i.LEFT: player = Vector2(408, 385)
		elif direction == Vector2i.DOWN: player = Vector2(240, 214)
		else: player = Vector2(240, 556)
		_update_room_label()
	)
	tween.tween_property(fade, "color:a", 0.0, 0.12)
	tween.tween_callback(func():
		transitioning = false
		transition_finished.emit()
	)

func _update_room_label() -> void:
	status_label.text = "ROOM %s     •     FLOOR 01" % dungeon.room_name()

func _blocked(pos: Vector2) -> bool:
	for pillar in PILLARS:
		if pillar.grow(RADIUS).has_point(pos): return true
	return false

func _draw() -> void:
	# Layered wall faces and tile seams give the room a three-quarter appearance.
	draw_rect(Rect2(22, 149, 436, 459), Color("080e18"))
	draw_rect(Rect2(32, 150, 416, 44), Color("263348"))
	draw_rect(FLOOR, Color("192539"))
	for y in range(8):
		for x in range(8):
			var tile := Rect2(33 + x * 52, 175 + y * 52, 50, 50)
			var palette: Array[Color] = [Color("202f43"), Color("253a40"), Color("343047"), Color("3b3434"), Color("303b36")]
			var color := palette[(dungeon.current.x + dungeon.current.y) % palette.size()]
			if (x + y) % 2 != 0: color = color.lightened(0.045)
			draw_rect(tile, color)
	draw_rect(Rect2(22, 174, 10, 434), Color("344157"))
	draw_rect(Rect2(448, 174, 10, 434), Color("344157"))
	draw_rect(Rect2(22, 596, 436, 12), Color("101a2a"))
	# Only draw open passages where another grid room exists.
	for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if dungeon.contains(dungeon.current + direction):
			_draw_door(direction)
	_draw_minimap()
	draw_string(font, Vector2(216, 401), dungeon.room_name(), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.8, 0.85, 0.9, 0.18))
	for x in [76, 404]:
		draw_circle(Vector2(x, 187), 26, Color(0.95, 0.55, 0.2, 0.045))
		draw_rect(Rect2(x - 3, 175, 6, 15), Color("78634d"))
		draw_circle(Vector2(x, 173), 5 + sin(clock * 7 + x) * 0.7, Color("f4bb63"))
	for pillar in PILLARS:
		if pillar.end.y <= player.y: _draw_pillar(pillar)
	_draw_player()
	for pillar in PILLARS:
		if pillar.end.y > player.y: _draw_pillar(pillar)
	if pointer != -1 or pointer_mouse:
		draw_circle(stick_origin, 48, Color(0.5, 0.75, 0.85, 0.12))
		draw_arc(stick_origin, 48, 0, TAU, 48, Color("7193a6"), 2)
		draw_circle(stick_origin + (stick_position - stick_origin).limit_length(45), 20, Color("48b9a8"))

func _draw_shadow(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var angle := TAU * i / 24.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radii)
	draw_colored_polygon(points, color)

func _draw_pillar(pillar: Rect2) -> void:
	_draw_shadow(pillar.position + Vector2(22, 44), Vector2(29, 10), Color(0, 0, 0, 0.25))
	draw_rect(pillar, Color("354359"))
	draw_rect(Rect2(pillar.position - Vector2(4, 15), Vector2(46, 19)), Color("60718a"))
	draw_line(pillar.position + Vector2(5, 7), pillar.position + Vector2(5, 33), Color("485972"), 3)

func _draw_player() -> void:
	# Original placeholder adventurer, with feet anchored to the collision position.
	_draw_shadow(player + Vector2(0, 3), Vector2(15, 6), Color(0, 0, 0, 0.4))
	draw_colored_polygon(PackedVector2Array([player + Vector2(-12, -5), player + Vector2(-10, -23), player + Vector2(10, -23), player + Vector2(13, -5)]), Color("39bca7"))
	draw_line(player + Vector2(-5, -4), player + Vector2(-5, 1), Color("b7c5d3"), 5)
	draw_line(player + Vector2(5, -4), player + Vector2(5, 1), Color("b7c5d3"), 5)
	draw_circle(player + Vector2(0, -29), 10, Color("edd0a3"))
	draw_arc(player + Vector2(0, -31), 10, PI, TAU, 12, Color("343043"), 6)
	draw_circle(player + Vector2(facing * 4, -29), 1.4, Color("172131"))

func _draw_door(direction: Vector2i) -> void:
	var door: Rect2
	if direction == Vector2i.UP: door = Rect2(208, 149, 64, 45)
	elif direction == Vector2i.DOWN: door = Rect2(208, 578, 64, 30)
	elif direction == Vector2i.LEFT: door = Rect2(22, 353, 30, 64)
	else: door = Rect2(428, 353, 30, 64)
	draw_rect(door.grow(3), Color("8e7247"))
	draw_rect(door, Color("0a1420"))
	var center := door.get_center()
	var arrow := Vector2(direction)
	var side := Vector2(-arrow.y, arrow.x)
	draw_line(center - arrow * 7, center + arrow * 7, Color("dfbd78"), 2)
	draw_line(center + arrow * 7, center + side * 5, Color("dfbd78"), 2)
	draw_line(center + arrow * 7, center - side * 5, Color("dfbd78"), 2)

func _draw_minimap() -> void:
	for y in range(5):
		for x in range(5):
			var cell := Vector2i(x, y)
			var color := Color("263348")
			if dungeon.rooms[cell]["visits"] > 0: color = Color("527b80")
			if cell == dungeon.current: color = Color("dfbd78")
			draw_rect(Rect2(359 + x * 16, 24 + y * 16, 12, 12), color)
