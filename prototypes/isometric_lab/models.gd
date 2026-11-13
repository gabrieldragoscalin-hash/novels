extends RefCounted
## Original low-poly test models, built from shared meshes and reusable attachment points.
static var materials: Dictionary = {}
static func material(hex: String, glow: bool = false) -> StandardMaterial3D:
	var key:=hex+str(glow)
	if materials.has(key): return materials[key]
	var m:=StandardMaterial3D.new(); m.albedo_color=Color(hex); m.roughness=0.9
	if glow: m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; m.emission_enabled=true; m.emission=Color(hex)
	materials[key]=m; return m
static func mesh(parent: Node3D, shape: Mesh, pos: Vector3, color: String, glow: bool = false) -> MeshInstance3D:
	var n:=MeshInstance3D.new(); n.mesh=shape; n.position=pos; n.material_override=material(color,glow); parent.add_child(n); return n
static func box(parent: Node3D, pos: Vector3, size: Vector3, color: String, glow: bool = false) -> MeshInstance3D:
	var shape:=BoxMesh.new(); shape.size=size; return mesh(parent,shape,pos,color,glow)
static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: String, top: float = -1) -> MeshInstance3D:
	var shape:=CylinderMesh.new(); shape.top_radius=radius if top<0 else top; shape.bottom_radius=radius; shape.height=height; shape.radial_segments=8
	return mesh(parent,shape,pos,color)
static func orb(parent: Node3D, pos: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var shape:=SphereMesh.new(); shape.radius=0.5; shape.height=1; shape.radial_segments=8; shape.rings=4
	var n:=mesh(parent,shape,pos,color); n.scale=size; return n
static func pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var n:=Node3D.new(); n.position=pos; parent.add_child(n); return n
static func segment(parent: Node3D, pos: Vector3, length: float, width: float, color: String) -> void:
	cylinder(parent,pos,width,length,color,width*0.8)
static func hero() -> Dictionary:
	var root:=Node3D.new(); root.name="Aster3D"
	var body:=pivot(root,Vector3.ZERO)
	# Bronze cuirass, ivory tunic, leather belt and crimson skirt panels.
	cylinder(body,Vector3(0,1.34,0),0.37,0.66,"bc8a4c",0.43).scale.z=0.68
	box(body,Vector3(0,1.35,-0.27),Vector3(0.46,0.37,0.06),"e0b26b")
	box(body,Vector3(0,1.47,-0.315),Vector3(0.08,0.41,0.03),"efe0ae")
	cylinder(body,Vector3(0,0.98,0),0.36,0.13,"483134").scale.z=0.72
	for i in range(7):
		var a:=i*TAU/7
		var skirt:=box(body,Vector3(sin(a)*0.30,0.79,cos(a)*0.24),Vector3(0.23,0.35,0.10),"9f3945" if i%2==0 else "c39a59")
		skirt.rotation.y=a
	orb(body,Vector3(0,1.94,0),Vector3(0.44,0.52,0.42),"d7a16f")
	orb(body,Vector3(0,2.10,0.035),Vector3(0.48,0.28,0.46),"332b31")
	box(body,Vector3(0,1.97,-0.215),Vector3(0.30,0.055,0.025),"4b3030")
	for side in [-1,1]:
		orb(body,Vector3(side*0.085,1.96,-0.233),Vector3(0.038,0.035,0.025),"17272a")
		for i in range(3): orb(body,Vector3(side*(0.13+i*0.025),2.08, -0.13+i*0.07),Vector3(0.12,0.06,0.05),"ead18a")
	var cape:=pivot(body,Vector3(0,1.64,0.21))
	var cloth:=SurfaceTool.new(); cloth.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in [Vector3(-0.29,0,0),Vector3(0.29,0,0),Vector3(-0.48,-1.05,0.27),Vector3(0.29,0,0),Vector3(0.48,-1.05,0.27),Vector3(-0.48,-1.05,0.27)]: cloth.set_normal(Vector3.BACK); cloth.add_vertex(v)
	var cloth_mesh:=MeshInstance3D.new(); cloth_mesh.mesh=cloth.commit()
	var cloth_mat:=material("b43d50").duplicate(); cloth_mat.cull_mode=BaseMaterial3D.CULL_DISABLED; cloth_mesh.material_override=cloth_mat; cape.add_child(cloth_mesh)
	var legs: Array=[]; var arms: Array=[]
	for side in [-1,1]:
		var leg:=pivot(root,Vector3(side*0.18,0.98,0)); legs.append(leg)
		segment(leg,Vector3(0,-0.22,0),0.42,0.12,"d4ad80")
		var shin:=pivot(leg,Vector3(0,-0.43,0)); leg.set_meta("shin",shin)
		segment(shin,Vector3(0,-0.20,0),0.40,0.11,"b49352")
		box(shin,Vector3(0,-0.47,-0.07),Vector3(0.23,0.15,0.39),"4c3932")
		var arm:=pivot(body,Vector3(side*0.42,1.62,0)); arms.append(arm)
		orb(arm,Vector3.ZERO,Vector3(0.31,0.24,0.32),"dfb571")
		segment(arm,Vector3(0,-0.20,0),0.39,0.10,"d4a478")
		var fore:=pivot(arm,Vector3(0,-0.38,0)); arm.set_meta("fore",fore)
		segment(fore,Vector3(0,-0.16,0),0.33,0.09,"d4a478")
		cylinder(fore,Vector3(0,-0.22,0),0.105,0.12,"bb995b")
		var hand:=pivot(fore,Vector3(0,-0.35,0)); orb(hand,Vector3.ZERO,Vector3(0.20,0.19,0.19),"ddb17f"); arm.set_meta("hand",hand)
	return {"root":root,"body":body,"legs":legs,"arms":arms,"cape":cape,"mount":arms[1].get_meta("hand")}
static func equip(rig: Dictionary, kind: String) -> void:
	var mount: Node3D=rig["mount"]
	for child in mount.get_children():
		if child.name=="Weapon": mount.remove_child(child); child.queue_free()
	var weapon:=pivot(mount,Vector3.ZERO); weapon.name="Weapon"
	if kind=="sword":
		cylinder(weapon,Vector3.ZERO,0.045,0.28,"694334")
		box(weapon,Vector3(0,0.17,0),Vector3(0.32,0.055,0.09),"e0b971")
		box(weapon,Vector3(0,0.67,0),Vector3(0.12,0.96,0.055),"dfe7d4")
		cylinder(weapon,Vector3(0,1.20,0),0.065,0.16,"f4dfaa",0).rotation.z=0
		orb(weapon,Vector3(0,-0.18,0),Vector3.ONE*0.13,"6ea99b")
	else:
		cylinder(weapon,Vector3(0,0.45,0),0.038,2.45,"755138")
		cylinder(weapon,Vector3(0,1.90,0),0.14,0.50,"e4d6ac",0)
		cylinder(weapon,Vector3(0,1.64,0),0.065,0.14,"dbac63")
		box(weapon,Vector3(0,1.48,0),Vector3(0.045,0.28,0.32),"b83e4a")
static func pose(rig: Dictionary, time: float, moving: float, attack: float, kind: String) -> void:
	var stride:=sin(time*13)*moving
	rig["body"].position.y=absf(stride)*0.045
	rig["body"].rotation.y=sin(attack*PI)*0.35 if attack>0 else 0
	for i in range(2):
		var leg: Node3D=rig["legs"][i]; leg.rotation.x=stride*(0.55 if i==0 else -0.55)
		leg.get_meta("shin").rotation.x=maxf(0,-stride*(0.60 if i==0 else -0.60))
	var main: Node3D=rig["arms"][1]; var off: Node3D=rig["arms"][0]
	main.rotation=Vector3(-0.55,-0.15,-0.13); main.get_meta("fore").rotation.x=-0.6
	off.rotation=Vector3(stride*0.32,0,0.14); off.get_meta("fore").rotation.x=-0.15
	if attack>0:
		main.rotation.x=-1.3-sin(attack*PI)*0.35
		main.rotation.z=lerpf(-1.05,0.65,attack) if kind=="sword" else -0.15
		main.get_meta("fore").rotation.x=-0.3
	if kind=="spear" and attack<=0: main.rotation.x=-0.75
	rig["cape"].rotation.x=-0.12-moving*0.35+sin(time*6)*0.055
static func shade(parent: Node3D, pos: Vector3, brute: bool = false) -> Dictionary:
	var root:=pivot(parent,pos); var size:=1.25 if brute else 1.0
	var body:=cylinder(root,Vector3(0,0.8,0),0.43,1.30,"405668",0.30)
	body.scale.z=0.72
	orb(root,Vector3(0,1.58,0),Vector3(0.50,0.50,0.42),"273a4e")
	box(root,Vector3(0,1.59,-0.22),Vector3(0.31,0.065,0.03),"eab46e",true)
	for side in [-1,1]:
		box(root,Vector3(side*0.43,1.22,0),Vector3(0.24,0.32,0.41),"68757a")
		box(root,Vector3(side*0.49,0.68,-0.12),Vector3(0.11,0.8,0.12),"b3905b")
	root.scale=Vector3.ONE*size
	return {"node":root,"pos":Vector2(pos.x,pos.z),"hp":5 if brute else 3,"max_hp":5 if brute else 3,"phase":"idle","timer":1.0,"brute":brute,"body":body,"flash":0.0,"aim":Vector2.ZERO}
static func batch_static(parent: Node3D) -> void:
	# Merge immutable scenery by material/shadow mode. Animated bodies stay separate.
	var groups: Dictionary={}
	for child in parent.get_children():
		if not child is MeshInstance3D: continue
		var material_value: Material=child.material_override
		var key:=str(material_value.get_instance_id())+":"+str(child.cast_shadow)
		if not groups.has(key):
			var tool:=SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[key]={"tool":tool,"material":material_value,"shadow":child.cast_shadow}
		var tool: SurfaceTool=groups[key]["tool"]
		for surface in range(child.mesh.get_surface_count()):
			var arrays: Array=child.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			for j in range(indices.size() if not indices.is_empty() else vertices.size()):
				var i: int=indices[j] if not indices.is_empty() else j
				tool.set_normal((child.transform.basis.inverse().transposed()*normals[i]).normalized())
				tool.add_vertex(child.transform*vertices[i])
		parent.remove_child(child); child.queue_free()
	for group in groups.values():
		var batch:=MeshInstance3D.new(); batch.mesh=group["tool"].commit(); batch.material_override=group["material"]; batch.cast_shadow=group["shadow"]; batch.name="StaticBatch"; parent.add_child(batch)
