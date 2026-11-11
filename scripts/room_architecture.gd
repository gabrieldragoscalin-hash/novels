extends RefCounted
## Original Sanctuary masonry using Archero's readable arena construction principles.
const Plans = preload("res://scripts/room_layouts.gd")
const Art = preload("res://scripts/game_art.gd")
const Surfaces = preload("res://scripts/room_surfaces.gd")
const FLOOR := Rect2(8,166,464,438)

static func draw_static(c: CanvasItem, layout: int, floor_number: int, neighbors: Array[Vector2i]) -> void:
	c.draw_rect(Rect2(0,140,480,487),Color("0d161b"))
	var tint: Color = Art.floor_tint(floor_number)*[Color.WHITE,Color(0.95,1,0.97),Color(1,0.97,0.93)][layout%3]
	c.draw_texture_rect(Art.ARENA_FLOOR,FLOOR,false,tint)
	# Back and side walls cast broad quiet shadows onto the fighting plane.
	c.draw_rect(Rect2(8,166,464,18),Color(0.03,0.08,0.08,0.28))
	c.draw_rect(Rect2(8,166,14,438),Color(0.03,0.08,0.08,0.2))
	if layout==0:
		for y in [210,500]: Surfaces.tile(c,"mosaic",Rect2(218,y,44,54),Vector2(54,54),Vector2.ZERO,Color(1,1,1,0.26))
	if layout==2:
		for x in [88,312]: Surfaces.tile(c,"mosaic",Rect2(x,254,80,50),Vector2(60,60),Vector2.ZERO,Color(1,1,1,0.22))
	if layout==5: Surfaces.tile(c,"mosaic",Rect2(212,357,56,56),Vector2(56,56),Vector2.ZERO,Color(1,1,1,0.3))
	var material := Plans.material(layout)
	for rect in Plans.terrain(layout):
		if material=="chasm": _fracture(c,rect)
		else: _channel_banks(c,rect)
	for rect in Plans.bridges(layout): _bridge(c,rect,layout==4)
	_shell(c,neighbors)
	if layout==1:
		_socket(c,Rect2(8,300,24,52),false,false)
		_socket(c,Rect2(448,300,24,52),false,true)
	if layout==4:
		_socket(c,Rect2(300,166,54,26),true,false)
		_socket(c,Rect2(300,578,54,26),true,true)
	var corruption := Art.stage(floor_number)
	if corruption>0: c.draw_texture_rect(Art.CORRUPTION,Rect2(0,142,480,476),false,Color(1,1,1,corruption*0.6))

static func draw_liquids(c: CanvasItem, layout: int, clock: float) -> void:
	var material := Plans.material(layout)
	if material not in ["water","lava"]: return
	for rect in Plans.terrain(layout):
		var vertical: bool = rect.size.y>rect.size.x
		var phase := Vector2(0,clock*9) if vertical else Vector2(clock*9,0)
		Surfaces.tile(c,material,rect.grow(-6),Vector2(112,112),phase,Color.WHITE)

static func _channel_banks(c: CanvasItem, rect: Rect2) -> void:
	c.draw_rect(rect.grow(5),Color("172326"))
	Surfaces.tile(c,"capstone",rect.grow(4),Vector2(48,48),Vector2.ZERO,Color(0.8,0.82,0.72))
	c.draw_rect(rect,Color("102326"))
	# A visible vertical bank face makes water/lava recessed below the room floor.
	if rect.size.y>rect.size.x:
		Surfaces.tile(c,"wall",Rect2(rect.position,Vector2(7,rect.size.y)),Vector2(24,48),Vector2.ZERO,Color(0.6,0.68,0.65))
	else:
		Surfaces.tile(c,"wall",Rect2(rect.position,Vector2(rect.size.x,7)),Vector2(48,24),Vector2.ZERO,Color(0.6,0.68,0.65))

static func _bridge(c: CanvasItem, rect: Rect2, horizontal: bool) -> void:
	c.draw_rect(rect.grow(3),Color("142326"))
	Surfaces.tile(c,"wall",Rect2(rect.position+Vector2(0,6),rect.size),Vector2(48,32),Vector2.ZERO,Color(0.65,0.7,0.66))
	Surfaces.tile(c,"bridge",rect,Vector2(64,64),Vector2.ZERO,Color(0.9,0.95,0.86))
	# Narrow capstones outline the crossing; no tall rails block its walkable deck.
	if horizontal:
		for y in [rect.position.y,rect.end.y-3]: Surfaces.tile(c,"capstone",Rect2(rect.position.x,y,rect.size.x,3),Vector2(48,12))
	else:
		for x in [rect.position.x,rect.end.x-3]: Surfaces.tile(c,"capstone",Rect2(x,rect.position.y,3,rect.size.y),Vector2(12,48))

static func _fracture(c: CanvasItem, rect: Rect2) -> void:
	var corners := [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]
	var rim := PackedVector2Array()
	for side in range(4):
		var a: Vector2 = corners[side]
		var direction: Vector2 = corners[(side+1)%4]-a
		var inward := direction.normalized().orthogonal()
		var steps := maxi(3,int(direction.length()/18))
		for i in range(steps):
			var stagger := 0.0 if i==0 else sin(i*4.1+side)*0.24
			var bite := 0.0 if i==0 else float(posmod(i*31+side*17+int(rect.position.x),10)-2)
			rim.append(a+direction*(i+stagger)/steps+inward*bite)
	c.draw_colored_polygon(rim,Color("8a8b75"))
	var opening := PackedVector2Array(); var uv := PackedVector2Array()
	var texture := Surfaces.frame("chasm")
	for point in rim:
		var inner := point.lerp(rect.get_center(),0.055)+Vector2(0,2)
		opening.append(inner)
		# Crop the material's walkable-looking outer shelves; the visible area is a drop.
		var local := ((inner-rect.position)/rect.size)*0.7+Vector2(0.15,0.15)
		uv.append((texture.region.position+local*texture.region.size)/Surfaces.SHEET.get_size())
	c.draw_polygon(opening,PackedColorArray([Color.WHITE]),uv,Surfaces.SHEET)
	for i in range(1,rim.size(),4):
		var outward := rect.get_center().direction_to(rim[i])
		c.draw_line(rim[i],rim[i]+outward*10,Color("273931"),1)

static func _shell(c: CanvasItem, neighbors: Array[Vector2i]) -> void:
	var top_gaps := [Vector2(8,208),Vector2(272,472)] if neighbors.has(Vector2i.UP) else [Vector2(8,472)]
	for span in top_gaps:
		var count := maxi(1,roundi((span.y-span.x)/96))
		for i in range(count): _picture(c,"masonry_h",Rect2(span.x+(span.y-span.x)*i/count,126,(span.y-span.x)/count+1,52))
	for side in [-1,1]:
		var direction := Vector2i.LEFT if side<0 else Vector2i.RIGHT
		var segments := [Vector2(174,353),Vector2(417,604)] if neighbors.has(direction) else [Vector2(174,604)]
		for span in segments:
			var x := 0.0 if side<0 else 463.0
			Surfaces.tile(c,"capstone",Rect2(x,span.x,17,span.y-span.x),Vector2(24,48),Vector2.ZERO,Color(0.83,0.85,0.77))
			Surfaces.tile(c,"wall",Rect2(x+(10 if side<0 else 0),span.x+3,7,span.y-span.x-3),Vector2(18,48),Vector2.ZERO,Color(0.65,0.72,0.68))
	var bottom_gaps := [Vector2(8,208),Vector2(272,472)] if neighbors.has(Vector2i.DOWN) else [Vector2(8,472)]
	for span in bottom_gaps:
		Surfaces.tile(c,"wall",Rect2(span.x,609,span.y-span.x,12),Vector2(48,24),Vector2.ZERO,Color(0.7,0.76,0.7))
		Surfaces.tile(c,"capstone",Rect2(span.x,601,span.y-span.x,9),Vector2(48,18))
	for direction in neighbors: draw_door(c,direction)

static func draw_door(c: CanvasItem, direction: Vector2i) -> void:
	if direction==Vector2i.UP:
		_picture(c,"steps",Rect2(216,174,48,30))
		_picture(c,"gate_front",Rect2(207,126,66,68))
	elif direction==Vector2i.DOWN:
		_picture(c,"steps",Rect2(208,590,64,34))
	elif direction==Vector2i.LEFT:
		_picture(c,"gate_side",Rect2(-10,337,46,78),true)
		_picture(c,"steps",Rect2(8,376,38,22))
	else:
		_picture(c,"gate_side",Rect2(444,337,46,78))
		_picture(c,"steps",Rect2(434,376,38,22),true)

static func _socket(c: CanvasItem, rect: Rect2, lava: bool, drain: bool) -> void:
	Surfaces.tile(c,"capstone",rect.grow(3),Vector2(32,32),Vector2.ZERO,Color(0.8,0.85,0.75))
	if drain: Surfaces.tile(c,"grate",rect.grow(-3),rect.size)
	else:
		Surfaces.tile(c,"wall",rect.grow(-3),Vector2(36,36),Vector2.ZERO,Color(0.45,0.55,0.5))
		var glow := Color(1,0.42,0.12,0.45) if lava else Color(0.25,0.85,0.65,0.4)
		c.draw_rect(rect.grow(-5),glow)

static func _picture(c: CanvasItem, key: String, rect: Rect2, flip: bool = false) -> void:
	var destination := rect
	if flip: destination = Rect2(rect.end.x,rect.position.y,-rect.size.x,rect.size.y)
	c.draw_texture_rect(Art.frame(key),destination,false)
