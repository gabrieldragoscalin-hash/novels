extends RefCounted
## Hand-validated quadrant patterns leave a 100px central cross and all four doors open.
const THEMES := ["Memorial", "Crypt", "Reliquary", "Barricade", "Root garden", "Fire court"]
static func index(seed_value: int, cell: Vector2i) -> int:
	return posmod(seed_value+cell.x*7+cell.y*11,6)
static func obstacles(layout: int) -> Array[Rect2]:
	var result: Array[Rect2] = []
	var patterns := [
		[Rect2(91,275,48,35),Rect2(337,453,48,35)],
		[Rect2(87,274,80,35),Rect2(313,453,80,35)],
		[Rect2(112,273,40,35),Rect2(327,273,40,35),Rect2(112,470,40,35)],
		[Rect2(75,290,102,22),Rect2(303,457,102,22)],
		[Rect2(105,278,58,35),Rect2(317,278,58,35),Rect2(317,463,58,35)],
		[Rect2(100,280,38,28),Rect2(342,280,38,28),Rect2(100,465,38,28),Rect2(342,465,38,28)]
	]
	for rect in patterns[posmod(layout,6)]: result.append(rect)
	return result
static func prop(layout: int, ordinal: int) -> String:
	return [["statue","pillar"],["tomb","tomb"],["urns","statue","urns"],["barricade","barricade"],["roots","roots","statue"],["brazier","brazier","brazier","brazier"]][posmod(layout,6)][ordinal]
