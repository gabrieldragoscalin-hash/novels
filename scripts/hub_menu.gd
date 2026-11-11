extends Control
## Full-screen hub shell. Future side features are deliberately unpopulated.
signal tab_changed(index: int)
signal dungeon_requested
signal item_requested(id: String)
signal training_requested
const Icons = preload("res://scripts/ui_icons.gd")
const Gear = preload("res://scripts/equipment.gd")
const TABS := ["Shop", "Inventory", "Play", "Perks", "Miscellaneous"]
const LEFT_SLOTS := ["weapon", "armor", "headgear", "pants"]
const RIGHT_SLOTS := ["boots", "necklace", "ring", "bracelet"]
var hub
var selected := 2
var content: Control
var pages: Array[Control] = []
var nav: Array[Button] = []
var slot_buttons: Dictionary = {}
var slot_icons: Dictionary = {}
var future_buttons: Dictionary = {}
var resource_label: Label
var best_label: Label
var inventory_grid: GridContainer
var shop_grid: GridContainer
var inventory_scroll: ScrollContainer
var shop_scroll: ScrollContainer
var inventory_heading: Label
var inventory_show_all: Button
var inventory_scale := 1.0
var inventory_note: Label
var perk_label: Label
var train_button: Button
var misc_label: Label
var dungeon_button: Button
var play_title: Label
var play_hint: Label
var play_badge: Label
var nav_top := 706.0
var filter_slot := ""

func setup(model) -> void:
	hub = model
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	resized.connect(_layout)
	_layout()
	refresh()

func _style(color: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(10)
	return s

func _label(parent: Node, text: String, pos: Vector2, font_size: int, color: Color = Color("eee5cc")) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, pos: Vector2, dimensions: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = dimensions
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_stylebox_override("normal", _style(Color("172c38"), Color("415b64")))
	button.add_theme_stylebox_override("disabled", _style(Color("11232e"), Color("3b4b57")))
	button.add_theme_stylebox_override("hover", _style(Color("254654"), Color("e6c57d")))
	button.add_theme_stylebox_override("pressed", _style(Color("294b53"), Color("e6c57d"), 2))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _icon(parent: Node, kind: String, pos: Vector2, dimensions: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = Icons.texture(kind)
	icon.position = pos
	icon.size = dimensions
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	return icon

func _build() -> void:
	content = Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	_label(content, "THE DUNGEON", Vector2(24, 22), 25)
	resource_label = _label(content, "", Vector2(24, 65), 12, Color("dfbd78"))
	best_label = _label(content, "", Vector2(330, 30), 11, Color("8cb6ba"))
	for i in range(5):
		var page := Control.new()
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(page)
		pages.append(page)
		var button := _button(content, "", Vector2.ZERO, Vector2(92, 76), select_tab.bind(i))
		button.name = TABS[i]
		_icon(button, TABS[i].to_lower(), Vector2(28, 7), Vector2(36, 36))
		var caption := _label(button, TABS[i], Vector2(0, 49), 10 if i == 4 else 12)
		caption.size = Vector2(92, 18)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nav.append(button)
	_build_play()
	_build_inventory()
	_build_shop()
	_build_perks()
	_build_misc()
	select_tab(2)

func _build_play() -> void:
	var page := pages[2]
	play_title = _label(page, "The Shifting Dungeon", Vector2.ZERO, 24)
	play_title.size.x = 480
	play_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_badge = _label(page, "EXPEDITION • FLOORS 1–3", Vector2.ZERO, 12, Color("dfbd78"))
	play_badge.size.x = 480
	play_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dungeon_button = _button(page, "", Vector2.ZERO, Vector2(250, 270), func(): dungeon_requested.emit())
	dungeon_button.name = "DungeonEntrance"
	dungeon_button.add_theme_stylebox_override("normal", _style(Color(0,0,0,0), Color(0,0,0,0), 0))
	_icon(dungeon_button, "dungeon", Vector2(0, 0), Vector2(250, 250))
	play_hint = _label(page, "Tap the dungeon to begin", Vector2.ZERO, 15, Color("bad2d0"))
	play_hint.size.x = 480
	play_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_inventory() -> void:
	var page := pages[1]
	_label(page, "INVENTORY", Vector2(24, 108), 22)
	_label(page, "Equipment applies when you enter the dungeon", Vector2(24, 139), 11, Color("8cb6ba"))
	for side in range(2):
		var slots: Array = LEFT_SLOTS if side == 0 else RIGHT_SLOTS
		for row in range(4):
			var slot: String = slots[row]
			var button := _button(page, "", Vector2(42 if side == 0 else 360, 170 + row * 74), Vector2(78, 66), _slot_selected.bind(slot))
			button.name = slot.capitalize()
			slot_icons[slot] = _icon(button, slot, Vector2(19, 3), Vector2(40, 40))
			var caption := _label(button, slot.capitalize(), Vector2(0, 47), 10)
			caption.size.x = 78
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			slot_buttons[slot] = button
	for index in range(2):
		var kind := "pet" if index == 0 else "spirit"
		var button := _button(page, "", Vector2(165 + index * 86, 476), Vector2(64, 64), func(): pass)
		button.disabled = true
		_icon(button, "lock", Vector2(18, 3), Vector2(28, 28))
		var caption := _label(button, "Pet\nFloor 10" if index == 0 else "Spirit\nLater", Vector2(0, 32), 10, Color("8c9ba8"))
		caption.size.x = 64
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		future_buttons[kind] = button
	inventory_heading = _label(page, "STORED ITEMS", Vector2(24, 563), 15)
	inventory_show_all = _button(page, "Show all", Vector2(350, 555), Vector2(106, 31), func():
		filter_slot = ""
		refresh()
	)
	inventory_note = _label(page, "", Vector2(24, 587), 11, Color("8cb6ba"))
	inventory_scroll = ScrollContainer.new()
	inventory_scroll.position = Vector2(24, 608)
	inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(inventory_scroll)
	inventory_grid = GridContainer.new()
	inventory_grid.columns = 4
	inventory_grid.add_theme_constant_override("h_separation", 8)
	inventory_grid.add_theme_constant_override("v_separation", 8)
	inventory_scroll.add_child(inventory_grid)

func _build_shop() -> void:
	var page := pages[0]
	_label(page, "SHOP", Vector2(24, 108), 22)
	_label(page, "Craft equipment with scrap from your expeditions.", Vector2(24, 143), 12, Color("8cb6ba"))
	shop_scroll = ScrollContainer.new()
	shop_scroll.position = Vector2(24, 183)
	shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(shop_scroll)
	shop_grid = GridContainer.new()
	shop_grid.columns = 2
	shop_grid.add_theme_constant_override("h_separation", 10)
	shop_grid.add_theme_constant_override("v_separation", 10)
	shop_scroll.add_child(shop_grid)

func _build_perks() -> void:
	var page := pages[3]
	_label(page, "PERKS", Vector2(24, 108), 22)
	_label(page, "Lasting preparation for your next expedition", Vector2(24, 143), 12, Color("8cb6ba"))
	_icon(page, "perks", Vector2(192, 226), Vector2(96, 96))
	perk_label = _label(page, "", Vector2(36, 350), 16)
	train_button = _button(page, "Train +1 starting HP • 1 key", Vector2(58, 444), Vector2(364, 52), func(): training_requested.emit())

func _build_misc() -> void:
	var page := pages[4]
	_label(page, "MISCELLANEOUS", Vector2(24, 108), 22)
	misc_label = _label(page, "", Vector2(30, 180), 15, Color("bad2d0"))

func select_tab(index: int) -> void:
	if index < 0 or index >= TABS.size(): return
	selected = index
	tab_changed.emit(index)
	for i in range(pages.size()):
		pages[i].visible = i == index
		nav[i].add_theme_stylebox_override("normal", _style(Color("294650") if i == index else Color("12232e"), Color("d4b974") if i == index else Color("344956"), 2 if i == index else 1))
	queue_redraw()

func _slot_selected(slot: String) -> void:
	var id: String = hub.equipped[slot]
	if not id.is_empty(): item_requested.emit(id)
	else:
		filter_slot = slot
		refresh()

func _clear_grid(grid: GridContainer) -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

func refresh() -> void:
	if hub == null or content == null: return
	resource_label.text = "%d SCRAP    %d KEYS    %d SEALS" % [hub.materials, hub.keys, hub.seals]
	best_label.text = "BEST FLOOR %d" % hub.highest_floor
	for slot in slot_buttons:
		var id: String = hub.equipped[slot]
		var button: Button = slot_buttons[slot]
		slot_icons[slot].texture = Icons.texture(id if not id.is_empty() else slot)
		slot_icons[slot].modulate.a = 1.0 if not id.is_empty() else 0.35
		button.add_theme_stylebox_override("normal", _style(Color("29444b") if not id.is_empty() else Color("152734"), Color("c6ad70") if not id.is_empty() else Color("3b5360")))
		button.tooltip_text = slot.capitalize() + ": " + (Gear.ITEMS[id]["name"] + " Lv.%d" % hub.inventory[id] if not id.is_empty() else "Empty")
	future_buttons["pet"].tooltip_text = "Unlocks after first reaching floor 10. Pet content comes later." if not hub.pet_slot_unlocked() else "Floor 10 reached. Pet content comes later."
	future_buttons["spirit"].tooltip_text = "Locked. Unlock requirement will be set later."
	_clear_grid(inventory_grid)
	var count := 0
	for id in Gear.ITEMS:
		if not hub.inventory.has(id): continue
		if not filter_slot.is_empty() and Gear.ITEMS[id]["slot"] != filter_slot: continue
		_add_item(inventory_grid, id, false)
		count += 1
	inventory_note.text = "Tap an item to equip or upgrade it" if count > 0 else "Nothing stored in this slot yet. Craft equipment in Shop."
	_clear_grid(shop_grid)
	for id in Gear.ITEMS: _add_item(shop_grid, id, true)
	perk_label.text = "Starting health training: %d / 3\nBonus: +%d maximum HP\nKeys available: %d" % [hub.training, hub.training, hub.keys]
	train_button.disabled = hub.keys <= 0 or hub.training >= 3
	misc_label.text = "BEST FLOOR: %d\n\nProgress saves on this device/browser.\nEquipment survives your expeditions.\nSupply seals give 20 coins on departure.\n\nCurrent expedition limit: floor 3.\nPets unlock after first reaching floor 10.\nSpirit unlocks later.\n\nSwipe item lists to browse your equipment." % hub.highest_floor
	if not hub.persistence_ok: misc_label.text += "\n\nStorage unavailable: progress is session-only."
	queue_redraw()

func _add_item(grid: GridContainer, id: String, shop: bool) -> void:
	var owned: bool = hub.inventory.has(id)
	var button := _button(grid, "", Vector2.ZERO, Vector2.ZERO, func(): item_requested.emit(id))
	button.custom_minimum_size = Vector2(204 if shop else 98, 116 if shop else 100)
	var width := 204.0 if shop else 98.0
	_icon(button, id, Vector2((width - 40) / 2, 6), Vector2(40, 40))
	var name_label := _label(button, Gear.ITEMS[id]["name"] if shop else Gear.ITEMS[id]["name"].replace(" ", "\n"), Vector2(3, 49), 12 if shop else 10)
	name_label.size.x = width - 6
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var caption := "Lv.%d" % hub.inventory[id] if owned else "%d scrap" % Gear.ITEMS[id]["cost"]
	if owned and hub.equipped[Gear.ITEMS[id]["slot"]] == id: caption += " • equipped"
	var status := _label(button, caption, Vector2(3, 91 if shop else 82), 11 if shop else 9, Color("dfbd78"))
	status.size.x = width - 6
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _layout() -> void:
	if content == null: return
	var view := get_viewport_rect().size
	content.position = Vector2((view.x - 480) / 2, 0)
	content.size = Vector2(480, view.y)
	nav_top = view.y - 94
	for i in range(nav.size()): nav[i].position = Vector2(4 + i * 96, nav_top)
	for page in pages: page.size = content.size
	inventory_scale = clampf(0.9 + (view.y - 800) * 0.001, 0.9, 1.0)
	for side in range(2):
		var slots: Array = LEFT_SLOTS if side == 0 else RIGHT_SLOTS
		for row in range(4):
			slot_buttons[slots[row]].position.y = _inventory_y(170 + row * 74)
			slot_buttons[slots[row]].size.y = 66 * inventory_scale
	for button in future_buttons.values(): button.position.y = _inventory_y(476)
	inventory_heading.position.y = _inventory_y(563)
	inventory_show_all.position.y = _inventory_y(555)
	inventory_note.position.y = _inventory_y(587)
	inventory_scroll.position.y = _inventory_y(608)
	inventory_scroll.size = Vector2(432, maxf(104, nav_top - inventory_scroll.position.y - 18))
	shop_scroll.size = Vector2(432, maxf(150, nav_top - 202))
	var center_y := clampf(view.y * 0.46, 330, view.y - 275)
	play_title.position = Vector2(0, center_y - 186)
	play_badge.position = Vector2(0, center_y - 146)
	dungeon_button.position = Vector2(115, center_y - 102)
	play_hint.position = Vector2(0, center_y + 178)
	queue_redraw()

func _draw() -> void:
	var view := get_viewport_rect().size
	# Original painted-style night backdrop, independent of the dungeon scene.
	draw_rect(Rect2(Vector2.ZERO, view), Color("0b1a25"))
	for band in range(18):
		var y := view.y * band / 18.0
		draw_rect(Rect2(0, y, view.x, view.y / 18.0 + 1), Color("122c38").lerp(Color("0c1d27"), band / 18.0))
	for i in range(42):
		var point := Vector2(fmod(i * 97.0 + 33, view.x), fmod(i * 53.0 + 44, view.y * 0.7))
		draw_circle(point, 1.1, Color(0.7,0.83,0.82,0.17))
	var cx := view.x / 2
	for layer in range(3):
		var points := PackedVector2Array([Vector2(0,view.y), Vector2(0,view.y * 0.55 + layer * 60)])
		for x in range(0, int(view.x) + 50, 50): points.append(Vector2(x, view.y * 0.56 + sin(x * 0.015 + layer) * 48 + layer * 62))
		points.append(Vector2(view.x,view.y))
		draw_colored_polygon(points, Color("142f38").darkened(layer * 0.16))
	draw_line(Vector2(cx - 210,90),Vector2(cx + 210,90),Color("38515b"),1)
	draw_rect(Rect2(0,nav_top - 10,view.x,104),Color("0a1721"))
	if selected == 1:
		_draw_character(Vector2(cx, _inventory_y(332)))

func _draw_character(center: Vector2) -> void:
	draw_circle(center + Vector2(0, 73), 60, Color(0.35,0.65,0.63,0.07))
	draw_arc(center + Vector2(0, 70), 60, 0, TAU, 40, Color("496666"), 2)
	var pants_color := Color("668296") if not hub.equipped["pants"].is_empty() else Color("384d61")
	for x in [-16,16]:
		draw_line(center + Vector2(x,15),center + Vector2(x,69),pants_color,18)
		draw_line(center + Vector2(x,65),center + Vector2(x,76),Color("d8c59a") if not hub.equipped["boots"].is_empty() else Color("253340"),20)
	draw_colored_polygon(PackedVector2Array([center+Vector2(-40,21),center+Vector2(-30,-64),center+Vector2(30,-64),center+Vector2(40,21)]),Color("367e78") if hub.equipped["armor"].is_empty() else Color("4b8892"))
	for x in [-35,35]: draw_line(center+Vector2(x,-48),center+Vector2(x,-2),Color("d7ba91"),12)
	draw_circle(center+Vector2(0,-89),24,Color("e5c39a"))
	draw_arc(center+Vector2(0,-94),25,PI,TAU,20,Color("26394b") if hub.equipped["headgear"].is_empty() else Color("729185"),12)
	for x in [-8,8]: draw_circle(center+Vector2(x,-90),2,Color("172a32"))
	if not hub.equipped["necklace"].is_empty(): draw_circle(center+Vector2(0,-43),6,Color("96c9ff"))
	if not hub.equipped["ring"].is_empty(): draw_circle(center+Vector2(-35,-2),4,Color("e6c57d"))
	if not hub.equipped["bracelet"].is_empty(): draw_line(center+Vector2(31,-13),center+Vector2(39,-13),Color("e6c57d"),5)
	draw_texture_rect(Icons.texture(hub.equipped["weapon"]),Rect2(center+Vector2(26,-63),Vector2(64,64)),false)

func _inventory_y(y: float) -> float:
	return 160 + (y - 160) * inventory_scale
