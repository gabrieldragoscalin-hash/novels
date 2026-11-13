extends RefCounted
## Cached original Sanctuary glyphs; the reveal never allocates textures per frame.
const SHAPES := {
"damage":"M15 55 47 11 55 8 53 21 24 59M14 40l20 15M11 59l7 5",
"attack_speed":"m14 20 16 16-16 16m20-32 16 16-16 16M55 16v40",
"movement":"m16 52 12-26 12 8-5 15 19 5M27 25l14-13 15 10M12 35h10",
"experience":"m36 9 7 17 19 3-14 12 5 19-17-10-17 10 5-19-14-12 19-3Z",
"piercing":"M8 36h54M52 26l10 10-10 10M23 15v42m20-42v42",
"multishot":"M24 57V15m-8 10 8-10 8 10M48 57V15m-8 10 8-10 8 10",
"multiple_shots":"M10 24h45M45 15l11 9-11 9M18 48h45M53 39l11 9-11 9",
"ricochet":"m12 54 18-18 15 6 16-24M48 18h13v13M24 21a6 6 0 1 0 .1 0M42 52a6 6 0 1 0 .1 0",
"follow":"M10 57q5-38 36-28m-11-6 12 6-10 8M45 10a11 11 0 1 0 .1 0M45 14v14m-7-7h14",
"see_all":"M8 35q28-32 56 0-28 32-56 0ZM36 24a11 11 0 1 0 .1 0M18 11v11m0 27v12m36-50v11m0 27v12",
"arrow_split":"M36 61V31m0 0L13 13m23 18 23-18M36 31V9m-8 10 8-10 8 10M13 26V13h13m20 0h13v13",
"stop_aim":"M10 36h52M36 10v52M36 18a18 18 0 1 0 .1 0M36 31a5 5 0 1 0 .1 0",
"explosive":"m36 8 6 15 15-7-6 16 14 5-15 6 7 15-16-7-5 14-6-15-15 7 7-16-14-5 15-6-7-15 16 7Z",
"perpetuum":"M10 30h52M10 42h52M10 36h52M22 18l-9 18 9 18m28-36 9 18-9 18",
"meteor":"m10 15 14 16m-4-22 13 15m3-13 9 13M43 27a18 18 0 1 0 .1 0M38 35l9 7-5 10",
"vitality":"M36 59C13 45 9 31 19 22q10-8 17 6 8-14 18-6 11 10-18 37ZM36 30v20m-10-10h20",
"medicine":"M25 12h22v13h13v22H47v13H25V47H12V25h13Z",
"gatherer":"M17 13h12v29q7 12 14 0V13h12v30Q37 74 17 43ZM17 27h12m14 0h12M7 43h8m43 0h8",
"reach":"M12 35h48M23 23 11 35l12 12m26-24 12 12-12 12M16 15h40m-40 44h40",
"last_enemy":"M36 12a23 23 0 1 0 .1 0M36 22a13 13 0 1 0 .1 0M36 30v12m-6-6h12",
"momentum":"m40 9-25 31h20l-3 23 25-32H37Z",
"barrier":"m36 9 23 10-3 28-20 17-20-17-3-28ZM28 25h16v23H28Zm8-5v33",
"salvage":"M15 32h42v27H15ZM15 32l7-17h28l7 17M31 32v27h10V32M24 21h25",
"second_chance":"M56 29a23 23 0 1 0-1 21M56 29H43m13 0V16M36 49q-17-12-10-20 6-5 10 3 4-8 10-3 7 8-10 20Z",
"meteor_size":"M36 18a20 20 0 1 0 .1 0M36 24v25M24 36h25M8 9l10 1-1 10m47 43-10-1 1-10",
"meteor_rain":"M15 30a9 9 0 1 0 .1 0M35 43a11 11 0 1 0 .1 0M55 25a9 9 0 1 0 .1 0M10 10l7 12m15-5 7 17m10-27 6 10",
"telekinesis":"M23 29a15 15 0 1 0 .1 0M41 44h22m-9-8 9 8-9 8M13 24l8 9 10-8",
"coins":"M11 45a21 8 0 1 0 42 0M11 45v11q21 15 42 0V45M29 14a16 16 0 1 0 .1 0M28 21v17m-6-13h11m-11 8h11"}
static var cache: Dictionary = {}
static func texture(id: String) -> Texture2D:
	if cache.has(id): return cache[id]
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="72" height="72" viewBox="0 0 72 72"><circle cx="36" cy="36" r="33" fill="#1b3e31" stroke="#af965e"/><circle cx="36" cy="36" r="29" fill="none" stroke="#536d4f" stroke-width=".7"/><path d="%s" fill="none" stroke="#efd495" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>' % SHAPES.get(id,SHAPES["damage"])
	var image := Image.new(); image.load_svg_from_string(svg,3.0)
	cache[id] = ImageTexture.create_from_image(image)
	return cache[id]
