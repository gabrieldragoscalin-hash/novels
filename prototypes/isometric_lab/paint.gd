extends RefCounted
const Stone = preload("res://prototypes/isometric_lab/stone.gdshader")
const Ink = preload("res://prototypes/isometric_lab/ink.gdshader")
static var cache: Dictionary={}
static var ink_material: ShaderMaterial
static func outline() -> ShaderMaterial:
	if ink_material==null:
		ink_material=ShaderMaterial.new(); ink_material.shader=Ink
	return ink_material
static func surface(kind: String) -> ShaderMaterial:
	if cache.has(kind): return cache[kind]
	var m:=ShaderMaterial.new(); m.shader=Stone
	m.set_shader_parameter("atlas",load("res://art/isometric/underworld_atlas.png"))
	match kind:
		"floor": m.set_shader_parameter("region",Vector4(0,0,0.5,0.5)); m.set_shader_parameter("density",0.16)
		"wall": m.set_shader_parameter("region",Vector4(0.5,0,0.5,0.5)); m.set_shader_parameter("mapping",1); m.set_shader_parameter("density",0.20); m.next_pass=outline()
		"relief": m.set_shader_parameter("region",Vector4(0,0.5,0.5,0.5)); m.set_shader_parameter("mapping",2)
		"medallion": m.set_shader_parameter("region",Vector4(0.5,0.5,0.5,0.5)); m.set_shader_parameter("mapping",2)
	if kind=="floor":
		m.set_shader_parameter("stone_shadow",Color("303943")); m.set_shader_parameter("stone_mid",Color("5f6a78")); m.set_shader_parameter("stone_high",Color("98a2ad")); m.set_shader_parameter("gold_amount",0.35)
	elif kind=="wall":
		m.set_shader_parameter("stone_shadow",Color("646568")); m.set_shader_parameter("stone_mid",Color("bcb6a6")); m.set_shader_parameter("stone_high",Color("e7dcc2")); m.set_shader_parameter("gold_amount",0.80)
	else:
		m.set_shader_parameter("stone_shadow",Color("414650")); m.set_shader_parameter("stone_mid",Color("bbb6aa")); m.set_shader_parameter("stone_high",Color("f2e4bf")); m.set_shader_parameter("gold_amount",1.0)
	cache[kind]=m; return m
