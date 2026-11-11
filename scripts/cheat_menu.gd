extends Control
## Deliberately available in the public testing prototype; remove before release.
var game
var body: VBoxContainer
var status: Label
var item_picker: OptionButton
var rarity_picker: OptionButton
var plus_picker: OptionButton
var floor_picker: OptionButton
var room_picker: OptionButton
var copies: SpinBox
var run_buttons: Array[Button] = []
var item_ids: Array = []
var upgrade_picker: OptionButton
var upgrade_ids: Array[String] = []
var reset_dialog: ConfirmationDialog
var god_button: Button

func setup(controller) -> void:
	game = controller
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.025,0.045,0.065,0.98)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := MarginContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_constant_override("margin_left",24)
	panel.add_theme_constant_override("margin_right",24)
	panel.add_theme_constant_override("margin_top",20)
	panel.add_theme_constant_override("margin_bottom",20)
	add_child(panel)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation",10); panel.add_child(column)
	var title := Label.new(); title.text = "CHEATS • TESTING PROTOTYPE"; column.add_child(title)
	var close := Button.new(); close.text = "Close and resume"; close.custom_minimum_size.y = 44; close.pressed.connect(hide); column.add_child(close)
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; column.add_child(scroll)
	body = VBoxContainer.new(); body.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",10); scroll.add_child(body)
	status = Label.new(); status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; body.add_child(status)
	_note("Wallet and item grants are saved on this device.\nRun cheats reset with a new expedition.")
	_action("+10,000 coins",grant.bind("coins"))
	_action("+1,000 gems",grant.bind("gems"))
	_action("+35 of EACH key",grant.bind("keys"))
	_action("+100 of EACH upgrade part",grant.bind("parts"))
	_action("Next chest guaranteed (all pity = 34)",grant.bind("pity"))
	_action("Reset daily key limits / daily shop",grant.bind("daily"))
	_note("CREATE EQUIPMENT • each copy is separate")
	item_ids = game.hub.Equipment.ITEMS.keys()
	item_picker = OptionButton.new()
	for id in item_ids: item_picker.add_item(game.hub.Equipment.ITEMS[id]["name"])
	body.add_child(item_picker)
	rarity_picker = OptionButton.new()
	for rarity in game.hub.Economy.RARITIES: rarity_picker.add_item(rarity)
	body.add_child(rarity_picker)
	plus_picker = OptionButton.new(); body.add_child(plus_picker)
	rarity_picker.item_selected.connect(func(_index): _enhancements())
	_enhancements()
	copies = SpinBox.new(); copies.min_value = 1; copies.max_value = 20; copies.value = 4; body.add_child(copies)
	_action("Give selected item copies",give_items)
	_note("PERKS • apply to the NEXT run")
	_action("Unlock all twelve perks at level 1",grant.bind("unlock_perks"))
	_action("Max all twelve perks",grant.bind("max_perks"))
	_note("NEW TEST EXPEDITION • replaces current run")
	floor_picker = OptionButton.new()
	for floor_number in range(1,game.DungeonState.MAX_FLOOR+1): floor_picker.add_item("Start on floor %d" % floor_number)
	body.add_child(floor_picker)
	_action("Start selected floor",start_floor)
	_note("CURRENT RUN")
	upgrade_picker = OptionButton.new(); body.add_child(upgrade_picker)
	_action("Add selected run upgrade",give_upgrade,true)
	god_button = _action("God mode",toggle_god,true)
	_action("Heal to full",heal,true)
	_action("+100 dungeon flares",flares,true)
	_action("Add one level-up choice",level_up,true)
	_action("Defeat current room enemies (normal rewards)",clear_room,true)
	room_picker = OptionButton.new()
	for y in range(5):
		for x in range(5): room_picker.add_item("Room %s%d" % [char(65+x),y+1])
	body.add_child(room_picker)
	_action("Teleport to selected room",teleport,true)
	_action("Teleport to boss",teleport_boss,true)
	_note("RESET • permanently deletes local progress")
	_action("Reset everything…",func(): reset_dialog.popup_centered(Vector2i(350,180)))
	reset_dialog = ConfirmationDialog.new()
	reset_dialog.title = "Start anew?"
	reset_dialog.dialog_text = "Delete all equipment, currencies, keys, perks,\ndaily counters, pity and dungeon progress?"
	reset_dialog.ok_button_text = "Delete and start anew"
	reset_dialog.confirmed.connect(reset_everything)
	add_child(reset_dialog)
	hide()

func reset_everything() -> void:
	var old = game.hub
	var fresh = game.HubState.new(false,old.storage_path)
	fresh.enabled = old.enabled
	if not fresh.save(): status.text = "Reset could not be saved. Try again."; return
	game.hub = fresh
	game.hub_menu.synthesis_base = ""; game.hub_menu.synthesis_fodder.clear()
	game.hub_menu.synthesis_mode = false
	game.hub_menu.perk_message = ""; game.hub_menu.message = ""; game.hub_menu.filter_slot = ""
	game._new_run(false)
	game._return_to_hub()
	game._refresh_hub()
	hide()

func _note(text: String) -> void:
	var label := Label.new(); label.text = text; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; body.add_child(label)

func _action(text: String, callback: Callable, run_only: bool = false) -> Button:
	var button := Button.new(); button.text = text; button.custom_minimum_size.y = 46
	button.add_theme_font_size_override("font_size",13)
	button.pressed.connect(callback); body.add_child(button)
	if run_only: run_buttons.append(button)
	return button

func open() -> void:
	if game.transitioning or game.wheel_spinning: return
	game._release_stick()
	for button in run_buttons: button.disabled = game.in_hub or not game.active
	god_button.text = "God mode: %s" % ("ON" if game.combat.invincible else "OFF")
	_refresh_upgrades()
	status.text = "Combat paused. Permanent grants are saved."
	show()

func _done(message: String) -> void:
	game.hub.save(); game._refresh_hub(); status.text = message

func _enhancements() -> void:
	plus_picker.clear(); plus_picker.add_item("No enhancement")
	if rarity_picker.selected in [3,4]: plus_picker.add_item("+1")
	if rarity_picker.selected == 4: plus_picker.add_item("+2")

func grant(kind: String) -> void:
	var h = game.hub
	match kind:
		"coins": h.coins += 10000
		"gems": h.gems += 1000
		"keys":
			for key in h.keys: h.keys[key] += 35
		"parts":
			for part in h.parts: h.parts[part] += 100
		"pity":
			for key in h.pity: h.pity[key] = 34
		"daily":
			h.daily_clears.clear(); h.claimed_clears.clear()
			for offer in h.offers: offer["sold"] = false
		"unlock_perks", "max_perks":
			for perk in h.perks: h.perks[perk] = h.PERK_CAPS[perk] if kind == "max_perks" else maxi(1,h.perks[perk])
			h.perk_purchases = h._perk_total()
		_: return
	_done("Applied: " + kind.replace("_"," "))

func give_items() -> void:
	for i in range(int(copies.value)): game.hub.find_equipment(item_ids[item_picker.selected],rarity_picker.selected,plus_picker.selected)
	_done("Added %d item copies to Inventory." % int(copies.value))

func start_floor() -> void:
	game.start_game() if game.in_hub else game.restart_run()
	for i in range(floor_picker.selected): game.dungeon.advance()
	game.player = Vector2(240,530)
	game._enter_current(); game._update_room_label()
	hide()

func toggle_god() -> void:
	game.combat.invincible = not game.combat.invincible
	god_button.text = "God mode: %s" % ("ON" if game.combat.invincible else "OFF")
	status.text = "God mode applies to this run only."

func heal() -> void:
	game.combat.health = game.combat.progression.max_health()
	status.text = "Fully healed."

func flares() -> void:
	game.combat.progression.flares += 100
	status.text = "Added 100 run flares."

func level_up() -> void:
	game.combat.progression.reward_choices(2,true)
	status.text = "Upgrade choice queued. Close to choose."

func clear_room() -> void:
	for enemy in game.combat.enemies:
		enemy["dormant"] = false
		game.combat._damage_enemy(enemy,1000000)
	game._claim_floor_reward()
	status.text = "Room defeated. XP pickups and normal rewards retained."

func teleport() -> void:
	_jump(Vector2i(room_picker.selected % 5,room_picker.selected / 5))

func teleport_boss() -> void:
	for pos in game.dungeon.rooms:
		if game.dungeon.rooms[pos]["role"] == "boss": _jump(pos); return

func _jump(pos: Vector2i) -> void:
	game.dungeon.current = pos
	game.player = Vector2(240,530)
	game._release_stick(); game._enter_current(); game._update_room_label()
	game._close_service()
	hide()

func _refresh_upgrades() -> void:
	upgrade_ids = game.combat.progression.available_upgrades()
	upgrade_picker.clear()
	for id in upgrade_ids: upgrade_picker.add_item(game.combat.progression.upgrade_info(id)[0])
	upgrade_picker.disabled = game.in_hub or not game.active

func give_upgrade() -> void:
	if game.in_hub or not game.active or upgrade_picker.selected < 0: return
	var id: String = upgrade_ids[upgrade_picker.selected]
	game.combat.give_upgrade(id)
	status.text = "Added: " + game.combat.progression.upgrade_info(id)[0]
	_refresh_upgrades()
