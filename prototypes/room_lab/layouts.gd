extends RefCounted
## Editable floor plans: courts and their connecting causeways are the floor itself.
const CELL := 56.0
const GRID := Vector2i(28,34)
const BOUNDS := Rect2(0,0,1568,1904)
const NAMES := ["The Processional Steps", "The Broken Forum", "Cinder Causeways"]
static func center(cell: Vector2i) -> Vector2: return (Vector2(cell)+Vector2(0.5,0.5))*CELL
static func make(index: int) -> Dictionary:
	var plan := {"index":posmod(index,3),"name":NAMES[posmod(index,3)],"cells":{},"bridges":{},"courts":[],"cover":[],"start":center(Vector2i(12,29)),"exit":center(Vector2i(13,3)),"shrine":center(Vector2i(23,20))}
	match posmod(index,3):
		0:
			court(plan,Rect2i(9,23,8,8),"Arrival",Vector2i(13,25))
			court(plan,Rect2i(2,16,8,9),"West cloister",Vector2i(5,19))
			court(plan,Rect2i(7,6,14,8),"Crown approach",Vector2i(14,10))
			court(plan,Rect2i(20,17,6,11),"Ember gallery",Vector2i(23,22))
			court(plan,Rect2i(10,2,8,5),"The threshold",Vector2i(13,4),false)
			for rect in [Rect2i(5,23,5,3),Rect2i(7,12,3,7),Rect2i(16,25,7,3),Rect2i(18,12,3,8)]: bridge(plan,rect)
			covers(plan,[Vector2i(10,24),Vector2i(15,27),Vector2i(4,18),Vector2i(7,21),Vector2i(10,8),Vector2i(17,11),Vector2i(23,24)])
		1:
			court(plan,Rect2i(6,22,13,9),"Arrival court",Vector2i(12,25))
			court(plan,Rect2i(2,9,10,8),"West gallery",Vector2i(6,12))
			court(plan,Rect2i(16,9,10,8),"East gallery",Vector2i(21,12))
			court(plan,Rect2i(7,5,14,5),"The broken forum",Vector2i(13,7))
			court(plan,Rect2i(11,2,7,4),"The threshold",Vector2i(13,3),false)
			for rect in [Rect2i(3,12,4,13),Rect2i(18,12,4,13),Rect2i(10,13,8,3),Rect2i(7,8,3,3),Rect2i(18,8,3,3)]: bridge(plan,rect)
			plan["shrine"] = center(Vector2i(3,11))
			covers(plan,[Vector2i(8,24),Vector2i(16,27),Vector2i(4,13),Vector2i(9,11),Vector2i(18,12),Vector2i(23,14),Vector2i(11,7),Vector2i(17,7)])
		2:
			court(plan,Rect2i(9,25,9,7),"Arrival island",Vector2i(13,27))
			court(plan,Rect2i(19,18,8,10),"Furnace court",Vector2i(23,22))
			court(plan,Rect2i(15,8,11,7),"Ashen crossing",Vector2i(20,11))
			court(plan,Rect2i(2,6,10,12),"The old sanctuary",Vector2i(7,11))
			court(plan,Rect2i(4,1,10,5),"The threshold",Vector2i(7,3),false)
			for rect in [Rect2i(16,25,7,3),Rect2i(22,13,3,7),Rect2i(8,10,9,3),Rect2i(5,3,3,5),Rect2i(5,27,5,3),Rect2i(3,15,4,14)]: bridge(plan,rect)
			plan["exit"] = center(Vector2i(7,2)); plan["shrine"] = center(Vector2i(24,10))
			covers(plan,[Vector2i(11,27),Vector2i(16,29),Vector2i(21,21),Vector2i(24,25),Vector2i(17,10),Vector2i(23,12),Vector2i(5,9),Vector2i(9,14)])
	return plan
static func court(plan: Dictionary, rect: Rect2i, title: String, encounter: Vector2i, fight: bool = true) -> void:
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x):
			# Chamfered corners read as architecture, not one enclosing rectangle.
			if x in [rect.position.x,rect.end.x-1] and y in [rect.position.y,rect.end.y-1]: continue
			plan["cells"][Vector2i(x,y)] = true
	plan["courts"].append({"rect":Rect2(Vector2(rect.position)*CELL,Vector2(rect.size)*CELL),"name":title,"center":center(encounter),"fight":fight})
static func bridge(plan: Dictionary, rect: Rect2i) -> void:
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x):
			var cell := Vector2i(x,y)
			if not plan["cells"].has(cell): plan["bridges"][cell] = true
			plan["cells"][cell] = true
static func covers(plan: Dictionary, cells: Array) -> void:
	for cell in cells: plan["cover"].append(Rect2(center(cell)-Vector2(23,16),Vector2(46,32)))
