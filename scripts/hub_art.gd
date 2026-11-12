extends RefCounted
## Original painted home-screen assets; no external runtime downloads.
const TOWER: Texture2D = preload("res://art/hub/tower.png")
const BANNER: Texture2D = preload("res://art/hub/hell_banner.png")
const PARCHMENT: Texture2D = preload("res://art/hub/parchment.png")
const SHEET: Texture2D = preload("res://art/hub/icons.png")
const HERO: Texture2D = preload("res://art/champions/aster.png")
const SERIF: Font = preload("res://art/fonts/SanctuarySerif.ttf")
const Regions = preload("res://scripts/hub_art_regions.gd")
static var cache: Dictionary = {}
static func icon(kind: String) -> AtlasTexture:
	if cache.has(kind): return cache[kind]
	assert(Regions.FRAMES.has(kind))
	var bounds: Array = Regions.FRAMES[kind]
	var texture := AtlasTexture.new(); texture.atlas = SHEET
	texture.region = Rect2(bounds[0],bounds[1],bounds[2],bounds[3]); texture.filter_clip = true
	cache[kind] = texture
	return texture
static func portrait() -> AtlasTexture:
	if cache.has("portrait"): return cache["portrait"]
	var texture := AtlasTexture.new(); texture.atlas = HERO
	texture.region = Rect2(280,0,470,470); texture.filter_clip = true
	cache["portrait"] = texture
	return texture
static func cover(canvas: CanvasItem, texture: Texture2D, rect: Rect2, tint: Color = Color.WHITE) -> void:
	var ratio := maxf(rect.size.x/texture.get_width(),rect.size.y/texture.get_height())
	var source_size := rect.size/ratio
	canvas.draw_texture_rect_region(texture,rect,Rect2(Vector2((texture.get_width()-source_size.x)*0.5,0),source_size),tint)
