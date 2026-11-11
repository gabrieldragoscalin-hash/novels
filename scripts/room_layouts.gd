extends RefCounted
## Collision traced against the ten finished backgrounds (world-space feet).
## Gaps stop bodies, not projectiles; low masonry stops both.
const THEMES := ["Quiet Sanctuary", "Weathered Flagstones", "Broken Corners", "Split Crypt", "Jade Waterway", "Molten Aqueduct", "Drowned Court", "Ruined Cloister", "Twin Watercourses", "Ember Crossing"]
static func index(seed_value: int, cell: Vector2i) -> int:
	return posmod(seed_value+cell.x*7+cell.y*11,THEMES.size())
static func obstacles(layout: int) -> Array[Rect2]:
	# The thin side walls belong to the painting. Their apertures stay clear.
	var result: Array[Rect2] = [Rect2(8,166,16,187),Rect2(8,417,16,187),Rect2(456,166,16,187),Rect2(456,417,16,187)]
	if posmod(layout,10)==7: result.append_array([Rect2(110,282,80,34),Rect2(302,425,78,34)])
	return result
static func terrain(layout: int) -> Array[Rect2]:
	var result: Array[Rect2] = []
	match posmod(layout,10):
		2: result.assign([Rect2(90,246,103,86),Rect2(286,430,108,86)])
		3: result.assign([Rect2(8,420,176,54),Rect2(296,420,176,54)])
		4: result.assign([Rect2(8,308,176,52),Rect2(296,308,176,52)])
		5: result.assign([Rect2(306,166,48,176),Rect2(306,420,48,184)])
		6: result.assign([Rect2(86,254,118,78),Rect2(274,254,120,78),Rect2(86,414,118,86),Rect2(274,414,120,86)])
		8: result.assign([Rect2(134,218,44,110),Rect2(134,432,44,108),Rect2(302,218,44,110),Rect2(302,432,44,108)])
		9: result.assign([Rect2(8,420,176,44),Rect2(296,420,176,44)])
	return result
static func bridges(layout: int) -> Array[Rect2]:
	var result: Array[Rect2] = []
	match posmod(layout,10):
		3: result.append(Rect2(184,414,112,68))
		4: result.append(Rect2(184,300,112,66))
		5: result.append(Rect2(298,342,64,78))
		8: result.assign([Rect2(126,328,60,104),Rect2(294,328,60,104)])
		9: result.append(Rect2(184,412,112,62))
	return result
