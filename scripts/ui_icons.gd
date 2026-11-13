extends RefCounted
## Original SVG menu doodles, generated locally; no external art dependency.
const Extensions = preload("res://scripts/weapon_extensions_art.gd")
static var cache: Dictionary = {}

static func texture(kind: String) -> Texture2D:
	if kind in ["spear","dual_axe","club"]: return Extensions.frame("weapon_"+kind)
	if cache.has(kind): return cache[kind]
	var shapes := ""
	match kind:
		"dungeon": shapes = '<path stroke="#436876" d="M2 55 L10 39 18 48 26 31 39 46 51 35 62 55 M4 59 H60"/><circle cx="49" cy="12" r="7" fill="#24434b"/><path fill="#203c47" d="M13 51 V24 H25 V51 M39 51 V24 H51 V51 M10 24 V15 H15 V19 H20 V15 H25 V24 M39 24 V15 H44 V19 H49 V15 H54 V24 M25 50 V28 H39 V50 M27 28 V21 H37 V28"/><path fill="#0b1a25" d="M27 51 V41 Q32 31 37 41 V51 Z"/><path d="M17 30 V35 M45 30 V35 M31 25 H33 M32 37 V51 M25 60 L29 53 H36 L40 60 M5 50 L8 43 11 50 M54 50 L57 42 60 50"/>'
		"weapon", "bow": shapes = '<path d="M19 9 Q57 32 19 55 L31 32 Z M9 32 H54 M47 26 L54 32 47 38"/>'
		"crossbow": shapes = '<path d="M13 19 Q32 7 51 19 M12 20 L32 29 52 20 M32 12 V56 M25 43 H39 M28 55 H36"/>'
		"wand": shapes = '<path d="M15 54 L39 23 M40 9 L44 17 54 18 46 25 48 35 39 30 30 35 32 25 25 18 35 16 Z"/>'
		"sword": shapes = '<path d="M12 53 L45 10 53 7 52 19 22 57 M13 39 L31 53 M10 56 L17 61"/>'
		"hammer": shapes = '<path d="M15 54 L40 22 M22 12 L34 4 55 24 45 36 Z M27 17 L46 31"/>'
		"chakram": shapes = '<circle cx="32" cy="32" r="25"/><circle cx="32" cy="32" r="14"/><path d="M10 20 L24 21 M44 10 L43 24 M54 44 L40 43 M20 54 L21 40"/>'
		"armor", "vest": shapes = '<path d="M22 10 L13 17 8 29 19 34 19 54 H46 V34 L56 29 51 17 42 10 Q32 23 22 10 Z M32 24 V48"/>'
		"headgear", "hood": shapes = '<path d="M13 49 V28 Q14 6 32 7 Q51 9 52 29 V49 L42 54 32 47 22 54 Z M21 34 Q21 20 32 18 Q43 20 43 34 L32 41 Z"/>'
		"pants": shapes = '<path d="M16 10 H48 L46 55 H34 L31 30 28 55 H16 Z M17 19 H47"/>'
		"boots": shapes = '<path d="M17 9 H32 V40 L45 46 V55 H12 V43 L17 38 Z M22 17 H29 M22 25 H29 M22 33 H29"/>'
		"necklace", "charm": shapes = '<path d="M12 10 Q8 40 32 43 Q56 40 52 10 M32 39 L22 49 32 59 42 49 Z M32 44 V53"/>'
		"ring": shapes = '<circle cx="32" cy="39" r="16"/><path d="M20 15 L26 7 H38 L44 15 32 29 Z M20 15 H44 M26 7 L32 29 38 7"/>'
		"bracelet": shapes = '<ellipse cx="32" cy="33" rx="23" ry="14"/><path d="M9 32 V43 Q32 61 55 43 V32 M20 34 V48 M44 34 V48 M27 26 H37 V38 H27 Z"/>'
		"shop": shapes = '<path d="M10 23 L16 10 H48 L54 23 V29 Q49 36 43 29 Q37 36 32 29 Q26 36 21 29 Q15 36 10 29 Z M15 34 V56 H49 V34 M26 56 V41 H38 V56"/>'
		"inventory": shapes = '<path d="M16 24 V17 Q32 2 48 17 V24 M11 24 H53 V57 H11 Z M24 24 V17 H40 V24 M20 37 H44 V49 H20 Z"/>'
		"perks": shapes = '<path d="M32 5 L39 23 59 25 43 38 48 58 32 47 16 58 21 38 5 25 25 23 Z"/>'
		"miscellaneous": shapes = '<circle cx="16" cy="32" r="4"/><circle cx="32" cy="32" r="4"/><circle cx="48" cy="32" r="4"/>'
		"lock", "pet", "spirit": shapes = '<rect x="14" y="27" width="36" height="29" rx="5"/><path d="M22 27 V18 Q32 3 42 18 V27 M32 37 V46"/>'
		_: shapes = '<path d="M17 48 L32 16 47 48 Z"/>'
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><g fill="none" stroke="#e6c57d" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">%s</g></svg>' % shapes
	if kind == "dungeon": svg = svg.replace('stroke-width="3"', 'stroke-width="1.8"')
	var image := Image.new()
	image.load_svg_from_string(svg, 5.0 if kind == "dungeon" else 1.0)
	var result := ImageTexture.create_from_image(image)
	cache[kind] = result
	return result
