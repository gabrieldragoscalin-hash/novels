extends RefCounted
## Bounded sprite work independent of the number of damage entities.
const NewWeapons = preload("res://scripts/weapon_extensions_art.gd")
const Vfx = preload("res://scripts/attack_vfx.gd")
const BOUNDS := Rect2(8,166,464,438)
const MAX_METEORS := 24
const MAX_PROJECTILES := 48
const MAX_ROCKS := 24
const MAX_EFFECTS := 48
const MAX_IMPACTS := 24
static var last_counts: Dictionary = {}

static func projectile_samples(bullets: Array) -> Array:
	var result: Array = []; var cells := {}; var total_rocks := 0
	for bullet in bullets:
		if bullet.get("kind","")=="rolling_meteor": total_rocks += 1
		elif result.size()<MAX_PROJECTILES: result.append(bullet)
	var rocks := 0
	for bullet in bullets:
		if bullet.get("kind","")!="rolling_meteor": continue
		if total_rocks>MAX_ROCKS:
			var cell := Vector2i((bullet["pos"]/26.0).floor())
			if cells.has(cell): continue
			cells[cell] = true
		result.append(bullet); rocks += 1
		if rocks>=MAX_ROCKS: break
	return result

static func meteor_samples(meteors: Array) -> Array:
	if meteors.size()<=MAX_METEORS: return meteors
	var result: Array = []; var cells := {}
	for meteor in meteors:
		var cell := Vector2i((meteor["pos"]/26.0).floor())
		if cells.has(cell): continue
		cells[cell] = true; result.append(meteor)
		if result.size()>=MAX_METEORS: break
	return result

static func draw_projectiles(c: CanvasItem, bullets: Array, clock: float, player: Vector2, muzzle: Vector2) -> void:
	var samples := projectile_samples(bullets)
	last_counts["projectiles"] = samples.size()
	for bullet in samples:
		var offset := Vector2(0,-16)
		if bullet.get("art_from_player",false):
			if not bullet.has("art_offset"): bullet["art_offset"] = muzzle-player
			var travel: float = bullet["art_launch"].distance_to(bullet["pos"])/bullet["art_distance"]
			bullet["art_progress"] = maxf(bullet.get("art_progress",0.0),clampf(travel,0,1))
			offset = bullet["art_offset"].lerp(offset,bullet["art_progress"])
		var pos: Vector2 = bullet["pos"]+offset
		var kind: String = bullet.get("kind","bow")
		var angle: float = bullet["velocity"].angle()
		if kind=="spear":
			var spear: Texture2D = NewWeapons.frame("weapon_spear")
			c.draw_set_transform(pos,angle+PI/2)
			c.draw_texture_rect(spear,Rect2(-5,-28,10,56),false)
			c.draw_set_transform(Vector2.ZERO)
			continue
		var size := Vector2(38,20)
		var clip := "arrow"
		var anchor := Vector2(0.87,0.62)
		var tint := Color.WHITE
		match kind:
			"sword_wave": clip = "slash"; size = Vector2(48,52); anchor = Vector2(0.5,0.5)
			"crossbow": clip = "bolt"; size = Vector2(47,25)
			"wand": clip = "magic"; size = Vector2(60,31)
			"chakram": clip = "chakram"; size = Vector2(30,30); anchor = Vector2(0.5,0.5); angle = clock*13
			"rolling_meteor": clip = "rock"; size = Vector2.ONE*bullet.get("radius",17.0)*2.1; anchor = Vector2(0.5,0.5); angle = clock*3
		if bullet.get("charged",false): size *= 1.6
		if bullet.get("explosive",false): tint = Color(1.1,0.76,0.48)
		_stamp(c,clip,fposmod(clock*5,1.0),pos,size,anchor,angle,tint)

static func draw_effects(c: CanvasItem, arsenal, impacts: Array, clock: float, player: Vector2, muzzle: Vector2, bounds: Rect2 = BOUNDS) -> void:
	var meteors := meteor_samples(arsenal.meteors)
	last_counts["meteors"] = meteors.size()
	for meteor in meteors:
		var pos: Vector2 = meteor["pos"]
		var radius: float = meteor["radius"]
		var duration: float = meteor.get("duration",0.45)
		var remaining: float = clampf(meteor["delay"]/duration,0,1)
		# A painted ignition on the floor marks the exact landing point.
		_clipped(c,Vfx.frame("explosion",0),Rect2(pos-Vector2.ONE*radius,Vector2.ONE*radius*2),Color(1,0.7,0.4,0.3),bounds)
		var altitude := 175*pow(remaining,0.8)
		var core := pos+Vector2(-altitude*0.35,-12-altitude)
		var size := Vector2.ONE*radius*3.4
		_clipped(c,Vfx.at("meteor",fposmod(clock*6,1)),Rect2(core-size*Vector2(0.72,0.76),size),Color.WHITE,bounds)
	var drawn := 0; var cells := {}
	for i in range(arsenal.effects.size()-1,-1,-1):
		var effect: Dictionary = arsenal.effects[i]
		var kind: String = effect["kind"]
		var age: float = 1.0-effect["life"]/effect["duration"]
		var cell := Vector2i((effect["pos"]/22.0).floor())
		var key := kind+str(cell)+str(int(age*3))
		if kind=="laser": key = "laser"+str(Vector2i((effect["pos"]/6.0).floor()))+str(Vector2i((effect["end"]/10.0).floor()))
		if kind in ["explosion","laser"] and cells.has(key): continue
		cells[key] = true
		var pos: Vector2 = effect["pos"]+Vector2(0,-16)
		if effect.get("circular",false) and kind in ["slash","wave"]:
			for segment in range(4): _stamp(c,kind,age,pos,Vector2(effect["radius"],effect["radius"]*1.3),Vector2(0.05,0.58),segment*PI/2,Color.WHITE)
			drawn += 1
			if drawn>=MAX_EFFECTS: break
			continue
		match kind:
			"arcane_patch": _stamp(c,"explosion",fposmod(age*2,1),pos,Vector2.ONE*effect["radius"]*2,Vector2(0.5,0.5),0,Color(0.4,1,0.7,0.45))
			"fissure": _stamp(c,"wave",age,pos,Vector2(effect["radius"]*2.5,28),Vector2(0.5,0.5),effect["direction"].angle(),Color(0.9,0.7,0.45,0.7))
			"explosion":
				_stamp(c,"explosion",age,pos,Vector2.ONE*effect["radius"]*2.25,Vector2(0.5,0.5),0,Color(1,1,1,0.9*minf(1,(1-age)*5)))
			"laser":
				if effect["pos"].distance_to(player)<24: pos = muzzle
				var end: Vector2 = effect["end"]+Vector2(0,-16)
				_stamp(c,"laser",fposmod(clock*6,1),pos,Vector2(pos.distance_to(end),48),Vector2(0,0.5),pos.angle_to_point(end),Color(1,1,1,minf(1,effect["life"]/0.05)))
				_stamp(c,"hit",fposmod(clock*7,1),end,Vector2(26,26),Vector2(0.5,0.5),0,Color(0.55,1,0.85))
			"slash":
				var size := Vector2(effect["radius"]*1.15,effect["radius"]*1.6)
				_stamp(c,"slash",age,pos,size,Vector2(0.05,0.58),effect["direction"].angle(),Color(1,1,1,minf(1,(1-age)*5)),effect.get("reverse",false))
			"wave":
				var size := Vector2(effect["radius"]*1.1,2*effect["radius"]*sin(effect["angle"]))
				_stamp(c,"wave",age,pos,size,Vector2(0.05,0.68),effect["direction"].angle(),Color(1,1,1,minf(1,(1-age)*5)))
		drawn += 1
		if drawn>=MAX_EFFECTS: break
	last_counts["effects"] = drawn
	var count := mini(impacts.size(),MAX_IMPACTS)
	for i in range(count):
		var impact: Dictionary = impacts[impacts.size()-1-i]
		_stamp(c,"hit",1-impact["life"]/0.22,impact["pos"]+Vector2(0,-16),Vector2(32,32),Vector2(0.5,0.5),0,Color.WHITE)
	last_counts["impacts"] = count

static func _stamp(c: CanvasItem, clip: String, progress: float, pos: Vector2, size: Vector2, anchor: Vector2, angle: float, tint: Color, reverse: bool = false) -> void:
	c.draw_set_transform(pos,angle,Vector2(1,-1 if reverse else 1))
	c.draw_texture_rect(Vfx.at(clip,progress),Rect2(-size*anchor,size),false,tint)
	c.draw_set_transform(Vector2.ZERO)

static func _clipped(c: CanvasItem, texture: Texture2D, rect: Rect2, tint: Color, bounds: Rect2 = BOUNDS) -> void:
	var visible := rect.intersection(bounds)
	if not visible.has_area(): return
	var source := Rect2((visible.position-rect.position)/rect.size*texture.get_size(),visible.size/rect.size*texture.get_size())
	c.draw_texture_rect_region(texture,visible,source,tint)
