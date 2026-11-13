extends Node2D
const Art = preload("res://scripts/game_art.gd")
const Effects = preload("res://scripts/attack_renderer.gd")
const Plans = preload("res://prototypes/room_lab/layouts.gd")
var lab_ref: WeakRef
var lab:
	get: return lab_ref.get_ref()
func _draw() -> void:
	if lab==null or lab.combat==null: return
	var combat=lab.combat
	for pickup in combat.pickups:
		var pos: Vector2=pickup["pos"]
		draw_colored_polygon(PackedVector2Array([pos+Vector2(0,-7),pos+Vector2(5,0),pos+Vector2(0,7),pos+Vector2(-5,0)]),Color("99daca"))
	var exit: Vector2=lab.plan["exit"]
	var unlocked: bool=lab.remaining()==0
	draw_circle(exit,43,Color(0.9,0.7,0.3,0.16))
	draw_arc(exit,42,0,TAU,40,Color("ffe1a2") if unlocked else Color("907754"),3)
	for side in [-1,1]:
		column(Rect2(exit+Vector2(side*48-12,-5),Vector2(24,24)))
	draw_line(exit+Vector2(-48,-65),exit+Vector2(48,-65),Color("c7a368"),12)
	draw_string(ThemeDB.fallback_font,exit+Vector2(-58,-83),"EXIT" if unlocked else "CLEAR ALL PACKS",HORIZONTAL_ALIGNMENT_CENTER,116,11,Color("e5d0a0"))
	var shrine: Vector2=lab.plan["shrine"]
	draw_circle(shrine,26,Color("243e37")); draw_arc(shrine,27,0,TAU,32,Color("7bafa0"),3)
	draw_string(ThemeDB.fallback_font,shrine+Vector2(-8,7),"+",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("536959") if lab.shrine_used else Color("a1e9bb"))
	var drawables: Array=[{"y":lab.player.y,"hero":true}]
	for cover in lab.plan["cover"]: drawables.append({"y":cover.get_center().y,"cover":cover})
	for enemy in combat.enemies:
		if enemy["hp"]>0: drawables.append({"y":enemy["pos"].y,"enemy":enemy})
	drawables.sort_custom(func(a,b): return a["y"]<b["y"])
	for item in drawables:
		if item.has("cover"): column(item["cover"])
		elif item.has("hero"):
			draw_arc(lab.player,16,0,TAU,24,Color("9bddb5"),2)
			if combat.hurt_time<=0 or int(lab.clock*12)%2==0: lab.hero.draw(self,lab.player)
		else: enemy(item["enemy"])
	for enemy in combat.enemies:
		if enemy["hp"]>0 and not enemy.get("dormant",false) and enemy.get("telegraph",0)>0:
			var origin: Vector2=enemy["pos"]
			draw_line(origin,origin+enemy.get("aim",Vector2.UP)*220,Color(1,0.5,0.2,0.6),3)
	for hazard in combat.hazards:
		draw_arc(hazard["pos"],hazard["radius"],0,TAU,32,Color("ffb36d"),3)
	for bullet in combat.hostile_bullets:
		Effects._stamp(self,"magic",fposmod(lab.clock*5,1),bullet["pos"]+Vector2(0,-16),Vector2(32,22),Vector2(0.85,0.62),bullet["velocity"].angle(),Color(1.5,0.45,0.35))
	Effects.draw_projectiles(self,combat.bullets,lab.clock,lab.player,lab.hero.muzzle)
	# Renderer receives world bounds explicitly, leaving the main dungeon's defaults intact.
	Effects.draw_effects(self,combat.arsenal,combat.impacts,lab.clock,lab.player,lab.hero.muzzle,Plans.BOUNDS)
	if lab.overview:
		for court in lab.plan["courts"]:
			draw_string(ThemeDB.fallback_font,court["rect"].get_center()+Vector2(-170,-80),court["name"],HORIZONTAL_ALIGNMENT_CENTER,340,36,Color("fff0c6"))
		for group in lab.groups:
			var alive: int=group["enemies"].filter(func(e): return e["hp"]>0).size()
			if alive>0: draw_string(ThemeDB.fallback_font,group["rect"].get_center()+Vector2(-100,70),"%d enemies" % alive,HORIZONTAL_ALIGNMENT_CENTER,200,30,Color("e9a28e"))
func enemy(value: Dictionary) -> void:
	var pos: Vector2=value["pos"]; var kind: String=value["kind"]
	var height: float=58.0 if kind=="brute" else (50.0 if kind=="shooter" else 46.0)
	var frame:=int(float(value.get("walk_distance",0))/12)%2
	if value.get("telegraph",0)>0: frame=2
	elif value.get("phase","")=="charge" or value.get("cast_time",0)>0: frame=3
	var texture: Texture2D=Art.frame(kind+"_"+str(frame))
	var width: float=height*texture.get_width()/texture.get_height()
	var tint:=Color("5d726c") if value.get("dormant",false) else Color.WHITE
	if value.get("flash",0)>0: tint=Color(1.5,1.3,1.1)
	draw_set_transform(pos+Vector2(0,2),0,Vector2(1,0.35)); draw_circle(Vector2.ZERO,15,Color(0,0,0,0.4)); draw_set_transform(Vector2.ZERO)
	draw_texture_rect(texture,Rect2(pos-Vector2(width/2,height),Vector2(width,height)),false,tint)
	if not value.get("dormant",false):
		draw_rect(Rect2(pos+Vector2(-17,-height-6),Vector2(34,3)),Color("182521"))
		draw_rect(Rect2(pos+Vector2(-17,-height-6),Vector2(34*value["hp"]/value["max_hp"],3)),Color("dca477"))
func column(foot: Rect2) -> void:
	var alpha:=0.55 if lab.player.y<foot.end.y and lab.player.y>foot.position.y-65 and absf(lab.player.x-foot.get_center().x)<45 else 1.0
	var rect:=foot
	draw_rect(rect.grow(4),Color(0,0,0,0.3*alpha))
	if foot.size.x>=40:
		var texture: Texture2D=Art.frame("cover_block")
		var dimensions:=Vector2(foot.size.x+10,(foot.size.x+10)*texture.get_height()/texture.get_width())
		draw_texture_rect(texture,Rect2(Vector2(foot.get_center().x-dimensions.x/2,foot.end.y-dimensions.y),dimensions),false,Color(1,1,1,alpha))
		return
	var top:=rect.position+Vector2(0,-42)
	draw_rect(Rect2(top,rect.size+Vector2(0,42)),Color("495244",alpha))
	draw_rect(Rect2(top,rect.size),Color("a09a73",alpha))
	draw_line(top,top+Vector2(rect.size.x,0),Color("e4c98a",alpha),3)
	draw_line(rect.position+Vector2(5,0),rect.position+Vector2(5,-37),Color("7d7b56",alpha),3)
	draw_rect(Rect2(top+Vector2(7,6),rect.size-Vector2(14,12)),Color("50634e",alpha))
