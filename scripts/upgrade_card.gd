extends Button
const HomeArt = preload("res://scripts/hub_art.gd")
var clip: Control
var strips: Array[Control] = []
var names: Array[Label] = []
var descriptions: Array[Label] = []
var images: Array[TextureRect] = []
var badge: Label
var last_cycle := -1
var final_entry: Dictionary = {}
var landed := false
var target := Vector2.ZERO
func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP; focus_mode = Control.FOCUS_NONE
	for state in ["normal","hover","pressed","disabled","focus"]: add_theme_stylebox_override(state,StyleBoxEmpty.new())
	clip = Control.new(); clip.clip_contents = true; clip.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(clip)
	for i in range(2):
		var strip := Control.new(); strip.mouse_filter = Control.MOUSE_FILTER_IGNORE; clip.add_child(strip); strips.append(strip)
		var title := Label.new(); title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title.add_theme_font_override("font",HomeArt.SERIF); title.add_theme_font_size_override("font_size",15); title.mouse_filter = Control.MOUSE_FILTER_IGNORE; strip.add_child(title); names.append(title)
		var icon := TextureRect.new(); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; strip.add_child(icon); images.append(icon)
		var note := Label.new(); note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.add_theme_font_size_override("font_size",12); note.add_theme_color_override("font_color",Color("d1ddc6")); note.mouse_filter = Control.MOUSE_FILTER_IGNORE; strip.add_child(note); descriptions.append(note)
	badge = Label.new(); badge.add_theme_font_size_override("font_size",10); badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; badge.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(badge)
	resized.connect(_layout)
func _layout() -> void:
	clip.position = Vector2(8,24); clip.size = Vector2(maxf(1,size.x-16),maxf(1,size.y-40))
	for i in range(2):
		strips[i].size = clip.size
		names[i].position = Vector2(2,0); names[i].size = Vector2(maxf(1,clip.size.x-4),53)
		images[i].position = Vector2((clip.size.x-64)/2,66); images[i].size = Vector2(64,64)
		descriptions[i].position = Vector2(3,145); descriptions[i].size = Vector2(maxf(1,clip.size.x-6),maxf(1,clip.size.y-149))
	badge.position = Vector2(4,-5); badge.size = Vector2(maxf(1,size.x-8),20)
	pivot_offset = size/2; queue_redraw()
func prepare(entry: Dictionary, location: Vector2) -> void:
	_layout()
	modulate = Color.WHITE
	final_entry = entry; target = location; landed = false; disabled = true; last_cycle = -1; badge.text = "FATE"; strips[1].show()
func _fill(index: int, entry: Dictionary) -> void:
	names[index].text = entry["title"]; descriptions[index].text = entry["description"]; images[index].texture = entry["icon"]
func roll(elapsed: float, delay: float, pool: Array) -> void:
	var local := elapsed-delay
	var arrival := clampf(local/0.22,0,1)
	modulate.a = arrival; position = target+Vector2(0,28*(1-arrival))
	if local<0.78:
		var cycle := maxi(0,int(local/0.09))
		if cycle!=last_cycle:
			_fill(0,pool[(cycle+int(delay*80))%pool.size()]); _fill(1,pool[(cycle+1+int(delay*80))%pool.size()]); last_cycle = cycle
		var offset := fposmod(maxf(0,local),0.09)/0.09*clip.size.y
		strips[0].position.y = offset; strips[1].position.y = offset-clip.size.y
	else:
		if not landed:
			_fill(0,final_entry); strips[1].hide(); landed = true
			badge.text = final_entry["badge"]
		var settle := clampf((local-0.78)/0.16,0,1)
		strips[0].position.y = -clip.size.y*0.45*pow(1-settle,3)
	queue_redraw()
func _draw() -> void:
	var gold := Color("b4a16a") if not landed else (Color("ca94e7") if final_entry.get("badge","")=="RARE" else Color("dfbd78"))
	var outline := PackedVector2Array([Vector2(0,15),Vector2(14,4),Vector2(size.x-14,4),Vector2(size.x,15),Vector2(size.x,size.y-23),Vector2(size.x/2,size.y),Vector2(0,size.y-23),Vector2(0,15)])
	draw_colored_polygon(outline,Color("14382c")); draw_polyline(outline,gold,2,true)
	draw_style_box(_badge_style(gold),Rect2(10,-6,size.x-20,24))
	draw_line(Vector2(12,82),Vector2(size.x-12,82),Color(0.7,0.6,0.35,0.15))
	var mid := Vector2(size.x/2,size.y-12); draw_colored_polygon(PackedVector2Array([mid+Vector2(0,-4),mid+Vector2(4,0),mid+Vector2(0,4),mid+Vector2(-4,0)]),gold)
func _badge_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color("264738"); style.border_color = color; style.set_border_width_all(1); style.set_corner_radius_all(5); return style
