extends Node2D
## First playable: one room, no combat or dungeon progression yet.
const SPEED := 185.0
const RADIUS := 12.0
const FLOOR := Rect2(32, 174, 416, 422)
const PILLARS: Array[Rect2] = [Rect2(108, 290, 38, 40), Rect2(334, 290, 38, 40), Rect2(108, 456, 38, 40), Rect2(334, 456, 38, 40)]
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
var font := ThemeDB.fallback_font

func _ready() -> void:
	_build_ui()
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
	_label(root, "FIRST STEPS   /   MOVEMENT PROTOTYPE", Vector2(29, 61), 11, Color("96a3b6"))
	status_label = _label(root, "ROOM A1     •     FLOOR 01", Vector2(29, 109), 13, Color("dfbd78"))
	_label(root, "Drag below the room to move", Vector2(111, 623), 16, Color("d2d7df"))
	_label(root, "WASD / arrow keys on a computer", Vector2(126, 648), 12, Color("8594aa"))
	var reset := Button.new()
	reset.text = "Reset position"
	reset.position = Vector2(164, 737)
	reset.size = Vector2(152, 40)
	reset.pressed.connect(reset_player)
	root.add_child(reset)
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
	title.text = "Your first room"
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)
	var text := Label.new()
	text.text = "Explore with touch or keyboard.\nThis is where the dungeon begins.\nCombat and other rooms come next."
	text.add_theme_font_size_override("font_size", 14)
	box.add_child(text)
	var start := Button.new()
	start.text = "Enter the dungeon"
	start.custom_minimum_size.y = 48
	start.pressed.connect(start_game)
	box.add_child(start)
	root.add_child(start_panel)

func _label(parent: Node, text: String, pos: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func start_game() -> void:
	active = true
	start_panel.hide()

func reset_player() -> void:
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
		if event.pressed and pointer == -1 and _is_control_area(event.position):
			pointer = event.index
			stick_origin = event.position
			stick_position = event.position
		elif not event.pressed and event.index == pointer:
			_release_stick()
	elif event is InputEventScreenDrag and event.index == pointer:
		stick_position = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and pointer == -1 and _is_control_area(event.position):
			pointer_mouse = true
			stick_origin = event.position
			stick_position = event.position
		elif not event.pressed and pointer_mouse:
			_release_stick()
	elif event is InputEventMouseMotion and pointer_mouse:
		stick_position = event.position

func _is_control_area(pos: Vector2) -> bool:
	return pos.y >= 605 and pos.y < 727

func _physics_process(delta: float) -> void:
	clock += delta
	if active:
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
			var color := Color("202f43") if (x + y) % 2 == 0 else Color("233247")
			draw_rect(tile, color)
	draw_rect(Rect2(22, 174, 10, 434), Color("344157"))
	draw_rect(Rect2(448, 174, 10, 434), Color("344157"))
	draw_rect(Rect2(22, 596, 436, 12), Color("101a2a"))
	# Sealed decorative doorway: room transitions are not implemented yet.
	draw_rect(Rect2(210, 151, 60, 43), Color("0c1421"))
	draw_rect(Rect2(216, 157, 48, 37), Color("483d38"))
	for x in [218, 232, 246, 260]: draw_line(Vector2(x, 158), Vector2(x, 193), Color("8e7247"), 2)
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
	else:
		draw_arc(Vector2(240, 701), 19, 0, TAU, 32, Color("40556d"), 2)
		draw_circle(Vector2(240, 701), 5, Color("6b849b"))

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
