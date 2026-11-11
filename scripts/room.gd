extends Node2D
## First combat prototype: auto-fire while moving and persistent encounters.
signal transition_finished
const HubMenu = preload("res://scripts/hub_menu.gd")
const HubState = preload("res://scripts/hub.gd")
const Services = preload("res://scripts/services.gd")
const CombatState = preload("res://scripts/combat.gd")
const DungeonState = preload("res://scripts/dungeon.gd")
const SPEED := 185.0
const RADIUS := 12.0
const FLOOR := Rect2(32, 174, 416, 422)
const PILLARS: Array[Rect2] = [Rect2(108, 290, 38, 40), Rect2(334, 290, 38, 40), Rect2(108, 456, 38, 40), Rect2(334, 456, 38, 40)]
var dungeon = DungeonState.new()
var combat = CombatState.new(FLOOR, PILLARS)
var hub = HubState.new()
var services
var seed_override := -1
var run_time := 0.0
var in_hub := true
var interacting := false
var service_panel: Panel
var service_close_button: Button
var service_title: Label
var service_description: Label
var service_buttons: Array[Button] = []
var interact_button: Button
var hub_menu
var cheat_menu
var cheat_run_button: Button
var outcome_title: Label
var outcome_text: Label
var run_token := ""
var wheel_rotation := 0.0
var death_panel: PanelContainer
var level_panel: Panel
var level_title: Label
var card_buttons: Array[Button] = []
var notice_label: Label
var notice_time := 0.0
var seed_label: Label
var xp_label: Label
var build_label: Label
var health_label: Label
var encounter_label: Label
var focused := true
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
var start_panel: Control
var status_label: Label
var movement_blockers: Array[Control] = []
var font := ThemeDB.fallback_font

func _ready() -> void:
	_read_seed()
	_build_ui()
	_build_cheats(hub_menu.get_parent())
	services = Services.new(dungeon, combat, hub)
	_refresh_hub()
	_update_room_label()
	combat.enter(dungeon.rooms[dungeon.current], player)
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
	_label(root, "FIVE FLOORS   /   BALANCE PROTOTYPE", Vector2(29, 61), 11, Color("96a3b6"))
	health_label = _label(root, "HP  6 / 6", Vector2(29, 83), 15, Color("69d4b8"))
	encounter_label = _label(root, "", Vector2(245, 130), 11, Color("96a3b6"))
	xp_label = _label(root, "", Vector2(29, 103), 11, Color("96c9ff"))
	notice_label = _label(root, "", Vector2(29, 607), 10, Color("dfbd78"))
	seed_label = _label(root, "", Vector2(29, 724), 9, Color("96a3b6"))
	build_label = _label(root, "", Vector2(29, 703), 10, Color("96a3b6"))
	status_label = _label(root, "ROOM A1     •     FLOOR 01", Vector2(29, 120), 13, Color("dfbd78"))
	_label(root, "Touch and drag anywhere to move", Vector2(99, 623), 16, Color("d2d7df"))
	_label(root, "WASD / arrows • E to interact", Vector2(132, 648), 12, Color("8594aa"))
	interact_button = Button.new()
	interact_button.position = Vector2(100, 665)
	interact_button.size = Vector2(280, 36)
	interact_button.pressed.connect(_interact)
	root.add_child(interact_button)
	movement_blockers.append(interact_button)

	var reset := Button.new()
	reset.text = "Return to hub"
	reset.position = Vector2(164, 737)
	reset.size = Vector2(152, 40)
	reset.pressed.connect(_return_to_hub)
	root.add_child(reset)
	movement_blockers.append(reset)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("131e30")
	style.border_color = Color("a7864d")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 25
	style.content_margin_right = 25
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	hub_menu = HubMenu.new()
	start_panel = hub_menu
	root.add_child(hub_menu)
	hub_menu.setup(hub)
	hub_menu.tab_changed.connect(func(_index):
		if in_hub and interacting: _close_service()
	)
	hub_menu.dungeon_requested.connect(start_game)
	hub_menu.item_requested.connect(_inventory_item)
	hub_menu.perk_requested.connect(func():
		if in_hub:
			var result: String = hub.buy_perk()
			hub_menu.perk_message = "Received %s Lv.%d" % [hub.PERK_NAMES[result],hub.perks[result]] if not result.is_empty() else "No perk purchased."
		_refresh_hub()
	)
	hub_menu.synthesis_requested.connect(_synthesis_changed)
	hub_menu.cheat_requested.connect(func(): cheat_menu.open())
	death_panel = PanelContainer.new()
	death_panel.position = Vector2(54, 250)
	death_panel.size = Vector2(372, 240)
	death_panel.add_theme_stylebox_override("panel", style)
	var death_box := VBoxContainer.new()
	death_box.add_theme_constant_override("separation", 18)
	death_panel.add_child(death_box)
	var death_title := Label.new()
	outcome_title = death_title
	death_title.text = "Your run has ended"
	death_title.add_theme_font_size_override("font_size", 24)
	death_box.add_child(death_title)
	var death_text := Label.new()
	outcome_text = death_text
	death_text.text = "Try again. Keep moving to dodge.\nRun upgrades reset. Stored gear stays safe."
	death_text.add_theme_font_size_override("font_size", 14)
	death_box.add_child(death_text)
	var retry := Button.new()
	retry.text = "Return to hub"
	retry.custom_minimum_size.y = 48
	retry.pressed.connect(_return_to_hub)
	death_box.add_child(retry)
	root.add_child(death_panel)
	death_panel.hide()
	level_panel = Panel.new()
	level_panel.position = Vector2(40, 210)
	level_panel.size = Vector2(400, 370)
	level_panel.add_theme_stylebox_override("panel", style)
	level_title = _label(level_panel, "LEVEL UP", Vector2(24, 20), 25, Color("dfbd78"))
	_label(level_panel, "Choose one. Combat is paused.", Vector2(24, 58), 14, Color("d2d7df"))
	for index in range(3):
		var card := Button.new()
		card.position = Vector2(24, 100 + index * 78)
		card.size = Vector2(352, 64)
		card.add_theme_font_size_override("font_size", 15)
		card.pressed.connect(_choose_upgrade.bind(index))
		level_panel.add_child(card)
		card_buttons.append(card)
	_label(level_panel, "Choose one reward • lasts this run", Vector2(24, 342), 12, Color("96a3b6"))
	root.add_child(level_panel)
	level_panel.hide()
	service_panel = Panel.new()
	service_panel.position = Vector2(30, 190)
	service_panel.size = Vector2(420, 420)
	service_panel.add_theme_stylebox_override("panel", style)
	service_title = _label(service_panel, "", Vector2(20, 17), 22, Color("dfbd78"))
	service_description = _label(service_panel, "", Vector2(20, 51), 13, Color("d2d7df"))
	for index in range(6):
		var button := Button.new()
		button.add_theme_font_size_override("font_size", 13)
		service_panel.add_child(button)
		service_buttons.append(button)
	var close := Button.new()
	service_close_button = close
	close.text = "Back to room"
	close.position = Vector2(110, 367)
	close.size = Vector2(200, 36)
	close.pressed.connect(_close_service)
	service_panel.add_child(close)
	root.add_child(service_panel)
	service_panel.hide()
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

func _build_cheats(root_control: Control) -> void:
	var button := Button.new()
	cheat_run_button = button
	button.hide()
	button.text = "Cheats"
	button.position = Vector2(330,737)
	button.size = Vector2(120,40)
	root_control.add_child(button)
	movement_blockers.append(button)
	cheat_menu = preload("res://scripts/cheat_menu.gd").new()
	root_control.add_child(cheat_menu)
	cheat_menu.setup(self)
	button.pressed.connect(func(): cheat_menu.open())

func start_game() -> void:
	if in_hub: _new_run()
	in_hub = false
	active = true
	start_panel.hide()
	if combat.progression.pending > 0: _show_level_up("STARTING UPGRADE")

func restart_run() -> void:
	if transitioning: return
	_new_run()
	in_hub = false
	active = true
	start_panel.hide()
	if combat.progression.pending > 0: _show_level_up("STARTING UPGRADE")

func _new_run() -> void:
	run_time = 0.0
	dungeon = DungeonState.new(seed_override)
	combat = CombatState.new(FLOOR, PILLARS)
	combat.progression.rng.seed = dungeon.seed_value + 101
	run_token = "%s-%s" % [Time.get_unix_time_from_system(),Time.get_ticks_usec()]
	combat.progression.wallet = hub
	combat.progression.base_health = 6 + int(hub.perks["starting_hp"])
	combat.progression.dodge_chance = hub.perks["dodge"] * 0.01
	combat.progression.boss_damage_bonus = hub.perks["boss_damage"] * 0.02
	combat.progression.apply_loadout(hub.loadout_stats())
	combat.health = combat.progression.max_health()
	hub.record_floor(1)
	services = Services.new(dungeon, combat, hub)
	reset_player()
	_enter_current()
	death_panel.hide()
	level_panel.hide()
	service_panel.hide()
	interacting = false
	notice_time = 0
	notice_label.hide()
	_update_room_label()
	if hub.perks["starting_upgrade"] > 0: combat.progression.reward_choices(2,false)

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
		focused = false
		_release_stick()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focused = true

func _input(event: InputEvent) -> void:
	if cheat_menu != null and cheat_menu.visible: return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
		_interact()
	if not active or interacting or combat.progression.pending > 0:
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
	cheat_run_button.visible = not in_hub
	if cheat_menu != null and cheat_menu.visible: return
	clock += delta
	if active and not interacting and not transitioning and focused and combat.progression.pending == 0:
		run_time += delta
		var direction := Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): direction.x -= 1
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): direction.x += 1
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): direction.y -= 1
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): direction.y += 1
		if pointer != -1 or pointer_mouse:
			direction += (stick_position - stick_origin).limit_length(45.0) / 45.0
		if direction.length() > 0.08:
			move_player(direction.limit_length(1.0) * SPEED * combat.progression.movement_multiplier() * delta)
		if not transitioning:
			notice_time = maxf(0, notice_time - delta)
			notice_label.visible = notice_time > 0
			var before_kills: int = combat.kills
			combat.tick(delta, player)
			if combat.kills > before_kills: hub.record_progress("kills",combat.kills-before_kills)
			for drop in combat.collected_items:
				var uid: String = hub.find_equipment(drop["type"],drop["rarity"])
				_notice("Picked up " + hub.item_name(uid))
			combat.collected_items.clear()
			_claim_floor_reward()
			if combat.progression.pending > 0: _show_level_up()
			if combat.health <= 0:
				active = false
				_release_stick()
				outcome_title.text = "Your run has ended"
				outcome_text.text = "Floor %d • %d enemies defeated\nItems, coins, gems and typed keys are kept." % [dungeon.floor_number, combat.kills]
				death_panel.show()
	_update_combat_labels()
	_update_interact()
	queue_redraw()

func move_player(motion: Vector2) -> void:
	if transitioning or interacting or combat.progression.pending > 0: return
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
	if not active or interacting or combat.progression.pending > 0: return
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
	if transitioning or interacting or combat.progression.pending > 0 or not dungeon.contains(dungeon.current + direction): return
	transitioning = true
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.12)
	tween.tween_callback(func():
		dungeon.enter(dungeon.current + direction)
		if direction == Vector2i.RIGHT: player = Vector2(72, 385)
		elif direction == Vector2i.LEFT: player = Vector2(408, 385)
		elif direction == Vector2i.DOWN: player = Vector2(240, 214)
		else: player = Vector2(240, 556)
		_enter_current()
		_update_room_label()
	)
	tween.tween_property(fade, "color:a", 0.0, 0.12)
	tween.tween_callback(func():
		transitioning = false
		transition_finished.emit()
	)

func _update_room_label() -> void:
	status_label.text = "%s • %s • FLOOR %d/%d" % [dungeon.room_name(), dungeon.rooms[dungeon.current]["role"].to_upper(), dungeon.floor_number,DungeonState.MAX_FLOOR]

func _update_combat_labels() -> void:
	health_label.text = "HP  %d / %d" % [combat.health, combat.progression.max_health()]
	health_label.modulate = Color("ff8b83") if combat.hurt_time > 0.7 else Color.WHITE
	xp_label.text = "L%d XP %d/%d • %d C • %d F" % [combat.progression.level, combat.progression.xp, combat.progression.required_xp(), combat.progression.coins, combat.progression.flares]
	build_label.text = "DMG %d  •  RATE %.1f/s  •  SPEED +%d%%  •  PIERCE %d" % [combat.progression.damage(), 1.0 / combat.progression.fire_interval(), roundi((combat.progression.gear_movement + combat.progression.ranks["movement"] * 0.1) * 100), combat.progression.base_pierce + combat.progression.ranks["piercing"]]
	seed_label.text = "SEED %d • %s Lv.%d • %d:%02d ACTIVE" % [dungeon.seed_value, combat.progression.weapon.to_upper(), combat.progression.weapon_level,int(run_time)/60,int(run_time)%60]
	var alive: int = combat.alive_count()
	encounter_label.text = "%d ENEMIES  •  %d DEFEATED" % [alive, combat.kills] if alive > 0 else "ROOM SAFE  •  %d DEFEATED" % combat.kills
	var style: String = dungeon.rooms[dungeon.current].get("encounter","")
	if not style.is_empty(): encounter_label.text = "%s • %d LEFT" % [style.to_upper(),alive]
	if combat.progression.slow_time > 0: encounter_label.text += " • SLOW"

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
	draw_rect(Rect2(150, 88, 130, 8), Color("263348"))
	draw_rect(Rect2(150, 88, 130.0 * combat.health / combat.progression.max_health(), 8), Color("69d4b8"))
	draw_rect(Rect2(285, 108, 60, 5), Color("263348"))
	draw_rect(Rect2(285, 108, 60.0 * combat.progression.xp / combat.progression.required_xp(), 5), Color("96c9ff"))
	draw_string(font, Vector2(216, 401), dungeon.room_name(), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.8, 0.85, 0.9, 0.18))
	_draw_room_content()
	for x in [76, 404]:
		draw_circle(Vector2(x, 187), 26, Color(0.95, 0.55, 0.2, 0.045))
		draw_rect(Rect2(x - 3, 175, 6, 15), Color("78634d"))
		draw_circle(Vector2(x, 173), 5 + sin(clock * 7 + x) * 0.7, Color("f4bb63"))
	for drop in combat.item_drops:
		var pos: Vector2 = drop["pos"]
		draw_circle(pos,12,Color("aab1ba"))
		draw_string(font,pos+Vector2(-4,5),"I",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("172a32"))
	for pickup in combat.pickups:
		var pos: Vector2 = pickup["pos"]
		draw_circle(pos, 10, Color(0.4, 0.7, 1, 0.12))
		draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -7), pos + Vector2(5, 0), pos + Vector2(0, 7), pos + Vector2(-5, 0)]), Color("96c9ff"))
	var actors: Array = []
	for pillar in PILLARS: actors.append({"y": pillar.end.y, "pillar": pillar})
	actors.append({"y": player.y, "player": true})
	for enemy in combat.enemies:
		if enemy["hp"] > 0 and not enemy.get("dormant",false): actors.append({"y": enemy["pos"].y, "enemy": enemy})
	actors.sort_custom(func(a, b): return a["y"] < b["y"])
	for actor in actors:
		if actor.has("pillar"): _draw_pillar(actor["pillar"])
		elif actor.has("enemy"): _draw_enemy(actor["enemy"])
		elif combat.hurt_time <= 0 or int(clock * 14) % 2 == 0: _draw_player()
	for hazard in combat.hazards:
		var color := Color(1,0.3,0.2,0.65) if hazard["warning"]>0 else Color(1,0.65,0.2,0.85)
		draw_circle(hazard["pos"],hazard["radius"],Color(color,0.15))
		draw_arc(hazard["pos"],hazard["radius"],0,TAU,32,color,3)
	for enemy in combat.enemies:
		if enemy["hp"]>0 and enemy.get("dormant",false) and dungeon.rooms[dungeon.current].get("wave_timer",-1.0)>0:
			draw_arc(enemy["pos"],22,0,TAU,24,Color("e8b965"),3)
			draw_string(font,enemy["pos"]+Vector2(-6,5),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("e8b965"))
		if enemy["hp"] > 0 and not enemy.get("dormant",false) and enemy.get("telegraph", 0.0) > 0:
			var origin: Vector2 = enemy["pos"]
			draw_line(origin,origin+enemy["aim"]*(150 if enemy.get("action","")=="charge" else 270),Color(1,0.6,0.2,0.7) if enemy.get("action","")=="charge" else Color(1,0.3,0.3,0.45),7 if enemy.get("action","")=="charge" else 3)
	for bullet in combat.hostile_bullets:
		draw_circle(bullet["pos"] + Vector2(0, -16), 6, Color("ff786f"))
	for bullet in combat.bullets:
		var tip: Vector2 = bullet["pos"] + Vector2(0,-16)
		var direction: Vector2 = bullet["velocity"].normalized()
		var kind: String = bullet.get("kind",combat.progression.weapon)
		var radius: float = bullet.get("radius",4.0)
		if kind == "chakram":
			draw_arc(tip,9,clock*12,clock*12+5.4,18,Color("8ce7c3"),3)
		elif kind == "rolling_meteor":
			draw_circle(tip,radius,Color("bd6c42")); draw_arc(tip,radius,clock*5,clock*5+3,16,Color("ffd48a"),3)
		elif kind == "wand":
			draw_line(tip-direction*34,tip,Color("6b94e9"),7)
			draw_line(tip-direction*34,tip,Color("d1e9ff"),3)
		else:
			var color := Color("ff956b") if bullet.get("explosive",false) else Color("f6c96c")
			var length := radius*3
			draw_line(tip-direction*length,tip,color,maxf(2,radius*0.5))
			draw_line(tip-direction*radius+direction.orthogonal()*radius*0.6,tip,color,2)
			draw_line(tip-direction*radius-direction.orthogonal()*radius*0.6,tip,color,2)
	_draw_weapon_effects()
	for impact in combat.impacts:
		draw_arc(impact["pos"] + Vector2(0, -16), (0.22 - impact["life"]) * 85 + 3, 0, TAU, 12, Color(1, 0.8, 0.4, impact["life"] / 0.22), 2)
	if pointer != -1 or pointer_mouse:
		draw_circle(stick_origin, 48, Color(0.5, 0.75, 0.85, 0.12))
		draw_arc(stick_origin, 48, 0, TAU, 48, Color("7193a6"), 2)
		draw_circle(stick_origin + (stick_position - stick_origin).limit_length(45), 20, Color("48b9a8"))

func _draw_weapon_effects() -> void:
	for meteor in combat.arsenal.meteors:
		var pos: Vector2 = meteor["pos"]
		var radius: float = meteor["radius"]
		draw_arc(pos,radius,0,TAU,28,Color(1,0.5,0.25,0.65),2)
		var falling: Vector2 = pos+Vector2(0,-16-meteor["delay"]*240)
		draw_line(falling+Vector2(-12,-24),falling,Color("f3a250"),7)
		draw_circle(falling,radius*0.55,Color("c07647"))
	for effect in combat.arsenal.effects:
		var kind: String = effect["kind"]
		var pos: Vector2 = effect["pos"]+Vector2(0,-16)
		var fade: float = effect["life"]/effect["duration"]
		if kind == "laser":
			draw_line(pos,effect["end"]+Vector2(0,-16),Color(0.4,0.7,1,fade*0.7),7)
			draw_line(pos,effect["end"]+Vector2(0,-16),Color(0.8,0.95,1,fade),2)
		elif kind == "explosion":
			draw_circle(pos,effect["radius"]*(1-fade*0.3),Color(1,0.45,0.15,fade*0.3))
			draw_arc(pos,effect["radius"]*(1-fade*0.3),0,TAU,32,Color(1,0.8,0.3,fade),3)
		else:
			var angle: float = effect["direction"].angle()
			var spread: float = effect["angle"]
			if kind == "wave":
				for wave in range(3): draw_arc(pos,effect["radius"]*(1-fade*0.65)-wave*10,angle-spread,angle+spread,24,Color(0.8,0.65,0.35,fade),3)
			else:
				draw_arc(pos,effect["radius"],angle-spread,angle+spread,24,Color(0.75,0.9,1,fade),5)
				var sweep: float = lerpf(-spread,spread,1-fade) * (-1 if effect["reverse"] else 1)
				draw_line(pos,pos+Vector2.from_angle(angle+sweep)*effect["radius"],Color(0.9,0.96,1,fade),4)
	if combat.arsenal.charge > 0:
		draw_arc(player+Vector2(0,-18),24,-PI/2,-PI/2+TAU*combat.arsenal.charge/3,32,Color("f6d58a"),4)

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
			if dungeon.rooms[cell]["role"] == "bonus": color = Color("5d588e")
			if dungeon.rooms[cell]["role"] == "loot": color = Color("8d7544")
			if dungeon.rooms[cell]["role"] == "trap": color = Color("8c4c55")
			if dungeon.rooms[cell]["role"] == "boss": color = Color("da5757")
			if dungeon.rooms[cell]["role"] == "start": color = Color("527b80")
			if cell == dungeon.current: color = Color("dfbd78")
			var tile := Rect2(359 + x * 16, 24 + y * 16, 12, 12)
			draw_rect(tile, color)
			var role: String = dungeon.rooms[cell]["role"]
			var symbol: String = {"combat": "C", "loot": "L", "trap": "!", "boss": "B", "start": "S", "empty": "."}.get(role, "?")
			if role == "bonus": symbol = dungeon.rooms[cell]["service"].left(1).to_upper()
			draw_string(font, tile.position + Vector2(2, 10), symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("101a29") if cell == dungeon.current else Color("e0d8c8"))
			if dungeon.rooms[cell]["visits"] > 0: draw_rect(tile, Color("69d4b8"), false, 1)

func _draw_enemy(enemy: Dictionary) -> void:
	var pos: Vector2 = enemy["pos"]
	_draw_shadow(pos + Vector2(0, 3), Vector2(16, 7), Color(0, 0, 0, 0.35))
	var base := Color("c85e72")
	if enemy.get("kind", "") == "shooter": base = Color("be8be8")
	if enemy.get("kind", "") == "brute": base = Color("db9a52")
	if enemy.get("kind", "") == "boss": base = Color("e25151")
	if enemy.get("kind", "") == "miniboss": base = Color("e3a63e")
	if enemy.get("phase","")=="recover": base = base.darkened(0.4)
	if enemy.get("frost_time", 0.0) > 0: base = Color("79bfe8")
	if enemy.get("burn_time", 0.0) > 0: draw_arc(pos + Vector2(0, -13), 18, 0, TAU, 16, Color("f5a255"), 2)
	var color := Color("ffecce") if enemy["flash"] > 0 else base
	draw_circle(pos + Vector2(0, -13), 23 if enemy.get("kind", "") == "boss" else (20 if enemy.get("kind","")=="miniboss" else 15), color)
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-12, -20), pos + Vector2(-12, -33), pos + Vector2(-3, -25)]), color)
	draw_colored_polygon(PackedVector2Array([pos + Vector2(12, -20), pos + Vector2(12, -33), pos + Vector2(3, -25)]), color)
	if enemy.get("kind","") in ["boss","miniboss"] and dungeon.floor_number>=3 and enemy["hp"]<enemy["max_hp"]*0.5:
		draw_arc(pos+Vector2(0,-13),27,clock*3,clock*3+5.5,24,Color("ffb24c"),3)
	for x in [-5, 5]: draw_circle(pos + Vector2(x, -16), 2.5, Color("ffeaa4"))
	draw_rect(Rect2(pos + Vector2(-17, -43), Vector2(34, 4)), Color("111a29"))
	draw_rect(Rect2(pos + Vector2(-17, -43), Vector2(34.0 * enemy["hp"] / enemy.get("max_hp", 3), 4)), Color("ed8392"))

func _show_level_up(title: String = "") -> void:
	_release_stick()
	level_title.text = "LEVEL %d — CHOOSE A REWARD" % combat.progression.level if title.is_empty() else title
	level_title.add_theme_font_size_override("font_size", 19)
	for index in range(3):
		card_buttons[index].visible = index < combat.progression.offers.size()
		if index >= combat.progression.offers.size(): continue
		var id: String = combat.progression.offers[index]
		if id == "coins":
			card_buttons[index].text = "+%d coins\nSave currency instead of an upgrade" % combat.progression.coin_reward()
		else:
			var info: Array = combat.progression.upgrade_info(id)
			card_buttons[index].text = "%s\n%s" % [info[0], info[1]]
	level_panel.show()

func _choose_upgrade(index: int) -> void:
	if not level_panel.visible or not combat.apply_choice(index): return
	_release_stick()
	if combat.progression.pending > 0: _show_level_up()
	else:
		level_panel.hide()
		combat.grace_time = maxf(combat.grace_time, 0.5)
	_update_combat_labels()

func _read_seed() -> void:
	if OS.has_feature("web"):
		var value = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('seed')")
		if value != null and str(value).is_valid_int(): seed_override = int(value)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed=") and arg.trim_prefix("--seed=").is_valid_int(): seed_override = int(arg.trim_prefix("--seed="))

func _refresh_hub() -> void:
	hub_menu.hub = hub
	hub_menu.refresh()

func _return_to_hub() -> void:
	if transitioning or wheel_spinning: return
	active = false
	interacting = false
	in_hub = true
	notice_time = 0
	notice_label.hide()
	_release_stick()
	level_panel.hide()
	death_panel.hide()
	service_panel.hide()
	_refresh_hub()
	hub_menu.select_tab(2)
	start_panel.show()

func _enter_current() -> void:
	combat.enter(dungeon.rooms[dungeon.current], player)
	services.enter()

func _update_interact() -> void:
	interact_button.visible = active and not transitioning and not interacting and combat.progression.pending == 0
	var state: Dictionary = dungeon.rooms[dungeon.current]
	interact_button.disabled = combat.alive_count() > 0
	match state["role"]:
		"boss": interact_button.text = "Finish expedition" if dungeon.floor_number == DungeonState.MAX_FLOOR else "Descend to floor %d" % (dungeon.floor_number + 1)
		"loot":
			interact_button.text = "Chest opened" if state["used"] else "Open loot chest"
			interact_button.disabled = interact_button.disabled or state["used"]
		"bonus":
			interact_button.text = "Visit travelling shop" if state.get("summoned_shop", false) else "Use %s" % state["service"].capitalize()
			interact_button.disabled = state["used"] and state["service"] != "shop" and not state.get("summoned_shop", false)
		_: interact_button.visible = false

func _interact() -> void:
	if not active or transitioning or interacting or combat.progression.pending > 0 or combat.alive_count() > 0: return
	var state: Dictionary = dungeon.rooms[dungeon.current]
	match state["role"]:
		"boss": _advance_floor()
		"loot":
			if services.loot():
				_notice(state["reward"])
				if combat.progression.pending > 0: _show_level_up("LOOT — CHOOSE A REWARD")
				else: _menu("Loot secured", "+%d coins • %d flares\n%s" % [15 + dungeon.floor_number * 5,20 if dungeon.floor_number%5==0 else 10,state["reward"]], [])
		"bonus":
			if state.get("summoned_shop", false): _open_shop()
			elif state["service"] == "shop": _open_shop()
			elif state["service"] == "healer":
				if not services.heal() and not state["used"]:
					_menu("Healer", "You have full health. Return when wounded.\nThe healing service has not been spent.", [])
			elif state["service"] == "upgrade":
				if services.free_upgrade(): _show_level_up("FREE UPGRADE")
			elif state["service"] == "trader": _begin_trade()
			elif state["service"] == "wheel": _spin_wheel()
	_update_combat_labels()
	_update_interact()

func _advance_floor() -> void:
	var state: Dictionary = dungeon.rooms[dungeon.current]
	if state["role"] != "boss" or combat.alive_count() > 0 or not state["boss_paid"]: return
	_claim_floor_reward()
	if dungeon.advance():
		hub.record_floor(dungeon.floor_number)
		player = Vector2(240, 530)
		_release_stick()
		_enter_current()
		_update_room_label()
		transitioning = true
		fade.color.a = 1
		var tween := create_tween()
		tween.tween_property(fade, "color:a", 0.0, 0.35)
		tween.tween_callback(func():
			transitioning = false
			transition_finished.emit()
		)
	else:
		active = false
		_release_stick()
		outcome_title.text = "Five floors conquered!"
		outcome_title.add_theme_font_size_override("font_size", 21)
		outcome_text.text = "Level %d • %d enemies defeated\n%d coins • %d flares remaining\nReturn to the hub. Floor 6 is disabled." % [combat.progression.level, combat.kills, combat.progression.coins, combat.progression.flares]
		death_panel.show()

func _menu(title: String, description: String, options: Array, columns: int = 1) -> void:
	interacting = true
	_release_stick()
	service_close_button.text = ("Back to inventory" if hub_menu.selected == 1 else "Back to shop") if in_hub else "Back to room"
	service_panel.position.x = (get_viewport_rect().size.x - service_panel.size.x) / 2 if in_hub else 30
	service_title.text = title
	service_description.text = description
	for index in range(service_buttons.size()):
		var button := service_buttons[index]
		for connection in button.pressed.get_connections(): button.pressed.disconnect(connection["callable"])
		button.visible = index < options.size()
		if not button.visible: continue
		button.text = options[index]["text"]
		button.disabled = options[index].get("disabled", false)
		if columns == 2:
			button.position = Vector2(20 + (index % 2) * 195, 112 + int(index / 2) * 76)
			button.size = Vector2(185, 65)
		else:
			button.position = Vector2(20, 104 + index * 42)
			button.size = Vector2(380, 38)
		button.pressed.connect(options[index]["action"])
	service_panel.show()

func _close_service() -> void:
	service_panel.hide()
	interacting = false
	_release_stick()
	combat.grace_time = maxf(combat.grace_time, 0.5)

func _open_shop(message: String = "") -> void:
	var stock: Dictionary = services.state()["stock"]
	var options: Array = []
	# Alternating indices form permanent-left / run-right columns.
	for item in [["weapon_item", "Common bow • 150 coins"], ["upgrade", "Upgrade choice • 20 F"], ["armor_item", "Common armor • 150 coins"], ["heal", "Heal 3 HP • 10 F"], ["", "Items stored in Inventory"], ["coins", "20 coins • 10 F"]]:
		var id: String = item[0]
		options.append({"text": item[1] + ("\nSOLD" if stock.get(id, false) else ""), "disabled": id.is_empty() or stock.get(id, false), "action": _shop_buy.bind(id)})
	_menu("Shop • permanent / this run", "Left: hub items (coins). Right: run help (flares).\n%d coins • %d flares\n%s" % [combat.progression.coins, combat.progression.flares, message], options, 2)

func _shop_buy(id: String) -> void:
	var message: String = services.buy(id)
	if combat.progression.pending > 0:
		_close_service()
		_show_level_up("SHOP — CHOOSE A REWARD")
	else: _open_shop(message)
	_update_combat_labels()

func _begin_trade() -> void:
	if services.state().get("trade_used", false): return
	var options: Array = []
	for id in services.tradable_owned():
		options.append({"text": "Exchange one %s" % combat.progression.upgrade_info(id)[0], "action": _trade_select_old.bind(id)})
	_menu("Upgrade trader", "Choose the upgrade rank to surrender.\nNo upgrade is removed until you confirm." if not options.is_empty() else "You need an owned upgrade and three eligible replacements.", options)

func _trade_select_old(old: String) -> void:
	var state: Dictionary = services.state()
	if not state.has("trade_offers"): state["trade_offers"] = {}
	if not state["trade_offers"].has(old): state["trade_offers"][old] = services.trade_options(old)
	var offered: Array[String] = state["trade_offers"][old]
	var options: Array = []
	if offered.size() == 3:
		for replacement in offered:
			options.append({"text": combat.progression.upgrade_info(replacement)[0], "action": _trade_finish.bind(old, replacement, offered)})
	_menu("Choose a replacement", "Surrender one %s for one of these three." % combat.progression.upgrade_info(old)[0] if offered.size() == 3 else "Not enough eligible replacements. Nothing spent.", options)

func _trade_finish(old: String, replacement: String, offered: Array[String]) -> void:
	if services.trade(old, replacement, offered): _close_service()

var wheel_spinning := false

func _spin_wheel() -> void:
	var state: Dictionary = services.state()
	if state["used"]: return
	state["used"] = true
	wheel_spinning = true
	interacting = true
	_release_stick()
	var result: int = dungeon.rng.randi_range(0, 4)
	var target_angle := -PI / 2 - (result + 0.5) * TAU / 5
	var remaining := fposmod(target_angle - wheel_rotation, TAU)
	var tween := create_tween()
	tween.tween_property(self, "wheel_rotation", wheel_rotation + TAU * 3 + remaining, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		wheel_spinning = false
		interacting = false
		match result:
			0:
				combat.health = mini(combat.progression.max_health(), combat.health + 3)
				_menu("Wheel: healing", "Recovered up to 3 HP.", [])
			1:
				combat.progression.coins += 20
				_menu("Wheel: coins", "You gained 20 coins.", [])
			2:
				combat.progression.reward_choices(2, false)
				_show_level_up("WHEEL — CHOOSE AN UPGRADE")
			3:
				if services.tradable_owned().is_empty():
					combat.progression.coins += 20
					_menu("Wheel: trade", "No eligible trade; received 20 coins instead.", [])
				else:
					state["wheel_trade"] = true
					_begin_trade()
			4:
				state["summoned_shop"] = true
				_open_shop("A shopkeeper answered the wheel.")
	)

func _draw_room_content() -> void:
	var state: Dictionary = dungeon.rooms[dungeon.current]
	var role: String = state["role"]
	var center := Vector2(240, 385)
	if role == "loot":
		draw_rect(Rect2(center - Vector2(24, 17), Vector2(48, 32)), Color("806445") if state["used"] else Color("c99a4b"))
		draw_line(center + Vector2(0, -17), center + Vector2(0, 15), Color("f6d080"), 5)
	elif role == "bonus":
		var label: String = state["service"].to_upper()
		if state["service"] == "wheel":
			var colors := [Color("69d4b8"), Color("dfbd78"), Color("96c9ff"), Color("be8be8"), Color("e88a81")]
			for i in range(5):
				var points := PackedVector2Array([center])
				for part in range(9):
					var angle := wheel_rotation + (i + part / 8.0) * TAU / 5
					points.append(center + Vector2.from_angle(angle) * 43)
				draw_colored_polygon(points, colors[i])
			draw_colored_polygon(PackedVector2Array([center + Vector2(-7, -51), center + Vector2(7, -51), center + Vector2(0, -39)]), Color.WHITE)
		else:
			draw_circle(center, 32, Color("5d588e"))
			draw_string(font, center + Vector2(-8, 7), label.left(1), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("eee5cc"))
		draw_string(font, center + Vector2(-45, 65), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("dfbd78"))
	elif role == "trap":
		var trap: int = state["trap"]
		var color := Color("be8be8") if trap == 0 else Color("ff786f")
		draw_arc(center, 100 if trap == 0 else 80, 0, TAU, 48, color, 2)
		if state["trap_time"] < 0.7:
			draw_circle(center, 80, Color(1, 0.3, 0.3, 0.12))
			if trap == 2:
				for x in [180, 240, 300]: draw_line(Vector2(x, 195), Vector2(x, 580), Color(1, 0.3, 0.3, 0.3), 3)
		draw_string(font, center + Vector2(-44, 5), ["SLOW FIELD", "SPIKES", "VOLLEY"][trap], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
	elif role == "boss" and combat.alive_count() == 0:
		draw_circle(center, 30, Color("69d4b8"))
		draw_string(font, center + Vector2(-23, 5), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("132030"))
	elif role == "empty":
		draw_string(font, center + Vector2(-34, 40), "QUIET" if dungeon.floor_number < 3 else "AWAKENED", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("96a3b6"))

func _open_inventory(_message: String = "") -> void:
	if not in_hub: return
	_close_service()
	hub_menu.select_tab(1)
	_refresh_hub()

func _inventory_item(uid: String, message: String = "") -> void:
	if not in_hub or not hub.inventory.has(uid): return
	var item: Dictionary = hub.inventory[uid]
	var slot: String = hub.Equipment.ITEMS[item["type"]]["slot"]
	var category: String = hub.Economy.part_for(slot)
	var owned_equipped: bool = hub.equipped[slot] == uid
	var options: Array = [
		{"text":"Equipped" if owned_equipped else "Equip for next run","disabled":owned_equipped,"action":_inventory_equip.bind(uid)},
		{"text":"Maximum item level" if item["level"] >= hub.Equipment.MAX_LEVEL else "Level up • %d %s parts" % [hub.upgrade_cost(uid),category],"disabled":item["level"] >= hub.Equipment.MAX_LEVEL or hub.parts[category] < hub.upgrade_cost(uid),"action":_inventory_upgrade.bind(uid)}
	]
	if slot != "weapon" and owned_equipped: options.append({"text":"Unequip","action":_inventory_unequip.bind(uid)})
	_menu("%s Lv.%d" % [hub.item_name(uid),item["level"]],"%s\n%d %s parts available.\n%s" % [hub.Equipment.instance_summary(item),hub.parts[category],category,message],options)
	service_title.add_theme_font_size_override("font_size",17)

func _inventory_equip(uid: String) -> void:
	if in_hub and hub.equip_item(uid):
		_refresh_hub()
		_inventory_item(uid,"Equipped.")

func _inventory_upgrade(uid: String) -> void:
	if in_hub and hub.upgrade(uid):
		_refresh_hub()
		_inventory_item(uid,"Item level increased.")

func _inventory_unequip(uid: String) -> void:
	if in_hub and hub.unequip(hub.Equipment.ITEMS[hub.item_type(uid)]["slot"]):
		_refresh_hub()
		_inventory_item(uid,"Unequipped.")

func _synthesis_changed() -> void:
	_refresh_hub()

func _notice(text: String) -> void:
	notice_label.text = text.replace("\n", " • ")
	notice_time = 5.0
	notice_label.show()

func _claim_floor_reward() -> void:
	var state: Dictionary = dungeon.rooms[dungeon.current]
	if state["role"] == "boss" and state["boss_paid"] and not state.get("floor_reward_claimed", false):
		state["floor_reward_claimed"] = true
		var reward: Dictionary = hub.claim_floor(dungeon.floor_number,run_token+"-"+str(dungeon.floor_number))
		_notice("Floor cleared • +%d %s key(s)" % [reward["amount"],reward["kind"]] if not reward.is_empty() else "Floor cleared • daily key limit reached for this floor")
