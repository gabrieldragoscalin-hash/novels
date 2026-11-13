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
		"wall": m.set_shader_parameter("region",Vector4(0.5,0,0.5,0.5)); m.set_shader_parameter("mapping",1); m.set_shader_parameter("density",0.20); m.set_shader_parameter("tint",Color(1.08,1.18,1.22,1)); m.next_pass=outline()
		"relief": m.set_shader_parameter("region",Vector4(0,0.5,0.5,0.5)); m.set_shader_parameter("mapping",2)
		"medallion": m.set_shader_parameter("region",Vector4(0.5,0.5,0.5,0.5)); m.set_shader_parameter("mapping",2)
	cache[kind]=m; return m
