extends Control
## Painted Sanctuary home, equipment pages, and account windows.
signal tab_changed(index: int)
signal dungeon_requested
signal item_requested(id: String)
signal perk_info_requested(id: String)
signal perk_requested
signal cheat_requested
signal synthesis_requested
const Art = preload("res://scripts/game_art.gd")
const HomeArt = preload("res://scripts/hub_art.gd")
const Windows = preload("res://scripts/hub_windows.gd")
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
var shop_grid: VBoxContainer
var perk_grid: GridContainer
var task_buttons: Array[Button] = []
var perk_message := ""
var synthesis_mode := false
var synthesis_base := ""
var synthesis_fodder: Array[String] = []
var synthesis_top: Control
var synthesis_label: Label
var synthesis_base_button: Button
var synthesis_ingredients: Array[Button] = []
var synthesis_commit: Button
var synthesis_toggle: Button
var message := ""
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
var player_button: Button
var battlepass_button: Button
var profile_layer: Control
var profile_menu: Panel
var profile_buttons: Dictionary = {}
var sidebar: Control
var sidebar_buttons: Dictionary = {}
var windows
var enter_button: Button
var profile_name: Label

func setup(model) -> void:
	Art.prepare()
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
	icon.texture = HomeArt.icon(kind) if HomeArt.Regions.FRAMES.has(kind) else Icons.texture(kind)
	icon.position = pos
	icon.size = dimensions
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	return icon

func _build() -> void:
	content = Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	_build_header()
	resource_label = _label(content, "", Vector2(106, 84), 10, Color("dfbd78"))
	resource_label.size = Vector2(354,20); resource_label.clip_text = true
	best_label = _label(content, "", Vector2.ZERO, 11); best_label.hide()
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
	_build_profile_menu()
	windows = Windows.new(); add_child(windows); windows.setup(hub)
	select_tab(2)

func _build_header() -> void:
	player_button = _button(content,"",Vector2(16,12),Vector2(72,68),_toggle_profile)
	player_button.name = "PlayerProfile"; player_button.tooltip_text = "Aster • player menu"
	player_button.add_theme_stylebox_override("normal",_style(Color("233b38"),Color("c3a15e"),2))
	var portrait := TextureRect.new(); portrait.texture = HomeArt.portrait()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.position = Vector2(4,2); portrait.size = Vector2(64,64); portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_button.add_child(portrait)
	profile_name = _label(content,"ASTER",Vector2(16,83),10,Color("e5c88d")); profile_name.size.x = 72; profile_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battlepass_button = _button(content,"",Vector2(104,14),Vector2(360,64),_open_window.bind("battlepass"))
	battlepass_button.name = "BattlepassBanner"
	var image := TextureRect.new(); image.texture = HomeArt.BANNER; image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; image.position = Vector2(3,3); image.size = Vector2(354,58)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE; battlepass_button.add_child(image)
	var shade := ColorRect.new(); shade.color = Color(0.04,0.015,0.01,0.47); shade.position = Vector2(3,3); shade.size = Vector2(354,58)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE; battlepass_button.add_child(shade)
	var caption := _label(battlepass_button,"HELL IN DEVELOPMENT",Vector2(0,9),16,Color("fff0cc"))
	caption.add_theme_font_override("font",HomeArt.SERIF); caption.size.x = 360; caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub := _label(battlepass_button,"THE INFERNAL PASS  •  COMING LATER",Vector2(0,36),9,Color("efcf99"))
	sub.size.x = 360; sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_profile_menu() -> void:
	profile_layer = Control.new(); profile_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	profile_layer.z_index = 15; content.add_child(profile_layer)
	var outside := Button.new(); outside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for state in ["normal","hover","pressed","focus"]: outside.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	outside.pressed.connect(func(): profile_layer.hide()); profile_layer.add_child(outside)
	profile_menu = Panel.new(); profile_menu.position = Vector2(16,99); profile_menu.size = Vector2(180,176)
	profile_menu.add_theme_stylebox_override("panel",_style(Color("132b30"),Color("c1a46d"),2)); profile_layer.add_child(profile_menu)
	for i in range(3):
		var key: String = ["settings","bag","details"][i]
		var button := _button(profile_menu,"",Vector2(8,8+i*54),Vector2(164,48),_open_window.bind(key)); profile_buttons[key] = button
		_icon(button,key,Vector2(8,6),Vector2(36,36))
		_label(button,key.capitalize(),Vector2(53,13),13)
	profile_layer.hide()

func _toggle_profile() -> void:
	profile_layer.visible = not profile_layer.visible
	if profile_layer.visible: profile_buttons["settings"].grab_focus()

func _open_window(kind: String) -> void:
	if is_instance_valid(profile_layer): profile_layer.hide()
	windows.hub = hub; windows.open(kind)

func _begin_dungeon() -> void:
	profile_layer.hide(); windows.close(); dungeon_requested.emit()

func _build_play() -> void:
	var page := pages[2]
	play_title = _label(page,"THE FALLEN\nSANCTUARY",Vector2.ZERO,23)
	play_title.add_theme_font_override("font",HomeArt.SERIF)
	play_title.size = Vector2(320,66); play_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_title.add_theme_color_override("font_shadow_color",Color(0,0,0,0.9)); play_title.add_theme_constant_override("shadow_offset_y",2)
	play_badge = _label(page,"REGION I  •  FLOORS 1–10",Vector2.ZERO,10,Color("e5c88d"))
	play_badge.size.x = 320; play_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dungeon_button = _button(page,"",Vector2.ZERO,Vector2(300,400),_begin_dungeon)
	dungeon_button.name = "DungeonEntrance"; dungeon_button.tooltip_text = "Enter the Fallen Sanctuary"
	for state in ["normal","hover","pressed","disabled"]: dungeon_button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	enter_button = _button(page,"ENTER THE DUNGEON",Vector2.ZERO,Vector2(282,52),_begin_dungeon)
	enter_button.add_theme_font_override("font",HomeArt.SERIF); enter_button.add_theme_font_size_override("font_size",16)
	enter_button.add_theme_stylebox_override("normal",_style(Color("25423d"),Color("d1ae65"),2))
	play_hint = _label(page,"The deeper you go, the closer to hell.",Vector2.ZERO,10,Color("e2caa1"))
	play_hint.size.x = 320; play_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sidebar = Control.new(); sidebar.mouse_filter = Control.MOUSE_FILTER_IGNORE; page.add_child(sidebar)
	var paper := TextureRect.new(); paper.texture = HomeArt.PARCHMENT; paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_SCALE; paper.size = Vector2(144,340); paper.mouse_filter = Control.MOUSE_FILTER_IGNORE; sidebar.add_child(paper)
	var heading := _label(sidebar,"JOURNAL",Vector2(12,34),11,Color("624223")); heading.add_theme_font_override("font",HomeArt.SERIF)
	heading.size.x = 120; heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in range(4):
		var key: String = ["tasks","login","privileges","event"][i]
		var button := _button(sidebar,"",Vector2(19,65+i*59),Vector2(106,54),_open_window.bind(key))
		button.name = key.capitalize(); sidebar_buttons[key] = button; task_buttons.append(button)
		button.add_theme_stylebox_override("normal",_style(Color(0.3,0.21,0.1,0.08),Color(0.45,0.3,0.12,0.28)))
		button.add_theme_stylebox_override("hover",_style(Color(0.42,0.3,0.15,0.15),Color("977443")))
		_icon(button,key,Vector2(37,2),Vector2(32,29))
		var caption := _label(button,{"tasks":"Daily tasks","login":"Daily login","privileges":"Privileges","event":"Event"}[key],Vector2(0,34),11,Color("4f321c"))
		caption.size.x = 106; caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_inventory() -> void:
	var page := pages[1]
	_label(page, "INVENTORY", Vector2(24, 108), 22)
	_label(page, "Equip items, level with parts, or synthesize duplicates", Vector2(24, 139), 11, Color("8cb6ba"))
	synthesis_toggle = _button(page,"Synthesis",Vector2(300,106),Vector2(156,30),_toggle_synthesis)
	synthesis_top = Control.new()
	synthesis_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(synthesis_top)
	synthesis_base_button = _button(synthesis_top,"Select base item",Vector2(42,170),Vector2(116,88),_clear_synthesis)
	_button(synthesis_top,"Clear selection",Vector2(275,186),Vector2(160,40),_clear_synthesis)
	for index in range(3):
		var ingredient := _button(synthesis_top,"",Vector2(42+index*130,285),Vector2(116,78),_remove_ingredient.bind(index))
		synthesis_ingredients.append(ingredient)
	synthesis_label = _label(synthesis_top,"",Vector2(42,378),12,Color("bad2d0"))
	_button(synthesis_top,"Quick synthesis",Vector2(42,510),Vector2(364,38),_quick_synthesis)
	synthesis_commit = _button(synthesis_top,"Synthesize",Vector2(42,450),Vector2(396,44),_commit_synthesis)
	synthesis_top.hide()
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
	_label(page,"SHOP",Vector2(24,108),22)
	_label(page,"Daily coin offers • keys or gems open chests",Vector2(24,143),12,Color("8cb6ba"))
	shop_scroll = ScrollContainer.new()
	shop_scroll.position = Vector2(24,183)
	shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(shop_scroll)
	shop_grid = VBoxContainer.new()
	shop_grid.add_theme_constant_override("separation",12)
	shop_scroll.add_child(shop_grid)

func _build_perks() -> void:
	var page := pages[3]
	_label(page,"PERKS",Vector2(24,108),22)
	_label(page,"Unlock all twelve perks before leveling",Vector2(24,143),12,Color("8cb6ba"))
	perk_grid = GridContainer.new()
	perk_grid.position = Vector2(24,184)
	perk_grid.columns = 4
	perk_grid.add_theme_constant_override("h_separation",8)
	perk_grid.add_theme_constant_override("v_separation",10)
	page.add_child(perk_grid)
	perk_label = _label(page,"",Vector2(24,490),12)
	train_button = _button(page,"",Vector2(58,562),Vector2(364,50),func(): perk_requested.emit())

func _build_misc() -> void:
	var page := pages[4]
	_label(page,"MISCELLANEOUS",Vector2(24,108),22)
	misc_label = _label(page,"Development tools",Vector2(24,154),14,Color("bad2d0"))
	_button(page,"Cheat menu • testing",Vector2(24,410),Vector2(432,48),func(): cheat_requested.emit())
	_label(page,"THE WORKSHOP",Vector2(24,260),18)
	_label(page,"Testing tools for the current prototype.\nPlayer progress and build information are in\nthe profile menu under Details.",Vector2(24,300),13,Color("bad2d0"))

func select_tab(index: int) -> void:
	if index < 0 or index >= TABS.size(): return
	selected = index
	if is_instance_valid(profile_layer): profile_layer.hide()
	if is_instance_valid(windows): windows.close()
	tab_changed.emit(index)
	for i in range(pages.size()):
		pages[i].visible = i == index
		nav[i].add_theme_stylebox_override("normal", _style(Color("28443e") if i == index else Color("142b2e"), Color("e3c48a") if i == index else Color("74613f"), 2 if i == index else 1))
	queue_redraw()

func _slot_selected(slot: String) -> void:
	var id: String = hub.equipped[slot]
	if not id.is_empty(): item_requested.emit(id)
	else:
		filter_slot = slot
		refresh()

func _clear_grid(grid: Node) -> void:
	for child in grid.get_children():
		# Keep the pressed control in the tree until input dispatch finishes.
		if child is CanvasItem: child.hide()
		child.queue_free()

func refresh() -> void:
	if hub == null or content == null: return
	hub.refresh_day()
	hub.apply_audio_settings()
	if is_instance_valid(windows): windows.hub = hub
	resource_label.text = "%s COINS  •  %s GEMS  •  %sC / %sS / %sG" % [_amount(hub.coins),_amount(hub.gems),_amount(hub.keys["copper"]),_amount(hub.keys["silver"]),_amount(hub.keys["gold"])]
	resource_label.tooltip_text = "%d coins • %d gems • Keys: %d copper / %d silver / %d gold" % [hub.coins,hub.gems,hub.keys["copper"],hub.keys["silver"],hub.keys["gold"]]
	for slot in slot_buttons:
		var uid: String = hub.equipped[slot]
		var id: String = hub.item_type(uid)
		var button: Button = slot_buttons[slot]
		button.visible = not synthesis_mode
		slot_icons[slot].texture = Icons.texture(id if not id.is_empty() else slot)
		slot_icons[slot].modulate.a = 1.0 if not id.is_empty() else 0.35
		var color: Color = hub.Economy.COLORS[hub.inventory[uid]["rarity"]] if not uid.is_empty() else Color("3b5360")
		button.add_theme_stylebox_override("normal",_style(Color("203741") if not uid.is_empty() else Color("152734"),color))
		button.tooltip_text = slot.capitalize()+": "+hub.item_name(uid)
	for button in future_buttons.values(): button.visible = not synthesis_mode
	future_buttons["pet"].tooltip_text = "Milestone reached; pet content is coming later." if hub.pet_slot_unlocked() else "First reach floor 10."
	for child in future_buttons["pet"].get_children():
		if child is Label: child.text = "Pet\nComing soon" if hub.pet_slot_unlocked() else "Pet\nFloor 10"
	future_buttons["spirit"].tooltip_text = "Unlocks later."
	synthesis_top.visible = synthesis_mode
	synthesis_toggle.text = "Equipment" if synthesis_mode else "Synthesis"
	_clear_grid(inventory_grid)
	var count := 0
	var eligible: Array = hub.synthesis_candidates(synthesis_base) if synthesis_mode and not synthesis_base.is_empty() else []
	for uid in hub.sorted_items(synthesis_mode):
		if synthesis_mode and not synthesis_base.is_empty() and not eligible.has(uid): continue
		if not synthesis_mode and not filter_slot.is_empty() and Gear.ITEMS[hub.item_type(uid)]["slot"] != filter_slot: continue
		_add_item(inventory_grid,uid)
		count += 1
	inventory_note.text = "Choose a base, then its required duplicates" if synthesis_mode else ("Tap an item to equip or level it with parts" if count > 0 else "No items here yet. Find equipment or open shop chests.")
	_refresh_synthesis()
	_refresh_shop()
	_clear_grid(perk_grid)
	var ids: Array = hub.PERK_NAMES.keys()
	for index in range(12):
		var caption := "Reserved\nLocked"
		if index < ids.size():
			var id: String = ids[index]
			caption = "%s\n%s" % [hub.PERK_NAMES[id].replace(" ","\n"),"Locked" if hub.perks[id] == 0 else "Lv.%d/%d" % [hub.perks[id],hub.PERK_CAPS[id]]]
		var card := _button(perk_grid,caption,Vector2.ZERO,Vector2.ZERO,func(): pass)
		card.custom_minimum_size = Vector2(100,88)
		card.add_theme_font_size_override("font_size",11)
		card.disabled = index>=ids.size()
		if index<ids.size():
			card.tooltip_text = hub.PERK_EFFECTS[ids[index]]
			card.pressed.connect(func(): perk_info_requested.emit(ids[index]))
	perk_label.text = "%s\nArmor %d • Accessory %d • Weapon %d parts\n%s" % [perk_message,hub.parts["armor"],hub.parts["accessory"],hub.parts["weapon"],"Unlock all twelve perks before leveling." if hub.Economy.REQUIRE_RESERVED_PERKS else "Leveling begins after all twelve perks unlock."]
	train_button.text = "Buy random perk • %d coins" % hub.perk_price()
	train_button.disabled = not hub.can_buy_perk()
	misc_label.text = "Development tools"
	queue_redraw()

func _add_item(grid: GridContainer, uid: String) -> void:
	var item: Dictionary = hub.inventory[uid]
	var kind: String = item["type"]
	var button := _button(grid,"",Vector2.ZERO,Vector2.ZERO,_item_clicked.bind(uid))
	button.custom_minimum_size = Vector2(98,112)
	button.add_theme_stylebox_override("normal",_style(Color("172c38"),hub.Economy.COLORS[item["rarity"]],2))
	_icon(button,kind,Vector2(29,5),Vector2(40,40))
	var title := _label(button,Gear.ITEMS[kind]["name"].replace(" ","\n"),Vector2(3,48),10)
	title.size.x = 92; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var caption := "%s%s Lv.%d" % [hub.Economy.RARITIES[item["rarity"]],"+%d" % item["plus"] if item["plus"] > 0 else "",item["level"]]
	if hub.equipped.values().has(uid): caption += " [E]"
	if synthesis_fodder.has(uid): caption = "INGREDIENT"
	if synthesis_base == uid: caption = "BASE"
	var label := _label(button,caption,Vector2(2,87),9,hub.Economy.COLORS[item["rarity"]])
	label.size.x = 94; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if synthesis_mode and not synthesis_base.is_empty() and uid != synthesis_base and not synthesis_fodder.has(uid): button.disabled = not hub.synthesis_candidates(synthesis_base).has(uid)

func _refresh_shop() -> void:
	_clear_grid(shop_grid)
	var heading := Label.new(); heading.text = "DAILY OFFERS • refresh at 00:00 UTC"; heading.add_theme_font_size_override("font_size",13); shop_grid.add_child(heading)
	var daily := GridContainer.new(); daily.columns = 2
	daily.add_theme_constant_override("h_separation",10); daily.add_theme_constant_override("v_separation",8); shop_grid.add_child(daily)
	for index in range(6):
		var offer: Dictionary = hub.offers[index]
		var title: String = "%d %s parts" % [offer["quantity"],offer["type"]] if offer["kind"] == "parts" else "Common "+Gear.ITEMS[offer["type"]]["name"]
		var button := _button(daily,"%s\n%s" % [title,"SOLD" if offer["sold"] else "%d coins" % offer["price"]],Vector2.ZERO,Vector2.ZERO,_buy_offer.bind(index))
		button.custom_minimum_size = Vector2(204,80); button.add_theme_font_size_override("font_size",11)
		button.disabled = offer["sold"] or hub.coins < offer["price"]
	var chest_heading := Label.new(); chest_heading.text = "ITEM CHESTS • duplicates are kept"; chest_heading.add_theme_font_size_override("font_size",13); shop_grid.add_child(chest_heading)
	for kind in ["copper","silver","gold"]:
		var card := Panel.new(); card.custom_minimum_size = Vector2(418,170); card.add_theme_stylebox_override("panel",_style(Color("172c38"),Color("50616c"))); shop_grid.add_child(card)
		_label(card,kind.capitalize()+" chest",Vector2(12,9),18)
		var highest := "Epic" if kind == "copper" else ("Legendary" if kind == "silver" else "Legendary +1")
		_label(card,"Guaranteed %s in ≤%d misses" % [highest,35-hub.pity[kind]],Vector2(12,39),11,Color("dfbd78"))
		var odds: Array = hub.Economy.ODDS[kind]
		_label(card,"Grey %s%% • Green %s%% • Blue %s%%\nPurple %s%% • Yellow %s%%%s" % [odds[0],odds[1],odds[2],odds[3],odds[4]," (10% of yellow is +1)" if kind == "gold" else ""],Vector2(12,60),10,Color("bad2d0"))
		if kind == "gold": _label(card,"Any yellow resets the gold guarantee.",Vector2(12,94),10,Color("bad2d0"))
		var key := _button(card,"Use 1 key (%d)" % hub.keys[kind],Vector2(12,122),Vector2(190,36),_open_chest.bind(kind,"key")); key.disabled = hub.keys[kind] <= 0
		var gem := _button(card,"%d gems" % hub.Economy.GEM_COST[kind],Vector2(216,122),Vector2(190,36),_open_chest.bind(kind,"gems")); gem.disabled = hub.gems < hub.Economy.GEM_COST[kind]
	var notice := Label.new(); notice.text = message; notice.add_theme_font_size_override("font_size",12); shop_grid.add_child(notice)

func _buy_offer(index: int) -> void:
	message = hub.buy_offer(index); refresh()

func _open_chest(kind: String,payment: String) -> void:
	var result: Dictionary = hub.open_chest(kind,payment)
	message = "Not enough currency." if result.is_empty() else ("Guaranteed: " if result["guaranteed"] else "Opened: ")+hub.item_name(result["uid"])
	refresh()
	if not result.is_empty(): item_requested.emit(result["uid"])

func _claim_task(kind: String) -> void:
	hub.claim_task(kind); refresh()

func _toggle_synthesis() -> void:
	synthesis_mode = not synthesis_mode; synthesis_base = ""; synthesis_fodder.clear(); filter_slot = ""; refresh()

func _clear_synthesis() -> void:
	synthesis_base = ""; synthesis_fodder.clear(); refresh()

func _item_clicked(uid: String) -> void:
	if not synthesis_mode: item_requested.emit(uid); return
	if synthesis_base.is_empty(): synthesis_base = uid
	elif synthesis_fodder.has(uid): synthesis_fodder.erase(uid)
	elif uid != synthesis_base and hub.synthesis_candidates(synthesis_base).has(uid):
		var recipe: Dictionary = hub.Economy.recipe(hub.inventory[synthesis_base])
		if synthesis_fodder.size() < recipe["count"]: synthesis_fodder.append(uid)
	refresh()

func _remove_ingredient(index: int) -> void:
	if index < synthesis_fodder.size(): synthesis_fodder.remove_at(index); refresh()

func _quick_synthesis() -> void:
	synthesis_base = ""; synthesis_fodder.clear()
	var count: int = hub.quick_synthesis()
	inventory_note.text = "Quick synthesis: %d merges" % count
	synthesis_requested.emit(); refresh()
	inventory_note.text = "Quick synthesis: %d merges (through Rare bases)" % count

func _refresh_synthesis() -> void:
	synthesis_base_button.text = "Select base item" if synthesis_base.is_empty() else _synthesis_slot_name(synthesis_base)
	synthesis_base_button.add_theme_font_size_override("font_size",10)
	var recipe: Dictionary = {} if synthesis_base.is_empty() else hub.Economy.recipe(hub.inventory[synthesis_base])
	for index in range(3):
		synthesis_ingredients[index].visible = not recipe.is_empty() and index < recipe["count"]
		synthesis_ingredients[index].text = _synthesis_slot_name(synthesis_fodder[index]) if index < synthesis_fodder.size() else "Add ingredient"
		synthesis_ingredients[index].add_theme_font_size_override("font_size",10)
	if synthesis_base.is_empty(): synthesis_label.text = "Select any item below as the base."
	elif recipe.is_empty(): synthesis_label.text = "Mythic is the current synthesis limit."
	else:
		var base: Dictionary = hub.inventory[synthesis_base]
		synthesis_label.text = "%d OTHER %s%s %s required.\nResult: %s%s (base level retained).\nIngredients are consumed; equipped items are protected." % [recipe["count"],hub.Economy.RARITIES[base["rarity"]],"+%d" % recipe["fodder_plus"] if recipe["fodder_plus"] > 0 else "",Gear.ITEMS[base["type"]]["name"] if recipe["exact"] else Gear.ITEMS[base["type"]]["slot"]+" items",hub.Economy.RARITIES[recipe["rarity"]],"+%d" % recipe["plus"] if recipe["plus"] > 0 else ""]
	synthesis_commit.disabled = recipe.is_empty() or synthesis_fodder.size() != recipe["count"]

func _commit_synthesis() -> void:
	if hub.synthesize(synthesis_base,synthesis_fodder):
		synthesis_fodder.clear(); synthesis_requested.emit(); refresh()

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
	play_title.position = Vector2(148,127)
	play_badge.position = Vector2(148,195)
	dungeon_button.position = Vector2(154,224); dungeon_button.size = Vector2(310,nav_top-334)
	enter_button.position = Vector2(172,nav_top-93)
	play_hint.position = Vector2(148,nav_top-31)
	sidebar.position = Vector2(9,227)
	queue_redraw()

func _draw() -> void:
	var view := get_viewport_rect().size
	var left := (view.x-480)/2
	draw_rect(Rect2(Vector2.ZERO,view),Color("07161b"))
	HomeArt.cover(self,HomeArt.TOWER,Rect2(left,100,480,nav_top-100))
	if selected!=2: draw_rect(Rect2(left,100,480,nav_top-100),Color(0.025,0.065,0.075,0.92))
	# Header and nav use the same jade, ivory and bronze as the Sanctuary.
	draw_rect(Rect2(left,0,480,104),Color("10262a"))
	draw_line(Vector2(left+16,103),Vector2(left+464,103),Color("91774a"),1)
	draw_rect(Rect2(left,nav_top-7,480,101),Color("0b1b20"))
	draw_line(Vector2(left,nav_top-7),Vector2(left+480,nav_top-7),Color("af9156"),2)
	if selected == 1 and not synthesis_mode: _draw_character(Vector2(view.x/2,_inventory_y(332)))

func _amount(value: int) -> String:
	if value>=1000000: return "%.1fM" % (value/1000000.0)
	if value>=10000: return "%.1fK" % (value/1000.0)
	return str(value)

func _draw_character(center: Vector2) -> void:
	draw_set_transform(center+Vector2(0,74),0,Vector2(1,0.28))
	draw_circle(Vector2.ZERO,60,Color(0.35,0.65,0.63,0.10))
	draw_arc(Vector2.ZERO,60,0,TAU,40,Color("9a8658"),2)
	draw_set_transform(Vector2.ZERO)
	var weapon: String = hub.item_type(hub.equipped["weapon"])
	# Weapon, hands and bent arms are painted together in a complete holding pose.
	var hero := Art.frame("inventory_"+weapon)
	var height := 200.0
	var width := height*hero.get_width()/hero.get_height()
	draw_texture_rect(hero,Rect2(center+Vector2(-width*0.5,76-height),Vector2(width,height)),false)

func _inventory_y(y: float) -> float:
	return 160 + (y - 160) * inventory_scale

func _synthesis_slot_name(uid: String) -> String:
	var item: Dictionary = hub.inventory[uid]
	return "%s%s\n%s" % [hub.Economy.RARITIES[item["rarity"]],"+%d" % item["plus"] if item["plus"] > 0 else "",Gear.ITEMS[item["type"]]["name"]]

func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(profile_layer) and profile_layer.visible and event.is_action_pressed("ui_cancel"):
		profile_layer.hide(); get_viewport().set_input_as_handled()
