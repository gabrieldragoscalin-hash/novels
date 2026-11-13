extends SceneTree
const Hub = preload("res://scripts/hub.gd")
const Menu = preload("res://scripts/hub_menu.gd")
const HomeArt = preload("res://scripts/hub_art.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var path := "user://home_settings_test.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var h = Hub.new(true,path); h.highest_floor = 7
	var menu = Menu.new(); root.add_child(menu); menu.setup(h)
	assert(menu.selected==2 and menu.sidebar_buttons.size()==4 and menu.profile_buttons.size()==3)
	assert(menu.dungeon_button.position.x>menu.sidebar.position.x+144)
	assert(not menu.best_label.visible and not menu.misc_label.text.contains("Best floor"))
	menu.player_button.pressed.emit(); assert(menu.profile_layer.visible)
	menu.profile_buttons["settings"].pressed.emit()
	assert(not menu.profile_layer.visible and menu.windows.current=="settings" and menu.windows.visible)
	for pair in [["master",36],["music",51],["effects",62]]:
		menu.windows.sound_sliders[pair[0]].value = pair[1]
		assert(h.audio_settings[pair[0]]==pair[1])
	h.set_audio_setting("muted",true)
	assert(AudioServer.is_bus_mute(0) and is_equal_approx(AudioServer.get_bus_volume_linear(0),0.36))
	var restored = Hub.new(true,path)
	assert(restored.audio_settings==h.audio_settings and restored.highest_floor==7)
	menu.windows.code_input.text = "TEST"; menu.windows._redeem()
	assert(menu.windows.code_status.text=="Code redemption is not available yet." and h.coins==0)
	menu.windows.code_input.text = "  "; menu.windows._redeem(); assert(menu.windows.code_status.text=="Enter a code first.")
	for kind in ["battlepass","bag","details","licenses","tasks","login","privileges","event"]:
		menu._open_window(kind)
		assert(menu.windows.visible and menu.windows.current==kind)
		assert(menu.windows.panel.size.x==420)
		if kind=="details": assert(menu.windows.clock_label.text.ends_with("UTC"))
		menu.windows.close(); assert(not menu.windows.visible and menu.selected==2)
	menu._open_window("bag"); menu.select_tab(1); assert(not menu.windows.visible)
	assert(h.inventory.size()==1 and h.highest_floor==7)
	for kind in HomeArt.Regions.FRAMES:
		var texture := HomeArt.icon(kind)
		assert(texture.filter_clip and texture.atlas==HomeArt.SHEET)
		assert(Rect2(Vector2.ZERO,HomeArt.SHEET.get_size()).encloses(texture.region))
	assert(HomeArt.portrait().atlas==HomeArt.HERO)
	# Corrupt/legacy preferences are ignored or clamped without affecting equipment.
	restored._load({"version":4,"audio_settings":{"master":-2,"music":200,"effects":"bad","muted":"bad"}})
	assert(restored.audio_settings["master"]==0 and restored.audio_settings["music"]==100 and restored.audio_settings["effects"]==62)
	h.set_audio_setting("muted",false)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	menu.queue_free()
	print("PASS: tower home, journal/profile windows, persisted sound buses, inactive redemption, separate empty bag, progression details, live UTC clock, licenses and twelve clipped painted icons")
	quit()
