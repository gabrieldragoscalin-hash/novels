extends RefCounted
## Floor construction is drawn from the same authored rectangles used by navigation.
const Plans = preload("res://scripts/room_layouts.gd")
static func draw_plan(c: CanvasItem, layout: int, clock: float) -> void:
	var gold := Color("806d49")
	# A continuous processional route gives the entrance and central service a focal axis.
	if layout==0:
		c.draw_rect(Rect2(207,195,66,376),Color(0.14,0.25,0.22,0.65))
		for x in [207,273]: c.draw_line(Vector2(x,195),Vector2(x,571),gold,2)
		for y in range(208,570,32): c.draw_line(Vector2(211,y),Vector2(269,y),Color(0.55,0.48,0.31,0.22),1)
		c.draw_arc(Vector2(240,385),54,0,TAU,48,gold,2)
	if layout==2:
		for x in [85,309]:
			c.draw_rect(Rect2(x,231,86,73),Color(0.22,0.09,0.12,0.45))
			c.draw_rect(Rect2(x,231,86,73),gold,false,1)
	if layout==5:
		c.draw_rect(Rect2(203,351,74,68),Color(0.48,0.47,0.34,0.24))
		c.draw_rect(Rect2(203,351,74,68),gold,false,2)
	var material := Plans.material(layout)
	for rect in Plans.terrain(layout):
		if material=="chasm": _fracture(c,rect)
		else: _channel(c,rect,material,clock)
	for rect in Plans.bridges(layout): _bridge(c,rect,layout==4)
	# Source and drain are built into the wall, on the same axis as the channel.
	if layout==1:
		_socket(c,Rect2(7,299,25,54),false,false,clock)
		_socket(c,Rect2(448,299,25,54),false,true,clock)
	if layout==4:
		_socket(c,Rect2(299,165,56,27),true,false,clock)
		_socket(c,Rect2(299,578,56,27),true,true,clock)

static func _channel(c: CanvasItem, rect: Rect2, material: String, clock: float) -> void:
	var lava := material=="lava"
	var vertical := rect.size.y>rect.size.x
	c.draw_rect(rect.grow(5),Color("82785c"))
	c.draw_rect(rect.grow(2),Color("29362f"))
	c.draw_rect(rect,Color("1c1718") if lava else Color("102e2d"))
	var surface := rect.grow(-5)
	c.draw_rect(surface,Color("a63b20") if lava else Color("19514a"))
	# Recessed masonry: dark near wall, lit lip at the opposite bank.
	if vertical:
		c.draw_rect(Rect2(rect.position,Vector2(7,rect.size.y)),Color(0,0,0,0.45))
		c.draw_line(Vector2(rect.end.x,rect.position.y),rect.end,Color("c2ac79"),2)
	else:
		c.draw_rect(Rect2(rect.position,Vector2(rect.size.x,7)),Color(0,0,0,0.45))
		c.draw_line(Vector2(rect.position.x,rect.end.y),rect.end,Color("c2ac79"),2)
	var length: float = surface.size.y if vertical else surface.size.x
	for i in range(int(length/17)+2):
		var travel := fposmod(i*17+clock*(21 if lava else 14),maxf(1,length))
		var wobble := sin(i*2.3+clock)*3
		var point := surface.position+(Vector2(surface.size.x*0.5+wobble,travel) if vertical else Vector2(travel,surface.size.y*0.5+wobble))
		var side := Vector2(1,0) if vertical else Vector2(0,1)
		var tint := Color(1,0.71,0.25,0.65) if lava else Color(0.44,0.79,0.64,0.30)
		var flow := Vector2.DOWN if vertical else Vector2.RIGHT
		c.draw_line(point-flow*6,point+flow*5,tint,2)
		if not lava:
			c.draw_line(point+side*9-flow*3,point+side*9+flow*4,Color(tint,0.2),1)
		else:
			c.draw_line(point-side*10-flow*4,point-side*8+flow*7,Color("d45b28"),3)
		if lava:
			c.draw_circle(point+side*5,4+sin(clock*2+i),Color(1,0.53,0.12,0.55))
			c.draw_circle(point+side*5,1.7,Color(1,0.85,0.37,0.85))
	# Stone joints reinforce that this is an engineered channel, not a colored stripe.
	for distance in range(0,int(rect.size.y if vertical else rect.size.x),25):
		if vertical:
			for x in [rect.position.x-4,rect.end.x+3]: c.draw_line(Vector2(x-2,rect.position.y+distance),Vector2(x+2,rect.position.y+distance),Color("393d32"),1)
		else:
			for y in [rect.position.y-4,rect.end.y+3]: c.draw_line(Vector2(rect.position.x+distance,y-2),Vector2(rect.position.x+distance,y+2),Color("393d32"),1)

static func _bridge(c: CanvasItem, rect: Rect2, horizontal: bool) -> void:
	c.draw_rect(rect.grow(3),Color("171f20"))
	c.draw_rect(rect,Color("8c876a"))
	# Stone blocks cross the flow. End ramps overlap intact floor on both banks.
	if horizontal:
		for x in range(int(rect.position.x)+4,int(rect.end.x)-2,14):
			c.draw_rect(Rect2(x,rect.position.y+4,11,rect.size.y-8),Color("aaa183"))
		for y in [rect.position.y+1,rect.end.y-2]: c.draw_line(Vector2(rect.position.x,y),Vector2(rect.end.x,y),Color("d2b97a"),3)
	else:
		for y in range(int(rect.position.y)+4,int(rect.end.y)-2,14):
			c.draw_rect(Rect2(rect.position.x+4,y,rect.size.x-8,11),Color("aaa183"))
		for x in [rect.position.x+1,rect.end.x-2]: c.draw_line(Vector2(x,rect.position.y),Vector2(x,rect.end.y),Color("d2b97a"),3)
	for point in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:
		c.draw_rect(Rect2(point-Vector2(3,3),Vector2(6,6)),Color("c6b27b"))

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
			var bite := 0.0 if i==0 else float(posmod(i*31+side*17+int(rect.position.x),12)-3)
			rim.append(a+direction*(i+stagger)/steps+inward*bite)
	c.draw_colored_polygon(rim,Color("77796a"))
	var opening := PackedVector2Array()
	for point in rim: opening.append(point.lerp(rect.get_center(),0.065)+Vector2(0,3))
	c.draw_colored_polygon(opening,Color("101a1c"))
	var depth := PackedVector2Array()
	for point in opening: depth.append(point.lerp(rect.get_center(),0.12)+Vector2(0,3))
	c.draw_colored_polygon(depth,Color("080e12"))
	# Uneven slab fractures continue onto the surrounding intact floor.
	for i in range(1,rim.size(),3):
		var point := rim[i]
		var outward := rect.get_center().direction_to(point)
		c.draw_line(point,point+outward*9,Color("202f2c"),2)
		c.draw_line(point+outward*9,point+outward.rotated(0.4)*16,Color("263632"),1)
		c.draw_line(point,point.lerp(rect.get_center(),0.07)+Vector2(0,3),Color("a5a18b"),1)

static func _socket(c: CanvasItem, rect: Rect2, lava: bool, drain: bool, clock: float) -> void:
	c.draw_rect(rect.grow(5),Color("9b8b65"))
	c.draw_rect(rect.grow(2),Color("4c5141"))
	c.draw_rect(rect,Color("172321"))
	var glow := Color("f49b3e") if lava else Color("60b99b")
	if drain:
		if lava:
			for x in range(int(rect.position.x)+5,int(rect.end.x),9): c.draw_line(Vector2(x,rect.position.y+2),Vector2(x,rect.end.y-2),Color("8a7751"),3)
		else:
			for y in range(int(rect.position.y)+5,int(rect.end.y),9): c.draw_line(Vector2(rect.position.x+2,y),Vector2(rect.end.x-2,y),Color("8a7751"),3)
	else:
		c.draw_rect(rect.grow(-5),Color(glow,0.45+sin(clock*3)*0.1))
		for i in range(3):
			var shift := fposmod(clock*22+i*9,rect.size.y-6)
			c.draw_line(rect.position+Vector2(7,3+shift),rect.position+Vector2(rect.size.x-7,3+shift),Color(glow,0.8),2)
