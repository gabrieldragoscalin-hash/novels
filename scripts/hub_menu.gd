extends Control
## Full-screen hub shell. Future side features are deliberately unpopulated.
signal tab_changed(index: int)
signal dungeon_requested
signal item_requested(id: String)
signal perk_info_requested(id: String)
signal perk_requested
signal cheat_requested
signal synthesis_requested
const Art = preload("res://scripts/game_art.gd")
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
	play_title = _label(page, "The Fallen Sanctuary", Vector2.ZERO, 24)
	play_title.size.x = 480
	play_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_badge = _label(page, "REGION I • FLOORS 1–10", Vector2.ZERO, 12, Color("dfbd78"))
	play_badge.size.x = 480
	play_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dungeon_button = _button(page, "", Vector2.ZERO, Vector2(250, 270), func(): dungeon_requested.emit())
	dungeon_button.name = "DungeonEntrance"
	dungeon_button.add_theme_stylebox_override("normal", _style(Color(0,0,0,0), Color(0,0,0,0), 0))
	var preview := TextureRect.new()
	preview.texture = Art.ROOM
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.position = Vector2(0,0); preview.size = Vector2(250,250)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dungeon_button.add_child(preview)
	var portal := TextureRect.new()
	portal.texture = Art.frame("exit")
	portal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portal.position = Vector2(70,50); portal.size = Vector2(110,170)
	portal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dungeon_button.add_child(portal)
	play_hint = _label(page, "Tap the dungeon to begin", Vector2.ZERO, 15, Color("bad2d0"))
	play_hint.size.x = 480
	play_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

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
	misc_label = _label(page,"",Vector2(24,154),12,Color("bad2d0"))
	_button(page,"Cheat menu • testing",Vector2(24,410),Vector2(432,48),func(): cheat_requested.emit())
	_label(page,"GEMS & TASKS",Vector2(24,300),18)
	_label(page,"Reserved until tasks and rewards are defined.\nGem purchases are not available.",Vector2(24,340),13,Color("bad2d0"))

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

func _clear_grid(grid: Node) -> void:
	for child in grid.get_children():
		# Keep the pressed control in the tree until input dispatch finishes.
		if child is CanvasItem: child.hide()
		child.queue_free()

func refresh() -> void:
	if hub == null or content == null: return
	hub.refresh_day()
	resource_label.text = "%d COINS  %d GEMS  •  KEYS %dC/%dS/%dG" % [hub.coins,hub.gems,hub.keys["copper"],hub.keys["silver"],hub.keys["gold"]]
	best_label.text = "BEST FLOOR %d" % hub.highest_floor
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
	misc_label.text = "Best floor %d • local-device save\nEach floor pays keys for its first 3 daily clears.\nPet: first reach floor 10. Spirit: later.\nCurrent expedition cap: floor 10." % hub.highest_floor
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
	if selected == 1 and not synthesis_mode:
		_draw_character(Vector2(cx, _inventory_y(332)))

func _draw_character(center: Vector2) -> void:
	draw_circle(center+Vector2(0,73),60,Color(0.35,0.65,0.63,0.07))
	draw_arc(center+Vector2(0,70),60,0,TAU,40,Color("496666"),2)
	var hero := Art.frame("hero_front")
	var height := 190.0
	var width := height*hero.get_width()/hero.get_height()
	draw_texture_rect(hero,Rect2(center+Vector2(-width*Art.pivot("hero_front"),76-height),Vector2(width,height)),false)

func _inventory_y(y: float) -> float:
	return 160 + (y - 160) * inventory_scale

func _synthesis_slot_name(uid: String) -> String:
	var item: Dictionary = hub.inventory[uid]
	return "%s%s\n%s" % [hub.Economy.RARITIES[item["rarity"]],"+%d" % item["plus"] if item["plus"] > 0 else "",Gear.ITEMS[item["type"]]["name"]]
