extends RefCounted
## Painted material tiles; clipped per tile so atlas neighbors cannot bleed into terrain.
const SHEET: Texture2D = preload("res://art/sanctuary/surfaces.png")
const KEYS := ["water","lava","chasm","bridge","capstone","wall","grate","mosaic"]
static var frames: Dictionary = {}
static func frame(key: String) -> AtlasTexture:
	if frames.has(key): return frames[key]
	var index := KEYS.find(key); assert(index>=0)
	var left := floori((index%4)*SHEET.get_width()/4.0)+3
	var top := floori(int(index/4)*SHEET.get_height()/2.0)+3
	var right := floori((index%4+1)*SHEET.get_width()/4.0)-3
	var bottom := floori((int(index/4)+1)*SHEET.get_height()/2.0)-3
	var texture := AtlasTexture.new(); texture.atlas = SHEET; texture.region = Rect2(left,top,right-left,bottom-top); texture.filter_clip = true
	frames[key] = texture; return texture
static func tile(c: CanvasItem, key: String, rect: Rect2, size: Vector2 = Vector2(48,48), phase: Vector2 = Vector2.ZERO, tint: Color = Color.WHITE) -> void:
	if not rect.has_area(): return
	var texture := frame(key)
	var origin := (rect.position/size).floor()*size+phase.posmodv(size)-size
	for y in range(int(ceil((rect.end.y-origin.y)/size.y))):
		for x in range(int(ceil((rect.end.x-origin.x)/size.x))):
			var cell := Rect2(origin+Vector2(x,y)*size,size)
			var visible := cell.intersection(rect)
			if not visible.has_area(): continue
			var uv := Rect2((visible.position-cell.position)/size*texture.get_size(),visible.size/size*texture.get_size())
			c.draw_texture_rect_region(texture,visible,uv,tint)
