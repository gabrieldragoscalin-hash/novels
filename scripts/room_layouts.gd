extends RefCounted
## Authored architectural plans. Gaps are movement-only; props also stop shots.
const THEMES := ["Processional Hall", "Jade Sluice", "Fractured Crypt", "Collapsed Cloister", "Lava Aqueduct", "Sunken Courtyard"]
static func index(seed_value: int, cell: Vector2i) -> int:
	return posmod(seed_value+cell.x*7+cell.y*11,THEMES.size())
static func props(layout: int) -> Array:
	var pairs: Array
	match posmod(layout,6):
		0: pairs = [["statue",Rect2(95,258,42,30)],["statue",Rect2(343,258,42,30)],["pillar",Rect2(95,478,42,30)],["pillar",Rect2(343,478,42,30)]]
		1: pairs = [["brazier",Rect2(155,267,28,24)],["brazier",Rect2(297,267,28,24)],["urns",Rect2(95,475,38,28)],["urns",Rect2(347,475,38,28)]]
		2: pairs = [["tomb",Rect2(92,267,72,32)],["tomb",Rect2(316,267,72,32)],["tomb",Rect2(92,520,72,28)],["tomb",Rect2(316,520,72,28)]]
		3: pairs = [["statue",Rect2(335,265,42,30)],["statue",Rect2(103,475,42,30)]]
		4: pairs = [["brazier",Rect2(259,264,24,24)],["brazier",Rect2(378,264,24,24)],["brazier",Rect2(259,479,24,24)],["brazier",Rect2(378,479,24,24)]]
		_: pairs = [["urns",Rect2(105,245,38,28)],["urns",Rect2(337,245,38,28)],["statue",Rect2(95,500,42,30)],["statue",Rect2(343,500,42,30)]]
	var result: Array = []
	for pair in pairs: result.append({"key":pair[0],"rect":pair[1]})
	return result
static func obstacles(layout: int) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for entry in props(layout): result.append(entry["rect"])
	return result
static func prop(layout: int, ordinal: int) -> String: return props(layout)[ordinal]["key"]
static func terrain(layout: int) -> Array[Rect2]:
	var result: Array[Rect2] = []
	match posmod(layout,6):
		1: result.assign([Rect2(8,300,192,52),Rect2(280,300,192,52)])
		2: result.assign([Rect2(8,438,188,52),Rect2(284,438,188,52)])
		3: result.assign([Rect2(90,230,98,100),Rect2(292,440,98,100)])
		4: result.assign([Rect2(300,166,54,179),Rect2(300,425,54,179)])
		5: result.assign([Rect2(80,295,120,48),Rect2(280,295,120,48),Rect2(80,427,120,48),Rect2(280,427,120,48)])
	return result
static func bridges(layout: int) -> Array[Rect2]:
	var result: Array[Rect2] = []
	match posmod(layout,6):
		1: result.append(Rect2(200,292,80,68))
		2: result.append(Rect2(196,430,88,68))
		4: result.append(Rect2(292,345,70,80))
		5: result.assign([Rect2(200,287,80,64),Rect2(200,419,80,64)])
	return result
static func material(layout: int) -> String:
	return ["stone","water","chasm","chasm","lava","water"][posmod(layout,6)]
