extends Control
## One modal stack. Closing a window never changes the selected hub page.
const Art = preload("res://scripts/hub_art.gd")
var hub
var panel: PanelContainer
var body: VBoxContainer
var title_label: Label
var close_button: Button
var scroll: ScrollContainer
var current := ""
var clock_label: Label
var code_input: LineEdit
var code_status: Label
var sound_sliders: Dictionary = {}
var sound_values: Dictionary = {}
var clock_age := 0.0
func setup(model) -> void:
	hub = model
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 30
	var shade := Button.new(); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := StyleBoxFlat.new(); dim.bg_color = Color(0.015,0.02,0.025,0.82)
	for state in ["normal","hover","pressed","focus"]: shade.add_theme_stylebox_override(state,dim)
	shade.pressed.connect(close); add_child(shade)
	panel = PanelContainer.new(); panel.name = "HubWindow"
	var frame := StyleBoxFlat.new(); frame.bg_color = Color("132b30"); frame.border_color = Color("b39861")
	frame.set_border_width_all(2); frame.set_corner_radius_all(12)
	frame.shadow_color = Color(0,0,0,0.6); frame.shadow_size = 18
	for edge in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: frame.set_content_margin(edge,20)
	panel.add_theme_stylebox_override("panel",frame); add_child(panel)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation",12); panel.add_child(column)
	var heading := HBoxContainer.new(); column.add_child(heading)
	title_label = Label.new(); title_label.add_theme_font_override("font",Art.SERIF); title_label.add_theme_font_size_override("font_size",22)
	title_label.add_theme_color_override("font_color",Color("ecdcb6")); title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title_label)
	close_button = Button.new(); close_button.text = "×"; close_button.custom_minimum_size = Vector2(40,40)
	close_button.add_theme_font_size_override("font_size",24); close_button.pressed.connect(close); heading.add_child(close_button)
	var line := HSeparator.new(); column.add_child(line)
	scroll = ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; column.add_child(scroll)
	body = VBoxContainer.new(); body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",14); scroll.add_child(body)
	resized.connect(_layout); _layout(); hide()
func _layout() -> void:
	if panel==null: return
	var view := get_viewport_rect().size
	panel.position = Vector2((view.x-420)/2,maxf(16,(view.y-610)/2))
	panel.size = Vector2(420,minf(610,view.y-32))
func _note(text: String, font_size: int = 14, color: Color = Color("c7d1c9")) -> Label:
	var label := Label.new(); label.text = text; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size); label.add_theme_color_override("font_color",color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(label); return label
func _action(text: String, callback: Callable) -> Button:
	var button := Button.new(); button.text = text; button.custom_minimum_size.y = 44
	button.pressed.connect(callback); body.add_child(button); return button
func open(kind: String) -> void:
	current = kind; clock_label = null; code_input = null; code_status = null
	sound_sliders.clear(); sound_values.clear()
	# Keep the pressed control in the tree until touch dispatch finishes.
	for child in body.get_children(): child.hide(); child.queue_free()
	scroll.scroll_vertical = 0
	title_label.text = {"battlepass":"THE INFERNAL PASS","settings":"SETTINGS","bag":"BAG","details":"CHRONICLE","licenses":"ENGINE & LICENSES","tasks":"DAILY TASKS","login":"DAILY LOGIN","privileges":"PRIVILEGES","event":"EVENT"}.get(kind,"THE SANCTUARY")
	match kind:
		"battlepass":
			var image := TextureRect.new(); image.texture = Art.BANNER; image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; image.custom_minimum_size.y = 150; body.add_child(image)
			_note("Hell in development",25,Color("efc784"))
			_note("The battlepass will arrive in a future update.")
		"settings": _settings()
		"bag": _bag()
		"details": _details()
		"licenses":
			_action("Back to Details",open.bind("details"))
			_note("GAME & ART\n© 2026 Dungeon project contributors.\nOriginal game artwork created with AI assistance.\n\nFONT\nDejaVu Serif — Bitstream Vera / DejaVu licenses.\nFull font notice included below.\n\nGODOT ENGINE\n"+Engine.get_license_text()+"\n\n"+FileAccess.get_file_as_string("res://art/fonts/LICENSE.txt"),11)
			for group in Engine.get_copyright_info():
				_note(group["name"],13,Color("d8b674"))
				for part in group["parts"]:
					_note("\n".join(part["copyright"])+"\n"+part["license"],10)
			var licenses := Engine.get_license_info()
			for key in licenses: _note(key+"\n"+licenses[key],10)
		_:
			_note("Coming to the Sanctuary",21,Color("e4c68c"))
			_note({"tasks":"Daily tasks and their rewards are being designed.","login":"Daily login rewards are being designed.","privileges":"Privileges will be defined in a future update.","event":"The first event is in development."}.get(kind,"In development."))
	show(); close_button.grab_focus()
func _settings() -> void:
	_note("SOUND",13,Color("d8b674"))
	for key in ["master","music","effects"]:
		var row := HBoxContainer.new(); body.add_child(row)
		var label := Label.new(); label.text = key.capitalize(); label.custom_minimum_size.x = 78; row.add_child(label)
		var slider := HSlider.new(); slider.min_value = 0; slider.max_value = 100; slider.step = 1
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL; slider.custom_minimum_size.y = 38; slider.value = hub.audio_settings[key]
		row.add_child(slider); sound_sliders[key] = slider
		var value := Label.new(); value.text = "%d%%" % slider.value; value.custom_minimum_size.x = 45; row.add_child(value); sound_values[key] = value
		slider.value_changed.connect(func(amount): hub.set_audio_setting(key,amount); sound_values[key].text = "%d%%" % amount)
	var mute := CheckButton.new(); mute.text = "Mute all sound"; mute.button_pressed = hub.audio_settings["muted"]
	mute.toggled.connect(func(on): hub.set_audio_setting("muted",on)); body.add_child(mute)
	_note("Your mix is saved on this device. Music and sound effects will be added later.",12)
	body.add_child(HSeparator.new())
	_note("INSERT CODE",13,Color("d8b674"))
	var row := HBoxContainer.new(); body.add_child(row)
	code_input = LineEdit.new(); code_input.placeholder_text = "Enter a redeem code"; code_input.max_length = 64
	code_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL; code_input.custom_minimum_size.y = 44; row.add_child(code_input)
	var redeem := Button.new(); redeem.text = "Redeem"; redeem.custom_minimum_size = Vector2(90,44); row.add_child(redeem)
	redeem.pressed.connect(_redeem); code_input.text_submitted.connect(func(_text): _redeem())
	code_status = _note("Code redemption is not available yet.",12,Color("d8b674"))
func _redeem() -> void:
	code_status.text = "Enter a code first." if code_input.text.strip_edges().is_empty() else "Code redemption is not available yet."
func _bag() -> void:
	_note("EVENT BELONGINGS",13,Color("d8b674"))
	_note("A separate home for shards, event currencies, and special containers.")
	var image := TextureRect.new(); image.texture = Art.icon("bag"); image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.custom_minimum_size.y = 110; image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; body.add_child(image)
	_note("Your bag is empty",21,Color("ecdcb6"))
	_note("Event items will appear here when those features arrive. Your equipment remains in Inventory.",13)
	var grid := GridContainer.new(); grid.columns = 3; grid.add_theme_constant_override("h_separation",8); body.add_child(grid)
	for caption in ["Shards","Currencies","Containers"]:
		var slot := Button.new(); slot.text = caption+"\nComing later"; slot.disabled = true; slot.custom_minimum_size = Vector2(118,72); slot.add_theme_font_size_override("font_size",11); grid.add_child(slot)
func _details() -> void:
	_note("THE DUNGEON",20,Color("ecdcb6"))
	_note("Version %s • Development build\nDefault champion: Aster, the mortal-born\nPlayable expedition: floors 1–10\nPlanned launch: 50 floors" % ProjectSettings.get_setting("application/config/version","0.4.0"),13)
	_note("YOUR JOURNEY",13,Color("d8b674"))
	_note("Best floor: %d\nProgress is saved on this device.\nEach floor pays keys for its first 3 daily clears.\nPet milestone: first reach floor 10. Spirit: later." % hub.highest_floor,13)
	clock_label = _note("",12,Color("d8b674")); _clock()
	_note("Prototype in active development. Balance, art, and systems will continue to evolve.\n\nBuilt with Godot %s (MIT).\n© 2026 Dungeon project contributors.\nOriginal artwork created with AI assistance." % Engine.get_version_info()["string"],12)
	_action("Engine, copyright & licenses",open.bind("licenses"))
func _clock() -> void:
	if is_instance_valid(clock_label): clock_label.text = "CURRENT TIME\n"+Time.get_datetime_string_from_system(true,true)+" UTC"
func _process(delta: float) -> void:
	if not visible: return
	clock_age += delta
	if clock_age>=1: clock_age = 0; _clock()
func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"): close(); get_viewport().set_input_as_handled()
func close() -> void:
	if is_instance_valid(code_input): code_input.release_focus()
	hide(); current = ""
